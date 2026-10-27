-- Seed for schema.sql (v0.3). Four areas built so far; rows tagged 'proposed' are ours, 'doc' are in district documents.
-- Rows with teacher <> '-' are observed practice (basis='observed') from the teacher survey.
-- K = grade 0.
PRAGMA foreign_keys = ON;

INSERT INTO tool(id,name,vendor,minutes,notes,url) VALUES
('cpm','CPM Core Connections','CPM',NULL,'Listed as MS core in tiers deck; McGraw Hill knowledge checks also listed (likely ALEKS). Confirm.',NULL),
('into-math','HMH Into Math','HMH',NULL,'K-4 core',NULL),
('fundations','Fundations','Wilson',NULL,'phonics core through gr 3',NULL),
('mcas-m','MCAS Math','DESE',NULL,'annual, prior grade; criterion-referenced',NULL),
('mcas-e','MCAS ELA','DESE',NULL,'annual, prior grade; valid comprehension screen (Vaughn & Fletcher 2012 p.4)',NULL),
('star-m','STAR Math','Renaissance',20,'NCII screen + PM. SEM about +/-20-30 SS, so keep to windows; PM use only as level check.',NULL),
('star-r','STAR Reading','Renaissance',20,'general comprehension; keep to windows',NULL),
('dibels','DIBELS / Acadience ORF','Acadience',5,'wcpm + accuracy; K-4',NULL),
('aleks','ALEKS','McGraw Hill',60,'standards-aligned topic mastery; NOT CPM-aligned; no norms; placement/practice, not a screener',NULL),
('tmsfa','TMSFA one-minute read','TEA (free)',2,'equated gr 6-8 passages, wcpm + accuracy + retell; Vaughn & Fletcher 2012','https://jukebox.esc13.net/vgcdeveloper/TALA%20Reading/TMSFA%20Materials/'),
('cbm-68','Grade 6-8 math CBM','easyCBM or Acadience Math',8,'mixed-skills timed probe with skills profile; TO BE CHOSEN',NULL),
('fact-2m','2-minute fact probe','in-house (Fuchs-style)',2,'digits correct by operation',NULL),
('wist','WIST','Wilson',40,'norm-referenced word ID + spelling; packaged with Just Words',NULL),
('celf5-s','CELF-5 Screening Test','Pearson',15,'language screen; SLP; failing -> full CELF-5 under sped eval',NULL),
('just-words','Just Words','Wilson',45,'structured literacy decoding gr 4-12; 14 units',NULL),
('read-nat','Read Naturally','Read Naturally',30,'repeated reading fluency; placement built in',NULL),
('bridges-i','Bridges Intervention','MLC',30,'K-5 kit organized by content (Vol 1-9); scripted; no outcome studies; not on NCII chart',NULL),
('ffo','Fraction Face-Off','Fuchs / Vanderbilt',35,'NCII-listed, gr 4-6; not owned',NULL),
('sbi','Schema-based instruction gr 6-8','Jitendra',45,'RCTs gr 6-8; PG 2021 Rec 5 strong; not owned',NULL),
('fact-prog','Timed fact practice + strategy','Rocket Math or in-house',10,'PG 2021 Rec 6 moderate; not owned',NULL);

INSERT INTO tool_license VALUES
('cpm',5,8,NULL),('into-math',0,4,NULL),('fundations',0,3,NULL),
('mcas-m',3,8,NULL),('mcas-e',3,8,NULL),('star-m',1,5,'licensed 1-5; proposed 5-8'),('star-r',5,8,NULL),
('dibels',0,4,NULL),('aleks',5,8,NULL),('tmsfa',6,8,'free download'),('fact-2m',0,8,'in-house'),
('wist',4,8,NULL),('celf5-s',0,8,'SLP owns'),('just-words',4,8,NULL),('read-nat',2,8,NULL),('bridges-i',0,5,'confirm volumes');

