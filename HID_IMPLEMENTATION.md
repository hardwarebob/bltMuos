# Bluetooth HID Server Implementation

## Overview

This document describes the technical implementation of Bluetooth HID (Human Interface Device) server functionality, which allows MuOS devices to act as Bluetooth gamepads.

## Implementation Details

### Mode Architecture

The application now supports two operating modes:

```lua
BluetoothHID.Mode = {
    CLIENT = 0,  -- Normal mode: connect to other devices
    SERVER = 1   -- HID mode: act as Bluetooth controller
}
```

Users can toggle between modes via the UI (Y button), which triggers a clean transition:
- Client → Server: Initializes HID profile and starts server
- Server → Client: Stops HID server, restores normal device class

### Components

#### 1. bluetooth_hid.lua

**Purpose**: Core Bluetooth HID functionality

**Key Functions**:
- `InitializeHIDServer()` - Sets up HID profile and starts Python server
- `StopHIDServer()` - Cleanly shuts down HID mode
- `SetDiscoverable(enable)` - Controls pairing visibility
- `UpdateControllerState(joystick)` - Reads controller input from LÖVE
- `SendHIDReport()` - Sends input data over Bluetooth
- `GetConnectedHosts()` - Lists paired devices

**HID Report Format**:
```
Byte 0: Left Stick X (0-255)
Byte 1: Left Stick Y (0-255)
Byte 2: Right Stick X (0-255)
Byte 3: Right Stick Y (0-255)
Byte 4: Buttons 1-8 (bitmask)
Byte 5: Buttons 9-16 (bitmask)
Byte 6: D-Pad (hat switch 0-8)
```

#### 2. hid_ui.lua

**Purpose**: User interface for HID mode

**Key Functions**:
- `DrawModeToggle()` - Shows current mode indicator
- `DrawHIDServerUI()` - Renders HID server status and instructions
- `DrawModeSelectionModal()` - Mode switching dialog
- `HandleModeSelectionInput(button)` - Processes mode switch confirmation
- `HandleHIDInput(button)` - Handles HID-specific button presses
- `Update(dt)` - Updates controller state and sends reports at 60Hz

**UI Elements**:
- Mode indicator bar (always visible)
- HID server status (active/inactive, discoverable/hidden)
- Pairing instructions
- Connected hosts list
- Status messages

#### 3. hid_server_dbus.py

**Purpose**: BlueZ D-Bus interface for HID profile

**Key Classes**:

```python
class HIDProfile(dbus.service.Object):
    """Implements org.bluez.Profile1 interface"""
    - NewConnection() - Handles incoming connections
    - RequestDisconnection() - Handles disconnections
    - Release() - Cleanup on profile unregister

class BTHIDDevice:
    """Main HID device manager"""
    - setup_profile() - Registers HID profile with BlueZ
    - get_sdp_record() - Generates SDP service record
    - read_and_send_report() - Polls FIFO and sends reports
    - send_report() - Writes HID reports to Bluetooth socket
```

**SDP Record**: Defines the HID device service for discovery, including:
- Service UUID: 0x1124 (Human Interface Device)
- Device class: Gamepad/Joystick
- HID descriptor: Standard gamepad layout
- Device name: "MuOS Gamepad"

**Communication**: Uses FIFO pipe (`/tmp/hid_report_fifo`) for inter-process communication between Lua and Python.

#### 4. Shell Scripts

**hid_init.sh**:
- Sets device class to gamepad (0x000508)
- Configures device name
- Enables discoverable and pairable modes
- Sets timeouts to 0 (always available)

**hid_control.sh**:
- Start/stop/restart/status commands
- PID file management
- Log file handling
- Cleanup on shutdown

### Integration with Main Application

**main.lua modifications**:

1. **Module imports** (line 4-5):
   ```lua
   local BluetoothHID = require("bluetooth_hid")
   local HIDUI = require("hid_ui")
   ```

2. **Initialization** (love.load, ~line 708):
   ```lua
   HIDUI.Init({A = ic_A, B = ic_B, X = ic_X, Y = ic_Y},
              {big = fontBig, small = fontSmall, bold = fontBold})
   ```

3. **Rendering** (love.draw, ~line 728):
   ```lua
   HIDUI.DrawModeToggle()
   if currentMode == BluetoothHID.Mode.CLIENT then
       -- Normal UI
   else
       HIDUI.DrawHIDServerUI()
   end
   HIDUI.DrawModeSelectionModal()
   ```

4. **Update loop** (love.update, ~line 793):
   ```lua
   HIDUI.Update(dt)  -- 60Hz controller polling
   ```

