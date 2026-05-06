#!/usr/bin/env python3
"""Run all 10 queries from codes.sql and print results one by one."""
import os
import re
import duckdb
from pathlib import Path

# Max characters per column so the table fits in the terminal; longer values are truncated
MAX_COL_WIDTH = 45


def format_table(cols, rows):
    """Format column headers and rows into an aligned table with fixed-width columns."""
    if not rows:
        return "\n".join("  ".join(str(c) for c in cols))
    # All cells as strings
    str_rows = [[str(x) for x in row] for row in rows]
    str_cols = [str(c) for c in cols]
    num_cols = len(cols)
    # Compute width per column: at least header length, at most MAX_COL_WIDTH
    widths = []
    for j in range(num_cols):
        col_vals = [str_cols[j]] + [r[j] for r in str_rows]
        w = min(max(len(s) for s in col_vals), MAX_COL_WIDTH)
        widths.append(max(w, 2))
    # Truncate and pad helper
    def cell(s, j):
        if len(s) > widths[j]:
            return s[: widths[j] - 3] + "..."
        return s.ljust(widths[j])

    lines = []
    lines.append("  ".join(cell(str_cols[j], j) for j in range(num_cols)))
    lines.append("-" * (sum(widths) + 2 * (num_cols - 1)))
    for row in str_rows:
        lines.append("  ".join(cell(row[j], j) for j in range(num_cols)))
    return "\n".join(lines)


def main():
    base = Path(__file__).resolve().parent
    sql_file = base / "codes.sql"
    data_dir = Path(os.environ.get("DATA_DIR", base)).expanduser().resolve()
    required_csvs = ["ADMISSIONS.csv", "TRANSFERS.csv", "CPTEVENTS.csv", "D_CPT.csv"]

    if not sql_file.exists():
        raise SystemExit("codes.sql not found")
    missing_csvs = [name for name in required_csvs if not (data_dir / name).exists()]
    if missing_csvs:
        missing_list = "\n".join(f"  - {name}" for name in missing_csvs)
        raise SystemExit(
            "Missing required private data file(s):\n"
            f"{missing_list}\n\n"
            "Place the CSVs in this folder or set DATA_DIR=/path/to/private/csvs."
        )

    # Split by "--query N" or "-- query N" (line-start comment)
    sql_text = sql_file.read_text()
    blocks = re.split(r"^\s*--\s*query\s+\d+\s*$", sql_text, flags=re.MULTILINE | re.IGNORECASE)
    # First block is empty or intro; rest are query 1..10
    queries = []
    for b in blocks[1:]:
        q = b.strip()
        if q.endswith(";"):
            q = q[:-1].strip()
        if q:
            queries.append(q)

    conn = duckdb.connect(database=":memory:")
    # CSV paths are intentionally configurable so private data can live outside Git.
    conn.execute(f"CREATE VIEW ADMISSIONS AS SELECT * FROM read_csv_auto('{data_dir / 'ADMISSIONS.csv'}')")
    conn.execute(f"CREATE VIEW TRANSFERS AS SELECT * FROM read_csv_auto('{data_dir / 'TRANSFERS.csv'}')")
    conn.execute(f"CREATE VIEW CPTEVENTS AS SELECT * FROM read_csv_auto('{data_dir / 'CPTEVENTS.csv'}')")
    conn.execute(f"CREATE VIEW D_CPT AS SELECT * FROM read_csv_auto('{data_dir / 'D_CPT.csv'}')")

    for i, sql in enumerate(queries, start=1):
        print("\n" + "=" * 60)
        print(f"QUERY {i}")
        print("=" * 60)
        try:
            result = conn.execute(sql)
            rows = result.fetchall()
            cols = [d[0] for d in result.description]
            # When > 100 rows, show at most 50 so output is readable
            display_rows = rows[:50] if len(rows) > 100 else rows
            print(format_table(cols, display_rows))
            if len(rows) > 100:
                print(f"\n(showing 50 of {len(rows)} row(s))")
            else:
                print(f"\n({len(rows)} row(s))")
        except Exception as e:
            print(f"Error: {e}")
    conn.close()
    print("\n" + "=" * 60)
    print("Done.")
    print("=" * 60)

if __name__ == "__main__":
    main()
