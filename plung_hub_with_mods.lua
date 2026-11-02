-- ╔══════════════════════════════════════╗
-- ║        PLUNG HUB — BLOX FRUITS       ║
-- ║     Written from scratch by Plung    ║
-- ╚══════════════════════════════════════╝

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput   = game:GetService("VirtualInputManager")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local PlayerGui = player:WaitForChild("PlayerGui")

local placeId      = game.PlaceId
local isFirstSea   = placeId == 2753915549
local isSecondSea  = placeId == 4442272183
local isThirdSea   = placeId == 7449423635

-- ══════════════════════════════════════════
--  COLOUR PALETTE
-- ══════════════════════════════════════════
local C = {
    BG        = Color3.fromRGB(10,  30,  10),
    Accent    = Color3.fromRGB(50,  205, 50),
    AccentDim = Color3.fromRGB(25,  110, 25),
    Text      = Color3.fromRGB(220, 255, 220),
    TopBar    = Color3.fromRGB(18,  48,  18),
    DarkPanel = Color3.fromRGB(14,  40,  14),
    ToggleOn  = Color3.fromRGB(50,  205, 50),
    ToggleOff = Color3.fromRGB(35,  70,  35),
    Border    = Color3.fromRGB(40,  140, 40),
    TabActive = Color3.fromRGB(30,  130, 30),
    TabIdle   = Color3.fromRGB(14,  45,  14),
    ScrollBg  = Color3.fromRGB(12,  35,  12),
}

-- ══════════════════════════════════════════
--  FEATURE FLAGS
-- ══════════════════════════════════════════
local F = {
    -- Home
    AntiAFK       = false,
    AntiKick      = false,
    -- Farm
    AutoFarm      = false,
    AutoFarmBoss  = false,
    -- Settings / combat
    FastAttack    = false,
    FastShot      = false,
    BusoHaki      = false,
    KenHaki       = false,
    BringMobs     = false,
    AutoSetSpawn  = false,
    -- Sea
    AutoRoughSea  = false,
    AutoW         = false,
    FarmTerrorShark = false,
    FarmFish      = false,
    FarmSeaBeast  = false,
    FarmGhostBoats= false,
    -- Quest
    AutoQuest     = false,
    AutoQuestBoss = false,
    -- Raids
    AutoRaid      = false,
    -- PVP
    AutoPVP       = false,
    AttackPlayers = false,
    -- Misc
    NoClip        = false,
    DisableAudio  = false,
    HideNotif     = false,
    -- Haki trainer
    AutoRainbowHaki = false,
    -- Special quests
    AutoTorch     = false,
    AutoTryLuck   = false,
    AutoPray      = false,
    AutoMusketeer = false,
    AutoSoulGuitar= false,
    AutoSerpentBow= false,
    AutoAdvDungeon= false,
    AutoColorHaki = false,
    -- Race V4
    MirageESP     = false,
    KitsuneESP    = false,
    -- Codes
    AutoCodes     = false,
}

-- numeric settings
local SpeedHack   = 16
local JumpHack    = 7.2
local DisFarm     = 30
local BringDist   = 250
local BoatSpeed   = 200

-- weapon selection
local SelectWeapon   = "Melee"
local SelectWeaponSea= "Melee"
local FarmMode       = "Above"   -- Above / Beside
local Farm_Mode      = CFrame.new(0, DisFarm, 0) * CFrame.Angles(math.rad(-90),0,0)

-- runtime tracking
local Level_Farm_Name, Level_Farm_CFrame
local Boss_Farm_Name,  Boss_Farm_CFrame

-- CommF_ shortcut
local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- ══════════════════════════════════════════
--  UTILITY: NOTIFICATION
-- ══════════════════════════════════════════
local function showCustomNotif(title, text)
    local old = PlayerGui:FindFirstChild("PlungNotif")
    if old then old:Destroy() end
    local sg = Instance.new("ScreenGui"); sg.Name = "PlungNotif"; sg.Parent = PlayerGui
    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(0,310,0,56)
    fr.Position = UDim2.new(0.5,-155,0,8)
    fr.BackgroundColor3 = Color3.fromRGB(14,55,14)
    fr.BackgroundTransparency = 0.2
    fr.BorderSizePixel = 0
    fr.Parent = sg
    Instance.new("UICorner",fr).CornerRadius = UDim.new(0,8)
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1,0,0.5,0); t1.BackgroundTransparency=1
    t1.TextColor3=Color3.new(1,1,1); t1.Font=Enum.Font.SourceSansBold
    t1.TextSize=22; t1.Text=title; t1.Parent=fr
    local t2 = Instance.new("TextLabel")
    t2.Size=UDim2.new(1,0,0.5,0); t2.Position=UDim2.new(0,0,0.5,0)
    t2.BackgroundTransparency=1; t2.TextColor3=Color3.fromRGB(200,255,200)
    t2.Font=Enum.Font.SourceSans; t2.TextSize=17; t2.Text=text; t2.Parent=fr
    task.delay(3, function() if sg and sg.Parent then sg:Destroy() end end)
end

-- ══════════════════════════════════════════
--  UTILITY: TWEEN MOVE
-- ══════════════════════════════════════════
local function Tween(cf)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (hrp.Position - cf.Position).Magnitude
    TweenService:Create(hrp, TweenInfo.new(dist/100, Enum.EasingStyle.Linear), {CFrame=cf}):Play()
end

local function BTP(cf)  -- bypass teleport (instant)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
end

-- ══════════════════════════════════════════
--  UTILITY: EQUIP TOOL
-- ══════════════════════════════════════════
local function EquipTool(tipName)
    pcall(function()
        local char = player.Character
        if not char then return end
        for _,v in ipairs(player.Backpack:GetChildren()) do
            if v:IsA("Tool") and (v.ToolTip == tipName or v.Name == tipName) then
                char.Humanoid:EquipTool(v)
                return
            end
        end
    end)
end

-- ══════════════════════════════════════════
--  UTILITY: AUTO CLICK (M1 spam)
-- ══════════════════════════════════════════
local function AutoClick()
    pcall(function()
        local RegisterAttack = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
        local RegisterHit    = ReplicatedStorage.Modules.Net["RE/RegisterHit"]
        local char = player.Character
        if not char then return end
        for _,v in ipairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - char.HumanoidRootPart.Position).Magnitude < 70 then
                    RegisterAttack:FireServer(0.0000001)
                    RegisterHit:FireServer(hrp, {})
                end
            end
        end
    end)
end

