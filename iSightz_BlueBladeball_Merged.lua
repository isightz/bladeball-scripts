-- iSightz Ware Bladeball Script (Merged UI + Enhanced Combat Auto-Parry)
-- This script combines features from iSightz_BlueBladeball_Merged.lua, cele2stia.lua.txt, and sillly hub source.txt.
-- It features a custom black UI with white text, enhanced auto-parry, and various other functionalities.

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
local VirtualInputManager = game:GetService("VirtualInputManager") -- For simulating input
local VirtualInputService = game:GetService("VirtualInputManager") -- Alias for consistency
local GuiService = game:GetService('GuiService')
local Stats = game:GetService('Stats')
local SoundService = game:GetService('SoundService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')
local Network = game:GetService('Network') -- For ping access

local Player = Players.LocalPlayer
local mouse = Player:GetMouse()

-->> GLOBAL VARIABLES <<--
-- Language settings for UI elements
getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}
local SelectedLanguage = GG.Language

-- General script state variables
local Tornado_Time = tick()
local Last_Input = UserInputService:GetLastInputType()
local Vector2_Mouse_Location = nil
local Grab_Parry = nil -- Used in old logic, consider if still needed
local Remotes = {} -- Remote events for game interaction
local Parry_Key = Enum.KeyCode.F -- Default parry key, can be changed via UI
local Speed_Divisor_Multiplier = 1.1 -- Used in auto-parry calculations
local LobbyAP_Speed_Divisor_Multiplier = 1.1 -- Lobby specific auto-parry speed multiplier
local firstParryFired = false
local ParryThreshold = 2.5 -- Distance threshold for parry
local firstParryType = 'F_Key' -- Default parry type (e.g., F_Key, Click, etc.)
local Previous_Positions = {} -- For ball prediction/curve detection
local Infinity = false -- Infinity ability state
local Parried = false -- Flag for successful parry
local Last_Parry = 0 -- Timestamp of last parry
local AutoParry = true -- Auto-parry toggle state
local CurrentBall = nil -- Reference to the current ball
local InputTask = nil -- Task for input simulation
local Cooldown = 0.02 -- Cooldown for certain actions
local Runtime = Workspace:FindFirstChild("Runtime") -- Game specific runtime folder

-- Global getgenv flags for various features (linked to UI checkboxes/sliders)
getgenv().RandomParryAccuracyEnabled = false -- Randomize parry timing slightly
getgenv().InfinityDetection = false -- Detect and react to Infinity ability
getgenv().AutoParryKeypress = true -- Simulate keypress for auto-parry
getgenv().PhantomV2Detection = false -- Anti-Phantom detection
getgenv().SlashOfFuryDetection = false -- Slash of Fury detection
getgenv().DeathSlashDetection = false -- Death Slash detection
getgenv().TimeHoleDetection = false -- Time Hole detection
getgenv().AutoAbility = false -- Automatically use abilities
getgenv().CooldownProtection = false -- Protect from ability cooldowns
getgenv().AutoSpamNotify = false -- Notify when spamming parry
getgenv().SpamParryKeypress = false -- Simulate spamming parry key
getgenv().ManualSpamNotify = false
getgenv().ManualSpamKeypress = false
getgenv().spamui = false -- for Manual Spam UI
getgenv().FlyEnabled = false -- Enable player fly
getgenv().FlySpeed = 50 -- Speed for fly
getgenv().originalCameraSubject = nil -- Store original camera subject for fly
getgenv().originalCFrame = nil -- Store original camera CFrame for fly
getgenv().AutoClickerEnabled = false -- Enable auto clicker
getgenv().AutoClickerDelay = 0.01 -- Delay between clicks
getgenv().AutoClickerButton = Enum.UserInputType.MouseButton1 -- Button for auto clicker
getgenv().SilentAimEnabled = false -- Enable silent aim
getgenv().SilentAimFOV = 90 -- Field of View for silent aim
getgenv().SilentAimTargetPart = "HumanoidRootPart" -- Part to aim for
getgenv().SilentAimSmoothness = 0.5 -- Smoothness of aim
getgenv().SilentAimPingCorrection = false -- Correct for ping
getgenv().SilentAimCheckTeam = false -- Check if target is on same team
getgenv().SilentAimVisibleOnly = false -- Only aim at visible targets
getgenv().SilentAimIgnoreWalls = false -- Ignore walls for aiming
getgenv().SilentAimPredict = false -- Predict target movement
getgenv().SilentAimRandomizePing = false -- Randomize ping for prediction
getgenv().SilentAimDistance = 100 -- Max distance for silent aim
getgenv().SilentAimVelocity = 50 -- Velocity for prediction
getgenv().SilentAimHealth = 100 -- Min health for silent aim
getgenv().SilentAimRaycast = false -- Use raycast for visibility
getgenv().SilentAimHumanoid = false -- Target humanoids
getgenv().SilentAimBodyPart = "HumanoidRootPart" -- Body part for Silent Aim (redundant with SilentAimTargetPart, but kept for clarity)
getgenv().HitboxExpanderEnabled = false -- Enable hitbox expander
getgenv().HitboxExpanderSize = 1 -- Size of hitbox expansion
getgenv().NoClipEnabled = false -- Enable noclip
getgenv().AntiRagdollEnabled = false -- Prevent ragdolling
getgenv().hit_Sound_Enabled = false -- Enable hit sound
getgenv().HitSoundVolume = 5 -- Volume of hit sound
getgenv().soundmodule = false -- Background sound module toggle
getgenv().LoopSong = false -- Loop background song
getgenv().WorldFilterEnabled = false -- Enable world filters
getgenv().AtmosphereEnabled = false -- Toggle atmosphere effect
getgenv().FogEnabled = false -- Toggle fog effect
getgenv().SaturationEnabled = false -- Toggle saturation effect
getgenv().HueEnabled = false -- Toggle hue effect
getgenv().AbilityESP = false -- ESP for abilities
getgenv().AbilityExploit = false -- General ability exploit toggle
getgenv().ThunderDashNoCooldown = false -- Thunder Dash no cooldown exploit
getgenv().ContinuityZeroExploit = false -- Continuity Zero exploit
getgenv().AutoVote = false -- Automatically vote in game
getgenv().AutoServerHop = false -- Automatically hop servers
getgenv().skinChanger = false -- Enable skin changer
getgenv().swordModel = "" -- Model ID for sword
getgenv().swordAnimations = "" -- Animation ID for sword
getgenv().swordFX = "" -- FX ID for sword

