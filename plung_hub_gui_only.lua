local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = player:WaitForChild("PlayerGui")

local placeId = game.PlaceId
local isFirstSea = placeId == 2753915549
local isSecondSea = placeId == 4442272183
local isThirdSea = placeId == 7449423635

-- Notification function
local function showCustomNotif(title, text)
    local oldNotif = PlayerGui:FindFirstChild("CustomNotification")
    if oldNotif then oldNotif:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomNotification"
    screenGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(0.5, -150, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(14, 55, 14)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextStrokeTransparency = 0.7
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 24
    titleLabel.Text = title
    titleLabel.Parent = frame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
    textLabel.Position = UDim2.new(0, 0, 0.5, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.7
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextSize = 18
    textLabel.Text = text
    textLabel.Parent = frame

    task.delay(3, function()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end

-- ══════════════════════════════════════════════════════════
--  PLUNG HUB GUI
-- ══════════════════════════════════════════════════════════

-- Color palette
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
}

-- Toggle state flags
local hubToggles = {
    AutoFarm   = false,
    NoClip     = false,
    AutoRaid   = false,
    AutoCodes  = false,
    AutoHaki   = false,
}

-- ── Hub ScreenGui ──────────────────────────────────────────
local hubGui = Instance.new("ScreenGui")
hubGui.Name              = "PlungHub"
hubGui.ResetOnSpawn      = false
hubGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
hubGui.IgnoreGuiInset    = true
hubGui.Parent            = PlayerGui

-- ── Icon button (draggable) ────────────────────────────────
local iconFrame = Instance.new("Frame")
iconFrame.Name              = "PlungIcon"
iconFrame.Size              = UDim2.new(0, 60, 0, 60)
iconFrame.Position          = UDim2.new(0, 20, 0.5, -30)
iconFrame.BackgroundColor3  = Color3.fromRGB(5, 20, 5)
iconFrame.BorderSizePixel   = 0
iconFrame.Active            = true
iconFrame.ZIndex            = 10
iconFrame.Parent            = hubGui

local iconStroke = Instance.new("UIStroke")
iconStroke.Color     = C.Accent
iconStroke.Thickness = 2
iconStroke.Parent    = iconFrame

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent       = iconFrame

local iconGrad = Instance.new("UIGradient")
iconGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(20,  100, 20)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60,  200, 60)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(15,  80,  15)),
})
iconGrad.Rotation = 135
iconGrad.Parent   = iconFrame

local iconLabel = Instance.new("TextLabel")
iconLabel.Size                 = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.TextColor3           = Color3.new(1, 1, 1)
iconLabel.Font                 = Enum.Font.GothamBold
iconLabel.TextSize             = 13
iconLabel.Text                 = "Plung"
iconLabel.TextStrokeTransparency = 0.4
iconLabel.TextStrokeColor3     = Color3.new(0, 0, 0)
iconLabel.ZIndex               = 11
iconLabel.Parent               = iconFrame

local iconInnerBorder = Instance.new("Frame")
iconInnerBorder.Size              = UDim2.new(0.85, 0, 0.60, 0)
iconInnerBorder.Position          = UDim2.new(0.075, 0, 0.20, 0)
iconInnerBorder.BackgroundColor3  = Color3.new(0, 0, 0)
iconInnerBorder.BackgroundTransparency = 0.0
iconInnerBorder.BorderSizePixel   = 0
iconInnerBorder.ZIndex            = 10
iconInnerBorder.Parent            = iconFrame

local iconInnerCorner = Instance.new("UICorner")
iconInnerCorner.CornerRadius = UDim.new(0, 3)
iconInnerCorner.Parent       = iconInnerBorder

local iconInnerText = Instance.new("TextLabel")
iconInnerText.Size                 = UDim2.new(1, 0, 1, 0)
iconInnerText.BackgroundTransparency = 1
iconInnerText.TextColor3           = Color3.new(1, 1, 1)
iconInnerText.Font                 = Enum.Font.GothamBold
iconInnerText.TextSize             = 13
iconInnerText.Text                 = "Plung"
iconInnerText.ZIndex               = 11
iconInnerText.Parent               = iconInnerBorder

