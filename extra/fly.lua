local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 35
local flying = false
local flyConnection
local particleEffect
local originalGravity = workspace.Gravity

-- Crear efecto visual para el vuelo
local function createFlightEffect()
    if particleEffect then particleEffect:Destroy() end
    
    particleEffect = Instance.new("ParticleEmitter")
    particleEffect.Color = ColorSequence.new(Color3.new(0, 0.8, 1))
    particleEffect.LightEmission = 0.7
    particleEffect.Size = NumberSequence.new(0.4)
    particleEffect.Texture = "rbxassetid://243664672"
    particleEffect.Transparency = NumberSequence.new(0.4)
    particleEffect.Acceleration = Vector3.new(0, -5, 0)
    particleEffect.Lifetime = NumberRange.new(0.8)
    particleEffect.Rate = 25
    particleEffect.Speed = NumberRange.new(3)
    particleEffect.Parent = torso
end

-- Sistema de vuelo con gravedad controlada
local function startFlying()
    if flying then return end
    flying = true
    
    -- Guardar gravedad original
    originalGravity = workspace.Gravity
    
    -- Crear efecto visual
    createFlightEffect()
    
    -- Reducir gravedad para permitir vuelo
    workspace.Gravity = 25  -- Gravedad reducida
    
    -- Crear controles de vuelo
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(0, 0, 0)  -- Inicialmente sin fuerza
    bv.P = 1250
    bv.Parent = torso
    
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        local verticalBoost = 0
        
        -- Movimiento horizontal
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        
        -- Movimiento vertical
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            verticalBoost = 1.5
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            verticalBoost = -1.0
        end
        
        -- Aplicar movimiento con gravedad compensada
        local velocity = moveDirection * flySpeed
        velocity = Vector3.new(velocity.X, velocity.Y + verticalBoost * flySpeed, velocity.Z)
        
        -- Mantener altura si no hay input vertical
        if verticalBoost == 0 then
            velocity = Vector3.new(velocity.X, -2, velocity.Z)  -- Caída lenta
        end
        
        bv.Velocity = velocity
        bv.MaxForce = Vector3.new(10000, 10000, 10000)
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Restaurar gravedad
    workspace.Gravity = originalGravity
    
    -- Eliminar efecto visual
    if particleEffect then
        particleEffect:Destroy()
        particleEffect = nil
    end
    
    -- Desconectar el vuelo
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Eliminar BodyVelocity
    for _, child in ipairs(torso:GetChildren()) do
        if child:IsA("BodyVelocity") then
            child:Destroy()
        end
    end
    
    -- Transición suave a caminar
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    -- Aterrizaje forzado si está volando
    if torso.Position.Y > 50 then
        local ray = Ray.new(torso.Position, Vector3.new(0, -500, 0))
        local hit, position = workspace:FindPartOnRay(ray, character)
        if hit then
            torso.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
        end
    end
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
