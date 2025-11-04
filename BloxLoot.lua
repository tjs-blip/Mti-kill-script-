--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService") 

local player = Players.LocalPlayer
-- Ensure the player object is loaded before continuing.
repeat task.wait() until player and player.Parent and player.PlayerGui

--== GUARD CLAUSE: PREVENT DUPLICATES & CLEANUP ==
-- Safely get PlayerGui
local PlayerGui = player:FindFirstChild("PlayerGui")
if not PlayerGui then 
    warn("[AutoAttack Guard] PlayerGui not found. Terminating new script.") 
    script:Destroy() 
    return 
end

local GUI_NAME = "AutoAttackGui"
local existingGui = PlayerGui:FindFirstChild(GUI_NAME)

if existingGui then
	warn("[AutoAttack Guard] Found existing instance of the script/GUI.")
    
    -- Attempt to destroy the parent object (which is often the old script instance)
    local oldScript = existingGui.Parent
    
    -- Safely check and destroy the old script instance
    if oldScript and oldScript:IsA("LocalScript") and oldScript ~= script then 
        warn("[AutoAttack Guard] Destroying old LocalScript instance.")
        oldScript:Destroy()
    else
        -- If parent is not the script, destroy the GUI directly for cleanup.
        existingGui:Destroy()
    end
    
	task.wait(0.1) 
end
--================================================

-- Rest of the script remains unchanged but is included for completeness.

--== PERSISTENT SETTINGS ==
local savedSettings = {
	radius = 100,
	attackInterval = 0.1,
	attacking = false,
	wasAttacking = false
}

--== VARIABLES ==
local character
local rootPart
local highlightedEnemies = {}
local enemiesCache = {}
local toggleButton
local currentAttackFunction
local cachedAttackFunctions = {}
local radiusIndicator 

--== STRICT AUTO TOOL DETECTION ==
local baseToolPrefix = "Tool_Character_1160945383_"

