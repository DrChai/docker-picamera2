# buulding numpy from the souce takes hours, 
# so separate this process into a single Docker image and then import it to picamera2 at the final stage.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM python:3.11-alpine AS wheeler-arm64
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels numpy

FROM python:3.11-alpine AS wheeler-arm
ARG TARGETARCH TARGETVARIANT
RUN apk add --update --no-cache \
    g++ zlib-dev make cmake gcc meson \
    # qemu=arm1176  \
    patchelf \
    ninja-build
RUN ln -s /usr/lib/ninja-build/bin/ninja /usr/local/bin/ninja
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
    export QEMU_CPU="arm1176"; fi \
    && pip wheel --no-deps --wheel-dir /app/wheels numpy

FROM wheeler-${TARGETARCH} AS wheeler

FROM python:3.11-alpine
ARG TARGETARCH TARGETVARIANT
WORKDIR /app
COPY --from=wheeler /app /app
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
    export QEMU_CPU="arm1176"; fi \
    && pip install wheels/*
# testing by: docker run carrycat/numpy-alpine python -c "import numpy"
# import wheel file from /app/wheels/