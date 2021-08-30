#!/bin/bash -x

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

REQUEST=/tmp/REQUEST
RUN=true
while ${RUN}; do
  SEARCH_TEXT="$(nc -l -p 22224)"
  
  #Try and get a lock 3 times
  for i in {1..3}; do
    if ! [ -f ${REQUEST}.lock ];then
      touch ${REQUEST}.lock
      echo ${SEARCH_TEXT} > ${REQUEST}
      rm -f ${REQUEST}.lock
      continue
    fi
    sleep 0.5
  done
  
  #if we got here then we couldn't get a lock, something went wrong so force it now
  touch ${REQUEST}.lock
  echo ${SEARCH_TEXT} > ${REQUEST}
  rm -f ${REQUEST}.lock
done
  
