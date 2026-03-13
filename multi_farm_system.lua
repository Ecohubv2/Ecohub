
-- MULTI FARM SYSTEM (No Respawn Sell)
-- Features:
-- Farm multiple locations
-- Do not sell when first farm is full
-- Sell only after all selected farms are full
-- Teleport to market to sell (no respawn)
-- Sell all farmed items

getgenv().XH = getgenv().XH or {}
local Env = getgenv().XH

Env.SelectedFarmTargets = Env.SelectedFarmTargets or {}
Env.CurrentFarmIndex = 1
Env.SellDelay = 5

local Player = game.Players.LocalPlayer

-- get current farm data
local function getCurrentFarmData()
    local name = Env.SelectedFarmTargets[Env.CurrentFarmIndex]
    if name then
        return FarmData[name]
    end
end

-- move to next farm
local function nextFarm()
    Env.CurrentFarmIndex += 1
    if Env.CurrentFarmIndex > #Env.SelectedFarmTargets then
        Env.CurrentFarmIndex = 1
    end
end

-- check if all farms full
local function allFarmsFull()

    for _,name in pairs(Env.SelectedFarmTargets) do

        local data = FarmData[name]
        local count = 0

        pcall(function()

            local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body

            for _,item in pairs(body:GetChildren()) do
                if item.Name == data.Item then
                    local amt = item.Main.Amount.Text:match("^(%d+)")
                    if amt then
                        count = tonumber(amt)
                    end
                end
            end

        end)

        if count < data.Max then
            return false
        end

    end

    return true

end

-- sell items without respawning
local function sellAllFarms()

    warpWithPermanentSeat(sellCFrame,false,false)

    task.wait(Env.SellDelay)

    for _,name in pairs(Env.SelectedFarmTargets) do

        local data = FarmData[name]

        for i = 1,4 do

            pcall(function()

                game:GetService("ReplicatedStorage")
                .Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire",
                    nil,
                    "Economy",
                    data.Item,
                    data.Max
                )

            end)

            task.wait(0.4)

        end

    end

end

-- example logic hook
function Env.MultiFarmLogic(currentCount,currentJobData)

    if currentCount >= currentJobData.Max then

        if allFarmsFull() then
            sellAllFarms()
        else
            nextFarm()
        end

    end

end
