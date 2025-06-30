local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 50
local flying = false
local flyConnection
local bv  -- Solo BodyVelocity para evitar detección

-- Variables para el estado de las teclas
local keysPressed = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.D] = false,
    [Enum.KeyCode.Space] = false,
    [Enum.KeyCode.LeftShift] = false
}

local function startFlying()
    if flying then return end
    flying = true
    
    -- Guardar estado original para restaurar al final
    local originalGravity = workspace.Gravity
    local originalPlatformStand = humanoid.PlatformStand
    
    -- Usar solo BodyVelocity para ser menos detectable
    bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.P = 1250  -- Suavizar movimiento
    bv.Parent = torso
    
    -- Desactivar gravedad solo para este personaje
    humanoid:SetAttribute("OriginalGravity", originalGravity)
    workspace.Gravity = 0
    
    -- Configurar detección de teclas
    local inputService = game:GetService("UserInputService")
    
    -- Registrar presión de teclas
    local keyDownConnection = inputService.InputBegan:Connect(function(input)
        if keysPressed[input.KeyCode] ~= nil then
            keysPressed[input.KeyCode] = true
        end
    end)
    
    local keyUpConnection = inputService.InputEnded:Connect(function(input)
        if keysPressed[input.KeyCode] ~= nil then
            keysPressed[input.KeyCode] = false
        end
    end)
    
    -- Bucle de movimiento suave
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying or not bv or not bv.Parent then return end
        
        local camera = workspace.CurrentCamera
        local direction = Vector3.new()
        
        -- Movimiento relativo a la cámara
        if keysPressed[Enum.KeyCode.W] then
            direction = direction + camera.CFrame.LookVector
        end
        if keysPressed[Enum.KeyCode.S] then
            direction = direction - camera.CFrame.LookVector
        end
        if keysPressed[Enum.KeyCode.A] then
            direction = direction - camera.CFrame.RightVector
        end
        if keysPressed[Enum.KeyCode.D] then
            direction = direction + camera.CFrame.RightVector
        end
        if keysPressed[Enum.KeyCode.Space] then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if keysPressed[Enum.KeyCode.LeftShift] then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        -- Aplicar velocidad solo si hay dirección
        if direction.Magnitude > 0 then
            bv.Velocity = direction.Unit * flySpeed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
    end)
    
    -- Restaurar estado al tocar suelo
    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed then
            stopFlying()
        end
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Restaurar gravedad original
    if humanoid:GetAttribute("OriginalGravity") then
        workspace.Gravity = humanoid:GetAttribute("OriginalGravity")
    else
        workspace.Gravity = 196.2
    end
    
    -- Eliminar controles de vuelo
    if bv then
        bv.Velocity = Vector3.new(0, 0, 0)
        bv:Destroy()
    end
    
    -- Desconectar eventos
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    -- Restablecer estado del personaje
    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
