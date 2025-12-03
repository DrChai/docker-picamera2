# docker-picamera2
Run Picamera2 and its dependencies within docker container.
make sure correct overlay camera module is set in the file `/boot/firmware/config.txt`([details](https://www.raspberrypi.com/documentation/computers/camera_software.html#configuration)). A recognized camera will be listed in `rpicam-still --list-cameras`
## Running Container with `privileged` flag:
```shell
docker run -ti --rm --privileged  carrycat/picamera2-alpine python
```
## To re-build the image with different verions of Picamera2:
- ARMv6 (Raspberry Pi Zero, Raspberry Pi 1)
- ARMv7 (Raspberry Pi 2)
- ARM64 (Raspberry Pi 2,3,4,5)
```shell
docker buildx build --platform linux/arm/v6,linux/arm64/v8,linux/arm/v7 --build-arg LIBCAMERA_VER=0.3.2 --build-arg PICAMERA2_VER=0.3.24 --push .
```