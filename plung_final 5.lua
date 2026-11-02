-- ╔══════════════════════════════════════════╗
-- ║         PLUNG HUB  v3.0  — TABBED       ║
-- ╚══════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp     = Players.LocalPlayer
local pgui   = lp:WaitForChild("PlayerGui")

-- character refs (updated on respawn)
local character, hrp, humanoid
local function refreshChar()
    character = lp.Character or lp.CharacterAdded:Wait()
    hrp       = character:WaitForChild("HumanoidRootPart")
    humanoid  = character:FindFirstChildOfClass("Humanoid")
end
refreshChar()

lp.CharacterAdded:Connect(function(c)
    character = c
    hrp       = c:WaitForChild("HumanoidRootPart")
    humanoid  = c:WaitForChild("Humanoid")
end)

-- sea detection
local placeId     = game.PlaceId
local isFirstSea  = placeId == 2753915549
local isSecondSea = placeId == 4442272183
local isThirdSea  = placeId == 7449423635

-- ─── hub toggle state ──────────────────────────────────────────────────────
local hubToggles = {
    AutoFarm  = true,
    NoClip    = false,
    AutoRaid  = false,
    AutoHaki  = false,
    AutoCodes = false,
}

-- ─── misc globals ──────────────────────────────────────────────────────────
local isDead           = false
local respawnCooldown  = 5
local lastPosition     = nil
local lastMoveTime     = tick()
local lastRaidTime     = 0
local hasTeleportedToSky = false
local sudahUnlockSea2  = isSecondSea or isThirdSea
local sudahMasuk       = false
local sudahTeleportMole= false

-- ─── colour palette ────────────────────────────────────────────────────────
local C = {
    BG        = Color3.fromRGB(8,  25,  8),
    Accent    = Color3.fromRGB(50, 205, 50),
    AccentDim = Color3.fromRGB(25, 110, 25),
    Text      = Color3.fromRGB(210, 255, 210),
    TopBar    = Color3.fromRGB(15,  45,  15),
    DarkPanel = Color3.fromRGB(12,  38,  12),
    ToggleOn  = Color3.fromRGB(50,  205, 50),
    ToggleOff = Color3.fromRGB(30,  65,  30),
    Border    = Color3.fromRGB(40,  140, 40),
    TabActive = Color3.fromRGB(30, 140, 30),
    TabIdle   = Color3.fromRGB(15,  55,  15),
    BtnBG     = Color3.fromRGB(20,  90,  20),
}

-- ─── notification ─────────────────────────────────────────────────────────
local function notify(title, text)
    pcall(function()
        local old = pgui:FindFirstChild("PlungNotif")
        if old then old:Destroy() end
        local sg = Instance.new("ScreenGui")
        sg.Name = "PlungNotif"; sg.ResetOnSpawn = false; sg.Parent = pgui
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,280,0,48)
        f.Position = UDim2.new(0.5,-140,0,10)
        f.BackgroundColor3 = Color3.fromRGB(10,45,10)
        f.BackgroundTransparency = 0.2
        f.BorderSizePixel = 0; f.Parent = sg
        Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)
        local t = Instance.new("TextLabel",f)
        t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1
        t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.GothamBold
        t.TextSize = 14; t.Text = title.." — "..text
        task.delay(4, function() pcall(function() sg:Destroy() end) end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  PLUNG ICON  (draggable, tap = toggle window)
-- ════════════════════════════════════════════════════════════════════════════
local iconSG = Instance.new("ScreenGui")
iconSG.Name = "PlungIcon"; iconSG.ResetOnSpawn = false
iconSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
iconSG.Parent = pgui

local iconFrame = Instance.new("Frame")
iconFrame.Size = UDim2.new(0,100,0,50)
iconFrame.Position = UDim2.new(0,20,0.5,-25)
iconFrame.BackgroundColor3 = Color3.fromRGB(10,40,10)
iconFrame.BorderSizePixel = 0
iconFrame.Parent = iconSG

Instance.new("UICorner",iconFrame).CornerRadius = UDim.new(0,10)

do
    local gr = Instance.new("UIGradient",iconFrame)
    gr.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,120,20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 30, 5)),
    }
    gr.Rotation = 135
end

local iconStroke = Instance.new("UIStroke",iconFrame)
iconStroke.Color = Color3.fromRGB(50,200,50)
iconStroke.Thickness = 2

-- inner black border rect
local innerBorder = Instance.new("Frame",iconFrame)
innerBorder.Size = UDim2.new(1,-8,1,-8)
innerBorder.Position = UDim2.new(0,4,0,4)
innerBorder.BackgroundTransparency = 1
innerBorder.BorderSizePixel = 0
Instance.new("UICorner",innerBorder).CornerRadius = UDim.new(0,6)
local innerStroke = Instance.new("UIStroke",innerBorder)
innerStroke.Color = Color3.fromRGB(0,0,0)
innerStroke.Thickness = 2

local iconLabel = Instance.new("TextLabel",iconFrame)
iconLabel.Size = UDim2.new(1,0,1,0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "Plung"
iconLabel.TextColor3 = Color3.fromRGB(255,255,255)
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextSize = 18
iconLabel.TextXAlignment = Enum.TextXAlignment.Center

-- drag logic
local iconDragging = false
local iconDragStart, iconStartPos
local iconMoved = false

iconFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        iconDragging  = true
        iconMoved     = false
        iconDragStart = inp.Position
        iconStartPos  = iconFrame.Position
    end
end)

iconFrame.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        iconDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if iconDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - iconDragStart
        if delta.Magnitude > 3 then iconMoved = true end
        iconFrame.Position = UDim2.new(
            iconStartPos.X.Scale,
            iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale,
            iconStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  HUB WINDOW
-- ════════════════════════════════════════════════════════════════════════════
local hubSG = Instance.new("ScreenGui")
hubSG.Name = "PlungHub"; hubSG.ResetOnSpawn = false
hubSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hubSG.Parent = pgui

local hubWindow = Instance.new("Frame")
hubWindow.Name = "HubWindow"
hubWindow.Size = UDim2.new(0,340,0,480)
hubWindow.Position = UDim2.new(0.5,-170,0.5,-240)
hubWindow.BackgroundColor3 = C.BG
hubWindow.BorderSizePixel = 0
hubWindow.Visible = false
hubWindow.Parent = hubSG

Instance.new("UICorner",hubWindow).CornerRadius = UDim.new(0,12)
local hubStroke = Instance.new("UIStroke",hubWindow)
hubStroke.Color = C.Border; hubStroke.Thickness = 2

-- top bar (drag handle)
local topBar = Instance.new("Frame",hubWindow)
topBar.Size = UDim2.new(1,0,0,36)
topBar.BackgroundColor3 = C.TopBar
topBar.BorderSizePixel = 0
Instance.new("UICorner",topBar).CornerRadius = UDim.new(0,12)

local titleLbl = Instance.new("TextLabel",topBar)
titleLbl.Size = UDim2.new(1,-40,1,0)
titleLbl.Position = UDim2.new(0,10,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🌿 Plung Hub"
titleLbl.TextColor3 = C.Accent
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton",topBar)
closeBtn.Size = UDim2.new(0,28,0,28)
closeBtn.Position = UDim2.new(1,-34,0,4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,30,30)
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner",closeBtn).CornerRadius = UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function() hubWindow.Visible = false end)

-- window drag
local winDragging = false
local winDragStart, winStartPos
topBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        winDragging = true
        winDragStart = inp.Position
        winStartPos  = hubWindow.Position
    end
end)
topBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        winDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if winDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - winDragStart
        hubWindow.Position = UDim2.new(
            winStartPos.X.Scale, winStartPos.X.Offset + delta.X,
            winStartPos.Y.Scale, winStartPos.Y.Offset + delta.Y
        )
    end
end)

