-- aimbot.txtxxx
-- ADVERTENCIA: Este es un script de trampa. Usarlo puede resultar en un baneo permanente.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de programación en Lua.

-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Variables optimizadas
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local predictionFactor = 0.15
local minTargetDistance = 5
local maxFOV = 90 -- Grados (ajustable)
local smoothingFactor = 0.3 -- Suavizado del movimiento (0=insta, 1=muy lento)
local humanizationEnabled = true -- Para hacer el movimiento más humano
local renderStepped
local keybindConnection
local headOffset = Vector3.new(0, 0.2, 0)
local lastDelta = Vector2.new(0, 0)

-- Sistema de caché para optimización
local playerCache = {}
local cacheTimeout = 0.5 -- segundos

-- Sistema de notificación visual mejorado
local notificationGui = nil
local notificationFrame = nil
local notificationLabel = nil
local notificationIcon = nil
local notificationStroke = nil

-- GUI de Configuración
local configGui = nil
local configFrame = nil

-- Crear notificación elegante
local function createNotification()
    if notificationGui then return end
    
    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "AimbotNotification"
    notificationGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    notificationFrame.BackgroundTransparency = 0.7
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Size = UDim2.new(0, 220, 0, 30)
    notificationFrame.Position = UDim2.new(0.5, -110, 0.02, 0)
    notificationFrame.Visible = false
    notificationFrame.Parent = notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    notificationStroke = Instance.new("UIStroke")
    notificationStroke.Color = Color3.new(0, 1, 0)
    notificationStroke.Thickness = 1
    notificationStroke.Parent = notificationFrame
    
    notificationIcon = Instance.new("ImageLabel")
    notificationIcon.Name = "Icon"
    notificationIcon.Image = "rbxassetid://3926307971"
    notificationIcon.ImageRectOffset = Vector2.new(324, 364)
    notificationIcon.ImageRectSize = Vector2.new(36, 36)
    notificationIcon.Size = UDim2.new(0, 20, 0, 20)
    notificationIcon.Position = UDim2.new(0, 5, 0.5, -10)
    notificationIcon.BackgroundTransparency = 1
    notificationIcon.ImageColor3 = Color3.new(0, 1, 0)
    notificationIcon.Parent = notificationFrame
    
    notificationLabel = Instance.new("TextLabel")
    notificationLabel.Name = "Label"
    notificationLabel.Text = "OBJETIVO VISIBLE"
    notificationLabel.TextColor3 = Color3.new(1, 1, 1)
    notificationLabel.Font = Enum.Font.GothamMedium
    notificationLabel.TextSize = 14
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.Size = UDim2.new(0, 160, 1, 0)
    notificationLabel.Position = UDim2.new(0, 30, 0, 0)
    notificationLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationLabel.Parent = notificationFrame
end

-- Actualizar notificación con estado: "visible", "oculto", o nil (ocultar)
local function updateNotification(state)
    if not notificationFrame then return end
    
    if state == nil then
        notificationFrame.Visible = false
        return
    end
    
    notificationFrame.Visible = true
    
    if state == "visible" then
        notificationLabel.Text = "OBJETIVO VISIBLE"
        notificationIcon.ImageColor3 = Color3.new(0, 1, 0)
        notificationStroke.Color = Color3.new(0, 1, 0)
    elseif state == "oculto" then
        notificationLabel.Text = "OBJETIVO OCULTO"
        notificationIcon.ImageColor3 = Color3.new(1, 0.5, 0) -- Naranja para oculto
        notificationStroke.Color = Color3.new(1, 0.5, 0)
    end
end

