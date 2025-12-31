# Bluetooth HID Gamepad Mode - User Guide

## Overview

The Bluetooth application now supports **two modes**:

1. **Client Mode** (Default): Connect to other Bluetooth devices (headphones, controllers, etc.)
2. **Server Mode** (NEW): Use your MuOS device as a Bluetooth gamepad for other devices

## What is HID Server Mode?

HID (Human Interface Device) Server Mode allows your MuOS handheld to function as a wireless Bluetooth gamepad. You can connect it to:

- PCs (Windows, Linux, macOS)
- Smartphones and Tablets (Android, iOS)
- Game Consoles (that support Bluetooth controllers)
- Smart TVs
- Raspberry Pi and other embedded devices

## How to Use HID Mode

### Switching to HID Server Mode

1. **Open the Bluetooth app** on your MuOS device
2. **Press the Y button** to open the mode selection dialog
3. **Press A** to confirm switching to Server Mode
4. Wait for the HID server to initialize (~2-3 seconds)

### Making Your Device Discoverable

1. Once in Server Mode, press the **A button** to make your device discoverable
2. Your device will appear as **"MuOS Gamepad"** on other Bluetooth devices
3. The UI will show "Discoverable: YES" when active

### Pairing with Another Device

1. On your target device (PC, phone, etc.):
   - Open Bluetooth settings
   - Look for **"MuOS Gamepad"** in the available devices list
   - Select it and pair

2. On your MuOS device:
   - The connection will be accepted automatically
   - Connected hosts will appear in the "Connected Hosts" section

### Using the Controller

Once paired, all your controller inputs will be sent to the connected device:

- **Analog Sticks**: Both left and right sticks are mapped
- **D-Pad**: All four directions
- **Buttons**: A, B, X, Y, L1, R1, Start, Select, etc.

The controller input is sent at ~60Hz for responsive gameplay.

### Stopping HID Mode

1. Press **X button** to stop the HID server
2. Press **Y button** to switch back to Client Mode

## Button Reference (HID Server Mode)

| Button | Action |
|--------|--------|
| **A** | Make Discoverable / Hide |
| **B** | Quit Application |
| **X** | Stop HID Server |
| **Y** | Switch Mode (Client ↔ Server) |
| **Start** | Turn Bluetooth On |
| **Select** | Turn Bluetooth Off |

## Technical Details

### Gamepad Profile

The HID implementation emulates a standard USB gamepad with:

- **2 Analog Sticks** (4 axes: X, Y, Z, Rz)
- **D-Pad** (Hat Switch with 8 directions)
- **16 Buttons** (A, B, X, Y, L1, R1, L2, R2, Start, Select, etc.)

### Compatibility

This implementation uses the BlueZ Bluetooth stack with D-Bus APIs. It should work with:

- ✅ BlueZ 5.50 or newer
- ✅ Linux kernel with Bluetooth HID support
- ✅ Python 3.6+ with python3-dbus and python3-gi

### Device Class

When in HID mode, the device class is set to `0x000508`:
- Major class: **Peripheral** (input device)
- Minor class: **Gamepad/Joystick**

## Troubleshooting

### Device Not Showing Up

**Problem**: "MuOS Gamepad" doesn't appear in Bluetooth settings

**Solutions**:
1. Ensure you pressed **A** to make the device discoverable
2. Check that Bluetooth is enabled on the target device
3. Try restarting the HID server (X to stop, then switch modes again)
4. Check logs at `/tmp/hid_server.log` and `/tmp/hid_init.log`

### Connection Drops

**Problem**: Controller keeps disconnecting

**Solutions**:
1. Ensure Bluetooth is powered on: Press **Start**
2. Move closer to the paired device (Bluetooth range ~10 meters)
3. Check for interference from other wireless devices
4. Restart the HID server

### Buttons Not Working

**Problem**: Connected but buttons don't respond

**Solutions**:
1. Verify the HID server is active (should show "HID Server: ACTIVE")
2. Test the controller in a game or controller testing app on the target device
3. Check that the target device recognizes it as a gamepad
4. Some systems may require controller calibration in settings

### Pairing Fails

**Problem**: Can't pair from target device

**Solutions**:
1. Remove old pairings of "MuOS Gamepad" from both devices
2. Restart Bluetooth on both devices
3. Ensure no other HID devices are trying to connect simultaneously
4. Check system logs for authentication errors

## Advanced Usage

### Manual Script Control

You can also control the HID server manually via shell scripts:

```bash
# Start HID server
/path/to/.bluetooth/bin/hid_control.sh start

# Stop HID server
/path/to/.bluetooth/bin/hid_control.sh stop

# Check status
/path/to/.bluetooth/bin/hid_control.sh status

# Restart
/path/to/.bluetooth/bin/hid_control.sh restart
```

### Logs

HID server logs are stored in `/tmp/`:
- `/tmp/hid_init.log` - Initialization log
- `/tmp/hid_server.log` - Server runtime log
- `/tmp/hid_report_fifo` - FIFO pipe for controller reports

### Custom Configuration

The HID descriptor can be customized in [bluetooth_hid.lua](/.bluetooth/bluetooth_hid.lua#L16) if you need different button mappings or want to emulate a different controller type.

## Known Limitations

1. **One connection at a time**: Can only be paired to one device at a time in HID mode
2. **No rumble/haptics**: Feedback from the host device is not supported
3. **Basic profile**: Emulates a generic gamepad (not Xbox/PS-specific features)
4. **Latency**: Bluetooth adds ~10-20ms of input latency compared to wired

## Going Back to Normal Mode

To return to regular Bluetooth functionality (connecting to devices):

1. Press **Y** to open mode selection
2. Press **A** to confirm switching to Client Mode
3. The device will return to normal Bluetooth operation

Your connected devices and pairings in Client Mode are preserved when switching modes.

## Development Notes

### Architecture

The HID implementation consists of:

1. **[bluetooth_hid.lua](/.bluetooth/bluetooth_hid.lua)** - Core HID functionality
2. **[hid_ui.lua](/.bluetooth/hid_ui.lua)** - User interface for HID mode
3. **[main.lua](/.bluetooth/main.lua)** - Integration with main app
4. **[hid_server_dbus.py](/.bluetooth/bin/hid_server_dbus.py)** - D-Bus HID server
5. **[hid_init.sh](/.bluetooth/bin/hid_init.sh)** - Initialization script
6. **[hid_control.sh](/.bluetooth/bin/hid_control.sh)** - Server control script

### Data Flow

```
Controller Input → LÖVE Joystick API → bluetooth_hid.lua
                                            ↓
                                  Format HID Report
                                            ↓
                                  Write to FIFO Pipe
                                            ↓
                           hid_server_dbus.py reads FIFO
                                            ↓
                              Send via Bluetooth D-Bus API
                                            ↓
                                   Target Device Receives
```

## Support

For issues or questions:
- Check logs in `/tmp/hid_*.log`
- Report issues on the GitHub repository
- Include logs and device information when reporting bugs

---

**Enjoy using your MuOS device as a wireless Bluetooth gamepad!**