-- tap icon to toggle window
iconFrame.InputEnded:Connect(function(inp)
    if (inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch) and not iconMoved then
        hubWindow.Visible = not hubWindow.Visible
    end
end)

-- ─── tab bar ────────────────────────────────────────────────────────────────
local TAB_NAMES = {"Home","Farm","Misc","Settings"}

local tabBar = Instance.new("Frame",hubWindow)
tabBar.Size = UDim2.new(1,0,0,32)
tabBar.Position = UDim2.new(0,0,0,36)
tabBar.BackgroundColor3 = C.DarkPanel
tabBar.BorderSizePixel = 0
local tabLayout = Instance.new("UIListLayout",tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- scroll area for tab panels
local scrollFrame = Instance.new("ScrollingFrame",hubWindow)
scrollFrame.Size = UDim2.new(1,0,1,-68)
scrollFrame.Position = UDim2.new(0,0,0,68)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = C.Accent
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)

-- panels table
local panels = {}
local tabBtns = {}

local function switchTab(name)
    for _, n in ipairs(TAB_NAMES) do
        if panels[n] then panels[n].Visible = (n == name) end
        if tabBtns[n] then
            tabBtns[n].BackgroundColor3 = (n == name) and C.TabActive or C.TabIdle
        end
    end
end

