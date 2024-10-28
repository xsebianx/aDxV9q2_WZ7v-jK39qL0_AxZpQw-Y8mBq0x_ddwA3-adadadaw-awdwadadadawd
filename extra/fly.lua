local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

-- Variables iniciales
local flyEnabled = false
local flightSpeed = 50 -- Velocidad de vuelo por defecto

-- Controles de vuelo
local flyControl = {
    space = false,
    shift = false,
    w = false,
    a = false,
    s = false,
    d = false,
}

-- Función para activar el vuelo
function activateFly()
    flyEnabled = true -- Activar el vuelo
    plr.Character.Humanoid.PlatformStand = true -- Desactivar la física del personaje
end

-- Función para desactivar el vuelo
function disableFly()
    flyEnabled = false -- Desactivar el vuelo
    plr.Character.Humanoid.PlatformStand = false -- Activar la física del personaje
end

-- Asignar las funciones a las variables globales
_G.activateFly = activateFly
_G.disableFly = disableFly

-- Captura de entradas del teclado
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        flyControl.w = true
    elseif input.KeyCode == Enum.KeyCode.A then
        flyControl.a = true
    elseif input.KeyCode == Enum.KeyCode.S then
        flyControl.s = true
    elseif input.KeyCode == Enum.KeyCode.D then
        flyControl.d = true
    elseif input.KeyCode == Enum.KeyCode.Space then
        flyControl.space = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        flyControl.shift = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        flyControl.w = false
    elseif input.KeyCode == Enum.KeyCode.A then
        flyControl.a = false
    elseif input.KeyCode == Enum.KeyCode.S then
        flyControl.s = false
    elseif input.KeyCode == Enum.KeyCode.D then
        flyControl.d = false
    elseif input.KeyCode == Enum.KeyCode.Space then
        flyControl.space = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        flyControl.shift = false
    end
end)

-- Conexión al ciclo de actualización del juego
RunService.Heartbeat:Connect(function(delta)
    if flyEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character.HumanoidRootPart
        local moveDirection = Vector3.new(
            (flyControl.d and 1 or 0) - (flyControl.a and 1 or 0),
            (flyControl.space and 1 or 0) - (flyControl.shift and 1 or 0),
            (flyControl.s and 1 or 0) - (flyControl.w and 1 or 0)
        )

        -- Normalizar la dirección de movimiento para evitar movimientos más rápidos en diagonal
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        -- Actualiza la posición del jugador según las teclas presionadas
        hrp.Velocity = moveDirection * flightSpeed
    end
end)