5. **Input handling** (OnKeyPress, ~line 850):
   ```lua
   if HIDUI.IsModeSelectionShown() then
       HIDUI.HandleModeSelectionInput(key)
   end
   if currentMode == BluetoothHID.Mode.SERVER then
       HIDUI.HandleHIDInput(key)
   end
   ```

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     LÖVE Framework                          │
│                                                             │
│  love.update(dt) → HIDUI.Update()                          │
│         ↓                                                   │
│  Read Joystick API → BluetoothHID.UpdateControllerState()  │
│         ↓                                                   │
│  Format Report → BluetoothHID.SendHIDReport()              │
└─────────────────────────────────────────────────────────────┘
                          ↓
                   Write to FIFO
                 /tmp/hid_report_fifo
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Python HID Server (hid_server_dbus.py)         │
│                                                             │
│  GLib.timeout_add(16ms) → read_and_send_report()           │
│         ↓                                                   │
│  Read FIFO → Parse CSV → send_report()                     │
│         ↓                                                   │
│  os.write(fd, b'\xa1' + report)                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
                    BlueZ D-Bus API
                          ↓
                  Bluetooth Hardware
                          ↓
                    Target Device
```

### HID Report Descriptor

The descriptor defines a standard gamepad profile compatible with most operating systems:

```
Usage Page: Generic Desktop (0x01)
Usage: Gamepad (0x05)
Collection: Application

  Usage Page: Buttons (0x09)
  Usage Min: Button 1
  Usage Max: Button 16
  Logical Min: 0
  Logical Max: 1
  Report Count: 16
  Report Size: 1 bit
  Input: Data, Variable, Absolute

  Usage Page: Generic Desktop
  Usage: X, Y, Z, Rz (4 axes for 2 analog sticks)
  Logical Min: 0
  Logical Max: 255
  Report Count: 4
  Report Size: 8 bits
  Input: Data, Variable, Absolute

  Usage: Hat Switch (D-pad)
  Logical Min: 0
  Logical Max: 7
  Physical Min: 0
  Physical Max: 315 degrees
  Report Count: 1
  Report Size: 8 bits
  Input: Data, Variable, Absolute, Null State

End Collection
```

### State Management

**Client Mode**:
- Normal Bluetooth operations (scan, pair, connect)
- Existing functionality unchanged
- Device class: 0x000000 (generic)

**Server Mode**:
- HID profile active
- Device class: 0x000508 (gamepad)
- Discoverable and pairable
- Controller input forwarded to connected hosts

**Transition Safety**:
- Mode switches require user confirmation
- HID server gracefully shuts down when switching to client
- Client connections are not affected by mode switching
- Both modes can coexist (future enhancement)

### Performance Considerations

1. **Input Polling**: 60Hz (16ms) for responsive gameplay
2. **Report Size**: 7 bytes per report (minimal overhead)
3. **FIFO Communication**: Non-blocking reads to prevent UI freezing
4. **D-Bus Efficiency**: Single connection reused for all reports

### Security

- **No authentication required**: Simplifies pairing but less secure
- **Authorization not required**: Automatic acceptance of connections
- **Recommendation**: Only use in trusted environments or add PIN pairing

### Testing

To test the implementation:

1. **Enable HID mode** in the Bluetooth app
2. **Make discoverable** and pair from another device
3. **Open gamepad tester** on target device (e.g., https://gamepad-tester.com)
4. **Press buttons** and move sticks on MuOS device
5. **Verify** all inputs are recognized

Common test devices:
- Linux: `jstest /dev/input/js0` or `evtest`
- Windows: Game Controllers settings panel
- Android: Gamepad Tester app
- Web: https://html5gamepad.com

### Known Issues

1. **D-Bus permissions**: May require bluetoothd to run with `-C` flag (compatible mode)
2. **Some devices**: May not recognize the generic HID descriptor
3. **Latency**: Bluetooth adds inherent 10-20ms input lag
4. **Reconnection**: May require re-pairing after device restarts

### Future Enhancements

- [ ] Simultaneous client+server modes
- [ ] Custom button mappings
- [ ] Rumble/haptic feedback support
- [ ] Battery level reporting
- [ ] Multiple simultaneous connections
- [ ] Xbox/PS controller profile emulation
- [ ] Touch screen input forwarding

## Dependencies

**Runtime**:
- BlueZ 5.50+ (`bluetoothd`, `bluetoothctl`, `hciconfig`)
- Python 3.6+ with `python3-dbus` and `python3-gi`
- LÖVE 11.x framework
- Linux kernel with HID Bluetooth support

**Development**:
- Understanding of Lua (LÖVE framework)
- Understanding of Python D-Bus
- Understanding of USB HID specification
- Understanding of Bluetooth SDP/L2CAP protocols

## References

- [USB HID Specification](https://www.usb.org/hid)
- [BlueZ D-Bus API](https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc)
- [Bluetooth HID Profile](https://www.bluetooth.com/specifications/specs/human-interface-device-profile-1-1-1/)
- [LÖVE Framework](https://love2d.org/)
- GitHub Projects:
  - [BTGamepad](https://github.com/007durgesh219/BTGamepad) - Emulate Bluetooth HID devices
  - [EmuBTHID](https://github.com/Alkaid-Benetnash/EmuBTHID) - BlueZ HID emulation
  - [BluezGP](https://github.com/smoscar/BluezGP) - Bluetooth gamepad emulator

## Contributing

When modifying HID functionality:

1. Test on multiple target devices (PC, phone, etc.)
2. Verify controller input accuracy
3. Check for memory leaks in Python server
4. Ensure clean mode switching (no crashes)
5. Update documentation for any new features
6. Add log messages for debugging

## License

This implementation follows the same license as the main bltMuos project.