-- make tab buttons
for i, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton",tabBar)
    btn.Size = UDim2.new(1/#TAB_NAMES,0,1,0)
    btn.BackgroundColor3 = C.TabIdle
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = C.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.LayoutOrder = i
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)
    tabBtns[name] = btn
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- make panels
for _, name in ipairs(TAB_NAMES) do
    local p = Instance.new("Frame",scrollFrame)
    p.Name = name
    p.Size = UDim2.new(1,0,1,0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.Visible = false
    local layout = Instance.new("UIListLayout",p)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    local pad = Instance.new("UIPadding",p)
    pad.PaddingLeft = UDim.new(0,8)
    pad.PaddingRight = UDim.new(0,8)
    pad.PaddingTop = UDim.new(0,6)
    panels[name] = p
end

-- auto-resize canvas
local function updateCanvas()
    for _, name in ipairs(TAB_NAMES) do
        if panels[name] and panels[name].Visible then
            local layout = panels[name]:FindFirstChildOfClass("UIListLayout")
            if layout then
                scrollFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
            end
        end
    end
end
RunService.Heartbeat:Connect(updateCanvas)

-- ─── UI helpers ─────────────────────────────────────────────────────────────
local rowCount = {}
local function nextOrder(panelName)
    rowCount[panelName] = (rowCount[panelName] or 0) + 1
    return rowCount[panelName]
end

local function addLabel(panelName, text)
    local p = panels[panelName]
    local f = Instance.new("Frame",p)
    f.Size = UDim2.new(1,-16,0,22)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.LayoutOrder = nextOrder(panelName)
    local t = Instance.new("TextLabel",f)
    t.Size = UDim2.new(1,0,1,0)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = C.AccentDim
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
end

local function addRow(panelName, label, flagKey, onChange)
    local p = panels[panelName]
    local row = Instance.new("Frame",p)
    row.Size = UDim2.new(1,-16,0,36)
    row.BackgroundColor3 = C.DarkPanel
    row.BorderSizePixel = 0
    row.LayoutOrder = nextOrder(panelName)
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel",row)
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local tog = Instance.new("TextButton",row)
    tog.Size = UDim2.new(0,50,0,24)
    tog.Position = UDim2.new(1,-58,0.5,-12)
    local state = hubToggles[flagKey] ~= nil and hubToggles[flagKey] or false
    tog.BackgroundColor3 = state and C.ToggleOn or C.ToggleOff
    tog.Text = state and "ON" or "OFF"
    tog.TextColor3 = Color3.new(1,1,1)
    tog.Font = Enum.Font.GothamBold
    tog.TextSize = 12
    tog.BorderSizePixel = 0
    Instance.new("UICorner",tog).CornerRadius = UDim.new(0,6)

    tog.MouseButton1Click:Connect(function()
        state = not state
        hubToggles[flagKey] = state
        tog.BackgroundColor3 = state and C.ToggleOn or C.ToggleOff
        tog.Text = state and "ON" or "OFF"
        if onChange then onChange(state) end
    end)
    return tog
end

local function addBtn(panelName, label, onClick)
    local p = panels[panelName]
    local btn = Instance.new("TextButton",p)
    btn.Size = UDim2.new(1,-16,0,34)
    btn.BackgroundColor3 = C.BtnBG
    btn.Text = label
    btn.TextColor3 = C.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.LayoutOrder = nextOrder(panelName)
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(function() pcall(onClick) end)
    return btn
end

-- ════════════════════════════════════════════════════════════════════════════
--  TAB: HOME
-- ════════════════════════════════════════════════════════════════════════════
addLabel("Home", "— Status —")
addRow("Home", "AutoFarm", "AutoFarm")
addRow("Home", "NoClip",   "NoClip")
addRow("Home", "AutoRaid", "AutoRaid")
addRow("Home", "AutoHaki", "AutoHaki")
addRow("Home", "AutoCodes","AutoCodes", function(on)
    if on then pcall(function() redeemCodes() end) end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  TAB: FARM
-- ════════════════════════════════════════════════════════════════════════════
addLabel("Farm", "— Auto Farming —")
addRow("Farm","AutoFarm","AutoFarm")
addRow("Farm","AutoRaid","AutoRaid")

addLabel("Farm","— Manual Teleport —")
addBtn("Farm","TP to Quest NPC", function()
    if hrp then hrp.CFrame = CFrame.new(1058.99, 16.13, 1551.73) end
end)
addBtn("Farm","TP to Raid Island", function()
    if hrp then
        local ok, cf = pcall(function()
            return workspace.Map.CircleIsland.RaidSummon.Button.Main.CFrame
        end)
        if ok then hrp.CFrame = cf + Vector3.new(0,5,0) end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  TAB: MISC
-- ════════════════════════════════════════════════════════════════════════════
addLabel("Misc","— Player Mods —")
addRow("Misc","AutoHaki","AutoHaki")
addRow("Misc","AutoCodes","AutoCodes", function(on)
    if on then pcall(function() redeemCodes() end) end
end)
addRow("Misc","NoClip","NoClip")

addLabel("Misc","— Actions —")
addBtn("Misc","Redeem Codes Now", function()
    pcall(function() redeemCodes() end)
    notify("Plung","Codes redeemed!")
end)
addBtn("Misc","Equip Best Fighting Style", function()
    pcall(function() equipBestFightingStyle() end)
    notify("Plung","Fighting style equipped!")
end)
addBtn("Misc","Buy Buso Haki", function()
    pcall(function() beliBusoHaki() end)
    notify("Plung","Buso purchased!")
end)
addBtn("Misc","Activate Buso", function()
    pcall(function() activateBuso() end)
    notify("Plung","Buso activated!")
end)

-- ════════════════════════════════════════════════════════════════════════════
--  TAB: SETTINGS
-- ════════════════════════════════════════════════════════════════════════════
addLabel("Settings","— About —")
do
    local p = panels["Settings"]
    local f = Instance.new("Frame",p)
    f.Size = UDim2.new(1,-16,0,60)
    f.BackgroundColor3 = C.DarkPanel
    f.BorderSizePixel = 0
    f.LayoutOrder = nextOrder("Settings")
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)
    local t = Instance.new("TextLabel",f)
    t.Size = UDim2.new(1,-8,1,0)
    t.Position = UDim2.new(0,4,0,0)
    t.BackgroundTransparency = 1
    t.Text = "Plung Hub v3.0\nFull AutoFarm Engine"
    t.TextColor3 = C.Text
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.TextWrapped = true
end

addBtn("Settings","Hide Window", function()
    hubWindow.Visible = false
end)

-- start on Home tab
switchTab("Home")

-- ════════════════════════════════════════════════════════════════════════════
--  MOD LOGIC FROM ae2b6e3c-plung_hub.luau
-- ════════════════════════════════════════════════════════════════════════════

-- NoClip
RunService.Stepped:Connect(function()
    if hubToggles.NoClip and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- tweenTo using BodyVelocity
local function tweenTo(cframe)
    if not hrp then return end
    local humanoidRef = character and character:FindFirstChildOfClass("Humanoid")
    local originalSpeed = humanoidRef and humanoidRef.WalkSpeed or 16
    if humanoidRef then
        humanoidRef.AutoRotate = false
        humanoidRef.WalkSpeed  = 0
    end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Velocity  = Vector3.zero
    bv.Parent    = hrp

    local reached   = false
    local connection
    local targetPos = cframe.Position + Vector3.new(0,5,0)

    connection = RunService.Heartbeat:Connect(function()
        if not hrp then connection:Disconnect(); return end
        local dist = (hrp.Position - targetPos).Magnitude
        if dist < 1 then
            reached = true
            bv.Velocity = Vector3.zero
            connection:Disconnect()
        else
            bv.Velocity = (targetPos - hrp.Position).Unit * 325
        end
    end)

    repeat task.wait() until reached
    bv:Destroy()
    if humanoidRef then
        humanoidRef.AutoRotate = true
        humanoidRef.WalkSpeed  = originalSpeed
    end
end

-- Combat helpers
local function cariMusuh(namaMusuh)
    local folder = workspace:FindFirstChild("Enemies")
    if not folder then return nil end
    for _, enemy in pairs(folder:GetChildren()) do
        if enemy.Name:lower():find(namaMusuh:lower())
        and enemy:FindFirstChild("Humanoid")
        and enemy.Humanoid.Health > 0 then
            return enemy
        end
    end
    return nil
end

local function tarikSemuaMusuh()
    if not hrp then return end
    local folder = workspace:FindFirstChild("Enemies")
    if not folder then return end
    local targetPos = hrp.Position - Vector3.new(0,30,0)
    for _, enemy in pairs(folder:GetChildren()) do
        local eHRP = enemy:FindFirstChild("HumanoidRootPart")
        if eHRP then
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e5,1e5,1e5)
            bp.Position = targetPos
            bp.P = 3000; bp.D = 100
            bp.Parent = eHRP
            task.delay(2, function()
                if bp and bp.Parent then bp:Destroy() end
            end)
        end
    end
end

local function serangMusuh(enemy, onKilled)
    local enemyHead = enemy:FindFirstChild("Head")
    local hum2      = enemy:FindFirstChild("Humanoid")
    if not (enemyHead and hum2) then return end
    tarikSemuaMusuh()
    local targetPos   = enemyHead.Position + Vector3.new(0,50,0)
    local targetCF    = CFrame.new(targetPos) * CFrame.Angles(0, hrp and hrp.CFrame.Rotation.Y or 0, 0)
    tweenTo(targetCF)
    task.wait(0.01)
    local diedConn
    diedConn = hum2.Died:Connect(function()
        diedConn:Disconnect()
        if onKilled then onKilled() end
    end)
    while enemy and hum2.Health > 0 do
        if not hrp then break end
        local newPos = enemyHead.Position + Vector3.new(0,30,0)
        hrp.CFrame = CFrame.new(newPos) * CFrame.Angles(0, hrp.CFrame.Rotation.Y, 0)
        pcall(function()
            ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer(0.5)
            local tp = enemy:FindFirstChild("Head")
            if tp then
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(tp,{},nil,"40763608")
            end
        end)
        task.wait(0.01)
    end
end

-- Codes
local REDEEM_CODES = {
    "fudd10","fudd10_V2","Chandler","BIGNEWS","KITT_RESET","Sub2UncleKizaru",
    "SUB2GAMERROBOT_RESET1","Sub2Fer999","Enyu_is_Pro","JCWK","StarcodeHEO",
    "MagicBUS","KittGaming","Sub2CaptainMaui","Sub2OfficialNoobie","TheGreatAce",
    "Sub2NoobMaster123","Sub2Daigrock","Axiore","StrawHatMaine","TantaiGaming",
    "Bluxxy","SUB2GAMERROBOT_EXP1"
}

function redeemCodes()
    for _, code in ipairs(REDEEM_CODES) do
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Redeem", code)
        end)
        task.wait(0.2)
    end
end

-- Fruit values
local fruitValues = {
    ["Spin-Spin"]=7500,["Chop-Chop"]=8000,["Spring-Spring"]=9000,
    ["Bomb-Bomb"]=15000,["Smoke-Smoke"]=28000,["Spike-Spike"]=30000,
    ["Flame-Flame"]=250000,["Ice-Ice"]=350000,["Sand-Sand"]=420000,
    ["Quake-Quake"]=1000000,["Dark-Dark"]=500000,["Light-Light"]=650000,
    ["String-String"]=1500000,["Magma-Magma"]=850000,["Rubber-Rubber"]=750000,
    ["Barrier-Barrier"]=800000,["Paw-Paw"]=2300000,["Phoenix-Phoenix"]=1800000,
    ["Revive-Revive"]=550000,["Buddha-Buddha"]=1200000,["Love-Love"]=1200000,
    ["Spider-Spider"]=1500000,["Bird-Bird: Phoenix"]=1800000,["Leopard-Leopard"]=5000000,
    ["Mammoth-Mammoth"]=2700000,["Dough-Dough"]=2800000,["Shadow-Shadow"]=2900000,
    ["Venom-Venom"]=3000000,["Control-Control"]=3200000,["Soul-Soul"]=3300000,
    ["Dragon-Dragon"]=3500000,["Ghost-Ghost"]=1300000,["Gravity-Gravity"]=2500000,
    ["Kitsune-Kitsune"]=8000000
}

local function getFruitValue(name)
    return fruitValues[name] or 0
end

-- Raid island CFrames
local function getIslandCFrames()
    local islands = {}
    pcall(function()
        for _, child in pairs(workspace.Map.CircleIsland:GetChildren()) do
            if child:IsA("BasePart") or child:IsA("Model") then
                local cf = child:IsA("Model") and child:GetPivot() or child.CFrame
                table.insert(islands, cf)
            end
        end
    end)
    return islands
end

-- Haki helpers
function beliBusoHaki()
    local data = lp:FindFirstChild("Data")
    if data and data:FindFirstChild("Beli") and data.Beli.Value >= 25000 then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki","Buso")
        end)
    end
