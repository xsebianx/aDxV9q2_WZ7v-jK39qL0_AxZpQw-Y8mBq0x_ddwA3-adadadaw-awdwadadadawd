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
local maxFOV = 90 -- Grados (ajustable)
local renderStepped
local headOffset = Vector3.new(0, 0.2, 0)

-- Sistema de notificación visual mejorado
local notificationGui = nil
local notificationFrame = nil
local notificationLabel = nil
local notificationIcon = nil
local notificationStroke = nil

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
    
    -- Esquinas redondeadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    -- Borde fino (guardamos referencia para cambiar color)
    notificationStroke = Instance.new("UIStroke")
    notificationStroke.Color = Color3.new(0, 1, 0)  -- Verde por defecto
    notificationStroke.Thickness = 1
    notificationStroke.Parent = notificationFrame
    
    -- Icono de objetivo (guardamos referencia)
    notificationIcon = Instance.new("ImageLabel")
    notificationIcon.Name = "Icon"
    notificationIcon.Image = "rbxassetid://3926307971"
    notificationIcon.ImageRectOffset = Vector2.new(324, 364)
    notificationIcon.ImageRectSize = Vector2.new(36, 36)
    notificationIcon.Size = UDim2.new(0, 20, 0, 20)
    notificationIcon.Position = UDim2.new(0, 5, 0.5, -10)
    notificationIcon.BackgroundTransparency = 1
    notificationIcon.ImageColor3 = Color3.new(0, 1, 0)  -- Verde por defecto
    notificationIcon.Parent = notificationFrame
    
    -- Texto elegante (guardamos referencia)
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
        notificationIcon.ImageColor3 = Color3.new(0, 1, 0)  -- Verde
        notificationStroke.Color = Color3.new(0, 1, 0)     -- Verde
    elseif state == "oculto" then
        notificationLabel.Text = "OBJETIVO OCULTO"
        notificationIcon.ImageColor3 = Color3.new(1, 0, 0)  -- Rojo
        notificationStroke.Color = Color3.new(1, 0, 0)      -- Rojo
    end
end

-- Verificación profesional de visibilidad con detección de obstáculos
local function isTargetVisible(character)
    if not character then return false end
    
    local origin = Camera.CFrame.Position
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    -- Usamos una posición ligeramente más baja que el centro de la cabeza
    local headPosition = head.Position + Vector3.new(0, -0.1, 0)
    
    -- Crear parámetros de raycast profesionales
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    -- Comprobación de 3 puntos clave para mayor precisión
    local pointsToCheck = {
        headPosition, -- Cabeza
        headPosition + Vector3.new(0, -1.5, 0), -- Torso
        headPosition + Vector3.new(0, -3, 0) -- Piernas
    }
    
    local visiblePoints = 0
    
    for _, point in ipairs(pointsToCheck) do
        local direction = (point - origin).Unit
        local distance = (point - origin).Magnitude
        
        -- Realizar el raycast
        local result = Workspace:Raycast(origin, direction * distance, raycastParams)
        
        -- Si no hay resultado, el punto es visible
        if not result then
            visiblePoints = visiblePoints + 1
        else
            -- Verificar si lo que bloquea es el mismo jugador
            local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
            if hitCharacter == character then
                visiblePoints = visiblePoints + 1
            else
                -- Verificar propiedades del obstáculo
                local hitPart = result.Instance
                local material = hitPart.Material
                local transparency = hitPart.Transparency
                
                -- Materiales transparentes
                local transparentMaterials = {
                    Enum.Material.Glass,
                    Enum.Material.ForceField,
                    Enum.Material.Neon,
                    Enum.Material.Plastic,
                    Enum.Material.Air,
                    Enum.Material.Water
                }
                
                -- Si es transparente o tiene alta transparencia, considerar visible
                local isTransparent = false
                for _, mat in ipairs(transparentMaterials) do
                    if material == mat then
                        isTransparent = true
                        break
                    end
                end
                
                if isTransparent or transparency > 0.7 or not hitPart.CanCollide then
                    visiblePoints = visiblePoints + 1
                end
            end
        end
    end
    
    -- Considerar visible si al menos 2 de 3 puntos son visibles
    return visiblePoints >= 2
end

-- Sistema avanzado de predicción de cabeza con protección
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

-- Sistema de seguimiento mejorado con FOV
local function precisionAim()
    local bestTarget = nil
    local bestHeadPos = nil
    local minScreenDistance = math.huge
    
    -- Calcular el radio máximo en píxeles para el FOV
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local maxRadius = math.tan(math.rad(maxFOV / 2)) * viewportSize.Y / 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local headPos = predictHeadPosition(player)
        if not headPos then continue end
        
        local screenPos = Camera:WorldToViewportPoint(headPos)
        if screenPos.Z < 0 then continue end
        
        -- Calcular distancia desde el centro de la pantalla
        local mousePos = UserInputService:GetMouseLocation()
        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local screenDistance = (screenPoint - mousePos).Magnitude
        
        -- Calcular distancia desde el centro (para FOV)
        local distanceFromCenter = (screenPoint - center).Magnitude
        
        -- Solo considerar objetivos dentro del FOV
        if distanceFromCenter > maxRadius then continue end
        
        if screenDistance < minScreenDistance then
            minScreenDistance = screenDistance
            bestTarget = player
            bestHeadPos = headPos
        end
    end
    
    -- ACTUALIZACIÓN: Verificar visibilidad profesional
    local visibilityState = nil
    if bestTarget and bestTarget.Character then
        if isTargetVisible(bestTarget.Character) then
            visibilityState = "visible"
        else
            visibilityState = "oculto"
        end
    end
    
    updateNotification(visibilityState)
    
    if not bestTarget or not bestHeadPos then return end
    
    -- Realizar el movimiento del mouse
    local screenPos = Camera:WorldToViewportPoint(bestHeadPos)
    local mousePos = UserInputService:GetMouseLocation()
    local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
    local delta = (targetScreenPos - mousePos)
    
    mousemoverel(delta.X * 0.7, delta.Y * 0.7)
end

-- Loop principal estable
local function stableLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        precisionAim()
    else
        updateNotification(nil)
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
            notificationLabel = nil
            notificationIcon = nil
            notificationStroke = nil
        end
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.headOffset then headOffset = options.headOffset end
        if options.minTargetDistance then minTargetDistance = options.minTargetDistance end
        if options.maxFOV then maxFOV = options.maxFOV end
    end
}
