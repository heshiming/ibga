<div align="center">

# IB Gateway Automation (IBGA)

**IB Gateway in headless docker container.**

[![Docker Pulls](https://img.shields.io/docker/pulls/heshiming/ibga?logo=docker&logoColor=white&label=pulls)](https://hub.docker.com/r/heshiming/ibga)
![Image size ~140 MB](https://img.shields.io/badge/image_size-~140_MB-2496ED?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/linux-amd64%20%7C%20arm64-888888)
[![Docs](https://img.shields.io/badge/docs-online-2ea44f)](https://heshiming.github.io/ibga/)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-yellow)](LICENSE)

</div>

---

IBGA is <a href="https://www.interactivebrokers.com/en/trading/ibgateway-latest.php">IB Gateway</a> in headless mode. It is a container image preloaded with scripts for automating user interactions with IBG, including TOTP (IBKR Mobile Authenticator App) automation and second factor support.

<img src="docs/images/ibga-video.gif" alt="IBGA in action" width="100%">

## Lightweight by design

* **Near-zero memory footprint** — the automation layer is plain bash scripts plus a small JVMTI agent and a few C utilities
* **~140 MB image** — built on `debian:bookworm-slim`, multi-arch (`linux/amd64`, `linux/arm64`)

## Benefits

* A "docker compose" flavored configuration
* Store username, password, time zone and other options in one place
* Automatic installation and easy upgrade of IBG
* Automatic handling of daily restarts beyond the one week limit, upon exit or crash
* Automatic handling of paper trading confirmation and options dialog
* Automatic daily export of logs
* Retaining of settings after an upgrade
* A disposable container design
* <a href="https://heshiming.github.io/ibga/guide/#how-to-setup-totp-mobile-authenticator-app-automated-login">Support Mobile Authenticator App automation</a> (as of Nov 3, 2024)
* <a href="https://heshiming.github.io/ibga/guide/#how-is-two-factor-authentication-interactive-brokers-secure-login-system-sls-handled-in-ibga">Support two-factor authentication</a> (as of Nov 11, 2022)

## Quick start

```yaml
# docker-compose.yml
services:
  my-ibga:
    image: heshiming/ibga
    restart: unless-stopped
    environment:
      - TERM=xterm
      - IB_USERNAME=username
      - IB_PASSWORD=password
      - IB_REGION=America
      - IB_TIMEZONE=America/New York
      - IB_LOGINTAB=IB API
      - IB_LOGINTYPE=Live Trading
      - IB_LOGOFF=11:55 PM
      - IB_APILOG=data
      - IB_LOGLEVEL=Error
    volumes:
      - ./run/program:/home/ibg
      - ./run/settings:/home/ibg_settings
    ports:
      - "15800:5800"   # noVNC web viewer
      - "4000:4000"    # IB Gateway API
```

```bash
docker compose up -d
```

Documentation: <a href="https://heshiming.github.io/ibga/">https://heshiming.github.io/ibga/</a>

## Under the hood

* IBGA runs in a set of bash scripts
* <a href="https://heshiming.github.io/jauto/">JAuto, a JVMTI agent</a> determines screen locations of windows, text boxes, and buttons
* <a href="https://github.com/jordansissel/xdotool">xdotool</a> simulates keyboard and mouse input
* <a href="https://en.wikipedia.org/wiki/Xvfb">Xvfb</a>, <a href="https://github.com/LibVNC/x11vnc">x11vnc</a>, and <a href="https://novnc.com/">noVNC</a> provide a VNC-capable <a href="https://en.wikipedia.org/wiki/X_Window_System">X11</a> environment for IBG
* <a href="https://www.nongnu.org/oath-toolkit/oathtool.1.html">oathtool</a> generates TOTP passcodes

## Contributing

Contributions are welcome and not restricted in any way: bug reports, pull requests, documentation fixes, and questions via issues.

## License

Apache-2.0 — see [LICENSE](LICENSE).