end

function activateBuso()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end)
end

-- Auto haki heartbeat
RunService.Heartbeat:Connect(function()
    if hubToggles.AutoHaki then
        pcall(activateBuso)
    end
end)

-- Stat auto upgrade
local function tambahStatOtomatis()
    while true do
        pcall(function()
            local stats = lp:FindFirstChild("Data") and lp.Data:FindFirstChild("Stats")
            if not stats then return end
            local melee   = stats:FindFirstChild("Melee")
            local defense = stats:FindFirstChild("Defense")
            if not (melee and defense) then return end
            local mLvl = melee:FindFirstChild("Level")
            local dLvl = defense:FindFirstChild("Level")
            if not (mLvl and dLvl) then return end
            if mLvl.Value >= 200 and dLvl.Value < mLvl.Value - 100 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint","Defense",50)
            else
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint","Melee",50)
            end
        end)
        task.wait(0.5)
    end
end

-- Fighting styles
local fightingStyles = {
    {name="Dark Step",       path="Black Leg",    buyFunction=function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg") end},
    {name="Electro",         path="Electro",      buyFunction=function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro") end},
    {name="Fishman Karate",  path="Fishman Karate",buyFunction=function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate") end},
    {name="Dragon Breath",   path="Dragon Breath",buyFunction=function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward","DragonClaw","1") end},
    {name="Superhuman",      path="Superhuman",   buyFunction=function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman") end},
}

local function autoBuyFightingStyles()
    for i = #fightingStyles, 1, -1 do
        local s = fightingStyles[i]
        local ok = pcall(s.buyFunction)
        if ok and (lp.Backpack:FindFirstChild(s.path) or (lp.Character and lp.Character:FindFirstChild(s.path))) then
            break
        end
    end
end

function equipBestFightingStyle()
    pcall(autoBuyFightingStyles)
    local priority = {"Superhuman","Dragon Breath","Fishman Karate","Electro","Black Leg","Combat"}
    for _, sName in ipairs(priority) do
        local style = lp.Backpack:FindFirstChild(sName) or (lp.Character and lp.Character:FindFirstChild(sName))
        if style then
            style.Parent = lp.Character
            return
        end
    end
end

-- Quest locations
local questLocations = {
    banditQuest           = CFrame.new(1058.99,16.13,1551.73),
    spawnBandit           = CFrame.new(974.83,16.66,1549.89),
    adventurerQuest       = CFrame.new(-1598.08,35.55,153.37),
    spawnMonkey           = CFrame.new(-1812.14,23.16,175.78),
    spawnGorilla          = CFrame.new(-1277.40,6.53,-525.15),
    spawnGorillaKing      = CFrame.new(-1091.20,6.71,-534.32),
    pirateQuest           = CFrame.new(-1141.07,4.10,3831.55),
    spawnPirate           = CFrame.new(-1183.90,5.06,3865.84),
    spawnBrute            = CFrame.new(-1265.14,15.18,4235.27),
    spawnChef             = CFrame.new(-1129.82,31.92,4103.30),
    DesertAdventurerQuest = CFrame.new(894.48,5.13,4392.43),
    spawnDesertBandit     = CFrame.new(937.16,6.81,4480.01),
    spawnDesertOfficer    = CFrame.new(1541.38,14.81,4388.90),
    villagerQuest         = CFrame.new(1387.18,86.62,-1295.04),
    spawnSnowBandit       = CFrame.new(1393.68,87.63,-1432.66),
    spawnSnowman          = CFrame.new(1199.26,106.14,-1439.76),
    spawnYeti             = CFrame.new(1150.20,106.60,-1511.29),
    marineQuest           = CFrame.new(-5039.58,27.35,4324.68),
    spawnChiefPetty       = CFrame.new(-4889.86,21.01,4083.02),
    spawnViceAdmiral      = CFrame.new(-5086.47,99.68,4406.73),
    skyadventurerQuest    = CFrame.new(-4839.52,716.36,-2619.44),
    spawnSkyBandit        = CFrame.new(-4940.17,278.10,-2841.86),
    spawnDarkMaster       = CFrame.new(-5229.21,388.68,-2251.19),
    jailkeeperQuest       = CFrame.new(5310.60,0.35,474.94),
    spawnPrisoner         = CFrame.new(5215.87,1.66,377.90),
    spawnDangerousPrisoner= CFrame.new(5060.83,1.68,1036.71),
    colosseumQuest        = CFrame.new(-1580.04,6.35,-2986.47),
    spawnToga             = CFrame.new(-1758.77,7.47,-2778.88),
    spawnGladiator        = CFrame.new(-1336.29,7.40,-3518.02),
    themayorQuest         = CFrame.new(-5313.37,10.94,8515.29),
    spawnMilitarySoldier  = CFrame.new(-5580.53,8.90,8438.72),
    spawnMilitarySpy      = CFrame.new(-5832.50,77.56,8897.02),
    spawnMagmaAdmiral     = CFrame.new(-5693.84,17.74,8744.93),
    kingneptuneQuest      = CFrame.new(61121.10,17.95,1564.52),
    spawnFishmanWarrior   = CFrame.new(60840.90,17.16,1301.12),
    spawnFishmanCommando  = CFrame.new(61858.90,17.33,1695.12),
    spawnFishmanLord      = CFrame.new(61352.90,32.35,1029.12),
    moleQuestindex1       = CFrame.new(-4721.88,843.87,-1949.96),
    moleQuestindex2dan3   = CFrame.new(-7859.09,5544.18,-381.47),
    spawnGodGuard         = CFrame.new(-4700.31,842.97,-1792.79),
    spawnShanda           = CFrame.new(-7710.76,5544.19,-336.44),
    spawnWysper           = CFrame.new(-7995.29,5544.76,-709.27),
    skyquestgiver2        = CFrame.new(-7904.68,5634.66,-1409.96),
    spawnRoyalSquad       = CFrame.new(-7513.94,5605.57,-1421.01),
    spawnRoyalSoldier     = CFrame.new(-7946.94,5606.22,-1824.01),
    spawnThunderGod       = CFrame.new(-7779.26,5606.93,-2421.94),
    freezeburgQuest       = CFrame.new(5259.81,37.35,4050.02),
    spawnGalleyPirate     = CFrame.new(5838.07,37.36,3914.32),
    spawnGalleyCaptain    = CFrame.new(5792.35,58.93,4823.92),
    spawnCyborg           = CFrame.new(6216.62,8.33,3990.00),
    pintuMasukKingNeptune = CFrame.new(4050.31,-1.68,-1814.12),
    pintuKeluarKingNeptune= CFrame.new(61170.04,-2,1952.83),
    area1QuestGiver       = CFrame.new(-429.54,71.77,1836.18),
    spawnRaider           = CFrame.new(-700.49,39.45,2289.63),
    spawnMercenary        = CFrame.new(-1042.69,73.27,1443.08),
    spawnDiamond          = CFrame.new(-1711.37,199.23,-97.08),
    area2QuestGiver       = CFrame.new(638.44,71.77,918.23),
    spawnSwanPirate       = CFrame.new(1029.53,73.38,1128.61),
    spawnFactory          = CFrame.new(-198.38,73.27,-655.22),
    spawnJeremy           = CFrame.new(2352.56,449.24,645.60),
    marineQuestGiver      = CFrame.new(-2440.79,71.71,-3216.06),
    spawnMarineLieutenant = CFrame.new(-2868.32,73.28,-2987.87),
    spawnMarineCaptain    = CFrame.new(-1762.54,100.59,-3173.36),
    spawnOrbitus          = CFrame.new(-2087.04,73.29,-4170.99),
    graveyardQuestGiver   = CFrame.new(-5497.06,47.59,-795.23),
    spawnZombie           = CFrame.new(-5614.95,47.35,-938.46),
    spawnVampire          = CFrame.new(-5952.99,5.27,-1568.52),
    snowQuestGiver        = CFrame.new(609.85,400.11,-5372.25),
    spawnSnowTrooper      = CFrame.new(642.66,400.29,-5454.49),
    spawnWinterWarrior    = CFrame.new(1446.27,428.29,-5369.21),
    iceQuestGiver         = CFrame.new(-6064.06,15.24,-4902.97),
    spawnLab              = CFrame.new(-5640.38,14.82,-4680.93),
    spawnHorned           = CFrame.new(-6398.37,28.42,-5866.41),
    spawnSmokeAdmiral     = CFrame.new(-5019.80,22.96,-5370.59),
    fireQuestGiver        = CFrame.new(-5428.03,15.06,-5299.43),
    spawnMagmaNinja       = CFrame.new(-5203.04,23.13,-6196.55),
    spawnLavaPirate       = CFrame.new(-5265.24,14.82,-4341.92),
    rearQuestGiver        = CFrame.new(1040.55,124.94,32909.10),
    spawnShipDeck         = CFrame.new(580.31,123.93,33124.26),
    spawnShipEngineer     = CFrame.new(1025.65,38.93,32740.85),
    FrontQuestGiver       = CFrame.new(974.07,124.95,33253.62),
    spawnShipSteward      = CFrame.new(801.37,124.05,33505.17),
    spawnShipOfficer      = CFrame.new(1144.53,179.93,33112.60),
    FrostQuestGiver       = CFrame.new(5667.65,26.80,-6486.08),
    spawnArcticWarrior    = CFrame.new(6271.31,26.88,-6151.53),
    spawnSnowLurker       = CFrame.new(5763.84,27.16,-6671.04),
    spawnAwakenedIceAdmiral=CFrame.new(6551.79,320.82,-6989.89),
    forgottenQuestGiver   = CFrame.new(-3054.44,238.34,-10142.81),
    spawnSeaSoldier       = CFrame.new(-2550.92,25.84,-9839.99),
    spawnWaterFighter     = CFrame.new(-3331.70,237.71,-10553.35),
    spawnTideKeeper       = CFrame.new(-3795.94,76.52,-11581.78),
}

local questSpawns = {
    ["Toga Warrior"] = {
        questLocations.spawnToga,
        CFrame.new(-2020.10,7.60,-2700.86),
        CFrame.new(-2089.38,7.75,-2849.77),
    },
    ["Gladiator"] = {
        questLocations.spawnGladiator,
        CFrame.new(-1446.98,7.75,-3185.14),
        CFrame.new(-1117.43,7.60,-3286.27),
    },
    ["Raider"] = {
        questLocations.spawnRaider,
        CFrame.new(-701.98,39.45,2358.73),
        CFrame.new(311.72,39.45,2295.78),
    },
    ["Mercenary"] = {
        questLocations.spawnMercenary,
        CFrame.new(-932.05,73.27,1659.31),
        CFrame.new(-1103.93,73.27,1174.63),
    },
    ["Factory"] = {
        questLocations.spawnFactory,
        CFrame.new(-198.38,73.27,-655.22),
        CFrame.new(-250.74,73.27,-52.81),
    },
}

-- Quest functions
local function ambilQuest(questGiverCF, questName, index, spawnCF)
    tweenTo(questGiverCF)
    task.wait(0.01)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", questName, index)
    end)
    if spawnCF then tweenTo(spawnCF) end
end

local function ambilQuestBandit()       ambilQuest(questLocations.banditQuest,      "BanditQuest1",    1, questLocations.spawnBandit) end
local function ambilQuestAdventurer(i)
    local spawns = {questLocations.spawnMonkey, questLocations.spawnGorilla, questLocations.spawnGorillaKing}
    ambilQuest(questLocations.adventurerQuest, "JungleQuest", i, spawns[i])
end
local function ambilQuestPirate(i)
    local spawns = {questLocations.spawnPirate, questLocations.spawnBrute, questLocations.spawnChef}
    ambilQuest(questLocations.pirateQuest, "BuggyQuest1", i, spawns[i])
end
local function ambilQuestDesert(i)
    local spawns = {questLocations.spawnDesertBandit, questLocations.spawnDesertOfficer}
    ambilQuest(questLocations.DesertAdventurerQuest, "DesertQuest", i, spawns[i])
end
local function ambilQuestVillager(i)
    local spawns = {questLocations.spawnSnowBandit, questLocations.spawnSnowman, questLocations.spawnYeti}
    ambilQuest(questLocations.villagerQuest, "SnowQuest", i, spawns[i])
end
local function ambilQuestMarine(i)
    local spawns = {questLocations.spawnChiefPetty, questLocations.spawnViceAdmiral}
    ambilQuest(questLocations.marineQuest, "MarineQuest2", i, spawns[i])
end
local function ambilQuestSkyAdventurer(i)
    local spawns = {questLocations.spawnSkyBandit, questLocations.spawnDarkMaster}
    ambilQuest(questLocations.skyadventurerQuest, "SkyQuest", i, spawns[i])
end
local function ambilQuestJailKeeper(i)
    local spawns = {questLocations.spawnPrisoner, questLocations.spawnDangerousPrisoner}
    ambilQuest(questLocations.jailkeeperQuest, "PrisonerQuest", i, spawns[i])
end
local function ambilQuestColosseum(i)
    local spawns = {questLocations.spawnToga, questLocations.spawnGladiator}
    ambilQuest(questLocations.colosseumQuest, "ColosseumQuest", i, spawns[i])
end
local function ambilQuestTheMayor(i)
    local spawns = {questLocations.spawnMilitarySoldier, questLocations.spawnMilitarySpy, questLocations.spawnMagmaAdmiral}
    ambilQuest(questLocations.themayorQuest, "MagmaQuest", i, spawns[i])
end
local function ambilQuestKingNeptune(i)
    if not sudahMasuk then
        tweenTo(questLocations.pintuMasukKingNeptune)
        task.wait(1.5)
        sudahMasuk = true
    end
    local spawns = {questLocations.spawnFishmanWarrior, questLocations.spawnFishmanCommando, questLocations.spawnFishmanLord}
    ambilQuest(questLocations.kingneptuneQuest, "FishmanQuest", i, spawns[i])
end
local function ambilQuestMole(i)
    local level = lp:WaitForChild("Data"):WaitForChild("Level").Value
    if level >= 450 and not hasTeleportedToSky then
        pcall(function()
            local cf = workspace.Map.SkyArea1:GetChildren()[13].CFrame
            hrp.CFrame = cf + Vector3.new(0,5,0)
        end)
        hasTeleportedToSky = true
        task.wait(1)
    end
    local giver = (i == 1) and questLocations.moleQuestindex1 or questLocations.moleQuestindex2dan3
    tweenTo(giver); task.wait(0.01)
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest","SkyExp1Quest",i) end)
    local spawns = {questLocations.spawnGodGuard, questLocations.spawnShanda, questLocations.spawnWysper}
    if spawns[i] then tweenTo(spawns[i]) end
end
local function ambilQuestSky2(i)
    local spawns = {questLocations.spawnRoyalSquad, questLocations.spawnRoyalSoldier, questLocations.spawnThunderGod}
    ambilQuest(questLocations.skyquestgiver2, "SkyExp2Quest", i, spawns[i])
end
local function ambilQuestFreezeburg(i)
    local spawns = {questLocations.spawnGalleyPirate, questLocations.spawnGalleyCaptain, questLocations.spawnCyborg}
    ambilQuest(questLocations.freezeburgQuest, "FountainQuest", i, spawns[i])
end
local function ambilQuestArea1Giver(i)
    local spawns = {questLocations.spawnRaider, questLocations.spawnMercenary, questLocations.spawnDiamond}
    ambilQuest(questLocations.area1QuestGiver, "Area1Quest", i, spawns[i])
end
local function ambilQuestArea2Giver(i)
    local spawns = {questLocations.spawnSwanPirate, questLocations.spawnFactory, questLocations.spawnJeremy}
    ambilQuest(questLocations.area2QuestGiver, "Area2Quest", i, spawns[i])
end
local function ambilQuestMarineGiver(i)
    local spawns = {questLocations.spawnMarineLieutenant, questLocations.spawnMarineCaptain, questLocations.spawnOrbitus}
    ambilQuest(questLocations.marineQuestGiver, "MarineQuest3", i, spawns[i])
end
local function ambilQuestGraveyard(i)
    local spawns = {questLocations.spawnZombie, questLocations.spawnVampire}
    ambilQuest(questLocations.graveyardQuestGiver, "ZombieQuest", i, spawns[i])
end
local function ambilQuestSnow(i)
    local spawns = {questLocations.spawnSnowTrooper, questLocations.spawnWinterWarrior}
    ambilQuest(questLocations.snowQuestGiver, "SnowMountainQuest", i, spawns[i])
end
local function ambilQuestIce(i)
    local spawns = {questLocations.spawnLab, questLocations.spawnHorned, questLocations.spawnSmokeAdmiral}
    ambilQuest(questLocations.iceQuestGiver, "IceSideQuest", i, spawns[i])
end
local function ambilQuestFire(i)
    local spawns = {questLocations.spawnMagmaNinja, questLocations.spawnLavaPirate}
    ambilQuest(questLocations.fireQuestGiver, "FireSideQuest", i, spawns[i])
end
local function ambilQuestRearCrew(i)
    local spawns = {questLocations.spawnShipDeck, questLocations.spawnShipEngineer}
    ambilQuest(questLocations.rearQuestGiver, " ShipQuest1", i, spawns[i])
end
local function ambilQuestFrontCrew(i)
    local spawns = {questLocations.spawnShipSteward, questLocations.spawnShipOfficer}
    ambilQuest(questLocations.FrontQuestGiver, "ShipQuest2", i, spawns[i])
end
local function ambilQuestFrost(i)
    local spawns = {questLocations.spawnArcticWarrior, questLocations.spawnSnowLurker, questLocations.spawnAwakenedIceAdmiral}
    ambilQuest(questLocations.FrostQuestGiver, "FrostQuest", i, spawns[i])
end
local function ambilQuestForgotten(i)
    local spawns = {questLocations.spawnSeaSoldier, questLocations.spawnWaterFighter, questLocations.spawnTideKeeper}
    ambilQuest(questLocations.forgottenQuestGiver, "ForgottenQuest", i, spawns[i])
end

-- Quest active check
local function isQuestActive()
    local ok, result = pcall(function()
        return lp.PlayerGui.Main.Quest.Visible
    end)
    return ok and result
end

-- Check if player has item
local function memilikiItem(namaItem)
    local ok, result = pcall(function()
        return ReplicatedStorage.Modules.Net["RF/ReadPlayerData"]:InvokeServer()
    end)
    if ok and result and result.Items then
        return result.Items[namaItem] == true
    end
    return false
end

-- Fruit helpers
local function getLowValueFruit()
    for _, item in pairs(lp.Backpack:GetChildren()) do
        local v = fruitValues[item.Name]
        if v and v < 1000000 then return item.Name end
    end
    return nil
end

-- AutoRaid
local function autoRaid()
    local fruitName = getLowValueFruit()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc","Select", fruitName or "Flame")
    end)
    task.wait(1)
    pcall(function()
        local det = workspace.Map.CircleIsland.RaidSummon.Button.Main:FindFirstChild("ClickDetector")
        if det then fireclickdetector(det) end
    end)
    local islandCFrames = getIslandCFrames()
    for i, iCF in ipairs(islandCFrames) do
        tweenTo(iCF)
        while true do
            local enemy = cariMusuh("")
            if enemy then
                serangMusuh(enemy)
                task.wait(0.5)
            else
                break
            end
        end
    end
end

-- Factory Staff
local function farmingFactoryStaff()
    ambilQuestArea2Giver(2)
    local idx = 1
    while isQuestActive() do
        local enemy = cariMusuh("Factory Staff")
        if not enemy then
            idx = idx % #questSpawns["Factory"] + 1
            tweenTo(questSpawns["Factory"][idx])
            task.wait(0.5)
        else
            serangMusuh(enemy)
        end
        task.wait(0.01)
    end
end

-- Bartilo quest
local function selesaikanQuestBartilo()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest","BartiloQuest",1)
    end)
    while isQuestActive() do
        local enemy = cariMusuh("Swan Pirate")
        if enemy then serangMusuh(enemy)
        else tweenTo(questLocations.spawnSwanPirate); task.wait(0.5) end
        task.wait(0.01)
    end
    tweenTo(questLocations.spawnJeremy); task.wait(1)
    local done = false
    local t0 = os.time()
    while not done and os.time()-t0 < 60 do
        local j = cariMusuh("Jeremy")
        if j then serangMusuh(j, function() done = true end)
        else tweenTo(questLocations.spawnJeremy); task.wait(0.5) end
        task.wait(0.01)
    end
    if done then
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress","Bartilo") end)
        return true
    end
    return false
end

-- Respawn
local function autoRespawn()
    if isDead then return end
    isDead = true
    task.wait(respawnCooldown)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetSpawnPoint")
        lp:LoadCharacter()
    end)
    repeat task.wait(0.05)
    until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    isDead = false
    character = lp.Character
    hrp       = character:WaitForChild("HumanoidRootPart")
    humanoid  = character:WaitForChild("Humanoid")
    task.wait(0.5)
    pcall(equipBestFightingStyle)
    pcall(activateBuso)
end

local function setupDeathDetection(hum)
    if hum then hum.Died:Connect(autoRespawn) end
end

lp.CharacterAdded:Connect(function(c)
    isDead = false
    setupDeathDetection(c:WaitForChild("Humanoid"))
end)
if lp.Character then setupDeathDetection(lp.Character:FindFirstChildOfClass("Humanoid")) end

-- Recovery
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            if not character or not character.Parent or not hrp then
                lp:LoadCharacter()
                character = lp.Character or lp.CharacterAdded:Wait()
                hrp       = character:WaitForChild("HumanoidRootPart")
            end
            if character:FindFirstChild("Humanoid") and character.Humanoid.Health <= 0 and not isDead then
                autoRespawn()
            end
        end)
    end
