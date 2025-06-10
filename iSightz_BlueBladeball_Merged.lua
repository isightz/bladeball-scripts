--[[
    iSightz Ware Bladeball Script (Merged and Enhanced)
    Version: 2.0
    Description: This script combines and enhances features from iSightz_BlueBladeball_Merged.lua, cele2stia.lua.txt, and sillly hub source.txt.
    It provides a custom black UI with white text, advanced auto-parry, trigger bot, player and world modifications,
    and various farming and miscellaneous utilities.

    Features:
    - Custom UI: Black background, white text, named "iSightz Ware".
    - UI Elements: Fully functional sliders, checkboxes, and dropdowns.
    - UI Toggle: RightAlt key to hide/show the GUI.
    - Discord Icon: Top-right icon leading to the specified Discord profile.
    - Auto Parry: Enhanced logic for precise parrying based on ball speed, distance, and ping.
    - Trigger Bot: Automatically parries when the ball is incoming and conditions are met.
    - Ability ESP: Displays player abilities above their heads.
    - Player Follow: Automatically follows a selected player.
    - Hit Sounds: Custom hit sounds on successful parries with volume control.
    - World Filters: Custom atmosphere, fog, tint, and saturation controls.
    - Custom Sky: Change the game's skybox with various presets.
    - Ability Exploits: Thunder Dash no cooldown, Continuity Zero exploit (use with caution).
    - Auto Farm: Auto Duels Requeue, Auto Ranked Requeue, Auto LTM Requeue.
    - Skin Changer: Client-side sword skin changer with persistent application.
    - Anti-Detection: Improved handling for Phantom V2, Slash of Fury, Infinity, Death Slash, and Time Hole.

    Important Notes for Roblox Execution:
    - This script is designed for a Roblox exploit/executor.
    - `cloneref` is used for certain services for potential anti-cheat bypass; its functionality depends on the executor.
    - `writefile`, `readfile`, `makefolder`, `isfile`, `isfolder` functions are used for config saving; these depend on your executor's capabilities. If your executor does not support these, the config will not persist across sessions, but the script will still run.
    - `getconnections`, `debug.getprotos`, `debug.getupvalues`, `debug.getconstants`, `islclosure`, `getinfo`, `setupvalue`, `rawget`, `hookmetamethod`, `setthreadidentity` are advanced functions that require a capable executor.
    - UI assets (rbxassetid://) are placeholders and should function as long as they are valid Roblox assets.

    To use: Copy and paste this entire script into your Roblox executor.
]]

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
local GuiService = game:GetService('GuiService')
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualInputService = game:GetService("VirtualInputManager")
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')
local ContentProvider = game:GetService('ContentProvider') -- Added for preloading assets

local Player = Players.LocalPlayer
local mouse = Player:GetMouse()

-- Global variables for game state and configurations.
-- These are made available globally using 'getgenv()' for easy access and modification by UI toggles.
getgenv().PhantomV2Detection = false
getgenv().SlashOfFuryDetection = false
getgenv().InfinityDetection = false
getgenv().DeathSlashDetection = false
getgenv().TimeHoleDetection = false
getgenv().AutoAbilityEnabled = false
getgenv().CooldownProtectionEnabled = false
getgenv().RandomParryAccuracyEnabled = false
getgenv().AutoParryKeypress = false -- Whether Auto Parry simulates keypress
getgenv().SpamParryKeypress = false -- Whether Auto Spam Parry simulates keypress
getgenv().ManualSpamKeypress = false -- Whether Manual Spam Parry simulates keypress
getgenv().AutoParryNotify = false
getgenv().AutoSpamNotify = false
getgenv().ManualSpamNotify = false
getgenv().PlayerFollowEnabled = false
getgenv().FollowNotifyEnabled = false
getgenv().WorldFilterEnabled = false
getgenv().AtmosphereEnabled = false
getgenv().FogEnabled = false
getgenv().AbilityESP = false
getgenv().ThunderDashNoCooldown = false
getgenv().ContinuityZeroExploit = false
getgenv().AutoVote = false -- New feature: Auto-vote for maps in lobby
getgenv().skinChanger = false
getgenv().swordModel = "" -- Stores the name of the custom sword model
getgenv().swordAnimations = "" -- Stores the name for custom sword animations
getgenv().swordFX = "" -- Stores the name for custom sword effects
getgenv().soundmodule = false
getgenv().spamui = false -- Controls visibility of the mobile spam UI
getgenv().AutoPlay = false -- Auto-play enabled/disabled
getgenv().AutoPlayJump = false -- Auto-play jump feature enabled/disabled

-- Core script variables
local Phantom = false -- Flag for Phantom V2 detection
local Tornado_Time = tick() -- Tracks time for Tornado ability bypass
local Last_Input = UserInputService:GetLastInputType() -- Last input type for UI scaling
local Grab_Parry = nil -- Stores the loaded animation track for Grab Parry
local Remotes = {} -- Table to store obfuscated remote events
local Parry_Key = nil -- Stores the detected parry key hash
local Speed_Divisor_Multiplier = 1.1 -- Adjusts parry accuracy based on ball speed
local LobbyAP_Speed_Divisor_Multiplier = 1.1 -- Seems unused in main logic, retained for consistency
local firstParryFired = false -- Tracks if the first parry in a sequence has occurred
local ParryThreshold = 2.5 -- Threshold for Auto Spam Parry distance
local firstParryType = 'F_Key' -- Configures how the first parry in a sequence is performed
local Parries = 0 -- Counter for consecutive parries to prevent excessive spamming
local Selected_Parry_Type = "Camera" -- Determines the parry angle/direction (e.g., Camera, Straight, Random)
local Infinity = false -- Flag for Infinity Ball detection
local deathshit = false -- Flag for Death Ball detection
local timehole = false -- Flag for Time Hole detection
local Parried = false -- Flag to ensure only one parry action per ball event in Auto Parry
local CurrentBall = nil -- Reference to the currently targeted ball
local Cooldown = 0.02 -- General cooldown/delay value
local RunTime = Workspace:FindFirstChild("Runtime") -- Reference to the Runtime folder in Workspace

-- For Player Follow
local SelectedPlayerFollow = nil -- The display name of the player to follow
local playerNamesCache = {} -- Cache for player display names
local hit_Sound_Enabled = false -- Toggle for hit sounds on parry success

-- Connections Manager table.
-- This table stores all active RBXScriptConnections, allowing for easy disconnection when features are toggled off.
local Connections_Manager = setmetatable({
    disconnect = function(self, connection_name)
        if self[connection_name] and typeof(self[connection_name]) == 'RBXScriptConnection' then
            self[connection_name]:Disconnect()
            self[connection_name] = nil
        end
    end,
    disconnect_all = function(self)
        for name, connection in pairs(self) do
            if typeof(connection) == 'RBXScriptConnection' then
                connection:Disconnect()
                self[name] = nil
            end
        end
    end
}, {})

-- Utility functions (adapted from sillly hub source.txt)
local Util = setmetatable({
    -- Maps a value from one range to another.
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    -- Converts a 2D screen point to a 3D world point.
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    -- Calculates an offset based on the viewport size.
    get_offset = function(self: any)
        local viewport_size_Y = Workspace.CurrentCamera.ViewportSize.Y
        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, {})

-- Acrylic Blur effect for UI (adapted from sillly hub source.txt)
-- This creates a semi-transparent, blurred background effect for the UI.
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
        Connections_Manager[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
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
    part.Size = Vector3.new(1, 1, 0)  -- Use a thin part to prevent z-fighting
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98 -- Almost transparent for the blur effect
    part.Parent = self._folder

    -- Create a SpecialMesh to simulate the acrylic blur effect
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  -- Using Brick mesh, common for simple mesh visuals
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  -- Small offset to prevent z-fighting
    specialMesh.Parent = part
    self._root = part  -- Store the part as root
end

function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    self:create_frame()
    self:render(0.001) -- Initial render call
    self:check_quality_level() -- Check game quality for effect visibility
end

-- Renders the acrylic blur effect by positioning and scaling a part based on UI frame.
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

        -- Convert 2D screen points to 3D world points
        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        -- Calculate width and height of the 3D part
        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        -- Position and scale the 3D part to match the UI frame's dimensions
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

    -- Connect to camera and frame property changes to update the blur effect
    Connections_Manager['cframe_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections_Manager['viewport_size_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections_Manager['field_of_view_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)
    Connections_Manager['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections_Manager['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    task.spawn(update)
end

-- Checks game quality level and adjusts blur visibility accordingly.
function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then -- Blur may not look good on lower quality settings
        self:change_visiblity(false)
    end

    Connections_Manager['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value
        self:change_visiblity(quality_level >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end

-- Configuration saving/loading functionality.
-- Uses `writefile`, `readfile`, `makefolder`, `isfile`, `isfolder` which depend on executor support.
local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            if writefile then
                writefile('iSightzWare/'..file_name..'.json', flags)
            else
                warn("writefile function not available, cannot save config.")
            end
        end)
        if not success_save then
            warn('Failed to save config: ', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if isfolder and not isfolder('iSightzWare') then
                makefolder('iSightzWare')
            end
            if isfile and not isfile('iSightzWare/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = isfile and readfile('iSightzWare/'..file_name..'.json') or nil
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success_load then
            warn('Failed to load config: ', result)
        end
        -- Ensure a default config structure is returned if loading fails
        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
        return result
    end
}, {})

-- Main UI Library and its functionalities.
local Library = {
    _config = Config:load(game.GameId, {}), -- Load configuration unique to this game (pass empty table for default)
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true, -- UI starts open by default
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _tab = 0 -- Counter for tab layout order
}
Library.__index = Library

-- Language settings (from sillly hub source.txt)
local GG = {
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

-- Custom Notification system (adapted from sillly hub source.txt)
function Library.SendNotification(settings)
    local NotificationContainer = CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("iSightzWareNotifications") or Instance.new("ScreenGui", CoreGui)
    NotificationContainer.Name = "iSightzWareNotifications"
    NotificationContainer.DisplayOrder = 999
    NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
    NotificationContainer.Position = UDim2.new(1, -310, 0, 10) -- Top right corner
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.ClipsDescendants = false;
    NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

    local UIListLayout = NotificationContainer:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
    UIListLayout.FillDirection = Enum.FillDirection.Vertical
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = NotificationContainer

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
    InnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40) -- Darker background
    InnerFrame.BackgroundTransparency = 0.1
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
    Body.TextColor3 = Color3.fromRGB(220, 220, 220) -- Slightly off-white
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
        wait(0.1) -- Small delay to allow text bounds to calculate
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10 -- Adjust height based on content
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end)

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.AbsoluteContentSize.Y) -- Adjust for existing notifications
        })
        tweenIn:Play()

        local duration = settings.duration or 5
        wait(duration)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, InnerFrame.Position.Y.Scale, InnerFrame.Position.Y.Offset) -- Slide out to the right
        })
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            Notification:Destroy() -- Clean up notification after it slides out
        end)
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = Workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_size_x / 1400 -- Base scale on a common viewport width
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

function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action) -- Disconnects UI when parent changes (e.g., script stops)
end

-- Checks if a flag exists and has a specific type in the config.
function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return false
    end
    return typeof(Library._config._flags[flag]) == flag_type
end

-- Removes a specific value from a table (used for multi-dropdown).
function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value == table_value then
            table.remove(__table, index)
            return -- Only remove one instance
        end
    end
end

