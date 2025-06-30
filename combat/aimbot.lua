-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables (se reinician en cada activación)
local fieldOfView
local predictionFactor
local targetLockDuration
local smoothingFactor
local fovCircle
local renderStepped
local positionHistory = {}
local currentTarget = nil
local targetLockTime = 0
local recentTargets = {}

-- Configuración visual
local visualSettings = {
    showFovCircle = true,
    fovCircleThickness = 0.5,
    fovCircleTransparency = 0.5
}

-- Función para crear elementos visuales
local function createVisuals()
    -- Limpiar elementos anteriores si existen
    if fovCircle then 
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
    
    -- Círculo de FOV (más discreto)
    if visualSettings.showFovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = visualSettings.fovCircleThickness
        fovCircle.Transparency = visualSettings.fovCircleTransparency
        fovCircle.Radius = fieldOfView
        fovCircle.Color = Color3.fromRGB(255, 50, 50)
        fovCircle.Filled = false
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

-- Verificación de visibilidad (mejorada para larga distancia)
local function isVisible(targetPart)
    if not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    
    -- Verificar si el rayo golpeó al jugador objetivo
    if raycastResult then
        local hitPart = raycastResult.Instance
        while hitPart and hitPart ~= workspace do
            if hitPart:IsDescendantOf(targetPart.Parent) then
                return true
            end
            hitPart = hitPart.Parent
        end
    end
    
    return raycastResult == nil
end

-- Mantener objetivo (mejorado con tiempo mínimo de bloqueo)
local function shouldKeepTarget(target)
    if not target or not target.Character then return false end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Mantener el objetivo durante al menos el tiempo de bloqueo
    if tick() - targetLockTime < targetLockDuration then
        return true
    end
    
    -- Verificación de visibilidad mejorada
    return isVisible(head)
end

-- Sistema de prioridad de objetivos (mejorado para larga distancia)
local function getTargetPriority(target)
    if not target or not target.Character or not target.Character.Head then
        return -math.huge
    end
    
    -- Priorizar objetivos que ya hemos estado siguiendo
    if recentTargets[target] then
        return 2
    end
    
    -- Priorizar objetivos cercanos
    local distance = (target.Character.Head.Position - Camera.CFrame.Position).Magnitude
    return 1 / (distance + 0.001)  -- Evitar división por cero
end

-- Encontrar objetivo más cercano (con estabilidad) - CORRECCIÓN APLICADA
local function findStableTarget()
    local bestTarget = nil
    local bestScore = -math.huge
    local cameraDir = Camera.CFrame.LookVector
    
    -- Primero intentar mantener el objetivo actual si es válido
    if currentTarget and shouldKeepTarget(currentTarget) then
        return currentTarget
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(math.clamp(cameraDir:Dot(directionToTarget), -1, 1))
                
                -- Convertir ángulo a grados
                local angleDegrees = math.deg(angle)
                
                -- Solo considerar objetivos dentro del FOV
                if angleDegrees < fieldOfView and isVisible(head) then
                    local score = getTargetPriority(player)
                    
                    if score > bestScore then
                        bestScore = score
                        bestTarget = player
                    end
                end
            end
        end
    end
    
    -- Actualizar historial de objetivos
    if bestTarget then
        recentTargets[bestTarget] = tick()
        
        -- Limpiar objetivos antiguos
        for target, time in pairs(recentTargets) do
            if tick() - time > 5 then -- 5 segundos de retención
                recentTargets[target] = nil
            end
        end
    end
    
    return bestTarget
end

-- Predicción de movimiento (mejorada para larga distancia)
local function predictPosition(target)
    if not target or not target.Character then return nil end
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    if not positionHistory[target] then positionHistory[target] = {} end
    
    local currentTime = tick()
    table.insert(positionHistory[target], {
        position = head.Position,
        time = currentTime
    })
    
    -- Mantener solo los últimos 3 puntos para evitar sobreajuste
    while #positionHistory[target] > 3 do
        table.remove(positionHistory[target], 1)
    end
    
    if #positionHistory[target] < 2 then
        return head.Position
    end
    
    -- Calcular velocidad basada en los últimos 2 puntos
    local lastIndex = #positionHistory[target]
    local prevIndex = math.max(1, lastIndex - 1)
    
    local deltaPos = positionHistory[target][lastIndex].position - positionHistory[target][prevIndex].position
    local deltaTime = positionHistory[target][lastIndex].time - positionHistory[target][prevIndex].time
    
    if deltaTime <= 0 then
        return head.Position
    end
    
    local velocity = deltaPos / deltaTime
    return head.Position + velocity * predictionFactor
end

-- Seguimiento suavizado
local function preciseAim(target)
    if not target then return end
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    local delta = targetPos - mousePos
    
    mousemoverel(delta.X * smoothingFactor, delta.Y * smoothingFactor)
end

-- Verificación de seguridad
local function safetyCheck()
    if not LocalPlayer or not LocalPlayer.Character then return false end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0 and not UserInputService:GetFocusedTextBox()
end

-- Función principal del aimbot (mejorada)
local function aimbotLoop()
    if not safetyCheck() then
        if fovCircle then fovCircle.Visible = false end
        currentTarget = nil
        return
    end
    
    -- Solo activar cuando se presiona el botón derecho
    local aiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if aiming then
        local closestTarget = findStableTarget()
        
        if closestTarget then
            -- Actualizar objetivo actual y tiempo de bloqueo
            if currentTarget ~= closestTarget then
                currentTarget = closestTarget
                targetLockTime = tick()
            end
            
            preciseAim(closestTarget)
        else
            currentTarget = nil
        end
        
        if fovCircle and visualSettings.showFovCircle then
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        end
    else
        currentTarget = nil
        if fovCircle then fovCircle.Visible = false end
    end
end

-- Sistema de limpieza (mejorado)
local function cleanUp()
    if fovCircle then 
        fovCircle:Remove()
        fovCircle = nil
    end
    
    if renderStepped then
        renderStepped:Disconnect()
        renderStepped = nil
    end
    
    -- Limpiar historiales
    positionHistory = {}
    recentTargets = {}
    currentTarget = nil
end

-- Retorno para integración con el hub
return {
    activate = function()
        -- Reiniciar configuración en cada activación
        fieldOfView = 50  -- Aumentado para mejor detección a distancia
        predictionFactor = 0.165
        targetLockDuration = 0.5
        smoothingFactor = 0.3
        
        -- Configuración visual predeterminada
        visualSettings = {
            showFovCircle = true,
            fovCircleThickness = 0.5,
            fovCircleTransparency = 0.5
        }
        
        -- Solo crear conexión si no existe
        if not renderStepped then
            createVisuals()
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        cleanUp()
    end,
    
    configure = function(options)
        if options.fieldOfView then
            fieldOfView = options.fieldOfView
            if fovCircle then
                fovCircle.Radius = fieldOfView
            end
        end
        if options.smoothingFactor then
            smoothingFactor = options.smoothingFactor
        end
        if options.predictionFactor then
            predictionFactor = options.predictionFactor
        end
        if options.targetLockDuration then
            targetLockDuration = options.targetLockDuration
        end
        
        -- Configuración visual
        if options.visualSettings then
            for key, value in pairs(options.visualSettings) do
                if visualSettings[key] ~= nil then
                    visualSettings[key] = value
                end
            end
            
            -- Recrear elementos visuales si es necesario
            createVisuals()
        end
    end
}
