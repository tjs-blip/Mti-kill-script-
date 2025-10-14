--[[ 
    AXE TOGGLE LOCAL SCRIPT (OPTIMIZED)
    
    This script implements toggles for targeting NPCs and Players via a RemoteEvent.
    Lag is reduced by decoupling the expensive target finding operation from the frame rate.
--]]

----------------------------------------------------
-- 1. SERVICE AND OBJECT REFERENCES
----------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService") 

-- Player and Remote Event references
local RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Axe")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------
-- 2. CORE CONFIGURATION AND TOGGLE STATE
----------------------------------------------------
local isNPCToggled = false        -- State for non-player targets (NPCs/Mobs)
local isPlayerKillToggled = false -- State for player targets
local ATTACK_INTERVAL = 5         -- Attack cooldown in seconds
local TARGET_UPDATE_INTERVAL = 1.0  -- NEW: Search for targets once every 1 second (Less laggy)

-- Stores targets found by the background task
local nearbyTargets = {} 

-- Styling Constants for efficiency
local BACKGROUND_COLOR = Color3.fromRGB(34, 40, 49) 
local OFF_COLOR = Color3.fromRGB(57, 62, 70) 
local NPC_ON_COLOR = Color3.fromRGB(0, 173, 181) 
local PLAYER_ON_COLOR = Color3.fromRGB(255, 87, 87) 
local TEXT_COLOR = Color3.fromRGB(238, 238, 238)

----------------------------------------------------
-- 3. TARGETING FUNCTIONS (Unchanged, but called less frequently)
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

local FRAME_WIDTH = 320 
local FRAME_HEIGHT = 50
local TOGGLE_SIZE = 40
local CORNER_RADIUS = UDim.new(0, 8) 
local BUTTON_SIZE = UDim2.fromOffset(150, 40)

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
ListLayout.FillDirection = Enum.FillDirection.Horizontal
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Padding = UDim.new(0, 10) 

-- 4.3. NPC Toggle Button
local NPCToggleButton = Instance.new("TextButton", ControlFrame)
NPCToggleButton.Name = "NPCToggleButton"
NPCToggleButton.Size = BUTTON_SIZE
NPCToggleButton.BackgroundColor3 = OFF_COLOR
NPCToggleButton.TextColor3 = TEXT_COLOR
NPCToggleButton.Text = "NPC Attack (OFF)"
NPCToggleButton.Font = Enum.Font.SourceSansBold
NPCToggleButton.TextSize = 16
Instance.new("UICorner", NPCToggleButton).CornerRadius = CORNER_RADIUS

-- 4.4. Player Kill Button (New Button)
local PlayerKillButton = Instance.new("TextButton", ControlFrame)
PlayerKillButton.Name = "PlayerKillButton"
PlayerKillButton.Size = BUTTON_SIZE
PlayerKillButton.BackgroundColor3 = OFF_COLOR
PlayerKillButton.TextColor3 = TEXT_COLOR
PlayerKillButton.Text = "Player Kill (OFF)"
PlayerKillButton.Font = Enum.Font.SourceSansBold
PlayerKillButton.TextSize = 16
Instance.new("UICorner", PlayerKillButton).CornerRadius = CORNER_RADIUS


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

----------------------------------------------------
-- 6. DRAG AND CLICK EVENT HANDLERS
----------------------------------------------------

-- Efficient Drag Function for the ControlFrame (Unchanged)
local function setupFrameDrag(frame)
    local dragging = false
    local dragInput = nil
    local dragStartPos = nil

    -- InputBegan: Start drag
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            dragInput = input
            frame.ZIndex = 2 
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

-- Apply the drag logic to the ControlFrame
setupFrameDrag(ControlFrame)

----------------------------------------------------
-- 7. OPTIMIZED BACKGROUND LOOPS
----------------------------------------------------

-- 7.1. TARGET DISCOVERY LOOP (Runs slowly to reduce lag)
task.spawn(function()
    while task.wait(TARGET_UPDATE_INTERVAL) do 
        
        -- Reset the list
        nearbyTargets = {}
        
        -- Check if either toggle is active before spending CPU time
        if isNPCToggled or isPlayerKillToggled then
            
            -- Find NPCs 
            if isNPCToggled then
                for _, model in ipairs(getNonPlayerCharacterModels()) do 
                    table.insert(nearbyTargets, model)
                end
            end
            
            -- Find Players 
            if isPlayerKillToggled then
                for _, model in ipairs(getPlayerCharacterModels()) do
                    table.insert(nearbyTargets, model)
                end
            end
        end
    end
end)


