#!/bin/bash -x

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

WAV=/tmp/wav.wav

#XDG setup to get around warnings
mkdir -p /tmp/xdgr
export XDG_RUNTIME_DIR=/tmp/xdgr

RADIO=false
YT_LINK=""
REQUEST=/tmp/REQUEST

#Find link to go with request, also check for radio request
find_request() {
  #Wait for a request
  set +x
  WAIT_4_REQ=true
  while ${WAIT_4_REQ}; do
    if [ -f ${REQUEST} ] && ! [ -f ${REQUEST}.lock ]; then
      touch ${REQUEST}.lock
      SEARCH_TEXT="$(cat ${REQUEST})"
      rm -f ${REQUEST} ${REQUEST}.lock
      WAIT_4_REQ=false
    fi
    sleep 0.3
  done
  set -x

  #Check if it is a radio request
  if echo ${SEARCH_TEXT} | grep -qi "radio$" ; then
    SEARCH_TEXT="$(echo ${SEARCH_TEXT} | tr 'A-Z' 'a-z' | sed 's/radio$//')"
    RADIO=true
  else
    rm -f /tmp/RADIO
  fi
  
  #Find YouTube video from request
  YT_LINK="$(${HERE}/getYouTubeLink.sh "${SEARCH_TEXT}")"
}

#start populating wav file for serving
create_wav() {
  rm -f ${WAV}
  cvlc -q --play-and-exit --vout=none --aout=afile --audiofile-file ${WAV} ${YT_LINK} &
  CVLC_PID=$!
  echo ${CVLC_PID} > /tmp/CVLC_PID
}

#play request
play_request() {
  
  #Stream to wav file that will be served to chromecast
  create_wav
 
  #Get the radio list if requested 
  if ${RADIO} && ! [ -f /tmp/RADIO ]; then
    YT_LINK_TRIM="$(echo ${YT_LINK} | sed 's%https://youtu.be/%%')"
    curl -s "https://www.youtube.com/watch?v=${YT_LINK_TRIM}" | grep -oP '"url":"/watch.*?"' | sed 's%\\.*"%"%' | sort -u | grep -v ${YT_LINK_TRIM} | cut -d':' -f2 | sed -e 's/^\"//' -e 's/\"$//' > /tmp/RADIO
  fi
  
  #Return once we verify the stream is up
  TRY_VLC_AGAIN=true
  TIMEOUT=10
  CNT=0
  while [ ${CNT} -lt ${TIMEOUT} ]; do
    CNT=$((CNT + 1))
    VLC_ALIVE=false
    kill -0 $(cat /tmp/CVLC_PID) && VLC_ALIVE=true
    if ! ${VLC_ALIVE} && ${TRY_VLC_AGAIN}; then
      TRY_VLC_AGAIN=false
      sleep 1
      create_wav
    fi
    if [ -f "${WAV}" ]; then
      SIZE=$(du ${WAV} | awk '{print $1}')
      if [ ${SIZE} -gt 0 ]; then
        break
      fi
    fi
    sleep 1
  done
}

if [ -f /tmp/RADIO ]; then
  sleep 5
  #need to see if /tmp/CVLC_PID is still working AND netstat -tn | grep "0\.0\.0\.0:5001" exists
  PLAY=false
  RUN=true
  while $RUN; do
    VLC_ALIVE=false
    kill -0 $(cat /tmp/CVLC_PID) && VLC_ALIVE=true
    CAST_ALIVE=false
    netstat -tn | grep -q "192\.168\.1\.11:5001" && CAST_ALIVE=true
    if ${CAST_ALIVE} && ! ${VLC_ALIVE}; then
      #Time to switch
      PLAY=true
      break
    elif ! ${CAST_ALIVE} || [ -f ${REQUEST} ]; then
      PLAY=false
      break
    fi
    sleep 0.5
  done
  if ${PLAY}; then
    #Get next song, and remove from list
    YT_LINK="https://youtu.be/$(head -1 /tmp/RADIO | cut -d'=' -f2)"
    RADIO_LIST="$(tail -n +2 /tmp/RADIO)"
    if [ -z "${RADIO_LIST}" ]; then
      #Finished playlist
      rm -f /tmp/RADIO
      RADIO=false
    else
      echo ${RADIO_LIST} | sed 's/ /\n/g' > /tmp/RADIO
      RADIO=true
    fi
    play_request
  else
    find_request
    play_request
  fi
else
  find_request
  play_request
fi
