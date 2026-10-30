-- v0.8: publisher design fields on tool (named after NCII's Intensity columns) and tool_evidence.
-- Loads Read Naturally's design from the NCII intervention chart's Intensity cells (copied 2026-10-30)
-- and records that NCII reviewed it. Other programs' designs are entered from publisher guides.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-tool-design-evidence.sql
PRAGMA foreign_keys = ON;
BEGIN;
ALTER TABLE tool ADD COLUMN design_group TEXT;
ALTER TABLE tool ADD COLUMN max_group INTEGER;
ALTER TABLE tool ADD COLUMN min_per_week INTEGER;
ALTER TABLE tool ADD COLUMN min_weeks INTEGER;
ALTER TABLE tool ADD COLUMN interventionist TEXT;
ALTER TABLE tool ADD COLUMN training TEXT;
ALTER TABLE tool ADD COLUMN grade_lo INTEGER;
ALTER TABLE tool ADD COLUMN grade_hi INTEGER;
ALTER TABLE tool ADD COLUMN design_source TEXT;
-- what each reviewer found about a tool, one row per source consulted. A 'not listed' row is a fact:
-- it says the source was checked on as_of. Absence of rows = nobody has looked yet.
CREATE TABLE tool_evidence (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  source      TEXT NOT NULL CHECK (source IN ('ncii','wwc','essa','publisher','study','other')),
  finding     TEXT NOT NULL,              -- the source's own words: 'Potentially positive effects', 'Promising', 'not listed'
  domain      TEXT,                       -- outcome the finding is about: 'alphabetics', 'computation'
  grades      TEXT,                       -- grade range the finding covers, as stated
  url         TEXT,
  notes       TEXT,
  as_of       TEXT,                       -- YYYY-MM the source was checked
  PRIMARY KEY (tool_id, source, finding)
);
UPDATE tool SET minutes = 30, min_per_week = 3, design_group = 'Individual students; Small group of students',
       interventionist = 'Teacher; Specialist; Support Staff/Other', training = '1 day of training',
       design_source = 'NCII intervention chart, Intensity (2026-10)'
 WHERE id = 'read-nat';
INSERT INTO tool_evidence (tool_id, source, finding, domain, url, notes, as_of) VALUES
('read-nat','ncii','3 studies reviewed','reading','https://charts.intensiveintervention.org/aintervention',
 'Christ & Davie 2009, Heistad 2005, Tucker & Jones 2010; see the NCII intervention rows on this page','2026-10');
COMMIT;
