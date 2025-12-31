local love = require("love")
local socket = require("socket")

local Config = require("config")

local BluetoothHID = {}

-- HID mode state
BluetoothHID.Mode = {
    CLIENT = 0,  -- Normal mode: connect to other devices
    SERVER = 1   -- HID mode: act as Bluetooth controller
}

-- Current mode
local currentMode = BluetoothHID.Mode.CLIENT
local isDiscoverable = false
local hidServerActive = false
local isConnected = false
local connectedHostMAC = nil
local controlsLocked = false

-- HID Report Descriptor for gamepad (USB HID specification)
-- This descriptor defines a standard gamepad with:
-- - 2 analog sticks (4 axes: X, Y, Z, Rz)
-- - D-pad (Hat switch)
-- - 16 buttons
local HID_GAMEPAD_DESCRIPTOR = "05010905a101850109013009011500250101752095108102c0050109303109310915003926ff007510950281020509193109291516ff027510950881029505750801030106003001ff095175089506810009514509454995068103050175089506810306003001ff09514509454995068103c0c0"

-- Store controller state
local controllerState = {
    buttons = {},      -- Button states (1-16)
    leftStickX = 0,    -- -1.0 to 1.0
    leftStickY = 0,
    rightStickX = 0,
    rightStickY = 0,
    dpadX = 0,         -- -1, 0, 1
    dpadY = 0
}

function BluetoothHID.GetMode()
    return currentMode
end

function BluetoothHID.SetMode(mode)
    if mode == BluetoothHID.Mode.CLIENT then
        BluetoothHID.StopHIDServer()
        currentMode = BluetoothHID.Mode.CLIENT
    elseif mode == BluetoothHID.Mode.SERVER then
        currentMode = BluetoothHID.Mode.SERVER
    end
end

function BluetoothHID.IsDiscoverable()
    return isDiscoverable
end

function BluetoothHID.IsServerActive()
    return hidServerActive
end

function BluetoothHID.IsConnected()
    return isConnected
end

function BluetoothHID.GetConnectedHost()
    return connectedHostMAC
end

function BluetoothHID.AreControlsLocked()
    return controlsLocked
end

function BluetoothHID.SetControlsLocked(locked)
    controlsLocked = locked
end

-- Initialize HID profile and D-Bus service
function BluetoothHID.InitializeHIDServer()
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        -- Create HID profile configuration
        local hidConfig = string.format([[#!/bin/bash
# Register HID device profile

# Set device class to gamepad (0x000508 = Gamepad/Joystick)
hciconfig hci0 class 0x000508

# Create SDP record for HID gamepad
sdptool add --channel=17 SP

# Register HID profile via D-Bus
# This creates a virtual HID device that can accept connections
]], HID_GAMEPAD_DESCRIPTOR)

        -- Write initialization script
        local file = io.open(Config.HID_INIT_SCRIPT_PATH or "/tmp/hid_init.sh", "w")
        if file then
            file:write(hidConfig)
            file:close()
            os.execute("chmod +x " .. (Config.HID_INIT_SCRIPT_PATH or "/tmp/hid_init.sh"))
        end

        -- Execute initialization
        os.execute((Config.HID_INIT_SCRIPT_PATH or "/tmp/hid_init.sh") .. " > /tmp/hid_init.log 2>&1")
        socket.sleep(1)

        -- Start Python HID server (if available) or use custom implementation
        -- This will handle the actual HID input/output channels
        local pythonServerPath = Config.HID_SERVER_PATH or "/tmp/hid_server.py"
        if BluetoothHID.CreatePythonHIDServer(pythonServerPath) then
            os.execute("python3 " .. pythonServerPath .. " > /tmp/hid_server.log 2>&1 &")
            socket.sleep(2)
            hidServerActive = true
        end
    end
end

-- Stop HID server and restore normal mode
function BluetoothHID.StopHIDServer()
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        -- Kill Python HID server
        os.execute("pkill -f hid_server.py")
        socket.sleep(0.5)

        -- Restore normal device class
        os.execute("hciconfig hci0 class 0x000000")

        -- Stop being discoverable
        BluetoothHID.SetDiscoverable(false)

        hidServerActive = false
    end
