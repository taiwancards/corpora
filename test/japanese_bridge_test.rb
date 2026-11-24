# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/japanese_bridge"

class JapaneseBridgeTest < Minitest::Test
  def forms
    JapaneseBridge::Forms.new(
      joyo: %w[学 戦 単 説 衆 区 欧 内],
      jinmei: %w[裡],
      jinmei_old: {"戰" => "戦"},
      new_variants: {"學" => "学"},
      opencc: {"單" => "単", "區" => "区", "內" => "内"},
      z_variants: {"說" => ["説"]},
      taiwan: {"眾" => "衆"}
    )
  end

  def test_kana_splits_small_kana_into_the_previous_mora
    assert_equal(%w[キョ ウ], JapaneseBridge::Kana.morae("キョウ"))
  end

  def test_kana_classifies_endings
    {
      "サン" => "n",
      "ガク" => "k",
      "シキ" => "k",
      "イチ" => "t",
      "ジツ" => "t",
      "ジョウ" => "you",
      "コウ" => "ou",
      "ヨウ" => "you",
      "シュウ" => "yuu",
      "ユウ" => "yuu",
      "クウ" => "uu",
      "セイ" => "ei",
      "カイ" => "ai",
      "スイ" => "ui"
    }.each { |reading, ending| assert_equal(ending, JapaneseBridge::Kana.ending(reading), reading) }
  end

  def test_kana_leaves_single_morae_and_plain_vowels_unclassified
    %w[キ チ ク カ バ ショ].each { |reading| assert_nil(JapaneseBridge::Kana.ending(reading), reading) }
  end

  def test_kana_rows_and_subrows
    assert_equal("カ", JapaneseBridge::Kana.row("キョウ"))
    assert_equal("ザ", JapaneseBridge::Kana.row("ジン"))
    assert_equal("ジ", JapaneseBridge::Kana.subrow("ジョウ"))
    assert_nil(JapaneseBridge::Kana.subrow("ザツ"))
  end

  def test_onyomi_keeps_only_katakana
    assert_equal(%w[ガク カク], JapaneseBridge::Kana.onyomi("ガク カク まなぶ"))
  end

  def test_zhuyin_parses_tone_initial_and_coda
    assert_equal(2, JapaneseBridge::Zhuyin.tone("ㄒㄩㄝˊ"))
    assert_equal(1, JapaneseBridge::Zhuyin.tone("ㄕㄢ"))
    assert_equal(0, JapaneseBridge::Zhuyin.tone("˙ㄇㄣ"))
    assert_equal("x", JapaneseBridge::Zhuyin.initial("ㄒㄧㄥ"))
    assert_equal("", JapaneseBridge::Zhuyin.initial("ㄧ"))
    assert_equal("ng", JapaneseBridge::Zhuyin.coda("ㄒㄧㄥ"))
    assert_equal("n", JapaneseBridge::Zhuyin.coda("ㄕㄢ"))
    assert_equal("open", JapaneseBridge::Zhuyin.coda("ㄍㄨㄛˊ"))
    assert_equal("er", JapaneseBridge::Zhuyin.coda("ㄦˋ"))
  end

  def test_forms_resolve_each_relation
    assert_equal(["学", "same"], forms.counterpart("学"))
    assert_equal(["裡", "same"], forms.counterpart("裡"))
    assert_equal(["学", "differs"], forms.counterpart("學"))
    assert_equal(["戦", "differs"], forms.counterpart("戰"))
    assert_equal(["説", "differs"], forms.counterpart("說"))
    assert_equal(["衆", "differs"], forms.counterpart("眾"))
    assert_equal([nil, "unused"], forms.counterpart("她"))
    assert_equal([nil, "unused"], forms.counterpart("們"))
  end

  def test_multiset_difference_counts_repeats
    assert_equal(%w[a], JapaneseBridge::Multiset.difference(%w[a a b], %w[a b]))
    assert(JapaneseBridge::Multiset.subset?(%w[a a], %w[a a c]))
    refute(JapaneseBridge::Multiset.subset?(%w[a a], %w[a c]))
  end

  def patterns
    components = {
      "單" => %w[DAN],
      "単" => %w[v w x y],
      "戰" => %w[DAN GE],
      "戦" => %w[v w x y GE],
      "彈" => %w[GONG DAN],
      "弾" => %w[GONG v w x y],
      "區" => %w[BOX K K K],
      "区" => %w[BOX X],
      "品" => %w[K K K],
      "歐" => %w[BOX K K K QIAN],
      "欧" => %w[BOX X QIAN],
      "驅" => %w[MA BOX K K K],
      "駆" => %w[MA BOX2 X],
      "臺" => %w[T1 T2],
      "台" => %w[S1]
    }
    parts = {
      "戰" => %w[單 戈],
      "彈" => %w[弓 單],
      "區" => %w[匚 品],
      "歐" => %w[區 欠],
      "驅" => %w[馬 區]
    }
    pairs = {
      "單" => "単",
      "戰" => "戦",
      "彈" => "弾",
      "區" => "区",
      "歐" => "欧",
      "驅" => "駆",
      "臺" => "台"
    }
    JapaneseBridge::Patterns.new(pairs:, components:, parts:, strokes: {}, counterpart: pairs.method(:[]))
  end

  def test_patterns_group_pairs_by_the_component_that_changes
    groups = patterns.groups

    assert_equal(%w[單 彈 戰].sort, groups["單"].sort)
    assert_equal(%w[區 歐 驅].sort, groups["區"].sort)
    assert_equal(%w[臺], groups["臺"])
  end

  def test_patterns_skip_singletons
    ids = patterns.patterns.map { |pattern| pattern["id"] }

    assert_equal(%w[區 單], ids.sort)
    assert_equal("単", patterns.patterns.find { |pattern| pattern["id"] == "單" }["to"])
  end

  def test_patterns_group_by_a_part_that_has_no_japanese_form_of_its_own
    bridge = JapaneseBridge::Patterns.new(
      pairs: {"經" => "経", "輕" => "軽"},
      components: {
        "經" => %w[SI A B C],
        "経" => %w[SI X Y],
        "輕" => %w[CHE A B C],
        "軽" => %w[CHE X Y],
        "巠" => %w[A B C]
      },
      parts: {"經" => %w[糸 巠], "輕" => %w[車 巠]}
    )
    pattern = bridge.patterns.first

    assert_equal("巠", pattern["id"])
    assert_nil(pattern["to"])
    assert_equal(%w[經 輕], pattern["members"].sort)
  end

  def test_small_print_needs_close_strokes_and_few_parts
    bridge = JapaneseBridge::Patterns.new(
      pairs: {"說" => "説", "學" => "学"},
      components: {"說" => %w[a b c], "説" => %w[a d c], "學" => %w[p q q r s], "学" => %w[x x y r s]},
      parts: {},
      strokes: {"說" => 14, "説" => 14, "學" => 16, "学" => 8}
    )

    assert(bridge.small?("說", "説"))
    refute(bridge.small?("學", "学"))
  end

  def row(char, on, zhuyin, rank = 1)
    JapaneseBridge::Correspondence::Row.new(char:, on:, zhuyin:, pinyin: "", rank:)
  end

  def test_correspondence_measures_endings_against_the_headline_reading
    rows = [
      row("山", "サン", "ㄕㄢ"),
      row("新", "シン", "ㄒㄧㄣ"),
      row("朋", "ホウ", "ㄆㄥˊ"),
      row("品", "ヒン", "ㄆㄧㄣˇ"),
      row("凡", "ボン", "ㄈㄢˊ"),
      row("登", "トン", "ㄉㄥ", 9)
    ]
    ending = JapaneseBridge::Correspondence.new(rows).endings.find { |item| item["ending"] == "n" }

    assert_equal(5, ending["total"])
    assert_equal(4, ending["hits"])
    assert_in_delta(0.8, ending["reliability"])
    assert_equal(%w[登], ending["exceptions"].map { |item| item["char"] })
  end

  def test_correspondence_splits_nasal_finals_by_the_onyomi_cue
    rows = [
      row("山", "サン", "ㄕㄢ"),
      row("上", "ジョウ", "ㄕㄤˋ"),
      row("星", "セイ", "ㄒㄧㄥ"),
      row("瓶", "ビン", "ㄆㄧㄥˊ"),
      row("小", "ショウ", "ㄒㄧㄠˇ")
    ]
    nasals = JapaneseBridge::Correspondence.new(rows).nasals

    assert_equal(
      {"total" => 2, "codas" => {"n" => 1, "ng" => 1}, "reliability" => 0.5},
      nasals["n"].except("exceptions")
    )
    assert_equal(1.0, nasals["long"]["reliability"])
    assert_equal(2, nasals["long"]["total"])
  end

  def test_correspondence_counts_initial_groups_per_row
    rows = [
      row("家", "カ", "ㄐㄧㄚ"),
      row("下", "カ", "ㄒㄧㄚˋ"),
      row("個", "コ", "ㄍㄜˋ"),
      row("人", "ジン", "ㄖㄣˊ")
    ]
    initials = JapaneseBridge::Correspondence.new(rows).initials.to_h { |item| [item["row"], item] }

    assert_equal({"jqx" => 2, "gkh" => 1}, initials["カ"]["groups"])
    assert_equal({"r" => 1}, initials["ジ…"]["groups"])
  end

  def test_correspondence_drops_rows_without_a_usable_reading
    rows = [row("們", "モン", "˙ㄇㄣ"), row("x", "まなぶ", "ㄒㄩㄝˊ"), row("y", "ガク", "")]

    assert_equal(%w[們], JapaneseBridge::Correspondence.new(rows).rows.map(&:char))
  end
end
