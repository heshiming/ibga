#!/bin/bash


source $(dirname "$BASH_SOURCE")/_env.sh
source $(dirname "$BASH_SOURCE")/_utils.sh
source $(dirname "$BASH_SOURCE")/_jauto.sh


function _wait_for_jauto {
    _info "• waiting for jauto availability ...\n"
    while true; do
        local JAS=$(_call_jauto "ping")
        if [ $JAS == "pong" ]; then
            _info "  jauto is ready\n"
            break
        else
            _err "  jauto is not ready: $JAS, will try again ...\n"
        fi
    done
}


function _wait_for_main_window {
    _info "• waiting for main window ...\n"
    local OUTPUT=$(_call_jauto_wait "get_windows?window_class=ibgateway" 1)
    readarray -t WINDOWS <<< "$OUTPUT"
    for WINDOW in "${WINDOWS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $WINDOW)"
        if  [ ${PROPS['w']} -gt 0 ] && \
            [ ${PROPS['x']} -gt 0 ]; then
            WINDOW_X=${PROPS['x']}
            WINDOW_Y=${PROPS['y']}
            _info "  found: ${PROPS['title']} at $WINDOW_X,$WINDOW_Y\n"
            break
        fi
    done
}


function _login_toggle {
    local OUTPUT=$(_call_jauto_wait "list_ui_components?window_class=ibgateway")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [ "${PROPS['F1']}" == "javax.swing.JToggleButton" ] && \
            [ "${PROPS['text']}" == "$1" ]; then
            if [ "${PROPS['selected']}" == "n" ]; then
                xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                sleep 0.25
            fi
            break
        fi
    done
}


function _login_type {
    local OUTPUT=$(_call_jauto_wait "list_ui_components?window_class=ibgateway")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [ "${PROPS['F1']}" == "$1" ] && \
            [ "${PROPS['editable']}" == "y" ]; then
            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
            sleep 0.25
            xdotool key ctrl+a BackSpace
            xdotool type $2
            sleep 0.25
            break
        fi
    done
}


function _login_click {
    local OUTPUT=$(_call_jauto_wait "list_ui_components?window_class=ibgateway")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
            [ "${PROPS['text']}" == "$1" ]; then
            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
            sleep 0.25
            break
        fi
    done
}


function __calc_key_action {
    local ACTION_KEY="Up"
    local KEY_COUNT=0
    local CIDX=$1
    local TIDX=$2
    if [[ $TIDX -gt $CIDX ]]; then
        ACTION_KEY="Down"
        KEY_COUNT=$(($TIDX-$CIDX))
    else
        KEY_COUNT=$(($CIDX-$TIDX))
    fi
    echo "$ACTION_KEY" "$KEY_COUNT"
}


function _get_skip_combo_filename {
    echo "$IBG_SETTINGS_DIR/skip_login_combobox_$1"
}


function _should_check_combobox {
    local _ret=true
    SKIP_COMBO_FILE=$(_get_skip_combo_filename "$1")
    if [[ -f $SKIP_COMBO_FILE ]]; then
        COMBO_VALUE=$(<"$SKIP_COMBO_FILE")
        if [[ "$COMBO_VALUE" == "$2" ]]; then
            _ret=''
        fi
    fi
    echo "$_ret"
}


function _check_combobox {
    SKIP_COMBO_FILE=""
    if [ -z "$4" ]; then
        SKIP_COMBO_FILE=$(_get_skip_combo_filename "$2")
    fi
    OUTPUT=$(_call_jauto "$1")
    readarray -t COMPONENTS <<< "$OUTPUT"
    local CB=0
    local CB_X=0
    local CB_Y=0
    local CIDX=-1
    local TIDX=-1
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [[ "${PROPS['F1']}" == "javax.swing.JLabel" ]] && \
            [[ "${PROPS['text']}" == "$2" ]]; then
            CB=1
            continue
        elif    [[ "${PROPS['F1']}" == "javax.swing.JComboBox" ]] && \
                [[ $CB -eq 1 ]]; then
                CIDX=${PROPS['index']}
                TIDX=$CIDX
                CB_X=${PROPS['mx']}
                CB_Y=${PROPS['my']}
                if [[ "${PROPS['text']}" == *"$3"* ]]; then
                    # TODO: persist skip
                    _info "  - $2 already matches $3.\n"
                    if [ -n "$SKIP_COMBO_FILE" ]; then
                        echo "$3" > "$SKIP_COMBO_FILE"
                    fi
                    break
                fi
        elif    [[ "${PROPS['F1']}" == "javax.swing.JComboBox(row)" ]] && \
                [[ $CB -eq 1 ]]; then
                if [[ "${PROPS['text']}" == *"$3"* ]]; then
                    TIDX=${PROPS['F2']}
                    _info "  - $2 combo target acquired.\n"
                    break
                fi
        elif    [[ $CB -eq 1 ]]; then
                CB=0
        fi
    done
    local ACTION_KEY KEY_COUNT
    read ACTION_KEY KEY_COUNT <<< $(__calc_key_action $CIDX $TIDX)
    if [[ $KEY_COUNT -gt 0 ]]; then
        local KEY_SEQ=$(repl "$ACTION_KEY " $KEY_COUNT)
        _info "  - navigating $2 to $3 by pressing $ACTION_KEY $KEY_COUNT times ...\n"
        xdotool mousemove $CB_X $CB_Y click 1 key $KEY_SEQ Return
    fi
}


