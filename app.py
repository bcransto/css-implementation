"""CSS tier-definition database: read view plus a password-gated edit form.

Routes:
  /                      every area, with its core, screeners and row counts
  /area/<id>             Q5 for one area: one table per tier, one column per profile;
                         defined rows first, then each teacher's observed rows
  /tool/<id>             one tool: licenses, where it is used, NCII screening, PM and intervention chart ratings
  /login, /logout        shared committee password (env CSS_PASSWORD)
  /area/<id>/new         create a protocol row            (login required)
  /protocol/<id>/edit    edit a protocol row              (login required)

Environment:
  CSS_DB        path to css.db (default: next to this file)
  CSS_PASSWORD  the shared password; editing is disabled when unset
  CSS_SECRET    Flask session secret; when unset, one is generated into .secret (gitignored)
"""
import hmac
import os
import re
import secrets
import sqlite3
from collections import OrderedDict
from functools import wraps

from flask import (Flask, abort, flash, g, redirect, render_template, request,
                   session, url_for)
from markupsafe import Markup, escape

HERE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.environ.get("CSS_DB", os.path.join(HERE, "css.db"))

app = Flask(__name__)


def secret_key():
    """CSS_SECRET if set; otherwise a key generated once and kept in .secret next to this file."""
    if os.environ.get("CSS_SECRET"):
        return os.environ["CSS_SECRET"]
    path = os.path.join(HERE, ".secret")
    try:
        with open(path, encoding="utf-8") as f:
            key = f.read().strip()
            if key:
                return key
    except FileNotFoundError:
        pass
    key = secrets.token_hex(32)
    with open(path, "w", encoding="utf-8") as f:
        f.write(key)
    os.chmod(path, 0o600)
    return key


app.secret_key = secret_key()

# protocol fields in page order: (column, label)
FIELDS = [
    ("entry_rule", "Intervention entry rule"),
    ("placement", "Placement test"),
    ("program", "Program"),
    ("deliverer_role", "Delivered by"),
    ("dosage", "Dosage"),
    ("group_size", "Group size"),
    ("weeks", "Weeks"),
    ("pm_tool", "PM tool"),
    ("pm_metric", "PM metric"),
    ("pm_rule", "PM rule"),
    ("review_rule", "Review"),
    ("exit_rule", "Exit rule"),
    ("next_step", "On response"),
    ("nonresponse", "On non-response"),
    ("citations", "Citations"),
]

STATUSES = ["doc", "unwritten", "proposed", "iep"]
BASES = ["defined", "observed"]
TOOL_COLS = [("placement_tool_id", "Placement test"), ("program_id", "Program"), ("pm_tool_id", "PM tool")]
# every editable column of protocol except id and area_id
EDIT_COLS = [
    "tier", "profile_id", "teacher", "basis", "as_of", "evidence", "deliverer_role",
    "placement_tool_id", "program_id", "pm_tool_id", "pm_metric", "entry_rule",
    "dosage", "group_size", "weeks", "pm_rule", "review_rule", "exit_rule",
    "next_step_id", "nonresponse_id", "status", "status_note", "citations",
]
ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")


# ---------------------------------------------------------------- db helpers

def db():
    if "db" not in g:
        con = sqlite3.connect(DB_PATH)
        con.execute("PRAGMA foreign_keys = ON")
        con.row_factory = sqlite3.Row
        con.create_function("grade_span", 2, grade_span)
        g.db = con
    return g.db


@app.teardown_appcontext
def close_db(_exc):
    con = g.pop("db", None)
    if con is not None:
        con.close()


def grade(n):
    return "K" if n == 0 else str(n)


def grade_span(lo, hi):
    return grade(lo) if lo == hi else f"{grade(lo)}–{grade(hi)}"


app.jinja_env.filters["grade_span"] = grade_span


def tier_label(tier):
    return "Outside the tiers" if tier is None else f"Tier {tier}"


