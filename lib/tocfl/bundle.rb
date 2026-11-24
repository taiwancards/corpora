# frozen_string_literal: true

require "fileutils"
require "json"
require "set"

require_relative "audio"
require_relative "booklet"
require_relative "clip_plan"
require_relative "cropper"
require_relative "script"
require_relative "text"

module Tocfl
  class Bundle
    VERSION = 1
    LETTERS = %w[A B C D E F].freeze

    attr_reader :paper, :report

    def initialize(paper, papers_dir:, media_dir:, out_dir:)
      @paper = paper
      @papers_dir = papers_dir
      @media_dir = media_dir
      @final_dir = File.join(out_dir, paper[:slug])
      @out_dir = File.join(out_dir, ".#{paper[:slug]}.building")
      @report = {slug: paper[:slug], problems: [], notes: []}
    end

    def build
      FileUtils.rm_rf(@out_dir)
      @document = Document.new(File.join(@papers_dir, paper[:paper]))
      @cropper = Cropper.new(@document, File.join(@out_dir, "img"))
      numbers = paper[:answers].keys.map(&:to_i).sort
      @booklet = Booklet.new(@document, numbers).parse
      @report[:problems].concat(@booklet.log)
      @script_document = listening? && paper[:transcript] && File.exist?(File.join(@papers_dir, paper[:transcript])) ? Document
        .new(File.join(@papers_dir, paper[:transcript])) : nil
      @script = @script_document && Script.new(@script_document).parse

      parts = build_parts
      bundle = {
        "v" => VERSION,
        "slug" => paper[:slug],
        "band" => paper[:band],
        "set" => paper[:set],
        "skill" => paper[:skill],
        "levels" => paper[:levels],
        "minutes" => paper[:minutes],
        "count" => numbers.size,
        "paper" => paper[:paper],
        "audio" => listening? ? paper[:audio] : nil
      }
      if listening?
        plan = plan_clips(parts)
        bundle["opening_clips"] = plan.opening.map(&:path)
        bundle["closing_clips"] = plan.closing.map(&:path)
        attach_clips(parts, plan)
        bundle["clip_files"] = @audio.clips.to_h { |clip|
          [clip.path, {"seconds" => clip.seconds, "sha256" => clip.sha256}]
        }
      end

      bundle["parts"] = parts
      bundle["key"] = paper[:answers]
      bundle["scale"] = paper[:scale]
      bundle["editions"] = build_editions(parts)
      bundle["source"] = {"holder" => "國家華語測驗推動工作委員會", "kind" => "official mock test"}
      verify(bundle)
      FileUtils.mkdir_p(@out_dir)
      File.write(File.join(@out_dir, "bundle.json"), "#{JSON.pretty_generate(bundle)}\n")
      FileUtils.rm_rf(@final_dir)
      File.rename(@out_dir, @final_dir)
      @report[:bundle] = bundle
      @report[:image_bytes] = @cropper.written.values.sum
      @report[:images] = @cropper.written.size
      self
    end

    def listening? = paper[:skill] == "listening"

    private

    def letters_for(part, items)
      counts = items.map { |item| item.options.size }.reject(&:zero?)
      size = counts.max_by { |count| counts.count(count) }
      size ||= part[:instruction]&.text.to_s.scan(/[(（]([A-F])[)）]/).flatten.uniq.size
      size = nil if size&.zero?
      key_max = items.filter_map { |item| paper[:answers][item.number.to_s] }.max
      key_size = key_max ? LETTERS.index(key_max) + 1 : 3
      [[size || key_size, key_size].max, 3].max
    end

    def build_parts
      @booklet.parts.each_with_index.map do |part, index|
        items = part[:entries].select { |kind, _| kind == :item }.map(&:last)
        letters = LETTERS.first(letters_for(part, items))
        groups = listening? ? listening_groups(part, letters) : reading_groups(part, letters)
        rendered = groups
          .flat_map { |group| group["items"].map { |item| item["options"].map { |option| option["k"] } } }
          .uniq
        letters = rendered.max_by(&:size) if rendered.size == 1 || (rendered.any? && items.empty?)
        {
          "id" => index + 1,
          "title" => part_title(part),
          "plays" => plays_for(index + 1),
          "pause_seconds" => 5,
          "letters" => letters,
          "intro" => intro_for(part, index + 1),
          "groups" => groups
        }
      end
    end

    def part_title(part)
      rows = part[:instruction]&.rows.to_a.take_while { |row| !row.compact_text.match?(Booklet::START) }
      title = rows.map(&:compact_text).find { |text| text.match?(/第.部分|、/) && !text.match?(/題/) }
      sub = rows.map(&:text).find { |text| text.match?(/\APart\s/i) }
      [title, sub].compact.join(" ").then { |text| text.empty? ? nil : text }
    end

    def plays_for(part)
      return 2 if paper[:band] == "Novice"
      return (part <= 3 ? 2 : 1) if paper[:band] == "A"

      1
    end

    def intro_for(part, number)
      instruction = part[:instruction]
      return {"clips" => [], "text" => nil, "image" => nil} unless instruction

      images = instruction.rows.group_by(&:page).each_with_index.filter_map do |(page, rows), index|
        @cropper.crop(page, block_box(page, rows), "part#{number}-intro#{index.zero? ? "" : "-#{index + 1}"}", pad: 4)
      end

      text = instruction.text
      if text && (issues(text, max: 2000).any? || instruction.rows.any? { |row| @document.ocr_page?(row.page) })
        text = nil
      end

      {"clips" => [], "text" => text, "image" => images.first}.tap { |intro|
        intro["images"] = images if images.size > 1
      }
    end

    def block_box(page, rows)
      union = Box.around(rows.map(&:box))
      others = @booklet.rows(page) - rows
      above = others.select { |row| row.y1 <= union.y0 + 1 }.map(&:y1).max || 0
      below = others.select { |row| row.y0 >= union.y1 - 1 }.map(&:y0).min || @document.page_box(page).height
      band = Box.new(
        8,
        [above + 2, union.y0 - 30].max,
        @document.page_box(page).width - 8,
        [below - 2, union.y1 + 30].min
      )
      Box.around([union, @document.ink_box(page, band)])
    end

    def reading_groups(part, letters)
      groups = []
      pending = []
      entries = with_cloze(part[:entries])
      entries.each do |kind, payload|
        case kind
        when :content
          pending << payload
        when :cloze
          groups << {contexts: [payload[:passage]], items: payload[:items], shared: true}
          pending = []
        else
          if pending.any? { |content| content.rows.any? || content.pictures.any? }
            groups << {contexts: pending, items: [payload]}
            pending = []
          elsif groups.last && groups.last[:contexts].any? && !groups.last[:shared]
            groups.last[:items] << payload
          else
            groups << {contexts: [], items: [payload]}
          end
        end
      end

      groups.map { |group| render_group(group, letters) }
    end

    CLOZE_MARK = /[（(]\s*(\d{1,3})\s*[)）]/

    def with_cloze(entries)
      present = @booklet
        .parts
        .flat_map { |part| part[:entries] }
        .select { |kind, _| kind == :item }
        .map { |_, item| item.number }
        .to_set
      missing = paper[:answers].keys.map(&:to_i).to_set - present - @cloze_taken.to_a
      merged = entries
        .chunk_while { |(kind_a, a), (kind_b, b)| kind_a == :content && kind_b == :content && a.page == b.page }
        .map do |run|
          next run if run.size == 1 || run.first.first != :content

          contents = run.map(&:last)
          [
            [
              :content,
              Booklet::Content.new(
                rows: contents.flat_map(&:rows),
                pictures: contents.flat_map(&:pictures),
                page: contents.first.page
              ),
              :merged,
              run
            ]
          ]
        end

      merged.flat_map do |entry|
        kind, payload, merged_flag, run = entry.first.is_a?(Array) ? entry.first : entry
        original = merged_flag == :merged ? run : [[kind, payload]]
        next original unless kind == :content

        segments = payload.rows.slice_when { |a, b| option_row?(a) && !option_row?(b) }.to_a
        built = segments.map { |rows| cloze_entry(rows, payload, missing) }
        next original if built.none? { |item_kind, _| item_kind == :cloze }

        built.each { |item_kind, cloze| missing -= cloze[:items].map(&:number) if item_kind == :cloze }
        built
      end
    end

    def option_row?(row) = row.words.first&.text&.match?(Text::LABEL_ONLY)

    def cloze_entry(rows, payload, missing)
      content = Booklet::Content.new(rows: rows, pictures: payload.pictures, page: payload.page)
      marks = rows
        .flat_map { |row| row.compact_text.scan(CLOZE_MARK).flatten.map(&:to_i) }
        .select { |number| missing.include?(number) }
        .uniq
      return [:content, content] if marks.size < 2

      option_rows, passage_rows = rows.partition { |row| option_row?(row) }
      options = option_rows.flat_map { |row| row_options(row) }
      letters = options.map(&:letter)
      unless letters == LETTERS.first(letters.size) && letters.size >= 3
        @report[:problems] << "cloze #{marks.join(",")}: option labels #{letters.join}"
        return [:content, content]
      end

      (@cloze_taken ||= Set.new).merge(marks)
      passage = Booklet::Content.new(rows: passage_rows, pictures: payload.pictures, page: payload.page)
      items = marks.sort.map do |number|
        Booklet::Item.new(
          number: number,
          page: payload.page,
          region: nil,
          anchor: nil,
          stem_tokens: [],
          stem_rows: [],
          stem_pictures: [],
          options: options,
          conflicts: [],
          gaps: []
        )
      end

      [:cloze, {passage: passage, items: items}]
    end

    def row_options(row)
      labels = row.words.each_index.select { |index| row.words[index].text.match?(Text::LABEL_ONLY) }
      labels.each_with_index.map do |index, position|
        stop = labels[position + 1] || row.words.size
        tokens = row.words[(index + 1)...stop]
        Booklet::Option.new(
          letter: row.words[index].text[Text::LABEL_ONLY, 1],
          label: row.words[index],
          tokens: tokens,
          rows: [row],
          picture: nil
        )
      end
    end

    def listening_groups(part, letters)
      items = part[:entries].select { |kind, _| kind == :item }.map(&:last)
      contexts = {}
      pending = []
      part[:entries].each do |kind, payload|
        if kind == :content
          pending << payload
        else
          contexts[payload.number] = pending if pending.any?
          pending = []
        end
      end

      clusters = []
      items.each do |item|
        script_group = @script&.for_number(item.number)
        if clusters.last && script_group && clusters.last[:script] == script_group
          clusters.last[:items] << item
        else
          clusters << {script: script_group, items: [item], contexts: contexts[item.number] || []}
        end
      end

      clusters.map do |cluster|
        group = render_group({contexts: cluster[:contexts], items: cluster[:items]}, letters)
        transcript = cluster[:script] && !cluster[:script].ocr ? @script.transcript(cluster[:script]) : nil
        if transcript &&
            (transcript.match?(Text::MISENCODED) ||
              (misencoded?(@script_document) && transcript.match?(Text::MISENCODED_AMBIGUOUS)))
          @report[:problems] << "#{group["id"]}: transcript withheld, the script font is mis-encoded"
          transcript = nil
        end

        group["transcript"] = transcript
        group
      end
    end

    def render_group(group, letters)
      first = group[:items].first.number
      context = render_context(group[:contexts], "g#{first}-context")
      items = if group[:shared]
        shared_letters = group[:items].first.options.map(&:letter)
        rendered = render_item(group[:items].first, shared_letters, prefix: "g#{first}")
        group[:items].map { |item| rendered.merge("n" => item.number) }
      else
        group[:items].map { |item| render_item(item, letters) }
      end

      {"id" => "g#{first}", "clips" => [], "context" => context, "items" => items}.tap { |out|
        out["options_shared"] = true if group[:shared]
      }
    end

    def render_context(contents, name)
      contents = contents.select { |content| content.rows.any? || content.pictures.any? }
      return {"text" => nil, "image" => nil} if contents.empty?

      images = contents.group_by(&:page).each_with_index.filter_map do |(page, list), index|
        boxes = list.flat_map { |content| content.rows.map(&:box) + content.pictures }
        union = Box.around(boxes)
        refined = Box.around([union, @document.ink_box(page, union.pad(3))])
        @cropper.crop(page, refined, index.zero? ? name : "#{name}-#{index + 1}")
      end

      rows = contents.flat_map(&:rows)
      text = rows.any? ? paragraphs(rows) : nil
      if text &&
          contents.any? { |content| content.pictures.any? } &&
          (text.size < 4 || text.match?(/\A[（(][一二三四五六七八九十]+[)）]\z/))
        text = nil
      end

      if text && (issues(text, max: 4000).any? || contents.any? { |content| @document.ocr_page?(content.page) })
        text = nil
      end

      {"text" => text, "image" => images.first}.tap { |context| context["images"] = images if images.size > 1 }
    end

    def paragraphs(rows)
      left = rows.map(&:x0).min
      widest = rows.map(&:x1).max
      out = []
      rows.each_with_index do |row, index|
        line = line_text(row.words, row.page)
        previous = index.positive? ? rows[index - 1] : nil
        ended = previous && previous.compact_text.match?(/[。！？」』：…]\z/)
        fresh = previous.nil? ||
          row.compact_text.match?(Booklet::PASSAGE_MARK) ||
          previous.compact_text.match?(Booklet::PASSAGE_MARK) ||
          (ended && (row.x0 > left + 10 || previous.x1 < widest - 40)) ||
          (row.page == previous.page && previous.x1 < widest - 80)
        if fresh
          out << line
        else
          out[-1] = Text.join([out[-1], line])
        end
      end

      Text.normalize(out.join("\n")).gsub(/ *\n */, "\n")
    end

    def line_text(tokens, page, leading: nil)
      pieces = []
      previous = leading
      tokens.each do |token|
        if previous && token.x0 - previous.x1 > [token.height * 1.2, 10].max
          gap = Box.new(previous.x1 + 0.5, [previous.y0, token.y0].min, token.x0 - 0.5, [previous.y1, token.y1].max + 4)
          ink = @document.ink_box(page, gap)
          pieces << Text::BLANK if ink && ink.height <= 4 && ink.width >= 0.4 * gap.width
        end

        underlined = token.text.match?(/\A\d{1,3}\z/) &&
          (line = @document.ink_box(page, Box.new(token.x0 - 1, token.y1 - 1, token.x1 + 1, token.y1 + 4))) &&
          line.height <= 3 &&
          line.width >= token.box.width *
          0.8
        pieces << (underlined ? "#{Text::BLANK}#{token.text}#{Text::BLANK}" : Text.strip_residue(token.text))
        previous = token
      end

      Text.normalize(Text.join(pieces))
    end

    def text_box(page, boxes)
      union = Box.around(boxes)
      return nil unless union

      visible = @booklet.rows(page).reject { |row|
        row.words.all? { |token|
          Text.residue?(token.text) || @booklet.shadow_tokens.include?(token) || token.text.match?(/\A\d{1,3}[.．]\z/)
        }
      }
      beside = visible.select { |row| row.box.overlap_x(union).positive? }
      above = beside.map(&:y1).select { |y| y <= union.y0 + 1 }.max
      below = beside.map(&:y0).select { |y| y >= union.y1 - 1 }.min
      top = above ? (above + union.y0) / 2.0 : union.y0 - 18
      bottom = below ? (below + union.y1) / 2.0 : union.y1 + 4
      top = [top, union.y0 - 18].max
      bottom = [bottom, union.y1 + 6].min
      core = Box.around([union, @document.ink_box(page, union.pad(1.5))])
      up = @document.ink_box(page, Box.new(union.x0 - 2, top, union.x1 + 2, core.y0 - 0.5))
      down = @document.ink_box(page, Box.new(union.x0 - 2, core.y1 + 0.5, union.x1 + 2, bottom))
      parts = [core]
      parts << up if up && up.y0 > top + 0.5 && up.height < 12
      parts << down if down && down.y1 < bottom - 0.5 && down.height < 6
      Box.around(parts)
    end

    def render_item(item, letters, prefix: nil)
      prefix ||= "q#{item.number}"
      trusted = !@document.ocr_page?(item.page)
      page = item.page
      stem_text = nil
      stem_image = nil
      if item.stem_pictures.any?
        stem_image = @cropper.crop(page, Box.around(item.stem_pictures), "q#{item.number}", pad: 2)
        pictures << stem_image
      end

      if item.stem_tokens.any?
        rows = item.stem_rows
        anchor_row = item.anchor && rows.find { |row| row.box.overlap_y(item.anchor.box) > 0.5 * item.anchor.height }
        stem_text = rows
          .map { |row|
            line_text(
              row.words.reject { |token| token.equal?(item.anchor) },
              page,
              leading: row.equal?(anchor_row) ? item.anchor : nil
            )
          }
          .join
        stem_text = Text.normalize(stem_text)
        stem_text = nil if !trusted || issues(stem_text, max: 300).any? || conflicted?(item, rows)
        crop = text_box(page, item.stem_tokens.map(&:box) + (anchor_row ? [item.anchor.box] : []))
        stem_image ||= @cropper.crop(page, crop, "q#{item.number}")
        if item.stem_pictures.any? && crop
          stem_image = @cropper.crop(page, Box.around([crop, *item.stem_pictures]), "q#{item.number}", pad: 2)
          pictures.delete(stem_image)
        end
      end

      if item.stem_tokens.empty? && (preview = @booklet.stray_previews[item.number])
        rows = preview_rows(preview)
        tokens = rows.flat_map(&:words).reject { |token| token.equal?(preview.token) }
        if tokens.any?
          stem_text = Text.normalize(
            rows
              .map { |row|
                line_text(
                  row.words.reject { |token| token.equal?(preview.token) },
                  preview.page,
                  leading: row.words.include?(preview.token) ? preview.token : nil
                )
              }
              .join
          )
          stem_text = nil if @document.ocr_page?(preview.page) || issues(stem_text, max: 300).any?
          stem_image = @cropper.crop(
            preview.page,
            text_box(preview.page, tokens.map(&:box) + [preview.token.box]),
            "q#{item.number}"
          )
        end
      end

      found = item.options.map(&:letter)
      letters_ok = (found.empty? || found == letters) && item.conflicts.none? { |conflict| conflict[:misprint] }
      unless found.empty? || found == letters
        @report[:problems] << "q#{item.number}: option labels #{found.join} where #{letters.join} expected"
      end

      if item.conflicts.any? { |conflict| conflict[:misprint] }
        @report[:problems] <<
          "q#{item.number}: the paper prints a duplicated option label; options read by position, text withheld"
      end

      key = paper[:answers][item.number.to_s]
      @report[:problems] << "q#{item.number}: key #{key} outside #{letters.join}" unless letters.include?(key)

      script_options = @script ? @script.options(item.number) : {}
      options = letters.map do |letter|
        option = item.options.find { |candidate| candidate.letter == letter }
        next ({"k" => letter, "text" => nil, "image" => nil}) unless option

        image = nil
        text = nil
        if option.picture
          image = @cropper.crop(page, option.picture, "#{prefix}-#{letter}", pad: 2)
          pictures << image
        elsif option.tokens.any?
          text = option
            .rows
            .map { |row| line_text(row.words.select { |token| option.tokens.include?(token) }, page) }
            .join
          text = Text.normalize(text)
          text = nil if !trusted || !letters_ok || issues(text, max: 200).any? || conflicted?(item, option.rows)
          text = nil if text && script_options[letter] && plain(script_options[letter]) != plain(text)
          image = @cropper.crop(
            page,
            text_box(page, [option.label.box] + option.tokens.map(&:box)),
            "#{prefix}-#{letter}"
          )
        end

        {"k" => letter, "text" => text, "image" => image}
      end

      {"n" => item.number, "stem" => {"text" => stem_text, "image" => stem_image}, "options" => options}
    end

    def issues(text, **limits)
      found = Text.problems(text, **limits)
      if misencoded?(@document) && text.to_s.match?(Text::MISENCODED_AMBIGUOUS)
        found << "ambiguous character in a mis-encoded paper"
      end

      found
    end

    def misencoded?(document)
      @misencoded ||= {}
      @misencoded.fetch(document.path) do
        @misencoded[document.path] = (1..document.page_count).any? { |page|
          document.words(page).any? { |word| word.text.match?(Text::MISENCODED) }
        }
      end
    end

    def preview_rows(preview)
      page_rows = @booklet.rows(preview.page)
      first = page_rows.find { |row| row.words.include?(preview.token) }
      return [] unless first

      rows = [first]
      page_rows.select { |row| row.y0 > first.y0 }.sort_by(&:y0).each do |row|
        unless row.y0 - rows.last.y1 < 6 && row.x0 >= preview.token.x1 - 4 && !row.words.first.text.match?(Text::ANCHOR)
          break
        end

        rows << row
      end

      rows
    end

    def plain(text) = text.to_s.gsub(/[\s。，、！？.,!?]/, "")

    def conflicted?(item, rows)
      item.conflicts.any? { |conflict| rows.include?(conflict[:row]) && !confirmed?(item.page, conflict) }
    end

    def confirmed?(page, conflict)
      kept = conflict[:kept].chars
      shadow = conflict[:shadow].chars
      kept_only = kept - shadow
      shadow_only = shadow - kept
      return false if kept_only.empty? && shadow_only.empty?

      seen = @document.ocr_line(page, conflict[:row].box.pad(2))
      verdict = kept_only.all? { |char| seen.include?(char) } && shadow_only.none? { |char| seen.include?(char) }
      @report[:notes] <<
        "layer conflict #{conflict[:shadow]}→#{conflict[:kept]}: OCR #{verdict ? "confirms" : "undecided"}"
      verdict
    end

    def plan_clips(parts)
      @audio = Audio.new(@media_dir, paper[:audio])
      unless @audio.exist?
        @report[:problems] << "audio folder #{paper[:audio]} missing"
        return ClipPlan.new([], []).tap { |plan| plan.instance_variable_set(:@scheme, "none") }
      end

      part_groups = parts.map { |part| part["groups"].map { |group| group["items"].map { |item| item["n"] } } }
      plan = ClipPlan.new(@audio.clips, part_groups).build
      @report[:problems].concat(plan.problems)
      @report[:notes] << "clips: #{plan.scheme}"
      plan
    end

    def attach_clips(parts, plan)
      parts.each do |part|
        part["intro"]["clips"] = plan.intros[part["id"]].map(&:path)
        repeated = []
        part["groups"].each do |group|
          line = plan.timelines[group["items"].first["n"]] || []
          group["clips"] = line.map { |entry| entry[:clip].path }
          group["timeline"] = line.map { |entry|
            {"clip" => entry[:clip].path, "n" => entry[:n], "seconds" => entry[:clip].seconds}
          }
          clips = line.map { |entry| entry[:clip] }
          group["repeat_in_clip"] = part["plays"] > 1 && clips.any? && clips.all?(&:repeated?)
          group["pause_in_clip"] = clips.any? && clips.last.trailing_silence >= 3.0
          repeated << group["repeat_in_clip"] if part["plays"] > 1
        end

        if part["plays"] > 1 && repeated.any? && !repeated.all?
          @report[:problems] <<
            "part #{part["id"]}: #{repeated.count(false)} of #{repeated.size} groups lack an audible repetition"
        end
      end
    end

    def build_editions(parts)
      editions = Array(paper[:editions])
      return nil if editions.empty?

      numbers = paper[:answers].keys.map(&:to_i).sort
      base_options = option_texts(parts)
      editions.to_h do |edition|
        code = edition[:code]
        if edition[:paper] == paper[:paper]
          next [code, {"paper" => edition[:paper], "audio" => edition[:audio], "base" => true}]
        end

        document = Document.new(File.join(@papers_dir, edition[:paper]))
        booklet = Booklet.new(document, numbers).parse
        cropper = Cropper.new(document, File.join(@out_dir, "img", code))
        intros = booklet.parts.each_with_index.to_h do |part, index|
          instruction = part[:instruction]
          images = Array(instruction&.rows).group_by(&:page).each_with_index.filter_map do |(page, rows), position|
            box = edition_block_box(document, booklet, page, rows)
            cropper
              .crop(page, box, "part#{index + 1}-intro#{position.zero? ? "" : "-#{position + 1}"}", pad: 4)
              &.sub("img/", "img/#{code}/")
          end

          text = instruction&.text
          if text && (issues(text, max: 2000).any? || instruction.rows.any? { |row| document.ocr_page?(row.page) })
            text = nil
          end

          [
            (index + 1).to_s,
            {"clips" => [], "text" => text, "image" => images.first}.tap { |intro|
              intro["images"] = images if images.size > 1
            }
          ]
        end

        same_items = compare_items(booklet, base_options)
        if booklet.parts.size != parts.size
          @report[:problems] << "#{code} edition: #{booklet.parts.size} parts where the base has #{parts.size}"
        end

        parsed = booklet.parts.sum { |part| part[:entries].count { |kind, _| kind == :item } }
        @report[:notes] << "#{code}: #{same_items} of #{parsed} parsed items match the base"
        entry = {
          "paper" => edition[:paper],
          "audio" => edition[:audio],
          "intros" => intros,
          "items_matching_base" => same_items
        }
        entry.merge!(edition_audio(edition, parts, intros)) if listening?
        @report[:image_bytes_editions] = (@report[:image_bytes_editions] || 0) + cropper.written.values.sum
        [code, entry]
      end
    end

    def edition_block_box(document, booklet, page, rows)
      union = Box.around(rows.map(&:box))
      others = booklet.rows(page) - rows
      above = others.select { |row| row.y1 <= union.y0 + 1 }.map(&:y1).max || 0
      below = others.select { |row| row.y0 >= union.y1 - 1 }.map(&:y0).min || document.page_box(page).height
      band = Box.new(
        8,
        [above + 2, union.y0 - 30].max,
        document.page_box(page).width - 8,
        [below - 2, union.y1 + 30].min
      )
      Box.around([union, document.ink_box(page, band)])
    end

    def option_texts(parts)
      parts.flat_map { |part| part["groups"].flat_map { |group| group["items"] } }.to_h do |item|
        [item["n"], item["options"].map { |option| option["text"] }]
      end
    end

    def compare_items(booklet, base_options)
      booklet.parts.sum do |part|
        part[:entries].count do |kind, item|
          next false unless kind == :item

          texts = item.options.map { |option| Text.normalize(Text.join(option.tokens.map(&:text))) }
          base = base_options[item.number]
          next false unless base

          base.each_with_index.all? { |text, index|
            text.nil? || texts[index].nil? || plain(text) == plain(texts[index])
          } &&
            (item.options.size == base.size || item.options.empty?)
        end
      end
    end

    def edition_audio(edition, parts, intros)
      audio = Audio.new(@media_dir, edition[:audio])
      unless audio.exist?
        @report[:problems] << "#{edition[:code]} audio folder #{edition[:audio]} missing"
        return {"clips" => {}}
      end

      part_groups = parts.map { |part| part["groups"].map { |group| group["items"].map { |item| item["n"] } } }
      plan = ClipPlan.new(audio.clips, part_groups).build
      @report[:problems].concat(plan.problems.map { |problem| "#{edition[:code]} audio: #{problem}" })
      base_by_hash = @audio.clips.to_h { |clip| [clip.sha256, clip.path] }
      overrides = {}
      shared = 0
      pairs = []
      parts.each do |part|
        line_pairs = part["groups"].flat_map do |group|
          base_line = group["clips"]
          edition_line = (plan.timelines[group["items"].first["n"]] || []).map { |entry| entry[:clip] }
          if edition_line.size != base_line.size
            @report[:problems] <<
              "#{edition[:code]} audio: #{group["id"]} has #{edition_line.size} clips, base #{base_line.size}"
          end

          base_line.zip(edition_line)
        end

        pairs.concat(line_pairs)
        (intros[part["id"].to_s] ||= {"clips" => [], "text" => nil, "image" => nil})["clips"] = plan.intros[part["id"]]
          .map(&:path)
      end

      pairs.each do |base_path, clip|
        next unless clip

        if base_by_hash[clip.sha256] == base_path
          shared += 1
        else
          overrides[base_path] = clip.path
        end
      end

      clip_files = audio.clips.to_h { |clip|
        [
          clip.path,
          {"seconds" => clip.seconds, "sha256" => clip.sha256, "same_as_base" => base_by_hash[clip.sha256]}.compact
        ]
      }
      {
        "opening_clips" => plan.opening.map(&:path),
        "closing_clips" => plan.closing.map(&:path),
        "clips" => overrides,
        "clips_shared_with_base" => shared,
        "clip_files" => clip_files
      }
    end

    def verify(bundle)
      items = bundle["parts"].flat_map { |part| part["groups"].flat_map { |group| group["items"] } }
      numbers = items.map { |item| item["n"] }
      if numbers.size != bundle["key"].size
        @report[:problems] << "item count #{numbers.size} differs from key #{bundle["key"].size}"
      end

      if (bundle["key"].keys.map(&:to_i) - numbers).any?
        @report[:problems] << "numbers #{(bundle["key"].keys.map(&:to_i) - numbers).inspect} missing"
      end

      @report[:problems] << "duplicate numbers" if numbers.uniq.size != numbers.size
      items.each { |item| @report[:problems] << "q#{item["n"]} has no options" if item["options"].empty? }
      images = []
      walk(bundle) { |key, value| images << value if %w[image].include?(key) && value }
      walk(bundle) { |key, value| images.concat(value) if key == "images" && value }
      images.uniq.each { |path|
        @report[:problems] << "missing image #{path}" unless File.exist?(File.join(@out_dir, path))
      }
      if listening?
        clips = bundle["opening_clips"] +
          bundle["closing_clips"] +
          bundle["parts"].flat_map { |part|
            part["intro"]["clips"] + part["groups"].flat_map { |group| group["clips"] }
          }
        clips.each { |clip|
          @report[:problems] << "missing clip #{clip}" unless File.exist?(File.join(@media_dir, bundle["audio"], clip))
        }
        unplaced = bundle["clip_files"].keys - clips
        @report[:problems] << "clips not placed: #{unplaced.join(", ")}" if unplaced.any?
        bundle["parts"].each { |part|
          part["groups"].each { |group| @report[:problems] << "#{group["id"]} has no clips" if group["clips"].empty? }
        }
      end

      @report[:text_items] = items.count { |item| item_has_text?(item) }
      @report[:picture_items] = items.count { |item|
        [item["stem"], *item["options"]].all? { |piece|
          piece["text"].nil? && (piece["image"].nil? || pictures.include?(piece["image"]))
        }
      }
      @report[:image_items] = items.size - @report[:text_items] - @report[:picture_items]
      @report[:withheld] = items.reject { |item| item_has_text?(item) }.filter_map { |item|
        unless [item["stem"], *item["options"]].all? { |piece|
            piece["text"].nil? && (piece["image"].nil? || pictures.include?(piece["image"]))
          }
          item["n"]
        end
      }
    end

    def item_has_text?(item)
      pieces = [item["stem"], *item["options"]].select { |piece|
        piece["text"] || (piece["image"] && !pictures.include?(piece["image"]))
      }
      pieces.any? && pieces.all? { |piece| piece["text"] }
    end

    def pictures = (@pictures ||= Set.new)

    def walk(node, &block)
      case node
      when Hash
        node.each do |key, value|
          yield(key, value)
          walk(value, &block)
        end

      when Array
        node.each { |value| walk(value, &block) }
      end
    end
  end
end
