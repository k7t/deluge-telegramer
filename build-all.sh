#!/usr/bin/env bash

HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker build -f Dockerfile-py --build-arg PYTHON_VERSION=${PYTHON_VERSION} --no-cache -t telegramer.build . \
    && docker run -v $(pwd)/out:/tmp/out --rm -i telegramer.build sh -s << COMMANDS
sh build_egg.sh
chown -R ${HOST_UID}:${HOST_GID} dist
cp -ar dist/ /tmp/out/
COMMANDS
