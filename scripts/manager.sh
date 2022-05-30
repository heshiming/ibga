#!/bin/bash

if [ ! -z "$IB_TIMEZONE" ]; then
    sudo ln -fs /usr/share/zoneinfo/${IB_TIMEZONE// /_} /etc/localtime
    sudo dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
fi

source $(dirname "$BASH_SOURCE")/_env.sh
source $(dirname "$BASH_SOURCE")/_utils.sh
source $(dirname "$BASH_SOURCE")/_run_xv.sh
source $(dirname "$BASH_SOURCE")/_run_socat.sh
source $(dirname "$BASH_SOURCE")/_install_ibg.sh
source $(dirname "$BASH_SOURCE")/_run_ibg.sh

sudo chown ibg:ibg "$IBG_DIR"
sudo chown ibg:ibg "$IBG_SETTINGS_DIR"
sudo chown ibg:ibg "$IBGA_LOG_EXPORT_DIR"

MSG="------------------------------------------------
 Manager Startup / $(date)
------------------------------------------------
"
_info "$MSG"

_run_xvfb
_run_vnc
_run_novnc
_run_socat

SC_PATH="$(dirname $(readlink -f $0))"
INSTALLED=''

# Try installation 10 times
trial=0
while [ $trial -lt 10 ] ; do
    trial=$[$trial+1]
    _install_ibg "$trial"
    install_status=$?
    if [ $install_status -eq 0 ]; then
        INSTALLED=true
        break
    fi
    _info "• manager will retry installation in 60s ($[$trial+1] of 10) ...\n"
    for (( i=10; i>0; i--)); do sleep 1 & wait; done
done

if [ "$INSTALLED" = true ] ; then
    _run_ibg
else
    _info "• manager is shutting down due to installation failure.\n"
fi
