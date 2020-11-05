#!/bin/bash -x

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

WAV=/tmp/wav.wav

#XDG setup to get around warnings
mkdir -p /tmp/xdgr
export XDG_RUNTIME_DIR=/tmp/xdgr

#Wait for a request
SEARCH_TEXT="$(nc -l -p 22224)"

#Find YouTube video from request
YT_LINK="$(${HERE}/getYouTubeLink.sh "${SEARCH_TEXT}")"

#Stream to wav file that will be served to chromecast
rm -f ${WAV}
cvlc -q --play-and-exit --vout=none --aout=afile --audiofile-file ${WAV} ${YT_LINK} &

#Return once we verify the stream is up
TIMEOUT=30
CNT=0
while [ ${CNT} -lt ${TIMEOUT} ]; do
  CNT=$((CNT + 1))
  if [ -f "${WAV}" ]; then
    SIZE=$(du ${WAV} | awk '{print $1}')
    if [ ${SIZE} -gt 0 ]; then
      break
    fi
  fi
  sleep 1
done
