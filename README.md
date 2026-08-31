# HuewizPi

HuewizPi is a Balena-first Raspberry Pi application that bundles a Wi-Fi access-point service, Passbolt, and Homebridge.

[![CI](https://github.com/b23prodtm/HuewizPi/actions/workflows/ci.yml/badge.svg)](https://github.com/b23prodtm/HuewizPi/actions/workflows/ci.yml)
[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/HuewizPi)

## Deployment (Balena Cloud)

This is the supported end-user deployment method.

1. Create or select a Balena Cloud application/fleet.
2. Connect this GitHub repository (or click the balena deploy button).
3. Set required environment variables in Balena Cloud:
   - `MYSQL_PASSWORD`
   - `APP_FULL_BASE_URL` (for example `https://<device-or-public-url>`)
4. Deploy and wait for services to start automatically.

No Docker CLI, Docker Compose CLI, balena CLI, or shell installation script is required for end users.

## Development (Docker Compose)

Local Docker Compose is for developers/maintainers only.

```bash
docker compose -f docker-compose.x86_64 config
docker compose -f docker-compose.x86_64 build
docker compose -f docker-compose.x86_64 up -d db passbolt homebridge
docker compose -f docker-compose.x86_64 ps
docker compose -f docker-compose.x86_64 logs
docker compose -f docker-compose.x86_64 down -v
```

For ARM devices, use `docker-compose.armhf` or `docker-compose.aarch64`.

## CI (GitHub Actions)

GitHub Actions validates the multi-service Compose stack by:

- checking Compose syntax (`docker compose config`)
- building services
- starting the stack for CI-safe services
- waiting for service healthchecks
- verifying service availability
- collecting logs on failure
- cleaning up containers/volumes

## Troubleshooting

- **Passbolt not reachable**: verify `APP_FULL_BASE_URL` and exposed ports.
- **Database startup issues**: check `MYSQL_PASSWORD` and database logs.
- **Hardware-specific startup issues (Wi-Fi/deCONZ)**: verify Raspberry Pi device access (`/dev/ttyAMA0`), Balena device type, and fleet host configuration.

## Balena compatibility notes

- Compose files use Docker Compose `2.1` syntax for Balena Cloud compatibility.
- Persistent data uses named volumes.
- Runtime configuration is environment-variable driven.
- ARM support is preserved via architecture-specific Dockerfiles and Compose files.

## License

Apache License 2.0
