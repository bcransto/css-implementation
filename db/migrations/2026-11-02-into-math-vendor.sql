-- Content: HMH Into Math, the K-4 math core, from the vendor and from EdReports (read 2026-11-02).
-- Into Math is a Tier 1 core, so it is on none of the three NCII charts (no ncii_* rows; the ncii
-- evidence row says so, as for Just Words and Bridges). The vendor side goes on tool_profile; the
-- EdReports 2020 review and HMH's own ESSA label go on tool_evidence; the two K-4 Tier 1 rows get the
-- lesson flow (instruction) and the within-core help for a flagged student (support).
-- HMH's current pages describe "Into Math Version 2" (2025). EdReports reviewed the 2020 edition, which
-- is most likely the one Carlisle owns; confirm which edition the K-4 rooms have. Minutes, sessions per
-- week, weeks, group size and price are not stated anywhere HMH publishes, so those columns stay NULL.
-- Apply to the LIVE database:
--   ssh bcransto@pinto 'sqlite3 -bail ~/css-implementation/css.db' < db/migrations/2026-11-02-into-math-vendor.sql
BEGIN;

UPDATE tool SET
  url   = 'https://www.hmhco.com/programs/into-math',
  notes = 'K-4 core. Tier 1 whole-class curriculum; not on any NCII chart (core programs are not charted). EdReports 2020 review: meets expectations on all three gateways, every grade K-8. HMH now sells Version 2 (2025); confirm which edition the K-4 rooms have.'
WHERE id = 'into-math';

INSERT INTO tool_profile (tool_id, grade_lo, grade_hi, intended_for, setting, max_group, minutes, min_per_week, min_weeks,
  interventionist, training, support, cost, technology, manual, fidelity_checklist, obtain, description, source, url, as_of)
VALUES ('into-math', 0, 8,
  'Core curriculum "designed for whole-class instruction," Grades K-Algebra 1 (K-8 in the research abstract). No Tier 2 or Tier 3 claim; HMH''s intervention product is Math 180 (Grades 3-12, students one or more years below grade level). Multilingual learners: Kate Kinsella routines, Language Development Resource Guide, Spanish edition (Arriba las Matematicas).',
  'Whole class, with a three-way small-group step after each lesson''s Quick Check: Almost There (reteach, tabletop flipchart mini-lesson, "perfect for co-teachers or resource math teachers"), On Track (small-group activity), Ready for More (challenge). Prerequisite Check at the start of each module forms small groups and flags concepts to reteach.',
  NULL, NULL, NULL, NULL,
  'Classroom teacher; the Almost There small-group lessons are written for a co-teacher or resource math teacher',
  'Included with the subscription: a Getting Started session with an HMH coach, Teacher Success Pathways (self-paced, first 30 days), Teacher''s Corner live and on-demand. Extra cost: Coachly 1:1 coaching, "Building Students'' Capacity for Reasoning and Discourse with Into Math" course. Nothing described as required; no durations given.',
  'HMH Customer Service and Technical Support portal (support.hmhco.com); Teacher''s Corner implementation support',
  'Quote only; no prices published',
  'Lives on HMH Ed; HMH says "no-tech, full-tech, or anywhere in between." Print: Student Edition, Practice Plus workbook, manipulatives, vocabulary cards, Almost There flipchart. Digital only: Teacher''s Guide (eBook/PDF), Interactive Classroom Presentations (HMH Classcraft), assessments and reports, Waggle adaptive practice, AI tools.',
  'Yes (Teacher''s Guide; Implementation Guide; Scope and Sequence with Pacing Guidance; editable lesson plans)',
  'No (none mentioned)',
  'HMH; hmhco.com/programs/into-math (sales contact; online sample for K-12 educators)',
  'Modules (16-21 a grade, grouped into units; a module is one standards cluster, like a textbook chapter) of 4-7 lessons. Each lesson: Learning Goal routine, Spark Your Learning task, discourse-rich tasks, Turn & Talk, Quick Check, then On Your Own practice. Each module: Prerequisite Check, lessons, module review, module test (Forms A and B). Beginning, middle and end-of-year benchmark assessments. Per-lesson Reteach, Almost There flipchart lesson, Challenge, Intervention Activities, Fluency Practice, games, practice videos; Waggle practice assigned by module and lesson. Reports on Ed: Assessment, Standards, Grouping, Program Activity; MAP Growth integration for districts rostered through HMH.',
  'HMH, Into Math Version 2 pages and the Grades K-5 Program Overview brochure and Component List (July 2025). Daily minutes, sessions, weeks, group size and cost are not stated; the Scope and Sequence with Pacing Guidance is inside Ed and was not read.',
  'https://www.hmhco.com/programs/into-math',
  '2026-11');

INSERT INTO tool_evidence (tool_id, source, finding, domain, grades, url, notes, as_of) VALUES
  ('into-math', 'ncii', 'not listed', NULL, NULL, NULL, 'Core curriculum; NCII charts screening, progress-monitoring and intervention tools only', '2026-11'),
  ('into-math', 'other', 'EdReports 2020: Meets Expectations on all three gateways (focus and coherence; rigor and mathematical practices; usability), every grade K-8. K-2: 100 / 94 / 94. Grade 3: 100 / 94 / 89. Grade 4: 100 / 88 / 89.', 'standards alignment and usability', 'K-8', 'https://www.edreports.org/reports/overview/hmh-into-math-2020', 'Review of the 2020 edition under EdReports tool v1.0, released 2020-05-21. Version 2 has not been reviewed.', '2026-11'),
  ('into-math', 'essa', 'HMH labels its "Into Math Version 2: Research Evidence Base" as Demonstrates a Rationale (ESSA Tier 4). It is a literature review; no efficacy study of Into Math is on HMH''s research library.', NULL, 'K-8', 'https://www.hmhco.com/research/into-math-research-evidence-base', 'The growth figures on HMH''s Waggle page are about Waggle, not Into Math', '2026-11');

UPDATE protocol SET
  instruction = 'Daily Into Math block, whole class, working through the current module in order. Each lesson: Learning Goal routine, Spark Your Learning task, guided tasks with Turn & Talk, Quick Check (Check Understanding), then On Your Own practice. Each module opens with a Prerequisite Check and closes with a review and module test.',
  support = 'Inside the lesson: students who miss the Quick Check go to the Almost There table for the flipchart reteach of that lesson while the others do the On Track activity or Ready for More challenge; Reteach pages and Intervention Activities are the paper equivalents; Waggle practice can be assigned by lesson. A student who misses the Prerequisite Check gets the module''s reteach of the prerequisite. This is same-day reteach of core content, not an intervention; a student who lands in Almost There lesson after lesson is the second-stage screening case.'
WHERE id = 'k4-t1';

UPDATE protocol SET
  instruction = 'Same daily Into Math block as the whole class. Schema instruction for word problems is part of the core lessons (Spark and task problems are contextual; practice pages include Open Middle problems), so nothing is added outside the block.',
  support = 'In-lesson: the Almost There reteach and Reteach pages for the lessons the student missed, with the word-problem items worked as schema instruction per PG 2021 Rec 5. Same-day reteach of core content, not an intervention.'
WHERE id = 'k4-t1-wp';

COMMIT;
