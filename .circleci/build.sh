#!/usr/bin/env bash
work_dir=$(echo $0 | awk -F'/' 'BEGIN {ORS="/"} {for ( i=0; ++i<NF;) print $i}')
source ./deploy.sh "$1" --nobuild
git commit -a -m "$1 arch to push"
sed -e /custom_checkout:/s/"\"\""/"\"\/tmp\/_circleci_local_build_repo\""/g $work_dir/config.yml | circleci config process - > $work_dir/config-compat.yml
circleci local execute -c $work_dir/config-compat.yml || echo -e $usage
