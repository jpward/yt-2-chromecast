FROM ubuntu:18.04

ENV DEBIAN_FRONTEND="noninteractive"

ENV PKGS="python3-pychromecast netcat vlc curl net-tools"

RUN apt-get update && \
    apt-get install --no-install-recommends -y ${PKGS} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

#curl -LOJ https://raw.githubusercontent.com/videolan/vlc/9d4c4d2fb9524b7709d2fdc1a7decc108602a445/share/lua/playlist/youtube.lua
RUN curl -LOJ https://raw.githubusercontent.com/videolan/vlc/6e0f4a28c6f82bef165473e2785ea2834f9f5563/share/lua/playlist/youtube.lua && \
    mv youtube.lua /usr/lib/x86_64-linux-gnu/vlc/lua/playlist/youtube.luac && \
    sed -i 's/geteuid/getppid/' /usr/bin/vlc

COPY chunk_server.py chromecast_server.py getYouTubeLink.sh vlcStream.sh /