-- Autoplay Config (from Silly Hub, adapted)
local AutoPlayModule = {
    CONFIG = {
        DEFAULT_DISTANCE = 30,
        MULTIPLIER_THRESHOLD = 70,
        TRAVERSING = 25,
        DIRECTION = 1,
        JUMP_PERCENTAGE = 50,
        DOUBLE_JUMP_PERCENTAGE = 50,
        JUMPING_ENABLED = false,
        MOVEMENT_DURATION = 0.8,
        OFFSET_FACTOR = 0.7,
        GENERATION_THRESHOLD = 0.25
    },
    ball = nil,
    lobbyChoice = nil,
    animationCache = nil,
    doubleJumped = false,
    ELAPSED = 0,
    CONTROL_POINT = nil,
    LAST_GENERATION = 0,
    signals = {}
}

-- Auto Parry Logic (Enhanced combination of iSightz, Silly, Celestia)
local Auto_Parry = {}

-- Function to get the current ball in the workspace
function Auto_Parry.Get_Ball()
    for _, ball in Workspace.Balls:GetChildren() do
        if ball:IsA("Part") and ball.Name == "Ball" then
            return ball
        end
    end
    return nil
end

-- Function to find the closest player to the local player
function Auto_Parry.Closest_Player()
    local closestDistance = math.huge
    local closestPlayer = nil
    local playerChar = Player.Character
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return nil end

    for _, p in Players:GetPlayers() do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (playerChar.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < closestDistance then
                closestDistance = dist
                closestPlayer = p
            end
        end
    end
    return closestPlayer
end

-- Function to check if the ball is curving based on previous positions (from Celestia)
function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then return false end

    -- Store previous positions
    table.insert(Previous_Positions, {Position = Ball.Position, Time = tick()})

    -- Keep only recent positions (e.g., last 0.1 seconds)
    for i = #Previous_Positions, 1, -1 do
        if tick() - Previous_Positions[i].Time > 0.1 then
            table.remove(Previous_Positions, i)
        end
    end

    if #Previous_Positions < 3 then return false end

    -- Check for curvature using dot product of direction vectors
    local p1 = Previous_Positions[#Previous_Positions].Position
    local p2 = Previous_Positions[#Previous_Positions - 1].Position
    local p3 = Previous_Positions[#Previous_Positions - 2].Position

    local v1 = (p1 - p2).Unit
    local v2 = (p2 - p3).Unit

    local dotProduct = v1:Dot(v2)

    -- If dot product is significantly less than 1, it means the direction has changed (curving)
    -- A threshold of 0.95 or less indicates a curve
    return dotProduct < 0.95
end

-- Function to perform the parry action
function Auto_Parry.Parry(parryType)
    if not getgenv().AutoParryKeypress then return end
    if tick() - Last_Parry < Cooldown then return end -- Basic cooldown to prevent spamming

    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    if parryType == 'F_Key' then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.01) -- Brief hold
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    elseif parryType == 'Click' then
        -- Simulate mouse click for parry
        VirtualInputManager:SendMouseEvent(mouse.X, mouse.Y, 0, true, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseEvent(mouse.X, mouse.Y, 0, false, 0)
    elseif parryType == 'Remotes' then
        -- This is a placeholder for game-specific remote event calls.
        -- You would need to reverse engineer the game's parry remote.
        -- Example (hypothetical):
        -- ReplicatedStorage.Remotes.ParryEvent:FireServer()
        Library.SendNotification({
            title = "Auto-Parry Warning",
            text = "Remote parry type selected, but no remote implemented. Please add game-specific remote logic.",
            duration = 3
        })
    end

    Last_Parry = tick()
    Parried = true
    firstParryFired = true -- For conditional logic after first parry
end

-- Main auto-parry loop (similar to previous iSightz and Silly logic)
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

    local Pings = Network.ServerStatsItem['Data Ping']:GetValue() or 0.1 -- Default to 0.1 if not found

    -- Enhanced ball distance and reach time calculations (from Celestia)
    local Speed_Threshold = math.min(Speed / 100, 40)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = getgenv().ParryThreshold - math.min(Distance / 1000, getgenv().ParryThreshold) + Speed_Threshold

    if Enough_Speed and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    -- Check for curvature
    local Curve_Detected = Auto_Parry.Is_Curved()

    -- Determine if conditions are met for parry
    local canParry = false
    if Distance <= Ball_Distance_Threshold and Dot > -0.25 then -- Using Celestia's dynamic threshold and Silly's dot product
        if Curve_Detected or not getgenv().InfinityDetection then -- If curved or not detecting Infinity, parry
            canParry = true
        end
    end

    -- Add random accuracy if enabled
    if getgenv().RandomParryAccuracyEnabled and canParry then
        if math.random() > 0.8 then -- 20% chance to miss
            canParry = false
        end
    end

    if canParry then
        Auto_Parry.Parry(getgenv().ParryKey)
    end
end)

-- Old Remote Event Handlers from iSightz and Silly
-- These are kept as they might contain game-specific logic
ReplicatedStorage.Remotes.PassAll.OnClientEvent:Connect(function(a, b)
    local Primary_Part = Player.Character and Player.Character.PrimaryPart
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return
    end

    local Zoomies = Ball:FindFirstChild('zoomies')

    if not Zoomies then
        return
    end

    local Speed = Zoomies.VectorVelocity.Magnitude
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Pings = Network.ServerStatsItem['Data Ping']:GetValue()

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold

    if Enough_Speed and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    -- This part sets 'Curving' based on ball distance, which is used by Auto_Parry.Is_Curved()
    if b ~= Primary_Part and Distance > Ball_Distance_Threshold then
        Tornado_Time = tick() -- Renamed Curving to Tornado_Time as per original Celestia file.
    end
end)

ReplicatedStorage.Remotes.Phantom.OnClientEvent:Connect(function(a, b)
    if getgenv().PhantomV2Detection then
        -- Implement anti-phantom logic here
        -- This could involve force-teleporting, changing collision groups, etc.
        Library.SendNotification({
            title = "Phantom Detected!",
            text = "Phantom V2 detected, attempting countermeasures.",
            duration = 2
        })
    end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    -- This event is useful for adjusting auto-parry logic if needed
    -- e.g., resetting cooldowns, or confirming a successful parry for more advanced features.
    Parried = true
    Last_Parry = tick()
end)

workspace.Balls.ChildAdded:Connect(function(newBall)
    if newBall:IsA("Part") and newBall.Name == "Ball" then
        CurrentBall = newBall
        -- Optionally, add a notification for ball spawn
        -- Library.SendNotification({title = "Ball Spawned", text = "New ball detected!", duration = 1})
    end
end)

-- Utility Functions (from Silly Hub, adapted)
function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

-- Connection management for UI elements and script functionalities
local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for key, value in pairs(self) do
            if typeof(value) == 'function' then
                continue
            end
            if typeof(value) == 'RBXScriptConnection' and value.Connected then
                value:Disconnect()
            end
            self[key] = nil -- Clear the reference
        end
    end
}, {__index = {}})

-- General utility functions
local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    -- Converts a screen point to a world point, useful for UI interaction with 3D space
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    -- Gets an offset based on viewport size, for responsive UI
    get_offset = function(self: any)
        local viewport_size_Y = Workspace.CurrentCamera.ViewportSize.Y
        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, {__index = {}})

