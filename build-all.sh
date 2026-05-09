#!/usr/bin/env bash

HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker build -f Dockerfile-py --build-arg PYTHON_VERSION=${PYTHON_VERSION} --no-cache -t telegramer.build . \
    && docker run -v $(pwd)/out:/tmp/out --rm -i telegramer.build sh -s << COMMANDS
python setup.py bdist_egg
python3 -c "
import zipfile, os, glob
egg = glob.glob('dist/*.egg')[0]
os.rename(egg, egg + '.zip')
zipfile.ZipFile(egg + '.zip').extractall(egg)
os.remove(egg + '.zip')
print('Directory egg:', egg)
"
chown -R ${HOST_UID}:${HOST_GID} dist
cp -ar dist/ /tmp/out/
COMMANDS
