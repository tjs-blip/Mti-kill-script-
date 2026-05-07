--[[
    AXE TOGGLE LOCAL SCRIPT (FINAL MERGED VERSION)
    *** MODIFICATION: Changed Parent from PlayerGui to CoreGui ***
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
local lastAttackTime      = 0
local DEFAULT_INTERVAL    = 0.3
local AttackInterval      = LocalPlayer:GetAttribute("SavedAttackInterval") or DEFAULT_INTERVAL

-- BLACK & WHITE PALETTE
local BG          = Color3.fromRGB(8, 8, 8)        -- near-black background
local SURFACE     = Color3.fromRGB(18, 18, 18)     -- slightly lifted surface
local BORDER      = Color3.fromRGB(38, 38, 38)     -- subtle border
local BTN_WHITE   = Color3.fromRGB(255, 255, 255)  -- white buttons
local BTN_TEXT    = Color3.fromRGB(8, 8, 8)        -- black text on white buttons
local TEXT_BRIGHT = Color3.fromRGB(255, 255, 255)  -- white text
local TEXT_DIM    = Color3.fromRGB(130, 130, 130)  -- muted label text
local ON_NPC      = Color3.fromRGB(255, 255, 255)  -- white = on (NPC)
local ON_PLAYER   = Color3.fromRGB(255, 255, 255)  -- white = on (Player)
local OFF_COLOR   = Color3.fromRGB(28, 28, 28)     -- dark off state
local SET_COLOR   = Color3.fromRGB(255, 255, 255)  -- white set button
local ERR_COLOR   = Color3.fromRGB(60, 60, 60)     -- dark grey for error flash

local FRAME_WIDTH  = 270
local FRAME_HEIGHT = 310
local TOGGLE_SIZE  = 36
local RADIUS       = UDim.new(0, 6)
local RADIUS_SM    = UDim.new(0, 4)

----------------------------------------------------
-- 2. GUI CREATION (manual positioning)
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name         = "AxeToggleUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10

----------------------------------------------------
-- FLOATING TOGGLE BUTTON
----------------------------------------------------
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

----------------------------------------------------
-- MAIN FRAME
----------------------------------------------------
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

----------------------------------------------------
-- DRAG HANDLE  (y=12, h=32)
----------------------------------------------------
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

-- Title text
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

-- Drag grip dots
local dragGrip = Instance.new("TextLabel", DragHandle)
dragGrip.Position               = UDim2.new(1, -28, 0, 0)
dragGrip.Size                   = UDim2.fromOffset(20, 32)
dragGrip.BackgroundTransparency = 1
dragGrip.TextColor3             = TEXT_DIM
dragGrip.Text                   = "= ="
dragGrip.Font                   = Enum.Font.Gotham
dragGrip.TextSize               = 10
dragGrip.ZIndex                 = 13

-- Thin white accent line under handle
local accent = Instance.new("Frame", Frame)
accent.Position         = UDim2.fromOffset(12, 46)
accent.Size             = UDim2.fromOffset(FRAME_WIDTH - 24, 1)
accent.BackgroundColor3 = BORDER
accent.BorderSizePixel  = 0
accent.ZIndex           = 11

----------------------------------------------------
-- HELPER: build a white button
----------------------------------------------------
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

    -- Main label
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

    -- Status badge (right side)
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

----------------------------------------------------
-- INTERVAL GROUP  (y=184, h=100)
----------------------------------------------------
local IntervalGroup = Instance.new("Frame", Frame)
IntervalGroup.Name             = "InputGroup"
IntervalGroup.Position         = UDim2.fromOffset(12, 184)
IntervalGroup.Size             = UDim2.fromOffset(FRAME_WIDTH - 24, 100)
IntervalGroup.BackgroundColor3 = SURFACE
IntervalGroup.BorderSizePixel  = 0
IntervalGroup.ZIndex           = 11
Instance.new("UICorner", IntervalGroup).CornerRadius = RADIUS

local groupBorder = Instance.new("UIStroke", IntervalGroup)
groupBorder.Color     = BORDER
groupBorder.Thickness = 1

-- Section label
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

-- Sub-label
local subLabel = Instance.new("TextLabel", IntervalGroup)
subLabel.Position               = UDim2.fromOffset(14, 24)
subLabel.Size                   = UDim2.fromOffset(FRAME_WIDTH - 48, 14)
subLabel.BackgroundTransparency = 1
subLabel.TextColor3             = Color3.fromRGB(70, 70, 70)
subLabel.Text                   = "seconds between attacks"
subLabel.TextXAlignment         = Enum.TextXAlignment.Left
subLabel.Font                   = Enum.Font.Gotham
subLabel.TextSize               = 9
subLabel.ZIndex                 = 12

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

local boxBorder = Instance.new("UIStroke", IntervalBox)
boxBorder.Color     = BORDER
boxBorder.Thickness = 1

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
-- 3. TARGET CACHES (event-driven)
----------------------------------------------------
local npcModelCache   = {}
local playerCharCache = {}

local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

for _, desc in ipairs(Workspace:GetDescendants()) do
    if desc:IsA("Humanoid") then
        local model = desc.Parent
        if model and model:IsA("Model") and model ~= Character and not isPlayerCharacter(model) then
            npcModelCache[model] = true
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        playerCharCache[player.Character] = true
    end
end

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Humanoid") then
        local model = desc.Parent
        if model and model:IsA("Model") and model ~= Character then
            if isPlayerCharacter(model) then
                if Players:GetPlayerFromCharacter(model) ~= LocalPlayer then
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

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        playerCharCache[char] = true
    end)
    player.CharacterRemoving:Connect(function(char)
        playerCharCache[char] = nil
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    for model in pairs(playerCharCache) do
        if Players:GetPlayerFromCharacter(model) == player then
            playerCharCache[model] = nil
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

local function findHumanoidInModel(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChildOfClass("Humanoid", true)
end

local function addValidTargetsFromCache(cache, outList)
    for model in pairs(cache) do
        local humanoid = findHumanoidInModel(model)
        if humanoid and humanoid.Health > 0 then
            outList[#outList + 1] = model
        end
    end
end

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

local function flashBox(flashColor, restoreColor)
    local flash = TweenService:Create(IntervalBox, TweenInfo.new(0.12), { BackgroundColor3 = flashColor })
    flash.Completed:Connect(function()
        TweenService:Create(IntervalBox, TweenInfo.new(0.25), { BackgroundColor3 = restoreColor }):Play()
    end)
    flash:Play()
end

local function handleIntervalInput()
    local newVal = tonumber(IntervalBox.Text)
    if newVal and newVal > 0.01 then
        AttackInterval = newVal
        LocalPlayer:SetAttribute("SavedAttackInterval", newVal)
        flashBox(Color3.fromRGB(50, 50, 50), BG)
    else
        IntervalBox.Text = string.format("%.2f", AttackInterval)
        flashBox(Color3.fromRGB(40, 20, 20), BG)
    end
end

IntervalBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then handleIntervalInput() end
end)

SetButton.Activated:Connect(handleIntervalInput)

ToggleButton.Activated:Connect(function()
    Frame.Visible = not Frame.Visible
    ToggleButton.Text = Frame.Visible and "x" or "+"
end)

----------------------------------------------------
-- 5. DUAL DRAG LOGIC
----------------------------------------------------
local isDragging      = false
local draggedElement  = nil
local dragStartPos    = Vector2.zero
local elementStartPos = UDim2.new()
local screenSize      = Workspace.CurrentCamera.ViewportSize
local snapThreshold   = 20

Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    screenSize = Workspace.CurrentCamera.ViewportSize
end)

local function setupDragListener(elementToDrag, elementToListenOn)
    elementToListenOn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isDragging      = true
            draggedElement  = elementToDrag
            dragStartPos    = input.Position
            elementStartPos = draggedElement.Position
            draggedElement.ZIndex = 99
        end
    end)
end

UserInputService.InputEnded:Connect(function(input)
    if not isDragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    isDragging = false
    if not draggedElement then return end

    local absPos  = draggedElement.AbsolutePosition
    local absSize = draggedElement.AbsoluteSize
    local newPos  = draggedElement.Position
    local width   = draggedElement == Frame and FRAME_WIDTH  or TOGGLE_SIZE
    local height  = draggedElement == Frame and FRAME_HEIGHT or TOGGLE_SIZE

    if absPos.X < snapThreshold then
        newPos = UDim2.new(0, 0, newPos.Y.Scale, newPos.Y.Offset)
    elseif absPos.X + absSize.X > screenSize.X - snapThreshold then
        newPos = UDim2.new(0, screenSize.X - width, newPos.Y.Scale, newPos.Y.Offset)
    end

    if absPos.Y < snapThreshold then
        newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, 0)
    elseif absPos.Y + absSize.Y > screenSize.Y - snapThreshold then
        newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, screenSize.Y - height)
    end

    draggedElement.Position = newPos
    draggedElement.ZIndex   = draggedElement == Frame and 1 or 2
    draggedElement          = nil
end)

UserInputService.InputChanged:Connect(function(input)
    if not isDragging or not draggedElement then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local delta = input.Position - dragStartPos
    draggedElement.Position = UDim2.new(
        0, elementStartPos.X.Offset + delta.X,
        0, elementStartPos.Y.Offset + delta.Y
    )
end)

setupDragListener(Frame, DragHandle)
setupDragListener(ToggleButton, ToggleButton)

----------------------------------------------------
-- 6. CORE ATTACK LOOP
----------------------------------------------------
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastAttackTime < AttackInterval then return end
    if not (isNPCToggled or isPlayerKillToggled) then return end
    lastAttackTime = now

    local combinedTargets = {}

    if isNPCToggled        then addValidTargetsFromCache(npcModelCache,   combinedTargets) end
    if isPlayerKillToggled then addValidTargetsFromCache(playerCharCache, combinedTargets) end

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
