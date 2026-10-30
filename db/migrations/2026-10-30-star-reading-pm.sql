-- Star Reading rows from NCII's academic progress monitoring chart, copied 2026-10-30, to tool star-r.
-- Grades 1-8, measure type Short Term Skill. No "d" markers.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-star-reading-pm.sql
PRAGMA foreign_keys = ON;
BEGIN;
INSERT INTO ncii_pm (tool_id,measure,grade,measure_type,reliability,validity,bias_analysis,slope_reliability,slope_validity,
  alt_forms,rules_goals,rules_instruction,admin_format,admin_time,scoring_format,roi_eoy,as_of) VALUES
('star-r','Reading',1,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',2,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',3,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',4,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',5,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',6,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',7,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10'),
('star-r','Reading',8,'Short Term Skill','convincing','convincing','Provided','convincing','unavailable','convincing','partial','unavailable','Individual; Group; Computer-administered','18 minutes','Automatic','ROI & EOY Benchmarks Available','2026-10');
COMMIT;
