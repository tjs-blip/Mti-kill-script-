--[[
    AXE TOGGLE LOCAL SCRIPT (FINAL MERGED VERSION)
    
    This script merges the clean, robust, dual-draggable GUI logic (from the second script)
    with the original structure, variable names, and TweenService usage (from the first script).
    
    *** MODIFICATION: Changed Parent from PlayerGui to CoreGui ***
]]

----------------------------------------------------
-- 1. SERVICES & VARIABLES
----------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui") -- ADDED CoreGui service
local task = task -- Added for the new GUI's visual feedback logic

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
-- Removed: local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") -- No longer needed

local RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Axe")

-- CORE CONFIGURATION AND TOGGLE STATE (From original script, adapted for new GUI defaults)
local isNPCToggled = false
local isPlayerKillToggled = false
local lastAttackTime = 0 -- Renamed from lastAttack for clarity
local DEFAULT_INTERVAL = 0.3
local AttackInterval = LocalPlayer:GetAttribute("SavedAttackInterval") or DEFAULT_INTERVAL 

-- STYLING CONSTANTS (From the second, preferred GUI script)
local PRIMARY_DARK = Color3.fromRGB(34, 40, 49) -- Used as BACKGROUND_COLOR
local SECONDARY_DARK = Color3.fromRGB(57, 62, 70) -- Used as OFF_COLOR
local ACCENT_GREEN = Color3.fromRGB(0, 173, 181) -- Used as NPC_ON_COLOR
local ACCENT_RED = Color3.fromRGB(255, 87, 87) -- Used as PLAYER_ON_COLOR
local TEXT_COLOR = Color3.fromRGB(238, 238, 238)
local SET_BUTTON_COLOR = Color3.fromRGB(47, 204, 113)

-- ADJUSTED DIMENSIONS (From the second, preferred GUI script)
local FRAME_WIDTH = 280
local FRAME_HEIGHT = 240
local TOGGLE_SIZE = 40
local HANDLE_HEIGHT = 30
local CORNER_RADIUS = UDim.new(0, 8)
local MAIN_PADDING = UDim.new(0, 10)

local BUTTON_WIDTH = FRAME_WIDTH - 20
local INPUT_ROW_WIDTH = BUTTON_WIDTH
local INPUT_HEIGHT = 30
local INPUT_WIDTH = (INPUT_ROW_WIDTH - 15) * 0.7
local SET_BUTTON_WIDTH = (INPUT_ROW_WIDTH - 15) * 0.3

----------------------------------------------------
-- 2. GUI CREATION (Using the robust structure)
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", CoreGui) -- CHANGED PARENT TO CoreGui
ScreenGui.Name = "AxeToggleUI"
ScreenGui.ResetOnSpawn = false

-- Toggle Button (Draggable target 2)
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Name = "GUIToggleButton"
ToggleButton.Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE)
ToggleButton.Position = UDim2.fromOffset(10, 10) 
ToggleButton.BackgroundColor3 = PRIMARY_DARK
ToggleButton.TextColor3 = TEXT_COLOR
ToggleButton.Text = "▶" -- Start closed 
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 24
Instance.new("UICorner", ToggleButton).CornerRadius = CORNER_RADIUS
ToggleButton.AutoButtonColor = false 
ToggleButton.ZIndex = 2
ToggleButton.Active = true

-- Main Frame (Drag target 1)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Name = "AxeControls"
Frame.Size = UDim2.fromOffset(FRAME_WIDTH, FRAME_HEIGHT) 
Frame.Position = UDim2.new(0.5, -FRAME_WIDTH/2, 0.5, -FRAME_HEIGHT/2) 
Frame.BackgroundColor3 = PRIMARY_DARK
Frame.BorderSizePixel = 0
Frame.Visible = false -- Start hidden
Frame.Active = true 
Frame.ZIndex = 1

-- Corner + Padding
Instance.new("UICorner", Frame).CornerRadius = CORNER_RADIUS
local Padding = Instance.new("UIPadding", Frame)
Padding.PaddingTop = MAIN_PADDING; Padding.PaddingBottom = MAIN_PADDING
Padding.PaddingLeft = MAIN_PADDING; Padding.PaddingRight = MAIN_PADDING

