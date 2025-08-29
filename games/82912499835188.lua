-- Arquivo do jogo específico
return function()
    print("✅ Script do Hire a Fisher foi carregado!")

    -- Exemplo de abrir o hub (substitua pela função real do seu hub)
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/BakonGG/roblox-universal-hub/main/Library.lua"))()

    local Window = Library:CreateWindow("Hire a Fisher Hub")

    local Tab = Window:CreateTab("Principal")

    Tab:CreateButton("Auto Pescar", function()
        print("🎣 Auto pescar ativado")
        -- Coloque aqui o código de pesca automática
    end)

    Tab:CreateButton("Auto Vender", function()
        print("💰 Auto vender ativado")
        -- Coloque aqui o código de venda automática
    end)
end