local function findLatestTool()
    -- Safely check for ReplicatedStorage/Runtime
    local runtime = ReplicatedStorage:FindFirstChild("Runtime")
    if not runtime then return nil end
    local actorsFolder = runtime:FindFirstChild("Actors")
    if not actorsFolder then return nil end

	local newestTool
	local highestNumber = 0

	for _, tool in ipairs(actorsFolder:GetChildren()) do
		if tool.Name:sub(1, #baseToolPrefix) == baseToolPrefix then
			local numStr = tool.Name:match(baseToolPrefix .. "(%d+)")
			local num = tonumber(numStr)
			if num and num > highestNumber then
				highestNumber = num
				newestTool = tool
			end
		end
	end
	return newestTool
end

local function getAttackFunction()
	local tool = findLatestTool()
	if not tool then
		warn("[AutoAttack] No tool found beginning with " .. baseToolPrefix)
		return nil
	end

	if cachedAttackFunctions[tool.Name] then
		return cachedAttackFunctions[tool.Name]
	end

	local functionsFolder = tool:FindFirstChild("Functions")
	local attackFunction = functionsFolder and functionsFolder:FindFirstChild("Attack")

	if attackFunction then
		cachedAttackFunctions[tool.Name] = attackFunction
		return attackFunction
	else
		warn("[AutoAttack] Tool found but missing Attack function: " .. tool.Name)
		return nil
	end
end

-- Auto-refresh when new tools appear/disappear
task.spawn(function()
    local runtime = ReplicatedStorage:FindFirstChild("Runtime")
    if not runtime then return end -- Nil check
	local actorsFolder = runtime:FindFirstChild("Actors")
    if not actorsFolder then return end -- Nil check

	local function refreshTool()
		local newTool = findLatestTool()
		if newTool and newTool.Name:sub(1, #baseToolPrefix) == baseToolPrefix then
			currentAttackFunction = getAttackFunction()
		end
	end

	actorsFolder.ChildAdded:Connect(function(child)
		if child.Name:sub(1, #baseToolPrefix) == baseToolPrefix then
			task.wait(0.2)
			refreshTool()
		end
	end)

	actorsFolder.ChildRemoved:Connect(function(child)
		if child.Name:sub(1, #baseToolPrefix) == baseToolPrefix then
			task.wait(0.2)
			refreshTool()
		end
	end)

	while true do
		if not currentAttackFunction or not currentAttackFunction.Parent then
			refreshTool()
		end
		task.wait(2)
	end
end)

local function getCurrentAttackFunction()
	if not currentAttackFunction or not currentAttackFunction.Parent then
		currentAttackFunction = getAttackFunction()
	end
	return currentAttackFunction
end

--== ENEMY DETECTION ==
local function updateEnemies()
	local enemyFolder = Workspace:FindFirstChild("Runtime") and Workspace.Runtime:FindFirstChild("Enemies")
	if not enemyFolder or not rootPart then return end

	local newCache = {}
	for _, model in pairs(enemyFolder:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("ActorId") and model:FindFirstChild("Humanoid") then
			local part = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
			if part then
				local distance = (part.Position - rootPart.Position).Magnitude
				if distance <= savedSettings.radius then
					newCache[model] = part
				end
			end
		end
	end
	enemiesCache = newCache
end

--== ENEMY HIGHLIGHTS ==
local function clearHighlights()
	for _, box in pairs(highlightedEnemies) do
		if box and box.Parent then box:Destroy() end
	end
	highlightedEnemies = {}
end

local function updateHighlights()
	if not rootPart then return end
    
	for enemy, box in pairs(highlightedEnemies) do
		if not enemiesCache[enemy] or not box.Parent then
			if box then box:Destroy() end
			highlightedEnemies[enemy] = nil
		end
	end

	for model, part in pairs(enemiesCache) do
        if not part then continue end 
        
		local distance = (part.Position - rootPart.Position).Magnitude
		if distance <= savedSettings.radius then
			if not highlightedEnemies[model] then
				local box = Instance.new("SelectionBox")
                if not part then continue end
                
				box.Adornee = part
				box.LineThickness = 0.05
				box.Color3 = Color3.fromRGB(0,170,255)
				box.Parent = part
				highlightedEnemies[model] = box
			end
		else
			if highlightedEnemies[model] then
				highlightedEnemies[model]:Destroy()
				highlightedEnemies[model] = nil
			end
		end
	end
end

local highlightThrottle = 0.05
local highlightTimer = 0
RunService.RenderStepped:Connect(function(dt)
	highlightTimer += dt
	if highlightTimer >= highlightThrottle then
		updateHighlights()
		highlightTimer = 0
	end
end)

--== CHARACTER HANDLING ==
local function onCharacterAdded(char)
	character = char
	rootPart = character and character:WaitForChild("HumanoidRootPart") 
	clearHighlights()
	
	savedSettings.wasAttacking = savedSettings.attacking

	repeat
		currentAttackFunction = getCurrentAttackFunction()
		task.wait(0.2)
	until currentAttackFunction

	if savedSettings.wasAttacking then
		savedSettings.attacking = true
		if toggleButton then
			toggleButton.Text = "Stop"
			toggleButton.BackgroundColor3 = Color3.fromRGB(170,0,0)
		end
	end
end

-- Simple logic: Direct connections
player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(function()
	clearHighlights()
	character = nil
	rootPart = nil
	enemiesCache = {}
end)

if player.Character then
	onCharacterAdded(player.Character)
end

--== AUTO ATTACK LOOP (RADIUS FILTERED) ==
task.spawn(function()
	while true do
		if savedSettings.attacking then
			local attackFunc = getCurrentAttackFunction()
			if not attackFunc or not rootPart then
				task.wait(0.1)
				continue
			end

			updateEnemies()

			if next(enemiesCache) then
				local attackTable = {}
				for model, part in pairs(enemiesCache) do
                    if not part then continue end
                    
					local actorId = model:FindFirstChild("ActorId")
                    if not actorId then continue end
                    
					local distance = (part.Position - rootPart.Position).Magnitude
					if distance <= savedSettings.radius then
						attackTable[actorId.Value] = part
					end
				end

				if next(attackTable) then
					local success, err = pcall(function()
                        if attackFunc then 
						    attackFunc:InvokeServer(attackTable)
                        end
					end)
					if not success then
						warn("[AutoAttack] InvokeServer failed: " .. tostring(err))
						currentAttackFunction = nil
					end
				end
			end
		end
		task.wait(savedSettings.attackInterval)
	end
end)

--== MODERN GUI ==
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME 
ScreenGui.DisplayOrder = 99999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- New: small tween helper + button hover styling
local function tweenInstance(obj, props, time)
	time = time or 0.16
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
	local success, tween = pcall(function() 
        if obj then return TweenService:Create(obj, info, props) end
        return nil, nil
    end)
	if success and tween then tween:Play() end
end

local buttonHoverProps = {
	brighten = Color3.fromRGB(20, 90, 140),
	normal = Color3.fromRGB(0, 50, 100),
	danger = Color3.fromRGB(170, 0, 0),
	text = Color3.fromRGB(0,170,255)
}

local function applyHover(btn, opts)
	if not btn then return end 
    
	btn.MouseEnter:Connect(function()
		local bColor = (opts and opts.danger) and buttonHoverProps.danger or buttonHoverProps.brighten
		tweenInstance(btn, {BackgroundColor3 = bColor}, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		tweenInstance(btn, {BackgroundColor3 = opts and (opts.danger and buttonHoverProps.danger or buttonHoverProps.normal) or buttonHoverProps.normal}, 0.12)
	end)
end

-- MAIN FRAME (modern/stylish)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0,280,0,180) 
mainFrame.Position = UDim2.new(0.05,0,0.25,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(12,16,22)
mainFrame.BackgroundTransparency = 0.06
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1
mainFrame.Active = true 
mainFrame.Draggable = true 
mainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0,14)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(30,50,70)
mainStroke.Transparency = 0.6
mainStroke.Thickness = 1

local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(8,14,24)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(16,24,36))
}
mainGradient.Rotation = 90
mainGradient.Transparency = NumberSequence.new(0.02)

-- TITLE BAR (with icon)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundTransparency = 1
mainFrame.Parent:IsA("ScreenGui") -- Safely ensure ScreenGui exists
titleBar.Parent = mainFrame

local titleAccent = Instance.new("Frame", titleBar)
titleAccent.Size = UDim2.new(1,0,0,4)
titleAccent.Position = UDim2.new(0,0,1,-4)
titleAccent.BackgroundColor3 = Color3.fromRGB(0,170,255)
titleAccent.BorderSizePixel = 0
local accentCorner = Instance.new("UICorner", titleAccent)
accentCorner.CornerRadius = UDim.new(0,4)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,-68,1,0)
titleText.Position = UDim2.new(0,12,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚔  Auto Attack"
titleText.TextColor3 = buttonHoverProps.text
titleText.Font = Enum.Font.GothamSemibold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.ZIndex = 2
titleText.Parent = titleBar

-- CLOSE BUTTON (styled and hover-enabled)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0,34,0,28)
closeButton.Position = UDim2.new(1,-42,0,4)
closeButton.BackgroundColor3 = buttonHoverProps.normal
closeButton.TextColor3 = Color3.fromRGB(0,170,255)
closeButton.Text = "✕"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.AutoButtonColor = false
closeButton.Parent = titleBar
local closeCorner = Instance.new("UICorner", closeButton)
closeCorner.CornerRadius = UDim.new(0,10)
local closeStroke = Instance.new("UIStroke", closeButton)
closeStroke.Color = Color3.fromRGB(22,60,90)
closeStroke.Transparency = 0.7
closeStroke.Thickness = 1

applyHover(closeButton, {danger = false})
closeButton.MouseButton1Click:Connect(function()
	-- 1. Stop attacking logic (if running)
	savedSettings.attacking = false
	
	-- 2. Clear all highlights in the workspace
	clearHighlights()
	
	-- 3. Destroy the entire GUI element (and all children)
	if ScreenGui then 
	    ScreenGui:Destroy()
    end
	
	-- 4. Terminate the script (THE MOST RELIABLE METHOD)
	script:Destroy()
end)

-- LABELS & TEXTBOXES
local function createLabel(text,pos)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0,100,0,25)
	lbl.Position = pos
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(0,170,255)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
    if mainFrame then 
	    lbl.Parent = mainFrame
    end
	return lbl
end

local function createBox(default,pos)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0,80,0,28)
	box.Position = pos
	box.BackgroundColor3 = Color3.fromRGB(20,20,20)
	box.TextColor3 = Color3.fromRGB(0,170,255)
	box.Text = tostring(default)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 16
	box.TextXAlignment = Enum.TextXAlignment.Center
    if mainFrame then 
	    box.Parent = mainFrame
    end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,12)
	corner.Parent = box
	return box
