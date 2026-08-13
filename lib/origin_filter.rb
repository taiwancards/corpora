# frozen_string_literal: true

require "twfilter"

require_relative "corpus"

module OriginFilter
  POLICY = TWFilter::Policy.new(han_range: (1..Float::INFINITY), min_han_ratio: 0.0, max_tier: :rare)
  CHECKS = [TWFilter::Checks::Script, TWFilter::Checks::Lexicon, TWFilter::Checks::Erhua, TWFilter::Checks::Wenyan].freeze

  Verdict = Data.define(:ok, :reasons, :taiwan_markers, :han, :wenyan_density) do
    def ok? = ok
  end

  module_function

  def han_length(text) = TWFilter::Han.count(text)

  def evidence(text) = TWFilter::Evidence.count(text)

  def simplified = TWFilter::Checks::Script.simplified_only

  def china_hits(text)
    exceptions = TWFilter::Checks::Lexicon.exceptions
    (TWFilter::Checks::Lexicon.hard_terms.keys + TWFilter::Checks::Lexicon.soft_terms.keys).select do |term|
      allowed = exceptions[term]
      (allowed ? allowed.reduce(text) { |memo, form| memo.gsub(form, "") } : text).include?(term)
    end
  end

  def foreign_hits(text) = TWFilter::Checks::Lexicon.foreign_topics.select { |term|
    TWFilter::Checks::Lexicon.topic?(text, term)
  }

  def inspect_text(text)
    subject = TWFilter::Subject.new(text, policy: POLICY)
    findings = CHECKS.flat_map { |check| check.call(subject) }

    Verdict.new(
      ok: findings.none?(&:reject?),
      reasons: findings.select(&:reject?).map { |finding| [finding.code, finding.detail].compact.join(": ") },
      taiwan_markers: TWFilter::Evidence.markers(subject.text),
      han: subject.han,
      wenyan_density: TWFilter::Checks::Wenyan.density(subject)
    )
  end

  def keep?(text) = inspect_text(text).ok
end
