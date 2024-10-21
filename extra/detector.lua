local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local suspiciousPlayers = {}
local warnings = {}
local isMenuVisible = true
local connections = {} -- Tabla para almacenar las conexiones

-- Crear una interfaz gráfica mejorada
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local SuspiciousListLabel = Instance.new("TextLabel")
local MinimizeButton = Instance.new("TextButton")
local FrameBorder = Instance.new("Frame")
local SuspiciousListBorder = Instance.new("Frame")

ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Marco del Frame principal
FrameBorder.Parent = ScreenGui
FrameBorder.BackgroundColor3 = Color3.fromRGB(85, 170, 255) -- Color del borde azul
FrameBorder.Position = UDim2.new(0.5, -152, 0.5, -202)
FrameBorder.Size = UDim2.new(0, 304, 0, 404)

Frame.Parent = FrameBorder
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Position = UDim2.new(0, 2, 0, 2)
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.Active = true
Frame.Draggable = true

TitleLabel.Parent = Frame
TitleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.Text = "Detección de Hacks"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Marco del Submenú
SuspiciousListBorder.Parent = Frame
SuspiciousListBorder.BackgroundColor3 = Color3.fromRGB(85, 170, 255) -- Color del borde azul
SuspiciousListBorder.Position = UDim2.new(0, 0, 0, 50)
SuspiciousListBorder.Size = UDim2.new(1, 0, 1, -50)

SuspiciousListLabel.Parent = SuspiciousListBorder
SuspiciousListLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SuspiciousListLabel.Position = UDim2.new(0, 2, 0, 2)
SuspiciousListLabel.Size = UDim2.new(1, -4, 1, -4)
SuspiciousListLabel.Text = ""
SuspiciousListLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SuspiciousListLabel.TextScaled = true
SuspiciousListLabel.TextWrapped = true

MinimizeButton.Parent = Frame
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
MinimizeButton.Position = UDim2.new(0.9, 0, 0, 0)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)

local function updateSuspicionGui()
    local text = ""
    for _, playerName in ipairs(suspiciousPlayers) do
        text = text .. playerName .. "\n"
    end
    SuspiciousListLabel.Text = text
end

local function addWarning(playerName)
    warnings[playerName] = (warnings[playerName] or 0) + 1
    if warnings[playerName] >= 3 and not table.find(suspiciousPlayers, playerName) then
        table.insert(suspiciousPlayers, playerName)
        updateSuspicionGui()
        -- Notificar a los administradores
        game.ReplicatedStorage:WaitForChild("NotifyAdmin"):FireServer(playerName .. " ha sido marcado como sospechoso.")
        -- Sistema de penalización: kickear al jugador
        if warnings[playerName] >= 5 then
            local suspect = Players:FindFirstChild(playerName)
            if suspect then
                suspect:Kick("Has sido expulsado por comportamiento sospechoso.")
            end
        end
    end
end

local function logSuspiciousActivity(playerName, reason)
    updateSuspicionGui()
    -- Registro detallado de eventos sospechosos
    print("Actividad sospechosa detectada: " .. playerName .. " - " .. reason)
end

