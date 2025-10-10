-- head.txt - Expansión de Cabeza/Cuerpo (Corregido y Mejorado)
-- ADVERTENCIA: Este script proporciona una ventaja visual injusta. Usarlo es considerado trampa.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de scripting en Lua.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {},
    mode = "Head" -- "Head" o "Body"
}

-- Configuración
local HEAD_SCALE = 10.0
local BODY_SCALE = 1.5
local LOCAL_PLAYER = Players.LocalPlayer
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)
local VISUAL_COLOR = Color3.fromRGB(255, 50, 50)
local CONFIG_KEY = Enum.KeyCode.F5

-- GUI de Configuración
local configGui, configFrame

-- Función para expandir una parte específica
local function expandPart(part, scale)
    if not part then return end
    
    -- Guardar tamaño y propiedades originales
    local originalSize = part.Size
    local originalTransparency = part.Transparency
    local originalMaterial = part.Material
    local originalColor = part.Color
    local originalCanCollide = part.CanCollide

    -- Aplicar expansión
    part.Size = part.Size * scale
    
    -- Configurar propiedades visuales
    part.Transparency = 0.3
    part.Material = Enum.Material.Neon
    part.Color = VISUAL_COLOR
    
    -- <<< LA CORRECCIÓN CLAVE >>>
    -- Hacer la parte no colisionable para evitar el bug de la cámara
    part.CanCollide = false
    -- <<< FIN DE LA CORRECCIÓN >>>
    
    return {
        part = part,
        originalSize = originalSize,
        originalTransparency = originalTransparency,
        originalMaterial = originalMaterial,
        originalColor = originalColor,
        originalCanCollide = originalCanCollide
    }
end

-- Función para expandir un jugador completo
local function expandPlayer(player)
    if not player or player == LOCAL_PLAYER then return end
    if not player.Character then return end
    
    local character = player.Character
    local partsToScale = {}
    
    if HeadAPI.mode == "Head" then
        local head = character:FindFirstChild("Head")
        if head then
            table.insert(partsToScale, expandPart(head, HEAD_SCALE))
        end
    elseif HeadAPI.mode == "Body" then
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        local lowerTorso = character:FindFirstChild("LowerTorso")
        if torso then table.insert(partsToScale, expandPart(torso, BODY_SCALE)) end
        if lowerTorso then table.insert(partsToScale, expandPart(lowerTorso, BODY_SCALE)) end
    end

    if #partsToScale > 0 then
        HeadAPI.scaledPlayers[player] = partsToScale
    end
end

-- Restaura las partes originales de un jugador
local function restorePlayer(player)
    local scaledParts = HeadAPI.scaledPlayers[player]
    if not scaledParts then return end
    
    for _, data in ipairs(scaledParts) do
        local part = data.part
        if part and part.Parent then
            part.Size = data.originalSize
            part.Transparency = data.originalTransparency
            part.Material = data.originalMaterial
            part.Color = data.originalColor
            part.CanCollide = data.originalCanCollide -- Restaurar colisión original
        end
    end
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Maneja nuevos jugadores
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    expandPlayer(player)
end

-- Maneja cambio de personaje
local function handleCharacterAdded(player, character)
    if not HeadAPI.active then return end
    character:WaitForChild("Humanoid")
    task.wait(0.5)
    expandPlayer(player)
end

-- === MENÚ DE CONFIGURACIÓN ===
local function createConfigGui()
    if configGui then
        configGui.Enabled = not configGui.Enabled
        return
    end

    configGui = Instance.new("ScreenGui")
    configGui.Name = "HeadConfigGui"
    configGui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
    configGui.ResetOnSpawn = false
    configGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    configFrame = Instance.new("Frame")
    configFrame.Size = UDim2.new(0, 250, 0, 150)
    configFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
    configFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = configGui
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "CONFIGURACIÓN DE CABEZA"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.BackgroundTransparency = 1
    title.Parent = configFrame

    local headButton = Instance.new("TextButton")
    headButton.Size = UDim2.new(1, -20, 0, 30)
    headButton.Position = UDim2.new(0, 10, 0, 40)
    headButton.Text = "Modo: Big Head"
    headButton.TextColor3 = Color3.new(1, 1, 1)
    headButton.Font = Enum.Font.Gotham
    headButton.TextSize = 14
    headButton.BackgroundColor3 = HeadAPI.mode == "Head" and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
    headButton.BorderSizePixel = 0
    headButton.Parent = configFrame
    Instance.new("UICorner", headButton).CornerRadius = UDim.new(0, 5)

    local bodyButton = Instance.new("TextButton")
    bodyButton.Size = UDim2.new(1, -20, 0, 30)
    bodyButton.Position = UDim2.new(0, 10, 0, 80)
    bodyButton.Text = "Modo: Big Body"
    bodyButton.TextColor3 = Color3.new(1, 1, 1)
    bodyButton.Font = Enum.Font.Gotham
    bodyButton.TextSize = 14
    bodyButton.BackgroundColor3 = HeadAPI.mode == "Body" and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
    bodyButton.BorderSizePixel = 0
    bodyButton.Parent = configFrame
    Instance.new("UICorner", bodyButton).CornerRadius = UDim.new(0, 5)

    headButton.MouseButton1Click:Connect(function()
        HeadAPI.mode = "Head"
        headButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
        bodyButton.BackgroundColor3 = Color3.new(0.5, 0, 0)
        -- Re-aplicar a todos los jugadores si está activo
        if HeadAPI.active then
            for player, _ in pairs(HeadAPI.scaledPlayers) do
                restorePlayer(player)
                expandPlayer(player)
            end
        end
    end)

    bodyButton.MouseButton1Click:Connect(function()
        HeadAPI.mode = "Body"
        bodyButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
        headButton.BackgroundColor3 = Color3.new(0.5, 0, 0)
        -- Re-aplicar a todos los jugadores si está activo
        if HeadAPI.active then
            for player, _ in pairs(HeadAPI.scaledPlayers) do
                restorePlayer(player)
                expandPlayer(player)
            end
        end
    end)
end

-- Activar el script
function HeadAPI.activate()
    if HeadAPI.active then return false end
    HeadAPI.active = true
    
    -- Conectar evento de configuración
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == CONFIG_KEY then
            createConfigGui()
        end
    end)
    
    -- Manejar jugadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER then
            if player.Character then
                expandPlayer(player)
            end
            local conn = player.CharacterAdded:Connect(function(char)
                handleCharacterAdded(player, char)
            end)
            table.insert(HeadAPI.connections, conn)
        end
    end
    
    -- Conectar nuevos jugadores
    local newPlayerConn = Players.PlayerAdded:Connect(handlePlayerAdded)
    table.insert(HeadAPI.connections, newPlayerConn)
    
    return true
end

-- Desactivar el script
function HeadAPI.deactivate()
    if not HeadAPI.active then return false end
    HeadAPI.active = false
    
    -- Desconectar eventos
    for _, conn in ipairs(HeadAPI.connections) do
        pcall(conn.Disconnect, conn)
    end
    HeadAPI.connections = {}
    
    -- Restaurar todos los jugadores
    for player in pairs(HeadAPI.scaledPlayers) do
        restorePlayer(player)
    end
    HeadAPI.scaledPlayers = {}
    
    -- Destruir GUI
    if configGui then
        configGui:Destroy()
        configGui = nil
        configFrame = nil
    end
    
    return true
end

return HeadAPI
