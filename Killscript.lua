--[[
    AXE TOGGLE LOCAL SCRIPT (MODIFIED: Added Target Self Toggle)
]]

----------------------------------------------------
-- 1. SERVICES & VARIABLES
----------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Axe")

local isNPCToggled        = false
local isPlayerKillToggled = false
local isSelfTargetToggled = false -- NEW VARIABLE
local lastAttackTime      = 0
local DEFAULT_INTERVAL    = 0.3
local AttackInterval      = LocalPlayer:GetAttribute("SavedAttackInterval") or DEFAULT_INTERVAL

-- BLACK & WHITE PALETTE
local BG          = Color3.fromRGB(8, 8, 8)
local SURFACE     = Color3.fromRGB(18, 18, 18)
local BORDER      = Color3.fromRGB(38, 38, 38)
local BTN_WHITE   = Color3.fromRGB(255, 255, 255)
local BTN_TEXT    = Color3.fromRGB(8, 8, 8)
local TEXT_BRIGHT = Color3.fromRGB(255, 255, 255)
local TEXT_DIM    = Color3.fromRGB(130, 130, 130)
local OFF_COLOR   = Color3.fromRGB(28, 28, 28)

local FRAME_WIDTH  = 270
local FRAME_HEIGHT = 370 -- INCREASED HEIGHT FOR NEW BUTTON
local TOGGLE_SIZE  = 36
local RADIUS       = UDim.new(0, 6)
local RADIUS_SM    = UDim.new(0, 4)

----------------------------------------------------
-- 2. GUI CREATION
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name         = "AxeToggleUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Name             = "GUIToggleButton"
ToggleButton.Size             = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE)
ToggleButton.Position         = UDim2.fromOffset(12, 12)
ToggleButton.BackgroundColor3 = BG
ToggleButton.TextColor3       = TEXT_BRIGHT
ToggleButton.Text             = "+"
ToggleButton.Font             = Enum.Font.GothamBold
ToggleButton.TextSize         = 22
ToggleButton.AutoButtonColor  = false
ToggleButton.ZIndex           = 20
ToggleButton.Active           = true
Instance.new("UICorner", ToggleButton).CornerRadius = RADIUS

local toggleBorder = Instance.new("UIStroke", ToggleButton)
toggleBorder.Color     = BORDER
toggleBorder.Thickness = 1

local Frame = Instance.new("Frame", ScreenGui)
Frame.Name                   = "AxeControls"
Frame.Size                   = UDim2.fromOffset(FRAME_WIDTH, FRAME_HEIGHT)
Frame.Position               = UDim2.new(0.5, -FRAME_WIDTH/2, 0.5, -FRAME_HEIGHT/2)
Frame.BackgroundColor3       = BG
Frame.BorderSizePixel        = 0
Frame.Visible                = false
Frame.Active                 = true
Frame.ZIndex                 = 10
Instance.new("UICorner", Frame).CornerRadius = RADIUS

local frameBorder = Instance.new("UIStroke", Frame)
frameBorder.Color     = BORDER
frameBorder.Thickness = 1

local DragHandle = Instance.new("Frame", Frame)
DragHandle.Name             = "DragHandle"
DragHandle.Position         = UDim2.fromOffset(12, 12)
DragHandle.Size             = UDim2.fromOffset(FRAME_WIDTH - 24, 32)
DragHandle.BackgroundColor3 = SURFACE
DragHandle.BorderSizePixel  = 0
DragHandle.ZIndex           = 12
DragHandle.Active           = true
Instance.new("UICorner", DragHandle).CornerRadius = RADIUS_SM

local handleBorder = Instance.new("UIStroke", DragHandle)
handleBorder.Color     = BORDER
handleBorder.Thickness = 1

local titleLabel = Instance.new("TextLabel", DragHandle)
titleLabel.Position               = UDim2.fromOffset(12, 0)
titleLabel.Size                   = UDim2.fromOffset(FRAME_WIDTH - 60, 32)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3             = TEXT_BRIGHT
titleLabel.Text                   = "AXE PANEL"
titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.TextSize               = 12
titleLabel.ZIndex                 = 13

