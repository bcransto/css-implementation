-- MTSS tier-definition schema, v0.12
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
-- v0.10: dimension gets chart/grp and NCII's screening skill list; tool_dimension gets measure (per-measure claims).
-- v0.11: who says what. tool_profile (the vendor's product claims, NCII's field names) and measure (the vendor's
--   per-instrument claims) take the design and usability columns out of tool and the ncii_* tables, which keep
--   only NCII's findings; ncii_intervention gains the study's own facts; the intervention checklist joins dimension.
-- v0.12: instructor (the people) and instructor_tool (their training). profile.teacher and protocol.teacher
--   reference it; '-' stays the sentinel. protocol.deliverer_id names the person when there is one.
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
  notes       TEXT,                       -- prose
  url         TEXT
);
-- Everything the vendor claims about a tool is on tool_profile (the product) and measure (each instrument);
-- everything NCII found is in the ncii_* tables. They never share a table.

-- what the vendor says about one product, in the field names of NCII's submission form (the top half
-- of every NCII tool page, reprinted unrated). One optional row per tool. For a program NCII never
-- reviewed, filled from the publisher's implementation guide; source says which.
CREATE TABLE tool_profile (
  tool_id     TEXT PRIMARY KEY REFERENCES tool(id),
  grade_lo    INTEGER,                    -- "intended for use in the following age(s) and/or grade(s)"; K = 0
  grade_hi    INTEGER,
  intended_for TEXT,                      -- "intended for use with the following groups", as checked
  setting     TEXT,                       -- "Setting for which the program is designed": 'Individual students; Small group of students'
  max_group   INTEGER,                    -- "how many students compose a small group", when a number is given
  minutes     INTEGER,                    -- Minimum Number of Minutes Per Session (an assessment: administration minutes)
  min_per_week INTEGER,                   -- Minimum Number of Sessions Per Week
  min_weeks   INTEGER,                    -- Minimum Number of Weeks; NULL = not stated / until effective
  interventionist TEXT,                   -- Staff Qualified to Administer
  training    TEXT,                       -- Training Requirements: required?, time, format
  support     TEXT,                       -- Access to Technical Support
  cost        TEXT,                       -- Initial Cost, Replacement Cost, pricing structure, as written
  technology  TEXT,                       -- Is Technology Required?, and what
  manual      TEXT,                       -- Detailed Implementation Manual or Instructions Available: 'Yes' | 'No'
  fidelity_checklist TEXT,                -- fidelity of implementation guidance in the manual: 'Yes' | 'No'
  obtain      TEXT,                       -- Where to obtain
  description TEXT,                       -- the vendor's description of the program
  source      TEXT,                       -- 'NCII intervention tool page (vendor submission)', 'Wilson, Implementing Just Words'
  url         TEXT,
  as_of       TEXT                        -- YYYY-MM the source was read
);