function _login_option_check {
    if  [ -z "$IB_REGION" ] && \
        [ -z "$IB_TIMEZONE" ]; then
        _info "  - skipped login option check, both IB_REGION and IB_TIMEZONE are blank.\n"
        return
    fi
    local CHECK_REGION=0
    local CHECK_TIMEZONE=0
    if [ ! -z "$IB_REGION" ]; then
        local CB_NAME="Region"
        local CB_VALUE="$IB_REGION"
        local CB_FILENAME=$(_get_skip_combo_filename "$CB_NAME")
        local TO_CHECK=$(_should_check_combobox "$CB_NAME" "$CB_VALUE")
        if [[ "$TO_CHECK" = true ]]; then
            CHECK_REGION=1
        else
            _info "  - skipping combobox $CB_NAME since persisted state ($CB_FILENAME) indicates it already matches $CB_VALUE\n"
        fi
    fi
    if [ ! -z "$IB_TIMEZONE" ]; then
        local CB_NAME="Time Zone"
        local CB_VALUE="$IB_TIMEZONE"
        local CB_FILENAME=$(_get_skip_combo_filename "$CB_NAME")
        local TO_CHECK=$(_should_check_combobox "$CB_NAME" "$CB_VALUE")
        if [[ "$TO_CHECK" = true ]]; then
            CHECK_TIMEZONE=1
        else
            _info "  - skipping combobox $CB_NAME since persisted state ($CB_FILENAME) indicates it already matches $CB_VALUE\n"
        fi
    fi

    if  [[ $CHECK_REGION -eq 1 ]] || \
        [[ $CHECK_TIMEZONE -eq 1 ]]; then
        _login_click "More Options"
        local OUTPUT=$(_call_jauto "list_ui_components?window_class=ibgateway")
        readarray -t COMPONENTS <<< "$OUTPUT"
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if  [ "${PROPS['F1']}" == "javax.swing.JScrollPane" ]; then
                xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1 click --repeat 3 5
                sleep 0.25
                break
            fi
        done
    fi

    if [[ $CHECK_REGION -eq 1 ]]; then
        _check_combobox "list_ui_components?window_class=ibgateway" "Region" "$IB_REGION"
    fi
    if [[ $CHECK_TIMEZONE -eq 1 ]]; then
        _check_combobox "list_ui_components?window_class=ibgateway" "Time Zone" "$IB_TIMEZONE"
    fi
}


function _click_menu {
    IFS='/' read -ra MENU_PARTS <<< "$@"
    CMENU=''
    for MP in "${MENU_PARTS[@]}"; do
        if [[ -z "$CMENU" ]]; then
            CMENU="$MP"
        else
            CMENU="$CMENU/$MP"
        fi
        local OUTPUT=$(_call_jauto "list_menu?window_title=IB Gateway")
        if [ "$OUTPUT" == "none" ]; then
            OUTPUT=$(_call_jauto "list_menu?window_title=IBKR Gateway")
        fi
        if [ "$OUTPUT" != "none" ]; then
            readarray -t COMPONENTS <<< "$OUTPUT"
            for COMPONENT in "${COMPONENTS[@]}"; do
                local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                if  [ "${PROPS['F1']}" == "$CMENU" ]; then
                    xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                    sleep 0.15
                    break
                fi
            done
        fi
    done
}


function __export_logs_by_date {
    local LIST_X=$1
    local LIST_Y=$2
    local EXPBTN_X=$3
    local EXPBTN_Y=$4
    local DATES
    IFS=' ' read -ra DATES <<< "$5"
    local SEL_DATE=$6
    local FILENAME_PREFIX=$(echo "$7" | tr '[:upper:]' '[:lower:]')
    local JAUTO_LOGS_DLG="list_ui_components?window_type=dialog&window_title=View Logs"
    local JAUTO_FILE_DLG="list_ui_components?window_type=dialog&window_title=Enter export filename"
    local JAUTO_MESSAGE="list_ui_components?window_type=dialog&is_active=1"
    # click the list, start exporting
    xdotool mousemove $LIST_X $LIST_Y click 1
    sleep 0.25
    local CIDX=-1
    local TIDX=-1
    local OUTPUT=$(_call_jauto "$JAUTO_LOGS_DLG")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [ "${PROPS['F1']}" == "javax.swing.JList(row)" ] && \
            [ "${PROPS['selected']}" == "y" ]; then
            CIDX="${PROPS['F2']}"
        fi
    done
    for i in ${!DATES[@]}; do
        if [ "$SEL_DATE" == "${DATES[$i]}" ]; then
            TIDX="$i"
            break
        fi
    done
    local ACTION_KEY KEY_COUNT
    # today's
    read ACTION_KEY KEY_COUNT <<< $(__calc_key_action $CIDX $TIDX)
    if [[ $KEY_COUNT -gt 0 ]]; then
        local KEY_SEQ=$(repl "$ACTION_KEY " $KEY_COUNT)
        xdotool key $KEY_SEQ
    fi
    _info "  - export logs, selected $SEL_DATE\n"
    xdotool mousemove $EXPBTN_X $EXPBTN_Y click 1
    sleep 0.25
    local OUTPUT=$(_call_jauto_wait "$JAUTO_FILE_DLG")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
            [ "${PROPS['text']}" == "Open" ]; then
            FILENAME="$IBGA_LOG_EXPORT_DIR/${FILENAME_PREFIX}_$SEL_DATE.log"
            _info "  - export logs: $FILENAME\n"
            xdotool type "$FILENAME"
            sleep 0.25
            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
            sleep 0.25
            break
        fi
    done
    local OUTPUT=$(_call_jauto_wait "$JAUTO_MESSAGE" 0.25 "JOptionPane")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if      [ "${PROPS['F1']}" == "javax.swing.JTextPane" ]; then
                _info "  - export logs, message: ${PROPS['text']}\n"
        elif    [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "OK" ]; then
                xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                sleep 0.25
                break
        fi
    done
}


