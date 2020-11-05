# text-2-chromecast

Simple container app to play youtube video (audio only) on chromecast devices

```
./docker/make_container.sh
./docker/run.sh

#From another terminal
echo "outlaws and outsiders" | nc 127.0.0.1 22224

#outlaws and outsiders should start playing on connected chromecast device
```
