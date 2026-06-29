-- Autofarm para Color by Number (ID: 8137333410)
-- Desenvolvido com base nos arquivos Knit e Constants extraídos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Espera o Knit carregar os serviços
local PixelGeneratorService = Knit.GetService("PixelGeneratorService")
local PlayerManagerService = Knit.GetService("PlayerManagerService")
local DrawPixelRemote = ReplicatedStorage.Knit.Services.PixelGeneratorService.RF.DrawPixel

-- Variáveis de Controle
local getgenv = getgenv or function() return _G end
getgenv().AutoPaint = false
getgenv().AutoBuyNext = false
getgenv().AutoFarmMaster = false
getgenv().PaintSpeedMode = getgenv().PaintSpeedMode or 2 -- 1=Muito Rapido, 2=Rapido, 3=Medio, 4=Lento
getgenv().LastTotalPixels = getgenv().LastTotalPixels or 0
getgenv().PixelTotalStableTime = getgenv().PixelTotalStableTime or 0

-- Em vez de spawnar milhares de threads com wait() aleatório, vamos processar em lotes por tick
local SpeedSettings = {
    { text = "M. Rápido (Risco)", batchSize = 25, waitTime = 0.05 },
    { text = "Rápido", batchSize = 10, waitTime = 0.05 },
    { text = "Médio", batchSize = 5, waitTime = 0.1 },
    { text = "Lento", batchSize = 2, waitTime = 0.2 }
}

---------------------------------------------------------
-- FUNÇÕES DE BUSCA (PLOT E PIXELS)
---------------------------------------------------------
local CachedPlot = nil
local function GetOwnerPlot()
    if CachedPlot and CachedPlot.Parent then return CachedPlot end
    
    local myAvatarImage = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=420&h=420"
    local plot = nil

    for _, v in pairs(workspace.Map.Blocks:GetDescendants()) do
        if v.Name == "OwnerFace" and v.Parent.Name == "SpawnLocation" then 
            local surfaceGui = v:FindFirstChild("SurfaceGui")
            if surfaceGui then
                local imageLabel = surfaceGui:FindFirstChild("ImageLabel")
                if imageLabel and imageLabel.Image == myAvatarImage then
                    plot = v.Parent.Parent
                    CachedPlot = plot
                    break
                end
            end
        end
    end
    return plot
end

local function GetPixelStats(plot)
    if not plot or not plot:FindFirstChild("Draw") then return 0, 0, 0 end
    
    local total = 0
    local unpainted = 0
    local processing = 0
    
    for _, v in pairs(plot.Draw:GetChildren()) do
        if v.Name == "Part" then
            local tex = v:FindFirstChild("Texture")
            if tex then
                total = total + 1
                if tex.Transparency < 1 then -- Transparency 1 = Pintado (Invisível)
                    if v:GetAttribute("AutoProcessing") then
                        processing = processing + 1
                    else
                        unpainted = unpainted + 1
                    end
                end
            end
        end
    end
    
    return unpainted, processing, total
end

---------------------------------------------------------
-- INTERFACE GRÁFICA (PAINEL)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ColorByNumberAuto"
local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 265)
MainFrame.Position = UDim2.new(0.5, -150, 0.8, -265)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🎨 Auto Color by Number"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -20, 0, 40)
StatusText.Position = UDim2.new(0, 10, 0, 35)
StatusText.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
StatusText.Text = "Pixels Pintados: 0 / 0"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 14
StatusText.Parent = MainFrame
Instance.new("UICorner", StatusText).CornerRadius = UDim.new(0, 6)

local function CreateButton(text, pos, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 35)
    Btn.Position = pos
    Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.Parent = MainFrame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

local MasterBtn = CreateButton("Master Auto Farm: OFF", UDim2.new(0, 10, 0, 85), function()
    getgenv().AutoFarmMaster = not getgenv().AutoFarmMaster
    getgenv().AutoPaint = getgenv().AutoFarmMaster
    getgenv().AutoBuyNext = getgenv().AutoFarmMaster
end)

local PaintBtn = CreateButton("Auto Paint: OFF", UDim2.new(0, 10, 0, 130), function()
    getgenv().AutoPaint = not getgenv().AutoPaint
end)