-- ── Main Hub Window ────────────────────────────────────────
local hubWindow = Instance.new("Frame")
hubWindow.Name              = "HubWindow"
hubWindow.Size              = UDim2.new(0, 300, 0, 340)
hubWindow.Position          = UDim2.new(0, 90, 0.5, -170)
hubWindow.BackgroundColor3  = C.BG
hubWindow.BorderSizePixel   = 0
hubWindow.Active            = true
hubWindow.Visible           = false
hubWindow.ZIndex            = 5
hubWindow.Parent            = hubGui

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(0, 10)
hubCorner.Parent       = hubWindow

local hubStroke = Instance.new("UIStroke")
hubStroke.Color     = C.Border
hubStroke.Thickness = 1.5
hubStroke.Parent    = hubWindow

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name             = "TopBar"
topBar.Size             = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = C.TopBar
topBar.BorderSizePixel  = 0
topBar.Active           = true
topBar.ZIndex           = 6
topBar.Parent           = hubWindow

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent       = topBar

local topPatch = Instance.new("Frame")
topPatch.Size              = UDim2.new(1, 0, 0.5, 0)
topPatch.Position          = UDim2.new(0, 0, 0.5, 0)
topPatch.BackgroundColor3  = C.TopBar
topPatch.BorderSizePixel   = 0
topPatch.ZIndex            = 6
topPatch.Parent            = topBar

local topTitle = Instance.new("TextLabel")
topTitle.Size                  = UDim2.new(1, -36, 1, 0)
topTitle.Position              = UDim2.new(0, 10, 0, 0)
topTitle.BackgroundTransparency = 1
topTitle.TextColor3            = C.Accent
topTitle.Font                  = Enum.Font.GothamBold
topTitle.TextSize              = 16
topTitle.TextXAlignment        = Enum.TextXAlignment.Left
topTitle.Text                  = "⚡ Plung Hub — Blox Fruits"
topTitle.ZIndex                = 7
topTitle.Parent                = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size                  = UDim2.new(0, 28, 0, 28)
closeBtn.Position              = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3      = Color3.fromRGB(180, 30, 30)
closeBtn.BorderSizePixel       = 0
closeBtn.Font                  = Enum.Font.GothamBold
closeBtn.TextSize              = 14
closeBtn.TextColor3            = Color3.new(1, 1, 1)
closeBtn.Text                  = "✕"
closeBtn.ZIndex                = 8
closeBtn.Parent                = topBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent       = closeBtn

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size              = UDim2.new(1, -20, 0, 36)
statusBar.Position          = UDim2.new(0, 10, 0, 44)
statusBar.BackgroundColor3  = C.DarkPanel
statusBar.BorderSizePixel   = 0
statusBar.ZIndex            = 6
statusBar.Parent            = hubWindow

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent       = statusBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size                  = UDim2.new(1, -10, 1, 0)
statusLabel.Position              = UDim2.new(0, 8, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3            = C.Text
statusLabel.Font                  = Enum.Font.Gotham
statusLabel.TextSize              = 12
statusLabel.TextXAlignment        = Enum.TextXAlignment.Left
statusLabel.Text                  = "🌊 Sea: Detecting... | Level: Loading..."
statusLabel.ZIndex                = 7
statusLabel.Parent                = statusBar

local function updateStatusLabel()
    local seaName = isFirstSea and "First Sea" or isSecondSea and "Second Sea" or isThirdSea and "Third Sea" or "Unknown"
    local lvl = "?"
    pcall(function()
        lvl = tostring(player.Data.Level.Value)
    end)
    statusLabel.Text = "🌊 " .. seaName .. "  |  ⚔ Level: " .. lvl
end
pcall(updateStatusLabel)

-- ── Toggle buttons ─────────────────────────────────────────
local toggleDefs = {
    { key = "AutoFarm",  label = "🌾 Auto Farm"   },
    { key = "NoClip",    label = "👻 NoClip"      },
    { key = "AutoRaid",  label = "⚡ Auto Raid"   },
    { key = "AutoHaki",  label = "🔮 Auto Haki"   },
    { key = "AutoCodes", label = "🎁 Auto Codes"  },
}

local function makeToggle(def, idx)
    local yPos = 88 + (idx - 1) * 44

    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, -20, 0, 36)
    row.Position          = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3  = C.DarkPanel
    row.BorderSizePixel   = 0
    row.ZIndex            = 6
    row.Parent            = hubWindow

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent       = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -60, 1, 0)
    lbl.Position              = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3            = C.Text
    lbl.Font                  = Enum.Font.Gotham
    lbl.TextSize              = 13
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = def.label
    lbl.ZIndex                = 7
    lbl.Parent                = row

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size              = UDim2.new(0, 46, 0, 24)
    toggleBtn.Position          = UDim2.new(1, -54, 0.5, -12)
    toggleBtn.BackgroundColor3  = hubToggles[def.key] and C.ToggleOn or C.ToggleOff
    toggleBtn.BorderSizePixel   = 0
    toggleBtn.Font              = Enum.Font.GothamBold
    toggleBtn.TextSize          = 11
    toggleBtn.TextColor3        = Color3.new(1, 1, 1)
    toggleBtn.Text              = hubToggles[def.key] and "ON" or "OFF"
    toggleBtn.ZIndex            = 8
    toggleBtn.Parent            = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 5)
    tCorner.Parent       = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        hubToggles[def.key] = not hubToggles[def.key]
        local on = hubToggles[def.key]
        toggleBtn.BackgroundColor3 = on and C.ToggleOn or C.ToggleOff
        toggleBtn.Text             = on and "ON" or "OFF"
        showCustomNotif("Plung Hub", def.label .. ": " .. (on and "ON" or "OFF"))
    end)
