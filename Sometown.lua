
getgenv().XH = getgenv().XH or {}
local Env = getgenv().XH

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")


local mt = getrawmetatable(game)
setreadonly(mt,false)

local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self,...)

    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" then
        local name = tostring(self):lower()

        if name:find("teleport")
        or name:find("warp")
        or name:find("rejoin")
        or name:find("server")
        or name:find("map")
        or name:find("town") then
            warn("Blocked Remote:",name)
            return
        end
    end

    if method == "Kick" then
        warn("Blocked Kick")
        return
    end

    return oldNamecall(self,...)
end)

local TeleportService = game:GetService("TeleportService")

for _,func in pairs({
    "Teleport",
    "TeleportAsync",
    "TeleportToPlaceInstance",
    "TeleportPartyAsync"
}) do

    local old
    old = hookfunction(TeleportService[func], function(...)
        warn("Blocked "..func)
        return
    end)

end

-- removed duplicate Env init

Env.ScriptID = (Env.ScriptID or 0) + 1
local CurrentID = Env.ScriptID

-- [[ 🛡️ ระบบ Anti-Overlap: ฆ่าสคริปต์เก่าก่อนรันใหม่ ]]


-- สั่งหยุดการทำงานของสคริปต์ก่อนหน้านี้ทั้งหมด
Env.SelectedFarmTargets = Env.SelectedFarmTargets or {}
Env.CurrentFarmIndex = Env.CurrentFarmIndex or 1
Env.SellDelay = 3
Env.NextFarmDelay = 3 
Env.AutoFarm = false
Env.AutoEat = false
Env.AutoSlide = false 
Env.SlideDelay = 1 
Env.MoneyTrackerEnabled = false
if Env.StamConn then Env.StamConn:Disconnect() end
if Env.SeatFollowConnection then Env.SeatFollowConnection:Disconnect() end
task.wait(0.5) 

local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- [[ 📋 ตารางข้อมูลงานทั้งหมด ]]
local FarmData = {
    ["Strawberry"] = { Pos = CFrame.new(5963.03, 48.90, -1669.50), Item = "Strawberry", Max = 60 },
    ["Corn"]       = { Pos = CFrame.new(5126.27, 45.23, -2333.77), Item = "Corn", Max = 60 },
    ["Chilli"]     = { Pos = CFrame.new(-636.49, 13.98, -3379.23), Item = "Chilli", Max = 60 },
    ["Banana"]      = { Pos = CFrame.new(-1094.96, 128.40, 2404.25), Item = "Banana", Max = 60 },
    ["Grape"]       = { Pos = CFrame.new(5461.96, 47.30, -1208.75), Item = "Grape", Max = 60 },
    ["Coconut"]     = { Pos = CFrame.new(-2836.33, 18.67, 2199.34), Item = "Coconut", Max = 60 },
    ["Pork"]        = { Pos = CFrame.new(-555.89, 56.65, 3099.75), Item = "Pork", Max = 60 },
    ["Flower"]      = { Pos = CFrame.new(-1763.48, 128.12, 1136.96), Item = "Flower", Max = 300 },
    ["Wood"]        = { Pos = CFrame.new(2331.03, 31.06, -2533.47), Item = "Wood", Max = 60 },
    ["Grass"]       = { Pos = CFrame.new(-2461.35, 73.00, -1938.21), Item = "Grassbush", Max = 80 },
}

-- [[ 🕒 Configuration ]]
local Delay_CheckLoop           = 3
local Delay_AfterFull_BeforeReset = 4
local Delay_BeforeReset           = 4
local Delay_WalkAtMarket        = 4
local Delay_AfterSell           = 4
local Delay_WarpWait            = 4
local Max_Distance_From_Spawn   = 1000

-- [[ ตัวแปรควบคุมกลาง ]]
Env.WebhookURL = ""
Env.MoneyTrackerEnabled = false
Env.AntiAFK = false
Env.SelectedLocation = "Spawn"
Env.SelectedFarmTarget = "None"
Env.AutoFarm = false
Env.AutoEat = false
Env.InfStamina = false

-- [[ ตัวแปรระบบฟาร์ม ]]
Env.VerifyCount = 0
Env.BotStatus = "CHECKING"
Env.PauseUIUpdate = false
Env.MyPersonalSeat = Env.MyPersonalSeat or nil
Env.SeatFollowConnection = Env.SeatFollowConnection or nil
Env.CurrentFarmTargetItem = nil

local targetAmountToSell = 60
local sellCFrame = CFrame.new(2862.30, 16.19, 2115.02)
local spawnPos = CFrame.new(5972.32, 48.80, -1632.06)

-- [[ 🏃 ฟังก์ชันระบบวิ่ง (FIXED FOR PC & MOBILE) ]]
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function getRunButton()
    local pgui = Player:FindFirstChild("PlayerGui")
    if pgui then
        local target = pgui:FindFirstChild("UIList")
        if target then target = target:FindFirstChild("MobileButton") end
        if target then target = target:FindFirstChild("List2") end
        if target then target = target:FindFirstChild("LeftShift") end
        if target then target = target:FindFirstChild("TextButton") end
        return target
    end
    return nil
