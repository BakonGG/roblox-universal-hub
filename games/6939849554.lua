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
    local nameLower = string.lower(LocalPlayer.Name)
    local displayLower = string.lower(LocalPlayer.DisplayName)
    
    -- Varre o workspace procurando pastas/modelos que sejam Tycoons
    for _, child in pairs(workspace:GetChildren()) do
        if string.find(child.Name, "Tycoon") then
            -- 1. Verifica se existe um ObjectValue chamado Owner
            local ownerVal = child:FindFirstChild("Owner")
            if ownerVal and ownerVal:IsA("ObjectValue") and ownerVal.Value == LocalPlayer then
                return child
            end
            
            -- 2. Busca por placas de texto com o nome do jogador (ignorando maiúsculas/minúsculas)
            for _, desc in pairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text ~= "" then
                    local txt = string.lower(desc.Text)
                    if string.find(txt, nameLower) or string.find(txt, displayLower) then
                        return child -- Retorna o modelo do Tycoon inteiro
                    end
                end
            end
        end
    end
    return nil
end

-- Função para coletar o dinheiro
local function CollectCash(tycoon)
    if not tycoon then 
        warn("[AutoFarm] ERRO: Tycoon não definido na função CollectCash.")
        return 
    end
    
    local success, err = pcall(function()
        local factory = tycoon:FindFirstChild("Factory")
        if not factory then warn("[AutoFarm] 'Factory' não encontrado em: " .. tycoon.Name) return end
        
        local ground = factory:FindFirstChild("Ground")
        if not ground then warn("[AutoFarm] 'Ground' não encontrado em Factory") return end
        
        local cashToCollect = ground:FindFirstChild("Cash to collect")
        if not cashToCollect then warn("[AutoFarm] 'Cash to collect' não encontrado em Ground") return end
        
        local collectPart = cashToCollect:FindFirstChild("Collect")
        if not collectPart then warn("[AutoFarm] 'Collect' não encontrado em Cash to collect") return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then 
            warn("[AutoFarm] Personagem ou HumanoidRootPart não encontrado")
            return 
        end
        local hrp = char.HumanoidRootPart
        
        local touched = false
        
        -- O grande segredo: O 'Collect' na verdade É UMA PEÇA (BasePart), e não uma pasta!
        if collectPart:IsA("BasePart") then
            firetouchinterest(hrp, collectPart, 0)
            firetouchinterest(hrp, collectPart, 1)
            touched = true
        end
        
        -- Busca genérica de garantia para os filhos
        for _, v in pairs(collectPart:GetDescendants()) do
            if v:IsA("BasePart") then
                firetouchinterest(hrp, v, 0)
                firetouchinterest(hrp, v, 1)
                touched = true
            end
            if v:IsA("ClickDetector") then
                fireclickdetector(v)
                touched = true
            end
        end
        
        if not touched then
            warn("[AutoFarm] Nenhuma BasePart ou ClickDetector encontrada dentro de Collect!")
        else
            print("[AutoFarm] Coleta realizada com sucesso no tycoon: " .. tycoon.Name)
        end
    end)
    
    if not success then
        warn("[AutoFarm] ERRO CRÍTICO no CollectCash: " .. tostring(err))
    end
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
        
        local myTycoon = GetMyTycoon()
        
        if getgenv().AutoCollectCash then
            if myTycoon then
                CollectCash(myTycoon)
            else
                warn("[AutoFarm] Tycoon do jogador não encontrado! Verifique se a placa tem seu nome.")
            end
        end
        
        -- Atualizar a UI com o nome do Tycoon
        local nameStr = myTycoon and ("Tycoon: " .. myTycoon.Name) or "Tycoon: Nenhum (Procurando...)"
        for _, gui in pairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, desc in pairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text:match("^Tycoon:") then
                        desc.Text = nameStr
                    end
                end
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
    Name = "Tycoon: Procurando...";
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
