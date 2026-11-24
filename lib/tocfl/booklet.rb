# frozen_string_literal: true

require_relative "document"
require_relative "rows"
require_relative "text"

module Tocfl
  class Booklet
    START = /\A說明\s*[:：]|\A說\s*明\s*[:：]/
    HEADER = /第\s*[一二三四五六七八九十\d]+\s*部\s*分|\APart\s+\w+\z|\A[（(]\s*第\s*\d+\s*[~～\-－]\s*\d+\s*題\s*[)）]\z|\A[一二三四五六七八九十]\s*、/
    FINISH = /說明結束|turn to|This is the end|答案卡|省略|每題只念一遍|請翻頁|correct answer|answer sheet/i
    EXAMPLE = /\A(例題|請看下面的例子|你會看到|Example|例如)/
    DIRECTIONS = /\ADirections\s*[:：]/i
    PASSAGE_MARK = /\A[（(]\s*[一二三四五六七八九十]+\s*[)）]\z/
    INTRO_HINT = /\A(以下是|下面是|請聽|請你|請閱讀|請看)/
    SENTENCE_END = /[。！？」』…]\z/
    MIN_PICTURE = 22

    Anchor = Data.define(:number, :page, :token)
    Instruction = Data.define(:rows, :text)
    Content = Data.define(:rows, :pictures, :page)
    Option = Data.define(:letter, :label, :tokens, :rows, :picture)
    Item = Data.define(
      :number,
      :page,
      :region,
      :anchor,
      :stem_tokens,
      :stem_rows,
      :stem_pictures,
      :options,
      :conflicts,
      :gaps
    )

    attr_reader :document, :numbers, :parts, :log

    def initialize(document, numbers)
      @document = document
      @numbers = numbers
      @log = []
    end

    def parse
      @page_rows = {}
      @page_tokens = {}
      (1..document.page_count).each do |page|
        tokens = Rows.tokens(document.words(page)).reject { |token| token.text.strip.empty? }
        rows = Rows.build(tokens).reject { |row| Rows.page_number?(row, document.page_box(page)) }
        @page_rows[page] = rows
        @page_tokens[page] = rows.flat_map(&:words)
      end

      @instructions = find_instructions
      @instruction_rows = @instructions.flat_map(&:rows).to_set
      @anchors = resolve_anchors(candidate_anchors)
      @parts = assemble
      self
    end

    def rows(page) = @page_rows.fetch(page)

    def stray_previews = @previews || {}

    def shadow_tokens = (@shadow_tokens ||= Set.new.compare_by_identity)

    private

    def reading_order = @page_rows.flat_map { |_page, rows| rows }

    def find_instructions
      found = []
      current = nil
      ended = false
      example = false
      order = reading_order
      order.each_with_index do |row, index|
        text = row.compact_text
        if text.match?(START) && current && !ended && row.page - current.last.page <= 1
          current << row
          next
        end

        if text.match?(START)
          found << current if current
          head = []
          back = index - 1
          while back >= 0 && order[back].page == row.page && header?(order[back])
            head.unshift(order[back])
            back -= 1
          end

          current = head + [row]
          ended = false
          example = false
          next
        end

        next unless current

        spaced = row.text
        example ||= text.match?(EXAMPLE) || spaced.match?(EXAMPLE)
        finish = example && (text.match?(FINISH) || spaced.match?(FINISH))
        same_page = row.page == current.last.page
        trailing = ended &&
          same_page &&
          row.y0 -
          current.last.y1 < 70 &&
          !row.words.first.text.match?(Text::ANCHOR) &&
          !header?(row) &&
          !text.match?(PASSAGE_MARK) &&
          !row.words.first.text.match?(Text::LABEL_ONLY)
        if (finish && (same_page || !ended)) ||
            (ended && same_page && row.y0 - current.last.y1 < 90 && bubble?(row)) ||
            trailing
          current << row
          ended = true if finish
          next
        end

        if ended || (example && !same_page)
          found << current
          current = nil
          ended = false
          next
        end

        current << row
      end

      found << current if current
      found.map { |rows| Instruction.new(rows: rows, text: directions(rows)) }
    end

    def header?(row) = row.compact_text.match?(HEADER) || row.text.match?(HEADER)

    def bubble?(row)
      tokens = row.words.map(&:text)
      tokens.first.to_s.match?(/\A\d{1,3}[.．]?\z/) &&
        tokens.drop(1).all? { |text| text.match?(/\A[A-F●○.．\uE000-\uF8FF\u2460-\u24FF]*\z/) }
    end

    def directions(rows)
      body = rows.drop_while { |row| !row.compact_text.match?(START) }
      body = body.take_while { |row| !row.compact_text.match?(EXAMPLE) }
      chinese, english = body.partition.with_index { |_row, index|
        body[0..index].none? { |row| row.compact_text.match?(DIRECTIONS) }
      }
      parts = [
        Text.join(chinese.map { |row| row.words.map(&:text).join(" ") }).gsub(/\s+/, ""),
        Text.join(english.flat_map { |row| row.words.map(&:text) }).gsub(/\s+/, " ")
      ]
      parts.reject(&:empty?).join("\n").then { |text| text.empty? ? nil : text }
    end

    def candidate_anchors
      reading_order.reject { |row| @instruction_rows.include?(row) }.flat_map do |row|
        row.words.each_with_index.filter_map do |token, index|
          match = token.text.match(/\A(\d{1,3})\s*[.．]\z/)
          next unless match
          next unless index.zero? || token.x0 - row.words[index - 1].x1 > 14

          Anchor.new(number: match[1].to_i, page: row.page, token: token)
        end
      end
    end

    def resolve_anchors(candidates)
      accepted = []
      @previews = {}
      wanted = numbers.to_set
      candidates.each do |candidate|
        number = candidate.number
        next unless wanted.include?(number)

        last = accepted.last&.number || 0
        if number > last && number <= last + 11
          accepted << candidate
        elsif (index = accepted.index { |anchor| anchor.number == number }) &&
            candidate.page -
            accepted[index].page <= 1 &&
            last -
            number <= 5
          accepted[index..].each { |anchor| @previews[anchor.number] = anchor }
          accepted = accepted[0...index] + [candidate]
        end
      end

      accepted
    end

    def assemble
      boundaries = @instructions.map { |instruction| instruction.rows.first }
      order = reading_order
      position = order.each_with_index.to_h
      anchor_rows = {}
      @anchors.each { |anchor|
        anchor_rows[anchor] = rows(anchor.page).find { |row| row.words.include?(anchor.token) }
      }

      parts = @instructions.map { |instruction| {instruction: instruction, entries: []} }
      if parts.empty? || (@anchors.any? && position[anchor_rows[@anchors.first]] < position[boundaries.first])
        parts.unshift({instruction: nil, entries: []})
      end

      part_for = lambda do |row|
        index = boundaries.count { |start| position[start] <= position[row] }
        parts[parts.first[:instruction].nil? ? index : [index - 1, 0].max]
      end

      (1..document.page_count).each do |page|
        page_anchors = @anchors.select { |anchor| anchor.page == page }
        page_rows = rows(page)
        content = page_rows.reject { |row| @instruction_rows.include?(row) }
        next if content.empty? && page_anchors.empty?

        instruction_tops = page_rows.select { |row| @instruction_rows.include?(row) }.map(&:y0)
        regions = page_anchors.map { |anchor| [anchor, region_for(anchor, page_anchors, page, instruction_tops)] }
        covered = regions.map(&:last)
        loose = content.reject { |row|
          covered.any? { |region| region.contains_center?(row.box) } ||
            page_anchors.any? { |anchor| row.words.include?(anchor.token) }
        }
        loose_groups = loose.chunk_while { |a, b| b.y0 - a.y1 < 40 }.to_a
        loose_groups.each do |group|
          next if group.all? { |row| header?(row) }

          part_for.call(group.first)[:entries] <<
            [:content, Content.new(rows: group, pictures: [], page: page), group.first.y0]
        end

        pre_top = regions.map { |_anchor, region| region.y0 }.min
        if pre_top.nil? && content.any?
          floor = page_rows.select { |row| @instruction_rows.include?(row) }.map(&:y1).max
          area = Box.new(0, floor ? floor + 4 : 0, document.page_box(page).width, document.page_box(page).height - 20)
          pictures = pictures_in(page, area)
          if pictures.any?
            part_for.call(content.first)[:entries] <<
              [:content, Content.new(rows: [], pictures: pictures, page: page), pictures.map(&:y0).min]
          end
        end

        if pre_top
          upper = Box.new(0, 0, document.page_box(page).width, pre_top)
          floor = page_rows.select { |row| @instruction_rows.include?(row) && row.y1 < pre_top }.map(&:y1).max
          upper = Box.new(0, floor + 4, upper.x1, upper.y1) if floor
          pictures = pictures_in(page, upper)
          unless pictures.empty?
            target = part_for.call(anchor_rows[regions.first.first])
            target[:entries] <<
              [:content, Content.new(rows: [], pictures: pictures, page: page), pictures.map(&:y0).min]
          end
        end

        regions.each do |anchor, region|
          item, tail = parse_item(anchor, region, page)
          target = part_for.call(anchor_rows[anchor])
          target[:entries] << [:item, item, region.y0]
          if tail.rows.any? || tail.pictures.any?
            target[:entries] << [:content, tail, tail.rows.map(&:y0).concat(tail.pictures.map(&:y0)).min]
          end
        end
      end

      parts.each do |part|
        part[:entries] = part[:entries]
          .each_with_index
          .sort_by { |(kind, payload, y), index| [entry_page(kind, payload), y || 0, index] }
          .map(&:first)
          .map { |kind, payload, _y| [kind, payload] }
      end

      parts
    end

    def entry_page(kind, payload) = kind == :item ? payload.page : payload.page

    def region_for(anchor, page_anchors, page, instruction_tops)
      token = anchor.token
      page_box = document.page_box(page)
      content_rows = rows(page)
      left_edge = 12
      right_edge = page_box.width - 12
      same_band = page_anchors.reject { |other| other == anchor }.select { |other|
        (other.token.y0 - token.y0).abs < 8
      }
      right = same_band.select { |other| other.token.x0 > token.x1 }.map { |other| other.token.x0 - 4 }.min ||
        right_edge
      left = same_band.any? { |other| other.token.x0 < token.x0 } ? token.x0 - 4 : left_edge
      below = page_anchors.select { |other|
        other.token.y0 > token.y1 + 2 && other.token.x0 < right && (other.token.x0 >= left - 2 || same_band.none?)
      }
      bottom = [
        below.map { |other| other.token.y0 - 3 }.min,
        instruction_tops.select { |top| top > token.y1 }.map { |top| top - 4 }.min,
        page_box.height - 30
      ].compact.min
      Box.new(left, token.y0 - 4, right, bottom)
    end

    def tokens_in(page, box)
      @page_tokens.fetch(page).select { |token|
        box.contains_center?(token.box) &&
          !@instruction_rows.any? { |row| row.page == page && row.words.include?(token) }
      }
    end

    def pictures_in(page, box, tokens = nil)
      tokens ||= tokens_in(page, box)
      masks = tokens.map { |token|
        token.box.pad(token.text.match?(Text::LABEL_ONLY) || token.text.match?(Text::ANCHOR) ? 4 : 1.5)
      }
      components = document.components(page, box, masks: masks, merge: 9)
      large, small = components.partition { |component|
        component.width >= MIN_PICTURE && component.height >= MIN_PICTURE
      }
      large = large.reject do |component|
        markers = tokens.count { |token|
          component.contains_center?(token.box) &&
            (token.text.match?(Text::LABEL_ONLY) || token.text.match?(Text::ANCHOR))
        }
        markers >= 2 || (markers == 1 && tokens.count { |token| component.contains_center?(token.box) } > 3)
      end

      small.select { |piece| piece.width >= 8 }.each do |piece|
        host = large.find { |picture|
          picture.overlap_x(piece) >= 0.5 * piece.width && (piece.y0 - picture.y1).between?(-2, 16)
        }
        next unless host

        large[large.index(host)] = Box.around([host, piece])
      end

      large
    end

    def parse_item(anchor, region, page)
      tokens = tokens_in(page, region).reject { |token| token.equal?(anchor.token) || token == anchor.token }
      pictures = stack(pictures_in(page, region, tokens), tokens)
      inside = tokens.select { |token|
        !token.text.match?(Text::LABEL_ONLY) && pictures.any? { |picture| picture.contains_center?(token.box) }
      }
      tokens -= inside
      tokens = tokens.reject { |token| Text.residue?(token.text) }
      item_rows = Rows.build(tokens)
      item_rows, conflicts = drop_shadows(item_rows)
      anchor_row_y = anchor.token.box

      labels = item_rows.flat_map { |row|
        row.words.select { |token| token.text.match?(Text::LABEL_ONLY) }.map { |token| [row, token] }
      }
      ordered = []
      labels.each do |row, token|
        letter = token.text[Text::LABEL_ONLY, 1]
        expected = ("A".ord + ordered.size).chr
        ordered << [row, token] if letter == expected
      end

      misprinted = false
      if ordered.size < labels.size &&
          labels.size.between?(3, 6) &&
          labels.each_cons(2).all? { |(row_a, a), (row_b, b)| ([row_a.y0, a.x0] <=> [row_b.y0, b.x0]) <= 0 } &&
          labels.map { |_, token| token.text }.uniq.size == labels.size -
          1
        ordered = labels
        misprinted = true
        @log <<
          "#{document.name} q#{anchor.number}: printed labels #{labels.map { |_, token| token.text }.join} read by position"
      end

      options = []
      block_end = anchor.token.y1
      ordered.each_with_index do |(row, token), index|
        next_in_row = ordered[(index + 1)..].find { |other_row, _| other_row.equal?(row) }
        limit = next_in_row ? next_in_row[1].x0 : Float::INFINITY
        text_tokens = row.words.select { |other|
          other.x0 >= token.x1 -
            1 &&
            other.x1 <= limit +
            1 &&
            !other.equal?(token) &&
            !other.text.match?(Text::LABEL_ONLY)
        }
        option_rows = [row]
        horizontal = ordered.count { |other_row, _| other_row.equal?(row) } > 1
        unless horizontal
          following = ordered[(index + 1)..].map(&:first).find { |other_row| other_row.y0 > row.y1 }
          stop = following ? following.y0 : Float::INFINITY
          previous = row
          item_rows.select { |candidate| candidate.y0 > row.y1 - 1 && candidate.y0 < stop - 1 }.each do |candidate|
            indent = text_tokens.first&.x0 || token.x1
            break unless candidate.x0 >= indent - 8 && candidate.y0 - previous.y1 < [previous.height, 12].max + 2
            break if candidate.words.any? { |other| other.text.match?(Text::LABEL_ONLY) }

            text_tokens += candidate.words
            option_rows << candidate
            previous = candidate
          end
        end

        block_end = [block_end, option_rows.map(&:y1).max].max
        options <<
          Option.new(
            letter: misprinted ? ("A".ord + index).chr : token.text[Text::LABEL_ONLY, 1],
            label: token,
            tokens: text_tokens,
            rows: option_rows,
            picture: nil
          )
      end

      used_rows = options.flat_map(&:rows).to_set
      first_label_top = ordered.first ? ordered.first[0].y0 : Float::INFINITY
      stem_rows = item_rows.reject { |row| used_rows.include?(row) }.select { |row|
        row.y0 < first_label_top - 1 || (ordered.empty? && row.y0 < anchor.token.y1 + 40)
      }
      stem_rows = stem_rows.select { |row| row.y0 <= anchor.token.y1 + 2 || stem_rows.any? }
      stem_rows = contiguous_from(stem_rows, anchor.token)
      stem_tokens = stem_rows.flat_map(&:words)
      block_end = [block_end, stem_rows.map(&:y1).max || 0].max

      with_text = options.any? { |option| option.tokens.any? }
      stem_pictures = []
      tail_pictures = []
      if options.empty? || with_text
        pictures.each { |picture|
          (picture.y0 < block_end + 6 || options.empty? ? stem_pictures : tail_pictures) << picture
        }
        if options.empty? && stem_pictures.size > 1
          stem_pictures = [Box.around(stem_pictures)]
        end
      else
        free = pictures.dup
        label_rows = ordered.map(&:first).uniq
        if label_rows.size == 1
          row_top = label_rows.first.y0
          columns = ordered.each_with_index.map do |(_row, token), index|
            from = index.zero? ? region.x0 : token.x0 - 3
            to = ordered[index + 1] ? ordered[index + 1][1].x0 - 3 : region.x1
            [from, to]
          end

          free = free.flat_map do |picture|
            cuts = columns.map(&:first).drop(1).select { |edge| edge > picture.x0 + 10 && edge < picture.x1 - 10 }
            next [picture] if cuts.empty? || picture.center_y < row_top

            edges = [picture.x0, *cuts, picture.x1]
            edges.each_cons(2).filter_map { |from, to|
              document.ink_box(page, Box.new(from, picture.y0, to, picture.y1))
            }
          end

          options = options.each_with_index.map do |option, index|
            from, to = columns[index]
            mine = free.select { |picture|
              picture.center_y > row_top && picture.center_x >= from && picture.center_x < to
            }
            free -= mine
            option.with(picture: Box.around(mine))
          end
        end

        options = options.map do |option|
          next option if option.picture

          candidates = free.select { |picture| picture.center_y > option.label.y0 && picture.y0 > option.label.y0 - 6 }
          chosen = candidates.min_by { |picture|
            (picture.y0 - option.label.y1).abs + (picture.center_x - (option.label.x0 + 40)).abs
          }
          free.delete(chosen) if chosen
          option.with(picture: chosen)
        end

        free = free.reject do |piece|
          index = options.index { |option|
            option.picture &&
              option.picture.overlap_x(piece) >= 0.5 *
              [piece.width, option.picture.width].min &&
              piece.y0 > option.label.y1 -
              2
          }
          next false unless index

          options[index] = options[index].with(picture: Box.around([options[index].picture, piece]))
          true
        end

        options = options.map do |option|
          next option unless option.picture

          covering = ordered.map(&:last).select { |label|
            label.box.overlap_x(option.picture) > 0 && label.y1 > option.picture.y0 && label.y1 < option.picture.y0 + 15
          }
          next option if covering.empty?

          trimmed = Box.new(option.picture.x0, covering.map(&:y1).max + 1, option.picture.x1, option.picture.y1)
          option.with(picture: document.ink_box(page, trimmed) || trimmed)
        end

        top = ordered.first[0].y0
        free.each { |picture| (picture.y1 <= top + 4 ? stem_pictures : tail_pictures) << picture }
        block_end = [block_end, options.filter_map(&:picture).map(&:y1).max || 0].max
      end

      used = used_rows + stem_rows.to_set
      tail_rows = item_rows.reject { |row| used.include?(row) }.select { |row| row.y0 > block_end - 2 }
      orphan_rows = item_rows.reject { |row| used.include?(row) } - tail_rows
      @log << "#{document.name} q#{anchor.number}: #{orphan_rows.size} unassigned rows" if orphan_rows.any?

      conflicts += [{misprint: true}] if misprinted
      item = Item.new(
        number: anchor.number,
        page: page,
        region: region,
        anchor: anchor.token,
        stem_tokens: stem_tokens,
        stem_rows: stem_rows,
        stem_pictures: stem_pictures,
        options: options,
        conflicts: conflicts,
        gaps: orphan_rows
      )
      [item, Content.new(rows: tail_rows, pictures: tail_pictures, page: page)]
    end

    def stack(pictures, tokens)
      labels = tokens.select { |token| token.text.match?(Text::LABEL_ONLY) }
      merged = pictures.sort_by(&:y0)
      loop do
        pair = merged.combination(2).find do |upper, lower|
          upper, lower = [upper, lower].sort_by(&:y0)
          gap = lower.y0 - upper.y1
          narrow = [upper.width, lower.width].min
          gap <= 12 &&
            upper.overlap_x(lower) >= 0.6 *
            narrow &&
            labels.none? { |label|
              label.y0 >= upper.y1 -
                2 &&
                label.y1 <= lower.y0 +
                2 &&
                label.box.overlap_x(Box.around([upper, lower])).positive?
            }
        end

        break unless pair

        merged = (merged - pair) + [Box.around(pair)]
      end

      merged
    end

    def contiguous_from(stem_rows, anchor)
      kept = []
      bottom = anchor.y1
      stem_rows.sort_by(&:y0).each do |row|
        break if row.y0 - bottom > [row.height, 14].max * 1.8 && kept.any?

        kept << row
        bottom = row.y1
      end

      kept
    end

    def drop_shadows(item_rows)
      conflicts = []
      shadows = []
      item_rows.each_cons(2) do |upper, lower|
        next unless lower.y0 - upper.y1 < 6 && (upper.x1 - upper.x0).positive?

        upper_text = plain(upper)
        lower_text = plain(lower)
        next if upper_text.size < 2 || lower_text.size < 2
        next if upper.words.any? { |token| token.text.match?(Text::LABEL_ONLY) || token.text.match?(Text::ANCHOR) }
        next unless (upper_text.size - lower_text.size).abs <= 2 && similarity(upper_text, lower_text) >= 0.6
        next unless upper.box.overlap_x(lower.box) > 0.7 * [upper.box.width, lower.box.width].min

        shadows << upper
        upper.words.each { |token| shadow_tokens << token }
        conflicts << {kept: lower_text, shadow: upper_text, row: lower} if upper_text != lower_text
      end

      [item_rows - shadows, conflicts]
    end

    def plain(row)
      row
        .words
        .reject { |token| token.text.match?(Text::LABEL_ONLY) }
        .map(&:text)
        .join
        .gsub(/[\s。，、！？.,!?]/, "")
    end

    def similarity(left, right)
      same = left.chars.zip(right.chars).count { |a, b| a == b }
      same.to_f / [left.size, right.size].max
    end
  end
end
