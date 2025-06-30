local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 30  -- Velocidad aumentada
local flying = false
local flyConnection
local particleEffect

-- Crear efecto visual para el vuelo
local function createFlightEffect()
    if particleEffect then particleEffect:Destroy() end
    
    particleEffect = Instance.new("ParticleEmitter")
    particleEffect.Color = ColorSequence.new(Color3.new(1, 0.3, 0.1))
    particleEffect.LightEmission = 0.8
    particleEffect.Size = NumberSequence.new(0.3)
    particleEffect.Texture = "rbxassetid://243664672"
    particleEffect.Transparency = NumberSequence.new(0.5)
    particleEffect.ZOffset = 0.5
    particleEffect.Acceleration = Vector3.new(0, -5, 0)
    particleEffect.Lifetime = NumberRange.new(0.5)
    particleEffect.Rate = 30
    particleEffect.Rotation = NumberRange.new(0, 360)
    particleEffect.Speed = NumberRange.new(2)
    particleEffect.VelocitySpread = 20
    particleEffect.Parent = torso
end

-- Sistema de movimiento potente pero controlado
local function startFlying()
    if flying then return end
    flying = true
    
    -- Crear efecto visual
    createFlightEffect()
    
    -- Guardar posición inicial para referencia
    local startY = torso.Position.Y
    
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function(delta)
        if not flying or not torso then return end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        
        -- Movimiento horizontal (WASD)
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
        
        -- Movimiento vertical (Espacio/Shift)
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1.5, 0)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection + Vector3.new(0, -1.5, 0)
        end
        
        -- Aplicar movimiento potente
        if moveDirection.Magnitude > 0 then
            -- Factor de impulso inicial
            local boost = 1.0
            if moveDirection.Y > 0 then
                boost = 1.5  -- Impulso extra hacia arriba
            end
            
            -- Movimiento con impulso
            local moveVector = moveDirection.Unit * flySpeed * boost * delta * 60
            local newCFrame = torso.CFrame + moveVector
            
            -- Limitar altura máxima (50 unidades desde inicio)
            if newCFrame.Position.Y > startY + 50 then
                newCFrame = CFrame.new(
                    newCFrame.Position.X, 
                    startY + 50, 
                    newCFrame.Position.Z
                )
            end
            
            torso.CFrame = newCFrame
        end
        
        -- Efecto de flotación más pronunciado
        local floatEffect = math.sin(tick() * 8) * 0.1
        torso.CFrame = torso.CFrame * CFrame.new(0, floatEffect, 0)
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Eliminar efecto visual
    if particleEffect then
        particleEffect:Destroy()
        particleEffect = nil
    end
    
    -- Desconectar el vuelo
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Efecto de aterrizaje
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    -- Buscar suelo si estamos muy alto
    local ray = Ray.new(torso.Position, Vector3.new(0, -100, 0))
    local hit, position = workspace:FindPartOnRay(ray, character)
    if hit then
        torso.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
