-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables de alta precisión
local predictionFactor
local smoothingFactor
local pingAdjustment
local hitboxPriority = {"Head", "HumanoidRootPart", "UpperTorso"}  -- Prioridad de hitboxes
local renderStepped
local positionHistory = {}
local currentTarget = nil
local recentTargets = {}
local targetLock = false

-- Fallback para mousemoverel (compatible con todos los exploits)
if not mousemoverel then
    mousemoverel = function(x, y)
        local mouse = LocalPlayer:GetMouse()
        pcall(function()
            mouse:MoveTo(mouse.X + x, mouse.Y + y)
        end)
    end
end

-- Verificación de visibilidad mejorada (ultra precisa)
local function isVisible(part)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if result then
        local hitPart = result.Instance
        while hitPart do
            if hitPart:IsDescendantOf(part.Parent) then
                return true
            end
            hitPart = hitPart.Parent
        end
    end
    
    return not result
end

-- Obtener el mejor hitbox disponible
local function getOptimalHitbox(target)
    if not target or not target.Character then return nil end
    
    -- Buscar hitboxes en orden de prioridad
    for _, hitboxName in ipairs(hitboxPriority) do
        local hitbox = target.Character:FindFirstChild(hitboxName)
        if hitbox and isVisible(hitbox) then
            return hitbox
        end
    end
    
    return nil
end

-- Sistema de predicción profesional (ultra preciso)
local function calculatePrecisionPrediction(target, hitbox, distance)
    if not target or not hitbox then return nil end
    
    -- Inicializar historial
    if not positionHistory[target] then positionHistory[target] = {} end
    
    -- Registrar posición, velocidad y aceleración
    local velocity = hitbox.AssemblyLinearVelocity
    local acceleration = Vector3.new(0, 0, 0)
    
    if #positionHistory[target] > 0 then
        local lastEntry = positionHistory[target][#positionHistory[target]]
        local deltaTime = tick() - lastEntry.time
        if deltaTime > 0 then
            acceleration = (velocity - lastEntry.velocity) / deltaTime
        end
    end
    
    table.insert(positionHistory[target], {
        position = hitbox.Position,
        velocity = velocity,
        acceleration = acceleration,
        time = tick()
    })
    
    -- Mantener solo los últimos 5 registros
    while #positionHistory[target] > 5 do
        table.remove(positionHistory[target], 1)
    end
    
    -- Calcular promedio ponderado
    local weightedVelocity = Vector3.new(0, 0, 0)
    local weightedAcceleration = Vector3.new(0, 0, 0)
    local totalWeight = 0
    
    for i = 1, #positionHistory[target] do
        local weight = 1.5 ^ i  -- Más peso a muestras recientes
        weightedVelocity = weightedVelocity + positionHistory[target][i].velocity * weight
        weightedAcceleration = weightedAcceleration + positionHistory[target][i].acceleration * weight
        totalWeight = totalWeight + weight
    end
    
    weightedVelocity = weightedVelocity / totalWeight
    weightedAcceleration = weightedAcceleration / totalWeight
    
    -- Factor de predicción dinámica
    local dynamicPrediction = predictionFactor * (1 + math.log(1 + distance/100))
    
    -- Compensación de ping
    local pingComp = pingAdjustment
    
    -- Tiempo de viaje balístico estimado
    local bulletSpeed = 1200  -- m/s (ajustar según juego)
    local travelTime = distance / bulletSpeed
    
    -- Predicción final con aceleración
    return hitbox.Position + 
           (weightedVelocity * (dynamicPrediction + pingComp + travelTime)) +
           (weightedAcceleration * (0.5 * (dynamicPrediction + pingComp + travelTime)^2))
end

-- Sistema de selección de objetivos de élite
local function findEliteTarget()
    local bestTarget = nil
    local bestHitbox = nil
    local bestScore = -math.huge
    local cameraPos = Camera.CFrame.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local hitbox = getOptimalHitbox(player)
            
            if humanoid and humanoid.Health > 0 and hitbox then
                local distance = (hitbox.Position - cameraPos).Magnitude
                
                -- Calcular puntaje basado en múltiples factores
                local score = 0
                
                -- Prioridad por distancia (más cerca = mejor)
                score = score + (1000 / distance)
                
                -- Prioridad por hitbox
                if hitbox.Name == "Head" then
                    score = score + 100
                elseif hitbox.Name == "HumanoidRootPart" then
                    score = score + 75
                else
                    score = score + 50
                end
                
                -- Prioridad por movimiento
                if hitbox.AssemblyLinearVelocity.Magnitude > 10 then
                    score = score + 30  -- Bonus para objetivos en movimiento
                end
                
                -- Prioridad por reincidencia
                if recentTargets[player] then
                    score = score + 40
                end
                
                -- Prioridad por ángulo
                local cameraDirection = Camera.CFrame.LookVector
                local directionToTarget = (hitbox.Position - cameraPos).Unit
                local angle = math.deg(math.acos(cameraDirection:Dot(directionToTarget)))
                score = score + (100 - angle)  -- Menor ángulo = mejor
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = player
                    bestHitbox = hitbox
                end
            end
        end
    end
    
    -- Actualizar historial reciente
    if bestTarget then
        recentTargets[bestTarget] = tick()
        
        -- Limpiar objetivos antiguos
        for target, time in pairs(recentTargets) do
            if tick() - time > 15 then
                recentTargets[target] = nil
            end
        end
    end
    
    return bestTarget, bestHitbox
end

-- Sistema de seguimiento de precisión extrema
local function precisionAim(target, hitbox)
    if not target or not hitbox then return end
    
    local distance = (hitbox.Position - Camera.CFrame.Position).Magnitude
    local predictedPosition = calculatePrecisionPrediction(target, hitbox, distance)
    
    if not predictedPosition then return end
    
    local success, screenPosition = pcall(function()
        return Camera:WorldToViewportPoint(predictedPosition)
    end)
    
    if not success then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPosition.X, screenPosition.Y)
    local delta = (targetPos - mousePos)
    
    -- Sistema de suavizado inteligente
    local dynamicSmoothing = smoothingFactor
    
    -- Ajustes basados en distancia
    if distance > 300 then
        -- Más suavizado para larga distancia
        dynamicSmoothing = smoothingFactor * (0.8 + distance/1000)
    else
        -- Más agresivo para corta distancia
        dynamicSmoothing = smoothingFactor * (0.7 - distance/2000)
    end
    
    -- Ajustes basados en velocidad del objetivo
    local targetSpeed = hitbox.AssemblyLinearVelocity.Magnitude
    if targetSpeed > 20 then
        dynamicSmoothing = dynamicSmoothing * (1 + targetSpeed/100)
    end
    
    -- Factor de corrección de error
    local errorCorrection = 1.0
    if targetLock then
        -- Reducir corrección cuando ya estamos bloqueados
        errorCorrection = 0.7
    end
    
    -- Movimiento final con micro-ajustes
    mousemoverel(
        delta.X * dynamicSmoothing * errorCorrection,
        delta.Y * dynamicSmoothing * errorCorrection
    )
    
    -- Actualizar estado de lock
    targetLock = true