-- what the vendor says about one instrument of an assessment (tool x measure): DIBELS 8 has seven,
-- Star Reading one ("Reading"). NCII's screening and PM pages describe this unit and print its
-- usability columns on every grade row; here they are held once. ncii_screening and ncii_pm reference it.
CREATE TABLE measure (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  measure     TEXT NOT NULL,              -- NCII "Area": 'Composite', 'Oral Reading Fluency', 'Reading'
  grade_lo    INTEGER,                    -- grades the instrument covers, per the NCII page; K = 0
  grade_hi    INTEGER,
  admin_format TEXT,                      -- 'Individual', 'Group', 'Individual; Group', 'Computer-administered'
  admin_time  TEXT,                       -- Admin & Scoring Time, as the chart writes it
  scoring_format TEXT,                    -- 'Automatic', 'Manual', 'Manual and/or Automatic'
  decision_rules TEXT,                    -- screening: Types of Decision Rules ('Benchmark Goals', 'Risk Benchmarks')
  multi_rules_evidence TEXT,              -- screening: Evidence Available for Multiple Decision Rules: 'Yes' | 'No'
  roi_eoy     TEXT,                       -- PM: ROI & EOY Benchmarks, as written
  description TEXT,                       -- the vendor's description of the measure
  url         TEXT,                       -- NCII tool detail page for this measure
  source      TEXT,
  as_of       TEXT,
  notes       TEXT,
  PRIMARY KEY (tool_id, measure)
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

-- NCII's skill / dimension lists from its tool detail pages, the full lists, so a tool page can show every
-- item and mark the ones a tool targets. Three lists, because NCII's charts differ:
--   chart 'pm'        the progress monitoring page's 17 "dimensions" (reading 8, spelling/writing 2, math 7)
--   chart 'screening' the screening page's "What skills does the tool screen?" checklist, finer and grouped
--                     (Phonological processing: RAN, ... ; Word ID: Accuracy, Speed; ... ; eight math groups x 4)
--   chart 'intervention' the intervention page's "area of focus" checklist (Early Literacy, Language, Reading,
--                     Mathematics, Writing, Externalizing and Internalizing Behavior)
CREATE TABLE dimension (
  id          TEXT PRIMARY KEY,           -- 'r-decoding', 's-pp-phonics', 'i-r-fluency'
  subject     TEXT NOT NULL CHECK (subject IN ('reading','writing','math','language','behavior')),
  name        TEXT NOT NULL,              -- as NCII prints it
  sort        INTEGER NOT NULL,           -- NCII's order within the list
  chart       TEXT NOT NULL DEFAULT 'pm' CHECK (chart IN ('pm','screening','intervention')),
  grp         TEXT                        -- group heading ('Word ID', 'Early Literacy'); NULL for the pm list
);

-- the dimensions a tool assesses or targets; absence = not selected on NCII's page (or not entered).
-- measure is '-' for a claim about a program; an assessment's rows name a measure row (NCII has one page
-- per measure). source says whether NCII's page or the publisher made the claim.
CREATE TABLE tool_dimension (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  measure     TEXT NOT NULL DEFAULT '-',  -- '-' = the whole tool; else a measure.measure for this tool (trigger below)
  dimension_id TEXT NOT NULL REFERENCES dimension(id),
  source      TEXT,                       -- 'NCII PM detail page', 'NCII screening detail page', 'publisher'
  as_of       TEXT,
  PRIMARY KEY (tool_id, measure, dimension_id)
);
-- a tool_dimension row that names a measure must name one the vendor described
CREATE TRIGGER tool_dimension_measure BEFORE INSERT ON tool_dimension
BEGIN
  SELECT RAISE(ABORT, 'tool_dimension.measure must be ''-'' or a measure row for this tool')
  WHERE NEW.measure <> '-'
    AND NOT EXISTS (SELECT 1 FROM measure m WHERE m.tool_id = NEW.tool_id AND m.measure = NEW.measure);
END;


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
-- Only NCII's findings: the chart's usability columns are the vendor's and live on measure.
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
  sample_rep  TEXT,                       -- Sample Representativeness, NCII's classification: 'National without Cross-Validation'
  bias_analysis TEXT,                     -- 'Provided' | 'Not Provided': whether the vendor submitted one
  as_of       TEXT,                       -- YYYY-MM the row was copied from the chart
  PRIMARY KEY (tool_id, measure, grade),
  FOREIGN KEY (tool_id, measure) REFERENCES measure(tool_id, measure)
);

