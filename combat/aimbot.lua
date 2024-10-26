local aimEnabled = false -- El aimbot está desactivado por defecto
local fieldOfView = 30 -- Campo de visión ajustado a 30 grados para un equilibrio
local detectionRadius = 75 -- Radio de detección ampliado para mayor facilidad de uso
local closestTarget = nil
local fovCircle
local visibleLabel
local targetIndicator
local sound
local adjustPredictionEnabled = false
local predictionFactor = 0.118

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
    return target, closestDistance
end

-- Función para activar el aimbot al presionar el clic derecho
local function onRightClick()
    aimEnabled = true
    visibleLabel.Visible = true
    print("Aimbot Activado")
end

-- Función para desactivar el aimbot al soltar el clic derecho
local function onRightRelease()
    aimEnabled = false
    visibleLabel.Visible = false
    print("Aimbot Desactivado")
end

-- Función para alternar el ajuste de predicción
function toggleAdjustPrediction()
    adjustPredictionEnabled = not adjustPredictionEnabled
    if not adjustPredictionEnabled then
        predictionFactor = 0.118 -- Restablecer al valor predeterminado
    end
    print("Ajustar Predicción Activado: ", adjustPredictionEnabled)
    print("Factor de Predicción Actual: ", predictionFactor)
end

-- Función para ajustar el factor de predicción basado en la distancia
local function adjustPredictionFactor(distance)
    if adjustPredictionEnabled then
        if distance >= 1000 then
            predictionFactor = 0.200
        elseif distance >= 800 then
            predictionFactor = 0.180
        elseif distance >= 600 then
            predictionFactor = 0.160
        elseif distance >= 400 then
            predictionFactor = 0.140
        elseif distance >= 300 then
            predictionFactor = 0.130
        elseif distance >= 230 then
            predictionFactor = 0.120
        elseif distance >= 100 then
            predictionFactor = 0.115 -- Predeterminado si está por debajo de 100 metros
        else
            predictionFactor = 0.115 -- Predeterminado si está por debajo de 100 metros
        end
        print("Factor de Predicción Actual: ", predictionFactor)
    end
end

-- Función de Aimbot que apunta instantáneamente a la parte superior de la cabeza (HeadTop)
local function aimbot(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPartPosition = target.Character.HumanoidRootPart.Position
        local distance = (workspace.CurrentCamera.CFrame.Position - humanoidRootPartPosition).magnitude
        adjustPredictionFactor(distance) -- Ajustar el factor de predicción basado en la distancia

        -- Calcular la posición del objetivo con predicción
        local predictedPosition = humanoidRootPartPosition + (target.Character.HumanoidRootPart.Velocity * predictionFactor)

        -- Mover el mouse hacia la posición predicha
        local rootScreenPos = workspace.CurrentCamera:WorldToViewportPoint(predictedPosition)
        mousemoverel((rootScreenPos.X - workspace.CurrentCamera.ViewportSize.X / 2), (rootScreenPos.Y - workspace.CurrentCamera.ViewportSize.Y / 2))
    end
end

-- Actualizar el objetivo cada ciclo
game:GetService("RunService").RenderStepped:Connect(function()
    if aimEnabled then
        local newTarget, _ = getClosestPlayerInFOV() -- Encontrar el jugador más cercano dentro del FOV y radio de detección
        if newTarget then
            closestTarget = newTarget
            aimbot(closestTarget) -- Usar Aimbot para asegurar el impacto
            targetIndicator.Visible = true
            local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(closestTarget.Character.Head.Position + Vector3.new(0, closestTarget.Character.Head.Size.Y / 2, 0))
            targetIndicator.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
        else
            targetIndicator.Visible = false
        end
    else
        targetIndicator.Visible = false -- Ocultar el indicador si el aimbot no está habilitado
    end
end)

-- Crear los elementos de UI
createFOVCircle()
createVisibleLabel()
createTargetIndicator()
createAlertSound()

-- Conectar los eventos de clic derecho
game.Players.LocalPlayer:GetMouse().Button2Down:Connect(onRightClick)
game.Players.LocalPlayer:GetMouse().Button2Up:Connect(onRightRelease) -- Desactivar el aimbot al soltar el clic derecho