-- UI Creation Function (main UI structure from sillly hub source.txt with modifications)
function Library:create_ui()
    -- Clean up old UIs if they exist
    local oldSilly = CoreGui:FindFirstChild('Silly')
    if oldSilly then
        Debris:AddItem(oldSilly, 0)
    end
    local oldISightz = CoreGui:FindFirstChild('iSightzBladeballScript')
    if oldISightz then
        Debris:AddItem(oldISightz, 0)
    end

    local Silly = Instance.new('ScreenGui')
    Silly.ResetOnSpawn = false
    Silly.Name = 'iSightzWare' -- Renamed UI to iSightzWare as requested
    Silly.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Silly.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.15
    Container.BackgroundColor3 = Color3.fromRGB(10, 10, 30) -- Darker background as requested (black UI)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0) -- Initial size for animation
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Silly
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(52, 66, 89) -- Border color
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479) -- Standard size
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder, will be transparent
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
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder, will be transparent
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text as requested
    ClientName.TextTransparency = 0.1 -- Slight transparency for glow effect
    ClientName.Text = 'iSightz Ware' -- Renamed UI Title as requested
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 100, 0, 13) -- Adjusted size
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.0560000017285347, 0, 0.054999999701976776, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder, will be transparent
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    }
    UIGradient.Parent = ClientName
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.13600000739097595, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent for highlight
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001' -- Placeholder icon
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.02500000037252903, 0, 0.054999999701976776, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
    Icon.Parent = Handler

    -- Discord Icon Button (Top-right, as requested)
    local DiscordIcon = Instance.new('ImageButton')
    DiscordIcon.Name = 'DiscordIcon'
    DiscordIcon.BackgroundTransparency = 1
    DiscordIcon.Size = UDim2.new(0, 24, 0, 24)
    DiscordIcon.Position = UDim2.new(1, -30, 0, 10) -- Top right corner
    DiscordIcon.Image = 'rbxassetid://6032230009' -- Generic Discord icon asset ID
    DiscordIcon.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon as requested
    DiscordIcon.Parent = Handler

    DiscordIcon.MouseButton1Click:Connect(function()
        -- Use pcall for safety when interacting with external services
        pcall(function()
            Library.SendNotification({
                Title = "Discord Link",
                Text = "Opening Discord link...",
                Duration = 2
            })
            game:GetService("BrowserService"):PromptOpenExternalUrl("https://discord.com/users/1204049262950883328")
        end)
    end)
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89) -- Divider color
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = '—' -- Minimize icon
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.96, 0, 0.02922755666077137, 0) -- Adjusted position
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = Silly

    -- UI Dragging functionality
    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections_Manager['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end
                Connections_Manager:disconnect('container_input_ended')
                self._dragging = false
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

    Connections_Manager['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections_Manager['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections_Manager:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.15;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        Silly.Enabled = not Silly.Enabled;
    end;

    -- Function to change UI visibility (expand/collapse)
    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52) -- Collapsed size for a compact look
            }):Play()
        end
    end
    
    function self:load()
        local content = {}
        for _, object in Silly:GetDescendants() do
            if object:IsA('ImageLabel') or object:IsA('ImageButton') then -- Preload ImageButtons too
                table.insert(content, object)
            end
        end
        ContentProvider:PreloadAsync(content) -- Preload assets for smoother UI
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            Connections_Manager['ui_scale'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        -- Initial UI expansion animation
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        AcrylicBlur.new(Container) -- Apply acrylic blur effect
        self._ui_loaded = true
    end

    -- Update tab visual state (pin position, text color, icon color)
    function self:update_tabs(tab: TextButton, LeftSection: ScrollingFrame, RightSection: ScrollingFrame)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end
            if object == tab then
                -- Apply selected tab styling (blue accent, less transparency)
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3) -- Adjust offset as needed for pin
                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.1,
                        TextColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.1,
                        ImageColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent
                    }):Play()
                end
                continue
            end
            -- Apply unselected tab styling (white text, more transparency)
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon
                }):Play()
            end
        end
    end

    -- Control visibility of sections based on selected tab
    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
                continue
            end
            object.Visible = false
        end
    end

    -- Function to create a new tab in the UI
    function self:create_tab(title: string, icon: string)
        local TabManager = {}
        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000
        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent for selected tab
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab -- Assign layout order for sorting
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text as requested
        TextLabel.TextTransparency = 0.7 -- Initial transparency for unselected tabs
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(200, 200, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929 -- Initial transparency for unselected icons
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
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
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
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

        self._tab += 1 -- Increment tab counter

        -- Activate the first tab on UI load
        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        -- Module Manager for creating UI components within tabs
        function TabManager:create_module(settings: any)
            local LayoutOrderModule = 0;
            local ModuleManager = {
                _state = false, -- Current toggle state of the module
                _size = 0, -- Current height of the options frame
                _multiplier = 0 -- Additional height needed for dropdowns
            }
            -- Determine the parent section (left or right)
            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93) -- Initial collapsed size
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(20, 20, 40) -- Dark background for module
            Module.Parent = settings.section
            Module.LayoutOrder = LayoutOrderModule -- Set initial layout order

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(52, 66, 89) -- Border color
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93) -- Occupies full module height initially
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.1
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045' -- Placeholder icon
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
            ModuleName.TextTransparency = 0.1
            if not settings.rich then
                ModuleName.Text = settings.title or "Module Title"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,255,255)'>Module</font> Title"
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
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(200, 200, 200) -- Light grey for description
            Description.TextTransparency = 0.2
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
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.7
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Dark grey for toggle background (off state)
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
            Circle.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Grey for toggle circle (off state)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.7
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark grey for keybind background
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
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8) -- Initial options size (small when collapsed)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            -- Function to change the module's state (on/off) and animate its expansion/collapse.
            function ModuleManager:change_state(state: boolean)
                self._state = state
                if self._state then
                    -- Expand module and options
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent for on state
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White circle
                        Position = UDim2.fromScale(0.53, 0.5) -- Move circle to the right
                    }):Play()
                else
                    -- Collapse module and options
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Dark grey for off state
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Grey circle
                        Position = UDim2.fromScale(0, 0.5) -- Move circle to the left
                    }):Play()
                end
                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config) -- Save config changes
                settings.callback(self._state) -- Execute module-specific callback
            end
            
            -- Connects a keybind to toggle the module's state.
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end
                Connections_Manager[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then -- Ignore if game-processed input
                        return
                    end
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    self:change_state(not self._state)
                end)
            end

            -- Scales the keybind display based on text length.
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

            -- Initialize module state based on saved config
            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag] -- Load saved state
                if ModuleManager._state then
                    Toggle.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent
                    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White circle
                    Circle.Position = UDim2.fromScale(0.53, 0.5) -- Move circle to 'on' position
                end
                settings.callback(ModuleManager._state) -- Apply initial state via callback
            else
                -- If no saved state or not a boolean, default to off.
                ModuleManager._state = false
                settings.callback(false)
            end

            -- Load and connect keybind if it exists in config
            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            -- Keybind setting interaction (right-click on module header)
            Connections_Manager[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then -- Right-click to set keybind
                    return
                end
                
                Library._choosing_keybind = true
                TextLabel.Text = "..." -- Indicate keybind selection mode
                
                Connections_Manager['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input_key: InputObject, process: boolean)
                    if process then
                        return
                    end
                    if input_key == Enum.UserInputState or input_key == Enum.UserInputType then
                        return
                    end
                    if input_key.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end
                    if input_key.KeyCode == Enum.KeyCode.Backspace then -- Clear keybind
                        ModuleManager:scale_keybind(true)
                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)
                        TextLabel.Text = 'None'
                        if Connections_Manager[settings.flag..'_keybind'] then
                            Connections_Manager:disconnect(settings.flag..'_keybind')
                        end
                        Connections_Manager:disconnect('keybind_choose_start')
                        Library._choosing_keybind = false
                        return
                    end
                    -- Set new keybind
                    Connections_Manager:disconnect('keybind_choose_start')
                    Library._config._keybinds[settings.flag] = tostring(input_key.KeyCode)
                    Config:save(game.GameId, Library._config)
                    if Connections_Manager[settings.flag..'_keybind'] then
                        Connections_Manager:disconnect(settings.flag..'_keybind')
                    end
                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    Library._choosing_keybind = false
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            -- Toggle module state on left-click of header
            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            -- Creates a paragraph element within the module's options.
            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1; -- Increment layout order for new element
                local ParagraphManager = {}
                
                if self._size == 0 then self._size = 11 end
                self._size += settings.customScale or 70 -- Add height for the paragraph
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end -- Resize module if already expanded
                Options.Size = UDim2.fromOffset(241, self._size) -- Set options frame size
            
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(20, 20, 40) -- Darker background
                Paragraph.BackgroundTransparency = 0.2
                Paragraph.Size = UDim2.new(0, 207, 0, 30) -- Initial size
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y -- Allows vertical resizing based on content
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule
            
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
                Body.TextColor3 = Color3.fromRGB(220, 220, 220) -- Slightly off-white
                
                if not settings.rich then
                    Body.Text = settings.text or "Placeholder text."
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,255,255)'>Placeholder</font> text."
                end
                
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                -- Hover effects for the paragraph
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 60) -- Slightly lighter on hover
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 40) -- Original dark background
                    }):Play()
                end)

                return ParagraphManager
            end

            -- Creates a simple text label element within the module's options.
            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextManager = {}
                if self._size == 0 then self._size = 11 end
                self._size += settings.CustomYSize or 50
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40) -- Darker background
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
                Body.TextColor3 = Color3.fromRGB(220, 220, 220)
                if not settings.rich then
                    Body.Text = settings.text or "Placeholder text."
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,255,255)'>Placeholder</font> text."
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
            
                -- Hover effects for the text frame
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Placeholder text."
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(255,255,255)'>Placeholder</font> text."
                    end
                end;
            
                return TextManager
            end

            -- Creates a textbox for user input.
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextboxManager = { _text = "" }
                if self._size == 0 then self._size = 11 end
                self._size += 32
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(40, 40, 60) -- Dark background for textbox
                Textbox.BackgroundTransparency = 0.1
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
                    settings.callback(self._text)
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                return TextboxManager
            end   

            -- Creates a checkbox toggle.
            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then self._size = 11 end
                self._size += 20
            
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 11
                end
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Checkbox Title"
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
                KeybindBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark background
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
                KeybindLabel.Text = Library._config._keybinds[settings.flag] 
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") 
                    or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9 -- Less transparent when off
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Dark grey for checkbox background (off state)
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
                Fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent for fill (on state)
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9) -- Fill the box
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0) -- Collapse the fill
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end
            
                -- Load initial state from config
                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end -- Right-click to set keybind
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
                            if Connections_Manager[settings.flag .. "_keybind"] then
                                Connections_Manager:disconnect(settings.flag .. "_keybind")
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
            
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections_Manager[settings.flag .. "_keybind"] then
                            Connections_Manager:disconnect(settings.flag .. "_keybind")
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
            
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)
            
                -- Connect module to its keybind for toggling
                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                })
                Connections_Manager[settings.flag .. "_keypress"] = keyPressConnection
            
                return CheckboxManager
            end

            -- Creates a horizontal divider, optionally with a title.
            function ModuleManager:create_divider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;
                if self._size == 0 then self._size = 11 end
                self._size += 27 -- Add height for the divider
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end

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
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White color for divider line
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2)
                
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),   
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0
                
                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2)
                    UICorner.Parent = Divider
                end;
                return true;
            end
            
            -- Creates a slider for numerical input.
            function ModuleManager:create_slider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local SliderManager = {}
                if self._size == 0 then self._size = 11 end
                self._size += 27 -- Add height for the slider
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                if SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark grey for slider track
                Drag.Parent = Slider
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4) -- Initial fill (halfway)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent for fill
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White circle
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.2
                Value.Text = '50' -- Initial value display
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                Value.Parent = Slider

                -- Sets the slider's visual and value, updates config, and calls callback.
                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0
                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10 -- One decimal place
                    end
                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value) -- Normalize to 0-1
                    
                    local slider_size = math.clamp(percentage, 0, 1) * Drag.Size.X.Offset -- Clamp between 0 and 1
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
    
                    Library._config._flags[settings.flag] = number_threshold -- Save to config
                    Value.Text = number_threshold -- Update displayed value
    
                    TweenService:Create(Fill, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { -- Faster tween for smoother dragging
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
    
                    settings.callback(number_threshold) -- Execute slider-specific callback
                end

                -- Updates the slider value based on mouse position.
                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position
                    self:set_percentage(percentage)
                end

                -- Handles mouse input for dragging the slider.
                function SliderManager:input()
                    SliderManager:update()
                    Connections_Manager['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    
                    Connections_Manager['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
                        Connections_Manager:disconnect('slider_drag_'..settings.flag)
                        Connections_Manager:disconnect('slider_input_'..settings.flag)
                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config); -- Save config when dragging ends
                        end;
                    end)
                end

                -- Initialize slider value from config or default.
                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;
    
                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                return SliderManager
            end

            -- Creates a dropdown menu for selecting options.
            function ModuleManager:create_dropdown(settings: any)
                if not settings.Order then LayoutOrderModule = LayoutOrderModule + 1; end;
                local DropdownManager = { _state = false, _size = 0 }
                if not settings.Order then
                    if self._size == 0 then self._size = 11 end
                    self._size += 44 -- Base height for dropdown
                end;
                if not settings.Order then
                    if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Placeholder
                Dropdown.Parent = Options

                if not settings.Order then Dropdown.LayoutOrder = LayoutOrderModule; else Dropdown.LayoutOrder = settings.OrderValue; end;
                if not Library._config._flags[settings.flag] then Library._config._flags[settings.flag] = {}; end; -- Initialize for multi-dropdown
                
                local TextLabel = Instance.new('TextLabel')
                if SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                TextLabel.Parent = Dropdown
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.9 -- Less transparent when folded
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0) -- Position below text label
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22) -- Collapsed height for options
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark background for dropdown box
                Box.Parent = TextLabel
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.TextTransparency = 0.2
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 10
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324' -- Down arrow icon
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                Arrow.Parent = Header
                
                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0) -- Initially 0 height
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options
                
                local UIListLayout = Instance.new('UIListLayout') -- Duplicate, intentional for specific layout
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                -- Updates the displayed selected option(s) and saves to config.
                function DropdownManager:update(option: any)
                    local convertStringToTable = function(inputString)
                        local result = {}
                        for value in string.gmatch(inputString, "([^,]+)") do
                            local trimmedValue = value:match("^%s*(.-)%s*$")
                            if trimmedValue ~= "" then table.insert(result, trimmedValue) end -- Ensure no empty strings
                        end
                        return result
                    end

                    local convertTableToString = function(inputTable)
                        return table.concat(inputTable, ", ")
                    end

                    if settings.multi_dropdown then
                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;
                        
                        local optionValue = (typeof(option) ~= 'string' and option.Name) or option;
                        local currentSelectionTable = Library._config._flags[settings.flag]

                        local found_in_config = false
                        for i, v in ipairs(currentSelectionTable) do
                            if v == optionValue then
                                table.remove(currentSelectionTable, i);
                                found_in_config = true
                                break;
                            end
                        end
                        if not found_in_config then
                            table.insert(currentSelectionTable, optionValue)
                        end
                        
                        CurrentOption.Text = convertTableToString(currentSelectionTable)
                        
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                if table.find(currentSelectionTable, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        Library._config._flags[settings.flag] = currentSelectionTable;
                    else
                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                
                    Config:save(game.GameId, Library._config)
                    settings.callback(option)
                end
                
                local CurrentDropSizeState = 0;

                -- Expands or collapses the dropdown menu.
                function DropdownManager:unfold_settings()
                    self._state = not self._state
                    if self._state then
                        -- Expand logic
                        ModuleManager._multiplier += self._size -- Add dropdown's full height to module's size
                        CurrentDropSizeState = self._size;
                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()
                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()
                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()
                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180 -- Rotate arrow up
                        }):Play()
                    else
                        -- Collapse logic
                        ModuleManager._multiplier -= CurrentDropSizeState -- Subtract previously added height
                        CurrentDropSizeState = 0;
                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()
                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()
                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()
                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0 -- Rotate arrow down
                        }):Play()
                    end
                end

                -- Populates the dropdown with options.
                if #settings.options > 0 then
                    DropdownManager._size = 3 -- Initial padding for options list
                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579 -- Default transparency for unselected option
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Placeholder
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then Library._config._flags[settings.flag] = {}; end;
                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end
                            DropdownManager:update(value)
                        end)
    
                        if index > settings.maximum_options then continue end
                        DropdownManager._size += 16 -- Add height for each option
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                -- Allows dynamically setting new options for the dropdown (e.g., for player lists).
                function DropdownManager:set_options(new_options: {string})
                    Options:ClearAllChildren() -- Clear existing options
                    DropdownManager._size = 3 -- Reset size calculation
                    for index, value in new_options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then Library._config._flags[settings.flag] = {}; end;
                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end
                            DropdownManager:update(value)
                        end)
                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                    -- Re-select the currently selected option if it exists in new options
                    if Library._config._flags[settings.flag] then
                        if settings.multi_dropdown then
                            -- Multi-dropdown already updates its display based on the table in config
                        else
                            DropdownManager:update(Library._config._flags[settings.flag])
                        end
                    end
                end

                -- Initialize current dropdown selection from config or default.
                if Library:flag_type(settings.flag, 'string') or Library:flag_type(settings.flag, 'table') then
                    local saved_value = Library._config._flags[settings.flag]
                    if saved_value and typeof(saved_value) == "table" then -- For multi-dropdown
                        CurrentOption.Text = table.concat(saved_value, ", ")
                    else -- For single selection dropdown
                        CurrentOption.Text = saved_value or settings.options[1] or "None"
                    end
                    
                    DropdownManager:update(CurrentOption.Text)
                else
                    CurrentOption.Text = settings.options[1] or "None"
                    DropdownManager:update(CurrentOption.Text)
                end

                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)
                
                return DropdownManager
            end

            return ModuleManager
        end
        return TabManager
    end

    -- UI Visibility Toggle (RightAlt)
    Connections_Manager['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        if process then return end -- Ignore if game-processed (e.g., typing in chat)
        if input.KeyCode == Enum.KeyCode.RightAlt then -- Changed to RightAlt as requested
            self._ui_open = not self._ui_open
            self:change_visiblity(self._ui_open)
        end
    end)
    -- Minimize button also toggles UI visibility
    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)
    return self
