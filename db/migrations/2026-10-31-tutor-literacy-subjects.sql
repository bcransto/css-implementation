-- v0.14: instructor roles 'coach' -> 'tutor' and 'reading specialist' -> 'literacy specialist'; instructor.subject
-- becomes the instructor_subject table because a tutor can cover both math and reading. The CHECK constraint
-- changes, so instructor is rebuilt (no trigger names it). Also renames "reading specialist" in the prose of
-- protocol.deliverer_role, which is Carlisle's own rule text; vendor text is not touched. No row holds either
-- old role value today, so the role copy is a straight CASE.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-10-31-tutor-literacy-subjects.sql
PRAGMA foreign_keys = OFF;
BEGIN;

CREATE TABLE instructor_new (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  full_name   TEXT,
  role        TEXT CHECK (role IN ('classroom teacher','interventionist','literacy specialist','special educator','para','slp','tutor','admin')),
  grade_lo    INTEGER,
  grade_hi    INTEGER,
  flex_duty   INTEGER,
  interviewed_on TEXT,
  notes       TEXT
);
INSERT INTO instructor_new (id, name, full_name, role, grade_lo, grade_hi, flex_duty, interviewed_on, notes)
SELECT id, name, full_name,
       CASE role WHEN 'coach' THEN 'tutor' WHEN 'reading specialist' THEN 'literacy specialist' ELSE role END,
       grade_lo, grade_hi, flex_duty, interviewed_on, notes
FROM instructor;

-- the subjects a person covers; a tutor can have two. No row = not recorded.
CREATE TABLE instructor_subject (
  instructor_id TEXT NOT NULL REFERENCES instructor(id),
  subject     TEXT NOT NULL CHECK (subject IN ('math','reading','behavior')),
  PRIMARY KEY (instructor_id, subject)
);
INSERT INTO instructor_subject (instructor_id, subject) SELECT id, subject FROM instructor WHERE subject IS NOT NULL;

DROP TABLE instructor;
ALTER TABLE instructor_new RENAME TO instructor;

UPDATE protocol SET deliverer_role = replace(deliverer_role, 'reading specialist', 'literacy specialist')
WHERE deliverer_role LIKE '%reading specialist%';

COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
