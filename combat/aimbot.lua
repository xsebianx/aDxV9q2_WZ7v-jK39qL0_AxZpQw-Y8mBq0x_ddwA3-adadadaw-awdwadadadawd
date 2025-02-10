local aimEnabled = false -- El aimbot está desactivado por defecto y se activa con clic derecho
local fieldOfView = 30 -- Campo de visión ajustado a 30 grados para un equilibrio
local detectionRadius = 75 -- Radio de detección ampliado para mayor facilidad de uso
local closestTarget = nil
local fovCircle
local targetIndicator
local predictionFactor = 0.165 -- Factor de predicción ajustado para mayor precisión

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

-- Crear un indicador visual para el objetivo
local function createTargetIndicator()
    if targetIndicator then targetIndicator:Remove() end
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 5
    targetIndicator.Color = Color3.fromRGB(0, 255, 0)
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

-- Función para predecir la posición del objetivo
local function predictPosition(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local head = target.Character.Head
        local velocity = head.Velocity
        local predictedPosition = head.Position + (velocity * predictionFactor)
        return predictedPosition
    end
    return nil
end

-- Función de Aimbot que apunta instantáneamente a la cabeza con predicción de movimiento
local function aimbot(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local predictedPosition = predictPosition(target)
        if predictedPosition then
            local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(predictedPosition)
            local mousePos = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
            local targetPos = Vector2.new(headScreenPos.X, headScreenPos.Y)
            mousemoverel(targetPos.X - mousePos.X, targetPos.Y - mousePos.Y)
        end
    end
end

-- Actualizar el objetivo cada ciclo
game:GetService("RunService").RenderStepped:Connect(function()
    if aimEnabled then
        local newTarget = getClosestPlayerInFOV() -- Encontrar el jugador más cercano dentro del FOV y radio de detección
        if newTarget and newTarget ~= closestTarget then
            closestTarget = newTarget
        end
        if closestTarget then
            aimbot(closestTarget) -- Usar Aimbot para asegurar el impacto
            targetIndicator.Visible = true
            local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(closestTarget.Character.Head.Position)
            targetIndicator.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
        else
            targetIndicator.Visible = false
        end
    else
        targetIndicator.Visible = false
    end
    -- Actualizar la posición del círculo FOV
    if fovCircle then
        fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    end
end)

-- Controles de teclas para activar el aimbot con clic derecho
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Clic derecho para activar el aimbot
        aimEnabled = true
        fovCircle.Visible = true
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Soltar clic derecho para desactivar el aimbot
        aimEnabled = false
        closestTarget = nil
        fovCircle.Visible = false
        targetIndicator.Visible = false
    end
end)

-- Iniciar el círculo de FOV y el indicador de objetivo
createFOVCircle()
createTargetIndicator()

-- Manejar la reconexión del jugador y la muerte
local localPlayer = game.Players.LocalPlayer
local function onCharacterAdded(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        createFOVCircle()
        createTargetIndicator()
    end)
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
