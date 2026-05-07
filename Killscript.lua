--[[
    AXE PANEL — Refined compact UI
]]

----------------------------------------------------
-- SERVICES
----------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Axe")

----------------------------------------------------
-- STATE
----------------------------------------------------
local flags     = { npc = false, player = false, self = false, heal = false }
local timers    = { attack = 0, heal = 0 }
local intervals = {
    attack = LocalPlayer:GetAttribute("SavedAttackInterval") or 0.3,
    heal   = LocalPlayer:GetAttribute("SavedHealInterval")   or 0.5,
}
local HEAL_AMOUNT = 999999999999999999
local npcCache    = {}
local playerCache = {}

----------------------------------------------------
-- INPUT HELPER
----------------------------------------------------
local function onClick(btn, fn)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then fn() end
    end)
end

----------------------------------------------------
-- CACHE
----------------------------------------------------
local function rebuildCache()
    npcCache = {}; playerCache = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Humanoid") then
            local m = d.Parent
            if m and m:IsA("Model") then
                local plr = Players:GetPlayerFromCharacter(m)
                if plr then
                    if flags.self or plr ~= LocalPlayer then playerCache[m] = true end
                else npcCache[m] = true end
            end
        end
    end
end
rebuildCache()

Workspace.DescendantAdded:Connect(function(d)
    if not d:IsA("Humanoid") then return end
    local m = d.Parent
    if not (m and m:IsA("Model")) then return end
    local plr = Players:GetPlayerFromCharacter(m)
    if plr then
        if flags.self or plr ~= LocalPlayer then playerCache[m] = true end
    else npcCache[m] = true end
end)
Workspace.DescendantRemoving:Connect(function(d)
    npcCache[d] = nil; playerCache[d] = nil
end)
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    if flags.self then playerCache[c] = true end
end)

----------------------------------------------------
-- PALETTE
----------------------------------------------------
local C = {
    bg      = Color3.fromRGB(10,  10,  10),
    surface = Color3.fromRGB(20,  20,  20),
    card    = Color3.fromRGB(16,  16,  16),
    border  = Color3.fromRGB(38,  38,  38),
    bordHi  = Color3.fromRGB(70,  70,  70),
    white   = Color3.fromRGB(235, 235, 235),
    dim     = Color3.fromRGB(85,  85,  85),
    muted   = Color3.fromRGB(50,  50,  50),
    green   = Color3.fromRGB(60,  200, 100),
    greenDk = Color3.fromRGB(20,  55,  35),
}

local W   = 210
local R   = UDim.new(0, 9)
local RS  = UDim.new(0, 5)
local RSX = UDim.new(0, 4)

----------------------------------------------------
-- ROOT
----------------------------------------------------
local old = CoreGui:FindFirstChild("AxePanel")
if old then old:Destroy() end

local Root = Instance.new("ScreenGui", CoreGui)
Root.Name = "AxePanel"; Root.ResetOnSpawn = false; Root.DisplayOrder = 99

----------------------------------------------------
-- FLOATING PILL
----------------------------------------------------
local Pill = Instance.new("TextButton", Root)
Pill.Size             = UDim2.fromOffset(42, 20)
Pill.Position         = UDim2.fromOffset(12, 12)
Pill.BackgroundColor3 = C.surface
Pill.TextColor3       = C.dim
Pill.Text             = "AXE"
Pill.Font             = Enum.Font.GothamBold
Pill.TextSize         = 9
Pill.AutoButtonColor  = false
Pill.ZIndex           = 20
Pill.Active           = true
Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)
local pillS = Instance.new("UIStroke", Pill)
pillS.Color = C.border; pillS.Thickness = 1

----------------------------------------------------
-- FRAME
----------------------------------------------------
local Frame = Instance.new("Frame", Root)
Frame.Name             = "Panel"
Frame.BackgroundColor3 = C.bg
Frame.BorderSizePixel  = 0
Frame.Visible          = false
Frame.Active           = true
Frame.ZIndex           = 10
Frame.Size             = UDim2.fromOffset(W, 10)
Instance.new("UICorner", Frame).CornerRadius = R
local fS = Instance.new("UIStroke", Frame)
fS.Color = C.border; fS.Thickness = 1

----------------------------------------------------
-- HEADER
----------------------------------------------------
local Header = Instance.new("Frame", Frame)
Header.Size             = UDim2.fromOffset(W, 30)
Header.Position         = UDim2.fromOffset(0, 0)
Header.BackgroundColor3 = C.surface
Header.BorderSizePixel  = 0
Header.ZIndex           = 12
Header.Active           = true
Instance.new("UICorner", Header).CornerRadius = R

