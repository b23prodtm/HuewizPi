#!/usr/bin/env bash
printf "%s\n" "-- check git mode auto LF"
cat .gitattributes | grep ".sh"
printf "%s\n" "--"
balena_deploy "${BASH_SOURCE[0]}" "$@"
