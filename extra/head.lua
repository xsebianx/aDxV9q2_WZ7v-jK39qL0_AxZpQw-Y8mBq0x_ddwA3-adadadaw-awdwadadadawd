local players = game:GetService("Players")
local debris = game:GetService("Debris")
local runService = game:GetService("RunService")

-- Tabla para rastrear conexiones y datos originales
local playerConnections = {}
local originalHeadData = {}
local headExpansionEnabled = true

-- Tamaño de cabeza aumentado (5 veces más grande)
local HEAD_SCALE = 5
local HEAD_TRANSPARENCY = 0.5

-- Función para aplicar la expansión de cabeza
local function applyHeadExpansion(character)
    if not character then return end
    
    local head = character:WaitForChild("Head", 2) -- Esperar máximo 2 segundos
    if not head then return end
    
    -- Guardar datos originales si no existen
    if not originalHeadData[head] then
        originalHeadData[head] = {
            Size = head.Size,
            Transparency = head.Transparency,
            CanCollide = head.CanCollide
        }
        
        -- Guardar datos de malla si existe
        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            originalHeadData[head].MeshScale = mesh.Scale
        end
    end
    
    -- Aplicar cambios visuales
    head.Size = originalHeadData[head].Size * HEAD_SCALE
    head.Transparency = HEAD_TRANSPARENCY
    head.CanCollide = false  -- Importante para evitar problemas físicos
    
    -- Ajustar malla si existe
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        mesh.Scale = originalHeadData[head].MeshScale * HEAD_SCALE
    end
    
    -- Crear efecto visual sin fuerzas físicas
    if not head:FindFirstChild("HeadExpansionEffect") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "HeadExpansionEffect"
        highlight.FillColor = Color3.new(1, 0, 0)
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.new(1, 1, 0)
        highlight.OutlineTransparency = 0.3
        highlight.Parent = head
    end
end

-- Función para restaurar la cabeza a su estado original
local function restoreHead(character)
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head or not originalHeadData[head] then return end
    
    -- Restaurar propiedades
    local data = originalHeadData[head]
    head.Size = data.Size
    head.Transparency = data.Transparency
    head.CanCollide = data.CanCollide
    
    -- Restaurar malla si existe
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if mesh and data.MeshScale then
        mesh.Scale = data.MeshScale
    end
    
    -- Eliminar efecto visual
    local effect = head:FindFirstChild("HeadExpansionEffect")
    if effect then
        effect:Destroy()
    end
    
    -- Limpiar datos
    originalHeadData[head] = nil
end

-- Función principal para manejar la expansión de cabeza
local function handleHeadExpansion(player)
    if player == players.LocalPlayer then return end
    
    local function setupCharacter(character)
        if not headExpansionEnabled then return end
        
        -- Esperar a que el personaje esté completamente cargado
        local humanoid = character:WaitForChild("Humanoid", 3)
        if not humanoid then return end
        
        applyHeadExpansion(character)
        
        -- Manejar evento de muerte
        playerConnections[player] = humanoid.Died:Connect(function()
            -- No hacer nada especial, dejar que el cuerpo se comporte normalmente
        end)
    end
    
    player.CharacterAdded:Connect(setupCharacter)
    
    if player.Character then
        setupCharacter(player.Character)
    end
end

-- Función para desactivar completamente la expansión
function disableHeadExpand()
    headExpansionEnabled = false
    
    -- Desconectar todos los eventos
    for player, connection in pairs(playerConnections) do
        connection:Disconnect()
    end
    playerConnections = {}
    
    -- Restaurar todas las cabezas
    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            restoreHead(player.Character)
        end
    end
    
    -- Limpiar datos
    originalHeadData = {}
end

-- Función para activar la expansión
function enableHeadExpand()
    headExpansionEnabled = true
    
    -- Aplicar a todos los jugadores
    for _, player in pairs(players:GetPlayers()) do
        if player ~= players.LocalPlayer then
            handleHeadExpansion(player)
        end
    end
end

-- Inicializar con los jugadores existentes
for _, player in pairs(players:GetPlayers()) do
    if player ~= players.LocalPlayer then
        handleHeadExpansion(player)
    end
end

-- Manejar nuevos jugadores
players.PlayerAdded:Connect(function(player)
    if player ~= players.LocalPlayer then
        handleHeadExpansion(player)
    end
end)

-- API para el hub
return {
    activate = enableHeadExpand,
    deactivate = disableHeadExpand,
    isActive = function() return headExpansionEnabled end
}
