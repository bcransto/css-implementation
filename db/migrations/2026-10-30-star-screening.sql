-- Star (Renaissance) rows from NCII's academic screening chart, copied 2026-10-30: Reading grades 1-11
-- to tool star-r, Math K-11 to tool star-m. No "d" markers on any row.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-30-star-screening.sql
PRAGMA foreign_keys = ON;
BEGIN;
INSERT INTO ncii_screening (tool_id,measure,grade,ca_fall,ca_winter,ca_spring,reliability,validity,sample_rep,bias_analysis,admin_format,admin_time,scoring_format,decision_rules,multi_rules_evidence,as_of) VALUES
('star-r','Reading',1,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',2,'convincing','convincing','convincing','convincing','convincing','Regional with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',3,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',4,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',5,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',6,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',7,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',8,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',9,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',10,'convincing','convincing','convincing','convincing','convincing','Regional with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-r','Reading',11,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group; Computer-administered','18 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',0,'partial','convincing','partial','convincing','convincing','National without Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',1,'convincing','convincing','convincing','convincing','convincing','Regional with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',2,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',3,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',4,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',5,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',6,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',7,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',8,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',9,'convincing','convincing','convincing','convincing','convincing','Regional with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',10,'convincing','convincing','convincing','convincing','convincing','Regional with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10'),
('star-m','Math',11,'convincing','convincing','convincing','convincing','convincing','National with Cross-Validation','Provided','Individual; Group','20 minutes','Automatic','Risk Benchmarks','No','2026-10');
COMMIT;
