#!/usr/bin/env bash

HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker build --no-cache -t telegramer.build . \
    && docker run -v $(pwd)/out:/tmp/out --rm -i telegramer.build sh -s << COMMANDS
python setup.py bdist_egg
python3 -c "
import zipfile, os, glob
egg = glob.glob('dist/*.egg')[0]
tmp = egg + '.tmp'
with zipfile.ZipFile(egg, 'r') as src, zipfile.ZipFile(tmp, 'w', compression=zipfile.ZIP_STORED) as dst:
    for item in src.infolist():
        item.compress_type = zipfile.ZIP_STORED
        item.flag_bits = 0
        dst.writestr(item, src.read(item.filename))
os.replace(tmp, egg)
print('Re-zipped:', egg)
"
chown -R ${HOST_UID}:${HOST_GID} dist
cp -ar dist/ /tmp/out/
COMMANDS
