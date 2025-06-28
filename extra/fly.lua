local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

-- Variables iniciales
local flyEnabled = false
local flightSpeed = 5 -- Velocidad de vuelo por defecto

-- Controles de vuelo
local flyControl = {
    space = false,
    shift = false,
    w = false,
    a = false,
    s = false,
    d = false,
}

-- Conexiones para poder desconectarlas
local inputBeganConnection
local inputEndedConnection
local heartbeatConnection

-- Función para activar el vuelo
function activateFly()
    if flyEnabled then return end  -- Si ya está activo, no hacer nada
    
    flyEnabled = true
    
    -- Crear conexiones solo si no existen
    if not inputBeganConnection then
        inputBeganConnection = UserInputService.InputBegan:Connect(function(input)
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
    end
    
    if not inputEndedConnection then
        inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
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
    end
    
    if not heartbeatConnection then
        heartbeatConnection = RunService.Heartbeat:Connect(function(delta)
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
    end
    
    -- Mensaje de confirmación
    print("Fly activado. Usa W, A, S, D, Espacio y Shift para moverte.")
end

-- Función para desactivar el vuelo
function disableFly()
    if not flyEnabled then return end  -- Si ya está desactivado, no hacer nada
    
    flyEnabled = false
    
    -- Resetear todos los controles
    for key in pairs(flyControl) do
        flyControl[key] = false
    end
    
    -- Mensaje de confirmación
    print("Fly desactivado.")
end

-- Función para cambiar la velocidad de vuelo
function setFlightSpeed(newSpeed)
    flightSpeed = newSpeed
    print("Velocidad de vuelo cambiada a: " .. newSpeed)
end

-- Asignar las funciones a las variables globales
_G.activateFly = activateFly
_G.disableFly = disableFly
_G.setFlightSpeed = setFlightSpeed

-- Si quieres que el fly esté activo por defecto al cargar el script, descomenta:
-- activateFly()