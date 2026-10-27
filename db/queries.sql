-- The queries the app must be able to answer. Each has been run against seed.sql.
-- K = grade 0 throughout. :area, :tool, :grade are bound by the app.

-- Q1  Protocols that depend on a tool not licensed for the area's grades (the budget list).
SELECT p.area_id, p.id AS protocol, t.name AS tool,
       (SELECT group_concat(grade_lo||'-'||grade_hi) FROM tool_license l WHERE l.tool_id=t.id) AS licensed_grades
FROM protocol p
JOIN area a ON a.id = p.area_id
JOIN tool t ON t.id IN (p.placement_tool_id, p.program_id, p.pm_tool_id)
WHERE NOT EXISTS (SELECT 1 FROM tool_license l
                  WHERE l.tool_id = t.id AND l.grade_lo <= a.grade_lo AND l.grade_hi >= a.grade_hi)
ORDER BY 1, 2;

-- Q1b Screeners used outside their license.
SELECT s.area_id, t.name, s.grade_lo, s.grade_hi
FROM area_screener s JOIN tool t ON t.id = s.tool_id
WHERE NOT EXISTS (SELECT 1 FROM tool_license l
                  WHERE l.tool_id = t.id AND l.grade_lo <= s.grade_lo AND l.grade_hi >= s.grade_hi);

-- Q2  Protocols with no progress-monitoring tool (IEP-governed rows excluded).
SELECT id, area_id, tier, profile_id, teacher FROM protocol
WHERE pm_tool_id IS NULL AND status <> 'iep';

-- Q3  Profiles with no program, and where they route instead.
SELECT pr.area_id, pr.name AS profile, p.tier, r.kind AS route
FROM profile pr
LEFT JOIN protocol p ON p.profile_id = pr.id
LEFT JOIN route r ON r.id = p.next_step_id
WHERE pr.id <> '-' AND pr.basis = 'defined' AND (p.program_id IS NULL OR p.id IS NULL)
ORDER BY pr.area_id;

-- Q4  Rules with no citation.
SELECT id, area_id FROM protocol WHERE citations IS NULL AND status <> 'iep' AND basis = 'defined';

-- Q5  The page for one area: rows by tier, one per profile.
SELECT COALESCE(p.tier, '-') AS tier, pr.name AS profile,
       pl.name AS placement, pg.name AS program, pm.name AS pm_tool, p.pm_metric,
       p.entry_rule, p.dosage, p.group_size, p.weeks, p.pm_rule, p.review_rule, p.exit_rule,
       nx.kind AS next_step, nr.kind AS nonresponse, p.status, p.status_note, p.citations
FROM protocol p
JOIN profile pr ON pr.id = p.profile_id
LEFT JOIN tool pl ON pl.id = p.placement_tool_id
LEFT JOIN tool pg ON pg.id = p.program_id
LEFT JOIN tool pm ON pm.id = p.pm_tool_id
LEFT JOIN route nx ON nx.id = p.next_step_id
LEFT JOIN route nr ON nr.id = p.nonresponse_id
WHERE p.area_id = :area AND p.teacher = :teacher   -- '-' for the area's defined rows
ORDER BY p.tier, pr.name;

-- Q6  Areas with no core program named.
SELECT a.id, a.subject, a.grade_lo, a.grade_hi
FROM area a LEFT JOIN area_core c ON c.area_id = a.id
WHERE c.area_id IS NULL AND a.id <> '-';

-- Q6b Areas with more than one core (e.g. phonics + comprehension).
SELECT area_id, group_concat(tool_id || ':' || COALESCE(role, 'core')) AS cores
FROM area_core GROUP BY area_id HAVING count(*) > 1;

-- Q7  Every role one tool plays, across areas.
SELECT 'screener' AS role, area_id, windows AS detail FROM area_screener WHERE tool_id = :tool
UNION ALL
SELECT CASE WHEN placement_tool_id = :tool THEN 'placement'
            WHEN program_id = :tool THEN 'program' ELSE 'pm' END, area_id, pm_rule
FROM protocol WHERE :tool IN (placement_tool_id, program_id, pm_tool_id);

-- Q8  What is screened at a given grade, across areas.
SELECT s.area_id, t.name, s.windows, s.cut, s.status
FROM area_screener s JOIN tool t ON t.id = s.tool_id
WHERE s.grade_lo <= :grade AND s.grade_hi >= :grade AND s.role = 'screen';

-- Q9  Variance: how each teacher in an area currently uses a tool, next to the defined rule.
SELECT p.teacher, p.basis, p.tier, pr.name AS profile, t.name AS pm_tool, p.pm_rule, p.entry_rule, p.exit_rule
FROM protocol p
JOIN profile pr ON pr.id = p.profile_id
LEFT JOIN tool t ON t.id = p.pm_tool_id
WHERE p.area_id = :area AND p.tier = :tier
ORDER BY p.basis DESC, p.teacher;

-- Q10 How many distinct ways an area's teachers sort students (observed profile sets).
SELECT area_id, teacher, group_concat(name, ' / ') AS categories
FROM profile WHERE basis = 'observed' GROUP BY area_id, teacher;