local hFill = Instance.new("Frame", Header)
hFill.Size             = UDim2.fromOffset(W, 14)
hFill.Position         = UDim2.fromOffset(0, 16)
hFill.BackgroundColor3 = C.surface
hFill.BorderSizePixel  = 0
hFill.ZIndex           = 12

for i = 0, 2 do
    local dot = Instance.new("Frame", Header)
    dot.Size             = UDim2.fromOffset(4, 4)
    dot.Position         = UDim2.fromOffset(11 + i * 8, 13)
    dot.BackgroundColor3 = i == 0 and Color3.fromRGB(75,75,75)
                         or i == 1 and Color3.fromRGB(52,52,52)
                         or           Color3.fromRGB(36,36,36)
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 14
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
end

local titleLbl = Instance.new("TextLabel", Header)
titleLbl.Position               = UDim2.fromOffset(40, 0)
titleLbl.Size                   = UDim2.fromOffset(W - 40, 30)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3             = C.white
titleLbl.Text                   = "AXE PANEL"
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 9
titleLbl.ZIndex                 = 13

local hSep = Instance.new("Frame", Frame)
hSep.Position         = UDim2.fromOffset(0, 30)
hSep.Size             = UDim2.fromOffset(W, 1)
hSep.BackgroundColor3 = C.border
hSep.BorderSizePixel  = 0
hSep.ZIndex           = 12

----------------------------------------------------
-- LAYOUT
----------------------------------------------------
local CY  = 34  -- start right after header
local PAD = 7
local RH  = 30  -- row height (was 34)
local GAP = 3   -- gap between rows (was 4)

----------------------------------------------------
-- SECTION LABEL
----------------------------------------------------
local function makeSection(label)
    CY += 5
    local lbl = Instance.new("TextLabel", Frame)
    lbl.Position               = UDim2.fromOffset(PAD + 2, CY)
    lbl.Size                   = UDim2.fromOffset(W, 11)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = C.muted
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 7
    lbl.ZIndex                 = 11
    CY += 13
end

----------------------------------------------------
-- TOGGLE ROW
----------------------------------------------------
local function makeRow(label, isHeal)
    local row = Instance.new("TextButton", Frame)
    row.Position         = UDim2.fromOffset(PAD, CY)
    row.Size             = UDim2.fromOffset(W - PAD * 2, RH)
    row.BackgroundColor3 = C.card
    row.Text             = ""
    row.AutoButtonColor  = false
    row.ZIndex           = 11
    row.Active           = true
    Instance.new("UICorner", row).CornerRadius = RSX
    local rS = Instance.new("UIStroke", row)
    rS.Color = C.border; rS.Thickness = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Position               = UDim2.fromOffset(9, 0)
    lbl.Size                   = UDim2.fromOffset(W - 65, RH)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = C.dim
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 10
    lbl.ZIndex                 = 12

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.fromOffset(26, 13)
    track.Position         = UDim2.fromOffset(W - PAD * 2 - 30, (RH - 13) / 2)
    track.BackgroundColor3 = C.muted
    track.BorderSizePixel  = 0
    track.ZIndex           = 12
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.fromOffset(9, 9)
    knob.Position         = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = C.dim
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 13
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local onColor = isHeal and C.green or C.white

    local function setState(on)
        lbl.TextColor3         = on and C.white or C.dim
        rS.Color               = on and C.bordHi or C.border
        track.BackgroundColor3 = on and (isHeal and C.greenDk or C.surface) or C.muted
        knob.BackgroundColor3  = on and onColor or C.dim
        knob.Position          = on
            and UDim2.fromOffset(26 - 11, 2)
            or  UDim2.fromOffset(2, 2)
    end

    CY += RH + GAP
    return row, setState
end

----------------------------------------------------
-- INPUT ROW
----------------------------------------------------
local function makeInput(label, default)
    local GH  = 46
    local grp = Instance.new("Frame", Frame)
    grp.Position         = UDim2.fromOffset(PAD, CY)
    grp.Size             = UDim2.fromOffset(W - PAD * 2, GH)
    grp.BackgroundColor3 = C.card
    grp.BorderSizePixel  = 0
    grp.ZIndex           = 11
    Instance.new("UICorner", grp).CornerRadius = RSX
    local gS = Instance.new("UIStroke", grp)
    gS.Color = C.border; gS.Thickness = 1

    local lbl = Instance.new("TextLabel", grp)
    lbl.Position               = UDim2.fromOffset(9, 5)
    lbl.Size                   = UDim2.fromOffset(W, 11)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = C.muted
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 7
    lbl.ZIndex                 = 12

    local IW = (W - PAD * 2 - 20 - 5) * 0.62
    local SW = (W - PAD * 2 - 20 - 5) * 0.38

    local box = Instance.new("TextBox", grp)
    box.Position         = UDim2.fromOffset(9, 20)
    box.Size             = UDim2.fromOffset(IW, 20)
    box.BackgroundColor3 = C.bg
    box.TextColor3       = C.white
    box.Font             = Enum.Font.GothamBold
    box.TextSize         = 11
    box.ClearTextOnFocus = false
    box.Text             = string.format("%.2f", default)
    box.ZIndex           = 12
    Instance.new("UICorner", box).CornerRadius = RS
    local bS = Instance.new("UIStroke", box)
    bS.Color = C.border; bS.Thickness = 1

    local setBtn = Instance.new("TextButton", grp)
    setBtn.Position         = UDim2.fromOffset(9 + IW + 5, 20)
    setBtn.Size             = UDim2.fromOffset(SW, 20)
    setBtn.BackgroundColor3 = C.white
    setBtn.TextColor3       = C.bg
    setBtn.Text             = "SET"
    setBtn.Font             = Enum.Font.GothamBold
    setBtn.TextSize         = 8
    setBtn.AutoButtonColor  = false
    setBtn.ZIndex           = 12
    Instance.new("UICorner", setBtn).CornerRadius = RS

    CY += GH + GAP
    return box, setBtn
