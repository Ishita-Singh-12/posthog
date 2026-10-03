-- no-transaction
--
-- Pages one sweep run's awaiting rows in primary key order: the run that queued them clears them
-- after its delete, and the next sweep resolves the rows a failed run left. Only rows awaiting a
-- delete are indexed, so the index stays empty between sweeps.
--
-- Recovery note: if this CONCURRENTLY build is ever interrupted, it leaves the index INVALID and a
-- rerun's IF NOT EXISTS will NOT rebuild it. Recover manually:
--   DROP INDEX CONCURRENTLY person_pg_cleanup_queue_awaiting_delete;
-- then re-run migrations.
CREATE INDEX CONCURRENTLY IF NOT EXISTS person_pg_cleanup_queue_awaiting_delete
    ON person_pg_cleanup_queue (awaiting_delete_run, team_id, person_uuid)
    WHERE awaiting_delete_run IS NOT NULL;
