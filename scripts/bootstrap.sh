#!/bin/bash

# Based on: http://www.richud.com/wiki/Ubuntu_Fluxbox_GUI_with_x11vnc_and_Xvfb

main() {
    log_i "Starting xvfb virtual display..."
    launch_xvfb
    log_i "Starting window manager..."
    launch_window_manager
    last_process=$!

    local background_path="/usr/share/images/fluxbox/background.png"
    if [ -f "$background_path" ]; then
        feh --no-fehbg --bg-scale "$background_path"
        log_d "Updated background image"
    fi

    if [ "$VNC_ENABLED" = 1 ]; then
        log_i "Starting VNC server..."
        run_vnc_server
        last_process=$!
    fi

    if [ -n "$(which robocat)" ]; then
        log_i "Starting Robocat..."
        if [ -n "$ROBOCAT_ARGS" ]; then
            log_d "Running robocat with arguments: $ROBOCAT_ARGS"
        fi
        robocat $ROBOCAT_ARGS &
        last_process=$!
    fi

    wait $last_process
}

launch_xvfb() {
    local xvfbLockFilePath="/tmp/.X1-lock"
    if [ -f "${xvfbLockFilePath}" ]; then
        log_i "Removing xvfb lock file '${xvfbLockFilePath}'..."
        if ! rm -v "${xvfbLockFilePath}"; then
            log_e "Failed to remove xvfb lock file"
            exit 1
        fi
    fi

    # Set defaults if the user did not specify envs.
    export DISPLAY=${XVFB_DISPLAY:-:1}
    local screen=${XVFB_SCREEN:-0}
    local resolution=${XVFB_RESOLUTION:-1280x960x24}
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either Xvfb to be fully up or we hit the timeout.
    Xvfb ${DISPLAY} -screen ${screen} ${resolution} >/dev/null 2>&1 &
    local loopCount=0
    until xdpyinfo -display ${DISPLAY} >/dev/null 2>&1; do
        loopCount=$((loopCount + 1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]; then
            log_e "xvfb failed to start"
            exit 1
        fi
    done

    log_i "xvfb started"
}

launch_window_manager() {
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either fluxbox to be fully up or we hit the timeout.
    fluxbox >/dev/null 2>&1 &
    local loopCount=0
    until wmctrl -m >/dev/null 2>&1; do
        loopCount=$((loopCount + 1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]; then
            log_e "fluxbox failed to start"
            exit 1
        fi
    done

    log_i "fluxbox started"
}

run_vnc_server() {
    local passwordArgument='-nopw'

    if [ -n "${VNC_PASSWORD}" ]; then
        local passwordFilePath="${HOME}/.x11vnc.pass"
        if ! x11vnc -storepasswd "${VNC_PASSWORD}" "${passwordFilePath}"; then
            log_e "Failed to store x11vnc password"
            exit 1
        fi
        passwordArgument=-"-rfbauth ${passwordFilePath}"
        log_i "The VNC server will ask for a password"
    else
        log_w "The VNC server will NOT ask for a password"
    fi
    # -viewonly
    x11vnc -display ${DISPLAY} -forever ${passwordArgument} >/dev/null 2>&1 &
}

log_i() {
    log "[INFO] ${@}"
}

log_w() {
    log "[WARN] ${@}"
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

control_c() {
    echo ""
    exit
}

trap control_c SIGINT SIGTERM SIGHUP

main

exit
