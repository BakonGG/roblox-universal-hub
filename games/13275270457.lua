-- LocalScript - StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- =========[ Player / Personagem ]=========
local character
local humanoid
local hrp

local function bindCharacter(char)
	character = char
	hrp = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
end

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(bindCharacter)

-- =========[ Funções úteis ]=========
local function isDescendantOfWorkspace(inst)
	local p = inst
	while p do
		if p == workspace then return true end
		p = p.Parent
	end
	return false
end

local function getTouchPart(inst)
	if not inst or not inst.Parent then return nil end
	if inst:IsA("BasePart") then return inst end
	if inst:IsA("Model") then
		if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") then
			return inst.PrimaryPart
		else
			return inst:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	return nil
end

local function clickPart(part)
	if not part or not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local touch = part:FindFirstChildOfClass("TouchTransmitter")
	if touch then
		firetouchinterest(hrp, part, 0)
		firetouchinterest(hrp, part, 1)
	end
end

local function getMyTycoon()
	local tycoons = workspace:FindFirstChild("Tycoons")
	if not tycoons then return nil end
	for _, tycoon in ipairs(tycoons:GetChildren()) do
		local owner = tycoon:FindFirstChild("Owner")
		if owner and owner.Value == player then
			return tycoon
		end
	end
	return nil
end

