# Glossary: NCII terms as used in this database

Definitions follow the National Center on Intensive Intervention (NCII, intensiveintervention.org), quoted where NCII gives a definition and paraphrased where it only describes. Each entry ends with how the term maps onto this database. Where NCII has no definition of its own, the entry says so. Sources are listed at the end; checked 2026-10-28.

## Assessment

**Screening (universal screening).** Brief assessment of *all* students to find the ones at risk. NCII: screening tools "identify students at risk for poor academic outcomes, including students who require intensive intervention" and "accurate universal screening sets the foundation for a successful tiered system of support." NCII rates screening tools on classification accuracy, reliability, validity, sample representativeness and bias. "Universal" is the "all students" part; a screen given only to some students is not universal screening. NCII does not prescribe a frequency; the field convention is fall, winter and spring windows.
*Here:* the `area_screener` rows (tool, windows, cut, role = screen).

**Screener (screening tool).** The instrument used for screening. An existing test can serve as a screener (MCAS, STAR) if it sorts students into at-risk and not-at-risk with known accuracy; a teacher-made check used for the same purpose is a screener with unknown accuracy.
*Here:* `tool` rows pointed at by `area_screener`.

**Cut score (cut point).** The score on a screener below which a student counts as at risk. NCII reviews the *classification accuracy* of a tool's cut points: how well the tool "groups students into at risk and not at risk" against an outside criterion. A cut score is what makes a screen a rule rather than a judgment.
*Here:* `area_screener.cut` ("PR < 25", "Partially Meeting"). Blank means no cut exists.

**Diagnostic assessment.** NCII: "diagnostic assessment tools help teachers identify a student's specific skill deficits" so the intervention can be targeted. Screening says *who*; diagnostic assessment says *what*. NCII's training materials: diagnostic assessments "evaluate students' current skills and knowledge to identify strengths, weaknesses, and gaps."
*Here:* the `profile.sort_rule` (what sorts a flagged student into a profile) and `protocol.placement_tool_id` (the test that places a student in a program).

**Progress monitoring.** NCII's definition: "repeated measurement of student performance used to inform instruction of individual students in general and special education." It is a kind of formative assessment, used "to measure growth for students already at risk," to "quantify a student rate of improvement or responsiveness to instruction, and to evaluate the effectiveness of instruction." The data are graphed against a goal and read with decision rules. NCII distinguishes progress monitoring from merely "monitoring progress": the former uses a standardized measure given repeatedly; the latter is watching.
*Here:* `pm_tool_id`, `pm_metric` and `pm_rule` on a `protocol` row. "Informal check-ins" is monitoring progress, not progress monitoring, and should be recorded as exactly that.

**Progress monitoring measure (tool).** NCII's four characteristics: "brief and easy for teachers to administer repeatedly; sensitive to change, which means it can pick up on improvements in student skills; meets standards of validity and reliability based on research; and follows standardized administration and scoring procedures." NCII rates tools on performance-level standards (reliability, validity) and growth standards (sensitivity to student learning, alternate forms, decision rules).
*Here:* the `tool` row in `pm_tool_id`.

**Probe.** One administration of a progress monitoring measure: the sheet the student actually does, timed and scored the same way every time. NCII uses the word in passing ("GOM probes sample all skills that will be taught in the annual grade-level curriculum"; "administer three progress monitoring probes and use the median score as the baseline") but has no entry defining it; the formal terms are *measure* and *tool*. In this project "probe" means a CBM-style measure, as opposed to a program's built-in check or a teacher's observation.
*Here:* the proposed six-week second stage ("3 probes, biweekly") and the biweekly Tier 2 PM rules.

**General outcome measure (GOM).** NCII: "a type of standardized assessment that indexes students' performance on a broad construct or outcome, such as words read correctly in connected text within a fixed time." GOM probes "sample all skills that will be taught in the annual grade-level curriculum, or they focus on a skill that reflects overall competence in a domain." Because every probe samples the same thing, scores are comparable across the year, which is what makes a slope meaningful.
*Here:* one-minute read (wcpm, accuracy), grade 6–8 mixed-skills math CBM.

**Single-skill (mastery) measure.** NCII: "indexes a student's mastery of a single objective or discrete skill or the rate of a student's mastery through a learning progression of objectives." Useful for short-term objectives, but "less useful for monitoring students' maintenance of skills and progress across the school year," and weaker for modelling growth. A program's unit check (Just Words unit test, Bridges module check, ALEKS topic mastery) is a mastery measure.
*Here:* the "unit >= 80% to advance" clauses in `pm_rule`; ALEKS topics mastered.