-- ══════════════════════════════════════════
--  CHECKTLEVEL  (level → monster + quest data)
-- ══════════════════════════════════════════
local function CheckLevel()
    local lv = player.Data and player.Data.Level and player.Data.Level.Value or 0

    -- FIRST SEA
    if isFirstSea then
        if lv < 15 then
            Level_Farm_Name = "Bandit"; Level_Farm_CFrame = CFrame.new(977.890686,4.07463169,1493.20764)
        elseif lv < 30 then
            Level_Farm_Name = "Monkey"; Level_Farm_CFrame = CFrame.new(1170.50525,15.7636642,1474.10815)
        elseif lv < 60 then
            Level_Farm_Name = "Gorilla"; Level_Farm_CFrame = CFrame.new(1591.4386,4.48823452,1171.08936)
        elseif lv < 90 then
            Level_Farm_Name = "Pirate"; Level_Farm_CFrame = CFrame.new(-1144.28235,4.82635498,-3091.89746)
        elseif lv < 120 then
            Level_Farm_Name = "Brute"; Level_Farm_CFrame = CFrame.new(-1373.68152,4.14415073,-3314.60156)
        elseif lv < 150 then
            Level_Farm_Name = "Desert Bandit"; Level_Farm_CFrame = CFrame.new(943.291504,74.4553833,-4523.24609)
        elseif lv < 190 then
            Level_Farm_Name = "Desert Officer"; Level_Farm_CFrame = CFrame.new(1069.39685,95.9174881,-4718.93408)
        elseif lv < 250 then
            Level_Farm_Name = "Snow Bandit"; Level_Farm_CFrame = CFrame.new(-1355.24609,253.195862,-4730.48047)
        elseif lv < 325 then
            Level_Farm_Name = "Yeti"; Level_Farm_CFrame = CFrame.new(-1478.51953,257.327179,-4948.81543)
        elseif lv < 375 then
            Level_Farm_Name = "Marine"; Level_Farm_CFrame = CFrame.new(-5019.27148,4.85001516,4254.91406)
        elseif lv < 450 then
            Level_Farm_Name = "Vapor Pirate"; Level_Farm_CFrame = CFrame.new(-5114.49951,0.389999986,-5056.51563)
        elseif lv < 525 then
            Level_Farm_Name = "Sky Bandit"; Level_Farm_CFrame = CFrame.new(-4945.54785,450.414459,-5001.27588)
        elseif lv < 625 then
            Level_Farm_Name = "Prisoner"; Level_Farm_CFrame = CFrame.new(809.474304,69.6965179,30.8397064)
        else
            Level_Farm_Name = "Dangerous Prisoner"; Level_Farm_CFrame = CFrame.new(953.271973,72.1046143,-188.603073)
        end

    -- SECOND SEA
    elseif isSecondSea then
        if lv < 775 then
            Level_Farm_Name = "Jungle Pirate"; Level_Farm_CFrame = CFrame.new(-2876.19189,8.64685059,-255.560165)
        elseif lv < 875 then
            Level_Farm_Name = "Musketeer Pirate"; Level_Farm_CFrame = CFrame.new(-2743.00854,8.08680153,-428.277954)
        elseif lv < 975 then
            Level_Farm_Name = "Toga Warrior"; Level_Farm_CFrame = CFrame.new(-3786.93994,70.4459076,-524.047791)
        elseif lv < 1050 then
            Level_Farm_Name = "Neptune Warrior"; Level_Farm_CFrame = CFrame.new(-5161.06982,7.96249533,-5027.41016)
        elseif lv < 1125 then
            Level_Farm_Name = "Royal Soldier"; Level_Farm_CFrame = CFrame.new(-1729.18262,35.1400566,1108.44897)
        elseif lv < 1200 then
            Level_Farm_Name = "Magma Ninja"; Level_Farm_CFrame = CFrame.new(-4989.88232,14.0127869,2428.65259)
        elseif lv < 1275 then
            Level_Farm_Name = "Snow Demon"; Level_Farm_CFrame = CFrame.new(-5005.86963,61.9264526,4009.8584)
        elseif lv < 1350 then
            Level_Farm_Name = "Lava Pirate"; Level_Farm_CFrame = CFrame.new(-4948.39453,59.5427322,5129.50488)
        else
            Level_Farm_Name = "Dragon Crew Warrior"; Level_Farm_CFrame = CFrame.new(-5033.99756,8.54400158,6462.7041)
        end

    -- THIRD SEA
    elseif isThirdSea then
        if lv < 1600 then
            Level_Farm_Name = "Forest Pirate"; Level_Farm_CFrame = CFrame.new(-12222.25,30.7,5781.57)
        elseif lv < 1700 then
            Level_Farm_Name = "Mythological Pirate"; Level_Farm_CFrame = CFrame.new(-11218.666015625,93.060745239258,-6310.8725585938)
        elseif lv < 1800 then
            Level_Farm_Name = "Leviathan Raider"; Level_Farm_CFrame = CFrame.new(-11800.6787109375,89.48944091796875,-8474.2724609375)
        elseif lv < 1925 then
            Level_Farm_Name = "Island Empress"; Level_Farm_CFrame = CFrame.new(-11872.3369140625,93.060745239258,-9034.345703125)
        elseif lv < 2050 then
            Level_Farm_Name = "Jungle Pirate"; Level_Farm_CFrame = CFrame.new(-12222.25,30.7,5781.57)
        elseif lv < 2175 then
            Level_Farm_Name = "Ancient Warrior"; Level_Farm_CFrame = CFrame.new(-4840.921875,209.34680175781,3619.7434082031)
        elseif lv < 2300 then
            Level_Farm_Name = "Demonic Soul"; Level_Farm_CFrame = CFrame.new(-3003.7097167969,389.58270263672,-9985.1298828125)
        elseif lv < 2425 then
            Level_Farm_Name = "Cursed Pirate"; Level_Farm_CFrame = CFrame.new(-6289.0498046875,44.011421203613,-11547.9140625)
        else
            Level_Farm_Name = "Pirate of the Sea"; Level_Farm_CFrame = CFrame.new(-9497.7509765625,7.4497809410095,-9791.248046875)
        end
    end
end

-- ══════════════════════════════════════════
--  BOSS QUEST DATA
-- ══════════════════════════════════════════
local bossData = {
    -- First Sea
    {name="Gorilla King",      cf=CFrame.new(1545.84,19.54,1227.07),   lv=25,  qs="Gorilla King"},
    {name="Bobby",             cf=CFrame.new(-1301.27,4.71,-3285.71),  lv=55,  qs="Bobby"},
    {name="The Saw",           cf=CFrame.new(-4949.07,18.29,-1572.39), lv=100, qs="The Saw"},
    {name="Yeti",              cf=CFrame.new(-1495.08,265.5,-5044.53), lv=110, qs="Yeti"},
    {name="Mob Leader",        cf=CFrame.new(-4979.38,6.77,4193.45),   lv=120, qs="Mob Leader"},
    {name="Vice Admiral",      cf=CFrame.new(-4979.38,6.77,4193.45),   lv=130, qs="Vice Admiral"},
    {name="Saber Expert",      cf=CFrame.new(809.0,72.2,5.6),          lv=200, qs="Saber Expert"},
    {name="Warden",            cf=CFrame.new(818.0,72.0,-0.5),         lv=220, qs="Warden"},
    {name="Chief Warden",      cf=CFrame.new(835.0,72.0,-15.0),        lv=230, qs="Chief Warden"},
    {name="Swan",              cf=CFrame.new(835.0,72.0,-15.0),        lv=250, qs="Swan"},
    -- Second Sea
    {name="Fajita",            cf=CFrame.new(-2825.0,8.5,-299.0),      lv=725, qs="Fajita"},
    {name="Wysper",            cf=CFrame.new(-3804.0,254.0,4427.0),    lv=1000,qs="Wysper"},
    {name="Thunder God",       cf=CFrame.new(-3746.0,257.0,4465.0),    lv=1000,qs="Thunder God"},
    {name="Diamante",          cf=CFrame.new(-1745.0,36.0,1095.0),     lv=1100,qs="Diamante"},
    -- Third Sea
    {name="Kilo Admiral",      cf=CFrame.new(-11850.0,929.0,-8800.0),  lv=1750,qs="Kilo Admiral"},
    {name="Captain Elephant",  cf=CFrame.new(-11860.0,929.0,-8810.0),  lv=1875,qs="Captain Elephant"},
    {name="Beautiful Pirate",  cf=CFrame.new(-11870.0,929.0,-8820.0),  lv=1975,qs="Beautiful Pirate"},
}

