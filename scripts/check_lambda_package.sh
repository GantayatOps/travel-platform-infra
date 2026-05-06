#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAMBDA_DIR="$ROOT_DIR/terraform/compute/lambda"
ZIP_PATH="$LAMBDA_DIR/lambda_function.zip"
SOURCE_PATH="$LAMBDA_DIR/lambda_function.py"

python3 - "$ZIP_PATH" "$SOURCE_PATH" <<'PY'
import sys
from pathlib import Path
from zipfile import BadZipFile, ZipFile

zip_path = Path(sys.argv[1])
source_path = Path(sys.argv[2])

if not zip_path.exists():
    raise SystemExit(f"{zip_path} is missing. Run scripts/package_lambda.sh")

try:
    with ZipFile(zip_path) as package:
        names = set(package.namelist())
        if "lambda_function.py" not in names:
            raise SystemExit("lambda_function.zip is missing lambda_function.py")
        if not any(name.startswith("psycopg2/") for name in names):
            raise SystemExit("lambda_function.zip is missing psycopg2 dependency files")

        packaged_source = package.read("lambda_function.py")
except BadZipFile as exc:
    raise SystemExit(f"{zip_path} is not a valid zip file: {exc}") from exc

current_source = source_path.read_bytes()
if packaged_source != current_source:
    raise SystemExit(
        "lambda_function.zip contains stale lambda_function.py. "
        "Run scripts/package_lambda.sh and commit the refreshed zip."
    )

print("Lambda package check passed")
PY
