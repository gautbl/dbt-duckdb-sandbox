#!/usr/bin/env bash
# setup.sh — (re)create the sandbox environment (MacOS / Linux).
# Run from the project root:  bash setup.sh
# Done when it ends with a `dbt --version` line naming dbt-core and dbt-duckdb.
set -euo pipefail
cd "$(dirname "$0")"

# 1. Python: 64-bit CPython 3.13, managed by uv.
if ! command -v uv &>/dev/null; then
    echo "uv not found. Install it first: https://docs.astral.sh/uv/"
    exit 1
fi
uv python install 3.13 2>/dev/null || true
uv venv --clear --python 3.13 .venv
uv pip install --python .venv/bin/python -r requirements.txt

# 2. Profile: sync the sandbox block into ~/.dbt/profiles.yml,
#    dbt's default profiles dir, so bare `dbt <cmd>` works from the
#    project root. Everything outside the marker lines is left untouched.
begin="# >>> dbt-duckdb-sandbox >>>"
end="# <<< dbt-duckdb-sandbox <<<"
profiles_dir="$HOME/.dbt"
profiles_path="$profiles_dir/profiles.yml"
mkdir -p "$profiles_dir"

block=$(cat profiles.yml)
block="$begin"$'\n'"$block"$'\n'"$end"$'\n'

existing=""
if [ -f "$profiles_path" ]; then
    existing=$(cat "$profiles_path")
fi
# Remove existing sandbox block
existing=$(printf "%s" "$existing" | perl -0777 -pe "s/(?s)# >>> dbt-duckdb-sandbox >>>.*?# <<< dbt-duckdb-sandbox <<<\n?//g" 2>/dev/null || echo "$existing" | sed -n '/# >>> dbt-duckdb-sandbox >>>/q;p')
existing="${existing%%[[:space:]]}"
if [ -n "$existing" ]; then
    existing="$existing"$'\n\n'
fi
printf "%s%s" "$existing" "$block" > "$profiles_path"

# 3. Completion check.
.venv/bin/dbt --version