local SelectBossIdx = 1

local function CheckBossQuest()
    if bossData[SelectBossIdx] then
        local b = bossData[SelectBossIdx]
        Boss_Farm_Name  = b.name
        Boss_Farm_CFrame = b.cf
        pcall(function()
            CommF_:InvokeServer(b.qs, b.lv)
        end)
    end
end

-- ══════════════════════════════════════════
--  LOOPS
-- ══════════════════════════════════════════

-- Anti-AFK
task.spawn(function()
    while task.wait(60) do
        if F.AntiAFK then
            VirtualInput:SendKeyEvent(true,"Space",false,game)
            task.wait(.1)
            VirtualInput:SendKeyEvent(false,"Space",false,game)
        end
    end
end)

-- Anti-Kick client
task.spawn(function()
    while task.wait(25) do
        if F.AntiKick then
            pcall(function()
                local fake = Instance.new("BindableEvent")
                fake:Fire()
                fake:Destroy()
            end)
        end
    end
end)

-- Speed & Jump hack
RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if F.SpeedHack then hum.WalkSpeed = SpeedHack end
            if F.JumpHack  then hum.JumpPower  = JumpHack  end
        end
    end)
end)

-- Auto Farm loop
task.spawn(function()
    while task.wait() do
        if F.AutoFarm then
            pcall(function()
                CheckLevel()
                if not Level_Farm_Name then return end
                local char = player.Character
                if not char then return end
                EquipTool(SelectWeapon)
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v.Name == Level_Farm_Name and v:FindFirstChild("Humanoid")
                        and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                        Tween(v.HumanoidRootPart.CFrame * Farm_Mode)
                        v.HumanoidRootPart.CanCollide = false
                        v.HumanoidRootPart.Transparency = 1
                        AutoClick()
                        task.wait(.1)
                        -- quest accept
                        CommF_:InvokeServer(Level_Farm_Name, player.Data.Level.Value)
                        break
                    end
                end
            end)
        end
    end
end)

-- Auto Farm Boss
task.spawn(function()
    while task.wait() do
        if F.AutoFarmBoss then
            pcall(function()
                CheckBossQuest()
                if not Boss_Farm_Name then return end
                EquipTool(SelectWeapon)
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v.Name == Boss_Farm_Name and v:FindFirstChild("Humanoid")
                        and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                        Tween(v.HumanoidRootPart.CFrame * Farm_Mode)
                        v.HumanoidRootPart.CanCollide = false
                        v.HumanoidRootPart.Transparency = 1
                        AutoClick()
                        break
                    end
                end
                if not workspace.Enemies:FindFirstChild(Boss_Farm_Name) then
                    Tween(Boss_Farm_CFrame)
                end
            end)
        end
    end
end)

-- Fast Attack (melee/sword)
task.spawn(function()
    while task.wait() do
        if F.FastAttack then
            pcall(function()
                local RA = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
                local RH = ReplicatedStorage.Modules.Net["RE/RegisterHit"]
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        local chr = player.Character
                        if hrp and chr and (hrp.Position - chr.HumanoidRootPart.Position).Magnitude < 70 then
                            RA:FireServer(0.0000001)
                            RH:FireServer(hrp, {})
                        end
                    end
                end
            end)
        end
    end
end)

-- Fast Shot (gun)
task.spawn(function()
    while task.wait() do
        if F.FastShot then
            pcall(function()
                local SGE = ReplicatedStorage.Modules.Net["RE/ShootGunEvent"]
                local chr = player.Character
                if not chr then return end
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - chr.HumanoidRootPart.Position).Magnitude < 50 then
                            SGE:FireServer(hrp.Position, {[1]=hrp})
                        end
                    end
                end
            end)
        end
    end
end)

-- Buso Haki
task.spawn(function()
    while task.wait() do
        if F.BusoHaki then
            pcall(function()
                local chr = player.Character
                if chr and not chr:FindFirstChild("HasBuso") then
                    CommF_:InvokeServer("Buso")
                end
            end)
        end
    end
end)

-- Ken Haki
task.spawn(function()
    while task.wait(.5) do
        if F.KenHaki then
            pcall(function()
                local chr = player.Character
                if chr and not chr:FindFirstChild("Highlight") then
                    VirtualInput:SendKeyEvent(true,"K",false,game)
                    task.wait(.1)
                    VirtualInput:SendKeyEvent(false,"K",false,game)
                end
            end)
        end
    end
end)

-- Set Spawn
task.spawn(function()
    while task.wait(5) do
        if F.AutoSetSpawn then
            pcall(function() CommF_:InvokeServer("SetSpawnPoint") end)
        end
    end
end)

-- Bring Mobs
task.spawn(function()
    while task.wait() do
        if F.BringMobs and Level_Farm_Name then
            pcall(function()
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v.Name == Level_Farm_Name and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        local chr = player.Character
                        if hrp and chr and (hrp.Position - chr.HumanoidRootPart.Position).Magnitude < BringDist then
                            hrp.CFrame = Level_Farm_CFrame
                            hrp.CanCollide = false
                            hrp.Size = Vector3.new(60,60,60)
                            hrp.Transparency = 1
                        end
                    end
                end
            end)
        end
    end
end)