end

local function triggerRun()
    if UIS.KeyboardEnabled then
        VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.01)
        VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end
    if UIS.TouchEnabled then
        local btn = getRunButton()
        if btn and btn.Visible then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
        end
    end
end

local function smartRun()
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        if hum.WalkSpeed <= 16.1 then
            triggerRun()
        end
    end
end
-- AUTO NOCLIP
local RunService = game:GetService("RunService")

RunService.Stepped:Connect(function()

    if Env.AutoFarm then

        local char = game.Players.LocalPlayer.Character

        if char then
            for _,v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end

    end

end)
-- [[ 🛠️ ระบบ Auto Slide (แก้ไขให้หยุดสไลด์ตอนขาย) ]]
local function getSlideButton()
    local pgui = Player:FindFirstChild("PlayerGui")
    if pgui then
        local target = pgui:FindFirstChild("UIList")
        if target then target = target:FindFirstChild("MobileButton") end
        if target then target = target:FindFirstChild("List2") end
        if target then target = target:FindFirstChild("C") end
        if target then target = target:FindFirstChild("TextButton") end
        return target
    end
    return nil
end

task.spawn(function()
    while true do
        if CurrentID ~= Env.ScriptID then break end
        if Env.AutoSlide and Env.BotStatus ~= "SELLING_START" and Env.BotStatus ~= "SELLING_IN_PROGRESS" then
            local isTyping = UIS:GetFocusedTextBox() ~= nil
            if not isTyping then
                if UIS.KeyboardEnabled then
                    pcall(function()
                        VIM:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                    end)
                end
                local btn = getSlideButton()
                if btn and btn.Visible then
                    pcall(function()
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end)
                end
            end
            task.wait(Env.SlideDelay)
        else
            task.wait(1)
        end
    end
end)


-- Test

for _, farmName in pairs(Env.SelectedFarmTargets or {}) do
    local data = FarmData[farmName]
    local amount = 0

    pcall(function()
        local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
        for _, item in pairs(body:GetChildren()) do
            if item.Name == data.Item then
                local amt = item.Main.Amount.Text:match("^(%d+)")
                if amt then
                    amount = tonumber(amt)
                end
            end
        end
    end)

    if amount > 0 then
        repeat
            pcall(function()
                game:GetService("ReplicatedStorage")
                .Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire",
                    nil,
                    "Economy",
                    data.Item,
                    amount
                )
            end)

            task.wait(0.5)

            amount = 0
            pcall(function()
                local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
                for _, item in pairs(body:GetChildren()) do
                    if item.Name == data.Item then
                        local amt = item.Main.Amount.Text:match("^(%d+)")
                        if amt then
                            amount = tonumber(amt)
                        end
                    end
                end
            end)

        until amount == 0
    end
end


-- [[ ฟังก์ชันสำหรับการวาร์ปทั่วไป ]]
local function teleportTo(cframe)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

-- [[ ฟังก์ชันหยุดถาวร ]]
local function PermanentStop()
    local player = game.Players.LocalPlayer
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if hum and root then
        hum:MoveTo(root.Position)
        hum:Move(Vector3.new(0,0,0))
    end

    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NetworkFramework"):WaitForChild("NetworkEvent")
    local joinTimeID = player:GetAttribute("JoinTime")
    if joinTimeID then
        local args = {"invoke", tostring(joinTimeID), "BrakAutoFarm", "\002\006\215\177\235^\156\001\003\001\002\001\001\001\fSomeToken321"}
        for i = 1, 3 do
            pcall(function() remote:FireServer(unpack(args)) end)
            task.wait(0.1)
        end
    end

    local ui = player.PlayerGui:FindFirstChild("AutoFarm")
    if ui then
        for _, v in pairs(ui:GetDescendants()) do
            if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                v.Disabled = true
            end
        end
        ui.Enabled = false
    end

    pcall(function()
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
        player.DevTouchMovementMode = Enum.DevTouchMovementMode.UserChoice
    end)
    
    Env.CurrentFarmTargetItem = nil
end

-- [[ 📦 ระบบ Smart Warp แบบเก้าอี้ถาวร ]]
local function getOrPullSeat()
    if _G.MyPersonalSeat and _G.MyPersonalSeat.Parent and _G.MyPersonalSeat:IsA("Seat") then
        return _G.MyPersonalSeat
    end
    local player = game.Players.LocalPlayer
    player:RequestStreamAroundAsync(sellCFrame.Position)
    task.wait(1.5)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Seat") and v.Occupant == nil then
            local char = player.Character
            if char and not v:IsDescendantOf(char) then
                local name = v.Name:lower()
                local isInCar = false
                local parentModel = v:FindFirstAncestorOfClass("Model")
                if parentModel then
                    local pName = parentModel.Name:lower()
                    if pName:find("car") or pName:find("vehicle") or parentModel:FindFirstChild("DriveSeat") then
                        isInCar = true
                    end
                end
                if not v:IsA("VehicleSeat") and not name:find("car") and not isInCar then
                    _G.MyPersonalSeat = v
                    return v
                end
            end
        end
    end
    return nil
