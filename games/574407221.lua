--// Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Tycoon alvo
local tycoon = workspace.Tycoons["9"]

--// Toggles
local autoBuyEnabled = false
local autoCollectEnabled = false
local autoClickEnabled = false

--// Lista de botões bloqueados
local blockedPrefixes = {
    "Buy Automatic Turret",
    "Buy Extra Bunker",
    "Buy x2 Cash Upgrader",
    "Buy Rainbow Upgrader_2",
}

local function isBlocked(name: string)
    for _, prefix in ipairs(blockedPrefixes) do
        if string.sub(name, 1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
end

--// Função para comprar um botão
local function tryBuy(button: Instance)
    if not button or isBlocked(button.Name) then return end

    local touchPart

    -- Caso comum: Primary com TouchInterest
    if button:IsA("Model") then
        local primary = button:FindFirstChild("Primary")
        if primary and primary:IsA("BasePart") and primary:FindFirstChildOfClass("TouchTransmitter") then
            touchPart = primary
        end
    end

    -- Procura qualquer TouchTransmitter dentro do botão
    if not touchPart then
        for _, desc in ipairs(button:GetDescendants()) do
            if desc:IsA("TouchTransmitter") and desc.Parent:IsA("BasePart") then
                touchPart = desc.Parent
                break
            end
        end
    end

    -- Se o próprio botão for um BasePart com TouchInterest
    if not touchPart and button:IsA("BasePart") then
        if button:FindFirstChildOfClass("TouchTransmitter") then
            touchPart = button
        end
    end

    if not touchPart then return end

    local hrp = getHRP()
    if not hrp then return end

    pcall(function()
        firetouchinterest(hrp, touchPart, 0)
        task.wait(0.07)
        firetouchinterest(hrp, touchPart, 1)
    end)
end

--// Auto-Buy
task.spawn(function()
    while true do
        if autoBuyEnabled then
            for _, button in ipairs(tycoon.Buttons:GetChildren()) do
                if not isBlocked(button.Name) then
                    tryBuy(button)
                    task.wait(0.05)
                end
            end
        end
        task.wait(0.6)
    end
end)

tycoon.Buttons.ChildAdded:Connect(function(child)
    task.wait(0.05)
    if autoBuyEnabled and not isBlocked(child.Name) then
        tryBuy(child)
    end
end)

--// Auto-Collect (coleta no Pad)
task.spawn(function()
    while true do
        if autoCollectEnabled then
            local hrp = getHRP()
            local pad = tycoon.Extras.Collector:FindFirstChild("Pad")
            if hrp and pad and pad:FindFirstChildOfClass("TouchTransmitter") then
                pcall(function()
                    firetouchinterest(hrp, pad, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, pad, 1)
                end)
            end
        end
        task.wait(1.5)
    end
end)

--// Auto-Click
task.spawn(function()
    while true do
        if autoClickEnabled then
            local cd = tycoon.Extras.IgnoredBase["1stFloorClickToEarn"].clicker:FindFirstChildOfClass("ClickDetector")
            if cd then
                pcall(function()
                    fireclickdetector(cd)
                end)
            end
        end
        task.wait(0.2)
    end
end)

----------------------------------------------------------------
-- GUI (canto superior direito)
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "TycoonHelperUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function makeButton(label, yOffset, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = UDim2.new(1, -210, 0, yOffset)
    btn.AnchorPoint = Vector2.new(0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = label .. ": OFF"
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = ScreenGui

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        onToggle(state)
        btn.Text = label .. (state and ": ON" or ": OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(40, 40, 40)
    end)

    return btn
end

makeButton("Auto Buy", 20, function(on) autoBuyEnabled = on end)
makeButton("Auto Collect", 70, function(on) autoCollectEnabled = on end)
makeButton("Auto Click", 120, function(on) autoClickEnabled = on end)
