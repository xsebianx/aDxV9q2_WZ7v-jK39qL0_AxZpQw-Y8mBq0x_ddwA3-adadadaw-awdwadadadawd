local players = game:GetService("Players")
local debris = game:GetService("Debris")

-- Tabla para rastrear conexiones y datos originales
local playerConnections = {}
local originalHeadData = {}
local headExpansionEnabled = true

-- Nuevo tamaño de cabeza (aumentado a 20x20x20)
local HEAD_SIZE = Vector3.new(20, 20, 20)
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
    head.Size = HEAD_SIZE
    head.Transparency = HEAD_TRANSPARENCY
    head.CanCollide = true
    
    -- Ajustar malla si existe
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        mesh.Scale = HEAD_SIZE
    end
    
    -- Crear fuerzas físicas
    if not head:FindFirstChild("ExpansionForces") then
        local bodyPos = Instance.new("BodyPosition")
        bodyPos.Name = "HeadBodyPosition"
        bodyPos.Position = head.Position
        bodyPos.MaxForce = Vector3.new(10000, 10000, 10000)
        bodyPos.P = 10000
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "HeadBodyGyro"
        bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
        bodyGyro.P = 10000
        
        local forceFolder = Instance.new("Folder")
        forceFolder.Name = "ExpansionForces"
        forceFolder.Parent = head
        bodyPos.Parent = forceFolder
        bodyGyro.Parent = forceFolder
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
    
    -- Eliminar fuerzas físicas
    local forceFolder = head:FindFirstChild("ExpansionForces")
    if forceFolder then
        forceFolder:Destroy()
    end
    
    -- Limpiar datos
    originalHeadData[head] = nil
end

-- Función principal para manejar la expansión de cabeza
local function handleHeadExpansion(player)
    if player == players.LocalPlayer then return end
    
    local function setupCharacter(character)
        if not headExpansionEnabled then return end
        
        applyHeadExpansion(character)
        
        -- Manejar evento de muerte
        local humanoid = character:WaitForChild("Humanoid")
        if humanoid then
            playerConnections[player] = humanoid.Died:Connect(function()
                -- Eliminar fuerzas para que el cadáver sea visible
                local head = character:FindFirstChild("Head")
                if head then
                    local forceFolder = head:FindFirstChild("ExpansionForces")
                    if forceFolder then
                        forceFolder:Destroy()
                    end
                end
                
                -- Restaurar cuando reaparezca
                player.CharacterAdded:Wait()
                task.wait(1) -- Esperar a que el nuevo personaje se cargue
                if headExpansionEnabled then
                    setupCharacter(player.Character)
                end
            end)
        end
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
