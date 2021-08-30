#!/bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

BASE="`cat ${HERE}/BUILDER | cut -d':' -f1`"
VER="`cat ${HERE}/BUILDER | cut -d':' -f2`"
DIMG="$(docker images | grep ${BASE,,} | head -1 | awk '{print $1":"$2}')"

RUNMODE="-d --restart always"
#RUNMODE="--rm"
docker run \
        --privileged \
        ${RUNMODE} \
        -ti \
        --net host \
        ${DIMG} /bin/bash -c ' \
                              (/chunk_server.sh &) \
                              && (/chromecast_server.sh &) \
                              && (/get_request.sh &) \
                              && while true; do ${HERE}/vlcStream.sh || echo "EEK"; kill -s SIGTERM $(cat /tmp/PID); sleep 0.1; done \
                             '

