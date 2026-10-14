# setup.ps1 — (re)create the sandbox environment.
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File setup.ps1
# Done when it ends with a `dbt --version` line naming dbt-core and dbt-duckdb.
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

# 1. Python: 64-bit CPython 3.13, managed by uv (system 3.13 here is 32-bit —
#    no duckdb wheels for it).
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw "uv not found. Install it first: https://docs.astral.sh/uv/"
}
uv python install 3.13
uv venv --clear --python 3.13 .venv
$venvPy = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
uv pip install --python $venvPy -r requirements.txt

# 2. Profile: sync the sandbox block into %USERPROFILE%\.dbt\profiles.yml,
#    dbt's default profiles dir, so bare `dbt <cmd>` works from the project
#    root. Everything outside the marker lines is left untouched.
$begin = "# >>> dbt-duckdb-sandbox >>>"
$end   = "# <<< dbt-duckdb-sandbox <<<"
$profilesDir  = Join-Path $env:USERPROFILE ".dbt"
$profilesPath = Join-Path $profilesDir "profiles.yml"
New-Item -ItemType Directory -Force -Path $profilesDir | Out-Null

$block = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "profiles.yml")).Trim()
$block = $begin + "`n" + $block + "`n" + $end + "`n"

$existing = ""
if (Test-Path $profilesPath) { $existing = [System.IO.File]::ReadAllText($profilesPath) }
$existing = [regex]::Replace($existing, "(?s)# >>> dbt-duckdb-sandbox >>>.*?# <<< dbt-duckdb-sandbox <<<\r?\n?", "")
$existing = $existing.TrimEnd()
if ($existing) { $existing += "`n`n" }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($profilesPath, $existing + $block, $utf8NoBom)

# 3. Completion check.
& (Join-Path $PSScriptRoot ".venv\Scripts\dbt.exe") --version