-- v0.12: instructor. The teacher names on profile and protocol become foreign keys to a table of people: who
-- they are (role, subject, grades, FLEX duty), when they were interviewed, and which programs they are trained
-- in (instructor_tool). Ids are slugs, normally the last name ('spiegl'); '-' stays the sentinel for the
-- area's own rule. protocol gains deliverer_id for rows where the deliverer is a named person; the three
-- observed Tier 2 rows whose deliverer_role already says "herself" / "only deliverer" get it set.
-- Rebuilds profile and protocol, so foreign keys are off for the transaction and checked at the end.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-31-instructor.sql
PRAGMA foreign_keys = OFF;
BEGIN;

CREATE TABLE instructor (
  id          TEXT PRIMARY KEY,           -- slug, normally the last name: 'spiegl'; a second Smith gets 'smith-j'
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
INSERT INTO instructor VALUES ('-', '-', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO instructor(id, name, role, subject, grade_lo, grade_hi, interviewed_on) VALUES
('putnam',   'Putnam',   'classroom teacher', 'math',    5, 5, '2026-10'),
('spiegl',   'Spiegl',   'classroom teacher', 'math',    6, 6, '2026-10'),
('balian',   'Balian',   'classroom teacher', 'math',    7, 7, '2026-10'),
('cloutier', 'Cloutier', 'classroom teacher', 'math',    8, 8, '2026-10'),
('rice',     'Rice',     'classroom teacher', 'reading', 7, 7, '2026-10');

-- which programs or instruments a person is trained to deliver; no row = not trained, or not asked
CREATE TABLE instructor_tool (
  instructor_id TEXT NOT NULL REFERENCES instructor(id),
  tool_id     TEXT NOT NULL REFERENCES tool(id),
  trained_on  TEXT,                       -- YYYY or YYYY-MM; NULL = date unknown
  note        TEXT,                       -- 'Wilson Just Words launch workshop'
  PRIMARY KEY (instructor_id, tool_id)
);

-- profile.teacher -> instructor
CREATE TABLE profile_new (
  id          TEXT PRIMARY KEY,
  area_id     TEXT NOT NULL REFERENCES area(id),
  teacher     TEXT NOT NULL DEFAULT '-' REFERENCES instructor(id),  -- '-' = the area's profile
  basis       TEXT NOT NULL DEFAULT 'defined' CHECK (basis IN ('observed','defined')),
  name        TEXT NOT NULL,
  sort_rule   TEXT NOT NULL,
  UNIQUE (area_id, teacher, name)
);
INSERT INTO profile_new SELECT id, area_id, lower(teacher), basis, name, sort_rule FROM profile;
DROP TABLE profile;
ALTER TABLE profile_new RENAME TO profile;

-- protocol.teacher -> instructor; new deliverer_id
CREATE TABLE protocol_new (
  id          TEXT PRIMARY KEY,
  area_id     TEXT NOT NULL REFERENCES area(id),
  tier        INTEGER,
  profile_id  TEXT NOT NULL DEFAULT '-' REFERENCES profile(id),
  teacher     TEXT NOT NULL DEFAULT '-' REFERENCES instructor(id),  -- '-' = the area's rule
  basis       TEXT NOT NULL DEFAULT 'defined' CHECK (basis IN ('observed','defined')),
  as_of       TEXT,
  evidence    TEXT,
  deliverer_role TEXT,
  deliverer_id TEXT REFERENCES instructor(id),  -- the named person, when there is one (observed rows)
  placement_tool_id TEXT REFERENCES tool(id),
  program_id  TEXT REFERENCES tool(id),
  pm_tool_id  TEXT REFERENCES tool(id),
  pm_metric   TEXT,
  entry_rule  TEXT,
  dosage      TEXT,
  group_size  TEXT,
  weeks       TEXT,
  pm_rule     TEXT,
  review_rule TEXT,
  exit_rule   TEXT,
  next_step_id   TEXT REFERENCES route(id),
  nonresponse_id TEXT REFERENCES route(id),
  status      TEXT NOT NULL CHECK (status IN ('doc','unwritten','proposed','iep')),
  status_note TEXT,
  citations   TEXT,
  UNIQUE (area_id, tier, profile_id, teacher)
);
INSERT INTO protocol_new (id, area_id, tier, profile_id, teacher, basis, as_of, evidence, deliverer_role, deliverer_id,
  placement_tool_id, program_id, pm_tool_id, pm_metric, entry_rule, dosage, group_size, weeks, pm_rule, review_rule,
  exit_rule, next_step_id, nonresponse_id, status, status_note, citations)
SELECT id, area_id, tier, profile_id, lower(teacher), basis, as_of, evidence, deliverer_role,
  CASE WHEN deliverer_role LIKE '%herself%' OR deliverer_role LIKE '%only deliverer%' THEN lower(teacher) END,
  placement_tool_id, program_id, pm_tool_id, pm_metric, entry_rule, dosage, group_size, weeks, pm_rule, review_rule,
  exit_rule, next_step_id, nonresponse_id, status, status_note, citations
FROM protocol;
DROP TABLE protocol;
ALTER TABLE protocol_new RENAME TO protocol;

CREATE TRIGGER protocol_profile_scope BEFORE INSERT ON protocol
BEGIN
  SELECT RAISE(ABORT, 'protocol.teacher must match profile.teacher (or profile = ''-'')')
  WHERE NEW.profile_id <> '-'
    AND NEW.teacher <> (SELECT teacher FROM profile WHERE id = NEW.profile_id);
END;

COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
