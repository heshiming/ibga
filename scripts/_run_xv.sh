source $(dirname "$BASH_SOURCE")/_env.sh
source $(dirname "$BASH_SOURCE")/_utils.sh


function _run_xvfb {
    CMD=/usr/bin/Xvfb
    ARGS="$DISPLAY -ac -screen 0 1024x768x16 +extension RANDR"
    _info "• starting xvfb ($CMD $ARGS) ...\n"
    sudo /sbin/start-stop-daemon --start --pidfile $XVFB_PIDFILE --make-pidfile --background --exec $CMD -- $ARGS
    XVFB_PID=$(_wait_for_pid $XVFB_PIDFILE)
    _info "  pid: $XVFB_PID\n"
    local SCREEN_READY=0
    local TIMER=0
    # Xvfb for some reason, may crash upon start. When this happens, it fails silently.
    # One way to make sure that X is ready is to use xdpyinfo to probe the display. If
    # probe fails after several seconds, Xvfb may have crashed. At this point,
    # start-stop-daemon should report pid being nonexistent. Usually, the next run will
    # work.
    while [ $SCREEN_READY != 1 ]; do
        xdpyinfo -display $DISPLAY >/dev/null 2>&1 && SCREEN_READY=1 || SCREEN_READY=0
        sleep 0.5
        ((TIMER=TIMER+1))
        if [ $TIMER == 10 ]; then
            _info "    still waiting for display $DISPLAY to be ready ...\n"
        fi
        if [ $TIMER -gt 20 ]; then
            _err "    display timed out, will try again ...\n"
            _info "  stopping xvfb ...\n"
            sudo /sbin/start-stop-daemon --stop --pidfile $XVFB_PIDFILE
            # potential call stack overflow
            _run_xvfb
            return 0
        fi
    done
    _info "  display $DISPLAY is ready\n"
}

function _run_vnc {
    CMD=/usr/bin/x11vnc
    ARGS="-forever -shared -rfbport 5900 -o $VNC_LOGFILE -display $DISPLAY"
    PWFILE="$HOME_DIR/.vnc/passwd"
    mkdir -p $HOME_DIR/.vnc
    rm -f "$PWFILE" || true
    if [ "$IBGA_VNC_PASSWORD" ]; then
        $CMD -storepasswd "$IBGA_VNC_PASSWORD" "$PWFILE" > /dev/null 2>&1
        ARGS="$ARGS -rfbauth $PWFILE"
    fi
    _info "• starting x11vnc ($CMD $ARGS) ...\n"
    sudo /sbin/start-stop-daemon --start --pidfile $VNC_PIDFILE --make-pidfile --background --exec $CMD -- $ARGS
    VNC_PID=$(_wait_for_pid $VNC_PIDFILE)
    _info "  pid: $VNC_PID\n"
}

function _run_novnc {
    CMD=$NOVNC_DIR/utils/novnc_proxy
    ARGS="--listen 5800 --vnc localhost:5900"
    echo "<html><head><meta http-equiv=\"refresh\" content=\"0; URL=/vnc.html?autoconnect=true&reconnect=true\"/></head></html>" | sudo tee $NOVNC_DIR/index.html 1>/dev/null
    _info "• starting novnc ($CMD $ARGS) ...\n"
    sudo /sbin/start-stop-daemon --start --pidfile $NOVNC_PIDFILE --make-pidfile --background --exec $CMD -- $ARGS
    NOVNC_PID=$(_wait_for_pid $NOVNC_PIDFILE)
    _info "  pid: $NOVNC_PID\n"
}
