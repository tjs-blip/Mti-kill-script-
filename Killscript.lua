--[[ 
    AXE TOGGLE LOCAL SCRIPT
    
    This script implements toggles for targeting NPCs and Players via a RemoteEvent, 
    featuring a clean, draggable GUI and a separate visibility toggle.

    DRAG FUNCTION: No inertia, instant response, snaps to screen edges.
--]]

----------------------------------------------------
-- 1. SERVICE AND OBJECT REFERENCES
----------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService") 
local task = task

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
local currentInterval = DEFAULT_INTERVAL 
local lastAttackTime = 0

-- Styling Constants 
local BACKGROUND_COLOR = Color3.fromRGB(34, 40, 49) 
local OFF_COLOR = Color3.fromRGB(57, 62, 70) 
local NPC_ON_COLOR = Color3.fromRGB(0, 173, 181) 
local PLAYER_ON_COLOR = Color3.fromRGB(255, 87, 87)
local TEXT_COLOR = Color3.fromRGB(238, 238, 238)
local SET_BUTTON_COLOR = Color3.fromRGB(47, 204, 113)

-- ADJUSTED DIMENSIONS (BIGGER)
local FRAME_WIDTH = 280
local FRAME_HEIGHT = 240
local TOGGLE_SIZE = 50
local HANDLE_HEIGHT = 30
local CORNER_RADIUS = UDim.new(0, 8) 
local MAIN_PADDING = UDim.new(0, 10) 

local BUTTON_WIDTH = FRAME_WIDTH - 20 
local BUTTON_SIZE = UDim2.fromOffset(BUTTON_WIDTH, 45) 

local INPUT_ROW_WIDTH = BUTTON_WIDTH
local INPUT_HEIGHT = 35
local INPUT_WIDTH = (INPUT_ROW_WIDTH - 15) * 0.7 
local SET_BUTTON_WIDTH = (INPUT_ROW_WIDTH - 15) * 0.3

----------------------------------------------------
-- 3. TARGETING FUNCTIONS
----------------------------------------------------
local function getNonPlayerCharacterModels()
    local nonPlayerModels = {}
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local model = descendant.Parent
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

local function getPlayerCharacterModels()
    local playerModels = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                table.insert(playerModels, char)
            end
        end
    end
    return playerModels
end

----------------------------------------------------
-- 4. GUI CREATION 
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "AxeToggleGui"
ScreenGui.ResetOnSpawn = false

-- Toggle Button
local GUIToggleButton = Instance.new("TextButton", ScreenGui)
GUIToggleButton.Name = "GUIToggleButton"
GUIToggleButton.Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE)
GUIToggleButton.Position = UDim2.fromOffset(10, 10) 
GUIToggleButton.BackgroundColor3 = BACKGROUND_COLOR
GUIToggleButton.TextColor3 = NPC_ON_COLOR 
GUIToggleButton.Text = "☰" 
GUIToggleButton.Font = Enum.Font.SourceSansBold
GUIToggleButton.TextSize = 28
Instance.new("UICorner", GUIToggleButton).CornerRadius = CORNER_RADIUS
GUIToggleButton.AutoButtonColor = false 
GUIToggleButton.ZIndex = 2 

-- Control Frame
local ControlFrame = Instance.new("Frame", ScreenGui)
ControlFrame.Name = "AxeControls"
ControlFrame.Size = UDim2.fromOffset(FRAME_WIDTH, FRAME_HEIGHT) 
ControlFrame.Position = UDim2.new(0.5, -FRAME_WIDTH/2, 0.5, -FRAME_HEIGHT/2) 
ControlFrame.BackgroundColor3 = BACKGROUND_COLOR
ControlFrame.BorderSizePixel = 0
ControlFrame.Visible = true 
ControlFrame.Active = true
ControlFrame.ZIndex = 1

-- Corner + Padding
Instance.new("UICorner", ControlFrame).CornerRadius = CORNER_RADIUS
Instance.new("UIPadding", ControlFrame).PaddingTop = MAIN_PADDING
Instance.new("UIPadding", ControlFrame).PaddingBottom = MAIN_PADDING
Instance.new("UIPadding", ControlFrame).PaddingLeft = MAIN_PADDING
Instance.new("UIPadding", ControlFrame).PaddingRight = MAIN_PADDING

local ListLayout = Instance.new("UIListLayout", ControlFrame)
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Drag Handle
local DragHandle = Instance.new("TextLabel", ControlFrame)
DragHandle.Name = "DragHandle"
DragHandle.Size = UDim2.fromOffset(FRAME_WIDTH, HANDLE_HEIGHT)
DragHandle.Position = UDim2.new(0, 0, 0, 0)
DragHandle.BackgroundColor3 = Color3.fromRGB(28,33,40)
DragHandle.TextColor3 = TEXT_COLOR
DragHandle.Text = "Axe Toggle Control Panel"
DragHandle.TextXAlignment = Enum.TextXAlignment.Center
DragHandle.Font = Enum.Font.SourceSansBold
DragHandle.TextSize = 18
DragHandle.ZIndex = 2
DragHandle.Active = true
Instance.new("UICorner", DragHandle).CornerRadius = CORNER_RADIUS

