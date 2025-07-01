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

-- Sistema de notificación visual
local notificationGui = nil
local notificationFrame = nil
local lastUpdateTime = 0
local DEBOUNCE_TIME = 0.15  -- 150ms de persistencia visual

-- Crear notificación simple y confiable
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
    
    -- Texto simple
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Text = "OBJETIVO VISIBLE"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = notificationFrame
end

-- Actualizar notificación con sistema simple
local function updateNotification(visible)
    if not notificationFrame then return end
    
    local currentTime = os.clock()
    
    if visible then
        lastUpdateTime = currentTime
        notificationFrame.UIStroke.Color = Color3.new(0, 1, 0)
        notificationFrame.Visible = true
    else
        if currentTime - lastUpdateTime > DEBOUNCE_TIME then
            notificationFrame.Visible = false
        end
    end
end

-- Sistema de predicción optimizado
local function predictHeadPosition(target)
    if not target or target == LocalPlayer then return nil end
    
    local character = target.Character
    if not character then return nil end
    
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Calcular distancia
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    if distance < minTargetDistance then return nil end
    
    -- Calcular velocidad y predecir
    local velocity = head.AssemblyLinearVelocity
    return head.Position + (velocity * predictionFactor) + headOffset
end

-- Sistema de detección de visibilidad confiable
local function isTargetVisible(target)
    if not target or not target.Character then return false end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = head.Position
    local direction = (targetPos - origin).Unit
    local distance = (targetPos - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local raycastResult = Workspace:Raycast(origin, direction * distance, raycastParams)
    
    return not raycastResult
end

-- Sistema de seguimiento optimizado
local function precisionAim()
    local bestTarget = nil
    local bestHeadPos = nil
    local minScreenDistance = math.huge
    local isVisible = false
    
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local headPos = predictHeadPosition(player)
        if not headPos then continue end
        
        local screenPos = Camera:WorldToViewportPoint(headPos)
        if screenPos.Z < 0 then continue end
        
        -- Calcular distancia en pantalla
        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local screenDistance = (screenPoint - mousePos).Magnitude
        
        if screenDistance < minScreenDistance then
            minScreenDistance = screenDistance
            bestTarget = player
            bestHeadPos = headPos
        end
    end
    
    -- Verificar visibilidad solo para el mejor objetivo
    if bestTarget then
        isVisible = isTargetVisible(bestTarget)
        updateNotification(isVisible)
    else
        updateNotification(false)
    end
    
    -- Aplicar aimbot solo si hay objetivo visible
    if bestTarget and bestHeadPos and isVisible then
        local screenPos = Camera:WorldToViewportPoint(bestHeadPos)
        local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
        local delta = (targetScreenPos - mousePos)
        
        mousemoverel(delta.X * 0.7, delta.Y * 0.7)
    end
end

-- Loop principal simplificado
local function mainLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        precisionAim()
    else
        updateNotification(false)
    end
end

-- API para el hub
return {
    activate = function()
        createNotification()
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(mainLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        
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
    end
}
