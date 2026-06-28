local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BakonScriptsHub"
screenGui.ResetOnSpawn = false

-- Use CoreGui if executor supports it, otherwise PlayerGui
local success, err = pcall(function()
    screenGui.Parent = CoreGui
end)
if not success then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Function to format numbers with commas
local function formatNumber(n)
    n = tostring(n)
    return n:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Main Frame (More beautiful)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 215)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -120)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(60, 60, 75)
uiStroke.Thickness = 1.5
uiStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Bakon's Scripts"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Hide Button
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -40, 0, 10)
hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
hideBtn.Text = "—"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 14
hideBtn.Parent = mainFrame

local hideBtnCorner = Instance.new("UICorner")
hideBtnCorner.CornerRadius = UDim.new(0, 8)
hideBtnCorner.Parent = hideBtn

-- Open Button (Mini button when hidden)
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 120, 0, 35)
openBtn.Position = UDim2.new(0, 15, 0, 15) -- Top left, below Roblox menu
openBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
openBtn.Text = "Bakon's Scripts"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Visible = false
openBtn.Parent = screenGui

local openBtnCorner = Instance.new("UICorner")
openBtnCorner.CornerRadius = UDim.new(0, 8)
openBtnCorner.Parent = openBtn

local openBtnStroke = Instance.new("UIStroke")
openBtnStroke.Color = Color3.fromRGB(60, 60, 75)
openBtnStroke.Thickness = 1
openBtnStroke.Parent = openBtn

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 55, 0, 55)
avatarImage.Position = UDim2.new(0, 15, 0, 50)
avatarImage.BackgroundTransparency = 1
avatarImage.Parent = mainFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarImage

-- Load Profile Picture
task.spawn(function()
    local userId = player.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    if isReady then
        avatarImage.Image = content
    end
end)

local userLabel = Instance.new("TextLabel")
userLabel.Size = UDim2.new(0, 220, 0, 25)
userLabel.Position = UDim2.new(0, 85, 0, 50)
userLabel.BackgroundTransparency = 1
userLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
userLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
userLabel.Font = Enum.Font.GothamBold
userLabel.TextSize = 15
userLabel.TextXAlignment = Enum.TextXAlignment.Left
userLabel.Parent = mainFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0, 220, 0, 25)
moneyLabel.Position = UDim2.new(0, 85, 0, 75)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "Dinheiro: $0"
moneyLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
moneyLabel.Font = Enum.Font.Gotham
moneyLabel.TextSize = 14
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = mainFrame

local spentLabel = Instance.new("TextLabel")
spentLabel.Size = UDim2.new(1, -30, 0, 25)
spentLabel.Position = UDim2.new(0, 15, 0, 115)
spentLabel.BackgroundTransparency = 1
spentLabel.Text = "Gasto (Sessão): $0"
spentLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
spentLabel.Font = Enum.Font.Gotham
spentLabel.TextSize = 14
spentLabel.TextXAlignment = Enum.TextXAlignment.Left
spentLabel.Parent = mainFrame

local autoBuyBtn = Instance.new("TextButton")
autoBuyBtn.Size = UDim2.new(1, -30, 0, 45)
autoBuyBtn.Position = UDim2.new(0, 15, 0, 150)
autoBuyBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 0)
autoBuyBtn.Text = "Auto Comprar: LIGADO"
autoBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBuyBtn.Font = Enum.Font.GothamBold
autoBuyBtn.TextSize = 16
autoBuyBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = autoBuyBtn

-- Variables
local autoBuyEnabled = true
local sessionSpent = 0
local currentMoneyValue = 0

-- UI Button Connections
hideBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBtn.Visible = true
end)

openBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openBtn.Visible = false
end)

autoBuyBtn.MouseButton1Click:Connect(function()
    autoBuyEnabled = not autoBuyEnabled
    if autoBuyEnabled then
        autoBuyBtn.Text = "Auto Comprar: LIGADO"
        autoBuyBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 0)
    else
        autoBuyBtn.Text = "Auto Comprar: DESLIGADO"
        autoBuyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
end)

-- Toggle UI with Right Shift (kept as a shortcut)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        if mainFrame.Visible then
            mainFrame.Visible = false
            openBtn.Visible = true
        else
            mainFrame.Visible = true
            openBtn.Visible = false
        end
    end
end)

