-- AutoFarm Supremo Nível 2 - Com GUI e AntiBan
-- Início do Script

local plr = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local commF = rs:WaitForChild("Remotes").CommF_
local vim = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações iniciais
local config = {
    arma = "Katana",
    usarSkills = true,
    autoSetSpawn = true,
    delayAtaqueMin = 0.12,
    delayAtaqueMax = 0.25,
    autoBoss = true,
    webhookURL = "", -- Coloque seu Discord webhook aqui
    notificacoesAtivas = true,
}

-- GUI básica
local ScreenGui = Instance.new("ScreenGui", plr.PlayerGui)
ScreenGui.Name = "AutoFarmGUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local title = Instance.new("TextLabel", Frame)
title.Text = "AutoFarm Supremo v2"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold

-- Checkbox function
local function criaCheckbox(text, parent, default, callback)
    local cbFrame = Instance.new("Frame", parent)
    cbFrame.Size = UDim2.new(1, -20, 0, 30)
    cbFrame.BackgroundTransparency = 1

    local cbLabel = Instance.new("TextLabel", cbFrame)
    cbLabel.Text = text
    cbLabel.Size = UDim2.new(1, -40, 1, 0)
    cbLabel.TextColor3 = Color3.new(1,1,1)
    cbLabel.BackgroundTransparency = 1
    cbLabel.TextXAlignment = Enum.TextXAlignment.Left
    cbLabel.Position = UDim2.new(0, 30, 0, 0)
    cbLabel.Font = Enum.Font.SourceSans

    local cbBox = Instance.new("TextButton", cbFrame)
    cbBox.Size = UDim2.new(0, 20, 0, 20)
    cbBox.Position = UDim2.new(0, 5, 0, 5)
    cbBox.BackgroundColor3 = default and Color3.new(0,1,0) or Color3.new(1,0,0)
    cbBox.Text = ""

    local ativo = default

    cbBox.MouseButton1Click:Connect(function()
        ativo = not ativo
        cbBox.BackgroundColor3 = ativo and Color3.new(0,1,0) or Color3.new(1,0,0)
        callback(ativo)
    end)

    return cbFrame
end

-- Criar checkboxes para config
local cbSkills = criaCheckbox("Usar Skills (Z, X, C, V)", Frame, config.usarSkills, function(v)
    config.usarSkills = v
end)
cbSkills.Position = UDim2.new(0, 10, 0, 50)

local cbSpawn = criaCheckbox("Auto Set Spawn", Frame, config.autoSetSpawn, function(v)
    config.autoSetSpawn = v
end)
cbSpawn.Position = UDim2.new(0, 10, 0, 90)

local cbBoss = criaCheckbox("Auto Boss", Frame, config.autoBoss, function(v)
    config.autoBoss = v
end)
cbBoss.Position = UDim2.new(0, 10, 0, 130)

-- Funções do AutoFarm, AutoBoss, etc.
local function ativarHaki()
    pcall(function()
        commF:InvokeServer("Buso")
    end)
end

local function equiparArma()
    local tool = plr.Backpack:FindFirstChild(config.arma)
    if tool then
        plr.Character.Humanoid:EquipTool(tool)
    end
end

local function usarSkills()
    if config.usarSkills then
        for _, tecla in ipairs({"Z","X","C","V"}) do
            vim:SendKeyEvent(true, tecla, false, game)
            wait(0.3)
        end
    end
end

local function setarSpawn()
    if config.autoSetSpawn then
        pcall(function()
            commF:InvokeServer("SetSpawnPoint")
        end)
    end
end

-- Função para buscar NPC baseado na missão (simplificado)
local function pegarMissao()
    local lv = plr.Data.Level.Value
    -- Aqui pode expandir as quests como quiser
    if lv <= 14 then
        return "BanditQuest1", "Bandit"
    elseif lv <= 29 then
        return "MonkeyQuest", "Monkey"
    elseif lv <= 59 then
        return "PirateQuest1", "Pirate"
    else
        return "BuggyQuest1", "Clown"
    end
end

local function buscarNPC(nome)
    for _, npc in pairs(workspace.Enemies:GetChildren()) do
        if npc.Name:match(nome) and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
            return npc
        end
    end
end

local function teleportarSeguro(cframe)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cframe + Vector3.new(0,2,0)
    end
end

-- AutoBoss simples (busca NPC com nome "Boss")
local function autoBoss()
    if config.autoBoss then
        for _, npc in pairs(workspace.Enemies:GetChildren()) do
            if npc.Name:lower():find("boss") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                return npc
            end
        end
    end
end

-- Função principal do farm
local farmAtivo = true
coroutine.wrap(function()
    while farmAtivo do
        pcall(function()
            setarSpawn()
            local questId, npcNome = pegarMissao()
            commF:InvokeServer("StartQuest", questId, 1)
            wait(1)

            local alvo = buscarNPC(npcNome) or autoBoss()
            if alvo then
                repeat
                    ativarHaki()
                    equiparArma()
                    teleportarSeguro(alvo.HumanoidRootPart.CFrame)
                    usarSkills()
                    rs.Remotes.Combat:FireServer(alvo)
                    wait(math.random(12,25)/100) -- Delay random para evitar ban
                until not alvo or alvo.Humanoid.Health <= 0 or alvo.Parent == nil
            else
                wait(1)
            end
        end)
        wait(1)
    end
end)()

-- Interface para sair
local sairBtn = Instance.new("TextButton", Frame)
sairBtn.Size = UDim2.new(0, 280, 0, 40)
sairBtn.Position = UDim2.new(0, 10, 0, 350)
sairBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
sairBtn.TextColor3 = Color3.new(1,1,1)
sairBtn.Text = "Parar AutoFarm"
sairBtn.Font = Enum.Font.SourceSansBold
sairBtn.TextScaled = true
sairBtn.MouseButton1Click:Connect(function()
    farmAtivo = false
    print("[AF] AutoFarm parado pelo usuário.")
    ScreenGui:Destroy()
end)

print("[AF] AutoFarm Supremo iniciado! GUI ativada.")

-- Fim do Script
