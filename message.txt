local Neverzen = loadstring(game:HttpGet("https://raw.githubusercontent.com/CodeE4X-dev/Library/main/neverzen.lua"))()
local Notification = Neverzen:CreateNotifier()

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local CAS = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local AliveFolder = Workspace:FindFirstChild("Alive")
local RuntimeFolder = Workspace:FindFirstChild("Runtime")
local AerodynamicActive = false
local AerodynamicTimer = tick()
local LastInputType = UserInputService:GetLastInputType()
local MousePosition = nil
local ParryAnimation = nil
local ParryKeyBind = nil
local RemoteEvents = {}
local ParryCount = 0
local DisableParryTimer = 0
local AbilityTimer = 0
local ConnectionsTable = {}
local AnimationData = {storage = {}, current = nil, track = nil}
local HasParried = false
local NearestPlayer = nil
local SpectateMode = false
local ManualSpamRate = 10
local PingBasedMode = true
local TargetMethod = ""
local IsSpamming = false
local SpamRate = 7
local TornadoTimer = tick()
local LerpRadians, VelocityHistory, LastWarpTime, LastCurveTime = 0, {}, tick(), tick()

local InfinityDetection, TimeHoleDetection, SingularityDetection, SlashesDetection, AutoAbilityMode, CooldownProtectionMode, PhantomDetection = false, false, false, false, false, false, false
local InfinityBallActive = false
local SlashesPending = false
local SlashesCounter = 0
local SlashesRunning = false

local SkinChangerActive = false
local SelectedWeapon = ""
local SelectedAnimationType = ""
local SelectedEffects = ""

local StrafeMode, AutoRewards, CameraFOVMode = false, false, false
local StrafeVelocity, CameraFieldOfView = 36, 70
local DefaultWalkSpeed = 16
local DefaultFieldOfView = 70
local DefaultGravityForce = 196.2
local DefaultMouseSensitivity = 1

local AIBotActive = false
local AIBotCoroutine = nil
local AIBotTarget = nil
local AIBotStrategy = "AdvancedPro"
local AutoFarmActive = false
local AutoFarmPattern = "Random Orbit"
local AutoFarmOrbitSpeed = 5
local AutoFarmElevation = 10
local AutoFarmDistance = 20
local AutoFarmCoroutine = nil
local AutoFarmComplexityLevel = 1

local VisualizerActive = false
local BallVisualizer = Instance.new("Part")
BallVisualizer.Shape = Enum.PartType.Ball
BallVisualizer.Anchored = true
BallVisualizer.CanCollide = false
BallVisualizer.Material = Enum.Material.ForceField
BallVisualizer.Transparency = 0.5
BallVisualizer.Parent = Workspace
BallVisualizer.Size = Vector3.zero

local BallTrailActive = false
local PlayerTrailActive = false
local VelocityDisplayActive = false
local ShadersActive = false
local FPSCapValue = 60

local SoundEffectActive = true
local SoundType = "DC_15X"

-- Gabungkan semua sound ID ke satu library
local SoundLibrary = {
    -- Original
    DC_15X = 'rbxassetid://936447863',
    Neverlose = 'rbxassetid://8679627751',
    Minecraft = 'rbxassetid://8766809464',
    MinecraftHit2 = 'rbxassetid://8458185621',
    TeamfortressBonk = 'rbxassetid://8255306220',
    TeamfortressBell = 'rbxassetid://2868331684',

    -- Hit Sounds
    Medal = "rbxassetid://6607336718",
    Fatality = "rbxassetid://6607113255",
    Skeet = "rbxassetid://6607204501",
    Switches = "rbxassetid://6607173363",
    ["Rust Headshot"] = "rbxassetid://138750331387064",
    ["Neverlose Sound"] = "rbxassetid://110168723447153",
    Bubble = "rbxassetid://6534947588",
    Laser = "rbxassetid://7837461331",
    Steve = "rbxassetid://4965083997",
    ["Call of Duty"] = "rbxassetid://5952120301",
    Bat = "rbxassetid://3333907347",
    ["TF2 Critical"] = "rbxassetid://296102734",
    Saber = "rbxassetid://8415678813",
    Bameware = "rbxassetid://3124331820"
}

-- Gabungkan semua nama ke dropdown
local allSoundOptions = {}
for name, _ in pairs(SoundLibrary) do
    table.insert(allSoundOptions, name)
end
table.sort(allSoundOptions) -- biar rapi

local Config = {
    SoundEffectActive = false, -- Default off
    SoundType = "DC_15X",
}

setfpscap(FPSCapValue)

task.spawn(function()
    for _, Value in getgc() do
        if type(Value) == 'function' and islclosure(Value) then
            local Protos = debug.getprotos(Value)
            local Upvalues = debug.getupvalues(Value)
            local Constants = debug.getconstants(Value)
            if #Protos == 4 and #Upvalues == 24 and #Constants >= 102 then
                local c62 = Constants[62]
                local c64 = Constants[64]
                local c65 = Constants[65]
                RemoteEvents[debug.getupvalue(Value, 16)] = c62
                ParryKeyBind = debug.getupvalue(Value, 17)
                RemoteEvents[debug.getupvalue(Value, 18)] = c64
                RemoteEvents[debug.getupvalue(Value, 19)] = c65
                break
            end
        end
    end
end)

local ZypherionModule = {}

