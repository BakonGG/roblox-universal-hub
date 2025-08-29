-- games/82912499835188.lua
-- Script do jogo (robusto, com UI, AutoCollect, AutoSell + Teleport)
-- Coloque este arquivo em: /games/82912499835188.lua

-- Proteção para não reiniciar tudo se o script for re-executado
if getgenv().__BAKONGG_GAME_82912499835188_LOADED then
    warn("[BakonGG] Script do jogo já carregado — evitando duplicar processos.")
    return
end
getgenv().__BAKONGG_GAME_82912499835188_LOADED = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Flags globais (permitem controlar entre execuções)
getgenv().Bakon_AutoCollect = getgenv().Bakon_AutoCollect or false
getgenv().Bakon_AutoSell = getgenv().Bakon_AutoSell or false

-- Guardas para iniciar loops apenas 1 vez
if getgenv().__Bakon_CollectLoopStarted == nil then getgenv().__Bakon_CollectLoopStarted = false end
if getgenv().__Bakon_SellLoopStarted == nil then getgenv().__Bakon_SellLoopStarted = false end
if getgenv().__Bakon_TeleportLoopStarted == nil then getgenv().__Bakon_TeleportLoopStarted = false end

-- util: dispara ProximityPrompt/ClickDetector de forma segura
local function safeActivatePrompt(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("ProximityPrompt") then
            fireproximityprompt(obj)
        elseif obj:IsA("ClickDetector") then
            fireclickdetector(obj)
        end
    end)
end

-- util: busca a referência do evento de venda com segurança
local function getSellRequest()
    local ok, client = pcall(function()
        return ReplicatedStorage:WaitForChild("Events", 2):WaitForChild("Client", 2)
    end)
    if not ok or not client then return nil end

    local ok2, sellFolder = pcall(function()
        return client:FindFirstChild("Sell")
    end)
    if not ok2 or not sellFolder then return nil end

    return sellFolder:FindFirstChild("SellRequest")
end

-- Encontrar o sellPart (index 54 conforme informado); tenta com segurança
local function findSellPart()
    local ok, sellRoot = pcall(function() return workspace:FindFirstChild("Shops") and workspace.Shops:FindFirstChild("Sell") end)
    if not ok or not sellRoot then return nil end
    local children = sellRoot:GetChildren()
    return children[54] -- pode ser nil se não existir
end

local vendPart = findSellPart()

-- COLETAR: percorre todos os plots e ativa CollectPrompt
local function startAutoCollectLoop()
    if getgenv().__Bakon_CollectLoopStarted then return end
    getgenv().__Bakon_CollectLoopStarted = true

    spawn(function()
        while true do
            if getgenv().Bakon_AutoCollect then
                local plots = workspace:FindFirstChild("Plots")
                if plots then
                    for _, plot in ipairs(plots:GetChildren()) do
                        local generators = plot:FindFirstChild("Generators")
                        if generators then
                            for _, gen in ipairs(generators:GetChildren()) do
                                local prompt = gen:FindFirstChild("CollectPrompt")
                                if prompt then
                                    safeActivatePrompt(prompt)
                                end
                            end
                        end
                    end
                end
                -- curto intervalo para não travar; Heartbeat é responsivo
                RunService.Heartbeat:Wait()
            else
                task.wait(0.25)
            end
        end
    end)
end

-- VENDER: envia SellRequest a cada 1s
local function startAutoSellLoop()
    if getgenv().__Bakon_SellLoopStarted then return end
    getgenv().__Bakon_SellLoopStarted = true

    spawn(function()
        local sellReq
        while true do
            if getgenv().Bakon_AutoSell then
                sellReq = sellReq or getSellRequest()
                if sellReq then
                    pcall(function() sellReq:InvokeServer(true) end)
                else
                    -- tenta recuperar nas próximas iterações
                    sellReq = getSellRequest()
                end
            end
            task.wait(1)
        end
    end)
end

-- TELEPORT: teleporta para vendPart a cada 30s e volta
local function startTeleportLoop()
    if getgenv().__Bakon_TeleportLoopStarted then return end
    getgenv().__Bakon_TeleportLoopStarted = true

    spawn(function()
        while true do
            task.wait(30)
            if getgenv().Bakon_AutoSell then
                -- atualiza vendPart caso tenha mudado
                vendPart = vendPart or findSellPart()
                if vendPart and vendPart:IsA("BasePart") then
                    pcall(function()
                        local char = player.Character or player.CharacterAdded:Wait()
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local old = hrp.CFrame
                            hrp.CFrame = vendPart.CFrame + Vector3.new(0, 5, 0)
                            task.wait(1.5)
                            -- volta (verifica se ainda existe)
                            if hrp and old then
                                hrp.CFrame = old
                            end
                        end
                    end)
                end
            end
        end
    end)
end

