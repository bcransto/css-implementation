-- v0.16: instructor.left_on (YYYY-MM). A person who retires or moves on keeps their instructor row and their
-- observed rows: those rows are dated history (protocol.as_of says when), and protocol.teacher and deliverer_id
-- reference the person. left_on only marks them as gone, so the area page can list current teachers first and
-- dim the departed, and so a replacement gets their own rows instead of overwriting these. NULL = still here.
-- A plain ADD COLUMN: no rebuild, no trigger to drop.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-11-01-instructor-left-on.sql
BEGIN;
ALTER TABLE instructor ADD COLUMN left_on TEXT;   -- YYYY-MM the person left; NULL = current
COMMIT;
