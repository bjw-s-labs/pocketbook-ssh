FROM --platform=amd64 ubuntu:latest AS build

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV PATH=/source/sdk/SDK_6.3.0/SDK-B288/usr/bin:$PATH
ENV HOST=arm-obreey-linux-gnueabi

ARG DROPBEAR_TAG="DROPBEAR_2025.87"
ARG OPENSSH_TAG="V_9_9_P2"

RUN \
  apt-get update && \
  apt-get install -y \
    autoconf \
    build-essential \
    git \
    libmpfr-dev && \
  ln -s /usr/lib/x86_64-linux-gnu/libmpfr.so.6 /usr/lib/x86_64-linux-gnu/libmpfr.so.4

WORKDIR /source/sdk
RUN \
  git clone https://github.com/pocketbook/SDK_6.3.0.git && \
  cd SDK_6.3.0 && \
  git checkout 6.5 && \
  SDK-B288/bin/update_path.sh

WORKDIR /srv/jenkins/workspace/SDK-GEN/output-B288/host
RUN <<EOF
  ln -s /source/sdk/SDK_6.3.0/SDK-B288/usr
EOF

WORKDIR /source
RUN <<EOF
  git clone --branch "${DROPBEAR_TAG}" --depth 1 https://github.com/mkj/dropbear.git dropbear
  git clone --branch "${OPENSSH_TAG}" --depth 1 https://github.com/openssh/openssh-portable.git openssh-portable
EOF

WORKDIR /source/dropbear
COPY patches /source/patches
COPY <<EOF localoptions.h
#define DROPBEAR_MLKEM768 0
#define DSS_PRIV_FILENAME "/mnt/ext1/applications/dropbear/dss_host_key"
#define RSA_PRIV_FILENAME "/mnt/ext1/applications/dropbear/rsa_host_key"
#define ECDSA_PRIV_FILENAME "/mnt/ext1/applications/dropbear/ecdsa_host_key"
#define ED25519_PRIV_FILENAME "/mnt/ext1/applications/dropbear/ed25519_host_key"
#define SFTPSERVER_PATH "/mnt/ext1/applications/dropbear/sftp-server"
EOF

RUN <<EOF
  for patch in ../patches/dropbear-2025.87-*.patch;do
    patch -p1 < $patch
  done

  ./configure --host=$HOST CC="$HOST"-gcc LD="$HOST"-ld --disable-zlib --disable-wtmp --disable-lastlog --disable-syslog --disable-utmpx --disable-utmp --disable-wtmpx --disable-loginfunc --disable-pututxline --disable-pututline --enable-bundled-libtom --disable-pam
  make clean
  make -j PROGRAMS="dropbear dropbearkey"
EOF

WORKDIR /source/openssh-portable
RUN <<EOF
  autoreconf
  ./configure --host=$HOST --without-openssl --without-zlib --without-pam --without-xauth CC="$HOST"-gcc LD="$HOST"-ld
  make clean
  make -j sftp-server
EOF

FROM ubuntu:latest
WORKDIR /output
COPY --chown=root:root --chmod=777 --from=build /source/openssh-portable/sftp-server /output/sftp-server
COPY --chown=root:root --chmod=777 --from=build /source/dropbear/dropbear /output/dropbear
COPY --chown=root:root --chmod=777 --from=build /source/dropbear/dropbearkey /output/dropbearkey
