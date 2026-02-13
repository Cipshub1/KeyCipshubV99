--====================================================
-- 🌊 CIPHUB V99 | UPDATED: ISOLATED DROPDOWN + SCROLL FIX 🌊
-- STATUS: FIXED INVISIBLE + REFRESH LIST + SMART VISIBILITY LOCK
-- MODIFIED: SEPARATED SELECT PLAYER GROUP FOR BETTER SCROLLING
-- UPDATE: STABLE AUTO-FOLLOW LOCK BODY
-- FIX: MOVEMENT RESET & JUMP POWER ADDED
-- SETTINGS: ALL UI SETTINGS ENABLED BY DEFAULT (REQUESTED)
-- NEW FEATURES: FULLBRIGHT, ANTI-AFK, RESPAWN, SERVER HOP, REJOIN
-- FIX AIMBOT: 100% STATIC LOCK (NO SHAKING) - STABILIZED
-- FIX SCROLL: SELECT PLAYER LIST SCROLLING REPAIRED
--====================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables for features
local PlayerConfig = {
    NoClip = false,
    SpinBot = false,
    Invisible = false,
    GodMode = false,
    FreezeCam = false,
    HitboxSize = 2,
    HitboxEnabled = false,
    AimbotEnabled = false,
    TargetPlayer = nil, 
    BodyLock = false,
    AutoFollow = false,
    SpectatePlayer = false,
    Fullbright = false,
    AntiAFK = false,
    TPX = 0,
    TPY = 0,
    TPZ = 0
}

-- Fullbright Logic
local OldLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime
}

RunService.RenderStepped:Connect(function()
    if PlayerConfig.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    end
end)

-- Anti-AFK Logic
LP.Idled:Connect(function()
    if PlayerConfig.AntiAFK then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Cleanup UI Lama
pcall(function() 
    if LP.PlayerGui:FindFirstChild("CiphubV99") then LP.PlayerGui.CiphubV99:Destroy() end
    if Lighting:FindFirstChild("CipsBlur") then Lighting.CipsBlur:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "CiphubV99"
Gui.Parent = LP:WaitForChild("PlayerGui")
Gui.ResetOnSpawn = false 

local Blur = Instance.new("BlurEffect", Lighting)
Blur.Name = "CipsBlur"
Blur.Size = 10
Blur.Enabled = true 

local Theme = {
    Main = Color3.fromRGB(15, 15, 15),
    Sidebar = Color3.fromRGB(10, 10, 10),
    Accent = Color3.fromRGB(0, 200, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(180, 180, 180),
    Stroke = Color3.fromRGB(60, 60, 60),
    Close = Color3.fromRGB(255, 95, 87),
    Minimize = Color3.fromRGB(255, 189, 46),
    Expand = Color3.fromRGB(39, 201, 63),
    Button = Color3.fromRGB(40, 40, 40),
    ToggleOn = Color3.fromRGB(0, 200, 255),
    ToggleOff = Color3.fromRGB(60, 60, 60),
    BoxBG = Color3.fromRGB(20, 20, 20)
}

local ESP_Config = {
    Skeleton = false,
    Name = false,
    Health = false,
    Lines = false,
    Distance = false,
    TeamCheck = false
}

local function Round(obj, rad)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, rad)
    return c
end

-- ====================================================
-- SMART AIMBOT VISIBILITY ENGINE
-- ====================================================
local function IsVisible(targetPart)
    if not targetPart or not LP.Character then return false end
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = (destination - origin).Unit * (destination - origin).Magnitude
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, Camera}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    if not result or result.Instance:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

local function GetBestTarget()
    if PlayerConfig.TargetPlayer then
        local target = Players:FindFirstChild(PlayerConfig.TargetPlayer)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local _, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen and IsVisible(head) then
                return target
            end
        end
        return nil 
    end

    local target = nil
    local shortestDist = math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LP and v.Character and v.Character:FindFirstChild("Head") then
            local head = v.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen and IsVisible(head) then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if mag < shortestDist then shortestDist = mag; target = v end
            end
        end
    end
    return target
end

-- ====================================================
-- ESP & PARTICLES & DRAGGABLE
-- ====================================================
local function CreateESP(plr)
    local Name = Drawing.new("Text")
    Name.Visible = false; Name.Color = Theme.Accent; Name.Size = 14; Name.Center = true; Name.Outline = true
    local Line = Drawing.new("Line")
    Line.Visible = false; Line.Color = Theme.Accent; Line.Thickness = 1
    local Bones = {}
    for i = 1, 15 do Bones[i] = Drawing.new("Line"); Bones[i].Visible = false; Bones[i].Color = Theme.Accent; Bones[i].Thickness = 1 end

    local function UpdateSkeleton(char, onScreen)
        if not ESP_Config.Skeleton or not onScreen then for _, b in pairs(Bones) do b.Visible = false end return end
        local function GetPos(partName)
            local part = char:FindFirstChild(partName)
            if part then local v, o = Camera:WorldToViewportPoint(part.Position) if o then return Vector2.new(v.X, v.Y) end end
            return nil
        end
        local joints = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightFoot", "RightFoot"}}
        for i, joint in pairs(joints) do
            local p1, p2 = GetPos(joint[1]), GetPos(joint[2])
            if p1 and p2 then Bones[i].From = p1; Bones[i].To = p2; Bones[i].Visible = true else Bones[i].Visible = false end
        end
    end

    RunService.RenderStepped:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr ~= LP then
            local Root = plr.Character.HumanoidRootPart
            local Hum = plr.Character:FindFirstChild("Humanoid")
            local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            local TeamPass = not (ESP_Config.TeamCheck and plr.Team == LP.Team)

            if OnScreen and TeamPass then
                local Dist = math.floor((Root.Position - LP.Character.HumanoidRootPart.Position).Magnitude)
                local TextStr = ""
                if ESP_Config.Name then TextStr = plr.Name .. " " end
                if ESP_Config.Distance then TextStr = TextStr .. "[" .. Dist .. "m] " end
                if ESP_Config.Health and Hum then TextStr = TextStr .. "\nHP: " .. math.floor(Hum.Health) end
                Name.Text = TextStr; Name.Position = Vector2.new(Pos.X, Pos.Y - 45); Name.Visible = (ESP_Config.Name or ESP_Config.Distance or ESP_Config.Health)
                if ESP_Config.Lines then Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); Line.To = Vector2.new(Pos.X, Pos.Y); Line.Visible = true else Line.Visible = false end
                UpdateSkeleton(plr.Character, OnScreen)
            else
                Name.Visible = false; Line.Visible = false; UpdateSkeleton(plr.Character, false)
            end
        else
            Name.Visible = false; Line.Visible = false; UpdateSkeleton(nil, false)
        end
    end)
