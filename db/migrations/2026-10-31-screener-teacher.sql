-- v0.15: area_screener is scoped to a teacher, like protocol and profile (v0.3). teacher '-' = the area's
-- rule; a person = what that teacher screens with. Rebuilt for the new key; no trigger names it.
-- Data: the 'unwritten' rows in math-5, math-7, math-8 and ela-7 came from one teacher's interview and those
-- areas have no defined Tier 1, so they move to that teacher. math-6 keeps its rows as the area's proposal and
-- Spiegl gets copies of the two she named. MCAS rows are added for Putnam, Balian and Rice, whose entry rules
-- name it; Rice's STAR row gets the cut her rule states. Everything here is from the 2026-10 interviews and
-- can be corrected on /area/<id>/screening/<teacher>.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-10-31-screener-teacher.sql
PRAGMA foreign_keys = OFF;
BEGIN;

CREATE TABLE area_screener_new (
  area_id     TEXT NOT NULL REFERENCES area(id),
  teacher     TEXT NOT NULL DEFAULT '-' REFERENCES instructor(id),  -- '-' = the area's rule; else that teacher's practice
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  grade_lo    INTEGER NOT NULL,
  grade_hi    INTEGER NOT NULL,
  windows     TEXT,
  role        TEXT NOT NULL CHECK (role IN ('screen','level_check','on_request')),
  cut         TEXT,
  status      TEXT NOT NULL CHECK (status IN ('doc','unwritten','proposed')),
  PRIMARY KEY (area_id, teacher, tool_id, grade_lo, role)
);
INSERT INTO area_screener_new (area_id, teacher, tool_id, grade_lo, grade_hi, windows, role, cut, status)
SELECT area_id, '-', tool_id, grade_lo, grade_hi, windows, role, cut, status FROM area_screener;
DROP TABLE area_screener;
ALTER TABLE area_screener_new RENAME TO area_screener;

-- interview rows move to their teacher (these areas have no defined Tier 1)
UPDATE area_screener SET teacher = 'putnam'   WHERE area_id = 'math-5' AND status = 'unwritten';
UPDATE area_screener SET teacher = 'balian'   WHERE area_id = 'math-7' AND status = 'unwritten';
UPDATE area_screener SET teacher = 'cloutier' WHERE area_id = 'math-8' AND status = 'unwritten';
UPDATE area_screener SET teacher = 'rice'     WHERE area_id = 'ela-7'  AND status = 'unwritten';

-- math-6: the area keeps its proposal; Spiegl's own copies of the two tools her entry rule names
INSERT INTO area_screener (area_id, teacher, tool_id, grade_lo, grade_hi, windows, role, cut, status)
SELECT area_id, 'spiegl', tool_id, grade_lo, grade_hi, windows, role, cut, 'unwritten'
FROM area_screener WHERE area_id = 'math-6' AND teacher = '-' AND tool_id IN ('aleks', 'm6-spiegl-screener');

-- MCAS, per teacher, where the entry rule names it
INSERT INTO area_screener (area_id, teacher, tool_id, grade_lo, grade_hi, windows, role, cut, status) VALUES
('math-5', 'putnam', 'mcas-m', 5, 5, 'prior spring', 'screen', NULL,                        'unwritten'),  -- "no cut score"
('math-7', 'balian', 'mcas-m', 7, 7, 'prior spring', 'screen', 'Partially Meeting',         'unwritten'),
('ela-7',  'rice',   'mcas-e', 7, 7, 'prior spring', 'screen', 'Partially Meeting or below','unwritten');
UPDATE area_screener SET cut = 'no specific cut' WHERE area_id = 'ela-7' AND teacher = 'rice' AND tool_id = 'star-r';

COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
