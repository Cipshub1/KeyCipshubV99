--====================================================
-- 🌊 CIPHUB V99 | UPDATED: REFRESH LIST + FIX INVIS + SMART AIM 🌊
-- STATUS: FIXED INVISIBLE + REFRESH LIST + SMART VISIBILITY LOCK
--====================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
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
    BodyLock = false
}

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
-- SMART AIMBOT VISIBILITY ENGINE (FIXED)
-- ====================================================
local function IsVisible(targetPart)
    if not targetPart or not LP.Character then return false end
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = (destination - origin).Unit * (destination - origin).Magnitude
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Abaikan karakter sendiri agar tidak menghalangi raycast
    params.FilterDescendantsInstances = {LP.Character, Camera}
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)
    
    -- Jika tidak ada hambatan, atau hambatan adalah bagian dari karakter musuh
    if not result or result.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

local function GetClosestVisiblePlayer()
    local target = nil
    local shortestDist = math.huge
    
    -- Prioritas manual target
    if PlayerConfig.TargetPlayer and PlayerConfig.TargetPlayer.Character and PlayerConfig.TargetPlayer.Character:FindFirstChild("Head") then
        local head = PlayerConfig.TargetPlayer.Character.Head
        local _, onScreen = Camera:WorldToViewportPoint(head.Position)
        if onScreen and IsVisible(head) then
            return PlayerConfig.TargetPlayer
        end
    end

    -- Auto find closest on screen
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LP and v.Character and v.Character:FindFirstChild("Head") then
            local head = v.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen and IsVisible(head) then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if mag < shortestDist then
                    shortestDist = mag
                    target = v
                end
            end
        end
    end
    return target
end

-- ====================================================
-- ESP & PARTICLES & DRAGGABLE (Omitted for brevity, kept in full script)
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
local TabHolder = Instance.new("ScrollingFrame", Sidebar); TabHolder.Size = UDim2.new(1, 0, 1, -120); TabHolder.Position = UDim2.new(0, 0, 0, 60); TabHolder.BackgroundTransparency = 1; TabHolder.ScrollBarThickness = 0; TabHolder.ZIndex = 3
local TabListLayout = Instance.new("UIListLayout", TabHolder); TabListLayout.Padding = UDim.new(0, 5); TabListLayout.HorizontalAlignment = "Center"

local LogoArea = Instance.new("Frame", Sidebar); LogoArea.Size = UDim2.new(1, 0, 0, 60); LogoArea.BackgroundTransparency = 1; LogoArea.ZIndex = 3
local LogoText = Instance.new("TextLabel", LogoArea); LogoText.Size = UDim2.new(1, -20, 0, 30); LogoText.Position = UDim2.new(0, 15, 0, 15); LogoText.RichText = true; LogoText.Text = 'Ciphub<font color="rgb(0, 200, 255)">V99</font>'; LogoText.Font = Enum.Font.GothamBold; LogoText.TextColor3 = Theme.Text; LogoText.TextSize = 20; LogoText.TextXAlignment = "Left"; LogoText.BackgroundTransparency = 1; LogoText.ZIndex = 4

local Content = Instance.new("Frame", Main); Content.Size = UDim2.new(1, -195, 1, -40); Content.Position = UDim2.new(0, 190, 0, 40); Content.BackgroundTransparency = 1; Content.ZIndex = 2
local Pages = {}

local UserPanel = Instance.new("Frame", Sidebar); UserPanel.Name = "UserPanel"; UserPanel.Size = UDim2.new(1, -16, 0, 50); UserPanel.Position = UDim2.new(0, 8, 1, -60); UserPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 22); UserPanel.ZIndex = 3; Round(UserPanel, 8)
Instance.new("UIStroke", UserPanel).Color = Theme.Stroke
local AvatarImg = Instance.new("ImageLabel", UserPanel); AvatarImg.Size = UDim2.fromOffset(36, 36); AvatarImg.Position = UDim2.new(0, 7, 0.5, -18); AvatarImg.BackgroundColor3 = Color3.fromRGB(35, 35, 35); AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150"; AvatarImg.ZIndex = 4; Round(AvatarImg, 100)
local DisplayNameLabel = Instance.new("TextLabel", UserPanel); DisplayNameLabel.Size = UDim2.new(1, -60, 0, 15); DisplayNameLabel.Position = UDim2.new(0, 50, 0.5, -14); DisplayNameLabel.Text = LP.DisplayName; DisplayNameLabel.Font = Enum.Font.GothamBold; DisplayNameLabel.TextColor3 = Theme.Text; DisplayNameLabel.TextSize = 11; DisplayNameLabel.TextXAlignment = "Left"; DisplayNameLabel.BackgroundTransparency = 1; DisplayNameLabel.ZIndex = 4; DisplayNameLabel.ClipsDescendants = true
local UsernameLabel = Instance.new("TextLabel", UserPanel); UsernameLabel.Size = UDim2.new(1, -60, 0, 15); UsernameLabel.Position = UDim2.new(0, 50, 0.5, 0); UsernameLabel.Text = "@"..LP.Name; UsernameLabel.Font = Enum.Font.Gotham; UsernameLabel.TextColor3 = Theme.SubText; UsernameLabel.TextSize = 9; UsernameLabel.TextXAlignment = "Left"; UsernameLabel.BackgroundTransparency = 1; UsernameLabel.ZIndex = 4; UsernameLabel.ClipsDescendants = true

