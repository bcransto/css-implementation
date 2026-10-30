-- MTSS tier-definition schema, v0.6
-- Changes from v0.1 (after simplifier + breaker review):
--   * numeric grade bounds on area, area_screener; new tool_license replaces tool.owned
--   * area_core link table (an area can have two cores)
--   * profile_id sentinel '-' instead of NULL so UNIQUE works for whole-class rows
--   * protocol_field_status, protocol_source dropped -> protocol.status_note, protocol.citations (text)
--   * route kept, trimmed; 'iep' and 'external' added; target_area_id added
--   * tool.kind / tool.ncii comma lists dropped; roles are derived from protocol columns
--   * student_example.timeline_json -> timeline (text)
-- v0.3: protocol and profile can be scoped to a teacher. teacher='-' means the area.
--   basis='observed' = a description of what a teacher does now; 'defined' = the area's decided rule.
--   area.teachers dropped; teachers appear only on scoped rows.
-- v0.4: ncii_screening, one row per row of NCII's academic screening tools chart.
--   No row for a tool = not on the chart. PM and intervention charts to follow.
-- v0.5: ncii_pm, one row per row of NCII's academic progress monitoring tools chart.
-- v0.6: ncii_intervention, one row per study on NCII's academic intervention tools chart.
PRAGMA foreign_keys = ON;

CREATE TABLE area (
  id          TEXT PRIMARY KEY,           -- 'math-6', 'reading-k2'
  subject     TEXT NOT NULL,              -- 'math' | 'reading' | 'behavior'
  grade_lo    INTEGER NOT NULL,           -- K = 0
  grade_hi    INTEGER NOT NULL,
  building    TEXT,                       -- 'CPS' | 'CMS' | 'CCHS'
  has_flex    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE tool (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  vendor      TEXT,
  minutes     INTEGER,
  notes       TEXT,                       -- evidence, training, NCII listing, URL: prose
  url         TEXT
);

-- which grades a tool is licensed/owned for; absence of a row = not owned
CREATE TABLE tool_license (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  grade_lo    INTEGER NOT NULL,
  grade_hi    INTEGER NOT NULL,
  note        TEXT,
  PRIMARY KEY (tool_id, grade_lo)
);

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

CREATE TABLE area_core (
  area_id     TEXT NOT NULL REFERENCES area(id),
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  role        TEXT,                       -- 'phonics', 'comprehension', NULL = the core
  status      TEXT NOT NULL CHECK (status IN ('doc','unwritten','proposed')),
  PRIMARY KEY (area_id, tool_id)
);

CREATE TABLE area_screener (
  area_id     TEXT NOT NULL REFERENCES area(id),
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  grade_lo    INTEGER NOT NULL,
  grade_hi    INTEGER NOT NULL,
  windows     TEXT,                       -- 'Sep,Jan,May' | 'prior spring' | 'on request'
  role        TEXT NOT NULL CHECK (role IN ('screen','level_check','on_request')),
  cut         TEXT,                       -- 'PR < 25', 'below benchmark'
  status      TEXT NOT NULL CHECK (status IN ('doc','unwritten','proposed')),
  PRIMARY KEY (area_id, tool_id, grade_lo, role)
);

CREATE TABLE profile (
  id          TEXT PRIMARY KEY,
  area_id     TEXT NOT NULL REFERENCES area(id),
  teacher     TEXT NOT NULL DEFAULT '-',  -- '-' = the area's profile; a name = that teacher's own category
  basis       TEXT NOT NULL DEFAULT 'defined' CHECK (basis IN ('observed','defined')),
  name        TEXT NOT NULL,
  sort_rule   TEXT NOT NULL,              -- observed: how this teacher decides; defined: how the second stage decides
  UNIQUE (area_id, teacher, name)
);

CREATE TABLE route (
  id          TEXT PRIMARY KEY,
  kind        TEXT NOT NULL CHECK (kind IN ('tier','tier1_plan','slp','cst','sped_eval','iep','carry','external','none')),
  tier        INTEGER,
  target_area_id TEXT REFERENCES area(id),
  description TEXT                        -- owner, legal note, what happens
);

CREATE TABLE source (
  id          TEXT PRIMARY KEY,
  citation    TEXT NOT NULL,
  url         TEXT
);

CREATE TABLE protocol (
  id          TEXT PRIMARY KEY,
  area_id     TEXT NOT NULL REFERENCES area(id),
  tier        INTEGER,                    -- NULL = routes outside the tiers
  profile_id  TEXT NOT NULL DEFAULT '-' REFERENCES profile(id),
  teacher     TEXT NOT NULL DEFAULT '-',  -- '-' = the area's rule; a name = what that teacher does
  basis       TEXT NOT NULL DEFAULT 'defined' CHECK (basis IN ('observed','defined')),
  as_of       TEXT,                       -- observed rows: when this was recorded (YYYY-MM)
  evidence    TEXT,                       -- observed rows: 'interview', 'PM sheet', 'self-report'
  deliverer_role TEXT,
  placement_tool_id TEXT REFERENCES tool(id),
  program_id  TEXT REFERENCES tool(id),
  pm_tool_id  TEXT REFERENCES tool(id),
  pm_metric   TEXT,
  entry_rule  TEXT,                       -- Tier 1: the flag rule
  dosage      TEXT,
  group_size  TEXT,
  weeks       TEXT,
  pm_rule     TEXT,                       -- frequency, aimline, decision rule, in one textarea
  review_rule TEXT,
  exit_rule   TEXT,
  next_step_id   TEXT REFERENCES route(id),
  nonresponse_id TEXT REFERENCES route(id),
  status      TEXT NOT NULL CHECK (status IN ('doc','unwritten','proposed','iep')),
  status_note TEXT,                       -- 'dosage is doc; rest proposed'
  citations   TEXT,                       -- 'pg2021 Rec 4 pp.29-39; smart p.14'
  UNIQUE (area_id, tier, profile_id, teacher)
);

-- a protocol and its profile must be scoped to the same teacher
CREATE TRIGGER protocol_profile_scope BEFORE INSERT ON protocol
BEGIN
  SELECT RAISE(ABORT, 'protocol.teacher must match profile.teacher (or profile = ''-'')')
  WHERE NEW.profile_id <> '-'
    AND NEW.teacher <> (SELECT teacher FROM profile WHERE id = NEW.profile_id);
END;

CREATE TABLE student_example (
  id          TEXT PRIMARY KEY,
  student_key TEXT NOT NULL,              -- 'K' : same key across areas = same (fake) student
  protocol_id TEXT NOT NULL REFERENCES protocol(id),
  timeline    TEXT NOT NULL
);

-- sentinels: whole-class rows use profile '-'
INSERT INTO area VALUES ('-', '-', 0, 0, NULL, 0);
INSERT INTO profile VALUES ('-', '-', '-', 'defined', '(all)', 'whole class');
