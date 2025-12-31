local love = require("love")
local BluetoothHID = require("bluetooth_hid")

local HIDUI = {}

-- UI state
local showModeSelection = false
local connectedHosts = {}
local statusMessage = ""

-- Images and fonts will be passed in from main.lua
local ic_A, ic_B, ic_X, ic_Y
local fontBig, fontSmall, fontBold

function HIDUI.Init(icons, fonts)
    ic_A = icons.A
    ic_B = icons.B
    ic_X = icons.X
    ic_Y = icons.Y

    fontBig = fonts.big
    fontSmall = fonts.small
    fontBold = fonts.bold
end

function HIDUI.SetStatusMessage(msg)
    statusMessage = msg
end

function HIDUI.ShowModeSelection()
    showModeSelection = true
end

function HIDUI.HideModeSelection()
    showModeSelection = false
end

function HIDUI.IsModeSelectionShown()
    return showModeSelection
end

-- Draw mode toggle UI at the top
function HIDUI.DrawModeToggle()
    local xPos = 8
    local yPos = 55
    local currentMode = BluetoothHID.GetMode()

    -- Mode indicator box
    love.graphics.setColor(0.078, 0.106, 0.173)
    love.graphics.rectangle("fill", xPos, yPos, 623, 35, 4, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)

    if currentMode == BluetoothHID.Mode.CLIENT then
        love.graphics.print("Mode: Client (Connect to Devices)", xPos + 10, yPos + 8)
        love.graphics.draw(ic_Y, xPos + 580, yPos + 5)
        love.graphics.setFont(fontSmall)
        love.graphics.print("Switch", xPos + 520, yPos + 8)
    else
        love.graphics.print("Mode: Server (Act as Gamepad)", xPos + 10, yPos + 8)
        love.graphics.draw(ic_Y, xPos + 580, yPos + 5)
        love.graphics.setFont(fontSmall)
        love.graphics.print("Switch", xPos + 520, yPos + 8)
    end
end

-- Draw HID server UI when in server mode
function HIDUI.DrawHIDServerUI()
    local xPos = 8
    local yPos = 100
    local currentMode = BluetoothHID.GetMode()

    if currentMode ~= BluetoothHID.Mode.SERVER then
        return
    end

    -- Title
    love.graphics.setColor(0.141, 0.141, 0.141)
    love.graphics.rectangle("fill", xPos, yPos, 623, 40, 4, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBold)
    love.graphics.print("Bluetooth Gamepad Mode", xPos + 200, yPos + 8)

    yPos = yPos + 50

    -- Discoverable status
    love.graphics.setFont(fontSmall)
    local isDiscoverable = BluetoothHID.IsDiscoverable()
    local isServerActive = BluetoothHID.IsServerActive()

    love.graphics.setColor(0.094, 0.094, 0.094)
    love.graphics.rectangle("fill", xPos, yPos, 623, 60, 4, 4)

    love.graphics.setColor(1, 1, 1)
    yPos = yPos + 10

    if isServerActive then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print("HID Server: ACTIVE", xPos + 10, yPos)
    else
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.print("HID Server: INACTIVE", xPos + 10, yPos)
    end

    yPos = yPos + 25
    love.graphics.setColor(1, 1, 1)

    if isDiscoverable then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print("Discoverable: YES - Other devices can pair now!", xPos + 10, yPos)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Discoverable: NO - Press A to make discoverable", xPos + 10, yPos)
    end

    yPos = yPos + 50
    love.graphics.setColor(1, 1, 1)

    -- Instructions
    love.graphics.setColor(0.094, 0.094, 0.094)
    love.graphics.rectangle("fill", xPos, yPos, 623, 140, 4, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    yPos = yPos + 10

    love.graphics.print("Instructions:", xPos + 10, yPos)
    yPos = yPos + 25

    love.graphics.print("1. Press A to make this device discoverable", xPos + 20, yPos)
    yPos = yPos + 20

    love.graphics.print("2. On your target device (PC, phone, etc.):", xPos + 20, yPos)
    yPos = yPos + 20

    love.graphics.print("   - Open Bluetooth settings", xPos + 30, yPos)
    yPos = yPos + 20

    love.graphics.print("   - Look for 'MuOS Gamepad' and pair", xPos + 30, yPos)
    yPos = yPos + 20

    love.graphics.print("3. Your controller input will be sent to the paired device", xPos + 20, yPos)

    yPos = yPos + 40

    -- Status message
    if statusMessage ~= "" then
        love.graphics.setColor(0.2, 0.6, 0.9)
        love.graphics.print(statusMessage, xPos + 10, yPos)
    end

    -- Connected hosts
    yPos = yPos + 40
    connectedHosts = BluetoothHID.GetConnectedHosts()

    if #connectedHosts > 0 then
        love.graphics.setColor(0.141, 0.141, 0.141)
        love.graphics.rectangle("fill", xPos, yPos, 623, 30, 4, 4)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontBold)
        love.graphics.print("Connected Hosts:", xPos + 10, yPos + 5)

        yPos = yPos + 35

        for i, host in ipairs(connectedHosts) do
            love.graphics.setFont(fontSmall)
            love.graphics.setColor(0.094, 0.094, 0.094)
            love.graphics.rectangle("fill", xPos, yPos, 623, 25, 4, 4)

            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.print(host.name .. " (" .. host.ip .. ")", xPos + 10, yPos + 5)

            yPos = yPos + 30
        end
    end
