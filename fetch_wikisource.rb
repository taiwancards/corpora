#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/http"

API = Corpus.source("WIKISOURCE_API_URL")
AGENT = Corpus.user_agent
AUTHORS = %w[賴和 楊華 張我軍 呂赫若 鍾理和].freeze
KEEP_SECTIONS = /小說|新詩|散文|雜文|隨筆|評論|論說|書信|白話/
SKIP_SECTIONS = /漢詩|古典|舊體|傳統詩|日文|翻譯/
LINK = /\[\[([^\]|#]+)(?:[|#][^\]]*)?\]\]/
HEADING = /\A=+[[:space:]]*(.*?)[[:space:]]*=+\z/
SKIP_PREFIXES = ["Author:", "作者:", "File:", "Category:", ":"].freeze

def out_dir = Corpus.corpora("wikisource")

def api(params) = Http.json(Http.query(API, params.merge(format: "json")), headers: AGENT)

def wikitext(title) = api(action: "parse", page: title, prop: "wikitext").dig("parse", "wikitext", "*")

def works_of(author)
  text = wikitext("Author:#{author}")
  return Corpus.say("#{author}: no author page") || [] if text.nil?

  works = []
  keep = false

  text.split("\n").each do |line|
    heading = line.match(HEADING)
    if heading
      title = heading[1]
      keep = title.match?(KEEP_SECTIONS) && !title.match?(SKIP_SECTIONS)
      next
    end

    next unless keep

    line.scan(LINK).flatten.each do |raw|
      link = Corpus.strip(raw)
      next if SKIP_PREFIXES.any? { |prefix| link.start_with?(prefix) }

      works << link
    end
  end

  works.uniq
end

out_dir.mkpath
manifest = {}

AUTHORS.each do |author|
  titles = works_of(author)
  Corpus.say("#{author}: #{titles.length} works in vernacular sections")
  fetched = []

  titles.each do |title|
    path = out_dir.join("#{author}__#{title.gsub(%r{[/\\[[:space:]]]+}, "_")}.txt")

    unless path.exist?
      body = begin
        wikitext(title)
      rescue StandardError => error
        Corpus.say("  #{title}: FAIL #{error.class}: #{error.message}")
        next
      end

      next Corpus.say("  #{title}: no text (red link)") if body.nil?

      path.write(body)
      sleep(3)
    end

    fetched << title
  end

  manifest[author] = fetched
end

Corpus.write_json(out_dir.join("manifest.json"), manifest, pretty: true)
Corpus.say("works downloaded: #{manifest.each_value.sum(&:length)}")