-- NCII academic progress monitoring tools chart, one row per chart row (tool x measure x grade x type).
-- No row for a tool = not on the chart. Same rating vocabulary as ncii_screening; the chart's
-- legend lists the "d" marker but no PM cell carries one, so there are no *_d flags here.
CREATE TABLE ncii_pm (
  tool_id       TEXT NOT NULL REFERENCES tool(id),
  measure       TEXT NOT NULL,            -- NCII "Area": 'Computation', 'Maze', 'Reading'
  grade         INTEGER NOT NULL,         -- K = 0; one grade per row, as on the chart
  measure_type  TEXT NOT NULL,            -- 'End Year Goal' (general outcome) | 'Short Term Skill' (mastery)
  -- performance level standards
  reliability   TEXT CHECK (reliability IN ('convincing','partial','unconvincing','unavailable')),
  validity      TEXT CHECK (validity IN ('convincing','partial','unconvincing','unavailable')),
  bias_analysis TEXT,                     -- 'Provided' | 'Not Provided'
  -- growth standards
  slope_reliability TEXT CHECK (slope_reliability IN ('convincing','partial','unconvincing','unavailable')),  -- Sensitivity: Reliability of Slope
  slope_validity    TEXT CHECK (slope_validity IN ('convincing','partial','unconvincing','unavailable')),     -- Sensitivity: Validity of Slope
  alt_forms         TEXT CHECK (alt_forms IN ('convincing','partial','unconvincing','unavailable')),          -- Alternate Forms
  rules_goals       TEXT CHECK (rules_goals IN ('convincing','partial','unconvincing','unavailable')),        -- Decision Rules: Setting & Revising Goals
  rules_instruction TEXT CHECK (rules_instruction IN ('convincing','partial','unconvincing','unavailable')),  -- Decision Rules: Changing Instruction
  as_of         TEXT,                     -- YYYY-MM the row was copied from the chart
  PRIMARY KEY (tool_id, measure, grade, measure_type),
  FOREIGN KEY (tool_id, measure) REFERENCES measure(tool_id, measure)
);

