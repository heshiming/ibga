HOME_DIR="/home/ibg"
IBG_DIR="${IBG_DIR:-$HOME_DIR}"
IBG_SETTINGS_DIR="${IBG_SETTINGS_DIR:-/home/ibg_settings}"
IBG_PORT_INTERNAL="${IBG_PORT_INTERNAL:-9000}"
IBG_PORT="${IBG_PORT:-4000}"
IBG_EXEC=Jts/ibgateway/ibgateway
IBG_DOWNLOAD_URL="${IBG_DOWNLOAD_URL:-https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/ibgateway-latest-standalone-linux-x64.sh}"
IBGA_LOG_EXPORT_DIR="${IBGA_LOG_EXPORT_DIR:-$IBG_SETTINGS_DIR/exported_logs}"
XVFB_PIDFILE=/var/run/xvfb.pid
VNC_PIDFILE=/var/run/x11vnc.pid
VNC_LOGFILE=/var/log/x11vnc.log
NOVNC_DIR=$(find /opt -maxdepth 1 -type d -name "noVNC*")
NOVNC_PIDFILE=/var/run/novnc.pid
SOCAT_PIDFILE=/var/run/socat.pid
DISPLAY=:0
JAUTO_INPUT=/tmp/ibg-jauto.in

export DISPLAY
