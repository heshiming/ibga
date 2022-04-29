function _info {
    local _po="${*//$'\n'/$'\n'$(tput setaf 6)}"
    printf '%b' "$(tput setaf 6)$_po$(tput setaf 7)"
}

function _succeeded {
    local _po="${*//$'\n'/$'\n'$(tput setaf 2)}"
    printf '%b' "$(tput setaf 2)$_po$(tput setaf 7)"
}

function _err {
    #printf "$*" >&2
    local _po="${*//$'\n'/$'\n'$(tput setaf 1)}"
    printf '%b' "$(tput setaf 1)$_po$(tput setaf 7)"
}

function _wait_for_pid {
    local _pid=''
    while [ ! -f $* ]; do sleep 0.25; done
    _pid=$(<$*)
    echo "$_pid"
}

function repl() {
    printf "$1"'%.s' $(eval "echo {1.."$(($2))"}")
}
