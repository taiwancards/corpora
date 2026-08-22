# frozen_string_literal: true

require_relative "cangjie_lessons_content"

module CangjieContent
  module_function
  def shapes(b)
    b.lesson(
      "s",
      stage: "letters",
      key: "s",
      title: {"ru" => "尸 — бок 側", "en" => "尸 — the side 側"},
      lede: {
        "ru" => "Полузамкнутый уголок: три стороны есть, четвёртой нет. Куда смотрит проём — неважно.",
        "en" => "A half-closed corner: three sides present, the fourth missing. Which way the gap faces does not matter."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "尸",
              "rule" => {"ru" => "Тело, лежащее на боку", "en" => "A body lying on its side"},
              "chars" => %w[尼 屋 局]
            },
            {
              "glyph" => "コ",
              "rule" => {"ru" => "Уголок, открытый влево", "en" => "A corner open to the left"},
              "chars" => %w[己 帚 局]
            },
            {
              "glyph" => "匚",
              "rule" => {"ru" => "Уголок, открытый вправо", "en" => "A corner open to the right"},
              "chars" => %w[區 匹]
            },
            {
              "glyph" => "𠃌",
              "rule" => {"ru" => "Тот же уголок в виде ножа", "en" => "The same corner as a knife"},
              "chars" => %w[刀 司 分]
            },
            {
              "glyph" => "⺊",
              "rule" => {"ru" => "Лежащее 卜", "en" => "卜 laid on its side"},
              "chars" => %w[非 面 乍]
            },
            {
              "glyph" => "𠃑",
              "rule" => {
                "ru" => "Тот же уголок с двумя перекладинами",
                "en" => "The same corner carrying two bars"
              },
              "chars" => %w[耳 髟 鬚]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "刀",
              "pieces" => %w[𠃌 丿],
              "why" => {
                "ru" => "Уголок и наклонная. Порядок не по письму, а по месту: уголок выше.",
                "en" => "A corner and a slant. Order comes from position, not from handwriting: the corner sits higher."
              }
            },
            {
              "char" => "尼",
              "pieces" => %w[尸 匕],
              "why" => {
                "ru" => "Бок снаружи, ложка внутри.",
                "en" => "The side outside, the spoon inside."
              }
            },
            {
              "char" => "非",
              "pieces" => %w[丨 一 ⺊ 卜],
              "why" => {
                "ru" => "Знак целый — берут подряд слева направо: вертикаль, черта, лежащее 卜, стоящее 卜.",
                "en" => "An unsplittable character taken left to right: vertical, bar, reclining 卜, upright 卜."
              }
            },
            {
              "char" => "區",
              "pieces" => %w[匚 口 口 口],
              "why" => {
                "ru" => "Снаружи внутрь: рамка, потом три рта. Четвёртый код — последний рот.",
                "en" => "Outside in: the frame, then three mouths. The fourth code is the last mouth."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Уголок 尸 не различает направления: 己 открыто влево, 區 — вправо, обе формы на одной клавише. Различать нужно другое — замкнут контур или нет: замкнутый квадрат уходит на 田.",
            "en" => "The 尸 corner does not care which way it opens: 己 opens left, 區 opens right, and both share the key. What matters is whether the outline closes: a closed square goes to 田."
          }
        }
      ],
      bank: %w[尸 尼 屋 己 區 匹 刀 司 分 非 面 乍 那 局 房 耳]
    )

    b.lesson(
      "t",
      stage: "letters",
      key: "t",
      title: {"ru" => "廿 — парность 並", "en" => "廿 — the pair 並"},
      lede: {
        "ru" => "Две одинаковые части бок о бок под общей перекладиной. Сюда же трава 艹 — самая частая форма клавиши.",
        "en" => "Two matching parts side by side under a shared bar. The grass radical 艹 — the key's commonest shape — belongs here too."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "艹",
              "rule" => {"ru" => "Трава сверху", "en" => "Grass on top"},
              "chars" => %w[草 花 菜 英]
            },
            {
              "glyph" => "卄",
              "rule" => {"ru" => "Симметричная пара", "en" => "A symmetric pair"},
              "chars" => %w[華 曲 世]
            },
            {
              "glyph" => "业",
              "rule" => {
                "ru" => "Пара с перекладиной внизу",
                "en" => "A pair with the bar underneath"
              },
              "chars" => %w[並 業 皿]
            },
            {
              "glyph" => "⺷",
              "rule" => {"ru" => "Пара внутри рамки", "en" => "A pair inside a frame"},
              "chars" => %w[典 其 黃]
            },
            {
              "glyph" => "丗",
              "rule" => {
                "ru" => "Старинное написание парности",
                "en" => "The archaic form of the pair"
              },
              "chars" => %w[虛 聯 關]
            },
            {
              "glyph" => "䒑",
              "rule" => {"ru" => "Две точки под чертой", "en" => "Two dots under a bar"},
              "chars" => %w[尊 前 首]
            },
            {
              "glyph" => "廾",
              "rule" => {"ru" => "Две руки снизу", "en" => "Two hands at the foot"},
              "chars" => %w[弄 弁]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "草",
              "pieces" => %w[艹 日 十],
              "why" => {
                "ru" => "Трава — голова, одна клавиша. Тело 早 — солнце и крест.",
                "en" => "Grass is the head, one key. The body 早 is a sun and a cross."
              }
            },
            {
              "char" => "花",
              "pieces" => %w[艹 亻 匕],
              "why" => {
                "ru" => "Трава над 化. Тело — человек и ложка.",
                "en" => "Grass over 化. The body is a person and a spoon."
              }
            },
            {
              "char" => "前",
              "pieces" => %w[䒑 月 丨 亅],
              "why" => {
                "ru" => "Две точки под чертой — голова. Тело: 月 и нож 刂.",
                "en" => "Two dots under a bar make the head. The body: 月 and the knife 刂."
              }
            },
            {
              "char" => "其",
              "pieces" => %w[⺷ 一 一 八],
              "why" => {
                "ru" => "Целый знак: рамка с парой, две черты и две точки снизу.",
                "en" => "An unsplittable character: framed pair, two bars, two dots at the foot."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "廿 стоит на T — рядом с 卜 (Y) и 山 (U). Трава попадается в каждой третьей строке текста, так что клавиша разрабатывается сама собой.",
            "en" => "廿 sits on T, next to 卜 (Y) and 山 (U). Grass shows up in every third line of text, so the key trains itself."
          }
        }
      ],
      bank: %w[廿 草 花 菜 英 華 曲 並 業 典 其 前 首 度 世 藥]
    )

    b.lesson(
      "u",
      stage: "letters",
      key: "u",
      title: {"ru" => "山 — чаша 仰", "en" => "山 — the cup 仰"},
      lede: {
        "ru" => "Полузамкнутая форма, раскрытая вверх. Сюда же петля 乚 и дно 目.",
        "en" => "A half-closed shape opening upward. The loop 乚 and the foot of 目 belong here too."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "山",
              "rule" => {"ru" => "Гора", "en" => "The mountain"},
              "chars" => %w[出 仙 島]
            },
            {
              "glyph" => "凵",
              "rule" => {"ru" => "Чаша, раскрытая вверх", "en" => "A cup open at the top"},
              "chars" => %w[凶 齒 目]
            },
            {
              "glyph" => "乚",
              "rule" => {"ru" => "Петля с крюком вверх", "en" => "A loop hooking upward"},
              "chars" => %w[先 洗 見]
            },
            {
              "glyph" => "屮",
              "rule" => {
                "ru" => "Росток — производная горы; встречается и зеркально",
                "en" => "The sprout, a mountain descendant; it turns up mirrored too"
              },
              "chars" => %w[逆 朔]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "出",
              "pieces" => %w[山 山],
              "why" => {"ru" => "Две горы одна над другой.", "en" => "Two mountains stacked."}
            },
            {
              "char" => "凶",
              "pieces" => %w[凵 乂],
              "why" => {
                "ru" => "Снаружи внутрь: чаша, потом косой крест.",
                "en" => "Outside in: the cup, then the X."
              }
            },
            {
              "char" => "目",
              "pieces" => %w[冂 凵],
              "why" => {
                "ru" => "Плоское 月 сверху, чаша снизу. Именно поэтому 目 — не 日.",
                "en" => "A flat 月 on top, a cup below. That is exactly why 目 is not 日."
              }
            },
            {
              "char" => "想",
              "pieces" => %w[木 凵 心],
              "why" => {
                "ru" => "Голова 相 не буква: первый кусок 木, последний — дно 目, то есть чаша.",
                "en" => "The head 相 is not a letter: first piece 木, last piece the foot of 目, that is the cup."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Ножки 儿 без крюка — это 金 (匹, 四). Ножки с крюком вверх — это 竹山 (兄, 見, 先). Крюк решает всё.",
            "en" => "Legs 儿 with no hook are 金 (匹, 四). Legs that hook upward are 竹山 (兄, 見, 先). The hook decides."
          }
        }
      ],
      bank: %w[山 出 仙 凶 齒 先 洗 見 想 目 完 塊 島 幽 兄 現]
    )

    b.lesson(
      "v",
      stage: "letters",
      key: "v",
      title: {"ru" => "女 — петля 紐", "en" => "女 — the loop 紐"},
      lede: {
        "ru" => "Завязанный узел: черта, которая изгибается и возвращается. Сюда же 幺, низ 衣 и уголок 𠃊.",
        "en" => "A tied knot: a stroke that bends and comes back. 幺, the foot of 衣 and the corner 𠃊 join it."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "女",
              "rule" => {"ru" => "Женщина", "en" => "The woman"},
              "chars" => %w[好 姐 媽]
            },
            {
              "glyph" => "幺",
              "rule" => {
                "ru" => "Моток нити — 女戈, два кода",
                "en" => "A skein of thread — 女戈, two codes"
              },
              "chars" => %w[幼 幾 鄉]
            },
            {
              "glyph" => "𧘇",
              "rule" => {"ru" => "Низ одежды", "en" => "The foot of a garment"},
              "chars" => %w[衣 良 表]
            },
            {
              "glyph" => "𠃊",
              "rule" => {"ru" => "Уголок без крюка вверх", "en" => "A corner that does not hook up"},
              "chars" => %w[以 民 收]
            },
            {
              "glyph" => "く",
              "rule" => {
                "ru" => "Тот же узел одной чертой",
                "en" => "The same knot in a single stroke"
              },
              "chars" => %w[邕 巡 甾]
            },
            {
              "glyph" => "乚",
              "rule" => {"ru" => "Изменённый узел", "en" => "The knot reshaped"},
              "chars" => %w[兮 互]
            },
            {
              "glyph" => "乀",
              "rule" => {"ru" => "Откос вправо вниз", "en" => "A stroke falling to the right"},
              "chars" => %w[鼠 獵]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "好",
              "pieces" => %w[女 𠃌 才],
              "why" => {
                "ru" => "Женщина — голова. Тело 子 — крюк и скелет дерева.",
                "en" => "The woman is the head. The body 子 is a hook and the wood skeleton."
              }
            },
            {
              "char" => "表",
              "pieces" => %w[龵 一 𧘇],
              "why" => {
                "ru" => "Целый знак: рука, черта, низ одежды.",
                "en" => "An unsplittable character: hand, bar, garment foot."
              }
            },
            {
              "char" => "銀",
              "pieces" => %w[釒 日 𧘇],
              "why" => {
                "ru" => "Металл — голова. Тело 艮 — солнце и низ одежды.",
                "en" => "Metal is the head. The body 艮 is a sun and a garment foot."
              }
            },
            {
              "char" => "灣",
              "pieces" => %w[氵 幺 火 弓],
              "why" => {
                "ru" => "Вода — голова. Тело 彎 длинное: первый кусок 幺, второй 火, последний 弓.",
                "en" => "Water is the head. The body 彎 is long: first piece 幺, second 火, last 弓."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Петля 乚 с крюком вверх — это 山 (先, 見). Уголок 𠃊 без крюка — это 女 (以, 民, 收).",
            "en" => "The loop 乚 that hooks upward is 山 (先, 見). The corner 𠃊 with no hook is 女 (以, 民, 收)."
          }
        }
      ],
      bank: %w[女 好 姐 媽 幼 幾 鄉 衣 良 表 以 民 收 銀 很 灣]
    )

    b.lesson(
      "w",
      stage: "letters",
      key: "w",
      title: {"ru" => "田 — квадрат 方", "en" => "田 — the square 方"},
      lede: {
        "ru" => "Замкнутая прямоугольная рамка. Если внутри рамки есть хоть что-нибудь — это 田, а не 口.",
        "en" => "A closed rectangular frame. If there is anything at all inside the frame, it is 田 and not 口."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "田",
              "rule" => {"ru" => "Поле", "en" => "The field"},
              "chars" => %w[男 界 果]
            },
            {
              "glyph" => "囗",
              "rule" => {
                "ru" => "Пустая рамка вокруг начинки",
                "en" => "An empty frame around a filling"
              },
              "chars" => %w[國 回 因 四]
            },
            {
              "glyph" => "罒",
              "rule" => {"ru" => "Приплюснутое поле", "en" => "The field flattened"},
              "chars" => %w[買 黑]
            },
            {
              "glyph" => "母",
              "rule" => {"ru" => "Мать — тоже рамка", "en" => "Mother is a frame as well"},
              "chars" => %w[母 每 海]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "回",
              "pieces" => %w[囗 口],
              "why" => {
                "ru" => "Внешняя рамка — 田, внутренняя пустая — 口. Один знак, обе клавиши.",
                "en" => "The outer frame is 田, the empty inner one is 口. One character, both keys."
              }
            },
            {
              "char" => "國",
              "pieces" => %w[囗 戈 口 一],
              "why" => {
                "ru" => "Рамка снаружи, потом начинка 或 — три кода: копьё, рот, черта.",
                "en" => "The frame outside, then the filling 或 in three codes: halberd, mouth, bar."
              }
            },
            {
              "char" => "果",
              "pieces" => %w[田 木],
              "why" => {
                "ru" => "Поле над деревом. А 東 — наоборот: дерево, сквозь которое проходит поле.",
                "en" => "A field over a tree. 東 is the other way round: a tree with a field run through it."
              }
            },
            {
              "char" => "四",
              "pieces" => %w[囗 儿],
              "why" => {
                "ru" => "Рамка и ножки без крюка — 田金.",
                "en" => "Frame plus unhooked legs — 田金."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Различайте 田 и 日: у 田 внутри крест, у 日 — одна перекладина и никакой вертикали. И 甲 — это 田中, а не 日中.",
            "en" => "Tell 田 from 日: 田 has a cross inside, 日 has one bar and no vertical. And 甲 is 田中, not 日中."
          }
        }
      ],
      bank: %w[田 男 界 果 國 回 因 四 母 每 海 買 東 西 甲 黑]
    )

    b.lesson(
      "y",
      stage: "letters",
      key: "y",
      title: {"ru" => "卜 — гадательная кость", "en" => "卜 — the divining stick"},
      lede: {
        "ru" => "Черта с точкой сбоку. Отсюда крышка 亠 и дорога 辶 — вторая по частоте форма во всём тексте.",
        "en" => "A stroke with a dot beside it. From it come the lid 亠 and the road 辶 — the second most frequent shape in running text."
      },
      blocks: [
        {
          "kind" => "shapes",
          "rows" => [
            {
              "glyph" => "卜",
              "rule" => {"ru" => "Кость стоя", "en" => "The stick upright"},
              "chars" => %w[卡 外 占]
            },
            {
              "glyph" => "⺊",
              "rule" => {"ru" => "Кость с точкой слева", "en" => "The stick with the dot on the left"},
              "chars" => %w[上 走 卓]
            },
            {
              "glyph" => "亠",
              "rule" => {
                "ru" => "Крышка: та же кость, положенная набок",
                "en" => "The lid: the same stick laid flat"
              },
              "chars" => %w[言 高 京]
            },
            {
              "glyph" => "辶",
              "rule" => {"ru" => "Дорога", "en" => "The road"},
              "chars" => %w[這 過 送 進]
            },
            {
              "glyph" => "冫",
              "rule" => {
                "ru" => "Сжатая крышка: две капли сверху или снизу знака",
                "en" => "The lid squashed: two drops above or below a character"
              },
              "chars" => %w[雨 冬 寒]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "上",
              "pieces" => %w[⺊ 一],
              "why" => {"ru" => "Кость и черта под ней.", "en" => "The stick and a bar under it."}
            },
            {
              "char" => "主",
              "pieces" => %w[丶 土],
              "why" => {
                "ru" => "Точка сверху — не 戈, а сплющенная крышка. Поэтому 卜土, а не 戈土.",
                "en" => "The dot on top is not 戈 but a squashed lid. Hence 卜土, not 戈土."
              }
            },
            {
              "char" => "這",
              "pieces" => %w[辶 亠 一 口],
              "why" => {
                "ru" => "Дорога охватывает знак снаружи — значит она голова. Тело 言: крышка, черта, рот.",
                "en" => "The road wraps the character, so it is the head. The body 言: lid, bar, mouth."
              }
            },
            {
              "char" => "京",
              "pieces" => %w[亠 口 小],
              "why" => {
                "ru" => "Крышка, рот, 小 — сверху вниз, три кода.",
                "en" => "Lid, mouth, 小 — top to bottom, three codes."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Дорога 辶 всегда голова, хотя пишется последней. Порядок цанцзе — по месту на бумаге, а не по руке.",
            "en" => "The road 辶 is always the head even though it is written last. Cangjie order follows the page, not the hand."
          }
        }
      ],
      bank: %w[卜 卡 外 占 上 走 卓 言 高 京 這 過 送 進 主 雨]
    )
  end

  def special(b)
    b.lesson(
      "x",
      stage: "letters",
      key: "x",
      title: {"ru" => "難 — заглушка X", "en" => "難 — the X placeholder"},
      lede: {
        "ru" => "X — не форма. Это признание: «этот кусок слишком мелко дробится, берём заглушку».",
        "en" => "X is not a shape. It is an admission: “this piece is too fiddly to spell out, take a placeholder.”"
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "Первый плюс 難", "en" => "First plus 難"},
              "text" => {
                "ru" => "Если и конец знака неочевиден, берут всего два кода.",
                "en" => "When even the tail is unclear, only two codes are taken."
              },
              "chars" => %w[臼 肅 卍 齊]
            },
            {
              "title" => {"ru" => "Первый, 難, последний", "en" => "First, 難, last"},
              "text" => {
                "ru" => "Если начало и конец берутся легко, а середина нет, — три кода.",
                "en" => "When the head and the tail are easy but the middle is not — three codes."
              },
              "chars" => %w[身 慶 鹿 廌 龜 黽 兼]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "身",
              "pieces" => %w[丿 難 丿],
              "why" => {
                "ru" => "Наклонная сверху, наклонная снизу, а середина заменена заглушкой.",
                "en" => "A slant on top, a slant at the foot, and a placeholder for the middle."
              }
            },
            {
              "char" => "廉",
              "pieces" => %w[广 廿 難 八],
              "why" => {
                "ru" => "Навес — голова. Тело 兼 — трудный знак: 廿, заглушка, 八.",
                "en" => "The awning is the head. The body 兼 is a hard character: 廿, placeholder, 八."
              }
            },
            {
              "char" => "姊",
              "pieces" => %w[女 丨 難 丿],
              "why" => {
                "ru" => "Женщина — голова. Тело трудное, и берут вертикаль, заглушку, наклонную.",
                "en" => "The woman is the head. The body is hard, so: vertical, placeholder, slant."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Список трудных знаков закрытый: 臼, 肅, 卍, 齊, 身, 慶, 廌, 鹿, 龜, 黽, 兼 и ещё пара форм. Подставлять X по своему усмотрению нельзя — код просто не найдётся.",
            "en" => "The list of hard characters is closed: 臼, 肅, 卍, 齊, 身, 慶, 廌, 鹿, 龜, 黽, 兼 and a couple more. Do not add your own X — the code simply will not exist."
          }
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Ту же клавишу X таблица использует вторым способом — как метку повтора. Об этом следующий урок.",
            "en" => "The table uses the same X key for a second job — as a repeat marker. That is the next lesson."
          }
        }
      ],
      bank: %w[齊 肅 身 慶 鹿 兼 廉 姊 淵 龜 黽 廌 卍 臼]
    )

    b.lesson(
      "z",
      stage: "letters",
      key: "z",
      title: {"ru" => "重 — клавиша, которой нет", "en" => "重 — the key that is not there"},
      lede: {
        "ru" => "На раскладке Z подписана 重, но иероглифов она не набирает: официальная таблица отдаёт её под словосочетания и самодельные знаки.",
        "en" => "The Z keycap reads 重, yet it types no characters: the official table hands it to phrases and user-made glyphs."
      },
      blocks: [
        {
          "kind" => "prose",
          "text" => {
            "ru" => "Иногда два разных иероглифа честно получают один и тот же код. Тогда частотный остаётся как есть, а редкий получает впереди метку повтора — и метка эта набирается клавишей X, той же, что и 難. Если из-за неё код перевалит за пять, последний код отбрасывают.",
            "en" => "Now and then two different characters honestly earn the same code. The frequent one keeps it; the rare one gets a repeat marker in front — and that marker is typed with X, the same key as 難. If the marker pushes the code past five, the last code is dropped."
          }
        },
        {
          "kind" => "compare",
          "rows" => [
            {
              "char" => "晾",
              "wrong" => "ayrf",
              "why" => {
                "ru" => "日卜口火 уже занято знаком 景, который встречается чаще. 晾 получает ту же цепочку с меткой впереди.",
                "en" => "日卜口火 already belongs to 景, which is far commoner. 晾 takes the same chain with a marker in front."
              }
            },
            {
              "char" => "筍",
              "wrong" => "hpa",
              "why" => {
                "ru" => "竹心日 занято знаком 昏. Тот же приём.",
                "en" => "竹心日 belongs to 昏. Same trick."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "На практике метка нужна редко: в тренажёре наберите обычный код и пролистайте кандидатов — редкий знак стоит там вторым или третьим.",
            "en" => "In practice the marker is seldom needed: type the plain code in the trainer and scroll the candidates — the rare character sits second or third."
          }
        }
      ],
      bank: %w[景 晾 昏 筍 夷]
    )
  end
end
