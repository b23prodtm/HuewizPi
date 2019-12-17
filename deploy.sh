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
usage="Usage ${BASH_SOURCE[0]} <arch> [--local|--balena|--nobuild]"
arch=$1
target=$2
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
    sed -E -e "s/%%BALENA_MACHINE_NAME%%/${BALENA_MACHINE_NAME}/g" \
    -e "s/(Dockerfile\.)[^\.]*/\\1${DKR_ARCH}/g" \
    -e "s/(DKR_ARCH[=:-]+)[^\$ }]+/\\1${DKR_ARCH}/g" \
    -e "s/(IMG_TAG[=:-]+)[^\$ }]+/\\1${IMG_TAG}/g" \
    -e "s/(PHP_OWNER[=:-]+)[^\$ }]+/\\1${PHP_OWNER}/g" \
    $1 | tee $2
  shift; shift; done
}
setArch Dockerfile.template Dockerfile.${DKR_ARCH} \
docker-compose.yml docker-compose.${DKR_ARCH} \
.circleci/images/primary/Dockerfile.template .circleci/images/primary/Dockerfile.${DKR_ARCH}
eval $(cat ${arch}.env | grep BALENA_MACHINE_NAME)
while [ true ]; do
  eval $(ssh-agent)
  ssh-add ~/.ssh/*id_rsa
  [ $(which balena) > /dev/null ] && declare -a apps=($(sudo balena apps | awk '{if (NR>1) print $2}'))
  i="1..${#apps}"; echo "$i: ${apps[@]}"
  case $target in
    1|--local)
      echo "Cross-build may be enabled"
      bash -c "docker-compose -f docker-compose.${DKR_ARCH} build"
      break;;
    2|--balena)
      read -p "Where do you want to push [1-${#apps}] or give an IP? " apporip
      echo "Disabled cross-build"
      uncomment Dockerfile.template
      git commit -a -m "${DKR_ARCH} pushed to balena.io"
      if [ $(sudo which balena) > /dev/null ]; then
        sudo balena push ${apps[$apporip-1]}
      else
        git push -uf balena ${apps[$apporip-1]}
      fi
      break;;
    3|--nobuild)
      break;;
    *)
      read -p "What target docker's going to use (1:local, 2:balena, 3:nobuilt) ?" target
      ;;
  esac
done
