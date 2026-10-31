-- v0.11: who says what. The vendor's claims leave tool and the ncii_* tables for tool_profile (per product)
-- and measure (per instrument); the ncii_* tables keep NCII's findings; ncii_intervention gains the study's
-- own facts as implemented; the intervention-page checklist joins dimension. Loads Read Naturally's vendor
-- profile, its three study pages (read 2026-10-31), its WWC and ESSA findings and target skills; measure rows
-- for DIBELS 8 (seven), Star Reading and Star Math; moves Star Reading's dimension rows to its measure.
-- Rebuilds tables, so foreign keys are off for the transaction and checked at the end.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-31-vendor-profile-measure.sql
PRAGMA foreign_keys = OFF;
BEGIN;

-- 1. the vendor's product claims
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


INSERT INTO tool_profile(tool_id, grade_lo, grade_hi, setting, max_group, minutes, min_per_week, min_weeks, interventionist, training, source)
  SELECT id, grade_lo, grade_hi, design_group, max_group, minutes, min_per_week, min_weeks, interventionist, training, design_source
  FROM tool
  WHERE coalesce(minutes, design_group, max_group, min_per_week, min_weeks, interventionist, training, grade_lo, grade_hi, design_source) IS NOT NULL;
UPDATE tool_profile SET grade_lo = '1', grade_hi = '12', intended_for = 'Students with learning disabilities; English language learners; Any student at risk for academic failure', setting = 'Individual students; Small group of students', max_group = NULL, minutes = '30', min_per_week = '3', min_weeks = NULL, interventionist = 'Special Education Teacher; General Education Teacher; Reading Specialist; Math Specialist; EL Specialist; Interventionist; Student Support Services Personnel', training = 'Required: 1 day of training. Live full-day seminars, video workshops and self-study training books; assumes expertise in reading.', support = 'Professional educators and technical support staff available five days a week', cost = 'Initial $129 per level (Encore). Read Live 30 seats $599 per year; Network Plus software $399 per level, one-time. Replacement: contact vendor.', technology = 'Yes: Encore needs a CD player; the software version is a standalone or network CD; Read Live is web-based', manual = 'Yes', fidelity_checklist = NULL, obtain = 'Read Naturally, 2945 Lone Oak Dr, Suite 190, St. Paul, MN 55121; (651) 452-4085; readnaturally.com', description = 'Develops fluency, supports vocabulary, and promotes comprehension by combining teacher modeling, repeated reading, and progress monitoring (vendor description).', source = 'NCII intervention tool page (vendor submission)', url = 'https://charts.intensiveintervention.org/intervention/toolGRP/b7b83d9394626b24', as_of = '2026-10' WHERE tool_id = 'read-nat';
UPDATE tool_profile SET url = 'https://www.wilsonlanguage.com/knowledge-library/programs/just-words/implementing-just-words/', as_of = '2026-10' WHERE tool_id = 'just-words';
UPDATE tool_profile SET url = 'https://www.mathlearningcenter.org/curriculum/bridges-intervention', as_of = '2026-10' WHERE tool_id = 'bridges-i';
UPDATE tool_profile SET source = 'NCII PM detail page (vendor submission)', url = 'https://charts.intensiveintervention.org/progressmonitoring/tool/?id=d833969b4dd49868', as_of = '2026-10' WHERE tool_id = 'star-r';

-- 2. the vendor's instrument claims, lifted off the chart rows (identical across grades)
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

INSERT INTO measure(tool_id, measure, grade_lo, grade_hi, admin_format, admin_time, scoring_format, decision_rules, multi_rules_evidence, url, source, as_of)
  SELECT tool_id, measure, min(grade), max(grade), max(admin_format), max(admin_time), max(scoring_format), max(decision_rules), max(multi_rules_evidence),
         max(url), 'NCII screening chart (vendor submission)', max(as_of)
  FROM ncii_screening GROUP BY tool_id, measure;
