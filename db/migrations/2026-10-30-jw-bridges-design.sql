-- Publisher design minimums for Just Words (Wilson) and Bridges Intervention (MLC), from the publishers'
-- own pages, read 2026-10-30. Bridges states only session length and grades; the rest stays NULL.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-jw-bridges-design.sql
PRAGMA foreign_keys = ON;
BEGIN;
UPDATE tool SET
  minutes = 45, min_per_week = 5, min_weeks = 30,
  design_group = 'Reading class (up to 15 students) or small group', max_group = 15,
  interventionist = 'General education teacher, reading specialist, or interventionist',
  training = 'Just Words Launch Workshop: one full day (four instructional hours), no prerequisite; Wilson certification not required',
  grade_lo = 4, grade_hi = 12,
  design_source = 'Wilson, Implementing Just Words (wilsonlanguage.com/knowledge-library/programs/just-words/implementing-just-words/). Designed as 5 days/week, 45 min, 14 units + 2 review weeks = 30 weeks. Wilson also describes 30 min x 5 over two years, and 3 days/week taking 1.5 years (about 8 of 14 units in a year).'
 WHERE id = 'just-words';
UPDATE tool SET
  minutes = 30,
  design_group = 'small groups; each set has manipulatives for up to six students per volume (a materials count, not a stated maximum)',
  grade_lo = 0, grade_hi = 5,
  design_source = 'MLC, Bridges Intervention overview and components pages (mathlearningcenter.org/curriculum/bridges-intervention). Sessions per week, duration, deliverer and training are not stated.',
  notes = 'K-5 kit organized by content (Vol 1-9); scripted; 8-13 modules x 5 sessions per volume (40-65 sessions); every fifth session is a progress check; no outcome studies'
 WHERE id = 'bridges-i';
INSERT INTO tool_evidence (tool_id, source, finding, grades, url, notes, as_of) VALUES
('just-words','publisher','implementation guidance only; no outcome studies cited','4-12','https://www.wilsonlanguage.com/programs/just-words/','Program overview, implementation article and workshop page read 2026-10-30','2026-10'),
('bridges-i','publisher','implementation guidance only; no outcome studies cited','K-5','https://www.mathlearningcenter.org/curriculum/bridges-intervention','Overview, components and volumes pages read 2026-10-30','2026-10'),
('just-words','ncii','not listed',NULL,'https://charts.intensiveintervention.org/aintervention','Academic intervention chart title list scanned 2026-10-30; no Just Words or Wilson title','2026-10'),
('bridges-i','ncii','not listed',NULL,'https://charts.intensiveintervention.org/aintervention','Academic intervention chart title list scanned 2026-10-30; no Bridges title','2026-10');
COMMIT;
