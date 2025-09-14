-- GUI principal
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0.05, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true -- deixa arrastável!

UIListLayout.Parent = Frame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local toggles = {}

-- Função auxiliar para criar botões
local function criarBotao(nome, callback)
    local Button = Instance.new("TextButton")
    Button.Parent = Frame
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.Text = nome .. " [OFF]"
    Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

    local ativo = false

    Button.MouseButton1Click:Connect(function()
        ativo = not ativo
        if ativo then
            Button.Text = nome .. " [ON]"
            Button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            toggles[nome] = true
            callback(true)
        else
            Button.Text = nome .. " [OFF]"
            Button.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            toggles[nome] = false
            callback(false)
        end
    end)
end

--------------------------------------------------
-- 1: Auto Click
criarBotao("Auto Click", function(estado)
    task.spawn(function()
        while estado and toggles["Auto Click"] do
            game:GetService("ReplicatedStorage"):WaitForChild("Click"):WaitForChild("Click"):FireServer()
            task.wait(0.05) -- rápido
        end
    end)
end)

-- 2: Auto Peixe (apenas farma peixe, sem comprar upgrades)
criarBotao("Auto Peixe", function(estado)
    task.spawn(function()
        while estado and toggles["Auto Peixe"] do
            local args = {"add", 10000}
            game:GetService("ReplicatedStorage"):WaitForChild("CurrencyTransaction"):FireServer(unpack(args))
            task.wait(0.2)
        end
    end)
end)

-- 3: Auto Click Upgrades (prioriza últimos + rebirth)
criarBotao("Auto Click Upgrades", function(estado)
    task.spawn(function()
        local comprasClick = {
            "aCursor","bAutoClicker","cMrClicker","dCatsFarm","ePresidentClicker","fCatsPump",
            "gKingClicker","hCatsFactory","iEmperorClicker","jCatsPyramid","kPopeClicker",
            "lCatsTemple","mGodClicker","nCatsPowerPlant","oTheClicker"
        }

        while estado and toggles["Auto Click Upgrades"] do
            -- Tentar comprar do último até o primeiro
            for i = #comprasClick, 1, -1 do
                local upgrade = game:GetService("ReplicatedStorage"):WaitForChild("Shop"):FindFirstChild(comprasClick[i])
                if upgrade then
                    upgrade:FireServer()
                    task.wait(0.1)
                end
            end

            -- Rebirth automático
            game:GetService("ReplicatedStorage"):WaitForChild("Rebirth"):FireServer()

            task.wait(1)
        end
    end)
end)