**Curriculum-based measurement (CBM).** The research tradition most GOMs come from: short, timed, standardized probes with alternate forms, scored in a countable unit (words read correctly, digits correct). NCII's charts and training are built around CBM-style measures but NCII uses the general terms above rather than defining CBM separately.
*Here:* `tool` notes ("mixed-skills timed probe"); the "Grade 6–8 math CBM" tool still to be chosen.

**Alternate forms.** Equivalent versions of a measure so that repeated administration does not test memory of the sheet. NCII's standard for the top rating: "at least 20 alternate forms and evidence is strong for comparability of alternate forms." A tool should have "a sufficient number of alternate forms of equal and controlled difficulty to allow for progress monitoring at recommended intervals."
*Here:* implied by any biweekly PM rule; a teacher-made probe without alternate forms cannot be given biweekly.

**Baseline.** The starting score on the PM measure. NCII's options: the universal screening score, or the median (or mean) of three probes.
*Here:* the three second-stage probes double as baseline.

**Goal line (aim line).** NCII: "a line on students' progress monitoring graphs that connects the data point representing students' baseline performance to their goal." The goal comes from an end-of-year benchmark, national norms for rate of improvement, or an intra-individual target.
*Here:* "aimline to 95% accuracy", "aimline to 25th pct" in `pm_rule`.

**Benchmark score.** NCII: "the level of performance expected on a specific measure at a specific point in time, usually the end of the present grade level."
*Here:* exit rules ("wcpm >= benchmark").

**Rate of improvement (ROI, slope).** Growth per week on the PM measure. NCII rates whether a tool publishes "standards for minimum acceptable growth." The slope of the student's scores is compared with the goal line.
*Here:* "slope >= aimline" in exit rules; the second stage's flat-versus-rising slope.

**Trend line and phase line.** NCII's "key features of a progress monitoring graph include a baseline, a goal, a trend line, and a phase line." The trend line is fitted to the student's scores; a phase (phase change) line marks where the intervention was changed.
*Here:* not stored; implied by `review_rule`.

**Decision rule.** A stated rule for reading the graph that says when to change the intervention or the goal: NCII rates tools on "decision rules for setting and revising goals" and for "changing instruction," and says progress monitoring data are used "to determine if and when instructional changes may be needed." The common form is a point rule ("four consecutive points below the goal line, change the intervention").
*Here:* the "4 below -> change" clause of `pm_rule`; `review_rule` is the scheduled version. "Checks continuously, no rule" is the honest entry when there is none.

**Formative and summative assessment.** NCII: formative assessments "gauge student learning during instruction to determine how students are responding"; summative "measure what students have learned after instruction is complete." Progress monitoring is formative. MCAS is summative, which is why it works as a screener but not as a progress monitor.

## Intervention

**Intervention (intervention program).** NCII's academic intervention tools chart covers "programs beyond the core curriculum that target small groups or individuals, with the goal of improving academic outcomes for students whose performance is nonresponsive to the core procedures." So an intervention is *additional* to core, *targeted* (small group or individual), and for students the core did not reach. Core instruction, however differentiated, is not an intervention.
*Here:* `program_id` on a Tier 2 row; the Tier 1 row's program is the core.

**Validated (evidence-based) intervention program.** An intervention with research showing it works; NCII's chart rates "the methodological quality and level of impact observed in studies of intervention programs." In DBI a validated program is Step 1, "intended as the starting point," before any adaptation. A teacher's self-made materials are an intervention without evidence, which the page should say rather than hide.
*Here:* `tool.notes` ("NCII-listed", "RCTs gr 6–8", "not on NCII chart"); `status` doc/proposed/unwritten says whether the district has adopted it.

**Intensity.** How much, how strong, how closely matched. NCII's Taxonomy of Intervention Intensity has seven dimensions: **strength** ("the evidence of effectiveness for students with intensive needs"), **dosage** ("the number of opportunities the student has to respond and receive feedback from the teacher"), **alignment** ("how well the intervention matches the targeted academic skills"), **attention to transfer**, **comprehensiveness** (explicit-instruction principles), **behavioral or academic support**, and **individualization** ("the ongoing use of progress monitoring data and other diagnostic data sources" to adjust). Note NCII's dosage is opportunities to respond, not minutes; minutes, sessions per week and group size are the usual proxies.
*Here:* `dosage`, `group_size`, `weeks`, `deliverer_role` are the proxies; strength lives in `tool.notes`.

**Intensive intervention.** NCII: "the most intense level of intervention and also may be known as Tier 3." For students "with severe and persistent learning and behavioral needs," including those "not making adequate progress in their current intervention program (often, a Tier 2, evidence-based intervention)." Characterized by "increased intensity and individualization." NCII's approach to it is DBI.
*Here:* not yet modelled; `tier = 3` rows would hold it, and the `iep` status and route exist for students whose plan governs.

