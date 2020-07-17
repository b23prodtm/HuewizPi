#!/usr/bin/env bash
REV="https://raw.githubusercontent.com/b23prodtm/docker-systemctl-replacement/master/files/docker/systemctl3.py"
curl -L "$REV" -o /usr/local/bin/systemctl3
chmod +x /usr/local/bin/systemctl3
systemctl3 "$@"
