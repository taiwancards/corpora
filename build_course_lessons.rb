# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
PATH = File.join(ROOT, "data/huayu/course_lessons.json")

KINDS = %w[word collocation measure_word phrase character].freeze
RANK = KINDS.each_with_index.to_h { |kind, index| [kind, index] }
TASK_KINDS = %w[meaning word reading cloze reply street order pair].freeze

PREFERRED = {
  "一個人" => ["ㄧˊ ˙ㄍㄜ ㄖㄣˊ", "yí ge rén"],
  "一次" => ["ㄧˊ ㄘˋ", "yí cì"],
  "一般人" => ["ㄧˋ ㄅㄢ ㄖㄣˊ", "yìbānrén"],
  "一週" => ["ㄧˋ ㄓㄡ", "yì zhōu"],
  "一開始" => ["ㄧ ㄎㄞ ㄕˇ", "yī kāishǐ"],
  "一點都不" => ["ㄧˋ ㄉㄧㄢˇ ㄉㄡ ㄅㄨˋ", "yìdiǎn dōu bù"],
  "三杯雞" => ["ㄙㄢ ㄅㄟ ㄐㄧ", "sānbēijī"],
  "上車" => ["ㄕㄤˋ ㄔㄜ", "shàngchē"],
  "下一站" => ["ㄒㄧㄚˋ ㄧˊ ㄓㄢˋ", "xià yí zhàn"],
  "下個" => ["ㄒㄧㄚˋ ˙ㄍㄜ", "xià ge"],
  "不一定" => ["ㄅㄨˋ ㄧˊ ㄉㄧㄥˋ", "bù yídìng"],
  "不太" => ["ㄅㄨˊ ㄊㄞˋ", "bú tài"],
  "不知道" => ["ㄅㄨˋ ㄓ ㄉㄠˋ", "bù zhīdào"],
  "丟下去" => ["ㄉㄧㄡ ㄒㄧㄚˋ ㄑㄩˋ", "diū xiàqù"],
  "並不是" => ["ㄅㄧㄥˋ ㄅㄨˊ ㄕˋ", "bìng bú shì"],
  "中南部" => ["ㄓㄨㄥ ㄋㄢˊ ㄅㄨˋ", "zhōngnánbù"],
  "也是" => ["ㄧㄝˇ ㄕˋ", "yěshì"],
  "了" => ["˙ㄌㄜ", "le"],
  "交通規則" => ["ㄐㄧㄠ ㄊㄨㄥ ㄍㄨㄟ ㄗㄜˊ", "jiāotōng guīzé"],
  "人資" => ["ㄖㄣˊ ㄗ", "rénzī"],
  "什麼時候" => ["ㄕㄣˊ ˙ㄇㄜ ㄕˊ ㄏㄡˋ", "shénme shíhòu"],
  "代工" => ["ㄉㄞˋ ㄍㄨㄥ", "dàigōng"],
  "你好" => ["ㄋㄧˇ ㄏㄠˇ", "nǐ hǎo"],
  "俄文" => ["ㄜˊ ㄨㄣˊ", "éwén"],
  "俄語" => ["ㄜˊ ㄩˇ", "éyǔ"],
  "保價" => ["ㄅㄠˇ ㄐㄧㄚˋ", "bǎojià"],
  "保費" => ["ㄅㄠˇ ㄈㄟˋ", "bǎofèi"],
  "保險費" => ["ㄅㄠˇ ㄒㄧㄢˇ ㄈㄟˋ", "bǎoxiǎnfèi"],
  "個" => ["˙ㄍㄜ", "ge"],
  "倒垃圾" => ["ㄉㄠˋ ㄌㄜˋ ㄙㄜˋ", "dào lèsè"],
  "借過" => ["ㄐㄧㄝˋ ㄍㄨㄛˋ", "jièguò"],
  "假訊息" => ["ㄐㄧㄚˇ ㄒㄩㄣˋ ㄒㄧˊ", "jiǎ xùnxí"],
  "做不到" => ["ㄗㄨㄛˋ ㄅㄨˊ ㄉㄠˋ", "zuò bú dào"],
  "做好" => ["ㄗㄨㄛˋ ㄏㄠˇ", "zuòhǎo"],
  "停機" => ["ㄊㄧㄥˊ ㄐㄧ", "tíngjī"],
  "健保費" => ["ㄐㄧㄢˋ ㄅㄠˇ ㄈㄟˋ", "jiànbǎofèi"],
  "免洗餐具" => ["ㄇㄧㄢˇ ㄒㄧˇ ㄘㄢ ㄐㄩˋ", "miǎnxǐ cānjù"],
  "免運" => ["ㄇㄧㄢˇ ㄩㄣˋ", "miǎnyùn"],
  "兩個字" => ["ㄌㄧㄤˇ ˙ㄍㄜ ㄗˋ", "liǎng ge zì"],
  "六折" => ["ㄌㄧㄡˋ ㄓㄜˊ", "liùzhé"],
  "再看" => ["ㄗㄞˋ ㄎㄢˋ", "zài kàn"],
  "再過" => ["ㄗㄞˋ ㄍㄨㄛˋ", "zài guò"],
  "初五" => ["ㄔㄨ ㄨˇ", "chūwǔ"],
  "刻印店" => ["ㄎㄜˋ ㄧㄣˋ ㄉㄧㄢˋ", "kèyìndiàn"],
  "前幾名" => ["ㄑㄧㄢˊ ㄐㄧˇ ㄇㄧㄥˊ", "qián jǐ míng"],
  "剩下的" => ["ㄕㄥˋ ㄒㄧㄚˋ ˙ㄉㄜ", "shèng xià de"],
  "加起來" => ["ㄐㄧㄚ ㄑㄧˇ ㄌㄞˊ", "jiā qǐlái"],
  "勞動人口" => ["ㄌㄠˊ ㄉㄨㄥˋ ㄖㄣˊ ㄎㄡˇ", "láodòng rénkǒu"],
  "勞工局" => ["ㄌㄠˊ ㄍㄨㄥ ㄐㄩˊ", "láogōngjú"],
  "南島語系" => ["ㄋㄢˊ ㄉㄠˇ ㄩˇ ㄒㄧˋ", "nándǎo yǔxì"],
  "取件" => ["ㄑㄩˇ ㄐㄧㄢˋ", "qǔjiàn"],
  "另一" => ["ㄌㄧㄥˋ ㄧ", "lìng yī"],
  "另一回事" => ["ㄌㄧㄥˋ ㄧˋ ㄏㄨㄟˊ ㄕˋ", "lìng yì huí shì"],
  "另一方面" => ["ㄌㄧㄥˋ ㄧˋ ㄈㄤ ㄇㄧㄢˋ", "lìng yì fāngmiàn"],
  "台啤" => ["ㄊㄞˊ ㄆㄧˊ", "táipí"],
  "右手邊" => ["ㄧㄡˋ ㄕㄡˇ ㄅㄧㄢ", "yòushǒubiān"],
  "吃不下" => ["ㄔ ㄅㄨˊ ㄒㄧㄚˋ", "chī bú xià"],
  "吃飽" => ["ㄔ ㄅㄠˇ", "chībǎo"],
  "吊照" => ["ㄉㄧㄠˋ ㄓㄠˋ", "diàozhào"],
  "吧" => ["˙ㄅㄚ", "ba"],
  "呢" => ["˙ㄋㄜ", "ne"],
  "和" => ["ㄏㄢˋ", "hàn"],
  "哪個" => ["ㄋㄚˇ ˙ㄍㄜ", "nǎ ge"],
  "哪裡都" => ["ㄋㄚˇ ㄌㄧˇ ㄉㄡ", "nǎlǐ dōu"],
  "啊" => ["˙ㄚ", "a"],
  "問法" => ["ㄨㄣˋ ㄈㄚˇ", "wènfǎ"],
  "喝" => ["ㄏㄜ", "hē"],
  "嗎" => ["˙ㄇㄚ", "ma"],
  "回收率" => ["ㄏㄨㄟˊ ㄕㄡ ㄌㄩˋ", "huíshōulǜ"],
  "國家語言" => ["ㄍㄨㄛˊ ㄐㄧㄚ ㄩˇ ㄧㄢˊ", "guójiā yǔyán"],
  "圖書證" => ["ㄊㄨˊ ㄕㄨ ㄓㄥˋ", "túshūzhèng"],
  "在職證明" => ["ㄗㄞˋ ㄓˊ ㄓㄥˋ ㄇㄧㄥˊ", "zàizhí zhèngmíng"],
  "基本工資" => ["ㄐㄧ ㄅㄣˇ ㄍㄨㄥ ㄗ", "jīběn gōngzī"],
  "外國人" => ["ㄨㄞˋ ㄍㄨㄛˊ ㄖㄣˊ", "wàiguórén"],
  "大夜班" => ["ㄉㄚˋ ㄧㄝˋ ㄅㄢ", "dàyèbān"],
  "大小章" => ["ㄉㄚˋ ㄒㄧㄠˇ ㄓㄤ", "dàxiǎozhāng"],
  "大法官" => ["ㄉㄚˋ ㄈㄚˇ ㄍㄨㄢ", "dàfǎguān"],
  "天公" => ["ㄊㄧㄢ ㄍㄨㄥ", "tiāngōng"],
  "太好了" => ["ㄊㄞˋ ㄏㄠˇ ˙ㄌㄜ", "tài hǎo le"],
  "好吧" => ["ㄏㄠˇ ˙ㄅㄚ", "hǎo ba"],
  "好幾" => ["ㄏㄠˇ ㄐㄧˇ", "hǎojǐ"],
  "好懂" => ["ㄏㄠˇ ㄉㄨㄥˇ", "hǎodǒng"],
  "好認" => ["ㄏㄠˇ ㄖㄣˋ", "hǎorèn"],
  "它們" => ["ㄊㄚ ˙ㄇㄣ", "tāmen"],
  "專用袋" => ["ㄓㄨㄢ ㄩㄥˋ ㄉㄞˋ", "zhuānyòngdài"],
  "小病" => ["ㄒㄧㄠˇ ㄅㄧㄥˋ", "xiǎobìng"],
  "少不了" => ["ㄕㄠˇ ㄅㄨˋ ㄌㄧㄠˇ", "shǎobùliǎo"],
  "居住者" => ["ㄐㄩ ㄓㄨˋ ㄓㄜˇ", "jūzhùzhě"],
  "居家服務" => ["ㄐㄩ ㄐㄧㄚ ㄈㄨˊ ㄨˋ", "jūjiā fúwù"],
  "工作天" => ["ㄍㄨㄥ ㄗㄨㄛˋ ㄊㄧㄢ", "gōngzuòtiān"],
  "工具機" => ["ㄍㄨㄥ ㄐㄩˋ ㄐㄧ", "gōngjùjī"],
  "左手邊" => ["ㄗㄨㄛˇ ㄕㄡˇ ㄅㄧㄢ", "zuǒshǒubiān"],
  "已讀不回" => ["ㄧˇ ㄉㄨˊ ㄅㄨˋ ㄏㄨㄟˊ", "yǐdú bù huí"],
  "市中心" => ["ㄕˋ ㄓㄨㄥ ㄒㄧㄣ", "shìzhōngxīn"],
  "常備藥" => ["ㄔㄤˊ ㄅㄟˋ ㄧㄠˋ", "chángbèiyào"],
  "年輕" => ["ㄋㄧㄢˊ ㄑㄧㄥ", "niánqīng"],
  "幾個" => ["ㄐㄧˇ ˙ㄍㄜ", "jǐ ge"],
  "待轉區" => ["ㄉㄞˋ ㄓㄨㄢˇ ㄑㄩ", "dàizhuǎnqū"],
  "很多" => ["ㄏㄣˇ ㄉㄨㄛ", "hěn duō"],
  "很少" => ["ㄏㄣˇ ㄕㄠˇ", "hěn shǎo"],
  "復振" => ["ㄈㄨˋ ㄓㄣˋ", "fùzhèn"],
  "怎麼說" => ["ㄗㄣˇ ˙ㄇㄜ ㄕㄨㄛ", "zěnme shuō"],
  "愈來愈" => ["ㄩˋ ㄌㄞˊ ㄩˋ", "yù lái yù"],
  "戶籍地" => ["ㄏㄨˋ ㄐㄧˊ ㄉㄧˋ", "hùjídì"],
  "手續費" => ["ㄕㄡˇ ㄒㄩˋ ㄈㄟˋ", "shǒuxùfèi"],
  "承辦人" => ["ㄔㄥˊ ㄅㄢˋ ㄖㄣˊ", "chéngbànrén"],
  "投票率" => ["ㄊㄡˊ ㄆㄧㄠˋ ㄌㄩˋ", "tóupiàolǜ"],
  "折現" => ["ㄓㄜˊ ㄒㄧㄢˋ", "zhéxiàn"],
  "插座" => ["ㄔㄚ ㄗㄨㄛˋ", "chāzuò"],
  "換車" => ["ㄏㄨㄢˋ ㄔㄜ", "huànchē"],
  "撐不下去" => ["ㄔㄥ ㄅㄨˊ ㄒㄧㄚˋ ㄑㄩˋ", "chēng bú xiàqù"],
  "收下" => ["ㄕㄡ ㄒㄧㄚˋ", "shōuxià"],
  "新年快樂" => ["ㄒㄧㄣ ㄋㄧㄢˊ ㄎㄨㄞˋ ㄌㄜˋ", "xīnnián kuàilè"],
  "新聞台" => ["ㄒㄧㄣ ㄨㄣˊ ㄊㄞˊ", "xīnwéntái"],
  "易碎" => ["ㄧˋ ㄙㄨㄟˋ", "yìsuì"],
  "最低" => ["ㄗㄨㄟˋ ㄉㄧ", "zuìdī"],
  "最遠" => ["ㄗㄨㄟˋ ㄩㄢˇ", "zuì yuǎn"],
  "會考" => ["ㄏㄨㄟˋ ㄎㄠˇ", "huìkǎo"],
  "有一天" => ["ㄧㄡˇ ㄧˋ ㄊㄧㄢ", "yǒu yì tiān"],
  "核退" => ["ㄏㄜˊ ㄊㄨㄟˋ", "hétuì"],
  "梅花肉" => ["ㄇㄟˊ ㄏㄨㄚ ㄖㄡˋ", "méihuāròu"],
  "橘色" => ["ㄐㄩˊ ㄙㄜˋ", "júsè"],
  "歡迎光臨" => ["ㄏㄨㄢ ㄧㄥˊ ㄍㄨㄤ ㄌㄧㄣˊ", "huānyíng guānglín"],
  "每年" => ["ㄇㄟˇ ㄋㄧㄢˊ", "měinián"],
  "氣象署" => ["ㄑㄧˋ ㄒㄧㄤˋ ㄕㄨˇ", "qìxiàngshǔ"],
  "水煮" => ["ㄕㄨㄟˇ ㄓㄨˇ", "shuǐzhǔ"],
  "永久居留" => ["ㄩㄥˇ ㄐㄧㄡˇ ㄐㄩ ㄌㄧㄡˊ", "yǒngjiǔ jūliú"],
  "沒問題" => ["ㄇㄟˊ ㄨㄣˋ ㄊㄧˊ", "méi wèntí"],
  "減碳" => ["ㄐㄧㄢˇ ㄊㄢˋ", "jiǎntàn"],
  "炒" => ["ㄔㄠˇ", "chǎo"],
  "無骨" => ["ㄨˊ ㄍㄨˇ", "wúgǔ"],
  "燃煤" => ["ㄖㄢˊ ㄇㄟˊ", "ránméi"],
  "特休" => ["ㄊㄜˋ ㄒㄧㄡ", "tèxiū"],
  "狗牌" => ["ㄍㄡˇ ㄆㄞˊ", "gǒupái"],
  "獨有" => ["ㄉㄨˊ ㄧㄡˇ", "dúyǒu"],
  "甘蔗汁" => ["ㄍㄢ ㄓㄜˋ ㄓ", "gānzhèzhī"],
  "用電量" => ["ㄩㄥˋ ㄉㄧㄢˋ ㄌㄧㄤˋ", "yòngdiànliàng"],
  "留下來" => ["ㄌㄧㄡˊ ㄒㄧㄚˋ ㄌㄞˊ", "liú xiàlái"],
  "留言區" => ["ㄌㄧㄡˊ ㄧㄢˊ ㄑㄩ", "liúyánqū"],
  "登入" => ["ㄉㄥ ㄖㄨˋ", "dēngrù"],
  "白班" => ["ㄅㄞˊ ㄅㄢ", "báibān"],
  "百分之" => ["ㄅㄞˇ ㄈㄣ ㄓ", "bǎifēnzhī"],
  "的" => ["˙ㄉㄜ", "de"],
  "的時候" => ["˙ㄉㄜ ㄕˊ ㄏㄡˋ", "de shíhòu"],
  "的話" => ["˙ㄉㄜ ㄏㄨㄚˋ", "de huà"],
  "直走" => ["ㄓˊ ㄗㄡˇ", "zhízǒu"],
  "直選" => ["ㄓˊ ㄒㄩㄢˇ", "zhíxuǎn"],
  "石化業" => ["ㄕˊ ㄏㄨㄚˋ ㄧㄝˋ", "shíhuàyè"],
  "矽盾" => ["ㄒㄧˋ ㄉㄨㄣˋ", "xìdùn"],
  "碎玻璃" => ["ㄙㄨㄟˋ ㄅㄛ ㄌㄧˊ", "suì bōlí"],
  "稅率" => ["ㄕㄨㄟˋ ㄌㄩˋ", "shuìlǜ"],
  "稱為" => ["ㄔㄥ ㄨㄟˊ", "chēngwéi"],
  "第二" => ["ㄉㄧˋ ㄦˋ", "dì'èr"],
  "等一下" => ["ㄉㄥˇ ㄧˊ ㄒㄧㄚˋ", "děng yí xià"],
  "紅線" => ["ㄏㄨㄥˊ ㄒㄧㄢˋ", "hóngxiàn"],
  "紙本" => ["ㄓˇ ㄅㄣˇ", "zhǐběn"],
  "累進" => ["ㄌㄟˇ ㄐㄧㄣˋ", "lěijìn"],
  "綁約" => ["ㄅㄤˇ ㄩㄝ", "bǎngyuē"],
  "網購" => ["ㄨㄤˇ ㄍㄡˋ", "wǎnggòu"],
  "網路媒體" => ["ㄨㄤˇ ㄌㄨˋ ㄇㄟˊ ㄊㄧˇ", "wǎnglù méitǐ"],
  "網銀" => ["ㄨㄤˇ ㄧㄣˊ", "wǎngyín"],
  "續借" => ["ㄒㄩˋ ㄐㄧㄝˋ", "xùjiè"],
  "罰錢" => ["ㄈㄚˊ ㄑㄧㄢˊ", "fáqián"],
  "群組" => ["ㄑㄩㄣˊ ㄗㄨˇ", "qúnzǔ"],
  "羽球" => ["ㄩˇ ㄑㄧㄡˊ", "yǔqiú"],
  "聽不懂" => ["ㄊㄧㄥ ㄅㄨˋ ㄉㄨㄥˇ", "tīng bù dǒng"],
  "聽得懂" => ["ㄊㄧㄥ ˙ㄉㄜ ㄉㄨㄥˇ", "tīng de dǒng"],
  "育嬰假" => ["ㄩˋ ㄧㄥ ㄐㄧㄚˋ", "yùyīngjià"],
  "自備杯" => ["ㄗˋ ㄅㄟˋ ㄅㄟ", "zìbèibēi"],
  "薪水單" => ["ㄒㄧㄣ ㄕㄨㄟˇ ㄉㄢ", "xīnshuǐdān"],
  "行動電源" => ["ㄒㄧㄥˊ ㄉㄨㄥˋ ㄉㄧㄢˋ ㄩㄢˊ", "xíngdòng diànyuán"],
  "行員" => ["ㄏㄤˊ ㄩㄢˊ", "hángyuán"],
  "行車紀錄器" => ["ㄒㄧㄥˊ ㄔㄜ ㄐㄧˋ ㄌㄨˋ ㄑㄧˋ", "xíngchē jìlùqì"],
  "試衣間" => ["ㄕˋ ㄧ ㄐㄧㄢ", "shìyījiān"],
  "話雖如此" => ["ㄏㄨㄚˋ ㄙㄨㄟ ㄖㄨˊ ㄘˇ", "huà suī rúcǐ"],
  "語系" => ["ㄩˇ ㄒㄧˋ", "yǔxì"],
  "語言學家" => ["ㄩˇ ㄧㄢˊ ㄒㄩㄝˊ ㄐㄧㄚ", "yǔyánxuéjiā"],
  "說實話" => ["ㄕㄨㄛ ㄕˊ ㄏㄨㄚˋ", "shuō shíhuà"],
  "誰" => ["ㄕㄟˊ", "shéi"],
  "調高" => ["ㄊㄧㄠˊ ㄍㄠ", "tiáogāo"],
  "豆乳雞" => ["ㄉㄡˋ ㄖㄨˇ ㄐㄧ", "dòurǔjī"],
  "買得起" => ["ㄇㄞˇ ˙ㄉㄜ ㄑㄧˇ", "mǎi de qǐ"],
  "買菜" => ["ㄇㄞˇ ㄘㄞˋ", "mǎicài"],
  "資訊工程" => ["ㄗ ㄒㄩㄣˋ ㄍㄨㄥ ㄔㄥˊ", "zīxùn gōngchéng"],
  "跟得上" => ["ㄍㄣ ˙ㄉㄜ ㄕㄤˋ", "gēn de shàng"],
  "跟著" => ["ㄍㄣ ˙ㄓㄜ", "gēn zhe"],
  "路考" => ["ㄌㄨˋ ㄎㄠˇ", "lùkǎo"],
  "轉診單" => ["ㄓㄨㄢˇ ㄓㄣˇ ㄉㄢ", "zhuǎnzhěndān"],
  "追不上" => ["ㄓㄨㄟ ㄅㄨˊ ㄕㄤˋ", "zhuī bú shàng"],
  "送餐" => ["ㄙㄨㄥˋ ㄘㄢ", "sòngcān"],
  "這一代" => ["ㄓㄜˋ ㄧˊ ㄉㄞˋ", "zhè yí dài"],
  "這件事" => ["ㄓㄜˋ ㄐㄧㄢˋ ㄕˋ", "zhè jiàn shì"],
  "這幾年" => ["ㄓㄜˋ ㄐㄧˇ ㄋㄧㄢˊ", "zhè jǐ nián"],
  "這點" => ["ㄓㄜˋ ㄉㄧㄢˇ", "zhè diǎn"],
  "連假" => ["ㄌㄧㄢˊ ㄐㄧㄚˋ", "liánjià"],
  "運動中心" => ["ㄩㄣˋ ㄉㄨㄥˋ ㄓㄨㄥ ㄒㄧㄣ", "yùndòng zhōngxīn"],
  "違憲" => ["ㄨㄟˊ ㄒㄧㄢˋ", "wéixiàn"],
  "還沒" => ["ㄏㄞˊ ㄇㄟˊ", "hái méi"],
  "那種" => ["ㄋㄚˋ ㄓㄨㄥˇ", "nà zhǒng"],
  "那邊" => ["ㄋㄚˋ ㄅㄧㄢ", "nàbiān"],
  "郵務員" => ["ㄧㄡˊ ㄨˋ ㄩㄢˊ", "yóuwùyuán"],
  "鄭氏" => ["ㄓㄥˋ ㄕˋ", "Zhèngshì"],
  "酒駕" => ["ㄐㄧㄡˇ ㄐㄧㄚˋ", "jiǔjià"],
  "醫療費" => ["ㄧ ㄌㄧㄠˊ ㄈㄟˋ", "yīliáofèi"],
  "鐵鋁罐" => ["ㄊㄧㄝˇ ㄌㄩˇ ㄍㄨㄢˋ", "tiělǚguàn"],
  "鑑賞期" => ["ㄐㄧㄢˋ ㄕㄤˇ ㄑㄧˊ", "jiànshǎngqí"],
  "長照" => ["ㄔㄤˊ ㄓㄠˋ", "chángzhào"],
  "長達" => ["ㄔㄤˊ ㄉㄚˊ", "chángdá"],
  "門號" => ["ㄇㄣˊ ㄏㄠˋ", "ménhào"],
  "限塑" => ["ㄒㄧㄢˋ ㄙㄨˋ", "xiànsù"],
  "除役" => ["ㄔㄨˊ ㄧˋ", "chúyì"],
  "陸上警報" => ["ㄌㄨˋ ㄕㄤˋ ㄐㄧㄥˇ ㄅㄠˋ", "lùshàng jǐngbào"],
  "雞肉" => ["ㄐㄧ ㄖㄡˋ", "jīròu"],
  "離岸風電" => ["ㄌㄧˊ ㄢˋ ㄈㄥ ㄉㄧㄢˋ", "lí'àn fēngdiàn"],
  "預付卡" => ["ㄩˋ ㄈㄨˋ ㄎㄚˇ", "yùfùkǎ"],
  "頭期款" => ["ㄊㄡˊ ㄑㄧˊ ㄎㄨㄢˇ", "tóuqíkuǎn"],
  "飛走" => ["ㄈㄟ ㄗㄡˇ", "fēizǒu"],
  "飯前" => ["ㄈㄢˋ ㄑㄧㄢˊ", "fànqián"],
  "飯後" => ["ㄈㄢˋ ㄏㄡˋ", "fànhòu"],
  "飲用水" => ["ㄧㄣˇ ㄩㄥˋ ㄕㄨㄟˇ", "yǐnyòngshuǐ"],
  "館員" => ["ㄍㄨㄢˇ ㄩㄢˊ", "guǎnyuán"],
  "首購" => ["ㄕㄡˇ ㄍㄡˋ", "shǒugòu"]
}.freeze

