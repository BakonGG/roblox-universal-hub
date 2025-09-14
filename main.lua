-- main.lua
-- Universal Script (GitHub raw loader)
-- Ajuste BASE_RAW_URL para apontar para o diretório raw do GitHub onde os arquivos `games/*.lua` estão.

local function log(...) print("[UNIVERSAL]", ...) end
local function warnlog(...) warn("[UNIVERSAL]", ...) end

log("=======================================")
log("🔄 Iniciando Universal Script...")
log("=======================================")

-- Detecta GameId (robusto)
local gameId = nil
pcall(function() gameId = game.PlaceId end)
if not gameId then
    pcall(function() gameId = game.GameId end)
end
if not gameId then
    warnlog("Não foi possível detectar PlaceId/GameId. Abortando.")
    return
end

log("[INFO] Jogo detectado! GameId:", tostring(gameId))

-- CONFIG: altere para seu repositório raw no GitHub (pasta 'games/')
local BASE_RAW_URL = "https://github.com/BakonGG/roblox-universal-hub/blob/main/main.lua"

-- URLs
local scriptURL = BASE_RAW_URL .. tostring(gameId) .. ".lua"
local defaultURL = BASE_RAW_URL .. "default.lua"

-- Função para tentar carregar código remoto
local function fetchAndRun(url, description)
    log("[INFO] Tentando baixar:", description, url)
    if not (type(game) == "table" and type(game.HttpGet) == "function") then
        -- alguns ambientes expõem game:HttpGet, outros usam http_request ou syn.request; tentamos várias opções
        local got = nil
        local ok, res = pcall(function()
            if _G and type(_G.syn) == "table" and type(syn.request) == "function" then
                return syn.request({Url = url, Method = "GET"}).Body
            elseif type(http_request) == "function" then
                return http_request({Url = url, Method = "GET"}).Body
            elseif type(request) == "function" then
                return request({Url = url, Method = "GET"}).Body
            else
                error("Nenhum método http detectado (game:HttpGet / request / http_request / syn.request).")
            end
        end)
        if not ok then
            warnlog("[ERRO] Falha ao buscar (método alternativo):", tostring(res))
            return false, res
        end
        got = res
        if not got or #got < 10 or got:match("Not Found") then
            warnlog("[WARN] Conteúdo parece inválido ou não encontrado.")
            return false, "notfound"
        end
        local ok2, res2 = pcall(function() local f = loadstring(got); return f and f() end)
        if not ok2 then
            warnlog("[ERRO] Falha ao executar script baixado:", tostring(res2))
            return false, res2
        end
        log("[OK] Script remoto executado com sucesso: ", description)
        return true, nil
    end

    -- método padrão: game:HttpGet
    local ok, bodyOrErr = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        warnlog("[ERRO] game:HttpGet falhou:", tostring(bodyOrErr))
        return false, bodyOrErr
    end

    if not bodyOrErr or #bodyOrErr < 10 or bodyOrErr:match("Not Found") then
        warnlog("[WARN] Resposta HTTP vazia ou 404 (Not Found).")
        return false, "notfound"
    end

    -- Tenta executar
    local ok2, execErr = pcall(function()
        local fn, loadErr = loadstring(bodyOrErr)
        if not fn then error("loadstring falhou: " .. tostring(loadErr)) end
        return fn()
    end)

    if not ok2 then
        warnlog("[ERRO] Falha ao executar script baixado:", tostring(execErr))
        return false, execErr
    end

    log("[OK] Script remoto executado com sucesso:", description)
    return true, nil
end

-- Tenta carregar o script específico do jogo
local ok, err = fetchAndRun(scriptURL, "games/" .. tostring(gameId) .. ".lua")
if not ok then
    log("[INFO] Tentando carregar script padrão (default.lua)...")
    local ok2, err2 = fetchAndRun(defaultURL, "games/default.lua")
    if not ok2 then
        warnlog("[ERRO] Não foi possível carregar nem o script do jogo nem o default. Verifique BASE_RAW_URL e se os arquivos existem no GitHub.")
    end
end

log("=======================================")
log("✅ Script Universal finalizado")
log("=======================================")
