-- Head.lua - Efecto de cabezas grandes con hitbox funcional
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {}
}

-- Configuración
local HEAD_SCALE = 10.0  -- Factor de escala para las cabezas
local LOCAL_PLAYER = Players.LocalPlayer
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)  -- Color al recibir daño

-- Función para aplicar el efecto de cabeza grande con hitbox funcional
local function applyHeadEffect(player)
    if not player or player == LOCAL_PLAYER then return end
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Crear un nuevo objeto para la cabeza grande con hitbox
    local bigHead = Instance.new("Part")
    bigHead.Name = "BigHeadEffect"
    bigHead.Size = head.Size * HEAD_SCALE
    bigHead.Shape = Enum.PartType.Ball
    bigHead.CanCollide = false
    bigHead.Anchored = true
    bigHead.Transparency = 0.3
    bigHead.Material = Enum.Material.Neon
    bigHead.Color = Color3.fromRGB(255, 50, 50)
    
    -- Crear detector de daño
    local damageDetector = Instance.new("Part")
    damageDetector.Name = "DamageDetector"
    damageDetector.Size = bigHead.Size
    damageDetector.Transparency = 1
    damageDetector.CanCollide = false
    damageDetector.Anchored = true
    damageDetector.Parent = bigHead
    
    -- Conectar detector de balas
    damageDetector.Touched:Connect(function(hit)
        if not HeadAPI.active then return end
        
        -- Destello visual al recibir daño
        bigHead.Color = DAMAGE_COLOR
        task.delay(0.1, function()
            if bigHead and bigHead.Parent then
                bigHead.Color = Color3.fromRGB(255, 50, 50)
            end
        end)
        
        -- Transferir daño a la cabeza real
        if hit and hit.Parent then
            local humanoid = hit.Parent:FindFirstChild("Humanoid")
            if not humanoid and hit.Parent.Parent then
                humanoid = hit.Parent.Parent:FindFirstChild("Humanoid")
            end
            
            if humanoid then
                -- Buscar la cabeza real para aplicar daño
                local realHead = player.Character:FindFirstChild("Head")
                if realHead then
                    -- Crear un evento de daño falso
                    local damageEvent = Instance.new("BindableEvent")
                    damageEvent.Name = "TakeDamage"
                    damageEvent.Parent = realHead
                    damageEvent:Fire(10)  -- 10 de daño
                    Debris:AddItem(damageEvent, 0.1)
                end
            end
        end
    end)
    
    -- Guardar referencia para restaurar después
    HeadAPI.scaledPlayers[player] = {
        originalHead = head,
        effectPart = bigHead
    }
    
    -- Conectar para actualizar posición
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active or not player.Character or not player.Character:FindFirstChild("Head") then
            if conn then conn:Disconnect() end
            return
        end
        
        -- Posicionar la cabeza grande sobre la cabeza real
        bigHead.CFrame = player.Character.Head.CFrame
    end)
    
    table.insert(HeadAPI.connections, conn)
    bigHead.Parent = Workspace
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
    
    -- Conectar para evitar memory leaks
    local heartbeat = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active then
            heartbeat:Disconnect()
        end
    end)
    table.insert(HeadAPI.connections, heartbeat)
    
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