end

local radiusLabel = createLabel("Radius:",UDim2.new(0,15,0,50))
local radiusBox = createBox(savedSettings.radius,UDim2.new(0,90,0,48))
local intervalLabel = createLabel("Interval (s):",UDim2.new(0,15,0,90))
local intervalBox = createBox(savedSettings.attackInterval,UDim2.new(0,90,0,88))

local function createApply(pos,callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,60,0,28)
	btn.Position = pos
	btn.Text = "Apply"
	btn.BackgroundColor3 = buttonHoverProps.normal
	btn.TextColor3 = buttonHoverProps.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = false
    if mainFrame then 
	    btn.Parent = mainFrame
    end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,12)
	corner.Parent = btn
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(20,60,95)
	stroke.Transparency = 0.7
	stroke.Thickness = 1
	btn.MouseButton1Click:Connect(callback)
	applyHover(btn)
	return btn
end

createApply(UDim2.new(0,180,0,48), function()
	local val = tonumber(radiusBox and radiusBox.Text) 
	if val and val > 0 then
		savedSettings.radius = val
	else
        if radiusBox then 
		    radiusBox.Text = tostring(savedSettings.radius)
        end
	end
end)

createApply(UDim2.new(0,180,0,88), function()
	local val = tonumber(intervalBox and intervalBox.Text) 
	if val and val > 0 then
		savedSettings.attackInterval = val
	else
        if intervalBox then 
		    intervalBox.Text = tostring(savedSettings.attackInterval)
        end
	end
end)

