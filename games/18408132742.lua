print("[GAME 18408132742] Script carregado com sucesso!")

-- Teste simples: esperar 5 segundos e printar
task.delay(5, function()
    print("[GAME 18408132742] Passaram-se 5 segundos, o script está rodando!")
end)
-- Serviços
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

-- Configuração (pode mudar depois)
local quantidadeUpgrades = 5   -- número de upgrades normais
local quantidadeRebirthUpgrades = 100 -- upgrades de rebirth automáticos

-- Flags para os botões
local autoClickAtivo = false
local autoUpgradeAtivo = false
local autoExtraAtivo = false
local autoRebirthAtivo = false
local autoRebirthUpgradeAtivo = false

-- Criando GUI
local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0, 200, 0, 250)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true -- arrastar a janela

-- Função para criar botões
local function criarBotao(texto, ordem)
    local botao = Instance.new("TextButton", frame)
    botao.Size = UDim2.new(1, -10, 0, 40)
    botao.Position = UDim2.new(0, 5, 0, (ordem - 1) * 45 + 5)
    botao.Text = texto .. " [OFF]"
    botao.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    botao.TextColor3 = Color3.fromRGB(255, 255, 255)
    botao.Font = Enum.Font.SourceSansBold
    botao.TextSize = 20
    return botao
end

-- Criando botões
local botaoClick = criarBotao("Auto Click", 1)
local botaoUpgrade = criarBotao("Auto Upgrade", 2)
local botaoExtra = criarBotao("Auto Upgrade Extra", 3)
local botaoRebirth = criarBotao("Auto Rebirth", 4)
local botaoRebirthUpgrade = criarBotao("Auto Rebirth Upgrade", 5)

-- Loops de execução
task.spawn(function()
    while task.wait(0.1) do
        if autoClickAtivo then
            Events:WaitForChild("ClickMoney"):FireServer()
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if autoUpgradeAtivo then
            for i = 1, quantidadeUpgrades do
                local args = {i, true}
                Events:WaitForChild("Upgrade"):FireServer(unpack(args))
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if autoExtraAtivo then
            local args = {1}
            Events:WaitForChild("Upgrade"):WaitForChild("ExtraUpgrade3"):FireServer(unpack(args))
        end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if autoRebirthAtivo then
            Events:WaitForChild("Prestige"):FireServer()
        end
    end
end)

task.spawn(function()
    while task.wait(4) do
        if autoRebirthUpgradeAtivo then
            for i = 1, quantidadeRebirthUpgrades do
                local args = {i}
                Events:WaitForChild("Prestige"):WaitForChild("PrestigeUpgrade"):FireServer(unpack(args))
            end
        end
    end
end)

-- Funções de clique nos botões
botaoClick.MouseButton1Click:Connect(function()
    autoClickAtivo = not autoClickAtivo
    botaoClick.Text = "Auto Click [" .. (autoClickAtivo and "ON" or "OFF") .. "]"
    botaoClick.BackgroundColor3 = autoClickAtivo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end)

botaoUpgrade.MouseButton1Click:Connect(function()
    autoUpgradeAtivo = not autoUpgradeAtivo
    botaoUpgrade.Text = "Auto Upgrade [" .. (autoUpgradeAtivo and "ON" or "OFF") .. "]"
    botaoUpgrade.BackgroundColor3 = autoUpgradeAtivo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end)

botaoExtra.MouseButton1Click:Connect(function()
    autoExtraAtivo = not autoExtraAtivo
    botaoExtra.Text = "Auto Upgrade Extra [" .. (autoExtraAtivo and "ON" or "OFF") .. "]"
    botaoExtra.BackgroundColor3 = autoExtraAtivo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end)

botaoRebirth.MouseButton1Click:Connect(function()
    autoRebirthAtivo = not autoRebirthAtivo
    botaoRebirth.Text = "Auto Rebirth [" .. (autoRebirthAtivo and "ON" or "OFF") .. "]"
    botaoRebirth.BackgroundColor3 = autoRebirthAtivo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end)

botaoRebirthUpgrade.MouseButton1Click:Connect(function()
    autoRebirthUpgradeAtivo = not autoRebirthUpgradeAtivo
    botaoRebirthUpgrade.Text = "Auto Rebirth Upgrade [" .. (autoRebirthUpgradeAtivo and "ON" or "OFF") .. "]"
    botaoRebirthUpgrade.BackgroundColor3 = autoRebirthUpgradeAtivo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end)
