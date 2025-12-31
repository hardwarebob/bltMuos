#!/bin/bash
#
# HID Server Control Script
# Usage: hid_control.sh [start|stop|status]
#

HID_SERVER_PATH="$(dirname "$0")/hid_server_dbus.py"
HID_INIT_PATH="$(dirname "$0")/hid_init.sh"
PID_FILE="/tmp/hid_server.pid"
LOG_FILE="/tmp/hid_server.log"

start_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "HID server is already running (PID: $PID)"
            return 1
        fi
    fi

    echo "Starting HID server..."

    # Run initialization script
    "$HID_INIT_PATH"

    # Start Python HID server in background
    python3 "$HID_SERVER_PATH" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"

    sleep 2

    if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        echo "HID server started successfully (PID: $(cat "$PID_FILE"))"
        return 0
    else
        echo "Failed to start HID server. Check $LOG_FILE for details."
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_server() {
    if [ ! -f "$PID_FILE" ]; then
        echo "HID server is not running"
        return 1
    fi

    PID=$(cat "$PID_FILE")
    echo "Stopping HID server (PID: $PID)..."

    kill "$PID" 2>/dev/null
    sleep 1

    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Forcing HID server to stop..."
        kill -9 "$PID" 2>/dev/null
    fi

    rm -f "$PID_FILE"

    # Restore normal device class
    hciconfig hci0 class 0x000000

    # Disable discoverable
    bluetoothctl discoverable off

    echo "HID server stopped"
    return 0
}

status_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "HID server is running (PID: $PID)"
            return 0
        else
            echo "HID server is not running (stale PID file)"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo "HID server is not running"
        return 1
    fi
}

case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    status)
        status_server
        ;;
    restart)
        stop_server
        sleep 1
        start_server
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac

exit $?