end

local function warpWithPermanentSeat(goalCFrame, isManual, isFarmingWarp)
    if CurrentID ~= Env.ScriptID then return end
    if not isManual and not Env.AutoFarm then return end
    
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local root = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    local runService = game:GetService("RunService")
    
    local seat = getOrPullSeat()
    
    if seat then
        Env.PauseUIUpdate = true
        if Env.SeatFollowConnection then Env.SeatFollowConnection:Disconnect() end

        local animScript = char:FindFirstChild("Animate")
        if animScript then animScript.Disabled = true end

        seat.Anchored = true
        seat.CFrame = root.CFrame * CFrame.new(0, -1, 0)
        
        local sitAttempts = 0
        repeat
            if not isManual and not Env.AutoFarm then break end
            seat:Sit(humanoid)
            task.wait(0.1)
            sitAttempts = sitAttempts + 1
        until humanoid.SeatPart == seat or sitAttempts > 10
        
        if humanoid.SeatPart ~= seat then
            if not isManual and not Env.AutoFarm then
                Env.PauseUIUpdate = false
                if animScript then animScript.Disabled = false end
                return
            end
        end

        task.wait(0.2)
        seat.CFrame = goalCFrame
        task.wait(Delay_WarpWait)

        root.Anchored = true
        humanoid.Sit = false
        task.wait(0.1)

        root.CFrame = goalCFrame * CFrame.new(0, 2, 0)
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
        task.wait(0.1)

        root.Anchored = false
        if animScript then animScript.Disabled = false end

        task.spawn(function()
            task.wait(0.6)
            if isFarmingWarp and (isManual or (Env.AutoFarm and CurrentID == Env.ScriptID)) then
                smartRun()
            end
        end)

        Env.SeatFollowConnection = runService.Heartbeat:Connect(function()
            if CurrentID ~= Env.ScriptID then if Env.SeatFollowConnection then Env.SeatFollowConnection:Disconnect() end return end
            if not isManual and not Env.AutoFarm then if Env.SeatFollowConnection then Env.SeatFollowConnection:Disconnect() end return end
            
            if seat and seat.Parent and root and root.Parent then
                seat.CFrame = root.CFrame * CFrame.new(0, -10, 0)
            else
                if Env.SeatFollowConnection then Env.SeatFollowConnection:Disconnect() end
            end
        end)
        
        Env.PauseUIUpdate = false
    end
end
-- [[ 🌐 ส่วน WEBHOOK LOGIC ]]
local HttpService = game:GetService("HttpService")
local request_func = request or (http and http.request) or http_request or (syn and syn.request) or (fluxus and fluxus.request)
local lastMoney = 0

local function extractNumber(str)
    if not str or str == "" then return nil end
    local numeric = str:gsub("[%D]", "")
    return tonumber(numeric)
end

local function notify(title, desc, color)
    if not request_func or Env.WebhookURL == "" then return end
    local proxy_url = Env.WebhookURL:gsub("discord.com", "hooks.hyra.io")
    
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = desc,
            ["color"] = color,
            ["footer"] = {["text"] = "Some Town"},
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }
    
    pcall(function()
        request_func({
            Url = proxy_url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function getAllPossibleMoney()
    local success, res = pcall(function()
        return Player.PlayerGui.Inventory.CanvasGroup.Main.Body.Cash.Main.Amount.Text
    end)
    if success and extractNumber(res) then return extractNumber(res) end

    local sources = {Player:FindFirstChild("Backpack"), Player.Character}
    for _, src in pairs(sources) do
        if src then
            for _, item in pairs(src:GetChildren()) do
                if item.Name:find("เงิน") or item.Name:find("Cash") then
                    local num = extractNumber(item.Name)
                    if num then return num end
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(1) do
        if CurrentID ~= Env.ScriptID then break end
        if Env.MoneyTrackerEnabled then
            local currentMoney = getAllPossibleMoney()
            if currentMoney and lastMoney and currentMoney ~= lastMoney then
                if lastMoney ~= 0 then
                    local diff = currentMoney - lastMoney
                    if diff > 0 then
                        notify("📈 เงินเพิ่ม!", "👤: "..Player.Name.."\n💰: +"..diff.."\n💵 รวม: "..currentMoney, 65280)
                    elseif diff < 0 then
                        notify("📉 เงินลด!", "👤: "..Player.Name.."\n💸: -"..math.abs(diff).."\n💵 รวม: "..currentMoney, 16711680)
                    end
                end
                lastMoney = currentMoney
            elseif currentMoney and not lastMoney then
                lastMoney = currentMoney
            end
        end
    end
end)

-- ===============================
-- SEAT SYSTEM
-- ===============================

local function getSeat()

    if _G.EcoSeat and _G.EcoSeat.Parent then
        return _G.EcoSeat
    end

    local seat = Instance.new("Seat")
    seat.Name = "EcoSeat"
    seat.Size = Vector3.new(2,1,2)
    seat.Anchored = true
    seat.Transparency = 1
    seat.CanCollide = false
    seat.Massless = true
    seat.Parent = workspace

    _G.EcoSeat = seat

    return seat
end

-- ===============================
-- STABLE SEAT WARP
-- ===============================

function SafeSeatWarp(goal)

    local char = Player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")

    if not root or not hum then return end

    local seat = getSeat()

    seat.CFrame = root.CFrame

    pcall(function()
        seat:Sit(hum)
    end)

    task.wait(0.2)

    local dist = (goal.Position - root.Position).Magnitude
    local steps = math.clamp(math.floor(dist/120),1,12)

    for i=1,steps do

        local cf = root.CFrame:Lerp(goal,i/steps)
        seat.CFrame = cf

        task.wait(0.05)

    end

    root.CFrame = goal + Vector3.new(0,3,0)
    root.Velocity = Vector3.zero

end


task.spawn(function()

    while task.wait(0.3) do

        local char = Player.Character
        if not char then continue end

        local root = char:FindFirstChild("HumanoidRootPart")

        if root and root.Position.Y < -20 then
            root.CFrame = CFrame.new(0,50,0)
        end

    end

end)

-- test
local function getCurrentFarmData()
    local name = Env.SelectedFarmTargets[Env.CurrentFarmIndex]
    if name then
        return FarmData[name]
    end
    return nil
end

local function nextFarm()
    task.wait(Env.NextFarmDelay)
    Env.CurrentFarmIndex = Env.CurrentFarmIndex + 1
    if Env.CurrentFarmIndex > #Env.SelectedFarmTargets then
        Env.CurrentFarmIndex = 1
    end
end
-- [[ ระบบ Anti-AFK ]]
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    if Env.AntiAFK and CurrentID == Env.ScriptID then
        local camera = workspace.CurrentCamera
        camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(0.1), 0)
    end
end)