end

-- Initialize the main UI library
local main = Library.new()
-- Create tabs with specified titles and icons
local rage = main:create_tab('Blatant', 'rbxassetid://76499042599127') -- Placeholder icon for Blatant
local player = main:create_tab('Player', 'rbxassetid://126017907477623') -- Placeholder icon for Player
local world = main:create_tab('World', 'rbxassetid://85168909131990') -- Placeholder icon for World
local farm = main:create_tab('Farm', 'rbxassetid://132243429647479') -- Placeholder icon for Farm
local misc = main:create_tab('Misc', 'rbxassetid://132243429647479') -- Placeholder icon for Misc

repeat task.wait() until game:IsLoaded() -- Wait for the game to be fully loaded before proceeding

-- Auto Parry Core Functions (from iSightz and cele2stia merged and enhanced)
local function BlockMovement(actionName, inputState, inputObject)
    return Enum.ContextActionResult.Sink -- Prevents player input from affecting game (e.g., when spamming parry)
end

local function updateNavigation(guiObject: GuiObject | nil)
    GuiService.SelectedObject = guiObject -- Used for simulating navigation input
end

-- Performs the first parry action based on selected type (F_Key, Left_Click, Navigation).
local function performFirstPress(parryType)
    if parryType == 'F_Key' then
        VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil) -- Simulate F key press
    elseif parryType == 'Left_Click' then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) -- Simulate left click
    elseif parryType == 'Navigation' then
        local button = Players.LocalPlayer.PlayerGui.Hotbar.Block -- Assuming this is the block button
        if button then
            updateNavigation(button)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game) -- Simulate Enter key for navigation select
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game) -- Release Enter key
            task.wait(0.01) -- Small delay
            updateNavigation(nil) -- Deselect navigation object
        end
    end
end

local PrivateKey = nil
local PropertyChangeOrder = {}
local HashOne
local HashTwo
local HashThree

-- Function to find obfuscated remote event hashes (from cele2stia)
-- This uses reflection to find the hidden remote events used for parrying.
local LPH_NO_VIRTUALIZE = function(Function) return Function end -- Helper for preventing virtualization (executor specific)
LPH_NO_VIRTUALIZE(function()
    for _, Value in pairs(getgc(true)) do -- Iterate through the garbage collector for functions
        if type(Value) == "function" and islclosure(Value) then -- Check if it's a Lua closure
            local Protos = debug.getprotos(Value)
            local Upvalues = debug.getupvalues(Value)
            local Constants = debug.getconstants(Value)
            -- Identify the target function by its structure (number of protos, upvalues, constants)
            if Protos and Upvalues and Constants and (#Protos == 4) and (#Upvalues == 24) and (#Constants == 104) then
                Remotes[debug.getupvalue(Value, 16)] = debug.getconstant(Value, 62) -- Store remote and its hash
                Parry_Key = debug.getupvalue(Value, 17) -- Store the parry key (likely a hash)
                Remotes[debug.getupvalue(Value, 18)] = debug.getconstant(Value, 64)
                Remotes[debug.getupvalue(Value, 19)] = debug.getconstant(Value, 65)
                break
            end
        end
    end
end)()

-- Fallback for PropertyChangeOrder (from iSightz/cele2stia)
-- This attempts to find hidden remote events by monitoring PropertyChangeOrder.
LPH_NO_VIRTUALIZE(function()
    for Index, Object in next, game:GetDescendants() do
        if Object:IsA("RemoteEvent") and string.find(Object.Name, "\n") then -- Look for remote events with unusual names
            Object.Changed:Once(function() -- Connect to the first change event
                table.insert(PropertyChangeOrder, Object)
            end)
        end
    end
end)()
repeat task.wait() until #PropertyChangeOrder == 3 -- Wait until all 3 expected remotes are found
local ShouldPlayerJump = PropertyChangeOrder[1]
local MainRemote = PropertyChangeOrder[2]
local GetOpponentPosition = PropertyChangeOrder[3]

-- Update Parry_Key if not found by the above method (alternative way to find the parry hash)
for Index, Value in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
    if Value and Value.Function and not iscclosure(Value.Function) then -- Check if it's a Lua function and not C function
        for Index2, Value2 in pairs(getupvalues(Value.Function)) do
            if type(Value2) == "function" then
                Parry_Key = getupvalue(getupvalue(Value2, 2), 17); -- Dig deeper into upvalues to find the key
            end;
        end;
    end;
end;

-- Consolidated Parry function (fires the obfuscated remotes)
local function Parry(...)
    for Remote, Hash in pairs(Remotes) do
        Remote:FireServer(Hash, Parry_Key, ...)
    end
end

-- Animation utilities (from sillly hub source.txt)
local Animation = {}
Animation.storage = {}
Animation.current = nil
Animation.track = nil

for _, v in pairs(ReplicatedStorage.Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end

local Emotes_Data = {}
for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end
table.sort(Emotes_Data) -- Sort emotes alphabetically

local Auto_Parry = {}

-- Loads and plays the specific parry animation.
function Auto_Parry.Parry_Animation()
    local Parry_Animation = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local Current_Sword = Player.Character:GetAttribute('CurrentlyEquippedSword')

    if not Current_Sword then return end
    if not Parry_Animation then return end

    local Sword_Data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)

    if not Sword_Data or not Sword_Data['AnimationType'] then return end

    -- Find the correct parry animation based on the equipped sword's animation type.
    for _, object in pairs(ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local sword_animation_type = 'GrabParry'
                if object:FindFirstChild('Grab') then sword_animation_type = 'Grab' end
                Parry_Animation = object[sword_animation_type]
            end
        end
    end
    -- Load and play the animation
    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

-- Plays a general animation (used for emotes).
function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]
    if not Animations then return false end
    local Animator = Player.Character.Humanoid.Animator
    if Animation.track then Animation.track:Stop() end -- Stop previous animation if any
    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()
    Animation.current = v
end

-- Gets all real balls in the workspace.
function Auto_Parry.Get_Balls()
    local Balls = {}
    for _, Instance in pairs(Workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false -- Set to non-collidable to prevent issues
            table.insert(Balls, Instance)
        end
    end
    return Balls
end

-- Gets the first real ball found in the workspace.
function Auto_Parry.Get_Ball()
    for _, Instance in pairs(Workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            return Instance
        end
    end
    return nil
end

-- Gets a training ball in the lobby.
function Auto_Parry.Lobby_Balls()
    for _, Instance in pairs(Workspace.TrainingBalls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            return Instance
        end
    end
    return nil
end

local Closest_Entity = nil
-- Finds the closest living player character to the local player.
function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge
    local Found_Entity = nil
    for _, Entity in pairs(Workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player.Character) then -- Ensure it's not self
            if Entity.PrimaryPart then
                local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
                if Distance < Max_Distance then
                    Max_Distance = Distance
                    Found_Entity = Entity
                end
            end
        end
    end
    Closest_Entity = Found_Entity
    return Found_Entity
end

-- Gets properties of the closest entity.
function Auto_Parry:Get_Entity_Properties()
    Auto_Parry.Closest_Player()
    if not Closest_Entity then return false end
    local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
    local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
    return {
        Velocity = Entity_Velocity,
        Direction = Entity_Direction,
        Distance = Entity_Distance
    }
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
-- Prepares data for the parry action based on the selected parry type.
function Auto_Parry.Parry_Data(Parry_Type)
    Auto_Parry.Closest_Player()
    local Events = {}
    local Camera = Workspace.CurrentCamera
    local Vector2_Mouse_Location
    
    -- Determine mouse/screen center location
    if Last_Input == Enum.UserInputType.MouseButton1 or Last_Input == Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    if isMobile then Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2} end -- Force center for mobile
    
    -- Get all player screen positions for event data
    local Players_Screen_Positions = {}
    for _, v in pairs(Workspace.Alive:GetChildren()) do
        if v ~= Player.Character then
            local worldPos = v.PrimaryPart.Position
            local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
            if isOnScreen then
                Players_Screen_Positions[v] = Vector2.new(screenPos.X, screenPos.Y)
            end
            Events[tostring(v)] = screenPos
        end
    end
    
    -- Return CFrame and event data based on selected parry type
    if Parry_Type == 'Camera' then return {0, Camera.CFrame, Events, Vector2_Mouse_Location} end
    if Parry_Type == 'Backwards' then
        local Backwards_Direction = Camera.CFrame.LookVector * -10000 -- Look behind
        Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z) -- Keep Y constant for horizontal aim
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == 'Straight' then
        local Aimed_Player = nil
        local Closest_Distance = math.huge
        local Mouse_Vector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])
        -- Find the player closest to the mouse cursor
        for _, v in pairs(Workspace.Alive:GetChildren()) do
            if v ~= Player.Character then
                local worldPos = v.PrimaryPart.Position
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (Mouse_Vector - playerScreenPos).Magnitude
                    if distance < Closest_Distance then
                        Closest_Distance = distance
                        Aimed_Player = v
                    end
                end
            end
        end
        -- Aim at the closest player, fallback to closest entity if no player near mouse
        if Aimed_Player then
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Aimed_Player.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        else
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        end
    end
    if Parry_Type == 'Random' then return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))), Events, Vector2_Mouse_Location} end
    if Parry_Type == 'High' then
        local High_Direction = Camera.CFrame.UpVector * 10000 -- Look straight up
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == 'Left' then
        local Left_Direction = Camera.CFrame.RightVector * 10000 -- Look left
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == 'Right' then
        local Right_Direction = Camera.CFrame.RightVector * 10000 -- Look right
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == 'RandomTarget' then
        local candidates = {}
        for _, v in pairs(Workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                if isOnScreen then table.insert(candidates, { character = v, screenXY = { screenPos.X, screenPos.Y } }) end
            end
        end
        if #candidates > 0 then
            local pick = candidates[ math.random(1, #candidates) ]
            local lookCFrame = CFrame.new(Player.Character.PrimaryPart.Position, pick.character.PrimaryPart.Position)
            return {0, lookCFrame, Events, pick.screenXY}
        else
            return {0, Camera.CFrame, Events, { Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2 }}
        end
    end
    return Parry_Type -- Should not be reached if types are handled
end

-- Executes the parry action, plays animation, and fires remotes.
function Auto_Parry.Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)
    if not firstParryFired then -- On the very first parry, simulate input as per user choice
        performFirstPress(firstParryType)
        firstParryFired = true
    else
        Parry(Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4]) -- Fire actual parry remote
    end
    -- Limit consecutive parries to prevent engine overload/detection
    if Parries > 7 then return false end
    Parries += 1
    task.delay(0.5, function() if Parries > 0 then Parries -= 1 end end)
end

local Lerp_Radians = 0
local Last_Warping = tick()
-- Linear interpolation function
function Auto_Parry.Linear_Interpolation(a, b, time_volume) return a + (b - a) * time_volume end
local Curving = tick() -- Tracks time for ball curving detection

-- Checks if the incoming ball is "curved" (i.e., not a straight shot).
function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then return false end
    local Zoomies = Ball:FindFirstChild('zoomies')
    if not Zoomies then return false end

    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude
    local Speed_Threshold = math.min(Speed / 100, 40)
    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)
    local Dot_Difference = Dot - Direction_Similarity
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Pings = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    local Dot_Threshold = 0.5 - (Pings / 1000) -- Adjust threshold based on ping
    local Reach_Time = Distance / Speed - (Pings / 1000)
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold
    local Clamped_Dot = math.clamp(Dot, -1, 1)
    local Radians = math.rad(math.asin(Clamped_Dot))
    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)

    if Speed > 100 and Reach_Time > Pings / 10 then Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15) end
    if Distance < Ball_Distance_Threshold then return false end
    if Dot_Difference < Dot_Threshold then return true end
    if Lerp_Radians < 0.018 then Last_Warping = tick() end
    if (tick() - Last_Warping) < (Reach_Time / 1.5) then return true end
    if (tick() - Curving) < (Reach_Time / 1.5) then return true end
    return Dot < Dot_Threshold
