-- Star Reading: NCII progress monitoring detail page URL on its PM rows, and Renaissance's own monitoring
-- guidance from that page (read 2026-10-31) in the tool note. The SEM figure behind "keep to windows"
-- is not on the NCII page; it is attributed to the Renaissance technical manual.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/2026-10-31-star-reading-detail.sql
PRAGMA foreign_keys = ON;
BEGIN;
UPDATE ncii_pm SET url = 'https://charts.intensiveintervention.org/progressmonitoring/tool/?id=d833969b4dd49868'
 WHERE tool_id = 'star-r';
UPDATE tool SET
  training = 'Less than one hour (Renaissance, per NCII detail page)',
  design_source = 'NCII PM detail page (charts.intensiveintervention.org/progressmonitoring/tool/?id=d833969b4dd49868), read 2026-10-31',
  notes = 'General comprehension; computer-adaptive, 18 min, automatic scoring. Renaissance monitoring guidance (NCII detail page): may test as often as weekly but recommends less; read the Progress Monitoring report only after at least 5 administrations; minimum acceptable growth SGP 50; default cutpoints PR 10 urgent, 25 intervention, 40 low risk. NCII slope reliability was computed on students below PR 30 with 10+ tests over 140+ days. No coefficients or SEM are published on the NCII page; the +/-20-30 scaled-score single-test error that justifies keeping STAR to its windows comes from the Renaissance technical manual (available on request). Slope validity and instruction-change decision rules: no evidence submitted.'
 WHERE id = 'star-r';
COMMIT;