ZypherionModule.LoadParryAnimation = function()
    local ParryAnimationAsset = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    local CurrentWeapon = LocalPlayer.Character:GetAttribute("CurrentlyEquippedSword")
    if not CurrentWeapon or not ParryAnimationAsset then return end
    
    local WeaponData = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(CurrentWeapon)
    if not WeaponData or not WeaponData['AnimationType'] then return end
    
    for _, object in pairs(ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == WeaponData['AnimationType'] then
            local animationType = (object:FindFirstChild("GrabParry") and "GrabParry") or "Grab"
            ParryAnimationAsset = object[animationType]
        end
    end
    
    ParryAnimation = LocalPlayer.Character.Humanoid.Animator:LoadAnimation(ParryAnimationAsset)
    ParryAnimation:Play()
end

ZypherionModule.GetAllBalls = function()
    local BallsArray = {}
    local ballFolder = Workspace:FindFirstChild(Workspace.Alive:FindFirstChild(tostring(LocalPlayer)) and "Balls" or "TrainingBalls")
    if not ballFolder then return {} end
    
    for _, ballObject in ipairs(ballFolder:GetChildren()) do
        if ballObject:GetAttribute("realBall") then
            ballObject.CanCollide = false
            BallsArray[#BallsArray + 1] = ballObject
        end
    end
    return BallsArray
end

ZypherionModule.GetActiveBall = function()
    local ballFolder = Workspace:FindFirstChild(Workspace.Alive:FindFirstChild(tostring(LocalPlayer)) and "Balls" or "TrainingBalls")
    if not ballFolder then return end
    
    for _, ballObject in ipairs(ballFolder:GetChildren()) do
        if ballObject:GetAttribute("realBall") then
            ballObject.CanCollide = false
            return ballObject
        end
    end
end

ZypherionModule.CalculateParryData = function()
    local Camera = Workspace.CurrentCamera
    if not Camera then return {0, CFrame.new(), {}, {0, 0}} end

    local ViewportDimensions = Camera.ViewportSize
    local MouseCoordinates = (LastInputType == Enum.UserInputType.MouseButton1 or LastInputType == Enum.UserInputType.MouseButton2 or LastInputType == Enum.UserInputType.Keyboard)
        and UserInputService:GetMouseLocation()
        or Vector2.new(ViewportDimensions.X / 2, ViewportDimensions.Y / 2)

    local UsedCoordinates = {MouseCoordinates.X, MouseCoordinates.Y}

    if TargetMethod == "ClosestToPlayer" then
        ZypherionModule.FindNearestPlayer()
        local targetedPlayer = NearestPlayer
        if targetedPlayer and targetedPlayer.PrimaryPart then
            UsedCoordinates = targetedPlayer.PrimaryPart.Position
        end
    end

    local AlivePlayers = Workspace.Alive:GetChildren()
    local EventsTable = table.create(#AlivePlayers)
    for _, player in ipairs(AlivePlayers) do
        if player.PrimaryPart then
            EventsTable[tostring(player)] = Camera:WorldToScreenPoint(player.PrimaryPart.Position)
        end
    end

    local cameraPosition = Camera.CFrame.Position
    local lookDirection = Camera.CFrame.LookVector
    local upDirection = Camera.CFrame.UpVector
    local rightDirection = Camera.CFrame.RightVector

    local directionMappings = {
        Backwards = cameraPosition - lookDirection * 1000,
        Random = Vector3.new(math.random(-3000, 3000), math.random(-3000, 3000), math.random(-3000, 3000)),
        Straight = cameraPosition + lookDirection * 1000,
        Up = cameraPosition + upDirection * 1000,
        Right = cameraPosition + rightDirection * 1000,
        Left = cameraPosition - rightDirection * 1000
    }

    local targetLookDirection = directionMappings[ZypherionModule.ParryDirection] or (cameraPosition + lookDirection * 1000)
    local DirectionalCFrame = CFrame.new(cameraPosition, targetLookDirection)

    return {0, DirectionalCFrame, EventsTable, UsedCoordinates}
end
--[[

]]
ZypherionModule.ExecuteParry = function()
    local ParryInformation = ZypherionModule.CalculateParryData()

    for RemoteEvent, Arguments in pairs(RemoteEvents) do
        local HashValue = nil
        if type(Arguments) == "string" and not string.find(Arguments, "PARRY_HASH_FAKE") then
            HashValue = Arguments
        end

        RemoteEvent:FireServer(HashValue, ParryKeyBind, ParryInformation[1], ParryInformation[2], ParryInformation[3], ParryInformation[4])
    end

    if ParryCount > 7 then return false end
    ParryCount += 1
    task.delay(0.5, function()
        if ParryCount > 0 then ParryCount -= 1 end
    end)
end


local LerpRadiansValue = 0
local LastWarpingTime = tick()
local PreviousVelocityData = {}
local CurvingTime = tick()

ZypherionModule.LinearInterpolation = function(startValue, endValue, timeVolume)
    return startValue + ((endValue - startValue) * timeVolume)
end

ZypherionModule.CurveDetect = function()
    local BallObject = ZypherionModule.GetActiveBall()
    if not BallObject then return false end
    
    local ZoomiesComponent = BallObject:FindFirstChild("zoomies")
    if not ZoomiesComponent then return false end

    local BallVelocity = ZoomiesComponent.VectorVelocity
    local BallDirection = BallVelocity.Unit
    local PlayerDirection = (LocalPlayer.Character.PrimaryPart.Position - BallObject.Position).Unit
    local DotProduct = PlayerDirection:Dot(BallDirection)
    local BallSpeed = BallVelocity.Magnitude
    local DistanceToPlayer = (LocalPlayer.Character.PrimaryPart.Position - BallObject.Position).Magnitude

    if not PingBasedMode then
        if BallSpeed < 100 then return false end
        if DotProduct < 0.8 then return true end
        if DistanceToPlayer > 100 then return false end
        return false
    end

    local NetworkPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local SpeedThreshold = math.min(BallSpeed / 100, 40)
    local AngleThreshold = 40 * math.max(DotProduct, 0)
    local DirectionDifference = (BallDirection - BallVelocity).Unit
    local DirectionSimilarity = PlayerDirection:Dot(DirectionDifference)
    local DotDifference = DotProduct - DirectionSimilarity
    local DotThreshold = 0.5 - (NetworkPing / 975)
    local ReachTime = (DistanceToPlayer / BallSpeed) - (NetworkPing / 1000)
    local SufficientSpeed = BallSpeed > 100
    local BallDistanceThreshold = ((math.max(NetworkPing/10,15) - math.min(DistanceToPlayer / 1000, 15)) + AngleThreshold + SpeedThreshold)*(1+NetworkPing/925)

    table.insert(PreviousVelocityData, BallVelocity)
    if #PreviousVelocityData > 4 then
        table.remove(PreviousVelocityData, 1)
    end

    if SufficientSpeed and (ReachTime > (NetworkPing / 10)) then
        BallDistanceThreshold = math.max(BallDistanceThreshold - 15, 15)
    end

    if DistanceToPlayer < BallDistanceThreshold then return false end

    if (tick() - CurvingTime) < (ReachTime / 1.5) then return true end

    if DotDifference < DotThreshold then return true end

    local RadiansValue = math.rad(math.asin(DotProduct))
    LerpRadiansValue = ZypherionModule.LinearInterpolation(LerpRadiansValue, RadiansValue, 0.8)
    if LerpRadiansValue < 0.018 then
        LastWarpingTime = tick()
    end

    if (tick() - LastWarpingTime) < (ReachTime / 1.5) then return true end

    if #PreviousVelocityData == 4 then
        local IntendedDirectionDiff = (BallDirection - PreviousVelocityData[1].Unit).Unit
        local IntendedDot = PlayerDirection:Dot(IntendedDirectionDiff)
        local IntendedDotDiff = DotProduct - IntendedDot
        local IntendedDirectionDiff2 = (BallDirection - PreviousVelocityData[2].Unit).Unit
        local IntendedDot2 = PlayerDirection:Dot(IntendedDirectionDiff2)
        local IntendedDotDiff2 = DotProduct - IntendedDot2

        if (IntendedDotDiff < DotThreshold) or (IntendedDotDiff2 < DotThreshold) then
            return true
        end
    end

    return DotProduct < DotThreshold
end

ZypherionModule.FindNearestPlayer = function()
    local MinimumDistance = math.huge
    NearestPlayer = nil
    for _, PlayerEntity in pairs(Workspace.Alive:GetChildren()) do
        if tostring(PlayerEntity) ~= tostring(LocalPlayer) and PlayerEntity.PrimaryPart then
            local DistanceValue = LocalPlayer:DistanceFromCharacter(PlayerEntity.PrimaryPart.Position)
            if DistanceValue < MinimumDistance then
                MinimumDistance = DistanceValue
                NearestPlayer = PlayerEntity
            end
        end
    end
    return NearestPlayer
end

local SlashesNetworking = ReplicatedStorage:WaitForChild("Packages")._Index:FindFirstChild("sleitnick_net@0.1.0")
local SlashesRemoteEvent = SlashesNetworking and SlashesNetworking:FindFirstChild("net"):FindFirstChild("RE/SlashesOfFuryActivate")

if SlashesRemoteEvent then
    SlashesRemoteEvent.OnClientEvent:Connect(function()
        if SlashesDetection then
            SlashesPending = true
        end
    end)
end

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    InfinityBallActive = b and true or false
end)

local function InitiateSlashesParry()
    if SlashesRunning then return end
    SlashesRunning = true
    SlashesCounter = 0
    task.wait(0.3)
    
    task.spawn(function()
        local lastParryTimestamp = tick()
        while SlashesCounter < 35 do
            local currentTimestamp = tick()
            local delayTime = 0.043
            
            if currentTimestamp - lastParryTimestamp >= delayTime then
                ZypherionModule.ExecuteParry()
                SlashesCounter += 1
                lastParryTimestamp = currentTimestamp
            end
            task.wait()
        end
        ParryCount = 0
        task.wait(0.15)
        SlashesRunning = false
    end)
end

local AbilityRemote = ReplicatedStorage.Remotes.AbilityButtonPress
local hotbarInterface = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Hotbar")
local ParryCooldown = hotbarInterface and hotbarInterface:FindFirstChild("Block") and hotbarInterface.Block:FindFirstChild("UIGradient")
local AbilityCooldown = hotbarInterface and hotbarInterface:FindFirstChild("Ability") and hotbarInterface.Ability:FindFirstChild("UIGradient")

local function CheckCooldownStatus1(uigradient)
    return uigradient and uigradient.Offset.Y < 0.4
end

local function CheckCooldownStatus2(uigradient)
    return uigradient and uigradient.Offset.Y == 0.5
end

local function ActivateCooldownProtection()
    if not CooldownProtectionMode or not AliveFolder:FindFirstChild(tostring(LocalPlayer)) then return false end
    if ParryCooldown and CheckCooldownStatus1(ParryCooldown) then
        AbilityRemote:Fire()
        return true
    end
    return false
end

local function TriggerAutoAbility()
    if not AutoAbilityMode or not AliveFolder:FindFirstChild(tostring(LocalPlayer)) then return false end
    if AbilityCooldown and CheckCooldownStatus2(AbilityCooldown) then
        local AbilitySystem = LocalPlayer.Character.Abilities
        if AbilitySystem["Raging Deflection"].Enabled or
           AbilitySystem["Rapture"].Enabled or
           AbilitySystem["Calming Deflection"].Enabled or
           AbilitySystem["Aerodynamic Slash"].Enabled or
           AbilitySystem["Fracture"].Enabled or
           AbilitySystem["Death Slash"].Enabled or
           AbilitySystem["Flash Counter"].Enabled then
            HasParried = true
            AbilityRemote:Fire()
            task.wait(2.432)
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            return true
        end
    end
    return false
end

local playerRef = LocalPlayer
local replicatedStorageRef = ReplicatedStorage
local swordsModule = require(replicatedStorageRef:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9))
local controllerRef, playEffectFunc, lastParryTime = nil, nil, 0

local function getSlashEffect(weaponName)
    local swordData = swordsModule:GetSword(weaponName)
    return (swordData and swordData.SlashName) or "SlashEffect"
end

getgenv().skinConfig = getgenv().skinConfig or {}
getgenv().skinConfig.slashEffect = getSlashEffect(getgenv().skinConfig.FX or "")

local function applySwordSkin()
    if not getgenv().skinConfig.enabled then return end
    setupvalue(rawget(swordsModule, "EquipSwordTo"), 2, false)
    swordsModule:EquipSwordTo(playerRef.Character, getgenv().skinConfig.ModelWeapon)
    if controllerRef and getgenv().skinConfig.Animation then
        controllerRef:SetSword(getgenv().skinConfig.Animation)
    end
end

getgenv().updateSwordSkin = function()
    getgenv().skinConfig.slashEffect = getSlashEffect(getgenv().skinConfig.FX)
    applySwordSkin()
end

while task.wait() and not controllerRef do
    for _, connection in getconnections(replicatedStorageRef.Remotes.FireSwordInfo.OnClientEvent) do
        if connection.Function and islclosure(connection.Function) then
            local upvalues = getupvalues(connection.Function)
            if #upvalues == 1 and type(upvalues[1]) == "table" then
                controllerRef = upvalues[1]
                break
            end
        end
    end
end

local parryConnectionA, parryConnectionB
while task.wait() and not parryConnectionA do
    for _, connection in getconnections(replicatedStorageRef.Remotes.ParrySuccessAll.OnClientEvent) do
        if connection.Function and getinfo(connection.Function).name == "parrySuccessAll" then
            parryConnectionA, playEffectFunc = connection, connection.Function
            connection:Disable()
            break
        end
    end
end

while task.wait() and not parryConnectionB do
    for _, connection in getconnections(replicatedStorageRef.Remotes.ParrySuccessClient.Event) do
        if connection.Function and getinfo(connection.Function).name == "parrySuccessAll" then
            parryConnectionB = connection
            connection:Disable()
            break
        end
    end
end

replicatedStorageRef.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    setthreadidentity(2)
    local arguments = {...}
    if tostring(arguments[4]) ~= playerRef.Name then
        lastParryTime = tick()
    elseif getgenv().skinConfig.enabled then
        arguments[1], arguments[3] = getgenv().skinConfig.slashEffect, getgenv().skinConfig.FX
    end
    return playEffectFunc(unpack(arguments))
end)

