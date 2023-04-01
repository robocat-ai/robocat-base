#!/bin/bash

export ROBOCAT_HOME=/home/robocat

initialize_flow_directory() {
    log_d "Initializing flow directory..."

    FLOW_SOURCE_DIR=/flow

    if [ ! -d "$FLOW_SOURCE_DIR" ]; then
        log_e "No flow directory is mounted to $FLOW_SOURCE_DIR"
        exit
    fi

    FLOW_DIR=$ROBOCAT_HOME/flow

    mkdir -p "$FLOW_DIR"

    log_d "Copying flow directory"

    cp -rT "$FLOW_SOURCE_DIR" "$FLOW_DIR"

    log_d "Cleaning previous flow output"

    rm -rf "$FLOW_DIR"/output/*

    log_d "Initialized flow directory: $FLOW_DIR"

    export FLOW_DIR
}

cleanup_flow_directory() {
    cd $ROBOCAT_HOME

    FLOW_DIR=$ROBOCAT_HOME/flow

    log_d "Cleaning up flow directory: $FLOW_DIR"

    rm -rf $FLOW_DIR

    log_d "Cleaned up flow directory"
}

main() {
    initialize_flow_directory

    cd $FLOW_DIR

    # Default argument values
    FLOW_PATH="${FLOW_PATH:-run.tag}"
    DATA_PATH="${DATA_PATH:-}"

    PROXY_ADDRESS="${PROXY_ADDRESS:-}"
    PROXY_PROTOCOL="${PROXY_PROTOCOL:-http}"

    if [ ! -f "$DATA_PATH" ]; then
        DATA_PATH=""
    fi

    parse_arguments $@

    extension="${FLOW_PATH##*.}"

    if [ "$extension" != "tag" ]; then
        FLOW_PATH="$FLOW_PATH.tag"
    fi

    if [ -n "$DATA_PATH" ]; then
        extension="${DATA_PATH##*.}"

        if [ "$extension" != "csv" ]; then
            DATA_PATH="$DATA_PATH.csv"
        fi
    fi

    cp $ROBOCAT_HOME/.config/tinyproxy.conf.tmpl $ROBOCAT_HOME/.config/tinyproxy.conf

    if [ -n "$PROXY_ADDRESS" ]; then
        echo "Upstream $PROXY_PROTOCOL $PROXY_ADDRESS" >>$ROBOCAT_HOME/.config/tinyproxy.conf
    fi

    kill_tinyproxy

    log_d "Starting tinyproxy..."

    mkdir -p /tmp/tinyproxy
    tinyproxy -d -c $ROBOCAT_HOME/.config/tinyproxy.conf >/dev/null 2>/tmp/tinyproxy/error.log &
    tinyproxy_pid=$!

    sleep 1
    kill -0 $tinyproxy_pid 2>/dev/null

    if [ $? -ne 0 ]; then
        log_e "tinyproxy failed to start, got error:"
        cat /tmp/tinyproxy/error.log
        exit 1
    fi

    log_d "tinyproxy started"

    rm -rf $ROBOCAT_HOME/tagui/src/chrome/tagui_user_profile
    TAGUI_COMMAND="tagui $FLOW_PATH $DATA_PATH $TAGUI_ARGS"
    log_d "Running TagUI with the following command: $TAGUI_COMMAND"
    $TAGUI_COMMAND
    taguiStatus=$?

    kill_tinyproxy

    cleanup_flow_directory

    exit $taguiStatus
}

log_i() {
    log "[INFO] ${@}"
}

log_e() {
    log "[ERROR] ${@}"
}

log_d() {
    if [ -n "$DEBUG" ]; then
        log "[DEBUG] ${@}"
    fi
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${@}"
}

kill_tinyproxy() {
    log_d "Stopping tinyproxy instance..."

    while true; do
        tinyproxy_process_id="$(ps x | grep tinyproxy | grep -v 'grep tinyproxy' | awk '{print $1}' | sort -nur | head -n 1)"
        if [ -n "$tinyproxy_process_id" ]; then
            kill $tinyproxy_process_id >/dev/null 2>&1
        else
            break
        fi
    done

    log_d "Done"
}

parse_arguments() {
    # Parse CLI arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
        -f | --flow)
            shift
            if [[ -z $1 ]]; then
                log_e "Flow name must not be empty"
                exit 1
            fi

            FLOW_PATH=$1
            ;;
        -d | --data)
            shift
            if [[ -z $1 ]]; then
                log_e "Datatable name must not be empty"
                exit 1
            fi

            DATA_PATH=$1
            ;;
        --proxy-address)
            shift
            if [[ -z $1 ]]; then
                log_e "Proxy address must not be empty"
                exit 1
            fi

            PROXY_ADDRESS=$1
            ;;
        --proxy-protocol)
            shift
            if [[ -z $1 ]]; then
                log_e "Proxy protocol must be one of the one supported by tinyproxy (http, socks5, socks4)"
                exit 1
            fi

            PROXY_PROTOCOL=$1
            ;;
        --tagui-arguments)
            shift
            if [[ -z $1 ]]; then
                log_e "TagUI arguments must not be empty"
                exit 1
            fi

            TAGUI_ARGS=$1
            ;;
        *)
            FLOW_PATH=$1
            ;;
        esac

        shift
    done
}

main $@
