#!/usr/bin/env bash
set -e

egg=$(ls dist/*.egg 2>/dev/null | head -1)
if [ -z "$egg" ]; then
    echo "No .egg found in dist/ - run 'python setup.py bdist_egg' first"
    exit 1
fi

echo "Re-zipping: $egg"

python3 - "$egg" <<'EOF'
import zipfile, os, sys, struct, zlib

egg = sys.argv[1]
tmp = egg + '.tmp'

with open(egg, 'rb') as raw, \
     zipfile.ZipFile(egg, 'r') as src, \
     zipfile.ZipFile(tmp, 'w', compression=zipfile.ZIP_STORED) as dst:

    for info in src.infolist():
        # Read raw compressed bytes directly, bypassing Python's CRC check
        raw.seek(info.header_offset)
        lh = raw.read(30)
        if lh[:4] != b'PK\x03\x04':
            raise ValueError(f"Bad local header for {info.filename}")
        fname_len = struct.unpack_from('<H', lh, 26)[0]
        extra_len = struct.unpack_from('<H', lh, 28)[0]
        raw.seek(info.header_offset + 30 + fname_len + extra_len)
        compressed = raw.read(info.compress_size)

        if info.compress_type == zipfile.ZIP_DEFLATED:
            data = zlib.decompress(compressed, -15)  # raw deflate, no CRC check
        elif info.compress_type == zipfile.ZIP_STORED:
            data = compressed
        else:
            raise ValueError(f"Unsupported compression {info.compress_type} in {info.filename}")

        info.compress_type = zipfile.ZIP_STORED
        info.flag_bits = 0
        info.CRC = zlib.crc32(data) & 0xFFFFFFFF
        info.file_size = len(data)
        info.compress_size = len(data)
        dst.writestr(info, data)

os.replace(tmp, egg)

# Verify every local header signature
errors = 0
with zipfile.ZipFile(egg) as z, open(egg, 'rb') as f:
    for info in z.infolist():
        f.seek(info.header_offset)
        if f.read(4) != b'PK\x03\x04':
            print(f"BAD HEADER: {info.filename}")
            errors += 1

if errors:
    print(f"FAILED: {errors} bad entries")
    sys.exit(1)

size = os.path.getsize(egg)
with zipfile.ZipFile(egg) as z:
    count = len(z.infolist())
print(f"OK: {count} entries, {size} bytes, all local headers valid")
EOF