def route_label(kind, tier):
    if kind is None:
        return None
    if kind == "tier":
        return f"Tier {tier}"
    return {
        "tier1_plan": "Tier 1 with a plan",
        "slp": "SLP",
        "cst": "CST",
        "sped_eval": "Sped evaluation",
        "iep": "IEP",
        "carry": "Carries over",
        "external": "External",
        "none": "None",
    }.get(kind, kind)


app.jinja_env.globals["route_label"] = route_label

# NCII tools-chart ratings: symbol and legend text for each value of a rating column
NCII_RATINGS = OrderedDict([
    ("convincing", ("●", "Convincing evidence")),
    ("partial", ("◐", "Partially convincing evidence")),
    ("unconvincing", ("○", "Unconvincing evidence")),
    ("unavailable", ("–", "Data unavailable")),
])
NCII_SCREENING_URL = "https://charts.intensiveintervention.org/ascreening"
NCII_PM_URL = "https://charts.intensiveintervention.org/aprogressmonitoring"
NCII_INTERVENTION_URL = "https://charts.intensiveintervention.org/aintervention"


def bubble(rating, disaggregated=0):
    """One NCII rating as a <span class="bubble">; '' when not entered. d = disaggregated data available."""
    if rating is None:
        return Markup('<span class="bubble none" title="not entered"></span>')
    if rating == "na":
        return Markup('<span class="bubble unavailable" title="Not applicable">NA</span>')
    sym, label = NCII_RATINGS.get(rating, ("?", rating))
    d = '<sup title="Disaggregated data available">d</sup>' if disaggregated else ""
    return Markup(f'<span class="bubble {escape(rating)}" title="{escape(label)}">{sym}{d}</span>')


app.jinja_env.globals["bubble"] = bubble
app.jinja_env.globals["NCII_RATINGS"] = NCII_RATINGS
app.jinja_env.globals["NCII_SCREENING_URL"] = NCII_SCREENING_URL
app.jinja_env.globals["NCII_PM_URL"] = NCII_PM_URL
app.jinja_env.globals["NCII_INTERVENTION_URL"] = NCII_INTERVENTION_URL


# ---------------------------------------------------------------- auth

def editing_enabled():
    return bool(os.environ.get("CSS_PASSWORD"))


def logged_in():
    return editing_enabled() and session.get("ok") is True


app.jinja_env.globals["logged_in"] = logged_in
app.jinja_env.globals["editing_enabled"] = editing_enabled


def login_required(view):
    @wraps(view)
    def wrapped(*a, **kw):
        if not editing_enabled():
            flash("Editing is disabled: CSS_PASSWORD is not set on the server.", "error")
            return redirect(url_for("index"))
        if not logged_in():
            return redirect(url_for("login", next=request.path))
        return view(*a, **kw)
    return wrapped


@app.route("/login", methods=["GET", "POST"])
def login():
    if not editing_enabled():
        flash("Editing is disabled: CSS_PASSWORD is not set on the server.", "error")
        return redirect(url_for("index"))
    if request.method == "POST":
        given = request.form.get("password", "")
        if hmac.compare_digest(given.encode(), os.environ["CSS_PASSWORD"].encode()):
            session["ok"] = True
            nxt = request.form.get("next") or url_for("index")
            if not nxt.startswith("/"):
                nxt = url_for("index")
            return redirect(nxt)
        flash("Wrong password.", "error")
    return render_template("login.html", next=request.args.get("next", ""))


@app.route("/logout", methods=["POST"])
def logout():
    session.clear()
    return redirect(url_for("index"))


# ---------------------------------------------------------------- read view

