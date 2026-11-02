-- Plung Client v1
-- Green theme | Blox Fruits

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

-- ── State ──────────────────────────────────────────────────────────────────
local State = {
    AutoFarm       = false,
    AutoKill       = false,
    ClearRaid      = false,
    LeviathanHunt  = false,
    LeviathanSpoof = true,   -- always-on: tricks game into 5-player check
    SelectedMaterial = nil,
    SelectedLeviathan = nil,
    FarmConnection = nil,
    AutoKillConn   = nil,
}

-- ── Leviathan list ─────────────────────────────────────────────────────────
local Leviathans = {
    "Leviathan",
    "Sea Beast",
    "Coastal Guardian",
    "Ruin Guardian",
    "Ancient Leviathan",
    "Sea Guardian",
    "Dark Sea Leviathan",
    "Darkbeard",
    "Raid Boss Leviathan",
}

-- ── Farmable materials ─────────────────────────────────────────────────────
local Materials = {
    "Fish Tail",
    "Shark Skin",
    "Leather",
    "Scrap Metal",
    "Wool",
    "Silk",
    "Magma Ore",
    "Mystic Droplet",
    "Dragon Scale",
    "Ice Fragment",
    "Sand Token",
    "Flower",
    "Bone",
    "Slime",
    "Rubber",
    "Spider Web",
    "Demonic Wisp",
    "Conjured Cocoa",
    "Candied Bane",
    "Tea Leaf",
    "Random Seed",
    "Interdimensional Core",
}

-- ── Utility ────────────────────────────────────────────────────────────────
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
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title   = "Plung Client",
        Text    = msg,
        Duration = 3,
    })
end

-- ── Leviathan player spoof ──────────────────────────────────────────────────
-- Tricks the server-side player count check by firing the remote that the
-- game uses to verify party size, spoofing it with a fake 5-player payload.
local function SpoofLeviathanPlayers()
    -- Blox Fruits checks a "StartLeviathan" or similar remote with a player list
    -- We fire every candidate remote with a table of 5 fake player entries
    local remotes = {}
    local function SearchRemotes(obj)
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local n = v.Name:lower()
                if n:find("leviathan") or n:find("boss") or n:find("sea") or
                   n:find("start") or n:find("spawn") or n:find("raid") then
                    table.insert(remotes, v)
                end
            end
        end
    end
    SearchRemotes(ReplicatedStorage)
    pcall(SearchRemotes, Workspace)

    -- Build fake party (5 entries — us + 4 dummy player refs)
    local fakeParty = {}
    for i = 1, 5 do
        fakeParty[i] = LocalPlayer  -- server will see a non-nil player ref
    end

    for _, remote in ipairs(remotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(fakeParty)
            end
        end)
    end

    -- Also hook the GetPropertyChangedSignal check client-side:
    -- many BF checks do #Players:GetPlayers() < 5, so we shadow it
    local ok = pcall(function()
        local mt = getrawmetatable(Players)
        local old = mt.__index
        setreadonly(mt, false)
        mt.__index = function(self, key)
            if key == "GetPlayers" then
                return function()
                    local real = old(self, key)(self)
                    -- pad to 5 with duplicates
                    while #real < 5 do table.insert(real, LocalPlayer) end
                    return real
                end
            end
            return old(self, key)
        end
        setreadonly(mt, true)
    end)
    if ok then
        Notify("Leviathan: 5-player spoof active")
    else
        Notify("Leviathan: remote spoof fired")
    end
end

-- ── Teleport to target NPC ─────────────────────────────────────────────────
local function TeleportToNPC(npcName)
    local hrp = GetHRP()
    if not hrp then return false end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(npcName:lower()) then
            local targetHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Root")
            if targetHRP then
                hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 5, 0)
                return true, obj
            end
        end
    end
    return false
end

-- ── One-shot kill (Auto Kill) ──────────────────────────────────────────────
local function OneShot(target)
    if not target then return end
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Damage remote (Blox Fruits uses a damage remote or we hook health)
    local dmgRemotes = {}
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            local n = v.Name:lower()
            if n:find("damage") or n:find("hit") or n:find("kill") or n:find("attack") then
                table.insert(dmgRemotes, v)
            end
        end
    end

    local killed = false
    for _, r in ipairs(dmgRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer(target, hum.MaxHealth * 999)
                killed = true
            end
        end)
        if killed then return end
    end

    -- Fallback: direct health write via simulation
    pcall(function()
        local mt = getrawmetatable(hum)
        if mt then
            setreadonly(mt, false)
            hum.Health = 0
            setreadonly(mt, true)
        else
            hum.Health = 0
        end
    end)