end
for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

local ParticleList = {}
local ParticlesActive = false
local function CreateParticle(parent)
    local p = Instance.new("Frame", parent)
    p.Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3))
    p.BackgroundColor3 = Color3.new(1, 1, 1)
    p.BackgroundTransparency = math.random(2, 5) / 10
    p.BorderSizePixel = 0
    p.Position = UDim2.new(math.random(), 0, math.random(), 0)
    Round(p, 100)
    local velocity = Vector2.new(math.random(-20, 20) / 5000, math.random(-20, 20) / 5000)
    return {obj = p, vel = velocity}
end
local function SetParticles(state, container)
    ParticlesActive = state
    if state then for i = 1, 50 do table.insert(ParticleList, CreateParticle(container)) end
    else for _, v in pairs(ParticleList) do v.obj:Destroy() end ParticleList = {} end
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ====================================================
-- UI BUILDER UTILS
-- ====================================================
local function CreateSection(parent, title)
    local Section = Instance.new("Frame", parent); Section.Size = UDim2.new(1, -10, 0, 30); Section.BackgroundTransparency = 1; Section.ZIndex = parent.ZIndex + 1
    local Title = Instance.new("TextLabel", Section); Title.Size = UDim2.new(1, 0, 1, 0); Title.Text = "   " .. title:upper(); Title.Font = Enum.Font.GothamBold; Title.TextColor3 = Theme.Accent; Title.TextSize = 12; Title.TextXAlignment = "Left"; Title.BackgroundTransparency = 1; Title.ZIndex = Section.ZIndex
    return Section
end

local function CreateFeatureBox(parent)
    local Box = Instance.new("Frame", parent)
    Box.Size = UDim2.new(1, -10, 0, 0); Box.BackgroundColor3 = Theme.BoxBG; Box.BorderSizePixel = 0; Round(Box, 6)
    local BoxStroke = Instance.new("UIStroke", Box); BoxStroke.Color = Theme.Stroke; BoxStroke.Thickness = 0.8; BoxStroke.Transparency = 0.5
    local BoxList = Instance.new("UIListLayout", Box); BoxList.Padding = UDim.new(0, 2); BoxList.HorizontalAlignment = "Center"; BoxList.SortOrder = Enum.SortOrder.LayoutOrder
    BoxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Box.Size = UDim2.new(1, -15, 0, BoxList.AbsoluteContentSize.Y + 8) end)
    return Box
end

