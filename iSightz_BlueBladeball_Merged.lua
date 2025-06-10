-- iSightz Ware Bladeball Script
-- Enhanced with features from cele2stia.lua.txt and sillly hub source.txt.
-- Custom black UI with white text, improved auto-parry, and various functionalities.

-->> SERVICES <<--
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService('GuiService')
local Stats = game:GetService('Stats')
local SoundService = game:GetService('SoundService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')
local Network = game:GetService('Network')

local Player = Players.LocalPlayer
local mouse = Player:GetMouse()

-->> GLOBAL VARIABLES <<--
getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled", CheckboxDisabled = "Disabled",
        SliderValue = "Value", DropdownSelect = "Select",
        DropdownNone = "None", DropdownSelected = "Selected",
        ButtonClick = "Click", TextboxEnter = "Enter",
        ModuleEnabled = "Enabled", ModuleDisabled = "Disabled",
        TabGeneral = "General", TabSettings = "Settings",
        Loading = "Loading...", Error = "Error", Success = "Success"
    }
}
local SelectedLanguage = GG.Language

local Tornado_Time = tick()
local Previous_Positions = {}
local Last_Parry = 0
local CurrentBall = nil
local InputTask = nil

-- getgenv flags for features
getgenv().AutoParry = true
getgenv().RandomParryAccuracyEnabled = false
getgenv().ParryThreshold = 15
getgenv().ParryKey = "F_Key"
getgenv().InfinityDetection = false
getgenv().PhantomV2Detection = false
getgenv().TimeHoleDetection = false
getgenv().FlyEnabled = false
getgenv().FlySpeed = 50
getgenv().NoClipEnabled = false
getgenv().AntiRagdollEnabled = false
getgenv().SilentAimEnabled = false
getgenv().SilentAimFOV = 90
getgenv().SilentAimTargetPart = "HumanoidRootPart"
getgenv().SilentAimSmoothness = 0.5
getgenv().SilentAimPingCorrection = false
getgenv().SilentAimVisibleOnly = false
getgenv().SilentAimPredict = false
getgenv().SilentAimDistance = 100
getgenv().SilentAimVelocity = 50
getgenv().HitboxExpanderEnabled = false
getgenv().HitboxExpanderSize = 1.2
getgenv().AutoClickerEnabled = false
getgenv().AutoClickerDelay = 0.05
getgenv().AutoClickerButton = Enum.UserInputType.MouseButton1
getgenv().AutoAbility = false
getgenv().CooldownProtection = false
getgenv().ThunderDashNoCooldown = false
getgenv().ContinuityZeroExploit = false
getgenv().AbilityESP = false
getgenv().WorldFilterEnabled = false
getgenv().AtmosphereEnabled = false
getgenv().FogEnabled = false
getgenv().SaturationEnabled = false
getgenv().HueEnabled = false
getgenv().soundmodule = false
getgenv().hit_Sound_Enabled = false
getgenv().HitSoundVolume = 0.5
getgenv().AutoVote = false
getgenv().AutoServerHop = false
getgenv().skinChanger = false
getgenv().swordModel = ""
getgenv().swordAnimations = ""
getgenv().swordFX = ""

-- Auto Parry Logic
local Auto_Parry = {}

function Auto_Parry.Get_Ball()
    for _, ball in Workspace.Balls:GetChildren() do
        if ball:IsA("Part") and ball.Name == "Ball" then
            return ball
        end
    end
    return nil
end

function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then return false end

    table.insert(Previous_Positions, {Position = Ball.Position, Time = tick()})
    for i = #Previous_Positions, 1, -1 do
        if tick() - Previous_Positions[i].Time > 0.1 then
            table.remove(Previous_Positions, i)
        end
    end

    if #Previous_Positions < 3 then return false end

    local p1 = Previous_Positions[#Previous_Positions].Position
    local p2 = Previous_Positions[#Previous_Positions - 1].Position
    local p3 = Previous_Positions[#Previous_Positions - 2].Position

    local v1 = (p1 - p2).Unit
    local v2 = (p2 - p3).Unit

    return v1:Dot(v2) < 0.95
end

function Auto_Parry.Parry(parryType)
    if tick() - Last_Parry < 0.02 then return end

    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    if parryType == 'F_Key' then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    elseif parryType == 'Click' then
        VirtualInputManager:SendMouseEvent(mouse.X, mouse.Y, 0, true, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseEvent(mouse.X, mouse.Y, 0, false, 0)
    elseif parryType == 'Remotes' then
        -- Placeholder for game-specific remote event calls.
        -- ReplicatedStorage.Remotes.ParryEvent:FireServer()
        Library.SendNotification({title = "Auto-Parry Warning", text = "Remote parry type selected, but no remote implemented.", duration = 3})
    end
    Last_Parry = tick()
end

RunService.RenderStepped:Connect(function()
    if not getgenv().AutoParry then return end

    local Ball = Auto_Parry.Get_Ball()
    if not Ball or not Ball:FindFirstChild('zoomies') then
        CurrentBall = nil
        return
    end
    CurrentBall = Ball

    local Primary_Part = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Primary_Part then return end

    local Zoomies = Ball:FindFirstChild('zoomies')
    if not Zoomies then return end

    local Speed = Zoomies.VectorVelocity.Magnitude
    local Distance = (Primary_Part.Position - Ball.Position).Magnitude
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local Direction = (Primary_Part.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Pings = Network.ServerStatsItem['Data Ping']:GetValue() or 0.1

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = getgenv().ParryThreshold - math.min(Distance / 1000, getgenv().ParryThreshold) + Speed_Threshold

    if Enough_Speed and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    local Curve_Detected = Auto_Parry.Is_Curved()
    local canParry = false
    if Distance <= Ball_Distance_Threshold and Dot > -0.25 then
        if Curve_Detected or not getgenv().InfinityDetection then
            canParry = true
        end
    end

    if getgenv().RandomParryAccuracyEnabled and canParry then
        if math.random() > 0.8 then
            canParry = false
        end
    end

    if canParry then
        Auto_Parry.Parry(getgenv().ParryKey)
    end
end)

-- Old Remote Event Handlers
ReplicatedStorage.Remotes.PassAll.OnClientEvent:Connect(function(a, b)
    local Primary_Part = Player.Character and Player.Character.PrimaryPart
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then return end
    local Zoomies = Ball:FindFirstChild('zoomies')
    if not Zoomies then return end

    local Speed = Zoomies.VectorVelocity.Magnitude
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Pings = Network.ServerStatsItem['Data Ping']:GetValue()

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold

    if Enough_Speed and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end
    if b ~= Primary_Part and Distance > Ball_Distance_Threshold then
        Tornado_Time = tick()
    end
end)

ReplicatedStorage.Remotes.Phantom.OnClientEvent:Connect(function(a, b)
    if getgenv().PhantomV2Detection then
        Library.SendNotification({title = "Phantom Detected!", text = "Phantom V2 detected, attempting countermeasures.", duration = 2})
    end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    Last_Parry = tick()
end)

workspace.Balls.ChildAdded:Connect(function(newBall)
    if newBall:IsA("Part") and newBall.Name == "Ball" then
        CurrentBall = newBall
    end
end)

-- Connection management
local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then return end
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for key, value in pairs(self) do
            if typeof(value) == 'RBXScriptConnection' and value.Connected then
                value:Disconnect()
            end
            self[key] = nil
        end
    end
}, {__index = {}})

-- General utility functions
local Util = setmetatable({
    map = function(self, value, in_minimum, in_maximum, out_minimum, out_maximum)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self, location, distance)
        local unit_ray = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self)
        local viewport_size_Y = Workspace.CurrentCamera.ViewportSize.Y
        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, {__index = {}})

-- Acrylic Blur Effect
local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(object)
    local self = setmetatable({ _object = object, _folder = nil, _frame = nil, _root = nil }, AcrylicBlur)
    self:setup()
    return self
end

function AcrylicBlur:create_folder()
    local old_folder = Workspace.CurrentCamera:FindFirstChild('AcrylicBlur')
    if old_folder then Debris:AddItem(old_folder, 0) end
    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = Workspace.CurrentCamera
    self._folder = folder
end

function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting
    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then continue end
        if object == depth_of_fields then continue end
        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)
        object.FarIntensity = 0
    end
end

function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object
    self._frame = frame
end

function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder

    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)
    specialMesh.Parent = part
    self._root = part