local BuyBtn = CreateButton("Auto Buy/Equip: OFF", UDim2.new(0, 10, 0, 175), function()
    getgenv().AutoBuyNext = not getgenv().AutoBuyNext
end)

local SpeedBtn = CreateButton("Velocidade: Rápida", UDim2.new(0, 10, 0, 220), function()
    getgenv().PaintSpeedMode = getgenv().PaintSpeedMode + 1
    if getgenv().PaintSpeedMode > #SpeedSettings then
        getgenv().PaintSpeedMode = 1
    end
end)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)

-- Atualiza UI visualmente
task.spawn(function()
    while task.wait(0.1) do
        if not ScreenGui.Parent then break end
        
        MasterBtn.Text = "Master Auto Farm: " .. (getgenv().AutoFarmMaster and "ON" or "OFF")
        MasterBtn.BackgroundColor3 = getgenv().AutoFarmMaster and Color3.fromRGB(150, 50, 200) or Color3.fromRGB(100, 50, 150)

        PaintBtn.Text = "Auto Paint: " .. (getgenv().AutoPaint and "ON" or "OFF")
        PaintBtn.BackgroundColor3 = getgenv().AutoPaint and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        
        BuyBtn.Text = "Auto Next Art: " .. (getgenv().AutoBuyNext and "ON" or "OFF")
        BuyBtn.BackgroundColor3 = getgenv().AutoBuyNext and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        
        local currentSpeed = SpeedSettings[getgenv().PaintSpeedMode]
        SpeedBtn.Text = "Veloc. " .. currentSpeed.text
        
        local plot = GetOwnerPlot()
        local unpainted, processing, total = GetPixelStats(plot)
        if total > 0 then
            StatusText.Text = string.format("Restam: %d | Processando: %d", unpainted, processing)
        else
            StatusText.Text = "Nenhum desenho encontrado."
        end
    end
end)

---------------------------------------------------------
-- LÓGICA DE COMPRA E EQUIPAR NOVO DESENHO
---------------------------------------------------------
local function BuyAndEquipNextDraw()
    print("[AutoFarm] Iniciando rotina de BuyAndEquipNextDraw...")
    local allCategories = Constants.CATEGORIES_PIXEL
    if not allCategories then 
        warn("[AutoFarm] ERRO: Constants.CATEGORIES_PIXEL não encontrado!")
        return false
    end
    
    print("[AutoFarm] Buscando próximo desenho não concluído na lista...")
    
    for categoryName, drawList in pairs(allCategories) do
        local unlockedDraws = {}
        local s2, res2 = pcall(function() return PlayerManagerService:GetUnlockedPixels(categoryName) end)
        if s2 then 
            unlockedDraws = res2 or {}
        end
        
        for _, draw in ipairs(drawList) do
            local drawData = unlockedDraws[draw.Name]
            local isUnlocked = (drawData ~= nil)
            local isCompleted = false
            
            if isUnlocked and drawData.Completed then
                isCompleted = true
            end

            -- Verifica se já foi concluído
            if not isCompleted then
                print(string.format("[AutoFarm] Encontrou desenho não concluído! Categoria: %s | Desenho: %s", categoryName, draw.Name))
                
                -- Se não tem, tenta comprar
                if not isUnlocked then
                    print("[AutoFarm] Tentando COMPRAR desenho: " .. tostring(draw.Name) .. " (Preço: " .. tostring(draw.Price or 0) .. ")")
                    local sBuy, resBuy = pcall(function()
                        return PixelGeneratorService:BuyPixelTable(categoryName, draw.Name)
                    end)
                    if sBuy and resBuy == true then 
                        print("[AutoFarm] Retorno do Servidor (Compra): Sucesso!")
                        isUnlocked = true
                    else
                        print("[AutoFarm] Falha ao comprar (sem dinheiro ou falha). Pulando para o próximo...")
                    end
                    task.wait(1)
                end
                
                -- Só tenta equipar se comprou ou se já era destrancado
                if isUnlocked then
                    print("[AutoFarm] Tentando EQUIPAR (Draw) desenho: " .. tostring(draw.Name))
                    
                    -- Quebra a parede antiga de paleta se houver (visual)
                    pcall(function()
                        local plot = GetOwnerPlot()
                        if plot then
                            local DrawFolder = plot:FindFirstChild("Draw")
                            if DrawFolder then
                                for _, v3 in ipairs(DrawFolder:GetChildren()) do
                                    if v3.Name == "GivePaletteWall" then
                                        v3.Parent = nil
                                        v3:Destroy()
                                    end
                                end
                            end
                        end
                    end)
                    
                    -- Equipa e gera a arte
                    local sEquip, resEquip = pcall(function()
                        PixelGeneratorService:GeneratePixel(categoryName, draw.Name)
                        PixelGeneratorService:UpdateSelectedPalettePixel(-1)
                    end)
                    
                    if sEquip and resEquip ~= false then
                        print("[AutoFarm] Chamada de Equipar foi executada com sucesso! Aguardando o servidor trocar o canvas.")
                        return true -- Para aqui, pois já encontrou e equipou o próximo!
                    else
                        warn("[AutoFarm] ERRO ao tentar equipar/gerar arte:", tostring(resEquip))
                    end
                end
            end
        end
    end
    print("[AutoFarm] Parabéns, aparentemente você completou TODOS os desenhos (ou não tem dinheiro)! O AutoFarm ficará em espera.")
    return false