-- 7.2. CORE ATTACK LOOP (Runs only on the cooldown interval)
task.spawn(function()
    while true do
        
        -- Only attempt to attack when the interval is met
        task.wait(ATTACK_INTERVAL) 
        
        -- Check toggles and if the character is valid
        if (not isNPCToggled and not isPlayerKillToggled) or not Character or Character.Parent == nil then 
            continue 
        end

        -- Use the pre-calculated targets
        if #nearbyTargets > 0 then
            
            -- Debug printing (optional, remove this block if absolute minimum lag is required)
            local targetNames = {}
            for _, targetModel in ipairs(nearbyTargets) do
                table.insert(targetNames, '"' .. targetModel.Name .. '"')
            end
            local formattedList = "{ " .. table.concat(targetNames, ", ") .. " }"
            print("Combined Targets (hb contents): " .. formattedList)
            
            -- Fire the single remote event
            local args = {
                {
                    hb = nearbyTargets, -- The entire pre-calculated table of targets
                    action = "hit",
                    combo = 1,
                    c = Character,
                    damage = 99999999999999
                }
            }

            RemoteEvent:FireServer(unpack(args))
        end
    end
end)
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

local FRAME_WIDTH = 320 -- Increased width for two buttons
local FRAME_HEIGHT = 50
local TOGGLE_SIZE = 40
local CORNER_RADIUS = UDim.new(0, 8) 
local BUTTON_SIZE = UDim2.fromOffset(150, 40)

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
ControlFrame.Visible = true -- Explicitly set visible on spawn

-- Styling children of ControlFrame
Instance.new("UICorner", ControlFrame).CornerRadius = CORNER_RADIUS
local ListLayout = Instance.new("UIListLayout", ControlFrame)
ListLayout.FillDirection = Enum.FillDirection.Horizontal
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Padding = UDim.new(0, 10) 

-- 4.3. NPC Toggle Button
local NPCToggleButton = Instance.new("TextButton", ControlFrame)
NPCToggleButton.Name = "NPCToggleButton"
NPCToggleButton.Size = BUTTON_SIZE
NPCToggleButton.BackgroundColor3 = OFF_COLOR
NPCToggleButton.TextColor3 = TEXT_COLOR
NPCToggleButton.Text = "NPC Attack (OFF)"
NPCToggleButton.Font = Enum.Font.SourceSansBold
NPCToggleButton.TextSize = 16
Instance.new("UICorner", NPCToggleButton).CornerRadius = CORNER_RADIUS

-- 4.4. Player Kill Button (New Button)
local PlayerKillButton = Instance.new("TextButton", ControlFrame)
PlayerKillButton.Name = "PlayerKillButton"
PlayerKillButton.Size = BUTTON_SIZE
PlayerKillButton.BackgroundColor3 = OFF_COLOR
PlayerKillButton.TextColor3 = TEXT_COLOR
PlayerKillButton.Text = "Player Kill (OFF)"
PlayerKillButton.Font = Enum.Font.SourceSansBold
PlayerKillButton.TextSize = 16
Instance.new("UICorner", PlayerKillButton).CornerRadius = CORNER_RADIUS


----------------------------------------------------
-- 5. TOGGLE STATE UPDATE FUNCTIONS
----------------------------------------------------

-- Function to handle button state updates efficiently
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

----------------------------------------------------
-- 6. DRAG AND CLICK EVENT HANDLERS
----------------------------------------------------

-- Efficient Drag Function for the ControlFrame
local function setupFrameDrag(frame)
    local dragging = false
    local dragInput = nil
    local dragStartPos = nil

    -- InputBegan: Start drag
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            dragInput = input
            frame.ZIndex = 2 -- Bring frame to front
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
NPCToggleButton.Activated:Connect(toggleNPCTargetState) -- NPC toggle
PlayerKillButton.Activated:Connect(togglePlayerKillState) -- NEW: Player toggle
GUIToggleButton.Activated:Connect(toggleUIVisibility)

-- Apply the drag logic to the ControlFrame
setupFrameDrag(ControlFrame)

----------------------------------------------------
-- 7. CORE ATTACK LOOP (SINGLE FIRE)
----------------------------------------------------

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    
    -- Check: If EITHER toggle is ON AND the interval is met
    if (isNPCToggled or isPlayerKillToggled) and (now - lastAttackTime >= ATTACK_INTERVAL) then
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