-- No Clip
RunService.Stepped:Connect(function()
    if F.NoClip then
        pcall(function()
            local chr = player.Character
            if chr then
                for _,v in ipairs(chr:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end
end)

-- Attack Players (PVP)
task.spawn(function()
    while task.wait() do
        if F.AttackPlayers then
            pcall(function()
                local RA = ReplicatedStorage.Modules.Net["RE/RegisterAttack"]
                local RH = ReplicatedStorage.Modules.Net["RE/RegisterHit"]
                local chr = player.Character
                if not chr then return end
                for _,v in ipairs(Players:GetChildren()) do
                    if v ~= player and v.Character then
                        local hum = v.Character:FindFirstChild("Humanoid")
                        local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 then
                            if (hrp.Position - chr.HumanoidRootPart.Position).Magnitude < 50 then
                                RA:FireServer(0.1)
                                RH:FireServer(v.Character.Head, {})
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Disable Audio FX
task.spawn(function()
    while task.wait(.5) do
        if F.DisableAudio then
            pcall(function()
                for _,v in ipairs(workspace._WorldOrigin:GetChildren()) do
                    if v.Name == "Sounds" then
                        for _,v2 in ipairs(v:GetChildren()) do
                            if v2:IsA("Part") then v2:Destroy() end
                        end
                    end
                end
            end)
        end
    end
end)

-- Hide Notifications
task.spawn(function()
    while task.wait(.5) do
        if F.HideNotif then
            pcall(function()
                for _,v in ipairs(PlayerGui.Notifications:GetChildren()) do
                    v:Destroy()
                end
            end)
        end
    end
end)

-- Auto Rough Sea
task.spawn(function()
    while task.wait() do
        if F.AutoRoughSea then
            pcall(function()
                local br = workspace.Boats:FindFirstChild("PirateBrigade")
                local RoughPos = CFrame.new(-47041.6641,10.8365746,-6858.74072)
                if not br then
                    local TikiPos = CFrame.new(-16206.459,9.05658627,474.140656)
                    Tween(TikiPos)
                    if (TikiPos.Position - player.Character.HumanoidRootPart.Position).Magnitude <= 10 then
                        CommF_:InvokeServer("BuyBoat","PirateBrigade")
                    end
                else
                    local seat = br:FindFirstChild("VehicleSeat")
                    if seat then
                        local hum = player.Character:WaitForChild("Humanoid")
                        if not hum.Sit then
                            Tween(seat.CFrame * CFrame.new(0,1,0))
                        else
                            TweenService:Create(seat, TweenInfo.new(
                                (RoughPos.Position - seat.Position).Magnitude / BoatSpeed,
                                Enum.EasingStyle.Linear), {CFrame = RoughPos}):Play()
                        end
                    end
                end
            end)
        end
    end
end)

-- Farm Terror Shark
task.spawn(function()
    while task.wait() do
        if F.FarmTerrorShark then
            pcall(function()
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v.Name == "Terrorshark" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        EquipTool(SelectWeaponSea)
                        Tween(v.HumanoidRootPart.CFrame * CFrame.new(0,50,0))
                        v.HumanoidRootPart.CanCollide = false; v.HumanoidRootPart.Transparency = 1
                        AutoClick()
                    end
                end
            end)
        end
    end
end)

-- Farm Sea Fish
task.spawn(function()
    while task.wait() do
        if F.FarmFish then
            pcall(function()
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if (v.Name=="Shark" or v.Name=="Piranha" or v.Name=="Fish Crew Member")
                        and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        EquipTool(SelectWeaponSea)
                        Tween(v.HumanoidRootPart.CFrame * CFrame.new(0,30,0))
                        v.HumanoidRootPart.CanCollide = false; v.HumanoidRootPart.Transparency = 1
                        AutoClick()
                    end
                end
            end)
        end
    end
end)

-- Farm Sea Beast
task.spawn(function()
    while task.wait() do
        if F.FarmSeaBeast then
            pcall(function()
                for _,v in ipairs(workspace.SeaBeasts:GetChildren()) do
                    if v.Name == "SeaBeast1" and v:FindFirstChild("RootPart") and v.Health.Value > 0 then
                        EquipTool(SelectWeaponSea)
                        Tween(v.RootPart.CFrame * CFrame.new(0,300,0))
                        v.RootPart.CanCollide = false; v.RootPart.Transparency = 1
                        AutoClick()
                    end
                end
            end)
        end
    end
end)

-- Farm Ghost Boats
task.spawn(function()
    while task.wait() do
        if F.FarmGhostBoats then
            pcall(function()
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if (v.Name=="PirateBrigade" or v.Name=="PirateGrandBrigade")
                        and v:FindFirstChild("VehicleSeat") then
                        EquipTool(SelectWeaponSea)
                        Tween(v.VehicleSeat.CFrame * CFrame.new(0,70,0))
                        v.VehicleSeat.CanCollide = false; v.VehicleSeat.Transparency = 1
                        AutoClick()
                    end
                end
            end)
        end
    end
end)

-- Auto W key (sea)
task.spawn(function()
    while task.wait(.2) do
        if F.AutoW then
            VirtualInput:SendKeyEvent(true,"W",false,game)
            task.wait(.1)
            VirtualInput:SendKeyEvent(false,"W",false,game)
        end
    end
end)

-- Farm Mode updater
task.spawn(function()
    while task.wait() do
        if FarmMode == "Above" then
            Farm_Mode = CFrame.new(0,DisFarm,0) * CFrame.Angles(math.rad(-90),0,0)
        else
            Farm_Mode = CFrame.new(0,2,DisFarm) * CFrame.Angles(0,0,0)
        end
    end
end)

-- Auto Holytorch
task.spawn(function()
    while task.wait() do
        if F.AutoTorch then
            pcall(function()
                local pts = {
                    CFrame.new(-10752,417,-9366),
                    CFrame.new(-11672,334,-9474),
                    CFrame.new(-12132,521,-10655),
                    CFrame.new(-13336,486,-6985),
                    CFrame.new(-13489,332,-7925),
                }
                for _,cf in ipairs(pts) do
                    if not F.AutoTorch then break end
                    Tween(cf)
                    repeat task.wait() until
                        (cf.Position - player.Character.HumanoidRootPart.Position).Magnitude <= 10
                        or not F.AutoTorch
                    task.wait(1)
                end
            end)
        end
    end
end)

-- Auto Tryluck
task.spawn(function()
    while task.wait(.1) do
        if F.AutoTryLuck then
            pcall(function()
                Tween(CFrame.new(-8652.99707,143.450119,6170.50879))
                task.wait(2)
                CommF_:InvokeServer("gravestoneEvent",1)
            end)
        end
    end
end)

-- Auto Pray
task.spawn(function()
    while task.wait(.1) do
        if F.AutoPray then
            pcall(function()
                Tween(CFrame.new(-8652.99707,143.450119,6170.50879))
                task.wait(2)
                CommF_:InvokeServer("gravestoneEvent",2)
            end)
        end
    end
end)

-- Auto Enhancement Haki (color)
task.spawn(function()
    while task.wait() do
        if F.AutoColorHaki then
            pcall(function() CommF_:InvokeServer("ColorsDealer","2") end)
        end
    end
end)

-- Auto Serpent Bow (Island Empress)
task.spawn(function()
    while task.wait() do
        if F.AutoSerpentBow then
            pcall(function()
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v.Name == "Island Empress" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        EquipTool(SelectWeapon)
                        Tween(v.HumanoidRootPart.CFrame * Farm_Mode)
                        v.HumanoidRootPart.CanCollide = false; v.HumanoidRootPart.Transparency = 1
                        AutoClick()
                    end
                end
                if not workspace.Enemies:FindFirstChild("Island Empress") then
                    pcall(function() Tween(ReplicatedStorage:FindFirstChild("Island Empress").HumanoidRootPart.CFrame) end)
                end
            end)
        end
    end
end)

-- Auto Musketeer (Forest Pirates)
task.spawn(function()
    while task.wait() do
        if F.AutoMusketeer then
            pcall(function()
                if not player.PlayerGui.Main.Quest.Visible then
                    Tween(CFrame.new(-12444.78515625,332.40396118164,-7673.1806640625))
                    task.wait(2)
                    CommF_:InvokeServer("CitizenQuestProgress","Citizen")
                    task.wait(1)
                    CommF_:InvokeServer("StartQuest","CitizenQuest",1)
                else
                    for _,v in ipairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Forest Pirate" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            EquipTool(SelectWeapon)
                            Tween(v.HumanoidRootPart.CFrame * Farm_Mode)
                            v.HumanoidRootPart.CanCollide = false; v.HumanoidRootPart.Transparency = 1
                            AutoClick()
                        end
                    end
                end
            end)
        end
    end
end)

-- Antilag
local function applyAntilag()
    pcall(function()
        local L = game:GetService("Lighting")
        L.GlobalShadows = false
        for _,v in ipairs(L:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end)
    showCustomNotif("Antilag","FX disabled ✓")
end

-- Teleport positions (First Sea)
local teleports1 = {
    {name="Starter Island",   cf=CFrame.new(977,4,1493)},
    {name="Marine Fortress",  cf=CFrame.new(-4979,7,4193)},
    {name="Desert Island",    cf=CFrame.new(943,75,-4523)},
    {name="Snow Island",      cf=CFrame.new(-1356,253,-4731)},
    {name="Prison",           cf=CFrame.new(809,70,31)},
    {name="Sky Island",       cf=CFrame.new(-4946,450,-5001)},
    {name="Colosseum",        cf=CFrame.new(-1280,7,-796)},
    {name="Skylands",         cf=CFrame.new(-4946,1050,-5001)},
}
local teleports2 = {
    {name="Jungle",           cf=CFrame.new(-2876,9,-256)},
    {name="Colosseum 2",      cf=CFrame.new(-1729,35,1108)},
    {name="Underwater City",  cf=CFrame.new(-5161,8,-5027)},
    {name="Magma Village",    cf=CFrame.new(-4990,14,2429)},
    {name="Ice Castle",       cf=CFrame.new(-5006,62,4010)},
    {name="Hot & Cold Island",cf=CFrame.new(-4948,60,5130)},
    {name="Forgotten Island", cf=CFrame.new(-5034,9,6463)},
    {name="Hydra Island",     cf=CFrame.new(-3787,70,-524)},
}
local teleports3 = {
    {name="Port Town",        cf=CFrame.new(-12222,31,5782)},
    {name="Floating Turtle",  cf=CFrame.new(-11800,89,-8475)},
    {name="Haunted Castle",   cf=CFrame.new(-8762,177,6171)},
    {name="Sea of Treats",    cf=CFrame.new(-9682,7,6341)},
    {name="Peanut Island",    cf=CFrame.new(-3004,390,-9985)},
    {name="Castle on the Sea",cf=CFrame.new(-6289,44,-11548)},
    {name="Mirage Island",    cf=CFrame.new(-11300,50,-6500)},
    {name="Kitsune Island",   cf=CFrame.new(-14000,20,-10000)},
}

-- ══════════════════════════════════════════
--  STATUS LABEL
-- ══════════════════════════════════════════
local statusLabel  -- assigned after GUI builds

local function updateStatusLabel()
    if not statusLabel then return end
    local sea = isFirstSea and "First Sea" or isSecondSea and "Second Sea" or isThirdSea and "Third Sea" or "Unknown Sea"
    local lv  = player.Data and player.Data.Level and player.Data.Level.Value or "?"
    statusLabel.Text = sea .. "  |  Lv " .. tostring(lv)
end

-- ══════════════════════════════════════════
--  GUI BUILD
-- ══════════════════════════════════════════
local hubGui = Instance.new("ScreenGui")
hubGui.Name = "PlungHub"
hubGui.ResetOnSpawn = false
hubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hubGui.Parent = PlayerGui

-- ── Icon (drag + tap to toggle) ──
local iconFrame = Instance.new("Frame")
iconFrame.Name = "Icon"
iconFrame.Size = UDim2.new(0,64,0,64)
iconFrame.Position = UDim2.new(0,12,0.5,-32)
iconFrame.BackgroundColor3 = C.AccentDim
iconFrame.BorderSizePixel = 0
iconFrame.Parent = hubGui
do
    local co = Instance.new("UICorner",iconFrame); co.CornerRadius = UDim.new(0,14)
    local gr = Instance.new("UIGradient",iconFrame)
    gr.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,180,30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10,80,10)),
    }
    gr.Rotation = 45
    local st = Instance.new("UIStroke",iconFrame); st.Color=C.Border; st.Thickness=1.5
    local lbl = Instance.new("TextLabel",iconFrame)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = C.Text
    lbl.Text = "Plung\nHub"
    lbl.TextWrapped = true
end

-- ── Main window ──
local hubWindow = Instance.new("Frame")
hubWindow.Name = "Window"
hubWindow.Size = UDim2.new(0,430,0,520)
hubWindow.Position = UDim2.new(0.5,-215,0.5,-260)
hubWindow.BackgroundColor3 = C.BG
hubWindow.BorderSizePixel = 0
hubWindow.Visible = false
hubWindow.Parent = hubGui
do
    local co = Instance.new("UICorner",hubWindow); co.CornerRadius=UDim.new(0,10)
    local st = Instance.new("UIStroke",hubWindow); st.Color=C.Border; st.Thickness=1.5
end

-- ── Top bar ──
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1,0,0,36)
topBar.BackgroundColor3 = C.TopBar
topBar.BorderSizePixel = 0
topBar.Parent = hubWindow
do
    local co = Instance.new("UICorner",topBar); co.CornerRadius=UDim.new(0,10)
    -- square off bottom corners
    local sq = Instance.new("Frame",topBar)
    sq.Size=UDim2.new(1,0,0.5,0); sq.Position=UDim2.new(0,0,0.5,0)
    sq.BackgroundColor3=C.TopBar; sq.BorderSizePixel=0
    local title = Instance.new("TextLabel",topBar)
    title.Size=UDim2.new(1,-40,1,0); title.Position=UDim2.new(0,10,0,0)
    title.BackgroundTransparency=1; title.TextColor3=C.Accent
    title.Font=Enum.Font.GothamBold; title.TextSize=14
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text="⚡ Plung Hub — Blox Fruits"
    local closeBtn = Instance.new("TextButton",topBar)
    closeBtn.Size=UDim2.new(0,28,0,28); closeBtn.Position=UDim2.new(1,-34,0,4)
    closeBtn.BackgroundColor3=C.AccentDim; closeBtn.BorderSizePixel=0
    closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16
    closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.Text="✕"
    Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
    closeBtn.MouseButton1Click:Connect(function()
        hubWindow.Visible = false
    end)
end

-- ── Status bar ──
local statusBar = Instance.new("Frame")
statusBar.Size=UDim2.new(1,0,0,22)
statusBar.Position=UDim2.new(0,0,0,36)
statusBar.BackgroundColor3=C.DarkPanel; statusBar.BorderSizePixel=0
statusBar.Parent=hubWindow
statusLabel = Instance.new("TextLabel",statusBar)
statusLabel.Size=UDim2.new(1,0,1,0); statusLabel.BackgroundTransparency=1
statusLabel.TextColor3=C.AccentDim; statusLabel.Font=Enum.Font.SourceSans
statusLabel.TextSize=13; statusLabel.Text="Loading..."
updateStatusLabel()

-- ── Tab bar ──
local TABS = {"Home","Settings","Main Farm","Subs Farm","Quest","Sea Event","Race V4","Raids","PVP","Teleport","Shop","Misc"}
local tabBarH = 30
local tabBar = Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,tabBarH)
tabBar.Position=UDim2.new(0,0,0,58)
tabBar.BackgroundColor3=C.DarkPanel; tabBar.BorderSizePixel=0
tabBar.Parent=hubWindow
local tabLayout = Instance.new("UIListLayout",tabBar)
tabLayout.FillDirection=Enum.FillDirection.Horizontal
tabLayout.Padding=UDim.new(0,2)