local SettingsOverlay = Instance.new("ScrollingFrame", Main); SettingsOverlay.Name = "SettingsOverlay"; SettingsOverlay.Size = UDim2.new(1, -180, 1, -30); SettingsOverlay.Position = UDim2.new(0, 180, 1, 0); SettingsOverlay.BackgroundColor3 = Theme.Main; SettingsOverlay.ZIndex = 200; SettingsOverlay.BorderSizePixel = 0; SettingsOverlay.ScrollBarThickness = 0; SettingsOverlay.ClipsDescendants = true
local SettingsLayout = Instance.new("UIListLayout", SettingsOverlay); SettingsLayout.Padding = UDim.new(0, 10)
local SettingsPadding = Instance.new("UIPadding", SettingsOverlay); SettingsPadding.PaddingLeft = UDim.new(0, 15); SettingsPadding.PaddingTop = UDim.new(0, 10)

CreateSection(SettingsOverlay, "UI Settings")
CreateToggle(SettingsOverlay, "UI Transparan", false, function(state) local trans = state and 0.3 or 0; TweenService:Create(Main, TweenInfo.new(0.3), {BackgroundTransparency = trans}):Play(); TweenService:Create(Sidebar, TweenInfo.new(0.3), {BackgroundTransparency = trans}):Play() end)
CreateToggle(SettingsOverlay, "Show Avatar Profile", true, function(state) UserPanel.Visible = state end)
CreateToggle(SettingsOverlay, "UI Blur Effect", true, function(v) Blur.Enabled = v end)
CreateToggle(SettingsOverlay, "Background Particles", false, function(v) SetParticles(v, ParticleContainer) end)

local settingsOpen = false
CreateGroupedBtn("×", Color3.fromRGB(255, 50, 50), function() Gui:Destroy(); if Blur then Blur:Destroy() end end, 22)
CreateGroupedBtn("-", Color3.fromRGB(0, 120, 255), function() Main.Visible = false; RestoreBtn.Visible = true; Blur.Enabled = false end, 32)
CreateGroupedBtn("⚙", Theme.Text, function() settingsOpen = not settingsOpen; TweenService:Create(SettingsOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = settingsOpen and UDim2.new(0, 180, 0, 30) or UDim2.new(0, 180, 1, 0)}):Play() end, 18)
MinClick.MouseButton1Click:Connect(function() Main.Visible = true; RestoreBtn.Visible = false; Blur.Enabled = true end)

local function CreateTab(name, icon)
    local TabButton = Instance.new("TextButton", TabHolder); TabButton.Size = UDim2.new(1, -20, 0, 35); TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabButton.BackgroundTransparency = 1; TabButton.Text = icon .. "  " .. name; TabButton.Font = Enum.Font.GothamMedium; TabButton.TextColor3 = Theme.SubText; TabButton.TextSize = 13; TabButton.ZIndex = 4; Round(TabButton, 6)
    local Page = Instance.new("ScrollingFrame", Content); Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 0; Page.ZIndex = 5
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
-- COMBAT TAB
-- ====================================================
local BoxCombatBoost = CreateFeatureBox(tabCombat)
CreateSection(BoxCombatBoost, "Combat Booster")
CreateManualInput(BoxCombatBoost, "Hitbox Size", "2", function(v) PlayerConfig.HitboxSize = v end)
CreateToggle(BoxCombatBoost, "Enable Hitbox", false, function(v) PlayerConfig.HitboxEnabled = v end)

local BoxAimbot = CreateFeatureBox(tabCombat)
CreateSection(BoxAimbot, "Aim Logic System")
CreateToggle(BoxAimbot, "Aim Bot 100% Lock", false, function(v) PlayerConfig.AimbotEnabled = v end)
local AimNote = Instance.new("TextLabel", BoxAimbot); AimNote.Size = UDim2.new(1, -20, 0, 20); AimNote.Text = "Lock only if enemy is visible"; AimNote.TextColor3 = Theme.SubText; AimNote.Font = Enum.Font.Gotham; AimNote.TextSize = 10; AimNote.BackgroundTransparency = 1

