#! Dockerfile
ARG LIBCAMERA_VER=latest
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM carrycat/libcamera-alpine:${LIBCAMERA_VER} AS libcamera

FROM python:3.11-alpine AS wheeler-arm64
RUN apk --no-cache add gcc jpeg-dev libjpeg libcap-dev musl-dev
RUN pip wheel --no-deps --wheel-dir /app/wheels \
    pillow python-prctl PiDNG 
RUN pip wheel --no-deps --wheel-dir /app/wheels jsonschema

FROM python:3.11-alpine AS wheeler-arm
ARG TARGETARCH TARGETVARIANT
RUN apk --no-cache add gcc zlib-dev musl-dev \
    # Pillow dependencies (incl zlib-dev)
    jpeg-dev libjpeg \
    # python-prctl dependencies
    libcap-dev \
    cargo
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
      export QEMU_CPU="arm1176"; fi \
    && pip wheel --no-deps --wheel-dir /app/wheels pillow python-prctl PiDNG \
    && pip wheel --wheel-dir /app/wheels jsonschema

FROM wheeler-${TARGETARCH} AS wheeler
ARG PICAMERA2_VER=0.3.24
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels \
    v4l2-python3 piexif libarchive-c tqdm picamera2==$PICAMERA2_VER

FROM carrycat/numpy-alpine AS numpy
ARG TARGETARCH TARGETVARIANT
RUN apk --update --no-cache add g++ make zlib-dev \
    # simplejpeg dependencies
    openssl-dev linux-headers
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
    export QEMU_CPU="arm1176"; fi \
    && pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels --find-links /app/wheels simplejpeg

FROM python:3.11-alpine AS pykms
RUN apk add --update --no-cache \
    bash git meson ninja-build pkgconfig
RUN ln -s /usr/lib/ninja-build/bin/ninja /usr/local/bin/ninja
WORKDIR /pykms
RUN git clone https://github.com/tomba/kmsxx
RUN apk add --update fmt-dev libdrm-dev py3-pybind11-dev gcc g++ musl-dev
WORKDIR /pykms/kmsxx
RUN meson setup build -Domap=disabled -Ddatadir=/app/pykms/data -Dlibdir=/app/pykms/lib
RUN ninja -C build install

FROM python:3.11-alpine
WORKDIR /app
ARG TARGETARCH TARGETVARIANT 
RUN apk add --update --no-cache --virtual .tmp \
    # essential deps
    libc-dev linux-headers libstdc++ \
    # camera runtime deps
    libcap libjpeg py3-pybind11 \
    # kms runtime deps
    fmt libdrm \
    # libcamera runtime
    gnutls openssl gnutls-dev \
    # av runtime
    libxml2
COPY --from=wheeler /app/wheels wheels
COPY --from=numpy /app/wheels wheels
COPY --from=carrycat/pyav-alpine /app /app
COPY --from=libcamera /app /app
COPY --from=libcamera /app/libcamera/data /usr/local/share
COPY --from=pykms /app /app
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
      export QEMU_CPU="arm1176"; fi \
    && pip install wheels/*
ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:/app/libcamera/lib:/app/ffmpeg-7.1/lib:/app/pykms/lib
ENV PYTHONPATH=/app/libcamera/lib/python3.11/site-packages/:/app/pykms/lib/python3.11/site-packages/