-- NPC Toggle Button
local NPCToggleButton = Instance.new("TextButton", ControlFrame)
NPCToggleButton.Name = "NPCToggleButton"
NPCToggleButton.Size = BUTTON_SIZE
NPCToggleButton.BackgroundColor3 = OFF_COLOR
NPCToggleButton.TextColor3 = TEXT_COLOR
NPCToggleButton.Text = "NPC Attack (OFF)"
NPCToggleButton.Font = Enum.Font.SourceSansBold
NPCToggleButton.TextSize = 18
NPCToggleButton.LayoutOrder = 1
NPCToggleButton.ZIndex = 2 
Instance.new("UICorner", NPCToggleButton).CornerRadius = CORNER_RADIUS

-- Player Kill Button
local PlayerKillButton = Instance.new("TextButton", ControlFrame)
PlayerKillButton.Name = "PlayerKillButton"
PlayerKillButton.Size = BUTTON_SIZE
PlayerKillButton.BackgroundColor3 = OFF_COLOR
PlayerKillButton.TextColor3 = TEXT_COLOR
PlayerKillButton.Text = "Player Kill (OFF)"
PlayerKillButton.Font = Enum.Font.SourceSansBold
PlayerKillButton.TextSize = 18
PlayerKillButton.LayoutOrder = 2
PlayerKillButton.ZIndex = 2
Instance.new("UICorner", PlayerKillButton).CornerRadius = CORNER_RADIUS

-- Interval Input
local InputGroup = Instance.new("Frame", ControlFrame)
InputGroup.Name = "InputGroup"
InputGroup.Size = UDim2.fromOffset(INPUT_ROW_WIDTH, 60)
InputGroup.BackgroundColor3 = BACKGROUND_COLOR
InputGroup.BorderSizePixel = 0
InputGroup.LayoutOrder = 3
InputGroup.ZIndex = 2

local InputListLayout = Instance.new("UIListLayout", InputGroup)
InputListLayout.FillDirection = Enum.FillDirection.Vertical
InputListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
InputListLayout.Padding = UDim.new(0, 4) 

local IntervalLabel = Instance.new("TextLabel", InputGroup)
IntervalLabel.Size = UDim2.fromOffset(INPUT_ROW_WIDTH, 18)
IntervalLabel.BackgroundColor3 = BACKGROUND_COLOR
IntervalLabel.TextColor3 = TEXT_COLOR
IntervalLabel.Text = "Attack Interval (seconds):"
IntervalLabel.TextXAlignment = Enum.TextXAlignment.Left
IntervalLabel.Font = Enum.Font.SourceSans
IntervalLabel.TextSize = 16
IntervalLabel.ZIndex = 2

local InputRow = Instance.new("Frame", InputGroup)
InputRow.Name = "InputRow"
InputRow.Size = UDim2.fromOffset(INPUT_ROW_WIDTH, INPUT_HEIGHT)
InputRow.BackgroundColor3 = BACKGROUND_COLOR
InputRow.BorderSizePixel = 0
InputRow.ZIndex = 2
InputRow.Active = true

local RowListLayout = Instance.new("UIListLayout", InputRow)
RowListLayout.FillDirection = Enum.FillDirection.Horizontal
RowListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
RowListLayout.Padding = UDim.new(0, 5)

local IntervalTextBox = Instance.new("TextBox", InputRow)
IntervalTextBox.Name = "IntervalTextBox"
IntervalTextBox.Size = UDim2.fromOffset(INPUT_WIDTH - 5, INPUT_HEIGHT) 
IntervalTextBox.BackgroundColor3 = OFF_COLOR
IntervalTextBox.TextColor3 = TEXT_COLOR
IntervalTextBox.Text = tostring(currentInterval)
IntervalTextBox.PlaceholderText = "seconds"
IntervalTextBox.Font = Enum.Font.SourceSans
IntervalTextBox.TextSize = 18
IntervalTextBox.ClearTextOnFocus = false
IntervalTextBox.TextEditable = true
IntervalTextBox.ZIndex = 2
Instance.new("UICorner", IntervalTextBox).CornerRadius = UDim.new(0, 4)

