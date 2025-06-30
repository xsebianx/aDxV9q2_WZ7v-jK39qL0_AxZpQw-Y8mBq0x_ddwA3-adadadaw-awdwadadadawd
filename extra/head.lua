-- Head.lua - Solución compatible con cualquier sistema de personajes
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {}
}

-- Configuración
local HEAD_SCALE = 10.0  -- Factor de escala para las cabezas
local HEAD_ELEVATION = 8.0  -- Altura adicional para evitar colisiones
local LOCAL_PLAYER = Players.LocalPlayer
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)  -- Color al recibir daño

-- Función para crear la cabeza grande sin tocar el personaje
local function createFloatingHead(player)
    if not player or player == LOCAL_PLAYER then return end
    if HeadAPI.scaledPlayers[player] then return end
    
    -- Crear contenedor para la cabeza grande
    local headContainer = Instance.new("Part")
    headContainer.Name = "BigHeadEffect_"..player.UserId
    headContainer.Size = Vector3.new(HEAD_SCALE, HEAD_SCALE, HEAD_SCALE)
    headContainer.Shape = Enum.PartType.Ball
    headContainer.Transparency = 0.3
    headContainer.Material = Enum.Material.Neon
    headContainer.Color = Color3.fromRGB(255, 50, 50)
    headContainer.CanCollide = false
    headContainer.Anchored = true
    headContainer.Parent = Workspace
    
    -- Conectar para movimiento
    local movementConnection
    movementConnection = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active or not player.Character then
            if movementConnection then movementConnection:Disconnect() end
            return
        end
        
        -- Posicionamiento seguro sin acceder a partes específicas
        pcall(function()
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            
            if rootPart then
                -- Calcular posición estimada de la cabeza
                local headPosition = rootPart.Position + Vector3.new(0, 3, 0)
                headContainer.CFrame = CFrame.new(headPosition.X, headPosition.Y + HEAD_ELEVATION, headPosition.Z)
            end
        end)
    end)
    
    -- Guardar referencias
    HeadAPI.scaledPlayers[player] = {
        headContainer = headContainer,
        movementConnection = movementConnection
    }
end

-- Eliminar cabeza grande
local function removeFloatingHead(player)
    local data = HeadAPI.scaledPlayers[player]
    if not data then return end
    
    pcall(function()
        if data.headContainer and data.headContainer.Parent then
            data.headContainer:Destroy()
        end
    end)
    
    pcall(function()
        if data.movementConnection then
            data.movementConnection:Disconnect()
        end
    end)
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Manejar jugadores
local function handlePlayer(player)
    if not HeadAPI.active then return end
    
    -- Esperar a que el personaje exista
    if player.Character then
        createFloatingHead(player)
    end
    
    -- Conectar para cambios de personaje
    local charAdded = player.CharacterAdded:Connect(function()
        createFloatingHead(player)
    end)
    
    return charAdded
end

-- Activar el script
function HeadAPI.activate()
    if HeadAPI.active then return false end
    HeadAPI.active = true
    
    -- Manejar todos los jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER then
            local conn = handlePlayer(player)
            if conn then
                table.insert(HeadAPI.connections, conn)
            end
        end
    end
    
    -- Conectar nuevos jugadores
    local newPlayerConn = Players.PlayerAdded:Connect(function(p)
        if p ~= LOCAL_PLAYER then
            local conn = handlePlayer(p)
            if conn then
                table.insert(HeadAPI.connections, conn)
            end
        end
    end)
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
    
    -- Eliminar todas las cabezas grandes
    for player in pairs(HeadAPI.scaledPlayers) do
        removeFloatingHead(player)
    end
    HeadAPI.scaledPlayers = {}
    
    return true
end

-- Manejo seguro de errores
function HeadAPI.safeActivate()
    local success, err = pcall(HeadAPI.activate)
    if not success then
        warn("[HEAD] Activation failed:", err)
        return false
    end
    return true
end

function HeadAPI.safeDeactivate()
    local success, err = pcall(HeadAPI.deactivate)
    if not success then
        warn("[HEAD] Deactivation failed:", err)
        return false
    end
    return true
end

return HeadAPI