end

-- Draw HID button hints at bottom
function HIDUI.DrawHIDButtons()
    local currentMode = BluetoothHID.GetMode()

    if currentMode ~= BluetoothHID.Mode.SERVER then
        return
    end

    local xPos = 250
    local yPos = 480 - 45

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)

    local isDiscoverable = BluetoothHID.IsDiscoverable()

    if isDiscoverable then
        love.graphics.draw(ic_A, xPos, yPos + 10)
        love.graphics.print("Hide", xPos + 40, yPos + 13)
    else
        love.graphics.draw(ic_A, xPos, yPos + 10)
        love.graphics.print("Discoverable", xPos + 40, yPos + 13)
    end

    xPos = xPos + 180
    if BluetoothHID.IsServerActive() then
        love.graphics.draw(ic_X, xPos, yPos + 10)
        love.graphics.print("Stop Server", xPos + 40, yPos + 13)
    end
end

-- Draw mode selection modal
function HIDUI.DrawModeSelectionModal()
    if not showModeSelection then
        return
    end

    local xPos = 120
    local yPos = 140

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Modal background
    love.graphics.setColor(0.094, 0.094, 0.094)
    love.graphics.rectangle("fill", xPos, yPos, 400, 200, 4, 4)

    -- Title bar
    love.graphics.setColor(0.141, 0.141, 0.141)
    love.graphics.rectangle("fill", xPos, yPos, 400, 35)

    love.graphics.setFont(fontBig)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Switch Mode?", xPos + 130, yPos + 5)

    -- Description
    love.graphics.setFont(fontSmall)
    yPos = yPos + 50

    love.graphics.print("Client Mode: Connect to Bluetooth devices", xPos + 20, yPos)
    yPos = yPos + 25
    love.graphics.print("Server Mode: Act as Bluetooth gamepad", xPos + 20, yPos)
    yPos = yPos + 40

    love.graphics.setColor(0.9, 0.6, 0.2)
    local currentMode = BluetoothHID.GetMode()
    if currentMode == BluetoothHID.Mode.CLIENT then
        love.graphics.print("Switch to Server Mode (Gamepad)?", xPos + 60, yPos)
    else
        love.graphics.print("Switch to Client Mode (Normal)?", xPos + 70, yPos)
    end

    -- Buttons
    yPos = yPos + 40
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(ic_A, xPos + 100, yPos)
    love.graphics.print("Confirm", xPos + 140, yPos + 3)

    love.graphics.draw(ic_B, xPos + 240, yPos)
    love.graphics.print("Cancel", xPos + 280, yPos + 3)
end

-- Handle mode selection input
function HIDUI.HandleModeSelectionInput(button)
    if not showModeSelection then
        return false
    end

    if button == "a" then
        -- Confirm mode switch
        local currentMode = BluetoothHID.GetMode()
        if currentMode == BluetoothHID.Mode.CLIENT then
            BluetoothHID.SetMode(BluetoothHID.Mode.SERVER)
            BluetoothHID.InitializeHIDServer()
            HIDUI.SetStatusMessage("Switched to Server Mode - HID Server starting...")
        else
            BluetoothHID.SetMode(BluetoothHID.Mode.CLIENT)
            HIDUI.SetStatusMessage("Switched to Client Mode")
        end
        showModeSelection = false
        return true
    elseif button == "b" then
        -- Cancel
        showModeSelection = false
        return true
    end

    return false
end

-- Handle HID-specific button presses
function HIDUI.HandleHIDInput(button)
    local currentMode = BluetoothHID.GetMode()

    if currentMode ~= BluetoothHID.Mode.SERVER then
        return false
    end

    if button == "a" then
        -- Toggle discoverable
        local isDiscoverable = BluetoothHID.IsDiscoverable()
        BluetoothHID.SetDiscoverable(not isDiscoverable)
        if not isDiscoverable then
            HIDUI.SetStatusMessage("Device is now discoverable - Pair from your target device")
        else
            HIDUI.SetStatusMessage("Device is now hidden")
        end
        return true
    elseif button == "x" then
        -- Stop HID server
        if BluetoothHID.IsServerActive() then
            BluetoothHID.StopHIDServer()
            HIDUI.SetStatusMessage("HID Server stopped")
        end
        return true
    elseif button == "y" then
        -- Show mode selection
        HIDUI.ShowModeSelection()
        return true
    end

    return false
end

-- Update controller state and send HID reports
function HIDUI.Update(dt)
    local currentMode = BluetoothHID.GetMode()

    if currentMode == BluetoothHID.Mode.SERVER and BluetoothHID.IsServerActive() then
        local joysticks = love.joystick.getJoysticks()
        if joysticks[1] then
            BluetoothHID.UpdateControllerState(joysticks[1])
            BluetoothHID.SendHIDReport()
        end
    end
end

return HIDUI
