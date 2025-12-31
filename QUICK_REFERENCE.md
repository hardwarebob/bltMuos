# HID Gamepad Mode - Quick Reference Card

## 🎮 Quick Start (30 Seconds)

1. Open Bluetooth app
2. Press **Y** → Press **A** (Switch to Server Mode)
3. Press **A** (Make Discoverable)
4. On target device: Pair with "MuOS Gamepad"
5. Play!

## 🎯 Button Controls

### Client Mode (Normal Bluetooth)
| Button | Action |
|--------|--------|
| A | Connect to device |
| B | Quit / Cancel |
| X | Disconnect/Remove device |
| Y | **Switch to Server Mode** |
| L1 | **Scan for devices** |
| R1 | Select audio output |
| Start | Bluetooth ON |
| Select | Bluetooth OFF |

### Server Mode (HID Gamepad)
| Button | Action |
|--------|--------|
| A | Make Discoverable / Hide |
| B | Quit application |
| X | Stop HID Server |
| Y | **Switch to Client Mode** |
| Start | Bluetooth ON |
| Select | Bluetooth OFF |

## 📋 Status Indicators

| Indicator | Meaning |
|-----------|---------|
| Mode: Client | Normal Bluetooth mode |
| Mode: Server | HID Gamepad mode active |
| HID Server: ACTIVE | Server running, ready to pair |
| HID Server: INACTIVE | Server stopped |
| Discoverable: YES | Visible to other devices |
| Discoverable: NO | Hidden from scanning |

## 🔧 Troubleshooting Fast Track

### Can't find "MuOS Gamepad"?
→ Press **A** to make discoverable

### Paired but no input?
→ Check "HID Server: ACTIVE" status
→ Press **X** to stop, then **Y** twice to restart

### Connection drops?
→ Move closer (5-10m range)
→ Turn Bluetooth OFF then ON

### Back to normal Bluetooth?
→ Press **Y** → Press **A**

## 📊 Quick Specs

- **Device Name**: MuOS Gamepad
- **Input Latency**: ~20ms
- **Range**: 5-10 meters
- **Report Rate**: 60 Hz
- **Buttons**: 16
- **Analog Sticks**: 2 (4 axes)
- **D-Pad**: 8 directions

## 🖥️ Compatible Devices

✅ Windows PC
✅ Linux PC
✅ macOS
✅ Android
✅ iOS
✅ PlayStation (some models)
✅ Xbox (some models)
✅ Smart TV

## 📁 File Locations

```
Logs:     /tmp/hid_server.log
          /tmp/hid_init.log

Scripts:  .bluetooth/bin/hid_control.sh
          .bluetooth/bin/hid_init.sh
          .bluetooth/bin/hid_server_dbus.py

Modules:  .bluetooth/bluetooth_hid.lua
          .bluetooth/hid_ui.lua
```

## 🆘 Emergency Recovery

**App frozen?**
```bash
killall love
```

**HID server stuck?**
```bash
pkill -f hid_server.py
```

**Bluetooth broken?**
```bash
systemctl restart bluetooth
```

**Reset everything?**
```bash
rfkill unblock all
hciconfig hci0 reset
```

## 📖 Full Documentation

- 📘 User Guide: [HID_MODE_GUIDE.md](HID_MODE_GUIDE.md)
- 🔧 Technical Docs: [HID_IMPLEMENTATION.md](HID_IMPLEMENTATION.md)
- ✅ Testing: [TESTING_GUIDE.md](TESTING_GUIDE.md)
- 📊 Summary: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

## 💡 Pro Tips

1. **Lower Latency**: Stay within 3 meters for best response
2. **Save Battery**: Turn off discoverable (press A) when paired
3. **Quick Switch**: Use Y button to toggle modes anytime
4. **Reconnect**: Most devices auto-reconnect after pairing once

## ⚠️ Known Limits

- One device at a time
- No rumble feedback
- 10-20ms latency (Bluetooth)
- Generic gamepad only

---

**Need help?** Check logs first, then see full guides!
