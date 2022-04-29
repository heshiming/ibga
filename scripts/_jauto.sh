function _call_jauto {
    # use a random temporary file
    local OUTPUT_FILE=$(mktemp)
    local CMD=$1
    local OUTPUT=''
    local TIMER=0
    rm -f $OUTPUT_FILE
    # wait until the $JAUTO_INPUT pipe becomes ready
    while [[ ! -p $JAUTO_INPUT ]]; do
        sleep 0.5
    done
    # infinite loop(1) until jauto responds or times out
    while true; do
        # use `timeout` to kill `echo` in case the pipe is broken,
        # preventing an infinite block here
        timeout -k 1s 1s echo "$OUTPUT_FILE|$CMD" > $JAUTO_INPUT
        # get the exit status of `timeout`
        local TIMEOUT_RET=$?
        if [ $TIMEOUT_RET == 0 ]; then
            # `timeout` did not time out, command sent successfully
            local OF_TIMER=0
            # infinite loop(2) until the $OUTPUT_FILE becomes readable
            while [ $OF_TIMER -lt 10 ]; do
                if [ -f $OUTPUT_FILE ]; then
                    # read $OUTPUT_FILE and break loop(2)
                    OUTPUT=$(<"$OUTPUT_FILE")
                    rm -f $OUTPUT_FILE
                    break
                fi
                ((OF_TIMER=OF_TIMER+1))
                sleep 0.5
            done
            # jauto never returns empty, $OUTPUT must be filled at this point,
            # if so break loop(1), otherwise consider it a timeout
            if [ ! -z "$OUTPUT" ]; then
                break
            fi
        fi
        # timeout loop(1) after 10 trials, or about 20 seconds
        # (1 sec `timeout` + 1 sec `sleep` per trial)
        ((TIMER=TIMER+1))
        if [ $TIMER -gt 10 ]; then
            OUTPUT="!timeout!"
            break
        fi
        sleep 1
    done
    echo "$OUTPUT"
}


function _call_jauto_wait {
    SLEEP_INTERVAL=${2:-0.25}
    KEYWORDS="${3:-_____}"
    while [ 1 ]; do
        local OUTPUT=$(_call_jauto "$1")
        if [ "$OUTPUT" == "none" ]; then
            sleep $SLEEP_INTERVAL
            continue
        fi
        if  [ "$KEYWORDS" != "_____" ] && \
            [[ ${OUTPUT} != *"$KEYWORDS"* ]]; then
            sleep $SLEEP_INTERVAL
            continue
        fi
        echo "$OUTPUT"
        return
    done
}


function _jauto_parse_windows {
    # _jauto_parse_windows "SEARCH_KEYWORD" "LIST_UI_COMPONENTS_OUTPUT"
    # Return only the ui components of the first window matching the
    # "SEARCH_KEYWORD".
    FLATTEN_DELIM=">§...§<"
    OUTPUT_FLT="${2//$'\n'/$FLATTEN_DELIM}"
    OUTPUT_FLT="${OUTPUT_FLT//-$FLATTEN_DELIM/$'\n'}"

    readarray -t WINDOWS_FLT <<< "$OUTPUT_FLT"

    for WINDOW_FLT in "${WINDOWS_FLT[@]}"; do
        if [[ "$WINDOW_FLT" == *"$1"* ]]; then
            WINDOW="${WINDOW_FLT//$FLATTEN_DELIM/$'\n'}"
            echo "$WINDOW"
            return
        fi
    done;
    echo ""
}


function _jauto_parse_props {
    # _jauto_parse_props "A_SINGLE_LINE_OF_COMPONENT"
    # Parse a comma-delimited line such as
    # "javax.swing.JLabel,,x:315,y:549,w:210,h:15,mx:420,my:556,text:Requesting startup parameters.."
    # and return an associative array.
    IFS="," read -ra WIN_PROPS <<< "$@"
    local -A PARSED_PROPS
    FIELD_NUM=0
    for WIN_PROP in "${WIN_PROPS[@]}"; do
        ((FIELD_NUM=FIELD_NUM+1))
        PROP_LEN=${#WIN_PROP}
        PROP_VALUE=${WIN_PROP#*":"}
        if [ $PROP_LEN -eq ${#PROP_VALUE} ]; then
            # PROP_LEN equals PROP_VALUE length means no colon, skip
            PARSED_PROPS["F"$FIELD_NUM]=$PROP_VALUE
            continue
        fi
        PROP_KEY=${WIN_PROP:0:PROP_LEN-${#PROP_VALUE}-1}
        # properly escape $PROP_VALUE
        PROP_VALUE="${PROP_VALUE//\\/\\\\}"
        PROP_VALUE="${PROP_VALUE//\"/\\\"}"
        PARSED_PROPS[$PROP_KEY]=$PROP_VALUE
    done
    echo '('
    for KEY in "${!PARSED_PROPS[@]}"; do
        echo "[$KEY]=\"${PARSED_PROPS[$KEY]}\""
    done
    echo ')'
}

