"""Rebuild css.db from db/schema.sql and db/seed.sql.

Usage: python build_db.py [path/to/css.db]
Foreign keys are on; schema loads before seed. The existing file is replaced.
"""
import os
import sqlite3
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def build(db_path):
    if os.path.exists(db_path):
        os.remove(db_path)
    con = sqlite3.connect(db_path)
    con.execute("PRAGMA foreign_keys = ON")
    for name in ("schema.sql", "seed.sql"):
        with open(os.path.join(HERE, "db", name), encoding="utf-8") as f:
            con.executescript(f.read())
    con.commit()
    n = con.execute("SELECT count(*) FROM protocol").fetchone()[0]
    con.close()
    return n


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "css.db")
    print(f"built {path}: {build(path)} protocol rows")
