################################################################################
# Build Args
################################################################################

ARG DEBIAN_IMAGE_DOMAIN="docker.io/library/debian"
ARG DEBIAN_IMAGE_BRANCH="10-slim"
ARG GOLANG_IMAGE_DOMAIN="docker.io/library/golang"
ARG GOLANG_IMAGE_BRANCH="buster"
ARG DISTROLESS_IMAGE_DOMAIN="gcr.io/distroless/base-debian10"
ARG DISTROLESS_IMAGE_BRANCH="latest"

################################################################################
# Build ImageMagick6 stage
################################################################################

FROM ${DEBIAN_IMAGE_DOMAIN}:${DEBIAN_IMAGE_BRANCH} AS imagick6

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG IMAGE_MAGICK_6_VERSION
ENV IMAGE_MAGICK_6_VERSION=${IMAGE_MAGICK_6_VERSION:-"6.9.11-57"}

RUN apt-get update \
 && apt-get -y --no-install-recommends install \
      wget \
      ca-certificates \
      build-essential \
      pkg-config \
      libfftw3-dev \
      libgif-dev \
      libjpeg-dev \
      libpng-dev \
      libtiff-dev \
      libwebp-dev \
      libwmf-dev \
      zlib1g-dev \
      libbz2-dev \
      liblzma-dev \
      libzstd-dev \
 && apt-get clean

WORKDIR /source
RUN wget "https://github.com/ImageMagick/ImageMagick6/archive/${IMAGE_MAGICK_6_VERSION}.tar.gz"

WORKDIR /build/ImageMagick6
RUN tar -xvf "/source/${IMAGE_MAGICK_6_VERSION}.tar.gz" --strip-components=1
RUN ./configure \
      --prefix=/usr \
      --sysconfdir=/etc \
      --enable-shared=no \
      --enable-static=yes \
      --enable-hdri=no \
      --disable-openmp \
      --disable-opencl \
      --disable-docs \
      --with-gcc-arch=generic \
      --with-quantum-depth=16 \
      --with-fontconfig=no \
      --with-freetype=no \
      --with-gslib=no \
      --with-magick-plus-plus=no \
      --with-pango=no \
      --with-perl=no \
      --with-x=no \
    | tee configure.log
RUN make -j $(nproc)
RUN make DESTDIR=/opt/ImageMagick6 install

WORKDIR /opt/ImageMagick6/usr/lib/pkgconfig
RUN mv ImageMagick.pc ImageMagick-6.pc
RUN mv MagickCore.pc MagickCore-6.pc
RUN mv MagickWand.pc MagickWand-6.pc
RUN mv Wand.pc Wand-6.pc
RUN for file in *; do grep -Esq '^Libs.private:.*-lzstd' $file || sed -i -E 's@^(Libs.private:.*)@\1 -lzstd@' $file; done

WORKDIR /build/ImageMagick6

################################################################################
# Build ImageMagick7 stage
################################################################################

FROM ${DEBIAN_IMAGE_DOMAIN}:${DEBIAN_IMAGE_BRANCH} AS imagick7

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG IMAGE_MAGICK_7_VERSION
ENV IMAGE_MAGICK_7_VERSION=${IMAGE_MAGICK_7_VERSION:-"7.0.10-58"}

RUN apt-get update \
 && apt-get -y --no-install-recommends install \
      wget \
      ca-certificates \
      build-essential \
      pkg-config \
      libfftw3-dev \
      libgif-dev \
      libjpeg-dev \
      libpng-dev \
      libtiff-dev \
      libwebp-dev \
      libwmf-dev \
      zlib1g-dev \
      libbz2-dev \
      liblzma-dev \
      libzstd-dev \
 && apt-get clean

WORKDIR /source
RUN wget "https://github.com/ImageMagick/ImageMagick/archive/${IMAGE_MAGICK_7_VERSION}.tar.gz"

WORKDIR /build/ImageMagick7
RUN tar -xvf "/source/${IMAGE_MAGICK_7_VERSION}.tar.gz" --strip-components=1
RUN ./configure \
      --prefix=/usr \
      --sysconfdir=/etc \
      --enable-shared=no \
      --enable-static=yes \
      --enable-hdri=no \
      --disable-openmp \
      --disable-opencl \
      --disable-docs \
      --with-gcc-arch=generic \
      --with-quantum-depth=16 \
      --with-fontconfig=no \
      --with-freetype=no \
      --with-gslib=no \
      --with-magick-plus-plus=no \
      --with-pango=no \
      --with-perl=no \
      --with-x=no \
    | tee configure.log
RUN make -j $(nproc)
RUN make DESTDIR=/opt/ImageMagick7 install

WORKDIR /opt/ImageMagick7/usr/lib/pkgconfig
RUN mv ImageMagick.pc ImageMagick-7.pc
RUN mv MagickCore.pc MagickCore-7.pc
RUN mv MagickWand.pc MagickWand-7.pc
RUN for file in *; do grep -Esq '^Libs.private:.*-lzstd' $file || sed -i -E 's@^(Libs.private:.*)@\1 -lzstd@' $file; done

WORKDIR /build/ImageMagick7

################################################################################
# Build Go Imagick stage
################################################################################

FROM ${GOLANG_IMAGE_DOMAIN}:${GOLANG_IMAGE_BRANCH} AS goimagick

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG SELECT_IMAGE_MAGICK_VERSION
ENV SELECT_IMAGE_MAGICK_VERSION=${SELECT_IMAGE_MAGICK_VERSION:-"6"}

COPY --from=imagick6 /opt/ImageMagick6 /
COPY --from=imagick7 /opt/ImageMagick7 /

RUN apt-get update \
 && apt-get -y --no-install-recommends install \
      wget \
      ca-certificates \
      build-essential \
      pkg-config \
      libfftw3-dev \
      libgif-dev \
      libjpeg-dev \
      libpng-dev \
      libtiff-dev \
      libwebp-dev \
      libwmf-dev \
      zlib1g-dev \
      libbz2-dev \
      liblzma-dev \
      libzstd-dev \
 && apt-get clean

RUN go env -w GO111MODULE="on"

RUN go env -w CGO_CFLAGS="-g -O2 $(pkg-config --static --cflags --libs MagickWand-${SELECT_IMAGE_MAGICK_VERSION})"
RUN go env -w CGO_CXXFLAGS="-g -O2 $(pkg-config --static --cflags --libs MagickWand-${SELECT_IMAGE_MAGICK_VERSION})"
RUN go env -w CGO_FFLAGS="-g -O2 $(pkg-config --static --cflags --libs MagickWand-${SELECT_IMAGE_MAGICK_VERSION})"
RUN go env -w CGO_LDFLAGS="-g -O2 $(pkg-config --static --cflags --libs MagickWand-${SELECT_IMAGE_MAGICK_VERSION})"

WORKDIR /go/src/github.com/takumin/docker-distroless-imagick
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
RUN go build -a -tags no_pkgconfig --ldflags '-s -w -extldflags "-static"' -o /usr/local/bin/app .

################################################################################
# Service stage
################################################################################

FROM ${DISTROLESS_IMAGE_DOMAIN}:${DISTROLESS_IMAGE_BRANCH} AS service

COPY --from=imagick6 /opt/ImageMagick6/etc/ /etc/
COPY --from=imagick6 /opt/ImageMagick6/usr/share/ /usr/share/
COPY --from=imagick7 /opt/ImageMagick7/etc/ /etc/
COPY --from=imagick7 /opt/ImageMagick7/usr/share/ /usr/share/
COPY --from=goimagick /usr/local/bin/app /

CMD ["/app"]