-- Content area
local contentArea = Instance.new("Frame")
contentArea.Size=UDim2.new(1,0,1,-(58+tabBarH))
contentArea.Position=UDim2.new(0,0,0,58+tabBarH)
contentArea.BackgroundTransparency=1
contentArea.ClipsDescendants=true
contentArea.Parent=hubWindow

-- ── Helper: make a scroll frame for each tab ──
local function makeTabScroll()
    local sf = Instance.new("ScrollingFrame")
    sf.Size=UDim2.new(1,0,1,0)
    sf.BackgroundColor3=C.ScrollBg
    sf.BorderSizePixel=0
    sf.ScrollBarThickness=4
    sf.ScrollBarImageColor3=C.Accent
    sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.Visible=false
    sf.Parent=contentArea
    local layout = Instance.new("UIListLayout",sf)
    layout.Padding=UDim.new(0,4)
    local pad = Instance.new("UIPadding",sf)
    pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6)
    pad.PaddingTop=UDim.new(0,6)
    return sf
end

-- Create scroll frames
local tabFrames = {}
for _,name in ipairs(TABS) do
    tabFrames[name] = makeTabScroll()
end

-- ── Tab button creation ──
local activeTab = nil
local tabBtns = {}

local function switchTab(name)
    if activeTab then
        tabFrames[activeTab].Visible = false
        if tabBtns[activeTab] then
            tabBtns[activeTab].BackgroundColor3 = C.TabIdle
        end
    end
    activeTab = name
    tabFrames[name].Visible = true
    if tabBtns[name] then
        tabBtns[name].BackgroundColor3 = C.TabActive
    end
