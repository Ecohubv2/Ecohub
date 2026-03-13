-- XH ULTRA V3 (Optimized Example)
-- Systems: Fast AutoFarm, Smart Item Finder, Instant Teleport, FPS Boost, Anti Kick

getgenv().XH = getgenv().XH or {}
local Env = getgenv().XH

Env.ScriptID = (Env.ScriptID or 0) + 1
local CurrentID = Env.ScriptID

Env.AutoFarm = false

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--====================
-- Anti Kick
--====================
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt,false)

    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self,...)
        local method = getnamecallmethod()

        if method == "Kick" then
            return
        end

        return old(self,...)
    end)
end)

--====================
-- Anti AFK
--====================
LocalPlayer.Idled:Connect(function()
    local vu = game:GetService("VirtualUser")
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

--====================
-- Character Helper
--====================
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

--====================
-- Instant Teleport
--====================
local function instantTP(cf)
    local char = getChar()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cf + Vector3.new(0,3,0)
        root.Velocity = Vector3.zero
    end
end

--====================
-- Fast Tween Teleport
--====================
local function fastTP(cf)
    local char = getChar()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = (root.Position - cf.Position).Magnitude
    local time = math.clamp(dist / 250,0.05,0.3)

    local tween = TweenService:Create(
        root,
        TweenInfo.new(time,Enum.EasingStyle.Linear),
        {CFrame = cf}
    )

    tween:Play()
end

--====================
-- Smart Item Finder
--====================
local function getNearestItem()
    local char = getChar()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local nearest = nil
    local distance = math.huge

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("TouchTransmitter") and v.Parent:IsA("BasePart") then

            local d = (v.Parent.Position - root.Position).Magnitude

            if d < distance then
                distance = d
                nearest = v.Parent
            end

        end
    end

    return nearest
end

--====================
-- FPS Boost
--====================
local function boostFPS()

    local lighting = game:GetService("Lighting")

    lighting.GlobalShadows = false
    lighting.FogEnd = 100000
    lighting.Brightness = 2

    for _,v in pairs(workspace:GetDescendants()) do

        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false

        elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()

        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end

    end

    settings().Rendering.QualityLevel = 1

end

--====================
-- AutoFarm Loop
--====================
task.spawn(function()

    while task.wait(0.1) do

        if CurrentID ~= Env.ScriptID then
            break
        end

        if Env.AutoFarm then

            local item = getNearestItem()

            if item then
                fastTP(item.CFrame)
            end

        end

    end

end)

--====================
-- Enable Systems
--====================
boostFPS()

print("XH ULTRA V3 Loaded")
