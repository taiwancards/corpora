#!/usr/bin/env bash
set -euo pipefail

DB="${1:?target DATABASE_URL required}"
DUMP="${2:?dump file required}"

echo "== Clearing dictionary and progress (users untouched) =="
psql "$DB" -v ON_ERROR_STOP=1 << 'SQL'
BEGIN;
UPDATE reading_texts SET content_source_id = NULL WHERE content_source_id IS NOT NULL;
UPDATE reading_texts SET collection_id = NULL WHERE collection_id IS NOT NULL;
TRUNCATE
  lexeme_reviews,
  lexeme_memories,
  pronunciation_attempts,
  collection_items,
  sentence_words,
  sentence_profiles,
  sense_examples,
  lexeme_senses,
  lexeme_content_sources,
  lexeme_links,
  mainland_markers,
  lexemes
RESTART IDENTITY;
-- reading_texts references collections and content_sources, so TRUNCATE
-- does not apply to them even after the detach above; DELETE does.
DELETE FROM collections;
DELETE FROM content_sources;
COMMIT;
SQL

CONTENT_TABLES="'lexemes','lexeme_links','lexeme_senses','sense_examples','lexeme_content_sources','sentence_profiles','sentence_words','content_sources','mainland_markers','collections','collection_items'"

INDEX_DEFS="${DUMP%.dump}-indexes.sql"
psql "$DB" -tA -v ON_ERROR_STOP=1 << SQL > "$INDEX_DEFS"
SELECT regexp_replace(indexdef, '^CREATE (UNIQUE )?INDEX ', 'CREATE \1INDEX IF NOT EXISTS ') || ';'
FROM pg_indexes i
WHERE schemaname = 'public'
  AND tablename IN ($CONTENT_TABLES)
  AND NOT EXISTS (
    SELECT 1 FROM pg_constraint c
    WHERE c.conindid = format('%I.%I', i.schemaname, i.indexname)::regclass
  );
SQL

EXPECTED_INDEXES="$(grep -c 'CREATE' "$INDEX_DEFS" || true)"
if [ "$EXPECTED_INDEXES" -lt 1 ]; then
  echo "ERROR: could not read index definitions; refusing to drop them." >&2
  exit 1
fi

echo "== Dropping indexes ($EXPECTED_INDEXES) =="
psql "$DB" -tA -v ON_ERROR_STOP=1 << SQL | psql "$DB" -v ON_ERROR_STOP=1 -f -
SELECT format('DROP INDEX %I.%I;', schemaname, indexname)
FROM pg_indexes i
WHERE schemaname = 'public'
  AND tablename IN ($CONTENT_TABLES)
  AND NOT EXISTS (
    SELECT 1 FROM pg_constraint c
    WHERE c.conindid = format('%I.%I', i.schemaname, i.indexname)::regclass
  );
SQL

echo "== Restoring the dump =="
pg_restore --data-only --no-owner --exit-on-error -d "$DB" "$DUMP"

echo "== Rebuilding indexes ($EXPECTED_INDEXES) =="
psql "$DB" -v ON_ERROR_STOP=1 -c "SET maintenance_work_mem = '64MB'" -f "$INDEX_DEFS"

ACTUAL_INDEXES="$(psql "$DB" -tA -c "
  SELECT count(*) FROM pg_indexes i
  WHERE schemaname = 'public' AND tablename IN ($CONTENT_TABLES)
    AND NOT EXISTS (
      SELECT 1 FROM pg_constraint c
      WHERE c.conindid = format('%I.%I', i.schemaname, i.indexname)::regclass
    );
")"
if [ "$ACTUAL_INDEXES" != "$EXPECTED_INDEXES" ]; then
  echo "ERROR: expected $EXPECTED_INDEXES indexes, found $ACTUAL_INDEXES." >&2
  echo "Rebuild manually: psql \"\$DATABASE_URL\" -f $INDEX_DEFS" >&2
  exit 1
fi
echo "indexes in place: $ACTUAL_INDEXES"

echo "== Sequences and statistics =="
psql "$DB" -v ON_ERROR_STOP=1 << 'SQL'
SELECT setval('lexemes_id_seq', COALESCE((SELECT max(id) FROM lexemes), 1));
SELECT setval('lexeme_links_id_seq', COALESCE((SELECT max(id) FROM lexeme_links), 1));
SELECT setval('lexeme_senses_id_seq', COALESCE((SELECT max(id) FROM lexeme_senses), 1));
SELECT setval('sense_examples_id_seq', COALESCE((SELECT max(id) FROM sense_examples), 1));
SELECT setval('lexeme_content_sources_id_seq', COALESCE((SELECT max(id) FROM lexeme_content_sources), 1));
SELECT setval('sentence_profiles_id_seq', COALESCE((SELECT max(id) FROM sentence_profiles), 1));
SELECT setval('sentence_words_id_seq', COALESCE((SELECT max(id) FROM sentence_words), 1));
SELECT setval('content_sources_id_seq', COALESCE((SELECT max(id) FROM content_sources), 1));
SELECT setval('mainland_markers_id_seq', COALESCE((SELECT max(id) FROM mainland_markers), 1));
SELECT setval('collections_id_seq', COALESCE((SELECT max(id) FROM collections), 1));
SELECT setval('collection_items_id_seq', COALESCE((SELECT max(id) FROM collection_items), 1));
ANALYZE;
SQL

echo "== Verification =="
psql "$DB" -c "SELECT kind, count(*) FROM lexemes GROUP BY kind ORDER BY kind;"
psql "$DB" -c "SELECT pg_size_pretty(pg_database_size(current_database()));"
echo "done"