local SetButton = Instance.new("TextButton", InputRow)
SetButton.Name = "SetButton"
SetButton.Size = UDim2.fromOffset(SET_BUTTON_WIDTH, INPUT_HEIGHT)
SetButton.BackgroundColor3 = SET_BUTTON_COLOR
SetButton.TextColor3 = TEXT_COLOR
SetButton.Text = "Set"
SetButton.Font = Enum.Font.SourceSansBold
SetButton.TextSize = 18
SetButton.ZIndex = 2
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

local function applyIntervalInput()
    local newText = IntervalTextBox.Text
    local newInterval = tonumber(newText)

    if newInterval and newInterval >= 0.01 then
        currentInterval = newInterval
        IntervalTextBox.BackgroundColor3 = SET_BUTTON_COLOR 
        task.delay(0.5, function() IntervalTextBox.BackgroundColor3 = OFF_COLOR end)
    else
        IntervalTextBox.Text = tostring(currentInterval)
        IntervalTextBox.BackgroundColor3 = PLAYER_ON_COLOR
        task.delay(0.5, function() IntervalTextBox.BackgroundColor3 = OFF_COLOR end)
        print("Invalid attack interval. Must be a number (>= 0.01s).")
    end
end

----------------------------------------------------
-- 6. DRAG AND CLICK EVENT HANDLERS (NO INERTIA)
----------------------------------------------------
local isDragging = false
local draggedElement = nil
local dragStartPos = Vector2.zero
local elementStartPos = UDim2.new()
local screenSize = Workspace.CurrentCamera.ViewportSize
local snapThreshold = 20

Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	screenSize = Workspace.CurrentCamera.ViewportSize
end)

local function setupDragListener(elementToDrag, elementToListenOn)
	elementToListenOn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			draggedElement = elementToDrag
			dragStartPos = input.Position
			elementStartPos = draggedElement.Position
			draggedElement.ZIndex = 99
		end
	end)
end

UserInputService.InputEnded:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		isDragging = false
		if draggedElement then
			local absPos = draggedElement.AbsolutePosition
			local absSize = draggedElement.AbsoluteSize
			local newPos = draggedElement.Position

			if absPos.X < snapThreshold then
				newPos = UDim2.new(0, 0, newPos.Y.Scale, newPos.Y.Offset)
			elseif absPos.X + absSize.X > screenSize.X - snapThreshold then
				newPos = UDim2.new(0, screenSize.X - absSize.X, newPos.Y.Scale, newPos.Y.Offset)
			end

			if absPos.Y < snapThreshold then
				newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, 0)
			elseif absPos.Y + absSize.Y > screenSize.Y - snapThreshold then
				newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, screenSize.Y - absSize.Y)
			end

			draggedElement.Position = newPos
			draggedElement.ZIndex = (draggedElement == ControlFrame) and 1 or 2
			draggedElement = nil
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and draggedElement then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStartPos
			draggedElement.Position = UDim2.new(
				elementStartPos.X.Scale,
				elementStartPos.X.Offset + delta.X,
				elementStartPos.Y.Scale,
				elementStartPos.Y.Offset + delta.Y
			)
		end
	end
end)

setupDragListener(ControlFrame, DragHandle)
setupDragListener(GUIToggleButton, GUIToggleButton)

-- Connect buttons
NPCToggleButton.Activated:Connect(toggleNPCTargetState)
PlayerKillButton.Activated:Connect(togglePlayerKillState)
GUIToggleButton.Activated:Connect(toggleUIVisibility)
IntervalTextBox.FocusLost:Connect(function(enterPressed) if enterPressed then applyIntervalInput() end end)
SetButton.Activated:Connect(applyIntervalInput)

----------------------------------------------------
-- 7. CORE ATTACK LOOP (TARGET HUMANOIDS BASED ON TOGGLES)
----------------------------------------------------
RunService.Heartbeat:Connect(function()
    local now = os.clock()

    -- Only run if either toggle is ON and interval has passed
    if (isNPCToggled or isPlayerKillToggled) and (now - lastAttackTime >= currentInterval) then
        lastAttackTime = now
        local combinedTargets = {}

        -- Helper function to add valid humanoids
        local function addValidTargets(models)
            for _, model in ipairs(models) do
                local humanoid = model:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    table.insert(combinedTargets, model)
                end
            end
        end

        if isNPCToggled and isPlayerKillToggled then
            -- Both toggles ON: target all humanoids
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    local humanoid = obj.Humanoid
                    if humanoid.Health > 0 then
                        table.insert(combinedTargets, obj)
                    end
                end
            end
        else
            -- Only one toggle ON: target individually
            if isNPCToggled then
                addValidTargets(getNonPlayerCharacterModels())
            end
            if isPlayerKillToggled then
                addValidTargets(getPlayerCharacterModels())
            end
        end

        -- Fire RemoteEvent if there are any valid targets
        if #combinedTargets > 0 then
            local args = {
                {
                    hb = combinedTargets,
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