local function detectAimbot(player)
    local lastLookVector = nil
    local lastTime = tick()
    local suspiciousChanges = 0
    local rightMouseDown = false
    local headTrackingTime = 0
    local headTrackingThreshold = 1 -- segundos
    local angleChangeThreshold = math.rad(10) -- ángulo en radianes, aumentado para reducir falsos positivos
    local suspiciousChangeThreshold = 5 -- número de cambios sospechosos, aumentado para reducir falsos positivos

    local function onCharacterAdded(character)
        local playerMouse = player:GetMouse()
        table.insert(connections, playerMouse.Button2Down:Connect(function()
            rightMouseDown = true
        end))
        table.insert(connections, playerMouse.Button2Up:Connect(function()
            rightMouseDown = false
        end))
        table.insert(connections, RunService.RenderStepped:Connect(function()
            if character and character:FindFirstChild("HumanoidRootPart") then
                local currentLookVector = character.HumanoidRootPart.CFrame.LookVector
                local currentTime = tick()
                if rightMouseDown and lastLookVector then
                    local angleChange = math.acos(lastLookVector:Dot(currentLookVector))
                    if angleChange > angleChangeThreshold then
                        suspiciousChanges = suspiciousChanges + 1
                    end
                    -- Verificar si el jugador sigue la cabeza de otro jugador
                    local target = playerMouse.Target
                    if target and target.Name == "Head" then
                        headTrackingTime = headTrackingTime + (currentTime - lastTime)
                    else
                        headTrackingTime = 0
                    end
                    -- Reset suspicious changes count after 0.5 seconds
                    if currentTime - lastTime > 0.5 then
                        if suspiciousChanges > suspiciousChangeThreshold then
                            logSuspiciousActivity(player.Name, "Aimbot detectado")
                            addWarning(player.Name)
                        end
                        suspiciousChanges = 0
                        lastTime = currentTime
                    end
                    -- Verificar si el jugador sigue la cabeza de otro jugador por más de headTrackingThreshold segundos
                    if headTrackingTime > headTrackingThreshold then
                        logSuspiciousActivity(player.Name, "Seguimiento constante de la cabeza detectado")
                        addWarning(player.Name)
                        headTrackingTime = 0
                    end
                end
                lastLookVector = currentLookVector
            end
        end))
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))
end

local function detectHeadshots(player)
    local totalShots = 0
    local headshots = 0

    local function onCharacterAdded(character)
        local playerMouse = player:GetMouse()
        table.insert(connections, playerMouse.Button1Down:Connect(function()
            totalShots = totalShots + 1
            local target = playerMouse.Target
            if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
                if target.Name == "Head" then
                    headshots = headshots + 1
                    local distance = (player.Character.HumanoidRootPart.Position - target.Position).Magnitude
                    if distance > 50 and totalShots > 0 and headshots / totalShots > 0.5 then
                        logSuspiciousActivity(player.Name, "Headshots sospechosos")
                        addWarning(player.Name)
                    end
                end
            end
        end))
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))
end

local function detectSpeedHack(player)
    local function onCharacterAdded(character)
        local lastPosition = character:WaitForChild("HumanoidRootPart").Position
        local lastTime = tick()
        table.insert(connections, RunService.RenderStepped:Connect(function()
            if character and character:FindFirstChild("HumanoidRootPart") then
                local currentPosition = character.HumanoidRootPart.Position
                local currentTime = tick()
                local movementSpeed = (currentPosition - lastPosition).Magnitude / (currentTime - lastTime)
                if movementSpeed > 50 then -- Ajustar el umbral según sea necesario
                    logSuspiciousActivity(player.Name, "Speed hack detectado")
                    addWarning(player.Name)
                end
                lastPosition = currentPosition
                lastTime = currentTime
            end
        end))
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))
end

-- Función para minimizar el menú
MinimizeButton.MouseButton1Click:Connect(function()
    isMenuVisible = not isMenuVisible
    Frame.Visible = isMenuVisible
end)

-- Iniciar la detección para el jugador local
detectAimbot(player)
detectHeadshots(player)
detectSpeedHack(player)

-- Para todos los jugadores en el servidor
local function detectAllPlayers()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            detectAimbot(otherPlayer)
            detectHeadshots(otherPlayer)
            detectSpeedHack(otherPlayer)
        end
    end
end

detectAllPlayers()

-- Conectar a nuevos jugadores que entren al juego
table.insert(connections, Players.PlayerAdded:Connect(function(newPlayer)
    detectAimbot(newPlayer)
    detectHeadshots(newPlayer)
    detectSpeedHack(newPlayer)
end))

-- Eliminar jugador de la lista si se desconecta
table.insert(connections, Players.PlayerRemoving:Connect(function(removedPlayer)
    for i = #suspiciousPlayers, 1, -1 do
        if suspiciousPlayers[i] == removedPlayer.Name then
            table.remove(suspiciousPlayers, i)
            updateSuspicionGui()
            break
        end
    end
end))

-- Función para desactivar el detector de hacks
local function disableHackDetector()
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    Frame.Visible = false
end

-- Exponer la función de desactivación globalmente para que pueda ser llamada desde fuera
_G.disableHackDetector = disableHackDetector