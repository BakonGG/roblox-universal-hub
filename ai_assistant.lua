--[[
    Bakon's AI Script Generator (OpenRouter)
    Powered by LLM models via OpenRouter API
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

---------------------------------------------------------
-- CONFIGURAÇÕES & HTTP POLYFILL
---------------------------------------------------------
getgenv().OpenRouterAPIKey = getgenv().OpenRouterAPIKey or ""
local CURRENT_MODEL = "google/gemini-2.5-flash:free"
-- local CURRENT_MODEL = "meta-llama/llama-3-8b-instruct:free"

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
if not httpRequest then
    warn("[AI Assistant] O seu executor não suporta requisições HTTP (request). O script não funcionará.")
end

---------------------------------------------------------
-- UI LIBRARY (Usando a mesma FriseX/Orion custom)
---------------------------------------------------------
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/BakonGG/FriseX/main/Library.lua"))()

local Window = Library:CreateWindow("Bakon's AI Assistant 🤖", "Beta v1.0", "Auto-Hacker")

local TabChat = Window:CreatePage("Chat AI 💬")
local TabSettings = Window:CreatePage("Configurações ⚙️")

---------------------------------------------------------
-- VARIÁVEIS DE ESTADO
---------------------------------------------------------
local ConversationHistory = {
    {
        role = "system",
        content = [[Você é um programador especialista em Roblox Lua (Exploiting/Executors).
O usuário pedirá scripts e você deve gerar o código Lua.
REGRAS CRÍTICAS:
1. Retorne APENAS o código Lua envolto em blocos ```lua ... ```.
2. Seja extremamente conciso nas explicações fora do código.
3. Se o script der erro, o usuário enviará o erro e você deve corrigir.
4. Adicione logs `print()` no seu código para facilitar o debug (ex: print("[AI] Tentando fazer X")).
5. Use `pcall` para operações arriscadas.]]
    }
}

local IsInspecting = false
local ConnectionInspect = nil
local LastGeneratedCode = ""
local CodeEditorLabel = nil
local ChatLogLabel = nil

---------------------------------------------------------
-- FUNÇÕES DE IA
---------------------------------------------------------
local function AddToChatLog(sender, text)
    if ChatLogLabel then
        local current = ChatLogLabel.Text
        ChatLogLabel.Text = current .. "\n\n[" .. sender .. "]: " .. text
    else
        print("[" .. sender .. "]: " .. text)
    end
end

local function ExtractLuaCode(text)
    local code = string.match(text, "```lua\n(.-)```")
    if not code then
        code = string.match(text, "```\n(.-)```")
    end
    if not code then
        code = text -- fallback
    end
    return code
end

local function SendToAI(userMessage)
    if getgenv().OpenRouterAPIKey == "" then
        AddToChatLog("ERRO", "Chave da API não configurada! Vá na aba Configurações.")
        return
    end
    
    AddToChatLog("Você", userMessage)
    
    table.insert(ConversationHistory, { role = "user", content = userMessage })
    
    local body = HttpService:JSONEncode({
        model = CURRENT_MODEL,
        messages = ConversationHistory
    })
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. getgenv().OpenRouterAPIKey,
        ["HTTP-Referer"] = "https://roblox.com",
        ["X-Title"] = "Bakon AI Assistant"
    }
    
    local response = httpRequest({
        Url = "https://openrouter.ai/api/v1/chat/completions",
        Method = "POST",
        Headers = headers,
        Body = body
    })
    
    if response and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data.choices and data.choices[1] and data.choices[1].message then
            local aiText = data.choices[1].message.content
            table.insert(ConversationHistory, { role = "assistant", content = aiText })
            
            AddToChatLog("IA", aiText)
            
            local code = ExtractLuaCode(aiText)
            LastGeneratedCode = code
            if CodeEditorLabel then
                CodeEditorLabel.Text = "-- Script Gerado:\n" .. code
            end
        else
            AddToChatLog("ERRO", "Resposta inválida da API.")
        end
    else
        local err = response and response.Body or "Erro desconhecido"
        AddToChatLog("ERRO HTTP", tostring(response.StatusCode) .. " - " .. err)
    end
end

---------------------------------------------------------
-- INSPECIONADOR (CONTA-GOTAS)
---------------------------------------------------------
local function GetInstancePath(obj)
    local path = obj.Name
    if not string.match(path, "^[%w_]+$") then
        path = '["' .. path .. '"]'
    end
    
    local parent = obj.Parent
    while parent and parent ~= game do
        local pName = parent.Name
        if parent == workspace then
            pName = "workspace"
        elseif not string.match(pName, "^[%w_]+$") then
            pName = '["' .. pName .. '"]'
        end
        
        if string.sub(path, 1, 1) == "[" then
            path = pName .. path
        else
            path = pName .. "." .. path
        end
        parent = parent.Parent
    end
    return path
end

local function ToggleInspector()
    IsInspecting = not IsInspecting
    if IsInspecting then
        AddToChatLog("SISTEMA", "Conta-Gotas ativado! Clique em uma peça no jogo para enviar à IA.")
        ConnectionInspect = Mouse.Button1Down:Connect(function()
            local target = Mouse.Target
            if target then
                local path = GetInstancePath(target)
                local msg = "Peça inspecionada:\nCaminho: `" .. path .. "`\nClasse: " .. target.ClassName
                
                -- Se tiver SurfaceGui/BillboardGui
                if target:FindFirstChildOfClass("SurfaceGui") or target:FindFirstChildOfClass("BillboardGui") then
                    msg = msg .. "\nContém Interface Gráfica dentro dela."
                end
                
                if target:FindFirstChildOfClass("ClickDetector") then
                    msg = msg .. "\nContém ClickDetector."
                end
                
                if target:FindFirstChildOfClass("TouchTransmitter") then
                    msg = msg .. "\nContém TouchInterest (pisar)."
                end
                
                -- Envia silenciosamente o contexto para a IA
                table.insert(ConversationHistory, { role = "system", content = msg })
                AddToChatLog("SISTEMA", "Peça salva no contexto da IA: " .. path)
                
                -- Desliga o inspecionador após clicar
                IsInspecting = false
                ConnectionInspect:Disconnect()
            end
        end)
    else
        if ConnectionInspect then ConnectionInspect:Disconnect() end
        AddToChatLog("SISTEMA", "Conta-Gotas desativado.")
    end
end

---------------------------------------------------------
-- EXECUTOR DE SCRIPT & AUTO-ERROR
---------------------------------------------------------
local function ExecuteAICode()
    if LastGeneratedCode == "" then return end
    AddToChatLog("SISTEMA", "Executando script...")
    
    local func, err = loadstring(LastGeneratedCode)
    if not func then
        AddToChatLog("ERRO DE SINTAXE", err)
        SendToAI("O script que você enviou teve um erro de SINTAXE:\n" .. tostring(err) .. "\n\nPor favor, corrija e mande o código inteiro novamente.")
        return
    end
    
    local success, runErr = pcall(func)
    if not success then
        AddToChatLog("ERRO DE EXECUÇÃO", runErr)
        SendToAI("O script que você enviou teve um erro durante a EXECUÇÃO:\n" .. tostring(runErr) .. "\n\nPor favor, corrija e mande o código inteiro novamente. Coloque prints para ajudar no debug.")
    else
        AddToChatLog("SISTEMA", "Script executado com sucesso!")
    end
end

---------------------------------------------------------
-- ABA: CHAT AI
---------------------------------------------------------
local ChatSection = TabChat:CreateSection("Conversa")

ChatLogLabel = ChatSection:CreateLabel("Bem-vindo ao AI Assistant!\nColoque sua API Key nas configurações primeiro.")

ChatSection:CreateTextBox({
    Name = "Falar com a IA:",
    PlaceholderText = "Digite seu pedido aqui...",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        if text and text ~= "" then
            -- Roda em paralelo para não travar a UI
            task.spawn(function()
                SendToAI(text)
            end)
        end
    end;
})

local ScriptSection = TabChat:CreateSection("Script Gerado (Bloco de Notas)")

CodeEditorLabel = ScriptSection:CreateLabel("-- O código gerado aparecerá aqui --")

ScriptSection:CreateButton({
    Name = "▶️ Executar Script",
    Callback = function()
        ExecuteAICode()
    end;
})

ScriptSection:CreateButton({
    Name = "📋 Copiar Script",
    Callback = function()
        if setclipboard then
            setclipboard(LastGeneratedCode)
            AddToChatLog("SISTEMA", "Script copiado para a área de transferência!")
        end
    end;
})

ScriptSection:CreateButton({
    Name = "🔍 Inspecionar Peça (Conta-Gotas)",
    Callback = function()
        ToggleInspector()
    end;
})

---------------------------------------------------------
-- ABA: CONFIGURAÇÕES
---------------------------------------------------------
local SettingsSec = TabSettings:CreateSection("API Key (OpenRouter)")

SettingsSec:CreateTextBox({
    Name = "OpenRouter API Key:",
    PlaceholderText = "sk-or-v1-...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        getgenv().OpenRouterAPIKey = text
        AddToChatLog("SISTEMA", "API Key atualizada!")
    end;
})

SettingsSec:CreateButton({
    Name = "Limpar Histórico do Chat",
    Callback = function()
        ConversationHistory = { ConversationHistory[1] } -- Mantém só o system prompt
        ChatLogLabel.Text = "Histórico limpo. IA pronta."
        LastGeneratedCode = ""
        if CodeEditorLabel then CodeEditorLabel.Text = "-- O código gerado aparecerá aqui --" end
    end;
})
