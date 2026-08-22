# frozen_string_literal: true

require_relative "cangjie_lessons_content"

module CangjieContent
  module_function
  def strokes(b)
    b.lesson(
      "h",
      stage: "letters",
      key: "h",
      title: {"ru" => "竹 — наклонная 斜", "en" => "竹 — the slant 斜"},
      lede: {
        "ru" => "На клавише написано 竹, но означает она не бамбук, а наклонную черту: мазок справа сверху влево вниз.",
        "en" => "The keycap reads 竹, yet the key does not mean bamboo. It means a slant: a stroke running from upper right to lower left."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "竹",
              "rule" => {"ru" => "Бамбук наверху знака", "en" => "Bamboo on top of a character"},
              "chars" => %w[第 等 答 筆]
            },
            {
              "glyph" => "丿",
              "rule" => {"ru" => "Короткая наклонная", "en" => "A short slant"},
              "chars" => %w[千 生 升 白]
            },
            {
              "glyph" => "厂",
              "rule" => {
                "ru" => "Наклонная с горизонталью — первая черта наклонная",
                "en" => "A slant carrying a bar — the first stroke is the slant"
              },
              "chars" => %w[反 斤 派 房]
            },
            {
              "glyph" => "彳",
              "rule" => {
                "ru" => "Шаг: это 竹 плюс 人, два кода",
                "en" => "The step: 竹 plus 人, two codes"
              },
              "chars" => %w[很 行 後 得]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "千",
              "pieces" => %w[丿 十],
              "why" => {
                "ru" => "Наклонная сверху, крестик снизу.",
                "en" => "A slant on top, a cross below."
              }
            },
            {
              "char" => "和",
              "pieces" => %w[丿 木 口],
              "why" => {
                "ru" => "禾 — это наклонная плюс дерево. Рот справа замыкает знак.",
                "en" => "禾 is a slant plus a tree. The mouth on the right closes the character."
              }
            },
            {
              "char" => "我",
              "pieces" => %w[丿 龵 戈],
              "why" => {
                "ru" => "Знак не режется надвое, его берут подряд: наклонная, рука, копьё.",
                "en" => "This one will not cut in two, so it is read straight through: slant, hand, halberd."
              }
            },
            {
              "char" => "反",
              "pieces" => %w[厂 又],
              "why" => {
                "ru" => "Навес начинается наклонной — значит 竹, а не 一. Внутри рука.",
                "en" => "The awning starts with a slant, so it is 竹 and not 一. A hand sits inside."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Навесов два. Если первая черта горизонтальная — это 一 (原, 厚, 歷). Если первая черта наклонная — это 竹 (反, 斤, 派, 房). Смотрите на верхний левый угол.",
            "en" => "There are two awnings. If the first stroke is horizontal it is 一 (原, 厚, 歷). If the first stroke is a slant it is 竹 (反, 斤, 派, 房). Look at the upper-left corner."
          }
        }
      ],
      bank: %w[竹 第 千 生 我 和 香 秋 反 斤 房 看 很 行 後 白]
    )

    b.lesson(
      "i",
      stage: "letters",
      key: "i",
      title: {"ru" => "戈 — точка 點", "en" => "戈 — the dot 點"},
      lede: {
        "ru" => "Клавиша значит точку. Кроме неё сюда попали копьё 戈, навес 广 и завиток 厶.",
        "en" => "This key means the dot. Along with it come the halberd 戈, the awning 广 and the curl 厶."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "戈",
              "rule" => {"ru" => "Копьё", "en" => "The halberd"},
              "chars" => %w[我 或 成 找]
            },
            {
              "glyph" => "丶",
              "rule" => {"ru" => "Точка", "en" => "The dot"},
              "chars" => %w[太 犬 寸 冰]
            },
            {
              "glyph" => "广",
              "rule" => {
                "ru" => "Навес: точка над горизонталью",
                "en" => "The awning: a dot above a bar"
              },
              "chars" => %w[店 度 廣 康]
            },
            {
              "glyph" => "厶",
              "rule" => {
                "ru" => "Завиток — производное точки",
                "en" => "The curl, a dot descendant"
              },
              "chars" => %w[台 私 允 去]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "太",
              "pieces" => %w[大 丶],
              "why" => {
                "ru" => "Точка стоит ниже перекладины, значит идёт второй.",
                "en" => "The dot sits below the bar, so it comes second."
              }
            },
            {
              "char" => "犬",
              "pieces" => %w[丶 大],
              "why" => {
                "ru" => "А здесь точка выше — и потому идёт первой. Те же две части, обратный порядок.",
                "en" => "Here the dot is higher, so it goes first. The same two pieces, the opposite order."
              }
            },
            {
              "char" => "店",
              "pieces" => %w[广 卜 口],
              "why" => {
                "ru" => "Навес — голова, одна клавиша. Тело 占 — 卜 и 口.",
                "en" => "The awning is the head, one key. The body 占 is 卜 and 口."
              }
            },
            {
              "char" => "冰",
              "pieces" => %w[丶 一 水],
              "why" => {
                "ru" => "Две капли 冫 — не вода: их всегда разбирают на точку и черту, 戈一.",
                "en" => "The two-drop 冫 is not water: it is always spelled out as dot plus bar, 戈一."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Не всякая точка — 戈. Точка, которая на деле сплющенная крышка 亠, идёт на 卜: 主 набирается 卜土, 雨 и 冬 тоже начинаются с 卜.",
            "en" => "Not every dot is 戈. A dot that is really a squashed 亠 lid goes to 卜: 主 is typed 卜土, and 雨 and 冬 start with 卜 too."
          }
        }
      ],
      bank: %w[戈 我 或 成 找 太 犬 寸 冰 店 度 廣 康 台 私 去]
    )

    b.lesson(
      "j",
      stage: "letters",
      key: "j",
      title: {"ru" => "十 — крестик 交", "en" => "十 — the cross 交"},
      lede: {
        "ru" => "Вертикаль под прямым углом пересекает горизонталь — и ничего не загибается. Сюда же крыша 宀.",
        "en" => "A vertical crosses a horizontal at a right angle, and nothing bends. The roof 宀 joins it."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "十",
              "rule" => {"ru" => "Прямой крест", "en" => "A plain cross"},
              "chars" => %w[古 車 協 直]
            },
            {
              "glyph" => "宀",
              "rule" => {
                "ru" => "Крыша: тот же крест, у которого концы опущены вниз",
                "en" => "The roof: the same cross with its ends pulled down"
              },
              "chars" => %w[守 家 定 完]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "古",
              "pieces" => %w[十 口],
              "why" => {"ru" => "Крест сверху, рот снизу.", "en" => "Cross on top, mouth below."}
            },
            {
              "char" => "車",
              "pieces" => %w[十 田 十],
              "why" => {
                "ru" => "Сверху вниз: перекладина, квадрат с начинкой, снова перекладина.",
                "en" => "Top to bottom: a bar, a filled square, another bar."
              }
            },
            {
              "char" => "定",
              "pieces" => %w[宀 一 卜 人],
              "why" => {
                "ru" => "Крыша — голова. Тело 疋 длиннее трёх кусков, поэтому берут первый, второй и последний.",
                "en" => "The roof is the head. The body 疋 runs past three pieces, so first, second and last are taken."
              }
            },
            {
              "char" => "早",
              "pieces" => %w[日 十],
              "why" => {"ru" => "Солнце над крестом.", "en" => "A sun over a cross."}
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Крест без загибов — 十. Крест, у которого вертикаль загибается крюком, — это скелет дерева, клавиша 木: 寸, 才, 子. Сравните 古 (十口) и 寸 (木戈).",
            "en" => "A cross with no bends is 十. A cross whose vertical hooks at the foot is the wood skeleton, key 木: 寸, 才, 子. Compare 古 (十口) with 寸 (木戈)."
          }
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Крыша тоже двоится: 宀 с торчащими вниз концами — 十 (守, 家, 定), а гладкая крышка 冖 без концов — 月 (冠, 軍).",
            "en" => "The lid splits in two as well: 宀 with ends hanging down is 十 (守, 家, 定), while the plain 冖 with no ends is 月 (冠, 軍)."
          }
        }
      ],
      bank: %w[十 古 車 協 直 守 家 定 完 早 草 煮 者 事 千 未]
    )

    b.lesson(
      "k",
      stage: "letters",
      key: "k",
      title: {"ru" => "大 — косой крест 叉", "en" => "大 — the X 叉"},
      lede: {
        "ru" => "Две черты, пересекающиеся наискось. Сюда же угол 𠂇 и болезнь 疒.",
        "en" => "Two strokes crossing on the diagonal. The corner 𠂇 and the sickness 疒 join them."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "大",
              "rule" => {
                "ru" => "Человек с раскинутыми руками",
                "en" => "A person with arms out"
              },
              "chars" => %w[天 太 因 知]
            },
            {
              "glyph" => "乂",
              "rule" => {"ru" => "Голый косой крест", "en" => "The bare X"},
              "chars" => %w[爻 凶]
            },
            {
              "glyph" => "𠂇",
              "rule" => {
                "ru" => "Верхний левый угол — половинка 大",
                "en" => "The upper-left corner, half of 大"
              },
              "chars" => %w[友 右 左 在]
            },
            {
              "glyph" => "疒",
              "rule" => {
                "ru" => "Болезнь: угол с двумя точками",
                "en" => "Sickness: the corner with two dots"
              },
              "chars" => %w[病 疼 痛 疲]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "天",
              "pieces" => %w[一 大],
              "why" => {"ru" => "Черта над человеком.", "en" => "A bar over a person."}
            },
            {
              "char" => "因",
              "pieces" => %w[囗 大],
              "why" => {
                "ru" => "Снаружи внутрь: рамка, потом её начинка.",
                "en" => "Outside in: the frame, then what it holds."
              }
            },
            {
              "char" => "右",
              "pieces" => %w[𠂇 口],
              "why" => {
                "ru" => "Верхний угол — 大, под ним рот.",
                "en" => "The corner on top is 大, the mouth below it."
              }
            },
            {
              "char" => "病",
              "pieces" => %w[疒 一 人 月],
              "why" => {
                "ru" => "Болезнь — голова, одна клавиша. Тело 丙 — черта, человек, оболочка.",
                "en" => "Sickness is the head, one key. The body 丙 is a bar, a person and a shell."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "𠂇 (в 友, 右, 左) — клавиша 大. Очень похожее 龵 (в 看, 那, 我) — клавиша 手. Разница в лишней короткой черте.",
            "en" => "𠂇 (in 友, 右, 左) is key 大. The near-identical 龵 (in 看, 那, 我) is key 手. One extra short stroke tells them apart."
          }
        }
      ],
      bank: %w[大 天 太 因 知 友 右 左 在 病 疼 痛 疲 凶 央 力]
    )

    b.lesson(
      "l",
      stage: "letters",
      key: "l",
      title: {"ru" => "中 — вертикаль 縱", "en" => "中 — the vertical 縱"},
      lede: {
        "ru" => "Черта сверху вниз. Сюда же одежда 衤 и кисть 聿.",
        "en" => "A stroke running top to bottom. The clothing 衤 and the brush 聿 come along."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "中",
              "rule" => {"ru" => "Середина", "en" => "The middle"},
              "chars" => %w[史 忠 蟲]
            },
            {
              "glyph" => "丨",
              "rule" => {"ru" => "Просто вертикаль", "en" => "Just the vertical"},
              "chars" => %w[川 巾 非]
            },
            {
              "glyph" => "衤",
              "rule" => {
                "ru" => "Одежда слева — одна клавиша",
                "en" => "Clothing on the left — one key"
              },
              "chars" => %w[補 被 襯]
            },
            {
              "glyph" => "聿",
              "rule" => {"ru" => "Кисть в руке", "en" => "The brush in a hand"},
              "chars" => %w[事 書 秉 隸]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "中",
              "pieces" => %w[中],
              "why" => {
                "ru" => "Сам себе буква: одно нажатие.",
                "en" => "A letter in its own right: one press."
              }
            },
            {
              "char" => "巾",
              "pieces" => %w[丨 冂],
              "why" => {
                "ru" => "Вертикаль выше оболочки, поэтому идёт первой.",
                "en" => "The vertical starts higher than the shell, so it comes first."
              }
            },
            {
              "char" => "書",
              "pieces" => %w[聿 土 日],
              "why" => {
                "ru" => "Кисть — голова. Тело 曰 съедается вместе с перекладиной: 土 и 日.",
                "en" => "The brush is the head. The body takes the bar and the sun: 土 and 日."
              }
            },
            {
              "char" => "補",
              "pieces" => %w[衤 丶 十 月],
              "why" => {
                "ru" => "Одежда слева — один код 中. Тело 甫 — точка, крест, оболочка.",
                "en" => "Clothing on the left is a single 中. The body 甫 is dot, cross, shell."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Одежда 衤 — одна клавиша 中. Похожий алтарь 礻 — две: 戈火 (神, 祈, 禮). Считайте точки слева.",
            "en" => "Clothing 衤 is one key, 中. The similar altar 礻 takes two: 戈火 (神, 祈, 禮). Count the dots on the left."
          }
        }
      ],
      bank: %w[中 史 忠 蟲 川 巾 非 補 被 襯 事 書 秉 隸 央 甲]
    )

    b.lesson(
      "m",
      stage: "letters",
      key: "m",
      title: {"ru" => "一 — горизонталь 橫", "en" => "一 — the horizontal 橫"},
      lede: {
        "ru" => "Черта слева направо. Сюда же навес 厂 с горизонтальным началом и работа 工.",
        "en" => "A stroke running left to right. The awning 厂 that starts flat, and the work sign 工, come with it."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "一",
              "rule" => {"ru" => "Черта", "en" => "The bar"},
              "chars" => %w[二 三 王 天]
            },
            {
              "glyph" => "厂",
              "rule" => {
                "ru" => "Навес, начинающийся горизонталью",
                "en" => "The awning that opens with a horizontal"
              },
              "chars" => %w[原 厚 歷]
            },
            {
              "glyph" => "𠂆",
              "rule" => {
                "ru" => "Слипшиеся горизонталь и наклонная — берутся одной клавишей",
                "en" => "A bar fused with a slant — one key, not two"
              },
              "chars" => %w[石 表 危]
            },
            {
              "glyph" => "工",
              "rule" => {"ru" => "Работа", "en" => "Work"},
              "chars" => %w[功 哥 左]
            },
            {
              "glyph" => "㇀",
              "rule" => {
                "ru" => "Черта, поднимающаяся вправо",
                "en" => "A bar rising to the right"
              },
              "chars" => %w[刁 勻 羽]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "三",
              "pieces" => %w[一 一 一],
              "why" => {"ru" => "Три черты — три нажатия.", "en" => "Three bars, three presses."}
            },
            {
              "char" => "王",
              "pieces" => %w[一 土],
              "why" => {
                "ru" => "Лишняя черта сверху, под ней земля. Правило целостности: земля берётся целиком.",
                "en" => "One extra bar on top, earth below. The completeness rule keeps the earth whole."
              }
            },
            {
              "char" => "石",
              "pieces" => %w[𠂆 口],
              "why" => {
                "ru" => "Горизонталь и наклонная слиты, поэтому это один код, а не 一竹.",
                "en" => "The bar and the slant are fused, so this is one code, not 一竹."
              }
            },
            {
              "char" => "原",
              "pieces" => %w[厂 丿 日 小],
              "why" => {
                "ru" => "Навес — голова. Тело 泉 длинное: первый кусок, второй и последний.",
                "en" => "The awning is the head. The body 泉 is long: first piece, second, last."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Новички разбивают 𠂆 на 一 и 丿. Так нельзя: там, где горизонталь и наклонная сцеплены в один росчерк, берут одну клавишу 一.",
            "en" => "Beginners split 𠂆 into 一 and 丿. Do not: where a bar and a slant are joined in one stroke, take the single key 一."
          }
        }
      ],
      bank: %w[一 二 三 王 天 石 表 原 厚 歷 功 哥 左 危 五 本]
    )

    b.lesson(
      "n",
      stage: "letters",
      key: "n",
      title: {"ru" => "弓 — крюк 鉤", "en" => "弓 — the hook 鉤"},
      lede: {
        "ru" => "Всё, что на конце загибается. Самая ёмкая клавиша: 亅, 乙, 𠂊, ⺈ — всё сюда.",
        "en" => "Anything that bends at its end. The most crowded key: 亅, 乙, 𠂊, ⺈ all land here."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "弓",
              "rule" => {"ru" => "Лук", "en" => "The bow"},
              "chars" => %w[強 引 弟 第]
            },
            {
              "glyph" => "亅",
              "rule" => {"ru" => "Крюк вниз", "en" => "A hook pointing down"},
              "chars" => %w[了 利 事]
            },
            {
              "glyph" => "𠂊",
              "rule" => {
                "ru" => "Крюк с хвостиком вниз-влево",
                "en" => "A hook with a tail down-left"
              },
              "chars" => %w[久 欠 夜]
            },
            {
              "glyph" => "⺈",
              "rule" => {"ru" => "Крюк-нож сверху", "en" => "The knife-hook on top"},
              "chars" => %w[色 免 危]
            },
            {
              "glyph" => "乛",
              "rule" => {"ru" => "Крюк, положенный набок", "en" => "The hook laid flat"},
              "chars" => %w[予 疋 耶]
            },
            {
              "glyph" => "乙",
              "rule" => {"ru" => "Вторая небесная ветвь", "en" => "The second heavenly stem"},
              "chars" => %w[乞]
            },
            {
              "glyph" => "乁",
              "rule" => {"ru" => "Изменённое 乙", "en" => "乙 reshaped"},
              "chars" => %w[虱 朵 九]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "了",
              "pieces" => %w[𠃌 亅],
              "why" => {
                "ru" => "Два крюка подряд — 弓弓. Один из самых частых знаков языка.",
                "en" => "Two hooks in a row — 弓弓. One of the commonest characters in the language."
              }
            },
            {
              "char" => "引",
              "pieces" => %w[弓 丨],
              "why" => {
                "ru" => "Лук слева, вертикаль справа.",
                "en" => "Bow on the left, vertical on the right."
              }
            },
            {
              "char" => "色",
              "pieces" => %w[⺈ 日 乚],
              "why" => {
                "ru" => "Крюк-нож, лежащее солнце, петля снизу — три кода.",
                "en" => "Knife-hook, reclining sun, loop at the foot — three codes."
              }
            },
            {
              "char" => "你",
              "pieces" => %w[亻 ⺈ 小],
              "why" => {
                "ru" => "Человек — голова. Тело 尔: крюк сверху и 小 снизу.",
                "en" => "The person is the head. The body 尔: a hook on top and 小 below."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Знак 力 сам по себе набирается 大尸, но крюк 𠂊 в 久, 欠, 夜 — это 弓. Клавиша отвечает за форму, а не за иероглиф.",
            "en" => "The character 力 on its own is typed 大尸, yet the hook 𠂊 in 久, 欠 and 夜 is 弓. The key answers to the shape, not to the character."
          }
        }
      ],
      bank: %w[弓 強 引 弟 第 了 利 事 久 欠 夜 色 免 你 九 那]
    )
  end

  def body(b)
    b.lesson(
      "o",
      stage: "letters",
      key: "o",
      title: {"ru" => "人 — человек", "en" => "人 — person"},
      lede: {
        "ru" => "Человек стоя, боком, шапочкой сверху, и даже одинокий откос вниз-вправо.",
        "en" => "A person standing, side-on, as a little roof, and even as a lone down-right stroke."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "人",
              "rule" => {"ru" => "Человек", "en" => "The person"},
              "chars" => %w[內 來 坐]
            },
            {
              "glyph" => "亻",
              "rule" => {"ru" => "Человек слева", "en" => "Person on the left"},
              "chars" => %w[他 你 作 但]
            },
            {
              "glyph" => "𠆢",
              "rule" => {"ru" => "Человек шапочкой", "en" => "Person as a cap"},
              "chars" => %w[會 今 界]
            },
            {
              "glyph" => "𠂉",
              "rule" => {"ru" => "Приплюснутая шапочка", "en" => "The cap flattened"},
              "chars" => %w[氣 年 每]
            },
            {
              "glyph" => "入",
              "rule" => {
                "ru" => "Вход: от 人 не отличается",
                "en" => "Entry: indistinguishable from 人"
              },
              "chars" => %w[內 兩]
            },
            {
              "glyph" => "㇏",
              "rule" => {"ru" => "Правая половина человека", "en" => "The right half of a person"},
              "chars" => %w[久 登]
            },
            {
              "glyph" => "⺁",
              "rule" => {"ru" => "Изменённый 亻", "en" => "亻 reshaped"},
              "chars" => %w[邱 兵 岳]
            },
            {
              "glyph" => "く",
              "rule" => {
                "ru" => "Производная того же откоса",
                "en" => "A descendant of the same stroke"
              },
              "chars" => %w[兆 豕 聚]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "作",
              "pieces" => %w[亻 𠂉 ⺊],
              "why" => {
                "ru" => "Человек — голова. Тело 乍: шапочка и лежащее 卜 — 人尸.",
                "en" => "The person is the head. The body 乍: a cap and a reclining 卜 — 人尸."
              }
            },
            {
              "char" => "來",
              "pieces" => %w[木 人 人],
              "why" => {
                "ru" => "Особый знак: сначала дерево целиком, потом две «ноги».",
                "en" => "A special character: the whole tree first, then the two legs."
              }
            },
            {
              "char" => "會",
              "pieces" => %w[𠆢 一 田 日],
              "why" => {
                "ru" => "Шапочка сверху, дальше сверху вниз: черта, квадрат с начинкой, солнце.",
                "en" => "The cap on top, then top to bottom: a bar, a filled square, a sun."
              }
            },
            {
              "char" => "年",
              "pieces" => %w[𠂉 龵],
              "why" => {
                "ru" => "Приплюснутая шапочка и рука — два кода на очень частый знак.",
                "en" => "A flattened cap and a hand — two codes for a very common character."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "人 и 入 на письме почти неразличимы, поэтому в цанцзе они на одной клавише. Спорить о том, какой из них перед вами, не нужно.",
            "en" => "人 and 入 look nearly the same on paper, so Cangjie puts them on one key. There is nothing to argue about."
          }
        }
      ],
      bank: %w[人 內 來 坐 他 你 作 但 會 今 界 氣 年 久 兩 信]
    )

    b.lesson(
      "p",
      stage: "letters",
      key: "p",
      title: {"ru" => "心 — сердце", "en" => "心 — heart"},
      lede: {
        "ru" => "Сердце в трёх положениях плюс целое семейство коротких крюков: 匕, 七, 勹.",
        "en" => "The heart in three positions, plus a family of short hooks: 匕, 七, 勹."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "心",
              "rule" => {
                "ru" => "Сердце внизу или отдельно",
                "en" => "The heart at the foot or on its own"
              },
              "chars" => %w[志 忘 悶]
            },
            {
              "glyph" => "忄",
              "rule" => {"ru" => "Сердце слева", "en" => "Heart on the left"},
              "chars" => %w[怕 忙 情]
            },
            {
              "glyph" => "⺗",
              "rule" => {"ru" => "Сердце подошвой", "en" => "Heart as a sole"},
              "chars" => %w[恭 慕]
            },
            {
              "glyph" => "匕",
              "rule" => {"ru" => "Ложка", "en" => "The spoon"},
              "chars" => %w[比 旨 化]
            },
            {
              "glyph" => "七",
              "rule" => {"ru" => "Семёрка — та же ложка", "en" => "The seven — the same spoon"},
              "chars" => %w[虎 世 屯]
            },
            {
              "glyph" => "勹",
              "rule" => {
                "ru" => "Ложка вверх ногами — обёртка",
                "en" => "The spoon upside down — the wrap"
              },
              "chars" => %w[包 勿]
            },
            {
              "glyph" => "𠃋",
              "rule" => {
                "ru" => "Ложка, срезанная до угла",
                "en" => "The spoon cut down to a corner"
              },
              "chars" => %w[民 武 代]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "化",
              "pieces" => %w[亻 匕],
              "why" => {
                "ru" => "Человек и ложка — два кода.",
                "en" => "A person and a spoon — two codes."
              }
            },
            {
              "char" => "忙",
              "pieces" => %w[忄 亠 𠃊],
              "why" => {
                "ru" => "Сердце слева — один код. Тело 亡 — крышка и петля.",
                "en" => "Heart on the left is one code. The body 亡 is a lid and a loop."
              }
            },
            {
              "char" => "包",
              "pieces" => %w[勹 口 乚],
              "why" => {
                "ru" => "Обёртка снаружи, начинка 巳 внутри: рот и петля.",
                "en" => "The wrap outside, the 巳 filling inside: mouth and loop."
              }
            },
            {
              "char" => "世",
              "pieces" => %w[七 卄],
              "why" => {
                "ru" => "Семёрка сверху, симметричная пара снизу.",
                "en" => "The seven on top, the symmetric pair below."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Обёртка 勹 — это 心 (包, 勿, 句). Похожий крюк 𠂊 в 久 и 夜 — это 弓. У 勹 первая черта наклонная и длинная, у 𠂊 — короткая.",
            "en" => "The wrap 勹 is 心 (包, 勿, 句). The similar hook 𠂊 in 久 and 夜 is 弓. The first stroke of 勹 is a long slant; the one in 𠂊 is short."
          }
        }
      ],
      bank: %w[心 志 忘 悶 怕 忙 情 恭 慕 比 旨 化 虎 世 包 他]
    )

    b.lesson(
      "q",
      stage: "letters",
      key: "q",
      title: {"ru" => "手 — рука", "en" => "手 — hand"},
      lede: {
        "ru" => "Рука отдельно, рука слева 扌 и её скелет 龵 — три черты поперёк вертикали.",
        "en" => "The hand alone, the hand on the left 扌, and its skeleton 龵 — three bars across a vertical."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "手",
              "rule" => {"ru" => "Рука", "en" => "The hand"},
              "chars" => %w[拿]
            },
            {
              "glyph" => "扌",
              "rule" => {"ru" => "Рука слева", "en" => "Hand on the left"},
              "chars" => %w[握 打 提 找]
            },
            {
              "glyph" => "龵",
              "rule" => {"ru" => "Скелет руки", "en" => "The hand skeleton"},
              "chars" => %w[我 青 春]
            },
            {
              "glyph" => "𠂒",
              "rule" => {
                "ru" => "Тот же скелет, срезанный слева",
                "en" => "The same skeleton, shaved on the left"
              },
              "chars" => %w[看 那]
            },
            {
              "glyph" => "⺸",
              "rule" => {
                "ru" => "Скелет с длинной вертикалью",
                "en" => "The skeleton with a long vertical"
              },
              "chars" => %w[年 半 生]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "打",
              "pieces" => %w[扌 一 亅],
              "why" => {
                "ru" => "Рука слева — голова. Тело 丁 — черта и крюк.",
                "en" => "Hand on the left is the head. The body 丁 is a bar and a hook."
              }
            },
            {
              "char" => "找",
              "pieces" => %w[扌 戈],
              "why" => {
                "ru" => "Рука и копьё — два кода.",
                "en" => "Hand and halberd — two codes."
              }
            },
            {
              "char" => "春",
              "pieces" => %w[龵 大 日],
              "why" => {
                "ru" => "Скелет руки, косой крест, солнце — сверху вниз.",
                "en" => "Hand skeleton, X, sun — top to bottom."
              }
            },
            {
              "char" => "半",
              "pieces" => %w[丷 ⺸],
              "why" => {
                "ru" => "Две точки — 金? Нет: по правилу целостности здесь берут 火, а низ — рука.",
                "en" => "Two dots — 金? No: the completeness rule takes 火 here, and the foot is a hand."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Помните пару из урока 大: 𠂇 (友, 右, 左) — это 大, а 龵 (看, 那, 我) — это 手.",
            "en" => "Remember the pair from the 大 lesson: 𠂇 (友, 右, 左) is 大, while 龵 (看, 那, 我) is 手."
          }
        }
      ],
      bank: %w[手 拿 握 打 提 找 我 青 春 看 那 年 半 生 表 掉]
    )

    b.lesson(
      "r",
      stage: "letters",
      key: "r",
      title: {"ru" => "口 — рот", "en" => "口 — mouth"},
      lede: {
        "ru" => "Единственная клавиша без вспомогательных форм: рот и только рот. Зато встречается чаще всех.",
        "en" => "The only key with no auxiliary shapes at all: the mouth, and nothing else. It also turns up more than any other."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "口",
              "rule" => {"ru" => "Маленький пустой квадрат", "en" => "A small empty square"},
              "chars" => %w[品 唱 和 知]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "品",
              "pieces" => %w[口 口 口],
              "why" => {
                "ru" => "Сначала верхний рот, потом нижние слева направо.",
                "en" => "The top mouth first, then the lower two from left to right."
              }
            },
            {
              "char" => "唱",
              "pieces" => %w[口 日 日],
              "why" => {
                "ru" => "Сначала левое, и только потом верх-низ. Не наоборот.",
                "en" => "Left first, top-bottom only afterwards. Not the other way round."
              }
            },
            {
              "char" => "呢",
              "pieces" => %w[口 尸 匕],
              "why" => {
                "ru" => "Рот — голова. Тело 尼 — бок и ложка.",
                "en" => "The mouth is the head. The body 尼 is a side and a spoon."
              }
            },
            {
              "char" => "知",
              "pieces" => %w[人 大 口],
              "why" => {
                "ru" => "Голова 矢 не буква: её первый кусок — шапочка 人, последний — 大.",
                "en" => "The head 矢 is not a letter: its first piece is the cap 人, its last is 大."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Пустой квадратик — 口. Квадрат, внутри которого что-то есть, — 田: 國, 回, 因, 四. Правило простое: есть начинка — жмите 田.",
            "en" => "An empty little square is 口. A square with something inside it is 田: 國, 回, 因, 四. The rule is plain: if it has filling, press 田."
          }
        }
      ],
      bank: %w[口 品 唱 和 知 只 吃 喝 呢 嗎 哪 同 古 右 石 台]
    )
  end
end
