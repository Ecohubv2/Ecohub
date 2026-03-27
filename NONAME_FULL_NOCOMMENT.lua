getgenv().NONAME = getgenv().NONAME or {}
local Env = getgenv().NONAME

if not Env then return end

Env.ScriptID = (Env.ScriptID or 0) + 1

local CurrentID = Env.ScriptID

local player = game.Players.LocalPlayer
local Player = player
local PlayerGui = Player:WaitForChild("PlayerGui")
local runService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

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

local Delay_CheckLoop           = 1.5
local Delay_AfterFull_BeforeReset = 5
local Delay_BeforeReset           = 5
local Delay_WalkAtMarket        = 5
local Delay_AfterSell           = 5
local Delay_WarpWait            = 5
local Max_Distance_From_Spawn   = 1000
local CachedItems = {}

Env.WebhookURL = ""
Env.MoneyTrackerEnabled = false
Env.AntiAFK = false
Env.SelectedLocation = "Spawn"
Env.SelectedFarmTarget = "None"
Env.AutoFarm = false
Env.AutoEat = false
Env.InfStamina = false
Env.inf = false
Env.VerifyCount = 0
Env.BotStatus = "CHECKING"
Env.PauseUIUpdate = false
Env.MyPersonalSeat = Env.MyPersonalSeat or nil
Env.SeatFollowConnection = Env.SeatFollowConnection or nil
Env.CurrentFarmTargetItem = nil

local targetAmountToSell = 60
local sellCFrame = CFrame.new(2862.30, 16.19, 2115.02)
local spawnPos = CFrame.new(5972.32, 48.80, -1632.06)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local originalSettings = {}
local myVehicle = nil

getgenv().Env = getgenv().Env or {}

local function getMyVehicle()
    local folder = workspace:FindFirstChild("PlayerVehicle")
    if not folder then return nil end

    for _, v in ipairs(folder:GetChildren()) do
        if v:GetAttribute("Owner") == player.Name then
            return v
        end
    end

    return nil
end

local function getVehicleSettings()
    if not myVehicle then return nil end
    return myVehicle:FindFirstChild("Settings")
end

local function saveOriginal(settings)
    if settings then
        originalSettings = {}
        for name, value in pairs(settings:GetAttributes()) do
            originalSettings[name] = value
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        local newVehicle = getMyVehicle()

        if newVehicle ~= myVehicle then
            myVehicle = newVehicle

            local settings = getVehicleSettings()
            saveOriginal(settings)
        end
    end
end)

local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if checkcaller() then
        return old(self, ...)
    end

    if Env.inf and myVehicle and self == myVehicle and method == "GetAttribute" then
        local attr = args[1]

        if attr == "Health" then
            return 999
        elseif attr == "Fuel" then
            return 999
        end
    end

    return old(self, ...)
end))


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

local function teleportTo(cframe)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

local function PermanentStop()
    
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

local function getOrPullSeat()
    if Env.MyPersonalSeat and Env.MyPersonalSeat.Parent and Env.MyPersonalSeat:IsA("Seat") then
        return Env.MyPersonalSeat
    end
    
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
                    Env.MyPersonalSeat = v
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

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local request_func = request or (http and http.request) or http_request or (syn and syn.request) or (fluxus and fluxus.request)



local checkIntervalMinutes = 30
local checkIntervalSeconds = checkIntervalMinutes * 60

local function formatNumber(num)
    num = tonumber(num) or 0
    local str = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (str:sub(1,1) == ",") and str:sub(2) or str
end

local function safeFind(parent, name)
    if not parent then return nil end
    return parent:FindFirstChild(name)
end

local function getMoney()
    local gui = safeFind(Player, "PlayerGui")
    gui = safeFind(gui, "Inventory")
    gui = safeFind(gui, "CanvasGroup")
    gui = safeFind(gui, "Main")
    gui = safeFind(gui, "Body")
    gui = safeFind(gui, "Cash")
    gui = safeFind(gui, "Main")
    gui = safeFind(gui, "Amount")

    if not gui then return 0 end

    for i = 1, 10 do
        local success, text = pcall(function()
            return gui.Text
        end)

        if success and typeof(text) == "string" and text ~= "" then
            local clean = text:gsub("[^%d]", "")
            if clean == "" then
                return 0
            end
            return tonumber(clean) or 0
        end

        task.wait(0.3)
    end

    return 0
end

