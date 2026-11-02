-- Plung Client v2
-- Green theme | Blox Fruits | Universal Client
-- Credits: Plung & Raven | discord.gg/universalmodding

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")
local StarterGui      = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Mouse       = LocalPlayer:GetMouse()

-- ════════════════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════════════════
local State = {
    -- Original Plung features
    AutoFarm         = false,
    AutoKill         = false,
    LeviathanHunt    = false,
    LeviathanSpoof   = true,
    SelectedMaterial = nil,
    SelectedLeviathan= nil,
    FarmConnection   = nil,
    AutoKillConn     = nil,
    -- New features from Ultra Hub
    AutoFarmLevel    = false,
    FastAttack       = false,
    FastAttackSpeed  = 10,
    AttackDistance   = 50,
    NoClip           = false,
    WalkOnWater      = false,
    AutoFarmChests   = false,
    AutoTPFruits     = false,
    AutoSpinFruit    = false,
    AutoFishing      = false,
    MagnetMobs       = false,
    MagnetRadius     = 150,
    AutoFarmBoss     = false,
    SelectedBoss     = nil,
    ESP_Players      = false,
    ESP_Chests       = false,
    ESP_Fruits       = false,
    ESP_Islands      = false,
}

-- ════════════════════════════════════════════════════════════════════════════
-- LISTS
-- ════════════════════════════════════════════════════════════════════════════
local Leviathans = {
    "Leviathan", "Sea Beast", "Coastal Guardian", "Ruin Guardian",
    "Ancient Leviathan", "Sea Guardian", "Dark Sea Leviathan",
    "Darkbeard", "Raid Boss Leviathan",
}

local Materials = {
    "Fish Tail", "Shark Skin", "Leather", "Scrap Metal", "Wool", "Silk",
    "Magma Ore", "Mystic Droplet", "Dragon Scale", "Ice Fragment",
    "Sand Token", "Flower", "Bone", "Slime", "Rubber", "Spider Web",
    "Demonic Wisp", "Conjured Cocoa", "Candied Bane", "Tea Leaf",
    "Random Seed", "Interdimensional Core",
}

local Bosses = {
    "Katakuri", "Dough King", "Rip Indra", "Tide Keeper",
    "Diamond", "Jeremy", "Darkbeard", "Swan", "Don Swan",
    "Cake Queen", "Cursed Captain",
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ════════════════════════════════════════════════════════════════════════════
local function GetCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return Character
end
local function GetHRP()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "Plung v2",
            Text     = msg,
            Duration = 3,
        })
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- BACKEND LOGIC
-- ════════════════════════════════════════════════════════════════════════════

-- ── 5-player leviathan spoof ──────────────────────────────────────────────
local function SpoofLeviathanPlayers()
    local remotes = {}
    local function SearchRemotes(obj)
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local n = v.Name:lower()
                if n:find("leviathan") or n:find("boss") or n:find("sea")
                   or n:find("start") or n:find("spawn") or n:find("raid") then
                    table.insert(remotes, v)
                end
            end
        end
    end
    SearchRemotes(ReplicatedStorage)
    pcall(SearchRemotes, Workspace)
    local fakeParty = {}
    for i = 1, 5 do fakeParty[i] = LocalPlayer end
    for _, remote in ipairs(remotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then remote:FireServer(fakeParty) end
        end)
    end
    local ok = pcall(function()
        local mt  = getrawmetatable(Players)
        local old = mt.__index
        setreadonly(mt, false)
        mt.__index = function(self, key)
            if key == "GetPlayers" then
                return function()
                    local real = old(self, key)(self)
                    while #real < 5 do table.insert(real, LocalPlayer) end
                    return real
                end
            end
            return old(self, key)
        end
        setreadonly(mt, true)
    end)
    Notify(ok and "5-player spoof active" or "Remote spoof fired")
end

-- ── One-shot kill ─────────────────────────────────────────────────────────
local function OneShot(target)
    if not target then return end
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local killed = false
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            local n = v.Name:lower()
            if n:find("damage") or n:find("hit") or n:find("kill") or n:find("attack") then
                pcall(function()
                    if v:IsA("RemoteEvent") then
                        v:FireServer(target, hum.MaxHealth * 999)
                        killed = true
                    end
                end)
                if killed then return end
            end
        end
    end
    pcall(function()
        local mt = getrawmetatable(hum)
        if mt then setreadonly(mt, false) end
        hum.Health = 0
        if mt then setreadonly(mt, true) end
    end)