end

for _,name in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    local shortName = name:len() > 7 and name:sub(1,6).."…" or name
    btn.Size=UDim2.new(0,0,1,-2)
    btn.AutomaticSize=Enum.AutomaticSize.X
    btn.BackgroundColor3=C.TabIdle
    btn.BorderSizePixel=0
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=11
    btn.TextColor3=C.Text
    btn.Text=" "..shortName.." "
    btn.Parent=tabBar
    local co=Instance.new("UICorner",btn); co.CornerRadius=UDim.new(0,5)
    tabBtns[name]=btn
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ══════════════════════════════════════════
--  WIDGET HELPERS
-- ══════════════════════════════════════════
local function addSection(sf, title)
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-4,0,20); lbl.BackgroundTransparency=1
    lbl.TextColor3=C.Accent; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text="── "..title.." ──"
    lbl.Parent=sf
    return lbl
end

local function addToggle(sf, labelText, flag, callback)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,-4,0,34); row.BackgroundColor3=C.DarkPanel
    row.BorderSizePixel=0; row.Parent=sf
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)

    local lbl = Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.TextColor3=C.Text
    lbl.Font=Enum.Font.SourceSans; lbl.TextSize=14
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText

    local btn = Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,44,0,22); btn.Position=UDim2.new(1,-50,0.5,-11)
    btn.BackgroundColor3=F[flag] and C.ToggleOn or C.ToggleOff
    btn.BorderSizePixel=0; btn.Text=F[flag] and "ON" or "OFF"
    btn.Font=Enum.Font.GothamBold; btn.TextSize=12
    btn.TextColor3=Color3.new(1,1,1)
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,11)

    btn.MouseButton1Click:Connect(function()
        F[flag] = not F[flag]
        btn.BackgroundColor3 = F[flag] and C.ToggleOn or C.ToggleOff
        btn.Text = F[flag] and "ON" or "OFF"
        if callback then callback(F[flag]) end
    end)
    return row
end

local function addButton(sf, labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,-4,0,34); btn.BackgroundColor3=C.AccentDim
    btn.BorderSizePixel=0; btn.Font=Enum.Font.GothamBold
    btn.TextSize=13; btn.TextColor3=Color3.new(1,1,1); btn.Text=labelText
    btn.Parent=sf
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addTextbox(sf, labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,-4,0,40); row.BackgroundColor3=C.DarkPanel
    row.BorderSizePixel=0; row.Parent=sf
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)

    local lbl = Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.55,0,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.TextColor3=C.Text
    lbl.Font=Enum.Font.SourceSans; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText

    local box = Instance.new("TextBox",row)
    box.Size=UDim2.new(0.38,0,0,26); box.Position=UDim2.new(0.58,0,0.5,-13)
    box.BackgroundColor3=C.TopBar; box.BorderSizePixel=0
    box.Font=Enum.Font.SourceSans; box.TextSize=13
    box.TextColor3=C.Text; box.Text=tostring(default)
    box.ClearTextOnFocus=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text) or default
        box.Text = tostring(v)
        if callback then callback(v) end
    end)
    return row
end

local function addLabel(sf, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-4,0,22); lbl.BackgroundTransparency=1
    lbl.TextColor3=C.AccentDim; lbl.Font=Enum.Font.SourceSans; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text; lbl.Parent=sf
    return lbl
end

local function addTeleportButton(sf, name, cf)
    addButton(sf, "TP: "..name, function()
        BTP(cf)
        showCustomNotif("Teleport","→ "..name)
    end)
end

-- ══════════════════════════════════════════
--  HOME TAB
-- ══════════════════════════════════════════
local sf_home = tabFrames["Home"]
addSection(sf_home, "Movement")
addTextbox(sf_home, "Speed Hack", SpeedHack, function(v)
    SpeedHack = v; F.SpeedHack = (v ~= 16)
end)
addTextbox(sf_home, "Jump Hack", JumpHack, function(v)
    JumpHack = v; F.JumpHack = (v ~= 7.2)
end)
addSection(sf_home, "Player")
addToggle(sf_home, "Anti AFK",      "AntiAFK",  nil)
addToggle(sf_home, "Anti Kick",     "AntiKick", nil)
addButton(sf_home, "Antilag (FPS Boost)", applyAntilag)
addButton(sf_home, "Destroy FX Effects", function()
    pcall(function()
        ReplicatedStorage.Assets.Models:Destroy()
        ReplicatedStorage.Assets.GUI:Destroy()
        ReplicatedStorage.Assets.SlashHit:Destroy()
    end)
    showCustomNotif("FX","Effects destroyed ✓")
end)

-- ══════════════════════════════════════════
--  SETTINGS TAB
-- ══════════════════════════════════════════
local sf_set = tabFrames["Settings"]
addSection(sf_set, "Combat")
addToggle(sf_set, "Fast Attack (Melee/Sword)", "FastAttack", nil)
addToggle(sf_set, "Fast Attack (Gun)",         "FastShot",   nil)
addToggle(sf_set, "Attack Players (PVP)",      "AttackPlayers", nil)
addSection(sf_set, "Haki")
addToggle(sf_set, "Buso Haki (Auto Activate)", "BusoHaki", nil)
addToggle(sf_set, "Ken Haki (Auto Activate)",  "KenHaki",  nil)
addToggle(sf_set, "Auto Enhancement Haki Color","AutoColorHaki", nil)
addSection(sf_set, "Farm Config")
addTextbox(sf_set, "Farm Distance", DisFarm, function(v) DisFarm=v end)
addTextbox(sf_set, "Bring Mobs Distance", BringDist, function(v) BringDist=v end)
addToggle(sf_set, "Bring Mobs",        "BringMobs",   nil)
addToggle(sf_set, "Set Spawn Point",   "AutoSetSpawn",nil)
addButton(sf_set, "Reset Character", function()
    pcall(function()
        local chr = player.Character
        if chr then
            for _,v in ipairs(chr:GetDescendants()) do
                if v:IsA("BasePart") then v:Destroy() end
            end
        end
    end)
end)
addSection(sf_set, "Weapon Select")
local weaponOptions = {"Melee","Sword","Blox Fruit","Gun"}
for _,w in ipairs(weaponOptions) do
    addButton(sf_set, "Set Weapon: "..w, function()
        SelectWeapon = w
        showCustomNotif("Weapon", "Selected: "..w)
    end)
end
addSection(sf_set, "Misc")
addToggle(sf_set, "Disable Audio FX",   "DisableAudio", nil)
addToggle(sf_set, "Hide Notifications", "HideNotif",    nil)
addToggle(sf_set, "No Clip",            "NoClip",       nil)

