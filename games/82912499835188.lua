-- Games/82912499835188.lua

return function()
    -- aqui vai o código do hub específico do jogo
    print("✅ Script do jogo carregado com sucesso!")

    -- exemplo: botão de auto sell
    local player = game.Players.LocalPlayer
    local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 50)
    button.Position = UDim2.new(0.5, -100, 0.8, 0)
    button.Text = "Auto Sell"
    button.Parent = gui

    local autoSell = false
    button.MouseButton1Click:Connect(function()
        autoSell = not autoSell
        button.Text = autoSell and "Auto Sell: ON" or "Auto Sell: OFF"

        while autoSell do
            task.wait(2)
            -- ajusta para o ponto de venda certo
            for _, plot in ipairs(workspace.Plots:GetChildren()) do
                for _, obj in ipairs(workspace.Shops.Sell:GetChildren()) do
                    fireproximityprompt(obj.ProximityPrompt)
                end
            end
        end
    end)
end
