local MarketplaceService = game:GetService("MarketplaceService")
local PlaceId = game.PlaceId
local GameName = MarketplaceService:GetProductInfo(PlaceId).Name

getgenv().Config = {
    [134493152783903] = {
        http = "https://raw.githubusercontent.com/Ecohubv2/Ecohub/main/LOL.lua"
    }
}

local function Load(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("HttpGet Error:", result)
        return false
    end

    local runSuccess, runError = pcall(function()
        loadstring(result)()
    end)

    if not runSuccess then
        warn("Loadstring Error:", runError)
        return false
    end

    return true
end

local Data = getgenv().Config[PlaceId] or getgenv().Config[GameName]

if Data and Data.http then
    print("Loading for:", GameName)
    Load(Data.http)
else
    warn("ไม่พบ config สำหรับเกมนี้")
    warn("PlaceId:", PlaceId)
    warn("GameName:", GameName)
end
