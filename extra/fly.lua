local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 18
local flying = false
local flyConnection
local lastValidPosition = torso.Position
local safeHeight = 5  -- Altura máxima segura sobre el suelo

-- Sistema de vuelo que mantiene posición válida
local function startFlying()
    if flying then return end
    flying = true
    
    -- Guardar última posición válida
    lastValidPosition = torso.Position
    
    -- Crear un punto de anclaje seguro
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Position = lastValidPosition
    anchor.Parent = workspace
    
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not flying or not torso then return end
        
        -- Calcular nueva posición basada en inputs
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        
        -- Movimiento relativo a la cámara (sin vertical)
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + (camera.CFrame.LookVector * Vector3.new(1,0,1)).Unit
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - (camera.CFrame.LookVector * Vector3.new(1,0,1)).Unit
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        
        -- Movimiento vertical independiente
        local verticalMove = 0
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            verticalMove = 1
        elseif game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            verticalMove = -1
        end
        
        -- Actualizar posición del anclaje
        anchor.Position = anchor.Position + 
            moveDirection * flySpeed * dt +
            Vector3.new(0, verticalMove * flySpeed * dt, 0)
        
        -- Mantener altura segura sobre el suelo
        local ray = Ray.new(anchor.Position, Vector3.new(0, -100, 0))
        local hit, position = workspace:FindPartOnRay(ray, character)
        
        if hit then
            local groundHeight = position.Y
            if anchor.Position.Y > groundHeight + safeHeight then
                anchor.Position = Vector3.new(
                    anchor.Position.X,
                    groundHeight + safeHeight,
                    anchor.Position.Z
                )
            end
        end
        
        -- Mover personaje suavemente hacia el anclaje
        torso.CFrame = torso.CFrame:Lerp(
            CFrame.new(anchor.Position) * CFrame.Angles(0, camera.CFrame.Y, 0),
            0.5
        )
        
        -- Actualizar última posición válida
        lastValidPosition = anchor.Position
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Desconectar el vuelo
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Encontrar posición segura para aterrizar
    local ray = Ray.new(torso.Position, Vector3.new(0, -100, 0))
    local hit, position = workspace:FindPartOnRay(ray, character)
    
    if hit then
        -- Mover a posición segura
        torso.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    else
        -- Volver a la última posición válida
        torso.CFrame = CFrame.new(lastValidPosition)
    end
    
    -- Eliminar anclaje
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "FlightAnchor" then
            obj:Destroy()
        end
    end
    
    -- Restaurar estado normal
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
