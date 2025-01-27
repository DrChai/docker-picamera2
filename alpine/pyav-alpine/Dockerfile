FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM python:3.11-alpine AS source
RUN apk add --update --no-cache bash git make clang lld wget pkgconfig
WORKDIR /app
RUN git clone https://code.videolan.org/videolan/x264.git
RUN git clone https://github.com/PyAV-Org/PyAV.git
WORKDIR /app/x264
COPY --from=xx --link / /
ARG TARGETPLATFORM
RUN xx-info && xx-apk add --update musl-dev gcc libxml2-dev
RUN CC=xx-clang ./configure --host=$(xx-clang --print-target-triple) \
    --disable-asm --enable-static --disable-opencl --bindir=usr/bin --libdir=usr/lib
RUN make DESTDIR=$(xx-info sysroot) -j$(nproc) install
RUN xx-verify $(xx-info sysroot)usr/bin/x264
WORKDIR /app/PyAV

ENV PYAV_LIBRARY=ffmpeg-7.1
ENV PYAV_LIBRARY_PREFIX=/app/PyAV/vendor/build/ffmpeg-7.1
ENV PKG_CONFIG_PATH="$PYAV_LIBRARY_PREFIX/lib/pkgconfig:/usr/local/lib/pkgconfig"
ENV PYAV_LIBRARY_ROOT=/app/PyAV/vendor
ENV PYAV_LIBRARY_BUILD=/app/PyAV/vendor/build
RUN <<EOF
#!/bin/bash
cd "$PYAV_ROOT"

# Skip the rest of the build if it already exists.
if [[ -e "$PYAV_LIBRARY_PREFIX/bin/ffmpeg" ]]; then
    echo "We have a cached build of ffmpeg-$PYAV_LIBRARY; skipping re-build."
    exit 0
fi
mkdir -p "$PYAV_LIBRARY_ROOT"
mkdir -p "$PYAV_LIBRARY_PREFIX"
cd "$PYAV_LIBRARY_ROOT"


# Download and expand the source.
if [[ ! -d $PYAV_LIBRARY ]]; then
    url="https://ffmpeg.org/releases/$PYAV_LIBRARY.tar.gz"
    echo Downloading $url
    wget --no-check-certificate "$url" || exit 1
    tar -xzf $PYAV_LIBRARY.tar.gz
    rm $PYAV_LIBRARY.tar.gz
    echo
fi
EOF
WORKDIR ${PYAV_LIBRARY_ROOT}/${PYAV_LIBRARY}
RUN ./configure \
    --disable-asm \
    --enable-cross-compile \
    --cc=xx-clang \
    --pkg-config=$(xx-info)-pkg-config \
    --disable-doc \
    --disable-static \
    --disable-stripping \
    --enable-debug=3 \
    --enable-gpl \
    --enable-version3 \
    --enable-libx264 \
    --enable-libxml2 \
    --enable-shared \
    --enable-sse \
    --enable-avx \
    --enable-avx2 \
    --prefix="$PYAV_LIBRARY_PREFIX"
RUN make -j$(nproc) install
RUN xx-verify ${PYAV_LIBRARY_PREFIX}/bin/ffmpeg

FROM python:3.11-alpine AS builder
COPY --link --from=source /app /app
WORKDIR /app/PyAV
ARG TARGETARCH
ARG TARGETVARIANT
ENV PYAV_ROOT=/app/PyAV
ENV PYAV_LIBRARY_PREFIX=/app/PyAV/vendor/build/ffmpeg-7.1
ENV PATH="$PYAV_LIBRARY_PREFIX/bin:$PATH"
ENV PYTHONPATH="$PYAV_ROOT"
ENV PKG_CONFIG_PATH="$PYAV_LIBRARY_PREFIX/lib/pkgconfig:/usr/local/lib/pkgconfig"
ENV LD_LIBRARY_PATH="$PYAV_LIBRARY_PREFIX/lib"
ENV DYLD_LIBRARY_PATH="$PYAV_LIBRARY_PREFIX/lib"
RUN pip install -U cython setuptools
RUN apk add --update --no-cache make pkgconfig ffmpeg-dev musl-dev gcc
RUN make && if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
      export QEMU_CPU="arm1176"; fi \
    && pip wheel --no-deps --wheel-dir /app/wheels .

FROM python:3.11-alpine AS release
ARG TARGETARCH
ARG TARGETVARIANT
COPY --from=builder /app/wheels /app/wheels
COPY --from=builder /app/PyAV/vendor/build/ffmpeg-7.1 /app/ffmpeg-7.1
WORKDIR /app
RUN if [[ "$TARGETARCH" == "arm" ]] && [ "$TARGETVARIANT" == "v6" ]; then \
      export QEMU_CPU="arm1176"; fi \
    && pip install wheels/*
