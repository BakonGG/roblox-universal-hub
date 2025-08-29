-- fallback.lua
local msg = ("Este jogo (PlaceId %s) ainda não tem script neste repositório."):format(tostring(game.PlaceId))
warn(msg)

-- Se quiser uma janelinha simples usando Shadow Lib:
local ok, ShadowLib = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/main/Shadow%20Lib.txt"
    ))()
end)

if ok and ShadowLib then
    local Window = ShadowLib:Window("Meu Hub (sem suporte)", Color3.fromRGB(128,128,128), Enum.KeyCode.RightControl)
    local Tab = Window:Tab("Info")
    -- Algumas libs têm :Label, outras não; usar Button para garantir:
    Tab:Button("PlaceId: ".. tostring(game.PlaceId), function() setclipboard(tostring(game.PlaceId)) end)
end
