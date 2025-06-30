local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 18  -- Velocidad reducida para parecer más natural
local flying = false
local flyConnection

-- Movimiento más natural que imita caminar/nadar
local function startFlying()
    if flying then return end
    flying = true
    
    -- Guardar estado original
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    
    -- Configurar estado de "nadar" para justificar movimiento en aire
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    
    -- Pequeñas mejoras de movimiento que parecen naturales
    humanoid.WalkSpeed = 18
    humanoid.JumpPower = 0
    
    -- Sistema de movimiento que imita caminar en el aire
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        
        -- Movimiento relativo a la cámara (como caminar normal)
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
        
        -- Movimiento vertical más suave
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 0.7, 0)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection + Vector3.new(0, -0.7, 0)
        end
        
        -- Aplicar movimiento como si estuvieras caminando/nadando
        if moveDirection.Magnitude > 0 then
            -- Limitar altura máxima para no levantar sospechas
            local maxHeight = 15  -- Altura máxima permitida antes de ser detectado
            if torso.Position.Y > maxHeight then
                moveDirection = Vector3.new(moveDirection.X, -0.5, moveDirection.Z)
            end
            
            -- Mover usando CFrame para parecer más natural
            torso.CFrame = torso.CFrame + moveDirection.Unit * (flySpeed / 30)
        end
        
        -- Simular pequeñas fluctuaciones de altura como si nadaras
        local waveEffect = math.sin(tick() * 5) * 0.05
        torso.CFrame = torso.CFrame + Vector3.new(0, waveEffect, 0)
    end)
    
    -- Sistema para aterrizar suavemente
    local landCheckConnection
    landCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then 
            landCheckConnection:Disconnect()
            return
        end
        
        -- Verificar si estamos cerca del suelo
        local ray = Ray.new(torso.Position, Vector3.new(0, -5, 0))
        local hit, _ = workspace:FindPartOnRay(ray, character)
        
        if hit then
            stopFlying()
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            landCheckConnection:Disconnect()
        end
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Restaurar estado natural
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Pequeña animación de aterrizaje
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
