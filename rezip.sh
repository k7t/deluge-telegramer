#!/usr/bin/env bash
set -e

egg=$(ls dist/*.egg 2>/dev/null | head -1)
if [ -z "$egg" ]; then
    echo "No .egg found in dist/ - run 'python setup.py bdist_egg' first"
    exit 1
fi

python3 -c "
import zipfile, os, glob
egg = '$egg'
tmp = egg + '.tmp'
with zipfile.ZipFile(egg, 'r') as src, zipfile.ZipFile(tmp, 'w', compression=zipfile.ZIP_DEFLATED) as dst:
    for item in src.infolist():
        dst.writestr(item, src.read(item.filename))
os.replace(tmp, egg)
print('Re-zipped:', egg)
"
