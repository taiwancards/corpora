# frozen_string_literal: true

ROOT = Rails.root
SOURCE = ROOT.join("data/huayu/moe4808.json")
LOOKUP = ROOT.join("storage/json/cangjie5.json")
TARGET = ROOT.join("data/huayu/cangjie_index.json")

TBCL_GRADE = /第(\d)\*?級/

def codes
  raw = JSON.parse(LOOKUP.read)
  first = {}
  raw.each { |code, chars| chars.each { |char| first[char] ||= code } }
  first.to_h { |char, code| [char, Huayu::Cangjie.canonical(char, code)] }
end

def rows(list, first)
  facts = Lexeme.where(kind: :character, text: list).pluck(
    :text,
    Arel.sql("data->>'freq_rank'"),
    Arel.sql("data->>'tocfl_level'"),
    Arel.sql("data->>'tbcl_level'")
  )
  facts = facts.to_h { |text, rank, tocfl, tbcl| [text, [rank&.to_i, tocfl, tbcl&.[](TBCL_GRADE, 1)&.to_i]] }

  list.each_with_index.filter_map do |char, position|
    code = first[char]
    next if code.nil?

    rank, tocfl, tbcl = facts[char]
    {"char" => char, "code" => code, "rank" => rank, "level" => tocfl, "tbcl" => tbcl, "order" => position}
  end
end

def sorted(rows)
  rows.sort_by { |row| [row["rank"] || Float::INFINITY, row["tbcl"] || 9, row["order"]] }
end

list = JSON.parse(SOURCE.read)
first = codes
index = sorted(rows(list, first)).group_by { |row| row["code"][0] }
index = index.sort.to_h.transform_values { |group| group.map { |row| row.except("order") } }

TARGET.write("#{JSON.pretty_generate(index)}\n")
puts("#{index.values.sum(&:size)} characters across #{index.size} keys -> #{TARGET}")
puts(index.map { |key, group| "#{key}:#{group.size}" }.join(" "))
