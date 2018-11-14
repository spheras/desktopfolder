#!/bin/bash
set -e

VERSION="1.0.10"
NAME="desktopfolder"
./git-archive-all.sh --format tar --prefix ${NAME}-${VERSION}/ --verbose -t HEAD ${NAME}-${VERSION}.tar
xz -9 "${NAME}-${VERSION}.tar"

gpg --default-key 5FA3600AF709CB11B898320892DED901DA15CC0D --armor --detach-sign "${NAME}-${VERSION}.tar.xz"
gpg --verify "${NAME}-${VERSION}.tar.xz.asc"