-- Acrylic Blur Effect for UI (from Silly Hub)
local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)
    self:setup()
    return self
end

function AcrylicBlur:create_folder()
    local old_folder = Workspace.CurrentCamera:FindFirstChild('AcrylicBlur')
    if old_folder then
        Debris:AddItem(old_folder, 0)
    end
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
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end
        if object == depth_of_fields then
            continue
        end
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

function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
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

        if not self._root then
            return
        end

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
    
    task.spawn(on_change) -- Initial call to set positions and update
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end

-- Configuration saving/loading (from Silly Hub, adapted)
local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Silly/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfolder("Silly") then -- Create folder if it doesn't exist
                makefolder("Silly")
            end
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
    
        if not success_load then
            warn('failed to load config', result)
        end
    
        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        return result
    end
}, {__index = {}})

-- Main UI Library (from Silly Hub, heavily adapted for iSightz Ware theme and features)
local Library = {
    _config = Config:load(game.GameId), -- Load saved configurations
    _choosing_keybind = false, -- Flag for keybind selection state
    _device = nil, -- Detected device type (PC, Mobile, Console)
    _ui_open = true, -- UI visibility state
    _ui_scale = 1, -- UI scaling factor
    _ui_loaded = false, -- Flag if UI is fully loaded
    _ui = nil, -- Reference to the main ScreenGui
    _dragging = false, -- Flag for UI dragging
    _drag_start = nil, -- Starting position for drag
    _container_position = nil -- Original position of container before drag
}
Library.__index = Library

function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0, -- Current tab index
    }, Library)
    
    self:create_ui() -- Initialize UI elements

    -- Set up Right Alt keybind for UI visibility
    Connections['ui_toggle_keybind'] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightAlt and not gameProcessed then
            Library:UIVisiblity()
        end
    end)

    return self
end

-- Notification System (from Silly Hub)
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false;
NotificationContainer.Parent = CoreGui -- Directly parent to CoreGui for simplicity
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
    InnerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Darker background for notifications
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
    Title.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
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
    Body.TextColor3 = Color3.fromRGB(200, 200, 200) -- Slightly grey text
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
            Position = UDim2.new(0, 0, 0, NotificationContainer.AbsoluteSize.Y.Offset - InnerFrame.AbsoluteSize.Y.Offset) -- Adjust position to stack upwards
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

-- Helper to get screen scale for responsive UI
function Library:get_screen_scale()
    local viewport_size_x = Workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_size_x / 1400 -- Base resolution for scaling
end

-- Detect user device type
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

-- Connects an action to the UI's AncestryChanged event for cleanup
function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end

-- Checks the type of a saved flag
function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return false -- Return false if flag doesn't exist
    end
    return typeof(Library._config._flags[flag]) == flag_type
end

-- Removes a specific value from a table
function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end
        table.remove(__table, index)
    end
end

