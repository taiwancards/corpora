#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-tmp/content-$(date +%Y%m%d-%H%M).dump}"
DB="${DATABASE_URL:-postgresql://localhost:${PGPORT:-5432}/taiwancards_development}"

TABLES=(
  content_sources
  lexemes
  lexeme_links
  lexeme_senses
  sense_examples
  lexeme_content_sources
  sentence_profiles
  sentence_words
  mainland_markers
  collections
  collection_items
)

ARGS=()
for table in "${TABLES[@]}"; do ARGS+=("-t" "$table"); done

pg_dump "$DB" --data-only -Fc --no-owner "${ARGS[@]}" -f "$OUT"

echo "dump: $OUT ($(du -h "$OUT" | cut -f1))"
echo "next: bash corpora/rails/import_content.sh \"\$PROD_DATABASE_URL\" $OUT"
