-- v0.7: ncii_screening.sample_rep becomes chart text (NCII prints 'National without Cross-Validation',
-- not a bubble); area.building dropped; tool 'dibels' is DIBELS 8th Edition (the district does not use
-- Acadience); DIBELS 8 screening rows from the NCII chart, copied 2026-10-30, no "d" markers on any row.
-- Apply to the LIVE database (css.db is the source of truth; seed.sql is not updated with content):
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-dibels8-building.sql
PRAGMA foreign_keys = ON;
BEGIN;
DROP TABLE ncii_screening;   -- empty at this point
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
ALTER TABLE area DROP COLUMN building;
UPDATE tool SET name = 'DIBELS 8th Edition', vendor = 'University of Oregon',
       notes = 'wcpm + accuracy; K-8 on the NCII screening chart (Composite, LNF, PSF, NWF, WRF, ORF, Maze)'
 WHERE id = 'dibels';
INSERT INTO ncii_screening (tool_id,measure,grade,ca_fall,ca_winter,ca_spring,reliability,validity,sample_rep,bias_analysis,admin_format,admin_time,scoring_format,decision_rules,multi_rules_evidence,as_of) VALUES
('dibels','Composite',0,'partial','partial','convincing','convincing','convincing','National without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',1,'partial','partial','convincing','convincing','convincing','Regional without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',2,'convincing','convincing','convincing','convincing','convincing','National without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',3,'partial','partial','partial','convincing','convincing','National without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',4,'partial','convincing','partial','convincing','convincing','National without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',5,'partial','convincing','partial','convincing','convincing','Regional without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',6,'partial','unconvincing','unconvincing','convincing','unconvincing','Regional without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',7,'convincing','partial','partial','convincing','partial','Regional without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Composite',8,'partial','partial','partial','convincing','partial','Regional without Cross-Validation','Provided','Other','5 minutes','Manual and/or Automatic','Benchmark Goals','Yes','2026-10'),
('dibels','Letter Naming Fluency',0,'partial','partial','partial','convincing','convincing','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Letter Naming Fluency',1,'unconvincing','unconvincing','unconvincing','convincing','partial','Regional without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',2,'partial','convincing','convincing','partial','partial','National without Cross-Validation','Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',3,'partial','partial','convincing','partial','unconvincing','National without Cross-Validation','Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',4,'partial','convincing','partial','partial','convincing','National without Cross-Validation','Not Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',5,'partial','partial','partial','convincing','partial','Regional without Cross-Validation','Not Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',6,'convincing','convincing','partial','convincing','partial','Regional without Cross-Validation','Not Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',7,'partial','partial','convincing','convincing','convincing','Regional without Cross-Validation','Not Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Maze',8,'partial','unconvincing','unavailable','partial','unconvincing','Regional without Cross-Validation','Not Provided','Individual; Group','7 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds',0,'partial','partial','partial','convincing','partial','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds',1,'partial','partial','partial','convincing','partial','Regional without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds',2,'partial','partial','partial','convincing','unconvincing','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds',3,'unconvincing','unconvincing','partial','convincing','partial','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',1,'partial','unavailable','partial','convincing','convincing','Regional without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',2,'partial','unavailable','convincing','convincing','convincing','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',3,'partial','unavailable','partial','convincing','convincing','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',4,'partial','unavailable','partial','convincing','convincing','National without Cross-Validation','Not Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',5,'partial','unavailable','partial','convincing','partial','Regional without Cross-Validation','Not Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',6,'partial','unavailable','partial','convincing','unconvincing','National without Cross-Validation','Not Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',7,'convincing','unavailable','partial','convincing','unconvincing','National without Cross-Validation','Not Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Oral Reading Fluency',8,'partial','unavailable','partial','convincing','unconvincing','Regional without Cross-Validation','Not Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Phonemic Segmentation Fluency',0,'partial','partial','partial','partial','unconvincing','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Phonemic Segmentation Fluency',1,'unconvincing','unconvincing','unconvincing','convincing','unconvincing','Regional without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Word Reading Fluency',0,'unavailable','partial','partial','convincing','partial','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Word Reading Fluency',1,'partial','partial','partial','convincing','convincing','Regional without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Word Reading Fluency',2,'convincing','convincing','convincing','convincing','partial','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10'),
('dibels','Word Reading Fluency',3,'partial','partial','partial','convincing','partial','National without Cross-Validation','Provided','Individual','3 minutes','Manual','Benchmark Goals','Yes','2026-10');
COMMIT;
