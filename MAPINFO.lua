getgenv().Config = {
    ["Throw a Coin"] = {
        URL = "https://raw.githubusercontent.com/Ecohubv2/Ecohub/main/Throwacoin.lua",

        Places = {
            72042130041700,
            81335362752013,
            100875131717601,
            115681808123944
        }
    },

     ["Roll a G"] = {
         URL = "https://raw.githubusercontent.com/Ecohubv2/Test/refs/heads/main/rag.lua",
         Places = {
             123456789
         }
     }
}


local Loader = {
    Version = "2.0.0",
    Loaded = false
}

local function Log(message)
    print("[Loader] " .. message)
end

local function Warn(message)
    warn("[Loader] " .. message)
end

function Loader:GetConfig()
    local placeId = game.PlaceId

    for gameName, config in pairs(getgenv().Config) do
        if type(config) == "table" and type(config.Places) == "table" then

            for _, id in ipairs(config.Places) do
                if tonumber(id) == placeId then
                    return gameName, config
                end
            end

        end
    end

    return nil, nil
end


function Loader:Download(url)
    if type(url) ~= "string" or url == "" then
        return false, "Invalid URL"
    end

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        return false, result
    end

    if type(result) ~= "string" or result == "" then
        return false, "Empty response"
    end

    return true, result
end



function Loader:Execute(source)
    if type(loadstring) ~= "function" then
        return false, "loadstring is not available"
    end

    local success, result = pcall(function()
        local fn, compileError = loadstring(source)

        if not fn then
            error(compileError)
        end

        return fn()
    end)

    if not success then
        return false, result
    end

    return true, result
end

function Loader:Start()
    if self.Loaded then
        Warn("Loader already executed.")
        return
    end

    local placeId = game.PlaceId

    Log("================================")
    Log("        Script Loader")
    Log("        Version " .. self.Version)
    Log("================================")
    Log("PlaceId: " .. tostring(placeId))

    local gameName, config = self:GetConfig()

    if not config then
        Warn("No configuration found for this PlaceId.")
        Warn("PlaceId: " .. tostring(placeId))
        return
    end

    Log("Game: " .. gameName)
    Log("Searching script...")

    local success, source = self:Download(config.URL)

    if not success then
        Warn("Download failed!")
        Warn(tostring(source))
        return
    end

    Log("Script downloaded.")
    Log("Executing...")

    local executed, errorMessage = self:Execute(source)

    if not executed then
        Warn("Execution failed!")
        Warn(tostring(errorMessage))
        return
    end

    self.Loaded = true

    Log("================================")
    Log("        Script Loaded ✓")
    Log("================================")
end

Loader:Start()