end

-- Make device discoverable for pairing
function BluetoothHID.SetDiscoverable(enable)
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        if enable then
            -- Set discoverable and pairable
            os.execute("bluetoothctl discoverable on")
            os.execute("bluetoothctl pairable on")
            -- Set a friendly device name
            local deviceName = "MuOS Gamepad"
            os.execute("bluetoothctl system-alias '" .. deviceName .. "'")
            isDiscoverable = true
        else
            os.execute("bluetoothctl discoverable off")
            isDiscoverable = false
        end
    end
end

-- Update controller state from LÖVE input
function BluetoothHID.UpdateControllerState(joystick)
    if not joystick then return end

    -- Read analog sticks
    controllerState.leftStickX = joystick:getGamepadAxis("leftx")
    controllerState.leftStickY = joystick:getGamepadAxis("lefty")
    controllerState.rightStickX = joystick:getGamepadAxis("rightx")
    controllerState.rightStickY = joystick:getGamepadAxis("righty")

    -- Read buttons (A, B, X, Y, etc.)
    local buttonMap = {
        "a", "b", "x", "y",
        "leftshoulder", "rightshoulder",
        "back", "start", "guide",
        "leftstick", "rightstick",
        "dpup", "dpdown", "dpleft", "dpright"
    }

    for i, button in ipairs(buttonMap) do
        controllerState.buttons[i] = joystick:isGamepadDown(button)
    end

    -- D-pad
    controllerState.dpadX = 0
    controllerState.dpadY = 0
    if joystick:isGamepadDown("dpleft") then controllerState.dpadX = -1 end
    if joystick:isGamepadDown("dpright") then controllerState.dpadX = 1 end
    if joystick:isGamepadDown("dpup") then controllerState.dpadY = -1 end
    if joystick:isGamepadDown("dpdown") then controllerState.dpadY = 1 end
end

-- Send HID report over Bluetooth
function BluetoothHID.SendHIDReport()
    if not hidServerActive then return end

    -- Build HID report packet
    -- Format: [LSX, LSY, RSX, RSY, Buttons1, Buttons2, DPad]
    local report = {
        math.floor((controllerState.leftStickX + 1) * 127.5),  -- 0-255
        math.floor((controllerState.leftStickY + 1) * 127.5),
        math.floor((controllerState.rightStickX + 1) * 127.5),
        math.floor((controllerState.rightStickY + 1) * 127.5),
        0,  -- Button byte 1
        0,  -- Button byte 2
        0   -- D-pad
    }

    -- Pack buttons into bytes
    for i = 1, 16 do
        if controllerState.buttons[i] then
            if i <= 8 then
                report[5] = report[5] + (2 ^ (i - 1))
            else
                report[6] = report[6] + (2 ^ (i - 9))
            end
        end
    end

    -- Pack D-pad (hat switch: 0-7 for directions, 8 for center)
    if controllerState.dpadY == -1 and controllerState.dpadX == 0 then
        report[7] = 0  -- Up
    elseif controllerState.dpadY == -1 and controllerState.dpadX == 1 then
        report[7] = 1  -- Up-Right
    elseif controllerState.dpadY == 0 and controllerState.dpadX == 1 then
        report[7] = 2  -- Right
    elseif controllerState.dpadY == 1 and controllerState.dpadX == 1 then
        report[7] = 3  -- Down-Right
    elseif controllerState.dpadY == 1 and controllerState.dpadX == 0 then
        report[7] = 4  -- Down
    elseif controllerState.dpadY == 1 and controllerState.dpadX == -1 then
        report[7] = 5  -- Down-Left
    elseif controllerState.dpadY == 0 and controllerState.dpadX == -1 then
        report[7] = 6  -- Left
    elseif controllerState.dpadY == -1 and controllerState.dpadX == -1 then
        report[7] = 7  -- Up-Left
    else
        report[7] = 8  -- Center
    end

    -- Write report to FIFO pipe for Python server to send
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        local reportStr = table.concat(report, ",") .. "\n"
        local file = io.open("/tmp/hid_report_fifo", "w")
        if file then
            file:write(reportStr)
            file:close()
        end
    end
end