-- ====================================================
-- PLAYER TAB (FIXED INVISIBLE)
-- ====================================================
local BoxPlayerConfig = CreateFeatureBox(tabPlayer)
CreateSection(BoxPlayerConfig, "Karakter Config")
CreateToggle(BoxPlayerConfig, "NoClip", false, function(v) PlayerConfig.NoClip = v end)
CreateToggle(BoxPlayerConfig, "Spin Bot", false, function(v) PlayerConfig.SpinBot = v end)

CreateToggle(BoxPlayerConfig, "Invisible (Real Fixed)", false, function(v) 
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

CreateToggle(BoxPlayerConfig, "God Mode (Semi)", false, function(v) PlayerConfig.GodMode = v end)
CreateToggle(BoxPlayerConfig, "Freeze Camera", false, function(v) PlayerConfig.FreezeCam = v; Camera.CameraType = v and Enum.CameraType.Scriptable or Enum.CameraType.Custom end)

-- ====================================================
-- TP PLAYER TAB (NEW: REFRESH LIST)
-- ====================================================
local BoxTPSelect = CreateFeatureBox(tabTP)
CreateSection(BoxTPSelect, "Target System")

local TargetLabel = Instance.new("TextLabel", BoxTPSelect); TargetLabel.Size = UDim2.new(1, -20, 0, 30); TargetLabel.Text = "Target: None"; TargetLabel.TextColor3 = Theme.Accent; TargetLabel.Font = Enum.Font.GothamBold; TargetLabel.TextSize = 12; TargetLabel.BackgroundTransparency = 1

local ListContainer = Instance.new("Frame", BoxTPSelect); ListContainer.Size = UDim2.new(1, -20, 0, 0); ListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12); ListContainer.ClipsDescendants = true; Round(ListContainer, 6)
local ListStroke = Instance.new("UIStroke", ListContainer); ListStroke.Color = Theme.Accent; ListStroke.Transparency = 0.8

local PlayerScroll = Instance.new("ScrollingFrame", ListContainer); PlayerScroll.Size = UDim2.new(1, 0, 1, -40); PlayerScroll.Position = UDim2.new(0, 0, 0, 5); PlayerScroll.BackgroundTransparency = 1; PlayerScroll.ScrollBarThickness = 4; PlayerScroll.ScrollBarImageColor3 = Theme.Accent; PlayerScroll.CanvasSize = UDim2.new(0,0,0,0)
local ScrollLayout = Instance.new("UIListLayout", PlayerScroll); ScrollLayout.Padding = UDim.new(0, 5); ScrollLayout.HorizontalAlignment = "Center"

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 10) end)

local function UpdatePlayerList()
    for _, child in pairs(PlayerScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local pBtn = Instance.new("TextButton", PlayerScroll)
            pBtn.Size = UDim2.new(0.9, 0, 0, 30); pBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); pBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"; pBtn.Font = Enum.Font.GothamMedium; pBtn.TextColor3 = Color3.new(1, 1, 1); pBtn.TextSize = 10; pBtn.ZIndex = 20; Round(pBtn, 4)
            pBtn.MouseButton1Click:Connect(function() PlayerConfig.TargetPlayer = p; TargetLabel.Text = "Target: " .. p.Name end)
        end
    end
end

local listOpen = false
local function CreateTPBtn(parent, text, callback)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(1, -20, 0, 35); btn.BackgroundColor3 = Theme.Button; btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Theme.Text; btn.TextSize = 11; btn.ZIndex = 10; Round(btn, 4)
    btn.MouseButton1Click:Connect(callback); return btn
end

CreateTPBtn(BoxTPSelect, "Open/Close Player List", function()
    listOpen = not listOpen; UpdatePlayerList()
    TweenService:Create(ListContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = listOpen and UDim2.new(1, -20, 0, 180) or UDim2.new(1, -20, 0, 0)}):Play()
end)

-- ADDED: REFRESH BUTTON INSIDE LIST
local RefreshBtn = Instance.new("TextButton", ListContainer)
RefreshBtn.Size = UDim2.new(1, -10, 0, 25); RefreshBtn.Position = UDim2.new(0, 5, 1, -30); RefreshBtn.BackgroundColor3 = Color3.fromRGB(40,40,40); RefreshBtn.Text = "🔄 Refresh List"; RefreshBtn.Font = Enum.Font.GothamBold; RefreshBtn.TextColor3 = Theme.Accent; RefreshBtn.TextSize = 10; Round(RefreshBtn, 4)
RefreshBtn.MouseButton1Click:Connect(UpdatePlayerList)

