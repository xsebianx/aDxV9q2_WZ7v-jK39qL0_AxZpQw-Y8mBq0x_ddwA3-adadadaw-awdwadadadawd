local aimEnabled = false
local fieldOfView = 30
local closestTarget = nil
local fovCircle, targetIndicator
local predictionFactor = 0.165
local lastTargetPosition = nil
local lastUpdateTime = tick()
local targetLockDuration = 0.5  -- Tiempo mínimo para mantener el objetivo
local lockStartTime = 0
local smoothingFactor = 0.3  -- Suavizado para el movimiento del mouse

-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Verificar si una función existe antes de llamarla
local function safeCall(func, ...)
    if func and type(func) == "function" then
        return func(...)
    end
    return nil
end

-- Crear elementos visuales básicos
local function createVisuals()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if targetIndicator then pcall(function() targetIndicator:Remove() end) end
    
    -- Círculo de FOV
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.7
    fovCircle.Radius = fieldOfView
    fovCircle.Color = Color3.fromRGB(255, 50, 50)
    fovCircle.Filled = false
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    -- Indicador de objetivo mejorado
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 8
    targetIndicator.Color = Color3.fromRGB(50, 255, 50)
    targetIndicator.Filled = false
end

-- Verificación de visibilidad MEJORADA con raycasting múltiple
local function isVisible(targetPart)
    if not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit * distance
    
    -- Lanzar múltiples rayos para mayor precisión
    local hitPoints = {
        targetPart.Position,
        targetPart.Position + Vector3.new(0, 1, 0),  -- Punto ligeramente arriba
        targetPart.Position + Vector3.new(0, -1, 0)  -- Punto ligeramente abajo
    }
    
    for _, point in ipairs(hitPoints) do
        local directionToPoint = (point - origin)
        local distanceToPoint = directionToPoint.Magnitude
        directionToPoint = directionToPoint.Unit * distanceToPoint
        
        local raycastResult = workspace:Raycast(origin, directionToPoint, raycastParams)
        
        if raycastResult then
            local hitPart = raycastResult.Instance
            if hitPart:IsDescendantOf(targetPart.Parent) then
                return true
            end
        end
    end
    
    return false
end

-- Encontrar objetivo más cercano con prioridad de visibilidad
local function findClosestTarget()
    local bestTarget = nil
    local minAngle = math.rad(fieldOfView)
    local shortestDistance = math.huge
    local cameraDir = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(cameraDir:Dot(directionToTarget))
                local distance = (head.Position - Camera.CFrame.Position).Magnitude
                
                -- Prioridad 1: Objetivo dentro del FOV y visible
                if angle < minAngle and distance < shortestDistance and isVisible(head) then
                    shortestDistance = distance
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget
end

-- Predicción mejorada con historial de posiciones
local positionHistory = {}
local function predictPosition(target)
    if not target or not target.Character then return nil end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Actualizar historial de posiciones
    if not positionHistory[target] then
        positionHistory[target] = {}
    end
    
    table.insert(positionHistory[target], {
        position = head.Position,
        time = tick()
    })
    
    -- Mantener solo los últimos 5 registros
    while #positionHistory[target] > 5 do
        table.remove(positionHistory[target], 1)
    end
    
    -- Calcular velocidad basada en el historial
    local velocity = Vector3.new(0, 0, 0)
    if #positionHistory[target] >= 2 then
        local firstEntry = positionHistory[target][1]
        local lastEntry = positionHistory[target][#positionHistory[target]]
        
        local timeDelta = lastEntry.time - firstEntry.time
        if timeDelta > 0 then
            velocity = (lastEntry.position - firstEntry.position) / timeDelta
        end
    end
    
    -- Predicción con suavizado
    return head.Position + velocity * predictionFactor
end

-- Seguimiento con protección contra nil y suavizado
local function preciseAim(target)
    if not target then return end
    
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    
    -- Calcular diferencia con suavizado
    local delta = targetPos - mousePos
    local distance = delta.Magnitude
    
    -- Aplicar suavizado exponencial
    local moveX = delta.X * smoothingFactor
    local moveY = delta.Y * smoothingFactor
    
    -- Mover el mouse solo si es necesario
    if math.abs(moveX) > 0.5 or math.abs(moveY) > 0.5 then
        safeCall(mousemoverel, moveX, moveY)
    end
end

-- Verificación de seguridad MEJORADA
local function safetyCheck()
    if not LocalPlayer then return false end
    if not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- No activar durante interacciones de UI
    if UserInputService:GetFocusedTextBox() then return false end
    
    return true
end

-- Sistema de bloqueo de objetivos
local function shouldKeepTarget(target)
    if not target then return false end
    
    -- Mantener el objetivo durante un tiempo mínimo
    if tick() - lockStartTime < targetLockDuration then
        return true
    end
    
    -- Verificar si el objetivo sigue siendo válido
    if not target.Character then return false end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Verificar si sigue dentro del FOV y visible
    local cameraDir = Camera.CFrame.LookVector
    local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
    local angle = math.acos(cameraDir:Dot(directionToTarget))
    
    return angle < math.rad(fieldOfView) and isVisible(head)
end

-- Conexión principal con manejo de errores
local renderStepped
renderStepped = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not safetyCheck() then
            if fovCircle then fovCircle.Visible = false end
            if targetIndicator then targetIndicator.Visible = false end
            closestTarget = nil
            lastTargetPosition = nil
            return
        end
        
        if aimEnabled then
            -- Mantener el objetivo actual si es válido
            if not shouldKeepTarget(closestTarget) then
                closestTarget = findClosestTarget()
                lockStartTime = tick()
            end
            
            if closestTarget then
                safeCall(preciseAim, closestTarget)
                if targetIndicator then
                    targetIndicator.Visible = true
                    local head = closestTarget.Character:FindFirstChild("Head")
                    if head then
                        local screenPos = Camera:WorldToViewportPoint(head.Position)
                        if screenPos then
                            targetIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
                        end
                    end
                end
            else
                if targetIndicator then targetIndicator.Visible = false end
            end
            
            if fovCircle then
                fovCircle.Visible = true
                fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                fovCircle.Radius = fieldOfView
            end
        else
            if fovCircle then fovCircle.Visible = false end
            if targetIndicator then targetIndicator.Visible = false end
            closestTarget = nil
        end
    end)
end)

-- Controles con protección
UserInputService.InputBegan:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton2 and safetyCheck() then
            aimEnabled = true
            closestTarget = findClosestTarget()
            lockStartTime = tick()
        end
    end)
end)

UserInputService.InputEnded:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimEnabled = false
            closestTarget = nil
        end
    end)
end)

-- Inicialización segura
pcall(createVisuals)

-- Sistema de limpieza optimizado
local function cleanUp()
    pcall(function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        if fovCircle then 
            fovCircle:Remove()
            fovCircle = nil
        end
        if targetIndicator then 
            targetIndicator:Remove()
            targetIndicator = nil
        end
    end)
end

-- Limpiar al cambiar de personaje
LocalPlayer.CharacterRemoving:Connect(cleanUp)
LocalPlayer.CharacterAdded:Connect(function()
    cleanUp()
    pcall(createVisuals)
end)

-- Limpiar al salir del juego
game:BindToClose(cleanUp)
