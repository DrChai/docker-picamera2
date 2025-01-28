# docker-picamera2
Run Picamera2 and its dependencies within docker container.
## Running Container with `privileged` flag:
```shell
docker run -ti --rm --privileged  carrycat/picamera2-alpine python
```
## To re-build the image with different verions of Picamera2:
```shell
docker buildx build --platform linux/arm/v6,linux/arm64/v8,linux/arm/v7 --build-arg LIBCAMERA_VER=0.3.2 --build-arg PICAMERA2_VER=0.3.24 --push .
```