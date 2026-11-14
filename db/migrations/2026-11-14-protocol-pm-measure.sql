-- v0.18: protocol.pm_measure, the instrument of the PM tool ('-' = the tool as a whole), mirroring
-- area_screener.measure (v0.17). A row can say DIBELS Maze rather than DIBELS, and the page shows NCII's
-- progress monitoring ratings for that instrument instead of "n NCII rows". Why now: which instrument is
-- valid depends on the grade (passage reading fluency weakens from grade 4-5; maze holds through grade 8),
-- so the tool's name alone does not say what is being monitored.
-- Plain ADD COLUMN, no rebuild. Two triggers (insert, and update of either column) because protocol rows
-- are updated in place by the form, unlike area_screener rows, which are deleted and re-inserted.
-- Data: a row whose PM tool has exactly one measure (Star Reading: 'Reading') names it; every other row
-- stays '-' until someone picks the instrument in the form.
-- Apply to the LIVE database (test on a copy on the Pi first):
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-11-14-protocol-pm-measure.sql
BEGIN;

ALTER TABLE protocol ADD COLUMN pm_measure TEXT NOT NULL DEFAULT '-';

-- a protocol that names a PM measure must name one the vendor described for its PM tool (same rule as area_screener)
CREATE TRIGGER protocol_pm_measure_ins BEFORE INSERT ON protocol
BEGIN
  SELECT RAISE(ABORT, 'protocol.pm_measure must be ''-'' or a measure row for the PM tool')
  WHERE NEW.pm_measure <> '-'
    AND NOT EXISTS (SELECT 1 FROM measure m WHERE m.tool_id = NEW.pm_tool_id AND m.measure = NEW.pm_measure);
END;
CREATE TRIGGER protocol_pm_measure_upd BEFORE UPDATE OF pm_tool_id, pm_measure ON protocol
BEGIN
  SELECT RAISE(ABORT, 'protocol.pm_measure must be ''-'' or a measure row for the PM tool')
  WHERE NEW.pm_measure <> '-'
    AND NOT EXISTS (SELECT 1 FROM measure m WHERE m.tool_id = NEW.pm_tool_id AND m.measure = NEW.pm_measure);
END;

UPDATE protocol SET pm_measure = (SELECT m.measure FROM measure m WHERE m.tool_id = protocol.pm_tool_id)
WHERE pm_tool_id IS NOT NULL
  AND (SELECT count(*) FROM measure m WHERE m.tool_id = protocol.pm_tool_id) = 1;

COMMIT;
SELECT id, pm_tool_id, pm_measure FROM protocol WHERE pm_measure <> '-' ORDER BY id;
