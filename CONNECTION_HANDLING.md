# HID Connection Handling

## Overview

The HID gamepad mode now properly manages connections with automatic control locking and a special disconnect combination to prevent accidental UI interaction while gaming.

## Features Implemented

### 1. Connection State Tracking

The system now tracks:
- **Connection status**: Whether a host device is connected
- **Connected host MAC**: The MAC address of the connected device
- **Controls locked**: Whether UI controls are disabled

### 2. Automatic Control Locking

**When a connection is established:**
- All UI controls are automatically locked
- All button inputs (A, B, X, Y, etc.) are sent to the connected host
- The screen displays a prominent "CONNECTED" status
- Discoverable mode is automatically disabled

**Why this is important:**
- Prevents accidental disconnection while gaming
- Ensures all inputs go to the game, not the UI
- Provides clear visual feedback that controls are active

### 3. Connection Status Display

**When connected, the UI shows:**
```
┌─────────────────────────────────────┐
│   Connected - Controls Active       │
├─────────────────────────────────────┤
│                                     │
│         CONNECTED                   │
│    Host: AA:BB:CC:DD:EE:FF         │
│  Controls locked - All inputs...    │
│  To disconnect: Press Select + R2   │
│                                     │
└─────────────────────────────────────┘
```

- Green highlighted background for connection status
- Shows MAC address of connected host
- Displays disconnect instructions
- Hides other UI elements (scan, discoverable buttons, etc.)

### 4. Special Disconnect Combination

**To disconnect and unlock controls:**
1. Press and hold **Select** (Back button)
2. While holding Select, press **R2** (Right Shoulder 2)
3. Connection will be terminated
4. Controls will be unlocked
5. UI returns to normal HID server mode

**Why this combination:**
- Unlikely to be pressed accidentally during gameplay
- Easy to remember and execute
- Uses buttons that are accessible without removing hands from controller
- Alternative to volume buttons (which may not be available via gamepad API)

### 5. Connection Monitoring

The system checks connection status every **1 second**:
- Automatically detects when a host connects
- Automatically detects when connection is lost
- Updates UI accordingly
- Unlocks controls if connection drops unexpectedly

## Technical Implementation

### State Variables

```lua
-- bluetooth_hid.lua
local isConnected = false           -- Connection state
local connectedHostMAC = nil        -- Host device MAC address
local controlsLocked = false        -- UI control lock state
```

### Key Functions

#### BluetoothHID.UpdateConnectionStatus()
- Queries `bluetoothctl devices Connected`
- Updates connection state
- Locks/unlocks controls automatically
- Disables discoverable when connected

#### BluetoothHID.DisconnectHost()
- Disconnects from connected host via `bluetoothctl disconnect`
- Unlocks controls
- Resets connection state

#### HIDUI.HandleHIDInput(button, joystick)
- Checks if controls are locked
- If locked, blocks all inputs except disconnect combination
- Detects Select + R2 combination via joystick API
- Calls DisconnectHost() when combination detected

### Connection Check Loop

```lua
-- hid_ui.lua Update function
connectionCheckTimer = connectionCheckTimer + dt
if connectionCheckTimer >= 1.0 then
    BluetoothHID.UpdateConnectionStatus()
    connectionCheckTimer = 0
end
```

## User Experience Flow

### Normal Connection Flow

1. **User switches to HID Server Mode** (Y button)
2. **User makes device discoverable** (A button)
3. **User pairs from target device** (PC, phone, etc.)
4. **Connection is established**
   - Auto-detected within 1 second
   - UI updates to show "CONNECTED"
   - Controls are automatically locked
   - Discoverable is disabled
5. **User plays game**
   - All controller inputs sent to host
   - UI inputs blocked
6. **User wants to disconnect**
   - Presses Select + R2
   - Connection terminates
   - Controls unlock
   - UI returns to normal

### Automatic Reconnection Handling

If the connection drops unexpectedly:
1. System detects disconnection within 1 second
2. Controls are automatically unlocked
3. UI returns to normal HID server mode
4. User can make discoverable again to reconnect

## Configuration

### Connection Check Interval

```lua
-- hid_ui.lua
local CONNECTION_CHECK_INTERVAL = 1.0  -- seconds
```

Can be adjusted if needed:
- **Lower** (e.g., 0.5s): More responsive, more CPU usage
- **Higher** (e.g., 2.0s): Less responsive, less CPU usage

### Disconnect Button Combination

Current: **Select + R2**

To change, modify in `hid_ui.lua`:
```lua
local selectPressed = joystick:isGamepadDown("back")  -- Select button
local r2Pressed = joystick:isGamepadDown("rightshoulder")  -- R2
```

Available button mappings:
- `"back"` - Select/Back
- `"start"` - Start
- `"leftshoulder"` - L1/LB
- `"rightshoulder"` - R1/RB
- `"lefttrigger"` - L2/LT
- `"righttrigger"` - R2/RT
- `"guide"` - Home/Guide

## Troubleshooting

### Controls won't unlock

**Problem**: Connected but can't interact with UI

**Solution**: Press Select + R2 to disconnect

### Connection keeps dropping

**Possible causes:**
1. **Bluetooth interference**: Move closer to target device
2. **Power management**: Check if host puts Bluetooth to sleep
3. **Range**: Stay within 5-10 meters

**Check logs:**
```bash
tail -f /tmp/hid_server.log
dmesg | grep -i bluetooth | tail -20
```

### Disconnect combination not working

**Troubleshooting:**
1. Ensure both buttons pressed simultaneously
2. Check if joystick is detected: `love.joystick.getJoysticks()`
3. Verify button mapping matches your device

**Manual disconnect via terminal:**
```bash
bluetoothctl disconnect [MAC_ADDRESS]
```

### Connection not detected

**Check:**
1. Is HID server active? (UI shows "HID Server: ACTIVE")
2. Is Python server running? `ps aux | grep hid_server`
3. Check connection logs:
   ```bash
   cat /tmp/hid_hosts.txt
   bluetoothctl devices Connected
   ```

## Testing

### Test Connection State

1. Start HID server mode
2. Make discoverable
3. Pair from another device
4. **Verify**: UI shows "CONNECTED" within 1 second
5. **Verify**: Controls are locked (A/B/X/Y don't work)
6. **Verify**: Controller inputs work in game on target device

### Test Disconnect Combination

1. While connected, press Select + R2
2. **Verify**: UI shows "Disconnected from host - Controls unlocked"
3. **Verify**: Controls are unlocked (can navigate UI)
4. **Verify**: Connection terminated on target device

### Test Auto-Reconnect

1. Connect to target device
2. Turn off Bluetooth on target device
3. **Verify**: MuOS detects disconnection within 1 second
4. **Verify**: Controls unlock automatically
5. Turn Bluetooth back on and reconnect
6. **Verify**: Connection re-established and controls lock again

## Known Limitations

1. **Volume buttons**: Real volume buttons not accessible via LÖVE gamepad API, so we use Select button instead
2. **Single connection**: Only one host can be connected at a time
3. **No manual pairing**: Host must initiate pairing
4. **1-second detection delay**: Connection status updated every second

## Future Enhancements

- [ ] Configurable disconnect button combination in UI
- [ ] Haptic feedback when connection established/lost
- [ ] Connection history/favorites
- [ ] Auto-reconnect to last paired device
- [ ] Battery level reporting to host
- [ ] Connection quality indicator (signal strength)

---

**Last Updated**: 2025-12-31
