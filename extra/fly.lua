local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 12  -- Velocidad más lenta para parecer natural
local flying = false
local flyConnection
local originalGravity = workspace.Gravity

-- Sistema de movimiento basado en CFrame sin componentes físicos
local function startFlying()
    if flying then return end
    flying = true
    
    -- Restablecer cualquier estado previo
    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    -- Almacenar posición inicial como referencia
    local startPosition = torso.Position
    
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function(delta)
        if not flying then return end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        
        -- Movimiento horizontal relativo a la cámara
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
        
        -- Movimiento vertical suave
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 0.7, 0)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection + Vector3.new(0, -0.7, 0)
        end
        
        -- Limitar altura máxima
        local currentHeight = torso.Position.Y - startPosition.Y
        if currentHeight > 10 then
            moveDirection = Vector3.new(moveDirection.X, -0.3, moveDirection.Z)
        end
        
        -- Aplicar movimiento si hay dirección
        if moveDirection.Magnitude > 0 then
            -- Movimiento suave usando CFrame
            local newPosition = torso.Position + moveDirection.Unit * flySpeed * delta
            torso.CFrame = CFrame.new(newPosition, newPosition + camera.CFrame.LookVector)
        end
        
        -- Pequeña animación de "flotación" natural
        torso.CFrame = torso.CFrame * CFrame.new(0, math.sin(tick() * 8) * 0.03, 0)
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Aterrizaje suave
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    -- Restablecer posición si está muy alto
    local ray = Ray.new(torso.Position, Vector3.new(0, -50, 0))
    local hit = workspace:FindPartOnRay(ray, character)
    if not hit then
        -- Buscar posición segura cerca del suelo
        local safePosition = (torso.Position - Vector3.new(0, 30, 0))
        torso.CFrame = CFrame.new(safePosition)
    end
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