end

-- ── Teleport to NPC ───────────────────────────────────────────────────────
local function TeleportToNPC(npcName)
    local hrp = GetHRP()
    if not hrp then return false end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(npcName:lower()) then
            local tHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Root")
            if tHRP then
                hrp.CFrame = tHRP.CFrame + Vector3.new(0, 5, 0)
                return true, obj
            end
        end
    end
    return false
end

-- ── Closest NPC ───────────────────────────────────────────────────────────
local function GetClosestNPC(radius)
    local c = LocalPlayer.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPos = c.HumanoidRootPart.Position
    local closest, shortest = nil, radius or math.huge
    for _, enemy in ipairs(Workspace:GetDescendants()) do
        if enemy:IsA("Model") and not Players:GetPlayerFromCharacter(enemy) then
            local eHRP = enemy:FindFirstChild("HumanoidRootPart")
            local eHum = enemy:FindFirstChildOfClass("Humanoid")
            if eHRP and eHum and eHum.Health > 0 then
                local dist = (eHRP.Position - rootPos).Magnitude
                if dist < shortest then shortest = dist; closest = enemy end
            end
        end
    end
    return closest
end

-- ── Material farm ─────────────────────────────────────────────────────────
local function StartMaterialFarm(matName)
    if State.FarmConnection then State.FarmConnection:Disconnect() State.FarmConnection = nil end
    Notify("Farming: " .. matName)
    State.FarmConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        local hrp = GetHRP(); if not hrp then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local name = obj.Name:lower(); local mat = matName:lower()
            if (obj:IsA("BasePart") or obj:IsA("Model")) then
                if name:find(mat) or name:find("drop") or name:find("item") then
                    local pos = obj:IsA("BasePart") and obj.Position
                              or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                    if pos and (hrp.Position - pos).Magnitude < 2000 then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") then
                                local vn = v.Name:lower()
                                if vn:find("collect") or vn:find("pickup") or vn:find("loot") then
                                    pcall(function() v:FireServer(obj) end)
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end
            end
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                    if name:find(mat) then
                        local tHRP = obj:FindFirstChild("HumanoidRootPart")
                        if tHRP then hrp.CFrame = tHRP.CFrame + Vector3.new(0,3,0); OneShot(obj); task.wait(0.2) end
                    end
                end
            end
        end
        task.wait(0.05)
    end)
end

-- ── Auto Kill loop ─────────────────────────────────────────────────────────
local function StartAutoKill()
    if State.AutoKillConn then State.AutoKillConn:Disconnect() State.AutoKillConn = nil end
    State.AutoKillConn = RunService.Heartbeat:Connect(function()
        if not State.AutoKill then return end
        local hrp = GetHRP(); if not hrp then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local hum  = obj:FindFirstChildOfClass("Humanoid")
                local oHRP = obj:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and oHRP
                   and not Players:GetPlayerFromCharacter(obj)
                   and (hrp.Position - oHRP.Position).Magnitude < 80 then
                    OneShot(obj)
                end
            end
        end
    end)
end

-- ── Clear Raid ────────────────────────────────────────────────────────────
local function ClearRaid()
    Notify("Clear Raid — wiping map...")
    local hrp = GetHRP()
    local killed = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= Character then
            local hum  = obj:FindFirstChildOfClass("Humanoid")
            local oHRP = obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and oHRP and not Players:GetPlayerFromCharacter(obj) then
                local dist = hrp and (hrp.Position - oHRP.Position).Magnitude or 0
                if dist < 9999 then
                    OneShot(obj); killed += 1; task.wait(0.01)
                end
            end
        end
    end
    Notify("Clear Raid done — wiped " .. killed .. " NPCs")
end