-- Verificación profesional de visibilidad con detección de obstáculos
local function isTargetVisible(character)
    if not character then return false end
    
    local origin = Camera.CFrame.Position
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    local headPosition = head.Position + Vector3.new(0, -0.1, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local pointsToCheck = {
        headPosition,
        headPosition + Vector3.new(0, -1.5, 0),
        headPosition + Vector3.new(0, -3, 0)
    }
    
    local visiblePoints = 0
    
    for _, point in ipairs(pointsToCheck) do
        local direction = (point - origin).Unit
        local distance = (point - origin).Magnitude
        local result = Workspace:Raycast(origin, direction * distance, raycastParams)
        
        if not result then
            visiblePoints = visiblePoints + 1
        else
            local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
            if hitCharacter == character then
                visiblePoints = visiblePoints + 1
            else
                local hitPart = result.Instance
                local material = hitPart.Material
                local transparency = hitPart.Transparency
                
                local transparentMaterials = {
                    Enum.Material.Glass, Enum.Material.ForceField,
                    Enum.Material.Neon, Enum.Material.Plastic,
                    Enum.Material.Air, Enum.Material.Water
                }
                
                local isTransparent = false
                for _, mat in ipairs(transparentMaterials) do
                    if material == mat then isTransparent = true; break end
                end
                
                if isTransparent or transparency > 0.7 or not hitPart.CanCollide then
                    visiblePoints = visiblePoints + 1
                end
            end
        end
    end
    
    return visiblePoints >= 2
end

-- Sistema de predicción de segundo orden (mejorado)
local function advancedPrediction(target)
    if not target or target == LocalPlayer then return nil end
    local character = target.Character
    if not character then return nil end
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    if distance < minTargetDistance then return nil end
    
    if not target.PositionHistory then target.PositionHistory = {} end
    
    table.insert(target.PositionHistory, {position = head.Position, time = tick()})
    if #target.PositionHistory > 5 then table.remove(target.PositionHistory, 1) end
    
    if #target.PositionHistory >= 2 then
        local newest = target.PositionHistory[#target.PositionHistory]
        local oldest = target.PositionHistory[#target.PositionHistory - 1]
        local timeDiff = newest.time - oldest.time
        local velocity = (newest.position - oldest.position) / timeDiff
        
        if #target.PositionHistory >= 3 then
            local mid = target.PositionHistory[#target.PositionHistory - 1]
            local oldest = target.PositionHistory[#target.PositionHistory - 2]
            local oldVelocity = (mid.position - oldest.position) / (mid.time - oldest.time)
            local acceleration = (velocity - oldVelocity) / timeDiff
            
            return head.Position + (velocity * predictionFactor) + (0.5 * acceleration * predictionFactor^2) + headOffset
        else
            return head.Position + (velocity * predictionFactor) + headOffset
        end
    end
    
    return head.Position + headOffset
end

-- Sistema de cálculo de amenaza (simplificado)
local function calculateThreatLevel(player)
    local character = player.Character
    if not character then return 0 end
    
    local head = character:FindFirstChild("Head")
    if not head then return 0 end
    
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    
    -- Factor distancia (más cerca = más amenaza)
    local threatLevel = math.max(0, 100 - distance)
    
    -- Factor si me está apuntando (cálculo simple con producto escalar)
    local lookVector = character.HumanoidRootPart.CFrame.LookVector
    local toPlayerVector = (LocalPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Unit
    local dotProduct = lookVector:Dot(toPlayerVector)
    
    if dotProduct > 0.8 then -- Si está mirando aproximadamente hacia mí
        threatLevel = threatLevel + 30
    end
    
    return math.min(100, threatLevel)
end

-- Sistema de suavizado de movimiento
local function smoothAim(targetScreenPos)
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (targetScreenPos - mousePos)
    local smoothedDelta = lastDelta:lerp(delta, smoothingFactor)
    lastDelta = smoothedDelta
    mousemoverel(smoothedDelta.X, smoothedDelta.Y)
end

-- Sistema de humanización para evadir anti-cheats
local function humanizeAim(targetScreenPos)
    if not humanizationEnabled then
        smoothAim(targetScreenPos)
        return
    end
    
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (targetScreenPos - mousePos)
    
    -- Añadir jitter aleatorio
    local jitter = Vector2.new(math.random(-50, 50) / 100, math.random(-50, 50) / 100)
    delta = delta + jitter
    
    -- Añadir retraso variable
    local delay = math.random(5, 15) / 1000
    task.wait(delay)
    
    smoothAim(targetScreenPos)
end

-- === FUNCIÓNES DE CACHÉ (CORRECCIÓN APLICADA AQUÍ) ===
-- Funciones de caché
local function isCacheValid(player)
    local cached = playerCache[player.UserId]
    return cached and (tick() - cached.timestamp) < cacheTimeout
end

local function updateCache(player, position)
    if position then
        playerCache[player.UserId] = {position = position, timestamp = tick()}
    end
end

-- Sistema de seguimiento mejorado con FOV y puntuación
local function precisionAim()
    local bestTarget = nil
    local bestHeadPos = nil
    local bestScore = math.huge
    
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local maxRadius = math.tan(math.rad(maxFOV / 2)) * viewportSize.Y / 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        -- Usar caché
        local headPos
        if isCacheValid(player) then
            headPos = playerCache[player.UserId].position
        else
            headPos = advancedPrediction(player)
            updateCache(player, headPos)
        end
        
        if not headPos then continue end
        
        local screenPos = Camera:WorldToViewportPoint(headPos)
        if screenPos.Z < 0 then continue end
        
        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local distanceFromCenter = (screenPoint - center).Magnitude
        if distanceFromCenter > maxRadius then continue end
        
        local mousePos = UserInputService:GetMouseLocation()
        local screenDistance = (screenPoint - mousePos).Magnitude
        
        -- Calcular puntuación: combina distancia y amenaza
        local threat = calculateThreatLevel(player)
        local score = screenDistance * (1 - threat / 200) -- La amenaza reduce la puntuación
        
        if score < bestScore then
            bestScore = score
            bestTarget = player
            bestHeadPos = headPos
        end
    end
    
    -- Verificar visibilidad y actualizar notificación
    local visibilityState = nil
    if bestTarget and bestTarget.Character then
        if isTargetVisible(bestTarget.Character) then
            visibilityState = "visible"
        else
            visibilityState = "oculto"
        end
    end
    updateNotification(visibilityState)
    
    if bestTarget and bestHeadPos and visibilityState == "visible" then
        local screenPos = Camera:WorldToViewportPoint(bestHeadPos)
        local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
        humanizeAim(targetScreenPos)
    end
end

-- Loop principal
local function stableLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        precisionAim()
    else
        updateNotification(nil)
    end
end

-- Crear GUI de Configuración
local function createConfigGui()
    if configGui then
        configGui.Enabled = not configGui.Enabled
        return
    end

    configGui = Instance.new("ScreenGui")
    configGui.Name = "AimbotConfig"
    configGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    configGui.ResetOnSpawn = false
    configGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    configFrame = Instance.new("Frame")
    configFrame.Size = UDim2.new(0, 300, 0, 420)
    configFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
    configFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = configGui
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "CONFIGURACIÓN AIMBOT"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = configFrame

    local function createSlider(option, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, yPos)
        label.Text = option.name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = configFrame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 50, 0, 20)
        valueLabel.Position = UDim2.new(1, -60, 0, yPos)
        valueLabel.Text = tostring(option.value)
        valueLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextSize = 14
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = configFrame

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -20, 0, 4)
        slider.Position = UDim2.new(0, 10, 0, yPos + 25)
        slider.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        slider.BorderSizePixel = 0
        slider.Parent = configFrame
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 2)

        local sliderButton = Instance.new("TextButton")
        sliderButton.Size = UDim2.new(0, 16, 0, 16)
        sliderButton.BackgroundColor3 = Color3.new(0, 1, 0)
        sliderButton.BorderSizePixel = 0
        sliderButton.Parent = slider
        Instance.new("UICorner", sliderButton).CornerRadius = UDim.new(0, 8)
        
        local percentage = (option.value - option.min) / (option.max - option.min)
        sliderButton.Position = UDim2.new(percentage, -8, 0, -6)

        local dragging = false
        local function updateSlider(input)
            local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            sliderButton.Position = UDim2.new(relativeX, -8, 0, -6)
            local value = option.min + (option.max - option.min) * relativeX
            valueLabel.Text = string.format("%.2f", value)
            _G[option.id] = value
        end

        sliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end
    
    local options = {
        {name = "Factor de Predicción", value = predictionFactor, min = 0, max = 0.5, id = "predictionFactor"},
        {name = "FOV Máximo", value = maxFOV, min = 30, max = 180, id = "maxFOV"},
        {name = "Distancia Mínima", value = minTargetDistance, min = 0, max = 100, id = "minTargetDistance"},
        {name = "Factor de Suavizado", value = smoothingFactor, min = 0.05, max = 1, id = "smoothingFactor"},
    }

    for i, option in ipairs(options) do
        createSlider(option, 60 + (i-1) * 80)
    end
    
    -- Botón de humanización
    local humanizeButton = Instance.new("TextButton")
    humanizeButton.Size = UDim2.new(1, -20, 0, 30)
    humanizeButton.Position = UDim2.new(0, 10, 0, 380)
    humanizeButton.Text = "Humanización: " .. (humanizationEnabled and "ON" or "OFF")
    humanizeButton.TextColor3 = Color3.new(1, 1, 1)
    humanizeButton.Font = Enum.Font.Gotham
    humanizeButton.TextSize = 14
    humanizeButton.BackgroundColor3 = humanizationEnabled and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
    humanizeButton.BorderSizePixel = 0
    humanizeButton.Parent = configFrame
    Instance.new("UICorner", humanizeButton).CornerRadius = UDim.new(0, 5)

    humanizeButton.MouseButton1Click:Connect(function()
        humanizationEnabled = not humanizationEnabled
        humanizeButton.Text = "Humanización: " .. (humanizationEnabled and "ON" or "OFF")
        humanizeButton.BackgroundColor3 = humanizationEnabled and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
    end)
end

-- API para el hub
return {
    activate = function()
        createNotification()
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(stableLoop)
        end
        if not keybindConnection then
            keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
                    createConfigGui()
                end
            end)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        if keybindConnection then
            keybindConnection:Disconnect()
            keybindConnection = nil
        end
        if notificationGui then
            notificationGui:Destroy()
            notificationGui = nil
        end
        if configGui then
            configGui:Destroy()
            configGui = nil
        end
        playerCache = {}
    end,
    
    configure = function(options)
        -- La configuración ahora se maneja a través de la GUI (tecla F2)
        -- pero esta función se mantiene para compatibilidad.
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.headOffset then headOffset = options.headOffset end
        if options.minTargetDistance then minTargetDistance = options.minTargetDistance end
        if options.maxFOV then maxFOV = options.maxFOV end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
    end
}
