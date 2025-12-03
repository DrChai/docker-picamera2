#! Dockerfile
FROM python:3.11-alpine AS base

RUN apk add --update --no-cache --virtual .tmp \
    # essential deps
    git libc-dev linux-headers \
    # camera deps
    g++ ninja-build cmake py3-pybind11-dev
RUN ln -s /usr/lib/ninja-build/bin/ninja /usr/local/bin/ninja
RUN pip install -U meson jinja2 pyyaml ply

FROM base AS builder
ARG LIB_REPO=https://github.com/raspberrypi/libcamera.git
ARG LIB_TAG='v0.3.2+rpt20241112'
RUN git clone -b ${LIB_TAG} ${LIB_REPO}
WORKDIR /libcamera
COPY 0_3 .
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

FROM python:3.11-alpine AS final
WORKDIR /app
RUN apk add --update --no-cache --virtual .tmp libstdc++
COPY --from=builder /app /app
COPY --from=builder /app/libcamera/lib /usr/local/lib
COPY --from=builder /app/libcamera/data /usr/local/share
ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib
