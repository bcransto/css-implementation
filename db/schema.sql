-- MTSS tier-definition schema, v0.3
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