task.spawn(function()
    while task.wait(1) do
        if getgenv().skinConfig.enabled then
            local character = playerRef.Character or playerRef.CharacterAdded:Wait()
            if playerRef:GetAttribute("CurrentlyEquippedSword") ~= getgenv().skinConfig.ModelWeapon or not character:FindFirstChild(getgenv().skinConfig.ModelWeapon) then
                applySwordSkin()
            end
            for _, model in pairs(character:GetChildren()) do
                if model:IsA("Model") and model.Name ~= getgenv().skinConfig.ModelWeapon then
                    model:Destroy()
                end
                task.wait()
            end
        end
    end
end)

local AIStuckDetection = {
    lastPosition = Vector3.new(),
    checkTime = 0,
    stuckDuration = 0
}

local AICooldownTimers = {
    jump = 0,
    dash = 0,
    targetSwitch = 0,
    action = 0
}

local function getValidTargets()
    local validPlayers = {}
    local myPosition = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart).Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local primaryPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character.PrimaryPart
            if primaryPart and primaryPart.Position then
                if myPosition then
                    local direction = (primaryPart.Position - myPosition).Unit
                    local viewVector = (LocalPlayer.Character:GetPrimaryPartCFrame().LookVector).Unit
                    if direction:Dot(viewVector) > math.cos(math.rad(60)) then
                        table.insert(validPlayers, {
                            Player = player,
                            Character = player.Character,
                            PrimaryPart = primaryPart,
                            LastPosition = primaryPart.Position,
                            Velocity = primaryPart.AssemblyLinearVelocity
                        })
                    end
                end
            end
        end
    end
    return validPlayers