INSERT INTO measure(tool_id, measure, grade_lo, grade_hi, admin_format, admin_time, scoring_format, roi_eoy, url, source, as_of)
  SELECT tool_id, measure, min(grade), max(grade), max(admin_format), max(admin_time), max(scoring_format), max(roi_eoy), max(url),
         'NCII PM chart (vendor submission)', max(as_of)
  FROM ncii_pm GROUP BY tool_id, measure
  ON CONFLICT(tool_id, measure) DO UPDATE SET
    roi_eoy = excluded.roi_eoy,
    grade_lo = min(grade_lo, excluded.grade_lo), grade_hi = max(grade_hi, excluded.grade_hi),
    source = source || '; NCII PM chart';
UPDATE measure SET grade_lo = '0', grade_hi = '8', url = 'https://charts.intensiveintervention.org/screening/tool/?id=4928894588828f86', description = 'Combines the grade''s DIBELS 8 subtest scores into one estimate of overall literacy skill; 5 min scoring per student', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Composite';
UPDATE measure SET grade_lo = '0', grade_hi = '1', url = 'https://charts.intensiveintervention.org/screening/tool/?id=d8bd5d99d4298b6f', description = 'Individually administered; an indicator of later reading risk in K and grade 1; 2 min per student plus 1 min scoring', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Letter Naming Fluency';
UPDATE measure SET grade_lo = '2', grade_hi = '8', url = 'https://charts.intensiveintervention.org/screening/tool/?id=cf4696c7f7475dbf', description = 'Standardized, group-administered measure of reading comprehension; 5 min per group plus 2 min scoring per student', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Maze';
UPDATE measure SET grade_lo = '0', grade_hi = '3', url = 'https://charts.intensiveintervention.org/screening/tool/?id=d56595d546f69956', description = 'Standardized, individually administered measure of the alphabetic principle; 2 min per student plus 1 min scoring', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Nonsense Word Fluency Correct Letter Sounds';
UPDATE measure SET grade_lo = '1', grade_hi = '8', url = 'https://charts.intensiveintervention.org/screening/tool/?id=cb824cd669f47cd5', description = 'Standardized, individually administered measure of accuracy and fluency with connected text; 2 min per student plus 1 min scoring', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Oral Reading Fluency';
UPDATE measure SET grade_lo = '0', grade_hi = '1', url = 'https://charts.intensiveintervention.org/screening/tool/?id=cff45492945927c9', description = 'Standardized, individually administered measure of phonological awareness; 2 min per student plus 1 min scoring', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Phonemic Segmentation Fluency';
UPDATE measure SET grade_lo = '0', grade_hi = '3', url = 'https://charts.intensiveintervention.org/screening/tool/?id=5f5d937d5493fc85', description = 'Standardized, individually administered measure of accuracy and fluency reading regular and irregular sight words in one minute; 2 min per student plus 1 min scoring', source = 'NCII screening chart and detail page (vendor submission)' WHERE tool_id = 'dibels' AND measure = 'Word Reading Fluency';
UPDATE measure SET url = 'https://charts.intensiveintervention.org/progressmonitoring/tool/?id=d833969b4dd49868', description = 'Computer-adaptive reading comprehension measure; Renaissance recommends it for screening and for monitoring at intervals of at least a few weeks' WHERE tool_id = 'star-r' AND measure = 'Reading';

