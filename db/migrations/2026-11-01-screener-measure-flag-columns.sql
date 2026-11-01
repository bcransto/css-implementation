-- v0.17: (1) area_screener names a measure, so a DIBELS row can say Oral Reading Fluency or Maze and the page
-- can show NCII's "What skills does the tool screen?" list for that instrument ('-' = the whole tool, as in
-- tool_dimension; a named measure must exist on `measure`). Rebuilt for the new key; no trigger names the table.
-- (2) protocol.support and protocol.clear_rule: what a flagged Tier 1 student gets while still in Tier 1, and
-- what removes the flag. With entry_rule (the screening note), pm_rule (further screening) and exit_rule
-- (Tier 2 entry) these are the "flagged students" block on the page. Plain ADD COLUMN, no rebuild.
-- Data: the reading-35 DIBELS row's cut already says ORF, so it names that measure; Star rows name their one
-- measure. MCAS, ALEKS and the homemade screeners have no measures and stay '-'.
-- Apply to the LIVE database (test on a copy on the Pi first):
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-11-01-screener-measure-flag-columns.sql
PRAGMA foreign_keys = OFF;
BEGIN;

ALTER TABLE protocol ADD COLUMN support TEXT;
ALTER TABLE protocol ADD COLUMN clear_rule TEXT;

CREATE TABLE area_screener_new (
  area_id     TEXT NOT NULL REFERENCES area(id),
  teacher     TEXT NOT NULL DEFAULT '-' REFERENCES instructor(id),  -- '-' = the area's rule; else that teacher's practice
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  measure     TEXT NOT NULL DEFAULT '-',  -- the instrument ('Oral Reading Fluency'); '-' = the tool as a whole (v0.17)
  grade_lo    INTEGER NOT NULL,
  grade_hi    INTEGER NOT NULL,
  windows     TEXT,
  role        TEXT NOT NULL CHECK (role IN ('screen','level_check','on_request')),
  cut         TEXT,
  status      TEXT NOT NULL CHECK (status IN ('doc','unwritten','proposed')),
  PRIMARY KEY (area_id, teacher, tool_id, measure, grade_lo, role)
);
INSERT INTO area_screener_new (area_id, teacher, tool_id, measure, grade_lo, grade_hi, windows, role, cut, status)
SELECT area_id, teacher, tool_id, '-', grade_lo, grade_hi, windows, role, cut, status FROM area_screener;
DROP TABLE area_screener;
ALTER TABLE area_screener_new RENAME TO area_screener;

CREATE TRIGGER area_screener_measure BEFORE INSERT ON area_screener
BEGIN
  SELECT RAISE(ABORT, 'area_screener.measure must be ''-'' or a measure row for this tool')
  WHERE NEW.measure <> '-'
    AND NOT EXISTS (SELECT 1 FROM measure m WHERE m.tool_id = NEW.tool_id AND m.measure = NEW.measure);
END;

UPDATE area_screener SET measure = 'Oral Reading Fluency' WHERE tool_id = 'dibels';
UPDATE area_screener SET measure = 'Reading' WHERE tool_id = 'star-r';
UPDATE area_screener SET measure = 'Math'    WHERE tool_id = 'star-m';

COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
