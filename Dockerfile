FROM debian:bookworm-slim

# set -euxo pipefail
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "xtrace", "-o", "pipefail", "-c"]

RUN \
  apt-get update && apt-get install -y \
    # To download:
    wget \
    # Error initializing NSS [...]: libsoftokn3.so: [...]: No such file or directory
    libnss3; \
  rm -rf /var/lib/apt/lists/*; \
\
  useradd \
    --create-home \
    --shell=/usr/sbin/nologin \
    browser

USER browser
WORKDIR /home/browser
ARG brow_version=v0.9.11.0

RUN \
  wget \
    --progress=bar:force:noscroll \
    -O browservice.AppImage \
    https://github.com/ttalvitie/browservice/releases/download/$brow_version/browservice-$brow_version-$(uname -m).AppImage; \
\
  chmod +x browservice.AppImage; \
  ./browservice.AppImage --appimage-extract; \
  rm browservice.AppImage; \
  mv squashfs-root browservice-root;

USER root
# https://github.com/ttalvitie/browservice/tree/v0.9.5.1#suid-sandbox-helper-not-found
RUN \
  chown root:root browservice-root/opt/browservice/chrome-sandbox; \
  chmod 4755 browservice-root/opt/browservice/chrome-sandbox

USER browser

CMD rm -f /home/browser/.browservice/cefdata/SingletonLock; \
  exec /home/browser/browservice-root/AppRun \
    --data-dir=/home/browser/.browservice/cefdata \
    --vice-opt-http-listen-addr=0.0.0.0:8080