end

-- Gets properties of the ball.
function Auto_Parry:Get_Ball_Properties()
    local Ball = Auto_Parry.Get_Ball()
    local Ball_Velocity = Vector3.zero
    local Ball_Origin = Ball
    if Ball then
        local zoomies = Ball:FindFirstChild('zoomies')
        if zoomies then
            Ball_Velocity = zoomies.VectorVelocity
        end
    end
    -- If no ball, return default values
    if not Ball_Origin then
        return {
            Velocity = Vector3.zero,
            Direction = Vector3.zero,
            Distance = math.huge,
            Dot = 0
        }
    end

    local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
    local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)

    return {
        Velocity = Ball_Velocity,
        Direction = Ball_Direction,
        Distance = Ball_Distance,
        Dot = Ball_Dot
    }
end

-- Calculates spam parry accuracy based on ball and entity properties.
function Auto_Parry.Spam_Service(self)
    local Ball = Auto_Parry.Get_Ball()
    local Entity = Auto_Parry.Closest_Player()

    if not Ball or not Entity or not Entity.PrimaryPart then return 0 end

    local Spam_Accuracy = 0
    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)
    local Target_Position = Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)
    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6, 95)

    if self.Entity_Properties.Distance > Maximum_Spam_Distance or
       self.Ball_Properties.Distance > Maximum_Spam_Distance or
       Target_Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed
    Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot
    return Spam_Accuracy
end

-- Listen for various ball-related remote events for anti-detection.
ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    if b then Infinity = true else Infinity = false end
end)

ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
    if d then deathshit = true else deathshit = false end
end)

ReplicatedStorage.Remotes.TimeHoleHoldBall.OnClientEvent:Connect(function(e, f)
    if f then timehole = true else timehole = false end
end)

-- Main auto parry loop
local Last_Parry = 0
local Balls = Workspace:WaitForChild('Balls')

local function GetBallForLoop()
    for _, Ball in ipairs(Balls:GetChildren()) do
        if Ball:FindFirstChild("ff") then
            return Ball
        end
    end
    return nil
end

local PlayerGui = Player:WaitForChild("PlayerGui")
local Hotbar = PlayerGui:WaitForChild("Hotbar")
local ParryCD = Hotbar.Block.UIGradient
local AbilityCD = Hotbar.Ability.UIGradient

-- Checks if parry cooldown is active
local function isCooldownInEffect1(uigradient)
    return uigradient.Offset.Y < 0.4
end

-- Checks if ability cooldown is active
local function isCooldownInEffect2(uigradient)
    return uigradient.Offset.Y == 0.5
end

-- Attempts to use ability if parry is on cooldown (Cooldown Protection).
local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) and getgenv().CooldownProtectionEnabled then
        game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

-- Automatically uses abilities.
local function AutoAbility()
    if isCooldownInEffect2(AbilityCD) and getgenv().AutoAbilityEnabled then
        -- Check for common offensive abilities
        if Player.Character.Abilities["Raging Deflection"] and Player.Character.Abilities["Raging Deflection"].Enabled or
           Player.Character.Abilities["Rapture"] and Player.Character.Abilities["Rapture"].Enabled or
           Player.Character.Abilities["Calming Deflection"] and Player.Character.Abilities["Calming Deflection"].Enabled or
           Player.Character.Abilities["Aerodynamic Slash"] and Player.Character.Abilities["Aerodynamic Slash"].Enabled or
           Player.Character.Abilities["Fracture"] and Player.Character.Abilities["Fracture"].Enabled or
           Player.Character.Abilities["Death Slash"] and Player.Character.Abilities["Death Slash"].Enabled then
            Parried = true
            game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
            task.wait(2.432) -- Wait for ability animation/cooldown
            -- Specific for Death Slash
            if Player.Character.Abilities["Death Slash"] and Player.Character.Abilities["Death Slash"].Enabled then
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            end
            return true
        end
    end
    return false
end

-- Slash of Fury Detection (from iSightz/cele2stia). Automatically parries during Slash of Fury.
Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == 'ComboCounter' then
            local Sof_Label = Child:FindFirstChildOfClass('TextLabel')
            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)
                    if Slashes_Counter and Slashes_Counter < 32 then -- Parry until 32 slashes (max combo)
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
                    task.wait()
                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)