data = JSON.parse(File.read(PATH))
lessons = data.fetch("lessons", []).sort_by { |lesson| lesson["number"] }
stages = data.fetch("stages", [])

grammar = JSON.parse(File.read(File.join(ROOT, "data/huayu/grammar_lessons.json"))).to_h { |row| [row["slug"], row] }

texts = lessons.flat_map { |lesson| lesson["vocabulary"].map { |word| word["zh"] } }.uniq
best = {}
Lexeme.where(kind: KINDS, text: texts).find_each do |lexeme|
  current = best[lexeme.text]
  best[lexeme.text] = lexeme if current.nil? || RANK[lexeme.kind] < RANK[current.kind]
end

unread = []
unknown_grammar = []

lessons.each do |lesson|
  lesson["vocabulary"].each do |word|
    override = PREFERRED[word["zh"]]
    lexeme = best[word["zh"]]
    if override
      word["zhuyin"], word["pinyin"] = override
    elsif lexeme && lexeme.readings["zhuyin"].present?
      word["zhuyin"] = lexeme.readings["zhuyin"]
      word["pinyin"] = lexeme.readings["pinyin"]
    end

    unread << "#{lesson["slug"]}: #{word["zh"]}" if word["zhuyin"].blank?
  end

  lesson["grammar"].each do |ref|
    unknown_grammar << "#{lesson["slug"]}: #{ref["slug"]}" unless grammar.key?(ref["slug"])
  end