local function CreateManualInput(parent, labelText, placeholder, callback)
    local InputFrame = Instance.new("Frame", parent); InputFrame.Size = UDim2.new(1, -15, 0, 40); InputFrame.BackgroundTransparency = 1; InputFrame.ZIndex = parent.ZIndex + 5
    local Label = Instance.new("TextLabel", InputFrame); Label.Size = UDim2.new(0.4, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Text = labelText; Label.Font = Enum.Font.Gotham; Label.TextColor3 = Theme.Text; Label.TextSize = 13; Label.TextXAlignment = "Left"; Label.BackgroundTransparency = 1; Label.ZIndex = InputFrame.ZIndex + 1
    local Box = Instance.new("TextBox", InputFrame); Box.Name = "InputBox"; Box.Size = UDim2.new(0.4, 0, 0, 28); Box.Position = UDim2.new(0.55, 0, 0.5, -14); Box.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Box.TextColor3 = Theme.Accent; Box.Font = Enum.Font.GothamBold; Box.TextSize = 12; Box.PlaceholderText = placeholder; Box.Text = ""; Box.ZIndex = InputFrame.ZIndex + 2; Round(Box, 4); Box.ClipsDescendants = true; Box.Active = true
    local BoxStroke = Instance.new("UIStroke", Box); BoxStroke.Color = Theme.Stroke; BoxStroke.Thickness = 0.8
    Box.FocusLost:Connect(function() local val = tonumber(Box.Text) if val then callback(val); Box.PlaceholderText = "" .. val end; Box.Text = "" end)
    return InputFrame
end

local function CreateToggle(parent, text, default, callback)
    local ToggleFrame = Instance.new("Frame", parent); ToggleFrame.Size = UDim2.new(1, -15, 0, 35); ToggleFrame.BackgroundTransparency = 1; ToggleFrame.ZIndex = parent.ZIndex + 5
    local Label = Instance.new("TextLabel", ToggleFrame); Label.Size = UDim2.new(1, -50, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Text = text; Label.Font = Enum.Font.Gotham; Label.TextColor3 = Theme.Text; Label.TextSize = 13; Label.TextXAlignment = "Left"; Label.BackgroundTransparency = 1; Label.ZIndex = ToggleFrame.ZIndex
    local ToggleBG = Instance.new("Frame", ToggleFrame); ToggleBG.Size = UDim2.fromOffset(36, 18); ToggleBG.Position = UDim2.new(1, -45, 0.5, -9); ToggleBG.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff; ToggleBG.ZIndex = ToggleFrame.ZIndex + 1; Round(ToggleBG, 10)
    local ToggleDot = Instance.new("Frame", ToggleBG); ToggleDot.Size = UDim2.fromOffset(12, 12); ToggleDot.Position = default and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 3, 0.5, -6); ToggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); ToggleDot.ZIndex = ToggleFrame.ZIndex + 2; Round(ToggleDot, 100)
    local ToggleButton = Instance.new("TextButton", ToggleFrame); ToggleButton.Size = UDim2.new(1, 0, 1, 0); ToggleButton.BackgroundTransparency = 1; ToggleButton.Text = ""; ToggleButton.ZIndex = ToggleFrame.ZIndex + 10
    local T_State = default
    ToggleButton.MouseButton1Click:Connect(function()
        T_State = not T_State
        TweenService:Create(ToggleBG, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundColor3 = T_State and Theme.ToggleOn or Theme.ToggleOff}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = T_State and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)}):Play()
        task.spawn(function() callback(T_State) end)
    end)
    return ToggleFrame
end

-- ====================================================
-- MAIN INTERFACE
-- ====================================================
local RestoreBtn = Instance.new("Frame", Gui)
RestoreBtn.Name = "RestoreButton"; RestoreBtn.Size = UDim2.fromOffset(100, 60); RestoreBtn.Position = UDim2.new(0, 30, 0.5, -30); RestoreBtn.BackgroundTransparency = 1; RestoreBtn.Visible = false; RestoreBtn.Active = true; RestoreBtn.ZIndex = 300
local MinLogoText = Instance.new("TextLabel", RestoreBtn); MinLogoText.Size = UDim2.new(1, 0, 1, 0); MinLogoText.BackgroundTransparency = 1; MinLogoText.RichText = true; MinLogoText.Text = '<font face="GothamBlack" color="#FFFFFF" size="18">CIPHUB</font>\n<font face="GothamBold" color="#00C8FF" size="14">V99</font>'; MinLogoText.ZIndex = 305
local GlowStroke = Instance.new("UIStroke", MinLogoText); GlowStroke.Color = Theme.Accent; GlowStroke.Thickness = 3; GlowStroke.Transparency = 0.6; GlowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
local MinClick = Instance.new("TextButton", RestoreBtn); MinClick.Size = UDim2.new(1, 0, 1, 0); MinClick.BackgroundTransparency = 1; MinClick.Text = ""; MinClick.ZIndex = 310
MakeDraggable(RestoreBtn, MinClick)

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.fromOffset(600, 350); Main.Position = UDim2.new(0.5, -300, 0.5, -175); Main.BackgroundColor3 = Theme.Main; Main.ClipsDescendants = true; Round(Main, 8)
Main.BackgroundTransparency = 0.3 
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Theme.Stroke; MainStroke.Thickness = 1
local ParticleContainer = Instance.new("Frame", Main); ParticleContainer.Name = "ParticleContainer"; ParticleContainer.Size = UDim2.new(1, 0, 1, 0); ParticleContainer.BackgroundTransparency = 1; ParticleContainer.ZIndex = 1

local TopBar = Instance.new("Frame", Main); TopBar.Size = UDim2.new(1, 0, 0, 30); TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TopBar.ZIndex = 101
MakeDraggable(Main, TopBar)