-- UI: tenta carregar Shadow Lib, se falhar cria GUI simples
local function createFallbackGUI()
    -- Remove GUI antiga se existir
    if player:FindFirstChild("PlayerGui") then
        local existing = player.PlayerGui:FindFirstChild("BakonGG_SimpleUI")
        if existing then existing:Destroy() end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BakonGG_SimpleUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local function makeButton(text, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 200, 0, 40)
        b.Position = UDim2.new(0.85, 0, y, 0)
        b.AnchorPoint = Vector2.new(0.5, 0)
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b.BorderSizePixel = 0
        b.TextColor3 = Color3.new(1,1,1)
        b.TextScaled = true
        b.Font = Enum.Font.SourceSansBold
        b.Text = text
        b.Parent = screenGui
        return b
    end

    local collectBtn = makeButton("Auto Collect: OFF", 0.66)
    local sellBtn = makeButton("Auto Sell: OFF", 0.73)

    collectBtn.MouseButton1Click:Connect(function()
        getgenv().Bakon_AutoCollect = not getgenv().Bakon_AutoCollect
        collectBtn.Text = "Auto Collect: " .. (getgenv().Bakon_AutoCollect and "ON" or "OFF")
        print("[BakonGG] Auto Collect:", getgenv().Bakon_AutoCollect and "ON" or "OFF")
    end)

    sellBtn.MouseButton1Click:Connect(function()
        getgenv().Bakon_AutoSell = not getgenv().Bakon_AutoSell
        sellBtn.Text = "Auto Sell: " .. (getgenv().Bakon_AutoSell and "ON" or "OFF")
        print("[BakonGG] Auto Sell:", getgenv().Bakon_AutoSell and "ON" or "OFF")
    end)
end

local function tryLoadShadowLib()
    local urls = {
        "https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/main/Shadow%20Lib.txt",
        "https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/main/shadowlib.lua",
        "https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/main/Shadow Lib.txt",
    }
    for _, url in ipairs(urls) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url, true))()
        end)
        if ok and lib then
            return lib
        end
    end
    return nil
end

-- Cria a UI (usa Shadow Lib se disponível; se não, fallback)
local function createUI()
    local lib = tryLoadShadowLib()
    if lib then
        -- tentativa de adaptação à API da Shadow Lib (vários forks usam nomes diferentes)
        local success, winOrErr = pcall(function()
            -- formas possíveis de criar janela em diferentes versões
            local win
            if lib.Window then
                win = lib:Window("Bakon Hub", Color3.fromRGB(44,120,224), Enum.KeyCode.RightControl)
            elseif lib.CreateWindow then
                win = lib.CreateWindow("Bakon Hub")
            elseif lib:CreateWindow then
                win = lib:CreateWindow("Bakon Hub")
            else
                error("API desconhecida da Shadow Lib")
            end

            -- método de criar abas/toggles — tentamos várias convenções
            local tab
            if win.Tab then
                tab = win:Tab("Farm")
            elseif win:Tab then
                tab = win:Tab("Farm")
            elseif win.CreateTab then
                tab = win.CreateTab("Farm")
            end

            -- Se não encontrou tab, apenas cria botões básicos via fallback
            if not tab then error("Não foi possível criar Tab na Shadow Lib") end

            -- Toggle Auto Collect
            if tab.Toggle then
                tab:Toggle("Auto Collect (todos os Plots)", getgenv().Bakon_AutoCollect, function(state)
                    getgenv().Bakon_AutoCollect = state
                    print("[BakonGG] Auto Collect:", state and "ON" or "OFF")
                end)
            elseif tab.toggle then
                tab:toggle("Auto Collect (todos os Plots)", getgenv().Bakon_AutoCollect, function(state)
                    getgenv().Bakon_AutoCollect = state
                    print("[BakonGG] Auto Collect:", state and "ON" or "OFF")
                end)
            else
                error("API de toggle não encontrada")
            end

            -- Toggle Auto Sell
            if tab.Toggle then
                tab:Toggle("Auto Sell + Teleport (30s)", getgenv().Bakon_AutoSell, function(state)
                    getgenv().Bakon_AutoSell = state
                    print("[BakonGG] Auto Sell:", state and "ON" or "OFF")
                end)
            elseif tab.toggle then
                tab:toggle("Auto Sell + Teleport (30s)", getgenv().Bakon_AutoSell, function(state)
                    getgenv().Bakon_AutoSell = state
                    print("[BakonGG] Auto Sell:", state and "ON" or "OFF")
                end)
            else
                error("API de toggle não encontrada")
            end

        end)
        if not success then
            warn("[BakonGG] Shadow Lib carregada, mas integração falhou:", winOrErr)
            createFallbackGUI()
        end
    else
        warn("[BakonGG] Shadow Lib não encontrada — usando GUI simples.")
        createFallbackGUI()
    end
end

-- Inicializa loops e UI
createUI()
startAutoCollectLoop()
startAutoSellLoop()
startTeleportLoop()

print("[BakonGG] Script do jogo carregado. Use a UI para ligar/desligar AutoCollect/AutoSell.")
