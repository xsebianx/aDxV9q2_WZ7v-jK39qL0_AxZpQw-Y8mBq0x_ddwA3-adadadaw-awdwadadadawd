-- Head.lua - Efecto de cabezas grandes (compatible universal)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {}
}

-- Configuración
local HEAD_SCALE = 10.0  -- Factor de escala para las cabezas
local LOCAL_PLAYER = Players.LocalPlayer

-- Función para aplicar el efecto de cabeza grande
local function applyHeadEffect(player)
    if not player or player == LOCAL_PLAYER then return end
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Crear un nuevo objeto para la cabeza grande
    local bigHead = Instance.new("Part")
    bigHead.Name = "BigHeadEffect"
    bigHead.Size = head.Size * HEAD_SCALE
    bigHead.Shape = Enum.PartType.Ball
    bigHead.CanCollide = false
    bigHead.Anchored = true
    bigHead.Transparency = 0.3
    bigHead.Material = Enum.Material.Neon
    bigHead.Color = Color3.fromRGB(255, 50, 50)
    
    -- Guardar referencia para restaurar después
    HeadAPI.scaledPlayers[player] = {
        originalHead = head,
        effectPart = bigHead
    }
    
    -- Conectar para actualizar posición
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active or not player.Character or not player.Character:FindFirstChild("Head") then
            conn:Disconnect()
            return
        end
        
        -- Posicionar la cabeza grande sobre la cabeza real
        bigHead.CFrame = player.Character.Head.CFrame
    end)
    
    table.insert(HeadAPI.connections, conn)
    bigHead.Parent = workspace
end

-- Restaura la cabeza a su estado normal
local function restoreHead(player)
    local data = HeadAPI.scaledPlayers[player]
    if not data then return end
    
    if data.effectPart and data.effectPart.Parent then
        data.effectPart:Destroy()
    end
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Maneja nuevos jugadores
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    applyHeadEffect(player)
end

-- Activar el script
function HeadAPI.activate()
    if HeadAPI.active then return false end
    HeadAPI.active = true
    
    -- Manejar jugadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(applyHeadEffect, player)
    end
    
    -- Conectar nuevos jugadores
    local conn = Players.PlayerAdded:Connect(handlePlayerAdded)
    table.insert(HeadAPI.connections, conn)
    
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
        restoreHead(player)
    end
    HeadAPI.scaledPlayers = {}
    
    return true
end

-- Manejo seguro de errores
function HeadAPI.safeActivate()
    local success, err = pcall(HeadAPI.activate)
    if not success then
        warn("[HEAD ERROR] Activation failed:", err)
        return false
    end
    return true
end

function HeadAPI.safeDeactivate()
    local success, err = pcall(HeadAPI.deactivate)
    if not success then
        warn("[HEAD ERROR] Deactivation failed:", err)
        return false
    end
    return true
end

return HeadAPI