end

analyzer = Huayu::TextAnalyzer.new(locale: :en)

POOL = lessons
  .flat_map do |lesson|
    lesson["vocabulary"].map { |word|
      word.slice("zh", "en", "ru", "pos", "zhuyin").merge("lesson" => lesson["number"])
    }
  end
  .freeze

REPLIES = lessons
  .flat_map do |lesson|
    lesson.dig("text", "lines").each_cons(2).filter_map do |first, second|
      next if first["who"].nil? || second["who"].nil? || first["who"] == second["who"]

      {"zh" => second["zh"], "lesson" => lesson["number"]}
    end
  end
  .freeze

STREET = lessons
  .flat_map { |lesson| Array(lesson["usage"]).map { |entry| entry.merge("lesson" => lesson["number"]) } }
  .freeze

def gloss_of(word) = {"en" => word["en"], "ru" => word["ru"]}

def near(rng, candidates, correct, distinct)
  candidates
    .reject { |candidate| distinct.call(candidate, correct) }
    .map { |candidate|
      score = 0
      score += 3 if candidate["pos"] && candidate["pos"] == correct["pos"]
      score += 4 if (candidate["zh"].to_s.chars & correct["zh"].to_s.chars).any?
      score += 2 if candidate["lesson"] == correct["lesson"]
      if candidate["lesson"] && correct["lesson"]
        gap = (candidate["lesson"] - correct["lesson"]).abs
        score += 4 if gap <= 3
        score += 2 if gap.between?(4, 8)
        score -= 4 if gap > 15
      end

      score += 3 if candidate["zhuyin"].to_s.split.size == correct["zhuyin"].to_s.split.size
      [score + rng.rand(4), candidate]
    }
    .sort_by { |score, candidate| [-score, candidate["zh"].to_s] }
    .map(&:last)