local ControlGroups = Instance.new("Frame", TopBar); ControlGroups.Size = UDim2.new(0, 120, 1, 0); ControlGroups.Position = UDim2.new(1, -130, 0, 0); ControlGroups.BackgroundTransparency = 1; ControlGroups.ZIndex = 110
local ControlLayout = Instance.new("UIListLayout", ControlGroups); ControlLayout.FillDirection = "Horizontal"; ControlLayout.HorizontalAlignment = "Right"; ControlLayout.Padding = UDim.new(0, 5); ControlLayout.VerticalAlignment = "Center"

local function CreateGroupedBtn(text, color, callback, fontSize)
    local Group = Instance.new("Frame", ControlGroups); Group.Size = UDim2.fromOffset(30, 24); Group.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Group.ZIndex = 111; Round(Group, 4)
    local Btn = Instance.new("TextButton", Group); Btn.Size = UDim2.new(1, 0, 1, 0); Btn.BackgroundTransparency = 1; Btn.Text = text; Btn.TextColor3 = color; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = fontSize or 18; Btn.ZIndex = 112
    Btn.MouseButton1Click:Connect(callback)
    return Group
end

local LeftControls = Instance.new("Frame", TopBar); LeftControls.Size = UDim2.new(0, 70, 1, 0); LeftControls.Position = UDim2.new(0, 10, 0, 0); LeftControls.BackgroundTransparency = 1
for i = 1, 3 do local dot = Instance.new("Frame", LeftControls); dot.Size = UDim2.fromOffset(10, 10); dot.Position = UDim2.new(0, (i-1)*18, 0.5, -5); dot.BackgroundColor3 = ({Theme.Close, Theme.Minimize, Theme.Expand})[i]; dot.ZIndex = 102; Round(dot, 100) end

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 180, 1, -30); Sidebar.Position = UDim2.new(0, 0, 0, 30); Sidebar.BackgroundColor3 = Theme.Sidebar; Sidebar.ZIndex = 2
Sidebar.BackgroundTransparency = 0.3 
local TabHolder = Instance.new("ScrollingFrame", Sidebar); TabHolder.Size = UDim2.new(1, 0, 1, -120); TabHolder.Position = UDim2.new(0, 0, 0, 60); TabHolder.BackgroundTransparency = 1; TabHolder.ScrollBarThickness = 0; TabHolder.ZIndex = 3
local TabListLayout = Instance.new("UIListLayout", TabHolder); TabListLayout.Padding = UDim.new(0, 5); TabListLayout.HorizontalAlignment = "Center"

local LogoArea = Instance.new("Frame", Sidebar); LogoArea.Size = UDim2.new(1, 0, 0, 60); LogoArea.BackgroundTransparency = 1; LogoArea.ZIndex = 3
local LogoText = Instance.new("TextLabel", LogoArea); LogoText.Size = UDim2.new(1, -20, 0, 30); LogoText.Position = UDim2.new(0, 15, 0, 15); LogoText.RichText = true; LogoText.Text = 'Ciphub<font color="rgb(0, 200, 255)">V99</font>'; LogoText.Font = Enum.Font.GothamBold; LogoText.TextColor3 = Theme.Text; LogoText.TextSize = 20; LogoText.TextXAlignment = "Left"; LogoText.BackgroundTransparency = 1; LogoText.ZIndex = 4

local Content = Instance.new("Frame", Main); Content.Size = UDim2.new(1, -195, 1, -40); Content.Position = UDim2.new(0, 190, 0, 40); Content.BackgroundTransparency = 1; Content.ZIndex = 2
local Pages = {}

local UserPanel = Instance.new("Frame", Sidebar); UserPanel.Name = "UserPanel"; UserPanel.Size = UDim2.new(1, -16, 0, 50); UserPanel.Position = UDim2.new(0, 8, 1, -60); UserPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 22); UserPanel.ZIndex = 3; Round(UserPanel, 8)
UserPanel.Visible = true 
Instance.new("UIStroke", UserPanel).Color = Theme.Stroke
local AvatarImg = Instance.new("ImageLabel", UserPanel); AvatarImg.Size = UDim2.fromOffset(36, 36); AvatarImg.Position = UDim2.new(0, 7, 0.5, -18); AvatarImg.BackgroundColor3 = Color3.fromRGB(35, 35, 35); AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150"; AvatarImg.ZIndex = 4; Round(AvatarImg, 100)
local DisplayNameLabel = Instance.new("TextLabel", UserPanel); DisplayNameLabel.Size = UDim2.new(1, -60, 0, 15); DisplayNameLabel.Position = UDim2.new(0, 50, 0.5, -14); DisplayNameLabel.Text = LP.DisplayName; DisplayNameLabel.Font = Enum.Font.GothamBold; DisplayNameLabel.TextColor3 = Theme.Text; DisplayNameLabel.TextSize = 11; DisplayNameLabel.TextXAlignment = "Left"; DisplayNameLabel.BackgroundTransparency = 1; DisplayNameLabel.ZIndex = 4; DisplayNameLabel.ClipsDescendants = true
local UsernameLabel = Instance.new("TextLabel", UserPanel); UsernameLabel.Size = UDim2.new(1, -60, 0, 15); UsernameLabel.Position = UDim2.new(0, 50, 0.5, 0); UsernameLabel.Text = "@"..LP.Name; UsernameLabel.Font = Enum.Font.Gotham; UsernameLabel.TextColor3 = Theme.SubText; UsernameLabel.TextSize = 9; UsernameLabel.TextXAlignment = "Left"; UsernameLabel.BackgroundTransparency = 1; UsernameLabel.ZIndex = 4; UsernameLabel.ClipsDescendants = true

