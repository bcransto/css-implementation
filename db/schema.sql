-- MTSS tier-definition schema, v0.9
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
-- v0.7: ncii_screening.sample_rep is chart text, not a rating; area.building dropped.
-- v0.8: tool carries the publisher's design (minimum dose, group size, deliverer, training, grades),
--   named after NCII's Intensity columns; tool_evidence records what each reviewer found, or did not.
-- v0.9: dimension (NCII's 17 academic dimensions) and tool_dimension (which ones a tool assesses).
PRAGMA foreign_keys = ON;

CREATE TABLE area (
  id          TEXT PRIMARY KEY,           -- 'math-6', 'reading-k2'
  subject     TEXT NOT NULL,              -- 'math' | 'reading' | 'behavior'
  grade_lo    INTEGER NOT NULL,           -- K = 0
  grade_hi    INTEGER NOT NULL,
  has_flex    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE tool (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  vendor      TEXT,
  minutes     INTEGER,                    -- minutes per session: the design minimum for a program, admin time for an assessment
  notes       TEXT,                       -- prose
  url         TEXT,
  -- the publisher's design for a program, named after NCII's Intensity columns; NULL = not stated
  design_group TEXT,                      -- Administration Group Size as the source states it: 'Small group of students', '1-5'
  max_group   INTEGER,                    -- largest group the design allows, when the source gives a number
  min_per_week INTEGER,                   -- Minimum Duration: sessions per week
  min_weeks   INTEGER,                    -- Minimum Duration: weeks, when stated
  interventionist TEXT,                   -- Minimum Interventionist Requirements
  training    TEXT,                       -- Minimum Training Requirements
  grade_lo    INTEGER,                    -- grades the design covers (not the license: see tool_license)
  grade_hi    INTEGER,
  design_source TEXT                      -- where the design came from: 'NCII intervention chart', an implementation guide, a URL
);

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

-- NCII's academic dimensions ("What dimensions does the tool assess?" on a tool's detail page),
-- the full list, so a tool page can show every dimension and mark the ones the tool targets.
CREATE TABLE dimension (
  id          TEXT PRIMARY KEY,           -- 'r-decoding', 'm-fractions'
  subject     TEXT NOT NULL CHECK (subject IN ('reading','writing','math')),
  name        TEXT NOT NULL,              -- as NCII prints it
  sort        INTEGER NOT NULL            -- NCII's order within the list
);

-- the dimensions a tool assesses or targets; absence = not selected on NCII's page (or not entered)
CREATE TABLE tool_dimension (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  dimension_id TEXT NOT NULL REFERENCES dimension(id),
  source      TEXT,                       -- 'NCII PM detail page', 'publisher'
  as_of       TEXT,
  PRIMARY KEY (tool_id, dimension_id)
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
-- disaggregated data available. Sample representativeness and bias analysis are chart text.
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
  sample_rep  TEXT,                       -- Sample Representativeness, chart text: 'National without Cross-Validation'
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
INSERT INTO area VALUES ('-', '-', 0, 0, 0);
INSERT INTO profile VALUES ('-', '-', '-', 'defined', '(all)', 'whole class');

-- NCII's academic dimension list (tool detail pages). NCII's page misspells "Writting"; corrected here.
INSERT INTO dimension VALUES
('r-global','reading','Global Indicator of Reading Competence',1),
('r-listening','reading','Listening Comprehension',2),
('r-vocab','reading','Vocabulary',3),
('r-pa','reading','Phonemic Awareness',4),
('r-decoding','reading','Decoding',5),
('r-passage','reading','Passage Reading',6),
('r-wordid','reading','Word Identification',7),
('r-comp','reading','Comprehension',8),
('w-spelling','writing','Global Indicator of Spelling Competence',9),
('w-expression','writing','Global Indicator of Written Expression Competence',10),
('m-global','math','Global Indicator of Mathematics Competence',11),
('m-early','math','Early Numeracy',12),
('m-concepts','math','Mathematics Concepts',13),
('m-computation','math','Mathematics Computation',14),
('m-application','math','Mathematics Application',15),
('m-fractions','math','Fractions',16),
('m-algebra','math','Algebra',17);