end

function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    self:create_frame()
    self:render(0.001)
    self:check_quality_level()
end

function AcrylicBlur:render(distance)
    local positions = { top_left = Vector2.new(), top_right = Vector2.new(), bottom_right = Vector2.new() }

    local function update_positions(size, position)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then return end
        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, Workspace.CurrentCamera.CFrame.XVector, Workspace.CurrentCamera.CFrame.YVector, Workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(on_change)
    Connections['field_of_view_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)
    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    task.spawn(on_change)
end

function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then self:change_visiblity(false) end
    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local quality_level = UserSettings().GameSettings.SavedQualityLevel.Value
        self:change_visiblity(quality_level >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state)
    self._root.Transparency = state and 0.98 or 1
end

-- Configuration saving/loading
local Config = setmetatable({
    save = function(self, file_name, config)
        pcall(function()
            local flags = HttpService:JSONEncode(config)
            if not isfolder("Silly") then makefolder("Silly") end
            writefile('Silly/'..file_name..'.json', flags)
        end)
    end,
    load = function(self, file_name, config)
        local success_load, result = pcall(function()
            if not isfolder("Silly") then makefolder("Silly") end
            if not isfile('Silly/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile('Silly/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success_load or not result then
            result = { _flags = {}, _keybinds = {}, _library = {} }
        end
        return result
    end
}, {__index = {}})

-- Main UI Library
local Library = {
    _config = Config:load(game.GameId),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library

function Library.new()
    local self = setmetatable({ _loaded = false, _tab = 0 }, Library)
    self:create_ui()

    Connections['ui_toggle_keybind'] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightAlt and not gameProcessed then
            self:UIVisiblity()
        end
    end)
    return self
end

-- Notification System
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = CoreGui
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 60)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer
    Notification.AutomaticSize = Enum.AutomaticSize.Y

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    InnerFrame.BackgroundTransparency = 0.2
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification Title"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.AutomaticSize = Enum.AutomaticSize.Y
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "This is the body of the notification."
    Body.TextColor3 = Color3.fromRGB(200, 200, 200)
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = InnerFrame

    task.spawn(function()
        task.wait(0.1)
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end)

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, NotificationContainer.AbsoluteSize.Y.Offset - InnerFrame.AbsoluteSize.Y.Offset)
        })
        tweenIn:Play()

        local duration = settings.duration or 5
        task.wait(duration)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, InnerFrame.Position.Y.Offset)
        })
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

function Library:get_screen_scale()
    self._ui_scale = Workspace.CurrentCamera.ViewportSize.X / 1400
end

function Library:get_device()
    local device = 'Unknown'
    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end
    self._device = device
end

