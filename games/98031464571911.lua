-- // GUI principal
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 280)
Frame.Position = UDim2.new(0.8, 0, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

-- // Título e botão minimizar
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -30, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.Text = "⚙️ Auto Farm Panel"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left

local Close = Instance.new("TextButton", Frame)
Close.Size = UDim2.new(0, 25, 0, 25)
Close.Position = UDim2.new(1, -30, 0, 5)
Close.Text = "➖"
Close.TextColor3 = Color3.fromRGB(255, 255, 100)
Close.BackgroundTransparency = 1
Close.Font = Enum.Font.SourceSansBold
Close.TextSize = 20

-- // Frame dos botões
local ButtonsFrame = Instance.new("Frame", Frame)
ButtonsFrame.Size = UDim2.new(1, 0, 1, -40)
ButtonsFrame.Position = UDim2.new(0, 0, 0, 35)
ButtonsFrame.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout", ButtonsFrame)
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- // Função de criação de botão
local function criarBotao(nome, cor)
	local botao = Instance.new("TextButton", ButtonsFrame)
	botao.Size = UDim2.new(0, 220, 0, 40)
	botao.Text = nome .. ": OFF"
	botao.TextColor3 = Color3.fromRGB(255, 255, 255)
	botao.BackgroundColor3 = cor or Color3.fromRGB(45, 45, 45)
	botao.Font = Enum.Font.SourceSansBold
	botao.TextSize = 18
	Instance.new("UICorner", botao).CornerRadius = UDim.new(0, 8)
	return botao
end

-- // Botões
local clickBtn = criarBotao("Auto Click")
local buyBtn = criarBotao("Auto Buy All")
local rebirthBtn = criarBotao("Auto Rebirth")
local kaitunBtn = criarBotao("Kaitun", Color3.fromRGB(70, 50, 120))

-- // Estados
local clickAtivo = false
local buyAtivo = false
local rebirthAtivo = false
local kaitunAtivo = false
local minimized = false

-- // Serviços Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = Shared:WaitForChild("Network")
local ClickEvent = Network:WaitForChild("Clicked")
local Packet = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Packet")
local RemoteEvent = Packet:WaitForChild("RemoteEvent")

-- // Sistema de notificações
local function showNotification(text, color)
	local notify = Instance.new("TextLabel", ScreenGui)
	notify.Size = UDim2.new(0, 260, 0, 40)
	notify.Position = UDim2.new(0.5, -130, 0.85, 0)
	notify.BackgroundColor3 = color
	notify.Text = text
	notify.TextColor3 = Color3.fromRGB(255, 255, 255)
	notify.Font = Enum.Font.SourceSansBold
	notify.TextSize = 20
	notify.BorderSizePixel = 0
	Instance.new("UICorner", notify).CornerRadius = UDim.new(0, 8)

	game:GetService("TweenService"):Create(notify, TweenInfo.new(0.4), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
	task.wait(1.2)
	game:GetService("TweenService"):Create(notify, TweenInfo.new(0.4), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
	task.wait(0.4)
	notify:Destroy()
end

-- // Lista de Upgrades
local upgrades = {
	"\002\014Furious Finger", "\002\018Witch\226\128\153s Cauldron", "\002\vGoblin Grip",
	"\002\fElixir Baker", "\002\021Elixir-Fueled Fingers", "\002\nRoyal Chef",
	"\002\nMighty Tap", "\002\016Magic Archer Aim", "\002\019P.E.K.K.A Precision",
	"\002\fGoblin Baker", "\002\rMirror Clicks", "\002\018Royal Tap Training",
	"\002\015Wizard\226\128\153s Oven", "\002\fGolden Touch", "\002\017Mother Witch Brew",
	"\002\018Champion\226\128\153s Swipe", "\002\015Princess Pastry", "\002\016King\226\128\153s Command",
	"\002\015Legendary Baker", "\002\nArena Moms", "\002\fGoblin Greed",
	"\002\021Bomber\226\128\153s Boom Bonus", "\002\022Princess\226\128\153s Precision",
	"\002\tCannonade", "\002\fTesla Tingle", "\002\015Fireball Frenzy",
	"\002\014Knightly Might", "\002\vSpell Surge", "\002\016Potion of Plenty"
}

-- // Minimizar GUI
Close.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		for _, obj in pairs(ButtonsFrame:GetChildren()) do
			if obj:IsA("TextButton") then obj.Visible = false end
		end
		Frame.Size = UDim2.new(0, 260, 0, 40)
		Close.Text = "➕"
	else
		for _, obj in pairs(ButtonsFrame:GetChildren()) do
			if obj:IsA("TextButton") then obj.Visible = true end
		end
		Frame.Size = UDim2.new(0, 260, 0, 280)
		Close.Text = "➖"
	end
end)

-- // AutoClick
task.spawn(function()
	while task.wait() do
		if clickAtivo or kaitunAtivo then
			pcall(function() ClickEvent:FireServer() end)
		end
	end
end)

-- // AutoBuy
task.spawn(function()
	while task.wait() do
		if buyAtivo or kaitunAtivo then
			for _, v in ipairs(upgrades) do
				pcall(function()
					local args = { buffer.fromstring(v) }
					RemoteEvent:FireServer(unpack(args))
				end)
			end
		end
	end
end)

-- // AutoRebirth
task.spawn(function()
	while task.wait() do
		if rebirthAtivo or kaitunAtivo then
			pcall(function()
				local args = { buffer.fromstring("\002\005Level") }
				RemoteEvent:FireServer(unpack(args))
			end)
		end
	end
end)

-- // Alternar botões com notificações
local function toggle(btn, varName, label)
	_G[varName] = not _G[varName]
	local ativo = _G[varName]
	btn.Text = label .. ": " .. (ativo and "ON" or "OFF")
	btn.BackgroundColor3 = ativo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(45, 45, 45)
	showNotification((ativo and "✅ " or "❌ ") .. label, ativo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(200, 50, 50))
	return ativo
end

clickBtn.MouseButton1Click:Connect(function() clickAtivo = toggle(clickBtn, "clickAtivo", "Auto Click") end)
buyBtn.MouseButton1Click:Connect(function() buyAtivo = toggle(buyBtn, "buyAtivo", "Auto Buy All") end)
rebirthBtn.MouseButton1Click:Connect(function() rebirthAtivo = toggle(rebirthBtn, "rebirthAtivo", "Auto Rebirth") end)

-- // Kaitun: ativa/desativa tudo
kaitunBtn.MouseButton1Click:Connect(function()
	kaitunAtivo = not kaitunAtivo
	kaitunBtn.Text = "Kaitun: " .. (kaitunAtivo and "ON" or "OFF")
	kaitunBtn.BackgroundColor3 = kaitunAtivo and Color3.fromRGB(140, 70, 255) or Color3.fromRGB(70, 50, 120)

	showNotification(
		(kaitunAtivo and "💜 Kaitun ativado! Fazendo tudo sozinho!" or "💤 Kaitun desativado."),
		kaitunAtivo and Color3.fromRGB(140, 70, 255) or Color3.fromRGB(100, 100, 100)
	)
end)