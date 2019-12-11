#!/usr/bin/env bash
work_dir=$(echo $0 | awk -F'/' 'BEGIN {ORS="/"} {for ( i=0; ++i<NF;) print $i}')
[ "$#" -lt 3 ] && echo -e "Usage: $0 [options] <work_sub_dir> <container_name> <TAG>
work_sub_dir:
    Path relative to $0
container_name TAG:
    Set to username/container to push to Docker.io, e.g. myself/cakephp2-image 0.1.1
Note: Rename any existing images with docker tag <repository/image:tag> <new_repository/new_image:tag>" && exit 0
DIR=$1
NAME=$2
TAG=$3
usage="$0 <-f, --force> <-e> <-m, --make-space>
--force:
  Set docker daemon restart flag on
-e:
  Reset docker machine environment variables
--make-space:
  Remove exited containers to free some disk space"
while [[ "$#" -gt 0 ]]; do case $1 in
  -[fF]*|--force)
    docker-machine restart default;;
  -[eE]*)
    eval $(docker-machine env);;
  -[mM]*|--make-space)
    docker rm $(docker ps -q -f 'status=exited')
    docker volume rm $(docker volume ls -qf dangling=true);;
  -[hH]*|--help)
    echo -e "${usage}"
    exit 1;;
  *)
    DIR=$1
    NAME=$2
    TAG=$3
    shift;shift;;
esac; shift; done
pwd=`pwd`
cd $work_dir$DIR
[ -f DockerFile ] && mv DockerFile Dockerfile
cd $pwd
docker build -t $NAME:$TAG $work_dir$DIR || docker rm $(docker ps -q -f 'status=exited')
docker run -itd $NAME:$TAG
# docker login -u $DOCKER_USER -p $DOCKER_PASS
docker login
docker push $NAME:$TAG
