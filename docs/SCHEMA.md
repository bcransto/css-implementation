# CSS tier-definition database — schema v0.5

The Carlisle System of Support (CSS, the district's MTSS) "Define the Tiers" group needs one place that says, for every academic area, what each tier actually *does*: which tool screens, which rule flags, which test places, which program runs, how it is measured, when it is reviewed, how a student exits, and where they go if they don't. The district's existing documents list nouns (programs, tests) with no verbs (rules). This database is the verbs.

It is edited by a faculty committee of about eight through a web form, so every design choice below favours a form over a query, and a text column over a table where a query doesn't need the structure.

## The one idea

A row of `protocol` is **one area × one tier × one diagnostic profile**. Not "ELA 7's Tier 2" — "ELA 7, Tier 2, decoding." Middle school reading has three profiles (decoding, fluency, comprehension-only) and each has its own placement test, program, progress metric, aimline and exit rule. Math 6 has four. Collapsing them to one row per tier is how the old slides lost the information.

A profile that routes *outside* the tiers (comprehension-only → SLP; pre-algebra → stays in Tier 1 with a plan) is still a `protocol` row, with `tier = NULL` or `tier = 1` and a `route` that says where it goes. That is deliberate: the page must show the kid who doesn't fit, not drop them.

## Defined vs observed (v0.3)

Before the committee can define a rule it needs to see what each teacher does now. So `protocol` and `profile` carry two scoping columns:

- `teacher` — `'-'` means the area's rule. A name means what that teacher does.
- `basis` — `defined` is the area's decided rule; `observed` is a description of a teacher's current practice. Observed rows also carry `as_of` (YYYY-MM) and `evidence` (`interview`, `PM sheet`, `self-report`).

An observed profile is a teacher's own sorting category ("can't do facts"), and its `sort_rule` is how that teacher decides. A trigger refuses a protocol whose `teacher` differs from its profile's `teacher` (the `'-'` profile is allowed for anyone). The page shows observed rows under the defined ones, so variance between teachers is visible next to the rule it will be replaced by. Observed rows are survey data; they are edited live on pinto and mirrored into the seed.

## Tables

| table | one row is | notes |
|---|---|---|
| `area` | a subject × grade band (`math-6`, `reading-k2`) | numeric `grade_lo`/`grade_hi`, K = 0; `building`, `has_flex` |
| `tool` | a named instrument or program | no `kind` column: a tool's role is whichever `protocol` column points at it |
| `tool_license` | the grades a tool is owned/licensed for | **no row = not owned**. Replaces a global `owned` flag; STAR Math is 1–5, not 6–8 |
| `ncii_screening` | one row of NCII's academic screening tools chart: tool × measure × grade | **no row = not on the chart**. Ratings are `convincing` / `partial` / `unconvincing` / `unavailable`, NULL when not yet entered; `*_d` flags are NCII's "d" marker. See "NCII ratings" |
| `ncii_pm` | one row of NCII's academic progress monitoring tools chart: tool × measure × grade × measure type | same conventions. Performance level standards (reliability, validity, bias analysis) and growth standards (slope reliability, slope validity, alternate forms, two decision-rule ratings) |
| `area_core` | a core program in an area | link table: grade 3 reading has a phonics core and a comprehension core |
| `area_screener` | one screening tool in one area for a grade range | `role` ∈ screen / level_check / on_request; `cut` is the flag threshold |
| `profile` | a diagnostic category inside an area, for the area (`teacher '-'`) or for one teacher | `sort_rule` says how the second stage assigns it. Row `'-'` is the whole-class sentinel |
| `route` | a destination | `kind` ∈ tier / tier1_plan / slp / cst / sped_eval / iep / carry / external / none; optional `target_area_id` for cross-building handoffs |
| `protocol` | area × tier × profile × teacher | the page. See below |
| `source` | a citation | read-only lookup; `protocol.citations` is free text that names these ids |
| `student_example` | an illustrative (fake) student timeline | `student_key` lets one fake student appear in two areas. Plain text, not JSON. **Never real students.** |

### `protocol` columns, in page order

| column | meaning | example |
|---|---|---|
| `teacher`, `basis` | scope: the area's defined rule, or one teacher's observed practice | `-` / `defined` |
| `as_of`, `evidence` | observed rows only: when recorded, and how | `2026-10` / `interview` |
| `entry_rule` | Tier 1: the flag rule (what opens the second stage). Tier 2+: what the second stage must show | `STAR PR<25 or MCAS Partially` / `flat second stage, accuracy <95%` |
| `placement_tool_id` | the test that places the student in the program | WIST, Bridges placement, CELF-5 Screener |
| `program_id` | the thing delivered | Just Words |
| `deliverer_role` | a role, not a person | `trained para` |
| `dosage`, `group_size`, `weeks` | | `3 x 45 FLEX`, `3-5`, `12-15` |
| `pm_tool_id`, `pm_metric` | the measure and which number from it | TMSFA one-minute read / `accuracy %` vs `wcpm` |
| `pm_rule` | frequency, aimline, decision rule, one textarea | `biweekly; aimline to 95%; 4 below -> change` |
| `review_rule` | | `wk 6 slope; wk 12 level+slope` |
| `exit_rule` | | `>=95% and slope>=aimline, two reviews` |
| `next_step_id` → route | on response / end of stage | `to-t1`, `slp` |
| `nonresponse_id` → route | | `cst`, `sped-eval` |
| `status` | doc / unwritten / proposed / iep | row-level |
| `status_note` | per-field exceptions, as prose | `dosage is doc; rest proposed` |
| `citations` | source ids with pages, as prose | `pg2021 Rec 4 pp.29-39; smart p.14` |

**Status vocabulary.** `doc` = exists in a district document (Carlisle Current Data Gathered, K–8 MTSS Tiers deck). `unwritten` = exists in practice, not written down. `proposed` = ours, for the department to confirm or change. `iep` = governed by an IEP, not by a district rule.

**Second stage.** Every Tier 1 row carries a six-week "second stage": a flagged student stays in core while a short probe is given three times, biweekly. The slope confirms or clears the flag, and the probe's profile (accuracy vs rate in reading; skills profile in math) sorts the student into a Tier 2 profile. This is why `profile.sort_rule` exists and why Tier 2 rows have a placement test but no diagnostic — the sorting already happened in Tier 1. Source: Fuchs & Fuchs 2017 pp. 263–264; Vaughn & Fletcher 2012 pp. 4–5.

**Progress monitoring.** STAR (Math, Reading) is kept to its three windows: its single-test error (~±20–30 scaled points) exceeds the growth expected between biweekly tests. Biweekly measures are CBM probes (one-minute read, math CBM, fact probe). See `tool.notes`.

## NCII ratings (v0.4, v0.5)

The National Center on Intensive Intervention publishes three tools charts (screening, progress monitoring, intervention), each with its own columns and a four-value rating legend: full bubble *convincing evidence*, half *partially convincing*, empty *unconvincing*, null bubble *data unavailable*, plus a "d" marker on a cell when disaggregated data are available. `ncii_screening` copies the academic screening chart at its own grain: one row per tool × measure (NCII's "Area": Composite, Computation, Maze) × grade, because classification accuracy differs by grade and averaging it would lose what the chart says. Columns follow the chart's three tabs: classification accuracy fall/winter/spring (ratings, each with a `_d` flag), technical standards (reliability, validity, sample representativeness as ratings; bias analysis as the chart's text, Provided / Not Provided), and usability features (admin format, admin and scoring time, scoring format, types of decision rules, evidence for multiple decision rules, all text as written). `as_of` is the month the row was copied. A tool with no rows is not on the chart, the same convention as `tool_license`. The tool page (`/tool/<id>`) shows the rows; the area page's screening table shows the three classification-accuracy bubbles when exactly one row matches the screener's grades. The charts share almost no columns, so each gets its own table rather than one wide one.

`ncii_pm` (v0.5) copies the academic progress monitoring chart the same way: one row per tool × measure × grade × **measure type**, where measure type is the chart's own text, `End Year Goal` for a general outcome measure or `Short Term Skill` for a mastery measure; it is part of the key because a tool can list both for one measure and grade. Columns follow the chart's three tabs: performance level standards (reliability and validity as ratings, bias analysis as text), growth standards (sensitivity as reliability and validity of the slope, alternate forms, decision rules for setting and revising goals and for changing instruction, all ratings), and usability (admin format, admin and scoring time, scoring format, and ROI & EOY benchmarks as the chart's text). No `_d` flags: the PM chart's legend lists the marker but none of its cells carry one; add flags by migration if a row ever needs one. The tool page shows the rows; in the protocol grid a PM tool cell shows the slope reliability, slope validity and alternate-forms bubbles when exactly one row matches the area's grades. The intervention chart (`ncii_intervention`) is still to come.

## Invariants the app should enforce

- `UNIQUE(area_id, tier, profile_id, teacher)` — works because `profile_id` and `teacher` default to `'-'`, never NULL.
- A protocol's `teacher` must equal its profile's `teacher` unless the profile is `'-'`. Enforced by the `protocol_profile_scope` trigger on insert; the form should also filter the profile select by teacher.
- A protocol's `placement_tool_id`, `program_id`, `pm_tool_id` should normally have a `tool_license` row covering the area's grades; Q1 lists violations. Do not block the insert — the violation is the finding.
- `citations` should name ids that exist in `source`; a soft check in the form, not a FK.
- No `ncii_screening` or `ncii_pm` row for a tool means it is not on that NCII chart (or not entered yet); never add a "reviewed" boolean to `tool`.
- `student_example` rows are illustrations. Never load real student data into this database.

## Queries the app must answer

`db/queries.sql`, Q1–Q12. Q5 is the page (bound to an area and a teacher; `'-'` for the defined rows). Q1/Q1b are the budget list. Q2–Q4, Q6 are the audit ("what's missing"). Q9 and Q10 are the variance view: each teacher's observed practice for a tier next to the defined rule, and the distinct sorting categories teachers use. Q11 is the NCII screening ratings for an area's screeners at its grades; Q12 the same for the PM tools its protocols use.

## Review history

v0.1 (10 tables) was reviewed by two independent passes: one trying to simplify, one trying to break it with ten edge cases (K–2's five DIBELS measures by grade, a behavior tier, Tier 3 inside an IEP, two core programs, one student in two tiers, 8→9 handoff to the high school, a tool used as both screener and PM, per-field status, two pages from one source, a tool licensed for some grades only). v0.2 is the merge: four tables collapsed to text columns, `tool_license` and `area_core` added, grade bounds made numeric, the NULL hole in the UNIQUE constraint closed. All ten cases load in v0.2 without workarounds; the duplicate whole-class row is correctly rejected.

v0.3 added teacher scoping (`teacher`, `basis`, `as_of`, `evidence` on `protocol`; `teacher`, `basis` on `profile`), widened the UNIQUE constraint to include `teacher`, added the scope trigger, dropped `area.teachers`, and added Q9/Q10.

v0.4 (2026-10-30) added `ncii_screening` and Q11, and the `/tool/<id>` page. Decided with Brad: per-chart-row grain rather than one summary row per tool; screening chart only for now; the four NCII rating values with a separate `_d` flag rather than a fifth value; no data loaded yet, rows are entered as the chart is read. Applied to the live database by `db/migrations/2026-10-30-ncii-screening.sql`.

v0.5 (2026-10-30) added `ncii_pm` and Q12, and the PM table on the tool page. Same decisions as v0.4; measure type added to the key. Applied by `db/migrations/2026-10-30-ncii-pm.sql`.

## Known gaps

- `area_screener.windows` is text. If per-window cut scores are ever needed (K–2 DIBELS benchmarks differ by window), split into a `screener_window` table.
- `route.target_area_id` is set for cross-building carries only; most routes are generic.
- No audit trail. If the committee needs to see who changed a cell, add `updated_by`, `updated_at` to `protocol`.
- No `student` table, on purpose.

## Seed

`db/seed.sql` loads four areas (K–4 math, 3–5 reading, math 6, ELA 6), 20 tools, 8 sources, 13 defined profiles, 17 defined protocols, 4 fake students, plus the observed rows from the teacher survey (one profile and two protocols for a math 6 teacher so far). Everything tagged `proposed` is a design proposal from the research pass, not district policy.
