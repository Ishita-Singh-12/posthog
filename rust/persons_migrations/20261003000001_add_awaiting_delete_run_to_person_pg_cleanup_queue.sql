-- The sweep run that queued a person and has not yet confirmed its ClickHouse delete; the drain skips the row while set.
--
-- SAFE: nullable column with no default, so catalog-only; lock_timeout bounds the ACCESS EXCLUSIVE wait. Idempotent.

SET LOCAL lock_timeout = '2s';

ALTER TABLE person_pg_cleanup_queue ADD COLUMN IF NOT EXISTS awaiting_delete_run TEXT;

COMMENT ON COLUMN person_pg_cleanup_queue.awaiting_delete_run IS
    'Sweep run that queued the person and has not yet confirmed its ClickHouse delete. The drain skips the row while set. NULL when drainable.';
