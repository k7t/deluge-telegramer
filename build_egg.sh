#!/usr/bin/env bash
set -e

# Build the egg directory structure via setuptools (keep temp dir, skip zipping)
rm -rf build/bdist.*/egg dist/*.egg
python3 setup.py bdist_egg --keep-temp 2>&1

# Find the built directory and the egg setuptools already created
egg_dir=$(ls -d build/bdist.*/egg 2>/dev/null | head -1)
if [ -z "$egg_dir" ]; then
    echo "ERROR: build directory not found"
    exit 1
fi

# Determine output egg name from Python version
py_ver=$(python3 -c "import sys; print(f'py{sys.version_info.major}.{sys.version_info.minor}')")
egg_name="dist/Telegramer-2.1.1.4-${py_ver}.egg"

echo "Zipping $egg_dir -> $egg_name"

python3 - "$egg_dir" "$egg_name" <<'EOF'
import zipfile, os, sys

src_dir = sys.argv[1]
egg_path = sys.argv[2]

os.makedirs(os.path.dirname(egg_path), exist_ok=True)

# Remove the egg setuptools already created; we build our own clean one
if os.path.exists(egg_path):
    os.remove(egg_path)

with zipfile.ZipFile(egg_path, 'w', compression=zipfile.ZIP_STORED) as z:
    for root, dirs, files in os.walk(src_dir):
        dirs[:] = sorted(d for d in dirs if d != '__pycache__')
        for f in sorted(files):
            if f.endswith('.pyc'):
                continue
            path = os.path.join(root, f)
            arcname = os.path.relpath(path, src_dir)
            z.write(path, arcname)

# Verify every local file header signature
errors = 0
with zipfile.ZipFile(egg_path) as z, open(egg_path, 'rb') as f:
    for info in z.infolist():
        f.seek(info.header_offset)
        if f.read(4) != b'PK\x03\x04':
            print(f"BAD HEADER: {info.filename}")
            errors += 1

if errors:
    print(f"FAILED: {errors} bad entries")
    sys.exit(1)

size = os.path.getsize(egg_path)
with zipfile.ZipFile(egg_path) as z:
    count = len(z.infolist())
print(f"OK: {egg_path} — {count} entries, {size} bytes, all headers valid")
EOF

# Package include/ libraries as a separate directory alongside the egg
include_out="dist/Telegramer-include"
rm -rf "$include_out"
cp -r telegramer/include/. "$include_out"
find "$include_out" -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
find "$include_out" -name '*.pyc' -delete 2>/dev/null || true
echo "Packaged include libs -> $include_out"
