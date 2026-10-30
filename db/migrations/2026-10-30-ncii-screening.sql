-- v0.4: NCII academic screening tools chart ratings, one row per chart row.
-- Apply to the LIVE database (css.db is the source of truth; seed.sql is not updated):
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-ncii-screening.sql
-- Creates the table only; rows are entered as Brad works through the chart.
PRAGMA foreign_keys = ON;
BEGIN;
-- NCII academic screening tools chart, one row per chart row (tool x measure x grade).
-- No row for a tool = not on the chart (same convention as tool_license).
-- Ratings: convincing / partial / unconvincing (NCII's full, half, empty bubble),
-- 'unavailable' = NCII's null bubble, NULL = not yet entered. *_d = NCII's "d" marker,
-- disaggregated data available.
CREATE TABLE ncii_screening (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  measure     TEXT NOT NULL,              -- NCII "Area": 'Composite', 'Computation', 'Maze'
  grade       INTEGER NOT NULL,           -- K = 0; one grade per row, as on the chart
  ca_fall     TEXT CHECK (ca_fall     IN ('convincing','partial','unconvincing','unavailable')),
  ca_winter   TEXT CHECK (ca_winter   IN ('convincing','partial','unconvincing','unavailable')),
  ca_spring   TEXT CHECK (ca_spring   IN ('convincing','partial','unconvincing','unavailable')),
  ca_fall_d   INTEGER NOT NULL DEFAULT 0,
  ca_winter_d INTEGER NOT NULL DEFAULT 0,
  ca_spring_d INTEGER NOT NULL DEFAULT 0,
  reliability TEXT CHECK (reliability IN ('convincing','partial','unconvincing','unavailable')),
  validity    TEXT CHECK (validity    IN ('convincing','partial','unconvincing','unavailable')),
  sample_rep  TEXT CHECK (sample_rep  IN ('convincing','partial','unconvincing','unavailable')),  -- Sample Representativeness
  bias_analysis TEXT,                     -- 'Provided' | 'Not Provided' (chart text, not a bubble)
  admin_format TEXT,                      -- 'Individual', 'Group', 'Individual; Group'
  admin_time  TEXT,                       -- Admin & Scoring Time, as written on the chart
  scoring_format TEXT,                    -- 'Automatic', 'Manual', ...
  decision_rules TEXT,                    -- Types of Decision Rules
  multi_rules_evidence TEXT,              -- Evidence Available for Multiple Decision Rules: 'Yes' | 'No'
  url         TEXT,                       -- NCII tool detail page
  as_of       TEXT,                       -- YYYY-MM the row was copied from the chart
  PRIMARY KEY (tool_id, measure, grade)
);
COMMIT;