end

---------------------------------------------------------
-- LOOP PRINCIPAL DE AUTO PAINT
---------------------------------------------------------
task.spawn(function()
    while task.wait() do
        local plot = GetOwnerPlot()
        if plot then
            local drawFolder = plot:FindFirstChild("Draw")
            local unpainted, processing, total = 0, 0, 0
            
            if drawFolder then
                unpainted, processing, total = GetPixelStats(plot)
                
                -- Verifica se a quantidade de partes estabilizou (para não pintar enquanto o jogo carrega e crashar o Client)
                if total ~= getgenv().LastTotalPixels then
                    getgenv().LastTotalPixels = total
                    getgenv().PixelTotalStableTime = tick()
                end
            end
            
            -- Se não tem desenho na tela (em branco/removido) 
            -- OU (total > 0 e terminamos tudo e nenhum está processando)
            if (not drawFolder) or (drawFolder and total == 0) or (drawFolder and total > 0 and unpainted == 0 and processing == 0) then
                if getgenv().AutoBuyNext or getgenv().AutoFarmMaster then
                    print("[AutoFarm] Tela em branco ou Desenho totalmente finalizado! Buscando o próximo...")
                    local success = BuyAndEquipNextDraw()
                    if success then
                        task.wait(3) -- Tempo para o servidor spawnar as peças
                    else
                        task.wait(10) -- Espera 10s se falhou (pra não floodar o console se estiver sem dinheiro)
                    end
                else
                    task.wait(1)
                end
            elseif drawFolder and getgenv().AutoPaint then
                -- Aguarda 3 segundos de estabilidade antes de pintar, para garantir que os scripts do jogo carregaram
                if tick() - getgenv().PixelTotalStableTime < 3 then
                    StatusText.Text = "Aguardando carregamento da arte..."
                    task.wait(0.5)
                else
                    -- Pinta os pixels usando Batch
                    local s = SpeedSettings[getgenv().PaintSpeedMode]
                    local batchLimit = s.batchSize
                local waitTime = s.waitTime
                
                local count = 0
                for _, v in pairs(drawFolder:GetChildren()) do
                    if not getgenv().AutoPaint then break end
                    
                    if v.Name == "Part" then
                        local tex = v:FindFirstChild("Texture")
                        -- Se tem Textura visível (< 1) e não estamos processando ela ainda
                        if tex and tex.Transparency < 1 and not v:GetAttribute("AutoProcessing") then
                            v:SetAttribute("AutoProcessing", true)
                            
                            task.spawn(function()
                                pcall(function()
                                    DrawPixelRemote:InvokeServer(v)
                                end)
                                -- Após 2 segundos, se o pixel ainda existir com Texture, limpa pra tentar denovo
                                task.delay(2, function()
                                    if v.Parent then
                                        v:SetAttribute("AutoProcessing", nil)
                                    end
                                end)
                            end)
                            
                            count = count + 1
                            if count >= batchLimit then
                                count = 0
                                task.wait(waitTime)
                            end
                        end
                    end
                end
                
                if count > 0 then
                    task.wait(waitTime)
                end
            end
        end
    end
end)
