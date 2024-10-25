-- Configuración inicial
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local aimbotEnabled = false
local isAiming = false
local targetHead = nil
local predictionEnabled = false
local adjustPredictionEnabled = true -- Por defecto habilitado
local predictionFactor = 0.118 -- Ajustar este valor según la predicción deseada (más alto significa más predicción)
local headSizeMultiplier = 5 -- Multiplicador para el tamaño de la cabeza
local transparencyValue = 0.3 -- Transparencia para la cabeza

-- Función para activar el aimbot
function enableAimbot()
    aimbotEnabled = true
    print("Aimbot activado")
end

-- Función para desactivar el aimbot
function disableAimbot()
    aimbotEnabled = false
    isAiming = false
    targetHead = nil
    print("Aimbot desactivado")
end

-- Asignar las funciones a las variables globales
_G.enableAimbot = enableAimbot
_G.disableAimbot = disableAimbot

-- Función para alternar la predicción
function togglePrediction()
    predictionEnabled = not predictionEnabled
    print("Predicción Activada: ", predictionEnabled)
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
        if distance >= 400 then
            predictionFactor = 0.200
        elseif distance >= 300 then
            predictionFactor = 0.180
        elseif distance >= 230 then
            predictionFactor = 0.160
        elseif distance >= 100 then
            predictionFactor = 0.140
        else
            predictionFactor = 0.115 -- Predeterminado si está por debajo de 100 metros
        end
        print("Factor de Predicción Actual: ", predictionFactor)
    end
end

-- Función para predecir la posición futura basado en la velocidad
local function predictTargetPosition(target)
    if not predictionEnabled then
        return target.Position
    end

    local targetCharacter = target.Parent
    local humanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.AssemblyLinearVelocity
        local currentPosition = target.Position
        
        -- Calcular la distancia
        local distance = (currentPosition - workspace.CurrentCamera.CFrame.Position).magnitude
        adjustPredictionFactor(distance)

        -- Calcular la posición predicha
        local predictedPosition = currentPosition + velocity * predictionFactor
        return predictedPosition
    end
    return target.Position
end

-- Función para actualizar el aimbot
function updateAimbot()
    if aimbotEnabled and isAiming then
        local target = mouse.Target
        if target and target.Parent then
            local npcModel = target.Parent
            if npcModel:FindFirstChild("Humanoid") and npcModel:FindFirstChild("Head") then
                targetHead = npcModel.Head
            end
        end

        if targetHead then
            local targetPosition = predictTargetPosition(targetHead)
            -- Apuntar suavemente a la posición de la cabeza predicha
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetPosition)
        end
    end
end

-- Manejo de entrada para el botón derecho del mouse
mouse.Button2Down:Connect(function()
    if aimbotEnabled then
        isAiming = true
    end
end)

mouse.Button2Up:Connect(function()
    isAiming = false
    targetHead = nil
end)

-- Conexión del Heartbeat para actualizar el aimbot
game:GetService("RunService").Heartbeat:Connect(updateAimbot)

-- Para activar el aimbot al inicio (puedes comentar esto si no lo deseas)
enableAimbot()