function _export_logs {
    sudo mkdir -p "$IBGA_LOG_EXPORT_DIR"
    sudo chown ibg:ibg "$IBGA_LOG_EXPORT_DIR"
    _info "  - export logs, clicking menu File/$1 Logs ...\n"
    _click_menu "File/$1 Logs"
    local JAUTO_LOGS_DLG="list_ui_components?window_type=dialog&window_title=View Logs"
    # wait for dialog, enumerate days, record button positions
    local EXPBTN_X=0
    local EXPBTN_Y=0
    local LIST_X=0
    local LIST_Y=0
    local CANCEL_X=0
    local CANCEL_Y=0
    local DATES=()
    local TODAY=$(date '+%Y%m%d')
    local OUTPUT=$(_call_jauto_wait "$JAUTO_LOGS_DLG")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if      [ "${PROPS['F1']}" == "javax.swing.JList(row)" ]; then
                DATES+=( ${PROPS['text']}  )
        elif    [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "Export Logs..." ]; then
                EXPBTN_X=${PROPS["mx"]}
                EXPBTN_Y=${PROPS["my"]}
        elif    [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "Cancel" ]; then
                CANCEL_X=${PROPS["mx"]}
                CANCEL_Y=${PROPS["my"]}
        elif    [ "${PROPS['F1']}" == "javax.swing.JList" ]; then
                LIST_X=${PROPS["mx"]}
                LIST_Y=${PROPS["my"]}
        fi
    done
    _info "  - export logs, today is $TODAY\n"
    local N_DATES="${#DATES[@]}"
    if [ $N_DATES -gt 0 ]; then
        local DATE_IDX=$((N_DATES-1))
        local SEL_DATE="${DATES[$DATE_IDX]}"
        __export_logs_by_date "$LIST_X" "$LIST_Y" "$EXPBTN_X" "$EXPBTN_Y" "${DATES[*]}" "$SEL_DATE" "$1"
        if [ $N_DATES -gt 1 ]; then
            DATE_IDX=$((N_DATES-2))
            SEL_DATE="${DATES[$DATE_IDX]}"
            __export_logs_by_date "$LIST_X" "$LIST_Y" "$EXPBTN_X" "$EXPBTN_Y" "${DATES[*]}" "$SEL_DATE" "$1"
        fi
    fi
    _info "  - export logs, done.\n"
    xdotool mousemove $CANCEL_X $CANCEL_Y click 1
}