end

-- ── Material auto-farm ─────────────────────────────────────────────────────
local function StartMaterialFarm(materialName)
    if State.FarmConnection then
        State.FarmConnection:Disconnect()
        State.FarmConnection = nil
    end

    Notify("Farming: " .. materialName)

    State.FarmConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end

        local hrp = GetHRP()
        if not hrp then return end

        -- Look for material drops / NPCs that drop the material
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            local mat  = materialName:lower()

            -- Pickup drops
            if obj:IsA("BasePart") or obj:IsA("Model") then
                if name:find(mat) or name:find("drop") or name:find("item") then
                    local pos
                    if obj:IsA("BasePart") then
                        pos = obj.Position
                    elseif obj:IsA("Model") and obj.PrimaryPart then
                        pos = obj.PrimaryPart.Position
                    end
                    if pos and (hrp.Position - pos).Magnitude < 2000 then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        -- Try to auto-collect
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

            -- Kill mobs that drop the material
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                    if name:find(mat) or (function()
                        -- check if this mob drops our material via a Values folder or tag
                        local drops = obj:FindFirstChild("Drops") or obj:FindFirstChild("Loot")
                        if drops then
                            for _, d in ipairs(drops:GetChildren()) do
                                if d.Name:lower():find(mat) then return true end
                            end
                        end
                        return false
                    end)() then
                        local targetHRP = obj:FindFirstChild("HumanoidRootPart")
                        if targetHRP then
                            hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
                            OneShot(obj)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end)
end

-- ── Auto Kill loop ─────────────────────────────────────────────────────────
local function StartAutoKill()
    if State.AutoKillConn then
        State.AutoKillConn:Disconnect()
        State.AutoKillConn = nil
    end

    State.AutoKillConn = RunService.Heartbeat:Connect(function()
        if not State.AutoKill then return end
        local hrp = GetHRP()
        if not hrp then return end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj)
                   and obj ~= Character then
                    local oHRP = obj:FindFirstChild("HumanoidRootPart")
                    if oHRP and (hrp.Position - oHRP.Position).Magnitude < 80 then
                        OneShot(obj)
                    end
                end
            end
        end
    end)
end

-- ── Clear Raid — AOE wipe ──────────────────────────────────────────────────
-- Kills every NPC in ~30-stud-equivalent map radius (Roblox studs; "30 miles" mapped
-- to effectively the whole visible map — everything on the current map layer).
local function ClearRaid()
    Notify("Clear Raid — wiping map...")
    local hrp = GetHRP()
    local RADIUS = 9999  -- whole map

    local killed = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local oHRP = obj:FindFirstChild("HumanoidRootPart")
                if oHRP then
                    local dist = hrp and (hrp.Position - oHRP.Position).Magnitude or 0
                    if dist < RADIUS then
                        OneShot(obj)
                        killed = killed + 1
                        task.wait(0.01)
                    end
                end
            end
        end
    end
    Notify("Clear Raid done — wiped " .. killed .. " NPCs")
end

-- ── Leviathan hunt ─────────────────────────────────────────────────────────
local function StartLeviathanHunt(levName)
    if State.LeviathanSpoof then SpoofLeviathanPlayers() end
    Notify("Hunting: " .. levName)

    local function HuntLoop()
        while State.LeviathanHunt do
            local found, obj = TeleportToNPC(levName)
            if found and obj then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local iters = 0
                while hum and hum.Health > 0 and State.LeviathanHunt and iters < 300 do
                    OneShot(obj)
                    -- Also fire sea-beast attack remotes
                    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local n = v.Name:lower()
                            if n:find("attack") or n:find("boss") or n:find("leviathan") then
                                pcall(function() v:FireServer(obj) end)
                            end
                        end
                    end
                    task.wait(0.1)
                    iters = iters + 1
                end
                if hum and hum.Health <= 0 then
                    Notify(levName .. " defeated! Respawning search...")
                end
            else
                -- Not found — try to trigger spawn via remote
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
    end

    task.spawn(HuntLoop)
end

