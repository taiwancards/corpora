#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/sentences"
require_relative "lib/registers"
require_relative "lib/http"
require_relative "lib/python_random"

include(Sentences)

SITEMAP = Corpus.source("VOCUS_SITEMAP_URL")
AGENT = Corpus.user_agent
PAUSE = Float(ENV.fetch("VOCUS_PAUSE", "1.2"))

PARAGRAPH = %r{<p[^>]*>(.*?)</p>}m
TAG = /<[^>]+>/
LITERARY = /小說|散文|文學|創作|故事|隨筆|詩|極短篇|日記|回憶/
SITEMAP_LINK = %r{<loc>([^<]+/sitemap-articles-\d+\.xml)</loc>}
ARTICLE_LINK = %r{<loc>([^<]+/article/[a-f0-9]+)</loc>}
TAG_LINK = %r{/tags/([^"?]+)}

def get(url, retries: 3)
  Http.get(url, headers: AGENT, retries: retries)
rescue Net::HTTPClientException => error
  return nil if %w[404 410].include?(error.response.code)

  nil
rescue StandardError
  nil
end

def article_urls(limit)
  index = get(SITEMAP).to_s
  maps = index.scan(SITEMAP_LINK).flatten
  return [] if maps.empty?

  random = Corpus::PythonRandom.new(Integer(ENV.fetch("VOCUS_SEED", "20260724")))
  random.shuffle!(maps)

  urls = []
  maps.each do |sitemap|
    body = get(sitemap)
    next if body.nil?

    found = body.scan(ARTICLE_LINK).flatten
    random.shuffle!(found)
    urls.concat(found)
    Corpus.say("  #{sitemap.split("/").last}: #{found.length}, total #{urls.length}")
    break if urls.length >= limit
  end

  urls.first(limit)
end

def article_text(html)
  literary = html.scan(TAG_LINK).flatten.join(" ").match?(LITERARY)

  pieces = html.scan(PARAGRAPH).flatten.filter_map { |block|
    text = Corpus.strip(block.gsub(TAG, "").gsub("&nbsp;", " "))
    text if text.length > 10
  }

  [pieces, literary]
end

def sentences_of(paragraphs)
  paragraphs.flat_map { |paragraph|
    TWFilter::Sentences.split(paragraph).filter_map { |piece|
      text = Corpus.strip(piece)
      text if !text.empty? && shaped?(text)
    }
  }
end

def existing(slug)
  path = Sentences.out_dir.join("#{slug}.json")
  path.exist? ? Corpus.read_json(path) : []
end

slug = ENV.fetch("VOCUS_SLUG", "vocus_prose")
target = Integer(ENV.fetch("VOCUS_CHARS", "3200000"))
scan = Integer(ENV.fetch("VOCUS_SCAN", "6000"))
checkpoint = Integer(ENV.fetch("VOCUS_CHECKPOINT", "200"))

urls = article_urls(scan)
Corpus.say("articles to walk: #{urls.length}")

out = existing(slug)
seen = out.to_set
chars = out.sum(&:length)
kept = literary_kept = 0
Corpus.say("already collected: #{out.length} sentences, #{chars} characters")

urls.each_with_index do |url, position|
  html = get(url)
  sleep(PAUSE)
  next if html.nil?

  paragraphs, literary = article_text(html)
  accepted = Registers.judge(sentences_of(paragraphs))
  next if accepted.empty?

  kept += 1
  literary_kept += 1 if literary

  accepted.each do |text|
    next unless seen.add?(text)

    out << text
    chars += text.length
  end

  if ((position + 1) % checkpoint).zero?
    write(slug, out)
    Corpus.say("  #{position + 1}/#{urls.length} articles, kept #{kept}, sentences #{out.length}, characters #{chars}")
  end

  break if chars >= target
end

Corpus.say("articles kept #{kept}, of them literary-tagged #{literary_kept}")
write(slug, out)