-- =========[ UI: Botões ]=========
local function createButton(name, position, text)
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("AutoFarmGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "AutoFarmGui"
		gui.ResetOnSpawn = false
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.fromOffset(170, 44)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 16
	btn.Text = text
	btn.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	return btn
end

local toggleCollectButton = createButton("CollectToggle", UDim2.new(1, -180, 0, 10), "Auto Coletar: OFF")
local farmButton = createButton("FarmButton", UDim2.new(1, -180, 0, 60), "Auto Farm: OFF")
local buyButton = createButton("BuyButton", UDim2.new(1, -180, 0, 110), "Auto Buy: OFF")

-- =========[ Estados ]=========
local collecting = false
local watching = false
local autoFarm = false
local autoBuy = false

local activeConns = {}
local dropQueue = {}
local queuedSet = setmetatable({}, { __mode = "k" })

-- =========[ Funções de coleta/TP ]=========
local function enqueueDrop(drop)
	if not drop or not drop.Parent then return end
	if queuedSet[drop] then return end
	local part = getTouchPart(drop)
	if not part then return end

	table.insert(dropQueue, drop)
	queuedSet[drop] = true

	drop.Destroying:Connect(function()
		queuedSet[drop] = nil
	end)
end

local function tpToDrop(drop)
	if not collecting or not character or not hrp or not humanoid then return end
	if not drop or not drop.Parent then return end

	local part = getTouchPart(drop)
	if not part or not part.Parent then return end
	if not isDescendantOfWorkspace(drop) then return end

	if humanoid.Sit then humanoid.Sit = false end

	local above = part.CFrame + Vector3.new(0, math.max(3, part.Size.Y), 0)
	local overlap = part.CFrame

	hrp.CFrame = above
	task.wait(0.05)
	hrp.CFrame = overlap
	task.wait(0.08)
end

local function processQueue()
	while collecting do
		-- limpa drops inválidos
		for i = #dropQueue, 1, -1 do
			local drop = dropQueue[i]
			if not drop or not drop.Parent then
				table.remove(dropQueue, i)
				queuedSet[drop] = nil
			end
		end

		-- teleporta para todos os drops
		for _, drop in ipairs(dropQueue) do
			if drop and drop.Parent then
				tpToDrop(drop)
			end
		end

		task.wait(0.1)
	end
end

local function watchCurrentDropsFolder(folder)
	for _, child in ipairs(folder:GetChildren()) do
		enqueueDrop(child)
	end

	local conn = folder.ChildAdded:Connect(function(child)
		if collecting then
			enqueueDrop(child)
		end
	end)
	table.insert(activeConns, conn)
end

local function startWatching()
	if watching then return end
	watching = true

	local tycoonsFolder = workspace:FindFirstChild("Tycoons")
	if not tycoonsFolder then
		watching = false
		return
	end

	for _, tycoon in ipairs(tycoonsFolder:GetChildren()) do
		local currentDrops = tycoon:FindFirstChild("CurrentDrops")
		if currentDrops and currentDrops:IsA("Folder") then
			watchCurrentDropsFolder(currentDrops)
		end
	end

	local c1 = tycoonsFolder.ChildAdded:Connect(function(tycoon)
		local currentDrops = tycoon:FindFirstChild("CurrentDrops")
		if currentDrops and currentDrops:IsA("Folder") then
			watchCurrentDropsFolder(currentDrops)
		else
			local c2
			c2 = tycoon.ChildAdded:Connect(function(obj)
				if obj.Name == "CurrentDrops" and obj:IsA("Folder") then
					watchCurrentDropsFolder(obj)
				end
			end)
			table.insert(activeConns, c2)
		end
	end)
	table.insert(activeConns, c1)
end

local function stopWatching()
	for _, conn in ipairs(activeConns) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	activeConns = {}
	watching = false
end

local function clearQueue()
	table.clear(dropQueue)
	queuedSet = setmetatable({}, { __mode = "k" })
end

local function setCollecting(state)
	collecting = state

	if collecting then
		toggleCollectButton.Text = "Auto Coletar: ON"
		toggleCollectButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		startWatching()
		task.spawn(processQueue)
	else
		toggleCollectButton.Text = "Auto Coletar: OFF"
		toggleCollectButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		stopWatching()
		clearQueue()
	end
end

-- =========[ Conexões de botões ]=========
toggleCollectButton.MouseButton1Click:Connect(function()
	setCollecting(not collecting)
end)

farmButton.MouseButton1Click:Connect(function()
	autoFarm = not autoFarm
	if autoFarm then
		farmButton.Text = "Auto Farm: ON"
		farmButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	else
		farmButton.Text = "Auto Farm: OFF"
		farmButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	end
end)

buyButton.MouseButton1Click:Connect(function()
	autoBuy = not autoBuy
	if autoBuy then
		buyButton.Text = "Auto Buy: ON"
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	else
		buyButton.Text = "Auto Buy: OFF"
		buyButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	end
end)

-- =========[ Alternância automática de Auto Coletar ]=========
task.spawn(function()
	while true do
		task.wait(30)
		setCollecting(not collecting)
	end
end)

-- =========[ Loop de Auto Farm (coleta de drops) ]=========
RunService.Heartbeat:Connect(function()
	if not autoFarm then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	local tycoons = workspace:FindFirstChild("Tycoons")
	if tycoons then
		for _, tycoon in ipairs(tycoons:GetChildren()) do
			local drops = tycoon:FindFirstChild("CurrentDrops")
			if drops then
				for _, drop in ipairs(drops:GetChildren()) do
					local part = getTouchPart(drop)
					if part then
						clickPart(part)
					end
				end
			end
		end
	end
end)

-- =========[ Loop de Auto Deposit / Merge a cada 30s ]=========
task.spawn(function()
	while true do
		task.wait(30)
		if autoFarm then
			local myTycoon = getMyTycoon()
			if myTycoon then
				local buttons = myTycoon:FindFirstChild("OtherButtons")
				if buttons then
					local deposit = buttons:FindFirstChild("Deposit")
					if deposit and deposit:FindFirstChild("ActivePart") then
						clickPart(deposit.ActivePart)
					end

					local merge = buttons:FindFirstChild("Merge")
					if merge and merge:FindFirstChild("ActivePart") then
						clickPart(merge.ActivePart)
					end
				end
			end
		end
	end
end)

-- =========[ Loop de Auto Buy a cada 2s ]=========
task.spawn(function()
	while true do
		task.wait(2)
		if autoBuy then
			local myTycoon = getMyTycoon()
			if myTycoon then
				local buyButtons = myTycoon:FindFirstChild("BuyItemButtons")
				if buyButtons then
					for _, button in ipairs(buyButtons:GetChildren()) do
						if button:FindFirstChild("ActivePart") then
							clickPart(button.ActivePart)
						end
					end
				end
			end
		end
	end
end)
