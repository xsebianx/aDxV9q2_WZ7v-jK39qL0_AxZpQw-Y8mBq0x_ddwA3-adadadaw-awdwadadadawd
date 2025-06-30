-- Head.lua - Solución definitiva sin modificar el personaje
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
local MAX_WAIT_TIME = 3  -- Tiempo máximo de espera para la cabeza (segundos)

-- Función segura para obtener la posición de la cabeza
local function safeGetHeadPosition(character)
    if not character then return nil end
    
    -- Primero intentar obtener la cabeza directamente
    local head = character:FindFirstChild("Head")
    if head then return head.Position end
    
    -- Intentar obtener a través de HumanoidRootPart
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        return rootPart.Position + Vector3.new(0, 2.5, 0)  -- Posición estimada de la cabeza
    end
    
    -- Último recurso: usar la posición del modelo
    if character:IsA("Model") and character.PrimaryPart then
        return character.PrimaryPart.Position + Vector3.new(0, 5, 0)
    end
    
    return character:GetPivot().Position + Vector3.new(0, 5, 0)
end

-- Función para crear la cabeza grande sin modificar el personaje
local function createFloatingHead(player)
    if not player or player == LOCAL_PLAYER then return end
    if HeadAPI.scaledPlayers[player] then return end  -- Evitar duplicados
    
    local character = player.Character
    if not character then return end
    
    -- Obtener posición de cabeza de forma segura
    local headPosition = safeGetHeadPosition(character)
    if not headPosition then return end
    
    -- Crear contenedor para la cabeza grande
    local headContainer = Instance.new("Part")
    headContainer.Name = "BigHeadContainer"
    headContainer.Size = Vector3.new(1, 1, 1)
    headContainer.Transparency = 1
    headContainer.CanCollide = false
    headContainer.Anchored = false
    headContainer.Parent = Workspace
    
    -- Crear cabeza grande
    local bigHead = Instance.new("Part")
    bigHead.Name = "BigHeadEffect"
    bigHead.Shape = Enum.PartType.Ball
    bigHead.Size = Vector3.new(HEAD_SCALE, HEAD_SCALE, HEAD_SCALE)
    bigHead.Transparency = 0.3
    bigHead.Material = Enum.Material.Neon
    bigHead.Color = Color3.fromRGB(255, 50, 50)
    bigHead.CanCollide = false
    bigHead.Parent = headContainer
    
    -- Posicionar inicialmente
    headContainer.CFrame = CFrame.new(headPosition.X, headPosition.Y + HEAD_ELEVATION, headPosition.Z)
    
    -- Conectar para movimiento suave
    local movementConnection
    movementConnection = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active or not player.Character or not bigHead or not headContainer then
            if movementConnection then movementConnection:Disconnect() end
            return
        end
        
        -- Actualizar posición de forma segura
        pcall(function()
            local newPosition = safeGetHeadPosition(player.Character)
            if newPosition then
                -- Suavizar movimiento
                local targetPosition = newPosition + Vector3.new(0, HEAD_ELEVATION, 0)
                headContainer.CFrame = headContainer.CFrame:Lerp(
                    CFrame.new(targetPosition),
                    0.3
                )
            end
        end)
    end)
    
    -- Guardar referencias
    HeadAPI.scaledPlayers[player] = {
        headContainer = headContainer,
        bigHead = bigHead,
        movementConnection = movementConnection
    }
end

-- Restaura todo sin tocar el personaje
local function removeFloatingHead(player)
    local data = HeadAPI.scaledPlayers[player]
    if not data then return end
    
    -- Eliminar elementos con protección
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

-- Maneja nuevos jugadores con protección
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    pcall(createFloatingHead, player)
end

-- Maneja cambio de personaje con protección
local function handleCharacterAdded(player, character)
    if not HeadAPI.active then return end
    
    -- Esperar a que el personaje esté listo
    pcall(function()
        task.wait(1)  -- Espera generosa
        createFloatingHead(player)
    end)
end

-- Activar el script con protección completa
function HeadAPI.activate()
    if HeadAPI.active then return false end
    HeadAPI.active = true
    
    -- Manejar jugadores existentes con protección
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER then
            pcall(function()
                if player.Character then
                    createFloatingHead(player)
                end
                
                -- Conectar evento para cambio de personaje
                local conn = player.CharacterAdded:Connect(function(char)
                    pcall(handleCharacterAdded, player, char)
                end)
                table.insert(HeadAPI.connections, conn)
            end)
        end
    end
    
    -- Conectar nuevos jugadores
    local newPlayerConn = Players.PlayerAdded:Connect(function(p)
        pcall(handlePlayerAdded, p)
    end)
    table.insert(HeadAPI.connections, newPlayerConn)
    
    return true
end

-- Desactivar el script con protección completa
function HeadAPI.deactivate()
    if not HeadAPI.active then return false end
    HeadAPI.active = false
    
    -- Desconectar eventos con protección
    for _, conn in ipairs(HeadAPI.connections) do
        pcall(conn.Disconnect, conn)
    end
    HeadAPI.connections = {}
    
    -- Restaurar todos los jugadores con protección
    for player in pairs(HeadAPI.scaledPlayers) do
        pcall(removeFloatingHead, player)
    end
    HeadAPI.scaledPlayers = {}
    
    return true
end

-- Manejo seguro de errores
function HeadAPI.safeActivate()
    local success, err = pcall(HeadAPI.activate)
    if not success then
        warn("[HEAD CRITICAL ERROR] Activation failed:", err)
        return false
    end
    return true
end

function HeadAPI.safeDeactivate()
    local success, err = pcall(HeadAPI.deactivate)
    if not success then
        warn("[HEAD CRITICAL ERROR] Deactivation failed:", err)
        return false
    end
    return true
end

return HeadAPI
