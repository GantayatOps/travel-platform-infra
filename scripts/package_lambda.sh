#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAMBDA_DIR="$ROOT_DIR/terraform/compute/lambda"
BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/travel-lambda.XXXXXX")
ZIP_PATH="$LAMBDA_DIR/lambda_function.zip"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

python3 -m pip install \
  --target "$BUILD_DIR" \
  --platform manylinux2014_aarch64 \
  --implementation cp \
  --python-version 3.10 \
  --only-binary=:all: \
  "psycopg2-binary==2.9.11"

cp "$LAMBDA_DIR/lambda_function.py" "$BUILD_DIR/lambda_function.py"
find "$BUILD_DIR" -type d -name "__pycache__" -prune -exec rm -rf {} +

python3 - "$BUILD_DIR" "$ZIP_PATH" <<'PY'
import os
import stat
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

build_dir = Path(sys.argv[1])
zip_path = Path(sys.argv[2])
fixed_timestamp = (1980, 1, 1, 0, 0, 0)

with ZipFile(zip_path, "w", compression=ZIP_DEFLATED) as package:
    for path in sorted(build_dir.rglob("*")):
        if path.is_dir():
            continue

        archive_name = path.relative_to(build_dir).as_posix()
        info = ZipInfo(archive_name, fixed_timestamp)
        info.compress_type = ZIP_DEFLATED
        info.external_attr = (stat.S_IMODE(path.stat().st_mode) or 0o644) << 16
        with path.open("rb") as source:
            package.writestr(info, source.read())

print(f"Wrote {zip_path}")
PY

"$ROOT_DIR/scripts/check_lambda_package.sh"