-- Main UI creation function (heavily customized for iSightz Ware)
function Library:create_ui()
    -- Clean up existing UI if any from previous versions or other scripts
    local existingScreenGui = CoreGui:FindFirstChild('iSightzWareScript')
    if existingScreenGui then
        existingScreenGui:Destroy()
    end
    local oldSilly = CoreGui:FindFirstChild('Silly')
    if oldSilly then
        oldSilly:Destroy()
    end

    local Silly = Instance.new('ScreenGui')
    Silly.ResetOnSpawn = false
    Silly.Name = 'iSightzWareScript' -- Renamed to iSightzWareScript
    Silly.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Silly.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05 -- More opaque black
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Darker black
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0) -- Starts minimized
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Silly
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(50, 50, 50) -- Dark grey stroke
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
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent, main background is container
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
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    ClientName.TextTransparency = 0.1 -- Slightly transparent
    ClientName.Text = 'iSightz Ware' -- Changed name
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 100, 0, 13) -- Adjusted size
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.0560000017285347, 0, 0.054999999701976776, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)), -- Light grey to white gradient
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    UIGradient.Parent = ClientName
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.13600000739097595, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001' -- Replace with suitable icon, e.g., a simple white eye or abstract symbol
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.02500000037252903, 0, 0.054999999701976776, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
    Icon.Parent = Handler
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey divider
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text for minimize button
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = Silly

    -- UI Dragging functionality
    local function on_drag(input: InputObject)
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

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began_drag'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed_drag'] = UserInputService.InputChanged:Connect(drag)

    -- Cleanup when UI is removed
    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    -- UI transparency update function (from Silly)
    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    -- Toggle UI visibility
    function self:UIVisiblity()
        Silly.Enabled = not Silly.Enabled;
        if Silly.Enabled then
            self:change_visiblity(true) -- Expand when shown
        else
            self:change_visiblity(false) -- Minimize when hidden
        end
    end;

    -- Change UI size (minimize/expand)
    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52) -- Minimized size
            }):Play()
        end
    end
    
    -- Load UI assets and set up scaling
    function self:load()
        local content = {}
    
        for _, object in Silly:GetDescendants() do
            if not object:IsA('ImageLabel') and not object:IsA('Font') then -- Avoid preloading fonts
                continue
            end
            table.insert(content, object)
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
    
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        AcrylicBlur.new(Container)
        self._ui_loaded = true
    end

    -- Update tab visual state and section visibility
    function self:update_tabs(tab: TextButton, left_section_frame: ScrollingFrame, right_section_frame: ScrollingFrame)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            local section_order = object.LayoutOrder
            local left_section = Sections:FindFirstChild('LeftSection' .. section_order)
            local right_section = Sections:FindFirstChild('RightSection' .. section_order)

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3) -- Calculate offset based on tab position

                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5 -- Selected tab background transparency
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.1, -- Less transparent
                        TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0) -- Gradient for selected state
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.1, -- Less transparent
                        ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon
                    }):Play()
                end

                -- Ensure correct sections are visible
                if left_section then left_section.Visible = true end
                if right_section then right_section.Visible = true end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1 -- Unselected tab background transparency
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7, -- More transparent
                    TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0) -- Reset gradient for unselected state
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8, -- More transparent
                    ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon
                }):Play()
            end
            -- Hide unselected sections
            if left_section then left_section.Visible = false end
            if right_section then right_section.Visible = false end
        end
    end

    -- Update visibility of content sections
    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
                continue
            end
            object.Visible = false
        end
    end

    -- Create a new tab in the UI
    function self:create_tab(title: string, icon: string)
        local TabManager = {}
        local LayoutOrder = 0;

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark background for tabs
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
        TextLabel.TextTransparency = 0.7 -- Unselected state
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
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
        Icon.ImageTransparency = 0.800000011920929 -- Unselected state
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection' .. self._tab -- Unique name
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
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
        RightSection.Name = 'RightSection' .. self._tab -- Unique name
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
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

        -- Module creation for various UI elements (checkboxes, sliders, etc.)
        function TabManager:create_module(settings: any)
            local LayoutOrderModule = 0;
            local ModuleManager = {
                _state = false, -- Current toggle state for the module
                _size = 0, -- Accumulated size for options within the module
                _multiplier = 0 -- Additional size multiplier
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5 -- More opaque
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93) -- Initial minimized size
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Darker background
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(50, 50, 50) -- Dark grey stroke
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045' -- Default icon (can be changed)
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
            ModuleName.TextTransparency = 0.1 -- Slightly transparent
            if not settings.rich then
                ModuleName.Text = settings.title or "Module"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,255,255)'>Module</font>" -- White rich text
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(200, 200, 200) -- Light grey text
            Description.TextTransparency = 0.3 -- Slightly transparent
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey for toggle background
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Grey for toggle circle (off state)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.699999988079071
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey for keybind background
            Keybind.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey divider
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey divider
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8) -- Initial small size
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            -- Function to change the module's toggle state
            function ModuleManager:change_state(state: boolean)
                self._state = state
                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier) -- Expand
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White
                        Position = UDim2.fromScale(0.53, 0.5) -- Move circle to right
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93) -- Collapse
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Grey
                        Position = UDim2.fromScale(0, 0.5) -- Move circle to left
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state -- Save state
                Config:save(game.GameId, Library._config)
                if settings.callback then
                    settings.callback(self._state) -- Execute callback
                end
            end
            
            -- Connect keybind for toggling the module
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind_module'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    
                    ModuleManager:change_state(not ModuleManager._state)
                end)
            end

            -- Scale keybind text based on its content
            function ModuleManager:scale_keybind(empty: boolean)
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

            -- Initialize module state from saved config
            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                if ModuleManager._state then
                    Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Circle.Position = UDim2.fromScale(0.53, 0.5)
                end
                settings.callback(ModuleManager._state) -- Initial callback
            end

            -- Initialize keybind text and connection
            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            -- Handle keybind selection
            Connections[settings.flag..'_input_began_keybind_selection'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then -- Right-click to set keybind
                    return
                end
                
                Library._choosing_keybind = true
                
                Connections['keybind_choose_start_module'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then -- Backspace to clear keybind
                        ModuleManager:scale_keybind(true)
                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)
                        TextLabel.Text = 'None'
                        
                        if Connections[settings.flag..'_keybind_module'] then
                            Connections[settings.flag..'_keybind_module']:Disconnect()
                            Connections[settings.flag..'_keybind_module'] = nil
                        end

                        Connections['keybind_choose_start_module']:Disconnect()
                        Connections['keybind_choose_start_module'] = nil

                        Library._choosing_keybind = false

                        return
                    end
                    
                    Connections['keybind_choose_start_module']:Disconnect()
                    Connections['keybind_choose_start_module'] = nil
                    
                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind_module'] then
                        Connections[settings.flag..'_keybind_module']:Disconnect()
                        Connections[settings.flag..'_keybind_module'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    
                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function() -- Left-click to toggle module state
                ModuleManager:change_state(not ModuleManager._state)
            end)

            -- Creates a paragraph text element within the module
            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;

                local ParagraphManager = {}
                
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 70
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Darker background
                Paragraph.BackgroundTransparency = 0.2
                Paragraph.Size = UDim2.new(0, 207, 0, 30)
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule;
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
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
                Body.TextColor3 = Color3.fromRGB(200, 200, 200) -- Light grey text
                
                if not settings.rich then
                    Body.Text = settings.text or "Paragraph text."
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(200,200,200)'>Paragraph rich text.</font>"
                end
                
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 25)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Darker on hover
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Reset on leave
                    }):Play()
                end)

                return ParagraphManager
            end

            -- Creates a simple text label within the module
            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextManager = {}
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 50
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Darker background
                TextFrame.BackgroundTransparency = 0.2
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize or 30) -- Adjusted default height
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
                Body.TextColor3 = Color3.fromRGB(200, 200, 200) -- Light grey text
            
                if not settings.rich then
                    Body.Text = settings.text or "Text content."
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(200,200,200)'>Rich text content.</font>"
                end
            
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Text content."
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(200,200,200)'>Rich text content.</font>"
                    end
                end;
            
                return TextManager
            end

            -- Creates a textbox input field within the module
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextboxManager = {
                    _text = ""
                }
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 32
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 10;
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark background
                Textbox.BackgroundTransparency = 0.9 -- Slightly transparent
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
            
                function TextboxManager:update_text(text: string)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    if settings.callback then
                        settings.callback(self._text)
                    end
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                return TextboxManager
            end   

            -- Creates a checkbox toggle within the module
            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0) -- Transparent, actual text color is for TitleLabel
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Transparent
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 11
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
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
                KeybindBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey background
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox
            
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 4)
                KeybindCorner.Parent = KeybindBox
            
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag] 
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") 
                    or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey for outer box
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
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White for fill (on state)
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7 -- Slightly less transparent
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9 -- More transparent
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    if settings.callback then
                        settings.callback(self._state)
                    end
                end
            
                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
            
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
            
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            ModuleManager:scale_keybind(true)
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag .. "_keybind_checkbox"] then -- Unique connection name
                                Connections[settings.flag .. "_keybind_checkbox"]:Disconnect()
                                Connections[settings.flag .. "_keybind_checkbox"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
            
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag .. "_keybind_checkbox"] then
                            Connections[settings.flag .. "_keybind_checkbox"]:Disconnect()
                            Connections[settings.flag .. "_keybind_checkbox"] = nil
                        end
                        -- ModuleManager:connect_keybind() -- This connects to module header, not checkbox specifically
                        -- ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
            
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)
            
                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag .. "_keypress_checkbox"] = keyPressConnection -- Unique connection name
            
                return CheckboxManager
            end

            -- Creates a horizontal divider within the module
            function ModuleManager:create_divider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 27
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                local dividerHeight = 1
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
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
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
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Transparent
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2)
                
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
                end;
                return {}; -- Return empty manager as it's purely visual
            end

            -- Creates a slider element within the module
            function ModuleManager:create_slider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;
                local SliderManager = {_value = settings.default}
                
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 40
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
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
            
                local function update_slider_value(inputX: number)
                    local relative_x = inputX - Slider.AbsolutePosition.X
                    local percentage = math.clamp(relative_x / Slider.AbsoluteSize.X, 0, 1)
                    local value = settings.min + (settings.max - settings.min) * percentage
                    value = math.round(value / settings.step) * settings.step -- Snap to step
                    value = math.clamp(value, settings.min, settings.max)
            
                    SliderManager._value = value
                    ValueLabel.Text = string.format(settings.format or "%.2f", value)
                    Fill.Size = UDim2.new((value - settings.min) / (settings.max - settings.min), 0, 1, 0)
                    Handle.Position = UDim2.new((value - settings.min) / (settings.max - settings.min), 0, 0.5, 0)
            
                    if settings.callback then
                        settings.callback(value)
                    end
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
            
                -- Initialize slider with saved value
                if Library:flag_type(settings.flag, 'number') then
                    SliderManager._value = Library._config._flags[settings.flag]
                    update_slider_value(Slider.AbsolutePosition.X + Slider.AbsoluteSize.X * ((SliderManager._value - settings.min) / (settings.max - settings.min)))
                else
                    -- Save default value if not already saved
                    Library._config._flags[settings.flag] = settings.default
                    Config:save(game.GameId, Library._config)
                    update_slider_value(Slider.AbsolutePosition.X + Slider.AbsoluteSize.X * ((settings.default - settings.min) / (settings.max - settings.min)))
                end

                function SliderManager:Get()
                    return self._value
                end

                function SliderManager:Set(value)
                    value = math.clamp(value, settings.min, settings.max)
                    value = math.round(value / settings.step) * settings.step
                    update_slider_value(Slider.AbsolutePosition.X + Slider.AbsoluteSize.X * ((value - settings.min) / (settings.max - settings.min)))
                end
            
                return SliderManager
            end

            -- Creates a dropdown menu within the module
            function ModuleManager:create_dropdown(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;
                local DropdownManager = {_value = settings.default or settings.options[1]}
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 40
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
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
                ArrowIcon.Image = "rbxassetid://6034177420" -- Down arrow icon
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.Size = UDim2.new(0, 10, 0, 10)
                ArrowIcon.Position = UDim2.new(1, -15, 0.5, 0)
                ArrowIcon.AnchorPoint = Vector2.new(1, 0.5)
                ArrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                ArrowIcon.Parent = CurrentSelection
            
                local OptionsFrame = Instance.new('Frame')
                OptionsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                OptionsFrame.BackgroundTransparency = 0.1
                OptionsFrame.Size = UDim2.new(1, 0, 0, 0) -- Starts collapsed
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
                    if dropdown_open then
                        local targetSizeY = #settings.options * (20 + 2) + 10 -- (item height + padding) * num_items + padding_top/bottom
                        TweenService:Create(OptionsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(1, 0, 0, targetSizeY)
                        }):Play()
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                        self._multiplier += targetSizeY + 5 -- Add space for dropdown
                        if ModuleManager._state then
                             TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                            }):Play()
                        end
                    else
                        TweenService:Create(OptionsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(1, 0, 0, 0)
                        }):Play()
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                        self._multiplier -= (#settings.options * (20 + 2) + 10) + 5 -- Remove space
                        if ModuleManager._state then
                            TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                            }):Play()
                        end
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
                        DropdownManager._value = option_text
                        CurrentSelection.Text = option_text
                        toggle_dropdown()
                        if settings.callback then
                            settings.callback(option_text)
                        end
                        Library._config._flags[settings.flag] = option_text
                        Config:save(game.GameId, Library._config)
                    end)
            
                    OptionButton.MouseEnter:Connect(function()
                        TweenService:Create(OptionButton, TweenInfo.new(0.1), {BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                    end)
                    OptionButton.MouseLeave:Connect(function()
                        TweenService:Create(OptionButton, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                    end)
                end
            
                -- Initialize dropdown with saved value
                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager._value = Library._config._flags[settings.flag]
                    CurrentSelection.Text = DropdownManager._value
                    if settings.callback then
                        settings.callback(DropdownManager._value)
                    end
                else
                    -- Save default value if not already saved
                    Library._config._flags[settings.flag] = settings.default or settings.options[1]
                    Config:save(game.GameId, Library._config)
                    if settings.callback then
                        settings.callback(Library._config._flags[settings.flag])
                    end
                end

                function DropdownManager:Get()
                    return self._value
                end
            
                return DropdownManager
            end

            -- Creates a button within the module
            function ModuleManager:create_button(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;
                
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 30
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Button = Instance.new('TextButton')
                Button.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.Text = settings.title or "Button"
                Button.Size = UDim2.new(0, 207, 0, 25)
                Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Darker button background
                Button.BackgroundTransparency = 0.2
                Button.BorderSizePixel = 0
                Button.Name = "Button"
                Button.Parent = Options
                Button.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Button
            
                Button.MouseButton1Click:Connect(function()
                    if settings.callback then
                        settings.callback()
                    end
                end)
            
                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
                end)
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end)
            
                return {}
            end
            
            return ModuleManager
        end
        return TabManager
    end
end

-- Initialize UI Library
local Library = Library.new()
Library:load() -- Load the UI

-- ================================================
-- >> FEATURES IMPLEMENTATION <<
-- ================================================

-- AUTO PARRY (Enhanced with Celestia and Silly logic)
local autoParryTab = Library:create_tab("Auto Parry", "rbxassetid://6034177420") -- Example icon

local autoParryModule = autoParryTab:create_module({
    title = "Auto Parry",
    description = "Automatically parry incoming balls.",
    flag = "AutoParryEnabled",
    callback = function(state)
        getgenv().AutoParry = state
    end
})

autoParryModule:create_checkbox({
    title = "Random Accuracy",
    description = "Adds slight randomness to parry timing.",
    flag = "RandomParryAccuracy",
    callback = function(state)
        getgenv().RandomParryAccuracyEnabled = state
    end
})

autoParryModule:create_slider({
    title = "Parry Threshold",
    description = "Distance at which to attempt parry.",
    flag = "ParryDistanceThreshold",
    min = 5, max = 50, step = 0.5, default = 15, format = "%.1f studs",
    callback = function(value)
        getgenv().ParryThreshold = value
    end
})

autoParryModule:create_dropdown({
    title = "Parry Input Type",
    description = "Method used to simulate parry input.",
    flag = "ParryInputType",
    options = {"F_Key", "Click", "Remotes"},
    default = "F_Key",
    callback = function(value)
        getgenv().ParryKey = value
    end
})

autoParryModule:create_divider({
    showtopic = true,
    title = "Advanced Detection"
})

autoParryModule:create_checkbox({
    title = "Infinity Detection",
    description = "Detects and reacts to Infinity ability.",
    flag = "InfinityDetectionEnabled",
    callback = function(state)
        getgenv().InfinityDetection = state
    end
})

autoParryModule:create_checkbox({
    title = "Phantom V2 Anti",
    description = "Attempts to counter Phantom V2 ability.",
    flag = "PhantomV2Anti",
    callback = function(state)
        getgenv().PhantomV2Detection = state
    end
})

autoParryModule:create_checkbox({
    title = "Time Hole Detection",
    description = "Detects and reacts to Time Hole ability.",
    flag = "TimeHoleDetection",
    callback = function(state)
        getgenv().TimeHoleDetection = state
    end
})


-- PLAYER / MOVEMENT
local playerTab = Library:create_tab("Player", "rbxassetid://6034177420") -- Example icon

local flyModule = playerTab:create_module({
    title = "Fly",
    description = "Enable Noclip style flying.",
    flag = "FlyToggle",
    callback = function(state)
        getgenv().FlyEnabled = state
        if state then
            -- Store original camera properties
            getgenv().originalCameraSubject = Workspace.CurrentCamera.CameraSubject
            getgenv().originalCFrame = Workspace.CurrentCamera.CFrame
            Workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid
            Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
            
            local char = Player.Character
            if char then
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.CanCollide = false
                end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
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
            if Connections['fly_render_step'] then
                Connections['fly_render_step']:Disconnect()
                Connections['fly_render_step'] = nil
            end
            local char = Player.Character
            if char then
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.CanCollide = true
                end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            -- Restore original camera properties
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
    callback = function(value)
        getgenv().FlySpeed = value
    end
})

playerTab:create_divider({showtopic = true, title = "Other Movement"})

local noclipModule = playerTab:create_module({
    title = "Noclip",
    description = "Walk through walls.",
    flag = "NoclipToggle",
    callback = function(state)
        getgenv().NoClipEnabled = state
        local char = Player.Character
        if char then
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CanCollide = not state
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not state
                end
            end
        end
    end
})

local antiRagdollModule = playerTab:create_module({
    title = "Anti-Ragdoll",
    description = "Prevents your character from ragdolling.",
    flag = "AntiRagdollToggle",
    callback = function(state)
        getgenv().AntiRagdollEnabled = state
        -- Actual anti-ragdoll implementation is game-specific
        -- Typically involves hooking into humanoid states or modifying physics properties
        if state then
            Library.SendNotification({
                title = "Anti-Ragdoll",
                text = "Anti-Ragdoll enabled. Functionality depends on game physics.",
                duration = 2
            })
        end
    end
})

-- COMBAT / AIM ASSIST
local combatTab = Library:create_tab("Combat", "rbxassetid://6034177420") -- Example icon

local silentAimModule = combatTab:create_module({
    title = "Silent Aim",
    description = "Aims for you without camera movement.",
    flag = "SilentAimToggle",
    callback = function(state)
        getgenv().SilentAimEnabled = state
    end
})

silentAimModule:create_slider({
    title = "FOV",
    description = "Field of View for silent aim.",
    flag = "SilentAimFOV",
    min = 0, max = 360, step = 1, default = 90, format = "%.0f degrees",
    callback = function(value)
        getgenv().SilentAimFOV = value
    end
})

silentAimModule:create_dropdown({
    title = "Target Part",
    description = "Body part to aim for.",
    flag = "SilentAimTargetPart",
    options = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    default = "HumanoidRootPart",
    callback = function(value)
        getgenv().SilentAimTargetPart = value
    end
})

silentAimModule:create_slider({
    title = "Smoothness",
    description = "Smoothness of the silent aim.",
    flag = "SilentAimSmoothness",
    min = 0, max = 1, step = 0.05, default = 0.5, format = "%.2f",
    callback = function(value)
        getgenv().SilentAimSmoothness = value
    end
})

silentAimModule:create_checkbox({
    title = "Ping Correction",
    description = "Corrects for your ping in aiming.",
    flag = "SilentAimPingCorrection",
    callback = function(state)
        getgenv().SilentAimPingCorrection = state
    end
})

silentAimModule:create_checkbox({
    title = "Visible Only",
    description = "Only aims at visible targets.",
    flag = "SilentAimVisibleOnly",
    callback = function(state)
        getgenv().SilentAimVisibleOnly = state
    end
})

silentAimModule:create_checkbox({
    title = "Predict Movement",
    description = "Predicts target's future position.",
    flag = "SilentAimPredict",
    callback = function(state)
        getgenv().SilentAimPredict = state
    end
})

silentAimModule:create_divider({showtopic = true, title = "Hitbox"})

local hitboxExpanderModule = combatTab:create_module({
    title = "Hitbox Expander",
    description = "Increases your hitbox size.",
    flag = "HitboxExpanderToggle",
    callback = function(state)
        getgenv().HitboxExpanderEnabled = state
        local char = Player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("Part") or part:IsA("MeshPart") then
                    if state then
                        part.Size = part.Size * getgenv().HitboxExpanderSize
                    else
                        -- Reset to original size (this is tricky without storing original sizes)
                        -- For simplicity, this will just reset to 1 if disabled
                        part.Size = part.Size / getgenv().HitboxExpanderSize
                    end
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
    callback = function(value)
        getgenv().HitboxExpanderSize = value
    end
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
            if InputTask then
                task.cancel(InputTask)
                InputTask = nil
            end
        end
    end
})

autoClickerModule:create_slider({
    title = "Click Delay",
    description = "Delay between clicks in seconds.",
    flag = "AutoClickerDelay",
    min = 0.01, max = 1, step = 0.01, default = 0.05, format = "%.2f s",
    callback = function(value)
        getgenv().AutoClickerDelay = value
    end
})

autoClickerModule:create_dropdown({
    title = "Click Button",
    description = "Button to simulate clicking.",
    flag = "AutoClickerButton",
    options = {"MouseButton1", "MouseButton2"},
    default = "MouseButton1",
    callback = function(value)
        getgenv().AutoClickerButton = Enum.UserInputType[value]
    end
})

-- ABILITIES / EXPLOITS
local abilitiesTab = Library:create_tab("Abilities", "rbxassetid://6034177420") -- Example icon

local autoAbilityModule = abilitiesTab:create_module({
    title = "Auto Ability",
    description = "Automatically uses your equipped ability.",
    flag = "AutoAbilityToggle",
    callback = function(state)
        getgenv().AutoAbility = state
    end
})

autoAbilityModule:create_checkbox({
    title = "Cooldown Protection",
    description = "Attempts to bypass ability cooldowns.",
    flag = "CooldownProtectionToggle",
    callback = function(state)
        getgenv().CooldownProtection = state
    end
})

autoAbilityModule:create_checkbox({
    title = "Thunder Dash No Cooldown",
    description = "Enables Thunder Dash without cooldown.",
    flag = "ThunderDashNoCooldownToggle",
    callback = function(state)
        getgenv().ThunderDashNoCooldown = state
    end
})

autoAbilityModule:create_checkbox({
    title = "Continuity Zero Exploit",
    description = "Enables Continuity Zero exploit.",
    flag = "ContinuityZeroExploitToggle",
    callback = function(state)
        getgenv().ContinuityZeroExploit = state
    end
})

-- VISUALS / MISC
local visualsTab = Library:create_tab("Visuals", "rbxassetid://6034177420") -- Example icon

local abilityEspModule = visualsTab:create_module({
    title = "Ability ESP",
    description = "Shows ESP for active abilities.",
    flag = "AbilityESPToggle",
    callback = function(state)
        getgenv().AbilityESP = state
        -- Implement ESP visuals here (e.g., drawing boxes/lines)
    end
})

local worldFilterModule = visualsTab:create_module({
    title = "World Filters",
    description = "Applies visual filters to the game world.",
    flag = "WorldFilterToggle",
    callback = function(state)
        getgenv().WorldFilterEnabled = state
    end
})

worldFilterModule:create_checkbox({
    title = "Atmosphere",
    description = "Toggle atmospheric effects.",
    flag = "AtmosphereEffect",
    callback = function(state)
        getgenv().AtmosphereEnabled = state
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
        if not atmosphere.Parent then atmosphere.Parent = Lighting end
        atmosphere.Enabled = state
    end
})

worldFilterModule:create_checkbox({
    title = "Fog",
    description = "Toggle fog effects.",
    flag = "FogEffect",
    callback = function(state)
        getgenv().FogEnabled = state
        local fog = Lighting:FindFirstChildOfClass("Fog") or Instance.new("Fog")
        if not fog.Parent then fog.Parent = Lighting end
        fog.Enabled = state
        if state then
            fog.Color = Color3.fromRGB(0,0,0)
            fog.End = 500
            fog.Start = 100
        end
    end
})

worldFilterModule:create_slider({
    title = "Saturation",
    description = "Adjust screen saturation.",
    flag = "SaturationValue",
    min = 0, max = 2, step = 0.05, default = 1, format = "%.2f",
    callback = function(value)
        getgenv().SaturationEnabled = true -- Assume enabled if slider is used
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
        if not cc.Parent then cc.Parent = Lighting end
        cc.Saturation = value
    end
})

worldFilterModule:create_slider({
    title = "Hue",
    description = "Adjust screen hue.",
    flag = "HueValue",
    min = 0, max = 1, step = 0.01, default = 0, format = "%.2f",
    callback = function(value)
        getgenv().HueEnabled = true -- Assume enabled if slider is used
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
        if not cc.Parent then cc.Parent = Lighting end
        cc.TintColor = Color3.fromHSV(value, 1, 1) -- Apply hue via TintColor
    end
})

local soundModule = visualsTab:create_module({
    title = "Sound Customization",
    description = "Customize in-game sounds.",
    flag = "SoundToggle",
    callback = function(state)
        getgenv().soundmodule = state
    end
})

soundModule:create_checkbox({
    title = "Hit Sound",
    description = "Plays a sound on hitting an opponent.",
    flag = "HitSoundToggle",
    callback = function(state)
        getgenv().hit_Sound_Enabled = state
        -- Implement hit sound logic (e.g., connect to hit event)
    end
})

soundModule:create_slider({
    title = "Hit Sound Volume",
    description = "Volume of hit sound.",
    flag = "HitSoundVolume",
    min = 0, max = 1, step = 0.05, default = 0.5, format = "%.2f",
    callback = function(value)
        getgenv().HitSoundVolume = value
    end
})

-- MISCELLANEOUS
local miscTab = Library:create_tab("Misc", "rbxassetid://6034177420") -- Example icon

local serverHopModule = miscTab:create_module({
    title = "Auto Server Hop",
    description = "Automatically hops to a new server.",
    flag = "AutoServerHopToggle",
    callback = function(state)
        getgenv().AutoServerHop = state
        if state then
            Library.SendNotification({
                title = "Auto Server Hop",
                text = "Auto Server Hop enabled. This will attempt to teleport you to a new server.",
                duration = 3
            })
            -- Implement server hopping logic (e.g., using TeleportService)
            -- This is game-specific and complex, typically requires a list of servers
            -- or finding an empty server. For this example, it's a placeholder.
        end
    end
})

local autoVoteModule = miscTab:create_module({
    title = "Auto Vote",
    description = "Automatically votes in game polls.",
    flag = "AutoVoteToggle",
    callback = function(state)
        getgenv().AutoVote = state
        if state then
            Library.SendNotification({
                title = "Auto Vote",
                text = "Auto Vote enabled. This might not work on all games.",
                duration = 3
            })
            -- Implement auto-voting logic (game-specific remote event calls)
        end
    end
})

local skinChangerModule = miscTab:create_module({
    title = "Skin Changer",
    description = "Changes your sword model and animations.",
    flag = "SkinChangerToggle",
    callback = function(state)
        getgenv().skinChanger = state
    end
})

skinChangerModule:create_textbox({
    title = "Sword Model ID",
    placeholder = "Enter Asset ID",
    flag = "SwordModelID",
    callback = function(value)
        getgenv().swordModel = value
        -- Logic to apply sword model (game-specific, likely involves AssetService or game remotes)
    end
})

skinChangerModule:create_textbox({
    title = "Sword Animation ID",
    placeholder = "Enter Asset ID",
    flag = "SwordAnimationID",
    callback = function(value)
        getgenv().swordAnimations = value
        -- Logic to apply animations
    end
})

skinChangerModule:create_textbox({
    title = "Sword FX ID",
    placeholder = "Enter Asset ID",
    flag = "SwordFXID",
    callback = function(value)
        getgenv().swordFX = value
        -- Logic to apply effects
    end
})


-- ================================================
-- >> GENERAL GAME LOGIC & EXPLOITS (Integrated) <<
-- ================================================

-- AUTO ABILITY (Placeholder, logic depends on game ability system)
RunService.RenderStepped:Connect(function()
    if getgenv().AutoAbility then
        -- This is highly game-specific.
        -- You would need to find the remote event or function that triggers abilities.
        -- Example (hypothetical):
        -- ReplicatedStorage.Events.UseAbility:FireServer("YourAbilityName")
    end
end)

-- SILENT AIM LOGIC
RunService.RenderStepped:Connect(function()
    if not getgenv().SilentAimEnabled then return end

    local target = nil
    local shortestDistance = math.huge
    local playerChar = Player.Character
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return end
    local localHRP = playerChar.HumanoidRootPart

    for _, p in Players:GetPlayers() do
        if p ~= Player and p.Character and p.Character:FindFirstChild(getgenv().SilentAimTargetPart) then
            local targetHRP = p.Character:FindFirstChild(getgenv().SilentAimTargetPart)
            if targetHRP then
                local screenPoint, inViewport = Workspace.CurrentCamera:WorldToScreenPoint(targetHRP.Position)
                if inViewport then
                    local distance = (localHRP.Position - targetHRP.Position).Magnitude
                    if distance < shortestDistance and distance <= getgenv().SilentAimDistance then
                        -- Check FOV
                        local vectorToTarget = (targetHRP.Position - Workspace.CurrentCamera.CFrame.Position).Unit
                        local dotProduct = Workspace.CurrentCamera.CFrame.lookVector:Dot(vectorToTarget)
                        local angle = math.acos(dotProduct)
                        if math.deg(angle) <= getgenv().SilentAimFOV / 2 then
                            -- Visibility check (simple raycast, more robust needed for complex environments)
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

    if target and target:FindFirstChild("HumanoidRootPart") then
        local targetPosition = target.HumanoidRootPart.Position
        
        -- Prediction logic
        if getgenv().SilentAimPredict and target:FindFirstChildOfClass("Humanoid") then
            local targetVelocity = target.Humanoid.AssemblyLinearVelocity
            local predictionTime = (localHRP.Position - targetPosition).Magnitude / getgenv().SilentAimVelocity
            if getgenv().SilentAimPingCorrection then
                predictionTime += (Network.ServerStatsItem['Data Ping']:GetValue() or 0) / 1000
            end
            targetPosition = targetPosition + targetVelocity * predictionTime
        end

        -- Smoothness
        local currentMousePos = mouse.Hit.p
        local desiredMousePos = Workspace.CurrentCamera:WorldToScreenPoint(targetPosition)
        
        local lerpedX = currentMousePos.X + (desiredMousePos.X - currentMousePos.X) * getgenv().SilentAimSmoothness
        local lerpedY = currentMousePos.Y + (desiredMousePos.Y - currentMousePos.Y) * getgenv().SilentAimSmoothness

        VirtualInputManager:SendMouseEvent(lerpedX, lerpedY, 0, false, 0) -- Move mouse without clicking
        -- For actual shooting, you'd integrate this with weapon fire
    end
end)


-- Anti Ragdoll (basic placeholder, game-specific)
if getgenv().AntiRagdollEnabled then
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.BreakJointsOnDeath = false -- Basic prevention
    end
end

-- Hit Sound (placeholder, requires game-specific hit events)
if getgenv().hit_Sound_Enabled then
    -- Connect to a "hit" remote or detect damage
    -- Example:
    -- local sound = Instance.new("Sound")
    -- sound.SoundId = "rbxassetid://YOUR_SOUND_ID"
    -- sound.Volume = getgenv().HitSoundVolume
    -- sound.Parent = Workspace
    -- sound:Play()
    -- Debris:AddItem(sound, sound.TimeLength)
end

-- Sound Module / Loop Song (basic background music)
if getgenv().soundmodule then
    local backgroundMusic = SoundService:FindFirstChild("BackgroundMusic")
    if not backgroundMusic then
        backgroundMusic = Instance.new("Sound")
        backgroundMusic.Name = "BackgroundMusic"
        backgroundMusic.SoundId = "rbxassetid://183181827" -- Example ID for a generic background track
        backgroundMusic.Volume = 0.3
        backgroundMusic.Looped = getgenv().LoopSong
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

-- Handle World Filters
local currentAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local currentFog = Lighting:FindFirstChildOfClass("Fog")
local currentColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")

if getgenv().WorldFilterEnabled then
    if getgenv().AtmosphereEnabled then
        if not currentAtmosphere then currentAtmosphere = Instance.new("Atmosphere", Lighting) end
        currentAtmosphere.Enabled = true
        -- Further properties can be set via UI
    end
    if getgenv().FogEnabled then
        if not currentFog then currentFog = Instance.new("Fog", Lighting) end
        currentFog.Enabled = true
        currentFog.Color = Color3.fromRGB(0,0,0)
        currentFog.End = 500
        currentFog.Start = 100
        -- Further properties can be set via UI
    end
    if getgenv().SaturationEnabled or getgenv().HueEnabled then
        if not currentColorCorrection then currentColorCorrection = Instance.new("ColorCorrectionEffect", Lighting) end
        currentColorCorrection.Enabled = true
        if getgenv().SaturationEnabled then currentColorCorrection.Saturation = getgenv().SaturationValue end
        if getgenv().HueEnabled then currentColorCorrection.TintColor = Color3.fromHSV(getgenv().HueValue, 1, 1) end
    end
else
    if currentAtmosphere then currentAtmosphere.Enabled = false end
    if currentFog then currentFog.Enabled = false end
    if currentColorCorrection then currentColorCorrection.Enabled = false end
end

-- AutoAbility, CooldownProtection, ThunderDashNoCooldown, ContinuityZeroExploit, AutoVote, AutoServerHop, SkinChanger, SwordModel/Animations/FX
-- These features are complex and highly game-specific.
-- Their actual implementation would require reverse-engineering the game's remote events and functions.
-- The current code provides UI elements to toggle their flags and basic notifications.
-- To make them fully functional, you would need to add specific game-interaction logic.