local SettingsOverlay = Instance.new("ScrollingFrame", Main); SettingsOverlay.Name = "SettingsOverlay"; SettingsOverlay.Size = UDim2.new(1, -180, 1, -30); SettingsOverlay.Position = UDim2.new(0, 180, 1, 0); SettingsOverlay.BackgroundColor3 = Theme.Main; SettingsOverlay.ZIndex = 200; SettingsOverlay.BorderSizePixel = 0; SettingsOverlay.ScrollBarThickness = 0; SettingsOverlay.ClipsDescendants = true
local SettingsLayout = Instance.new("UIListLayout", SettingsOverlay); SettingsLayout.Padding = UDim.new(0, 10)
local SettingsPadding = Instance.new("UIPadding", SettingsOverlay); SettingsPadding.PaddingLeft = UDim.new(0, 15); SettingsPadding.PaddingTop = UDim.new(0, 10)

CreateSection(SettingsOverlay, "UI Settings")
CreateToggle(SettingsOverlay, "UI Transparan", true, function(state) local trans = state and 0.3 or 0; TweenService:Create(Main, TweenInfo.new(0.3), {BackgroundTransparency = trans}):Play(); TweenService:Create(Sidebar, TweenInfo.new(0.3), {BackgroundTransparency = trans}):Play() end)
CreateToggle(SettingsOverlay, "Show Avatar Profile", true, function(state) UserPanel.Visible = state end)
CreateToggle(SettingsOverlay, "UI Blur Effect", true, function(v) Blur.Enabled = v end)
CreateToggle(SettingsOverlay, "Background Particles", true, function(v) SetParticles(v, ParticleContainer) end)
SetParticles(true, ParticleContainer) 

local settingsOpen = false
CreateGroupedBtn("×", Color3.fromRGB(255, 50, 50), function() Gui:Destroy(); if Blur then Blur:Destroy() end end, 22)
CreateGroupedBtn("-", Color3.fromRGB(0, 120, 255), function() Main.Visible = false; RestoreBtn.Visible = true; Blur.Enabled = false end, 32)
CreateGroupedBtn("⚙", Theme.Text, function() settingsOpen = not settingsOpen; TweenService:Create(SettingsOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = settingsOpen and UDim2.new(0, 180, 0, 30) or UDim2.new(0, 180, 1, 0)}):Play() end, 18)
MinClick.MouseButton1Click:Connect(function() Main.Visible = true; RestoreBtn.Visible = false; Blur.Enabled = true end)

local function CreateTab(name, icon)
    local TabButton = Instance.new("TextButton", TabHolder); TabButton.Size = UDim2.new(1, -20, 0, 35); TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabButton.BackgroundTransparency = 1; TabButton.Text = icon .. "  " .. name; TabButton.Font = Enum.Font.GothamMedium; TabButton.TextColor3 = Theme.SubText; TabButton.TextSize = 13; TabButton.ZIndex = 4; Round(TabButton, 6)
    local Page = Instance.new("ScrollingFrame", Content); Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 0; Page.ZIndex = 5; Page.ClipsDescendants = false 
    local PageLayout = Instance.new("UIListLayout", Page); PageLayout.Padding = UDim.new(0, 12); PageLayout.HorizontalAlignment = "Center"
    TabButton.MouseButton1Click:Connect(function() for _, v in pairs(Pages) do v.Page.Visible = false; v.Button.BackgroundTransparency = 1; v.Button.TextColor3 = Theme.SubText end; Page.Visible = true; TabButton.BackgroundTransparency = 0.5; TabButton.TextColor3 = Theme.Accent end)
    Pages[name] = {Page = Page, Button = TabButton, Layout = PageLayout}
    return Page
end

local tabCombat  = CreateTab("Combat", "⚔️")
local tabPlayer  = CreateTab("Player", "👤")
local tabMove    = CreateTab("Movement", "🏃")
local tabVisuals = CreateTab("Visuals", "👁️")
local tabTP      = CreateTab("Tp player", "📍")
local tabMisc    = CreateTab("Misc", "🔧")

-- ====================================================
-- COMBAT TAB (FIXED SCROLL & STATIC AIM)
-- ====================================================
local BoxCombatBoost = CreateFeatureBox(tabCombat)
CreateSection(BoxCombatBoost, "Combat Booster")
CreateManualInput(BoxCombatBoost, "Hitbox Size", "2", function(v) PlayerConfig.HitboxSize = v end)
CreateToggle(BoxCombatBoost, "Enable Hitbox", false, function(v) PlayerConfig.HitboxEnabled = v end)

