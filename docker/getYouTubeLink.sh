#!/bin/bash

#provide script video you want a link for:
#  ./getYouTubeLink.sh "outlaws and outsiders"
INPUT=$(echo $1 | sed 's/ /+/g')
URL_LINK=$(curl -s https://www.youtube.com/results?search_query=${INPUT} | grep -oP '"url":"/watch.*?"' | head -1)
URL_LINK_TRIM=$(echo ${URL_LINK} | cut -d':' -f2 | sed -e 's/^\"//' -e 's/\"$//' -e 's/\\u.*//')

#The first link is browser link, second is stream link
#echo https://www.youtube.com${URL_LINK_TRIM}
echo https://youtu.be/$(echo ${URL_LINK_TRIM} | cut -d'=' -f2)