-- [[ 📱 แยกขนาด UI ตามอุปกรณ์ ]]
local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(450, 320) or UDim2.fromOffset(580, 460)

local Window = Library:CreateWindow({
    Title = "ECO HUB",
    SubTitle = "| by _kopeas",
    TabWidth = 140,
    Size = WindowSize,
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "rbxassetid://4483345998" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "share-2" }),
    FixLag = Window:AddTab({ Title = "Fix Lag", Icon = "monitor" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}


Tabs.Farm:AddDropdown("SelectFarmTarget", {
    Title = "Select Farm",
    Multi = true,
    Values = {
        "Strawberry","Corn","Chilli","Banana",
        "Grape","Coconut","Pork","Flower","Wood","Grass"
    },

    Default = {},

    Callback = function(Value)

        -- กันบัค ถ้า Value เป็น string
        if type(Value) ~= "table" then
            local t = {}
            t[Value] = true
            Value = t
        end

        Env.SelectedFarmTargets = {}

for name,state in pairs(Value) do
    if state then
        table.insert(Env.SelectedFarmTargets,name)
    end
end
        Env.BotStatus = "CHECKING"
        Env.CurrentFarmTargetItem = nil

        if Env.AutoFarm then
            task.spawn(function()
                task.wait(0.1)
                smartRun()
            end)
        end

    end
})

Tabs.Farm:AddToggle("AutoFarm", {
    Title = "Auto Farm", Default = false,
    Callback = function(v)
        Env.AutoFarm = v
        if not v then
            Env.BotStatus = "CHECKING"
            PermanentStop()
        else
            Env.BotStatus = "CHECKING"
            task.spawn(function() task.wait(0.5); smartRun() end)
        end
    end 
})
Tabs.Farm:AddSlider("SellDelay",{
    Title = "Sell Delay",
    Description = "Delay before selling",
    Default = 5,
    Min = 0,
    Max = 30,
    Rounding = 1,
    Callback = function(v)
        Env.SellDelay = v
    end
})


local SlideSection = Tabs.Farm:AddSection("Auto Slide Settings")
Tabs.Farm:AddToggle("AutoSlide", { Title = "Auto Slide", Default = false, Callback = function(v) Env.AutoSlide = v end })
local SlideSlider = Tabs.Farm:AddSlider("SlideDelay", {
    Title = "Slide Delay",
    Description = "ปรับระยะเวลาการสไลด์ (1-20 วินาที)",
    Default = Env.SlideDelay,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        Env.SlideDelay = Value
    end
})

local SlideInput = Tabs.Farm:AddInput("SlideDelayInput", {
    Title = "Slide Delay(ใส่เลขสำหรับมือถือ)",
    Default = tostring(Env.SlideDelay),
    Placeholder = "ใส่เลข 1 ถึง 20...",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            if num < 1 then num = 1 end
            if num > 20 then num = 20 end
            Env.SlideDelay = num
            SlideSlider:SetValue(num)
        end
    end
})

Tabs.Teleport:AddDropdown("SelectLocation", {
    Title = "Select Location", Values = {"ร้านค้า", "ตลาดโลก", "เรเบลฟ้า", "อู่", "โรงบาล", "สถานีตำรวจ"},
    Default = "None",
    Callback = function(Value) Env.SelectedLocation = Value end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Selected",
    Callback = function()
        if Env.SelectedLocation == "ร้านค้า" then warpWithPermanentSeat(CFrame.new(3000.52, 14.63, 2278.16), true, false)
        elseif Env.SelectedLocation == "ตลาดโลก" then warpWithPermanentSeat(CFrame.new(2851.19, 14.57, 2112.10), true, false)
        elseif Env.SelectedLocation == "เรเบลฟ้า" then warpWithPermanentSeat(CFrame.new(1977.28, 14.09, 2520.64), true, false)
        elseif Env.SelectedLocation == "อู่" then warpWithPermanentSeat(CFrame.new(2832.98, 14.27, 2648.37), true, false)
        elseif Env.SelectedLocation == "โรงบาล" then warpWithPermanentSeat(CFrame.new(2803.07, 14.27, 3452.44), true, false)
        elseif Env.SelectedLocation == "สถานีตำรวจ" then warpWithPermanentSeat(CFrame.new(3522.56, 14.27, 3252.11), true, false)
        end
    end
})

local WebhookSection = Tabs.Webhook:AddSection("Webhook Settings")
Tabs.Webhook:AddInput("WebhookURL", {
    Title = "Discord Webhook URL", Default = Env.WebhookURL,
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value) Env.WebhookURL = Value end
})