local ListLayout = Instance.new("UIListLayout", Frame)
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ListLayout.Padding = UDim.new(0, 8)

-- Drag Handle
local DragHandle = Instance.new("TextLabel", Frame)
DragHandle.Name = "DragHandle"
DragHandle.Size = UDim2.fromOffset(FRAME_WIDTH - 20, HANDLE_HEIGHT) 
DragHandle.BackgroundColor3 = SECONDARY_DARK
DragHandle.TextColor3 = TEXT_COLOR
DragHandle.Text = "AXE TOGGLE PANEL"
DragHandle.TextXAlignment = Enum.TextXAlignment.Center
DragHandle.Font = Enum.Font.SourceSansBold
DragHandle.TextSize = 16
DragHandle.ZIndex = 2
DragHandle.Active = true
DragHandle.LayoutOrder = 0 
Instance.new("UICorner", DragHandle).CornerRadius = CORNER_RADIUS

-- NPC Toggle Button
local NPCToggle = Instance.new("TextButton", Frame) -- Name kept for original logic
NPCToggle.Name = "NPCToggleButton"
NPCToggle.Size = UDim2.fromOffset(BUTTON_WIDTH, 40)
NPCToggle.BackgroundColor3 = SECONDARY_DARK
NPCToggle.TextColor3 = TEXT_COLOR
NPCToggle.Text = "Toggle NPC Kill: OFF"
NPCToggle.Font = Enum.Font.SourceSansBold
NPCToggle.TextSize = 16
NPCToggle.LayoutOrder = 1
Instance.new("UICorner", NPCToggle).CornerRadius = CORNER_RADIUS

-- Player Kill Button
local PlayerToggle = Instance.new("TextButton", Frame) -- Name kept for original logic
PlayerToggle.Name = "PlayerKillButton"
PlayerToggle.Size = UDim2.fromOffset(BUTTON_WIDTH, 40)
PlayerToggle.BackgroundColor3 = SECONDARY_DARK
PlayerToggle.TextColor3 = TEXT_COLOR
PlayerToggle.Text = "Toggle Player Kill: OFF"
PlayerToggle.Font = Enum.Font.SourceSansBold
PlayerToggle.TextSize = 16
PlayerToggle.LayoutOrder = 2
Instance.new("UICorner", PlayerToggle).CornerRadius = CORNER_RADIUS

-- Interval Input Group
local IntervalGroup = Instance.new("Frame", Frame) -- Name kept for original logic
IntervalGroup.Name = "InputGroup"
IntervalGroup.Size = UDim2.fromOffset(INPUT_ROW_WIDTH, 55)
IntervalGroup.BackgroundColor3 = PRIMARY_DARK
IntervalGroup.LayoutOrder = 3

local InputListLayout = Instance.new("UIListLayout", IntervalGroup)
InputListLayout.FillDirection = Enum.FillDirection.Vertical
InputListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
InputListLayout.Padding = UDim.new(0, 4) 

local IntervalLabel = Instance.new("TextLabel", IntervalGroup)
IntervalLabel.Size = UDim2.fromOffset(INPUT_ROW_WIDTH, 14)
IntervalLabel.BackgroundColor3 = PRIMARY_DARK
IntervalLabel.TextColor3 = TEXT_COLOR
IntervalLabel.Text = "Attack Interval (seconds):"
IntervalLabel.TextXAlignment = Enum.TextXAlignment.Left
IntervalLabel.Font = Enum.Font.SourceSans
IntervalLabel.TextSize = 14

local InputRow = Instance.new("Frame", IntervalGroup)
InputRow.Name = "InputRow"
InputRow.Size = UDim2.fromOffset(INPUT_ROW_WIDTH, INPUT_HEIGHT)
InputRow.BackgroundColor3 = PRIMARY_DARK
InputRow.Active = true

local RowListLayout = Instance.new("UIListLayout", InputRow)
RowListLayout.FillDirection = Enum.FillDirection.Horizontal
RowListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
RowListLayout.Padding = UDim.new(0, 5)

