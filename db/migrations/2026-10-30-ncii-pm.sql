-- v0.5: NCII academic progress monitoring tools chart ratings, one row per chart row.
-- Apply to the LIVE database (css.db is the source of truth; seed.sql is not updated):
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-ncii-pm.sql
-- Creates the table only; rows are entered as Brad works through the chart.
PRAGMA foreign_keys = ON;
BEGIN;
-- NCII academic progress monitoring tools chart, one row per chart row (tool x measure x grade x type).
-- No row for a tool = not on the chart. Same rating vocabulary as ncii_screening; the chart's
-- legend lists the "d" marker but no PM cell carries one, so there are no *_d flags here.
CREATE TABLE ncii_pm (
  tool_id       TEXT NOT NULL REFERENCES tool(id),
  measure       TEXT NOT NULL,            -- NCII "Area": 'Computation', 'Maze', 'Oral Reading Fluency'
  grade         INTEGER NOT NULL,         -- K = 0; one grade per row, as on the chart
  measure_type  TEXT NOT NULL,            -- 'End Year Goal' (general outcome) | 'Short Term Skill' (mastery)
  -- performance level standards
  reliability   TEXT CHECK (reliability IN ('convincing','partial','unconvincing','unavailable')),
  validity      TEXT CHECK (validity IN ('convincing','partial','unconvincing','unavailable')),
  bias_analysis TEXT,                     -- 'Provided' | 'Not Provided' (chart text, not a bubble)
  -- growth standards
  slope_reliability TEXT CHECK (slope_reliability IN ('convincing','partial','unconvincing','unavailable')),  -- Sensitivity: Reliability of Slope
  slope_validity    TEXT CHECK (slope_validity IN ('convincing','partial','unconvincing','unavailable')),     -- Sensitivity: Validity of Slope
  alt_forms         TEXT CHECK (alt_forms IN ('convincing','partial','unconvincing','unavailable')),          -- Alternate Forms
  rules_goals       TEXT CHECK (rules_goals IN ('convincing','partial','unconvincing','unavailable')),        -- Decision Rules: Setting & Revising Goals
  rules_instruction TEXT CHECK (rules_instruction IN ('convincing','partial','unconvincing','unavailable')),  -- Decision Rules: Changing Instruction
  -- usability
  admin_format  TEXT,                     -- 'Individual', 'Group', 'Computer-administered', 'Other'
  admin_time    TEXT,                     -- Admin & Scoring Time, as written on the chart
  scoring_format TEXT,                    -- 'Manual', 'Automatic', 'Other'
  roi_eoy       TEXT,                     -- ROI & EOY Benchmarks, as written ('ROI & EOY Benchmarks Available')
  url           TEXT,                     -- NCII tool detail page
  as_of         TEXT,                     -- YYYY-MM the row was copied from the chart
  PRIMARY KEY (tool_id, measure, grade, measure_type)
);
COMMIT;
