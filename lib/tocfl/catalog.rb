# frozen_string_literal: true

module Tocfl
  module Catalog
    LEVELS = {
      "Novice" => ["Novice 1", "Novice 2"],
      "A" => ["Level 1", "Level 2"],
      "B" => ["Level 3", "Level 4"],
      "C" => ["Level 5", "Level 6"]
    }.freeze
    LEVEL_LABEL = {"Novice" => "Novice 1–2", "A" => "A1–A2", "B" => "B1–B2", "C" => "C1–C2"}.freeze
    EDITION_TAGS = {"en" => "en", "vi" => "vie", "id" => "id", "ja" => "ja", "de" => "ger"}.freeze

    module_function

    def prefix(set) = set == 1 ? "mock" : "mock#{set}"

    def sets
      novice = {
        band: "Novice",
        set: 1,
        level: LEVEL_LABEL["Novice"],
        audio: "mock_Novice_mp3_en",
        reading: "rd_mock_test_Novice_en_201811_t.pdf",
        listening: "ls_mock_test_Novice_en_201811_t.pdf",
        transcript: "ls_mock_test_Novice_listen.pdf",
        key: "mock_test_Novice_answer.pdf",
        combined: true,
        editions: EDITION_TAGS.to_h do |code, tag|
          suffix = code == "id" ? "id" : "#{tag}_201811"
          [
            code,
            {
              reading: "rd_mock_test_Novice_#{suffix}_t.pdf",
              listening: "ls_mock_test_Novice_#{suffix}_t.pdf",
              audio: "mock_Novice_mp3_#{tag}"
            }
          ]
        end
      }
      band_a = (1..5).map do |set|
        name = prefix(set)
        {
          band: "A",
          set: set,
          level: LEVEL_LABEL["A"],
          audio: "#{name}_BandA_mp3_en",
          reading: "rd_#{name}_test_BandA_en_t.pdf",
          reading_key: "rd_#{name}_test_BandA_answer.pdf",
          listening: "ls_#{name}_test_BandA_en_t.pdf",
          listening_key: "ls_#{name}_test_BandA_answer.pdf",
          transcript: "ls_#{name}_test_BandA_listen.pdf",
          editions: EDITION_TAGS.to_h do |code, tag|
            [
              code,
              {
                reading: "rd_#{name}_test_BandA_#{tag}_t.pdf",
                listening: "ls_#{name}_test_BandA_#{tag}_t.pdf",
                audio: "#{name}_BandA_mp3_#{tag}"
              }
            ]
          end
        }
      end

      band_b = (1..5).map do |set|
        name = prefix(set)
        {
          band: "B",
          set: set,
          level: LEVEL_LABEL["B"],
          audio: "#{name}_BandB_mp3",
          reading: "rd_#{name}_test_BandB_t.pdf",
          reading_key: set == 2 ? "rd_mock2_test_BandB_answer_t.pdf" : "rd_#{name}_test_BandB_answer.pdf",
          listening: "ls_#{name}_test_BandB_t.pdf",
          listening_key: "ls_#{name}_test_BandB_answer.pdf",
          transcript: "ls_#{name}_test_BandB_listen.pdf"
        }
      end

      band_c = (1..4).map do |set|
        name = prefix(set)
        {
          band: "C",
          set: set,
          level: LEVEL_LABEL["C"],
          audio: "#{name}_BandC_mp3",
          reading: set == 1 ? "rd_mock_test_BandC_t_2022.pdf" : "rd_#{name}_test_BandC_t.pdf",
          reading_key: "rd_#{name}_test_BandC_answer.pdf",
          listening: set == 2 ? "ls_mock2_test_BandC_t_2022.pdf" : "ls_#{name}_test_BandC_t.pdf",
          listening_key: set == 3 ? "ls_mock3_test_BandC_answer_fix.pdf" : "ls_#{name}_test_BandC_answer.pdf",
          transcript: set == 2 ? "ls_mock2_test_BandC_listen_2022.pdf" : "ls_#{name}_test_BandC_listen.pdf"
        }
      end

      [novice, *band_a, *band_b, *band_c]
    end
  end
end
