-- Read Naturally studies from NCII's academic intervention chart, copied 2026-10-30, to tool read-nat.
-- Effect sizes as printed: † could not be computed, -- no broader measures submitted.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-read-naturally-intervention.sql
PRAGMA foreign_keys = ON;
BEGIN;
INSERT INTO ncii_intervention (tool_id,study,study_type,design,es_targeted,es_broader,disagg_es,visual_analysis,
  participants,fidelity,targeted_measures,broader_measures,n_outcome_measures,admin_group_size,duration,
  interventionist,training,wwc_essa,other_research,as_of) VALUES
('read-nat','Christ & Davie (2009)','Group Design','partial','†','-0.07','None','na',
  'unconvincing','convincing','convincing','convincing','9 Reading','Individual students; Small group of students','30 minutes, 3 times a week',
  'Teacher; Specialist; Support Staff/Other','1 day of training','WWC & E-ESSA','6','2026-10'),
('read-nat','Heistad (2005)','Group Design','partial','†','--','None','na',
  'unconvincing','unconvincing','convincing','unavailable','3 Reading','Individual students; Small group of students','30 minutes, 3 times a week',
  'Teacher; Specialist; Support Staff/Other','1 day of training','WWC & E-ESSA','6','2026-10'),
('read-nat','Tucker & Jones (2010)','Group Design','unconvincing','0.71','--','None','na',
  'convincing','unconvincing','convincing','unavailable','3 Reading','Individual students; Small group of students','30 minutes, 3 times a week',
  'Teacher; Specialist; Support Staff/Other','1 day of training','WWC & E-ESSA','6','2026-10');
COMMIT;
