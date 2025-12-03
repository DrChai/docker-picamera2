
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM  python:slim AS base
RUN apt update && apt install -y --no-install-recommends \
    # essential deps
    clang lld git ninja-build python3-pybind11 cmake
RUN pip install meson
COPY --link --from=xx / /
ARG TARGETPLATFORM
RUN xx-apt install -y --no-install-recommends g++

FROM base AS libcamera
ARG LIB_REPO=https://github.com/raspberrypi/libcamera.git
# specify the desired libcamera version, e.g., v0.3.2+rpt20241112
ARG LIBCAMERA_VER='v0.5.2' 
RUN git clone -b ${LIBCAMERA_VER} ${LIB_REPO}
WORKDIR /libcamera
RUN pip install -U jinja2 pyyaml ply

RUN meson setup build --buildtype=release \
    -Dpipelines=rpi/vc4,rpi/pisp \
    -Dipas=rpi/vc4,rpi/pisp \
    -Dgstreamer=disabled \
    -Dv4l2=true \
    -Dtest=false -Dlc-compliance=disabled \
    -Dcam=disabled -Dqcam=disabled \
    -Ddocumentation=disabled -Dpycamera=enabled \
    -Ddatadir=/app/libcamera/data -Dlibdir=/app/libcamera/lib \
    -Dlibexecdir=/app/libcamera/libexce
RUN ninja -C build install

FROM --platform=$BUILDPLATFORM python:slim AS wheeler-arm64
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Pillow dependencies
    libjpeg-dev \
    # python-prctl dependencies
    libcap-dev
COPY --from=xx / /
ARG TARGETPLATFORM
RUN xx-apt install -y --no-install-recommends gcc
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels \
    pillow python-prctl PiDNG \
    av numpy simplejpeg

FROM python:slim AS numpy-arm32
ARG TARGETARCH TARGETVARIANT
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    # numpy dependencies
    patchelf ninja-build \
    # simplejpeg(python cmake) dependencies
    libssl-dev make
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
      export QEMU_CPU="arm1176"; fi \
    && pip wheel --no-deps --wheel-dir /app/wheels numpy simplejpeg

FROM numpy-arm32 AS wheeler-arm
ARG TARGETARCH TARGETVARIANT
RUN apt update && apt install -y --no-install-recommends \
    # ffmpeg dependencies
    libavformat-dev libavdevice-dev pkg-config \
    libjpeg-dev \
    # Pillow dependencies
    zlib1g-dev \
    # python-prctl dependencies
    libcap-dev
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
      export QEMU_CPU="arm1176"; fi \
    && pip wheel --no-deps --wheel-dir /app/wheels pillow python-prctl PiDNG \
    && pip wheel --wheel-dir /app/wheels av

FROM wheeler-${TARGETARCH} AS wheeler
ARG PICAMERA2_VER=0.3.24
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels \
    jsonschema v4l2-python3 piexif libarchive-c tqdm picamera2==$PICAMERA2_VER

FROM base AS pykms
RUN apt install -y --no-install-recommends \
    libfmt-dev libdrm-dev pkg-config
WORKDIR /pykms
RUN git clone https://github.com/tomba/kmsxx
WORKDIR /pykms/kmsxx
RUN meson setup build -Domap=disabled -Dlibdir=/app/pykms/lib
RUN ninja -C build install

FROM python:slim
WORKDIR /app
RUN apt update && apt install -y --no-install-recommends \
    # kms runtime
    libfmt-dev libdrm2 \
    # libcamera runtime
    openssl gnutls-bin
COPY --from=wheeler /app/wheels wheels
RUN pip install wheels/*

COPY --from=libcamera /app /app
COPY --from=libcamera /app/libcamera/lib /usr/local/lib
COPY --from=libcamera /app/libcamera/data /usr/local/share
COPY --from=pykms /app/pykms/lib /usr/local/lib
ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib
ENV PYTHONPATH=/app/libcamera/lib/python3.*/site-packages/:/app/pykms/lib/python3.*/site-packages/