**Data-based individualization (DBI).** NCII: "a research-based process for individualizing and intensifying interventions through the systematic use of assessment data, validated interventions, and research-based adaptation strategies." "A process, not a specific program or product." Five steps: validated intervention program; progress monitoring; diagnostic assessment; intervention adaptation; continued progress monitoring.
*Here:* the five steps are, in order, `program_id`, `pm_*`, `placement_tool_id`/profile, `review_rule`, and the loop back.

**Intervention adaptation.** DBI Step 4: changing the validated program (dosage, group size, explicitness, content focus) when progress monitoring shows the student is not responding, using "research-based adaptation strategies."
*Here:* "4 below -> change" and what follows it; `review_rule`.

**Responsiveness and non-response.** Whether the student's progress monitoring data reach the goal line. NCII's phrase for the population interventions serve is students "whose performance is nonresponsive to the core procedures," and intensive intervention is for those not responding to Tier 2. Non-response is a data finding, not a trait.
*Here:* `exit_rule` defines response; `next_step_id` and `nonresponse_id` say where each leads.

**Fidelity.** Delivering the program and the assessments as designed. NCII treats "the quality and fidelity of Tier 1 and Tier 2 supports" as the foundation DBI stands on, and publishes fidelity tools. A decision rule applied inconsistently is a fidelity problem.
*Here:* not stored; `deliverer_role` and `tool.notes` ("training") are the nearest things.

## Tiers

**Multi-tiered system of supports (MTSS).** NCII: "a well-functioning tiered system of support, commonly called a multi-tiered system of supports (MTSS)," also known as RTI or PBIS. Core for all (Tier 1), targeted intervention for some (Tier 2), intensive individualized intervention for few (Tier 3, "only about 3 to 5 percent of a school's population" in NCII's partner schools). Carlisle's name for it is CSS.

**Tier 1.** Core instruction for every student, plus universal screening. NCII does not define Tier 1 itself; it describes it as the foundation whose "quality and fidelity" must be solid before intervention is layered on.
*Here:* the `tier = 1` row with profile `-`. Its intervention entry rule is the *flag* rule: what moves a student out of ordinary Tier 1 toward intervention. Every student is in Tier 1; nobody "enters" it.

**Tier 2.** Targeted, usually small-group, evidence-based intervention in addition to core, for students the screen flagged. NCII's reference point for Tier 2 is "a Tier 2, evidence-based intervention" that a student is "not making adequate progress in" before intensive intervention is considered.
*Here:* `tier = 2` rows, one per profile.

**Tier 3.** See *intensive intervention*.

**Second stage (multi-gated screening).** Not an NCII term. This project's name for a short confirmation period after the screen: the flagged student stays in core while a probe is given three times over six weeks; a rising slope clears the flag, a flat one confirms it, and the probe's error pattern sorts the student into a profile. The idea comes from Fuchs & Fuchs (2017) and Vaughn & Fletcher (2012); NCII's note that screening tools are not fully accurate, so schools "often confirm risk status using additional data," is the same point. NCII's name for this kind of design is a multi-gated or two-stage screening process.
*Here:* the Tier 1 `pm_rule`. Every teacher interviewed so far answered "no second look; the screen alone decides."

## Sources

- NCII, *Data-Based Individualization*, https://intensiveintervention.org/data-based-individualization
- NCII, *Intensive Intervention*, https://intensiveintervention.org/intensive-intervention
- NCII, *Intensive Intervention & MTSS*, https://intensiveintervention.org/special-topics/mtss
- NCII, *Progress Monitoring: Data & Goal Setting*, https://intensiveintervention.org/data-based-individualization/progress-monitoring
- NCII, *Types of Student Assessment*, https://intensiveintervention.org/tools-charts/identifying-assessments
- NCII, *Tools Charts Overview*, https://intensiveintervention.org/tools-charts/overview
- NCII, *Tool Chart Users Guide* (2019), https://intensiveintervention.org/sites/default/files/Tools_Chart_User_Guide-508.pdf
- NCII, *Academic Screening Tools Chart* and *Academic Progress Monitoring Tools Chart* (rating rubrics), https://charts.intensiveintervention.org/ascreening and https://charts.intensiveintervention.org/aprogressmonitoring
- NCII, *What Is Progress Monitoring: A Note-Taking Guide* (2024), https://intensiveintervention.org/sites/default/files/2024-11/WhatProgrssMontr-NoteTaking-Fillable-508.pdf
- NCII, *Strategies for Setting High-Quality Academic IEP Goals* (glossary), https://intensiveintervention.org/sites/default/files/NCII-SetAcademicIEPGoals508.pdf
- NCII, *Taxonomy of Intervention Intensity*, https://intensiveintervention.org/taxonomy-intervention-intensity
- NCII, *Screening Standards Overviews*, https://intensiveintervention.org/resource/screening-standards-overviews
