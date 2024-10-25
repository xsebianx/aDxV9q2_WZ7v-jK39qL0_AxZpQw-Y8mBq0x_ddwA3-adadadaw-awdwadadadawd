local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

-- Variables iniciales
local flyEnabled = false
local flightSpeed = 5 -- Velocidad de vuelo por defecto

local flyControl = {
    space = false,
    shift = false,
    w = false,
    a = false,
    s = false,
    d = false,
}

-- Captura de entradas del teclado
UserInputService.InputBegan:Connect(function(input)
    if flyEnabled then
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
        local speed = flightSpeed * 10 * delta
        local hrp = plr.Character.HumanoidRootPart
        local cf = hrp.CFrame

        -- Actualiza la posición del jugador según las teclas presionadas
        hrp.CFrame = cf * CFrame.new(
            (flyControl.d and speed or 0) - (flyControl.a and speed or 0),
            (flyControl.space and speed or 0) - (flyControl.shift and speed or 0),
            (flyControl.s and speed or 0) - (flyControl.w and speed or 0)
        )

        -- Detener la física de las partes del personaje
        for _, part in pairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)

-- Conexión con el menú externo para habilitar/deshabilitar el vuelo
_G.disableFly = function()
    flyEnabled = false -- Desactivar el vuelo
end

-- Esta función puede ser llamada desde tu menú externo para habilitar el vuelo
function enableFly()
    flyEnabled = true -- Activar el vuelo
end