local function RefreshCombatPlayers()
    local names = {"[ None / All Players ]"} 
    for _, plr in pairs(Players:GetPlayers()) do 
        if plr ~= LP then table.insert(names, plr.Name) end 
    end
    return names
end

local function CreateDropdownFixed(parent, text, options, callback)
    local DropdownFrame = Instance.new("Frame", parent); DropdownFrame.Size = UDim2.new(1, -15, 0, 45); DropdownFrame.BackgroundTransparency = 1; DropdownFrame.ZIndex = 50
    local Label = Instance.new("TextLabel", DropdownFrame); Label.Size = UDim2.new(0.4, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Text = text; Label.Font = Enum.Font.Gotham; Label.TextColor3 = Theme.Text; Label.TextSize = 13; Label.TextXAlignment = "Left"; Label.BackgroundTransparency = 1; Label.ZIndex = 51
    local DropdownBtn = Instance.new("TextButton", DropdownFrame); DropdownBtn.Size = UDim2.new(0.55, 0, 0, 32); DropdownBtn.Position = UDim2.new(0.42, 0, 0.5, -16); DropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); DropdownBtn.Text = "Select Player..."; DropdownBtn.Font = Enum.Font.GothamBold; DropdownBtn.TextColor3 = Theme.Accent; DropdownBtn.TextSize = 12; DropdownBtn.ZIndex = 52; Round(DropdownBtn, 4)
    local BoxStroke = Instance.new("UIStroke", DropdownBtn); BoxStroke.Color = Theme.Stroke; BoxStroke.Thickness = 0.8
    
    local DropdownListScroll = Instance.new("ScrollingFrame", DropdownBtn); DropdownListScroll.Size = UDim2.new(1, 0, 0, 0); DropdownListScroll.Position = UDim2.new(0, 0, 1, 5); DropdownListScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25); DropdownListScroll.ZIndex = 1000; DropdownListScroll.Visible = false; DropdownListScroll.ScrollBarThickness = 2; DropdownListScroll.BorderSizePixel = 0; Round(DropdownListScroll, 4)
    local ListStroke = Instance.new("UIStroke", DropdownListScroll); ListStroke.Color = Theme.Accent; ListStroke.Thickness = 1
    local ListLayout = Instance.new("UIListLayout", DropdownListScroll); ListLayout.Padding = UDim.new(0, 2)
    
    local function UpdateOptions(newOptions)
        for _, child in pairs(DropdownListScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _, option in pairs(newOptions) do
            local OptionBtn = Instance.new("TextButton", DropdownListScroll); OptionBtn.Size = UDim2.new(1, 0, 0, 28); OptionBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); OptionBtn.BorderSizePixel = 0; OptionBtn.Text = option; OptionBtn.Font = Enum.Font.Gotham; OptionBtn.TextColor3 = Theme.Text; OptionBtn.TextSize = 11; OptionBtn.ZIndex = 1001
            OptionBtn.MouseButton1Click:Connect(function() 
                DropdownBtn.Text = option; 
                DropdownListScroll.Visible = false; 
                callback(option) 
            end)
        end
        -- FIX SCROLL CANVAS
        DropdownListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end
    
    UpdateOptions(options)
    DropdownBtn.MouseButton1Click:Connect(function()
        DropdownListScroll.Visible = not DropdownListScroll.Visible
        DropdownListScroll.Size = UDim2.new(1, 0, 0, math.min(ListLayout.AbsoluteContentSize.Y + 5, 120)) 
        DropdownListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        DropdownFrame.ZIndex = DropdownListScroll.Visible and 500 or 50 
    end)
    return {Frame = DropdownFrame, Update = UpdateOptions}
end

local function CreateButton(parent, text, callback)
    local ButtonFrame = Instance.new("Frame", parent); ButtonFrame.Size = UDim2.new(1, -15, 0, 40); ButtonFrame.BackgroundTransparency = 1; ButtonFrame.ZIndex = parent.ZIndex + 5
    local Button = Instance.new("TextButton", ButtonFrame); Button.Size = UDim2.new(1, 0, 0, 32); Button.Position = UDim2.new(0, 0, 0.5, -16); Button.BackgroundColor3 = Theme.Button; Button.Text = text; Button.Font = Enum.Font.GothamBold; Button.TextColor3 = Theme.Text; Button.TextSize = 12; Button.ZIndex = ButtonFrame.ZIndex + 1; Round(Button, 6)
    local ButtonStroke = Instance.new("UIStroke", Button); ButtonStroke.Color = Theme.Stroke; ButtonStroke.Thickness = 0.8
    Button.MouseButton1Click:Connect(callback)
    return ButtonFrame
end

local BoxAimbot = CreateFeatureBox(tabCombat)
CreateSection(BoxAimbot, "Aim Logic System")
CreateToggle(BoxAimbot, "Aim Bot 100% Lock", false, function(v) PlayerConfig.AimbotEnabled = v end)

local CombatDropdown = CreateDropdownFixed(BoxAimbot, "Lock Player", RefreshCombatPlayers(), function(selected) 
    if selected == "[ None / All Players ]" then
        PlayerConfig.TargetPlayer = nil
    else
        PlayerConfig.TargetPlayer = selected
    end
end)

