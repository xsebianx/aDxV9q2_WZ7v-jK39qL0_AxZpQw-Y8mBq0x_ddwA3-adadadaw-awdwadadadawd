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
local fovCircle, targetIndicator
local renderStepped
local positionHistory = {}
local currentTarget = nil
local targetLockTime = 0
local recentTargets = {}

-- Configuración visual
local visualSettings = {
    showFovCircle = true,
    showTargetIndicator = true,
    fovCircleThickness = 0.5,
    fovCircleTransparency = 0.5,
    indicatorType = "cross"  -- "circle" o "cross"
}

-- Función para crear elementos visuales
local function createVisuals()
    -- Limpiar elementos anteriores si existen
    if fovCircle then 
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
    if targetIndicator then 
        if type(targetIndicator) == "table" then
            for _, element in pairs(targetIndicator) do
                pcall(function() element:Remove() end)
            end
        elseif targetIndicator.Remove then
            pcall(function() targetIndicator:Remove() end)
        end
        targetIndicator = nil
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
    
    -- Indicador de objetivo (cruz en lugar de círculo)
    if visualSettings.showTargetIndicator then
        if visualSettings.indicatorType == "cross" then
            targetIndicator = {
                horizontal = Drawing.new("Line"),
                vertical = Drawing.new("Line")
            }
            
            targetIndicator.horizontal.Visible = false
            targetIndicator.horizontal.Thickness = 1
            targetIndicator.horizontal.Color = Color3.fromRGB(50, 255, 50)
            
            targetIndicator.vertical.Visible = false
            targetIndicator.vertical.Thickness = 1
            targetIndicator.vertical.Color = Color3.fromRGB(50, 255, 50)
        else
            targetIndicator = Drawing.new("Circle")
            targetIndicator.Visible = false
            targetIndicator.Thickness = 1
            targetIndicator.Radius = 4
            targetIndicator.Color = Color3.fromRGB(50, 255, 50)
            targetIndicator.Filled = false
        end
    end
end

-- Verificación de visibilidad (mejorada)
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
    return raycastResult == nil or raycastResult.Instance:IsDescendantOf(targetPart.Parent)
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
    
    local cameraDir = Camera.CFrame.LookVector
    local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
    local angle = math.acos(cameraDir:Dot(directionToTarget))
    
    return angle < math.rad(fieldOfView * 1.2) and isVisible(head) -- 20% de margen adicional
end

-- Sistema de prioridad de objetivos
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
    if distance < 50 then
        return 1
    end
    
    return 0
end

-- Encontrar objetivo más cercano (con estabilidad) - CORRECCIÓN APLICADA
local function findStableTarget()
    local bestTarget = nil
    local minAngle = math.rad(fieldOfView)
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
                local angle = math.acos(cameraDir:Dot(directionToTarget))
                local distance = (head.Position - Camera.CFrame.Position).Magnitude
                
                if angle < minAngle and isVisible(head) then
                    local score = (1 / distance) * 100 + getTargetPriority(player)
                    
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

-- Predicción de movimiento
local function predictPosition(target)
    if not target or not target.Character then return nil end
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    if not positionHistory[target] then positionHistory[target] = {} end
    
    table.insert(positionHistory[target], {
        position = head.Position,
        time = tick()
    })
    
    while #positionHistory[target] > 5 do
        table.remove(positionHistory[target], 1)
    end
    
    if #positionHistory[target] < 2 then
        return head.Position
    end
    
    local velocity = (positionHistory[target][#positionHistory[target]].position - 
                    positionHistory[target][1].position) / 
                    (positionHistory[target][#positionHistory[target]].time - 
                    positionHistory[target][1].time)
    
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

-- Actualizar indicador visual
local function updateTargetIndicator(target)
    if not targetIndicator or not visualSettings.showTargetIndicator then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local screenPos = Camera:WorldToViewportPoint(head.Position)
    if not screenPos then return end
    
    local pos = Vector2.new(screenPos.X, screenPos.Y)
    
    if visualSettings.indicatorType == "cross" then
        local size = 6
        
        targetIndicator.horizontal.Visible = true
        targetIndicator.horizontal.From = Vector2.new(pos.X - size, pos.Y)
        targetIndicator.horizontal.To = Vector2.new(pos.X + size, pos.Y)
        
        targetIndicator.vertical.Visible = true
        targetIndicator.vertical.From = Vector2.new(pos.X, pos.Y - size)
        targetIndicator.vertical.To = Vector2.new(pos.X, pos.Y + size)
    else
        targetIndicator.Visible = true
        targetIndicator.Position = pos
    end
end

-- Función principal del aimbot (mejorada)
local function aimbotLoop()
    if not safetyCheck() then
        if fovCircle then fovCircle.Visible = false end
        if targetIndicator then
            if visualSettings.indicatorType == "cross" then
                if targetIndicator.horizontal then
                    targetIndicator.horizontal.Visible = false
                end
                if targetIndicator.vertical then
                    targetIndicator.vertical.Visible = false
                end
            else
                targetIndicator.Visible = false
            end
        end
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
            updateTargetIndicator(closestTarget)
        else
            currentTarget = nil
            if targetIndicator then
                if visualSettings.indicatorType == "cross" then
                    if targetIndicator.horizontal then
                        targetIndicator.horizontal.Visible = false
                    end
                    if targetIndicator.vertical then
                        targetIndicator.vertical.Visible = false
                    end
                else
                    targetIndicator.Visible = false
                end
            end
        end
        
        if fovCircle and visualSettings.showFovCircle then
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        end
    else
        currentTarget = nil
        if fovCircle then fovCircle.Visible = false end
        if targetIndicator then
            if visualSettings.indicatorType == "cross" then
                if targetIndicator.horizontal then
                    targetIndicator.horizontal.Visible = false
                end
                if targetIndicator.vertical then
                    targetIndicator.vertical.Visible = false
                end
            else
                targetIndicator.Visible = false
            end
        end
    end
end

-- Sistema de limpieza (mejorado)
local function cleanUp()
    if fovCircle then 
        fovCircle:Remove()
        fovCircle = nil
    end
    
    if targetIndicator then 
        if visualSettings.indicatorType == "cross" then
            if targetIndicator.horizontal then
                targetIndicator.horizontal:Remove()
            end
            if targetIndicator.vertical then
                targetIndicator.vertical:Remove()
            end
        else
            if targetIndicator then
                targetIndicator:Remove()
            end
        end
        targetIndicator = nil
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
        fieldOfView = 30
        predictionFactor = 0.165
        targetLockDuration = 0.5
        smoothingFactor = 0.3
        
        -- Configuración visual predeterminada
        visualSettings = {
            showFovCircle = true,
            showTargetIndicator = true,
            fovCircleThickness = 0.5,
            fovCircleTransparency = 0.5,
            indicatorType = "cross"
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
            if options.visualSettings.indicatorType or options.visualSettings.showTargetIndicator then
                createVisuals()
            end
        end
    end
}
