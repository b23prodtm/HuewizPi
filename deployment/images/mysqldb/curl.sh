#!/usr/bin/env bash
# Save the path to THIS script (before we go changing dirs)
TOPDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# The top of our source tree is the parent of this scripts dir
TOPDIR+="deployment/images/mariadb"
mkdir -p $TOPDIR
cd $TOPDIR || exit 1
MARIADB_MAJOR=${MARIADB_MAJOR:-10.4}
curl -L "https://raw.githubusercontent.com/docker-library/mariadb/master/$MARIADB_MAJOR/docker-entrypoint.sh" -o docker-entrypoint.sh
curl -L "https://raw.githubusercontent.com/docker-library/mariadb/master/$MARIADB_MAJOR/Dockerfile" -o Dockerfile.template
# patch Dockerfile with balenalib and cross-compilers
# shellcheck disable=SC1004
sed -i.orig -E -e 's/FROM\ ubuntu:bionic/FROM\ balenalib\/%%BALENA_MACHINE_NAME%%-ubuntu:bionic-build\
\#\ RUN\ [\ \"cross-build-start\"\ ]\
ARG\ DEBIAN_FRONTEND=noninteractive/' \
-e 's/(^CMD.*)/\#\ RUN\ [\ \"cross-build-end\"\ ]\
\1/' \
Dockerfile.template
MARIADB_VERSION=$(awk '/ENV MARIADB_VERSION/' < Dockerfile.template | awk 'BEGIN{ FS=" " }{ print $3 }' )
printf "Mariadb: %s\nImage: %s" "$MARIADB_MAJOR" "$MARIADB_VERSION" | tee VERSION
printf "[Experimental] build of MariaDB for ARM (deployment/images/secondary)"
printf "Find a stable build at lsioarmhf/mariadb."
