#!/bin/bash
#
# Initialize Bluetooth HID Server Mode
# This script sets up the device to act as a Bluetooth gamepad
#

LOG_FILE="/tmp/hid_init.log"

log() {
    echo "[HID Init] $1" | tee -a "$LOG_FILE"
}

log "Starting HID initialization..."

# Ensure Bluetooth is powered on
hciconfig hci0 up 2>&1 | tee -a "$LOG_FILE"
sleep 1

# Set device class to Gamepad/Joystick (0x000508)
# Device Class format: 0x<Service><Major><Minor>
# 0x00 = No specific service
# 0x05 = Peripheral (input device)
# 0x08 = Gamepad/Joystick
log "Setting device class to Gamepad..."
hciconfig hci0 class 0x000508 2>&1 | tee -a "$LOG_FILE"

# Set a friendly device name
DEVICE_NAME="MuOS Gamepad"
log "Setting device name to: $DEVICE_NAME"
bluetoothctl system-alias "$DEVICE_NAME" 2>&1 | tee -a "$LOG_FILE"

# Make device discoverable and pairable
log "Enabling discoverable and pairable mode..."
bluetoothctl discoverable on 2>&1 | tee -a "$LOG_FILE"
bluetoothctl pairable on 2>&1 | tee -a "$LOG_FILE"

# Set pairable timeout to 0 (always pairable when in HID mode)
bluetoothctl pairable-timeout 0 2>&1 | tee -a "$LOG_FILE"

# Set discoverable timeout to 0 (always discoverable until manually disabled)
bluetoothctl discoverable-timeout 0 2>&1 | tee -a "$LOG_FILE"

log "HID initialization complete"
log "Device is now ready to pair as a Bluetooth gamepad"
log "Look for '$DEVICE_NAME' on your target device's Bluetooth settings"

exit 0
