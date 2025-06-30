local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 22  -- Velocidad moderada para evitar detección
local flying = false
local flyConnection
local particleEffect
local originalGravity = workspace.Gravity

-- Crear efecto visual discreto
local function createFlightEffect()
    if particleEffect then particleEffect:Destroy() end
    
    particleEffect = Instance.new("ParticleEmitter")
    particleEffect.Color = ColorSequence.new(Color3.new(0.8, 0.8, 0.8))
    particleEffect.LightEmission = 0.3
    particleEffect.Size = NumberSequence.new(0.2)
    particleEffect.Texture = "rbxassetid://243664672"
    particleEffect.Transparency = NumberSequence.new(0.7)
    particleEffect.Acceleration = Vector3.new(0, -2, 0)
    particleEffect.Lifetime = NumberRange.new(0.6)
    particleEffect.Rate = 15
    particleEffect.Speed = NumberRange.new(1)
    particleEffect.Parent = torso
end

-- Sistema de vuelo que imita movimiento natural
local function startFlying()
    if flying then return end
    flying = true
    
    -- Guardar estado original
    originalGravity = workspace.Gravity
    local originalWalkSpeed = humanoid.WalkSpeed
    
    -- Crear efecto visual discreto
    createFlightEffect()
    
    -- Reducir gravedad gradualmente
    for i = 0, 1, 0.1 do
        workspace.Gravity = originalGravity * (1 - i)
        task.wait(0.05)
    end
    
    -- Sistema de movimiento natural
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not flying then return end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        local isMoving = false
        
        -- Movimiento horizontal muy suave
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + (camera.CFrame.LookVector * Vector3.new(1,0,0.8)).Unit
            isMoving = true
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - (camera.CFrame.LookVector * Vector3.new(1,0,0.8)).Unit
            isMoving = true
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - (camera.CFrame.RightVector * 0.7)
            isMoving = true
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + (camera.CFrame.RightVector * 0.7)
            isMoving = true
        end
        
        -- Movimiento vertical suave
        local verticalInput = 0
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            verticalInput = 0.5
        elseif game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            verticalInput = -0.5
        end
        
        -- Aplicar movimiento con física natural
        if isMoving or verticalInput ~= 0 then
            -- Movimiento horizontal suave
            local horizontalVelocity = moveDirection * flySpeed * 0.8
            torso.Velocity = Vector3.new(
                horizontalVelocity.X,
                torso.Velocity.Y + verticalInput * 10,
                horizontalVelocity.Z
            )
            
            -- Pequeño impulso vertical
            if verticalInput ~= 0 then
                torso.Velocity = Vector3.new(
                    torso.Velocity.X,
                    verticalInput * flySpeed,
                    torso.Velocity.Z
                )
            end
        else
            -- Mantener posición flotando suavemente
            torso.Velocity = Vector3.new(
                torso.Velocity.X * 0.9,
                math.sin(tick() * 5) * 0.5,
                torso.Velocity.Z * 0.9
            )
        end
        
        -- Imitar animación de caminar cuando se mueve horizontalmente
        if isMoving then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        else
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Restaurar gravedad gradualmente
    for i = 0, 1, 0.1 do
        workspace.Gravity = originalGravity * i
        task.wait(0.05)
    end
    
    -- Eliminar efecto visual
    if particleEffect then
        particleEffect:Destroy()
        particleEffect = nil
    end
    
    -- Desconectar el vuelo
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Transición suave a caminar
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.3)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    -- Asegurar aterrizaje
    local ray = Ray.new(torso.Position, Vector3.new(0, -10, 0))
    local hit, position = workspace:FindPartOnRay(ray, character)
    if hit then
        torso.CFrame = CFrame.new(torso.Position.X, position.Y + 3, torso.Position.Z)
    end
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