end

-- Verificación de seguridad profesional
local function safetyCheck()
    if not LocalPlayer then return false end
    if not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    if UserInputService:GetFocusedTextBox() then return false end
    
    return true
end

-- Loop principal de precisión
local function aimbotLoop()
    local success, err = pcall(function()
        if not safetyCheck() then
            currentTarget = nil
            targetLock = false
            return
        end
        
        local aiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if aiming then
            local target, hitbox = findEliteTarget()
            
            if target and hitbox then
                if currentTarget ~= target then
                    currentTarget = target
                    targetLock = false
                end
                
                precisionAim(target, hitbox)
            else
                currentTarget = nil
                targetLock = false
            end
        else
            currentTarget = nil
            targetLock = false
        end
    end)
    
    if not success then
        warn("[PRECISION AIMBOT ERROR]", err)
        currentTarget = nil
        targetLock = false
    end
end

-- API de precisión para integración
return {
    activate = function()
        -- Configuración de élite para precisión extrema
        predictionFactor = 0.18   -- Base de predicción
        smoothingFactor = 0.06    -- Suavizado mínimo para precisión
        pingAdjustment = 0.12     -- Compensación de ping óptima
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        positionHistory = {}
        recentTargets = {}
        currentTarget = nil
        targetLock = false
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
        if options.pingAdjustment then pingAdjustment = options.pingAdjustment end
        if options.hitboxPriority then hitboxPriority = options.hitboxPriority end
    end
}
