# AGENTS.md

IBGA: headless Interactive Brokers IB Gateway in Docker, driven by bash scripts that
click the Swing GUI via the JAuto JVMTI agent (`/tmp/ibg-jauto.in` pipe) and `xdotool`
on Xvfb. No tests, lint, or CI — verify changes by `./build.sh` then `docker compose up`
and watching `docker compose logs -f` / noVNC at `http://localhost:15800/`.

## Architecture

`scripts/manager.sh` (entrypoint) sources everything into one shell: Xvfb/VNC/noVNC
(`_run_xv.sh`), socat 4000→9000 (`_run_socat.sh`), IBG install + jauto vmoptions patch
(`_install_ibg.sh`), then `_run_ibg.sh`: start IBG → fill login form → polling
`_maintenance_cycle` that handles dialogs (login failed, paper warning, welcome/TOTP/
two-factor, existing session, token expiry), plus options check and log export. Daily
IBG logoff just kills the process; the outer loop restarts. Fatal error → `sleep infinity`.

## JAuto protocol (scripts/_jauto.sh)

- Write `OUTPUT_FILE|COMMAND?arg&arg` to `/tmp/ibg-jauto.in`; result appears in
  OUTPUT_FILE. Empty result = literal `none`; failure = `!timeout!`.
- `window_class=` is a case-insensitive **substring** (IBGA relies on partial internal
  packages like `twslaunch.jconnection`); `window_title=` is **exact** (case-insensitive).
- Queries default to **JFrame only**; dialogs need `window_type=dialog` (token-expiry
  dialog: use `window_type=dialog&is_active=1`).
- One comma-delimited line per component: `x,y,w,h,mx,my,text,...`; `mx/my` is the click
  point. Colon-less fields become positional keys (`F1` = class name). List/tree children
  have `(row)` class suffix with index in `F2`. Text can contain commas — parse only via
  `_jauto_parse_props`/`_jauto_escape`.
- Manual probe in container: `echo "/tmp/out|list_ui_components?window_type=dialog" > /tmp/ibg-jauto.in; cat /tmp/out`

## Conventions

- `_`-prefixed files are sourced libraries; only `manager.sh` executes. Functions:
  `_public`, `__private`. Run state = `G_*` globals (0 pending / 1 in progress / 2 done);
  config = env vars `IB_*`/`IBGA_*` (docs/references/config-args.md).
- UI interaction pattern everywhere: `_call_jauto` query → parse props →
  `xdotool mousemove mx my click 1`.

## Gotchas

- All UI matching is **exact-case English text**: env values (`IB_LOGINTAB=IB API`),
  labels, buttons. Paper login clicks `Paper Log In`, not `Log In`.
- Skip files in `$IBG_SETTINGS_DIR` (`/home/ibg_settings`) cache GUI state:
  `skip_option_check2`, `skip_login_combobox_*`. Delete them when settings changes seem ignored.
- Install detection also rejects leftovers: `*.tmp` in `Jts/ibgateway/jars/` = partial install.
- Liveness check is `ps -A | grep java` — any java process counts.
- `G_PAPER_TRADING_WARNING_DONE` is re-armed per login pass (paper accounts show the
  warning on every re-login).
- Root `docker-compose.yml` is a local dev config with real credentials commented out —
  never commit credentials. Root `patch` is a historical diff, not build input.
- `jauto/` is an untracked vendored copy used only by `private_build.sh`/`private_dockerfile`;
  public builds download JAuto v1.0.0 (`JAUTO_VER` in `dockerfile`).
- VNC is unauthenticated unless `IBGA_VNC_PASSWORD` (max 8 effective chars); keep 5800 local.