INSERT INTO source VALUES
('pg2021','Fuchs, L.S. et al. (2021). Assisting Students Struggling with Mathematics: Intervention in the Elementary Grades. WWC 2021006.','https://ies.ed.gov/ncee/wwc/PracticeGuide/26'),
('pg2009r','Gersten, R. et al. (2009). Assisting Students Struggling with Reading: RTI and Multi-Tier Intervention in the Primary Grades. WWC.',NULL),
('smart','Fuchs, D., Fuchs, L.S., & Compton, D.L. (2012). Smart RTI. Exceptional Children 78(3), 263-279.',NULL),
('crit','Fuchs, D., & Fuchs, L.S. (2017). Critique of the National Evaluation of RTI. Exceptional Children 83(3), 255-268.',NULL),
('vf2012','Vaughn, S., & Fletcher, J.M. (2012). RTI with Secondary School Students with Reading Difficulties. JLD 45(3), 244-256.',NULL),
('espin','Espin, C.A. et al. (2010). Creating a progress measurement system in reading for middle-school students. LDRP 25, 60-75.',NULL),
('hock','Hock, M.F. et al. (2009). Reading component skill profile of adolescent struggling readers. LDQ 32(1), 21-38.',NULL),
('siegler','Siegler, R.S. et al. (2012). Early predictors of high school mathematics achievement. Psychological Science 23(7).',NULL);

INSERT INTO area VALUES
('math-k4','math',0,4,'CPS',0),
('reading-35','reading',3,5,'CPS',0),
('math-6','math',6,6,'CMS',1),
('ela-6','reading',6,6,'CMS',1);

INSERT INTO route VALUES
('to-t2','tier',2,NULL,'Tier 2; placement next. Owner: interventionist.'),
('to-t1','tier',1,NULL,'Return to Tier 1 with a monthly probe through the spring window.'),
('t1-plan','tier1_plan',1,NULL,'Stays in Tier 1 with a named plan; re-screened next window. Owner: classroom teacher + dept chair.'),
('slp','slp',NULL,NULL,'SLP language screen; evaluation referral if failed.'),
('sped-eval','sped_eval',NULL,NULL,'Special education evaluation. 34 CFR 300.300 consent; 603 CMR 28.05 timelines.'),
('cst','cst',NULL,NULL,'CST referral. CST Hub covers PS-5 only; the MS route is not written.'),
('carry','carry',NULL,NULL,'Status carries across the year boundary; first fall probe is the next PM point; no new second stage.'),
('iep','iep',NULL,NULL,'Rules governed by the IEP.');

INSERT INTO area_core VALUES
('math-k4','into-math',NULL,'doc'),
('math-6','cpm',NULL,'doc');
-- reading-35 and ela-6 have no core named in either district document.

INSERT INTO area_screener VALUES
('math-k4','star-m',3,4,'Sep,Jan,May','screen','PR < 25','doc'),
('math-k4','mcas-m',4,4,'prior spring','screen','Partially Meeting','doc'),
('reading-35','dibels',3,4,'Sep,Jan,May','screen','below ORF benchmark','doc'),
('reading-35','star-r',5,5,'Sep,Jan,May','screen','PR < 25','doc'),
('reading-35','mcas-e',4,5,'prior spring','screen','Partially Meeting','doc'),
('math-6','mcas-m',6,6,'prior spring','screen','Partially Meeting','doc'),
('math-6','star-m',6,6,'Sep,Jan,May','screen','PR < 25','proposed'),
('math-6','star-m',6,6,'Jan','level_check',NULL,'proposed'),
('math-6','star-m',6,6,'on request','on_request','PR < 25','proposed'),
('ela-6','star-r',6,6,'Sep,Jan,May','screen','PR < 25','doc'),
('ela-6','mcas-e',6,6,'prior spring','screen','Partially Meeting','doc'),
('ela-6','star-r',6,6,'Jan','level_check',NULL,'proposed'),
('ela-6','star-r',6,6,'on request','on_request','PR < 25','proposed');

