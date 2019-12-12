#!/usr/bin/env bash
MARK_BEGIN_ARM="#BEGIN\sARM"
MARK_END_ARM="#END\sARM"
MARKERS_ARM="/${MARK_BEGIN_ARM}/,/${MARK_END_ARM}/"
comment_ARM() {
  [ "$#" -eq 0 ] && echo "comment had with no file input" && exit 0
  sed -i.old -E ${MARKERS_ARM}s/^/#/g $1
}
uncomment_ARM() {
  [ "$#" -eq 0 ] && echo "comment had with no file input" && exit 0
  sed -i.old -E ${MARKERS_ARM}s/^#\s//g $1
}
usage="Usage $0 <arch>"
arch=$1
while [ true ]; do
  case $arch in
    1|arm32*|armv7l|armhf)
      arch="arm32v7"
      uncomment_ARM docker-compose.yml
      break;;
    2|arm64*|aarch64)
      arch="arm64v8"
      uncomment_ARM docker-compose.yml
      break;;
    3|amd64|x86_64)
      arch="amd64"
      comment_ARM docker-compose.yml
      break;;
    *)
      echo $usage
      read -p "Set docker machine architecture ARM32, ARM64 bits or X86-64 (choose 1, 2 or 3) ? " arch
      ;;
  esac
done
ln -vsf ${arch}.env .env
eval $(cat ${arch}.env)
function setArch() {
  while [ "$#" -gt 0 ]; do
    sed -i.old -E -e s/"%%BALENA_MACHINE_NAME%%"/"${BALENA_MACHINE_NAME}"/ \
-e "s/\\\$DKR_ARCH/${DKR_ARCH}/g" \
-e "s/(Dockerfile\.)[^\.]*/\\1${DKR_ARCH}/g" \
$1
  shift; done
}
setArch Dockerfile.${DKR_ARCH} docker-compose.yml
eval $(cat ${arch}.env | grep BALENA_MACHINE_NAME)
