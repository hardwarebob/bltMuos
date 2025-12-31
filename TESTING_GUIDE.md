# HID Mode Testing Guide

## Quick Test Checklist

Use this checklist to verify the HID implementation works correctly.

### Pre-Test Setup

- [ ] Device has Bluetooth enabled
- [ ] Python 3 with dbus and gi libraries installed
- [ ] BlueZ 5.50+ is running
- [ ] LÖVE framework is installed
- [ ] Target device (PC/phone) is ready with Bluetooth enabled

### Test 1: Basic Mode Switching

1. [ ] Launch Bluetooth app
2. [ ] Bluetooth turns on successfully
3. [ ] Press Y button - mode selection modal appears
4. [ ] Modal shows "Switch to Server Mode (Gamepad)?"
5. [ ] Press A to confirm
6. [ ] UI changes to show "Mode: Server (Act as Gamepad)"
7. [ ] Press Y again
8. [ ] Modal shows "Switch to Client Mode (Normal)?"
9. [ ] Press A to confirm
10. [ ] UI returns to normal client mode

**Expected Result**: Smooth transition between modes without crashes

### Test 2: HID Server Initialization

1. [ ] Switch to Server Mode
2. [ ] Status shows "HID Server: ACTIVE" (within 3 seconds)
3. [ ] Instructions are displayed clearly
4. [ ] Bottom bar shows "A: Discoverable" button

**Expected Result**: Server starts automatically and shows active status

**If Failed**: Check `/tmp/hid_init.log` and `/tmp/hid_server.log`

### Test 3: Making Device Discoverable

1. [ ] In Server Mode, press A button
2. [ ] Status changes to "Discoverable: YES"
3. [ ] Message appears: "Device is now discoverable - Pair from your target device"
4. [ ] Press A again
5. [ ] Status changes to "Discoverable: NO"
6. [ ] Message appears: "Device is now hidden"

**Expected Result**: Discoverable status toggles correctly

### Test 4: Pairing from PC (Windows)

1. [ ] Make MuOS device discoverable (press A)
2. [ ] On Windows PC:
   - Open Settings → Bluetooth & devices
   - Click "Add device" → Bluetooth
   - Wait for "MuOS Gamepad" to appear
   - Click "MuOS Gamepad"
   - Wait for pairing
3. [ ] On MuOS device:
   - Connection should be accepted automatically
   - "MuOS Gamepad" should appear in "Connected Hosts"
4. [ ] On Windows:
   - Device should show as "Connected"
   - Check "Game Controllers" panel (joy.cpl)
   - "MuOS Gamepad" should be listed

**Expected Result**: Successful pairing without manual PIN entry

### Test 5: Pairing from Linux

1. [ ] Make MuOS device discoverable
2. [ ] On Linux PC:
   ```bash
   bluetoothctl
   scan on
   # Wait for "MuOS Gamepad" to appear
   pair [MAC_ADDRESS]
   connect [MAC_ADDRESS]
   ```
3. [ ] Verify with:
   ```bash
   ls /dev/input/js*  # Should show new joystick
   jstest /dev/input/js0  # Should show device info
   ```

**Expected Result**: Device appears as /dev/input/jsX

### Test 6: Pairing from Android

1. [ ] Make MuOS device discoverable
2. [ ] On Android:
   - Open Settings → Connected devices → Pair new device
   - Tap "MuOS Gamepad"
   - Wait for connection
3. [ ] Install "Gamepad Tester" app
4. [ ] Open app - should detect gamepad

**Expected Result**: Gamepad recognized in Android apps

### Test 7: Controller Input - Buttons

1. [ ] Pair with target device
2. [ ] Open gamepad testing tool on target:
   - Windows: joy.cpl → Properties → Test
   - Linux: `jstest /dev/input/js0`
   - Web: https://gamepad-tester.com
   - Android: Gamepad Tester app

3. [ ] Test each button on MuOS device:
   - [ ] A button registers
   - [ ] B button registers
   - [ ] X button registers
   - [ ] Y button registers
   - [ ] Start button registers
   - [ ] Select button registers
   - [ ] L1/L2 buttons register
   - [ ] R1/R2 buttons register

**Expected Result**: All buttons detected with no delay

### Test 8: Controller Input - Analog Sticks

1. [ ] In gamepad tester, move left stick:
   - [ ] Up/Down moves Y axis
   - [ ] Left/Right moves X axis
   - [ ] Values range from 0 to 255 (or -1 to 1)
   - [ ] Centered position is ~128 (or 0)

2. [ ] Move right stick:
   - [ ] Up/Down moves Rz axis
   - [ ] Left/Right moves Z axis
   - [ ] Values range correctly

**Expected Result**: Smooth analog movement, no jitter

### Test 9: Controller Input - D-Pad

1. [ ] Press D-pad directions:
   - [ ] Up registers
   - [ ] Down registers
   - [ ] Left registers
   - [ ] Right registers
   - [ ] Diagonals work (Up+Right, etc.)

**Expected Result**: All 8 directions detected

