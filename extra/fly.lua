local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 18  -- Velocidad segura
local flying = false
local flyConnection
local originalGravity = workspace.Gravity
local lastPosition = torso.Position

-- Sistema de movimiento compatible con la replicación
local function startFlying()
    if flying then return end
    flying = true
    
    -- Guardar estado inicial
    originalGravity = workspace.Gravity
    lastPosition = torso.Position
    
    -- Reducción gradual de gravedad
    for i = 1, 10 do
        workspace.Gravity = originalGravity * (1 - i/10)
        task.wait(0.03)
    end
    
    -- Sistema de movimiento autorizado
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        
        -- Obtener inputs de movimiento
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new()
        local verticalInput = 0
        
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
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            verticalInput = 0.7
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            verticalInput = -0.7
        end
        
        -- Calcular nueva posición
        local newPosition = torso.Position + 
            moveDirection.Unit * flySpeed * 0.03 +
            Vector3.new(0, verticalInput * flySpeed * 0.03, 0)
        
        -- Limitar distancia desde última posición válida
        if (newPosition - lastPosition).Magnitude > 5 then
            newPosition = lastPosition + (newPosition - lastPosition).Unit * 5
        end
        
        -- Aplicar movimiento autorizado
        torso.CFrame = CFrame.new(newPosition)
        lastPosition = newPosition
        
        -- Replicar movimiento natural
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end)
    
    -- Simular replicación legítima
    local function safeReplicate()
        while flying do
            -- Usar el sistema de replicación del juego
            game:GetService("ReplicatedStorage").Connections.CharacterReplicator:FireServer(
                "UpdatePosition",
                torso.Position,
                torso.CFrame
            )
            task.wait(0.1)
        end
    end
    coroutine.wrap(safeReplicate)()
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Restaurar gravedad gradualmente
    for i = 1, 10 do
        workspace.Gravity = originalGravity * (i/10)
        task.wait(0.03)
    end
    
    -- Desconectar sistema de vuelo
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Aterrizaje seguro
    local ray = Ray.new(torso.Position, Vector3.new(0, -50, 0))
    local hit, position = workspace:FindPartOnRay(ray, character)
    if hit then
        -- Replicar aterrizaje válido
        game:GetService("ReplicatedStorage").Connections.RemoteFunction:InvokeServer(
            "SafeTeleport",
            position + Vector3.new(0, 3, 0)
        )
    end
    
    -- Restaurar estado normal
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
