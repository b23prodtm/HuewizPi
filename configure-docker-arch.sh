#!/usr/bin/env bash
setMARKERS(){
  export MARK_BEGIN="$1"
  export MARK_END="$2"
}
comment() {
  [ "$#" -eq 0 ] && echo "missing file input" && exit 0
  sed -i.old -E -e "s/[# ]*(${MARK_BEGIN})/# \\1/g" -e "s/[# ]*(${MARK_END})/# \\1/g" $1;
}
uncomment() {
  [ "$#" -eq 0 ] && echo "missing file input" && exit 0
  sed -i.old -E -e "s/[# ]+(${MARK_BEGIN})/\\1/g" -e "s/[# ]+(${MARK_END})/\\1/g" $1;
}
setMARKERS "RUN \[ \"cross-build-start\" \]" "RUN \[ \"cross-build-end\" \]"
usage="Usage $0 <arch>"
arch=$1
while [ true ]; do
  case $arch in
    1|arm32*|armv7l|armhf)
      arch="arm32v7"
      uncomment Dockerfile.template
      break;;
    2|arm64*|aarch64)
      arch="arm64v8"
      uncomment Dockerfile.template
      break;;
    3|amd64|x86_64)
      arch="amd64"
      comment Dockerfile.template
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
  while [ "$#" -gt 1 ]; do
    cp -f $1 $1.old
    sed -E -e s/"%%BALENA_MACHINE_NAME%%"/"${BALENA_MACHINE_NAME}"/ \
    -e "s/\\\$DKR_ARCH/${DKR_ARCH}/g" \
    -e "s/(Dockerfile\.)[^\.]*/\\1${DKR_ARCH}/g" \
    -e "/image:/s/(betothreeprod[^\-]*).*/\\1-${DKR_ARCH}/g" \
    $1 | tee $2
  shift; shift; done
}
setArch docker-compose.yml docker-compose.${DKR_ARCH} Dockerfile.template Dockerfile.${DKR_ARCH}
eval $(cat ${arch}.env | grep BALENA_MACHINE_NAME)
