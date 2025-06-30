-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables avanzadas
local predictionFactor
local smoothingFactor
local fovCircle
local renderStepped
local positionHistory = {}
local currentTarget = nil
local targetLockTime = 0
local recentTargets = {}
local pingAdjustment = 0.15  -- Ajuste para compensar ping

-- Sistema de predicción mejorado (para larga distancia)
local function calculateAdvancedPrediction(target, distance)
    if not target or not target.Character then return nil end
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    if not positionHistory[target] then positionHistory[target] = {} end
    
    -- Registro histórico de movimientos
    table.insert(positionHistory[target], {
        position = head.Position,
        velocity = (head.AssemblyLinearVelocity * Vector3.new(1, 0, 1)),  -- Ignorar movimiento vertical
        time = tick()
    })
    
    -- Mantener solo datos relevantes
    while #positionHistory[target] > 5 do
        table.remove(positionHistory[target], 1)
    end
    
    -- Calcular velocidad promedio vectorial
    local avgVelocity = Vector3.new(0, 0, 0)
    for i = 2, #positionHistory[target] do
        avgVelocity = avgVelocity + positionHistory[target][i].velocity
    end
    avgVelocity = avgVelocity / (#positionHistory[target] - 1)
    
    -- Factor de predicción dinámico (mayor a larga distancia)
    local dynamicPrediction = predictionFactor * (1 + math.log(distance/100 + 1))
    
    -- Tiempo estimado de viaje (basado en velocidad de bala hipotética)
    local bulletSpeed = 5000  -- m/s (ajustar según juego)
    local timeToTarget = distance / bulletSpeed
    
    -- Predicción final con compensación de ping
    return head.Position + (avgVelocity * (dynamicPrediction + timeToTarget + pingAdjustment))
end

-- Sistema de selección de objetivos mejorado
local function findProfessionalTarget()
    local bestTarget = nil
    local bestScore = -math.huge
    local cameraPos = Camera.CFrame.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local distance = (head.Position - cameraPos).Magnitude
                
                -- Priorizar objetivos visibles y lejanos
                if isVisible(head) then
                    local score = (distance > 350) and 2.0 or 1.0  -- Bonus para objetivos lejanos
                    
                    -- Bonus adicional si el objetivo está moviéndose
                    if head.AssemblyLinearVelocity.Magnitude > 5 then
                        score = score * 1.5
                    end
                    
                    if score > bestScore then
                        bestScore = score
                        bestTarget = player
                    end
                end
            end
        end
    end
    
    return bestTarget
end

-- Seguimiento ultrasuave para precisión profesional
local function professionalAim(target)
    if not target then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    local predictedPosition = calculateAdvancedPrediction(target, distance)
    
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    local delta = targetPos - mousePos
    
    -- Suavizado adaptativo (más suave a larga distancia)
    local dynamicSmoothing = smoothingFactor
    if distance > 300 then
        dynamicSmoothing = smoothingFactor * (1 + distance/1000)
    end
    
    mousemoverel(
        delta.X * dynamicSmoothing,
        delta.Y * dynamicSmoothing
    )
end

-- Configuración profesional
return {
    activate = function()
        predictionFactor = 0.22  -- Más alto para larga distancia
        smoothingFactor = 0.15   -- Más preciso
        pingAdjustment = 0.18    -- Mayor compensación de ping
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(function()
                if not safetyCheck() then
                    currentTarget = nil
                    return
                end
                
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    currentTarget = findProfessionalTarget()
                    if currentTarget then
                        professionalAim(currentTarget)
                    end
                else
                    currentTarget = nil
                end
            end)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        positionHistory = {}
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
        if options.pingAdjustment then pingAdjustment = options.pingAdjustment end
    end
}