local function makeButton(parent, yPos, labelText, badgeText)
    local btn = Instance.new("TextButton", parent)
    btn.Position         = UDim2.fromOffset(12, yPos)
    btn.Size             = UDim2.fromOffset(FRAME_WIDTH - 24, 48)
    btn.BackgroundColor3 = BTN_WHITE
    btn.Text             = ""
    btn.AutoButtonColor  = false
    btn.ZIndex           = 11
    btn.Active           = true
    Instance.new("UICorner", btn).CornerRadius = RADIUS

    local lbl = Instance.new("TextLabel", btn)
    lbl.Name                  = "Label"
    lbl.Position              = UDim2.fromOffset(16, 0)
    lbl.Size                  = UDim2.fromOffset(FRAME_WIDTH - 100, 48)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3            = BTN_TEXT
    lbl.Text                  = labelText
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 13
    lbl.ZIndex                = 12

    local badge = Instance.new("TextLabel", btn)
    badge.Name             = "Badge"
    badge.Position         = UDim2.fromOffset(FRAME_WIDTH - 80, 13)
    badge.Size             = UDim2.fromOffset(44, 22)
    badge.BackgroundColor3 = OFF_COLOR
    badge.TextColor3       = TEXT_DIM
    badge.Text             = badgeText or "OFF"
    badge.Font             = Enum.Font.GothamBold
    badge.TextSize         = 10
    badge.ZIndex           = 12
    Instance.new("UICorner", badge).CornerRadius = RADIUS_SM

    return btn
end

local NPCToggle    = makeButton(Frame, 60,  "Kill NPCs",    "OFF")
local PlayerToggle = makeButton(Frame, 120, "Kill Players", "OFF")
local SelfToggle   = makeButton(Frame, 180, "Target Self",  "OFF") -- NEW BUTTON

------------------------------------
-- INTERVAL GROUP (shifted down)
------------------------------------
local IntervalGroup = Instance.new("Frame", Frame)
IntervalGroup.Name             = "InputGroup"
IntervalGroup.Position         = UDim2.fromOffset(12, 244)
IntervalGroup.Size             = UDim2.fromOffset(FRAME_WIDTH - 24, 100)
IntervalGroup.BackgroundColor3 = SURFACE
IntervalGroup.BorderSizePixel  = 0
IntervalGroup.ZIndex           = 11
Instance.new("UICorner", IntervalGroup).CornerRadius = RADIUS

local sectionLabel = Instance.new("TextLabel", IntervalGroup)
sectionLabel.Position               = UDim2.fromOffset(14, 10)
sectionLabel.Size                   = UDim2.fromOffset(FRAME_WIDTH - 48, 16)
sectionLabel.BackgroundTransparency = 1
sectionLabel.TextColor3             = TEXT_DIM
sectionLabel.Text                   = "ATTACK INTERVAL"
sectionLabel.TextXAlignment         = Enum.TextXAlignment.Left
sectionLabel.Font                   = Enum.Font.GothamBold
sectionLabel.TextSize               = 9
sectionLabel.ZIndex                 = 12

local INPUT_W = (FRAME_WIDTH - 24 - 28 - 8) * 0.65
local SET_W   = (FRAME_WIDTH - 24 - 28 - 8) * 0.35

local IntervalBox = Instance.new("TextBox", IntervalGroup)
IntervalBox.Name             = "IntervalTextBox"
IntervalBox.Position         = UDim2.fromOffset(14, 50)
IntervalBox.Size             = UDim2.fromOffset(INPUT_W, 34)
IntervalBox.BackgroundColor3 = BG
IntervalBox.TextColor3       = TEXT_BRIGHT
IntervalBox.Text             = string.format("%.2f", AttackInterval)
IntervalBox.Font             = Enum.Font.GothamBold
IntervalBox.TextSize         = 16
IntervalBox.ClearTextOnFocus = false
IntervalBox.ZIndex           = 12
Instance.new("UICorner", IntervalBox).CornerRadius = RADIUS_SM