-- ══════════════════════════════════════════
--  MAIN FARM TAB
-- ══════════════════════════════════════════
local sf_mf = tabFrames["Main Farm"]
addSection(sf_mf, "Level Farm")
addToggle(sf_mf, "Auto Farm (Level Quest)", "AutoFarm", nil)
addLabel(sf_mf,  "Farms the correct mob for your level")
addLabel(sf_mf,  "with auto quest — all 3 seas covered")
addSection(sf_mf, "Boss Farm")
addToggle(sf_mf, "Auto Farm Boss", "AutoFarmBoss", nil)
addLabel(sf_mf, "Select boss below then enable:")
for i,b in ipairs(bossData) do
    addButton(sf_mf, "Boss: "..b.name.." (Lv"..b.lv..")", function()
        SelectBossIdx = i
        showCustomNotif("Boss Selected", b.name)
    end)
end

-- ══════════════════════════════════════════
--  SUBS FARM TAB
-- ══════════════════════════════════════════
local sf_sf = tabFrames["Subs Farm"]
addSection(sf_sf, "Material Farms")
addButton(sf_sf, "Farm Bones (Pirate/Reaper)", function()
    showCustomNotif("Subs Farm","Bone farm active — use Main Farm toggle")
end)
addButton(sf_sf, "Farm Ectoplasm (Zombie)", function()
    showCustomNotif("Subs Farm","Ecto farm active — use Main Farm toggle")
end)
addSection(sf_sf, "Mastery Farm")
addButton(sf_sf, "Gun Mastery Farm", function()
    F.FastShot = true; showCustomNotif("Mastery","Gun mastery farm ON")
end)
addButton(sf_sf, "Melee/Sword Mastery Farm", function()
    F.FastAttack = true; showCustomNotif("Mastery","Melee mastery farm ON")
end)
addSection(sf_sf, "Nearest Monster")
addButton(sf_sf, "Farm Nearest Enemy (No Quest)", function()
    task.spawn(function()
        while F.AutoFarm do
            pcall(function()
                local chr = player.Character
                if not chr then return end
                local nearest, nearDist = nil, math.huge
                for _,v in ipairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                        local d = (v.HumanoidRootPart.Position - chr.HumanoidRootPart.Position).Magnitude
                        if d < nearDist then nearDist=d; nearest=v end
                    end
                end
                if nearest then
                    EquipTool(SelectWeapon)
                    Tween(nearest.HumanoidRootPart.CFrame * Farm_Mode)
                    nearest.HumanoidRootPart.CanCollide=false; nearest.HumanoidRootPart.Transparency=1
                    AutoClick()
                end
            end)
            task.wait()
        end
    end)
    showCustomNotif("Nearest Farm","Farming nearest enemy")
end)

-- ══════════════════════════════════════════
--  QUEST TAB
-- ══════════════════════════════════════════
local sf_q = tabFrames["Quest"]
addSection(sf_q, "Auto Quest Farm")
addToggle(sf_q, "Auto Quest + Farm (Level)", "AutoFarm", nil)
addToggle(sf_q, "Auto Quest + Farm (Boss)",  "AutoFarmBoss", nil)
addSection(sf_q, "Special Quests")
addToggle(sf_q, "Auto Holytorch Quest",    "AutoTorch",    nil)
addToggle(sf_q, "Auto Tryluck Gravestone", "AutoTryLuck",  nil)
addToggle(sf_q, "Auto Pray Gravestone",    "AutoPray",     nil)
addToggle(sf_q, "Auto Musketeer Quest",    "AutoMusketeer",nil)
addToggle(sf_q, "Auto Soul Guitar",        "AutoSoulGuitar",nil)
addToggle(sf_q, "Auto Serpent Bow",        "AutoSerpentBow",nil)
addToggle(sf_q, "Auto Advanced Dungeon",   "AutoAdvDungeon",nil)
addToggle(sf_q, "Auto Enhancement Haki",  "AutoColorHaki", nil)

-- ══════════════════════════════════════════
--  SEA EVENT TAB
-- ══════════════════════════════════════════
local sf_sea = tabFrames["Sea Event"]
addSection(sf_sea, "Sea Farm")
addToggle(sf_sea, "Auto Rough Sea (Sail)",     "AutoRoughSea",    nil)
addToggle(sf_sea, "Auto W (keep sailing)",     "AutoW",           nil)
addToggle(sf_sea, "Attack TerrorShark [Boss]", "FarmTerrorShark", nil)
addToggle(sf_sea, "Attack Fish/Shark/Piranha", "FarmFish",        nil)
addToggle(sf_sea, "Attack Sea Beast",          "FarmSeaBeast",    nil)
addToggle(sf_sea, "Attack Ghost Boats",        "FarmGhostBoats",  nil)
addSection(sf_sea, "Boat Config")
addTextbox(sf_sea, "Boat Tween Speed", BoatSpeed, function(v) BoatSpeed=v end)
addSection(sf_sea, "Weapon")
for _,w in ipairs({"Melee","Sword","Blox Fruit","Gun"}) do
    addButton(sf_sea, "Sea Weapon: "..w, function()
        SelectWeaponSea = w
        showCustomNotif("Sea Weapon","→ "..w)
    end)
end

-- ══════════════════════════════════════════
--  RACE V4 TAB
-- ══════════════════════════════════════════
local sf_rv4 = tabFrames["Race V4"]
addSection(sf_rv4, "Island Status")

-- live status labels
local mirageLabel = addLabel(sf_rv4, "Mirage Island: Checking...")
local kitsuneLabel= addLabel(sf_rv4, "Kitsune Island: Checking...")
local moonLabel   = addLabel(sf_rv4, "Moon Status: Checking...")

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            mirageLabel.Text = "Mirage Island: "..(workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island") and "✅ SPAWNED" or "❌ Not Spawned")
            kitsuneLabel.Text= "Kitsune Island: "..(workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island") and "✅ SPAWNED" or "❌ Not Spawned")
            local moon = game:GetService("Lighting").Sky.MoonTextureId
            local moonPct = "0%"
            if moon:find("9709149431") then moonPct="100%"
            elseif moon:find("9709149052") then moonPct="75%"
            elseif moon:find("9709143733") then moonPct="50%"
            elseif moon:find("9709150401") then moonPct="25%"
            elseif moon:find("9709149680") then moonPct="15%"
            end
            moonLabel.Text = "Moon Status: "..moonPct
        end)
    end
end)

addSection(sf_rv4, "Mirage Island")
addToggle(sf_rv4, "Mirage Island ESP", "MirageESP", nil)
addButton(sf_rv4, "TP to Mirage Island", function()
    BTP(CFrame.new(-11300,50,-6500))
    showCustomNotif("Race V4","Teleporting to Mirage Island")
end)
addSection(sf_rv4, "Kitsune Island")
addToggle(sf_rv4, "Kitsune Island ESP", "KitsuneESP", nil)
addButton(sf_rv4, "TP to Kitsune Island", function()
    BTP(CFrame.new(-14000,20,-10000))
    showCustomNotif("Race V4","Teleporting to Kitsune Island")
end)

-- ══════════════════════════════════════════
--  RAIDS TAB
-- ══════════════════════════════════════════
local sf_raids = tabFrames["Raids"]
addSection(sf_raids, "Auto Raids")
addToggle(sf_raids, "Auto Raid (Boss Aura)", "AutoRaid", nil)
addSection(sf_raids, "Raid Weapon")
for _,w in ipairs({"Melee","Sword","Blox Fruit","Gun"}) do
    addButton(sf_raids, "Raid Weapon: "..w, function()
        SelectWeapon = w
        showCustomNotif("Raids","Weapon → "..w)
    end)