INSERT INTO profile(id,area_id,name,sort_rule) VALUES
('k4-fact','math-k4','fact fluency','fact items low on probe'),
('k4-pv','math-k4','place value / multi-digit','regrouping, magnitude items low'),
('k4-frac','math-k4','fractions','fraction items low (gr 3-4)'),
('k4-wp','math-k4','word problems','computation fine, word-problem items low'),
('r35-dec','reading-35','decoding','ORF accuracy < 95%'),
('r35-flu','reading-35','fluency','accuracy >= 95%, ORF below benchmark'),
('m6-fact','math-6','fact fluency','fact and multi-digit items low'),
('m6-rat','math-6','rational number','fraction/decimal/ratio items low, whole number fine'),
('m6-wp','math-6','word problems','computation fine, word-problem items low'),
('m6-pre','math-6','proportional / pre-algebra','equation/variable/proportion items low, all else fine'),
('e6-dec','ela-6','decoding','accuracy < 95%'),
('e6-flu','ela-6','fluency','accuracy >= 95%, wcpm below 25th pct'),
('e6-com','ela-6','comprehension only','accuracy and wcpm both fine; STAR gap unexplained by word reading');

INSERT INTO protocol(id,area_id,tier,profile_id,deliverer_role,placement_tool_id,program_id,pm_tool_id,pm_metric,entry_rule,dosage,group_size,weeks,pm_rule,review_rule,exit_rule,next_step_id,nonresponse_id,status,status_note,citations) VALUES
-- K-4 math
('k4-t1','math-k4',1,'-','classroom teacher',NULL,'into-math','star-m','scaled score','STAR PR<25 or MCAS Partially -> second stage','daily block','class','year','6-wk second stage: STAR biweekly, 3 points; flat slope -> Tier 2','end of second stage',NULL,'to-t2',NULL,'proposed',NULL,'crit pp.263-264'),
('k4-t2-fact','math-k4',2,'k4-fact','Heather or trained para','fact-2m','bridges-i','star-m','scaled score','flat second stage, fact profile','3 x 30','3-5','12-15','STAR biweekly vs goal line to PR 40; 4 below -> change; Bridges module >=80% to advance','wk 6 slope; wk 12 level+slope','PR>=40 and slope>=goal line at two reviews','to-t1','cst','proposed','program is doc (Bridges Interv. pre/post in data inventory)','smart p.14; pg2021 Rec 6'),
('k4-t2-pv','math-k4',2,'k4-pv','Heather or trained para','bridges-i','bridges-i','star-m','scaled score','flat second stage, place-value profile','3 x 30','3-5','12-15','STAR biweekly vs goal line to PR 40; 4 below -> change; Bridges module >=80% to advance','wk 6 slope; wk 12 level+slope','PR>=40 and slope>=goal line at two reviews','to-t1','cst','proposed','program is doc','smart p.14; pg2021 Rec 4'),
('k4-t2-frac','math-k4',2,'k4-frac','Heather or trained para','bridges-i','bridges-i','star-m','scaled score','flat second stage, fraction profile','3 x 30','3-5','12-15','STAR biweekly vs goal line to PR 40; 4 below -> change; Bridges module >=80% to advance','wk 6 slope; wk 12 level+slope','PR>=40 and slope>=goal line at two reviews','to-t1','cst','proposed','program is doc','smart p.14; pg2021 Rec 4; siegler'),
('k4-t1-wp','math-k4',1,'k4-wp','classroom teacher',NULL,'into-math','star-m','PR at window','word-problem profile','in class','class','to next window','schema instruction in core (PG Rec 5); STAR at windows only','next window','re-screen','t1-plan',NULL,'proposed',NULL,'pg2021 Rec 5 pp.40-50'),
-- 3-5 reading
('r35-t1','reading-35',1,'-','classroom teacher',NULL,NULL,'dibels','wcpm + accuracy','below ORF benchmark -> second stage','daily literacy block','class','year','6-wk second stage: ORF biweekly, 3 reads; flat -> Tier 2','end of second stage',NULL,'to-t2',NULL,'proposed','no core named; district shopping','pg2009r Rec 3'),
('r35-t2-dec','reading-35',2,'r35-dec','reading specialist or trained para','wist','just-words','dibels','accuracy %','flat second stage, accuracy <95%','3-5 x 20-40','3-5','12-15','ORF biweekly; aimline to 95% accuracy; 4 below -> change; JW unit >=80%','wk 6; wk 12','accuracy>=95% and slope>=aimline, two reviews','to-t1','cst','proposed','program is doc','pg2009r Rec 3 p.19'),
('r35-t2-flu','reading-35',2,'r35-flu','reading specialist or trained para','read-nat','read-nat','dibels','wcpm','flat second stage, accuracy >=95%','3-5 x 20-40','3-5','12-15','ORF biweekly; aimline to grade benchmark; 4 below -> change','wk 6; wk 12','wcpm>=benchmark and slope>=aimline, two reviews','to-t1','cst','proposed','program is doc','pg2009r Rec 3 p.19'),
-- MS math 6
('m6-t1','math-6',1,'-','classroom teacher',NULL,'cpm','cbm-68','points','STAR PR<25 or MCAS Partially; teacher may request off-window STAR; grades and ALEKS alone do not flag','daily block','class','year','6-wk second stage: CBM probe biweekly, 3 probes; skills profile sorts','end of second stage',NULL,'to-t2',NULL,'proposed',NULL,'crit pp.263-264; smart p.9'),
('m6-t2-fact','math-6',2,'m6-fact','trained para','fact-2m','fact-prog','cbm-68','points + digits correct','flat second stage, fact profile','3 x 45 FLEX','3-5','12-15','CBM biweekly, fact probe weekly; aimline to 25th pct and 40 digits/2 min; 4 below -> change','wk 6; wk 12','CBM>=25th pct and 40 digits, two reviews','to-t1','cst','proposed','dosage is doc (tiers deck)','pg2021 Rec 6; smart p.14'),
('m6-t2-rat','math-6',2,'m6-rat','interventionist','bridges-i','bridges-i','cbm-68','points','flat second stage, rational-number profile','3 x 45 FLEX','3-5','12-15','CBM biweekly; aimline to 25th pct; 4 below -> change; Bridges module >=80%','wk 6; wk 12','CBM>=25th pct, two reviews','to-t1','cst','proposed','dosage is doc; Bridges is a K-5 kit used by content','pg2021 Rec 4 pp.29-39; siegler'),
('m6-t2-wp','math-6',2,'m6-wp','math teacher on FLEX duty','sbi','sbi','cbm-68','points + schema check','flat second stage, word-problem profile','3 x 45 FLEX','3-5','12-15','CBM biweekly; aimline to 25th pct; 4 below -> change; 5/6 per schema to advance','wk 6; wk 12','CBM>=25th pct and 4/4 schemas, two reviews','to-t1','cst','proposed','dosage is doc','pg2021 Rec 5 pp.40-50'),
('m6-t1-pre','math-6',1,'m6-pre','classroom teacher',NULL,'aleks','star-m','PR at window','pre-algebra profile; no Tier 2 protocol with evidence','3 x 20 in class','class','to next window','ALEKS strand mastery; STAR at windows only','Jan dept review','re-screen','t1-plan','carry','proposed',NULL,NULL),
-- MS ELA 6
('e6-t1','ela-6',1,'-','ELA teacher',NULL,NULL,'tmsfa','wcpm + accuracy','STAR PR<25 or MCAS Partially; teacher may request off-window STAR; grades alone do not flag','daily block','class','year','6-wk second stage: one-minute read biweekly, 3 reads; accuracy/rate sort','end of second stage',NULL,'to-t2',NULL,'proposed','no core named','vf2012 pp.4-5'),
('e6-t2-dec','ela-6',2,'e6-dec','reading specialist','wist','just-words','tmsfa','accuracy %','flat second stage, accuracy <95%','3 x 45 FLEX','3-5','12-15','one-minute read biweekly; aimline to 95%; 4 below -> change; JW unit >=80%','wk 6; wk 12','accuracy>=95% and slope>=aimline, two reviews','to-t1','cst','proposed','dosage and program are doc','espin pp.60-75; vf2012 p.5 (sort), p.8 (group size)'),
('e6-t2-flu','ela-6',2,'e6-flu','trained para','read-nat','read-nat','tmsfa','wcpm','flat second stage, accuracy >=95%, wcpm low','3 x 45 FLEX','3-5','12-15','one-minute read biweekly; aimline to 25th pct; 4 below -> change','wk 6; wk 12','wcpm>=25th pct and slope>=aimline, two reviews','to-t1','cst','proposed','dosage and program are doc','pg2009r Rec 3; vf2012 p.5'),
('e6-com','ela-6',NULL,'e6-com','SLP','celf5-s',NULL,'star-r','PR at window','accuracy and rate fine; not a Tier 2 reading entry','n/a',NULL,NULL,'re-screen at next window from Tier 1','next window',NULL,'slp','sped-eval','proposed','no Tier 2 protocol exists for this profile','vf2012 p.5; hock');

