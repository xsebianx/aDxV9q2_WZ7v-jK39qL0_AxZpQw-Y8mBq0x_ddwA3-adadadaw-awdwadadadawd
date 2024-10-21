local aimEnabled = false -- El aimbot está desactivado por defecto y se activa con clic derecho
local fieldOfView = 30 -- Campo de visión ajustado a 30 grados para un equilibrio
local detectionRadius = 75 -- Radio de detección ampliado para mayor facilidad de uso
local closestTarget = nil
local sound
local connections = {} -- Tabla para almacenar las conexiones

-- Crear un sonido para alertas
local function createAlertSound()
    if sound then sound:Destroy() end
    sound = Instance.new("Sound", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    sound.SoundId = "rbxassetid://12222242" -- ID del sonido de alerta
    sound.Volume = 1
end

-- Verificar si el objetivo es visible, sin obstáculos en el camino
local function isVisible(part)
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (part.Position - origin).unit * 5000 -- Aumenta la longitud del rayo para mayor alcance
    local ray = Ray.new(origin, direction)
    local partHit, _ = workspace:FindPartOnRay(ray, game.Players.LocalPlayer.Character, false, true)
    return partHit and partHit:IsDescendantOf(part.Parent)
end

-- Función para encontrar el objetivo más cercano dentro del campo de visión y que esté visible
local function getClosestNPCInFOV()
    local closestDistance = math.huge
    local target = nil
    local camera = workspace.CurrentCamera
    local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    
    for _, npc in pairs(workspace:GetDescendants()) do -- Buscar en todo el workspace
        if npc:IsA("Model") and npc:FindFirstChild("Head") and not game.Players:GetPlayerFromCharacter(npc) then
            local headScreenPos = camera:WorldToViewportPoint(npc.Head.Position)
            local distanceFromCenter = (screenCenter - Vector2.new(headScreenPos.X, headScreenPos.Y)).magnitude
            -- Si el NPC está dentro del campo de visión y está visible
            if distanceFromCenter < detectionRadius and isVisible(npc.Head) then
                local distance = (camera.CFrame.Position - npc.Head.Position).magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    target = npc
                end
            end
        end
    end
    return target
end

-- Función de Aimbot que apunta instantáneamente a la cabeza
local function aimbot(target)
    if target and target:FindFirstChild("Head") then
        local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(target.Head.Position)
        mousemoverel((headScreenPos.X - workspace.CurrentCamera.ViewportSize.X / 2), (headScreenPos.Y - workspace.CurrentCamera.ViewportSize.Y / 2))
    end
end

-- Actualizar el objetivo cada ciclo
local function onRenderStepped()
    if aimEnabled then
        local newTarget = getClosestNPCInFOV() -- Encontrar el NPC más cercano dentro del FOV y radio de detección
        if newTarget and newTarget ~= closestTarget then
            closestTarget = newTarget
            sound:Play()
        end
        if closestTarget then
            aimbot(closestTarget) -- Usar Aimbot para asegurar el impacto
        end
    end
end

-- Controles de teclas para activar el aimbot con clic derecho
local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Clic derecho para activar el aimbot
        aimEnabled = true
    end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Soltar clic derecho para desactivar el aimbot
        aimEnabled = false
        closestTarget = nil
    end
end

-- Iniciar el sonido de alerta
createAlertSound()

-- Manejar la reconexión del jugador y la muerte
local localPlayer = game.Players.LocalPlayer
local function onCharacterAdded(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        createAlertSound()
    end)
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Conectar eventos
table.insert(connections, game:GetService("RunService").RenderStepped:Connect(onRenderStepped))
table.insert(connections, game:GetService("UserInputService").InputBegan:Connect(onInputBegan))
table.insert(connections, game:GetService("UserInputService").InputEnded:Connect(onInputEnded))

-- Función para desactivar el aimbot NPC
local function disableAimbotNPC()
    aimEnabled = false
    closestTarget = nil
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
end

-- Exponer la función de desactivación globalmente para que pueda ser llamada desde fuera
_G.disableAimbotNPC = disableAimbotNPC