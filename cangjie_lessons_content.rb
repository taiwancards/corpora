# frozen_string_literal: true

module CangjieContent
  SECTIONS = %i[basics nature strokes body shapes special rules exceptions taiwan].freeze

  module_function
  def basics(b)
    b.lesson(
      "keyboard",
      stage: "basics",
      title: {
        "ru" => "Клавиатура: двадцать четыре буквы",
        "en" => "The keyboard: twenty-four letters"
      },
      lede: {
        "ru" => "Цанцзе не знает чтений. Иероглиф разбирается на видимые куски, каждый кусок — одна клавиша.",
        "en" => "Cangjie knows nothing about pronunciation. A character is cut into visible pieces; each piece is one key."
      },
      blocks: [
        {"kind" => "keys"},
        {
          "kind" => "prose",
          "text" => {
            "ru" => "Двадцать четыре буквы разложены по четырём семьям. Первая и третья — картинки: солнце, луна, металл, дерево, вода, огонь, земля; человек, сердце, рука, рот. Вторая — не иероглифы, а черты: наклонная, точка, крестик, косой крест, вертикаль, горизонталь, крюк; на клавишах написаны 竹戈十大中一弓, но это лишь ярлыки. Четвёртая — очертания: бок, парность, раскрытая вверх чаша, петля, замкнутый квадрат, и отдельно 卜.",
            "en" => "The twenty-four letters fall into four families. The first and third are pictures: sun, moon, metal, wood, water, fire, earth; person, heart, hand, mouth. The second is not characters at all but strokes: slant, dot, cross, X, vertical, horizontal, hook; the keycaps read 竹戈十大中一弓, yet those are only labels. The fourth is outlines: a side, a symmetric pair, a cup open at the top, a loop, a closed square, plus 卜."
          }
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "X (難) и Z (重) — служебные, своей формы у них нет. X подставляется вместо куска, который слишком мелко дробится, и той же клавишей помечается повтор, когда два знака получают одинаковый код. Z иероглифов не набирает вовсе.",
            "en" => "X (難) and Z (重) are utility keys with no shape of their own. X stands in for a piece too fiddly to spell out, and the same key marks a repeat when two characters earn the same code. Z types no characters at all."
          }
        },
        {
          "kind" => "walk",
          "title" => {"ru" => "Три знака целиком", "en" => "Three characters end to end"},
          "rows" => [
            {
              "char" => "明",
              "pieces" => %w[日 月],
              "why" => {
                "ru" => "Слева 日, справа 月. Оба — буквы, значит два нажатия и всё.",
                "en" => "日 on the left, 月 on the right. Both are letters, so two presses and done."
              }
            },
            {
              "char" => "村",
              "pieces" => %w[木 十 丶],
              "why" => {
                "ru" => "Слева 木 — это голова. Справа 寸: скелет 十 берётся клавишей 木, точка — клавишей 戈.",
                "en" => "木 on the left is the head. On the right 寸: its 十 skeleton is typed with 木, the dot with 戈."
              }
            },
            {
              "char" => "灣",
              "pieces" => %w[氵 幺 火 弓],
              "why" => {
                "ru" => "氵 — голова, одна клавиша 水. Тело 彎 длинное, поэтому от него берут только первый, второй и последний кусок.",
                "en" => "氵 is the head, one press of 水. The body 彎 is long, so only its first, second and last pieces are taken."
              }
            }
          ]
        }
      ],
      bank: %w[日 月 金 木 水 火 土 人 心 手 口 山 女 田 中 一]
    )

    b.lesson(
      "head-body",
      stage: "basics",
      title: {"ru" => "Голова и тело", "en" => "Head and body"},
      lede: {
        "ru" => "Почти любой иероглиф режется один раз: голова 字首 — крайняя левая или самая верхняя часть, остальное — тело 字身.",
        "en" => "Almost every character is cut once: the head 字首 is the leftmost or topmost part, everything else is the body 字身."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "Слева направо", "en" => "Left first"},
              "text" => {
                "ru" => "Если знак делится вертикальной линией — голова слева.",
                "en" => "If a vertical cut separates the character, the head is on the left."
              },
              "chars" => %w[明 好 你 說]
            },
            {
              "title" => {"ru" => "Сверху вниз", "en" => "Top next"},
              "text" => {
                "ru" => "Если вертикально не режется, а горизонтально режется — голова сверху.",
                "en" => "If it will not cut vertically but does cut horizontally, the head is on top."
              },
              "chars" => %w[早 花 分 想]
            },
            {
              "title" => {"ru" => "Снаружи внутрь", "en" => "Outside last"},
              "text" => {
                "ru" => "Если часть охватывает остальное — она и есть голова.",
                "en" => "If one part wraps the rest, that wrapper is the head."
              },
              "chars" => %w[國 問 房 進]
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Голова цанцзе — не ключ словаря. Ключ выбирается по смыслу и может стоять где угодно; голова выбирается по месту на бумаге. В 到 ключ — 刀 справа, а голова цанцзе — 至 слева.",
            "en" => "A Cangjie head is not a dictionary radical. A radical is chosen by meaning and may sit anywhere; a head is chosen by position on the page. In 到 the radical is 刀 on the right, but the Cangjie head is 至 on the left."
          }
        },
        {
          "kind" => "prose",
          "text" => {
            "ru" => "Голова даёт не больше двух кодов, тело — не больше трёх. Отсюда потолок в пять клавиш на знак. Если голова сама является буквой или вспомогательной формой, она стоит один код; иначе берут её первый и последний кусок.",
            "en" => "The head yields at most two codes, the body at most three. That is where the five-key ceiling comes from. If the head is itself a letter or an auxiliary shape it costs one code; otherwise take its first and last piece."
          }
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "到",
              "head" => 2,
              "pieces" => %w[一 土 中 弓],
              "why" => {
                "ru" => "Голова 至 не буква, поэтому от неё берут первый кусок 一 и последний 土. Тело 刂 — 中 и 弓.",
                "en" => "The head 至 is not a letter, so it gives its first piece 一 and its last piece 土. The body 刂 gives 中 and 弓."
              }
            },
            {
              "char" => "地",
              "head" => 1,
              "pieces" => %w[土 心 十],
              "why" => {
                "ru" => "Голова 土 — буква, один код. Тело 也 —心 и 十; больше в нём кусков нет.",
                "en" => "The head 土 is a letter: one code. The body 也 gives 心 and 十, and there is nothing else in it."
              }
            },
            {
              "char" => "想",
              "head" => 2,
              "pieces" => %w[木 凵 心],
              "why" => {
                "ru" => "Режется горизонтально: голова 相, тело 心. Голова не буква, поэтому берут её первый кусок 木 и последний — дно 目, то есть чашу 山.",
                "en" => "It cuts horizontally: head 相, body 心. The head is not a letter, so take its first piece 木 and its last one — the foot of 目, the cup 山."
              }
            }
          ]
        }
      ],
      bank: %w[明 好 你 說 早 花 分 想 國 問 房 進 到 地 時 們]
    )

    b.lesson(
      "order",
      stage: "basics",
      title: {"ru" => "Порядок обхода", "en" => "The order you read in"},
      lede: {
        "ru" => "Куски набираются в одном и том же порядке: слева направо, сверху вниз, снаружи внутрь. Порядок написания черт здесь ни при чём.",
        "en" => "Pieces are typed in one fixed order: left to right, top to bottom, outside to inside. Handwriting stroke order plays no part."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "由左而右", "en" => "由左而右"},
              "text" => {"ru" => "Сначала левое, потом правое.", "en" => "Left before right."},
              "chars" => %w[唱 浮 似 你]
            },
            {
              "title" => {"ru" => "由上而下", "en" => "由上而下"},
              "text" => {
                "ru" => "Сначала верхнее, потом нижнее.",
                "en" => "Top before bottom."
              },
              "chars" => %w[草 央 是 花]
            },
            {
              "title" => {"ru" => "由外而內", "en" => "由外而內"},
              "text" => {
                "ru" => "Сначала оболочка, потом начинка.",
                "en" => "The wrapper before what it holds."
              },
              "chars" => %w[回 國 凶 用]
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Внутри знака сначала отрабатывается левое-правое, и только потом верх-низ. В 唱 сперва левое 口, а уже потом два 日 сверху вниз.",
            "en" => "Inside a character, left-right is settled first and top-bottom only afterwards. In 唱 the left 口 comes first, and only then the two 日 from top to bottom."
          }
        },
        {
          "kind" => "compare",
          "rows" => [
            {
              "char" => "可",
              "wrong" => "mrn",
              "why" => {
                "ru" => "Крюк 亅 стоит выше, чем 口, поэтому он идёт вторым, а рот — третьим.",
                "en" => "The hook 亅 starts higher than 口, so the hook is second and the mouth third."
              }
            },
            {
              "char" => "用",
              "wrong" => "qb",
              "why" => {
                "ru" => "Оболочка 冂 снаружи, значит она первая; начинка 龵 — вторая.",
                "en" => "The 冂 shell is outside, so it comes first; the 龵 filling second."
              }
            }
          ]
        }
      ],
      bank: %w[唱 浮 似 草 央 回 國 凶 用 可 明 花 是 你 問 到]
    )

    b.lesson(
      "count",
      stage: "basics",
      title: {"ru" => "Сколько нажатий", "en" => "How many presses"},
      lede: {
        "ru" => "От одного до пяти. Голова — до двух, тело — до трёх; целый нерасчленимый знак — до четырёх.",
        "en" => "One to five. The head takes up to two, the body up to three; an unsplittable character takes up to four."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "Один код", "en" => "One code"},
              "text" => {
                "ru" => "Знак сам является буквой.",
                "en" => "The character is a letter itself."
              },
              "chars" => %w[日 月 木 水 火 土 人 心 手 口 山 女 田 中 一]
            },
            {
              "title" => {"ru" => "Два кода", "en" => "Two codes"},
              "text" => {
                "ru" => "Голова — буква, тело — буква.",
                "en" => "A letter head and a letter body."
              },
              "chars" => %w[明 朋 林 早 不 只 有 吉]
            },
            {
              "title" => {"ru" => "Три кода", "en" => "Three codes"},
              "text" => {
                "ru" => "Обычный случай: голова одна, тело из двух кусков.",
                "en" => "The common case: a one-code head and a two-piece body."
              },
              "chars" => %w[好 你 地 花 分 包 忙 怕]
            },
            {
              "title" => {"ru" => "Четыре и пять", "en" => "Four and five"},
              "text" => {
                "ru" => "Тело набирает три кода, голова — один или два.",
                "en" => "The body fills three codes, the head one or two."
              },
              "chars" => %w[是 說 這 時 過 學 灣 臺]
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Пятикодовые знаки редки: около шестидесяти тысяч иероглифов различаются пятью клавишами, но в повседневном тексте почти всё укладывается в три-четыре.",
            "en" => "Five-code characters are uncommon: five keys are enough to tell some sixty thousand characters apart, yet everyday text almost always lands on three or four."
          }
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Сколько бы кодов ни взяла голова, тело всегда берёт свои один-три. Поэтому у 棋, 基, 箕 головы разные, а общее тело 其 всегда набирается 廿一金.",
            "en" => "However many codes the head takes, the body always takes its own one to three. So 棋, 基 and 箕 have different heads, yet their shared body 其 is always 廿一金."
          }
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "Одно тело, разные головы", "en" => "One body, different heads"},
          "chars" => %w[其 棋 基 期]
        }
      ],
      bank: %w[日 明 好 是 說 這 時 灣 臺 學 過 花 包 只 有 吉]
    )
  end

  def nature(b)
    b.lesson(
      "a",
      stage: "letters",
      key: "a",
      title: {"ru" => "日 — солнце", "en" => "日 — sun"},
      lede: {
        "ru" => "Прямоугольник с перекладиной. Узкий 日, широкий 曰 и приплюснутое солнце внутри 巴 и 色 — всё это клавиша A.",
        "en" => "A box with a bar across it. The narrow 日, the wide 曰, and the squat sun inside 巴 and 色 all live on key A."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "日",
              "rule" => {"ru" => "Само солнце", "en" => "The sun itself"},
              "chars" => %w[明 早 者 春]
            },
            {
              "glyph" => "曰",
              "rule" => {"ru" => "Широкое 曰 — то же самое", "en" => "Wide 曰 counts as the same"},
              "chars" => %w[曾 書 會 最]
            },
            {
              "glyph" => "日",
              "rotate" => 90,
              "rule" => {
                "ru" => "Лежащее на боку солнце — верх 巴, 色, 免",
                "en" => "The sun on its side — the top of 巴, 色, 免"
              },
              "chars" => %w[巴 色 免 象]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "早",
              "pieces" => %w[日 十],
              "why" => {
                "ru" => "Голова 日 сверху, тело 十 снизу. Ровно два кода.",
                "en" => "Head 日 on top, body 十 below. Exactly two codes."
              }
            },
            {
              "char" => "白",
              "pieces" => %w[丿 日],
              "why" => {
                "ru" => "Мазок сверху — это наклонная черта, клавиша 竹. Ниже целое 日.",
                "en" => "The stroke on top is a slant, key 竹. Below it a whole 日."
              }
            },
            {
              "char" => "是",
              "pieces" => %w[日 一 卜 人],
              "why" => {
                "ru" => "Голова 日 — один код. Тело 疋 длиннее трёх кусков, поэтому от него берут первый, второй и последний.",
                "en" => "The head 日 is one code. The body 疋 runs longer than three pieces, so its first, second and last are taken."
              }
            },
            {
              "char" => "色",
              "pieces" => %w[⺈ 日 乚],
              "why" => {
                "ru" => "Сверху 「⺈」 — крюк, клавиша 弓. Дальше лежащее солнце и петля снизу.",
                "en" => "The 「⺈」 on top is a hook, key 弓. Then the reclining sun and the loop below."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "日 и 田 путают постоянно. В 日 одна перекладина и нет вертикали посередине; в 田 есть крест внутри. 目 — не 日: это 月 с горизонтальными чертами плюс раскрытая чаша, 月山.",
            "en" => "日 and 田 get mixed up constantly. 日 has one bar and no vertical inside; 田 has a cross inside. And 目 is not 日: it is a flat-barred 月 plus an upward cup, 月山."
          }
        },
        {
          "kind" => "compare",
          "rows" => [
            {
              "char" => "目",
              "wrong" => "bm",
              "why" => {
                "ru" => "По правилу целостности берут ту форму, что сохраняет очертание: снизу видна чаша 凵, а не одинокая черта.",
                "en" => "The completeness rule takes the shape that keeps the outline: what shows at the bottom is the cup 凵, not a lone stroke."
              }
            }
          ]
        }
      ],
      bank: %w[明 早 是 春 白 者 時 晚 星 唱 昨 書 最 曾 會 香]
    )

    b.lesson(
      "b",
      stage: "letters",
      key: "b",
      title: {"ru" => "月 — луна", "en" => "月 — moon"},
      lede: {
        "ru" => "Самая многоликая клавиша. Кроме 月 сюда идут 夕, 爫, плоское 月 внутри 目, оболочка 冂 и крышка 冖.",
        "en" => "The busiest key of all. Besides 月 it holds 夕, 爫, the flat 月 inside 目, the shell 冂 and the lid 冖."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "月",
              "rule" => {"ru" => "Луна и мясо ⺼", "en" => "The moon, and the flesh radical ⺼"},
              "chars" => %w[朋 有 服 期]
            },
            {
              "glyph" => "夕",
              "rule" => {"ru" => "Косая луна", "en" => "The slanted moon"},
              "chars" => %w[望 祭 炙]
            },
            {
              "glyph" => "爫",
              "rule" => {
                "ru" => "Изменённая 夕 — коготь сверху",
                "en" => "夕 reshaped — the claw on top"
              },
              "chars" => %w[受 采 爭 愛]
            },
            {
              "glyph" => "目",
              "rule" => {
                "ru" => "Плоское 月: черты внутри горизонтальные",
                "en" => "The flat 月: the strokes inside lie horizontal"
              },
              "chars" => %w[目 且 助 見]
            },
            {
              "glyph" => "冂",
              "rule" => {
                "ru" => "Оболочка — внешний контур 月",
                "en" => "The shell — the outline of 月"
              },
              "chars" => %w[同 用 周 典]
            },
            {
              "glyph" => "⺆",
              "rule" => {
                "ru" => "Та же оболочка, узкая и высокая",
                "en" => "The same shell, tall and narrow"
              },
              "chars" => %w[周 冉 甩]
            },
            {
              "glyph" => "冖",
              "rule" => {
                "ru" => "Крышка без выходящих черт",
                "en" => "A lid with nothing poking out"
              },
              "chars" => %w[冠 罕 旁 軍]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "同",
              "pieces" => %w[冂 一 口],
              "why" => {
                "ru" => "Снаружи внутрь: сначала оболочка 冂, потом её содержимое сверху вниз.",
                "en" => "Outside in: the shell 冂 first, then what it holds, top to bottom."
              }
            },
            {
              "char" => "受",
              "pieces" => %w[爫 冖 又],
              "why" => {
                "ru" => "Коготь и крышка — обе клавиши 月, поэтому код начинается с двух одинаковых нажатий.",
                "en" => "Claw and lid are both 月, which is why the code opens with the same key twice."
              }
            },
            {
              "char" => "有",
              "pieces" => %w[𠂇 月],
              "why" => {
                "ru" => "Верхний угол 「𠂇」 — косой крест, клавиша 大. Ниже 月 целиком.",
                "en" => "The 「𠂇」 corner is an X, key 大. Below it a whole 月."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Крышка без выступов 冖 — это 月. Крышка с выступающими вниз концами 宀 — это 十. Сравните 冠 и 守.",
            "en" => "The plain lid 冖 is 月. The lid whose ends hang down, 宀, is 十. Compare 冠 and 守."
          }
        }
      ],
      bank: %w[朋 有 服 期 同 用 周 目 助 見 受 愛 爭 冠 軍 祭]
    )

    b.lesson(
      "c",
      stage: "letters",
      key: "c",
      title: {"ru" => "金 — металл", "en" => "金 — metal"},
      lede: {
        "ru" => "Кроме самого 金 клавиша C держит две точки: 丷 сверху и перевёрнутое 八 снизу.",
        "en" => "Besides 金 itself, key C holds the two-dot shapes: 丷 on top and the upturned 八 below."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "金",
              "rule" => {
                "ru" => "Металл целиком и слева 釒",
                "en" => "The whole 金 and the left-hand 釒"
              },
              "chars" => %w[金 錢 鐘 銀]
            },
            {
              "glyph" => "丷",
              "rule" => {"ru" => "Две точки врозь", "en" => "Two dots leaning apart"},
              "chars" => %w[丫 弟 兌 曾]
            },
            {
              "glyph" => "八",
              "rule" => {"ru" => "Перевёрнутые точки", "en" => "The dots turned over"},
              "chars" => %w[只 巷 分 谷]
            },
            {
              "glyph" => "儿",
              "rule" => {"ru" => "Изменённое 八 — ножки", "en" => "八 reshaped — the little legs"},
              "chars" => %w[匹 西 四 兵]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "谷",
              "pieces" => %w[八 人 口],
              "why" => {
                "ru" => "Сверху 八 — клавиша 金, ниже 人, в основании рот. Три куска — три кода.",
                "en" => "八 on top is 金, then 人, then a mouth at the base. Three pieces, three codes."
              }
            },
            {
              "char" => "四",
              "pieces" => %w[囗 儿],
              "why" => {
                "ru" => "Квадрат снаружи — 田, ножки внутри — 金. Снаружи внутрь.",
                "en" => "The square outside is 田, the legs inside are 金. Outside in."
              }
            },
            {
              "char" => "只",
              "pieces" => %w[口 八],
              "why" => {
                "ru" => "Рот сверху, две точки снизу — два кода и всё.",
                "en" => "Mouth on top, two dots below — two codes and done."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "儿 с крюком на конце — это не 金, а «наклонная плюс чаша», 竹山: сравните 匹 (внутри 儿, клавиша 金) и 兄 (внизу 儿 с крюком, 竹山).",
            "en" => "A 儿 whose tail hooks up is not 金 but slant-plus-cup, 竹山: compare 匹, whose inner 儿 is 金, with 兄, whose hooked 儿 at the foot is 竹山."
          }
        },
        {
          "kind" => "compare",
          "rows" => [
            {
              "char" => "兄",
              "wrong" => "rc",
              "why" => {
                "ru" => "У нижних ножек есть крюк вверх, значит это 竹山, а не 金.",
                "en" => "The legs at the foot hook upward, so they are 竹山, not 金."
              }
            }
          ]
        }
      ],
      bank: %w[金 錢 分 只 四 西 曾 弟 谷 巷 兵 兌 匹 銀 鐘 典]
    )

    b.lesson(
      "d",
      stage: "letters",
      key: "d",
      title: {"ru" => "木 — дерево", "en" => "木 — wood"},
      lede: {
        "ru" => "Само 木, его скелет 十 с крюком, и перекладина с загибом внутри 五 и 快.",
        "en" => "木 itself, its bare 十 skeleton with a hook, and the bent crossbar inside 五 and 快."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "木",
              "rule" => {"ru" => "Дерево целиком", "en" => "The whole tree"},
              "chars" => %w[林 本 果 樹]
            },
            {
              "glyph" => "才",
              "rule" => {
                "ru" => "Скелет дерева: вертикаль с крюком и перекладина",
                "en" => "The bare skeleton: a hooked vertical crossed by a bar"
              },
              "chars" => %w[寸 子 爭 才]
            },
            {
              "glyph" => nil,
              "hint" => {"ru" => "перекладина с загибом", "en" => "the bent crossbar"},
              "rule" => {
                "ru" => "Тот же скелет, положенный набок — середина 五, 也, 快",
                "en" => "The same skeleton lying flat — the middle of 五, 也, 快"
              },
              "chars" => %w[五 也 快 偉]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "本",
              "pieces" => %w[木 一],
              "why" => {
                "ru" => "Дерево, под ним черта. Два кода.",
                "en" => "A tree with a bar under it. Two codes."
              }
            },
            {
              "char" => "寸",
              "pieces" => %w[才 丶],
              "why" => {
                "ru" => "Скелет дерева и точка. Точка — всегда клавиша 戈.",
                "en" => "The wood skeleton and a dot. A dot is always key 戈."
              }
            },
            {
              "char" => "地",
              "pieces" => %w[土 乜 才],
              "why" => {
                "ru" => "Голова 土. В теле 也 сначала петля 心, потом перекладина с загибом — клавиша 木.",
                "en" => "Head 土. In the body 也 comes the loop 心 first, then the bent crossbar — key 木."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Главная развилка книги: 十 без крюка, где вертикаль просто пересекает горизонталь, — это клавиша 十 (古, 車). 十 с крюком или частью дерева — клавиша 木 (寸, 才, 子). Проверяйте, есть ли загиб внизу.",
            "en" => "The sharpest fork in the book: a plain 十 where a vertical simply crosses a bar is key 十 (古, 車). A 十 with a hook, or one that is part of a tree, is key 木 (寸, 才, 子). Look for the bend at the foot."
          }
        },
        {
          "kind" => "compare",
          "rows" => [
            {
              "char" => "寸",
              "wrong" => "ji",
              "why" => {
                "ru" => "Вертикаль загибается — это скелет дерева, а не крестик.",
                "en" => "The vertical bends, so this is the wood skeleton, not a plain cross."
              }
            },
            {
              "char" => "古",
              "wrong" => "dr",
              "why" => {
                "ru" => "Здесь загиба нет, вертикаль прямая — значит 十.",
                "en" => "Here nothing bends and the vertical runs straight, so it is 十."
              }
            }
          ]
        }
      ],
      bank: %w[林 本 果 木 寸 子 才 五 也 地 村 樹 東 來 對 時]
    )

    b.lesson(
      "e",
      stage: "letters",
      key: "e",
      title: {"ru" => "水 — вода", "en" => "水 — water"},
      lede: {
        "ru" => "Вода, боковое 氵, донное 氺 — и, неожиданно, рука 又: 水, сложенное вдвое.",
        "en" => "Water, the side form 氵, the foot form 氺 — and, unexpectedly, the hand 又: 水 folded over itself."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "水",
              "rule" => {"ru" => "Вода целиком", "en" => "Water whole"},
              "chars" => %w[水 冰 泉 永]
            },
            {
              "glyph" => "氵",
              "rule" => {"ru" => "Вода слева", "en" => "Water on the left"},
              "chars" => %w[潮 河 沒 法]
            },
            {
              "glyph" => "氺",
              "rule" => {"ru" => "Вода снизу", "en" => "Water at the foot"},
              "chars" => %w[暴 求 康 隸]
            },
            {
              "glyph" => "又",
              "rule" => {
                "ru" => "Рука: 水, наложенное само на себя",
                "en" => "The hand: 水 laid across itself"
              },
              "chars" => %w[叉 及 隆 取]
            },
            {
              "glyph" => "𡈼",
              "rule" => {
                "ru" => "Вода, сплющенная в перекладину — середина 屬 и 犀",
                "en" => "Water flattened into a bar — the middle of 屬 and 犀"
              },
              "chars" => %w[屬 犀]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "沒",
              "pieces" => %w[氵 𠘨 又],
              "why" => {
                "ru" => "Голова 氵 — один код. В теле 殳 сверху крюк 弓, снизу рука 水.",
                "en" => "The head 氵 is one code. In the body 殳 the hook 弓 sits on top and the hand 水 below."
              }
            },
            {
              "char" => "法",
              "pieces" => %w[氵 土 厶],
              "why" => {
                "ru" => "Тело 去 — это 土 и 厶; 厶 — производная точки, клавиша 戈.",
                "en" => "The body 去 is 土 plus 厶; 厶 derives from the dot, key 戈."
              }
            },
            {
              "char" => "取",
              "pieces" => %w[耳 十 又],
              "why" => {
                "ru" => "Голова 耳 не буква, поэтому берут её первый кусок 「⺊」 и последний 十. Тело 又 — вода.",
                "en" => "The head 耳 is not a letter, so it gives its first piece 「⺊」 and its last 十. The body 又 is water."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Две капли 冫 — не вода. Их разбирают на точку и черту, 戈一: 冰, 冷, 決.",
            "en" => "The two-drop 冫 is not water. It is spelled out as dot plus stroke, 戈一: 冰, 冷, 決."
          }
        }
      ],
      bank: %w[水 冰 永 潮 河 沒 法 求 康 叉 及 取 隆 泉 決 深]
    )

    b.lesson(
      "f",
      stage: "letters",
      key: "f",
      title: {"ru" => "火 — огонь", "en" => "火 — fire"},
      lede: {
        "ru" => "Огонь, его донные четыре точки 灬, и всё семейство 小: 小, ⺌, 业.",
        "en" => "Fire, its four-dot foot 灬, and the whole 小 family: 小, ⺌, 业."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "火",
              "rule" => {"ru" => "Огонь целиком", "en" => "Fire whole"},
              "chars" => %w[火 燒 秋 炎]
            },
            {
              "glyph" => "灬",
              "rule" => {
                "ru" => "Огонь снизу — четыре точки",
                "en" => "Fire at the foot — four dots"
              },
              "chars" => %w[熱 煮 無 然]
            },
            {
              "glyph" => "⺌",
              "rule" => {"ru" => "Верхняя половина огня", "en" => "The upper half of fire"},
              "chars" => %w[平 當 判 常]
            },
            {
              "glyph" => "小",
              "rule" => {
                "ru" => "Малое — то же семейство",
                "en" => "小 belongs to the same family"
              },
              "chars" => %w[不 尖 京 省]
            },
            {
              "glyph" => "八",
              "rule" => {"ru" => "Огонь в подошве знака", "en" => "Fire as the sole of a character"},
              "chars" => %w[戀 變 蠻]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "不",
              "pieces" => %w[一 ⺌],
              "why" => {
                "ru" => "Черта сверху, под ней огрызок огня. Один из самых частых знаков языка — всего два нажатия.",
                "en" => "A bar on top, a stub of fire under it. One of the commonest characters in the language — two presses."
              }
            },
            {
              "char" => "京",
              "pieces" => %w[亠 口 小],
              "why" => {
                "ru" => "Крышка 亠 — клавиша 卜, потом рот, потом 小 — клавиша 火.",
                "en" => "The 亠 lid is key 卜, then the mouth, then 小 as key 火."
              }
            },
            {
              "char" => "當",
              "pieces" => %w[⺌ 冖 口 田],
              "why" => {
                "ru" => "Голова 「⺌冖」 не буква: берут первый кусок 火 и последний 月. Тело — 口 и 田.",
                "en" => "The head 「⺌冖」 is not a letter: take its first piece 火 and its last 月. The body is 口 and 田."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Две точки, расходящиеся врозь 丷, — это 金, а не 火. У 火-формы 「⺌」 посередине есть третий штрих. Сравните 平 (火) и 弟 (金).",
            "en" => "Two dots leaning apart, 丷, are 金, not 火. The fire form 「⺌」 has a third stroke in the middle. Compare 平 (火) with 弟 (金)."
          }
        }
      ],
      bank: %w[火 燒 秋 熱 然 無 不 少 尖 京 平 當 判 常 光 省]
    )

    b.lesson(
      "g",
      stage: "letters",
      key: "g",
      title: {"ru" => "土 — земля", "en" => "土 — earth"},
      lede: {
        "ru" => "Самая простая клавиша книги: 土 и почти неотличимое от него 士.",
        "en" => "The simplest key in the book: 土, and 士, which is barely distinguishable from it."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "土",
              "rule" => {"ru" => "Земля", "en" => "Earth"},
              "chars" => %w[地 場 王 塊]
            },
            {
              "glyph" => "士",
              "rule" => {
                "ru" => "Учёный муж: отличить его от 土 почти невозможно, поэтому обе формы на одной клавише",
                "en" => "The scholar: telling it from 土 is nearly impossible, so both live on one key"
              },
              "chars" => %w[吉 款 喜 志]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "王",
              "pieces" => %w[一 土],
              "why" => {
                "ru" => "Сверху лишняя черта, под ней земля. Поэтому 王 — не одна клавиша, а две.",
                "en" => "One extra bar on top, earth below. That is why 王 is two keys, not one."
              }
            },
            {
              "char" => "吉",
              "pieces" => %w[士 口],
              "why" => {
                "ru" => "Учёный сверху, рот снизу.",
                "en" => "The scholar on top, the mouth below."
              }
            },
            {
              "char" => "在",
              "pieces" => %w[大 中 土],
              "why" => {
                "ru" => "Голова 「𠂇」 — это 大, потом вертикаль 中, и уже потом земля.",
                "en" => "The head 「𠂇」 is 大, then the vertical 中, and only then earth."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "土 стоит на клавише G рядом с 木 (D) и 十 (J). Все три часто встречаются в теле знака подряд: 時 — 日土木戈.",
            "en" => "土 sits on G next to 木 (D) and 十 (J). All three often turn up in a row inside a body: 時 is 日土木戈."
          }
        }
      ],
      bank: %w[土 地 場 王 塊 吉 喜 志 在 去 走 坐 街 幸 款 時]
    )
  end
end