Q5_ALL_TEACHERS = """
SELECT p.id, p.tier, p.teacher, p.basis, p.as_of, p.evidence,
       pr.name AS profile, pr.sort_rule,
       pl.name AS placement, pl.notes AS placement_notes, p.placement_tool_id AS placement_id,
       pg.name AS program,   pg.notes AS program_notes,   p.program_id,
       pg.minutes AS design_minutes, pg.min_per_week AS design_per_week, pg.max_group AS design_max_group,
       pm.name AS pm_tool,   pm.notes AS pm_tool_notes,   p.pm_tool_id AS pm_tool_id,
       p.pm_metric, p.entry_rule, p.deliverer_role, p.dosage, p.group_size, p.weeks,
       p.pm_rule, p.review_rule, p.exit_rule,
       nx.kind AS next_kind, nx.tier AS next_tier, nx.description AS next_desc,
       nr.kind AS nr_kind,   nr.tier AS nr_tier,   nr.description AS nr_desc,
       p.status, p.status_note, p.citations
FROM protocol p
JOIN profile pr ON pr.id = p.profile_id
LEFT JOIN tool pl ON pl.id = p.placement_tool_id
LEFT JOIN tool pg ON pg.id = p.program_id
LEFT JOIN tool pm ON pm.id = p.pm_tool_id
LEFT JOIN route nx ON nx.id = p.next_step_id
LEFT JOIN route nr ON nr.id = p.nonresponse_id
WHERE p.area_id = ?
ORDER BY (p.teacher <> '-'), p.teacher, (p.tier IS NULL), p.tier, (pr.id <> '-'), pr.name
"""


DOSE_RE = re.compile(r"(\d+)(?:\s*-\s*\d+)?\s*[x×]\s*(\d+)", re.I)


def parse_dosage(text):
    """'3 x 45 FLEX' -> (3, 45); '3-5 x 20-40' -> (3, 20) (the low end); 'daily block' -> (5, None)."""
    if not text:
        return None, None
    m = DOSE_RE.search(text)
    if m:
        return int(m.group(1)), int(m.group(2))
    if "daily" in text.lower():
        return 5, None
    return None, None


def parse_group(text):
    """'about 4' -> 4; '4-5' -> 5 (the high end); 'class' -> None."""
    if not text:
        return None
    nums = [int(n) for n in re.findall(r"\d+", text)]
    return max(nums) if nums else None


def design_check(dosage, group_size, minutes, per_week, max_group):
    """Where a protocol's dose or group falls short of the program's design. Only compares what both sides state."""
    out = []
    pw, mins = parse_dosage(dosage)
    if mins is not None and minutes is not None and mins < minutes:
        out.append(f"{mins} min per session; the program's design minimum is {minutes}")
    if pw is not None and per_week is not None and pw < per_week:
        out.append(f"{pw} sessions a week; the design minimum is {per_week}")
    g = parse_group(group_size)
    if g is not None and max_group is not None and g > max_group:
        out.append(f"group of {g}; the design allows at most {max_group}")
    return out


def cell(row, col):
    """Return {text, note, tool_id} for one field of one protocol. tool_id is set for tool columns."""
    if col == "next_step":
        return {"text": route_label(row["next_kind"], row["next_tier"]), "note": row["next_desc"]}
    if col == "nonresponse":
        return {"text": route_label(row["nr_kind"], row["nr_tier"]), "note": row["nr_desc"]}
    if col in ("placement", "program", "pm_tool"):
        return {"text": row[col], "note": row[col + "_notes"], "tool_id": row[col + "_id"]}
    return {"text": row[col], "note": None}


def group_protocols(rows):
    """-> OrderedDict teacher -> OrderedDict tier -> [column dicts]"""
    by_teacher = OrderedDict()
    for r in rows:
        tiers = by_teacher.setdefault(r["teacher"], OrderedDict())
        cols = tiers.setdefault(r["tier"], [])
        cols.append({
            "id": r["id"],
            "profile": r["profile"],
            "sort_rule": r["sort_rule"],
            "status": r["status"],
            "status_note": r["status_note"],
            "basis": r["basis"],
            "as_of": r["as_of"],
            "evidence": r["evidence"],
            "cells": {col: cell(r, col) for col, _ in FIELDS},
        })
        warns = design_check(r["dosage"], r["group_size"], r["design_minutes"], r["design_per_week"], r["design_max_group"])
        for w in warns:
            key = "group_size" if w.startswith("group") else "dosage"
            cols[-1]["cells"][key]["warn"] = w
    return by_teacher