local SetButton = Instance.new("TextButton", IntervalGroup)
SetButton.Name             = "SetButton"
SetButton.Position         = UDim2.fromOffset(14 + INPUT_W + 8, 50)
SetButton.Size             = UDim2.fromOffset(SET_W, 34)
SetButton.BackgroundColor3 = BTN_WHITE
SetButton.TextColor3       = BTN_TEXT
SetButton.Text             = "SET"
SetButton.Font             = Enum.Font.GothamBold
SetButton.TextSize         = 12
SetButton.AutoButtonColor  = false
SetButton.ZIndex           = 12
Instance.new("UICorner", SetButton).CornerRadius = RADIUS_SM

----------------------------------------------------
-- 3. TARGET CACHES
----------------------------------------------------
local npcModelCache   = {}
local playerCharCache = {}

local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function updateCaches()
    npcModelCache = {}
    playerCharCache = {}
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Humanoid") then
            local model = desc.Parent
            if model and model:IsA("Model") then
                local player = Players:GetPlayerFromCharacter(model)
                if player then
                    -- If Target Self is OFF, exclude LocalPlayer. If ON, include everyone.
                    if isSelfTargetToggled or player ~= LocalPlayer then
                        playerCharCache[model] = true
                    end
                else
                    npcModelCache[model] = true
                end
            end
        end
    end
end

updateCaches()

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Humanoid") then
        local model = desc.Parent
        if model and model:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                if isSelfTargetToggled or player ~= LocalPlayer then
                    playerCharCache[model] = true
                end
            else
                npcModelCache[model] = true
            end
        end
    end
end)

Workspace.DescendantRemoving:Connect(function(desc)
    if desc:IsA("Model") then
        npcModelCache[desc]   = nil
        playerCharCache[desc] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    if isSelfTargetToggled then playerCharCache[newChar] = true end
end)

----------------------------------------------------
-- 4. BUTTON INTERACTIONS
----------------------------------------------------
local function updateToggle(button, isToggled)
    local badge = button:FindFirstChild("Badge")
    if badge then
        if isToggled then
            badge.Text             = "ON"
            badge.BackgroundColor3 = BTN_WHITE
            badge.TextColor3       = BTN_TEXT
        else
            badge.Text             = "OFF"
            badge.BackgroundColor3 = OFF_COLOR
            badge.TextColor3       = TEXT_DIM
        end
    end
end

NPCToggle.Activated:Connect(function()
    isNPCToggled = not isNPCToggled
    updateToggle(NPCToggle, isNPCToggled)
end)

PlayerToggle.Activated:Connect(function()
    isPlayerKillToggled = not isPlayerKillToggled
    updateToggle(PlayerToggle, isPlayerKillToggled)
end)

SelfToggle.Activated:Connect(function()
    isSelfTargetToggled = not isSelfTargetToggled
    updateToggle(SelfToggle, isSelfTargetToggled)
    updateCaches() -- Refresh to include/exclude local player
end)

SetButton.Activated:Connect(function()
    local newVal = tonumber(IntervalBox.Text)
    if newVal and newVal > 0.01 then
        AttackInterval = newVal
        LocalPlayer:SetAttribute("SavedAttackInterval", newVal)
    end
end)

ToggleButton.Activated:Connect(function()
    Frame.Visible = not Frame.Visible
    ToggleButton.Text = Frame.Visible and "x" or "+"
end)

----------------------------------------------------
-- 5. DRAG LOGIC (Simplified for brevity)
----------------------------------------------------
local function setupDrag(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
setupDrag(Frame)
setupDrag(ToggleButton)

----------------------------------------------------
-- 6. CORE ATTACK LOOP
----------------------------------------------------
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastAttackTime < AttackInterval then return end
    if not (isNPCToggled or isPlayerKillToggled) then return end
    lastAttackTime = now

    local combinedTargets = {}
    if isNPCToggled then
        for model in pairs(npcModelCache) do
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then table.insert(combinedTargets, model) end
        end
    end
    if isPlayerKillToggled then
        for model in pairs(playerCharCache) do
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then table.insert(combinedTargets, model) end
        end
    end

    if #combinedTargets > 0 then
        RemoteEvent:FireServer({
            hb     = combinedTargets,
            action = "hit",
            combo  = 1,
            c      = Character,
            damage = 99999999999999
        })
    end
end)
