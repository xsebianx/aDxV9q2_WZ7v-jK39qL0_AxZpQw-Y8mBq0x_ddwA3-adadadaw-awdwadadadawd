-- Head.lua - Expansión real de cabeza con hitbox funcional (versión mejorada)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {}
}

-- CONFIGURACIÓN PERSONALIZABLE
local HEAD_SCALE = 7.0                 -- Tamaño de la cabeza (7x más grande)
local BASE_COLOR = Color3.fromRGB(255, 0, 0)        -- Color rojo permanente
local DAMAGE_COLOR = Color3.fromRGB(255, 200, 200)  -- Color de daño (rojo claro)
local HEAD_TRANSPARENCY = 0.3           -- Transparencia de la cabeza
local HEAD_MATERIAL = Enum.Material.Neon -- Material de la cabeza
local DAMAGE_COOLDOWN = 0.2             -- Tiempo entre efectos de daño (segundos)
local STABILIZATION_DELAY = 0.5         -- Tiempo de espera después de spawn

-- Variables internas
local LOCAL_PLAYER = Players.LocalPlayer

-- Función para expandir la cabeza hacia arriba
local function expandRealHead(player)
    if not player or player == LOCAL_PLAYER then return end
    if not player.Character then return end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not head or not humanoid or not rootPart then return end
    
    -- Guardar propiedades originales
    local originalSize = head.Size
    local originalCFrame = head.CFrame
    local originalTransparency = head.Transparency
    local originalMaterial = head.Material
    local originalColor = head.Color
    
    -- Calcular nueva posición (crecimiento hacia arriba)
    local currentTopPosition = head.Position + Vector3.new(0, originalSize.Y/2, 0)
    local newSize = originalSize * HEAD_SCALE
    local newBottomPosition = currentTopPosition - Vector3.new(0, newSize.Y/2, 0)
    
    -- Aplicar expansión
    head.Size = newSize
    head.CFrame = CFrame.new(newBottomPosition) * (originalCFrame - originalCFrame.Position)
    
    -- Configurar propiedades visuales
    head.Transparency = HEAD_TRANSPARENCY
    head.Material = HEAD_MATERIAL
    head.Color = BASE_COLOR
    
    -- Desactivar colisiones innecesarias
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= head then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end
    
    -- Guardar referencia para restaurar
    HeadAPI.scaledPlayers[player] = {
        originalSize = originalSize,
        originalCFrame = originalCFrame,
        originalTransparency = originalTransparency,
        originalMaterial = originalMaterial,
        originalColor = originalColor
    }
    
    -- Efecto visual al recibir daño
    local lastDamageTime = 0
    local damageConnection
    damageConnection = head.Touched:Connect(function(part)
        if not HeadAPI.active then return end
        if tick() - lastDamageTime < DAMAGE_COOLDOWN then return end
        
        lastDamageTime = tick()
        
        -- Destello de daño
        local tween = TweenService:Create(head, TweenInfo.new(0.1), {
            Color = DAMAGE_COLOR
        })
        tween:Play()
        
        tween.Completed:Wait()
        
        if head and head.Parent then
            TweenService:Create(head, TweenInfo.new(0.2), {
                Color = BASE_COLOR
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
        head.CFrame = data.originalCFrame
        head.Transparency = data.originalTransparency
        head.Material = data.originalMaterial
        head.Color = data.originalColor
        
        -- Restaurar colisiones
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
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
    
    character:WaitForChild("Head", 5)
    task.wait(STABILIZATION_DELAY)  -- Espera para asegurar estabilidad
    
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
