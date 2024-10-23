local aimEnabled = false -- El aimbot está desactivado por defecto y se activa con clic derecho
local fieldOfView = 30 -- Campo de visión ajustado a 30 grados para un equilibrio
local detectionRadius = 75 -- Radio de detección ampliado para mayor facilidad de uso
local closestTarget = nil
local fovCircle
local visibleLabel
local targetIndicator
local notificationLabel
local sound
local totalTargetsDetected = 0
local connections = {} -- Tabla para almacenar las conexiones

-- Crear un círculo visual para mostrar el FOV del aimbot
local function createFOVCircle()
    if fovCircle then fovCircle:Remove() end
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 2
    fovCircle.Radius = fieldOfView
    fovCircle.Color = Color3.fromRGB(255, 0, 0)
    fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end

-- Crear un TextLabel para mostrar "Jugador visible"
local function createVisibleLabel()
    if visibleLabel then visibleLabel:Remove() end
    local screenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    visibleLabel = Instance.new("TextLabel", screenGui)
    visibleLabel.Size = UDim2.new(0, 200, 0, 50)
    visibleLabel.Position = UDim2.new(0.5, -100, 0, 10)
    visibleLabel.Text = "Jugador visible"
    visibleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    visibleLabel.TextScaled = true
    visibleLabel.BackgroundTransparency = 1
    visibleLabel.Visible = false
end

-- Crear un indicador visual para el objetivo
local function createTargetIndicator()
    if targetIndicator then targetIndicator:Remove() end
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 5
    targetIndicator.Color = Color3.fromRGB(0, 255, 0)
end

-- Crear un TextLabel para notificaciones
local function createNotificationLabel()
    if notificationLabel then notificationLabel:Remove() end
    local screenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    notificationLabel = Instance.new("TextLabel", screenGui)
    notificationLabel.Size = UDim2.new(0, 300, 0, 50)
    notificationLabel.Position = UDim2.new(0.5, -150, 0, 60)
    notificationLabel.Text = ""
    notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    notificationLabel.TextScaled = true
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.Visible = false
end

-- Crear un sonido para alertas
local function createAlertSound()
    if sound then sound:Destroy() end
    sound = Instance.new("Sound", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    sound.SoundId = "rbxassetid://12222242" -- ID del sonido de alerta
    sound.Volume = 1
end

-- Mostrar una notificación
local function showNotification(message)
    notificationLabel.Text = message
    notificationLabel.Visible = true
    wait(2)
    notificationLabel.Visible = false
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
local function getClosestPlayerInFOV()
    local closestDistance = math.huge
    local target = nil
    local camera = workspace.CurrentCamera
    local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local headScreenPos = camera:WorldToViewportPoint(player.Character.Head.Position)
            local distanceFromCenter = (screenCenter - Vector2.new(headScreenPos.X, headScreenPos.Y)).magnitude
            -- Si el jugador está dentro del campo de visión y está visible
            if distanceFromCenter < detectionRadius and isVisible(player.Character.Head) then
                local distance = (camera.CFrame.Position - player.Character.Head.Position).magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    target = player
                end
            end
        end
    end
    return target
end

-- Función de Aimbot que apunta instantáneamente a la cabeza
local function aimbot(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(target.Character.Head.Position)
        mousemoverel((headScreenPos.X - workspace.CurrentCamera.ViewportSize.X / 2), (headScreenPos.Y - workspace.CurrentCamera.ViewportSize.Y / 2))
    end
end

-- Actualizar el objetivo cada ciclo
local function onRenderStepped()
    if aimEnabled then
        local newTarget = getClosestPlayerInFOV() -- Encontrar el jugador más cercano dentro del FOV y radio de detección
        if newTarget and newTarget ~= closestTarget then
            closestTarget = newTarget
            totalTargetsDetected = totalTargetsDetected + 1
            trackingStartTime = tick()
            showNotification("Objetivo detectado: " .. closestTarget.Name)
            sound:Play()
        end
        if closestTarget then
            aimbot(closestTarget) -- Usar Aimbot para asegurar el impacto
            visibleLabel.Visible = true -- Mostrar el mensaje "Jugador visible"
            targetIndicator.Visible = true
            local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(closestTarget.Character.Head.Position)
            targetIndicator.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
            totalTrackingTime = totalTrackingTime + (tick() - trackingStartTime)
            trackingStartTime = tick()
        else
            visibleLabel.Visible = false -- Ocultar el mensaje si no hay objetivo visible
            targetIndicator.Visible = false
        end
    else
        visibleLabel.Visible = false -- Ocultar el mensaje si el aimbot no está habilitado
        targetIndicator.Visible = false
        if trackingStartTime > 0 then
            totalTrackingTime = totalTrackingTime + (tick() - trackingStartTime)
            trackingStartTime = 0
        end
    end
    -- Actualizar la posición del círculo FOV
    if fovCircle then
        fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    end
    updateStats()
end

-- Conectar la función de actualización al evento RenderStepped
table.insert(connections, game:GetService("RunService").RenderStepped:Connect(onRenderStepped))

-- Controles de teclas para activar el aimbot con clic derecho
table.insert(connections, game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Clic derecho para activar el aimbot
        aimEnabled = true
        fovCircle.Visible = true
    end
end))

table.insert(connections, game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Soltar clic derecho para desactivar el aimbot
        aimEnabled = false
        closestTarget = nil
        fovCircle.Visible = false
        visibleLabel.Visible = false -- Ocultar el mensaje cuando se desactiva el aimbot
        targetIndicator.Visible = false
    end
end))

-- Iniciar el círculo de FOV, el mensaje de visibilidad, el indicador de objetivo, el sistema de notificación y el sistema de estadísticas
createFOVCircle()
createVisibleLabel()
createTargetIndicator()
createNotificationLabel()
createAlertSound()

-- Manejar la reconexión del jugador y la muerte
local localPlayer = game.Players.LocalPlayer
local function onCharacterAdded(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        createFOVCircle()
        createVisibleLabel()
        createTargetIndicator()
        createNotificationLabel()
        createAlertSound()
    end)
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Función para desactivar el aimbot
local function disableAimbot()
    aimEnabled = false
    closestTarget = nil
    if fovCircle then fovCircle.Visible = false end
    if visibleLabel then visibleLabel.Visible = false end
    if targetIndicator then targetIndicator.Visible = false end
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
end

-- Exponer la función de desactivación globalmente para que pueda ser llamada desde fuera
_G.disableAimbot = disableAimbot