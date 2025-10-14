--[[ 
    AXE TOGGLE LOCAL SCRIPT
    
    This script implements toggles for targeting NPCs and Players via a RemoteEvent, 
    featuring a clean, draggable GUI and a separate visibility toggle.
    
    UPDATE: Drag functionality fixed to correctly allow dragging the GUI toggle button and the main panel.
--]]

----------------------------------------------------
-- 1. SERVICE AND OBJECT REFERENCES
----------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService") 
local task = task -- Roblox's modern task scheduler library

-- Player and Remote Event references
local RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Axe")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------
-- 2. CORE CONFIGURATION AND TOGGLE STATE
----------------------------------------------------
local isNPCToggled = false
local isPlayerKillToggled = false

local DEFAULT_INTERVAL = 5
local currentInterval = DEFAULT_INTERVAL -- State variable for the active attack cooldown
local lastAttackTime = 0

-- Styling Constants for efficiency
local BACKGROUND_COLOR = Color3.fromRGB(34, 40, 49) 
local OFF_COLOR = Color3.fromRGB(57, 62, 70) 
local NPC_ON_COLOR = Color3.fromRGB(0, 173, 181) 
local PLAYER_ON_COLOR = Color3.fromRGB(255, 87, 87) -- Distinct color for player targeting
local TEXT_COLOR = Color3.fromRGB(238, 238, 238)
local SET_BUTTON_COLOR = Color3.fromRGB(47, 204, 113) -- Green color for confirmation

----------------------------------------------------
-- 3. TARGETING FUNCTIONS
----------------------------------------------------

-- Function to find non-player targets
local function getNonPlayerCharacterModels()
    local nonPlayerModels = {}
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local model = descendant.Parent
            
            -- Check if model is valid, not the local player's character, and not a player
            if model and model ~= Character and model:FindFirstChild("Humanoid") then
                local player = Players:GetPlayerFromCharacter(model)
                if not player then
                    table.insert(nonPlayerModels, model)
                end
            end
        end
    end
    return nonPlayerModels
end

-- Function to find other player targets (excluding LocalPlayer)
local function getPlayerCharacterModels()
    local playerModels = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then -- CRITICAL: Do not target self
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                table.insert(playerModels, char)
            end
        end
    end
    return playerModels
end

----------------------------------------------------
-- 4. GUI CREATION (CLEAN, DRAGGABLE STRUCTURE)
----------------------------------------------------

-- ADJUSTED DIMENSIONS for vertical layout
local FRAME_WIDTH = 220  -- Increased width to accommodate input + button
local FRAME_HEIGHT = 155 
local TOGGLE_SIZE = 40
local CORNER_RADIUS = UDim.new(0, 8) 
local BUTTON_SIZE = UDim2.fromOffset(FRAME_WIDTH - 20, 40) -- Main buttons fit the frame width
local INPUT_WIDTH = (FRAME_WIDTH - 30) * 0.7 -- ~70% of available width
local SET_BUTTON_WIDTH = (FRAME_WIDTH - 30) * 0.3 -- ~30% of available width

-- ScreenGui Container
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "AxeToggleGui"
ScreenGui.ResetOnSpawn = false

-- 4.1. GUI Toggle Button (Small, Fixed, Top-Left Corner)
local GUIToggleButton = Instance.new("TextButton", ScreenGui)
GUIToggleButton.Name = "GUIToggleButton"
GUIToggleButton.Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE)
GUIToggleButton.Position = UDim2.fromOffset(10, 10) 
GUIToggleButton.BackgroundColor3 = BACKGROUND_COLOR
GUIToggleButton.TextColor3 = NPC_ON_COLOR 
GUIToggleButton.Text = "☰" 
GUIToggleButton.Font = Enum.Font.SourceSansBold
GUIToggleButton.TextSize = 24
Instance.new("UICorner", GUIToggleButton).CornerRadius = CORNER_RADIUS

-- 4.2. Draggable Control Frame (Main Panel, Centered)
local ControlFrame = Instance.new("Frame", ScreenGui)
ControlFrame.Name = "AxeControls"
ControlFrame.Size = UDim2.fromOffset(FRAME_WIDTH, FRAME_HEIGHT) 
ControlFrame.Position = UDim2.new(0.5, -FRAME_WIDTH/2, 0.5, -FRAME_HEIGHT/2) 
ControlFrame.BackgroundColor3 = BACKGROUND_COLOR
ControlFrame.BorderSizePixel = 0
ControlFrame.Visible = true 

-- Styling children of ControlFrame
Instance.new("UICorner", ControlFrame).CornerRadius = CORNER_RADIUS
local ListLayout = Instance.new("UIListLayout", ControlFrame)
ListLayout.FillDirection = Enum.FillDirection.Vertical -- Vertical layout for stack
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ListLayout.Padding = UDim.new(0, 5) 
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 4.3. NPC Toggle Button
local NPCToggleButton = Instance.new("TextButton", ControlFrame)
NPCToggleButton.Name = "NPCToggleButton"
NPCToggleButton.Size = BUTTON_SIZE
NPCToggleButton.BackgroundColor3 = OFF_COLOR
NPCToggleButton.TextColor3 = TEXT_COLOR
NPCToggleButton.Text = "NPC Attack (OFF)"
NPCToggleButton.Font = Enum.Font.SourceSansBold
NPCToggleButton.TextSize = 16
NPCToggleButton.LayoutOrder = 1
Instance.new("UICorner", NPCToggleButton).CornerRadius = CORNER_RADIUS