-- ════════════════════════════════════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "PlungClient"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset   = true
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- ── Color palette ────────────────────────────────────────────────────────
local C = {
    BG        = Color3.fromRGB(18,  30,  18),
    Panel     = Color3.fromRGB(24,  40,  24),
    Accent    = Color3.fromRGB(50,  205, 50),   -- lime green
    AccentDim = Color3.fromRGB(30,  130, 30),
    Text      = Color3.fromRGB(220, 255, 220),
    SubText   = Color3.fromRGB(140, 200, 140),
    Red       = Color3.fromRGB(220, 60,  60),
    TopBar    = Color3.fromRGB(30,  60,  30),
    Border    = Color3.fromRGB(50,  205, 50),
    Toggle_ON = Color3.fromRGB(50,  205, 50),
    Toggle_OFF= Color3.fromRGB(60,  60,  60),
}

-- ── Icon / toggle button (P logo, green) ─────────────────────────────────
local IconBtn = Instance.new("TextButton")
IconBtn.Name            = "PlungIcon"
IconBtn.Size            = UDim2.new(0, 52, 0, 52)
IconBtn.Position        = UDim2.new(0, 20, 0.5, -26)
IconBtn.BackgroundColor3= C.AccentDim
IconBtn.TextColor3      = C.Accent
IconBtn.Font            = Enum.Font.GothamBold
IconBtn.TextSize        = 22
IconBtn.Text            = "P"
IconBtn.ZIndex          = 10
IconBtn.Parent          = ScreenGui
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
local IconStroke = Instance.new("UIStroke", IconBtn)
IconStroke.Color     = C.Accent
IconStroke.Thickness = 2

local IconLabel = Instance.new("TextLabel")
IconLabel.Size            = UDim2.new(0, 60, 0, 14)
IconLabel.Position        = UDim2.new(0.5, -30, 1, 2)
IconLabel.BackgroundTransparency = 1
IconLabel.TextColor3      = C.Accent
IconLabel.Font            = Enum.Font.GothamBold
IconLabel.TextSize        = 11
IconLabel.Text            = "Plung"
IconLabel.ZIndex          = 10
IconLabel.Parent          = IconBtn

-- ── Main window ───────────────────────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name                = "Main"
Main.Size                = UDim2.new(0, 420, 0, 560)
Main.Position            = UDim2.new(0, 90, 0.5, -280)
Main.BackgroundColor3    = C.BG
Main.BorderSizePixel     = 0
Main.Visible             = false
Main.ZIndex              = 5
Main.Parent              = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color     = C.Border
MainStroke.Thickness = 1.5

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size              = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3  = C.TopBar
TopBar.BorderSizePixel   = 0
TopBar.ZIndex            = 6
TopBar.Parent            = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size              = UDim2.new(1, -50, 1, 0)
TitleLabel.Position          = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3        = C.Accent
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextSize          = 18
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Text              = "⬡  Plung Client  v1"
TitleLabel.ZIndex            = 7
TitleLabel.Parent            = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size                = UDim2.new(0, 30, 0, 30)
CloseBtn.Position            = UDim2.new(1, -38, 0, 6)
CloseBtn.BackgroundColor3    = C.Red
CloseBtn.TextColor3          = Color3.new(1,1,1)
CloseBtn.Font                = Enum.Font.GothamBold
CloseBtn.TextSize            = 16
CloseBtn.Text                = "✕"
CloseBtn.ZIndex              = 7
CloseBtn.Parent              = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

-- Scroll content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                  = UDim2.new(1, -8, 1, -50)
Scroll.Position              = UDim2.new(0, 4, 0, 46)
Scroll.BackgroundTransparency= 1
Scroll.ScrollBarThickness    = 3
Scroll.ScrollBarImageColor3  = C.Accent
Scroll.BorderSizePixel       = 0
Scroll.ZIndex                = 6
Scroll.Parent                = Main
Scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
Scroll.CanvasSize            = UDim2.new(0,0,0,0)

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.SortOrder         = Enum.SortOrder.LayoutOrder
ListLayout.Padding           = UDim.new(0, 6)
local ScrollPad = Instance.new("UIPadding", Scroll)
ScrollPad.PaddingLeft        = UDim.new(0, 8)
ScrollPad.PaddingRight       = UDim.new(0, 8)
ScrollPad.PaddingTop         = UDim.new(0, 6)

