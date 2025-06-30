-- Head.lua - Agrandar cabezas de jugadores
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Configuración
local HEAD_SCALE = 2.5  -- Factor de escala para las cabezas
local LOCAL_PLAYER = Players.LocalPlayer
local DEBUG_MODE = false  -- Cambiar a true para depuración

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    originalSizes = {},
    scaledPlayers = {}
}

-- Función para depuración
local function debugPrint(message)
    if DEBUG_MODE then
        print("[HEAD DEBUG]", message)
    end
end

-- Aplica el efecto de cabeza grande a un jugador
local function applyHeadEffect(player)
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local head = player.Character:FindFirstChild("Head")
    
    if humanoid and head then
        -- Guardar tamaño original si es la primera vez
        if not HeadAPI.originalSizes[player] then
            HeadAPI.originalSizes[player] = {
                headSize = head.Size,
                scale = humanoid.HeadScale
            }
        end
        
        -- Aplicar escala
        humanoid.HeadScale = HEAD_SCALE
        head.Size = HeadAPI.originalSizes[player].headSize * HEAD_SCALE
        
        -- Marcar como escalado
        HeadAPI.scaledPlayers[player] = true
        debugPrint("Aplicado efecto a: "..player.Name)
    end
end

-- Restaura la cabeza a su tamaño original
local function restoreHead(player)
    if not player or not HeadAPI.originalSizes[player] then return end
    
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local head = player.Character:FindFirstChild("Head")
        
        if humanoid and head then
            humanoid.HeadScale = HeadAPI.originalSizes[player].scale
            head.Size = HeadAPI.originalSizes[player].headSize
            debugPrint("Restaurado: "..player.Name)
        end
    end
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Maneja nuevos jugadores
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    
    -- Esperar a que el personaje exista
    local charAdded
    charAdded = player.CharacterAdded:Connect(function(character)
        task.wait(0.5)  -- Esperar a que el modelo esté completo
        applyHeadEffect(player)
    end)
    
    -- Manejar desconexión
    local playerRemoving
    playerRemoving = Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            charAdded:Disconnect()
            playerRemoving:Disconnect()
        end
    end)
    
    -- Guardar conexiones
    table.insert(HeadAPI.connections, charAdded)
    table.insert(HeadAPI.connections, playerRemoving)
    
    -- Aplicar si ya tiene personaje
    if player.Character then
        task.wait(0.1)
        applyHeadEffect(player)
    end
end

-- Activar el script
function HeadAPI.activate()
    if HeadAPI.active then
        debugPrint("Ya está activado")
        return false
    end

    debugPrint("Activando Head...")
    HeadAPI.active = true
    
    -- Manejar jugadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER then
            coroutine.wrap(handlePlayerAdded)(player)
        end
    end
    
    -- Conectar nuevos jugadores
    local newPlayerConn = Players.PlayerAdded:Connect(handlePlayerAdded)
    table.insert(HeadAPI.connections, newPlayerConn)
    
    -- Conectar para evitar memory leaks
    local heartbeat = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active then
            heartbeat:Disconnect()
        end
    end)
    
    return true
end

-- Desactivar el script
function HeadAPI.deactivate()
    if not HeadAPI.active then
        debugPrint("No está activo")
        return false
    end

    debugPrint("Desactivando Head...")
    HeadAPI.active = false
    
    -- Desconectar eventos
    for _, conn in ipairs(HeadAPI.connections) do
        pcall(conn.Disconnect, conn)
    end
    HeadAPI.connections = {}
    
    -- Restaurar todos los jugadores
    for player, _ in pairs(HeadAPI.scaledPlayers) do
        restoreHead(player)
    end
    
    HeadAPI.scaledPlayers = {}
    HeadAPI.originalSizes = {}
    
    return true
end

-- Manejo de errores seguro
function HeadAPI.safeActivate()
    local success, err = pcall(HeadAPI.activate)
    if not success then
        warn("[HEAD ERROR] Al activar:", err)
        return false
    end
    return true
end

function HeadAPI.safeDeactivate()
    local success, err = pcall(HeadAPI.deactivate)
    if not success then
        warn("[HEAD ERROR] Al desactivar:", err)
        return false
    end
    return true
end

return HeadAPI
