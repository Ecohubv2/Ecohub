-- ECO HUB FULL MERGED (FINAL FILE)

getgenv().XH = getgenv().XH or {}
local Env = getgenv().XH

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

Env.ScriptID = (Env.ScriptID or 0) + 1
local CurrentID = Env.ScriptID

Env.AutoFarm = false
Env.AutoSlide = false
Env.AntiAFK = false
Env.InfStamina = false
Env.SelectedFarmTargets = {}
Env.CurrentFarmIndex = 1
Env.SellDelay = 3
Env.SlideDelay = 1

local FarmData = {
    ["Strawberry"] = { Pos = CFrame.new(5963,48,-1669), Item="Strawberry", Max=60 },
    ["Corn"] = { Pos = CFrame.new(5126,45,-2333), Item="Corn", Max=60 },
    ["Wood"] = { Pos = CFrame.new(2331,31,-2533), Item="Wood", Max=60 },
}

local SELL_POS = CFrame.new(2854,14,2111)

local function getRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function tp(cf)
    local root = getRoot()
    if root then root.CFrame = cf end
end

local function getCount(itemName)
    local count = 0
    pcall(function()
        local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
        for _,v in pairs(body:GetChildren()) do
            if v.Name == itemName then
                local amt = v.Main.Amount.Text:match("^(%d+)")
                if amt then count = tonumber(amt) end
            end
        end
    end)
    return count
end

local function sellAll()
    tp(SELL_POS)
    task.wait(Env.SellDelay)

    for _,name in ipairs(Env.SelectedFarmTargets) do
        local data = FarmData[name]
        if data then
            repeat
                pcall(function()
                    game:GetService("ReplicatedStorage")
                    .Modules.NetworkFramework.NetworkEvent:FireServer(
                        "fire", nil, "Economy", data.Item, data.Max
                    )
                end)
                task.wait(0.3)
            until getCount(data.Item) == 0
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        if CurrentID ~= Env.ScriptID then break end
        if not Env.AutoFarm then continue end

        local root = getRoot()
        if not root then continue end

        local jobName = Env.SelectedFarmTargets[Env.CurrentFarmIndex]
        local job = FarmData[jobName]
        if not job then continue end

        local count = getCount(job.Item)

        if count >= job.Max then
            sellAll()
        else
            tp(job.Pos)
        end
    end
end)

RunService.Stepped:Connect(function()
    if Env.AutoFarm then
        local char = Player.Character
        if char then
            for _,v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end
end)

Env.Start = function(list)
    Env.SelectedFarmTargets = list or {"Strawberry"}
    Env.CurrentFarmIndex = 1
    Env.AutoFarm = true
end

Env.Stop = function()
    Env.AutoFarm = false
end

print("ECO HUB FINAL LOADED")