-- ── Leviathan hunt ────────────────────────────────────────────────────────
local function StartLeviathanHunt(levName)
    if State.LeviathanSpoof then SpoofLeviathanPlayers() end
    Notify("Hunting: " .. levName)
    task.spawn(function()
        while State.LeviathanHunt do
            local found, obj = TeleportToNPC(levName)
            if found and obj then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local iters = 0
                while hum and hum.Health > 0 and State.LeviathanHunt and iters < 300 do
                    OneShot(obj)
                    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local n = v.Name:lower()
                            if n:find("attack") or n:find("boss") or n:find("leviathan") then
                                pcall(function() v:FireServer(obj) end)
                            end
                        end
                    end
                    task.wait(0.1); iters += 1
                end
                if hum and hum.Health <= 0 then Notify(levName .. " defeated!") end
            else
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n = v.Name:lower()
                        if n:find("leviathan") or n:find("seabeast") or n:find("summon") then
                            pcall(function() v:FireServer() end)
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- ── Water platform for Jesus Mode ────────────────────────────────────────
local WaterPlatform = Instance.new("Part")
WaterPlatform.Size        = Vector3.new(500, 1, 500)
WaterPlatform.Anchored    = true
WaterPlatform.Transparency= 1
WaterPlatform.CanCollide  = false
WaterPlatform.Parent      = Workspace

-- ── RunService loops ──────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    -- Fast Attack
    if State.FastAttack then
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                local tool = c:FindFirstChildOfClass("Tool")
                if tool then
                    for i = 1, math.min(State.FastAttackSpeed, 10) do
                        tool:Activate()
                    end
                end
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    -- No-Clip
    if State.NoClip then
        pcall(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    -- Walk on Water
    if State.WalkOnWater then
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if root.Position.Y < 15 then
                    WaterPlatform.CFrame    = CFrame.new(root.Position.X, 0, root.Position.Z)
                    WaterPlatform.CanCollide= true
                else
                    WaterPlatform.CanCollide= false
                end
            end
        end)
    else
        WaterPlatform.CanCollide = false
    end
end)