-- 4.4. Player Kill Button
local PlayerKillButton = Instance.new("TextButton", ControlFrame)
PlayerKillButton.Name = "PlayerKillButton"
PlayerKillButton.Size = BUTTON_SIZE
PlayerKillButton.BackgroundColor3 = OFF_COLOR
PlayerKillButton.TextColor3 = TEXT_COLOR
PlayerKillButton.Text = "Player Kill (OFF)"
PlayerKillButton.Font = Enum.Font.SourceSansBold
PlayerKillButton.TextSize = 16
PlayerKillButton.LayoutOrder = 2
Instance.new("UICorner", PlayerKillButton).CornerRadius = CORNER_RADIUS

-- 4.5. Interval Input Group (NEW ELEMENTS)
local InputGroup = Instance.new("Frame", ControlFrame)
InputGroup.Name = "InputGroup"
InputGroup.Size = UDim2.fromOffset(FRAME_WIDTH - 20, 50)
InputGroup.BackgroundColor3 = BACKGROUND_COLOR
InputGroup.BorderSizePixel = 0
InputGroup.LayoutOrder = 3

local InputListLayout = Instance.new("UIListLayout", InputGroup)
InputListLayout.FillDirection = Enum.FillDirection.Vertical
InputListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
InputListLayout.Padding = UDim.new(0, 2) 

local IntervalLabel = Instance.new("TextLabel", InputGroup)
IntervalLabel.Size = UDim2.fromOffset(FRAME_WIDTH - 20, 15)
IntervalLabel.BackgroundColor3 = BACKGROUND_COLOR
IntervalLabel.TextColor3 = TEXT_COLOR
IntervalLabel.Text = "Attack Interval (seconds):"
IntervalLabel.Font = Enum.Font.SourceSans
IntervalLabel.TextSize = 14

-- Horizontal container for Textbox and Button
local InputRow = Instance.new("Frame", InputGroup)
InputRow.Name = "InputRow"
InputRow.Size = UDim2.fromOffset(FRAME_WIDTH - 20, 30)
InputRow.BackgroundColor3 = BACKGROUND_COLOR
InputRow.BorderSizePixel = 0

local RowListLayout = Instance.new("UIListLayout", InputRow)
RowListLayout.FillDirection = Enum.FillDirection.Horizontal
RowListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
RowListLayout.Padding = UDim.new(0, 5)

local IntervalTextBox = Instance.new("TextBox", InputRow)
IntervalTextBox.Name = "IntervalTextBox"
IntervalTextBox.Size = UDim2.fromOffset(INPUT_WIDTH - 5, 30) -- Adjusted size
IntervalTextBox.BackgroundColor3 = OFF_COLOR
IntervalTextBox.TextColor3 = TEXT_COLOR
IntervalTextBox.Text = tostring(currentInterval) -- Display current value
IntervalTextBox.PlaceholderText = "seconds"
IntervalTextBox.Font = Enum.Font.SourceSans
IntervalTextBox.TextSize = 16
IntervalTextBox.ClearTextOnFocus = false
IntervalTextBox.TextEditable = true
Instance.new("UICorner", IntervalTextBox).CornerRadius = UDim.new(0, 4)

-- NEW: Set Button
local SetButton = Instance.new("TextButton", InputRow)
SetButton.Name = "SetButton"
SetButton.Size = UDim2.fromOffset(SET_BUTTON_WIDTH, 30) -- Adjusted size
SetButton.BackgroundColor3 = SET_BUTTON_COLOR
SetButton.TextColor3 = TEXT_COLOR
SetButton.Text = "Set"
SetButton.Font = Enum.Font.SourceSansBold
SetButton.TextSize = 16
Instance.new("UICorner", SetButton).CornerRadius = UDim.new(0, 4)


----------------------------------------------------
-- 5. TOGGLE STATE UPDATE FUNCTIONS
----------------------------------------------------

local function updateButtonState(button, isToggled, onText, offText, onColor)
    button.Text = isToggled and onText or offText
    button.BackgroundColor3 = isToggled and onColor or OFF_COLOR
end

local function toggleNPCTargetState()
    isNPCToggled = not isNPCToggled
    updateButtonState(NPCToggleButton, isNPCToggled, "NPC Attack (ON)", "NPC Attack (OFF)", NPC_ON_COLOR)
end

local function togglePlayerKillState()
    isPlayerKillToggled = not isPlayerKillToggled
    updateButtonState(PlayerKillButton, isPlayerKillToggled, "Player Kill (ON)", "Player Kill (OFF)", PLAYER_ON_COLOR)
