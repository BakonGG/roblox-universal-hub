-- Made by pompomsaturin | https://scriptblox.com/u/PomPomSaturin | If you need support please join my discord server and ping me
--LOADSTRING VERSION - loadstring(game:HttpGet("https://files.catbox.moe/0a6gbf.txt",true))()
local claimb = game.Players.LocalPlayer.PlayerGui.Bingo.StaticDisplayArea.Cards.PlayerArea.Cards.Container.SubContainer

local function click(btn)
    if not btn then return end
    for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
    for _, c in pairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
    for _, c in pairs(getconnections(btn.Activated)) do c:Fire() end
end

while true do
    task.wait()
    
    local claimc = claimb:FindFirstChild("Blocks") and claimb.Blocks.Block or claimb.VerticalScroll.Cards
    local claim = claimb.Buttons.ClaimButton

    if claimc and claim then
        for _, card in pairs(claimc:GetChildren()) do
            if card:IsA("Frame") then
                local content = card:FindFirstChild("Content")
                local nums = content and content:FindFirstChild("Numbers")
                if nums then
                    for _, n in pairs(nums:GetChildren()) do
                        click(n)
                        task.wait()
                    end
                end

                local toGo = card:FindFirstChild("ToGo")
                if toGo and toGo.ToGoText.Text == "BINGO!" then
                    click(claim)
                end
            end
        end
    end
end