end

----------------------------------------------------
-- BUILD
----------------------------------------------------
makeSection("COMBAT")
local NPCRow,    setNPC    = makeRow("Kill NPCs")
local PlayerRow, setPlayer = makeRow("Kill Players")
local SelfRow,   setSelf   = makeRow("Target Self")
makeSection("UTILITY")
local HealRow,   setHeal   = makeRow("Heal Self", true)
makeSection("TIMING")
local AtkBox,  AtkSet  = makeInput("ATTACK INTERVAL (s)", intervals.attack)
local HealBox, HealSet = makeInput("HEAL INTERVAL (s)",   intervals.heal)

CY += 6
Frame.Size     = UDim2.fromOffset(W, CY)
Frame.Position = UDim2.new(0.5, -W/2, 0.5, -CY/2)

----------------------------------------------------
-- WIRE
----------------------------------------------------
local function wire(key, row, setFn, onEn, onDis)
    onClick(row, function()
        flags[key] = not flags[key]
        setFn(flags[key])
        if flags[key] then if onEn  then onEn()  end
        else               if onDis then onDis() end end
    end)
end

wire("npc",    NPCRow,    setNPC,
    nil, function() npcCache = {}; timers.attack = 0 end)
wire("player", PlayerRow, setPlayer,
    nil, function() playerCache = {}; timers.attack = 0 end)
wire("self",   SelfRow,   setSelf,   rebuildCache, rebuildCache)
wire("heal",   HealRow,   setHeal,
    function() timers.heal = 0 end, function() timers.heal = 0 end)

onClick(AtkSet, function()
    local v = tonumber(AtkBox.Text)
    if v and v > 0.01 then intervals.attack = v
        LocalPlayer:SetAttribute("SavedAttackInterval", v)
    else AtkBox.Text = string.format("%.2f", intervals.attack) end
end)
onClick(HealSet, function()
    local v = tonumber(HealBox.Text)
    if v and v > 0.01 then intervals.heal = v
        LocalPlayer:SetAttribute("SavedHealInterval", v)
    else HealBox.Text = string.format("%.2f", intervals.heal) end
end)
onClick(Pill, function()
    Frame.Visible   = not Frame.Visible
    Pill.TextColor3 = Frame.Visible and C.white or C.dim
    pillS.Color     = Frame.Visible and C.bordHi or C.border
end)

----------------------------------------------------
-- DRAG
----------------------------------------------------
local function setupDrag(handle, target)
    local drag, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                  or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                        sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

setupDrag(Header, Frame)
setupDrag(Pill,   Pill)

----------------------------------------------------
-- HEARTBEAT
----------------------------------------------------
RunService.Heartbeat:Connect(function()
    local now = os.clock()

    if (flags.npc or flags.player) and (now - timers.attack >= intervals.attack) then
        timers.attack = now
        local targets = {}
        if flags.npc then
            for m in pairs(npcCache) do
                local h = m:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(targets, m) end
            end
        end
        if flags.player then
            for m in pairs(playerCache) do
                local h = m:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(targets, m) end
            end
        end
        if #targets > 0 and (flags.npc or flags.player) then
            RemoteEvent:FireServer({
                hb = targets, action = "hit",
                combo = 1, c = Character,
                damage = 99999999999999,
            })
        end
    end

    if flags.heal and (now - timers.heal >= intervals.heal) then
        timers.heal = now
        if Character then
            local h = Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and flags.heal then
                RemoteEvent:FireServer({
                    hb = { Character }, action = "hit",
                    combo = 1, c = Character,
                    damage = -HEAL_AMOUNT,
                })
            end
        end
    end
end)
