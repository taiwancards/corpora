#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$HERE/../.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

ROOT="${1:-${CORPORA_DIR:-$HERE/../dict_and_corpora/corpora}}"
MEDIA="${MEDIA_ROOT:-$HERE/../media}"
AGENT="${CORPUS_USER_AGENT:-TaiwanCards/1.0}"

need() {
  if [ -z "${!1:-}" ]; then
    echo "$1 is not set — see .env.dev" >&2
    exit 1
  fi
}

grab() {
  local url="$1" target="$2"
  [ -f "$target" ] && return 0
  mkdir -p "$(dirname "$target")"
  echo "==> ${target#"$ROOT"/}"
  curl -fSL --retry 3 -A "$AGENT" -o "$target" "$url"
}

echo "==> Target: $ROOT"

need LAW_CORPUS_URL
if [ ! -f "$ROOT/law/FaLv.xml" ]; then
  grab "$LAW_CORPUS_URL" "$ROOT/law/FaLv.zip"
  unzip -o -q "$ROOT/law/FaLv.zip" -d "$ROOT/law"
fi

need NTPC_NEWS_CSV_URL
need NTPC_ACTIVITIES_CSV_URL
grab "$NTPC_NEWS_CSV_URL" "$ROOT/ntpc/news.csv"
grab "$NTPC_ACTIVITIES_CSV_URL" "$ROOT/ntpc/activities.csv"

need MOE_CONCISED_DICT_URL
if [ ! -f "$ROOT/moedict/dict_concised.xlsx" ]; then
  grab "$MOE_CONCISED_DICT_URL" "$ROOT/moedict/dict_concised.zip"
  ruby "$HERE/unpack_concised.rb" "$ROOT/moedict"
fi

need MOE_REVISED_DICT_URL
if [ ! -f "$ROOT/moedict/dict-revised.json" ]; then
  grab "$MOE_REVISED_DICT_URL" "$ROOT/moedict/dict-revised.json.xz"
  xz -dk "$ROOT/moedict/dict-revised.json.xz"
fi

need COMMON_VOICE_BASE_URL
for f in sentence-collector.txt setences.txt chatlogs.txt taipei_city_gov.txt lms.txt; do
  grab "$COMMON_VOICE_BASE_URL/$f" "$ROOT/common_voice_txt/$f"
done

need LEGISLATIVE_TRANSCRIPT_BASE_URL
for s in 10-3 10-4 10-5 10-6 10-7 10-8 11-1 11-2 11-3; do
  grab "$LEGISLATIVE_TRANSCRIPT_BASE_URL/$s.csv" "$ROOT/ly/$s.csv"
done

need TBCL_GRAMMAR_URL
grab "$TBCL_GRAMMAR_URL" "$ROOT/tbcl/grammar_points.xlsx"

need TBCL_VOCAB_URL
if [ ! -f "$ROOT/tbcl/jieci_01.html" ]; then
  mkdir -p "$ROOT/tbcl"
  for page in $(seq 1 31); do
    echo "==> tbcl/jieci page $page/31"
    curl -fsSL --retry 2 -A "$AGENT" \
      -o "$ROOT/tbcl/jieci_$(printf %02d "$page").html" \
      "$TBCL_VOCAB_URL?deng_ji=all&q=&num=50&page=$page"
    sleep 0.4
  done
fi

need CNS11643_PROPERTIES_URL
need CNS11643_MAPPINGS_URL
if [ ! -f "$ROOT/cns11643/CNS_stroke.txt" ]; then
  grab "$CNS11643_PROPERTIES_URL" "$ROOT/cns11643/Properties.zip"
  unzip -o -q "$ROOT/cns11643/Properties.zip" -d "$ROOT/cns11643" || true
fi
if [ ! -f "$ROOT/cns11643/CNS2UNICODE_Unicode_BMP.txt" ]; then
  grab "$CNS11643_MAPPINGS_URL" "$ROOT/cns11643/MapingTables.zip"
  ruby "$HERE/unpack_cns.rb" "$ROOT/cns11643"
fi

need CNS11643_VOICE_URL
if [ ! -d "$MEDIA/cns_voice/audio" ]; then
  grab "$CNS11643_VOICE_URL" "$ROOT/cns11643/Voice.zip"
  ruby "$HERE/unpack_cns.rb" "$ROOT/cns11643" "$MEDIA/cns_voice"
fi

need XIAOXUE_CCR_BASE_URL
for part in 01_shangguyin 02_zhongguyin 03_yunshu 04_guanhua 05_jinyu 06_wuyu 07_huiyu \
  08_ganyu 09_xiangyu 10_minyu 11_yueyu 12_pinghua 13_keyu 14_otherdialects; do
  grab "$XIAOXUE_CCR_BASE_URL/ccr${part}_data_xlsx.zip" "$ROOT/ccr/ccr${part}_data_xlsx.zip"
done

need NAER_TERMS_BASE_URL
for part in "3/場所標示壓縮檔.zip" "3/業務標示壓縮檔.zip" "3/漢語文化特色詞條壓縮檔.zip" \
  "3/選舉詞彙壓縮檔.zip" "3/地方機關首長職稱壓縮檔.zip"; do
  grab "$NAER_TERMS_BASE_URL/$part" "$ROOT/naer/$(basename "$part")"
done

need MOI_NAMES_URL
grab "$MOI_NAMES_URL" "$ROOT/moi/names.csv"

need PTT_GOSSIP_CORPUS_URL
grab "$PTT_GOSSIP_CORPUS_URL" "$ROOT/ptt/Gossiping-QA-Dataset-2_0.csv"

need OPENCC_ST_URL
need OPENCC_TS_URL
grab "$OPENCC_ST_URL" "$ROOT/opencc/STCharacters.txt"
grab "$OPENCC_TS_URL" "$ROOT/opencc/TSCharacters.txt"

need OPENSUBTITLES_URL
need TED2020_URL
grab "$OPENSUBTITLES_URL" "$ROOT/opus/opensubtitles_zh_TW.txt.gz"
grab "$TED2020_URL" "$ROOT/opus/ted2020_zh_tw.txt.gz"

need WIKIPEDIA_DUMP_URL
grab "$WIKIPEDIA_DUMP_URL" "$ROOT/wiki/zhwiki-1.xml.bz2"

if [ -n "${HF_TOKEN:-}" ] && [ -n "${TTE_DATASET_URL:-}" ]; then
  for n in $(seq -w 0 7); do
    target="$ROOT/tte/train-0000$n.parquet"
    [ -f "$target" ] && continue
    mkdir -p "$ROOT/tte"
    echo "==> tte/train-0000$n.parquet"
    curl -fSL --retry 3 -H "Authorization: Bearer $HF_TOKEN" \
      -o "$target" "$TTE_DATASET_URL/train-0000$n-of-00008.parquet"
  done
else
  echo "==> tte skipped: needs HF_TOKEN and TTE_DATASET_URL"
fi

echo "==> Done. Next, for the sources that need an API key or a crawl:"
echo "    bundle exec ruby scripts/fetch_youtube.rb"
echo "    bundle exec ruby scripts/fetch_vocus.rb"
echo "    bundle exec ruby scripts/fetch_wikisource.rb"