function __maintenance_handle_login_failed {
    local JAUTO_ARGS="list_ui_components?window_type=dialog&window_title=Login failed"
    local DIALOGS=$(_call_jauto "$JAUTO_ARGS")
    if [ "$DIALOGS" != "none" ]; then
        OUTPUT=$(_call_jauto "$JAUTO_ARGS")
        readarray -t COMPONENTS <<< "$OUTPUT"
        local DIALOG_TEXT=''
        local DIALOG_OK_X=0
        local DIALOG_OK_Y=0
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if  [ "${PROPS['F1']}" == "javax.swing.JTextPane" ] && \
                [ ! -z "${PROPS['text']}" ]; then
                DIALOG_TEXT+="${PROPS['text']}"
            fi
            if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "OK" ]; then
                DIALOG_OK_X="${PROPS['mx']}"
                DIALOG_OK_Y="${PROPS['my']}"
            fi
        done
        if  [ ${#DIALOG_TEXT} -gt 0 ]; then
            _info "  - login failed: $DIALOG_TEXT\n"
            _info "    clicking OK at $DIALOG_OK_X,$DIALOG_OK_Y ...\n"
            if [[ "$DIALOG_TEXT" == *"Invalid username or password."* ]]; then
                G_FATAL_ERROR="Invalid username or password."
            fi
            xdotool mousemove $DIALOG_OK_X $DIALOG_OK_Y click 1
            G_LOGIN_FAILED=2
        fi
    fi
}


function __maintenance_handle_paper_trading_warning {
    local DIALOGS=$(_call_jauto "get_windows?window_type=dialog")
    if [ "$DIALOGS" != "none" ]; then
        OUTPUT=$(_call_jauto "list_ui_components?window_type=dialog&window_title=Warning")
        # <html>This is not a brokerage account. <br>This is a "paper" trading account in which you <br>can engage in simulated trading. <br><br>Please confirm that you understand and wish <br>to conduct simulated trading before proceeding.</html>
        # I understand and accept
        readarray -t COMPONENTS <<< "$OUTPUT"
        local DIALOG_TEXT=''
        local DIALOG_BTNS=()
        local DIALOG_BTNS_X=()
        local DIALOG_BTNS_Y=()
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if  [ "${PROPS['F1']}" == "javax.swing.JLabel" ] && \
                [ ! -z "${PROPS['text']}" ]; then
                DIALOG_TEXT+="${PROPS['text']}"
            fi
            if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ ! -z "${PROPS['text']}" ]; then
                DIALOG_BTNS+=( "${PROPS['text']}" )
                DIALOG_BTNS_X+=( "${PROPS['mx']}" )
                DIALOG_BTNS_Y+=( "${PROPS['my']}" )
            fi
        done
        if  [ ${#DIALOG_BTNS[@]} -gt 0 ] && \
            [ ${#DIALOG_TEXT} -gt 0 ]; then
            _info "  - got warning: $DIALOG_TEXT [$DIALOG_BTNS]\n"
            if [ "${DIALOG_BTNS[0]}" == "I understand and accept" ]; then
                _info "    clicking [${DIALOG_BTNS[0]}] at ${DIALOG_BTNS_X[0]},${DIALOG_BTNS_Y[0]} ...\n"
                xdotool mousemove ${DIALOG_BTNS_X[0]} ${DIALOG_BTNS_Y[0]} click 1
                # click one more time to activate the main window
                sleep 1
                xdotool mousemove ${DIALOG_BTNS_X[0]} ${DIALOG_BTNS_Y[0]} click 1
                sleep 0.25
                G_PAPER_TRADING_WARNING_DONE=2
                G_WELCOME_MESSAGE_DONE=2
            fi
        fi
    fi
}


function __maintenance_handle_general_warning {
    local JAUTO_ARGS="list_ui_components?window_class=feature.messages.&window_type=dialog"
    local DIALOGS=$(_call_jauto "$JAUTO_ARGS")
    if [ "$DIALOGS" != "none" ]; then
        OUTPUT=$(_call_jauto "$JAUTO_ARGS")
        readarray -t COMPONENTS <<< "$OUTPUT"
        local DIALOG_TEXT=''
        local DIALOG_OK_X=0
        local DIALOG_OK_Y=0
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if  [ "${PROPS['F1']}" == "javax.swing.JTextPane" ] && \
                [ ! -z "${PROPS['text']}" ]; then
                DIALOG_TEXT+="${PROPS['text']}"
            fi
            if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "OK" ]; then
                DIALOG_OK_X="${PROPS['mx']}"
                DIALOG_OK_Y="${PROPS['my']}"
            fi
        done
        if  [ ${#DIALOG_TEXT} -gt 0 ]; then
            _info "  - handle general warning: $DIALOG_TEXT\n"
            _info "    clicking OK at $DIALOG_OK_X,$DIALOG_OK_Y ...\n"
            xdotool mousemove $DIALOG_OK_X $DIALOG_OK_Y click 1
        fi
    fi
}


function __maintenance_handle_relogin_warning {
    local JAUTO_ARGS="list_ui_components?window_class=twslaunch.jconnection&window_type=dialog"
    local DIALOGS=$(_call_jauto "$JAUTO_ARGS")
    if [ "$DIALOGS" != "none" ]; then
        OUTPUT=$(_call_jauto "$JAUTO_ARGS")
        readarray -t COMPONENTS <<< "$OUTPUT"
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "Re-login" ]; then
                _info "  - handle relogin warning by allowing ...\n"
                xdotool mousemove ${PROPS['mx']} ${PROPS['my']} click 1
            fi
        done
    fi
}


function __maintenance_handle_welcome {
    local OUTPUT=$(_call_jauto "list_ui_components?window_class=twslaunch.feature.welcome.")
    if [ "$OUTPUT" != "none" ]; then
        G_WELCOME_MESSAGE_DONE=1
        readarray -t COMPONENTS <<< "$OUTPUT"
        message=""
        progress=0
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if  [ "${PROPS['F1']}" == "javax.swing.JLabel" ] && \
                [ ! -z "${PROPS['text']}" ]; then
                message="$message ${PROPS['text']}"
            fi
            if  [ "${PROPS['F1']}" == "javax.swing.JProgressBar" ]; then
                progress=${PROPS['progress']}
            fi
        done
        message="$progress%$message"
        if [ "$message" != "$G_WELCOME_MESSAGE" ]; then
            G_WELCOME_MESSAGE="$message"
            _info "  - welcome: $message\n"
        fi
        # handle existing session detected
        local OUTPUT=$(_call_jauto "get_windows?window_class=twslaunch.jconnection&window_type=dialog")
        if [ "$OUTPUT" != "none" ]; then
            _info "  - existing session detected, will kick it out\n"
            local OUTPUT=$(_call_jauto "list_ui_components?window_class=twslaunch.jconnection&window_type=dialog")
            if [ "$OUTPUT" != "none" ]; then
                readarray -t COMPONENTS <<< "$OUTPUT"
                for COMPONENT in "${COMPONENTS[@]}"; do
                    local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                    if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                        [ "${PROPS['text']}" == "Continue Login" ]; then
                        xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                    fi
                done
            fi
        fi
        # handle Mobile Authenticator app code
        if [ ! -z "$TOTP_KEY" ]; then
            local WINDOW_CLASS="twslaunch.jutils.aO"
            local OUTPUT=$(_call_jauto "get_windows?window_class=$WINDOW_CLASS&window_type=dialog")
            if [ "$OUTPUT" == "none" ]; then
                WINDOW_CLASS="twslaunch.jutils.aQ"
                OUTPUT=$(_call_jauto "get_windows?window_class=$WINDOW_CLASS&window_type=dialog")
            fi
            if [ "$OUTPUT" != "none" ]; then
                local OUTPUT=$(_call_jauto "list_ui_components?window_class=$WINDOW_CLASS&window_type=dialog")
                if [ "$OUTPUT" != "none" ]; then
                    _info "  - handling TOTP Mobile Authenticator\n"
                    readarray -t COMPONENTS <<< "$OUTPUT"
                    local RUN_OTP=0
                    local ACCEPT_OTP=0
                    for COMPONENT in "${COMPONENTS[@]}"; do
                        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                        if  [ "${PROPS['F1']}" == "javax.swing.JLabel" ] && \
                            [[ "${PROPS['text']}" == *"Enter"* ]]; then
                            RUN_OTP=1
                            _info "    TOTP form identified\n"
                        fi
                        if  [ "${PROPS['F1']}" == "javax.swing.JTextField" ] && \
                            [ "${PROPS['editable']}" == "y" ] && \
                            [ "$RUN_OTP" == 1 ]; then
                            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                            TOTP_ANSWER=$(oathtool --totp -b "$TOTP_KEY")
                            sleep 0.25
                            xdotool type $TOTP_ANSWER
                            _info "    TOTP answer entered\n"
                            sleep 0.25
                            ACCEPT_OTP=1
                        fi
                        if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                            [ "${PROPS['text']}" == "OK" ] &&
                            [ "$ACCEPT_OTP" == 1 ]; then
                            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                            _info "    TOTP OK clicked\n"
                        fi
                    done
                fi
            fi
        fi
        # handle two-factor authentication
        local OUTPUT=$(_call_jauto "get_windows?window_class=twslaunch.jauthentication&window_type=dialog")
        if [ "$OUTPUT" != "none" ]; then
            _err "!!! IB Gateway is waiting for two-factor authentication !!!\n"
        fi
        if [ "$IB_PREFER_IBKEY" == "true" ] || [ ! -z "$TOTP_KEY" ]; then
            local DEVICE_TO_CLICK=" IB Key"
            if [ ! -z "$TOTP_KEY" ]; then
                DEVICE_TO_CLICK=" Mobile Authenticator app"
            fi
            local OUTPUT=$(_call_jauto "list_ui_components?window_class=twslaunch.jauthentication&window_type=dialog")
            if [ "$OUTPUT" != "none" ]; then
                readarray -t COMPONENTS <<< "$OUTPUT"
                for COMPONENT in "${COMPONENTS[@]}"; do
                    local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                    if  [ "${PROPS['F1']}" == "javax.swing.JList" ]; then
                        xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                        _info "  - focused on two-factor choice listbox"
                    fi
                done
            fi
            sleep 0.25
            local OUTPUT=$(_call_jauto "list_ui_components?window_class=twslaunch.jauthentication&window_type=dialog")
            if [ "$OUTPUT" != "none" ]; then
                readarray -t COMPONENTS <<< "$OUTPUT"
                local CIDX=-1
                local TIDX=-1
                for COMPONENT in "${COMPONENTS[@]}"; do
                    local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                    if  [ "${PROPS['F1']}" == "javax.swing.JList(row)" ] && \
                        [ "${PROPS['selected']}" == "y" ]; then
                        CIDX="${PROPS['F2']}"
                    fi
                    if  [ "${PROPS['F1']}" == "javax.swing.JList(row)" ] && \
                        [ "${PROPS['text']}" == "$DEVICE_TO_CLICK" ]; then
                        TIDX="${PROPS['F2']}"
                    fi
                done
                if  [[ $CIDX -ge 0 ]] && \
                    [[ $TIDX -ge 0 ]]; then
                    _info "  - selecting $CIDX $TIDX $DEVICE_TO_CLICK"
                    local ACTION_KEY KEY_COUNT
                    read ACTION_KEY KEY_COUNT <<< $(__calc_key_action $CIDX $TIDX)
                    if [[ $KEY_COUNT -gt 0 ]]; then
                        local KEY_SEQ=$(repl "$ACTION_KEY " $KEY_COUNT)
                        xdotool key $KEY_SEQ
                    fi
                    sleep 0.25
                    for COMPONENT in "${COMPONENTS[@]}"; do
                        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                        if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                            [ "${PROPS['text']}" == "OK" ]; then
                            _info "  - two-factor auth, selected $DEVICE_TO_CLICK ...\n"
                            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                        fi
                    done
                fi
            fi
        fi
    else
        if [ $G_WELCOME_MESSAGE_DONE -eq 1 ]; then
            G_LOGIN_AGAIN=0
            # find existence of login window
            local OUTPUT=$(_call_jauto_wait "list_ui_components?window_class=ibgateway")
            readarray -t COMPONENTS <<< "$OUTPUT"
            for COMPONENT in "${COMPONENTS[@]}"; do
                local -A PROPS="$(_jauto_parse_props $COMPONENT)"
                if  [ "${PROPS['F1']}" == "javax.swing.JToggleButton" ] && \
                    [ "${PROPS['text']}" == "IB API" ]; then
                    G_LOGIN_AGAIN=1
                    break
                fi
            done

            if [ $G_LOGIN_AGAIN -eq 0 ]; then
                G_WELCOME_MESSAGE_DONE=2
            fi
        fi
    fi
}


function __maintenance_check_options {
    SKIP_CHECK="$IBG_SETTINGS_DIR/skip_option_check2"
    if [ -f $SKIP_CHECK ]; then
        _info "  - option check skipped, to perform again remove $SKIP_CHECK\n"
        G_OPTION_ESSENTIAL_DONE=2
        return
    fi
    _info "  - option check, clicking menu Configure/Settings ...\n"
    _click_menu "Configure/Settings"
    # Location of OK, Apply, Cancel buttons, "API" item, "Lock and Exit" item
    local OK_X=0
    local OK_Y=0
    local APPLY_X=0
    local APPLY_Y=0
    local CANCEL_X=0
    local CANCEL_Y=0
    local API_X=0
    local API_Y=0
    local LAE_X=0
    local LAE_Y=0
    local SETTINGS_CHANGED=0
    local OUTPUT=$(_call_jauto_wait "list_ui_components?window_type=dialog")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        # locate buttons
        if  [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
            [ "${PROPS['text']}" == "OK" ]; then
            OK_X=${PROPS["mx"]}
            OK_Y=${PROPS["my"]}
        elif    [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "Apply" ]; then
                APPLY_X=${PROPS["mx"]}
                APPLY_Y=${PROPS["my"]}
        elif    [ "${PROPS['F1']}" == "javax.swing.JButton" ] && \
                [ "${PROPS['text']}" == "Cancel" ]; then
                CANCEL_X=${PROPS["mx"]}
                CANCEL_Y=${PROPS["my"]}
        # locate Configuration/API
        elif    [ "${PROPS['F1']}" == "javax.swing.JTree(row)" ] && \
                [ "${PROPS['F2']}" == "Configuration/API" ]; then
                API_X=${PROPS["mx"]}
                API_Y=${PROPS["my"]}
        # locate Configuration/Lock and Exit
        elif    [ "${PROPS['F1']}" == "javax.swing.JTree(row)" ] && \
                [ "${PROPS['F2']}" == "Configuration/Lock and Exit" ]; then
                LAE_X=${PROPS["mx"]}
                LAE_Y=${PROPS["my"]}
        fi
    done
    # Configuration/Lock and Exit
    if [ ! -z "$IB_LOGOFF" ]; then
        read -ra LOGOFF_PARAMS <<< "${IB_LOGOFF^^}"
        _info "  - option check, clicking tree item Configuration/Lock and Exit ...\n"
        xdotool mousemove $LAE_X $LAE_Y click 1
        local OUTPUT=$(_call_jauto "list_ui_components?window_type=dialog")
        readarray -t COMPONENTS <<< "$OUTPUT"
        for COMPONENT in "${COMPONENTS[@]}"; do
            local -A PROPS="$(_jauto_parse_props $COMPONENT)"
            if      [ "${PROPS['F1']}" == "javax.swing.JTextField" ] && \
                    [ "${PROPS['editable']}" == "y" ]; then
                    if [ "${PROPS['text']}" != "${LOGOFF_PARAMS[0]}" ]; then
                        _info "  - option check, changing logoff time from ${PROPS['text']} to ${LOGOFF_PARAMS[0]} ...\n"
                        SETTINGS_CHANGED=1
                        xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1 key ctrl+a BackSpace type "${LOGOFF_PARAMS[0]}"
                        sleep 0.25
                    fi
            elif    [ "${PROPS['F1']}" == "javax.swing.JRadioButton" ] && \
                    [ "${PROPS['text']}" == "${LOGOFF_PARAMS[1]}" ]; then
                    if [ "${PROPS['selected']}" != "y" ]; then
                        _info "  - option check, clicking logoff time ${LOGOFF_PARAMS[1]} ...\n"
                        SETTINGS_CHANGED=1
                        xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                        sleep 0.25
                    fi
            elif    [ "${PROPS['F1']}" == "javax.swing.JRadioButton" ] && \
                    [ "${PROPS['text']}" == "Auto restart" ] && \
                    [ "${PROPS['selected']}" != "y" ]; then
                    # stick to shutdown instead of restart
                    _info "  - option check, clicking Auto restart ...\n"
                    SETTINGS_CHANGED=1
                    xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                    sleep 0.25
            fi
        done
    fi
    # Configuration/API/Settings for "socket port", "read-only API"
    # Plus IB_APILOG, IB_LOGGINGLEVEL
    _info "  - option check, double clicking tree item Configuration/API ...\n"
    xdotool mousemove $API_X $API_Y click --repeat 2 1
    sleep 0.25
    local OUTPUT=$(_call_jauto "list_ui_components?window_type=dialog")
    readarray -t COMPONENTS <<< "$OUTPUT"
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if  [ "${PROPS['F1']}" == "javax.swing.JTree(row)" ] && \
            [ "${PROPS['F2']}" == "Configuration/API/Settings" ]; then
            _info "  - option check, clicking tree item ${PROPS['F2']} ...\n"
            xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
            sleep 0.25
            break
        fi
    done
    local OUTPUT=$(_call_jauto "list_ui_components?window_type=dialog")
    readarray -t COMPONENTS <<< "$OUTPUT"
    local NEXT_EDIT_IS_PORT=0
    local NEXT_SCROLLPANE_IS_CONTENT=0
    local CONTENT_X=0
    local CONTENT_Y=0
    for COMPONENT in "${COMPONENTS[@]}"; do
        local -A PROPS="$(_jauto_parse_props $COMPONENT)"
        if      [ "${PROPS['F1']}" == "javax.swing.JCheckBox" ] && \
                [ "${PROPS['text']}" == "Read-Only API" ] && \
                [ "${PROPS['selected']}" == "y" ]; then
                SETTINGS_CHANGED=1
                _info "  - option check, unchecking ${PROPS['text']} ...\n"
                xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                sleep 0.25
        elif    [ $NEXT_EDIT_IS_PORT -eq 0 ] && \
                [ "${PROPS['F1']}" == "javax.swing.JLabel" ] && \
                [ "${PROPS['text']}" == "Socket port" ]; then
                NEXT_EDIT_IS_PORT=1
        elif    [ $NEXT_EDIT_IS_PORT -eq 1 ] && \
                [ "${PROPS['F1']}" == "javax.swing.JTextField" ] && \
                [ "${PROPS['editable']}" == "y" ]; then
                NEXT_EDIT_IS_PORT=2
                if [ "${PROPS['text']}" != "$IBG_PORT_INTERNAL" ]; then
                    SETTINGS_CHANGED=1
                    _info "  - option check, changing port from ${PROPS['text']} to $IBG_PORT_INTERNAL ...\n"
                    xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1 key ctrl+a BackSpace type "$IBG_PORT_INTERNAL"
                    sleep 0.25
                fi
        elif    [ "${PROPS['F1']}" == "javax.swing.JCheckBox" ] && \
                [ "${PROPS['text']}" == "Create API message log file" ]; then
                if  [ -n "$IB_APILOG" ] && \
                    [ "${PROPS['selected']}" == "n" ]; then
                    SETTINGS_CHANGED=1
                    _info "  - option check, checking ${PROPS['text']} for IB_APILOG: $IB_APILOG ...\n"
                    xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                    sleep 0.25
                fi
        elif    [ "${PROPS['F1']}" == "javax.swing.JCheckBox" ] && \
                [ "${PROPS['text']}" == "Include market data in API log file" ]; then
                if  [ "${IB_APILOG,,}" == "data" ] && \
                    [ "${PROPS['selected']}" == "n" ]; then
                    SETTINGS_CHANGED=1
                    _info "  - option check, checking ${PROPS['text']} for IB_APILOG: $IB_APILOG ...\n"
                    xdotool mousemove ${PROPS["mx"]} ${PROPS["my"]} click 1
                    sleep 0.25
                fi
        elif    [ "${PROPS['F1']}" == "javax.swing.JScrollPane" ] && \
                [ $NEXT_SCROLLPANE_IS_CONTENT -eq 0 ]; then
                NEXT_SCROLLPANE_IS_CONTENT=1
        elif    [ "${PROPS['F1']}" == "javax.swing.JScrollPane" ] && \
                [ $NEXT_SCROLLPANE_IS_CONTENT -eq 1 ]; then
                NEXT_SCROLLPANE_IS_CONTENT=2
                CONTENT_X=${PROPS["mx"]}
                CONTENT_Y=${PROPS["my"]}
        fi
    done
    if [ -n "$IB_LOGLEVEL" ]; then
        xdotool mousemove $CONTENT_X $CONTENT_Y click --repeat 5 5
        local MSG=$(_check_combobox "list_ui_components?window_type=dialog" "Logging Level" "$IB_LOGLEVEL" "noskip")
        if [[ "$MSG" == *"navigating"* ]]; then
            _info "  - option check, selected $IB_LOGLEVEL for IB_LOGLEVEL.\n"
            SETTINGS_CHANGED=1
        fi
    fi
    if [ $SETTINGS_CHANGED -eq 1 ]; then
        _info "  - option check, confirming settings change ...\n"
        xdotool mousemove $APPLY_X $APPLY_Y click 1
        __maintenance_handle_general_warning
        xdotool mousemove $OK_X $OK_Y click 1
    else
        _info "  - option check, no settings change necessary.\n"
        xdotool mousemove $CANCEL_X $CANCEL_Y click 1
        echo "remove this file to perform option check" > "$SKIP_CHECK"
        _info "  - option check, created $SKIP_CHECK to skip future option check runs.\n"
    fi
    G_OPTION_ESSENTIAL_DONE=2
}


function __maintenance_export_logs {
    G_LOG_EXPORT_DONE=1
    if [ "$IBGA_EXPORT_LOGS" == "true" ]; then
        _export_logs Gateway
        _export_logs API
    fi
    G_LOG_EXPORT_DONE=2
}


function _maintenance_cycle {
    _info "• entered maintenance cycle\n"
    while true; do
        # Freeze termination disabled in response to forced two-factor login.
        # TODO: Research for a better solution.
        # readarray -t RUNTIME <<< $(ps -p $IBG_PID -o etimes)
        # if [ ${#RUNTIME[@]} -gt 1 ]; then
        #     if [ ${RUNTIME[1]} -gt 86520 ]; then
        #         _err "• IB Gateway has reached the maximum allowed runtime of 24H.\n"
        #         _err "• IB Gateway has freezed.\n"
        #         _err "• Forcefully terminating IB Gateway ...\n"
        #         kill -9 $IBG_PID
        #         sleep 10
        #         break
        #     fi
        # fi
        IBG_INSTANCE=$(ps -A| grep java |wc -l)
        if [ $IBG_INSTANCE -eq 0 ]; then
            _info "• IB Gateway is no longer running, will restart ...\n"
            break
        fi
        if [ $G_LOGIN_FAILED -lt 2 ]; then
            __maintenance_handle_login_failed
        fi
        if [ $G_PAPER_TRADING_WARNING_DONE -lt 2 ]; then
            __maintenance_handle_paper_trading_warning
        fi
        if [ $G_WELCOME_MESSAGE_DONE -lt 2 ]; then
            __maintenance_handle_welcome
        else
            G_LOGIN_FAILED=2
        fi
        if [ $G_LOGIN_AGAIN -eq 1 ]; then
            _info "• breaking out of maintenance cycle because login is needed again\n"
            break
        fi
        if  [ $G_PAPER_TRADING_WARNING_DONE -eq 2 ] && \
            [ $G_WELCOME_MESSAGE_DONE -eq 2 ] && \
            [ $G_OPTION_ESSENTIAL_DONE -eq 0 ]; then
            __maintenance_check_options
        fi
        if  [ "$G_FATAL_ERROR" != "" ]; then
            _info "• breaking out of maintenance cycle due to fatal error: $G_FATAL_ERROR\n"
            break
        fi
        if  [ $G_PAPER_TRADING_WARNING_DONE -eq 2 ] && \
            [ $G_WELCOME_MESSAGE_DONE -eq 2 ] && \
            [ $G_OPTION_ESSENTIAL_DONE -eq 2 ] && \
            [ $G_LOG_EXPORT_DONE -eq 0 ]; then
            __maintenance_export_logs
        fi
        if  [ $G_PAPER_TRADING_WARNING_DONE -eq 2 ] && \
            [ $G_WELCOME_MESSAGE_DONE -eq 2 ] && \
            [ $G_OPTION_ESSENTIAL_DONE -eq 2 ] && \
            [ $G_LOG_EXPORT_DONE -eq 2 ]; then
            # The welcome box shows again during reconnecting after interruption.
            # Show its status.
            __maintenance_handle_welcome
            sleep 5
        else
            sleep 2
        fi
        __maintenance_handle_relogin_warning
    done
}


function _run_ibg {
MSG="---------------------------------------------------
 IB Gateway Startup / $(date)
---------------------------------------------------
"
    _info "$MSG"

    IBG_ARGS="-J-DjtsConfigDir=$IBG_SETTINGS_DIR"

    while true; do
        rm -f $JAUTO_INPUT
        G_FATAL_ERROR=""
        G_PAPER_TRADING_WARNING_DONE=2
        if [ "$IB_LOGINTYPE" == "Paper Trading" ]; then
            G_PAPER_TRADING_WARNING_DONE=0
        fi
        _info "• time: $(date)\n"
        _info "• starting IB Gateway ...\n"
        "$IBG_DIR/$IBG_EXEC" $IBG_ARGS &
        IBG_PID=$!
        _info "  pid: $IBG_PID\n"

        _wait_for_jauto
        _wait_for_main_window

        while true; do
            G_WELCOME_MESSAGE_DONE=0
            G_OPTION_ESSENTIAL_DONE=0
            G_LOG_EXPORT_DONE=0
            G_LOGIN_FAILED=0
            G_LOGIN_AGAIN=0
            G_WELCOME_MESSAGE=""
            _info "• filling in login form ...\n"
            _login_toggle "$IB_LOGINTAB"
            _login_toggle "$IB_LOGINTYPE"
            _login_type "javax.swing.JTextField" "$IB_USERNAME"
            _login_type "javax.swing.JPasswordField" "$IB_PASSWORD"
            _login_option_check
            _info "• logging in ...\n"
            if [ "$IB_LOGINTYPE" == "Paper Trading" ]; then
                _login_click "Paper Log In"
            else
                _login_click "Log In"
            fi

            _maintenance_cycle

            if  [ $G_LOGIN_AGAIN -ne 1 ]; then
                break;
            fi
        done

        if  [ "$G_FATAL_ERROR" != "" ]; then
            _info "• cannot continue due to fatal error: $G_FATAL_ERROR\n"
            _info "• entering infinit sleep ...\n"
            show_text 1024 768 "$G_FATAL_ERROR" &
            sleep infinity
        fi
    done
}

