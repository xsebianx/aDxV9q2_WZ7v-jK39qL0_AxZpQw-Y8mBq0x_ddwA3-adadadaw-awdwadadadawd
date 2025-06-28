local players = game:GetService("Players")
local debris = game:GetService("Debris")

-- Función para cambiar el tamaño de la cabeza y hacerla transparente
local function expandHead(player)
    if player == players.LocalPlayer then return end -- No aplicar al jugador local

    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    
    -- Guardar el tamaño original
    if not head:FindFirstChild("OriginalSize") then
        local originalSize = Instance.new("Vector3Value")
        originalSize.Name = "OriginalSize"
        originalSize.Value = head.Size
        originalSize.Parent = head
    end

    -- Aumentar tamaño y transparencia
    head.Size = Vector3.new(10, 10, 10)
    head.Transparency = 0.5
    head.CanCollide = true

    -- Ajustar Mesh
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        mesh.Scale = Vector3.new(10, 10, 10)
    end

    -- Crear fuerzas para simular expansión física
    local bodyPos = Instance.new("BodyPosition")
    bodyPos.Position = head.Position
    bodyPos.MaxForce = Vector3.new(10000, 10000, 10000)
    bodyPos.P = 10000
    bodyPos.Parent = head

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
    bodyGyro.P = 10000
    bodyGyro.Parent = head

    -- Conectar evento de muerte
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        -- 1. Crear explosión al morir
        local explosion = Instance.new("Explosion")
        explosion.Position = head.Position
        explosion.BlastRadius = 15
        explosion.BlastPressure = 1000000
        explosion.DestroyJointRadiusPercent = 0
        explosion.ExplosionType = Enum.ExplosionType.NoCraters
        explosion.Parent = workspace

        -- 2. Eliminar fuerzas físicas
        bodyPos:Destroy()
        bodyGyro:Destroy()

        -- 3. Restaurar cabeza en el nuevo personaje
        player.CharacterAdded:Wait()
        wait(0.5) -- Esperar a que el personaje se estabilice
        expandHead(player)
    end)
end

-- Función para desactivar la expansión (actualizada)
function disableHeadExpand()
    for _, player in pairs(players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("Head") then
            local head = character.Head
            
            -- Destruir fuerzas físicas
            for _, obj in ipairs(head:GetChildren()) do
                if obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                    obj:Destroy()
                end
            end
            
            -- Restaurar tamaño original
            local originalSize = head:FindFirstChild("OriginalSize")
            if originalSize then
                head.Size = originalSize.Value
                head.Transparency = 0
                
                local mesh = head:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh.Scale = Vector3.new(1, 1, 1)
                end
                
                originalSize:Destroy()
            end
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

-- Funciones globales
_G.activateHeadExpand = expandHead
_G.disableHeadExpand = disableHeadExpand