@app.route("/")
def index():
    con = db()
    areas = con.execute(
        """SELECT a.*,
                  (SELECT count(*) FROM protocol p WHERE p.area_id = a.id AND p.teacher = '-') AS defined_rows,
                  (SELECT count(DISTINCT teacher) FROM protocol p WHERE p.area_id = a.id AND p.teacher <> '-') AS teachers,
                  (SELECT group_concat(t.name, ', ') FROM area_core c JOIN tool t ON t.id = c.tool_id
                     WHERE c.area_id = a.id) AS cores,
                  (SELECT group_concat(DISTINCT t.name) FROM area_screener s JOIN tool t ON t.id = s.tool_id
                     WHERE s.area_id = a.id AND s.role = 'screen') AS screeners
           FROM area a WHERE a.id <> '-'
           ORDER BY a.grade_lo, a.subject"""
    ).fetchall()
    status_counts = con.execute(
        "SELECT status, count(*) AS n FROM protocol WHERE teacher = '-' GROUP BY status"
    ).fetchall()
    return render_template("index.html", areas=areas, status_counts=status_counts)


def all_areas(con):
    return con.execute(
        "SELECT id, subject, grade_lo, grade_hi FROM area WHERE id <> '-' ORDER BY grade_lo, subject"
    ).fetchall()


@app.route("/area/<area_id>")
def area(area_id):
    con = db()
    a = con.execute("SELECT * FROM area WHERE id = ? AND id <> '-'", (area_id,)).fetchone()
    if a is None:
        abort(404)
    cores = con.execute(
        """SELECT t.id AS tool_id, t.name, c.role, c.status FROM area_core c JOIN tool t ON t.id = c.tool_id
           WHERE c.area_id = ? ORDER BY c.role""", (area_id,)).fetchall()
    screeners = [dict(r) for r in con.execute(
        """SELECT t.id AS tool_id, t.name, s.grade_lo, s.grade_hi, s.windows, s.role, s.cut, s.status
           FROM area_screener s JOIN tool t ON t.id = s.tool_id
           WHERE s.area_id = ?
           ORDER BY CASE s.role WHEN 'screen' THEN 0 WHEN 'level_check' THEN 1 ELSE 2 END, s.grade_lo, t.name""",
        (area_id,))]
    for s in screeners:  # NCII screening-chart rows for this tool at this screener's grades (Q11)
        s["ncii"] = con.execute(
            """SELECT measure, grade, ca_fall, ca_winter, ca_spring, ca_fall_d, ca_winter_d, ca_spring_d
               FROM ncii_screening WHERE tool_id = ? AND grade BETWEEN ? AND ? ORDER BY measure, grade""",
            (s["tool_id"], s["grade_lo"], s["grade_hi"])).fetchall()
    rows = con.execute(Q5_ALL_TEACHERS, (area_id,)).fetchall()
    # NCII progress-monitoring rows for each PM tool the protocols use, at this area's grades (Q12)
    pm_ncii = {}
    for tid in {r["pm_tool_id"] for r in rows if r["pm_tool_id"]}:
        pm_ncii[tid] = con.execute(
            """SELECT measure, grade, measure_type, slope_reliability, slope_validity, alt_forms
               FROM ncii_pm WHERE tool_id = ? AND grade BETWEEN ? AND ? ORDER BY measure, grade, measure_type""",
            (tid, a["grade_lo"], a["grade_hi"])).fetchall()
    # NCII intervention studies for each program the protocols use (Q13; studies are not grade-bound)
    prog_ncii = {}
    for tid in {r["program_id"] for r in rows if r["program_id"]}:
        prog_ncii[tid] = con.execute(
            """SELECT study, design, targeted_measures, broader_measures, es_targeted, es_broader
               FROM ncii_intervention WHERE tool_id = ? ORDER BY study""", (tid,)).fetchall()
    examples = con.execute(
        """SELECT e.student_key, e.protocol_id, e.timeline, pr.name AS profile, p.tier
           FROM student_example e JOIN protocol p ON p.id = e.protocol_id
           JOIN profile pr ON pr.id = p.profile_id
           WHERE p.area_id = ? ORDER BY e.student_key""", (area_id,)).fetchall()
    return render_template(
        "area.html",
        area=a, cores=cores, screeners=screeners, examples=examples, all_areas=all_areas(con),
        by_teacher=group_protocols(rows), fields=FIELDS, tier_label=tier_label, pm_ncii=pm_ncii, prog_ncii=prog_ncii,
    )