end

local function getSafeBallReference()
    local success, ballObject = pcall(function()
        return ZypherionModule.GetActiveBall()
    end)
    return success and ballObject or nil
end

local function predictFuturePosition(currentPosition, velocity, timeOffset)
    return currentPosition + (velocity * timeOffset)
end

local function detectStuckState(currentPosition)
    if (currentPosition - AIStuckDetection.lastPosition).Magnitude < 1.5 then
        AIStuckDetection.stuckDuration += 1
    else
        AIStuckDetection.stuckDuration = 0
    end
    AIStuckDetection.lastPosition = currentPosition
    return AIStuckDetection.stuckDuration > 8
end

local function moveCharacterToPosition(character, targetPosition, aggressiveMode)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not humanoid or not primaryPart then return end
    
    local direction = (targetPosition - primaryPart.Position).Unit
    local distance = (targetPosition - primaryPart.Position).Magnitude
    
    local raycastParameters = RaycastParams.new()
    raycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParameters.FilterDescendantsInstances = {character}
    
    local raycastResult = Workspace:Raycast(
        primaryPart.Position,
        direction * 8,
        raycastParameters
    )
    
    if raycastResult and raycastResult.Instance then
        if AICooldownTimers.jump <= 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
            AICooldownTimers.jump = 0.6 + math.random() * 0.3
        end
    end
    
    if detectStuckState(primaryPart.Position) then
        humanoid.Jump = true
        if AICooldownTimers.dash <= 0 then
            humanoid:MoveTo(primaryPart.Position + (Vector3.new(math.random(-1,1), 0, math.random(-1,1)) * 15))
            AICooldownTimers.dash = 2 + math.random()
        end
    end
    
    if aggressiveMode then
        humanoid:MoveTo(targetPosition + (direction * 2))
    else
        humanoid:MoveTo(targetPosition)
    end
end

local AIStrategies = {
    AdvancedPro = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        local ballObject = getSafeBallReference()
        local validTargets = getValidTargets()
        local targetData = nil
        
        if ballObject and (math.random() > 0.4 or #validTargets == 0) then
            local predictionTime = 0.5 + math.random() * 0.3
            targetData = {
                Position = predictFuturePosition(ballObject.Position, ballObject.Velocity, predictionTime),
                Type = "Ball"
            }
        elseif #validTargets > 0 then
            if AICooldownTimers.targetSwitch <= 0 or not AIBotTarget then
                AIBotTarget = validTargets[math.random(math.max(1, #validTargets - 2), #validTargets)]
                AICooldownTimers.targetSwitch = 2 + math.random() * 2
            end
            if AIBotTarget and AIBotTarget.PrimaryPart then
                local predictionTime = 0.4 + math.random() * 0.2
                targetData = {
                    Position = predictFuturePosition(AIBotTarget.PrimaryPart.Position, AIBotTarget.Velocity, predictionTime),
                    Type = "Player"
                }
            end
        end
        
        if targetData then
            local idealDistance = math.random(8, 15)
            local toTarget = (targetData.Position - primaryPart.Position)
            local moveToPosition = targetData.Position - (toTarget.Unit * idealDistance)
            
            local shouldJump = (primaryPart.Position - targetData.Position).Magnitude < 15
                and (targetData.Position.Y > primaryPart.Position.Y + 1.5)
                and humanoid.FloorMaterial ~= Enum.Material.Air
                and AICooldownTimers.jump <= 0
            
            if shouldJump then
                humanoid.Jump = true
                AICooldownTimers.jump = 0.8 + math.random() * 0.4
            end
            
            moveCharacterToPosition(character, moveToPosition, true)
        else
            local wanderPosition = primaryPart.Position + Vector3.new(math.random(-25,25), 0, math.random(-25,25))
            moveCharacterToPosition(character, wanderPosition, false)
        end
    end,
    
    BallChaser = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        for key, value in pairs(AICooldownTimers) do
            if value > 0 then AICooldownTimers[key] = value - 0.1 end
        end
        
        local ballObject = getSafeBallReference()
        if ballObject then
            local predictedPosition = predictFuturePosition(ballObject.Position, ballObject.Velocity, 0.5)
            local distance = (predictedPosition - primaryPart.Position).Magnitude
            local timeToReach = distance / humanoid.WalkSpeed
            local moveToPosition = predictFuturePosition(ballObject.Position, ballObject.Velocity, timeToReach * 0.7)
            
            if (ballObject.Position - primaryPart.Position).Unit:Dot(ballObject.Velocity.Unit) > 0.7 then
                moveToPosition = ballObject.Position
            end
            
            moveCharacterToPosition(character, moveToPosition, true)
            
            if distance < 12 and AICooldownTimers.jump <= 0 then
                humanoid.Jump = true
                AICooldownTimers.jump = 0.5 + math.random() * 0.3
            end
            
            if distance > 15 and AICooldownTimers.dash <= 0 and math.random() > 0.6 then
                humanoid:MoveTo(moveToPosition)
                AICooldownTimers.dash = 2 + math.random()
            end
        else
            AIStrategies.AdvancedPro(character)
        end
    end
}

local function executeAIBehavior()
    local lastUpdateTime = os.clock()
    while AIBotActive do
        local character = LocalPlayer.Character
        if character then
            local deltaTime = os.clock() - lastUpdateTime
            lastUpdateTime = os.clock()
            
            for key, value in pairs(AICooldownTimers) do
                AICooldownTimers[key] = math.max(0, value - deltaTime)
            end
            
            local success, errorMessage = pcall(function()
                if AIStrategies[AIBotStrategy] then
                    AIStrategies[AIBotStrategy](character)
                end
            end)
            
            if not success then
                warn("AI Error:", errorMessage)
                AIBotStrategy = "AdvancedPro"
            end
        end
        task.wait(0.1 + math.random() * 0.15)
    end
end

local function getBallReference()
    local ballsFolder = Workspace:FindFirstChild("Balls")
    return ballsFolder and ballsFolder:FindFirstChildWhichIsA("Part", true) or nil
end

local function getPlayerRootPart(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function executeAutoFarm()
    local player = LocalPlayer
    local ballObject = getBallReference()
    local rootPart = getPlayerRootPart(player)
    if not ballObject or not rootPart then return end
    
    local ballPosition = ballObject.Position
    local angleValue = tick() * math.pi * 2 / (AutoFarmOrbitSpeed / 5)
    local timeValue = tick()
    
    if AutoFarmPattern == "UnderBall" then
        rootPart.CFrame = CFrame.new(ballPosition - Vector3.new(0, AutoFarmElevation, 0))
    elseif AutoFarmPattern == "X Orbit" then
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            math.cos(angleValue) * AutoFarmDistance,
            0,
            math.sin(angleValue) * AutoFarmDistance
        ))
    elseif AutoFarmPattern == "Y Orbit" then
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            0,
            math.sin(angleValue) * AutoFarmDistance,
            math.cos(angleValue) * AutoFarmDistance
        ))
    elseif AutoFarmPattern == "Z Orbit" then
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            math.cos(angleValue) * AutoFarmDistance,
            math.sin(angleValue) * AutoFarmDistance,
            0
        ))
    elseif AutoFarmPattern == "Helix" then
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            math.cos(angleValue) * AutoFarmDistance,
            math.sin(timeValue * AutoFarmComplexityLevel) * AutoFarmElevation,
            math.sin(angleValue) * AutoFarmDistance
        ))
    elseif AutoFarmPattern == "Figure8" then
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            math.cos(angleValue) * AutoFarmDistance,
            0,
            math.sin(2 * angleValue) * (AutoFarmDistance / 2)
        ))
    elseif AutoFarmPattern == "Spiral" then
        local spiralRadius = AutoFarmDistance * (1 + math.sin(timeValue * 0.5))
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            math.cos(angleValue) * spiralRadius,
            timeValue % AutoFarmElevation,
            math.sin(angleValue) * spiralRadius
        ))
    elseif AutoFarmPattern == "Random Orbit" then
        rootPart.CFrame = CFrame.new(ballPosition + Vector3.new(
            math.noise(timeValue) * AutoFarmDistance,
            math.noise(timeValue + 10) * AutoFarmElevation,
            math.noise(timeValue + 20) * AutoFarmDistance
        ))
    end
