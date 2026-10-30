-- v0.6: NCII academic intervention tools chart, one row per study of a program.
-- Apply to the LIVE database (css.db is the source of truth; seed.sql is not updated):
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-ncii-intervention.sql
-- Creates the table only; rows are entered as Brad works through the chart.
PRAGMA foreign_keys = ON;
BEGIN;
-- NCII academic intervention tools chart, one row per STUDY of a program (the chart's grain).
-- No row for a tool = not on the chart. Same rating vocabulary; visual_analysis also allows
-- 'na' (the chart's NA for group designs). Effect sizes are kept as the chart prints them,
-- with its markers: * significant, † not computable, -- no measures submitted.
CREATE TABLE ncii_intervention (
  tool_id       TEXT NOT NULL REFERENCES tool(id),
  study         TEXT NOT NULL,            -- citation as on the chart: 'Tracey & Young (2004)'
  study_type    TEXT,                     -- 'Group Design' | 'Single Case'
  -- quality of design & results
  design        TEXT CHECK (design IN ('convincing','partial','unconvincing','unavailable')),
  es_targeted   TEXT,                     -- Average ES (Targeted), as printed
  es_broader    TEXT,                     -- Average ES (Broader), as printed
  disagg_es     TEXT,                     -- Disaggregated ES Data Available: 'None', or which subgroups
  visual_analysis TEXT CHECK (visual_analysis IN ('convincing','partial','unconvincing','unavailable','na')),
  -- quality of other indicators
  participants  TEXT CHECK (participants IN ('convincing','partial','unconvincing','unavailable')),
  fidelity      TEXT CHECK (fidelity IN ('convincing','partial','unconvincing','unavailable')),         -- Fidelity of Implementation
  targeted_measures TEXT CHECK (targeted_measures IN ('convincing','partial','unconvincing','unavailable')),
  broader_measures  TEXT CHECK (broader_measures IN ('convincing','partial','unconvincing','unavailable')),
  n_outcome_measures TEXT,                -- No. of Outcome Measures: '7 Reading'
  -- intensity
  admin_group_size TEXT,                  -- Administration Group Size: 'Small group of students'
  duration      TEXT,                     -- Duration of Intervention: '45 minutes, 2 times a week, 20 weeks'
  interventionist TEXT,                   -- Minimum Interventionist Requirements: 'Teacher', 'Specialist'
  training      TEXT,                     -- Minimum Training Requirements: '1-2 days of training'
  -- additional research
  wwc_essa      TEXT,                     -- Intervention Reviewed by WWC or E-ESSA
  other_research TEXT,                    -- Other Research Potentially Eligible for NCII Review
  url           TEXT,                     -- NCII study detail page
  as_of         TEXT,                     -- YYYY-MM the row was copied from the chart
  PRIMARY KEY (tool_id, study)
);
COMMIT;
