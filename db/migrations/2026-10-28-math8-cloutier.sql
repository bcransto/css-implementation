-- math-8 observed rows from Brad's interview with Rachel Cloutier, 2026-10-28.
-- Apply to the LIVE database (css.db is the source of truth; seed.sql is not updated):
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-28-math8-cloutier.sql
-- Not yet asked: mid-year re-check, what she does with the equation-lost kid, what goes to CCHS in June, what she would want.
PRAGMA foreign_keys = ON;
BEGIN;
INSERT INTO area VALUES ('math-8','math',8,8,'CMS',1);
INSERT INTO area_core VALUES ('math-8','cpm',NULL,'unwritten');
INSERT INTO tool(id,name,vendor,minutes,notes) VALUES
('cloutier-pretest','Grade 8 math pre-test (teacher-made)','Rachel Cloutier',NULL,'September; teacher judgment, no cut'),
('cloutier-materials','Grade 8 FLEX materials (teacher-made)','Rachel Cloutier',45,'created by the teacher for the FLEX group');
INSERT INTO tool_license VALUES ('cloutier-pretest',8,8,'in-house'),('cloutier-materials',8,8,'in-house');
INSERT INTO area_screener VALUES
('math-8','mcas-m',8,8,'prior spring','screen','Partially Meeting or below','unwritten'),
('math-8','aleks',8,8,'Sep','screen','teacher judgment; no threshold','unwritten'),
('math-8','cloutier-pretest',8,8,'Sep','screen','teacher judgment','unwritten');
INSERT INTO profile(id,area_id,teacher,basis,name,sort_rule) VALUES
('m8-rc-frac','math-8','Cloutier','observed','fractions','ALEKS knowledge check, read by the teacher'),
('m8-rc-other','math-8','Cloutier','observed','(no other profile named)','flagged but not sorted');
INSERT INTO protocol(id,area_id,tier,profile_id,teacher,basis,as_of,evidence,deliverer_role,placement_tool_id,program_id,pm_tool_id,pm_metric,entry_rule,dosage,group_size,weeks,pm_rule,review_rule,exit_rule,next_step_id,nonresponse_id,status,status_note) VALUES
('m8-rc-t1','math-8',1,'-','Cloutier','observed','2026-10','interview','classroom teacher',NULL,'cpm',NULL,NULL,'September only: MCAS Partially Meeting or below, or teacher judgment from ALEKS and own pre-test. Mid-year re-check unknown.','daily','class','year','none','none',NULL,'to-t2',NULL,'unwritten','flag is real and used; nothing written'),
('m8-rc-t2-frac','math-8',2,'m8-rc-frac','Cloutier','observed','2026-10','interview','classroom teacher (only deliverer)','aleks','cloutier-materials',NULL,NULL,'flagged in September; fractions per ALEKS','3 x 45 FLEX','4-5','6 minimum, sometimes 12','none; teacher gut','none','none; no benchmark exists, teacher instinct','to-t1','cst','unwritten','program is teacher-made; no measure; no exit rule'),
('m8-rc-t2-other','math-8',2,'m8-rc-other','Cloutier','observed','2026-10','interview','classroom teacher (only deliverer)','aleks','cloutier-materials',NULL,NULL,'flagged in September; no profile identified','3 x 45 FLEX','4-5','6 minimum, sometimes 12','none; teacher gut','none','none; teacher instinct','to-t1','cst','unwritten','same group as fractions; nothing handed to CCHS in June');
COMMIT;
