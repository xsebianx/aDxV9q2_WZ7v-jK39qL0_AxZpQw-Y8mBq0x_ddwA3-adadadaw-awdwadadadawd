local aimEnabled = false
local fieldOfView = 30
local closestTarget = nil
local fovCircle, targetIndicator
local predictionFactor = 0.165
local lastTargetPosition = nil
local lastUpdateTime = tick()

-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 1. VERIFICACIÓN DE FUNCIONES CRÍTICAS
local function isFunctionValid(fn)
    return type(fn) == "function"
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
    
    -- Indicador de objetivo simple
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 6
    targetIndicator.Color = Color3.fromRGB(50, 255, 50)
    targetIndicator.Filled = true
end

-- Verificación de visibilidad MEJORADA
local function isVisible(targetPart)
    if not targetPart then return false end
    
    -- 2. VERIFICACIÓN DE RAYCASTPARAMS
    if not isFunctionValid(RaycastParams.new) then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit * distance
    
    -- 3. VERIFICACIÓN DE WORKSPACE RAYCAST
    if not isFunctionValid(workspace.Raycast) then return false end
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    return raycastResult == nil or (raycastResult.Instance and raycastResult.Instance:IsDescendantOf(targetPart.Parent))
end

-- Encontrar objetivo más cercano con seguimiento continuo
local function findClosestTarget()
    local closestPlayer = nil
    local minAngle = math.rad(fieldOfView)
    local shortestDistance = math.huge
    local cameraDir = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        -- 4. VERIFICACIÓN DE JUGADOR VÁLIDO
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(cameraDir:Dot(directionToTarget))
                local distance = (head.Position - Camera.CFrame.Position).Magnitude
                
                if angle < minAngle and distance < shortestDistance and isVisible(head) then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- Predicción mejorada con seguridad
local function predictPosition(target)
    if not target or not target.Character then return nil end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Calcular velocidad REAL con verificación de tiempo
    local currentPosition = head.Position
    local velocity = head.Velocity
    
    if lastTargetPosition and lastUpdateTime then
        local deltaTime = tick() - lastUpdateTime
        if deltaTime > 0 then
            -- Combinar velocidad actual con desplazamiento reciente
            local actualMovement = (currentPosition - lastTargetPosition)
            velocity = (velocity + actualMovement/deltaTime) * 0.5
        end
    end
    
    lastTargetPosition = currentPosition
    lastUpdateTime = tick()
    
    -- Aumentar predicción en movimiento lateral
    local rightVector = Camera.CFrame.RightVector
    local lateralMovement = velocity:Dot(rightVector) * rightVector
    local lateralPrediction = lateralMovement * (predictionFactor + 0.05)
    
    return head.Position + velocity * predictionFactor + lateralPrediction
end

-- Seguimiento con protección contra nil
local function preciseAim(target)
    if not target then return end
    
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    
    -- Corrección adicional para movimiento rápido
    local delta = targetPos - mousePos
    local distance = delta.Magnitude
    
    -- Factor dinámico basado en velocidad
    local dynamicFactor = math.clamp(0.15 + (distance/500), 0.1, 0.3)
    
    -- 5. VERIFICACIÓN CRÍTICA DE MOUSEMOVEREL
    if mousemoverel and type(mousemoverel) == "function" then
        -- Aplicar con compensación lateral extra
        mousemoverel(delta.X * (dynamicFactor + 0.05), delta.Y * dynamicFactor)
    else
        -- Sistema alternativo si mousemoverel no está disponible
        warn("mousemoverel no está disponible - usando método alternativo")
        UserInputService.MouseDelta = Vector3.new(delta.X * 0.5, delta.Y * 0.5, 0)
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

-- Conexión principal con manejo de errores
local renderStepped = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not safetyCheck() then
            if fovCircle then fovCircle.Visible = false end
            if targetIndicator then targetIndicator.Visible = false end
            lastTargetPosition = nil
            return
        end
        
        if aimEnabled then
            closestTarget = findClosestTarget()
            
            if closestTarget then
                preciseAim(closestTarget)
                if targetIndicator then
                    targetIndicator.Visible = true
                    local head = closestTarget.Character:FindFirstChild("Head")
                    if head then
                        local screenPos = Camera:WorldToViewportPoint(head.Position)
                        targetIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
                    end
                end
            else
                if targetIndicator then targetIndicator.Visible = false end
                lastTargetPosition = nil
            end
            
            if fovCircle then
                fovCircle.Visible = true
                fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            end
        else
            if fovCircle then fovCircle.Visible = false end
            if targetIndicator then targetIndicator.Visible = false end
            lastTargetPosition = nil
        end
    end)
end)

-- Controles con protección
UserInputService.InputBegan:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton2 and safetyCheck() then
            aimEnabled = true
            lastTargetPosition = nil
        end
    end)
end)

UserInputService.InputEnded:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimEnabled = false
            closestTarget = nil
            lastTargetPosition = nil
        end
    end)
end)

-- Inicialización segura
pcall(createVisuals)

-- Limpieza con protección
game:BindToClose(function()
    pcall(function()
        renderStepped:Disconnect()
        if fovCircle then fovCircle:Remove() end
        if targetIndicator then targetIndicator:Remove() end
    end)
end)