local IntervalBox = Instance.new("TextBox", InputRow) -- Name kept for original logic
IntervalBox.Name = "IntervalTextBox"
IntervalBox.Size = UDim2.fromOffset(INPUT_WIDTH - 5, INPUT_HEIGHT) 
IntervalBox.BackgroundColor3 = SECONDARY_DARK
IntervalBox.TextColor3 = TEXT_COLOR
IntervalBox.Text = tostring(math.floor(AttackInterval * 100) / 100)
IntervalBox.Font = Enum.Font.SourceSans
IntervalBox.TextSize = 16
IntervalBox.ClearTextOnFocus = false
Instance.new("UICorner", IntervalBox).CornerRadius = UDim.new(0, 4)

local SetButton = Instance.new("TextButton", InputRow)
SetButton.Name = "SetButton"
SetButton.Size = UDim2.fromOffset(SET_BUTTON_WIDTH, INPUT_HEIGHT)
SetButton.BackgroundColor3 = SET_BUTTON_COLOR
SetButton.TextColor3 = TEXT_COLOR
SetButton.Text = "Set"
SetButton.Font = Enum.Font.SourceSansBold
SetButton.TextSize = 16
Instance.new("UICorner", SetButton).CornerRadius = UDim.new(0, 4)


----------------------------------------------------
-- 3. TARGETING FUNCTIONS (ROBUST GetDescendants)
----------------------------------------------------
-- Helper function to find a Humanoid using FindFirstChildOfClass
local function findHumanoidInModel(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChildOfClass("Humanoid", true) 
end

-- Retrieves all models that contain a Humanoid but are not player characters.
local function getNonPlayerCharacterModels()
    local nonPlayerModels = {}
    local processedModels = {} 

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local model = descendant.Parent

            if model and model:IsA("Model") and model ~= Character and not processedModels[model] then
                local player = Players:GetPlayerFromCharacter(model)

                if not player then
                    table.insert(nonPlayerModels, model)
                    processedModels[model] = true 
                end
            end
        end
    end
    return nonPlayerModels
end

-- Retrieves all player character models excluding the LocalPlayer's.
local function getPlayerCharacterModels()
    local playerModels = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and findHumanoidInModel(char) and findHumanoidInModel(char).Health > 0 then 
                table.insert(playerModels, char)
            end
        end
    end
    return playerModels
end


----------------------------------------------------
-- 4. BUTTON INTERACTIONS (Merged logic and event handling)
----------------------------------------------------
local function updateToggle(button, isToggled, onColor, offColor)
    button.Text = "Toggle NPC Kill: " .. (isToggled and "ON" or "OFF") -- For NPCToggle
    if button == PlayerToggle then
        button.Text = "Toggle Player Kill: " .. (isToggled and "ON" or "OFF")
    end
    button.BackgroundColor3 = isToggled and onColor or offColor
end

-- NPC Toggle
NPCToggle.Activated:Connect(function()
	isNPCToggled = not isNPCToggled
	updateToggle(NPCToggle, isNPCToggled, ACCENT_GREEN, SECONDARY_DARK)
end)

-- Player Toggle
PlayerToggle.Activated:Connect(function()
	isPlayerKillToggled = not isPlayerKillToggled
	updateToggle(PlayerToggle, isPlayerKillToggled, ACCENT_RED, SECONDARY_DARK)
end)

-- Interval Box Logic (using TweenService from the original script)
local function handleIntervalInput()
    local newVal = tonumber(IntervalBox.Text)
    if newVal and newVal > 0.01 then -- Use 0.01 as the minimum valid interval
        AttackInterval = newVal
        LocalPlayer:SetAttribute("SavedAttackInterval", newVal)
        -- Visual feedback for successful save
        local flash = TweenService:Create(IntervalBox, TweenInfo.new(0.15), { BackgroundColor3 = SET_BUTTON_COLOR })
        local back = TweenService:Create(IntervalBox, TweenInfo.new(0.3), { BackgroundColor3 = SECONDARY_DARK })
        flash:Play()
        -- Use .Completed:Wait() cautiously, task.delay is safer in a tight environment
        back:Play() 
    else
        -- Revert to last valid value if input is bad
        IntervalBox.Text = tostring(math.floor(AttackInterval * 100) / 100)
        local flash = TweenService:Create(IntervalBox, TweenInfo.new(0.15), { BackgroundColor3 = ACCENT_RED })
        local back = TweenService:Create(IntervalBox, TweenInfo.new(0.3), { BackgroundColor3 = SECONDARY_DARK })
        flash:Play()
        back:Play()
    end
end

IntervalBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		handleIntervalInput()
	end
end)

