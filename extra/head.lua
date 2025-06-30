-- Head.lua - Cabeza grande elevada sin colisión
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {}
}

-- Configuración
local HEAD_SCALE = 10.0  -- Factor de escala para las cabezas
local HEAD_ELEVATION = 5.0  -- Altura adicional para evitar colisiones
local LOCAL_PLAYER = Players.LocalPlayer
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)  -- Color al recibir daño

-- Función para expandir la cabeza elevada
local function expandHead(player)
    if not player or player == LOCAL_PLAYER then return end
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Clonar la cabeza para mantener animaciones
    local headClone = head:Clone()
    headClone.Name = "BigHeadClone"
    headClone.Size = head.Size * HEAD_SCALE
    headClone.Transparency = 0.3
    headClone.Material = Enum.Material.Neon
    headClone.Color = Color3.fromRGB(255, 50, 50)
    headClone.CanCollide = false
    
    -- Ocultar la cabeza original
    head.Transparency = 1
    head.Name = "OriginalHeadHidden"
    
    -- Posicionar el clon elevado
    headClone.Parent = player.Character
    
    -- Crear un punto de anclaje elevado
    local anchor = Instance.new("Part")
    anchor.Name = "HeadAnchor"
    anchor.Size = Vector3.new(0.1, 0.1, 0.1)
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.Anchored = false
    anchor.Parent = player.Character
    
    -- Posicionar el anclaje sobre la cabeza original
    local headPosition = head.Position
    anchor.CFrame = CFrame.new(headPosition.X, headPosition.Y + HEAD_ELEVATION, headPosition.Z)
    
    -- Conectar con weld
    local weld = Instance.new("Weld")
    weld.Part0 = anchor
    weld.Part1 = headClone
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = headClone
    
    -- Mover el anclaje con el personaje
    local movementConnection
    movementConnection = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active or not player.Character or not head or not anchor then
            movementConnection:Disconnect()
            return
        end
        
        -- Mantener el anclaje sobre la cabeza
        local headPosition = head.Position
        anchor.CFrame = CFrame.new(headPosition.X, headPosition.Y + HEAD_ELEVATION, headPosition.Z)
    end)
    
    -- Efecto visual al recibir daño
    local lastDamageTime = 0
    local damageConnection
    damageConnection = head.Touched:Connect(function(part)
        if not HeadAPI.active then return end
        if tick() - lastDamageTime < 0.2 then return end
        
        lastDamageTime = tick()
        
        -- Destello de daño
        local tween = TweenService:Create(headClone, TweenInfo.new(0.1), {
            Color = DAMAGE_COLOR
        })
        tween:Play()
        
        tween.Completed:Wait()
        
        if headClone and headClone.Parent then
            TweenService:Create(headClone, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 50, 50)
            }):Play()
        end
    end)
    
    -- Guardar referencias
    HeadAPI.scaledPlayers[player] = {
        originalHead = head,
        headClone = headClone,
        anchor = anchor,
        movementConnection = movementConnection,
        damageConnection = damageConnection,
        originalTransparency = head.Transparency,
        originalName = head.Name
    }
end

-- Restaura la cabeza a su estado normal
local function restoreHead(player)
    local data = HeadAPI.scaledPlayers[player]
    if not data then return end
    
    -- Restaurar cabeza original
    if data.originalHead and data.originalHead.Parent then
        data.originalHead.Transparency = data.originalTransparency
        data.originalHead.Name = data.originalName
    end
    
    -- Eliminar elementos creados
    if data.headClone and data.headClone.Parent then
        data.headClone:Destroy()
    end
    
    if data.anchor and data.anchor.Parent then
        data.anchor:Destroy()
    end
    
    -- Desconectar eventos
    if data.movementConnection then
        pcall(data.movementConnection.Disconnect, data.movementConnection)
    end
    
    if data.damageConnection then
        pcall(data.damageConnection.Disconnect, data.damageConnection)
    end
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Maneja nuevos jugadores
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    expandHead(player)
end

-- Maneja cambio de personaje
local function handleCharacterAdded(player, character)
    if not HeadAPI.active then return end
    
    character:WaitForChild("Head", 5)
    task.wait(0.5)  -- Espera para asegurar estabilidad
    
    if character:FindFirstChild("Head") then
        expandHead(player)
    end
end

-- Activar el script
function HeadAPI.activate()
    if HeadAPI.active then return false end
    HeadAPI.active = true
    
    -- Manejar jugadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER then
            if player.Character then
                expandHead(player)
            end
            
            -- Conectar evento para cambio de personaje
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
