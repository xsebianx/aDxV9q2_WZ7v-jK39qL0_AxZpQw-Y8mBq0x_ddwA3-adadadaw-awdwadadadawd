-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Variables optimizadas
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local predictionFactor = 0.18
local minTargetDistance = 5
local renderStepped
local headOffset = Vector3.new(0, 0.2, 0)

-- Sistema de notificación visual mejorado
local notificationGui = nil
local notificationFrame = nil
local lastVisibleState = false
local visibilityDebounce = 0
local DEBOUNCE_TIME = 0.2  -- 200ms de persistencia visual

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
    notificationFrame.Size = UDim2.new(0, 180, 0, 30)
    notificationFrame.Position = UDim2.new(0.5, -90, 0.02, 0)
    notificationFrame.Visible = false
    notificationFrame.Parent = notificationGui
    
    -- Esquinas redondeadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    -- Borde fino
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 1, 0)
    stroke.Thickness = 1
    stroke.Parent = notificationFrame
    
    -- Icono de objetivo
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Image = "rbxassetid://3926307971"
    icon.ImageRectOffset = Vector2.new(324, 364)
    icon.ImageRectSize = Vector2.new(36, 36)
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 5, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Color3.new(0, 1, 0)
    icon.Parent = notificationFrame
    
    -- Texto elegante
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Text = "OBJETIVO VISIBLE"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notificationFrame
end

-- Actualizar notificación con persistencia
local function updateNotification(visible)
    if not notificationFrame then return end
    
    -- Sistema de persistencia para evitar parpadeos
    local currentTime = os.clock()
    if visible then
        lastVisibleState = true
        visibilityDebounce = currentTime + DEBOUNCE_TIME
        notificationFrame.Visible = true
    elseif currentTime > visibilityDebounce then
        lastVisibleState = false
        notificationFrame.Visible = false
    else
        notificationFrame.Visible = true
    end
end

-- Sistema profesional de detección de visibilidad
local function isTargetVisible(character)
    if not character then return false end
    
    local origin = Camera.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true

    -- Puntos estratégicos del cuerpo
    local bodyPoints = {
        {part = "Head", offset = Vector3.new(0, 0.5, 0)},
        {part = "UpperTorso", offset = Vector3.new(0, 0.5, 0)},
        {part = "HumanoidRootPart", offset = Vector3.new(0, 1.5, 0)},
        {part = "LeftUpperArm", offset = Vector3.new(0, 0, 0)},
        {part = "RightUpperArm", offset = Vector3.new(0, 0, 0)}
    }
    
    -- Verificar múltiples puntos con prioridad estratégica
    local visiblePoints = 0
    local requiredPoints = 2  -- Requerir al menos 2 puntos visibles
    
    for _, pointData in ipairs(bodyPoints) do
        local part = character:FindFirstChild(pointData.part)
        if part then
            local targetPosition = part.Position + pointData.offset
            local direction = (targetPosition - origin).Unit
            local distance = (targetPosition - origin).Magnitude
            
            local raycastResult = Workspace:Raycast(origin, direction * distance, raycastParams)
            
            if not raycastResult then
                visiblePoints = visiblePoints + 1
                if visiblePoints >= requiredPoints then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Sistema avanzado de predicción de cabeza
local function predictHeadPosition(target)
    if not target or target == LocalPlayer then return nil end
    
    local character = target.Character
    if not character then return nil end
    
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Calcular distancia al jugador local
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    if distance < minTargetDistance then return nil end
    
    -- Calcular velocidad real
    local velocity = head.AssemblyLinearVelocity
    
    -- Predecir posición futura
    return head.Position + (velocity * predictionFactor) + headOffset
end

-- Sistema de seguimiento mejorado
local function precisionAim()
    local bestTarget = nil
    local bestHeadPos = nil
    local minScreenDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local headPos = predictHeadPosition(player)
        if not headPos then continue end
        
        local screenPos = Camera:WorldToViewportPoint(headPos)
        if screenPos.Z < 0 then continue end
        
        -- Calcular distancia desde el centro de la pantalla
        local mousePos = UserInputService:GetMouseLocation()
        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if screenDistance < minScreenDistance then
            minScreenDistance = screenDistance
            bestTarget = player
            bestHeadPos = headPos
        end
    end
    
    -- Verificar visibilidad con sistema profesional
    local isVisible = false
    if bestTarget and bestTarget.Character then
        isVisible = isTargetVisible(bestTarget.Character)
    end
    
    updateNotification(isVisible)
    
    if not bestTarget or not bestHeadPos then return end
    
    -- Realizar el movimiento del mouse solo si el objetivo es visible
    if isVisible then
        local screenPos = Camera:WorldToViewportPoint(bestHeadPos)
        local mousePos = UserInputService:GetMouseLocation()
        local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
        local delta = (targetScreenPos - mousePos)
        
        mousemoverel(delta.X * 0.7, delta.Y * 0.7)
    end
end

-- Loop principal estable
local function stableLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        precisionAim()
    else
        updateNotification(false)
    end
end

-- API para el hub
return {
    activate = function()
        -- Configuración profesional
        predictionFactor = 0.15
        
        -- Crear notificación
        createNotification()
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(stableLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        
        -- Eliminar notificación
        if notificationGui then
            notificationGui:Destroy()
            notificationGui = nil
            notificationFrame = nil
        end
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.headOffset then headOffset = options.headOffset end
        if options.minTargetDistance then minTargetDistance = options.minTargetDistance end
        if options.debounceTime then DEBOUNCE_TIME = options.debounceTime end
    end
}
