-- Anti-Duplicação (Para quando executar novamente, parar o anterior)
getgenv().TycoonAutoFarmId = tick()
local CurrentExecId = getgenv().TycoonAutoFarmId

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Limpar UI antiga para não acumular
for _, gui in pairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        local isOurs = false
        for _, desc in pairs(gui:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text == "Bakon's Tycoon Farm" then
                isOurs = true
                break
            end
        end
        if isOurs then
            gui:Destroy()
        end
    end
end
-- Limpar o botão de toggle antigo
for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name == "BakonToggleGui" then
        gui:Destroy()
    end
end

-- Variáveis Globais de Controle
getgenv().AutoCollectCash = false

---------------------------------------------------------
-- FUNÇÕES DE BUSCA E COLETA
---------------------------------------------------------

-- Função robusta para encontrar o Tycoon do jogador
local function GetMyTycoon()
    local expectedText = LocalPlayer.Name .. "'s Tycoon"
    
    -- Varre o workspace procurando pastas/modelos com "Tycoon" no nome
    for _, child in pairs(workspace:GetChildren()) do
        if string.find(child.Name, "Tycoon") then
            -- Procura por TextLabels dentro desse Tycoon
            for _, desc in pairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == expectedText then
                    return child -- Retorna o modelo do Tycoon inteiro (ex: workspace.TycoonC)
                end
            end
        end
    end
    return nil
end

-- Função para coletar o dinheiro
local function CollectCash(tycoon)
    if not tycoon then return end
    
    pcall(function()
        local factory = tycoon:FindFirstChild("Factory")
        if factory then
            local ground = factory:FindFirstChild("Ground")
            if ground then
                local cashToCollect = ground:FindFirstChild("Cash to collect")
                if cashToCollect then
                    local collectFolder = cashToCollect:FindFirstChild("Collect")
                    if collectFolder then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local hrp = char.HumanoidRootPart
                            
                            -- Busca genérica: Toca em todas as Parts (pois o Cash tem TouchInterest) e ativa ClickDetectors
                            for _, v in pairs(collectFolder:GetDescendants()) do
                                if v:IsA("BasePart") then
                                    firetouchinterest(hrp, v, 0)
                                    firetouchinterest(hrp, v, 1)
                                end
                                if v:IsA("ClickDetector") then
                                    fireclickdetector(v)
                                end
                            end
                        end
                        
                    end
                end
            end
        end
    end)
end

---------------------------------------------------------
-- LOOP PRINCIPAL DE AUTO FARM
---------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        -- Se o script for executado novamente, esse loop morre e dá lugar ao novo
        if getgenv().TycoonAutoFarmId ~= CurrentExecId then
            break
        end
        
        if getgenv().AutoCollectCash then
            local myTycoon = GetMyTycoon()
            if myTycoon then
                CollectCash(myTycoon)
            else
                --print("[AutoFarm] Não encontrei o Tycoon de", LocalPlayer.Name)
            end
        end
    end
end)

---------------------------------------------------------
-- INTERFACE GRÁFICA (Baseada na UI_base.lua)
---------------------------------------------------------
local omni = loadstring(game:HttpGet("https://raw.githubusercontent.com/TweedLeak-LeakScripts/FriseX/main/UI-Library"))()

local UI = omni.new({
    Name = "💸 Bakon's Tycoon Farm 💸";
    Credit = "Created by Bakon";
    Color = Color3.fromRGB(40, 200, 80); -- Cor verde para dinheiro
    Bind = "RightShift";
    UseLoader = false;
    FullName = "Bakon's Tycoon Farm";
    CheckKey = function(inputtedKey)
        return true
    end;
    Discord = "";
})

local Pages = UI:CreatePage("AutoFarm 💰")
local Section = Pages:CreateSection("Funções Principais")

Section:CreateToggle({
    Name = "Auto Collect Cash";
    Flag = "ToggleCollect";
    Default = false;
    Callback = function(state)
        getgenv().AutoCollectCash = state
    end;
})

Section:CreateButton({
    Name = "Mais funções em breve...";
    Callback = function()
    end;
})

---------------------------------------------------------
-- BOTÃO DE TOGGLE & INTERCEPTAÇÃO DO "X"
---------------------------------------------------------
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "BakonToggleGui"
ToggleGui.ResetOnSpawn = false
local sGui = pcall(function() ToggleGui.Parent = CoreGui end)
if not sGui then ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local OpenBtn = Instance.new("ImageButton")
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Position = UDim2.new(0, 5, 0, 45) -- Embaixo do ícone do Roblox
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
OpenBtn.Image = "rbxassetid://6026568240" -- Icone estilo Menu/Settings
OpenBtn.Parent = ToggleGui
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = OpenBtn

OpenBtn.MouseButton1Click:Connect(function()
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            -- Verifica se é a nossa UI
            for _, desc in pairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == "Bakon's Tycoon Farm" then
                    gui.Enabled = not gui.Enabled
                    break
                end
            end
        end
    end
end)

-- Interceptar o botão X (Close) da UI
task.spawn(function()
    task.wait(2) -- Aguarda a UI carregar
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local isOurs = false
            for _, desc in pairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == "Bakon's Tycoon Farm" then
                    isOurs = true
                    break
                end
            end
            
            if isOurs then
                for _, btn in pairs(gui:GetDescendants()) do
                    if btn:IsA("TextButton") and (btn.Text == "X" or btn.Text == "x") then
                        local newBtn = btn:Clone()
                        newBtn.Parent = btn.Parent
                        btn:Destroy()
                        
                        newBtn.MouseButton1Click:Connect(function()
                            gui.Enabled = false
                        end)
                        break
                    end
                end
            end
        end
    end
end)
