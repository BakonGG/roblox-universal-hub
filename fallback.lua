local HttpService = game:GetService("HttpService")
local PlaceId = game.PlaceId

local branches = { "main", "master" }
local repo = "https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/%s/games/%s.lua"
local fallback = "https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/%s/fallback.lua"

local function tryLoad(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok then
        loadstring(result)()
        print("✅ Script carregado de:", url)
        return true
    else
        warn("⚠️ Falha ao baixar:", url, result)
        return false
    end
end

local loaded = false
for _, branch in ipairs(branches) do
    local url = string.format(repo, branch, PlaceId) .. "?nocache=" .. tick()
    if tryLoad(url) then
        loaded = true
        break
    end
end

if not loaded then
    for _, branch in ipairs(branches) do
        local url = string.format(fallback, branch) .. "?nocache=" .. tick()
        if tryLoad(url) then break end
    end
end