RunService.Heartbeat:Connect(function()
    -- Magnet Mobs
    if State.MagnetMobs then
        pcall(function()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local myPos = c.HumanoidRootPart.Position
                for _, enemy in ipairs(Workspace:GetDescendants()) do
                    if enemy:IsA("Model") and not Players:GetPlayerFromCharacter(enemy) then
                        local eHRP = enemy:FindFirstChild("HumanoidRootPart")
                        local eHum = enemy:FindFirstChildOfClass("Humanoid")
                        if eHRP and eHum and eHum.Health > 0 then
                            local dist = (eHRP.Position - myPos).Magnitude
                            if dist <= State.MagnetRadius then
                                eHRP.CFrame   = c.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                                eHRP.CanCollide = false
                                eHum.WalkSpeed  = 0
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Auto Farm Level loop
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoFarmLevel then
            pcall(function()
                local target = GetClosestNPC(2000)
                if target and target:FindFirstChild("HumanoidRootPart") then
                    local c = LocalPlayer.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                            * CFrame.new(0, 6, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    end
                end
            end)
        end
    end
end)

-- Auto Farm Chests loop
task.spawn(function()
    while task.wait(0.5) do
        if State.AutoFarmChests then
            pcall(function()
                for _, chest in ipairs(Workspace:GetChildren()) do
                    if string.find(string.lower(chest.Name), "chest") and chest:IsA("BasePart") then
                        local c = LocalPlayer.Character
                        if c and c:FindFirstChild("HumanoidRootPart") then
                            c.HumanoidRootPart.CFrame = chest.CFrame
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto TP Fruits loop
task.spawn(function()
    while task.wait(1) do
        if State.AutoTPFruits then
            pcall(function()
                for _, v in ipairs(Workspace:GetChildren()) do
                    if string.find(v.Name, "Fruit") then
                        local handle = v:FindFirstChild("Handle") or v:FindFirstChildOfClass("Part")
                        if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = handle.CFrame
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Spin Fruit loop
task.spawn(function()
    while task.wait(5) do
        if State.AutoSpinFruit then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            end)
        end
    end
end)

-- Auto Fishing loop
task.spawn(function()
    while task.wait(2) do
        if State.AutoFishing then
            pcall(function()
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        local n = v.Name:lower()
                        if n:find("fish") or n:find("cast") or n:find("rod") then
                            v:FireServer()
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Farm Boss loop
task.spawn(function()
    while task.wait(0.3) do
        if State.AutoFarmBoss and State.SelectedBoss then
            pcall(function()
                local found, obj = TeleportToNPC(State.SelectedBoss)
                if found and obj then
                    OneShot(obj)
                end
            end)
        end
    end
end)

-- ── ESP System ────────────────────────────────────────────────────────────
local ESPFolder = Instance.new("Folder")
ESPFolder.Name   = "PlungESP"
ESPFolder.Parent = CoreGui

local function ClearESP()
    for _, v in ipairs(ESPFolder:GetChildren()) do v:Destroy() end
end

local function CreateBillboard(part, text, color)
    if not part then return end
    local bb = Instance.new("BillboardGui")
    bb.Adornee     = part
    bb.Size        = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent      = ESPFolder
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size              = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = color or Color3.new(1,1,1)
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 14
    lbl.Text              = text
end

RunService.Heartbeat:Connect(function()
    if not (State.ESP_Players or State.ESP_Chests or State.ESP_Fruits or State.ESP_Islands) then
        if #ESPFolder:GetChildren() > 0 then ClearESP() end
        return
    end
    ClearESP()
    if State.ESP_Players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then CreateBillboard(hrp, p.Name, Color3.fromRGB(50,205,50)) end
            end
        end
    end
    if State.ESP_Chests then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name:lower():find("chest") then
                CreateBillboard(v, "🎁 Chest", Color3.fromRGB(255,215,0))
            end
        end
    end
    if State.ESP_Fruits then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name:lower():find("fruit") then
                local p = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                if p then CreateBillboard(p, "🍎 " .. v.Name, Color3.fromRGB(255,100,100)) end
            end
        end
    end
    if State.ESP_Islands then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and (v.Name:lower():find("island") or v.Name:lower():find("sea")) then
                local p = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
                if p then CreateBillboard(p, "🏝 " .. v.Name, Color3.fromRGB(100,200,255)) end
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- GUI SETUP
-- ════════════════════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "PlungClientV2"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent or not ScreenGui:IsDescendantOf(game) then
    ScreenGui.Parent = LocalPlayer.PlayerGui
end

-- Color palette
local C = {
    BG        = Color3.fromRGB(14,  24,  14),
    Panel     = Color3.fromRGB(22,  38,  22),
    PanelDark = Color3.fromRGB(18,  30,  18),
    Accent    = Color3.fromRGB(50,  205, 50),
    AccentDim = Color3.fromRGB(30,  120, 30),
    Text      = Color3.fromRGB(220, 255, 220),
    SubText   = Color3.fromRGB(130, 180, 130),
    Red       = Color3.fromRGB(210, 55,  55),
    TopBar    = Color3.fromRGB(25,  55,  25),
    Toggle_ON = Color3.fromRGB(50,  205, 50),
    Toggle_OFF= Color3.fromRGB(55,  55,  55),
    TabActive = Color3.fromRGB(30,  120, 30),
    TabInact  = Color3.fromRGB(22,  38,  22),
    Slider    = Color3.fromRGB(40,  70,  40),
}

-- ── Draggable Icon ─────────────────────────────────────────────────────────
local IconBtn = Instance.new("TextButton")
IconBtn.Name             = "PlungIcon"
IconBtn.Size             = UDim2.new(0, 46, 0, 46)
IconBtn.Position         = UDim2.new(0, 16, 0.5, -23)
IconBtn.BackgroundColor3 = C.AccentDim
IconBtn.TextColor3       = C.Accent
IconBtn.Font             = Enum.Font.GothamBold
IconBtn.TextSize         = 20
IconBtn.Text             = "P"
IconBtn.ZIndex           = 10
IconBtn.Parent           = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
local IconStroke = Instance.new("UIStroke", IconBtn)
IconStroke.Color     = C.Accent
IconStroke.Thickness = 2
local IconLabel = Instance.new("TextLabel", IconBtn)
IconLabel.Size             = UDim2.new(0, 54, 0, 13)
IconLabel.Position         = UDim2.new(0.5, -27, 1, 2)
IconLabel.BackgroundTransparency = 1
IconLabel.TextColor3       = C.Accent
IconLabel.Font             = Enum.Font.GothamBold
IconLabel.TextSize         = 10
IconLabel.Text             = "Plung"
IconLabel.ZIndex           = 10

local iconDragging, iconDragStart, iconStartPos, iconMoved
IconBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = true; iconMoved = false
        iconDragStart = inp.Position; iconStartPos = IconBtn.Position
    end
end)
IconBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then iconDragging = false end
end)

-- ── Main Window ───────────────────────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 380, 0, 480)
Main.Position         = UDim2.new(0, 76, 0.5, -240)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel  = 0
Main.Visible          = false
Main.ZIndex           = 5
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color     = C.Accent
MainStroke.Thickness = 1.5

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = C.TopBar
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 6
TopBar.Parent           = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size             = UDim2.new(1, -50, 1, 0)
TitleLabel.Position         = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3       = C.Accent
TitleLabel.Font             = Enum.Font.GothamBold
TitleLabel.TextSize         = 15
TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left
TitleLabel.Text             = "⬡  Plung Client  v2"
TitleLabel.ZIndex           = 7
TitleLabel.Parent           = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -36, 0, 8)
CloseBtn.BackgroundColor3 = C.Red
CloseBtn.TextColor3       = Color3.new(1,1,1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 15
CloseBtn.Text             = "✕"
CloseBtn.ZIndex           = 7
CloseBtn.Parent           = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

-- ── Tab bar ────────────────────────────────────────────────────────────────
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, 34)
TabBar.Position         = UDim2.new(0, 0, 0, 44)
TabBar.BackgroundColor3 = C.PanelDark
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 6
TabBar.Parent           = Main
local TabBarList = Instance.new("UIListLayout", TabBar)
TabBarList.FillDirection = Enum.FillDirection.Horizontal
TabBarList.SortOrder     = Enum.SortOrder.LayoutOrder
TabBarList.Padding       = UDim.new(0, 2)
local TabBarPad = Instance.new("UIPadding", TabBar)
TabBarPad.PaddingLeft = UDim.new(0, 4)
TabBarPad.PaddingTop  = UDim.new(0, 4)

-- ── Content area (scrolling frames per tab) ────────────────────────────────
local ContentArea = Instance.new("Frame")
ContentArea.Size             = UDim2.new(1, 0, 1, -82)
ContentArea.Position         = UDim2.new(0, 0, 0, 82)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex           = 6
ContentArea.Parent           = Main

-- ── Tab system helpers ─────────────────────────────────────────────────────
local AllTabs      = {}
local ActiveTabBtn = nil

local function MakeTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 72, 0, 28)
    btn.BackgroundColor3 = C.TabInact
    btn.TextColor3       = C.SubText
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 11
    btn.Text             = icon .. " " .. name
    btn.ZIndex           = 7
    btn.LayoutOrder      = #AllTabs + 1
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local page = Instance.new("ScrollingFrame")
    page.Size                  = UDim2.new(1, -8, 1, 0)
    page.Position              = UDim2.new(0, 4, 0, 0)
    page.BackgroundTransparency= 1
    page.ScrollBarThickness    = 3
    page.ScrollBarImageColor3  = C.Accent
    page.BorderSizePixel       = 0
    page.ZIndex                = 6
    page.Visible               = false
    page.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    page.CanvasSize            = UDim2.new(0,0,0,0)
    page.Parent                = ContentArea
    local pList = Instance.new("UIListLayout", page)
    pList.SortOrder  = Enum.SortOrder.LayoutOrder
    pList.Padding    = UDim.new(0, 6)
    local pPad = Instance.new("UIPadding", page)
    pPad.PaddingTop    = UDim.new(0, 6)
    pPad.PaddingBottom = UDim.new(0, 8)

    local tabObj = {Btn = btn, Page = page}
    table.insert(AllTabs, tabObj)

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(AllTabs) do
            t.Btn.BackgroundColor3 = C.TabInact
            t.Btn.TextColor3       = C.SubText
            t.Page.Visible         = false
        end
        btn.BackgroundColor3 = C.TabActive
        btn.TextColor3       = C.Accent
        page.Visible         = true
        ActiveTabBtn         = btn
    end)

    -- Activate first tab by default
    if #AllTabs == 1 then
        btn.BackgroundColor3 = C.TabActive
        btn.TextColor3       = C.Accent
        page.Visible         = true
        ActiveTabBtn         = btn
    end

    return page
end

-- ── UI element helpers ────────────────────────────────────────────────────
local function SectionLabel(page, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = C.Accent
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 12
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = "▸  " .. text
    lbl.LayoutOrder      = order
    lbl.ZIndex           = 7
    lbl.Parent           = page
end

local function MakeToggle(page, labelText, order, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = C.Panel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.ZIndex           = 7
    row.Parent           = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(1, -66, 1, 0)
    lbl.Position         = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = C.Text
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = labelText
    lbl.ZIndex           = 8
    local tog = Instance.new("TextButton", row)
    tog.Size             = UDim2.new(0, 44, 0, 22)
    tog.Position         = UDim2.new(1, -54, 0.5, -11)
    tog.BackgroundColor3 = C.Toggle_OFF
    tog.TextColor3       = Color3.new(1,1,1)
    tog.Font             = Enum.Font.GothamBold
    tog.TextSize         = 10
    tog.Text             = "OFF"
    tog.ZIndex           = 8
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)
    local on = false
    tog.MouseButton1Click:Connect(function()
        on = not on
        tog.BackgroundColor3 = on and C.Toggle_ON or C.Toggle_OFF
        tog.Text             = on and "ON" or "OFF"
        callback(on)
    end)
    return row, tog
end

local function MakeButton(page, labelText, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = C.AccentDim
    btn.TextColor3       = C.Text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.Text             = labelText
    btn.LayoutOrder      = order
    btn.ZIndex           = 7
    btn.Parent           = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function MakeSlider(page, text, minV, maxV, defaultV, order, callback)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = C.Panel
    frame.BorderSizePixel  = 0
    frame.LayoutOrder      = order
    frame.ZIndex           = 7
    frame.Parent           = page
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size             = UDim2.new(1, -24, 0, 20)
    lbl.Position         = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = C.Text
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = text .. ": " .. tostring(defaultV)
    lbl.ZIndex           = 8
    local track = Instance.new("Frame", frame)
    track.Size           = UDim2.new(1, -24, 0, 6)
    track.Position       = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = C.Slider
    track.ZIndex         = 8
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size            = UDim2.new((defaultV - minV)/(maxV - minV), 0, 1, 0)
    fill.BackgroundColor3= C.Accent
    fill.ZIndex          = 9
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local slideDragging = false
    local function UpdateSlider(input)
        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minV + (maxV - minV) * pct)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        lbl.Text  = text .. ": " .. tostring(val)
        pcall(callback, val)
    end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            slideDragging = true; UpdateSlider(inp)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then slideDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if slideDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(inp)
        end
    end)
end

local function MakeDropdown(page, labelText, items, order, onSelect)
    local wrapper = Instance.new("Frame")
    wrapper.Size             = UDim2.new(1, 0, 0, 36)
    wrapper.BackgroundColor3 = C.Panel
    wrapper.BorderSizePixel  = 0
    wrapper.LayoutOrder      = order
    wrapper.ZIndex           = 7
    wrapper.ClipsDescendants = false
    wrapper.Parent           = page
    Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 6)
    local header = Instance.new("TextButton", wrapper)
    header.Size             = UDim2.new(1, 0, 0, 36)
    header.BackgroundTransparency = 1
    header.TextColor3       = C.Text
    header.Font             = Enum.Font.Gotham
    header.TextSize         = 13
    header.TextXAlignment   = Enum.TextXAlignment.Left
    header.Text             = "  " .. labelText .. ": None"
    header.ZIndex           = 8
    local arrow = Instance.new("TextLabel", header)
    arrow.Size              = UDim2.new(0, 24, 1, 0)
    arrow.Position          = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3        = C.Accent
    arrow.Font              = Enum.Font.GothamBold
    arrow.TextSize          = 13
    arrow.Text              = "▼"
    arrow.ZIndex            = 9
    local dropdown = Instance.new("Frame", wrapper)
    dropdown.Size           = UDim2.new(1, 0, 0, math.min(#items, 6) * 28)
    dropdown.Position       = UDim2.new(0, 0, 1, 2)
    dropdown.BackgroundColor3 = C.PanelDark
    dropdown.BorderSizePixel  = 0
    dropdown.ZIndex         = 20
    dropdown.Visible        = false
    dropdown.ClipsDescendants = true
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)
    local ddStroke = Instance.new("UIStroke", dropdown)
    ddStroke.Color = C.AccentDim; ddStroke.Thickness = 1
    local ddScroll = Instance.new("ScrollingFrame", dropdown)
    ddScroll.Size               = UDim2.new(1,0,1,0)
    ddScroll.BackgroundTransparency = 1
    ddScroll.ScrollBarThickness = 2
    ddScroll.ScrollBarImageColor3 = C.Accent
    ddScroll.BorderSizePixel    = 0
    ddScroll.ZIndex             = 21
    ddScroll.AutomaticCanvasSize= Enum.AutomaticSize.Y
    ddScroll.CanvasSize         = UDim2.new(0,0,0,0)
    local ddList = Instance.new("UIListLayout", ddScroll)
    ddList.SortOrder = Enum.SortOrder.LayoutOrder
    for i, item in ipairs(items) do
        local itemBtn = Instance.new("TextButton", ddScroll)
        itemBtn.Size            = UDim2.new(1, 0, 0, 28)
        itemBtn.BackgroundTransparency = 1
        itemBtn.TextColor3      = C.Text
        itemBtn.Font            = Enum.Font.Gotham
        itemBtn.TextSize        = 13
        itemBtn.TextXAlignment  = Enum.TextXAlignment.Left
        itemBtn.Text            = "  " .. item
        itemBtn.ZIndex          = 22
        itemBtn.LayoutOrder     = i
        itemBtn.MouseButton1Click:Connect(function()
            header.Text = "  " .. labelText .. ": " .. item
            dropdown.Visible = false; arrow.Text = "▼"
            wrapper.ZIndex = 7
            onSelect(item)
        end)
        itemBtn.MouseEnter:Connect(function() itemBtn.TextColor3 = C.Accent end)
        itemBtn.MouseLeave:Connect(function() itemBtn.TextColor3 = C.Text  end)
    end
    header.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
        arrow.Text = dropdown.Visible and "▲" or "▼"
        wrapper.ZIndex = dropdown.Visible and 50 or 7
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- BUILD TABS
-- ════════════════════════════════════════════════════════════════════════════
local ord = 0
local function O() ord = ord + 1 return ord end

-- ── TAB 1: COMBAT ─────────────────────────────────────────────────────────
local CombatPage = MakeTab("Combat", "⚔️")
ord = 0

SectionLabel(CombatPage, "AUTO COMBAT", O())
MakeToggle(CombatPage, "Auto Kill  (1-shot nearby mobs)", O(), function(on)
    State.AutoKill = on
    if on then StartAutoKill()
    elseif State.AutoKillConn then State.AutoKillConn:Disconnect(); State.AutoKillConn = nil end
end)
MakeButton(CombatPage, "⚡  Clear Raid  (wipe full map)", O(), function()
    task.spawn(ClearRaid)
end)

SectionLabel(CombatPage, "FAST ATTACK", O())
MakeToggle(CombatPage, "Fast Attack Speed", O(), function(on)
    State.FastAttack = on
end)
MakeSlider(CombatPage, "Attack Speed (x1-x100)", 1, 100, 10, O(), function(v)
    State.FastAttackSpeed = v
end)
MakeSlider(CombatPage, "Attack Reach (x1-x300)", 1, 300, 50, O(), function(v)
    State.AttackDistance = v
end)

SectionLabel(CombatPage, "MAGNET MOBS", O())
MakeToggle(CombatPage, "Magnet Mobs  (pull enemies to you)", O(), function(on)
    State.MagnetMobs = on
end)
MakeSlider(CombatPage, "Magnet Radius", 50, 300, 150, O(), function(v)
    State.MagnetRadius = v
end)

-- ── TAB 2: FARM ───────────────────────────────────────────────────────────
local FarmPage = MakeTab("Farm", "🌾")
ord = 0

SectionLabel(FarmPage, "AUTO FARM LEVEL", O())
MakeToggle(FarmPage, "Auto Farm Level  (TP to closest NPC)", O(), function(on)
    State.AutoFarmLevel = on
end)

SectionLabel(FarmPage, "BOSS FARM", O())
MakeDropdown(FarmPage, "Select Boss", Bosses, O(), function(sel)
    State.SelectedBoss = sel
end)
MakeToggle(FarmPage, "Auto Farm Boss", O(), function(on)
    State.AutoFarmBoss = on
    if on and not State.SelectedBoss then Notify("Pick a boss first") end
end)

SectionLabel(FarmPage, "MATERIAL FARM", O())
MakeDropdown(FarmPage, "Select Material", Materials, O(), function(sel)
    State.SelectedMaterial = sel
end)
MakeToggle(FarmPage, "Auto Farm Material", O(), function(on)
    State.AutoFarm = on
    if on then
        if not State.SelectedMaterial then Notify("Pick a material first"); return end
        StartMaterialFarm(State.SelectedMaterial)
    elseif State.FarmConnection then
        State.FarmConnection:Disconnect(); State.FarmConnection = nil
    end
end)

SectionLabel(FarmPage, "WORLD FARM", O())
MakeToggle(FarmPage, "Auto Farm Chests", O(), function(on) State.AutoFarmChests = on end)
MakeToggle(FarmPage, "Auto TP & Collect Fruits", O(), function(on) State.AutoTPFruits = on end)
MakeToggle(FarmPage, "Auto Fishing", O(), function(on) State.AutoFishing = on end)
MakeToggle(FarmPage, "Auto Spin Fruit  (random gacha)", O(), function(on) State.AutoSpinFruit = on end)

-- ── TAB 3: LEVIATHAN ─────────────────────────────────────────────────────
local LevPage = MakeTab("Levi", "🌊")
ord = 0

SectionLabel(LevPage, "LEVIATHAN HUNT", O())
MakeDropdown(LevPage, "Select Leviathan", Leviathans, O(), function(sel)
    State.SelectedLeviathan = sel
end)
MakeToggle(LevPage, "Auto Hunt Leviathan", O(), function(on)
    State.LeviathanHunt = on
    if on then
        if not State.SelectedLeviathan then Notify("Pick a leviathan first"); return end
        StartLeviathanHunt(State.SelectedLeviathan)
    end
end)

SectionLabel(LevPage, "PARTY SPOOF", O())
MakeToggle(LevPage, "5-Player Spoof  (bypass party check)", O(), function(on)
    State.LeviathanSpoof = on
    if on then SpoofLeviathanPlayers() end
end)
MakeButton(LevPage, "▶  Spoof Now", O(), function()
    SpoofLeviathanPlayers()
end)

-- ── TAB 4: MOVEMENT ───────────────────────────────────────────────────────
local MovePage = MakeTab("Move", "🏃")
ord = 0

SectionLabel(MovePage, "MOVEMENT HACKS", O())
MakeToggle(MovePage, "No-Clip  (walk through walls)", O(), function(on) State.NoClip = on end)
MakeToggle(MovePage, "Jesus Mode  (walk on water)", O(), function(on) State.WalkOnWater = on end)

SectionLabel(MovePage, "MISC", O())
MakeButton(MovePage, "⟳  Respawn Character", O(), function()
    LocalPlayer:LoadCharacter()
end)
MakeButton(MovePage, "☰  Rejoin Server", O(), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- ── TAB 5: ESP ────────────────────────────────────────────────────────────
local ESPPage = MakeTab("ESP", "👁")
ord = 0

SectionLabel(ESPPage, "ESP OVERLAYS", O())
MakeToggle(ESPPage, "ESP Players", O(), function(on) State.ESP_Players = on end)
MakeToggle(ESPPage, "ESP Chests", O(), function(on) State.ESP_Chests = on end)
MakeToggle(ESPPage, "ESP Fruits", O(), function(on) State.ESP_Fruits = on end)
MakeToggle(ESPPage, "ESP Islands", O(), function(on) State.ESP_Islands = on end)
MakeButton(ESPPage, "🗑  Clear ESP", O(), function()
    State.ESP_Players = false
    State.ESP_Chests  = false
    State.ESP_Fruits  = false
    State.ESP_Islands = false
    ClearESP()
    Notify("ESP cleared")
end)

-- Credits
local cred = Instance.new("TextLabel")
cred.Size             = UDim2.new(1, 0, 0, 18)
cred.BackgroundTransparency = 1
cred.TextColor3       = C.SubText
cred.Font             = Enum.Font.Gotham
cred.TextSize         = 11
cred.Text             = "Plung Client v2  •  discord.gg/universalmodding"
cred.LayoutOrder      = 999
cred.ZIndex           = 7
cred.Parent           = ESPPage

-- ════════════════════════════════════════════════════════════════════════════
-- WINDOW DRAG
-- ════════════════════════════════════════════════════════════════════════════
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = inp.Position; startPos = Main.Position
    end
end)
TopBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if dragging then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    if iconDragging then
        local delta = inp.Position - iconDragStart
        if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then iconMoved = true end
        IconBtn.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
                                      iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- TOGGLE / KEYBIND
-- ════════════════════════════════════════════════════════════════════════════
IconBtn.MouseButton1Click:Connect(function()
    if iconMoved then iconMoved = false return end
    Main.Visible = not Main.Visible
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)
UserInputService.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

-- Auto-open
task.wait(0.5)
Main.Visible = true
Notify("Plung Client v2 loaded  •  RightShift to toggle")
