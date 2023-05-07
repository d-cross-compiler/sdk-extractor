#!/usr/bin/env bash

# Environment variables:
# EXTRACTOR_VERSION: the version of the release (required)
# EXTRACTOR_TARGET_ARCH: the target architecture (required)
# EXTRACTOR_TARGET_OS: the target operating system (required)
# EXTRACTOR_TARGET_VERSION: the target operating system version (required)

set -xueo pipefail

release_name="$EXTRACTOR_TARGET_ARCH-unknown-${EXTRACTOR_TARGET_OS}${EXTRACTOR_TARGET_VERSION}"
archive_name="sdk-$EXTRACTOR_VERSION-$release_name.tar.xz"
[ "$EXTRACTOR_TARGET_ARCH" = 'x86_64' ] && arch='amd64' || arch="$EXTRACTOR_TARGET_ARCH"

freebsd() {
  local url_base='http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/'
  local base_set_url="$url_base/$arch/$EXTRACTOR_TARGET_VERSION-RELEASE/base.txz"

  download "$base_set_url" base.txz
  unarchive base.txz ./lib ./usr/include ./usr/lib

  archive \
    "$release_name/lib" \
    "$release_name/usr/include" \
    "$release_name/usr/lib"
}

netbsd() {
  local url_base="https://cdn.netbsd.org/pub/NetBSD/NetBSD-$EXTRACTOR_TARGET_VERSION/$arch/binary/sets/"
  local base_set_url="$url_base/base.tar.xz"
  local comp_set_url="$url_base/comp.tar.xz"

  download "$base_set_url" base.tar.xz
  download "$comp_set_url" comp.tar.xz

  unarchive base.tar.xz ./lib ./usr/lib ./usr/include
  unarchive comp.tar.xz ./usr/lib ./usr/include

  archive \
    "$release_name/lib" \
    "$release_name/usr/include" \
    "$release_name/usr/lib"
}

openbsd() {
  local set_version=$(sed 's/\.//' <<< "$EXTRACTOR_TARGET_VERSION")
  local url_base="https://mirror.fra10.de.leaseweb.net/pub/OpenBSD/$EXTRACTOR_TARGET_VERSION/$arch"
  local base_set_url="$url_base/base$set_version.tgz"
  local comp_set_url="$url_base/comp$set_version.tgz"

  download "$base_set_url" base.tgz
  download "$comp_set_url" comp.tgz

  unarchive base.tgz ./usr/lib ./usr/local/lib ./usr/share/relink/usr/lib
  unarchive comp.tgz ./usr/include ./usr/lib

  archive \
    "$release_name/usr/include" \
    "$release_name/usr/lib" \
    "$release_name/usr/local/lib" \
    "$release_name/usr/share/relink/usr/lib"
}

download() {
  curl -L -o "$2" --retry 3 "$1"
}

archive() {
  tar -c \
    -f "$archive_name" \
    --use-compress-program pixz \
    "$@"
}

unarchive() {
  local archive="$1"
  shift

  mkdir -p "$release_name"
  tar -x -f "$archive" -C "$release_name" --strip-components 1 "$@"
}

case "$EXTRACTOR_TARGET_OS" in
  freebsd) freebsd;;
  netbsd) netbsd;;
  openbsd) openbsd;;
  *)
    echo "Unhandled platform: $release_name"
    exit 1
    ;;
esac