end

def pick(rng, candidates, correct, distinct, count = 3)
  chosen = []
  near(rng, candidates, correct, distinct).each do |candidate|
    break if chosen.size == count
    next if chosen.any? { |taken| distinct.call(candidate, taken) }

    chosen << candidate
  end

  chosen
end

def shuffled(rng, size)
  order = (0...size).to_a
  loop do
    order = order.shuffle(random: rng)
    break unless order.each_with_index.all? { |value, index| value == index }
  end

  order
end

def choice(rng, kind, correct, others, key, extra = {})
  options = [correct] + others
  order = shuffled(rng, options.size)
  {"kind" => kind, "options" => order.map { |index| key.call(options[index]) }, "answer" => order.index(0)}.merge(extra)
end

SAME_WORD = -> (a, b) { a["zh"] == b["zh"] }
SAME_GLOSS = -> (a, b) { a["zh"] == b["zh"] || a["en"] == b["en"] }
SAME_LINE = -> (a, b) { a["zh"] == b["zh"] }

def build_tasks(lesson, analyzer, rng, want_street: true)
  vocab = lesson["vocabulary"].map { |word| word.merge("lesson" => lesson["number"]) }
  lines = lesson.dig("text", "lines")
  tasks = []
  used = []

  fresh = lambda do |minimum = 1|
    candidates = vocab.reject { |word| used.include?(word["zh"]) || word["zh"].length < minimum }
    candidates = vocab.reject { |word| word["zh"].length < minimum } if candidates.empty?
    word = candidates[rng.rand(candidates.size)]
    used << word["zh"]
    word
  end

  2.times do
    word = fresh.call
    tasks <<
      choice(
        rng,
        "meaning",
        word,
        pick(rng, POOL, word, SAME_GLOSS),
        -> (other) { gloss_of(other) },
        "zh" => word["zh"]
      )
  end

  word = fresh.call
  tasks <<
    choice(rng, "word", word, pick(rng, POOL, word, SAME_WORD), -> (other) { other["zh"] }, "gloss" => gloss_of(word))

  readable = vocab.select { |entry| entry["zhuyin"].present? && entry["zh"].length >= 2 && used.exclude?(entry["zh"]) }
  readable = vocab.select { |entry| entry["zhuyin"].present? } if readable.empty?
  if readable.any?
    word = readable[rng.rand(readable.size)]
    used << word["zh"]
    tasks <<
      choice(
        rng,
        "reading",
        word,
        pick(rng, POOL, word, SAME_WORD),
        -> (other) { other["zh"] },
        "zh" => word["zhuyin"]
      )
  end

  cloze = []
  lines.each do |line|
    break if cloze.size >= 2

    hit = vocab.find do |entry|
      entry["zh"].length >= 2 &&
        line["zh"].scan(entry["zh"]).size == 1 &&
        cloze.none? { |_, taken| taken["zh"] == entry["zh"] }
    end

    cloze << [line, hit] if hit
  end

  cloze.each do |line, word|
    tasks <<
      choice(
        rng,
        "cloze",
        word,
        pick(rng, POOL, word, SAME_WORD),
        -> (other) { other["zh"] },
        "zh" => line["zh"].sub(word["zh"], "＿＿"),
        "gloss" => {"en" => line["en"], "ru" => line["ru"]}
      )
  end

  turns = lines.each_cons(2).select { |a, b| a["who"] && b["who"] && a["who"] != b["who"] }
  if turns.any?
    ask, answer = turns[rng.rand(turns.size)]
    others = REPLIES.reject { |reply| reply["lesson"] == lesson["number"] }
    close = others.select { |reply| (reply["lesson"] - lesson["number"]).abs <= 8 }
    others = close if close.size >= 3
    tasks <<
      choice(
        rng,
        "reply",
        {"zh" => answer["zh"]},
        pick(rng, others, {"zh" => answer["zh"], "lesson" => lesson["number"]}, SAME_LINE),
        -> (reply) { reply["zh"] },
        "zh" => ask["zh"],
        "gloss" => {"en" => ask["en"], "ru" => ask["ru"]}
      )
  end

  short = lines.select { |line| line["zh"].delete("？！。，、「」…：").length.between?(5, 26) }
  if short.any?
    source = short[rng.rand(short.size)]
    chunks = analyzer.segment(source["zh"].delete("？！。，、「」…：")).reject(&:blank?)
    while chunks.size > 8
      index = chunks.each_index.min_by { |i| i + 1 < chunks.size ? chunks[i].length + chunks[i + 1].length : 99 }
      break if index.nil? || index + 1 >= chunks.size

      chunks = chunks[0...index] + [chunks[index] + chunks[index + 1]] + chunks[(index + 2)..]
    end

    if chunks.size.between?(3, 8)
      tasks <<
        {
          "kind" => "order",
          "gloss" => {"en" => source["en"], "ru" => source["ru"]},
          "chunks" => chunks,
          "order" => shuffled(rng, chunks.size),
          "answer" => 0
        }
    end
  end

  usable = lines.select { |line| line["zh"].length.between?(4, 18) }
  pairs = if usable.size >= 4
    usable.shuffle(random: rng).first(4).map { |line| {"zh" => line["zh"], "en" => line["en"], "ru" => line["ru"]} }
  else
    vocab.shuffle(random: rng).first(4).map { |word| {"zh" => word["zh"], "en" => word["en"], "ru" => word["ru"]} }
  end

  tasks << {"kind" => "pair", "pairs" => pairs, "order" => shuffled(rng, pairs.size), "answer" => 0} if pairs.size == 4

  own = Array(lesson["usage"])
  if want_street && own.any?
    entry = own[rng.rand(own.size)]
    others = STREET.reject { |row| row["lesson"] == lesson["number"] || row["street"] == entry["street"] }
    distractors = pick(rng, others, entry, -> (a, b) { a["street"] == b["street"] }, 3).map { |row|
      {"zh" => row["street"]}
    }
    if distractors.size == 3
      tasks <<
        choice(
          rng,
          "street",
          {"zh" => entry["street"]},
          distractors,
          -> (row) { row["zh"] },
          "zh" => entry["standard"]
        )
    end
  end

  tasks