-- NCII academic intervention tools chart, one row per STUDY of a program (the chart's grain).
-- No row for a tool = not on the chart. Same rating vocabulary; visual_analysis also allows
-- 'na' (the chart's NA for group designs). Effect sizes are kept as the chart prints them,
-- with its markers: * significant, † not computable, -- no measures submitted. The chart's Intensity
-- columns are the vendor's design (tool_profile); its WWC/E-ESSA column is in tool_evidence.
CREATE TABLE ncii_intervention (
  tool_id       TEXT NOT NULL REFERENCES tool(id),
  study         TEXT NOT NULL,            -- citation as on the chart: 'Tracey & Young (2004)'
  study_type    TEXT,                     -- 'Group Design' | 'Single Case'
  -- NCII's ratings: quality of design & results
  design        TEXT CHECK (design IN ('convincing','partial','unconvincing','unavailable')),
  es_targeted   TEXT,                     -- Average ES (Targeted), as printed
  es_broader    TEXT,                     -- Average ES (Broader), as printed
  disagg_es     TEXT,                     -- Disaggregated ES Data Available: 'None', or which subgroups
  visual_analysis TEXT CHECK (visual_analysis IN ('convincing','partial','unconvincing','unavailable','na')),
  -- NCII's ratings: quality of other indicators
  participants  TEXT CHECK (participants IN ('convincing','partial','unconvincing','unavailable')),
  fidelity      TEXT CHECK (fidelity IN ('convincing','partial','unconvincing','unavailable')),         -- Fidelity of Implementation
  targeted_measures TEXT CHECK (targeted_measures IN ('convincing','partial','unconvincing','unavailable')),
  broader_measures  TEXT CHECK (broader_measures IN ('convincing','partial','unconvincing','unavailable')),
  n_outcome_measures TEXT,                -- No. of Outcome Measures: '7 Reading'
  -- the study's own facts, as implemented (the vendor's design minimums are on tool_profile)
  sample        TEXT,                     -- who: '109 grade 3 students in 6 suburban schools, below the 40th percentile on ORF'
  grades        TEXT,                     -- '3', '3-5'
  assignment    TEXT,                     -- 'randomized', 'matched comparison', 'systematic (convenience sample)'
  group_size    TEXT,                     -- as run: '3-6 (mean 5)', 'individual'
  weeks         TEXT,
  per_week      TEXT,                     -- sessions per week, as run
  minutes       TEXT,                     -- per session, as run: '30 planned, about 20 delivered'
  deliverer     TEXT,                     -- who taught it, and their training
  notes         TEXT,                     -- results and caveats in a sentence
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

-- the people. Ids are slugs, normally the last name; a second Smith gets 'smith-j'. '-' = nobody (the area's rule).
CREATE TABLE instructor (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,              -- as shown on the page: 'Spiegl'
  full_name   TEXT,
  role        TEXT CHECK (role IN ('classroom teacher','interventionist','reading specialist','special educator','para','slp','coach','admin')),
  subject     TEXT,                       -- 'math' | 'reading' | NULL = both / not applicable
  grade_lo    INTEGER,                    -- grades taught; K = 0
  grade_hi    INTEGER,
  flex_duty   INTEGER,                    -- 1 = staffs the FLEX block, 0 = does not, NULL = not asked
  interviewed_on TEXT,                    -- YYYY-MM(-DD) of the interview behind this person's observed rows
  notes       TEXT                        -- prose
);

-- which programs or instruments a person is trained to deliver; no row = not trained, or not asked
CREATE TABLE instructor_tool (
  instructor_id TEXT NOT NULL REFERENCES instructor(id),
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  trained_on  TEXT,                       -- YYYY or YYYY-MM; NULL = date unknown
  note        TEXT,                       -- 'Wilson Just Words launch workshop'
  PRIMARY KEY (instructor_id, tool_id)
);

CREATE TABLE profile (
  id          TEXT PRIMARY KEY,
  area_id     TEXT NOT NULL REFERENCES area(id),
  teacher     TEXT NOT NULL DEFAULT '-' REFERENCES instructor(id),  -- '-' = the area's profile; else that teacher's own category
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
  teacher     TEXT NOT NULL DEFAULT '-' REFERENCES instructor(id),  -- '-' = the area's rule; else what that teacher does
  basis       TEXT NOT NULL DEFAULT 'defined' CHECK (basis IN ('observed','defined')),
  as_of       TEXT,                       -- observed rows: when this was recorded (YYYY-MM)
  evidence    TEXT,                       -- observed rows: 'interview', 'PM sheet', 'self-report'
  deliverer_role TEXT,                    -- a role: 'trained para'
  deliverer_id TEXT REFERENCES instructor(id),  -- the named person, when there is one (observed rows)
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

-- sentinels: whole-class rows use profile '-', the area's own rows use instructor '-'
INSERT INTO area VALUES ('-', '-', 0, 0, 0);
INSERT INTO instructor VALUES ('-', '-', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO profile VALUES ('-', '-', '-', 'defined', '(all)', 'whole class');

-- NCII's academic dimension list (tool detail pages). NCII's page misspells "Writting"; corrected here.
INSERT INTO dimension(id, subject, name, sort) VALUES
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

-- NCII's screening skill checklist (screening tool detail pages), grouped as the page prints it.
INSERT INTO dimension(id, subject, name, sort, chart, grp) VALUES
('s-pp-ran','reading','RAN',101,'screening','Phonological processing'),
('s-pp-memory','reading','Memory',102,'screening','Phonological processing'),
('s-pp-awareness','reading','Awareness',103,'screening','Phonological processing'),
('s-pp-lsc','reading','Letter sound correspondence',104,'screening','Phonological processing'),
('s-pp-phonics','reading','Phonics',105,'screening','Phonological processing'),
('s-pp-structural','reading','Structural analysis',106,'screening','Phonological processing'),
('s-wid-acc','reading','Accuracy',107,'screening','Word ID'),
('s-wid-speed','reading','Speed',108,'screening','Word ID'),
('s-nw-acc','reading','Accuracy',109,'screening','Nonword'),
('s-nw-speed','reading','Speed',110,'screening','Nonword'),
('s-sp-acc','reading','Accuracy',111,'screening','Spelling'),
('s-sp-speed','reading','Speed',112,'screening','Spelling'),
('s-pass-acc','reading','Accuracy',113,'screening','Passage'),
('s-pass-speed','reading','Speed',114,'screening','Passage'),
('s-rc-mc','reading','Multiple choice questions',115,'screening','Reading comprehension'),
('s-rc-cloze','reading','Cloze',116,'screening','Reading comprehension'),
('s-rc-cr','reading','Constructed response',117,'screening','Reading comprehension'),
('s-rc-retell','reading','Retell',118,'screening','Reading comprehension'),
('s-rc-maze','reading','Maze',119,'screening','Reading comprehension'),
('s-rc-sv','reading','Sentence verification',120,'screening','Reading comprehension'),
('s-rc-other','reading','Other',121,'screening','Reading comprehension'),
('s-lc-mc','reading','Multiple choice questions',122,'screening','Listening comprehension'),
('s-lc-cloze','reading','Cloze',123,'screening','Listening comprehension'),
('s-lc-cr','reading','Constructed response',124,'screening','Listening comprehension'),
('s-lc-retell','reading','Retell',125,'screening','Listening comprehension'),
('s-lc-maze','reading','Maze',126,'screening','Listening comprehension'),
('s-lc-sv','reading','Sentence verification',127,'screening','Listening comprehension'),
('s-lc-vocab','reading','Vocabulary',128,'screening','Listening comprehension'),
('s-lc-expressive','reading','Expressive',129,'screening','Listening comprehension'),
('s-lc-receptive','reading','Receptive',130,'screening','Listening comprehension'),
('s-m-global-acc','math','Accuracy',131,'screening','Global Indicator of Math Competence'),
('s-m-global-speed','math','Speed',132,'screening','Global Indicator of Math Competence'),
('s-m-global-mc','math','Multiple choice',133,'screening','Global Indicator of Math Competence'),
('s-m-global-cr','math','Constructed response',134,'screening','Global Indicator of Math Competence'),
('s-m-early-acc','math','Accuracy',135,'screening','Early Numeracy'),
('s-m-early-speed','math','Speed',136,'screening','Early Numeracy'),
('s-m-early-mc','math','Multiple choice',137,'screening','Early Numeracy'),
('s-m-early-cr','math','Constructed response',138,'screening','Early Numeracy'),
('s-m-concepts-acc','math','Accuracy',139,'screening','Mathematics Concepts'),
('s-m-concepts-speed','math','Speed',140,'screening','Mathematics Concepts'),
('s-m-concepts-mc','math','Multiple choice',141,'screening','Mathematics Concepts'),
('s-m-concepts-cr','math','Constructed response',142,'screening','Mathematics Concepts'),
('s-m-computation-acc','math','Accuracy',143,'screening','Mathematics Computation'),
('s-m-computation-speed','math','Speed',144,'screening','Mathematics Computation'),
('s-m-computation-mc','math','Multiple choice',145,'screening','Mathematics Computation'),
('s-m-computation-cr','math','Constructed response',146,'screening','Mathematics Computation'),
('s-m-application-acc','math','Accuracy',147,'screening','Mathematics Application'),
('s-m-application-speed','math','Speed',148,'screening','Mathematics Application'),
('s-m-application-mc','math','Multiple choice',149,'screening','Mathematics Application'),
('s-m-application-cr','math','Constructed response',150,'screening','Mathematics Application'),
('s-m-fractions-acc','math','Accuracy',151,'screening','Fractions/Decimals'),
('s-m-fractions-speed','math','Speed',152,'screening','Fractions/Decimals'),
('s-m-fractions-mc','math','Multiple choice',153,'screening','Fractions/Decimals'),
('s-m-fractions-cr','math','Constructed response',154,'screening','Fractions/Decimals'),
('s-m-algebra-acc','math','Accuracy',155,'screening','Algebra'),
('s-m-algebra-speed','math','Speed',156,'screening','Algebra'),
('s-m-algebra-mc','math','Multiple choice',157,'screening','Algebra'),
('s-m-algebra-cr','math','Constructed response',158,'screening','Algebra'),
('s-m-geometry-acc','math','Accuracy',159,'screening','Geometry'),
('s-m-geometry-speed','math','Speed',160,'screening','Geometry'),
('s-m-geometry-mc','math','Multiple choice',161,'screening','Geometry'),
('s-m-geometry-cr','math','Constructed response',162,'screening','Geometry'),
('s-m-other','math','Other',163,'screening','Mathematics');

-- NCII's intervention-page checklist ("Please indicate the academic / behavior area of focus").
INSERT INTO dimension(id, subject, name, sort, chart, grp) VALUES
('i-el-print','reading','Print knowledge/awareness',201,'intervention','Early Literacy'),
('i-el-alphabet','reading','Alphabet knowledge',202,'intervention','Early Literacy'),
('i-el-pa','reading','Phonological awareness',203,'intervention','Early Literacy'),
('i-el-writing','reading','Early writing',204,'intervention','Early Literacy'),
('i-el-decoding','reading','Early decoding abilities',205,'intervention','Early Literacy'),
('i-el-other','reading','Other',206,'intervention','Early Literacy'),
('i-lang-vocab','language','Expressive and receptive vocabulary',207,'intervention','Language'),
('i-lang-grammar','language','Grammar',208,'intervention','Language'),
('i-lang-syntax','language','Syntax',209,'intervention','Language'),
('i-lang-listening','language','Listening comprehension',210,'intervention','Language'),
('i-lang-other','language','Other',211,'intervention','Language'),
('i-r-pa','reading','Phonological awareness',212,'intervention','Reading'),
('i-r-phonics','reading','Phonics/word study',213,'intervention','Reading'),
('i-r-comp','reading','Comprehension',214,'intervention','Reading'),
('i-r-fluency','reading','Fluency',215,'intervention','Reading'),
('i-r-vocab','reading','Vocabulary',216,'intervention','Reading'),
('i-r-spelling','reading','Spelling',217,'intervention','Reading'),
('i-r-other','reading','Other',218,'intervention','Reading'),
('i-m-computation','math','Computation',219,'intervention','Mathematics'),
('i-m-concepts','math','Concepts and/or word problems',220,'intervention','Mathematics'),
('i-m-whole','math','Whole number arithmetic',221,'intervention','Mathematics'),
('i-m-comprehensive','math','Comprehensive: computation/procedures, problem solving, and mathematical concepts',222,'intervention','Mathematics'),
('i-m-algebra','math','Algebra',223,'intervention','Mathematics'),
('i-m-fractions','math','Fractions, decimals (rational number)',224,'intervention','Mathematics'),
('i-m-geometry','math','Geometry and measurement',225,'intervention','Mathematics'),
('i-m-other','math','Other',226,'intervention','Mathematics'),
('i-w-handwriting','writing','Handwriting',227,'intervention','Writing'),
('i-w-spelling','writing','Spelling',228,'intervention','Writing'),
('i-w-sentence','writing','Sentence construction',229,'intervention','Writing'),
('i-w-planning','writing','Planning and revising',230,'intervention','Writing'),
('i-w-other','writing','Other',231,'intervention','Writing'),
('i-ext-aggression','behavior','Physical aggression',232,'intervention','Externalizing Behavior'),
('i-ext-threats','behavior','Verbal threats',233,'intervention','Externalizing Behavior'),
('i-ext-property','behavior','Property destruction',234,'intervention','Externalizing Behavior'),
('i-ext-noncompliance','behavior','Noncompliance',235,'intervention','Externalizing Behavior'),
('i-ext-disengagement','behavior','High levels of disengagement',236,'intervention','Externalizing Behavior'),
('i-ext-disruptive','behavior','Disruptive behavior',237,'intervention','Externalizing Behavior'),
('i-ext-social','behavior','Social behavior (peer and adult interactions)',238,'intervention','Externalizing Behavior'),
('i-ext-other','behavior','Other',239,'intervention','Externalizing Behavior'),
('i-int-depression','behavior','Depression',240,'intervention','Internalizing Behavior'),
('i-int-anxiety','behavior','Anxiety',241,'intervention','Internalizing Behavior'),
('i-int-social','behavior','Social difficulties (e.g., withdrawal)',242,'intervention','Internalizing Behavior'),
('i-int-phobia','behavior','School phobia',243,'intervention','Internalizing Behavior'),
('i-int-other','behavior','Other',244,'intervention','Internalizing Behavior');
