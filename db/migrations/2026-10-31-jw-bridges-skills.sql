-- Just Words and Bridges Intervention: the publishers' skill claims on NCII's intervention checklist
-- (tool_dimension, source 'publisher'), plus the vendor-profile fields the publisher pages state.
-- Read 2026-10-31: wilsonlanguage.com (program page, Implementing Just Words, Evidence of Effectiveness);
-- mathlearningcenter.org (Bridges Intervention overview, volumes, components, upgrades).
-- Ticked only what the publisher names as something the program teaches. Not ticked: Just Words
-- comprehension (Wilson says to pair it with a core program for that) and vocabulary (not stated);
-- Bridges algebra (equations with an unknown appear inside two volumes, no algebra strand),
-- "comprehensive" (never claimed), geometry and measurement (measurement only inside word problems).
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-31-jw-bridges-skills.sql
PRAGMA foreign_keys = ON;
BEGIN;

INSERT INTO tool_dimension(tool_id, measure, dimension_id, source, as_of) VALUES
('just-words','-','i-r-pa','publisher (Wilson: "emphasizes phonemic awareness, phonics, word study, and spelling")','2026-10'),
('just-words','-','i-r-phonics','publisher (Wilson: word structure by the six syllable types, sound-symbol, spelling rules, morphology)','2026-10'),
('just-words','-','i-r-fluency','publisher (Wilson: word- and phrase-level automaticity, "fluent reading for meaning rather than speed")','2026-10'),
('just-words','-','i-r-spelling','publisher (Wilson: decoding and spelling automaticity; dictation in every unit test)','2026-10'),
('bridges-i','-','i-m-computation','publisher (MLC: fluency volumes 2, 3, 5, 6)','2026-10'),
('bridges-i','-','i-m-concepts','publisher (MLC: problem-situation volumes 4, 7, 9)','2026-10'),
('bridges-i','-','i-m-whole','publisher (MLC: volumes 1-7, counting and place value through multidigit multiplication and division)','2026-10'),
('bridges-i','-','i-m-fractions','publisher (MLC: volume 8 fractions, volume 9 money and decimals)','2026-10');

UPDATE tool_profile SET
  intended_for = 'Tier 2: grades 4-12 and adults with mild to moderate decoding and spelling gaps who "do not require intensive intervention"; English learners included; not for students with a significant language learning disability such as dyslexia (Wilson Reading System instead). Screen students below the 50th percentile; place the 16th-50th percentile on WIST / TOSWRF-2',
  technology = 'A magnetic board or interactive whiteboard with internet connection',
  support = 'Program workshops, facilitator and presenter certification, virtual implementation support, demonstration sites with on-site coaching, Wilson Academy / Just Words Learning Community',
  manual = 'Yes (comprehensive materials; structured lesson plan)',
  obtain = 'Wilson Language Training; store.wilsonlanguage.com',
  description = 'An accelerated, explicit, multimodal Tier 2 word-study program: phonemic awareness, phonics, word structure, spelling and word-level fluency. Wilson says to pair it with a core reading program for comprehension strategy instruction. Standard model 45 min x 5 days for one year (14 units plus two review weeks); alternatives 30 min x 5 over two years, or 45 min x 3 days (about 8 units a year).'
WHERE tool_id = 'just-words';

UPDATE tool_profile SET
  intended_for = 'Not stated by tier or population: "some students just need more time, more opportunities or more support"; small groups, "consistent with RTI and MTSS frameworks"; works with any elementary curriculum; Spanish student materials included',
  technology = 'Not stated as required. Sets include MLC Educator Site access with all guides and student pages as PDFs; free virtual manipulatives',
  support = 'MLC regional support team; preview account on request',
  manual = 'Yes (Teachers Guides, one full plan per 30-minute session; not described as scripted)',
  obtain = 'The Math Learning Center; store.mathlearningcenter.org (Set 1 = volumes 1-4, Set 2 = volumes 5-9)',
  description = 'Nine volumes of K-5 content organized by skill rather than grade: counting and early place value; basic and multidigit addition and subtraction; addition and subtraction problem situations; basic and multidigit multiplication and division; multiplication and division problem situations; fractions; money and decimals. 8-13 modules per volume, 5 sessions per module (40-65 sessions a volume); every fifth session is a progress-monitoring assessment.'
WHERE tool_id = 'bridges-i';

-- Wilson now publishes a vendor study; the earlier "guidance only" finding is superseded
UPDATE tool_evidence SET
  finding = 'Vendor study, 2023-24: 360+ students, grades 4-12, 8 schools in 4 districts; significant gains with medium to large effect sizes in word identification and spelling (WIST, TOSWRF-2) vs business as usual; Wilson rates it ESSA Level 3',
  domain = 'word identification, spelling',
  url = 'https://www.wilsonlanguage.com/resources/research-evidence/just-words-evidence-of-effectiveness/',
  notes = 'Publisher-reported; authors and the comparison design are not named on the page. Earlier unnamed studies claim word-reading and comprehension gains. Full document: Just Words Evidence of Effectiveness 2026 (PDF, not read).',
  as_of = '2026-10'
WHERE tool_id = 'just-words' AND source = 'publisher';

UPDATE tool_evidence SET
  finding = 'No outcome studies or evidence claims on the publisher pages; implementation guidance only',
  notes = 'Overview, volumes, components and upgrades pages read 2026-10-31; no research page linked',
  as_of = '2026-10'
WHERE tool_id = 'bridges-i' AND source = 'publisher';

COMMIT;
