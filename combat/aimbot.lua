-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables avanzadas
local predictionFactor
local smoothingFactor
local pingAdjustment
local renderStepped
local positionHistory = {}
local currentTarget = nil
local targetLockTime = 0
local recentTargets = {}

-- Fallback para mousemoverel
if not mousemoverel then
    mousemoverel = function(x, y)
        local mouse = LocalPlayer:GetMouse()
        local pos = Vector2.new(mouse.X + x, mouse.Y + y)
        pcall(function()
            mouse:MoveTo(pos.X, pos.Y)
        end)
    end
end

-- Verificación de visibilidad mejorada
local function isVisible(part)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction * 1000, raycastParams)
    
    if result then
        local hitPart = result.Instance
        while hitPart and hitPart ~= workspace do
            if hitPart:IsDescendantOf(part.Parent) then
                return true
            end
            hitPart = hitPart.Parent
        end
    end
    
    return not result
end

-- Sistema de predicción profesional para larga distancia
local function calculateAdvancedPrediction(target, distance)
    if not target or not target.Character then return nil end
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Inicializar historial
    if not positionHistory[target] then positionHistory[target] = {} end
    
    -- Registrar posición y velocidad actual
    table.insert(positionHistory[target], {
        position = head.Position,
        velocity = head.AssemblyLinearVelocity,
        time = tick()
    })
    
    -- Mantener solo los últimos 5 registros
    while #positionHistory[target] > 5 do
        table.remove(positionHistory[target], 1)
    end
    
    -- Calcular velocidad promedio
    local avgVelocity = Vector3.new(0, 0, 0)
    local validSamples = 0
    
    for i = 2, #positionHistory[target] do
        local sample = positionHistory[target][i]
        if sample.velocity.Magnitude > 0 then
            avgVelocity = avgVelocity + sample.velocity
            validSamples = validSamples + 1
        end
    end
    
    if validSamples == 0 then
        return head.Position
    end
    
    avgVelocity = avgVelocity / validSamples
    
    -- Factor dinámico basado en distancia
    local dynamicFactor = predictionFactor * (1 + distance / 500)
    
    -- Compensación de ping
    local pingComp = pingAdjustment
    
    -- Predicción final
    return head.Position + (avgVelocity * dynamicFactor) + (avgVelocity * pingComp)
end

-- Sistema profesional de selección de objetivos
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
                local isTargetVisible = isVisible(head)
                
                if isTargetVisible then
                    -- Priorizar objetivos a larga distancia
                    local score = distance > 350 and 2.0 or 1.0
                    
                    -- Bonus por movimiento rápido
                    if head.AssemblyLinearVelocity.Magnitude > 10 then
                        score = score * 1.5
                    end
                    
                    -- Bonus por ser objetivo reciente
                    if recentTargets[player] then
                        score = score * 1.2
                    end
                    
                    if score > bestScore then
                        bestScore = score
                        bestTarget = player
                    end
                end
            end
        end
    end
    
    -- Actualizar historial reciente
    if bestTarget then
        recentTargets[bestTarget] = tick()
        
        -- Limpiar objetivos antiguos
        for target, time in pairs(recentTargets) do
            if tick() - time > 10 then
                recentTargets[target] = nil
            end
        end
    end
    
    return bestTarget
end

-- Seguimiento ultrasuave para precisión profesional
local function professionalAim(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    local predictedPosition = calculateAdvancedPrediction(target, distance)
    
    if not predictedPosition then return end
    
    local success, targetScreenPos, onScreen = pcall(function()
        return Camera:WorldToViewportPoint(predictedPosition)
    end)
    
    if not success or not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    local delta = targetPos - mousePos
    
    -- Suavizado adaptativo para larga distancia
    local dynamicSmoothing = smoothingFactor
    if distance > 300 then
        dynamicSmoothing = smoothingFactor * (0.8 + distance/800)
    end
    
    mousemoverel(
        delta.X * dynamicSmoothing,
        delta.Y * dynamicSmoothing
    )
end

-- Verificación de seguridad reforzada
local function safetyCheck()
    if not LocalPlayer or not LocalPlayer.Character then 
        return false 
    end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    if UserInputService:GetFocusedTextBox() then
        return false
    end
    
    return true
end

-- Función principal del aimbot con gestión de errores
local function aimbotLoop()
    local success, err = pcall(function()
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
    
    if not success then
        warn("[AIMBOT ERROR]", err)
    end
end

-- API para integración con el hub
return {
    activate = function()
        -- Configuración profesional para Visera EXFIL
        predictionFactor = 0.24   -- Aumentado para larga distancia
        smoothingFactor = 0.12    -- Precisión profesional
        pingAdjustment = 0.18     -- Compensación de ping
        
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
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
        if options.pingAdjustment then pingAdjustment = options.pingAdjustment end
    end
}