-- Phantom V2 Detection (from iSightz and cele2stia). Prevents being stuck by Phantom.
RunTime.ChildAdded:Connect(function(Object)
    local Name = Object.Name
    if getgenv().PhantomV2Detection then
        if Name == "maxTransmission" or Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = Player.Character or Player.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    CurrentBall = GetBallForLoop()
                    Weld:Destroy() -- Remove the weld to unstick

                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
                            if Highlighted == true then
                                Player.Character.Humanoid.WalkSpeed = 36 -- Increase walk speed temporarily
                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    local PlayerPosition = HumanoidRootPart.Position
                                    local BallPosition = CurrentBall.Position
                                    local PlayerToBall = (BallPosition - PlayerPosition).Unit
                                    Player.Character.Humanoid:Move(PlayerToBall, false) -- Move towards ball
                                end
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
                                Player.Character.Humanoid.WalkSpeed = 10 -- Reset speed
                                Player.Character.Humanoid:Move(Vector3.new(0, 0, 0), false) -- Stop movement
                                task.delay(3, function() Player.Character.Humanoid.WalkSpeed = 16 end) -- Restore default after delay
                                CurrentBall = nil
                            end
                        end)
                        task.delay(3, function() -- Timeout to prevent endless movement if ball disappears
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
                                Player.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                Player.Character.Humanoid.WalkSpeed = 16 -- Restore default walkspeed
                                CurrentBall = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- UI Modules
do -- Blatant Tab Modules (Auto Parry, Spam Parry, Trigger Bot)
    local module = rage:create_module({
        title = 'Auto Parry',
        flag = 'Auto_Parry',
        description = 'Automatically parries incoming balls.',
        section = 'left',
        callback = function(value: boolean)
            if getgenv().AutoParryNotify then
                if value then Library.SendNotification({ title = "Module Notification", text = "Auto Parry has been turned ON", duration = 3 })
                else Library.SendNotification({ title = "Module Notification", text = "Auto Parry has been turned OFF", duration = 3 }) end
            end
            if value then
                Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
                    local One_Ball = Auto_Parry.Get_Ball()
                    local Balls = Auto_Parry.Get_Balls()

                    for _, Ball in pairs(Balls) do
                        if not Ball then return end
                        local Zoomies = Ball:FindFirstChild('zoomies')
                        if not Zoomies then return end

                        Ball:GetAttributeChangedSignal('target'):Once(function() Parried = false end)
                        if Parried then return end

                        local Ball_Target = Ball:GetAttribute('target')
                        local One_Target = One_Ball:GetAttribute('target')
                        local Velocity = Zoomies.VectorVelocity
                        local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
                        local Ping_Threshold = math.clamp(Ping / 10, 5, 17) -- Adjust based on ping
                        local Speed = Velocity.Magnitude
                        local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                        local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002
                        local effectiveMultiplier = Speed_Divisor_Multiplier
                        if getgenv().RandomParryAccuracyEnabled then
                            if Speed < 200 then effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                            else effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99) end
                        end
                        local speed_divisor = speed_divisor_base * effectiveMultiplier
                        local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5)
                        local Curved = Auto_Parry.Is_Curved()

                        -- Anti-abilities/effects
                        if Ball:FindFirstChild('AeroDynamicSlashVFX') then Debris:AddItem(Ball.AeroDynamicSlashVFX, 0) Tornado_Time = tick() end
                        if RunTime:FindFirstChild('Tornado') then if (tick() - Tornado_Time) < (RunTime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then return end end
                        if One_Target == tostring(Player) and Curved then return end -- If curved and target is self, don't parry
                        if Ball:FindFirstChild("ComboCounter") then return end
                        local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild('SingularityCape')
                        if Singularity_Cape then return end
                        if getgenv().InfinityDetection and Infinity then return end
                        if getgenv().DeathSlashDetection and deathshit then return end
                        if getgenv().TimeHoleDetection and timehole then return end
                        
                        -- Main parry condition
                        if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                            if AutoAbility() then return end -- Try auto ability first if enabled
                            if cooldownProtection() then return end -- Try cooldown protection if enabled
                            local Parry_Time = os.clock()
                            local Time_View = Parry_Time - (Last_Parry)
                            if Time_View > 0.5 then Auto_Parry.Parry_Animation() end -- Play animation only if enough time passed
                            if getgenv().AutoParryKeypress then VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil) -- Simulate F key
                            else Auto_Parry.Parry(Selected_Parry_Type) end -- Direct parry
                            Last_Parry = Parry_Time
                            Parried = true
                        end
                        local Last_Parrys = tick()
                        repeat RunService.PreSimulation:Wait() until (tick() - Last_Parrys) >= 1 or not Parried
                        Parried = false -- Reset parry flag after a delay or if not parried
                    end
                end)
            else
                if Connections_Manager['Auto Parry'] then Connections_Manager:disconnect('Auto Parry') end
            end
        end
    })

    local dropdown3 = module:create_dropdown({
        title = 'First Parry Type',
        flag = 'First_Parry_Type',
        options = { 'F_Key', 'Left_Click', 'Navigation' },
        multi_dropdown = false,
        maximum_options = 3,
        callback = function(value) firstParryType = value end
    })

    local parryTypeMap = {
        ["Camera"] = "Camera", ["Random"] = "Random", ["Backwards"] = "Backwards",
        ["Straight"] = "Straight", ["High"] = "High", ["Left"] = "Left",
        ["Right"] = "Right", ["Random Target"] = "RandomTarget"
    }
    local dropdown = module:create_dropdown({
        title = 'Parry Type',
        flag = 'Parry_Type',
        options = { 'Camera', 'Random', 'Backwards', 'Straight', 'High', 'Left', 'Right', 'Random Target' },
        multi_dropdown = false,
        maximum_options = 8,
        callback = function(value: string) Selected_Parry_Type = parryTypeMap[value] or value end
    })

    module:create_slider({
        title = 'Parry Accuracy',
        flag = 'Parry_Accuracy',
        maximum_value = 100,
        minimum_value = 1,
        value = 100, -- Default value
        round_number = true,
        callback = function(value: boolean) Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99) end
    })
    module:create_divider({})
    module:create_checkbox({
        title = "Infinity Detection",
        flag = "Infinity_Detection",
        callback = function(value: boolean) getgenv().InfinityDetection = value end
    })
    module:create_checkbox({
        title = "Anti Phantom",
        flag = "Anti_Phantom",
        callback = function(value: boolean) getgenv().PhantomV2Detection = value end
    })
    module:create_checkbox({
        title = "Death Slash Detection",
        flag = "Death_Slash_Detection",
        callback = function(value: boolean) getgenv().DeathSlashDetection = value end
    })
    module:create_checkbox({
        title = "Time Hole Detection",
        flag = "Time_Hole_Detection",
        callback = function(value: boolean) getgenv().TimeHoleDetection = value end
    })
    module:create_checkbox({
        title = "Auto Ability",
        flag = "Auto_Ability",
        callback = function(value: boolean) getgenv().AutoAbilityEnabled = value end
    })
    module:create_checkbox({
        title = "Cooldown Protection",
        flag = "Cooldown_Protection",
        callback = function(value: boolean) getgenv().CooldownProtectionEnabled = value end
    })
    module:create_checkbox({
        title = "Random Parry Accuracy",
        flag = "Random_Parry_Accuracy",
        callback = function(value: boolean) getgenv().RandomParryAccuracyEnabled = value end
    })
    module:create_checkbox({
        title = "Keypress",
        flag = "Auto_Parry_Keypress",
        callback = function(value: boolean) getgenv().AutoParryKeypress = value end
    })
    module:create_checkbox({
        title = "Notify",
        flag = "Auto_Parry_Notify",
        callback = function(value: boolean) getgenv().AutoParryNotify = value end
    })

    -- Auto Spam Parry Module
    local SpamParry = rage:create_module({
        title = 'Auto Spam Parry',
        flag = 'Auto_Spam_Parry',
        description = 'Automatically spam parries the ball.',
        section = 'right',
        callback = function(value: boolean)
            if getgenv().AutoSpamNotify then
                if value then Library.SendNotification({ title = "Module Notification", text = "Auto Spam Parry turned ON", duration = 3 })
                else Library.SendNotification({ title = "Module Notification", text = "Auto Spam Parry turned OFF", duration = 3 }) end
            end
            if value then
                Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
                    local Ball = Auto_Parry.Get_Ball()
                    if not Ball then return end
                    local Zoomies = Ball:FindFirstChild('zoomies')
                    if not Zoomies then return end
                    Auto_Parry.Closest_Player()
                    if not Closest_Entity then return end -- Ensure closest entity exists
                    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
                    local Ping_Threshold = math.clamp(Ping / 10, 1, 16)
                    local Ball_Target = Ball:GetAttribute('target')
                    local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                    local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                    local Spam_Accuracy = Auto_Parry.Spam_Service({ Ball_Properties = Ball_Properties, Entity_Properties = Entity_Properties, Ping = Ping_Threshold })
                    local Target_Position = Closest_Entity.PrimaryPart.Position
                    local Target_Distance = Player:DistanceFromCharacter(Target_Position)
                    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                    local Ball_Direction = Zoomies.VectorVelocity.Unit
                    local Dot = Direction:Dot(Ball_Direction)
                    local Distance = Player:DistanceFromCharacter(Ball.Position)
                    
                    if not Ball_Target then return end
                    if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then return end
                    local Pulsed = Player.Character:GetAttribute('Pulsed')
                    if Pulsed then return end -- Don't spam if pulsed (ability)
                    if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then return end -- Distant targets
                    
                    local threshold = ParryThreshold
                    if Distance <= Spam_Accuracy and Parries > threshold then -- Use Parries to limit spam rate
                        if getgenv().SpamParryKeypress then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        else Auto_Parry.Parry(Selected_Parry_Type) end
                    end
                end)
            else
                if Connections_Manager['Auto Spam'] then Connections_Manager:disconnect('Auto Spam') end
            end
        end
    })

    local dropdown2 = SpamParry:create_dropdown({
        title = 'Parry Type',
        flag = 'Spam_Parry_Type',
        options = { 'Legit', 'Blatant' }, -- This dropdown is cosmetic as the parry type is controlled by main 'Parry Type' dropdown
        multi_dropdown = false,
        maximum_options = 2,
        callback = function(value: string) end -- Callback is empty as functionality not explicitly defined.
    })
    SpamParry:create_slider({
        title = "Parry Threshold",
        flag = "Parry_Threshold",
        maximum_value = 3,
        minimum_value = 1,
        value = 2.5, -- Default value
        round_number = false,
        callback = function(value: number) ParryThreshold = value end
    })
    SpamParry:create_divider({})

    -- Animation Fix for spamming (PC only)
    if not isMobile then
        local AnimationFix = SpamParry:create_checkbox({
            title = "Animation Fix",
            flag = "AnimationFix",
            callback = function(value: boolean)
                if value then
                    Connections_Manager['Animation Fix'] = RunService.PreSimulation:Connect(function()
                        local Ball = Auto_Parry.Get_Ball()
                        if not Ball then return end
                        local Zoomies = Ball:FindFirstChild('zoomies')
                        if not Zoomies then return end
                        Auto_Parry.Closest_Player()
                        if not Closest_Entity then return end
                        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
                        local Ping_Threshold = math.clamp(Ping / 10, 10, 16)
                        local Ball_Target = Ball:GetAttribute('target')
                        local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                        local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                        local Spam_Accuracy = Auto_Parry.Spam_Service({ Ball_Properties = Ball_Properties, Entity_Properties = Entity_Properties, Ping = Ping_Threshold })
                        local Target_Position = Closest_Entity.PrimaryPart.Position
                        local Target_Distance = Player:DistanceFromCharacter(Target_Position)
                        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                        local Ball_Direction = Zoomies.VectorVelocity.Unit
                        local Dot = Direction:Dot(Ball_Direction)
                        local Distance = Player:DistanceFromCharacter(Ball.Position)
                        if not Ball_Target then return end
                        if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then return end
                        local Pulsed = Player.Character:GetAttribute('Pulsed')
                        if Pulsed then return end
                        if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then return end
                        local threshold = ParryThreshold
                        if Distance <= Spam_Accuracy and Parries > threshold then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) end
                    end)
                else
                    if Connections_Manager['Animation Fix'] then Connections_Manager:disconnect('Animation Fix') end
                end
            end
        })
        AnimationFix:change_state(false) -- Default to off, user can toggle
    end
    SpamParry:create_checkbox({
        title = "Keypress",
        flag = "Auto_Spam_Parry_Keypress",
        callback = function(value: boolean) getgenv().SpamParryKeypress = value end
    })
    SpamParry:create_checkbox({
        title = "Notify",
        flag = "Auto_Spam_Parry_Notify",
        callback = function(value: boolean) getgenv().AutoSpamNotify = value end
    })

    -- Manual Spam Parry Module (for player-initiated spamming)
    local ManualSpam = rage:create_module({
        title = 'Manual Spam Parry',
        flag = 'Manual_Spam_Parry',
        description = 'Manually spams Parry (using F key or UI button).',
        section = 'right',
        callback = function(value: boolean)
            if getgenv().ManualSpamNotify then
                if value then Library.SendNotification({ title = "Module Notification", text = "Manual Spam Parry turned ON", duration = 3 })
                else Library.SendNotification({ title = "Module Notification", text = "Manual Spam Parry turned OFF", duration = 3 }) end
            end
            if value then
                Connections_Manager['Manual Spam'] = RunService.PreSimulation:Connect(function()
                    if getgenv().spamui then return end -- If UI button is active, don't use keypress
                    if getgenv().ManualSpamKeypress then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    else Auto_Parry.Parry(Selected_Parry_Type) end
                end)
            else
                if Connections_Manager['Manual Spam'] then Connections_Manager:disconnect('Manual Spam') end
            end
        end
    })
    ManualSpam:change_state(false) -- Default to off

    if isMobile then -- Mobile UI for Manual Spam
        ManualSpam:create_checkbox({
            title = "UI",
            flag = "Manual_Spam_UI",
            callback = function(value: boolean)
                getgenv().spamui = value
                if value then
                    local gui = Instance.new("ScreenGui")
                    gui.Name = "ManualSpamUI"
                    gui.ResetOnSpawn = false
                    gui.Parent = CoreGui
                    local frame = Instance.new("Frame")
                    frame.Name = "MainFrame"
                    frame.Position = UDim2.new(0, 20, 0, 20)
                    frame.Size = UDim2.new(0, 200, 0, 100)
                    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 30) -- Dark background
                    frame.BackgroundTransparency = 0.3
                    frame.BorderSizePixel = 0
                    frame.Active = true
                    frame.Draggable = true
                    frame.Parent = gui
                    local uiCorner = Instance.new("UICorner")
                    uiCorner.CornerRadius = UDim.new(0, 12)
                    uiCorner.Parent = frame
                    local uiStroke = Instance.new("UIStroke")
                    uiStroke.Thickness = 2
                    uiStroke.Color = Color3.fromRGB(0, 120, 255) -- Blue accent
                    uiStroke.Parent = frame
                    local button = Instance.new("TextButton")
                    button.Name = "ClashModeButton"
                    button.Text = "Clash Mode"
                    button.Size = UDim2.new(0, 160, 0, 40)
                    button.Position = UDim2.new(0.5, -80, 0.5, -20)
                    button.BackgroundTransparency = 1
                    button.BorderSizePixel = 0
                    button.Font = Enum.Font.GothamSemibold
                    button.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                    button.TextSize = 22
                    button.Parent = frame
                    local activated = false
                    local function toggle()
                        activated = not activated
                        button.Text = activated and "Stop" or "Clash Mode"
                        if activated then
                            Connections_Manager['Manual Spam UI'] = game:GetService("RunService").Heartbeat:Connect(function() Auto_Parry.Parry(Selected_Parry_Type) end)
                        else
                            if Connections_Manager['Manual Spam UI'] then Connections_Manager:disconnect('Manual Spam UI') end
                        end
                    end
                    button.MouseButton1Click:Connect(toggle)
                else
                    if CoreGui:FindFirstChild("ManualSpamUI") then CoreGui:FindFirstChild("ManualSpamUI"):Destroy() end
                    if Connections_Manager['Manual Spam UI'] then Connections_Manager:disconnect('Manual Spam UI') end
                end
            end
        })
    end
    ManualSpam:create_checkbox({
        title = "Keypress",
        flag = "Manual_Spam_Keypress",
        callback = function(value: boolean) getgenv().ManualSpamKeypress = value end
    })
    ManualSpam:create_checkbox({
        title = "Notify",
        flag = "Manual_Spam_Parry_Notify",
        callback = function(value: boolean) getgenv().ManualSpamNotify = value end
    })
end

do -- Player Tab Modules (Player Follow, Hit Sounds, Ability ESP)
    local function getPlayerNames()
        local names = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player then
                table.insert(names, p.DisplayName)
            end
        end
        table.sort(names)
        return names
    end

    local PlayerFollow = player:create_module({
        title = 'Player Follow',
        flag = 'Player_Follow',
        description = 'Follows the selected player.',
        section = 'left',
        callback = function(value)
            getgenv().PlayerFollowEnabled = value
            if value then
                Connections_Manager['Player Follow'] = RunService.Heartbeat:Connect(function()
                    if not SelectedPlayerFollow then return end
                    local targetPlayer = Players:FindFirstChild(SelectedPlayerFollow)
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character.PrimaryPart then
                        local char = Player.Character
                        if char then
                            local humanoid = char:FindFirstChild("Humanoid")
                            if humanoid then humanoid:MoveTo(targetPlayer.Character.PrimaryPart.Position) end
                        end
                    end
                end)
            else
                if Connections_Manager['Player Follow'] then Connections_Manager:disconnect('Player Follow') end
            end
        end
    })

    local followDropdown
    local initialOptions = getPlayerNames()
    if #initialOptions > 0 then
        followDropdown = PlayerFollow:create_dropdown({
            title = "Follow Target",
            flag = "Follow_Target",
            options = initialOptions,
            multi_dropdown = false,
            maximum_options = #initialOptions,
            callback = function(value)
                if value then
                    SelectedPlayerFollow = value
                    if getgenv().FollowNotifyEnabled then Library.SendNotification({ title = "Module Notification", text = "Now following: " .. value, duration = 3 }) end
                end
            end
        })
        SelectedPlayerFollow = initialOptions[1] -- Select first player by default
        followDropdown:update(SelectedPlayerFollow) -- Update dropdown display
        getgenv().FollowDropdown = followDropdown -- Store for updates
    else
        SelectedPlayerFollow = nil
        followDropdown = PlayerFollow:create_dropdown({ -- Create a blank dropdown if no players
            title = "Follow Target",
            flag = "Follow_Target",
            options = {},
            multi_dropdown = false,
            maximum_options = 1,
            callback = function(value) SelectedPlayerFollow = value end
        })
        followDropdown:update("No Players") -- Display 'No Players'
        getgenv().FollowDropdown = followDropdown
    end

    -- Periodically update the player list in the dropdown
    local lastOptionsString = table.concat(initialOptions, ",")
    local updateTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        updateTimer = updateTimer + dt
        if updateTimer >= 10 then -- Update every 10 seconds
            local newOptions = getPlayerNames()
            table.sort(newOptions)
            local newOptionsString = table.concat(newOptions, ",")
            if newOptionsString ~= lastOptionsString then
                if followDropdown then
                    if #newOptions > 0 then
                        followDropdown:set_options(newOptions) -- Call set_options on the dropdown manager
                        if not table.find(newOptions, SelectedPlayerFollow) then -- If current target leaves, pick new first one
                            SelectedPlayerFollow = newOptions[1]
                            followDropdown:update(SelectedPlayerFollow)
                        end
                    else
                        SelectedPlayerFollow = nil
                        followDropdown:set_options({}) -- Clear options if no players
                        followDropdown:update("No Players")
                    end
                end
                lastOptionsString = newOptionsString
            end
            updateTimer = 0
        end
    end)

    PlayerFollow:create_checkbox({
        title = "Notify",
        flag = "Follow_Notify",
        default = false,
        callback = function(value) getgenv().FollowNotifyEnabled = value end
    })

    local HitSounds = player:create_module({
        title = 'Hit Sounds',
        flag = 'Hit_Sounds',
        description = 'Plays custom sounds on parry success.',
        section = 'right',
        callback = function(value) hit_Sound_Enabled = value end
    })

    local Folder = Instance.new("Folder")
    Folder.Name = "Useful Utility"
    Folder.Parent = Workspace
    local hit_Sound = Instance.new('Sound', Folder)
    hit_Sound.Volume = 6
    hit_Sound.Looped = false -- Ensure hit sounds don't loop

    local hitSoundOptions = {
        "Medal", "Fatality", "Skeet", "Switches", "Rust Headshot", "Neverlose Sound",
        "Bubble", "Laser", "Steve", "Call of Duty", "Bat", "TF2 Critical", "Saber", "Bameware"
    }
    local hitSoundIds = {
        Medal = "rbxassetid://6607336718", Fatality = "rbxassetid://6607113255", Skeet = "rbxassetid://6607204501",
        Switches = "rbxassetid://6607173363", ["Rust Headshot"] = "rbxassetid://138750331387064",
        ["Neverlose Sound"] = "rbxassetid://110168723447153", Bubble = "rbxassetid://6534947588",
        Laser = "rbxassetid://7837461331", Steve = "rbxassetid://4965083997",
        ["Call of Duty"] = "rbxassetid://5952120301", Bat = "rbxassetid://3333907347",
        ["TF2 Critical"] = "rbxassetid://296102734", Saber = "rbxassetid://8415678813",
        Bameware = "rbxassetid://3124331820"
    }

    HitSounds:create_dropdown({
        title = 'Select Hit Sound',
        flag = 'HitSoundSelection',
        options = hitSoundOptions,
        multi_dropdown = false,
        maximum_options = #hitSoundOptions,
        callback = function(value)
            hit_Sound.SoundId = hitSoundIds[value] or "rbxassetid://6607336718" -- Default to Medal
        end
    })

    HitSounds:create_slider({
        title = 'Volume',
        flag = 'HitSoundVolume',
        minimum_value = 1,
        maximum_value = 10,
        value = 5,
        round_number = true, -- Round to integer volume
        callback = function(value) hit_Sound.Volume = value end
    })

    -- Play hit sound on ParrySuccess event
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if hit_Sound_Enabled then hit_Sound:Play() end
    end)

    -- Ability ESP
    local billboardLabels = {}
    local function qolPlayerNameVisibility()
        local plr = Player
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")

        local function createBillboardGui(p)
            if billboardLabels[p] then return end
            local character = p.Character or p.CharacterAdded:Wait()
            if not character then return end
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Size = UDim2.new(0, 200, 0, 30)
            billboardGui.Adornee = humanoidRootPart
            billboardGui.AlwaysOnTop = true
            billboardGui.ExtentsOffset = Vector3.new(0, 2, 0)
            billboardGui.StudsOffset = Vector3.new(0, 3, 0)
            billboardGui.Parent = character
            billboardGui.Enabled = getgenv().AbilityESP -- Initial state based on global setting

            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.Text = p.DisplayName
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextStrokeTransparency = 0
            textLabel.TextWrapped = true
            textLabel.Parent = billboardGui
            billboardLabels[p] = billboardGui

            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

            local heartbeatConnection
            -- Continuously update the ESP text
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not (character and character.Parent and p.Character == character) then -- Check if character still exists and is the current one
                    heartbeatConnection:Disconnect()
                    if billboardGui then billboardGui:Destroy() end
                    billboardLabels[p] = nil
                    return
                end
                if getgenv().AbilityESP then
                    billboardGui.Enabled = true
                    local abilityName = p:GetAttribute("EquippedAbility")
                    if abilityName then textLabel.Text = p.DisplayName .. " [" .. abilityName .. "]"
                    else textLabel.Text = p.DisplayName end
                else
                    billboardGui.Enabled = false
                end
            end)
        end

        for _, p in Players:GetPlayers() do
            if p ~= plr then
                p.CharacterAdded:Connect(function() createBillboardGui(p) end)
                createBillboardGui(p)
            end
        end
        Players.PlayerAdded:Connect(function(newPlayer)
            newPlayer.CharacterAdded:Connect(function() createBillboardGui(newPlayer) end)
        end)
    end
    qolPlayerNameVisibility() -- Initialize on load

    local AbilityESP = player:create_module({
        title = 'Ability ESP',
        flag = 'AbilityESP',
        description = 'Displays Player Abilities above their heads.',
        section = 'left',
        callback = function(value: boolean)
            getgenv().AbilityESP = value
            for _, label_gui in pairs(billboardLabels) do
                label_gui.Enabled = value -- Toggle the BillboardGui's Enabled property
            end
        end
    })
