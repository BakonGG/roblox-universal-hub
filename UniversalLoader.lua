-- UniversalLoader.lua
local HttpService = game:GetService("HttpService")
local PlaceId = tostring(game.PlaceId)

local base = "https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/main/"
local gamelistUrl = base .. "gamelist.json?nocache=" .. tick()

-- Função segura para pegar conteúdo
local function safeGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok then return result end
    warn("Erro ao baixar:", url, result)
    return nil
end

-- Pegar lista de jogos
local gamelistRaw = safeGet(gamelistUrl)
local gamelist = {}
if gamelistRaw then
    gamelist = HttpService:JSONDecode(gamelistRaw)
end

-- Função para carregar script de um jogo
local function loadGameScript(pid)
    local url = base .. "games/" .. pid .. ".lua?nocache=" .. tick()
    local script = safeGet(url)
    if script then
        loadstring(script)()
        return true
    end
    return false
end

-- Primeiro tenta detectar automaticamente
if gamelist[PlaceId] then
    print("✅ Detectado jogo:", gamelist[PlaceId])
    if not loadGameScript(PlaceId) then
        warn("⚠️ Script não encontrado para:", PlaceId)
    end
else
    -- Se não detectar → abrir Hub inicial
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/main/shadowlib.lua"))()
    local Window = Library:CreateWindow("Universal Hub")

    local Tab = Window:CreateTab("Escolha um Jogo")

    for pid, name in pairs(gamelist) do
        Tab:CreateButton(name, function()
            Library:Close() -- fecha o menu inicial
            loadGameScript(pid)
        end)
    end

    Tab:CreateLabel("Nenhum jogo detectado automaticamente.")
end
