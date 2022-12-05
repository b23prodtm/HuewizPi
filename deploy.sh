#!/usr/bin/env bash
printf "%s\n" "-- check git mode auto LF"
grep ".sh" < .gitattributes
printf "%s\n" "--"
balena_deploy "${BASH_SOURCE[0]}" "$@"