-- Function to find user's tycoon
local function getMyTycoon()
    local playerName = player.Name
    local tycoons = workspace:FindFirstChild("Tycoons")
    if tycoons then
        for _, tycoon in ipairs(tycoons:GetChildren()) do
            local values = tycoon:FindFirstChild("Values")
            if values then
                local owner = values:FindFirstChild("Owner")
                if owner then
                    local isOwner = false
                    
                    if owner:IsA("ObjectValue") and owner.Value == player then
                        isOwner = true
                    elseif owner:IsA("StringValue") and (owner.Value == playerName or owner.Value == player.DisplayName) then
                        isOwner = true
                    elseif tostring(owner.Value) == playerName then
                        isOwner = true
                    end
                    
                    if isOwner then
                        return tycoon
                    end
                end
            end
        end
    end
    return nil
end

-- Update Money Loop
task.spawn(function()
    while task.wait(0.5) do
        local newMoney = 0
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cash = leaderstats:FindFirstChild("Money")
            if cash then
                newMoney = cash.Value
            end
        end
        
        if currentMoneyValue > 0 and newMoney < currentMoneyValue then
            sessionSpent = sessionSpent + (currentMoneyValue - newMoney)
        end
        
        currentMoneyValue = newMoney
        moneyLabel.Text = "Dinheiro: $" .. formatNumber(currentMoneyValue)
        spentLabel.Text = "Gasto (Sessão): $" .. formatNumber(sessionSpent)
    end
end)

-- Auto Collect Money provided by user
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("__remotes"):WaitForChild("TycoonService"):WaitForChild("CollectMoneyTS"):FireServer()
        end)
    end
end)

-- Helper Functions for Auto Buy
local function parsePrice(text)
    local clean = string.gsub(text, "[%$%, ]", "")
    local suffix = string.sub(clean, -1)
    local multiplier = 1
    
    if suffix == "K" or suffix == "k" then
        multiplier = 1000
        clean = string.sub(clean, 1, -2)
    elseif suffix == "M" or suffix == "m" then
        multiplier = 1000000
        clean = string.sub(clean, 1, -2)
    elseif suffix == "B" or suffix == "b" then
        multiplier = 1000000000
        clean = string.sub(clean, 1, -2)
    elseif suffix == "T" or suffix == "t" then
        multiplier = 1000000000000
        clean = string.sub(clean, 1, -2)
    end
    
    local num = tonumber(clean)
    if num then
        return num * multiplier
    end
    return nil
end

local function getPrice(button)
    for _, desc in ipairs(button:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local textToUse = desc.Text
            if desc.ContentText and desc.ContentText ~= "" then
                textToUse = desc.ContentText
            end
            
            if string.find(textToUse, "%$") then
                return parsePrice(textToUse)
            end
        end
    end
    return nil
end

local function clickButton(btnModel)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if btnModel:IsA("BasePart") and btnModel:FindFirstChildOfClass("TouchTransmitter") then
        firetouchinterest(hrp, btnModel, 0)
        firetouchinterest(hrp, btnModel, 1)
        return
    end

    local pressPart = btnModel:FindFirstChild("Press")
    if pressPart and pressPart:IsA("BasePart") then
        firetouchinterest(hrp, pressPart, 0)
        firetouchinterest(hrp, pressPart, 1)
        return
    end

    for _, desc in ipairs(btnModel:GetDescendants()) do
        if desc:IsA("BasePart") and desc:FindFirstChildOfClass("TouchTransmitter") then
            firetouchinterest(hrp, desc, 0)
            firetouchinterest(hrp, desc, 1)
            return
        end
    end
    
    local fallback = btnModel:IsA("BasePart") and btnModel or btnModel:FindFirstChildWhichIsA("BasePart", true)
    if fallback then
        firetouchinterest(hrp, fallback, 0)
        firetouchinterest(hrp, fallback, 1)
    end
end

-- Auto Buy Logic
task.spawn(function()
    while task.wait(0.25) do
        if autoBuyEnabled then
            local myTycoon = getMyTycoon()
            if myTycoon then
                local currentMoney = 0
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats and leaderstats:FindFirstChild("Money") then
                    currentMoney = leaderstats.Money.Value
                end
                
                if currentMoney > 0 then
                    local availableButtons = {}
                    local tycoonFolder = myTycoon:FindFirstChild("Tycoon") or myTycoon
                    
                    for _, desc in ipairs(tycoonFolder:GetDescendants()) do
                        if string.find(string.lower(desc.Name), "buttons") then
                            for _, btn in ipairs(desc:GetChildren()) do
                                local price = getPrice(btn)
                                if price then
                                    table.insert(availableButtons, {button = btn, price = price})
                                end
                            end
                        end
                    end
                    
                    table.sort(availableButtons, function(a, b) return a.price < b.price end)
                    
                    for _, data in ipairs(availableButtons) do
                        if currentMoney >= data.price then
                            clickButton(data.button)
                            task.wait(0.1)
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
