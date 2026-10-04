-- no-transaction
--
-- Pages one sweep run's awaiting rows; partial, so it stays empty between sweeps.
--
-- If the CONCURRENTLY build is interrupted, run DROP INDEX CONCURRENTLY person_pg_cleanup_queue_awaiting_delete; then re-run migrations.
CREATE INDEX CONCURRENTLY IF NOT EXISTS person_pg_cleanup_queue_awaiting_delete
    ON person_pg_cleanup_queue (awaiting_delete_run, team_id, person_uuid)
    WHERE awaiting_delete_run IS NOT NULL;