end

local function initializeAutoFarm()
    if AutoFarmCoroutine then
        AutoFarmCoroutine:Disconnect()
        AutoFarmCoroutine = nil
    end
    AutoFarmCoroutine = RunService.Heartbeat:Connect(function()
        if AutoFarmActive then
            local success, errorMessage = pcall(executeAutoFarm)
            if not success then
                warn("AutoFarm Error:", errorMessage)
            end
        end
    end)
end

local function createBallTrail(ballObject)
    if not BallTrailActive or not ballObject then return end
    
    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 255))
    trail.Transparency = NumberSequence.new(0, 1)
    trail.Lifetime = 2
    trail.MinLength = 0
    trail.FaceCamera = true
    
    local attachment0 = Instance.new("Attachment")
    local attachment1 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(-1, 0, 0)
    attachment1.Position = Vector3.new(1, 0, 0)
    
    attachment0.Parent = ballObject
    attachment1.Parent = ballObject
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Parent = ballObject
end

local function createPlayerTrail(character)
    if not PlayerTrailActive or not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 0))
    trail.Transparency = NumberSequence.new(0, 1)
    trail.Lifetime = 1.5
    trail.MinLength = 0
    trail.FaceCamera = true
    
    local attachment0 = Instance.new("Attachment")
    local attachment1 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(-0.5, 0, 0)
    attachment1.Position = Vector3.new(0.5, 0, 0)
    
    attachment0.Parent = humanoidRootPart
    attachment1.Parent = humanoidRootPart
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Parent = humanoidRootPart
end

local function createVelocityDisplay(ballObject)
    if not VelocityDisplayActive or not ballObject then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = ballObject
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = true
    textLabel.Parent = billboardGui
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if ballObject.Parent and ballObject:FindFirstChild("zoomies") then
            local velocity = ballObject.zoomies.VectorVelocity.Magnitude
            textLabel.Text = string.format("Velocity: %.1f", velocity)
        else
            connection:Disconnect()
            billboardGui:Destroy()
        end
    end)
end

local function applyShaders()
    if not ShadersActive then return end
    
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.1
    colorCorrection.Contrast = 0.2
    colorCorrection.Saturation = 0.3
    colorCorrection.TintColor = Color3.fromRGB(255, 240, 220)
    colorCorrection.Parent = Lighting
    
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.5
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting
    
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.25
    sunRays.Spread = 0.2
    sunRays.Parent = Lighting
end

local function PlaySoundEffect()
    if not Config.SoundEffectActive then return end
    
    local soundId = SoundLibrary[Config.SoundType]
    if not soundId then return end

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 1
    sound.PlayOnRemove = true
    sound.Parent = workspace
    sound:Destroy()
end

task.defer(function()
    game:GetService("ReplicatedStorage").Remotes.ParrySuccess.OnClientEvent:Connect(PlaySoundEffect)
end)

function CreateManualSpamGUI()
    if ManualSpamGUI then
        ManualSpamGUI:Destroy()
        ManualSpamGUI = nil
        return
    end

    ManualSpamGUI = Instance.new("ScreenGui")
    ManualSpamGUI.Name = "ManualSpamGUI"
    ManualSpamGUI.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    ManualSpamGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ManualSpamGUI.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ManualSpamGUI
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.41414836, 0, 0.404336721, 0)
    MainFrame.Size = UDim2.new(0.227479532, 0, 0.191326529, 0)

    local UICorner = Instance.new("UICorner")
    UICorner.Parent = MainFrame

    local StatusIndicator = Instance.new("Frame")
    StatusIndicator.Name = "StatusIndicator"
    StatusIndicator.Parent = MainFrame
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    StatusIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
    StatusIndicator.BorderSizePixel = 0
    StatusIndicator.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0)
    StatusIndicator.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0)

    local UICorner_2 = Instance.new("UICorner")
    UICorner_2.CornerRadius = UDim.new(1, 0)
    UICorner_2.Parent = StatusIndicator

    local KeybindLabel = Instance.new("TextLabel")
    KeybindLabel.Name = "KeybindLabel"
    KeybindLabel.Parent = MainFrame
    KeybindLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    KeybindLabel.BorderSizePixel = 0
    KeybindLabel.Position = UDim2.new(0.547999978, 0, 0.826666653, 0)
    KeybindLabel.Size = UDim2.new(0.451999992, 0, 0.173333332, 0)
    KeybindLabel.Font = Enum.Font.GothamBold
    KeybindLabel.Text = "PC: E to spam"
    KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindLabel.TextScaled = true
    KeybindLabel.TextSize = 16
    KeybindLabel.TextWrapped = true

    local SpamButton = Instance.new("TextButton")
    SpamButton.Name = "SpamButton"
    SpamButton.Parent = MainFrame
    SpamButton.Active = false
    SpamButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SpamButton.BackgroundTransparency = 1
    SpamButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SpamButton.BorderSizePixel = 0
    SpamButton.Position = UDim2.new(0.164000005, 0, 0.326666653, 0)
    SpamButton.Selectable = false
    SpamButton.Size = UDim2.new(0.667999983, 0, 0.346666664, 0)
    SpamButton.Font = Enum.Font.GothamBold
    SpamButton.Text = "Spam"
    SpamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpamButton.TextScaled = true
    SpamButton.TextSize = 24
    SpamButton.TextWrapped = true

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    UIGradient.Parent = SpamButton

    local spamConnection
    local manualSpamActive = false

    local function toggleSpamMode()
        manualSpamActive = not manualSpamActive

        if spamConnection then
            spamConnection:Disconnect()
            spamConnection = nil
        end

        if manualSpamActive then
            spamConnection = RunService.PreSimulation:Connect(function()
                for _ = 1, ManualSpamRate do
                    if not manualSpamActive then
                        break
                    end
                    local success, errorMessage = pcall(function()
                        ZypherionModule.ExecuteParry()
                    end)
                    if not success then
                        warn("Error in Parry function:", errorMessage)
                    end
                    task.wait(0.001)
                end
            end)
        end
    end

    local function updateIndicatorColor()
        if manualSpamActive then
            StatusIndicator.BackgroundColor3 = Color3.new(1, 0, 0)
        else
            StatusIndicator.BackgroundColor3 = Color3.new(0, 1, 0)
        end
        toggleSpamMode()
    end

    SpamButton.MouseButton1Click:Connect(updateIndicatorColor)

    local keyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.E then
            updateIndicatorColor()
        end
    end)

    ManualSpamGUI.Destroying:Connect(function()
        if keyConnection then keyConnection:Disconnect() end
        if spamConnection then spamConnection:Disconnect() end
    end)

    local gui = MainFrame
    local dragging, dragInput, dragStart, startPos

    local function updatePosition(input)
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(gui, tweenInfo, {Position = newPosition})
        tween:Play()
    end

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            updatePosition(input)
        end
    end)