@app.route("/tool/<tool_id>")
def tool(tool_id):
    con = db()
    t = con.execute("SELECT * FROM tool WHERE id = ?", (tool_id,)).fetchone()
    if t is None:
        abort(404)
    licenses = con.execute(
        "SELECT grade_lo, grade_hi, note FROM tool_license WHERE tool_id = ? ORDER BY grade_lo", (tool_id,)).fetchall()
    # where the tool is used (Q7): cores, screeners, and the three protocol columns
    uses = con.execute(
        """SELECT 'core' AS role, c.area_id, c.role AS detail, NULL AS teacher, NULL AS tier, NULL AS profile
           FROM area_core c WHERE c.tool_id = :t
           UNION ALL
           SELECT 'screener: ' || replace(s.role, '_', ' '), s.area_id,
                  grade_span(s.grade_lo, s.grade_hi) || coalesce(', ' || s.windows, ''), NULL, NULL, NULL
           FROM area_screener s WHERE s.tool_id = :t
           UNION ALL
           SELECT CASE WHEN p.placement_tool_id = :t THEN 'placement test'
                       WHEN p.program_id = :t THEN 'program' ELSE 'PM tool' END,
                  p.area_id, p.id, p.teacher, p.tier, pr.name
           FROM protocol p JOIN profile pr ON pr.id = p.profile_id
           WHERE :t IN (p.placement_tool_id, p.program_id, p.pm_tool_id)
           ORDER BY 2, 4, 5, 1""", {"t": tool_id}).fetchall()
    ncii = con.execute(
        "SELECT * FROM ncii_screening WHERE tool_id = ? ORDER BY measure, grade", (tool_id,)).fetchall()
    ncii_pm = con.execute(
        "SELECT * FROM ncii_pm WHERE tool_id = ? ORDER BY measure, grade, measure_type", (tool_id,)).fetchall()
    ncii_iv = con.execute(
        "SELECT * FROM ncii_intervention WHERE tool_id = ? ORDER BY study", (tool_id,)).fetchall()
    evidence = con.execute(
        "SELECT * FROM tool_evidence WHERE tool_id = ? ORDER BY source, finding", (tool_id,)).fetchall()
    # NCII's dimension list with this tool's selections marked; grouped by subject in NCII's order
    dims = con.execute(
        """SELECT d.subject, d.name, (td.tool_id IS NOT NULL) AS selected, td.source
           FROM dimension d LEFT JOIN tool_dimension td ON td.dimension_id = d.id AND td.tool_id = ?
           ORDER BY d.sort""", (tool_id,)).fetchall()
    dimensions = OrderedDict()
    for d in dims:
        dimensions.setdefault(d["subject"], []).append(d)
    has_dims = any(d["selected"] for d in dims)
    return render_template("tool.html", tool=t, licenses=licenses, uses=uses, ncii=ncii, ncii_pm=ncii_pm,
                           ncii_iv=ncii_iv, evidence=evidence, dimensions=dimensions, has_dims=has_dims,
                           all_areas=all_areas(con), tier_label=tier_label)


