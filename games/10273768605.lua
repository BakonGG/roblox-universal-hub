-- ⚠️ Necessário executor que suporte fireproximityprompt e firetouchinterest
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- Controle ON/OFF
local enabled = true

-- Criar GUI de toggle
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AutoTycoonGUI"

local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.new(0, 120, 0, 40)
toggleBtn.Position = UDim2.new(0, 20, 0, 200)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "Auto: ON"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 20

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleBtn.Text = enabled and "Auto: ON" or "Auto: OFF"
    toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
end)

-- Forçar prompt mesmo longe
local function firePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = math.huge
        fireproximityprompt(prompt)
    end
end

-- Forçar toque
local function fireTouch(touch)
    if touch and touch:IsA("TouchTransmitter") then
        firetouchinterest(hrp, touch.Parent, 0)
        task.wait()
        firetouchinterest(hrp, touch.Parent, 1)
    end
end

-- Lista de botões proibidos
local blockedButtons = {
    workspace.Tycoons.PurpleTycoon.Buttons:WaitForChild("RainbowCooler"),
    workspace.Tycoons.PurpleTycoon.Buttons:WaitForChild("VIP")
}

local function isBlocked(button)
    for _, blocked in ipairs(blockedButtons) do
        if button == blocked or button:IsDescendantOf(blocked) then
            return true
        end
    end
    return false
end

-- Loop dos cliques
task.spawn(function()
    while task.wait(0.2) do
        if enabled then
            firePrompt(workspace.Tycoons.PurpleTycoon.Essentials.ManualButtons.Clicker.Main.ProximityPrompt)
            firePrompt(workspace.Tycoons.PurpleTycoon.Essentials.ManualButtons.Machine.Main.ProximityPrompt)
        end
    end
end)

-- Loop das compras
task.spawn(function()
    while task.wait(0.5) do
        if enabled then
            for _, obj in pairs(workspace.Tycoons.PurpleTycoon.Buttons:GetDescendants()) do
                if obj:IsA("TouchTransmitter") and not isBlocked(obj.Parent) then
                    fireTouch(obj)
                end
            end
        end
    end
end)
