local PlaceId = game.PlaceId

getgenv().Config = {
    [134493152783903] = { 
        http = "https://raw.githubusercontent.com/Ecohubv2/Ecohub/refs/heads/main/LOL.lua"
    }
}

local function Load(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if success and result then
        loadstring(result)()
    end
end

local Data = getgenv().Config[PlaceId]

if Data and Data.http then
    Load(Data.http)
end