-- ATTACK TOGGLE BUTTON
toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0,80,0,28)
toggleButton.Position = UDim2.new(0.5,-40,0,138) 
toggleButton.Text = "Start"
toggleButton.BackgroundColor3 = Color3.fromRGB(0,50,100)
toggleButton.TextColor3 = Color3.fromRGB(0,170,255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0,12)
toggleCorner.Parent = toggleButton

toggleButton.MouseButton1Click:Connect(function()
	savedSettings.attacking = not savedSettings.attacking
	if toggleButton then
        if savedSettings.attacking then
            toggleButton.Text = "Stop"
            toggleButton.BackgroundColor3 = Color3.fromRGB(170,0,0)
        else
            toggleButton.Text = "Start"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0,50,100)
        end
    end
end)
applyHover(toggleButton)

-- MINI FLOATING TOGGLE
local miniToggle = Instance.new("TextButton")
miniToggle.Size = UDim2.new(0,30,0,30)
miniToggle.Position = UDim2.new(1,-40,1,-40)
miniToggle.BackgroundColor3 = Color3.fromRGB(0,50,100)
miniToggle.TextColor3 = Color3.fromRGB(0,170,255)
miniToggle.Text = ">>"
miniToggle.Font = Enum.Font.GothamBold
miniToggle.TextSize = 16
miniToggle.ZIndex = 50
miniToggle.Parent = ScreenGui
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0,12)
miniCorner.Parent = miniToggle

miniToggle.MouseButton1Click:Connect(function()
    if mainFrame and miniToggle then
	    mainFrame.Visible = not mainFrame.Visible
	    miniToggle.Text = mainFrame.Visible and "<<" or ">>"
    end
end)
applyHover(miniToggle)

-- F1 HOTKEY
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.F1 then
        if mainFrame and miniToggle then
		    mainFrame.Visible = not mainFrame.Visible
		    miniToggle.Text = mainFrame.Visible and "<<" or ">>"
        end
	end
end)
