target "picamera2-alpine" {
  context = "./alpine"
  args = {
    LIBCAMERA_VER="0.3.2"
    PICAMERA2_VER="0.3.24"
  }
  tags = ["carrycat/picamera2-alpine:latest", "carrycat/picamera2-alpine:0.3.24"]
  platforms = ["linux/arm/v6", "linux/arm/v7", "linux/arm64/v8"]
}
target "broken" {
  context = "./alpine"
  args = {
    LIBCAMERA_VER="0.0.5"
    PICAMERA2_VER="0.3.12"
  }
  tags = ["carrycat/picamera2-alpine:0.3.12",]
  platforms = ["linux/arm64/v8"]
}