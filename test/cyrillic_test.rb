# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/cyrillic"

class CyrillicTest < Minitest::Test
  SYLLABLES = %w[
    a
    ai
    an
    ang
    ao
    ba
    bai
    ban
    bang
    bao
    bei
    ben
    beng
    bi
    bian
    biao
    bie
    bin
    bing
    bo
    bu
    ca
    cai
    can
    cang
    cao
    ce
    cen
    ceng
    cha
    chai
    chan
    chang
    chao
    che
    chen
    cheng
    chi
    chong
    chou
    chu
    chua
    chuai
    chuan
    chuang
    chui
    chun
    chuo
    ci
    cong
    cou
    cu
    cuan
    cui
    cun
    cuo
    da
    dai
    dan
    dang
    dao
    de
    den
    deng
    di
    dian
    diao
    die
    ding
    diu
    dong
    dou
    du
    duan
    dui
    dun
    duo
    e
    ei
    en
    eng
    er
    fa
    fan
    fang
    fei
    fen
    feng
    fiao
    fo
    fou
    fu
    ga
    gai
    gan
    gang
    gao
    ge
    gei
    gen
    geng
    gong
    gou
    gu
    gua
    guai
    guan
    guang
    gui
    gun
    guo
    ha
    hai
    han
    hang
    hao
    he
    hei
    hen
    heng
    hong
    hou
    hu
    hua
    huai
    huan
    huang
    hui
    hun
    huo
    ji
    jia
    jian
    jiang
    jiao
    jie
    jin
    jing
    jiong
    jiu
    ju
    juan
    jue
    jun
    ka
    kai
    kan
    kang
    kao
    ke
    ken
    keng
    kong
    kou
    ku
    kua
    kuai
    kuan
    kuang
    kui
    kun
    kuo
    la
    lai
    lan
    lang
    lao
    le
    lei
    leng
    li
    lia
    lian
    liang
    liao
    lie
    lin
    ling
    liu
    long
    lou
    lu
    luan
    lun
    luo
    lü
    lüe
    ma
    mai
    man
    mang
    mao
    me
    mei
    men
    meng
    mi
    mian
    miao
    mie
    min
    ming
    miu
    mo
    mou
    mu
    na
    nai
    nan
    nang
    nao
    ne
    nei
    nen
    neng
    ni
    nian
    niang
    niao
    nie
    nin
    ning
    niu
    nong
    nou
    nu
    nuan
    nun
    nuo
    nü
    nüe
    o
    ou
    pa
    pai
    pan
    pang
    pao
    pei
    pen
    peng
    pi
    pian
    piao
    pie
    pin
    ping
    po
    pou
    pu
    qi
    qia
    qian
    qiang
    qiao
    qie
    qin
    qing
    qiong
    qiu
    qu
    quan
    que
    qun
    ran
    rang
    rao
    re
    ren
    reng
    ri
    rong
    rou
    ru
    rua
    ruan
    rui
    run
    ruo
    sa
    sai
    san
    sang
    sao
    se
    sen
    seng
    sha
    shai
    shan
    shang
    shao
    she
    shei
    shen
    sheng
    shi
    shou
    shu
    shua
    shuai
    shuan
    shuang
    shui
    shun
    shuo
    si
    song
    sou
    su
    suan
    sui
    sun
    suo
    ta
    tai
    tan
    tang
    tao
    te
    teng
    ti
    tian
    tiao
    tie
    ting
    tong
    tou
    tu
    tuan
    tui
    tun
    tuo
    wa
    wai
    wan
    wang
    wei
    wen
    weng
    wo
    wu
    xi
    xia
    xian
    xiang
    xiao
    xie
    xin
    xing
    xiong
    xiu
    xu
    xuan
    xue
    xun
    ya
    yan
    yang
    yao
    ye
    yi
    yin
    ying
    yo
    yong
    you
    yu
    yuan
    yue
    yun
    za
    zai
    zan
    zang
    zao
    ze
    zei
    zen
    zeng
    zha
    zhai
    zhan
    zhang
    zhao
    zhe
    zhen
    zheng
    zhi
    zhong
    zhou
    zhu
    zhua
    zhuai
    zhuan
    zhuang
    zhui
    zhun
    zhuo
    zi
    zong
    zou
    zu
    zuan
    zui
    zun
    zuo
  ]
    .freeze

  def taiwan(*syllables, hyphen: false) = Cyrillic.word(syllables, system: Cyrillic::Taiwan, hyphen:)

  def palladius(*syllables) = Cyrillic.word(syllables, system: Cyrillic::Palladius)

  def test_writes_every_standard_syllable_in_both_systems
    SYLLABLES.each do |syllable|
      refute_empty(Cyrillic::Taiwan.syllable(syllable), syllable)
      refute_empty(Cyrillic::Palladius.syllable(syllable), syllable)
    end
  end

  def test_never_needs_a_soft_sign
    assert_empty(SYLLABLES.map { |syllable| Cyrillic::Taiwan.syllable(syllable) }.grep(/ь/))
  end

  def test_writes_the_course_cast_as_it_sounds
    assert_equal("Дин", taiwan("dīng"))
    assert_equal("Дан-щу", taiwan("dān", "xù", hyphen: true))
    assert_equal("Лин", taiwan("lín"))
    assert_equal("Ан-ан", taiwan("ān", "ān", hyphen: true))
    assert_equal("Бо-хан", taiwan("bó", "hàn", hyphen: true))
    assert_equal("Ю-щи", taiwan("yòu", "xī", hyphen: true))
    assert_equal("Дзя-щан", taiwan("jiā", "xiáng", hyphen: true))
    assert_equal("И-дзюн", taiwan("yí", "jūn", hyphen: true))
    assert_equal("Щао-мэй", taiwan("xiǎo", "měi", hyphen: true))
  end

  def test_keeps_aspiration_in_the_choice_of_letter
    assert_equal(%w[Б П Д Т Г К], %w[bā pā dā tā gā kā].map { |syllable| taiwan(syllable)[0] })
    assert_equal(
      %w[Дзи Чи Дза Ца Джа Ча],
      %w[jī qī zā cā zhā chā].map { |syllable| taiwan(syllable) }
    )
  end

  def test_tells_the_palatal_from_the_retroflex_by_the_vowel_letter
    refute_equal(taiwan("qí"), taiwan("chī"))
    refute_equal(taiwan("qiáng"), taiwan("cháng"))
    assert_equal("Чы", taiwan("chī"))
  end

  def test_tells_common_surnames_apart
    assert_equal(%w[Лиу Лю], [taiwan("liú"), taiwan("lǚ")])
    assert_equal(%w[Щу Ще Щао], [taiwan("xǔ"), taiwan("xiè"), taiwan("xiāo")])
    assert_equal(
      %w[Уан Джан Дзен Хуэй Гуэй],
      [taiwan("wáng"), taiwan("zhāng"), taiwan("jiǎn"), taiwan("huī"), taiwan("guì")]
    )
  end

  def test_reads_pinyin_written_with_v_or_tone_marks
    assert_equal(taiwan("lǚ"), taiwan("lv"))
    assert_equal(taiwan("nü"), taiwan("nǚ"))
  end

  def test_writes_the_palladius_forms_found_in_older_texts
    assert_equal(
      %w[Чэнь Линь Даньсюй Сяомэй Цзян Сюй Люй Хуэй Гуй Ван Го],
      [
        palladius("chén"),
        palladius("lín"),
        palladius("dān", "xù"),
        palladius("xiǎo", "měi"),
        palladius("jiāng"),
        palladius("xǔ"),
        palladius("lǚ"),
        palladius("huī"),
        palladius("guì"),
        palladius("wáng"),
        palladius("guō")
      ]
    )
  end
end
