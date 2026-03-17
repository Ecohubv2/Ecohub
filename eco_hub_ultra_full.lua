-- ECO HUB ULTRA FULL (ALL SYSTEMS)

getgenv().XH = getgenv().XH or {}
local Env = getgenv().XH

-- SERVICES
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

-- SAFE THREAD RESET
Env.ScriptID = (Env.ScriptID or 0) + 1
local ID = Env.ScriptID

-- STATES
Env.AutoFarm = false
Env.AutoSlide = false
Env.AntiAFK = true
Env.InfStamina = true
Env.SelectedFarmTargets = {}
Env.CurrentFarmIndex = 1
Env.SellDelay = 2
Env.SlideDelay = 0.8

-- FARM DATA (FULL)
local FarmData = {
    ["Strawberry"] = { Pos = CFrame.new(5963,48,-1669), Item="Strawberry", Max=60 },
    ["Corn"] = { Pos = CFrame.new(5126,45,-2333), Item="Corn", Max=60 },
    ["Chilli"] = { Pos = CFrame.new(-636,13,-3379), Item="Chilli", Max=60 },
    ["Banana"] = { Pos = CFrame.new(-1094,128,2404), Item="Banana", Max=60 },
    ["Grape"] = { Pos = CFrame.new(5461,47,-1208), Item="Grape", Max=60 },
    ["Coconut"] = { Pos = CFrame.new(-2836,18,2199), Item="Coconut", Max=60 },
    ["Pork"] = { Pos = CFrame.new(-555,56,3099), Item="Pork", Max=60 },
    ["Flower"] = { Pos = CFrame.new(-1763,128,1136), Item="Flower", Max=300 },
    ["Wood"] = { Pos = CFrame.new(2331,31,-2533), Item="Wood", Max=60 },
    ["Grass"] = { Pos = CFrame.new(-2461,73,-1938), Item="Grassbush", Max=80 },
}

local SELL_POS = CFrame.new(2854,14,2111)

-- UTIL
local function getRoot()
    local c = Player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tp(cf)
    local r = getRoot()
    if r then r.CFrame = cf end
end

local function getCount(item)
    local count = 0
    pcall(function()
        local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
        for _,v in pairs(body:GetChildren()) do
            if v.Name == item then
                local n = v.Main.Amount.Text:match("^(%d+)")
                if n then count = tonumber(n) end
            end
        end
    end)
    return count
end

local function nextFarm()
    Env.CurrentFarmIndex += 1
    if Env.CurrentFarmIndex > #Env.SelectedFarmTargets then
        Env.CurrentFarmIndex = 1
    end
end

local function allFull()
    for _,name in ipairs(Env.SelectedFarmTargets) do
        local d = FarmData[name]
        if d and getCount(d.Item) < d.Max then
            return false
        end
    end
    return true
end

-- SELL
local function sellAll()
    tp(SELL_POS)
    task.wait(Env.SellDelay)
    for _,name in ipairs(Env.SelectedFarmTargets) do
        local d = FarmData[name]
        if d then
            repeat
                pcall(function()
                    game:GetService("ReplicatedStorage")
                    .Modules.NetworkFramework.NetworkEvent:FireServer(
                        "fire", nil, "Economy", d.Item, d.Max
                    )
                end)
                task.wait(0.25)
            until getCount(d.Item) == 0
        end
    end
end

-- NEAREST
local function getNearest(root)
    local best,dist = nil, math.huge
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("TouchTransmitter") then
            local p = v.Parent
            if p and p:IsA("BasePart") then
                local d = (p.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    best = p
                end
            end
        end
    end
    return best
end

-- MAIN LOOP
task.spawn(function()
    while task.wait(0.35) do
        if ID ~= Env.ScriptID then break end
        if not Env.AutoFarm then continue end
        if #Env.SelectedFarmTargets == 0 then continue end

        local root = getRoot()
        if not root then continue end

        local name = Env.SelectedFarmTargets[Env.CurrentFarmIndex]
        local job = FarmData[name]
        if not job then continue end

        local count = getCount(job.Item)

        if count >= job.Max then
            if allFull() then
                sellAll()
            else
                nextFarm()
                tp(FarmData[Env.SelectedFarmTargets[Env.CurrentFarmIndex]].Pos)
            end
        else
            local t = getNearest(root)
            if t then
                Player.Character.Humanoid:MoveTo(t.Position)
            else
                tp(job.Pos)
            end
        end
    end
end)

-- SLIDE
task.spawn(function()
    while task.wait(Env.SlideDelay) do
        if Env.AutoSlide then
            VIM:SendKeyEvent(true, Enum.KeyCode.C, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.C, false, game)
        end
    end
end)

-- NOCLIP
RunService.Stepped:Connect(function()
    if Env.AutoFarm then
        local c = Player.Character
        if c then
            for _,v in pairs(c:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end
end)

-- STAMINA
RunService.RenderStepped:Connect(function()
    if Env.InfStamina then
        local c = Player.Character
        if c and c:FindFirstChild("Humanoid") then
            c.Humanoid.WalkSpeed = 24
            c:SetAttribute("Stamina",100)
        end
    end
end)

-- ANTI AFK
Player.Idled:Connect(function()
    if Env.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end
end)

-- CONTROL
Env.Start = function(list)
    Env.SelectedFarmTargets = list or {"Strawberry"}
    Env.CurrentFarmIndex = 1
    Env.AutoFarm = true
end

Env.Stop = function()
    Env.AutoFarm = false
end

print("ECO HUB ULTRA FULL LOADED")