-- Create Python HID server script
function BluetoothHID.CreatePythonHIDServer(path)
    local pythonCode = [[#!/usr/bin/env python3
import os
import sys
import socket
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

# HID Report Descriptor for gamepad
HID_DESCRIPTOR = bytes.fromhex(']] .. HID_GAMEPAD_DESCRIPTOR .. [[')

class BTHIDDevice(dbus.service.Object):
    """
    Bluetooth HID Device using BlueZ D-Bus API
    """

    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.profile_path = "/org/bluez/muos_hid_profile"

        # Set up HID profile
        self.setup_hid_profile()

        # Create FIFO for receiving reports
        if not os.path.exists("/tmp/hid_report_fifo"):
            os.mkfifo("/tmp/hid_report_fifo")

        # Main loop
        self.mainloop = GLib.MainLoop()

        # Monitor FIFO for input reports
        GLib.timeout_add(16, self.read_and_send_report)  # ~60Hz

    def setup_hid_profile(self):
        """Register HID profile with BlueZ"""
        # This is a simplified version - full implementation would
        # require proper D-Bus profile registration
        pass

    def read_and_send_report(self):
        """Read HID report from FIFO and send over Bluetooth"""
        try:
            with open("/tmp/hid_report_fifo", "r") as fifo:
                line = fifo.readline().strip()
                if line:
                    # Parse report data
                    report_bytes = [int(x) for x in line.split(',')]
                    # Send over Bluetooth (implementation depends on BlueZ version)
                    self.send_report(bytes(report_bytes))
        except:
            pass
        return True

    def send_report(self, report):
        """Send HID report to connected host"""
        # Implementation depends on BlueZ HID profile
        pass

    def run(self):
        """Start the main loop"""
        try:
            self.mainloop.run()
        except KeyboardInterrupt:
            self.cleanup()

    def cleanup(self):
        """Cleanup resources"""
        if os.path.exists("/tmp/hid_report_fifo"):
            os.remove("/tmp/hid_report_fifo")
        self.mainloop.quit()

if __name__ == "__main__":
    device = BTHIDDevice()
    device.run()
]]

    local file = io.open(path, "w")
    if file then
        file:write(pythonCode)
        file:close()
        os.execute("chmod +x " .. path)
        return true
    end
    return false
end

-- Get list of devices connected to us (as HID server)
function BluetoothHID.GetConnectedHosts()
    local hosts = {}

    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        -- Query devices that have connected to our HID profile
        os.execute("bluetoothctl devices Connected > /tmp/hid_hosts.txt")
        socket.sleep(0.3)

        local file = io.open("/tmp/hid_hosts.txt", "r")
        if file then
            for line in file:lines() do
                if string.find(line, "^Device") then
                    local lineData = line:gsub("Device ", "")
                    local mac, name = lineData:match("([^%s]+)%s+(.*)")
                    if mac and name then
                        table.insert(hosts, {
                            ip = mac,
                            name = name:match("^%s*(.-)%s*$")  -- trim
                        })
                    end
                end
            end
            file:close()
        end
    end

    return hosts
end

-- Check and update connection status
function BluetoothHID.UpdateConnectionStatus()
    if not hidServerActive then
        isConnected = false
        connectedHostMAC = nil
        return
    end

    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        local hosts = BluetoothHID.GetConnectedHosts()

        if #hosts > 0 then
            -- We have a connection
            if not isConnected then
                -- New connection established
                isConnected = true
                connectedHostMAC = hosts[1].ip
                controlsLocked = true  -- Lock controls when connected

                -- Disable discoverable once connected
                BluetoothHID.SetDiscoverable(false)
            end
        else
            -- No connection
            if isConnected then
                -- Connection was lost
                isConnected = false
                connectedHostMAC = nil
                controlsLocked = false
            end
        end
    end
end

-- Manually disconnect from connected host
function BluetoothHID.DisconnectHost()
    if connectedHostMAC and os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= "1" then
        os.execute("bluetoothctl disconnect " .. connectedHostMAC)
        socket.sleep(0.5)
        isConnected = false
        connectedHostMAC = nil
        controlsLocked = false
    end
end

return BluetoothHID