-- Observed practice (what a teacher does now). Survey rows; basis='observed', teacher = the teacher.
-- Anne (math 6), interviewed 2026-10: screens and probes with ALEKS against DESE grade 6 standards; does not use STAR Math.
INSERT INTO profile(id,area_id,teacher,basis,name,sort_rule) VALUES
('m6-anne-facts','math-6','Anne','observed','can''t do facts','teacher judgment from class work');
INSERT INTO protocol(id,area_id,tier,profile_id,teacher,basis,as_of,evidence,deliverer_role,program_id,pm_tool_id,pm_metric,entry_rule,dosage,group_size,weeks,pm_rule,review_rule,exit_rule,next_step_id,nonresponse_id,status,status_note) VALUES
('m6-anne-t1','math-6',1,'-','Anne','observed','2026-10','interview','classroom teacher','cpm','aleks','DESE grade 6 standards mastered','ALEKS knowledge check against DESE grade 6 standards, her own screener; does not use STAR Math','daily block','class','year','ALEKS as the ongoing probe, by DESE grade 6 standard; no STAR Math',NULL,NULL,NULL,NULL,'unwritten','ALEKS is both screener and probe; nothing written down'),
('m6-anne-t2','math-6',2,'m6-anne-facts','Anne','observed','2026-10','interview','classroom teacher','aleks','aleks','DESE grade 6 standards mastered','ALEKS knowledge check (DESE grade 6 standards) + teacher judgment; not STAR Math','3 x 45 FLEX','varies','open-ended','ALEKS progress by DESE grade 6 standard; no shared measure with other teachers','none','none',NULL,'cst','unwritten','ALEKS is both screener and probe; nothing written down');