Tabs.Webhook:AddButton({
    Title = "Test Webhook",
    Description = "กดเพื่อทดสอบ Webhook",
    Callback = function()
        if Env.WebhookURL == "" then
            Library:Notify({
                Title = "Error",
                Content = "กรุณาใส่ Webhook URL ก่อนทดสอบ",
                Duration = 5
            })
            return
        end
        notify("🧪 Test Message", "Webhook ของคุณทำงานปกติ!\n👤: "..Player.Name, 16776960)
        Library:Notify({
            Title = "Success",
            Content = "ส่งข้อความทดสอบไปที่ Discord แล้ว!",
            Duration = 5
        })
    end
})

Tabs.Webhook:AddToggle("MoneyTracker", {
    Title = "Enable Money Tracker", Default = Env.MoneyTrackerEnabled,
    Callback = function(v) Env.MoneyTrackerEnabled = v end
})

-- [[ 🚀 ส่วน Fix Lag ]]
Tabs.FixLag:AddButton({
    Title = "Boost FPS",
    Description = "ลดกราฟิกและลบส่วนไม่จำเป็นเพื่อเพิ่มความลื่น",
    Callback = function()
        local p = game.Players.LocalPlayer
        local lighting = game:GetService("Lighting")
        pcall(function()
            lighting.GlobalShadows = false
            lighting.Brightness = 1
            lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
            for _, v in pairs(lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("Bloom") or v:IsA("Blur") or v:IsA("Sky") then
                    v:Destroy()
                end
            end
        end)
        local function MakeItUgly(obj)
            if obj:IsDescendantOf(p.Character) then return end
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
                obj.CastShadow = false
                if obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    obj.RenderFidelity = Enum.RenderFidelity.Performance
                    obj.CollisionFidelity = Enum.CollisionFidelity.Box
                end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            end
        end
        for _, v in pairs(workspace:GetDescendants()) do
            pcall(function() MakeItUgly(v) end)
        end
        workspace.DescendantAdded:Connect(function(v)
            pcall(function() MakeItUgly(v) end)
        end)
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end
})

Tabs.Settings:AddToggle("AutoEat", {
    Title = "Auto Eat", Default = false,
    Callback = function(v)
        Env.AutoEat = v
        if v then
            task.spawn(function()
                while Env.AutoEat and CurrentID == Env.ScriptID do
                    pcall(function()
                        local pGui = Player:WaitForChild("PlayerGui")
                        local statusGui = pGui.Status.Main.Status
                        if statusGui.Hunger.Bar.Size.Y.Scale <= 0.20 or statusGui.Thirsty.Bar.Size.Y.Scale <= 0.20 then
                            local item = statusGui.Hunger.Bar.Size.Y.Scale <= 0.20 and "Bread" or "Water"
                            game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Use Item", item)
                        end
                    end)
                    task.wait(10)
                end
            end)
        end
    end 
})

-- [[ ⚡ Infinite Stamina ]]
Tabs.Settings:AddToggle("InfStamina", {
    Title = "Infinite Stamina", Default = false,
    Callback = function(v)
        Env.InfStamina = v
        if v then
            local player = game.Players.LocalPlayer
            local runService = game:GetService("RunService")
            pcall(function()
                local mainUI = player.PlayerGui:WaitForChild("Status"):WaitForChild("Main")
                local staminaFolder = mainUI:WaitForChild("Stamina")
                local immortalBar = staminaFolder:FindFirstChild("Immortal_Bar") or Instance.new("Frame")
                immortalBar.Name = "Immortal_Bar"
                immortalBar.Parent = staminaFolder
                immortalBar.Size = UDim2.new(1, 0, 1, 0)
                immortalBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                immortalBar.ZIndex = 20
                Env.StamConn = runService.RenderStepped:Connect(function()
                    if CurrentID ~= Env.ScriptID or not Env.InfStamina then
                        if Env.StamConn then Env.StamConn:Disconnect() end
                        return
                    end
                    immortalBar.Visible = true
                    if staminaFolder:FindFirstChild("Bar") then staminaFolder.Bar.Visible = false end
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        local hum = char.Humanoid
                        if hum.MoveDirection.Magnitude > 0 then
                            if hum.WalkSpeed > 16.1 then
                                hum.WalkSpeed = 22
                            elseif hum.WalkSpeed < 16 and hum.WalkSpeed > 0 then
                                hum.WalkSpeed = 16
                            end
                        end
                        char:SetAttribute("Stamina", 100)
                    end
                end)
            end)
        else
            if Env.StamConn then Env.StamConn:Disconnect() end
            pcall(function()
                if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                    Player.Character.Humanoid.WalkSpeed = 16
                end
                local staminaFolder = PlayerGui.Status.Main.Stamina
                if staminaFolder:FindFirstChild("Immortal_Bar") then staminaFolder.Immortal_Bar.Visible = false end
                if staminaFolder:FindFirstChild("Bar") then staminaFolder.Bar.Visible = true end
            end)
        end
    end 
})

Tabs.Settings:AddToggle("AntiAFK", { Title = "Anti-AFK", Default = false, Callback = function(v) Env.AntiAFK = v end })
Tabs.Settings:AddButton({
    Title = "Revive",
    Description = "กดตอนตายเท่านั้น",
    Callback = function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.Health = 0
        end 
    end 
})

-- [[ 🔄 ระบบตรวจสอบไอเทม ]]
task.spawn(function()
    while true do
        if CurrentID ~= Env.ScriptID then break end
        task.wait(Delay_CheckLoop)
        local currentJobData = FarmData[Env.SelectedFarmTargets[Env.CurrentFarmIndex]]
        if Env.AutoFarm and currentJobData and not Env.PauseUIUpdate then
            pcall(function()
                local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
                local currentCount = 0
                for _, item in pairs(body:GetChildren()) do
                    if item.Name == currentJobData.Item then
                        local amt = item.Main.Amount.Text:match("^(%d+)")
                        if amt then currentCount = tonumber(amt) break end
                    end
                end
                if currentCount >= currentJobData.Max then
                    Env.VerifyCount = Env.VerifyCount + 1
                    if Env.VerifyCount >= 3 then
                        if Env.BotStatus == "FARMING" then Env.BotStatus = "WAITING_TO_RESET" end
                        Env.VerifyCount = 0
                    end
                else
                    Env.VerifyCount = 0
                end
            end)
        end
    end
end)

-- [[ 🚜 Main Loops (ระบบฟาร์ม และการขายของ) ]]
task.spawn(function()
    while true do
        if CurrentID ~= Env.ScriptID then break end
        task.wait(0.5)
        local currentJobData = FarmData[Env.SelectedFarmTargets[Env.CurrentFarmIndex]]
        if Env.AutoFarm and currentJobData then
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and root then
                if Env.BotStatus == "CHECKING" then
                    local alreadyFull = false
                    pcall(function()
                        local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
                        for _, item in pairs(body:GetChildren()) do
                            if item.Name == currentJobData.Item then
                                local amt = item.Main.Amount.Text:match("^(%d+)")
                                if amt and tonumber(amt) >= currentJobData.Max then alreadyFull = true; break end
                            end
                        end
                    end)
                    if alreadyFull then Env.BotStatus = "SELLING_START"
                    else 
                        warpWithPermanentSeat(currentJobData.Pos, false, true)
                        if Env.AutoFarm then Env.BotStatus = "FARMING" end
                    end
                end
                if not Env.AutoFarm then PermanentStop(); continue  end
                local distanceFromSpawn = (root.Position - currentJobData.Pos.Position).Magnitude
                if Env.BotStatus == "FARMING" and distanceFromSpawn > Max_Distance_From_Spawn then
                    warpWithPermanentSeat(currentJobData.Pos, false, true)
                end
                if Env.BotStatus == "WAITING_TO_RESET" then
                    task.wait(Delay_AfterFull_BeforeReset)
                    if Env.AutoFarm then Env.BotStatus = "SELLING_START" end
                elseif Env.BotStatus == "SELLING_START" then
                    Env.BotStatus = "SELLING_IN_PROGRESS"
                    task.wait(Delay_BeforeReset)
                    if Env.AutoFarm then
                        hum.Health = 0
                        local newChar = Player.CharacterAdded:Wait()
                        local newRoot = newChar:WaitForChild("HumanoidRootPart", 20)
                        local newHum = newChar:WaitForChild("Humanoid", 20)
                        task.wait(3)
                        if Env.AutoFarm and CurrentID == Env.ScriptID then
                            newRoot.CFrame = sellCFrame
                            local walkEndTime = tick() + Delay_WalkAtMarket
                            task.spawn(function()
                                while tick() < walkEndTime and Env.AutoFarm and CurrentID == Env.ScriptID do
                                    newHum:MoveTo(newRoot.Position + (newRoot.CFrame.LookVector * 0.1))
                                    task.wait(0.1)
                                end
                            end)
                            task.wait(Delay_WalkAtMarket)
                            if Env.AutoFarm and CurrentID == Env.ScriptID then
                                local isStillHoldingItem = true
                                repeat
                                    if not Env.AutoFarm then break end
                                    pcall(function() game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Economy", currentJobData.Item, currentJobData.Max) end)
                                    local checkStart = tick()
                                    while tick() - checkStart < 1.5 do
                                        local currentCount = 0
                                        pcall(function()
                                            local body = Player.PlayerGui.Inventory.CanvasGroup.Main.Body
                                            for _, item in pairs(body:GetChildren()) do
                                                if item.Name == currentJobData.Item then
                                                    local amt = item.Main.Amount.Text:match("^(%d+)")
                                                    if amt then currentCount = tonumber(amt) end
                                                end
                                            end
                                        end)
                                        if currentCount == 0 then isStillHoldingItem = false; break end
                                        task.wait(0.3)
                                    end
                                until not isStillHoldingItem or not Env.AutoFarm or CurrentID ~= Env.ScriptID
                                task.wait(Delay_AfterSell)
                                if Env.AutoFarm then Env.BotStatus = "INIT" end
                            end
                        end
                    end
                elseif Env.BotStatus == "INIT" then
                    warpWithPermanentSeat(currentJobData.Pos, false, true)
                    if Env.AutoFarm then Env.BotStatus = "FARMING" end
                elseif Env.BotStatus == "FARMING" then
                    local targetItem = Env.CurrentFarmTargetItem
                    if not (targetItem and targetItem.Parent and targetItem:FindFirstChild("TouchTransmitter")) then
                        Env.CurrentFarmTargetItem = nil
                        targetItem = nil
                        local dist = 150
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("TouchTransmitter") and v.Parent and v.Parent:IsA("BasePart") then
                                local d = (v.Parent.Position - root.Position).Magnitude
                                if d < dist then dist = d; targetItem = v.Parent end
                            end
                        end
                        Env.CurrentFarmTargetItem = targetItem
                    end
                    if targetItem and Env.AutoFarm then hum:MoveTo(targetItem.Position) end
                end
            end
        else PermanentStop() end
    end
end)

local function CreateToggle()
    local player = game.Players.LocalPlayer
    local pgui = player:WaitForChild("PlayerGui")
    if pgui:FindFirstChild("XH_Universal_Fixed") then pgui.XH_Universal_Fixed:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "XH_Universal_Fixed"
    sg.Parent = pgui
    sg.ResetOnSpawn = false
    local btn = Instance.new("TextButton")
    btn.Parent = sg
    btn.Size = UDim2.new(0, 45, 0, 45)
    btn.Position = UDim2.new(0.02, 0, 0.15, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.Text = "E"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Draggable = true
    btn.Active = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.new(1,1,1)
    stroke.Thickness = 2
    btn.MouseButton1Click:Connect(function() pcall(function() if Window then Window:Minimize() end end) end)
end
task.spawn(CreateToggle)
InterfaceManager:SetLibrary(Library)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
Window:SelectTab(1)
Library:Notify({ Title = "Eco Hub", Content = "Loaded Fully", Duration = 5 })

-- =====================================================
-- ECO HUB FULL PATCH (Bug Fix + Smart Farm + Safe Warp)
-- =====================================================
do
    local Env = getgenv().XH
    local Player = game.Players.LocalPlayer

    if not Env then return end

    Env.SelectedFarmTargets = Env.SelectedFarmTargets or {}
    Env.CurrentFarmIndex = Env.CurrentFarmIndex or 1

    -- ==========================
    -- Smart Farm (nearest item)
    -- ==========================
    function Env.GetNearestFarmItem(root)
        local nearest = nil
        local dist = math.huge

        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("TouchTransmitter") then
                local part = v.Parent
                if part and part:IsA("BasePart") then
                    local d = (part.Position - root.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = part
                    end
                end
            end
        end

        return nearest
    end

    -- ==========================
    -- Safe Seat Warp
    -- ==========================
    function Env.SafeSeatWarp(goal)

        local char = Player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")

        if not root or not hum then return end

        if not getOrPullSeat then
            root.CFrame = goal
            return
        end

        local seat = getOrPullSeat()
        if not seat then
            root.CFrame = goal
            return
        end

        seat.Anchored = true
        seat.CFrame = root.CFrame

        pcall(function()
            seat:Sit(hum)
        end)

        task.wait(0.2)

        local distance = (goal.Position - root.Position).Magnitude
        local steps = math.clamp(math.floor(distance / 120),1,10)

        for i=1,steps do
            local lerp = root.CFrame:Lerp(goal,i/steps)
            seat.CFrame = lerp
            task.wait(0.05)
        end

        root.CFrame = goal + Vector3.new(0,2,0)

    end

    -- ==========================
    -- MultiFarm helpers
    -- ==========================
    local function getCurrentFarm()
        local name = Env.SelectedFarmTargets[Env.CurrentFarmIndex]
        if name and FarmData then
            return FarmData[name]
        end
    end

    local function nextFarm()
        Env.CurrentFarmIndex += 1
        if Env.CurrentFarmIndex > #Env.SelectedFarmTargets then
            Env.CurrentFarmIndex = 1
        end
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

    local function allFull()
        for _,name in ipairs(Env.SelectedFarmTargets) do
            local data = FarmData[name]
            if data then
                if getCount(data.Item) < data.Max then
                    return false
                end
            end
        end
        return true
    end

    local function sellAll()
        if not sellCFrame then return end
        if Env.SafeSeatWarp then
            Env.SafeSeatWarp(sellCFrame)
        end

        task.wait(Env.SellDelay or 5)

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
                    task.wait(0.5)
                until getCount(data.Item) == 0
            end
        end
    end

    -- ==========================
    -- Supervisor Loop
    -- ==========================
    task.spawn(function()

        while task.wait(1) do

            if not Env.AutoFarm then continue end
            if #Env.SelectedFarmTargets == 0 then continue end

            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if not root or not hum then continue end

            local job = getCurrentFarm()
            if not job then continue end

            local count = getCount(job.Item)

            if count >= job.Max then
                if allFull() then
                    sellAll()
                else
                    nextFarm()
                    local nextJob = getCurrentFarm()
                    if nextJob and Env.SafeSeatWarp then
                        Env.SafeSeatWarp(nextJob.Pos)
                    end
                end
            else
                local nearest = Env.GetNearestFarmItem(root)
                if nearest then
                    hum:MoveTo(nearest.Position)
                end
            end

        end

    end)

    -- ==========================
    -- Anti AFK fix
    -- ==========================
    pcall(function()
        Player.Idled:Connect(function()
            if Env.AntiAFK then
                local vu = game:GetService("VirtualUser")
                vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            end
        end)
    end)

end



-- =========================
-- 🔥 ADDON: AUTO FARM + RESPAWN SELL
-- =========================

local Config = {
    SellPosition = CFrame.new(2862.30, 16.19, 2115.02),
    MaxAmount = 60,
    DelayFarmCheck = 2,
    DelaySell = 1,
}

local FarmPos = {
    Strawberry = CFrame.new(5963.03, 48.90, -1669.50),
    Corn       = CFrame.new(5126.27, 45.23, -2333.77),
    Chilli     = CFrame.new(-636.49, 13.98, -3379.23),
    Banana     = CFrame.new(-1094.96, 128.40, 2404.25),
    Grape      = CFrame.new(5461.96, 47.30, -1208.75),
    Coconut    = CFrame.new(-2836.33, 18.67, 2199.34),
    Pork       = CFrame.new(-555.89, 56.65, 3099.75),
    Flower     = CFrame.new(-1763.48, 128.12, 1136.96),
    Wood       = CFrame.new(2331.03, 31.06, -2533.47),
    Grass      = CFrame.new(-2461.35, 73.00, -1938.21)
}

local function GetItemCount(itemName)
    local count = 0
    pcall(function()
        local body = game.Players.LocalPlayer.PlayerGui.Inventory.CanvasGroup.Main.Body
        for _, item in pairs(body:GetChildren()) do
            if item.Name == itemName then
                local amt = item.Main.Amount.Text:match("^(%d+)")
                if amt then count = tonumber(amt) end
            end
        end
    end)
    return count
end

local function Sell(itemName, amount)
    pcall(function()
        game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer(
            "fire", nil, "Economy", itemName, amount
        )
    end)
end

local function RespawnAndSell(itemName)
    local player = game.Players.LocalPlayer
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")

    if hum then hum.Health = 0 end

    local newChar = player.CharacterAdded:Wait()
    local root = newChar:WaitForChild("HumanoidRootPart")
    local newHum = newChar:WaitForChild("Humanoid")

    task.wait(3)
    root.CFrame = Config.SellPosition

    local t = tick() + 4
    task.spawn(function()
        while tick() < t do
            newHum:MoveTo(root.Position + root.CFrame.LookVector)
            task.wait(0.1)
        end
    end)

    task.wait(4)

    repeat
        Sell(itemName, Config.MaxAmount)
        task.wait(Config.DelaySell)
    until GetItemCount(itemName) <= 0
end

_G.StartAutoFarm = function(itemName)
    while true do
        teleportTo(FarmPos[itemName])
        task.wait(2)

        repeat task.wait(Config.DelayFarmCheck)
        until GetItemCount(itemName) >= Config.MaxAmount

        RespawnAndSell(itemName)
        task.wait(2)
    end
end

