-- The highest ClickHouse person version the sweep removed for each queued person. The drain sends
-- it with the hard delete, and personhog deletes the Postgres row only while its version is at or
-- below it. A person tombstoned again after the sweep has newer ClickHouse rows the sweep did not
-- remove, and its Postgres row must keep that version.
--
-- NULL marks a row queued before this column existed. The drain does not delete such persons,
-- because no sweep recorded the version it removed for them.
--
-- SAFE: ADD COLUMN of a nullable column with no default only changes the catalog: no table
-- rewrite, no scan, no backfill. The remaining hazard is the brief ACCESS EXCLUSIVE lock, which
-- waits behind an open sweep or drain transaction. lock_timeout bounds that wait; on timeout the
-- per-file transaction aborts, nothing is recorded, and the next migration run retries this
-- idempotent file.

SET LOCAL lock_timeout = '2s';

ALTER TABLE person_pg_cleanup_queue ADD COLUMN IF NOT EXISTS max_version BIGINT;

COMMENT ON COLUMN person_pg_cleanup_queue.max_version IS
    'Highest ClickHouse person version the sweep removed. The drain deletes the Postgres person only at or below this version. NULL on rows queued before the column existed; the drain leaves those rows in place.';