end

do -- World Tab Modules (Sound Controller, World Filter, Custom Sky, Ability Exploits)
    local soundOptions = {
        ["Eeyuh"] = "rbxassetid://16190782181", ["Sweep"] = "rbxassetid://103508936658553",
        ["Bounce"] = "rbxassetid://134818882821660", ["Everybody Wants To Rule The World"] = "rbxassetid://87209527034670",
        ["Missing Money"] = "rbxassetid://134668194128037", ["Sour Grapes"] = "rbxassetid://117820392172291",
        ["Erwachen"] = "rbxassetid://124853612881772", ["Grasp the Light"] = "rbxassetid://89549155689397",
        ["Beyond the Shadows"] = "rbxassetid://120729792529978", ["Rise to the Horizon"] = "rbxassetid://72573266268313",
        ["Echoes of the Candy Kingdom"] = "rbxassetid://103040477333590", ["Speed"] = "rbxassetid://125550253895893",
        ["Lo-fi Chill A"] = "rbxassetid://9043887091", ["Lo-fi Ambient"] = "rbxassetid://129775776987523",
        ["Tears in the Rain"] = "rbxassetid://129710845038263"
    }
    local currentSound = Instance.new("Sound")
    currentSound.Volume = 3
    currentSound.Looped = false
    currentSound.Parent = game:GetService("SoundService")

    local function playSoundById(soundId)
        currentSound:Stop()
        currentSound.SoundId = soundId
        currentSound:Play()
    end
    local selectedSound = "Eeyuh" -- Default selected sound

    local soundModule = world:create_module({
        title = 'Sound Controller',
        flag = 'sound_controller',
        description = 'Control background music and sounds.',
        section = 'left',
        callback = function(value)
            getgenv().soundmodule = value
            if value then playSoundById(soundOptions[selectedSound])
            else currentSound:Stop() end
        end
    })
    soundModule:create_checkbox({
        title = "Loop Song",
        flag = "LoopSong",
        callback = function(value) currentSound.Looped = value end
    })
    soundModule:create_divider({})
    soundModule:create_dropdown({
        title = 'Select Sound',
        flag = 'sound_selection',
        options = { "Eeyuh", "Sweep", "Bounce", "Everybody Wants To Rule The World", "Missing Money", "Sour Grapes", "Erwachen", "Grasp the Light", "Beyond the Shadows", "Rise to the Horizon", "Echoes of the Candy Kingdom", "Speed", "Lo-fi Chill A", "Lo-fi Ambient", "Tears in the Rain" },
        multi_dropdown = false,
        maximum_options = 15,
        callback = function(value)
            selectedSound = value
            if getgenv().soundmodule then playSoundById(soundOptions[value]) end
        end
    })

    local WorldFilter = world:create_module({
        title = 'Filter',
        flag = 'Filter',
        description = 'Toggles custom world filter effects.',
        section = 'right',
        callback = function(value)
            getgenv().WorldFilterEnabled = value
            if not value then
                if Lighting:FindFirstChild("CustomAtmosphere") then Lighting.CustomAtmosphere:Destroy() end
                Lighting.FogEnd = 100000 -- Reset fog
                if Lighting.ColorCorrection then -- Check for ColorCorrection
                    Lighting.ColorCorrection.TintColor = Color3.new(1, 1, 1) -- Reset tint
                    Lighting.ColorCorrection.Saturation = 0 -- Reset saturation
                end
            else
                -- Ensure ColorCorrection is present when enabling filters
                if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
                    local colorCorrection = Instance.new("ColorCorrectionEffect")
                    colorCorrection.Parent = Lighting
                end
            end
        end
    })
    WorldFilter:create_checkbox({
        title = 'Enable Atmosphere',
        flag = 'World_Filter_Atmosphere',
        callback = function(value)
            getgenv().AtmosphereEnabled = value
            if value then
                if not Lighting:FindFirstChild("CustomAtmosphere") then
                    local atmosphere = Instance.new("Atmosphere")
                    atmosphere.Name = "CustomAtmosphere"
                    atmosphere.Parent = Lighting
                end
            else
                if Lighting:FindFirstChild("CustomAtmosphere") then Lighting.CustomAtmosphere:Destroy() end
            end
        end
    })
    WorldFilter:create_slider({
        title = 'Atmosphere Density',
        flag = 'World_Filter_Atmosphere_Slider',
        minimum_value = 0,
        maximum_value = 1,
        value = 0.5,
        round_number = false,
        callback = function(value)
            if getgenv().AtmosphereEnabled and Lighting:FindFirstChild("CustomAtmosphere") then Lighting.CustomAtmosphere.Density = value end
        end
    })
    WorldFilter:create_checkbox({
        title = 'Enable Fog',
        flag = 'World_Filter_Fog',
        callback = function(value)
            getgenv().FogEnabled = value
            if not value then Lighting.FogEnd = 100000 end
        end
    })
    WorldFilter:create_slider({
        title = 'Fog Distance',
        flag = 'World_Filter_Fog_Slider',
        minimum_value = 50,
        maximum_value = 10000,
        value = 1000,
        round_number = true,
        callback = function(value)
            if getgenv().FogEnabled then Lighting.FogEnd = value end
        end
    })
    WorldFilter:create_slider({
        title = 'Tint Color R',
        flag = 'World_Filter_Color_R',
        minimum_value = 0, maximum_value = 1, value = 1, round_number = false,
        callback = function(value)
            if getgenv().WorldFilterEnabled and Lighting.ColorCorrection then Lighting.ColorCorrection.TintColor = Color3.new(value, Lighting.ColorCorrection.TintColor.G, Lighting.ColorCorrection.TintColor.B) end
        end
    })
    WorldFilter:create_slider({
        title = 'Tint Color G',
        flag = 'World_Filter_Color_G',
        minimum_value = 0, maximum_value = 1, value = 1, round_number = false,
        callback = function(value)
            if getgenv().WorldFilterEnabled and Lighting.ColorCorrection then Lighting.ColorCorrection.TintColor = Color3.new(Lighting.ColorCorrection.TintColor.R, value, Lighting.ColorCorrection.TintColor.B) end
        end
    })
    WorldFilter:create_slider({
        title = 'Tint Color B',
        flag = 'World_Filter_Color_B',
        minimum_value = 0, maximum_value = 1, value = 1, round_number = false,
        callback = function(value)
            if getgenv().WorldFilterEnabled and Lighting.ColorCorrection then Lighting.ColorCorrection.TintColor = Color3.new(Lighting.ColorCorrection.TintColor.R, Lighting.ColorCorrection.TintColor.G, value) end
        end
    })
    WorldFilter:create_slider({
        title = 'Saturation',
        flag = 'World_Filter_Saturation',
        minimum_value = 0, maximum_value = 1, value = 0, round_number = false,
        callback = function(value)
            if getgenv().WorldFilterEnabled and Lighting.ColorCorrection then Lighting.ColorCorrection.Saturation = value end
        end
    })

    local CustomSky = world:create_module({
        title = 'Custom Sky',
        flag = 'Custom_Sky',
        description = 'Toggles a custom skybox.',
        section = 'left',
        callback = function(value)
            local Sky = Lighting:FindFirstChildOfClass("Sky")
            if value then
                if not Sky then Sky = Instance.new("Sky", Lighting) end
            else
                -- Reset to default skybox if toggle off
                if Sky then
                    local defaultSkyboxIds = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"}
                    local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
                    for index, face in ipairs(skyFaces) do Sky[face] = "rbxassetid://" .. defaultSkyboxIds[index] end
                    Lighting.GlobalShadows = true
                end
            end
        end
    })
    CustomSky:create_dropdown({
        title = 'Select Sky',
        flag = 'custom_sky_selector',
        options = { "Default", "Vaporwave", "Redshift", "Desert", "DaBaby", "Minecraft", "SpongeBob", "Skibidi", "Blaze", "Pussy Cat", "Among Us", "Space Wave", "Space Wave2", "Turquoise Wave", "Dark Night", "Bright Pink", "White Galaxy", "Blue Galaxy" },
        multi_dropdown = false,
        maximum_options = 18,
        callback = function(selectedOption)
            local skyboxData = nil
            if selectedOption == "Default" then skyboxData = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"}
            elseif selectedOption == "Vaporwave" then skyboxData = {"1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643"}
            elseif selectedOption == "Redshift" then skyboxData = {"401664839", "401664862", "401664960", "401664881", "401664901", "401664936"}
            elseif selectedOption == "Desert" then skyboxData = {"1013852", "1013853", "1013850", "1013851", "1013849", "1013854"}
            elseif selectedOption == "DaBaby" then skyboxData = {"7245418472", "7245418472", "7245418472", "7245418472", "7245418472", "7245418472"}
            elseif selectedOption == "Minecraft" then skyboxData = {"1876545003", "1876544331", "1876542941", "1876543392", "1876543764", "1876544642"}
            elseif selectedOption == "SpongeBob" then skyboxData = {"7633178166", "7633178166", "7633178166", "7633178166", "7633178166", "7633178166"}
            elseif selectedOption == "Skibidi" then skyboxData = {"14952256113", "14952256113", "14952256113", "14952256113", "14952256113", "14952256113"}
            elseif selectedOption == "Blaze" then skyboxData = {"150939022", "150939038", "150939047", "150939056", "150939063", "150939082"}
            elseif selectedOption == "Pussy Cat" then skyboxData = {"11154422902", "11154422902", "11154422902", "11154422902", "11154422902", "11154422902"}
            elseif selectedOption == "Among Us" then skyboxData = {"5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190"}
            elseif selectedOption == "Space Wave" then skyboxData = {"16262356578", "16262358026", "16262360469", "16262362003", "16262363873", "16262366016"}
            elseif selectedOption == "Space Wave2" then skyboxData = {"1233158420", "1233158838", "1233157105", "1233157640", "1233157995", "1233159158"}
            elseif selectedOption == "Turquoise Wave" then skyboxData = {"47974894", "47974690", "47974821", "47974776", "47974859", "47974909"}
            elseif selectedOption == "Dark Night" then skyboxData = {"6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635"}
            elseif selectedOption == "Bright Pink" then skyboxData = {"271042516", "271077243", "271042556", "271042310", "271042467", "271077958"}
            elseif selectedOption == "White Galaxy" then skyboxData = {"5540798456", "5540799894", "5540801779", "5540801192", "5540799108", "5540800635"}
            elseif selectedOption == "Blue Galaxy" then skyboxData = {"14961495673", "14961494492", "14961492844", "14961491298", "14961490439", "14961489508"} end
            if not skyboxData then warn("Sky option not found: " .. tostring(selectedOption)) return end
            local Sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
            local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
            for index, face in ipairs(skyFaces) do Sky[face] = "rbxassetid://" .. skyboxData[index] end
            Lighting.GlobalShadows = false -- Often improves custom sky look
        end
    })

    local AbilityExploit = world:create_module({
        title = 'Ability Exploit',
        flag = 'AbilityExploit',
        description = 'Ability Exploits (Blatant).',
        section = 'right',
        callback = function(value) getgenv().AbilityExploit = value end
    })
    AbilityExploit:create_checkbox({
        title = 'Thunder Dash No Cooldown',
        flag = 'ThunderDashNoCooldown',
        callback = function(value)
            getgenv().ThunderDashNoCooldown = value
            if getgenv().AbilityExploit and getgenv().ThunderDashNoCooldown then
                local thunderModule = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Abilities"):WaitForChild("Thunder Dash")
                local mod = require(thunderModule)
                mod.cooldown = 0
                mod.cooldownReductionPerUpgrade = 0
            end
        end
    })
    AbilityExploit:create_checkbox({
        title = 'Continuity Zero Exploit',
        flag = 'ContinuityZeroExploit',
        callback = function(value)
            getgenv().ContinuityZeroExploit = value
            if getgenv().AbilityExploit and getgenv().ContinuityZeroExploit then
                local ContinuityZeroRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseContinuityPortal")
                local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if self == ContinuityZeroRemote and method == "FireServer" then
                        -- Teleport to extreme coordinates, often used to confuse server
                        return oldNamecall(self, CFrame.new(9e17, 9e16, 9e15, 9e14, 9e13, 9e12, 9e11, 9e10, 9e9, 9e8, 9e7, 9e6), Player.Name )
                    end
                    return oldNamecall(self, ...)
                end)
            end
        end
    })
