# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "set"

require_relative "lib/tocfl/audio"
require_relative "lib/tocfl/bundle"
require_relative "lib/tocfl/catalog"
require_relative "lib/tocfl/cover"
require_relative "lib/tocfl/scale"

root = File.expand_path("..", __dir__)
papers_dir = File.join(root, "data/tocfl_official/papers")
media_dir = File.join(root, "media/tocfl_official")
bundles_dir = File.join(root, "data/tocfl_official/bundles")
out = File.join(root, "data/huayu/tocfl_papers.json")
only = ARGV.reject { |arg| arg.start_with?("--") }.to_set
skip_bundles = ARGV.include?("--keys-only")
write_index = ARGV.include?("--write-index")

unless File.directory?(papers_dir)
  puts("no official papers under #{papers_dir}")
  exit
end

text_of = lambda do |file|
  path = File.join(papers_dir, file)
  return nil unless File.exist?(path)

  stdout, _stderr, status = Open3.capture3("pdftotext", "-layout", path, "-")
  status.success? ? stdout : nil
end

pairs_in = lambda do |text|
  text.to_s.scan(/(?<!\d)(\d{1,3})\s+([A-F])(?![A-Za-z])/).map { |number, letter| [number.to_i, letter] }
end

repaired = []
sequence = lambda do |pairs, label|
  answers = {}
  pairs.each_with_index do |(number, letter), index|
    expected = index + 1
    if number != expected
      repaired << "#{label}: printed #{number} at position #{expected}"
      number = expected
    end

    answers[number.to_s] = letter
  end

  answers
end

OPTION_LINE = /\A\s*[(（]\s*([A-F])\s*[)）]\s*(.*)\z/
QUESTION_LINE = /\A\s*(\d{1,3})\s*[.．]\s*(.*)\z/
PASSAGE_MARK = /\A\s*[(（]\s*[一二三四五六七八九十]\s*[)）]\s*\z/
BOILERPLATE = /第\s*[一二三四五六七八九]\s*部分|Part\s+\d|例題|作答|測驗|Page|TOCFL|華語文能力測驗/
GAP_MARK = /[　\s]{4,}|＿|_{2,}/

parse_items = lambda do |file|
  path = File.join(papers_dir, file)
  return [] unless File.exist?(path)

  stdout, _stderr, status = Open3.capture3("pdftotext", "-layout", path, "-")
  return [] unless status.success?

  items = []
  context = []
  pending = []
  current = nil
  after_options = false

  stdout.split("\n").each do |line|
    stripped = line.strip

    if (match = QUESTION_LINE.match(line))
      items << current if current
      context = pending.dup if pending.any?
      pending = []
      current = {"number" => match[1].to_i, "stem" => match[2].strip, "options" => {}, "context" => context.join("\n")}
      after_options = false
      next
    end

    if (match = OPTION_LINE.match(line))
      current["options"][match[1]] = match[2].strip if current
      after_options = true
      next
    end

    next if stripped.empty? || stripped.match?(BOILERPLATE)

    if PASSAGE_MARK.match?(stripped)
      pending = []
      context = []
      next
    end

    if current.nil? || after_options
      pending << stripped
    elsif current["options"].empty?
      current["stem"] = "#{current["stem"]} #{stripped}".strip
    end
  end

  items << current if current
  items
end

mangled = lambda do |item|
  stem = item["stem"].to_s.strip
  half = stem.length / 2
  return true if half >= 8 && stem[0, half].strip == stem[-half..].to_s.strip

  item["options"].values.uniq.size != item["options"].size
end

dropped_papers = []
certain_items = lambda do |slug, file, answers|
  parsed = parse_items.call(file)
  wanted = parsed.select do |item|
    letter = answers[item["number"].to_s]
    next false if letter.nil?
    next false unless item["options"].key?(letter)

    letters = item["options"].keys.sort
    next false unless [3, 4].include?(letters.size)
    next false unless letters == %w[A B C D].first(letters.size)
    next false unless item["options"].values.all? { |value| value.length.between?(2, 40) }
    next false unless item["stem"].length.between?(6, 80)

    item["stem"].match?(GAP_MARK)
  end

  wanted.each { |item| item.delete("context") }

  if wanted.any?(&mangled)
    dropped_papers << slug
    return []
  end

  wanted
end

clips_for = lambda do |folder|
  return [] if folder.nil?

  path = File.join(media_dir, folder)
  return [] unless File.directory?(path)

  Dir.glob(File.join(path, "**", "*.mp3")).map { |file| file.delete_prefix("#{path}/") }.sort
end

