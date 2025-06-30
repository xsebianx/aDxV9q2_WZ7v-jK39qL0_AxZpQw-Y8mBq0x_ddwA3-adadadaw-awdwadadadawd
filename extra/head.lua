local players = game:GetService("Players")
local debris = game:GetService("Debris")

-- Tabla para rastrear conexiones de eventos
local playerConnections = {}
local headExpansionEnabled = true

-- Nuevo tamaño de cabeza (aumentado a 15x15x15)
local HEAD_SIZE = Vector3.new(15, 15, 15)
local HEAD_TRANSPARENCY = 0.5

-- Función para cambiar el tamaño de la cabeza
local function expandHead(player)
    if not headExpansionEnabled or player == players.LocalPlayer then return end
    
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    
    -- Guardar el tamaño original y otras propiedades
    if not head:FindFirstChild("OriginalData") then
        local originalData = Instance.new("Folder")
        originalData.Name = "OriginalData"
        
        local size = Instance.new("Vector3Value")
        size.Name = "Size"
        size.Value = head.Size
        size.Parent = originalData
        
        local transparency = Instance.new("NumberValue")
        transparency.Name = "Transparency"
        transparency.Value = head.Transparency
        transparency.Parent = originalData
        
        local collide = Instance.new("BoolValue")
        collide.Name = "CanCollide"
        collide.Value = head.CanCollide
        collide.Parent = originalData
        
        originalData.Parent = head
    end

    -- Aumentar tamaño y transparencia
    head.Size = HEAD_SIZE
    head.Transparency = HEAD_TRANSPARENCY
    head.CanCollide = true

    -- Ajustar Mesh si existe
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        if not head.OriginalData:FindFirstChild("MeshScale") then
            local meshScale = Instance.new("Vector3Value")
            meshScale.Name = "MeshScale"
            meshScale.Value = mesh.Scale
            meshScale.Parent = head.OriginalData
        end
        mesh.Scale = HEAD_SIZE
    end

    -- Crear fuerzas para simular expansión física
    if not head:FindFirstChild("ExpansionForces") then
        local forces = Instance.new("Folder")
        forces.Name = "ExpansionForces"
        
        local bodyPos = Instance.new("BodyPosition")
        bodyPos.Position = head.Position
        bodyPos.MaxForce = Vector3.new(10000, 10000, 10000)
        bodyPos.P = 10000
        bodyPos.Parent = forces
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
        bodyGyro.P = 10000
        bodyGyro.Parent = forces
        
        forces.Parent = head
    end

    -- Conectar evento de muerte solo si no está ya conectado
    if not playerConnections[player] then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            playerConnections[player] = humanoid.Died:Connect(function()
                -- Eliminar fuerzas físicas
                if head:FindFirstChild("ExpansionForces") then
                    head.ExpansionForces:Destroy()
                end
                
                -- Restaurar cabeza en el nuevo personaje
                player.CharacterAdded:Wait()
                task.wait(0.5) -- Esperar a que el personaje se estabilice
                expandHead(player)
            end)
        end
    end
end

-- Función mejorada para desactivar la expansión
function disableHeadExpand()
    headExpansionEnabled = false
    
    -- Desconectar todos los eventos
    for player, connection in pairs(playerConnections) do
        connection:Disconnect()
    end
    playerConnections = {}
    
    -- Restaurar todos los jugadores
    for _, player in pairs(players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("Head") then
            local head = character.Head
            
            -- Eliminar fuerzas físicas
            if head:FindFirstChild("ExpansionForces") then
                head.ExpansionForces:Destroy()
            end
            
            -- Restaurar propiedades originales
            if head:FindFirstChild("OriginalData") then
                local data = head.OriginalData
                
                head.Size = data.Size.Value
                head.Transparency = data.Transparency.Value
                head.CanCollide = data.CanCollide.Value
                
                -- Restaurar mesh si existe
                local mesh = head:FindFirstChildOfClass("SpecialMesh")
                if mesh and data:FindFirstChild("MeshScale") then
                    mesh.Scale = data.MeshScale.Value
                end
                
                data:Destroy()
            end
        end
    end
end

-- Función para reactivar la expansión
function enableHeadExpand()
    headExpansionEnabled = true
    
    -- Aplicar a todos los jugadores
    for _, player in pairs(players:GetPlayers()) do
        if player ~= players.LocalPlayer then
            expandHead(player)
        end
    end
end

-- Conectar eventos de jugadores
players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        expandHead(player)
    end)
end)

-- Aplicar a jugadores existentes
for _, player in pairs(players:GetPlayers()) do
    if player ~= players.LocalPlayer then
        expandHead(player)
    end
end

-- Funciones globales para la API
return {
    activate = enableHeadExpand,
    deactivate = disableHeadExpand,
    isActive = function() return headExpansionEnabled end
}
