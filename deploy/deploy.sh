#!/usr/bin/env bash
# Deploy a pushed commit to pinto: pull, install, restart. Run from the Mac after `git push`.
# The database is not touched; run build_db.py on the Pi only for a fresh install.
set -euo pipefail
ssh bcransto@pinto 'cd ~/css-implementation && git pull -q && .venv/bin/pip install -q -r requirements.txt && sudo systemctl restart css-tiers && sleep 1 && systemctl is-active css-tiers'
