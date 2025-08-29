-- 🌐 Universal Script Loader
-- Criado por BakonGG

-- Configurações do repositório
local repo = "https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/main/games/"
local fallback = "https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/main/fallback.lua"

-- Função para carregar script remoto
local function loadScript(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local runSuccess, err = pcall(function()
            loadstring(result)()
        end)
        if runSuccess then
            warn("✅ Script carregado de:", url)
        else
            warn("⚠️ Erro ao executar script:", err)
        end
        return runSuccess
    else
        warn("❌ Falha ao baixar URL:", url)
        return false
    end
end

-- Detectar jogo
local placeId = game.PlaceId
print("🕹️ PlaceId detectado:", placeId)

-- Montar URL do jogo
local gameUrl = repo .. placeId .. ".lua"

-- Tentar carregar script específico
if not loadScript(gameUrl) then
    warn("ℹ️ Nenhum script específico encontrado para este jogo. Carregando fallback...")
    loadScript(fallback)
end
