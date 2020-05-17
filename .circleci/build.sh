#!/usr/bin/env bash
work_dir=$(cd `dirname $BASH_SOURCE` && pwd)
usage="
Usage: $0
    CircleCI needs a primary image with docker-in-docker backend.
    To build it use deployment/build.sh script to push to image registry and tag it:
        deployment/images/build.sh secondary betothreeprod/cci-mariadb arm64v8-latest
Then you can run composition process: sudo docker-compose up --build"
[ ! $(which circleci) > /dev/null ] && curl -fLSs https://circle.ci/cli | bash
source ./deploy.sh "$1" --docker
sed -e /custom_checkout:/s/"\"\""/"\"\/tmp\/_circleci_local_build_repo\""/g ${work_dir}/config.yml | circleci config process - > ${work_dir}/config-compat.yml
circleci local execute -c ${work_dir}/config-compat.yml || echo -e $usage

