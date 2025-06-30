-- Head.lua - Expansión real de cabeza con hitbox funcional
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
local HEAD_SCALE = 5.0  -- Factor de escala para las cabezas
local LOCAL_PLAYER = Players.LocalPlayer
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)  -- Color al recibir daño

-- Función para expandir la cabeza real
local function expandRealHead(player)
    if not player or player == LOCAL_PLAYER then return end
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Guardar tamaño original
    local originalSize = head.Size
    local originalTransparency = head.Transparency
    
    -- Aplicar expansión
    head.Size = head.Size * HEAD_SCALE
    
    -- Configurar propiedades visuales
    head.Transparency = 0.3
    head.Material = Enum.Material.Neon
    head.Color = Color3.fromRGB(255, 50, 50)
    
    -- Guardar referencia para restaurar
    HeadAPI.scaledPlayers[player] = {
        originalSize = originalSize,
        originalTransparency = originalTransparency,
        originalMaterial = head.Material,
        originalColor = head.Color
    }
    
    -- Efecto visual al recibir daño
    local lastDamageTime = 0
    local damageConnection
    damageConnection = head.Touched:Connect(function(part)
        if not HeadAPI.active then return end
        if tick() - lastDamageTime < 0.2 then return end  -- Prevenir destellos rápidos
        
        lastDamageTime = tick()
        
        -- Destello de daño
        local tween = TweenService:Create(head, TweenInfo.new(0.1), {
            Color = DAMAGE_COLOR
        })
        tween:Play()
        
        tween.Completed:Wait()
        
        if head and head.Parent then
            TweenService:Create(head, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 50, 50)
            }):Play()
        end
    end)
    
    table.insert(HeadAPI.connections, damageConnection)
end

-- Restaura la cabeza a su estado normal
local function restoreHead(player)
    local data = HeadAPI.scaledPlayers[player]
    if not data then return end
    
    local head = player.Character and player.Character:FindFirstChild("Head")
    if head then
        head.Size = data.originalSize
        head.Transparency = data.originalTransparency
        head.Material = data.originalMaterial
        head.Color = data.originalColor
    end
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Maneja nuevos jugadores
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    expandRealHead(player)
end

-- Maneja cambio de personaje
local function handleCharacterAdded(player, character)
    if not HeadAPI.active then return end
    
    -- Esperar a que el personaje esté completo
    character:WaitForChild("Head", 5)
    task.wait(0.5)  -- Espera adicional para asegurar estabilidad
    
    if character:FindFirstChild("Head") then
        expandRealHead(player)
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
                expandRealHead(player)
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