end

lessons.each { |lesson| lesson["exercises"] = build_tasks(lesson, analyzer, Random.new(lesson["number"] * 7919 + 13)) }

stages.each do |stage|
  own = lessons.select { |lesson| lesson["stage"] == stage["slug"] }
  next stage["exam"] = [] if own.empty?

  rng = Random.new(stage["order"].to_i * 104_729 + 7)
  drawn = own.flat_map { |lesson|
    build_tasks(lesson, analyzer, Random.new(lesson["number"] * 31 + stage["order"].to_i), want_street: false)
  }
  by_kind = drawn.group_by { |task| task["kind"] }
  wanted = {"meaning" => 6, "word" => 3, "reading" => 3, "cloze" => 4, "reply" => 2, "order" => 1, "pair" => 1}
  exam = wanted.flat_map { |kind, count| Array(by_kind[kind]).shuffle(random: rng).first(count) }.compact
  exam += drawn.shuffle(random: rng).first(20 - exam.size) if exam.size < 20
  stage["exam"] = exam.shuffle(random: rng)
end

File.write(PATH, JSON.pretty_generate({"stages" => stages, "lessons" => lessons}))

short = lessons.select { |lesson| lesson["exercises"].size < 6 }
strange = lessons.flat_map { |lesson| lesson["exercises"] }.reject { |task| TASK_KINDS.include?(task["kind"]) }

puts(
  "lessons #{lessons.size}, tasks #{lessons.sum { |lesson| lesson["exercises"].size }}, exams #{stages.sum { |stage| stage["exam"].size }}"
)
puts("words without a reading: #{unread.size}")
unread.first(30).each { |row| puts("  #{row}") }
puts("grammar slugs that do not exist: #{unknown_grammar.size}")
unknown_grammar.first(30).each { |row| puts("  #{row}") }
puts("lessons with fewer than six tasks: #{short.size}")
puts("tasks of an unknown kind: #{strange.size}")
