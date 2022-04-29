source $(dirname "$BASH_SOURCE")/_env.sh
source $(dirname "$BASH_SOURCE")/_utils.sh

function _run_socat {
    CMD=/usr/bin/socat
    ARGS="TCP-LISTEN:$IBG_PORT,fork,reuseaddr TCP:localhost:$IBG_PORT_INTERNAL,forever,shut-down"
    _info "• starting socat ($CMD $ARGS) ...\n"
    sudo /sbin/start-stop-daemon --start --pidfile $SOCAT_PIDFILE --make-pidfile --background --exec $CMD -- $ARGS
    SOCAT_PID=$(_wait_for_pid $SOCAT_PIDFILE)
    _info "  pid: $SOCAT_PID\n"
}