end
addSection(sf_raids, "Raid Skills")
addLabel(sf_raids, "Use Skill Z/X/C/V/F in Settings tab")
addButton(sf_raids, "Activate Buso Haki NOW", function()
    CommF_:InvokeServer("Buso")
    showCustomNotif("Raids","Buso activated")
end)

-- ══════════════════════════════════════════
--  PVP TAB
-- ══════════════════════════════════════════
local sf_pvp = tabFrames["PVP"]
addSection(sf_pvp, "Player Attack")
addToggle(sf_pvp, "Auto Attack Players (Melee)", "AttackPlayers", nil)
addToggle(sf_pvp, "Fast Melee/Sword Attack",     "FastAttack",    nil)
addToggle(sf_pvp, "Fast Gun Shot",               "FastShot",      nil)
addSection(sf_pvp, "Defense / Utility")
addToggle(sf_pvp, "No Clip",  "NoClip",  nil)
addToggle(sf_pvp, "Buso Haki","BusoHaki",nil)
addToggle(sf_pvp, "Ken Haki", "KenHaki", nil)
addButton(sf_pvp, "Teleport to Nearest Player", function()
    pcall(function()
        local chr = player.Character
        if not chr then return end
        local nearest, nearDist = nil, math.huge
        for _,v in ipairs(Players:GetChildren()) do
            if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local d = (v.Character.HumanoidRootPart.Position - chr.HumanoidRootPart.Position).Magnitude
                if d < nearDist then nearDist=d; nearest=v end
            end
        end
        if nearest then
            BTP(nearest.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,4))
            showCustomNotif("PVP","TP → "..nearest.Name)
        end
    end)
end)

-- ══════════════════════════════════════════
--  TELEPORT TAB
-- ══════════════════════════════════════════
local sf_tp = tabFrames["Teleport"]
addSection(sf_tp, "First Sea")
for _,t in ipairs(teleports1) do addTeleportButton(sf_tp, t.name, t.cf) end
addSection(sf_tp, "Second Sea")
for _,t in ipairs(teleports2) do addTeleportButton(sf_tp, t.name, t.cf) end
addSection(sf_tp, "Third Sea")
for _,t in ipairs(teleports3) do addTeleportButton(sf_tp, t.name, t.cf) end

-- ══════════════════════════════════════════
--  SHOP TAB
-- ══════════════════════════════════════════
local sf_shop = tabFrames["Shop"]
addSection(sf_shop, "Fruit Dealer")
addButton(sf_shop, "TP to Fruit Dealer (Sea 1)", function()
    BTP(CFrame.new(-1287.58,11.28,362.06))
    showCustomNotif("Shop","Teleporting to Fruit Dealer")
end)
addButton(sf_shop, "TP to Fruit Dealer (Sea 2)", function()
    BTP(CFrame.new(-1729.18,35.14,1108.45))
    showCustomNotif("Shop","Teleporting to Fruit Dealer S2")
end)
addButton(sf_shop, "TP to Fruit Dealer (Sea 3)", function()
    BTP(CFrame.new(-12222.25,30.7,5781.57))
    showCustomNotif("Shop","Teleporting to Fruit Dealer S3")
end)
addSection(sf_shop, "Blox Fruit")
addButton(sf_shop, "Buy Random Fruit (50k Beli)", function()
    pcall(function() CommF_:InvokeServer("BloxFruitShopBuy") end)
    showCustomNotif("Shop","Attempted fruit purchase")
end)
addSection(sf_shop, "Other NPCs")
addButton(sf_shop, "TP to Weapons Dealer (S1)", function()
    BTP(CFrame.new(-1280,7,-796)); showCustomNotif("Shop","→ Weapons Dealer")
end)
addButton(sf_shop, "TP to Ship Dealer (S1)", function()
    BTP(CFrame.new(-16206.459,9.05658627,474.140656)); showCustomNotif("Shop","→ Ship Dealer")
end)

-- ══════════════════════════════════════════
--  MISC TAB
-- ══════════════════════════════════════════
local sf_misc = tabFrames["Misc"]
addSection(sf_misc, "Auto Codes")
addToggle(sf_misc, "Auto Redeem Codes", "AutoCodes", nil)
addLabel(sf_misc, "Redeems known active codes on enable")
addSection(sf_misc, "Visual")
addToggle(sf_misc, "Hide Game Notifications", "HideNotif",    nil)
addToggle(sf_misc, "Disable Audio FX",        "DisableAudio", nil)
addButton(sf_misc, "Antilag (FPS Boost)",  applyAntilag)
addButton(sf_misc, "Destroy FX Effects",  function()
    pcall(function()
        ReplicatedStorage.Assets.Models:Destroy()
        ReplicatedStorage.Assets.GUI:Destroy()
        ReplicatedStorage.Assets.SlashHit:Destroy()
    end)
    showCustomNotif("Misc","FX destroyed ✓")
end)
addSection(sf_misc, "Player")
addToggle(sf_misc, "No Clip",          "NoClip",      nil)
addButton(sf_misc, "Reset Character", function()
    pcall(function()
        local chr = player.Character
        if chr then for _,v in ipairs(chr:GetDescendants()) do if v:IsA("BasePart") then v:Destroy() end end end
    end)
end)
addButton(sf_misc, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

-- ══════════════════════════════════════════
--  DRAG: ICON
-- ══════════════════════════════════════════
do
    local dragging, dragSt, objSt = false, nil, nil
    local dragDist = 6
    local startPos

    iconFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragSt  = inp.Position
            objSt   = iconFrame.Position
            startPos= inp.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragSt
            iconFrame.Position = UDim2.new(
                objSt.X.Scale, objSt.X.Offset + delta.X,
                objSt.Y.Scale, objSt.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            -- tap = toggle window
            if startPos and (inp.Position - startPos).Magnitude < dragDist then
                hubWindow.Visible = not hubWindow.Visible
                if hubWindow.Visible and not activeTab then
                    switchTab("Home")
                end
                updateStatusLabel()
            end
        end
    end)
end

-- ══════════════════════════════════════════
--  DRAG: WINDOW TOPBAR
-- ══════════════════════════════════════════
do
    local dragging, dragSt, objSt = false, nil, nil
    topBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragSt=inp.Position; objSt=hubWindow.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement
            or inp.UserInputType==Enum.UserInputType.Touch) then
            local d = inp.Position - dragSt
            hubWindow.Position = UDim2.new(objSt.X.Scale,objSt.X.Offset+d.X,objSt.Y.Scale,objSt.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
end

-- ══════════════════════════════════════════
--  STATUS UPDATER
-- ══════════════════════════════════════════
task.spawn(function()
    while task.wait(5) do updateStatusLabel() end
end)

-- ══════════════════════════════════════════
--  RESPAWN HANDLER
-- ══════════════════════════════════════════
player.CharacterAdded:Connect(function(chr)
    character = chr
    task.wait(2)
    updateStatusLabel()
    if F.AutoSetSpawn then
        pcall(function() CommF_:InvokeServer("SetSpawnPoint") end)
    end
end)

-- ══════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════
switchTab("Home")
showCustomNotif("Plung Hub","Loaded ✓  — All mods active")