### Test 10: Multiple Connect/Disconnect Cycles

1. [ ] Pair device
2. [ ] Disconnect from target device
3. [ ] Reconnect from target device
4. [ ] Repeat 3 times
5. [ ] Controller still works after each reconnect

**Expected Result**: Stable reconnections without needing to re-pair

### Test 11: Gaming Performance

1. [ ] Pair with PC
2. [ ] Launch a game that supports gamepads (e.g., Steam Big Picture)
3. [ ] Test gameplay:
   - [ ] Input lag is acceptable (<50ms perceived)
   - [ ] No missed inputs
   - [ ] Analog sticks feel responsive
   - [ ] No random disconnections during gameplay

**Expected Result**: Playable gaming experience

### Test 12: Range Test

1. [ ] Pair device
2. [ ] Move away from target device
3. [ ] Test at distances:
   - [ ] 2 meters - works
   - [ ] 5 meters - works
   - [ ] 10 meters - works (may vary)
   - [ ] 15 meters - may disconnect

**Expected Result**: At least 5-10 meters range

### Test 13: Battery Reporting (Optional)

1. [ ] Check if target device shows battery level
2. [ ] Note: This feature may not be implemented yet

**Expected Result**: May not work - this is acceptable for v1

### Test 14: Switching Back to Client Mode

1. [ ] In Server Mode, press Y
2. [ ] Press A to switch to Client Mode
3. [ ] HID server stops (status changes to INACTIVE)
4. [ ] UI returns to normal Bluetooth client
5. [ ] Can scan and connect to other devices normally

**Expected Result**: Clean shutdown, no residual HID processes

### Test 15: Log Files

1. [ ] Check log files exist:
   ```bash
   ls -la /tmp/hid_*.log
   cat /tmp/hid_init.log
   cat /tmp/hid_server.log
   ```

2. [ ] Logs should contain:
   - [ ] "HID initialization complete" in hid_init.log
   - [ ] "HID server started successfully" in hid_server.log
   - [ ] No Python tracebacks or errors

**Expected Result**: Clean logs with no errors

## Common Issues and Solutions

### Issue: HID Server shows "INACTIVE"

**Diagnosis**:
```bash
cat /tmp/hid_server.log
```

**Common Causes**:
- Python dependencies missing: `pip3 install dbus-python PyGObject`
- BlueZ not running: `systemctl status bluetooth`
- Permissions issue: Check dbus policy

### Issue: Can't find "MuOS Gamepad" when scanning

**Solutions**:
1. Verify discoverable is ON (press A)
2. Check Bluetooth is powered:
   ```bash
   hciconfig hci0
   ```
3. Check device class:
   ```bash
   hciconfig hci0 class
   # Should show: 0x000508
   ```
4. Restart HID server (X to stop, switch modes)

### Issue: Paired but inputs don't work

**Diagnosis**:
1. Check FIFO exists:
   ```bash
   ls -la /tmp/hid_report_fifo
   ```

2. Test FIFO writing:
   ```bash
   echo "128,128,128,128,0,0,8" > /tmp/hid_report_fifo
   ```

3. Check Python server is reading:
   ```bash
   ps aux | grep hid_server
   ```

### Issue: Input lag is too high

**Possible Causes**:
- Bluetooth interference (move closer)
- Target device CPU overload
- Bluetooth adapter quality

**Test latency**:
- Should be <30ms for most devices
- Web tools: https://gamepad-tester.com shows input immediately

## Performance Benchmarks

Expected values:

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| Pairing Time | <5s | <10s | >10s |
| Input Latency | <20ms | <50ms | >50ms |
| Report Rate | 60Hz | 30Hz | <30Hz |
| Range | >10m | >5m | <5m |
| Battery Impact | <5% extra | <10% | >10% |

## Reporting Issues

When reporting bugs, include:

1. **Device Info**:
   - MuOS device model
   - BlueZ version: `bluetoothd --version`
   - Python version: `python3 --version`

2. **Logs**:
   ```bash
   cat /tmp/hid_init.log
   cat /tmp/hid_server.log
   dmesg | grep -i bluetooth | tail -20
   ```

3. **Target Device**:
   - OS and version
   - Bluetooth adapter info

4. **Steps to Reproduce**:
   - What you did
   - What you expected
   - What actually happened

## Success Criteria

The implementation is considered successful if:

- ✅ Mode switching works without crashes
- ✅ Device pairs with at least 2 different OS types (e.g., Windows + Android)
- ✅ All buttons and analog sticks register correctly
- ✅ Input latency is <50ms
- ✅ Connection is stable for >5 minutes of continuous use
- ✅ Can reconnect after disconnection
- ✅ Switching back to client mode works cleanly

## Next Steps After Testing

If all tests pass:
1. Document any device-specific quirks
2. Update README with supported platforms
3. Create demo video (optional)
4. Submit for community testing

If tests fail:
1. Review logs for error messages
2. Check troubleshooting section
3. Test on different target devices
4. Report issues with full diagnostics