SetButton.Activated:Connect(handleIntervalInput)

-- UI Visibility Toggle
ToggleButton.Activated:Connect(function()
	Frame.Visible = not Frame.Visible
    
    if Frame.Visible then
        ToggleButton.Text = "☰"
        ToggleButton.TextColor3 = ACCENT_GREEN
    else
        ToggleButton.Text = "▶"
        ToggleButton.TextColor3 = TEXT_COLOR
    end
end)


----------------------------------------------------
-- 5. DUAL DRAG LOGIC (From the robust script)
----------------------------------------------------
local isDragging = false
local draggedElement = nil
local dragStartPos = Vector2.zero
local elementStartPos = UDim2.new()
local screenSize = Workspace.CurrentCamera.ViewportSize
local snapThreshold = 20 -- Pixels from the edge to snap

-- Update screen size on camera change
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	screenSize = Workspace.CurrentCamera.ViewportSize
end)

local function setupDragListener(elementToDrag, elementToListenOn)
	elementToListenOn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Prevent dragging if input started on an interactive element *inside* the main frame
            if elementToDrag == Frame and not elementToListenOn:IsDescendantOf(elementToListenOn.Parent) then
                return 
            end

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
            local width = draggedElement == Frame and FRAME_WIDTH or TOGGLE_SIZE
            local height = draggedElement == Frame and FRAME_HEIGHT or TOGGLE_SIZE

			-- X-Axis Snapping
			if absPos.X < snapThreshold then
				newPos = UDim2.new(0, 0, newPos.Y.Scale, newPos.Y.Offset)
			elseif absPos.X + absSize.X > screenSize.X - snapThreshold then
				newPos = UDim2.new(0, screenSize.X - width, newPos.Y.Scale, newPos.Y.Offset)
			end

			-- Y-Axis Snapping
			if absPos.Y < snapThreshold then
				newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, 0)
			elseif absPos.Y + absSize.Y > screenSize.Y - snapThreshold then
				newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, screenSize.Y - height)
			end

			draggedElement.Position = newPos
			draggedElement.ZIndex = (draggedElement == Frame) and 1 or 2
			draggedElement = nil
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and draggedElement then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStartPos
			
			-- Update position using only Offset (Scale 0)
			draggedElement.Position = UDim2.new(
				0, elementStartPos.X.Offset + delta.X,
				0, elementStartPos.Y.Offset + delta.Y
			)
		end
	end
end)

-- Setup drag for ControlFrame (using the dedicated DragHandle) and the Toggle Button
setupDragListener(Frame, DragHandle)
setupDragListener(ToggleButton, ToggleButton)


----------------------------------------------------
-- 6. CORE ATTACK LOOP
----------------------------------------------------
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	
	-- Note: The original script used 'lastAttack', the new one uses 'lastAttackTime'. 
    -- We use 'lastAttackTime' here as it was defined earlier in this merged script.
	if now - lastAttackTime < AttackInterval then return end
	lastAttackTime = now

	if not (isNPCToggled or isPlayerKillToggled) then return end

	local combinedTargets = {}

	local function addValidTargets(targets)
        for _, model in ipairs(targets) do
            local humanoid = findHumanoidInModel(model) 
            if humanoid and humanoid.Health > 0 then
                table.insert(combinedTargets, model)
            end
        end
    end

	if isNPCToggled then
		addValidTargets(getNonPlayerCharacterModels())
	end

	if isPlayerKillToggled then
		addValidTargets(getPlayerCharacterModels())
	end

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
end)