end

local ToggleScreenGui = Instance.new("ScreenGui")
local ToggleImageButton = Instance.new("ImageButton")
local ToggleUICorner = Instance.new("UICorner")

ToggleScreenGui.Parent = game.CoreGui
ToggleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ToggleImageButton.Parent = ToggleScreenGui
ToggleImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleImageButton.BorderSizePixel = 0
ToggleImageButton.Position = UDim2.new(0.120833337, 0, 0.0952890813, 0)
ToggleImageButton.Size = UDim2.new(0, 50, 0, 50)
ToggleImageButton.Image = "rbxassetid://103649857680781"
ToggleImageButton.Draggable = true

ToggleUICorner.Parent = ToggleImageButton

ToggleImageButton.MouseButton1Click:Connect(function()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
end)

local Window = Neverzen.new({
    Name = "NodeX",
    Keybind = Enum.KeyCode.LeftControl,
    Scale = UDim2.new(0, 650, 0, 500),
    Resizable = true,
    Theme = "Matrix",
    Shadow = true,
    Acrylic = true,
})


local MainTab = Window:AddTab({
    Name = "Main",
    Icon = "swords"
})

local AbilitiesTab = Window:AddTab({
    Name = "Abilities", 
    Icon = "shield"
})

local SkinChangerTab = Window:AddTab({
    Name = "Skin Changer",
    Icon = "palette"
})

local PlayerAdjustTab = Window:AddTab({
    Name = "Player Adjustment",
    Icon = "user"
})

local FarmTab = Window:AddTab({
    Name = "Farm Section",
    Icon = "cpu"
})

local VisualTab = Window:AddTab({
    Name = "Visuals",
    Icon = "eye"
})

local SettingsTab = Window:AddTab({
    Name = "Settings",
    Icon = "settings"
})

local MainSectionLeft = MainTab:AddSection({
    Name = "Core Features",
    Position = "left"
})

local MainSectionRight = MainTab:AddSection({
    Name = "Additional",
    Position = "right"
})

MainSectionLeft:AddButton({
    Name = "Join Discord",
    Callback = function()
        setclipboard('https://discord.gg/7t83Vx7PvV')
        StarterGui:SetCore("SendNotification", {
            Title = "Discord",
            Text = "Discord Link Copied to Clipboard",
            Duration = 5
        })
    end,
})

MainSectionLeft:AddToggle({
    Name = "Auto Parry",
    Default = false,
    Callback = function(value)
        if value then
            ConnectionsTable["Auto Parry"] = RunService.PreSimulation:Connect(function()
                local BallsArray = ZypherionModule.GetAllBalls()
                if not BallsArray or #BallsArray == 0 then return end
                
                for _, BallObject in pairs(BallsArray) do
                    if not BallObject then return end
                    local ZoomiesComponent = BallObject:FindFirstChild("zoomies")
                    if not ZoomiesComponent then return end
                    
                    BallObject:GetAttributeChangedSignal("target"):Once(function()
                        HasParried = false
                    end)
                    
                    if HasParried then return end
                    
                    local BallTarget = BallObject:GetAttribute("target")
                    local BallVelocity = ZoomiesComponent.VectorVelocity
                    local character = LocalPlayer.Character
                    if not character or not character.PrimaryPart then return end
                    
                    local DistanceToPlayer = (character.PrimaryPart.Position - BallObject.Position).Magnitude
                    local BallSpeed = BallVelocity.Magnitude
                    local NetworkPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                    local ParryAccuracy = (BallSpeed / 3.25) + NetworkPing
                    local IsCurved = ZypherionModule.CurveDetect()
                    
                    if BallTarget == tostring(LocalPlayer) and AerodynamicActive then
                        local ElapsedTornado = tick() - AerodynamicTimer
                        if ElapsedTornado > 0.6 then
                            AerodynamicTimer = tick()
                            AerodynamicActive = false
                        end
                        return
                    end
                    
                    if BallTarget == tostring(LocalPlayer) and IsCurved then return end
                    
                    if BallTarget == tostring(LocalPlayer) and DistanceToPlayer <= ParryAccuracy then
                        if TriggerAutoAbility() then return end
                        if SlashesDetection and SlashesPending then
                            SlashesPending = false
                            InitiateSlashesParry()
                        end
                        if ActivateCooldownProtection() then return end
                        if not SlashesRunning then ZypherionModule.ExecuteParry() end
                        HasParried = true
                        
                        if BallTrailActive then
                            createBallTrail(BallObject)
                        end
                        if VelocityDisplayActive then
                            createVelocityDisplay(BallObject)
                        end
                    end
                    
                    local LastParryTime = tick()
                    while (tick() - LastParryTime) < 1 do
                        if not HasParried then break end
                        task.wait()
                    end
                    HasParried = false
                end
            end)
        elseif ConnectionsTable["Auto Parry"] then
            ConnectionsTable["Auto Parry"]:Disconnect()
            ConnectionsTable["Auto Parry"] = nil
        end
    end,
})

local autoSpamCoroutine = nil
local targetedPlayer = nil