INSERT INTO student_example VALUES
('ex-k4-j','J','k4-t2-fact','Grade 4. Sep 8 STAR SS 592 PR 18, MCAS gr3 Partially. Second stage 592/598/601 (+1.5/wk). Oct 24 probe: 11 digits/2 min; Bridges Vol 4 Module 2. Oct 27-Feb 13 Bridges 3x30 group of 3. STAR 605,618,622,637,649,658,667,671 vs line +4.4/wk. Dec 8 on track; Jan 26 PR 41 (cycle 1); Feb 13 PR 42 exit. Mar 678, Apr 684.'),
('ex-m6-k','K','m6-t2-fact','Grade 6. Sep 9 STAR PR 17, MCAS Partially. Second stage CBM 14/15/15. Oct 27 placement: x6-x9 and division below 50%. Para, 3x45 FLEX, group of 4. CBM 16,18,21,23,26,28,31,33 (aimline 14->30); facts 14->42. Dec 8 above line; Jan 26 first qualifying review; Feb 13 exit.'),
('ex-e6-m','M','e6-t2-dec','Grade 6. Sep 9 STAR PR 16, MCAS Partially. Second stage 98/96/99 wcpm at 91/90/92% accuracy. Oct 27 WIST word ID 6th pct; Just Words Unit 1. Specialist, 3x45 FLEX, group of 3. Accuracy 92,93,93,95,96,96,97,98. Jan 26 first qualifying review; Feb 13 exit at 98%, 124 wcpm. Units 7-14 unfinished; fall check.'),
('ex-e6-a','A','e6-com','Grade 8. Sep 9 STAR PR 23, MCAS Partially. Second stage 141/143/140 wcpm at 98-99%: reading is not the problem. Oct 28 CELF-5 Screener not met. Nov 3 eval referral, Nov 7 consent. Dec 2 CELF-5 Core Language 78. Jan 20 team: language disability eligible. Tier 2 reading never opened.');