scales = Tocfl::Scale.new(papers_dir).load
papers = []
reports = []
Tocfl::Catalog.sets.each do |entry|
  band = entry[:band]
  slug_base = "#{band.downcase}-set#{entry[:set]}"

  keys = {}
  if entry[:combined]
    text = text_of.call(entry[:key])
    if text
      listening_part, reading_part = text.split(/二、[^\n]*閱讀/, 2)
      keys["listening"] = sequence.call(pairs_in.call(listening_part), "#{slug_base} listening")
      keys["reading"] = sequence.call(pairs_in.call(reading_part), "#{slug_base} reading")
    end
  else
    keys["reading"] = sequence.call(pairs_in.call(text_of.call(entry[:reading_key])), "#{slug_base} reading")
    keys["listening"] = sequence.call(pairs_in.call(text_of.call(entry[:listening_key])), "#{slug_base} listening")
  end

  %w[reading listening].each do |skill|
    answers = keys[skill] || {}
    next if answers.empty?

    paper = entry[skill.to_sym]
    next unless File.exist?(File.join(papers_dir, paper))

    slug = "#{slug_base}-#{skill}"
    items = skill == "reading" ? certain_items.call(slug, paper, answers) : []
    bundle_file = File.join(bundles_dir, slug, "bundle.json")

    if !skip_bundles && (only.empty? || only.include?(slug))
      editions = (entry[:editions] || {}).filter_map do |code, edition|
        file = edition[skill.to_sym]
        next unless File.exist?(File.join(papers_dir, file))

        {code: code, paper: file, audio: skill == "listening" ? edition[:audio] : nil}
      end

      spec = {
        slug: slug,
        band: band,
        set: entry[:set],
        skill: skill,
        paper: paper,
        transcript: skill == "listening" ? entry[:transcript] : nil,
        audio: skill == "listening" ? entry[:audio] : nil,
        answers: answers,
        levels: Tocfl::Catalog::LEVELS[band],
        minutes: Tocfl::Cover.minutes(Tocfl::Document.new(File.join(papers_dir, paper))),
        scale: scales.for(band, skill, entry[:set]),
        editions: editions
      }
      begin
        reports <<
          Tocfl::Bundle.new(spec, papers_dir: papers_dir, media_dir: media_dir, out_dir: bundles_dir).build.report
      rescue StandardError => error
        FileUtils.rm_rf(File.join(bundles_dir, ".#{slug}.building"))
        reports <<
          {
            slug: slug,
            problems: ["build failed: #{error.class}: #{error.message} at #{error.backtrace.first}"],
            notes: [],
            text_items: 0,
            image_items: 0,
            images: 0,
            image_bytes: 0
          }
      end
    end

    papers <<
      {
        "slug" => slug,
        "band" => band,
        "set" => entry[:set],
        "level" => entry[:level],
        "skill" => skill,
        "paper" => paper,
        "transcript" => (skill == "listening" ? entry[:transcript] : nil),
        "audio" => (skill == "listening" ? entry[:audio] : nil),
        "clips" => (skill == "listening" ? clips_for.call(entry[:audio]) : []),
        "answers" => answers,
        "count" => answers.size,
        "items" => items,
        "bundle" => (File.exist?(bundle_file) ? "tocfl_official/bundles/#{slug}/bundle.json" : nil)
      }.compact
  end
end

Tocfl::Audio.save

if write_index
  File.write(out, "#{JSON.pretty_generate({"papers" => papers})}\n")
  puts("wrote #{out}")
end

puts("papers: #{papers.size}, questions: #{papers.sum { |paper| paper["count"] }}")
puts("questions rendered as interactive items: #{papers.sum { |paper| paper["items"].size }}")
puts("papers dropped for untrustworthy layout: #{dropped_papers.empty? ? "none" : dropped_papers.join(", ")}")
papers.group_by { |paper| paper["band"] }.each do |band, rows|
  puts(
    "  band #{band}: #{rows.size} papers, #{rows.sum { |paper| paper["count"] }} questions, #{rows.sum { |paper| paper["clips"].size }} clips"
  )
end

puts("numbering repaired: #{repaired.size}")
repaired.first(10).each { |line| puts("  #{line}") }

reports.each do |report|
  puts(
    format(
      "%-22s text %3d  image-only %3d  pictures %3d  images %4d  %7.1f KB  editions %7.1f KB",
      report[:slug],
      report[:text_items],
      report[:image_items],
      report[:picture_items].to_i,
      report[:images],
      report[:image_bytes] / 1024.0,
      report[:image_bytes_editions].to_i / 1024.0
    )
  )
  puts("    image-only: #{report[:withheld].join(" ")}") if report[:withheld]&.any?
  report[:notes].each { |note| puts("    · #{note}") }
  report[:problems].first(12).each { |problem| puts("    ! #{problem}") }
  puts("    ! … #{report[:problems].size - 12} more") if report[:problems].size > 12
end
