-- /games/123456789.lua  (substitua 123456789 pelo PlaceId real)

-- Carrega Shadow Lib (atenção: espaço no nome do arquivo -> %20)
local ShadowLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/main/Shadow%20Lib.txt"
))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Janela do Hub
local Window = ShadowLib:Window("Meu Hub - ".. tostring(game.PlaceId), Color3.fromRGB(44,120,224), Enum.KeyCode.RightControl)
local TabFarm = Window:Tab("Farm")

-- Flags globais (persistem se reexecutar)
getgenv().AutoCollect = getgenv().AutoCollect or false
getgenv().AutoSell    = getgenv().AutoSell or false

-- Toggles
TabFarm:Toggle("Auto Collect (todos os Plots)", getgenv().AutoCollect, function(state)
    getgenv().AutoCollect = state
end)

TabFarm:Toggle("Auto Sell + Teleport (30s)", getgenv().AutoSell, function(state)
    getgenv().AutoSell = state
end)

-- ========== WORKERS (iniciam uma vez e obedecem as flags) ==========

-- 1) Auto Collect (percorrendo todos os Plots)
task.spawn(function()
    while true do
        if getgenv().AutoCollect then
            local plotsFolder = workspace:FindFirstChild("Plots")
            if plotsFolder then
                for _, plot in ipairs(plotsFolder:GetChildren()) do
                    local generators = plot:FindFirstChild("Generators")
                    if generators then
                        for _, gen in ipairs(generators:GetChildren()) do
                            local prompt = gen:FindFirstChild("CollectPrompt")
                            if prompt then
                                if prompt:IsA("ProximityPrompt") then
                                    pcall(fireproximityprompt, prompt)
                                elseif prompt:IsA("ClickDetector") then
                                    pcall(fireclickdetector, prompt)
                                end
                            end
                        end
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end)

-- 2) Auto Sell (evento a cada 1s)
task.spawn(function()
    while true do
        if getgenv().AutoSell then
            pcall(function()
                local ev = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Client")
                    :WaitForChild("Sell"):WaitForChild("SellRequest")
                ev:InvokeServer(true)
            end)
        end
        task.wait(1)
    end
end)

-- 3) Teleport a cada 30s para a área de venda [index 54] e volta
task.spawn(function()
    local player = Players.LocalPlayer
    while true do
        if getgenv().AutoSell then
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            local sellFolder = workspace:FindFirstChild("Shops") and workspace.Shops:FindFirstChild("Sell")
            if hrp and sellFolder then
                local children = sellFolder:GetChildren()
                local sellPart = children[54]  -- conforme você informou
                if sellPart and sellPart.CFrame then
                    local oldCFrame = hrp.CFrame
                    hrp.CFrame = sellPart.CFrame + Vector3.new(0, 5, 0)
                    task.wait(1.5)
                    hrp.CFrame = oldCFrame
                end
            end
        end
        task.wait(30)
    end
end)