local function notifyTotalMoney()
    if not request_func then return end
    if Env.WebhookURL == "" then return end

    local success, err = pcall(function()
        local money = getMoney()

        local utc_time = os.time()
        local local_time = utc_time + 7*3600
        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", local_time)

        local data = {
            ["embeds"] = {{
                ["title"] = "💰 เงินทั้งหมดของผู้เล่น",
                ["description"] = string.format(
                    "👤 Player: **%s**\n💵 Total Money: **%s**",
                    Player.Name,
                    formatNumber(money)
                ),
                ["color"] = 16776960,
                ["footer"] = {
                    ["text"] = "Money Tracker | "..os.date("%d/%m/%Y %H:%M:%S", local_time)
                },
                ["timestamp"] = timestamp
            }}
        }

        request_func({
            Url = Env.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not success then
        warn("Webhook Error:", err)
    end
end

task.spawn(function()
    local elapsed = 0

    while CurrentID == Env.ScriptID do
        task.wait(1)

        if Env.MoneyTrackerEnabled then
            elapsed = elapsed + 1

            if elapsed >= checkIntervalSeconds then
                elapsed = 0
                notifyTotalMoney()
            end
        else
            elapsed = 0
        end
    end
end)
task.spawn(function()
    while task.wait(5) do
        if Env.BotStatus == "SELLING_IN_PROGRESS" then
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                local dist = (root.Position - sellCFrame.Position).Magnitude

                if dist > 50 then
                    warpWithPermanentSeat(sellCFrame, true, false)
                end
            end
        end
    end
end)
task.spawn(function()
    while task.wait(30) do
        if CurrentID ~= Env.ScriptID then break end

        if Env and Env.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new())
            end)
        end
    end
end)

local WindowSize = UIS.TouchEnabled and UDim2.fromOffset(450, 320) or UDim2.fromOffset(580, 460)

local Window = Library:CreateWindow({
    Title = "ΝONAME HUB | SomeTown ",
    SubTitle = "Permanent Edition",
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
    Car = Window:AddTab({ Title = "Car", Icon = "car" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Other = Window:AddTab({ Title = "Other", Icon = "monitor" }),
    
}


Tabs.Farm:AddDropdown("SelectFarmTarget", {
    Title = "Select Farm Target",
    Values = {"Strawberry", "Corn", "Chilli", "Banana", "Grape", "Coconut", "Pork", "Flower", "Wood", "Grass"},
    Default = "None",
    Callback = function(Value)
        Env.SelectedFarmTarget = Value
        Env.BotStatus = "CHECKING"
        Env.CurrentFarmTargetItem = nil
        if Env.AutoFarm then
            task.spawn(function() task.wait(0.1); smartRun() end)
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

Tabs.Settings:AddButton({
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

Tabs.Settings:AddButton({
    Title = "Revive",
    Description = "กดตอนตายเท่านั้น",
    Callback = function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.Health = 0
        end 
    end 
})

Tabs.Settings:AddToggle("AutoEat", {
    Title = "Auto Eat", Default = false,
    Callback = function(v)
        Env.AutoEat = v
        if v then
            task.spawn(function()
                while Env.AutoEat and CurrentID == Env.ScriptID do
                    if not Player or not Player.Parent then break end
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

Tabs.Settings:AddToggle("InfStamina", {
    Title = "Infinite Stamina", Default = false,
    Callback = function(v)
        Env.InfStamina = v
        if v then
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
                local PlayerGui = player:WaitForChild("PlayerGui")
local staminaFolder = PlayerGui.Status.Main.Stamina
                if staminaFolder:FindFirstChild("Immortal_Bar") then staminaFolder.Immortal_Bar.Visible = false end
                if staminaFolder:FindFirstChild("Bar") then staminaFolder.Bar.Visible = true end
            end)
        end
    end 
})

Tabs.Settings:AddToggle("AntiAFK", { Title = "Anti-AFK", Default = false, Callback = function(v) Env.AntiAFK = v end })


task.spawn(function()
    while true do
        if CurrentID ~= Env.ScriptID then break end
        task.wait(Delay_CheckLoop)
        local currentJobData = FarmData[Env.SelectedFarmTarget]
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

task.spawn(function()
    while true do
        if CurrentID ~= Env.ScriptID then break end
        task.wait(0.5)
        local currentJobData = FarmData[Env.SelectedFarmTarget]
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
                if not Env.AutoFarm then PermanentStop(); continue end
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
                        task.wait(1.5)
                        
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
Tabs.Farm:AddSection("Mine")

Env.AutoMine = false

Env.DelayMine = 1.5
Env.DelayWarp = 5
Env.DelayProcess = 5
Env.DelayWaitEmpty = 5
Env.DelayRespawn = 5
Env.DelaySell = 5

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Remote = ReplicatedStorage
    :WaitForChild("Modules")
    :WaitForChild("NetworkFramework")
    :WaitForChild("NetworkEvent")

local function fireRemote(...)
    pcall(function()
        Remote:FireServer(...)
    end)
end

local function equipPickaxe()
    fireRemote("fire", nil, "Tools", "Pickaxe")
end

local function getCharacter()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)

    if not (char and hum and root and hum.Health > 0) then
        return nil
    end

    return char, hum, root
end

local function getRockAmount()
    local cur, max = 0, 0

    pcall(function()
        local txt = Player.PlayerGui.Inventory.CanvasGroup.Main.Body.Rock.Main.Amount.Text
        local a, b = txt:match("(%d+)%s*/%s*(%d+)")
        if a and b then
            cur = tonumber(a)
            max = tonumber(b)
        end
    end)

    return cur or 0, max or 0
end

local function usePickaxe()
    fireRemote("fire", nil, "Tools", "Pickaxe")
end

local function processRock()
    fireRemote("fire", nil, "Process", "Rock")
end

local function sellFragments(amount)
    fireRemote("fire", nil, "Economy", "Rockfragments", amount)
end

local function resetCharacter()
    local char, hum = getCharacter()
    if hum then
        hum.Health = 0
    end
end

Tabs.Farm:AddToggle("AutoMine", {
    Title = "Auto Mine",
    Default = false,
    Callback = function(v)
        Env.AutoMine = v

        if v then
            equipPickaxe()

            task.spawn(function()
                while Env.AutoMine do
                    task.wait(Env.DelayMine)

                    local char, hum, root = getCharacter()
                    if not char then continue end

                    local cur, max = getRockAmount()

                    if cur < max then
                        warpWithPermanentSeat(rockPos, false, true)
                        task.wait(Env.DelayWarp)

                        usePickaxe()

                    else
                        warpWithPermanentSeat(processPos, true, false)
                        task.wait(Env.DelayProcess)

                        processRock()

                        repeat
                            task.wait(Env.DelayWaitEmpty)
                            cur = select(1, getRockAmount())
                        until cur == 0 or not Env.AutoMine

                        local fragments = 0

                        repeat
                            task.wait(0.5)
                            fragments = Player:GetAttribute("Rockfragments") or 0
                        until fragments > 0 or not Env.AutoMine

                        if fragments > 0 then
                            resetCharacter()

                            local newChar = Player.CharacterAdded:Wait()
                            local newHum = newChar:WaitForChild("Humanoid", 5)
                            local newRoot = newChar:WaitForChild("HumanoidRootPart", 5)

                            if not (newChar and newHum and newRoot) then continue end

                            repeat task.wait()
                            until newHum.Health > 0

                            task.wait(Env.DelayRespawn)

                            equipPickaxe()

                            newRoot.CFrame = sellCFrame
                            task.wait(Env.DelaySell)

                            sellFragments(fragments)

                            task.wait(Env.DelaySell)
                        end

                        warpWithPermanentSeat(rockPos, false, true)
                    end
                end
            end)
        end
    end
})

Tabs.Farm:AddToggle("AutoMine", {
    Title = "Auto Mine",
    Default = false,
    Callback = function(v)
        Env.AutoMine = v
    end
})

Env.AutoFish = false

Env.DelayAfterReset = 4
Env.DelayAfterSell = 5
Env.DelayAfterBuy = 4
Env.DelayBeforeNextLoop = 5
Env.DelayFishingCheck = 5
Env.DelayBetweenItems = 1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Remote = ReplicatedStorage
    :WaitForChild("Modules")
    :WaitForChild("NetworkFramework")
    :WaitForChild("NetworkEvent")

local baitShop = CFrame.new(3000.26025, 14.6258106, 2278.10205, 0.867425501, 1.18460228e-07, -0.497567087, -1.22624328e-07, 1, 2.43037732e-08, 0.497567087, 3.99321181e-08, 0.867425501)

local fishSpot = CFrame.new(2345.66235, 9.31522369, 3845.95898, -0.796783566, -2.56285499e-08, -0.604264796, -6.02654495e-08, 1, 3.7053244e-08, 0.604264796, 6.59397017e-08, -0.796783566)

local sellPos = CFrame.new(2862.30, 16.19, 2115.02)

local function getCharacter()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)

    if not (char and hum and root and hum.Health > 0) then
        return nil
    end

    return char, hum, root
end

local function getItemAmount(itemName)
    local amount = 0

    pcall(function()
        local body = Player:WaitForChild("PlayerGui", 5)
            :WaitForChild("Inventory", 5)
            :WaitForChild("CanvasGroup", 5)
            :WaitForChild("Main", 5)
            :WaitForChild("Body", 5)

        local item = body:FindFirstChild(itemName)
        if not item then return end

        local txtObj = item:FindFirstChild("Main") and item.Main:FindFirstChild("Amount")
        if not txtObj then return end

        local txt = txtObj.Text
        local num = txt:match("^(%d+)")
        if num then amount = tonumber(num) end
    end)

    return amount or 0
end

local function getBaitAmount()
    return getItemAmount("Bait")
end

local function fireRemote(...)
    pcall(function()
        Remote:FireServer(...)
    end)
end

local function buyBait()
    warpWithPermanentSeat(baitShop, true, false)
    task.wait(Env.DelayAfterBuy)
    fireRemote("fire", nil, "Supermarket", "Bait", 150)
    task.wait(Env.DelayAfterBuy)
end

local function startFishing()
    fireRemote("fire", nil, "AutoFishing")
end

local function sellAll()
    warpWithPermanentSeat(sellPos, true, false)
    task.wait(Env.DelayAfterSell)

    local items = {
        "Fish","Crab","Stingray","Squid","Shark","Dolphin"
    }

    for _, item in pairs(items) do
        local amount = getItemAmount(item)

        if amount and amount > 0 then
            fireRemote("fire", nil, "Economy", item, amount)
            task.wait(Env.DelayBetweenItems)
        end
    end

    task.wait(Env.DelayAfterSell)
end

local function resetCharacter()
    local char, hum = getCharacter()
    if hum then
        hum.Health = 0
    end
end

task.spawn(function()
    while task.wait(Env.DelayFishingCheck) do
        if not Env.AutoFish then continue end

        local char, hum, root = getCharacter()
        if not char then continue end

        local bait = getBaitAmount()

        if bait <= 0 then
            resetCharacter()

            local newChar = Player.CharacterAdded:Wait()
            local newHum = newChar:WaitForChild("Humanoid", 5)
            local newRoot = newChar:WaitForChild("HumanoidRootPart", 5)

            if not (newChar and newHum and newRoot) then continue end

            repeat task.wait()
            until newHum.Health > 0

            task.wait(Env.DelayAfterReset)

            sellAll()
            buyBait()

            task.wait(Env.DelayBeforeNextLoop)
            continue
        end

        warpWithPermanentSeat(fishSpot, true, false)
        task.wait(1)

        startFishing()

        repeat
            task.wait(Env.DelayFishingCheck)
            bait = getBaitAmount()
        until bait <= 0 or not Env.AutoFish
    end
end)

Tabs.Farm:AddSection("Auto Fish")

Tabs.Farm:AddToggle("AutoFish", {
    Title = "Auto Fish",
    Default = false,
    Callback = function(v)
        Env.AutoFish = v
    end
})

Tabs.Car:AddToggle("inf", {
    Title = "Inf Fuel & Health",
    Default = false,
    Callback = function(v)
        Env.inf = v
    end
})

Tabs.Car:AddInput("MaxSpeedInput", {
    Title = "MaxSpeed",
    Default = "",
    Numeric = true,
    Finished = true,

    Callback = function(Value)
        local num = tonumber(Value)
        if not num then return end

        local settings = getVehicleSettings()
        if settings then
            settings:SetAttribute("MaxSpeed", num)
        end
    end
})

Tabs.Car:AddButton({
    Title = "Reset Settings",
    Description = "รีค่ารถกลับค่าเดิม",
    Callback = function()
        local settings = getVehicleSettings()
        if settings then
            for name, value in pairs(originalSettings) do
                settings:SetAttribute(name, value)
            end
        end
    end
})

local function CreateToggle()
    
    local pgui = player:WaitForChild("PlayerGui")
    if pgui:FindFirstChild("NONAME") then pgui.NONAME:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "NONAME"
    sg.Parent = pgui
    sg.ResetOnSpawn = false
    local btn = Instance.new("TextButton")
    btn.Parent = sg
    btn.Size = UDim2.new(0, 45, 0, 45)
    btn.Position = UDim2.new(0.02, 0, 0.15, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.Text = "NN"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
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
InterfaceManager:BuildInterfaceSection(Tabs.Other)
Window:SelectTab(1)
Library:Notify({ Title = "NONAME HUB", Content = "Loaded Fully", Duration = 5 })
