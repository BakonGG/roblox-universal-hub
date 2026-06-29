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
        end
    end)
    
    if not success then
        warn("[AutoFarm] ERRO CRÍTICO no CollectCash: " .. tostring(err))
    end
end

---------------------------------------------------------
-- AUTO BUY LOGIC
---------------------------------------------------------
local function ParsePrice(text)
    -- Remove vírgulas, $ e espaços, MAS MANTÉM O PONTO DECIMAL
    local cleanText = string.gsub(text, "[%$%s,]", "")
    -- Procura por números (com ou sem ponto) seguidos de K, M, B, etc.
    local val, suffix = string.match(cleanText, "([%d%.]+)([KkMmBbtT]?)")
    if val then
        local price = tonumber(val)
        if price then
            local suf = string.upper(suffix)
            if suf == "K" then price = price * 1000
            elseif suf == "M" then price = price * 1000000
            elseif suf == "B" then price = price * 1000000000
            elseif suf == "T" then price = price * 1000000000000
            end
            return math.floor(price)
        end
    end
    -- Fallback genérico
    local numStr = string.match(cleanText, "%d+")
    if numStr then return tonumber(numStr) end
    return 0
end

local function FormatNumber(n)
    n = tostring(n)
    local k
    while true do
        n, k = string.gsub(n, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return n
end

local function GetPlayerMoney()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local main = pg:FindFirstChild("Main")
        if main then
            local leftFrame = main:FindFirstChild("LeftFrame")
            if leftFrame then
                local cashFolder = leftFrame:FindFirstChild("Cash")
                if cashFolder then
                    local cashLbl = cashFolder:FindFirstChild("Cash")
                    if cashLbl and cashLbl:IsA("TextLabel") then
                        return ParsePrice(cashLbl.Text)
                    end
                end
            end
        end
    end
    
    -- Fallback: Tenta achar na leaderstats
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in pairs(leaderstats:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                return v.Value
            end
        end
    end
    return 0
end

local function GetButtonPrice(head)
    local nameGui = head:FindFirstChild("NameGui")
    if nameGui then
        -- 1. Caminho exato que o usuário mandou
        local full = nameGui:FindFirstChild("Full")
        if full then
            local mainCur = full:FindFirstChild("MainCurrency")
            if mainCur then
                local cash = mainCur:FindFirstChild("Cash")
                if cash then
                    local valueLbl = cash:FindFirstChild("Value")
                    if valueLbl and valueLbl:IsA("TextLabel") then
                        return ParsePrice(valueLbl.Text)
                    end
                end
            end
        end
    end
    return 0 -- Retorna 0 se não encontrar (provavelmente é botão de Robux sem valor)
end

getgenv().TotalSpent = getgenv().TotalSpent or 0
getgenv().KnownButtons = getgenv().KnownButtons or {}

local function AutoBuyTycoon(tycoon)
    if not tycoon then return nil end
    local cheapest = math.huge
    
    pcall(function()
        local factory = tycoon:FindFirstChild("Factory")
        if not factory then return end
        
        local myMoney = GetPlayerMoney()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        
        -- Verificar botões comprados para somar no TotalSpent
        for item, price in pairs(getgenv().KnownButtons) do
            if typeof(item) == "Instance" and item.Parent == nil then
                getgenv().TotalSpent = getgenv().TotalSpent + price
                getgenv().KnownButtons[item] = nil
            end
        end
        
        for _, item in pairs(factory:GetChildren()) do
            if item:IsA("Model") or item:IsA("Folder") then
                local head = item:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    
                    if not head:FindFirstChild("Coin_effect") then
                        local price = GetButtonPrice(head)
                        
                        -- Registrar na tabela de conhecidos para calcular gasto
                        if price > 0 and not getgenv().KnownButtons[item] then
                            getgenv().KnownButtons[item] = price
                        end
                        
                        if price > 0 and price < cheapest then
                            cheapest = price
                            getgenv().NextButtonHead = head
                        end
                        
                        if myMoney >= price and price > 0 then
                            print("[AutoFarm] Tentando comprar:", item.Name, "| Preço:", price, "| Meu Dinheiro:", myMoney)
                            firetouchinterest(hrp, head, 0)
                            task.wait(0.05)
                            firetouchinterest(hrp, head, 1)
                            
                            local cd = head:FindFirstChildOfClass("ClickDetector")
                            if cd then fireclickdetector(cd) end
                        end
                    end
                end
            end
        end
    end)
    return cheapest
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
        
        local cheapest = math.huge
        if getgenv().AutoBuy then
            if myTycoon then
                cheapest = AutoBuyTycoon(myTycoon) or math.huge
            end
        end
        
        -- Format strings for UI
        local nameStr = myTycoon and ("Tycoon: " .. myTycoon.Name) or "Tycoon: Nenhum (Procurando...)"
        local moneyStr = "Dinheiro: " .. FormatNumber(GetPlayerMoney())
        local spentStr = "Total Gasto: " .. FormatNumber(getgenv().TotalSpent or 0)
        local nextStr = "Próximo Botão: " .. (cheapest == math.huge and "Nenhum" or FormatNumber(cheapest))
        
        for _, gui in pairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, desc in pairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") then
                        if desc.Text:match("^Tycoon:") then desc.Text = nameStr end
                        if desc.Text:match("^Dinheiro:") then desc.Text = moneyStr end
                        if desc.Text:match("^Total Gasto:") then desc.Text = spentStr end
                        if desc.Text:match("^Próximo Botão:") then desc.Text = nextStr end
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

Section:CreateToggle({
    Name = "Auto Buy (Botões)";
    Flag = "ToggleAutoBuy";
    Default = false;
    Callback = function(state)
        getgenv().AutoBuy = state
    end;
})

Section:CreateButton({
    Name = "Tycoon: Procurando...";
    Callback = function() end;
})

Section:CreateButton({
    Name = "Dinheiro: 0";
    Callback = function() end;
})

Section:CreateButton({
    Name = "Total Gasto: 0";
    Callback = function() end;
})

Section:CreateButton({
    Name = "Próximo Botão: Procurando...";
    Callback = function()
        local h = getgenv().NextButtonHead
        if h and h.Parent then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(h.Position + Vector3.new(0, 3, 0))
            end
        end
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
