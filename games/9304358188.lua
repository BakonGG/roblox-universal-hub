local player = game.Players.LocalPlayer
local humroot = player.Character.HumanoidRootPart

for _, pal in pairs(game.Workspace.Pals:GetDescendants()) do
    if pal:IsA('BasePart') then
        pal.CFrame = humroot.CFrame
    elseif pal:IsA('Model') and pal.PrimaryPart then
        pal:SetPrimaryPartCFrame(humroot.CFrame)
    end
end
