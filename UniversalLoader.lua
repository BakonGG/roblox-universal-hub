-- UniversalLoader.lua (versão debug)
if getgenv().__MY_UNI_HUB_LOADER then return end
getgenv().__MY_UNI_HUB_LOADER = true

local BASE = "https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/main/"

local function try(url)
    print("🔎 Tentando carregar URL:", url)  -- <<< debug

    local okGet, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not okGet then
        warn("❌ Falha ao baixar URL:", url)
        return false
    end

    local okRun, err = pcall(function()
        loadstring(body)()
    end)
    if not okRun then
        warn("❌ Falha ao executar script:", err)
        return false
    end
    print("✅ Script carregado com sucesso!")
    return true
end

-- 1) tenta por PlaceId
if not try(BASE .. "games/" .. game.PlaceId .. ".lua") then
    -- 2) opcional: tenta por GameId
    if not try(BASE .. "games/" .. tostring(game.GameId) .. ".lua") then
        -- 3) fallback
        try(BASE .. "fallback.lua")
    end
end