end

local function toggleUIVisibility()
    ControlFrame.Visible = not ControlFrame.Visible
    
    if ControlFrame.Visible then
        GUIToggleButton.Text = "☰"
        GUIToggleButton.TextColor3 = NPC_ON_COLOR
    else
        GUIToggleButton.Text = "▶"
        GUIToggleButton.TextColor3 = TEXT_COLOR
    end
end

-- Function to process and apply the interval input
local function applyIntervalInput()
    local newText = IntervalTextBox.Text
    local newInterval = tonumber(newText)

    -- Validate input: must be a number greater than a very small delay (0.01s minimum)
    if newInterval and newInterval >= 0.01 then
        currentInterval = newInterval
        IntervalTextBox.BackgroundColor3 = SET_BUTTON_COLOR -- Success color
        task.delay(0.5, function() IntervalTextBox.BackgroundColor3 = OFF_COLOR end)
    else
        -- Input invalid or too small, revert text and show error color
        IntervalTextBox.Text = tostring(currentInterval) -- Revert to last valid number
        IntervalTextBox.BackgroundColor3 = PLAYER_ON_COLOR -- Error color (Red)
        task.delay(0.5, function() IntervalTextBox.BackgroundColor3 = OFF_COLOR end)
        print("Invalid attack interval. Must be a number (>= 0.01s).")
    end
end

----------------------------------------------------
-- 6. DRAG AND CLICK EVENT HANDLERS (FIXED DRAG LOGIC)
----------------------------------------------------

-- Efficient Drag Function for the ControlFrame
local function setupFrameDrag(frame)
    local dragging = false
    local dragInput = nil
    local dragStartPos = nil

    -- InputBegan: Start drag
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            
            -- Check if the target is an interactive child (TextBox/Button)
            local isTargetInteractiveChild = input.Target:IsA("TextBox") or input.Target:IsA("TextButton")
            -- Check if the target is the frame/button itself being dragged
            local isTargetFrame = input.Target == frame
            
            -- Allow drag if the target is NOT an interactive child OR if the target IS the frame itself (necessary for GUIToggleButton)
            if not isTargetInteractiveChild or isTargetFrame then
                dragging = true
                dragStartPos = input.Position
                dragInput = input
                frame.ZIndex = 2 -- Bring frame to front
            end
        end
    end)
    
    -- InputChanged: Move the frame
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStartPos
            
            frame.Position = UDim2.new(0, frame.AbsolutePosition.X + delta.X, 
                                       0, frame.AbsolutePosition.Y + delta.Y)
            
            dragStartPos = input.Position
        end
    end)

    -- InputEnded: Stop drag
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            dragInput = nil
            frame.ZIndex = 1
        end
    end)
end

-- Setup click handlers 
NPCToggleButton.Activated:Connect(toggleNPCTargetState)
PlayerKillButton.Activated:Connect(togglePlayerKillState)
GUIToggleButton.Activated:Connect(toggleUIVisibility)

-- Connect the input validation handlers
IntervalTextBox.FocusLost:Connect(function(enterPressed) 
    if enterPressed then applyIntervalInput() end
end)
SetButton.Activated:Connect(applyIntervalInput)

-- Apply the drag logic to the ControlFrame
setupFrameDrag(ControlFrame)
-- Apply the drag logic to the GUIToggleButton
setupFrameDrag(GUIToggleButton)

----------------------------------------------------
-- 7. CORE ATTACK LOOP (SINGLE FIRE)
----------------------------------------------------

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    
    -- Check: If EITHER toggle is ON AND the attack interval (currentInterval) is met
    if (isNPCToggled or isPlayerKillToggled) and (now - lastAttackTime >= currentInterval) then
        lastAttackTime = now -- Reset timer immediately

        local combinedTargets = {}

        -- Gather targets only if their respective toggle is active
        if isNPCToggled then
            for _, targetModel in ipairs(getNonPlayerCharacterModels()) do
                table.insert(combinedTargets, targetModel)
            end
        end

        if isPlayerKillToggled then
            for _, targetModel in ipairs(getPlayerCharacterModels()) do
                table.insert(combinedTargets, targetModel)
            end
        end

        -- Use the original single-fire method
        if #combinedTargets > 0 then
            
            -- Debug printing (retained from original script)
            local targetNames = {}
            for _, targetModel in ipairs(combinedTargets) do
                table.insert(targetNames, '"' .. targetModel.Name .. '"')
            end
            local formattedList = "{ " .. table.concat(targetNames, ", ") .. " }"
            print("Combined Targets (hb contents): " .. formattedList)
            
            -- Create the single argument table
            local args = {
                {
                    hb = combinedTargets, -- The entire table of targets
                    action = "hit",
                    combo = 1,
                    c = Character,
                    -- Damage value maintained from previous step
                    damage = 99999999999999
                }
            }

            -- Fire the single remote event
            RemoteEvent:FireServer(unpack(args))
        end
    end
end)