local BoxBodyLock = CreateFeatureBox(tabTP)
CreateSection(BoxBodyLock, "Body Lock")
CreateToggle(BoxBodyLock, "Enable Body Lock Behind", false, function(v) PlayerConfig.BodyLock = v end)

-- ====================================================
-- VISUALS, MOVE, MISC (Kept from original)
-- ====================================================
local BoxESP = CreateFeatureBox(tabVisuals)
CreateSection(BoxESP, "ESP Player")
CreateToggle(BoxESP, "ESP Name", false, function(v) ESP_Config.Name = v end)
CreateToggle(BoxESP, "ESP Darah", false, function(v) ESP_Config.Health = v end)
CreateToggle(BoxESP, "ESP Jarak", false, function(v) ESP_Config.Distance = v end)
CreateToggle(BoxESP, "ESP Line atau Garis Garis", false, function(v) ESP_Config.Lines = v end)
CreateToggle(BoxESP, "ESP Musuh atau Teman (TeamCheck)", false, function(v) ESP_Config.TeamCheck = v end)
CreateToggle(BoxESP, "ESP Skeleton", false, function(v) ESP_Config.Skeleton = v end)

local MovementVars = { WS_Enabled = false, WS_Amount = 16, JP_Enabled = false, JP_Amount = 50, InfJump = false }
local BoxMoveConfig = CreateFeatureBox(tabMove)
CreateSection(BoxMoveConfig, "Movement Config")
CreateManualInput(BoxMoveConfig, "Walkspeed Set", "16", function(val) MovementVars.WS_Amount = val end)
CreateToggle(BoxMoveConfig, "Enable Walkspeed", false, function(v) MovementVars.WS_Enabled = v if not v then pcall(function() LP.Character.Humanoid.WalkSpeed = 16 end) end end)
CreateManualInput(BoxMoveConfig, "JumpPower Set", "50", function(val) MovementVars.JP_Amount = val end)
CreateToggle(BoxMoveConfig, "Enable Jump Power", false, function(v) MovementVars.JP_Enabled = v if not v then pcall(function() LP.Character.Humanoid.JumpPower = 50 end) end end)
CreateToggle(BoxMoveConfig, "Infinity Jump", false, function(v) MovementVars.InfJump = v end)

local BoxEmote = CreateFeatureBox(tabMisc)
CreateSection(BoxEmote, "Extra Scripts")
CreateTPBtn(BoxEmote, "Load script emote", function() task.spawn(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-AFEM-Max-Open-Alpha-50210"))() end) end)
local BoxGraphic = CreateFeatureBox(tabMisc)
CreateSection(BoxGraphic, "Graphics Booster")
CreateTPBtn(BoxGraphic, "Load script Grafik", function() task.spawn(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-pshade-ultimate-25505"))() end) end)

-- ====================================================
-- CORE LOGIC LOOP
-- ====================================================
RunService.Stepped:Connect(function()
    pcall(function()
        local Char = LP.Character
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        
        if Hum then
            if MovementVars.WS_Enabled then Hum.WalkSpeed = MovementVars.WS_Amount end
            if MovementVars.JP_Enabled then Hum.JumpPower = MovementVars.JP_Amount end
            if PlayerConfig.GodMode then Hum.Health = 100 end
        end

        -- SMART VISIBILITY AIMBOT
        if PlayerConfig.AimbotEnabled then
            local target = GetClosestVisiblePlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local headPos = target.Character.Head.Position
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, headPos)
            end
        end

        if PlayerConfig.BodyLock and PlayerConfig.TargetPlayer and PlayerConfig.TargetPlayer.Character then
            local targetRoot = PlayerConfig.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = Char:FindFirstChild("HumanoidRootPart")
            if targetRoot and myRoot then myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3) end
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
    for _, data in pairs(Pages) do if data.Page and data.Layout then data.Page.CanvasSize = UDim2.new(0, 0, 0, data.Layout.AbsoluteContentSize.Y + 20) end end
    SettingsOverlay.CanvasSize = UDim2.new(0, 0, 0, SettingsLayout.AbsoluteContentSize.Y + 20)
    TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
end)

Pages["Combat"].Button.BackgroundTransparency = 0.5; Pages["Combat"].Button.TextColor3 = Theme.Accent; Pages["Combat"].Page.Visible = true

print("Ciphub V99: Refreshed & Optimized! 🌊")
