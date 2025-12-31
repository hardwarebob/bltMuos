# Button Mapping Changes for HID Mode

## Summary

To accommodate the new HID Gamepad Mode feature, some button mappings have been updated to avoid conflicts while maintaining all original functionality.

## Button Changes

### Y Button (Changed)

**Before:**
- **Y** = Open scan timeout selection (to scan for devices)

**After:**
- **Y** = Toggle between Client Mode and Server Mode (HID)

**Reason:** Y button is more prominent and better suited for the important mode-switching function.

---

### L1 Button (Changed)

**Before:**
- **L1** = Open audio sink selection

**After:**
- **L1** = Open scan timeout selection (to scan for devices)

**Reason:** Scan functionality moved from Y to L1, keeping all original features accessible.

---

### R1 Button (New)

**Before:**
- **R1** = (Not used)

**After:**
- **R1** = Open audio sink selection

**Reason:** Audio selection moved from L1 to R1 to make room for scan on L1.

---

## Complete Button Reference

### Client Mode (Normal Bluetooth)

| Button | Action |
|--------|--------|
| **A** | Connect to selected device |
| **B** | Quit application / Cancel |
| **X** | Disconnect/Remove selected device |
| **Y** | **Switch to Server Mode** ⭐ NEW |
| **L1** | **Scan for devices** ⭐ MOVED |
| **R1** | **Select audio output** ⭐ MOVED |
| **Start** | Turn Bluetooth ON |
| **Select** | Turn Bluetooth OFF |
| **D-Pad Left/Right** | Switch between Available/Connected tabs |
| **D-Pad Up/Down** | Navigate device list |

### Server Mode (HID Gamepad)

| Button | Action |
|--------|--------|
| **A** | Make discoverable / Hide |
| **B** | Quit application |
| **X** | Stop HID server |
| **Y** | **Switch to Client Mode** ⭐ NEW |
| **Start** | Turn Bluetooth ON |
| **Select** | Turn Bluetooth OFF |

## UI Updates

The on-screen button hints have been updated to reflect these changes:

1. **Available Devices panel**: Now shows L1 icon for "Scan" (was Y)
2. **Mode toggle bar**: Shows Y icon for "Switch" mode
3. **HID Server screen**: Shows Y icon for returning to Client mode

## Migration Notes

**For existing users:**

- If you were pressing **Y to scan**, now press **L1** instead
- If you were pressing **L1 for audio**, now press **R1** instead
- The new **Y button** opens the mode selection dialog

**No other workflows are affected** - all original functionality is preserved, just on different buttons.

## Rationale

This button remapping achieves several goals:

1. ✅ **Prominent placement**: Mode switching uses Y (face button)
2. ✅ **No lost features**: All original functions still accessible
3. ✅ **Logical grouping**: L1/R1 for secondary functions (scan/audio)
4. ✅ **Muscle memory**: Most common actions (A=Connect, B=Quit, X=Disconnect) unchanged
5. ✅ **Discoverability**: On-screen hints show correct buttons

## Testing

After these changes, verify:

- [x] Y button opens mode selection modal
- [x] L1 button opens scan timeout selection (in Client mode)
- [x] R1 button opens audio selection
- [x] All UI labels show correct button icons
- [x] Mode switching works in both directions
- [x] Original Bluetooth functionality intact

---

**Last Updated:** 2025-12-31