end

do -- Farm Tab Modules (Auto Duels, Auto Ranked, Auto LTM)
    local autoDuelsRequeueEnabled = false
    local AutoDuelsRequeue = farm:create_module({
        title = 'Auto Duels Requeue',
        flag = 'AutoDuelsRequeue',
        description = 'Automatically requeues duels.',
        section = 'left',
        callback = function(value)
            autoDuelsRequeueEnabled = value
            if autoDuelsRequeueEnabled then
                task.spawn(function()
                    while autoDuelsRequeueEnabled do
                        -- Fire remote to requeue duels
                        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index") and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.1.0") then
                            ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net:WaitForChild("RE/PlayerWantsRematch"):FireServer()
                        end
                        task.wait(5)
                    end
                end)
            end
        end
    })

    local validRankedPlaceIds = { 13772394625, 14915220621, } -- Example PlaceIds for ranked
    local selectedQueue = "FFA"
    local autoRequeueEnabled = false
    local AutoRankedRequeue = farm:create_module({
        title = 'Auto Ranked Requeue',
        flag = 'AutoRankedRequeue',
        description = 'Automatically requeues Ranked matches.',
        section = 'right',
        callback = function(value)
            autoRequeueEnabled = value
            if autoRequeueEnabled then
                if not table.find(validRankedPlaceIds, game.PlaceId) then
                    autoRequeueEnabled = false -- Disable if not in a ranked place
                    Library.SendNotification({ Title = "Auto Ranked Requeue", text = "Not in a valid Ranked game to requeue.", duration = 4 })
                    return
                end
                task.spawn(function()
                    while autoRequeueEnabled do
                        -- Fire remote to join ranked queue
                        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("JoinQueue"):FireServer("Ranked", selectedQueue, "Normal")
                        task.wait(5)
                    end
                end)
            end
        end
    })
    AutoRankedRequeue:create_dropdown({
        title = 'Select Queue Type',
        flag = 'QueueType',
        options = { "FFA", "Duo" },
        multi_dropdown = false,
        maximum_options = 2,
        callback = function(selectedOption) selectedQueue = selectedOption end
    })

    local autoLTMRequeueEnabled = false
    local validLTMPlaceId = 13772394625 -- Example PlaceId for LTM
    local AutoLTMRequeue = farm:create_module({
        title = 'Auto LTM Requeue',
        flag = 'AutoLTMRequeue',
        description = 'Automatically requeues LTM (Limited Time Mode) matches.',
        section = 'left',
        callback = function(value)
            autoLTMRequeueEnabled = value
            if autoLTMRequeueEnabled then
                if game.PlaceId ~= validLTMPlaceId then
                    autoLTMRequeueEnabled = false
                    Library.SendNotification({ Title = "Auto LTM Requeue", text = "Not in a valid LTM game to requeue.", duration = 4 })
                    return
                end
                task.spawn(function()
                    while autoLTMRequeueEnabled do
                        -- Fire remote for LTM tournament queue
                        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index") and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.1.0") then
                            ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net:WaitForChild("RF/JoinTournamentEventQueue"):InvokeServer({})
                        end
                        task.wait(5)
                    end
                end)
            end
        end
    })
end