# ---------------------------------------------------------------- edit form

def form_choices(con, area_id):
    return {
        "profiles": con.execute(
            "SELECT id, name, teacher, basis FROM profile WHERE area_id = ? OR id = '-' "
            "ORDER BY (id <> '-'), teacher, name", (area_id,)).fetchall(),
        "tools": con.execute("SELECT id, name FROM tool ORDER BY name").fetchall(),
        "routes": con.execute("SELECT id, kind, tier, description FROM route ORDER BY id").fetchall(),
        "statuses": STATUSES,
        "bases": BASES,
    }


def read_form():
    """Form -> dict of column values. Blank strings become NULL; teacher defaults to '-'."""
    vals = {}
    for col in EDIT_COLS:
        v = request.form.get(col, "")
        v = v.strip() if isinstance(v, str) else v
        vals[col] = v or None
    if vals["tier"] is not None:
        try:
            vals["tier"] = int(vals["tier"])
        except ValueError:
            vals["tier"] = None
    vals["teacher"] = vals["teacher"] or "-"
    vals["profile_id"] = vals["profile_id"] or "-"
    vals["basis"] = vals["basis"] or "defined"
    return vals


def hard_errors(con, vals):
    """Things that must be fixed before saving."""
    errs = []
    if vals["status"] not in STATUSES:
        errs.append("Status is required.")
    if vals["basis"] not in BASES:
        errs.append("Basis must be defined or observed.")
    prof = con.execute("SELECT teacher FROM profile WHERE id = ?", (vals["profile_id"],)).fetchone()
    if prof is None:
        errs.append("Profile does not exist.")
    elif vals["profile_id"] != "-" and prof["teacher"] != vals["teacher"]:
        errs.append(f"Profile belongs to teacher '{prof['teacher']}' but this row is for '{vals['teacher']}'.")
    return errs


def soft_warnings(con, area_id, vals):
    """The design doc's soft checks: license coverage and citation ids. Never block a save."""
    warns = []
    a = con.execute("SELECT grade_lo, grade_hi FROM area WHERE id = ?", (area_id,)).fetchone()
    for col, label in TOOL_COLS:
        tid = vals.get(col)
        if not tid:
            continue
        covered = con.execute(
            "SELECT 1 FROM tool_license WHERE tool_id = ? AND grade_lo <= ? AND grade_hi >= ?",
            (tid, a["grade_lo"], a["grade_hi"])).fetchone()
        if not covered:
            lic = con.execute(
                "SELECT grade_lo, grade_hi FROM tool_license WHERE tool_id = ? ORDER BY grade_lo",
                (tid,)).fetchall()
            lic = ", ".join(grade_span(r["grade_lo"], r["grade_hi"]) for r in lic)
            name = con.execute("SELECT name FROM tool WHERE id = ?", (tid,)).fetchone()["name"]
            where = f"licensed for grades {lic}" if lic else "not owned"
            warns.append(f"{label} {name} is {where}; this area is grades "
                         f"{grade_span(a['grade_lo'], a['grade_hi'])}. (Q1 budget list)")
    if vals.get("program_id"):
        d = con.execute("SELECT name, minutes, min_per_week, max_group FROM tool WHERE id = ?",
                        (vals["program_id"],)).fetchone()
        if d:
            for w in design_check(vals.get("dosage"), vals.get("group_size"), d["minutes"], d["min_per_week"], d["max_group"]):
                warns.append(f"{d['name']}: {w}.")
    if vals.get("citations"):
        known = {r["id"] for r in con.execute("SELECT id FROM source")}
        for part in vals["citations"].split(";"):
            tok = part.strip().split(" ")[0] if part.strip() else ""
            if tok and tok not in known:
                warns.append(f"Citation '{tok}' is not a source id. Known: {', '.join(sorted(known))}.")
    return warns


