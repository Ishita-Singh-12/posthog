-- The sweep queues each person before it deletes the person's ClickHouse rows, so a failure after
-- the delete cannot lose the handoff. Until the delete is confirmed, the row carries the sweep run
-- id here and the drain skips it: a Postgres hard delete while ClickHouse still holds the
-- tombstone would let a recreated person start below that tombstone and stay hidden.
--
-- The run that queued the row clears the column after its delete. A row a failed run left behind
-- is resolved by the next sweep: cleared when ClickHouse holds no rows for the person, deleted
-- otherwise. NULL marks a drainable row, which includes every row queued before this column
-- existed.
--
-- SAFE: ADD COLUMN of a nullable column with no default only changes the catalog: no table
-- rewrite, no scan, no backfill. The remaining hazard is the brief ACCESS EXCLUSIVE lock, which
-- waits behind an open sweep or drain transaction. lock_timeout bounds that wait; on timeout the
-- per-file transaction aborts, nothing is recorded, and the next migration run retries this
-- idempotent file.

SET LOCAL lock_timeout = '2s';

ALTER TABLE person_pg_cleanup_queue ADD COLUMN IF NOT EXISTS awaiting_delete_run TEXT;

COMMENT ON COLUMN person_pg_cleanup_queue.awaiting_delete_run IS
    'Sweep run that queued the person and has not yet confirmed its ClickHouse delete. The drain skips the row while set. NULL when drainable.';