end

for i, def in ipairs(toggleDefs) do
    makeToggle(def, i)
end

-- ── Drag system ────────────────────────────────────────────
local iconDragging     = false
local iconMoved        = false
local iconDragStartX   = 0
local iconDragStartY   = 0
local windowDragging   = false
local windowDragStartX = 0
local windowDragStartY = 0

iconFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging   = true
        iconMoved      = false
        iconDragStartX = input.Position.X - iconFrame.AbsolutePosition.X
        iconDragStartY = input.Position.Y - iconFrame.AbsolutePosition.Y
    end
end)
iconFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if not iconMoved then
            hubWindow.Visible = not hubWindow.Visible
            if hubWindow.Visible then updateStatusLabel() end
        end
        iconDragging = false
    end
end)

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging   = true
        windowDragStartX = input.Position.X - hubWindow.AbsolutePosition.X
        windowDragStartY = input.Position.Y - hubWindow.AbsolutePosition.Y
    end
end)
topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging = false
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    hubWindow.Visible = false
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if iconDragging then
            local dx = math.abs(input.Position.X - iconFrame.AbsolutePosition.X - iconDragStartX)
            local dy = math.abs(input.Position.Y - iconFrame.AbsolutePosition.Y - iconDragStartY)
            if dx > 3 or dy > 3 then iconMoved = true end
            if iconMoved then
                local vp = workspace.CurrentCamera.ViewportSize
                local nx = math.clamp(input.Position.X - iconDragStartX, 0, vp.X - 60)
                local ny = math.clamp(input.Position.Y - iconDragStartY, 0, vp.Y - 60)
                iconFrame.Position = UDim2.new(0, nx, 0, ny)
            end
        end
        if windowDragging then
            local vp = workspace.CurrentCamera.ViewportSize
            local nx = math.clamp(input.Position.X - windowDragStartX, 0, vp.X - 300)
            local ny = math.clamp(input.Position.Y - windowDragStartY, 0, vp.Y - 340)
            hubWindow.Position = UDim2.new(0, nx, 0, ny)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--  END PLUNG HUB GUI
-- ══════════════════════════════════════════════════════════

showCustomNotif("Plung Hub", "Loaded ✓")
