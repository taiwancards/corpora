#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/bigram_model"

cases = BigramModel.gold_cases
words, = Segmenter.vocabulary(Corpus.corpora("segvocab.json"))
limit = Segmenter.max_word(words)
unigram = BigramModel.unigram_model(limit)
model = BigramModel.load

BigramModel.report("unigram", cases) { |text| Segmenter.segment(text, words, unigram) }

best = nil
(0..32).each do |step|
  penalty = step * 0.25
  exact, average = BigramModel.report(format("bigram λ=%5.2f", penalty), cases) { |text|
    BigramModel.viterbi(text, words, model, limit, penalty)
  }
  best = [penalty, exact, average] if best.nil? || ([average, exact] <=> [best[2], best[1]]).positive?
end

penalty, exact, average = best
Corpus.say("")
Corpus.say(format("best penalty λ = %.2f: exact %d/%d, F1 %.4f", penalty, exact, cases.length, average))

if ENV["SHOW_ERRORS"]
  cases.each do |kase|
    pieces = BigramModel.viterbi(kase["text"], words, model, limit, penalty)
    next if pieces == kase["gold"]

    Corpus.say(format("  %-22s gold %-34s model %s", kase["text"], kase["gold"].join("/"), pieces.join("/")))
  end
end
