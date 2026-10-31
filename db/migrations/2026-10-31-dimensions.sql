-- v0.9: NCII academic dimensions and which ones each tool assesses. Loads the 17 NCII dimensions and
-- Star Reading's four (from its NCII PM detail page, read 2026-10-31). NCII's own page misspells
-- "Writting Expression"; corrected here.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-31-dimensions.sql
PRAGMA foreign_keys = ON;
BEGIN;
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
INSERT INTO tool_dimension VALUES
('star-r','r-global','NCII PM detail page','2026-10'),
('star-r','r-vocab','NCII PM detail page','2026-10'),
('star-r','r-passage','NCII PM detail page','2026-10'),
('star-r','r-comp','NCII PM detail page','2026-10');
-- NCII reviews already loaded as chart rows, recorded as evidence so the tool page does not say "no reviewer checked"
INSERT INTO tool_evidence (tool_id, source, finding, domain, grades, url, notes, as_of) VALUES
('star-r','ncii','reviewed: academic screening chart','reading','1-11','https://charts.intensiveintervention.org/ascreening','see the screening rows on this page','2026-10'),
('star-r','ncii','reviewed: academic progress monitoring chart','reading','1-8','https://charts.intensiveintervention.org/progressmonitoring/tool/?id=d833969b4dd49868','see the PM rows on this page','2026-10'),
('star-m','ncii','reviewed: academic screening chart','math','K-11','https://charts.intensiveintervention.org/ascreening','see the screening rows on this page; PM chart rows not yet entered','2026-10'),
('dibels','ncii','reviewed: academic screening chart','reading','K-8','https://charts.intensiveintervention.org/ascreening','see the screening rows on this page','2026-10');
COMMIT;
