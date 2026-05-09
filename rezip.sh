#!/usr/bin/env bash
set -e

egg=$(ls dist/*.egg 2>/dev/null | head -1)
if [ -z "$egg" ]; then
    echo "No .egg found in dist/ - run 'python setup.py bdist_egg' first"
    exit 1
fi

echo "Re-zipping: $egg"

python3 - "$egg" <<'EOF'
import zipfile, os, sys, struct

egg = sys.argv[1]
tmp = egg + '.tmp'

with zipfile.ZipFile(egg, 'r') as src, \
     zipfile.ZipFile(tmp, 'w', compression=zipfile.ZIP_STORED) as dst:
    for item in src.infolist():
        item.compress_type = zipfile.ZIP_STORED
        item.flag_bits = 0
        dst.writestr(item, src.read(item.filename))

os.replace(tmp, egg)

# Verify every entry has a valid local file header
errors = 0
with zipfile.ZipFile(egg) as z, open(egg, 'rb') as f:
    for info in z.infolist():
        f.seek(info.header_offset)
        sig = f.read(4)
        if sig != b'PK\x03\x04':
            print(f"BAD HEADER at {info.filename}: {sig.hex()}")
            errors += 1

if errors:
    print(f"FAILED: {errors} bad entries")
    sys.exit(1)
else:
    size = os.path.getsize(egg)
    with zipfile.ZipFile(egg) as z:
        count = len(z.infolist())
    print(f"OK: {count} entries, {size} bytes, all local headers valid")
EOF
