# frozen_string_literal: true

require "json"
require "open3"

root = File.expand_path("..", __dir__)
papers_dir = File.join(root, "data/tocfl_official/papers")
media_dir = File.join(root, "media/tocfl_official")
out = File.join(root, "data/huayu/tocfl_papers.json")

unless File.directory?(papers_dir)
  puts "no official papers under #{papers_dir}"
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

SETS = [
  {band: "Novice", set: 1, level: "Novice 1–2", audio: "mock_Novice_mp3_en",
   reading: "rd_mock_test_Novice_en_201811_t.pdf", listening: "ls_mock_test_Novice_en_201811_t.pdf",
   transcript: "ls_mock_test_Novice_listen.pdf", key: "mock_test_Novice_answer.pdf", combined: true},
  {band: "A", set: 1, level: "A1–A2", audio: "mock_BandA_mp3_en",
   reading: "rd_mock_test_BandA_en_t.pdf", reading_key: "rd_mock_test_BandA_answer.pdf",
   listening: "ls_mock_test_BandA_en_t.pdf", listening_key: "ls_mock_test_BandA_answer.pdf",
   transcript: "ls_mock_test_BandA_listen.pdf"},
  {band: "A", set: 2, level: "A1–A2", audio: "mock2_BandA_mp3_en",
   reading: "rd_mock2_test_BandA_en_t.pdf", reading_key: "rd_mock2_test_BandA_answer.pdf",
   listening: "ls_mock2_test_BandA_en_t.pdf", listening_key: "ls_mock2_test_BandA_answer.pdf",
   transcript: "ls_mock2_test_BandA_listen.pdf"},
  {band: "A", set: 3, level: "A1–A2", audio: "mock3_BandA_mp3_en",
   reading: "rd_mock3_test_BandA_en_t.pdf", reading_key: "rd_mock3_test_BandA_answer.pdf",
   listening: "ls_mock3_test_BandA_en_t.pdf", listening_key: "ls_mock3_test_BandA_answer.pdf",
   transcript: "ls_mock3_test_BandA_listen.pdf"},
  {band: "A", set: 4, level: "A1–A2", audio: "mock4_BandA_mp3_en",
   reading: "rd_mock4_test_BandA_en_t.pdf", reading_key: "rd_mock4_test_BandA_answer.pdf",
   listening: "ls_mock4_test_BandA_en_t.pdf", listening_key: "ls_mock4_test_BandA_answer.pdf",
   transcript: "ls_mock4_test_BandA_listen.pdf"},
  {band: "A", set: 5, level: "A1–A2", audio: "mock5_BandA_mp3_en",
   reading: "rd_mock5_test_BandA_en_t.pdf", reading_key: "rd_mock5_test_BandA_answer.pdf",
   listening: "ls_mock5_test_BandA_en_t.pdf", listening_key: "ls_mock5_test_BandA_answer.pdf",
   transcript: "ls_mock5_test_BandA_listen.pdf"},
  {band: "B", set: 1, level: "B1–B2", audio: "mock_BandB_mp3",
   reading: "rd_mock_test_BandB_t.pdf", reading_key: "rd_mock_test_BandB_answer.pdf",
   listening: "ls_mock_test_BandB_t.pdf", listening_key: "ls_mock_test_BandB_answer.pdf",
   transcript: "ls_mock_test_BandB_listen.pdf"},
  {band: "B", set: 2, level: "B1–B2", audio: "mock2_BandB_mp3",
   reading: "rd_mock2_test_BandB_t.pdf", reading_key: "rd_mock2_test_BandB_answer_t.pdf",
   listening: "ls_mock2_test_BandB_t.pdf", listening_key: "ls_mock2_test_BandB_answer.pdf",
   transcript: "ls_mock2_test_BandB_listen.pdf"},
  {band: "B", set: 3, level: "B1–B2", audio: "mock3_BandB_mp3",
   reading: "rd_mock3_test_BandB_t.pdf", reading_key: "rd_mock3_test_BandB_answer.pdf",
   listening: "ls_mock3_test_BandB_t.pdf", listening_key: "ls_mock3_test_BandB_answer.pdf",
   transcript: "ls_mock3_test_BandB_listen.pdf"},
  {band: "B", set: 4, level: "B1–B2", audio: "mock4_BandB_mp3",
   reading: "rd_mock4_test_BandB_t.pdf", reading_key: "rd_mock4_test_BandB_answer.pdf",
   listening: "ls_mock4_test_BandB_t.pdf", listening_key: "ls_mock4_test_BandB_answer.pdf",
   transcript: "ls_mock4_test_BandB_listen.pdf"},
  {band: "B", set: 5, level: "B1–B2", audio: "mock5_BandB_mp3",
   reading: "rd_mock5_test_BandB_t.pdf", reading_key: "rd_mock5_test_BandB_answer.pdf",
   listening: "ls_mock5_test_BandB_t.pdf", listening_key: "ls_mock5_test_BandB_answer.pdf",
   transcript: "ls_mock5_test_BandB_listen.pdf"}
].freeze

OPTION_LINE = /\A\s*[(（]\s*([A-F])\s*[)）]\s*(.*)\z/
QUESTION_LINE = /\A\s*(\d{1,3})\s*[.．]\s*(.*)\z/
PASSAGE_MARK = /\A\s*[(（]\s*[一二三四五六七八九十]\s*[)）]\s*\z/
BOILERPLATE = /第\s*[一二三四五六七八九]\s*部分|Part\s+\d|例題|作答|測驗|Page|TOCFL|華語文能力測驗/
GAP_MARK = /[　\s]{4,}|＿|_{2,}/
MIN_CONTEXT = 40

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

papers = []
SETS.each do |entry|
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

    items = skill == "reading" ? certain_items.call("#{slug_base}-#{skill}", paper, answers) : []

    papers << {
      "slug" => "#{slug_base}-#{skill}",
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
      "items" => items
    }.compact
  end
end

File.write(out, "#{JSON.pretty_generate({"papers" => papers})}\n")

puts "papers: #{papers.size}, questions: #{papers.sum { |paper| paper["count"] }}"
puts "questions rendered as interactive items: #{papers.sum { |paper| paper["items"].size }}"
puts "papers dropped for untrustworthy layout: #{dropped_papers.join(", ").presence || "none"}"
papers.group_by { |paper| paper["band"] }.each do |band, rows|
  puts "  band #{band}: #{rows.size} papers, #{rows.sum { |paper| paper["count"] }} questions, #{rows.sum { |paper| paper["clips"].size }} clips"
end
puts "numbering repaired: #{repaired.size}"
repaired.first(10).each { |line| puts "  #{line}" }