def render_form(con, a, vals, protocol_id=None, errors=(), warnings=()):
    return render_template(
        "edit.html", area=a, vals=vals, protocol_id=protocol_id, errors=errors, warnings=warnings,
        all_areas=all_areas(con), **form_choices(con, a["id"]))


@app.route("/area/<area_id>/new", methods=["GET", "POST"])
@login_required
def protocol_new(area_id):
    con = db()
    a = con.execute("SELECT * FROM area WHERE id = ? AND id <> '-'", (area_id,)).fetchone()
    if a is None:
        abort(404)
    if request.method == "GET":
        vals = {c: None for c in EDIT_COLS}
        vals.update(teacher="-", profile_id="-", basis="defined", status="proposed")
        return render_form(con, a, vals)
    vals = read_form()
    new_id = (request.form.get("id") or "").strip().lower()
    errors = hard_errors(con, vals)
    if not ID_RE.match(new_id):
        errors.append("Id is required: lowercase letters, digits and hyphens, e.g. m6-t2-fact.")
    elif con.execute("SELECT 1 FROM protocol WHERE id = ?", (new_id,)).fetchone():
        errors.append(f"A protocol with id '{new_id}' already exists.")
    if errors:
        return render_form(con, a, vals, errors=errors, warnings=soft_warnings(con, area_id, vals)), 400
    cols = ["id", "area_id"] + EDIT_COLS
    try:
        con.execute(
            f"INSERT INTO protocol ({', '.join(cols)}) VALUES ({', '.join('?' * len(cols))})",
            [new_id, area_id] + [vals[c] for c in EDIT_COLS])
        con.commit()
    except sqlite3.IntegrityError as e:
        con.rollback()
        return render_form(con, a, vals, errors=[integrity_message(e)],
                           warnings=soft_warnings(con, area_id, vals)), 400
    flash_saved(new_id, soft_warnings(con, area_id, vals))
    return redirect(url_for("area", area_id=area_id))


@app.route("/protocol/<protocol_id>/edit", methods=["GET", "POST"])
@login_required
def protocol_edit(protocol_id):
    con = db()
    row = con.execute("SELECT * FROM protocol WHERE id = ?", (protocol_id,)).fetchone()
    if row is None:
        abort(404)
    a = con.execute("SELECT * FROM area WHERE id = ?", (row["area_id"],)).fetchone()
    if request.method == "GET":
        vals = {c: row[c] for c in EDIT_COLS}
        return render_form(con, a, vals, protocol_id, warnings=soft_warnings(con, a["id"], vals))
    vals = read_form()
    errors = hard_errors(con, vals)
    if errors:
        return render_form(con, a, vals, protocol_id, errors, soft_warnings(con, a["id"], vals)), 400
    try:
        con.execute(
            f"UPDATE protocol SET {', '.join(c + ' = ?' for c in EDIT_COLS)} WHERE id = ?",
            [vals[c] for c in EDIT_COLS] + [protocol_id])
        con.commit()
    except sqlite3.IntegrityError as e:
        con.rollback()
        return render_form(con, a, vals, protocol_id, [integrity_message(e)],
                           soft_warnings(con, a["id"], vals)), 400
    flash_saved(protocol_id, soft_warnings(con, a["id"], vals))
    return redirect(url_for("area", area_id=a["id"]))


def integrity_message(e):
    msg = str(e)
    if "UNIQUE" in msg:
        return "There is already a row for this area, tier, profile and teacher. Edit that row instead."
    if "FOREIGN KEY" in msg:
        return "One of the selected ids does not exist."
    return f"Could not save: {msg}"


def flash_saved(protocol_id, warnings):
    flash(f"Saved {protocol_id}.", "ok")
    for w in warnings:
        flash(w, "warn")


if __name__ == "__main__":
    app.run(debug=True, port=5055)
