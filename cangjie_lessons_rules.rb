# frozen_string_literal: true

require_relative "cangjie_lessons_content"

module CangjieContent
  module_function
  def rules(b)
    b.lesson(
      "whole",
      stage: "splitting",
      title: {"ru" => "Целые знаки", "en" => "Unsplittable characters"},
      lede: {
        "ru" => "Некоторые знаки не режутся ни вертикально, ни горизонтально. Голову и тело у них не ищут — берут куски подряд.",
        "en" => "Some characters will not cut vertically or horizontally. They have no head and body: their pieces are simply taken in order."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "Черты сцеплены", "en" => "The strokes interlock"},
              "text" => {
                "ru" => "Разрезать нечего: черты проходят сквозь друг друга.",
                "en" => "There is nothing to cut: the strokes run through one another."
              },
              "chars" => %w[我 更 才 韭 重 凸 凹]
            },
            {
              "title" => {"ru" => "Форма единая", "en" => "The form reads as one"},
              "text" => {
                "ru" => "Сцеплено не всё, но знак воспринимается как одна фигура.",
                "en" => "Not everything is joined, yet the character reads as a single figure."
              },
              "chars" => %w[島 烏 焉 來 乖 坐]
            }
          ]
        },
        {
          "kind" => "prose",
          "text" => {
            "ru" => "Целый знак берёт до четырёх кодов. Если кусков четыре или меньше — берут все подряд. Если больше — первый, второй, третий и последний, а середина выбрасывается.",
            "en" => "An unsplittable character takes up to four codes. Four pieces or fewer: take them all in order. More than that: first, second, third and last, and the middle is dropped."
          }
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "甩",
              "pieces" => %w[冂 龵 乚],
              "why" => {
                "ru" => "Снаружи внутрь, потом сверху вниз. Три куска — три кода.",
                "en" => "Outside in, then top to bottom. Three pieces, three codes."
              }
            },
            {
              "char" => "乖",
              "pieces" => %w[丿 十 丨 匕],
              "why" => {
                "ru" => "Сначала целиком 千, потом 北. Ровно четыре кода.",
                "en" => "First 千 whole, then 北. Exactly four codes."
              }
            },
            {
              "char" => "烏",
              "pieces" => %w[丿 口 ⺊ 灬],
              "why" => {
                "ru" => "Наклонная, рот, лежащая кость, четыре точки — знак не режется.",
                "en" => "Slant, mouth, reclining stick, four dots — the character will not split."
              }
            },
            {
              "char" => "韭",
              "pieces" => %w[丨 ⺊ 一 一],
              "why" => {
                "ru" => "Кусков больше четырёх, поэтому середина отброшена, а последний код сохранён.",
                "en" => "There are more than four pieces, so the middle is dropped and the last code kept."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Если целый знак стоит наверху составного, головой становится он весь: у 意 голова — 音, у 勇 — 甬, у 普 — 並.",
            "en" => "When an unsplittable character sits on top of a compound one, the whole thing becomes the head: 意 takes 音, 勇 takes 甬, 普 takes 並."
          }
        }
      ],
      bank: %w[我 更 才 重 凸 凹 島 烏 焉 來 乖 坐 甩 韭 直 非]
    )

    b.lesson(
      "body-three",
      stage: "splitting",
      title: {"ru" => "Тело из трёх кодов", "en" => "A three-code body"},
      lede: {
        "ru" => "Когда тело само делится надвое, три кода берутся по строгой схеме. Это единственное место, где нужна память, а не глаз.",
        "en" => "When the body itself divides in two, its three codes follow a strict scheme. This is the one place where memory matters more than the eye."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "Тело не делится", "en" => "The body does not divide"},
              "text" => {
                "ru" => "Первый, второй, последний кусок.",
                "en" => "First piece, second piece, last piece."
              },
              "chars" => %w[根 盛 員 牌]
            },
            {
              "title" => {
                "ru" => "Голова тела — один код",
                "en" => "The body's own head takes one code"
              },
              "text" => {
                "ru" => "Эта голова, затем первый и последний кусок остатка.",
                "en" => "That head, then the first and last piece of what is left."
              },
              "chars" => %w[這 嘻 命 強]
            },
            {
              "title" => {
                "ru" => "Голова тела — два кода",
                "en" => "The body's own head takes two codes"
              },
              "text" => {
                "ru" => "Первый и последний кусок этой головы, затем последний кусок остатка.",
                "en" => "The first and last piece of that head, then the last piece of the remainder."
              },
              "chars" => %w[婚 倒 藥 參]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "這",
              "pieces" => %w[辶 亠 一 口],
              "why" => {
                "ru" => "Голова знака — дорога. Тело 言 делится: его голова 亠 стоит один код, дальше первый и последний кусок остатка.",
                "en" => "The character's head is the road. The body 言 divides: its own head 亠 is one code, then the first and last piece of the rest."
              }
            },
            {
              "char" => "婚",
              "pieces" => %w[女 丿 匕 日],
              "why" => {
                "ru" => "Тело 昏 делится на 氏 и 日. Голова тела 氏 стоит два кода — 竹 и 心, — поэтому от остатка берут только последний.",
                "en" => "The body 昏 divides into 氏 and 日. That head 氏 costs two codes — 竹 and 心 — so only the last piece of the rest is taken."
              }
            },
            {
              "char" => "倒",
              "pieces" => %w[亻 一 土 亅],
              "why" => {
                "ru" => "Тело 到 делится на 至 и 刂. 至 стоит два кода, остаток даёт последний.",
                "en" => "The body 到 divides into 至 and 刂. 至 costs two codes, the remainder gives its last."
              }
            },
            {
              "char" => "根",
              "pieces" => %w[木 日 𧘇],
              "why" => {
                "ru" => "Тело 艮 не делится, поэтому просто первый и последний кусок.",
                "en" => "The body 艮 does not divide, so simply its first and last piece."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Схема запоминается через сумму: голова тела и остаток вместе всегда дают ровно три кода. Один плюс два или два плюс один.",
            "en" => "Remember it as a sum: the body's head and the remainder always add up to exactly three codes. One plus two, or two plus one."
          }
        }
      ],
      bank: %w[根 盛 員 這 嘻 命 婚 倒 藥 參 強 牌 讓 稼 排 藍]
    )

    b.lesson(
      "complete",
      stage: "splitting",
      title: {"ru" => "Правило целостности", "en" => "The completeness rule"},
      lede: {
        "ru" => "Когда часть знака можно прочитать двумя способами, выбирают тот, что сохраняет очертание целиком. Это главное правило цанцзе.",
        "en" => "When a part can be read two ways, take the reading that keeps the outline whole. This is the central rule of Cangjie."
      },
      blocks: [
        {
          "kind" => "compare",
          "title" => {
            "ru" => "Слева верно, справа — так делают новички",
            "en" => "Right on the left, beginner's guess on the right"
          },
          "rows" => [
            {
              "char" => "目",
              "wrong" => "bm",
              "why" => {
                "ru" => "Снизу видна чаша целиком, а не одинокая черта.",
                "en" => "What shows at the foot is a whole cup, not a lone bar."
              }
            },
            {
              "char" => "米",
              "wrong" => "cd",
              "why" => {
                "ru" => "Верх — 「⺌」 с третьим штрихом, значит 火, а не две точки 金.",
                "en" => "The top is 「⺌」 with its third stroke, so 火, not the two-dot 金."
              }
            },
            {
              "char" => "生",
              "wrong" => "hjg",
              "why" => {
                "ru" => "Средняя часть — цельная рука 龵, её незачем резать на 十 и 土.",
                "en" => "The middle is a whole hand 龵; there is no reason to cut it into 十 and 土."
              }
            },
            {
              "char" => "永",
              "wrong" => "ime",
              "why" => {
                "ru" => "Второй кусок — крюк, сохраняющий изгиб, а не плоская черта.",
                "en" => "The second piece is a hook that keeps its bend, not a flat bar."
              }
            },
            {
              "char" => "由",
              "wrong" => "la",
              "why" => {
                "ru" => "Внутри рамки есть черта — значит 田, а не 日.",
                "en" => "There is a bar inside the frame, so 田 and not 日."
              }
            },
            {
              "char" => "力",
              "wrong" => "kn",
              "why" => {
                "ru" => "Нижняя часть — уголок 尸 целиком, а не голый крюк.",
                "en" => "The lower part is the whole 尸 corner, not a bare hook."
              }
            },
            {
              "char" => "巳",
              "wrong" => "su",
              "why" => {
                "ru" => "Верх замкнут со всех сторон — это рот, а не полуоткрытый уголок.",
                "en" => "The top closes on every side: a mouth, not a half-open corner."
              }
            },
            {
              "char" => "民",
              "wrong" => "svp",
              "why" => {
                "ru" => "То же самое: замкнутый верх — 口.",
                "en" => "Same thing: a closed top is 口."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "У правила две границы. Оно не должно ломать характер знака: 之 набирается 戈弓人, потому что вариант с крышкой 卜 уничтожил бы узнаваемое начало. И оно не должно удлинять код: 云 — это 一一戈, а не 一厂丶戈.",
            "en" => "The rule has two limits. It must not destroy what makes a character recognisable: 之 is typed 戈弓人, because starting with the 卜 lid would wipe out its opening. And it must not lengthen the code: 云 is 一一戈, not 一厂丶戈."
          }
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "Проверьте себя", "en" => "Check yourself"},
          "chars" => %w[之 云 育 者 爭 九 毛 乍]
        }
      ],
      bank: %w[目 米 生 永 由 力 巳 民 之 云 育 者 爭 九 毛 乍]
    )

    b.lesson(
      "omit",
      stage: "splitting",
      title: {"ru" => "Правило пропуска", "en" => "The omission rule"},
      lede: {
        "ru" => "Голова даёт максимум два кода, тело — максимум три. Всё, что не поместилось, просто выбрасывается — и на дальнейший разбор это не влияет.",
        "en" => "The head gives at most two codes, the body at most three. Whatever does not fit is simply dropped — and it changes nothing further down."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "Пропуск в голове", "en" => "Omission in the head"},
              "text" => {
                "ru" => "У 鬱 голова 木缶木 — берут только 木 и 木. У 顯 голова даёт 日 и 灬.",
                "en" => "The head of 鬱 is 木缶木 — only 木 and 木 are taken. The head of 顯 gives 日 and 灬."
              },
              "chars" => %w[鬱 顯 梨 欺]
            },
            {
              "title" => {"ru" => "Пропуск в теле", "en" => "Omission in the body"},
              "text" => {
                "ru" => "У 僅 тело 堇 длинное: 廿, 中, 一. У 睡 тело 垂 — 竹, 十, 一.",
                "en" => "The body 堇 of 僅 is long: 廿, 中, 一. The body 垂 of 睡 gives 竹, 十, 一."
              },
              "chars" => %w[僅 睡 讓 藍]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "梨",
              "pieces" => %w[丿 亅 木],
              "why" => {
                "ru" => "Голова 利 — не буква, поэтому от неё остаются только первый кусок 丿 и последний 亅. Тело 木 берётся целиком.",
                "en" => "The head 利 is not a letter, so only its first piece 丿 and its last 亅 survive. The body 木 is taken whole."
              }
            },
            {
              "char" => "鬱",
              "pieces" => %w[木 木 冂 凵 丿],
              "why" => {
                "ru" => "От головы 林缶 остались два дерева. Тело даёт свои три кода, как ни в чём не бывало.",
                "en" => "Two trees survive from the head. The body still gives its own three codes, unaffected."
              }
            },
            {
              "char" => "讓",
              "pieces" => %w[亠 口 亠 口 𧘇],
              "why" => {
                "ru" => "Голова 言 даёт 卜 и 口. Тело 襄 — свои три: 卜, 口, 女.",
                "en" => "The head 言 gives 卜 and 口. The body 襄 gives its own three: 卜, 口, 女."
              }
            },
            {
              "char" => "睡",
              "pieces" => %w[冂 凵 丿 十 一],
              "why" => {
                "ru" => "Голова 目 — два кода, тело 垂 — три. Ровно пять, потолок.",
                "en" => "The head 目 takes two codes, the body 垂 three. Exactly five, the ceiling."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Выброшенные куски не «сдвигают» остальные. Тело всегда считается заново, от своего начала.",
            "en" => "Dropped pieces do not shift the rest along. The body is always counted afresh, from its own beginning."
          }
        }
      ],
      bank: %w[鬱 顯 梨 欺 僅 睡 讓 藍 稼 排 期 基 灣 臺 說 過]
    )

    b.lesson(
      "contain",
      stage: "splitting",
      title: {"ru" => "Пропуск начинки", "en" => "Skipping the filling"},
      lede: {
        "ru" => "Отдельное правило для оболочек. Когда последний код упирается в замкнутую или полузамкнутую форму, берут только её контур, а всё внутри пропускают.",
        "en" => "A rule of its own for shells. When the last code lands on a closed or half-closed shape, take only its outline and skip everything inside."
      },
      blocks: [
        {
          "kind" => "outlines",
          "title" => {
            "ru" => "Оболочки, которые прячут начинку",
            "en" => "The shells that hide their filling"
          },
          "rows" => [
            {"glyph" => "口", "rule" => {"ru" => "рот", "en" => "mouth"}},
            {"glyph" => "冂", "rule" => {"ru" => "оболочка", "en" => "shell"}},
            {"glyph" => "コ", "rule" => {"ru" => "уголок влево", "en" => "corner left"}},
            {"glyph" => "匚", "rule" => {"ru" => "уголок вправо", "en" => "corner right"}},
            {"glyph" => "廿", "rule" => {"ru" => "парность", "en" => "the pair"}},
            {"glyph" => "力", "rule" => {"ru" => "сила", "en" => "strength"}},
            {"glyph" => "几", "rule" => {"ru" => "столик", "en" => "the stool"}},
            {"glyph" => "勹", "rule" => {"ru" => "обёртка", "en" => "the wrap"}},
            {"glyph" => "乃", "rule" => {"ru" => "乃", "en" => "乃"}}
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "粵",
              "pieces" => %w[丿 田 一 𠃊 コ],
              "why" => {
                "ru" => "Последний код — уголок コ. Дерево внутри него не набирается.",
                "en" => "The last code is the コ corner. The tree inside it is never typed."
              }
            },
            {
              "char" => "夠",
              "pieces" => %w[𠂊 𠂊 勹 口],
              "why" => {
                "ru" => "Последний код тела — обёртка 勹, а точка внутри пропущена.",
                "en" => "The body's last code is the 勹 wrap; the dot inside it is skipped."
              }
            },
            {
              "char" => "澳",
              "pieces" => %w[氵 丿 冂 大],
              "why" => {
                "ru" => "Внутри 冂 сидит 米, но берут оболочку — и сразу дальше.",
                "en" => "米 sits inside 冂, yet only the shell is taken, and on we go."
              }
            },
            {
              "char" => "藏",
              "pieces" => %w[艹 戈 𠂆 匚],
              "why" => {
                "ru" => "Последний код — уголок 匚; вертикаль внутри него не считается.",
                "en" => "The last code is the 匚 corner; the vertical inside it does not count."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Правило работает только на последнем коде — голова, голова тела или тело, всё равно, но именно на последнем. В середине кода оболочка разбирается как обычно.",
            "en" => "The rule only fires on the last code — of the head, of the body's head, or of the body — but only there. Mid-code, a shell is spelled out as usual."
          }
        }
      ],
      bank: %w[粵 船 夠 颱 歐 盈 牆 侮 麗 澳 欄 呃 揭 藏 罕 甩]
    )
  end

  def exceptions(b)
    b.lesson(
      "compound-heads",
      stage: "exceptions",
      title: {"ru" => "Составные головы", "en" => "Compound heads"},
      lede: {
        "ru" => "Восемь форм, которые в роли головы считаются одним целым: берут только их первый и последний код.",
        "en" => "Eight shapes that count as one whole when they act as a head: only their first and last code are taken."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "麻 → 戈金", "en" => "麻 → 戈金"},
              "text" => {"ru" => "Верх 麼, 磨, 摩.", "en" => "The top of 麼, 磨, 摩."},
              "chars" => %w[麼 磨 摩]
            },
            {
              "title" => {"ru" => "麻 → 戈木", "en" => "麻 → 戈木"},
              "text" => {"ru" => "Тот же навес с деревьями.", "en" => "The same awning with trees."},
              "chars" => %w[麻 嘛]
            },
            {
              "title" => {"ru" => "厭 → 一大", "en" => "厭 → 一大"},
              "text" => {"ru" => "Голова 壓.", "en" => "The head of 壓."},
              "chars" => %w[壓 厭]
            },
            {
              "title" => {"ru" => "辰 → 一女", "en" => "辰 → 一女"},
              "text" => {"ru" => "Голова 蜃, 褥.", "en" => "The head of 蜃, 褥."},
              "chars" => %w[辰 農]
            },
            {
              "title" => {"ru" => "气 → 人弓", "en" => "气 → 人弓"},
              "text" => {"ru" => "Голова 氣, 氧.", "en" => "The head of 氣, 氧."},
              "chars" => %w[氣 氧]
            },
            {
              "title" => {"ru" => "合 → 人口", "en" => "合 → 人口"},
              "text" => {"ru" => "Голова 盒, 搶.", "en" => "The head of 盒."},
              "chars" => %w[合 盒]
            },
            {
              "title" => {"ru" => "羽 → 尸一", "en" => "羽 → 尸一"},
              "text" => {"ru" => "Голова 習.", "en" => "The head of 習."},
              "chars" => %w[羽 習]
            },
            {
              "title" => {"ru" => "薛 → 廿十", "en" => "薛 → 廿十"},
              "text" => {"ru" => "Голова 孽.", "en" => "The head of 孽."},
              "chars" => %w[薛]
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Сокращение работает, только когда форма стоит головой. Отдельно или телом она набирается обычным порядком: 麻 сама по себе — 戈木木, а 合 — 人一口.",
            "en" => "The shortcut applies only when the shape is a head. Standing alone or serving as a body it is typed the ordinary way: 麻 by itself is 戈木木, and 合 is 人一口."
          }
        },
        {
          "kind" => "compare",
          "rows" => [
            {
              "char" => "麻",
              "wrong" => "id",
              "why" => {
                "ru" => "Отдельный знак — полный код, а не сокращённая голова.",
                "en" => "On its own the character takes the full code, not the shortened head."
              }
            },
            {
              "char" => "合",
              "wrong" => "or",
              "why" => {
                "ru" => "Здесь 合 — самостоятельный знак, значит 人一口.",
                "en" => "Here 合 stands alone, so 人一口."
              }
            }
          ]
        }
      ],
      bank: %w[麼 磨 摩 麻 壓 厭 辰 農 氣 氧 合 盒 羽 習 薛 嘛]
    )

    b.lesson(
      "compound",
      stage: "exceptions",
      title: {"ru" => "Составные знаки", "en" => "Compound characters"},
      lede: {
        "ru" => "Семь форм, которые всегда — где угодно в знаке — берут ровно два кода: первый и последний.",
        "en" => "Seven shapes that always take exactly two codes — first and last — wherever they turn up."
      },
      blocks: [
        {
          "kind" => "steps",
          "rows" => [
            {
              "title" => {"ru" => "門 → 日弓", "en" => "門 → 日弓"},
              "text" => {
                "ru" => "Ворота: и сами по себе, и в любом знаке.",
                "en" => "The gate, alone or inside anything."
              },
              "chars" => %w[門 間 問 開 關 們]
            },
            {
              "title" => {"ru" => "阝 → 弓中", "en" => "阝 → 弓中"},
              "text" => {
                "ru" => "Холм слева и посёлок справа — одно и то же.",
                "en" => "The mound on the left and the town on the right are the same shape."
              },
              "chars" => %w[阿 除 那 鄉]
            },
            {
              "title" => {"ru" => "隹 → 人土", "en" => "隹 → 人土"},
              "text" => {"ru" => "Короткохвостая птица.", "en" => "The short-tailed bird."},
              "chars" => %w[隹 售 雄 進]
            },
            {
              "title" => {"ru" => "幾 → 女戈", "en" => "幾 → 女戈"},
              "text" => {
                "ru" => "В составе знака — два кода.",
                "en" => "Inside a character, two codes."
              },
              "chars" => %w[機 畿]
            },
            {
              "title" => {"ru" => "虍 → 卜心", "en" => "虍 → 卜心"},
              "text" => {"ru" => "Тигриная шкура.", "en" => "The tiger's hide."},
              "chars" => %w[虎 處 虛]
            },
            {
              "title" => {"ru" => "鬥 → 中弓", "en" => "鬥 → 中弓"},
              "text" => {
                "ru" => "Драка: две руки друг против друга.",
                "en" => "The brawl: two hands facing off."
              },
              "chars" => %w[鬧]
            }
          ]
        },
        {
          "kind" => "walk",
          "rows" => [
            {
              "char" => "問",
              "pieces" => %w[日 弓 口],
              "why" => {
                "ru" => "Ворота — голова и всегда два кода. Тело 口 — один.",
                "en" => "The gate is the head and always two codes. The body 口 is one."
              }
            },
            {
              "char" => "除",
              "pieces" => %w[弓 中 人 一 木],
              "why" => {
                "ru" => "Холм слева — два кода, тело 余 — три. Пять, потолок.",
                "en" => "The mound on the left is two codes, the body 余 is three. Five, the ceiling."
              }
            },
            {
              "char" => "機",
              "pieces" => %w[木 女 戈 丶],
              "why" => {
                "ru" => "Дерево — голова. Тело 幾 как составной знак даёт 女戈, дальше последний кусок.",
                "en" => "The tree is the head. The body 幾, being a compound, gives 女戈, then the last piece."
              }
            },
            {
              "char" => "處",
              "pieces" => %w[卜 心 丿 又 乁],
              "why" => {
                "ru" => "Шкура тигра — два кода головы, дальше тело 処.",
                "en" => "The tiger hide is the head's two codes, then the body 処."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Отличие от составных голов простое: составная голова сокращается только наверху, а составной знак — всегда и везде.",
            "en" => "The difference from compound heads is simple: a compound head shortens only at the top, a compound character shortens everywhere."
          }
        }
      ],
      bank: %w[門 間 問 開 關 們 阿 除 那 隹 售 雄 機 虎 處 鬧]
    )

    b.lesson(
      "special-chars",
      stage: "exceptions",
      title: {"ru" => "Прошитые знаки", "en" => "Threaded characters"},
      lede: {
        "ru" => "Пять форм — 木, 火, 戈, 大, 七 — если сквозь них проходит посторонняя черта, берутся первыми и целиком, а остаток разбирается отдельно.",
        "en" => "Five shapes — 木, 火, 戈, 大, 七 — when a foreign stroke runs through them, are taken first and whole, and the remainder is read on its own."
      },
      blocks: [
        {
          "kind" => "grid",
          "title" => {"ru" => "Все прошитые знаки", "en" => "The whole list"},
          "chars" => %w[束 末 朿 來 東 柬 秉 乘 爽 奭 夷 夾 屯]
        },
        {
          "kind" => "compare",
          "title" => {
            "ru" => "Сравните с обычным разбором",
            "en" => "Compare with ordinary coding"
          },
          "rows" => [
            {
              "char" => "東",
              "wrong" => "da",
              "why" => {
                "ru" => "Дерево берётся целиком, а остаток — рамка с начинкой, то есть 田, а не 日.",
                "en" => "The tree is taken whole, and the remainder is a filled frame — 田, not 日."
              }
            },
            {
              "char" => "末",
              "wrong" => "dm",
              "why" => {
                "ru" => "Остаток — перекладина, пересечённая вертикалью, значит 十.",
                "en" => "The remainder is a bar crossed by a vertical, so 十."
              }
            },
            {
              "char" => "未",
              "wrong" => "dj",
              "why" => {
                "ru" => "А здесь сквозь дерево ничего не проходит — знак разбирается сверху вниз, обычным порядком.",
                "en" => "Here nothing runs through the tree, so the character is read top to bottom, the ordinary way."
              }
            },
            {
              "char" => "央",
              "wrong" => "kbl",
              "why" => {
                "ru" => "Оболочка 冂 не проходит сквозь 大, поэтому правило не применяется.",
                "en" => "The 冂 shell does not run through 大, so the rule does not apply."
              }
            }
          ]
        },
        {
          "kind" => "note",
          "tone" => "warn",
          "text" => {
            "ru" => "Список закрытый — тринадцать знаков. Все они целые: головы и тела у них нет.",
            "en" => "The list is closed — thirteen characters. All of them are unsplittable: no head, no body."
          }
        }
      ],
      bank: %w[束 末 朿 來 東 柬 秉 乘 爽 夷 夾 屯 未 吏 事 央]
    )
  end

  def taiwan(b)
    b.lesson(
      "taiwan",
      stage: "taiwan",
      title: {"ru" => "臺灣 и всё вокруг", "en" => "臺灣 and everything around it"},
      lede: {
        "ru" => "Знаки, которые вы наберёте в первый же день: остров, города, транспорт, еда.",
        "en" => "The characters you will type on day one: the island, the cities, transport, food."
      },
      blocks: [
        {
          "kind" => "walk",
          "title" => {"ru" => "Два главных знака", "en" => "The two that matter most"},
          "rows" => [
            {
              "char" => "臺",
              "pieces" => %w[士 口 冖 土],
              "why" => {
                "ru" => "Сверху вниз: 士, рот, крышка без концов, земля. Крышка — 月, отсюда третий код.",
                "en" => "Top to bottom: 士, mouth, a lid with no ends, earth. The lid is 月, hence the third code."
              }
            },
            {
              "char" => "灣",
              "pieces" => %w[氵 幺 火 弓],
              "why" => {
                "ru" => "Вода — голова. Тело 彎: первый кусок 幺, второй 火, последний 弓. Середина выброшена.",
                "en" => "Water is the head. The body 彎: first piece 幺, second 火, last 弓. The middle is dropped."
              }
            },
            {
              "char" => "台",
              "pieces" => %w[厶 口],
              "why" => {
                "ru" => "Короткое написание — всего два кода. В вывесках и адресах встречается чаще полного.",
                "en" => "The short spelling takes just two codes. On signs and addresses it beats the full form."
              }
            }
          ]
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "География", "en" => "Geography"},
          "chars" => %w[臺 灣 台 北 南 中 東 高 雄 花 蓮 港 市 縣 鎮 島 山 海]
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "Город и транспорт", "en" => "City and transport"},
          "chars" => %w[捷 運 車 站 路 街 店 便 利 商 樓 門 口 房]
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "Еда и напитки", "en" => "Food and drink"},
          "chars" => %w[珍 珠 奶 茶 飯 麵 湯 魚 肉 菜 蛋 雞 餃 梨 芒 果]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "臺 и 台 в цанцзе — два разных знака с разными кодами. Официальные документы просят 臺, вывески почти всегда пишут 台.",
            "en" => "臺 and 台 are two different characters with different codes. Official paperwork asks for 臺; shop signs almost always use 台."
          }
        }
      ],
      bank: %w[臺 灣 台 北 南 高 雄 花 蓮 港 市 縣 島 捷 運 站]
    )

    b.lesson(
      "novice",
      stage: "taiwan",
      title: {"ru" => "Novice 1, Novice 2 и A1", "en" => "Novice 1, Novice 2 and A1"},
      lede: {
        "ru" => "Двести шестьдесят шесть знаков трёх первых уровней TOCFL, целиком и по частотности. Наберите их не думая — и повседневный текст перестанет тормозить.",
        "en" => "All two hundred and sixty-six characters of the first three TOCFL levels, in frequency order. Type them without thinking and everyday text stops being slow."
      },
      blocks: [
        {
          "kind" => "grid",
          "title" => {"ru" => "Novice 1 — по частотности", "en" => "Novice 1 — by frequency"},
          "chars" => %w[
            的
            一
            是
            不
            我
            有
            人
            他
            這
            大
            說
            也
            你
            能
            都
            學
            她
            國
            想
            小
            很
            十
            分
            三
            二
            做
            問
            兩
            高
            位
            第
            再
            四
            書
            五
            走
            幾
            九
            聽
            水
            難
            車
            八
            百
            六
            住
            找
            七
            字
            寫
            吃
            嗎
            叫
            媽
            呢
            請
            吧
            半
            千
            錢
            坐
            歲
            久
            弟
            哥
            妳
            誰
            買
            忙
            爸
            姐
            您
            塊
            飯
            妹
            姊
            真
          ]
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "Novice 2 — по частотности", "en" => "Novice 2 — by frequency"},
          "chars" => %w[
            事
            多
            天
            最
            常
            手
            太
            又
            日
            外
            見
            女
            先
            像
            新
            美
            它
            山
            月
            路
            邊
            件
            風
            萬
            元
            讀
            男
            房
            念
            畫
            球
            共
            腳
            痛
            熱
            怕
            低
            藥
            酒
            慢
            課
            衣
            穿
            玩
            店
            魚
            左
            肉
            旁
            牛
            冷
            右
            跳
            喝
            樓
            湯
            歌
            短
            紙
            舊
            嘴
            懂
            菜
            雨
            唱
            茶
            蛋
            累
            鞋
            杯
            椅
            枝
            鼻
            甜
            豬
            輛
            碗
            餓
            飽
            瘦
            唸
            胖
            矮
            筷
            餃
            麵
            雞
            裏
            裡
          ]
        },
        {
          "kind" => "grid",
          "title" => {"ru" => "TOCFL A1 — по частотности", "en" => "TOCFL A1 — by frequency"},
          "chars" => %w[
            地
            心
            還
            行
            間
            長
            部
            才
            更
            西
            加
            電
            東
            馬
            場
            放
            拉
            海
            離
            輕
            遠
            南
            笑
            交
            北
            條
            片
            市
            算
            城
            跑
            答
            試
            火
            哪
            講
            苦
            剛
            啊
            臉
            樹
            掉
            送
            支
            句
            河
            隻
            草
            香
            班
            壞
            屋
            賣
            忘
            狗
            啦
            春
            脫
            夏
            呀
            哭
            街
            雪
            盤
            替
            髮
            洗
            鳥
            燈
            戴
            窗
            湖
            騎
            掛
            秋
            零
            冬
            借
            酸
            糖
            肚
            搬
            寄
            瓶
            貓
            渴
            帽
            褲
            租
            盒
            踢
            烤
            叉
            辣
            襪
            錶
            裙
            喂
            鹹
            台
          ]
        },
        {
          "kind" => "note",
          "tone" => "info",
          "text" => {
            "ru" => "Самый частый знак языка, 的, набирается 竹日心戈: наклонная, солнце, обёртка, точка. Второй по частоте, 一, — одно нажатие.",
            "en" => "The commonest character in the language, 的, is 竹日心戈: slant, sun, wrap, dot. The second, 一, is a single press."
          }
        }
      ],
      bank: %w[的 一 是 不 我 有 人 他 這 大 說 也 你 能 都 學]
    )
  end
end