do -- Misc Tab Modules (Skin Changer, Auto Play)
    local SkinChanger = misc:create_module({
        title = 'Skin Changer',
        flag = 'SkinChanger',
        description = 'Changes your sword skin client-side.',
        section = 'left',
        callback = function(value: boolean) getgenv().skinChanger = value if value then getgenv().updateSword() end end
    })
    SkinChanger:change_state(false)
    SkinChanger:create_paragraph({
        title = "⚠️EVERYONE CAN SEE ANIMATIONS",
        text = "IF YOU USE SKIN CHANGER BACKSWORD YOU MUST EQUIP AN ACTUAL BACKSWORD"
    })
    local skinchangertextbox = SkinChanger:create_textbox({
        title = "￬ Skin Name (Case Sensitive) ￬",
        placeholder = "Enter Sword Skin Name... ",
        flag = "SkinChangerTextbox",
        callback = function(text)
            getgenv().swordModel = text
            getgenv().swordAnimations = text
            getgenv().swordFX = text
            if getgenv().skinChanger then getgenv().updateSword() end
        end
    })

    local swordsController
    local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared",9e9):WaitForChild("ReplicatedInstances",9e9):WaitForChild("Swords",9e9)
    local swordInstances = require(swordInstancesInstance)

    -- Hook into game's internal sword equipping function
    while task.wait() and (not swordsController) do
        for i,v in getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent) do
            if v.Function and islclosure(v.Function) then
                local upvalues = getupvalues(v.Function)
                if #upvalues == 1 and type(upvalues[1]) == "table" then
                    swordsController = upvalues[1]
                    break
                end
            end
        end
    end

    function getSlashName(swordName)
        local slashName = swordInstances:GetSword(swordName)
        return (slashName and slashName.SlashName) or "SlashEffect" -- Default slash name
    end

    function setSword()
        if not getgenv().skinChanger then return end
        if swordsController then
            setupvalue(rawget(swordInstances,"EquipSwordTo"),2,false) -- Bypass security check
            swordInstances:EquipSwordTo(Player.Character, getgenv().swordModel) -- Equip the custom sword model
            swordsController:SetSword(getgenv().swordAnimations) -- Set sword animations
        end
    end

    local playParryFunc
    local parrySuccessAllConnection
    while task.wait() and not parrySuccessAllConnection do
        for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent) do
            if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                parrySuccessAllConnection = v
                playParryFunc = v.Function -- Store original function
                v:Disable() -- Disable original connection to redirect
            end
        end
    end

    local parrySuccessClientConnection
    while task.wait() and not parrySuccessClientConnection do
        for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event) do
            if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                parrySuccessClientConnection = v
                v:Disable()
            end
        end
    end

    getgenv().slashName = getSlashName(getgenv().swordFX)
    local lastOtherParryTimestamp = 0
    local clashConnections = {} -- Used for other clash-related connections

    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
        setthreadidentity(2) -- Change thread identity for security bypass
        local args = {...}
        if tostring(args[4]) ~= Player.Name then -- If parry is not by self
            lastOtherParryTimestamp = tick()
        elseif getgenv().skinChanger then -- If skin changer is active
            args[1] = getgenv().slashName -- Override slash effect
            args[3] = getgenv().swordFX -- Override sword FX
        end
        return playParryFunc(unpack(args)) -- Call original function with modified args
    end)
    table.insert(clashConnections, getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)[1])

    getgenv().updateSword = function()
        getgenv().slashName = getSlashName(getgenv().swordFX)
        setSword()
    end

    task.spawn(function()
        while task.wait(1) do
            if getgenv().skinChanger then
                local char = Player.Character or Player.CharacterAdded:Wait()
                if Player:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then setSword() end
                if char and (not char:FindFirstChild(getgenv().swordModel)) then setSword() end
                -- Remove any other sword models that aren't the custom one
                for _,v in (char and char:GetChildren()) or {} do
                    if v:IsA("Model") and v.Name ~= getgenv().swordModel then v:Destroy() end
                    task.wait()
                end
            end
        end
    end)


    -- Auto Play Module (Pathfinding and Movement)
    local AutoPlayModule = {}
    AutoPlayModule.CONFIG = {
        DEFAULT_DISTANCE = 30, MULTIPLIER_THRESHOLD = 70, TRAVERSING = 25, DIRECTION = 1,
        JUMP_PERCENTAGE = 50, DOUBLE_JUMP_PERCENTAGE = 50, JUMPING_ENABLED = false,
        MOVEMENT_DURATION = 0.8, OFFSET_FACTOR = 0.7, GENERATION_THRESHOLD = 0.25
    }
    AutoPlayModule.ball = nil
    AutoPlayModule.lobbyChoice = nil
    AutoPlayModule.animationCache = nil
    AutoPlayModule.doubleJumped = false
    AutoPlayModule.ELAPSED = 0
    AutoPlayModule.CONTROL_POINT = nil
    AutoPlayModule.LAST_GENERATION = 0
    AutoPlayModule.signals = {} -- Manages connections for Auto Play
    do
        local getServiceFunction = game.GetService
        local function getClonerefPermission()
            local permission = pcall(cloneref, getServiceFunction(game, "ReplicatedFirst")) -- Use pcall for safety
            return permission
        end
        AutoPlayModule.clonerefPermission = getClonerefPermission()
        if not AutoPlayModule.clonerefPermission then warn("cloneref is not available on your executor! AutoPlay may have detection risks.") end

        function AutoPlayModule.findCachedService(self, name)
            for index, value in self do if value.Name == name then return value end end
            return nil
        end

        function AutoPlayModule.getService(self, name)
            local cachedService = AutoPlayModule.findCachedService(self, name)
            if cachedService then return cachedService end
            local service = getServiceFunction(game, name)
            if AutoPlayModule.clonerefPermission then service = cloneref(service) end -- Use cloneref if available
            table.insert(self, service)
            return service
        end
        AutoPlayModule.customService = setmetatable({}, { __index = AutoPlayModule.getService }) -- Custom service getter
    end

    AutoPlayModule.playerHelper = {
        isAlive = function(player)
            local character = nil
            if player and player:IsA("Player") then character = player.Character end
            if not character then return false end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            if not rootPart or not humanoid then return false end
            return humanoid.Health > 0
        end,
        inLobby = function(character)
            if not character then return false end
            return character.Parent == AutoPlayModule.customService.Workspace.Dead -- Check if in lobby (dead parent)
        end,
        onGround = function(character)
            if not character then return false end
            return character.Humanoid.FloorMaterial ~= Enum.Material.Air
        end
    }

    AutoPlayModule.isLimited = function()
        local passedTime = tick() - AutoPlayModule.LAST_GENERATION
        return passedTime < AutoPlayModule.CONFIG.GENERATION_THRESHOLD
    end

    AutoPlayModule.percentageCheck = function(limit)
        if AutoPlayModule.isLimited() then return false end
        local percentage = math.random(100)
        AutoPlayModule.LAST_GENERATION = tick()
        return limit >= percentage
    end

    AutoPlayModule.ballUtils = {
        getBall = function()
            for _, object in AutoPlayModule.customService.Workspace.Balls:GetChildren() do
                if object:GetAttribute("realBall") then AutoPlayModule.ball = object return end
            end
            AutoPlayModule.ball = nil
        end,
        getDirection = function()
            if not AutoPlayModule.ball then return end
            local char = AutoPlayModule.customService.Players.LocalPlayer.Character
            if not char or not char.HumanoidRootPart then return end
            local direction = (char.HumanoidRootPart.Position - AutoPlayModule.ball.Position).Unit
            return direction
        end,
        getVelocity = function()
            if not AutoPlayModule.ball then return end
            local zoomies = AutoPlayModule.ball:FindFirstChild("zoomies")
            if not zoomies then return end
            return zoomies.VectorVelocity
        end,
        getSpeed = function()
            local velocity = AutoPlayModule.ballUtils.getVelocity()
            if not velocity then return end
            return velocity.Magnitude
        end,
        isExisting = function() return AutoPlayModule.ball ~= nil end
    }

    -- Math functions for pathfinding (interpolation)
    AutoPlayModule.lerp = function(start, finish, alpha) return start + (finish - start) * alpha end
    AutoPlayModule.quadratic = function(start, middle, finish, alpha)
        local firstLerp = AutoPlayModule.lerp(start, middle, alpha)
        local secondLerp = AutoPlayModule.lerp(middle, finish, alpha)
        return AutoPlayModule.lerp(firstLerp, secondLerp, alpha)
    end

    AutoPlayModule.getCandidates = function(middle, theta, offsetLength)
        local firstCanditateX = math.cos(theta + math.pi / 2)
        local firstCanditateZ = math.sin(theta + math.pi / 2)
        local firstCandidate = middle + Vector3.new(firstCanditateX, 0, firstCanditateZ) * offsetLength
        local secondCanditateX = math.cos(theta - math.pi / 2)
        local secondCanditateZ = math.sin(theta - math.pi / 2)
        local secondCandidate = middle + Vector3.new(secondCanditateX, 0, secondCanditateZ) * offsetLength
        return firstCandidate, secondCandidate
    end

    AutoPlayModule.getControlPoint = function(start, finish)
        local middle = (start + finish) * 0.5
        local difference = start - finish
        if difference.Magnitude < 5 then return finish end -- If too close, just go straight
        local theta = math.atan2(difference.Z, difference.X)
        local offsetLength = difference.Magnitude * AutoPlayModule.CONFIG.OFFSET_FACTOR
        local firstCandidate, secondCandidate = AutoPlayModule.getCandidates(middle, theta, offsetLength)
        local dotValue = start - middle
        if (firstCandidate - middle):Dot(dotValue) < 0 then return firstCandidate
        else return secondCandidate end
    end

    AutoPlayModule.getCurve = function(start, finish, delta)
        AutoPlayModule.ELAPSED = AutoPlayModule.ELAPSED + delta
        local timeElapsed = math.clamp(AutoPlayModule.ELAPSED / AutoPlayModule.CONFIG.MOVEMENT_DURATION, 0, 1)
        if timeElapsed >= 1 then
            local distance = (start - finish).Magnitude
            if distance >= 10 then AutoPlayModule.ELAPSED = 0 end -- Reset if far from target
            AutoPlayModule.CONTROL_POINT = nil
            return finish
        end
        if not AutoPlayModule.CONTROL_POINT then AutoPlayModule.CONTROL_POINT = AutoPlayModule.getControlPoint(start, finish) end
        assert(AutoPlayModule.CONTROL_POINT, "CONTROL_POINT: Vector3 expected, got nil")
        return AutoPlayModule.quadratic(start, AutoPlayModule.CONTROL_POINT, finish, timeElapsed)
    end

    AutoPlayModule.map = {
        getFloor = function()
            local floor = AutoPlayModule.customService.Workspace:FindFirstChild("FLOOR")
            if not floor then
                for _, part in pairs(AutoPlayModule.customService.Workspace:GetDescendants()) do
                    if part:IsA("MeshPart") or part:IsA("BasePart") then
                        local size = part.Size
                        if size.X > 50 and size.Z > 50 and part.Position.Y < 5 then return part end
                    end
                end
            end
            return floor
        end
    }

    AutoPlayModule.getRandomPosition = function()
        local floor = AutoPlayModule.map.getFloor()
        if not floor or not AutoPlayModule.ballUtils.isExisting() then return end
        local ballDirection = AutoPlayModule.ballUtils.getDirection() * AutoPlayModule.CONFIG.DIRECTION
        local ballSpeed = AutoPlayModule.ballUtils.getSpeed()
        local speedThreshold = math.min(ballSpeed / 10, AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD)
        local speedMultiplier = AutoPlayModule.CONFIG.DEFAULT_DISTANCE + speedThreshold
        local negativeDirection = ballDirection * speedMultiplier
        local currentTime = os.time() / 1.2
        local sine = math.sin(currentTime) * AutoPlayModule.CONFIG.TRAVERSING
        local cosine = math.cos(currentTime) * AutoPlayModule.CONFIG.TRAVERSING
        local traversing = Vector3.new(sine, 0, cosine)
        local finalPosition = floor.Position + negativeDirection + traversing
        return finalPosition
    end

    AutoPlayModule.lobby = {
        isChooserAvailable = function() return AutoPlayModule.customService.Workspace.Spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options.Visible end,
        updateChoice = function(choice) AutoPlayModule.lobbyChoice = choice end,
        getMapChoice = function()
            local choice = AutoPlayModule.lobbyChoice or math.random(1, 3)
            local collider = AutoPlayModule.customService.Workspace.Spawn.NewPlayerCounter.Colliders:FindFirstChild(tostring(choice))
            return collider
        end,
        getPadPosition = function()
            if not AutoPlayModule.lobby.isChooserAvailable() then AutoPlayModule.lobbyChoice = nil return end
            local choice = AutoPlayModule.lobby.getMapChoice()
            if not choice then return end
            return choice.Position, choice.Name
        end
    }

    AutoPlayModule.movement = {
        removeCache = function() if AutoPlayModule.animationCache then AutoPlayModule.animationCache = nil end end,
        createJumpVelocity = function(player)
            local maxForce = math.huge
            local velocity = Instance.new("BodyVelocity")
            velocity.MaxForce = Vector3.new(maxForce, maxForce, maxForce)
            velocity.Velocity = Vector3.new(0, 80, 0)
            velocity.Parent = player.Character.HumanoidRootPart
            AutoPlayModule.customService.Debris:AddItem(velocity, 0.001)
            AutoPlayModule.customService.ReplicatedStorage.Remotes.DoubleJump:FireServer()
        end,
        playJumpAnimation = function(player)
            if not AutoPlayModule.animationCache then
                local doubleJumpAnimation = AutoPlayModule.customService.ReplicatedStorage.Assets.Tutorial.Animations.DoubleJump
                AutoPlayModule.animationCache = player.Character.Humanoid.Animator:LoadAnimation(doubleJumpAnimation)
            end
            if AutoPlayModule.animationCache then AutoPlayModule.animationCache:Play() end
        end,
        doubleJump = function(player)
            if AutoPlayModule.doubleJumped then return end
            if not getgenv().AutoPlayJump then return end -- Only double jump if enabled
            if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE) then return end
            AutoPlayModule.doubleJumped = true
            AutoPlayModule.movement.createJumpVelocity(player)
            AutoPlayModule.movement.playJumpAnimation(player)
        end,
        jump = function(player)
            if not getgenv().AutoPlayJump then return end -- Only jump if enabled
            if not AutoPlayModule.CONFIG.JUMPING_ENABLED then return end
            if not AutoPlayModule.playerHelper.onGround(player.Character) then AutoPlayModule.movement.doubleJump(player) return end
            if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.JUMP_PERCENTAGE) then return end
            AutoPlayModule.doubleJumped = false
            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end,
        move = function(player, playerPosition) player.Character.Humanoid:MoveTo(playerPosition) end,
        stop = function(player)
            local playerPosition = player.Character.HumanoidRootPart.Position
            player.Character.Humanoid:MoveTo(playerPosition)
        end
    }

    AutoPlayModule.signal = {
        connect = function(name, connection, callback)
            if not name then name = AutoPlayModule.customService.HttpService:GenerateGUID() end
            AutoPlayModule.signals[name] = connection:Connect(callback)
            return AutoPlayModule.signals[name]
        end,
        disconnect = function(name)
            if not name or not AutoPlayModule.signals[name] then return end
            AutoPlayModule.signals[name]:Disconnect()
            AutoPlayModule.signals[name] = nil
        end,
        stop = function()
            for name, connection in pairs(AutoPlayModule.signals) do
                if typeof(connection) ~= "RBXScriptConnection" then continue end
                connection:Disconnect()
                AutoPlayModule.signals[name] = nil
            end
        end
    }

    AutoPlayModule.findPath = function(inLobby, delta)
        local rootPosition = AutoPlayModule.customService.Players.LocalPlayer.Character.HumanoidRootPart.Position
        if inLobby then
            local padPosition, padNumber = AutoPlayModule.lobby.getPadPosition()
            local choice = tonumber(padNumber)
            if choice and getgenv().AutoVote then -- Only auto-vote if enabled
                AutoPlayModule.lobby.updateChoice(choice)
                if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index") and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.1.0") then
                    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net:WaitForChild("RE/UpdateVotes"):FireServer("FFA")
                end
            end
            if not padPosition then return nil end
            return AutoPlayModule.getCurve(rootPosition, padPosition, delta)
        end
        local randomPosition = AutoPlayModule.getRandomPosition()
        if not randomPosition then return nil end
        return AutoPlayModule.getCurve(rootPosition, randomPosition, delta)
    end

    AutoPlayModule.followPath = function(delta)
        if not AutoPlayModule.playerHelper.isAlive(AutoPlayModule.customService.Players.LocalPlayer) then AutoPlayModule.movement.removeCache() return end
        local inLobby = AutoPlayModule.customService.Players.LocalPlayer.Character.Parent == AutoPlayModule.customService.Workspace.Dead
        local path = AutoPlayModule.findPath(inLobby, delta)
        if not path then AutoPlayModule.movement.stop(AutoPlayModule.customService.Players.LocalPlayer) return end
        AutoPlayModule.movement.move(AutoPlayModule.customService.Players.LocalPlayer, path)
        AutoPlayModule.movement.jump(AutoPlayModule.customService.Players.LocalPlayer)
    end

    AutoPlayModule.finishThread = function()
        AutoPlayModule.signal.disconnect("auto-play")
        AutoPlayModule.signal.disconnect("synchronize")
        if not AutoPlayModule.playerHelper.isAlive(AutoPlayModule.customService.Players.LocalPlayer) then return end
        AutoPlayModule.movement.stop(AutoPlayModule.customService.Players.LocalPlayer)
    end

    AutoPlayModule.start = function()
        AutoPlayModule.signal.connect("auto-play", RunService.RenderStepped, AutoPlayModule.followPath)
    end

    local AutoPlayModuleUI = misc:create_module({
        title = 'Auto Play',
        flag = 'AutoPlay',
        description = 'Automatically moves and jumps for you.',
        section = 'right',
        callback = function(value)
            getgenv().AutoPlay = value
            if value then AutoPlayModule.start()
            else AutoPlayModule.finishThread() end
        end
    })
    AutoPlayModuleUI:create_checkbox({
        title = "Jump",
        flag = "AutoPlayJump",
        callback = function(value) AutoPlayModule.CONFIG.JUMPING_ENABLED = value getgenv().AutoPlayJump = value end
    })
    AutoPlayModuleUI:create_slider({
        title = "Jump Percentage",
        flag = "AutoPlayJumpPercentage",
        minimum_value = 0,
        maximum_value = 100,
        value = 50,
        round_number = true,
        callback = function(value) AutoPlayModule.CONFIG.JUMP_PERCENTAGE = value end
    })
    AutoPlayModuleUI:create_slider({
        title = "Double Jump Percentage",
        flag = "AutoPlayDoubleJumpPercentage",
        minimum_value = 0,
        maximum_value = 100,
        value = 50,
        round_number = true,
        callback = function(value) AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE = value end
    })
    AutoPlayModuleUI:create_checkbox({
        title = "Auto Vote (Lobby)",
        flag = "AutoVote",
        callback = function(value) getgenv().AutoVote = value end
    })
end

-- Load the UI and activate first tab
main:load()

-- Trigger bot logic (from cele2stia.lua.txt, integrated and enhanced)
local lastBallVelocity = Vector3.new(0, 0, 0)
local currentBall = nil
local lastBallDistance = math.huge
local lastBallDot = 0
local lastTarget = ""

local function calculateTriggerBotParryTime(ballVelocity, ballPosition, playerPosition, ping)
    local distance = (playerPosition - ballPosition).Magnitude
    local speed = ballVelocity.Magnitude
    if speed < 10 then return 0 end -- Ball too slow, don't parry
    local timeToReach = distance / speed
    local adjustedTime = timeToReach - (ping / 1000) -- Adjust for ping
    return adjustedTime
end

-- Trigger bot main loop
Connections_Manager['TriggerBot'] = RunService.RenderStepped:Connect(function()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then
        currentBall = nil
        return
    end

    local PlayerCharacter = Player.Character
    if not PlayerCharacter or not PlayerCharacter:FindFirstChild("HumanoidRootPart") then return end

    local HumanoidRootPart = PlayerCharacter.HumanoidRootPart
    local BallPosition = Ball.Position

    local Zoomies = Ball:FindFirstChild('zoomies')
    if not Zoomies then return end
    local BallVelocity = Zoomies.VectorVelocity

    local ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

    -- Check if it's a new ball or target changed
    if Ball ~= currentBall or Ball:GetAttribute('target') ~= lastTarget then
        currentBall = Ball
        lastTarget = Ball:GetAttribute('target')
        lastBallVelocity = BallVelocity
        lastBallDistance = (HumanoidRootPart.Position - BallPosition).Magnitude
        lastBallDot = (HumanoidRootPart.Position - BallPosition).Unit:Dot(BallVelocity.Unit)
    end

    -- Update ball properties if it's the same ball
    lastBallVelocity = BallVelocity
    lastBallDistance = (HumanoidRootPart.Position - BallPosition).Magnitude
    lastBallDot = (HumanoidRootPart.Position - BallPosition).Unit:Dot(BallVelocity.Unit)

    local targetPlayer = Ball:GetAttribute('target')
    if targetPlayer == tostring(Player) then -- If the ball is targeting the local player
        local timeToParry = calculateTriggerBotParryTime(lastBallVelocity, BallPosition, HumanoidRootPart.Position, ping)
        
        -- Trigger bot logic: parry if ball is close enough and moving towards player
        -- Adjust thresholds based on experience and desired "blatancy"
        local minSpeed = 50 -- Minimum speed for trigger bot to react
        local maxDistance = 30 -- Maximum distance for trigger bot to react
        local minDot = -0.5 -- Minimum dot product for ball to be considered incoming

        if lastBallDot > minDot and lastBallVelocity.Magnitude > minSpeed and lastBallDistance <= maxDistance then
            -- Additional check for time to parry (e.g., parry slightly before it hits)
            if timeToParry <= 0.1 and timeToParry > -0.1 then -- Parries within a small time window around expected hit time
                Auto_Parry.Parry(Selected_Parry_Type)
            end
        end
    end
end)
