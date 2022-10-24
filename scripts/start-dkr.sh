#!/usr/bin/env bash
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# shellcheck disable=SC1090
. "$scriptsd/.env" && . "$scriptsd/common.env"
balena_deploy "${BASH_SOURCE[0]}" "$BALENA_ARCH" --docker 0
docker-compose -f "docker-compose.${BALENA_ARCH}" up