function Library:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:create_ui()
    local existingScreenGui = CoreGui:FindFirstChild('iSightzWareScript')
    if existingScreenGui then existingScreenGui:Destroy() end
    local oldSilly = CoreGui:FindFirstChild('Silly')
    if oldSilly then oldSilly:Destroy() end

    local Silly = Instance.new('ScreenGui')
    Silly.ResetOnSpawn = false
    Silly.Name = 'iSightzWareScript'
    Silly.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Silly.Parent = CoreGui
    Silly.Enabled = true -- Make UI visible by default

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 698, 0, 479) -- Start at full size
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Silly
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(50, 50, 50)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextTransparency = 0.1
    ClientName.Text = 'iSightz Ware'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 100, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.056, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    UIGradient.Parent = ClientName
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026, 0, 0.136, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.025, 0, 0.055, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Handler
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.235, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.02, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = Silly

    local function on_drag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position
            Connections['container_input_ended_drag'] = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 or inputEnded.UserInputType == Enum.UserInputType.Touch then
                    self._dragging = false
                    Connections:disconnect('container_input_ended_drag')
                end
            end)
        end
    end

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
        TweenService:Create(Container, TweenInfo.new(0.2), {Position = position}):Play()
    end

    local function drag(input, process)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began_drag'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed_drag'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a)
            end)
        end
    end

    function self:UIVisiblity()
        Silly.Enabled = not Silly.Enabled
        self:change_visiblity(Silly.Enabled)
    end

    function self:change_visiblity(state)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
    
    function self:load()
        local content = {}
        for _, object in Silly:GetDescendants() do
            if object:IsA('ImageLabel') then
                table.insert(content, object)
            end
        end
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            Connections['ui_scale_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
        AcrylicBlur.new(Container)
        self._ui_loaded = true
    end

    function self:update_tabs(tab, left_section_frame, right_section_frame)
        for _, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then continue end
            local section_order = object.LayoutOrder
            local left_section = Sections:FindFirstChild('LeftSection' .. section_order)
            local right_section = Sections:FindFirstChild('RightSection' .. section_order)

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)
                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    
                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()
                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.1, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Offset = Vector2.new(1, 0)}):Play()
                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.1, ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end
                if left_section then left_section.Visible = true end
                if right_section then right_section.Visible = true end
                continue
            end
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.7, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Offset = Vector2.new(0, 0)}):Play()
                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.8, ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end
            if left_section then left_section.Visible = false end
            if right_section then right_section.Visible = false end
        end
    end

    function self:update_sections(left_section, right_section)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
                continue
            end
            object.Visible = false
        end
    end

    function self:create_tab(title, icon)
        local TabManager = {}
        local LayoutOrder = 0

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000
        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.24, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.1, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection' .. self._tab
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.259, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection' .. self._tab
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.629, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = { _state = false, _size = 0, _multiplier = 0 }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(50, 50, 50)
            UIStroke.Thickness = 1.5
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(255, 255, 255)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.7
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.071, 0, 0.82, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.TextTransparency = 0.1
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.073, 0, 0.24, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(200, 200, 200)
            Description.TextTransparency = 0.3
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.073, 0, 0.42, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.7
            Toggle.Position = UDim2.new(0.82, 0, 0.757, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.2
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.7
            Keybind.Position = UDim2.new(0.15, 0, 0.735, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Keybind.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.62, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            function ModuleManager:change_state(state)
                self._state = state
                local targetSize = UDim2.fromOffset(241, self._state and (93 + self._size + self._multiplier) or 93)
                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
                
                local circlePos = self._state and UDim2.fromScale(0.53, 0.5) or UDim2.fromScale(0, 0.5)
                local circleColor = self._state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
                TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = circleColor, Position = circlePos}):Play()

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)
                if settings.callback then settings.callback(self._state) end
            end
            
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then return end
                Connections[settings.flag..'_keybind_module'] = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then return end
                    ModuleManager:change_state(not ModuleManager._state)
                end)
            end

            function ModuleManager:scale_keybind(empty)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                local circleColor = ModuleManager._state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
                local circlePos = ModuleManager._state and UDim2.fromScale(0.53, 0.5) or UDim2.fromScale(0, 0.5)
                Circle.BackgroundColor3 = circleColor
                Circle.Position = circlePos
                if settings.callback then settings.callback(ModuleManager._state) end
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began_keybind_selection'] = Header.InputBegan:Connect(function(input)
                if Library._choosing_keybind then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                
                Library._choosing_keybind = true
                Connections['keybind_choose_start_module'] = UserInputService.InputBegan:Connect(function(keyInput, process)
                    if process or keyInput.UserInputType ~= Enum.UserInputType.Keyboard or keyInput.KeyCode == Enum.KeyCode.Unknown then return end
                    
                    if keyInput.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)
                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)
                        TextLabel.Text = 'None'
                        if Connections[settings.flag..'_keybind_module'] then Connections[settings.flag..'_keybind_module']:Disconnect() end
                    else
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag..'_keybind_module'] then Connections[settings.flag..'_keybind_module']:Disconnect() end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        TextLabel.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    end
                    Connections['keybind_choose_start_module']:Disconnect()
                    Library._choosing_keybind = false
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += settings.customScale or 70
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                Paragraph.BackgroundTransparency = 0.2
                Paragraph.Size = UDim2.new(0, 207, 0, 30)
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph
            
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(200, 200, 200)
                Body.Text = settings.text or "Paragraph text."
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 25)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                Paragraph.MouseEnter:Connect(function() TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play() end)
                Paragraph.MouseLeave:Connect(function() TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play() end)
                return {}
            end

            function ModuleManager:create_text(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += settings.customScale or 50
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                TextFrame.BackgroundTransparency = 0.2
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize or 30)
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(200, 200, 200)
                Body.Text = settings.text or "Text content."
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
                TextFrame.MouseEnter:Connect(function() TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play() end)
                TextFrame.MouseLeave:Connect(function() TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play() end)
                return {}
            end

            function ModuleManager:create_textbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += 32
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.Parent = Options
                Label.TextSize = 10
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
            
                function Textbox:update_text(text)
                    Textbox.Text = text
                    Library._config._flags[settings.flag] = text
                    Config:save(game.GameId, Library._config)
                    if settings.callback then settings.callback(text) end
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    Textbox:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    Textbox:update_text(Textbox.Text)
                end)
                return Textbox
            end   

            function ModuleManager:create_checkbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += 20
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 11
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Checkbox"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox
            
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 4)
                KeybindCorner.Parent = KeybindBox
            
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag] and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function Checkbox:change_state(state)
                    Checkbox._state = state
                    local fillSize = state and UDim2.fromOffset(9, 9) or UDim2.fromOffset(0, 0)
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = fillSize}):Play()
                    
                    local boxTransparency = state and 0.7 or 0.9
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = boxTransparency}):Play()

                    Library._config._flags[settings.flag] = Checkbox._state
                    Config:save(game.GameId, Library._config)
                    if settings.callback then settings.callback(Checkbox._state) end
                end
            
                if Library:flag_type(settings.flag, "boolean") then
                    Checkbox:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function() Checkbox:change_state(not Checkbox._state) end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
            
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if processed or keyInput.UserInputType ~= Enum.UserInputType.Keyboard or keyInput.KeyCode == Enum.KeyCode.Unknown then return end
            
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            KeybindLabel.Text = "..."
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            if Connections[settings.flag .. "_keybind_checkbox"] then Connections[settings.flag .. "_keybind_checkbox"]:Disconnect() end
                        else
                            Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                            Config:save(game.GameId, Library._config)
                            if Connections[settings.flag .. "_keybind_checkbox"] then Connections[settings.flag .. "_keybind_checkbox"]:Disconnect() end
                            KeybindLabel.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        end
                        chooseConnection:Disconnect()
                        Library._choosing_keybind = false
                    end)
                end)
            
                Connections[settings.flag .. "_keypress_checkbox"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    local storedKey = Library._config._keybinds[settings.flag]
                    if storedKey and tostring(input.KeyCode) == storedKey then
                        Checkbox:change_state(not Checkbox._state)
                    end
                end)
                return Checkbox
            end

            function ModuleManager:create_divider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += 27
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                local dividerWidth = 207
            
                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20)
                OuterFrame.BackgroundTransparency = 1
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3
                    TextLabel.TextStrokeTransparency = 0
                    TextLabel.Parent = OuterFrame
                end
                
                if not settings or settings and not settings.disableline then
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, 1)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2
                    Divider.Position = UDim2.new(0, 0, 0.5, -0.5)
                
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    })
                    Gradient.Rotation = 90
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.8),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 0.8)
                    })
                end
                return {}
            end

            function ModuleManager:create_slider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += 40
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local SliderFrame = Instance.new('Frame')
                SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                SliderFrame.BackgroundTransparency = 0.2
                SliderFrame.Size = UDim2.new(0, 207, 0, 30)
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Name = "Slider"
                SliderFrame.Parent = Options
                SliderFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = SliderFrame
            
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title.Text = settings.title or "Slider"
                Title.Size = UDim2.new(1, -10, 0, 15)
                Title.Position = UDim2.new(0, 5, 0, 3)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextSize = 12
                Title.Parent = SliderFrame
            
                local ValueLabel = Instance.new('TextLabel')
                ValueLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                ValueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                ValueLabel.Text = string.format(settings.format or "%.2f", settings.default)
                ValueLabel.Size = UDim2.new(0, 50, 0, 15)
                ValueLabel.AnchorPoint = Vector2.new(1, 0)
                ValueLabel.Position = UDim2.new(1, -5, 0, 3)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.TextSize = 11
                ValueLabel.Parent = SliderFrame
            
                local Slider = Instance.new('Frame')
                Slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Slider.BackgroundTransparency = 0.5
                Slider.Size = UDim2.new(0, 197, 0, 5)
                Slider.Position = UDim2.new(0, 5, 0, 20)
                Slider.BorderSizePixel = 0
                Slider.Name = "Slider"
                Slider.Parent = SliderFrame
            
                local SliderCorner = Instance.new('UICorner')
                SliderCorner.CornerRadius = UDim.new(0, 3)
                SliderCorner.Parent = Slider
            
                local Fill = Instance.new('Frame')
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.BackgroundTransparency = 0.2
                Fill.Size = UDim2.new(0, 0, 1, 0)
                Fill.BorderSizePixel = 0
                Fill.Name = "Fill"
                Fill.Parent = Slider
            
                local FillCorner = Instance.new('UICorner')
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                local Handle = Instance.new('Frame')
                Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Handle.BackgroundTransparency = 0.1
                Handle.Size = UDim2.new(0, 10, 0, 10)
                Handle.AnchorPoint = Vector2.new(0.5, 0.5)
                Handle.Position = UDim2.new(0, 0, 0.5, 0)
                Handle.BorderSizePixel = 0
                Handle.Name = "Handle"
                Handle.Parent = Slider
            
                local HandleCorner = Instance.new('UICorner')
                HandleCorner.CornerRadius = UDim.new(1, 0)
                HandleCorner.Parent = Handle
            
                local is_dragging = false
            
                local function update_slider_value(inputX)
                    local relative_x = inputX - Slider.AbsolutePosition.X
                    local percentage = math.clamp(relative_x / Slider.AbsoluteSize.X, 0, 1)
                    local value = settings.min + (settings.max - settings.min) * percentage
                    value = math.round(value / settings.step) * settings.step
                    value = math.clamp(value, settings.min, settings.max)
            
                    SliderFrame._value = value
                    ValueLabel.Text = string.format(settings.format or "%.2f", value)
                    Fill.Size = UDim2.new((value - settings.min) / (settings.max - settings.min), 0, 1, 0)
                    Handle.Position = UDim2.new((value - settings.min) / (settings.max - settings.min), 0, 0.5, 0)
            
                    if settings.callback then settings.callback(value) end
                    Library._config._flags[settings.flag] = value
                    Config:save(game.GameId, Library._config)
                end
            
                Slider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        is_dragging = true
                        update_slider_value(input.Position.X)
                    end
                end)
            
                Slider.InputChanged:Connect(function(input)
                    if is_dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        update_slider_value(input.Position.X)
                    end
                end)
            
                Slider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        is_dragging = false
                    end
                end)
            
                if Library:flag_type(settings.flag, 'number') then
                    SliderFrame._value = Library._config._flags[settings.flag]
                    update_slider_value(Slider.AbsolutePosition.X + Slider.AbsoluteSize.X * ((SliderFrame._value - settings.min) / (settings.max - settings.min)))
                else
                    Library._config._flags[settings.flag] = settings.default
                    Config:save(game.GameId, Library._config)
                    update_slider_value(Slider.AbsolutePosition.X + Slider.AbsoluteSize.X * ((settings.default - settings.min) / (settings.max - settings.min)))
                end

                function SliderFrame:Get() return SliderFrame._value end
                function SliderFrame:Set(value)
                    value = math.clamp(value, settings.min, settings.max)
                    value = math.round(value / settings.step) * settings.step
                    update_slider_value(Slider.AbsolutePosition.X + Slider.AbsoluteSize.X * ((value - settings.min) / (settings.max - settings.min)))
                end
                return SliderFrame
            end

            function ModuleManager:create_dropdown(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += 40
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local DropdownFrame = Instance.new('Frame')
                DropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                DropdownFrame.BackgroundTransparency = 0.2
                DropdownFrame.Size = UDim2.new(0, 207, 0, 30)
                DropdownFrame.BorderSizePixel = 0
                DropdownFrame.Name = "Dropdown"
                DropdownFrame.Parent = Options
                DropdownFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = DropdownFrame
            
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title.Text = settings.title or "Dropdown"
                Title.Size = UDim2.new(1, -10, 0, 15)
                Title.Position = UDim2.new(0, 5, 0, 3)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextSize = 12
                Title.Parent = DropdownFrame
            
                local CurrentSelection = Instance.new('TextButton')
                CurrentSelection.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                CurrentSelection.TextColor3 = Color3.fromRGB(200, 200, 200)
                CurrentSelection.Text = settings.default or settings.options[1]
                CurrentSelection.Size = UDim2.new(0, 80, 0, 15)
                CurrentSelection.AnchorPoint = Vector2.new(1, 0)
                CurrentSelection.Position = UDim2.new(1, -5, 0, 3)
                CurrentSelection.BackgroundTransparency = 1
                CurrentSelection.TextXAlignment = Enum.TextXAlignment.Right
                CurrentSelection.TextSize = 11
                CurrentSelection.Parent = DropdownFrame
                CurrentSelection.AutoButtonColor = false
            
                local ArrowIcon = Instance.new('ImageLabel')
                ArrowIcon.Image = "rbxassetid://6034177420"
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.Size = UDim2.new(0, 10, 0, 10)
                ArrowIcon.Position = UDim2.new(1, -15, 0.5, 0)
                ArrowIcon.AnchorPoint = Vector2.new(1, 0.5)
                ArrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                ArrowIcon.Parent = CurrentSelection
            
                local OptionsFrame = Instance.new('Frame')
                OptionsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                OptionsFrame.BackgroundTransparency = 0.1
                OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
                OptionsFrame.Position = UDim2.new(0, 0, 1, 5)
                OptionsFrame.BorderSizePixel = 0
                OptionsFrame.Name = "OptionsFrame"
                OptionsFrame.ClipsDescendants = true
                OptionsFrame.Parent = DropdownFrame
            
                local OptionsListLayout = Instance.new('UIListLayout')
                OptionsListLayout.FillDirection = Enum.FillDirection.Vertical
                OptionsListLayout.Padding = UDim.new(0, 2)
                OptionsListLayout.Parent = OptionsFrame
            
                local OptionsUIPadding = Instance.new('UIPadding')
                OptionsUIPadding.PaddingTop = UDim.new(0, 5)
                OptionsUIPadding.PaddingBottom = UDim.new(0, 5)
                OptionsUIPadding.Parent = OptionsFrame

                local dropdown_open = false
                local function toggle_dropdown()
                    dropdown_open = not dropdown_open
                    local targetSizeY = dropdown_open and (#settings.options * (20 + 2) + 10) or 0
                    TweenService:Create(OptionsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetSizeY)}):Play()
                    
                    local arrowRotation = dropdown_open and 180 or 0
                    TweenService:Create(ArrowIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Rotation = arrowRotation}):Play()
                    
                    self._multiplier = dropdown_open and (targetSizeY + 5) or 0
                    if ModuleManager._state then
                         TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                        }):Play()
                    end
                end
            
                CurrentSelection.MouseButton1Click:Connect(toggle_dropdown)
            
                for _, option_text in ipairs(settings.options) do
                    local OptionButton = Instance.new('TextButton')
                    OptionButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    OptionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                    OptionButton.Text = option_text
                    OptionButton.Size = UDim2.new(1, 0, 0, 20)
                    OptionButton.BackgroundTransparency = 1
                    OptionButton.TextXAlignment = Enum.TextXAlignment.Center
                    OptionButton.TextSize = 11
                    OptionButton.Parent = OptionsFrame
                    OptionButton.AutoButtonColor = false
            
                    OptionButton.MouseButton1Click:Connect(function()
                        DropdownFrame._value = option_text
                        CurrentSelection.Text = option_text
                        toggle_dropdown()
                        if settings.callback then settings.callback(option_text) end
                        Library._config._flags[settings.flag] = option_text
                        Config:save(game.GameId, Library._config)
                    end)
            
                    OptionButton.MouseEnter:Connect(function() TweenService:Create(OptionButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play() end)
                    OptionButton.MouseLeave:Connect(function() TweenService:Create(OptionButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play() end)
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    DropdownFrame._value = Library._config._flags[settings.flag]
                    CurrentSelection.Text = DropdownFrame._value
                    if settings.callback then settings.callback(DropdownFrame._value) end
                else
                    Library._config._flags[settings.flag] = settings.default or settings.options[1]
                    Config:save(game.GameId, Library._config)
                    if settings.callback then settings.callback(Library._config._flags[settings.flag]) end
                end

                function DropdownFrame:Get() return DropdownFrame._value end
                return DropdownFrame
            end

            function ModuleManager:create_button(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                self._size += 30
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Button = Instance.new('TextButton')
                Button.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.Text = settings.title or "Button"
                Button.Size = UDim2.new(0, 207, 0, 25)
                Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                Button.BackgroundTransparency = 0.2
                Button.BorderSizePixel = 0
                Button.Name = "Button"
                Button.Parent = Options
                Button.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Button
            
                Button.MouseButton1Click:Connect(function() if settings.callback then settings.callback() end end)
            
                Button.MouseEnter:Connect(function() TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play() end)
                Button.MouseLeave:Connect(function() TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play() end)
                return {}
            end
            return ModuleManager
        end
        return TabManager
    end
end

-- Initialize UI Library and load it
local Library = Library.new()
Library:load()

-- ================================================
-- >> FEATURES IMPLEMENTATION <<
-- ================================================

-- AUTO PARRY
local autoParryTab = Library:create_tab("Auto Parry", "rbxassetid://6034177420")

local autoParryModule = autoParryTab:create_module({
    title = "Auto Parry",
    description = "Automatically parry incoming balls.",
    flag = "AutoParry",
    callback = function(state) getgenv().AutoParry = state end
})

autoParryModule:create_checkbox({
    title = "Random Accuracy",
    description = "Adds randomness to parry timing.",
    flag = "RandomParryAccuracy",
    callback = function(state) getgenv().RandomParryAccuracyEnabled = state end
})

autoParryModule:create_slider({
    title = "Parry Threshold",
    description = "Distance at which to attempt parry.",
    flag = "ParryDistanceThreshold",
    min = 5, max = 50, step = 0.5, default = 15, format = "%.1f studs",
    callback = function(value) getgenv().ParryThreshold = value end
})

autoParryModule:create_dropdown({
    title = "Parry Input Type",
    description = "Method to simulate parry input.",
    flag = "ParryInputType",
    options = {"F_Key", "Click", "Remotes"},
    default = "F_Key",
    callback = function(value) getgenv().ParryKey = value end
})

autoParryModule:create_divider({showtopic = true, title = "Advanced Detection"})

autoParryModule:create_checkbox({
    title = "Infinity Detection",
    description = "Detects and reacts to Infinity ability.",
    flag = "InfinityDetection",
    callback = function(state) getgenv().InfinityDetection = state end
})

autoParryModule:create_checkbox({
    title = "Phantom V2 Anti",
    description = "Attempts to counter Phantom V2 ability.",
    flag = "PhantomV2Anti",
    callback = function(state) getgenv().PhantomV2Detection = state end
})

autoParryModule:create_checkbox({
    title = "Time Hole Detection",
    description = "Detects and reacts to Time Hole ability.",
    flag = "TimeHoleDetection",
    callback = function(state) getgenv().TimeHoleDetection = state end
})


-- PLAYER / MOVEMENT
local playerTab = Library:create_tab("Player", "rbxassetid://6034177420")

local flyModule = playerTab:create_module({
    title = "Fly",
    description = "Enable Noclip style flying.",
    flag = "FlyToggle",
    callback = function(state)
        getgenv().FlyEnabled = state
        local char = Player.Character
        if not char then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        if state then
            getgenv().originalCameraSubject = Workspace.CurrentCamera.CameraSubject
            getgenv().originalCFrame = Workspace.CurrentCamera.CFrame
            Workspace.CurrentCamera.CameraSubject = char.Humanoid
            Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
            
            rootPart.CanCollide = false
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end

            Connections['fly_render_step'] = RunService.RenderStepped:Connect(function()
                if getgenv().FlyEnabled and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = Player.Character.HumanoidRootPart
                    local camera = Workspace.CurrentCamera
                    local moveVector = Vector3.new()

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += camera.CFrame.lookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= camera.CFrame.lookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= camera.CFrame.rightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += camera.CFrame.rightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector += Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector -= Vector3.new(0, 1, 0) end

                    if moveVector.Magnitude > 0 then
                        root.CFrame = root.CFrame + moveVector.Unit * getgenv().FlySpeed * RunService.RenderStepped:Wait()
                    end
                end
            end)
        else
            if Connections['fly_render_step'] then Connections['fly_render_step']:Disconnect() end
            rootPart.CanCollide = true
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
            Workspace.CurrentCamera.CameraSubject = getgenv().originalCameraSubject
            Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            Workspace.CurrentCamera.CFrame = getgenv().originalCFrame
        end
    end
})

flyModule:create_slider({
    title = "Fly Speed",
    description = "Adjust the speed of flying.",
    flag = "FlySpeed",
    min = 10, max = 200, step = 5, default = 50, format = "%.0f studs/s",
    callback = function(value) getgenv().FlySpeed = value end
})

playerTab:create_divider({showtopic = true, title = "Other Movement"})

local noclipModule = playerTab:create_module({
    title = "Noclip",
    description = "Walk through walls.",
    flag = "NoclipToggle",
    callback = function(state)
        getgenv().NoClipEnabled = state
        local char = Player.Character
        if not char then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        rootPart.CanCollide = not state
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not state end
        end
    end
})

local antiRagdollModule = playerTab:create_module({
    title = "Anti-Ragdoll",
    description = "Prevents your character from ragdolling.",
    flag = "AntiRagdollToggle",
    callback = function(state)
        getgenv().AntiRagdollEnabled = state
        if state then
            Library.SendNotification({title = "Anti-Ragdoll", text = "Anti-Ragdoll enabled. Functionality depends on game physics.", duration = 2})
            local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.BreakJointsOnDeath = false end
        else
            local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.BreakJointsOnDeath = true end
        end
    end
})

-- COMBAT / AIM ASSIST
local combatTab = Library:create_tab("Combat", "rbxassetid://6034177420")

local silentAimModule = combatTab:create_module({
    title = "Silent Aim",
    description = "Aims for you without camera movement.",
    flag = "SilentAimToggle",
    callback = function(state) getgenv().SilentAimEnabled = state end
})

silentAimModule:create_slider({
    title = "FOV",
    description = "Field of View for silent aim.",
    flag = "SilentAimFOV",
    min = 0, max = 360, step = 1, default = 90, format = "%.0f degrees",
    callback = function(value) getgenv().SilentAimFOV = value end
})

silentAimModule:create_dropdown({
    title = "Target Part",
    description = "Body part to aim for.",
    flag = "SilentAimTargetPart",
    options = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    default = "HumanoidRootPart",
    callback = function(value) getgenv().SilentAimTargetPart = value end
})

silentAimModule:create_slider({
    title = "Smoothness",
    description = "Smoothness of the silent aim.",
    flag = "SilentAimSmoothness",
    min = 0, max = 1, step = 0.05, default = 0.5, format = "%.2f",
    callback = function(value) getgenv().SilentAimSmoothness = value end
})

silentAimModule:create_checkbox({
    title = "Ping Correction",
    description = "Corrects for your ping in aiming.",
    flag = "SilentAimPingCorrection",
    callback = function(state) getgenv().SilentAimPingCorrection = state end
})

silentAimModule:create_checkbox({
    title = "Visible Only",
    description = "Only aims at visible targets.",
    flag = "SilentAimVisibleOnly",
    callback = function(state) getgenv().SilentAimVisibleOnly = state end
})

silentAimModule:create_checkbox({
    title = "Predict Movement",
    description = "Predicts target's future position.",
    flag = "SilentAimPredict",
    callback = function(state) getgenv().SilentAimPredict = state end
})

silentAimModule:create_divider({showtopic = true, title = "Hitbox"})

local hitboxExpanderModule = combatTab:create_module({
    title = "Hitbox Expander",
    description = "Increases your hitbox size.",
    flag = "HitboxExpanderToggle",
    callback = function(state)
        getgenv().HitboxExpanderEnabled = state
        local char = Player.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("Part") or part:IsA("MeshPart") then
                if state then
                    part.Size = part.Size * getgenv().HitboxExpanderSize
                else
                    part.Size = part.Size / getgenv().HitboxExpanderSize
                end
            end
        end
    end
})

hitboxExpanderModule:create_slider({
    title = "Expansion Size",
    description = "How much to expand the hitbox.",
    flag = "HitboxExpanderSize",
    min = 1, max = 5, step = 0.1, default = 1.2, format = "x%.1f",
    callback = function(value) getgenv().HitboxExpanderSize = value end
})

-- AUTO CLICKER
local autoClickerModule = combatTab:create_module({
    title = "Auto Clicker",
    description = "Automatically clicks for you.",
    flag = "AutoClickerToggle",
    callback = function(state)
        getgenv().AutoClickerEnabled = state
        if state then
            InputTask = task.spawn(function()
                while getgenv().AutoClickerEnabled do
                    VirtualInputManager:SendMouseEvent(mouse.X, mouse.Y, 0, true, 0)
                    task.wait(getgenv().AutoClickerDelay)
                    VirtualInputManager:SendMouseEvent(mouse.X, mouse.Y, 0, false, 0)
                    task.wait(getgenv().AutoClickerDelay)
                end
            end)
        else
            if InputTask then task.cancel(InputTask) end
        end
    end
})

autoClickerModule:create_slider({
    title = "Click Delay",
    description = "Delay between clicks in seconds.",
    flag = "AutoClickerDelay",
    min = 0.01, max = 1, step = 0.01, default = 0.05, format = "%.2f s",
    callback = function(value) getgenv().AutoClickerDelay = value end
})

autoClickerModule:create_dropdown({
    title = "Click Button",
    description = "Button to simulate clicking.",
    flag = "AutoClickerButton",
    options = {"MouseButton1", "MouseButton2"},
    default = "MouseButton1",
    callback = function(value) getgenv().AutoClickerButton = Enum.UserInputType[value] end
})

-- ABILITIES / EXPLOITS
local abilitiesTab = Library:create_tab("Abilities", "rbxassetid://6034177420")

local autoAbilityModule = abilitiesTab:create_module({
    title = "Auto Ability",
    description = "Automatically uses your equipped ability.",
    flag = "AutoAbilityToggle",
    callback = function(state) getgenv().AutoAbility = state end
})

autoAbilityModule:create_checkbox({
    title = "Cooldown Protection",
    description = "Attempts to bypass ability cooldowns.",
    flag = "CooldownProtectionToggle",
    callback = function(state) getgenv().CooldownProtection = state end
})

autoAbilityModule:create_checkbox({
    title = "Thunder Dash No Cooldown",
    description = "Enables Thunder Dash without cooldown.",
    flag = "ThunderDashNoCooldownToggle",
    callback = function(state) getgenv().ThunderDashNoCooldown = state end
})

autoAbilityModule:create_checkbox({
    title = "Continuity Zero Exploit",
    description = "Enables Continuity Zero exploit.",
    flag = "ContinuityZeroExploitToggle",
    callback = function(state) getgenv().ContinuityZeroExploit = state end
})

-- VISUALS / MISC
local visualsTab = Library:create_tab("Visuals", "rbxassetid://6034177420")

local abilityEspModule = visualsTab:create_module({
    title = "Ability ESP",
    description = "Shows ESP for active abilities.",
    flag = "AbilityESPToggle",
    callback = function(state) getgenv().AbilityESP = state end
})

local worldFilterModule = visualsTab:create_module({
    title = "World Filters",
    description = "Applies visual filters to the game world.",
    flag = "WorldFilterToggle",
    callback = function(state) getgenv().WorldFilterEnabled = state end
})

worldFilterModule:create_checkbox({
    title = "Atmosphere",
    description = "Toggle atmospheric effects.",
    flag = "AtmosphereEffect",
    callback = function(state)
        getgenv().AtmosphereEnabled = state
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Enabled = state
    end
})

worldFilterModule:create_checkbox({
    title = "Fog",
    description = "Toggle fog effects.",
    flag = "FogEffect",
    callback = function(state)
        getgenv().FogEnabled = state
        local fog = Lighting:FindFirstChildOfClass("Fog") or Instance.new("Fog", Lighting)
        fog.Enabled = state
        if state then fog.Color = Color3.fromRGB(0,0,0); fog.End = 500; fog.Start = 100 end
    end
})

worldFilterModule:create_slider({
    title = "Saturation",
    description = "Adjust screen saturation.",
    flag = "SaturationValue",
    min = 0, max = 2, step = 0.05, default = 1, format = "%.2f",
    callback = function(value)
        getgenv().SaturationEnabled = true
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Enabled = true
        cc.Saturation = value
    end
})

worldFilterModule:create_slider({
    title = "Hue",
    description = "Adjust screen hue.",
    flag = "HueValue",
    min = 0, max = 1, step = 0.01, default = 0, format = "%.2f",
    callback = function(value)
        getgenv().HueEnabled = true
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Enabled = true
        cc.TintColor = Color3.fromHSV(value, 1, 1)
    end
})

local soundModule = visualsTab:create_module({
    title = "Sound Customization",
    description = "Customize in-game sounds.",
    flag = "SoundToggle",
    callback = function(state) getgenv().soundmodule = state end
})

soundModule:create_checkbox({
    title = "Hit Sound",
    description = "Plays a sound on hitting an opponent.",
    flag = "HitSoundToggle",
    callback = function(state) getgenv().hit_Sound_Enabled = state end
})

soundModule:create_slider({
    title = "Hit Sound Volume",
    description = "Volume of hit sound.",
    flag = "HitSoundVolume",
    min = 0, max = 1, step = 0.05, default = 0.5, format = "%.2f",
    callback = function(value) getgenv().HitSoundVolume = value end
})

-- MISCELLANEOUS
local miscTab = Library:create_tab("Misc", "rbxassetid://6034177420")

local serverHopModule = miscTab:create_module({
    title = "Auto Server Hop",
    description = "Automatically hops to a new server.",
    flag = "AutoServerHopToggle",
    callback = function(state)
        getgenv().AutoServerHop = state
        if state then Library.SendNotification({title = "Auto Server Hop", text = "Auto Server Hop enabled. This will attempt to teleport you to a new server.", duration = 3}) end
    end
})

local autoVoteModule = miscTab:create_module({
    title = "Auto Vote",
    description = "Automatically votes in game polls.",
    flag = "AutoVoteToggle",
    callback = function(state)
        getgenv().AutoVote = state
        if state then Library.SendNotification({title = "Auto Vote", text = "Auto Vote enabled. This might not work on all games.", duration = 3}) end
    end
})

local skinChangerModule = miscTab:create_module({
    title = "Skin Changer",
    description = "Changes your sword model and animations.",
    flag = "SkinChangerToggle",
    callback = function(state) getgenv().skinChanger = state end
})

skinChangerModule:create_textbox({
    title = "Sword Model ID",
    placeholder = "Enter Asset ID",
    flag = "SwordModelID",
    callback = function(value) getgenv().swordModel = value end
})

skinChangerModule:create_textbox({
    title = "Sword Animation ID",
    placeholder = "Enter Asset ID",
    flag = "SwordAnimationID",
    callback = function(value) getgenv().swordAnimations = value end
})

skinChangerModule:create_textbox({
    title = "Sword FX ID",
    placeholder = "Enter Asset ID",
    flag = "SwordFXID",
    callback = function(value) getgenv().swordFX = value end
})


-- ================================================
-- >> GENERAL GAME LOGIC & EXPLOITS <<
-- ================================================

RunService.RenderStepped:Connect(function()
    if getgenv().AutoAbility then
        -- Game-specific: Logic to use ability
    end
end)

RunService.RenderStepped:Connect(function()
    if not getgenv().SilentAimEnabled then return end

    local target = nil
    local shortestDistance = math.huge
    local playerChar = Player.Character
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return end
    local localHRP = playerChar.HumanoidRootPart

    for _, p in Players:GetPlayers() do
        if p ~= Player and p.Character and p.Character:FindFirstChild(getgenv().SilentAimTargetPart) then
            local targetPart = p.Character:FindFirstChild(getgenv().SilentAimTargetPart)
            if targetPart then
                local screenPoint, inViewport = Workspace.CurrentCamera:WorldToScreenPoint(targetPart.Position)
                if inViewport then
                    local distance = (localHRP.Position - targetPart.Position).Magnitude
                    if distance < shortestDistance and distance <= getgenv().SilentAimDistance then
                        local vectorToTarget = (targetPart.Position - Workspace.CurrentCamera.CFrame.Position).Unit
                        local dotProduct = Workspace.CurrentCamera.CFrame.lookVector:Dot(vectorToTarget)
                        local angle = math.acos(math.clamp(dotProduct, -1, 1))
                        if math.deg(angle) <= getgenv().SilentAimFOV / 2 then
                            if getgenv().SilentAimVisibleOnly then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterDescendantsInstances = {playerChar, p.Character}
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                local rayResult = Workspace:Raycast(Workspace.CurrentCamera.CFrame.Position, vectorToTarget * distance, rayParams)
                                if rayResult and rayResult.Instance:IsDescendantOf(p.Character) then
                                    target = p.Character
                                    shortestDistance = distance
                                end
                            else
                                target = p.Character
                                shortestDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end

    if target and target:FindFirstChild(getgenv().SilentAimTargetPart) then
        local targetPosition = target[getgenv().SilentAimTargetPart].Position
        
        if getgenv().SilentAimPredict and target:FindFirstChildOfClass("Humanoid") then
            local targetVelocity = target.Humanoid.AssemblyLinearVelocity
            local predictionTime = (localHRP.Position - targetPosition).Magnitude / getgenv().SilentAimVelocity
            if getgenv().SilentAimPingCorrection then
                predictionTime += (Network.ServerStatsItem['Data Ping']:GetValue() or 0) / 1000
            end
            targetPosition = targetPosition + targetVelocity * predictionTime
        end

        local currentMousePos = mouse.Hit.p
        local desiredScreenPos, _ = Workspace.CurrentCamera:WorldToScreenPoint(targetPosition)
        
        local lerpedX = currentMousePos.X + (desiredScreenPos.X - currentMousePos.X) * getgenv().SilentAimSmoothness
        local lerpedY = currentMousePos.Y + (desiredScreenPos.Y - currentMousePos.Y) * getgenv().SilentAimSmoothness

        VirtualInputManager:SendMouseEvent(lerpedX, lerpedY, 0, false, 0)
    end
end)

-- Sound Module / Loop Song
if getgenv().soundmodule then
    local backgroundMusic = SoundService:FindFirstChild("BackgroundMusic")
    if not backgroundMusic then
        backgroundMusic = Instance.new("Sound")
        backgroundMusic.Name = "BackgroundMusic"
        backgroundMusic.SoundId = "rbxassetid://183181827"
        backgroundMusic.Volume = 0.3
        backgroundMusic.Looped = true
        backgroundMusic.Parent = SoundService
    end
    if backgroundMusic.PlaybackState ~= Enum.PlaybackState.Playing then
        backgroundMusic:Play()
    end
else
    local backgroundMusic = SoundService:FindFirstChild("BackgroundMusic")
    if backgroundMusic and backgroundMusic.PlaybackState == Enum.PlaybackState.Playing then
        backgroundMusic:Stop()
        backgroundMusic:Destroy()
    end
end