CreateButton(BoxAimbot, "🔄 Refresh Player List", function() 
    CombatDropdown.Update(RefreshCombatPlayers()) 
end)

local AimNote = Instance.new("TextLabel", BoxAimbot); AimNote.Size = UDim2.new(1, -20, 0, 20); AimNote.Text = "Note: If no player selected, locks all visible"; AimNote.TextColor3 = Theme.SubText; AimNote.Font = Enum.Font.Gotham; AimNote.TextSize = 10; AimNote.BackgroundTransparency = 1

-- ====================================================
-- 👤 PLAYER TAB (RAPID GROUPED)
-- ====================================================
local BoxPlayerMenu = CreateFeatureBox(tabPlayer)
CreateSection(BoxPlayerMenu, "Player Environment & Stealth")

CreateToggle(BoxPlayerMenu, "Enable NoClip", false, function(v) PlayerConfig.NoClip = v end)
CreateToggle(BoxPlayerMenu, "Spin Bot Active", false, function(v) PlayerConfig.SpinBot = v end)
CreateToggle(BoxPlayerMenu, "Invisible (Real Fixed)", false, function(v) 
    PlayerConfig.Invisible = v 
    local Char = LP.Character
    if Char then
        for _, p in pairs(Char:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.Transparency = v and 1 or (p.Name == "HumanoidRootPart" and 1 or 0)
            end
        end
    end
end)
CreateToggle(BoxPlayerMenu, "God Mode (Semi)", false, function(v) PlayerConfig.GodMode = v end)
CreateToggle(BoxPlayerMenu, "Freeze Camera", false, function(v) PlayerConfig.FreezeCam = v; Camera.CameraType = v and Enum.CameraType.Scriptable or Enum.CameraType.Custom end)
CreateToggle(BoxPlayerMenu, "Fullbright", false, function(v) 
    PlayerConfig.Fullbright = v 
    if not v then
        Lighting.Ambient = OldLighting.Ambient
        Lighting.OutdoorAmbient = OldLighting.OutdoorAmbient
        Lighting.Brightness = OldLighting.Brightness
        Lighting.ClockTime = OldLighting.ClockTime
    end
end)

-- ====================================================
-- TP PLAYER TAB
-- ====================================================
local SelectedTPPlayer = nil
local function RefreshPlayerDropdown()
    local playerNames = {}
    for _, plr in pairs(Players:GetPlayers()) do if plr ~= LP then table.insert(playerNames, plr.Name) end end
    return playerNames
end

local BoxSelectPlayer = CreateFeatureBox(tabTP)
CreateSection(BoxSelectPlayer, "Target Player")
local PlayerDropdown = CreateDropdownFixed(BoxSelectPlayer, "Select Player", RefreshPlayerDropdown(), function(selected) SelectedTPPlayer = selected end)

local BoxTPButtons = CreateFeatureBox(tabTP)
CreateSection(BoxTPButtons, "Teleport Actions")
CreateButton(BoxTPButtons, "🚀 Teleport to Player", function()
    if SelectedTPPlayer then
        local target = Players:FindFirstChild(SelectedTPPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
        end
    end
end)
CreateButton(BoxTPButtons, "🔄 Refresh List", function() PlayerDropdown.Update(RefreshPlayerDropdown()) end)

local BoxTPAuto = CreateFeatureBox(tabTP)
CreateSection(BoxTPAuto, "Automation")
CreateToggle(BoxTPAuto, "Auto Follow (Smooth)", false, function(v) 
    PlayerConfig.AutoFollow = v 
    if v then
        task.spawn(function()
            while PlayerConfig.AutoFollow do
                local target = Players:FindFirstChild(SelectedTPPlayer or "")
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    LP.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0) 
                    LP.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end
end)
CreateToggle(BoxTPAuto, "Spectate Player", false, function(v)
    PlayerConfig.SpectatePlayer = v
    if SelectedTPPlayer then
        local target = Players:FindFirstChild(SelectedTPPlayer)
        if target then Camera.CameraSubject = v and (target.Character and target.Character:FindFirstChild("Humanoid") or target.Character) or (LP.Character and LP.Character:FindFirstChild("Humanoid")) end
    end
end)

-- ====================================================
-- VISUALS TAB
-- ====================================================
local BoxESP = CreateFeatureBox(tabVisuals)
CreateSection(BoxESP, "ESP Player")
CreateToggle(BoxESP, "ESP Name", false, function(v) ESP_Config.Name = v end)
CreateToggle(BoxESP, "ESP Darah", false, function(v) ESP_Config.Health = v end)
CreateToggle(BoxESP, "ESP Jarak", false, function(v) ESP_Config.Distance = v end)
CreateToggle(BoxESP, "ESP Line atau Garis Garis", false, function(v) ESP_Config.Lines = v end)
CreateToggle(BoxESP, "ESP Skeleton", false, function(v) ESP_Config.Skeleton = v end)

-- ====================================================
-- MOVEMENT TAB
-- ====================================================
local MovementVars = { WS_Enabled = false, WS_Amount = 16, JP_Enabled = false, JP_Amount = 50, InfJump = false }
local BoxMoveConfig = CreateFeatureBox(tabMove)
CreateSection(BoxMoveConfig, "Movement Config")
CreateManualInput(BoxMoveConfig, "Walkspeed Set", "16", function(val) MovementVars.WS_Amount = val end)
CreateToggle(BoxMoveConfig, "Enable Walkspeed", false, function(v) MovementVars.WS_Enabled = v; if not v then pcall(function() LP.Character.Humanoid.WalkSpeed = 16 end) end end)
CreateManualInput(BoxMoveConfig, "JumpPower Set", "50", function(val) MovementVars.JP_Amount = val end)
CreateToggle(BoxMoveConfig, "Enable JumpPower", false, function(v) MovementVars.JP_Enabled = v; if v then pcall(function() LP.Character.Humanoid.UseJumpPower = true end) else pcall(function() LP.Character.Humanoid.JumpPower = 50 end) end end)
CreateToggle(BoxMoveConfig, "Infinity Jump", false, function(v) MovementVars.InfJump = v end)

-- ====================================================
-- MISC TAB
-- ====================================================
local BoxEmote = CreateFeatureBox(tabMisc)
CreateSection(BoxEmote, "Extra Scripts")
CreateButton(BoxEmote, "🎭 Load Script Emote", function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-AFEM-Max-Open-Alpha-50210"))() end)

local BoxGraphic = CreateFeatureBox(tabMisc)
CreateSection(BoxGraphic, "Graphics Booster")
CreateButton(BoxGraphic, "✨ Load Script Grafik", function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-pshade-ultimate-25505"))() end)

local BoxServer = CreateFeatureBox(tabMisc)
CreateSection(BoxServer, "Server Management")
CreateToggle(BoxServer, "Anti-AFK 100% Work", false, function(v) PlayerConfig.AntiAFK = v end)
CreateButton(BoxServer, "🌀 Respawn Character", function() LP.Character:BreakJoints() end)
CreateButton(BoxServer, "🌍 Server Hop", function()
    local Http = game:GetService("HttpService")
    local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    local function NextServer()
        local _v = Http:JSONDecode(game:HttpGet(Api))
        for _, server in pairs(_v.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                break
            end
        end
    end
    NextServer()
end)
CreateButton(BoxServer, "⚡ Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)

-- ====================================================
-- CORE LOGIC LOOP (FIXED STATIC AIM LOCK)
-- ====================================================
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- STATIC 100% AIMBOT LOCK (STABILIZED)
        if PlayerConfig.AimbotEnabled then
            local target = GetBestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                -- Memperbaiki Fokus Kamera ke Target tanpa merusak rotasi karakter sendiri
                local targetPos = target.Character.Head.Position
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            end
        end

        -- Update UI Canvas Sizes
        for _, data in pairs(Pages) do 
            if data.Page and data.Layout then 
                data.Page.CanvasSize = UDim2.new(0, 0, 0, data.Layout.AbsoluteContentSize.Y + 20) 
            end 
        end
    end)
end)

RunService.Stepped:Connect(function()
    pcall(function()
        local Char = LP.Character
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        
        if Hum then
            if MovementVars.WS_Enabled then Hum.WalkSpeed = MovementVars.WS_Amount end
            if MovementVars.JP_Enabled then Hum.JumpPower = MovementVars.JP_Amount end
        end

        if PlayerConfig.NoClip and Char then
            for _, v in pairs(Char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
        if PlayerConfig.SpinBot and Char and Char:FindFirstChild("HumanoidRootPart") then
            Char.HumanoidRootPart.CFrame = Char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(25), 0)
        end
        if PlayerConfig.HitboxEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = p.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(PlayerConfig.HitboxSize, PlayerConfig.HitboxSize, PlayerConfig.HitboxSize)
                    hrp.Transparency = 0.7; hrp.Color = Theme.Accent; hrp.CanCollide = false
                end
            end
        end
    end)
end)

UIS.JumpRequest:Connect(function() if MovementVars.InfJump then pcall(function() LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end) end end)

RunService.RenderStepped:Connect(function()
    if ParticlesActive then
        for _, p in pairs(ParticleList) do
            local pos = p.obj.Position; local nX, nY = pos.X.Scale + p.vel.X, pos.Y.Scale + p.vel.Y
            if nX > 1 then nX = 0 elseif nX < 0 then nX = 1 end
            if nY > 1 then nY = 0 elseif nY < 0 then nY = 1 end
            p.obj.Position = UDim2.new(nX, 0, nY, 0)
        end
    end
    SettingsOverlay.CanvasSize = UDim2.new(0, 0, 0, SettingsLayout.AbsoluteContentSize.Y + 20)
    TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
end)

Pages["Combat"].Button.BackgroundTransparency = 0.5; Pages["Combat"].Button.TextColor3 = Theme.Accent; Pages["Combat"].Page.Visible = true

print("Ciphub V99 Updated: Tab Player Grouped & Static Aim Fix Loaded! 🌊")
