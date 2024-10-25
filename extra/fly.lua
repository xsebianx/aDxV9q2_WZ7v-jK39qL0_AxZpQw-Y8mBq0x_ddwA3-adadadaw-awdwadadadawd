local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

-- Variables iniciales
local flyEnabled = false -- Estado inicial del vuelo
local gamesetting = {
    flightspeed = 5 -- Velocidad de vuelo por defecto
}

local flycontrol = {
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
            flycontrol.w = true
        elseif input.KeyCode == Enum.KeyCode.A then
            flycontrol.a = true
        elseif input.KeyCode == Enum.KeyCode.S then
            flycontrol.s = true
        elseif input.KeyCode == Enum.KeyCode.D then
            flycontrol.d = true
        elseif input.KeyCode == Enum.KeyCode.Space then
            flycontrol.space = true
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            flycontrol.shift = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        flycontrol.w = false
    elseif input.KeyCode == Enum.KeyCode.A then
        flycontrol.a = false
    elseif input.KeyCode == Enum.KeyCode.S then
        flycontrol.s = false
    elseif input.KeyCode == Enum.KeyCode.D then
        flycontrol.d = false
    elseif input.KeyCode == Enum.KeyCode.Space then
        flycontrol.space = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        flycontrol.shift = false
    end
end)

-- Conexión al ciclo de actualización del juego
RunService.Heartbeat:Connect(function(delta)
    if flyEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local s = gamesetting.flightspeed * 10 * delta
        local hrp = plr.Character.HumanoidRootPart
        local cf = hrp.CFrame

        -- Actualiza la posición del jugador según las teclas presionadas
        hrp.CFrame = cf * CFrame.new(
            (flycontrol.d and s or 0) - (flycontrol.a and s or 0),
            (flycontrol.space and s or 0) - (flycontrol.shift and s or 0),
            (flycontrol.s and s or 0) - (flycontrol.w and s or 0)
        )

        -- Detener la física de las partes del personaje
        for _, v in pairs(plr.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Velocity, v.RotVelocity = Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
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