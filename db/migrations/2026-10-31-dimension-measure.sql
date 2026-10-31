-- v0.10: per-measure dimensions. DIBELS 8 has one NCII screening page per measure, each with its own
-- "What skills does the tool screen?" checklist, and that checklist is a different, finer list than the
-- progress monitoring page's 17 dimensions. So: dimension gets chart ('pm' | 'screening') and grp (the
-- screening page's group heading) and the screening list is loaded; tool_dimension gets measure ('-' =
-- whole tool). Loads DIBELS 8's seven measures (pages read 2026-10-31) and sets each measure's NCII
-- detail URL on its ncii_screening rows. Star Reading's four rows keep measure '-'.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-31-dimension-measure.sql
PRAGMA foreign_keys = ON;
BEGIN;
ALTER TABLE dimension ADD COLUMN chart TEXT NOT NULL DEFAULT 'pm' CHECK (chart IN ('pm','screening'));
ALTER TABLE dimension ADD COLUMN grp TEXT;

CREATE TABLE tool_dimension_new (
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  measure     TEXT NOT NULL DEFAULT '-',
  dimension_id TEXT NOT NULL REFERENCES dimension(id),
  source      TEXT,
  as_of       TEXT,
  PRIMARY KEY (tool_id, measure, dimension_id)
);
INSERT INTO tool_dimension_new(tool_id, measure, dimension_id, source, as_of)
  SELECT tool_id, '-', dimension_id, source, as_of FROM tool_dimension;
DROP TABLE tool_dimension;
ALTER TABLE tool_dimension_new RENAME TO tool_dimension;

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

INSERT INTO tool_dimension(tool_id, measure, dimension_id, source, as_of) VALUES
('dibels','Composite','s-pp-awareness','NCII screening detail page','2026-10'),
('dibels','Composite','s-pp-lsc','NCII screening detail page','2026-10'),
('dibels','Composite','s-pp-phonics','NCII screening detail page','2026-10'),
('dibels','Composite','s-wid-acc','NCII screening detail page','2026-10'),
('dibels','Composite','s-wid-speed','NCII screening detail page','2026-10'),
('dibels','Composite','s-nw-acc','NCII screening detail page','2026-10'),
('dibels','Composite','s-nw-speed','NCII screening detail page','2026-10'),
('dibels','Composite','s-pass-acc','NCII screening detail page','2026-10'),
('dibels','Composite','s-pass-speed','NCII screening detail page','2026-10'),
('dibels','Composite','s-rc-maze','NCII screening detail page','2026-10'),
('dibels','Maze','s-rc-maze','NCII screening detail page','2026-10'),
('dibels','Letter Naming Fluency','s-pp-ran','NCII screening detail page','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds','s-pp-lsc','NCII screening detail page','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds','s-pp-phonics','NCII screening detail page','2026-10'),
('dibels','Nonsense Word Fluency Correct Letter Sounds','s-nw-acc','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-pp-lsc','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-pp-phonics','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-wid-acc','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-wid-speed','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-nw-speed','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-pass-acc','NCII screening detail page','2026-10'),
('dibels','Oral Reading Fluency','s-pass-speed','NCII screening detail page','2026-10'),
('dibels','Phonemic Segmentation Fluency','s-pp-awareness','NCII screening detail page','2026-10'),
('dibels','Word Reading Fluency','s-pp-lsc','NCII screening detail page','2026-10'),
('dibels','Word Reading Fluency','s-pp-phonics','NCII screening detail page','2026-10'),
('dibels','Word Reading Fluency','s-wid-acc','NCII screening detail page','2026-10'),
('dibels','Word Reading Fluency','s-wid-speed','NCII screening detail page','2026-10'),
('dibels','Word Reading Fluency','s-nw-speed','NCII screening detail page','2026-10');

UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=4928894588828f86' WHERE tool_id = 'dibels' AND measure = 'Composite';
UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=cf4696c7f7475dbf' WHERE tool_id = 'dibels' AND measure = 'Maze';
UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=d8bd5d99d4298b6f' WHERE tool_id = 'dibels' AND measure = 'Letter Naming Fluency';
UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=d56595d546f69956' WHERE tool_id = 'dibels' AND measure = 'Nonsense Word Fluency Correct Letter Sounds';
UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=cb824cd669f47cd5' WHERE tool_id = 'dibels' AND measure = 'Oral Reading Fluency';
UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=cff45492945927c9' WHERE tool_id = 'dibels' AND measure = 'Phonemic Segmentation Fluency';
UPDATE ncii_screening SET url = 'https://charts.intensiveintervention.org/screening/tool/?id=5f5d937d5493fc85' WHERE tool_id = 'dibels' AND measure = 'Word Reading Fluency';
COMMIT;
