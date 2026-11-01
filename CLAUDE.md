# css-implementation

Database and (eventually) web form for Carlisle Public Schools' CSS / MTSS tier definitions. Owner: Brad Cranston (7th grade science, CSS steering committee, Group 1 "Define the Tiers").

Read `docs/SCHEMA.md` first. It explains the one idea (a protocol row is area × tier × profile) and why the tables are shaped the way they are.

## Layout

- `db/schema.sql` — SQLite DDL, v0.15. Includes sentinel rows (`area '-'`, `profile '-'`). v0.3 adds `teacher`/`basis` scoping so one area can hold the defined rule plus each teacher's observed practice. v0.4–v0.6 add `ncii_screening`, `ncii_pm` and `ncii_intervention` (NCII tools-chart ratings, one row per chart row; intervention rows are per study; no row = not on the chart). v0.8 adds `tool_evidence` (what each reviewer found, including "not listed"). v0.9–v0.10 add `dimension` (NCII's three checklists: PM dimensions, screening skills, intervention areas of focus; `chart`, `grp`) and `tool_dimension`, keyed by measure (`'-'` = whole tool). v0.11 separates who says what: `tool_profile` (the vendor's product claims, in NCII's field names, also filled from publishers for Just Words and Bridges) and `measure` (the vendor's per-instrument claims; `ncii_screening`, `ncii_pm` and `tool_dimension` reference it) hold the vendor side; the `ncii_*` tables hold only NCII's findings plus, for interventions, each study's own facts as run. v0.12 adds `instructor` (the people: `profile.teacher` and `protocol.teacher` reference it, `'-'` is the sentinel) and `instructor_tool` (their training); `protocol.deliverer_id` names the person when there is one. v0.13 adds `protocol.instruction` (prose: what the instruction looks like). v0.14 renames roles to `tutor` and `literacy specialist` and moves the instructor's subject to `instructor_subject` (a tutor covers both). v0.15 scopes `area_screener` to a teacher (`'-'` = the area's rule) so the Observed tab shows each teacher's screeners as rows.
- `db/migrations/` — dated SQL files, one per change to the live database (schema changes and interview content). Apply by hand: `ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db' < db/migrations/<file>.sql`. Schema changes also go into `db/schema.sql`; content does not go into `db/seed.sql`.
- `db/seed.sql` — four areas of real content. `proposed` rows are design proposals, `doc` rows come from district documents.
- `db/queries.sql` — the ten queries the app must answer. Q5 is the per-area page (bound to area + teacher). Q9/Q10 are the teacher-variance view.
- `docs/SCHEMA.md` — design doc and review history.
- `build_db.py` — rebuilds `css.db` from schema + seed (replaces the file).
- `app.py`, `templates/`, `static/` — Flask app. Read view: `/` lists areas, `/area/<id>` is Q5 as one table per tier, one column per profile, defined rows then each teacher's observed rows; `/tool/<id>` is one tool: the vendor's profile and measures, its licenses, where it is used, NCII's checklists, and its rows from the three NCII tools charts (tool names link to it). `/instructors` lists the people, `/instructor/<id>` is one person: who they are, training, their observed rows and the rows that name them as deliverer. Edit: `/area/<id>/new` and `/protocol/<id>/edit` (the form follows the tier: a Tier 1 row also edits that teacher's screener rows, and a screening row can name a new tool, which is created with just its name), `/instructors/new` and `/instructor/<id>/edit` (the person and their training rows in one form), and `/area/<id>/screening/<teacher>` (all of one area × teacher's screener rows in one form), behind a shared password.

## Build and run

```
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python build_db.py
.venv/bin/flask --app app run --port 5055 --debug
```
`build_db.py` is equivalent to `sqlite3 css.db < db/schema.sql && sqlite3 css.db < db/seed.sql`. Foreign keys are on; schema loads before seed. It replaces `css.db`, so don't run it on a database the committee has edited.

Environment variables: `CSS_DB` (path to the database, default `css.db` next to `app.py`), `CSS_PASSWORD` (the shared committee password; editing is disabled and the site is read-only when unset), `CSS_SECRET` (session secret; when unset one is generated into `.secret`, gitignored). See `.env.example`.

## Production deployment (pinto)

Live at **<https://css-tiers.938752.xyz>** since 2026-10-27. Runs on Brad's Raspberry Pi `pinto` (`bcransto@pinto` over Tailscale; the first SSH from a new session may ask for a browser check), same pattern as Blue Book and grocery-shopper: a systemd service on a localhost port, HTTPS terminated by the existing Cloudflare Tunnel, no reverse proxy on the Pi, code pulled from GitHub.

- **Code.** GitHub `bcransto/css-implementation` (private). From the Mac, push over HTTPS; SSH pushes often fail here because of the 1Password agent, so `origin` is the HTTPS URL with `gh` as the credential helper. The Pi pulls with a read-only deploy key through the alias `github-css-implementation` in its `~/.ssh/config`, so its remote is `github-css-implementation:bcransto/css-implementation.git`. Don't "fix" that URL.

- **Process.** systemd unit `css-tiers` ([deploy/css-tiers.service](deploy/css-tiers.service)) runs gunicorn from `/home/bcransto/css-implementation/.venv` on `127.0.0.1:4004` (3030 is Blue Book, 4000–4003 are Curriculum Map, gdocs-mcp and grocery-deals).
- **Secrets.** `/home/bcransto/css-implementation/.env`, chmod 600, gitignored, loaded by the unit. Template: `.env.example`.
- **Database.** `/home/bcransto/css-implementation/css.db` is the source of truth, edited through the form or by SQL over SSH. `db/seed.sql` is the 2026-10-27 starting content only and is **not** kept in sync with live edits (Brad's call, 2026-10-27); never rerun `build_db.py` on the Pi. Restore from `~/backups/` if needed.
- **Backups.** [deploy/backup.sh](deploy/backup.sh) from the `bcransto` crontab at 1:50 AM, keeps 3 snapshots in `~/backups/`; ranchero rsyncs the home directory at 2:00 AM. Don't move the job past 2:00.
- **Ingress.** The Cloudflare Tunnel `pinto-apps-tunnel` is dashboard-managed (cloudflared runs with a token; no config file on the Pi). Its route `css-tiers.938752.xyz` is a Published application pointing at `http://localhost:4004` (plain http: gunicorn has no TLS). Changes are made in Cloudflare One → Networks → Tunnels → Add route.
- **The committee password** is only in the Pi's `.env`: `ssh bcransto@pinto 'grep CSS_PASSWORD ~/css-implementation/.env'`. Change it there and `sudo systemctl restart css-tiers`.

```bash
# first install, on the Pi
git clone github-css-implementation:bcransto/css-implementation.git ~/css-implementation && cd ~/css-implementation
python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt
cp .env.example .env && chmod 600 .env   # then fill in CSS_PASSWORD and CSS_SECRET
.venv/bin/python build_db.py
sudo cp deploy/css-tiers.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now css-tiers
( crontab -l 2>/dev/null; echo "50 1 * * * /home/bcransto/css-implementation/deploy/backup.sh" ) | crontab -

# every later change, from the Mac
git push && deploy/deploy.sh

# logs / database on the Pi
ssh bcransto@pinto 'sudo journalctl -u css-tiers -f'
ssh bcransto@pinto 'sqlite3 ~/css-implementation/css.db'
```

## Stack

SQLite + Flask + gunicorn. Read view and the `protocol` edit form are done. The form has `<select>` inputs for every `_id` column and textareas for rules. Hard errors (block the save): missing status, profile whose teacher differs from the row's teacher, duplicate area/tier/profile/teacher, bad id. Soft warnings (shown, never block): a tool with no `tool_license` row covering the area's grades (the Q1 budget list), a dosage or group size outside the vendor's minimums on `tool_profile`, and a citation token that is not a `source` id. Blank fields are stored as NULL. Not built: delete, and editing of any table other than `protocol`, `area_screener`, `instructor`, `instructor_subject` and `instructor_tool`, plus creating a `tool` by name from a screening row (`tool_profile`, `measure`, profiles, routes, `area_core` and the `ncii_*` tables change by SQL on pinto, recorded in `db/migrations/`).

## Rules

- Never put real student data in `student_example` or anywhere else here.
- `tool_license` absence means not owned; don't add an `owned` boolean back.
- Keep `profile_id` and `teacher` non-null (`'-'` for whole-class / area-level rows) or the UNIQUE constraint stops working.
- Don't reintroduce per-field status or citation tables; prose columns were chosen on purpose after review.
