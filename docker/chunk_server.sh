#!/bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

RUN=true
RESTART=true

while ${RUN}; do
  if ${RESTART}; then
    cd /tmp
    python3 ${HERE}/chunk_server.py &
    CS_PID=$!
    echo ${CS_PID} > /tmp/CHUNK_SRVR_PID
    RESTART=false
  fi

  if ! kill -0 ${CS_PID}; then
    RESTART=true
  fi

  sleep 3
done
