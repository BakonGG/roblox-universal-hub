-- Script Único: Auto-Click + Auto-Coletor + Auto-Buy (com botões e correções)
-- LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- atualiza HRP após respawn (evita quebrar coletor/auto-buy)
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)

-- Ajuste seu tycoon aqui, se necessário
local tycoon = workspace:WaitForChild("tycoon2"):WaitForChild("Tycoons"):WaitForChild("Blue Team")

------------------------------------------------
-- VARIÁVEIS DE CONTROLE
------------------------------------------------
local autoClickEnabled = true
local autoCollectEnabled = true
local autoBuyEnabled = true
local isBuying = false -- garante 1 compra por vez

local CLICK_INTERVAL = 0.05 -- clique mais rápido (20x/seg). Aumente se precisar aliviar carga.

-- Dinheiro do player (evita nome fixo)
local moneyFolder = RS:WaitForChild("PlayerMoney")
local moneyValue = moneyFolder:WaitForChild(player.Name)

------------------------------------------------
-- FUNÇÕES ÚTEIS
------------------------------------------------
-- Encontra dinamicamente o ClickDetector do Dropper1 (ou de um dropper)
local function findDropperClickDetector()
    local purchased = tycoon:FindFirstChild("PurchasedObjects")
    if not purchased then return nil end

    -- Tenta primeiro o Dropper1
    local dropper = purchased:FindFirstChild("Dropper1")
    if dropper then
        for _, d in ipairs(dropper:GetDescendants()) do
            if d:IsA("ClickDetector") then
                return d
            end
        end
    end

    -- Fallback: qualquer ClickDetector dentro de algo chamado "Dropper"
    for _, d in ipairs(purchased:GetDescendants()) do
        if d:IsA("ClickDetector") then
            local anc = d.Parent
            while anc do
                if anc.Name:lower():find("dropper") then
                    return d
                end
                anc = anc.Parent
            end
        end
    end
    return nil
end

-- Toque “seguro” em botão de compra
local function safeTouch(part)
    if not part or not part.Parent then return end
    pcall(function()
        firetouchinterest(hrp, part, 0)
        task.wait()
        firetouchinterest(hrp, part, 1)
    end)
end

------------------------------------------------
-- AUTO CLICK (Dropper) robusto
------------------------------------------------
task.spawn(function()
    local purchased = tycoon:WaitForChild("PurchasedObjects")
    local clickDetector = nil

    -- Reage se algo novo for comprado (pode nascer o Dropper/ClickDetector depois)
    purchased.DescendantAdded:Connect(function(desc)
        if not clickDetector and desc:IsA("ClickDetector") then
            -- Se o detector adicionado está dentro de um Dropper, pegue-o
            local anc = desc.Parent
            while anc do
                if anc.Name:lower():find("dropper") then
                    clickDetector = desc
                    break
                end
                anc = anc.Parent
            end
        end
    end)

    while true do
        if autoClickEnabled then
            if (not clickDetector) or (not clickDetector.Parent) or (not clickDetector:IsDescendantOf(workspace)) then
                clickDetector = findDropperClickDetector()
            end
            if clickDetector then
                -- pcall evita que um erro pare a thread se o objeto for destruído entre o frame e o clique
                pcall(fireclickdetector, clickDetector)
            end
        end
        task.wait(CLICK_INTERVAL)
    end
end)

------------------------------------------------
-- AUTO COLETOR DE DINHEIRO (Giver) robusto
------------------------------------------------
task.spawn(function()
    local giver = tycoon:WaitForChild("Essentials"):WaitForChild("Giver")
    while true do
        if autoCollectEnabled then
            safeTouch(giver)
        end
        task.wait(0.5)
    end
end)

------------------------------------------------
-- AUTO BUY (checa dinheiro e faz 1 compra por vez)
------------------------------------------------
local buttonsFolder = tycoon:WaitForChild("Buttons")

local function touchButton(button)
    if not autoBuyEnabled or isBuying then return end
    if not button or not button.Parent then return end
    if button.Name:lower():find("gamepass") then return end

    local hitPart = button:FindFirstChild("hit") or button:FindFirstChild("Hit") or button:FindFirstChildWhichIsA("BasePart")
    local price = button:FindFirstChild("Price")

    if not (hitPart and price and moneyValue) then return end
    if typeof(price.Value) ~= "number" or typeof(moneyValue.Value) ~= "number" then return end

    if price.Value <= moneyValue.Value then
        isBuying = true
        safeTouch(hitPart)
        -- pequena folga para garantir que só 1 item seja comprado
        task.wait(0.5)
        isBuying = false
    end
end

-- Comprar botões existentes periodicamente
task.spawn(function()
    while true do
        if autoBuyEnabled then
            for _, button in ipairs(buttonsFolder:GetChildren()) do
                touchButton(button)
            end
        end
        task.wait(1)
    end
end)

-- Comprar quando aparecer botão novo
buttonsFolder.ChildAdded:Connect(function(newButton)
    task.wait(0.2)
    touchButton(newButton)
end)

------------------------------------------------
-- UI DOS BOTÕES (ON/OFF)
------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local function createToggleButton(name, position, getState, toggleState)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 40)
    button.Position = position
    button.BackgroundColor3 = getState() and Color3.fromRGB(30, 150, 30) or Color3.fromRGB(150, 30, 30)
    button.TextColor3 = Color3.new(1,1,1)
    button.Text = name .. ": " .. (getState() and "ON" or "OFF")
    button.Parent = screenGui

    button.MouseButton1Click:Connect(function()
        toggleState()
        local state = getState()
        button.BackgroundColor3 = state and Color3.fromRGB(30, 150, 30) or Color3.fromRGB(150, 30, 30)
        button.Text = name .. ": " .. (state and "ON" or "OFF")
    end)
end

createToggleButton("Auto-Click", UDim2.new(1, -160, 0, 10),
    function() return autoClickEnabled end,
    function() autoClickEnabled = not autoClickEnabled end
)

createToggleButton("Auto-Coletor", UDim2.new(1, -160, 0, 60),
    function() return autoCollectEnabled end,
    function() autoCollectEnabled = not autoCollectEnabled end
)

createToggleButton("Auto-Buy", UDim2.new(1, -160, 0, 110),
    function() return autoBuyEnabled end,
    function() autoBuyEnabled = not autoBuyEnabled end
)
