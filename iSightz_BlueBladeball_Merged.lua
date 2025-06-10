-- Blade Ball Pro Hub (Final Merged)
-- Features: Auto Parry, TriggerBot, Auto Spam, Weapon/Emote Changer, Anti-Kick, Clean UI
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.Character

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local CG = game:GetService("CoreGui")
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- ANTI-KICK
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNameCall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if tostring(self):lower():find("kick") and method == "FireServer" then
        warn("[Anti-Kick] Blocked kick attempt.")
        return
    end
    return oldNameCall(self, ...)
end)

-- REMOVE OLD GUI
for _, gui in pairs(CG:GetChildren()) do
    if gui.Name == "iSightzBladeballScript" or gui.Name == "Silly" then gui:Destroy() end
end

-- UI SETUP
local GUI = Instance.new("ScreenGui", CG)
GUI.Name = "iSightzBladeballScript"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true

local Main = Instance.new("Frame", GUI)
Main.Size = UDim2.new(0, 500, 0, 330)
Main.Position = UDim2.new(0.5, -250, 0.5, -165)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(0, 120, 255)
stroke.Thickness = 2.2

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "Blade Ball Pro Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1

-- DRAG
local dragging = false
local dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- UI TOGGLE
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightAlt then
        GUI.Enabled = not GUI.Enabled
    end
end)

-- NOTIFY
local function Notify(msg)
    game.StarterGui:SetCore("SendNotification", {
        Title = "Blade Ball Pro Hub",
        Text = msg,
        Duration = 3
    })
end

-- FEATURES
local autoParry, autoSpam, triggerBot = false, false, false
local phrase = "ez"
local lastParryTime = 0

-- FUNCTION: GET REAL BALL
local function getRealBall()
    for _, b in pairs(workspace.Balls:GetChildren()) do
        if b:IsA("BasePart") and b:GetAttribute("realBall") then return b end
    end
end

-- AUTO PARRY LOOP
task.spawn(function()
    while true do
        task.wait()
        if autoParry and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local ball = getRealBall()
            if ball then
                local dir = (LP.Character.HumanoidRootPart.Position - ball.Position).Unit
                local dot = dir:Dot(ball.Velocity.Unit)
                if dot < -0.97 and tick() - lastParryTime > 0.35 then
                    VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    task.wait()
                    VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    lastParryTime = tick()
                end
            end
        end
    end
end)

-- AUTO SPAM
task.spawn(function()
    while true do
        task.wait(2)
        if autoSpam then
            game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(phrase, "All")
        end
    end
end)

-- TRIGGERBOT
task.spawn(function()
    while true do
        task.wait()
        if triggerBot and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            for _, enemy in pairs(workspace.Alive:GetChildren()) do
                if enemy:IsA("Model") and enemy ~= LP.Character and enemy:FindFirstChild("HumanoidRootPart") then
                    local dist = (enemy.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 25 then
                        VIM:SendMouseButtonEvent(0,0,0,true,game,0)
                        task.wait()
                        VIM:SendMouseButtonEvent(0,0,0,false,game,0)
                        break
                    end
                end
            end
        end
    end
end)

-- BUTTON CREATOR
local function createButton(name, posY, callback)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0, 200, 0, 32)
    b.Position = UDim2.new(0, 20, 0, posY)
    b.Text = name
    b.Font = Enum.Font.Gotham
    b.TextSize = 16
    b.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    b.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(callback)
end

-- BUTTONS
createButton("Auto Parry", 50, function()
    autoParry = not autoParry
    Notify("Auto Parry: " .. tostring(autoParry))
end)

createButton("Triggerbot", 90, function()
    triggerBot = not triggerBot
    Notify("Triggerbot: " .. tostring(triggerBot))
end)

createButton("Auto Spam", 130, function()
    autoSpam = not autoSpam
    Notify("Auto Spam: " .. tostring(autoSpam))
end)

createButton("Emote: Laugh", 170, function()
    local anim = ReplicatedStorage.Misc.Emotes:FindFirstChild("Laugh")
    if anim then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:LoadAnimation(anim):Play() end
    end
end)

createButton("Weapon: Default", 210, function()
    local swordAPI = ReplicatedStorage.Shared.ReplicatedInstances.Swords
    if swordAPI then
        swordAPI.GetSword:Invoke("Default")
        Notify("Weapon set to Default")
    end
end)

-- DONE
Notify("Blade Ball Pro Hub Loaded Successfully")

