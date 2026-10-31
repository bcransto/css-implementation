-- v0.13: protocol.instruction, prose for what the instruction looks like. Tier 1: what happens in the core
-- block beyond naming the program; Tier 2+: what a session contains, which dosage and group size do not say.
-- Scoped like every other protocol column, so the Defined tab holds the area's description and each
-- Observed tab the teacher's. Starts empty. A plain ADD COLUMN: no rebuild, no trigger.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-10-31-instruction.sql
ALTER TABLE protocol ADD COLUMN instruction TEXT;
