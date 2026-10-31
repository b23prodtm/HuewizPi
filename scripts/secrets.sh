#!/usr/bin/env bash
# shellcheck shell=bash
# Resolve secrets without baking them into images or compose files.
# Lookup order for NAME:
#   1. environment variable NAME (Balena fleet/device variable)
#   2. file referenced by NAME_FILE
#   3. ${SECRETS_DIR}/NAME (Docker/Balena secrets mount, default /run/secrets)
#   4. ${SECRETS_STORE}/NAME (persisted on the hapwizard volume)
#   5. generated random value (only when a 2nd argument "generate" is given),
#      persisted to ${SECRETS_STORE} with mode 600.
SECRETS_DIR="${SECRETS_DIR:-/run/secrets}"
SECRETS_STORE="${SECRETS_STORE:-/etc/hapwizard/secrets}"

function secret_get() {
  local name="$1" mode="${2:-}" file value
  value="${!name:-}"
  if [ -z "$value" ]; then
    file="${name}_FILE"; file="${!file:-}"
    [ -n "$file" ] && [ -r "$file" ] && value="$(cat "$file")"
  fi
  [ -z "$value" ] && [ -r "${SECRETS_DIR}/${name}" ] && value="$(cat "${SECRETS_DIR}/${name}")"
  [ -z "$value" ] && [ -r "${SECRETS_STORE}/${name}" ] && value="$(cat "${SECRETS_STORE}/${name}")"
  if [ -z "$value" ] && [ "$mode" = "generate" ]; then
    value="$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)"
    ( umask 077; mkdir -p "${SECRETS_STORE}" && printf '%s' "$value" > "${SECRETS_STORE}/${name}" )
  fi
  printf '%s' "$value"
}

# export_secrets: resolve the secrets used by this project into the environment.
function export_secrets() {
  PRIV_PASSWD="$(secret_get AP_PASSWORD generate)"
  [ -n "${PRIV_PASSWD}" ] && export PRIV_PASSWD
  WAN_PASSWD="$(secret_get WIFI_PASSWORD)"
  export WAN_PASSWD
  PRIV_SSID="${AP_SSID:-${PRIV_SSID:-HuewizPi}}"
  WAN_SSID="${WIFI_SSID:-${WAN_SSID:-}}"
  export PRIV_SSID WAN_SSID
}