-- 3. the ncii_* tables keep NCII's findings only
CREATE TABLE ncii_screening_new (
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

INSERT INTO ncii_screening_new
  SELECT tool_id, measure, grade, ca_fall, ca_winter, ca_spring, ca_fall_d, ca_winter_d, ca_spring_d, reliability, validity, sample_rep, bias_analysis, as_of
  FROM ncii_screening;
DROP TABLE ncii_screening;
ALTER TABLE ncii_screening_new RENAME TO ncii_screening;

CREATE TABLE ncii_pm_new (
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

INSERT INTO ncii_pm_new
  SELECT tool_id, measure, grade, measure_type, reliability, validity, bias_analysis, slope_reliability, slope_validity, alt_forms, rules_goals, rules_instruction, as_of
  FROM ncii_pm;
DROP TABLE ncii_pm;
ALTER TABLE ncii_pm_new RENAME TO ncii_pm;

CREATE TABLE ncii_intervention_new (
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

INSERT INTO ncii_intervention_new(tool_id, study, study_type, design, es_targeted, es_broader, disagg_es, visual_analysis,
                                  participants, fidelity, targeted_measures, broader_measures, n_outcome_measures, url, as_of)
  SELECT tool_id, study, study_type, design, es_targeted, es_broader, disagg_es, visual_analysis,
         participants, fidelity, targeted_measures, broader_measures, n_outcome_measures, url, as_of
  FROM ncii_intervention;
DROP TABLE ncii_intervention;
ALTER TABLE ncii_intervention_new RENAME TO ncii_intervention;
UPDATE ncii_intervention SET sample = '109 grade 3 students (60 male, 49 female) in 6 suburban Midwestern schools, at or below the 40th percentile on fall ORF (DIBELS or AIMSweb) and end-of-grade-2 MAP comprehension; 10% special education, 23% ELL, 60% free/reduced lunch', grades = '3', assignment = 'Randomized within classrooms: 55 intervention, 54 no-treatment control', group_size = '3-6 (mean 5)', weeks = '8', per_week = '5', minutes = '30 planned; sessions averaged about 20', deliverer = 'Four teachers after a six-hour training plus self-study; fidelity observed every two weeks', notes = 'Unpublished RCT (University of Minnesota). CBM-R slope 1.53 vs 1.10 wcpm/week, F(1,99)=4.58, p<.05, g=.18; ES on broader measures -0.07.', url = 'https://charts.intensiveintervention.org/intervention/toolGRP/b7b83d9394626b24' WHERE tool_id = 'read-nat' AND study = 'Christ & Davie (2009)';
UPDATE ncii_intervention SET sample = '78 grade 3-5 Minneapolis students nominated by school teams or parents as not on course in reading (96 nominated, 18 dropped for missing data), with 78 matched controls from other schools; 11.5% LD, 36% ELL, 64% free/reduced lunch', grades = '3-5', assignment = 'Matched comparison, not randomized: controls matched on NALT pretest and 7 demographic variables (93% perfect matches)', group_size = '5-10 (mean 5)', weeks = '30', per_week = '4', minutes = '30', deliverer = 'One lead teacher per school after a six-hour training; three monitoring visits', notes = 'Unpublished district evaluation. Vendor did not supply the data NCII needed for effect sizes; fidelity data were not collected.', url = 'https://charts.intensiveintervention.org/intervention/toolGRP/38dc64f254665934' WHERE tool_id = 'read-nat' AND study = 'Heistad (2005)';
UPDATE ncii_intervention SET sample = 'Grade 4 students scoring 70 or below on the DIBELS ORF probe at one urban northeastern elementary school; no special education or prior supplemental reading; n not stated (percentages suggest 10 per group)', grades = '4', assignment = 'Systematic, convenience sample', group_size = 'Individual', weeks = '10', per_week = '4', minutes = '30', deliverer = 'The investigator, the school SLP completing her Ed.D., after a 2009 Read Naturally seminar; no fidelity measure', notes = 'National Forum of Educational Administration and Supervision Journal 28(1). Independent-samples t-test; average targeted ES 0.71, not marked significant.', url = 'https://charts.intensiveintervention.org/intervention/toolGRP/cdc7828939b49485' WHERE tool_id = 'read-nat' AND study = 'Tucker & Jones (2010)';

-- the chart's WWC / E-ESSA column, as findings in the reviewers' own words
INSERT INTO tool_evidence(tool_id, source, finding, domain, grades, url, notes, as_of) VALUES
('read-nat','wwc','Potentially positive effects on general literacy achievement (Adolescent Literacy)','adolescent literacy',NULL,'https://ies.ed.gov/ncee/wwc/Intervention/477','1 of 4 studies met WWC standards; quoted on the NCII study pages','2026-10'),
('read-nat','wwc','No discernible effects on fluency and reading comprehension (Beginning Reading)','beginning reading',NULL,'https://ies.ed.gov/ncee/wwc/Intervention/477','5 of 11 studies met WWC standards; quoted on the NCII study pages','2026-10'),
('read-nat','wwc','No discernible effects on reading achievement and English language development (English Language Learners)','ELL reading','elementary','https://ies.ed.gov/ncee/wwc/Intervention/477','2 of 3 studies met WWC standards; quoted on the NCII study pages','2026-10'),
('read-nat','wwc','No discernible effects on reading fluency; potentially positive effects on writing (Students with Learning Disabilities)','LD reading, writing',NULL,'https://ies.ed.gov/ncee/wwc/Intervention/477','2 of 3 studies met WWC standards; quoted on the NCII study pages','2026-10'),
('read-nat','essa','No studies met inclusion requirements','reading',NULL,'https://www.evidenceforessa.org/','Evidence for ESSA, as quoted on the NCII study pages','2026-10');
UPDATE tool_evidence SET notes = 'Christ & Davie 2009, Heistad 2005, Tucker & Jones 2010; see the NCII intervention rows on this page. NCII counts 6 other studies potentially eligible for review (Arvans 2010; Chenault et al. 2006; Denton et al. 2004; Hancock 2002; Kemp 2006; Mesa 2004).' WHERE tool_id = 'read-nat' AND source = 'ncii' AND finding = '3 studies reviewed';

-- 4. tool keeps identity only
ALTER TABLE tool DROP COLUMN minutes;
ALTER TABLE tool DROP COLUMN design_group;
ALTER TABLE tool DROP COLUMN max_group;
ALTER TABLE tool DROP COLUMN min_per_week;
ALTER TABLE tool DROP COLUMN min_weeks;
ALTER TABLE tool DROP COLUMN interventionist;
ALTER TABLE tool DROP COLUMN training;
ALTER TABLE tool DROP COLUMN grade_lo;
ALTER TABLE tool DROP COLUMN grade_hi;
ALTER TABLE tool DROP COLUMN design_source;

-- 5. dimension: the intervention checklist (needs wider subject / chart checks, so rebuild)
CREATE TABLE dimension_new (
  id          TEXT PRIMARY KEY,           -- 'r-decoding', 's-pp-phonics', 'i-r-fluency'
  subject     TEXT NOT NULL CHECK (subject IN ('reading','writing','math','language','behavior')),
  name        TEXT NOT NULL,              -- as NCII prints it
  sort        INTEGER NOT NULL,           -- NCII's order within the list
  chart       TEXT NOT NULL DEFAULT 'pm' CHECK (chart IN ('pm','screening','intervention')),
  grp         TEXT                        -- group heading ('Word ID', 'Early Literacy'); NULL for the pm list
);

INSERT INTO dimension_new SELECT id, subject, name, sort, chart, grp FROM dimension;
DROP TABLE dimension;
ALTER TABLE dimension_new RENAME TO dimension;
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

-- 6. tool_dimension: Star Reading's rows name its measure; a trigger keeps measure names honest
UPDATE tool_dimension SET measure = 'Reading' WHERE tool_id = 'star-r' AND measure = '-';
-- a tool_dimension row that names a measure must name one the vendor described
CREATE TRIGGER tool_dimension_measure BEFORE INSERT ON tool_dimension
BEGIN
  SELECT RAISE(ABORT, 'tool_dimension.measure must be ''-'' or a measure row for this tool')
  WHERE NEW.measure <> '-'
    AND NOT EXISTS (SELECT 1 FROM measure m WHERE m.tool_id = NEW.tool_id AND m.measure = NEW.measure);
END;

INSERT INTO tool_dimension(tool_id, measure, dimension_id, source, as_of) VALUES
('read-nat','-','i-r-phonics','NCII intervention tool page (vendor submission)','2026-10'),
('read-nat','-','i-r-comp','NCII intervention tool page (vendor submission)','2026-10'),
('read-nat','-','i-r-fluency','NCII intervention tool page (vendor submission)','2026-10'),
('read-nat','-','i-r-vocab','NCII intervention tool page (vendor submission)','2026-10');

COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
