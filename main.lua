-- Universal Script
-- Autor: Você
-- Projeto: Script Universal para vários jogos
-- GitHub ready ✅

-- Console Header
print("=======================================")
print("🔄 Iniciando Script Universal...")
print("=======================================")

-- Obter ID do jogo
local gameId = game.PlaceId or game.GameId
print("[INFO] Jogo detectado! GameId: " .. tostring(gameId))

-- Função para carregar scripts
local function loadScript(id)
    local success, result = pcall(function()
        local path = "games/" .. tostring(id) .. ".lua"
        local scriptFile = isfile and readfile(path) or nil

        if scriptFile then
            print("[INFO] Script encontrado para o jogo " .. id .. " ✅")
            return loadstring(scriptFile)()
        else
            print("[WARN] Nenhum script encontrado para este jogo (" .. id .. ") ❌")
            local defaultPath = "games/default.lua"
            if isfile and isfile(defaultPath) then
                print("[INFO] Carregando script padrão...")
                return loadstring(readfile(defaultPath))()
            end
        end
    end)

    if not success then
        warn("[ERRO] Falha ao carregar o script do jogo: " .. tostring(result))
    end
end

-- Executa
loadScript(gameId)

print("=======================================")
print("✅ Script Universal finalizado")
print("=======================================")
