# AI in Healthcare - MIMIC SQL

This repository contains SQL queries and a small Python runner. The work analyzes hospital admission, transfer, and procedure-code data using DuckDB.

## Repository Contents

- `codes.sql` - ten SQL queries for the assignment analysis.
- `run_queries.py` - Python script that loads the private CSV files into DuckDB views and runs each query.
- `requirements.txt` - Python dependency list.
- `.gitignore` - excludes private data files, local environments, and generated outputs.

## Data Notice

The source CSV files are not included in this repository because they may contain proprietary or restricted healthcare data. The script expects access to the following private CSV files:

- `ADMISSIONS.csv`
- `TRANSFERS.csv`
- `CPTEVENTS.csv`
- `D_CPT.csv`

Additional data files such as `CAREGIVERS.csv`, `CALLOUT.csv`, `D_ITEMS.csv`, `D_ICD_DIAGNOSES.csv`, and `D_ICD_PROCEDURES.csv` should also remain outside Git unless your course or data license explicitly allows redistribution.

## Setup

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

## Running the Queries

If the required CSV files are in the same folder as `run_queries.py`, run:

```bash
python run_queries.py
```

If the CSV files are stored somewhere else, keep them outside the repository and set `DATA_DIR`:

```bash
DATA_DIR=/path/to/private/csvs python run_queries.py
```

The script prints each query result in order. Large result sets are truncated in the terminal for readability.

## GitHub Publishing Checklist

Add these files to GitHub:

- `README.md`
- `.gitignore`
- `requirements.txt`
- `run_queries.py`
- `codes.sql`

Do not add these files to GitHub:

- Any `*.csv` files
- Any `.duckdb`, `.db`, or `.sqlite` database files
- Any `.env` files
- Virtual environments such as `.venv/`
- Generated output folders such as `outputs/` or `results/`

Before pushing, check the staged files with:

```bash
git status --short
```

Only the code, SQL, README, dependency file, and `.gitignore` should appear as files being committed.