end)

-- Keep character at height 50 while not farming (float hack)
RunService.Heartbeat:Connect(function()
    if hubToggles.AutoFarm and hrp then
        pcall(function()
            local p = hrp.Position
            hrp.CFrame = CFrame.new(p.X, 50, p.Z)
        end)
    end
end)

-- Stat upgrade background task
task.spawn(tambahStatOtomatis)

-- Background: buy haki + fruit management every 10 min
task.spawn(function()
    while true do
        pcall(beliBusoHaki)
        pcall(function()
            local ok, result = pcall(function()
                return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin","Check")
            end)
            if ok and result then
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin","Buy") end)
                task.wait(1)
                for _, tool in ipairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:find("Fruit") then
                        local fName = tool.Name:gsub(" Fruit","")
                        if getFruitValue(fName) < 1000000 then
                            pcall(function()
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fName, tool)
                            end)
                        end
                    end
                end
            end
        end)
        task.wait(600)
    end
end)

-- Initial equip
task.spawn(function()
    task.wait(0.5)
    pcall(equipBestFightingStyle)
    pcall(activateBuso)
    if hubToggles.AutoCodes then pcall(redeemCodes) end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  MAIN AUTO-FARM LOOP
-- ════════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        local ok, err = pcall(function()
            if not hubToggles.AutoFarm then task.wait(0.5); return end
            if isDead then task.wait(0.1); return end

            local level = lp:WaitForChild("Data"):WaitForChild("Level").Value

            -- Auto Raid trigger
            if hubToggles.AutoRaid and level >= 1100 and (isSecondSea or isThirdSea)
            and (tick() - lastRaidTime > 300) then
                lastRaidTime = tick()
                if not memilikiItem("Flame") then
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc","Buy","Flame")
                    end)
                end
                pcall(autoRaid)
            end

            -- First Sea
            if isFirstSea then
                if level < 10 then
                    ambilQuestBandit()
                    while isQuestActive() do
                        local e = cariMusuh("Bandit")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 15 then
                    ambilQuestAdventurer(1)
                    while isQuestActive() do
                        local e = cariMusuh("Monkey")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 30 then
                    ambilQuestAdventurer(2)
                    while isQuestActive() do
                        local e = cariMusuh("Gorilla") or cariMusuh("The Gorilla King")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 40 then
                    ambilQuestPirate(1)
                    while isQuestActive() do
                        local e = cariMusuh("Pirate")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 60 then
                    ambilQuestPirate(2)
                    while isQuestActive() do
                        local e = cariMusuh("Brute") or cariMusuh("Chef")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 75 then
                    ambilQuestDesert(1)
                    while isQuestActive() do
                        local e = cariMusuh("Desert Bandit")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 90 then
                    ambilQuestDesert(2)
                    while isQuestActive() do
                        local e = cariMusuh("Desert Officer")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 100 then
                    ambilQuestVillager(1)
                    while isQuestActive() do
                        local e = cariMusuh("Snow Bandit")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 120 then
                    ambilQuestVillager(2)
                    while isQuestActive() do
                        local e = cariMusuh("Snowman") or cariMusuh("Yeti")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 150 then
                    ambilQuestMarine(1)
                    while isQuestActive() do
                        local e = cariMusuh("Chief Petty Officer") or cariMusuh("Vice Admiral")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 175 then
                    ambilQuestSkyAdventurer(1)
                    while isQuestActive() do
                        local e = cariMusuh("Sky Bandit")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 190 then
                    ambilQuestSkyAdventurer(2)
                    while isQuestActive() do
                        local e = cariMusuh("Dark Master")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 210 then
                    ambilQuestJailKeeper(1)
                    while isQuestActive() do
                        local e = cariMusuh("Prisoner")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 250 then
                    ambilQuestJailKeeper(2)
                    while isQuestActive() do
                        local e = cariMusuh("Dangerous Prisoner")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 300 then
                    ambilQuestColosseum(1)
                    local idx = 1
                    while isQuestActive() do
                        local e = cariMusuh("Toga Warrior")
                        if not e then
                            idx = idx % #questSpawns["Toga Warrior"] + 1
                            tweenTo(questSpawns["Toga Warrior"][idx]); task.wait(0.5)
                        else serangMusuh(e) end
                        task.wait(0.1)
                    end
                    ambilQuestColosseum(2)
                    idx = 1
                    while isQuestActive() do
                        local e = cariMusuh("Gladiator")
                        if not e then
                            idx = idx % #questSpawns["Gladiator"] + 1
                            tweenTo(questSpawns["Gladiator"][idx]); task.wait(0.5)
                        else serangMusuh(e) end
                        task.wait(0.1)
                    end
                elseif level < 325 then
                    ambilQuestTheMayor(1)
                    while isQuestActive() do
                        local e = cariMusuh("Military Soldier")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 375 then
                    ambilQuestTheMayor(2)
                    while isQuestActive() do
                        local e = cariMusuh("Military Spy") or cariMusuh("Magma Admiral")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 400 then
                    ambilQuestKingNeptune(1)
                    while isQuestActive() do
                        local e = cariMusuh("Fishman Warrior")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 450 then
                    ambilQuestKingNeptune(2)
                    while isQuestActive() do
                        local e = cariMusuh("Fishman Commando") or cariMusuh("Fishman Lord")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 475 then
                    ambilQuestMole(1)
                    while isQuestActive() do
                        local e = cariMusuh("God's Guard")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 525 then
                    ambilQuestMole(2)
                    while isQuestActive() do
                        local e = cariMusuh("Shanda") or cariMusuh("Wysper")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 550 then
                    ambilQuestSky2(1)
                    while isQuestActive() do
                        local e = cariMusuh("Royal Squad")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 625 then
                    ambilQuestSky2(2)
                    while isQuestActive() do
                        local e = cariMusuh("Royal Soldier") or cariMusuh("Thunder God")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 650 then
                    ambilQuestFreezeburg(1)
                    while isQuestActive() do
                        local e = cariMusuh("Galley Pirate")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 700 then
                    ambilQuestFreezeburg(2)
                    while isQuestActive() do
                        local e = cariMusuh("Galley Captain") or cariMusuh("Cyborg")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level >= 700 and not sudahUnlockSea2 then
                    -- Sea 2 unlock
                    local detCF = CFrame.new(4853.36,4.35,717.71)
                    tweenTo(detCF); task.wait(2)
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Detective")
                    end)
                    local iceAdCF = CFrame.new(1344.54,42.25,-1327.88)
                    tweenTo(iceAdCF); task.wait(0.5)
                    local defeated = false
                    local t0 = os.time()
                    while os.time()-t0 < 30 do
                        local e = cariMusuh("Ice Admiral")
                        if e then
                            pcall(equipBestFightingStyle)
                            serangMusuh(e, function() defeated = true end)
                            if defeated then break end
                        end
                        task.wait(0.5)
                    end
                    if defeated then
                        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Ice Admiral") end)
                        tweenTo(detCF); task.wait(0.5)
                        local rOk = pcall(function()
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Detective")
                        end)
                        if rOk then
                            sudahUnlockSea2 = true
                            local capCF = CFrame.new(-1163.06,6.74,1727.85)
                            tweenTo(capCF); task.wait(0.5)
                            pcall(function()
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Dressrosa")
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                            end)
                        end
                    end
                end

            -- Second/Third Sea
            elseif isSecondSea or isThirdSea then
                if level < 725 then
                    ambilQuestArea1Giver(1)
                    local idx = 1
                    while isQuestActive() do
                        local e = cariMusuh("Raider")
                        if not e then
                            idx = idx % #questSpawns["Raider"] + 1
                            tweenTo(questSpawns["Raider"][idx]); task.wait(0.5)
                        else serangMusuh(e) end
                        task.wait(0.01)
                    end
                elseif level < 775 then
                    ambilQuestArea1Giver(2)
                    local idx = 1
                    while isQuestActive() do
                        local e = cariMusuh("Mercenary")
                        if not e then
                            idx = idx % #questSpawns["Mercenary"] + 1
                            tweenTo(questSpawns["Mercenary"][idx]); task.wait(0.5)
                        else serangMusuh(e) end
                        task.wait(0.01)
                    end
                elseif level < 800 then
                    ambilQuestArea2Giver(1)
                    while isQuestActive() do
                        local e = cariMusuh("Swan Pirate")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 850 then
                    ambilQuestArea2Giver(2)
                    local idx = 1
                    while isQuestActive() do
                        local e = cariMusuh("Factory Staff")
                        if not e then
                            idx = idx % #questSpawns["Factory"] + 1
                            tweenTo(questSpawns["Factory"][idx]); task.wait(0.5)
                        else serangMusuh(e) end
                        task.wait(0.01)
                    end
                elseif level < 875 then
                    if memilikiItem("Warrior Helmet") then
                        farmingFactoryStaff()
                    else
                        selesaikanQuestBartilo()
                        farmingFactoryStaff()
                    end
                elseif level < 900 then
                    ambilQuestMarineGiver(1)
                    while isQuestActive() do
                        local e = cariMusuh("Marine Lieutenant")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 925 then
                    ambilQuestMarineGiver(2)
                    while isQuestActive() do
                        local e = cariMusuh("Marine Captain") or cariMusuh("Orbitus")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 950 then
                    ambilQuestGraveyard(1)
                    while isQuestActive() do
                        local e = cariMusuh("Zombie")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 975 then
                    ambilQuestGraveyard(2)
                    while isQuestActive() do
                        local e = cariMusuh("Vampire")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1000 then
                    ambilQuestSnow(1)
                    while isQuestActive() do
                        local e = cariMusuh("Snow Trooper")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1050 then
                    ambilQuestSnow(2)
                    while isQuestActive() do
                        local e = cariMusuh("Winter Warrior")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1100 then
                    ambilQuestIce(1)
                    while isQuestActive() do
                        local e = cariMusuh("Lab Subordinate")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1150 then
                    ambilQuestIce(2)
                    while isQuestActive() do
                        local e = cariMusuh("Horned Warrior")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1200 then
                    ambilQuestIce(3)
                    while isQuestActive() do
                        local e = cariMusuh("Smoke Admiral")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1250 then
                    ambilQuestFire(1)
                    while isQuestActive() do
                        local e = cariMusuh("Magma Ninja")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1275 then
                    ambilQuestFire(2)
                    while isQuestActive() do
                        local e = cariMusuh("Lava Pirate")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1300 then
                    ambilQuestRearCrew(1)
                    while isQuestActive() do
                        local e = cariMusuh("Ship Deckhand")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1325 then
                    ambilQuestRearCrew(2)
                    while isQuestActive() do
                        local e = cariMusuh("Ship Engineer")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1350 then
                    ambilQuestFrontCrew(1)
                    while isQuestActive() do
                        local e = cariMusuh("Ship Steward")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1375 then
                    ambilQuestFrontCrew(2)
                    while isQuestActive() do
                        local e = cariMusuh("Ship Officer")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1400 then
                    ambilQuestFrost(1)
                    while isQuestActive() do
                        local e = cariMusuh("Arctic Warrior")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1425 then
                    ambilQuestFrost(2)
                    while isQuestActive() do
                        local e = cariMusuh("Snow Lurker")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1450 then
                    ambilQuestFrost(3)
                    while isQuestActive() do
                        local e = cariMusuh("Awakened Ice Admiral")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1475 then
                    ambilQuestForgotten(1)
                    while isQuestActive() do
                        local e = cariMusuh("Sea Soldier")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                elseif level < 1500 then
                    ambilQuestForgotten(2)
                    while isQuestActive() do
                        local e = cariMusuh("Water Fighter")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                else
                    ambilQuestForgotten(3)
                    while isQuestActive() do
                        local e = cariMusuh("Tide Keeper")
                        if e then serangMusuh(e) end; task.wait(0.01)
                    end
                end
            end
        end)
        if not ok then warn("[Plung Farm Error]", err) end
        task.wait(0.1)
    end
end)

notify("Plung Hub v3","Full AutoFarm Engine loaded!")
