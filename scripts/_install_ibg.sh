INSTALLER_FN=ibgateway-latest-standalone-linux-x64.sh

source $(dirname "$BASH_SOURCE")/_env.sh
source $(dirname "$BASH_SOURCE")/_utils.sh

function _ibg_exec_exists {
    local _ret=''
    if [ -f "$IBG_DIR/$IBG_EXEC" ]; then
        tmp_count=$(ls -1q $IBG_DIR/Jts/ibgateway/jars/*.tmp 2> /dev/null | wc -l | xargs)
        if [ $tmp_count = 0 ]; then
            _ret=true
        fi
    fi
    echo "$_ret"
}

function _ibg_installer_exists {
    local _ret=''
    if [ -f "$IBG_DIR/$INSTALLER_FN" ]; then
        _ret=true
    fi
    echo "$_ret"
}

function _install_ibg {
    # Early exit if IBG is already installed
    ex=$(_ibg_exec_exists)
    if [ "$ex" = true ]; then
        _succeeded "• found IBG at $IBG_DIR/$IBG_EXEC.\n"
        return 0
    fi

MSG="----------------------------
 IB Gateway Installation $1
----------------------------
"
    _info "$MSG"
    _info "• will install into $IBG_DIR\n"

    for (( i=5; i>0; i--)); do sleep 1 & wait; done

    mkdir -p {$IBG_DIR,$IBG_SETTINGS_DIR}
    ex=$(_ibg_installer_exists)
    if [ "$ex" = true ]; then
        _info "• will use the existing installer: $IBG_DIR/$INSTALLER_FN ...\n"
    else
        show_text 1024 768 "Downloading IBG installer ..." &
        local stpid="$!"
        URL="https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/$INSTALLER_FN"
        _info "• downloading from $URL ...\n"
        curl -k "$URL" -# -o $IBG_DIR/$INSTALLER_FN
        chmod +x $IBG_DIR/$INSTALLER_FN
        sudo kill -SIGTERM $stpid
    fi
    show_text 1024 768 "Installing IBG ..." &
    local stpid="$!"
    cd $IBG_DIR
    _info "• installing ...\n"
    rm -rf $IBG_DIR/Jts/
    rm -rf $IBG_DIR/$INSTALLER_FN.*
    printf '%s/Jts/ibgateway\n\n' "$IBG_DIR" | DISPLAY="" ./$INSTALLER_FN
    sudo kill -SIGTERM $stpid

    ex=$(_ibg_exec_exists)
    if [ "$ex" = true ]; then
        _succeeded "• found IBG at $IBG_DIR/$IBG_EXEC.\n"
        JAUTO_PATCH="-agentpath:/opt/jauto.so=$JAUTO_INPUT"
        OPTIONS_FILE="$IBG_DIR/Jts/ibgateway/ibgateway.vmoptions"
        grep -qxF -- "$JAUTO_PATCH" $OPTIONS_FILE || (echo "$JAUTO_PATCH" >> $OPTIONS_FILE && \
            _info "• ibgateway.vmoptions patched for jauto\n")
        return 0
    fi

    _err "• installation has failed.\n"
    rm $IBG_DIR/$INSTALLER_FN
    return 1
}