MainSectionLeft:AddToggle({
    Name = "Auto Spam",
    Default = false,
    Callback = function(value)
        if value then
            if autoSpamCoroutine then
                coroutine.resume(autoSpamCoroutine, "stop")
                autoSpamCoroutine = nil
            end

            autoSpamCoroutine = coroutine.create(function(signal)
                while value and (signal ~= "stop") do
                    local ballObject = ZypherionModule.GetActiveBall()
                    if ballObject and ballObject:IsDescendantOf(workspace) then
                        local zoomiesComponent = ballObject:FindFirstChild("zoomies")
                        if zoomiesComponent then
                            ZypherionModule.FindNearestPlayer()
                            targetedPlayer = NearestPlayer

                            if targetedPlayer and targetedPlayer.PrimaryPart and targetedPlayer:IsDescendantOf(workspace) then
                                local playerDistance = LocalPlayer:DistanceFromCharacter(ballObject.Position)
                                local targetPosition = targetedPlayer.PrimaryPart.Position
                                local targetDistance = LocalPlayer:DistanceFromCharacter(targetPosition)

                                if targetedPlayer.Parent then
                                    if ballObject:IsDescendantOf(workspace) and (ballObject.Position.Magnitude >= 1) then
                                        local ballVelocity = ballObject.Velocity.Magnitude
                                        local ballSpeed = math.max(ballVelocity, 0)
                                        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                                        local pingThreshold = math.clamp(ping / 10, 10, 16)

                                        if (zoomiesComponent.Parent == ballObject) and ((playerDistance <= 30) or (targetDistance <= 30)) and (ParryCount > 1) then
                                            ZypherionModule.ExecuteParry()
                                        end
                                    else
                                        local waitTime = 0
                                        repeat
                                            task.wait(0.1)
                                            waitTime = waitTime + 0.1
                                            ballObject = ZypherionModule.GetActiveBall()
                                        until (ballObject and ballObject:IsDescendantOf(workspace) and (ballObject.Position.Magnitude > 1)) or (waitTime >= 2.5)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.0001)
                end
            end)

            coroutine.resume(autoSpamCoroutine)
        elseif autoSpamCoroutine then
            coroutine.resume(autoSpamCoroutine, "stop")
            autoSpamCoroutine = nil
        end
    end,
})

MainSectionRight:AddToggle({
    Name = "Manual Spam",
    Default = false,
    Callback = function()
        CreateManualSpamGUI()
    end
})

ZypherionModule.ParryDirection = "Straight"
MainSectionRight:AddDropdown({
    Name = "Curve Method",
    Values = {"Random", "Backwards", "Straight", "Up", "Right", "Left"},
    Default = "Straight",
    Callback = function(selected)
        ZypherionModule.ParryDirection = selected
    end
})

local AbilitiesSectionLeft = AbilitiesTab:AddSection({
    Name = "Ability Detection",
    Position = "left"
})

local AbilitiesSectionRight = AbilitiesTab:AddSection({
    Name = "Auto Features",
    Position = "right"
})

AbilitiesSectionLeft:AddToggle({
    Name = "Slashes of Fury Detection",
    Default = false,
    Callback = function(state)
        SlashesDetection = state
    end
})

AbilitiesSectionLeft:AddToggle({
    Name = "Infinity Detection",
    Default = false,
    Callback = function(state)
        InfinityDetection = state
    end
})

AbilitiesSectionLeft:AddToggle({
    Name = "Time Hole Detection",
    Default = false,
    Callback = function(state)
        TimeHoleDetection = state
    end
})

AbilitiesSectionLeft:AddToggle({
    Name = "Singularity Detection",
    Default = false,
    Callback = function(state)
        SingularityDetection = state
    end
})

AbilitiesSectionLeft:AddToggle({
    Name = "Phantom Detection",
    Default = false,
    Callback = function(state)
        PhantomDetection = state
    end
})

AbilitiesSectionRight:AddToggle({
    Name = "Auto Ability",
    Default = false,
    Callback = function(state)
        AutoAbilityMode = state
    end
})

AbilitiesSectionRight:AddToggle({
    Name = "Cooldown Protection",
    Default = false,
    Callback = function(state)
        CooldownProtectionMode = state
    end
})

local SkinSectionRight = SkinChangerTab:AddSection({
    Name = "Copy Script",
    Position = "left"
})



SkinSectionRight:AddButton({
    Name = "Copy Script",
    Callback = function()
        setclipboard([[
getgenv().Gen = getgenv().Gen or {
    SwModel = "SWORD NAME",
    Animation = "SWORD NAME",
    Slash = "SWORD NAME"
}
loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/f1cfaa45dddeda3f553806250af98fbe.lua"))()
        ]])

        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Copied!",
            Text = "Script Copied to Clipboard!",
            Duration = 3
        })
    end
})

local PlayerSectionLeft = PlayerAdjustTab:AddSection({
    Name = "Movement Settings",
    Position = "left"
})

local PlayerSectionRight = PlayerAdjustTab:AddSection({
    Name = "Camera & Physics",
    Position = "right"
})

PlayerSectionLeft:AddSlider({
    Name = "Walk Speed",
    Min = 5,
    Max = 50,
    Round = 1,
    Default = DefaultWalkSpeed,
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end,
})

PlayerSectionRight:AddSlider({
    Name = "Field of View",
    Min = 40,
    Max = 120,
    Round = 1,
    Default = DefaultFieldOfView,
    Callback = function(value)
        Workspace.CurrentCamera.FieldOfView = value
    end,
})

PlayerSectionRight:AddSlider({
    Name = "Gravity",
    Min = 50,
    Max = 196.2,
    Round = 0.1,
    Default = DefaultGravityForce,
    Callback = function(value)
        Workspace.Gravity = value
    end,
})

PlayerSectionLeft:AddSlider({
    Name = "Camera Sensitivity",
    Min = 0.1,
    Max = 5,
    Round = 0.1,
    Default = DefaultMouseSensitivity,
    Callback = function(value)
        pcall(function()
            UserSettings():GetService("UserGameSettings").MouseSensitivity = value
        end)
    end,
})

PlayerSectionRight:AddButton({
    Name = "Reset All Settings",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = DefaultWalkSpeed
        end
        Workspace.CurrentCamera.FieldOfView = DefaultFieldOfView
        Workspace.Gravity = DefaultGravityForce
        pcall(function()
            UserSettings():GetService("UserGameSettings").MouseSensitivity = DefaultMouseSensitivity
        end)
        StarterGui:SetCore("SendNotification", {
            Title = "Player Adjustment",
            Text = "All settings reset to default",
            Duration = 3
        })
    end
})

local FarmSectionLeft = FarmTab:AddSection({
    Name = "AI System",
    Position = "left"
})

local FarmSectionRight = FarmTab:AddSection({
    Name = "Auto Farm",
    Position = "right"
})

FarmSectionLeft:AddToggle({
    Name = "AI Play",
    Default = false,
    Callback = function(state)
        AIBotActive = state
        if state then
            if AIBotCoroutine then
                coroutine.close(AIBotCoroutine)
            end
            AIBotCoroutine = coroutine.create(executeAIBehavior)
            coroutine.resume(AIBotCoroutine)
        else
            if AIBotCoroutine then
                coroutine.close(AIBotCoroutine)
                AIBotCoroutine = nil
            end
        end
    end
})

FarmSectionLeft:AddDropdown({
    Name = "AI Method",
    Values = {"AdvancedPro", "BallChaser"},
    Default = "AdvancedPro",
    Callback = function(selected)
        AIBotStrategy = selected
    end
})