-- ── Helper: make a section label ──────────────────────────────────────────
local function SectionLabel(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = C.Accent
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 13
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = "▸  " .. text
    lbl.LayoutOrder       = order
    lbl.ZIndex            = 7
    lbl.Parent            = Scroll
    return lbl
end

-- ── Helper: toggle button ─────────────────────────────────────────────────
local function MakeToggle(labelText, order, callback)
    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3  = C.Panel
    row.BorderSizePixel   = 0
    row.LayoutOrder       = order
    row.ZIndex            = 7
    row.Parent            = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size              = UDim2.new(1, -70, 1, 0)
    lbl.Position          = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = C.Text
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 14
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = labelText
    lbl.ZIndex            = 8

    local tog = Instance.new("TextButton", row)
    tog.Size              = UDim2.new(0, 50, 0, 26)
    tog.Position          = UDim2.new(1, -62, 0.5, -13)
    tog.BackgroundColor3  = C.Toggle_OFF
    tog.TextColor3        = Color3.new(1,1,1)
    tog.Font              = Enum.Font.GothamBold
    tog.TextSize          = 11
    tog.Text              = "OFF"
    tog.ZIndex            = 8
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

-- ── Helper: action button ─────────────────────────────────────────────────
local function MakeButton(labelText, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size              = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3  = C.AccentDim
    btn.TextColor3        = C.Text
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = 14
    btn.Text              = labelText
    btn.LayoutOrder       = order
    btn.ZIndex            = 7
    btn.Parent            = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── Helper: dropdown ──────────────────────────────────────────────────────
local function MakeDropdown(labelText, items, order, onSelect)
    local wrapper = Instance.new("Frame")
    wrapper.Size          = UDim2.new(1, 0, 0, 38)
    wrapper.BackgroundColor3 = C.Panel
    wrapper.BorderSizePixel  = 0
    wrapper.LayoutOrder   = order
    wrapper.ZIndex        = 7
    wrapper.ClipsDescendants = false
    wrapper.Parent        = Scroll
    Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 7)

    local header = Instance.new("TextButton", wrapper)
    header.Size           = UDim2.new(1, 0, 0, 38)
    header.BackgroundTransparency = 1
    header.TextColor3     = C.Text
    header.Font           = Enum.Font.Gotham
    header.TextSize       = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text           = "  " .. labelText .. ": None"
    header.ZIndex         = 8

    local arrow = Instance.new("TextLabel", header)
    arrow.Size            = UDim2.new(0, 24, 1, 0)
    arrow.Position        = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3      = C.Accent
    arrow.Font            = Enum.Font.GothamBold
    arrow.TextSize        = 14
    arrow.Text            = "▼"
    arrow.ZIndex          = 9

    local dropdown = Instance.new("Frame", wrapper)
    dropdown.Size         = UDim2.new(1, 0, 0, math.min(#items, 6) * 30)
    dropdown.Position     = UDim2.new(0, 0, 1, 2)
    dropdown.BackgroundColor3 = C.Panel
    dropdown.BorderSizePixel  = 0
    dropdown.ZIndex       = 20
    dropdown.Visible      = false
    dropdown.ClipsDescendants = true
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 7)
    local ddStroke = Instance.new("UIStroke", dropdown)
    ddStroke.Color = C.AccentDim
    ddStroke.Thickness = 1

    local ddScroll = Instance.new("ScrollingFrame", dropdown)
    ddScroll.Size          = UDim2.new(1,0,1,0)
    ddScroll.BackgroundTransparency = 1
    ddScroll.ScrollBarThickness = 2
    ddScroll.ScrollBarImageColor3 = C.Accent
    ddScroll.BorderSizePixel = 0
    ddScroll.ZIndex        = 21
    ddScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ddScroll.CanvasSize    = UDim2.new(0,0,0,0)
    local ddList = Instance.new("UIListLayout", ddScroll)
    ddList.SortOrder = Enum.SortOrder.LayoutOrder

    for i, item in ipairs(items) do
        local itemBtn = Instance.new("TextButton", ddScroll)
        itemBtn.Size          = UDim2.new(1, 0, 0, 30)
        itemBtn.BackgroundTransparency = 1
        itemBtn.TextColor3    = C.Text
        itemBtn.Font          = Enum.Font.Gotham
        itemBtn.TextSize      = 13
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.Text          = "  " .. item
        itemBtn.ZIndex        = 22
        itemBtn.LayoutOrder   = i
        itemBtn.MouseButton1Click:Connect(function()
            header.Text = "  " .. labelText .. ": " .. item
            dropdown.Visible = false
            arrow.Text = "▼"
            onSelect(item)
        end)
        itemBtn.MouseEnter:Connect(function() itemBtn.TextColor3 = C.Accent end)
        itemBtn.MouseLeave:Connect(function() itemBtn.TextColor3 = C.Text  end)
    end

    header.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
        arrow.Text = dropdown.Visible and "▲" or "▼"
        -- bring above siblings
        wrapper.ZIndex = dropdown.Visible and 50 or 7
    end)

    return wrapper
end

-- ════════════════════════════════════════════════════════════════════════════
-- Build the UI sections
-- ════════════════════════════════════════════════════════════════════════════
local ord = 0
local function O() ord = ord + 1 return ord end

-- ── COMBAT ────────────────────────────────────────────────────────────────
SectionLabel("COMBAT", O())

MakeToggle("Auto Kill  (1-shot nearby mobs)", O(), function(on)
    State.AutoKill = on
    if on then
        StartAutoKill()
    else
        if State.AutoKillConn then
            State.AutoKillConn:Disconnect()
            State.AutoKillConn = nil
        end
    end
end)

MakeButton("⚡  Clear Raid  (wipe full map)", O(), function()
    task.spawn(ClearRaid)
end)

-- ── LEVIATHAN ─────────────────────────────────────────────────────────────
SectionLabel("LEVIATHAN HUNT", O())

MakeDropdown("Select Leviathan", Leviathans, O(), function(sel)
    State.SelectedLeviathan = sel
end)

MakeToggle("Auto Hunt Leviathan", O(), function(on)
    State.LeviathanHunt = on
    if on then
        if not State.SelectedLeviathan then
            Notify("Pick a leviathan first")
            return
        end
        StartLeviathanHunt(State.SelectedLeviathan)
    end
end)

MakeToggle("5-Player Spoof  (bypass party check)", O(), function(on)
    State.LeviathanSpoof = on
    if on then SpoofLeviathanPlayers() end
end)

MakeButton("▶  Spoof Now", O(), function()
    SpoofLeviathanPlayers()
end)

-- ── MATERIAL FARM ─────────────────────────────────────────────────────────
SectionLabel("MATERIAL FARM", O())

MakeDropdown("Select Material", Materials, O(), function(sel)
    State.SelectedMaterial = sel
end)

MakeToggle("Auto Farm Material", O(), function(on)
    State.AutoFarm = on
    if on then
        if not State.SelectedMaterial then
            Notify("Pick a material first")
            return
        end
        StartMaterialFarm(State.SelectedMaterial)
    else
        if State.FarmConnection then
            State.FarmConnection:Disconnect()
            State.FarmConnection = nil
        end
    end
end)

-- ── MISC ──────────────────────────────────────────────────────────────────
SectionLabel("MISC", O())

MakeButton("⟳  Respawn Character", O(), function()
    LocalPlayer:LoadCharacter()
end)

MakeButton("☰  Rejoin Server", O(), function()
    local TS = game:GetService("TeleportService")
    TS:Teleport(game.PlaceId, LocalPlayer)
end)

-- ── Credits ───────────────────────────────────────────────────────────────
local cred = Instance.new("TextLabel")
cred.Size                = UDim2.new(1, 0, 0, 20)
cred.BackgroundTransparency = 1
cred.TextColor3          = C.SubText
cred.Font                = Enum.Font.Gotham
cred.TextSize            = 11
cred.Text                = "Plung Client  •  discord.gg/universalmodding"
cred.LayoutOrder         = O()
cred.ZIndex              = 7
cred.Parent              = Scroll

-- ════════════════════════════════════════════════════════════════════════════
-- Window drag
-- ════════════════════════════════════════════════════════════════════════════
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = Main.Position
    end
end)
TopBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- Icon toggle
-- ════════════════════════════════════════════════════════════════════════════
IconBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- ── Keybind: RightShift toggles window ───────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

-- ── Auto-open on load ─────────────────────────────────────────────────────
task.wait(0.5)
Main.Visible = true

Notify("Plung Client v1 loaded  |  RightShift to toggle")