FarmSectionRight:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(state)
        AutoFarmActive = state
        if state then
            initializeAutoFarm()
        else
            if AutoFarmCoroutine then
                AutoFarmCoroutine:Disconnect()
                AutoFarmCoroutine = nil
            end
        end
    end
})

FarmSectionRight:AddDropdown({
    Name = "Auto Farm Type",
    Values = {"UnderBall", "X Orbit", "Y Orbit", "Z Orbit", "Helix", "Figure8", "Spiral", "Random Orbit"},
    Default = "Random Orbit",
    Callback = function(selected)
        AutoFarmPattern = selected
    end
})

FarmSectionRight:AddSlider({
    Name = "Farm Radius",
    Min = 5,
    Max = 50,
    Round = 1,
    Default = 20,
    Callback = function(value)
        AutoFarmDistance = value
    end,
})

FarmSectionRight:AddSlider({
    Name = "Farm Height",
    Min = 5,
    Max = 30,
    Round = 1,
    Default = 10,
    Callback = function(value)
        AutoFarmElevation = value
    end,
})

local VisualSectionLeft = VisualTab:AddSection({
    Name = "Visual Effects",
    Position = "left"
})

local VisualSectionRight = VisualTab:AddSection({
    Name = "Sound Effects",
    Position = "right"
})

VisualSectionLeft:AddToggle({
    Name = "Ball Visualizer",
    Default = false,
    Callback = function(state)
        VisualizerActive = state
        if not state then
            BallVisualizer.Size = Vector3.zero
        end
    end
})

VisualSectionLeft:AddToggle({
    Name = "Ball Trail",
    Default = false,
    Callback = function(state)
        BallTrailActive = state
    end
})

VisualSectionLeft:AddToggle({
    Name = "Player Trail",
    Default = false,
    Callback = function(state)
        PlayerTrailActive = state
        if state and LocalPlayer.Character then
            createPlayerTrail(LocalPlayer.Character)
        end
    end
})

VisualSectionLeft:AddToggle({
    Name = "Ball Velocity Display",
    Default = false,
    Callback = function(state)
        VelocityDisplayActive = state
    end
})

VisualSectionLeft:AddToggle({
    Name = "Shaders",
    Default = false,
    Callback = function(state)
        ShadersActive = state
        if state then
            applyShaders()
        else
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") then
                    effect:Destroy()
                end
            end
        end
    end
})

VisualSectionRight:AddToggle({
    Name = "Hit Sound",
    Default = false,
    Callback = function(state)
        SoundEffectActive = state
    end
})

VisualSectionRight:AddDropdown({
    Name = "Sound Type",
    Values = allSoundOptions,
    Default = "DC_15X",
    Callback = function(selected)
        SoundType = selected
    end
})



local SettingsSectionLeft = SettingsTab:AddSection({
    Name = "Performance",
    Position = "left"
})

local SettingsSectionRight = SettingsTab:AddSection({
    Name = "Spam Settings",
    Position = "right"
})

SettingsSectionLeft:AddToggle({
    Name = "Ping Based",
    Default = true,
    Callback = function(state)
        PingBasedMode = state
    end
})

SettingsSectionLeft:AddSlider({
    Name = "FPS Cap",
    Min = 30,
    Max = 240,
    Round = 1,
    Default = 60,
    Callback = function(value)
        FPSCapValue = value
        setfpscap(value)
    end,
})

SettingsSectionRight:AddSlider({
    Name = "Manual Spam Speed",
    Min = 1,
    Max = 20,
    Round = 1,
    Default = 10,
    Callback = function(value)
        ManualSpamRate = value
    end,
})

RunService.RenderStepped:Connect(function()
    if not VisualizerActive then return end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local primaryPart = character and character.PrimaryPart
    local ballObject = ZypherionModule.GetActiveBall()
    
    if not (primaryPart and ballObject) then
        BallVisualizer.Size = Vector3.zero
        return
    end
    
    local target = ballObject:GetAttribute("target")
    local isTargetingPlayer = (target == LocalPlayer.Name)
    local velocity = ballObject:FindFirstChild("zoomies") and ballObject.zoomies.VectorVelocity.Magnitude or 0
    local radius = math.clamp((velocity / 2.4) + 10, 15, 200)
    
    BallVisualizer.Size = Vector3.new(radius, radius, radius)
    BallVisualizer.CFrame = primaryPart.CFrame
    BallVisualizer.Color = isTargetingPlayer and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
end)

CreateManualSpamGUI()

local staffBlacklist = {
    950659306, 81048598, 1434394144, 1091441664, 282464546,
    3075023597, 6133498737, 4055831197, 1362635, 3611927169,
    1686376775, 556522880, 81233250, 368477234, 1607891435,
    45385291, 207355228, 5119318514, 28131272, 135312065,
    92313341, 85388005, 219183651, 7604240058, 3109057880,
    3514574599, 675320181, 202412127, 4853759656, 136346113,
    2685088297, 3562941918, 2735356267, 7099764218, 7140938597,
    70858479, 33836554, 932083, 780769472, 7758626448,
    7930656926, 7369302977, 7688358340, 429368993, 7350680242,
    7447457572, 42902110, 101278664, 813163219, 2678001507,
    5098885657, 5638883751, 812993282, 4946842593, 2243026817,
    71017424, 276557820, 5080868749
}

local function validatePlayer(player)
    if table.find(staffBlacklist, player.UserId) then
        warn("[ANTI-BAN] Detected staff member:", player.Name, "| ID:", player.UserId)
        LocalPlayer:Kick("Anti-Ban Activated: Staff Detected - we dont let you get ban:)")
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        validatePlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    validatePlayer(player)
end)

local function optimizeGamePerformance()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Rendering.EditQualityLevel = Enum.QualityLevel.Level01
    
    for _, object in pairs(Workspace:GetDescendants()) do
        if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
            object.Enabled = false
        elseif object:IsA("Explosion") then
            object.Visible = false
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    
    task.wait(1)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = StrafeVelocity or DefaultWalkSpeed
    end
    
    if PlayerTrailActive then
        createPlayerTrail(newCharacter)
    end
end)

local function performCleanup()
    for name, connection in pairs(ConnectionsTable) do
        if connection then
            connection:Disconnect()
            ConnectionsTable[name] = nil
        end
    end
    
    if AutoFarmCoroutine then
        AutoFarmCoroutine:Disconnect()
        AutoFarmCoroutine = nil
    end
    
    if AIBotCoroutine then
        coroutine.close(AIBotCoroutine)
        AIBotCoroutine = nil
    end
    
    if autoSpamCoroutine then
        coroutine.close(autoSpamCoroutine)
        autoSpamCoroutine = nil
    end
    
    if BallVisualizer then
        BallVisualizer:Destroy()
    end
    
    if ManualSpamGUI then
        ManualSpamGUI:Destroy()
    end
end


task.spawn(function()
    while task.wait(5) do
        local currentFPS = 1 / RunService.Heartbeat:Wait()
        if currentFPS < 30 then
            optimizeGamePerformance()
        end
    end
end)


StarterGui:SetCore("SendNotification", {
    Title = "NodeX",
    Text = "Script loaded successfully!",
    Duration = 8
})



