-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Variables optimizadas
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local predictionFactor = 0.22
local smoothingFactor = 0.06
local renderStepped
local lastInputTime = 0
local targetCache = {}
local playerList = Players:GetPlayers()

-- Sistema de notificación visual
local notificationGui = nil
local notificationLabel = nil
local lastTarget = nil
local notificationTime = 0

-- Crear la notificación
local function createNotification()
    if notificationGui then return end
    
    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "AimbotNotification"
    notificationGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    notificationLabel = Instance.new("TextLabel")
    notificationLabel.Name = "TargetIndicator"
    notificationLabel.Text = "OBJETIVO VISIBLE"
    notificationLabel.TextColor3 = Color3.new(0, 1, 0)  -- Verde brillante
    notificationLabel.Font = Enum.Font.GothamBold
    notificationLabel.TextSize = 16
    notificationLabel.TextStrokeColor3 = Color3.new(0, 0.2, 0)
    notificationLabel.TextStrokeTransparency = 0.5
    notificationLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    notificationLabel.BackgroundTransparency = 0.7
    notificationLabel.BorderSizePixel = 0
    notificationLabel.Size = UDim2.new(0, 150, 0, 30)
    notificationLabel.Position = UDim2.new(0.5, -75, 0.01, 0)  -- Parte superior, centrado
    notificationLabel.Visible = false
    notificationLabel.Parent = notificationGui
    
    -- Esquinas redondeadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationLabel
    
    -- Icono de confirmación
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Image = "rbxassetid://3926305904"  -- Icono de Roblox
    icon.ImageRectOffset = Vector2.new(964, 324)
    icon.ImageRectSize = Vector2.new(36, 36)
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 5, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Color3.new(0, 1, 0)  -- Verde
    icon.Parent = notificationLabel
end

-- Actualizar notificación
local function updateNotification(target)
    if not notificationLabel then return end
    
    if target and target ~= lastTarget then
        notificationLabel.Visible = true
        notificationLabel.Text = "OBJETIVO VISIBLE"
        notificationTime = tick()
    elseif not target and notificationLabel.Visible and (tick() - notificationTime > 0.3) then
        notificationLabel.Visible = false
    end
    
    lastTarget = target
end

-- Función ultra rápida para movimiento de mouse
local function optimizedMouseMove(deltaX, deltaY)
    local now = tick()
    if now - lastInputTime > 0.016 then  -- 60 FPS máximo
        lastInputTime = now
        mousemoverel(deltaX, deltaY)
    end
end

-- Sistema de detección de objetivos
local function findAnyVisiblePart(target)
    if not target or not target.Character then return nil end
    
    -- Buscar cualquier parte visible
    for _, part in ipairs(target.Character:GetChildren()) do
        if part:IsA("BasePart") then
            return part
        end
    end
    
    return nil
end

-- Sistema de selección de objetivos
local function findOptimalTarget()
    local bestTarget = nil
    local bestPart = nil
    local bestDistance = math.huge
    
    for _, player in ipairs(playerList) do
        if player == LocalPlayer then continue end
        
        local character = targetCache[player] or player.Character
        if not character then continue end
        targetCache[player] = character
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local part = findAnyVisiblePart(player)
        if part then
            local distance = (part.Position - Camera.CFrame.Position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                bestTarget = player
                bestPart = part
            end
        end
    end
    
    return bestTarget, bestPart
end

-- Sistema de seguimiento
local function pixelPerfectAim()
    local target, part = findOptimalTarget()
    
    -- Actualizar notificación
    updateNotification(target)
    
    if not target or not part then return end
    
    local predictedPos = part.Position + (part.AssemblyLinearVelocity * predictionFactor)
    local screenPos = Camera:WorldToViewportPoint(predictedPos)
    if screenPos.Z < 0 then return end  -- Detrás de la cámara
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
    local delta = (targetPos - mousePos)
    
    optimizedMouseMove(
        delta.X * smoothingFactor,
        delta.Y * smoothingFactor
    )
end

-- Loop principal
local function aimbotLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        pixelPerfectAim()
    else
        updateNotification(nil)
    end
end

-- API para el hub
return {
    activate = function()
        -- Configuración profesional
        predictionFactor = 0.18
        smoothingFactor = 0.04
        
        -- Crear notificación
        createNotification()
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
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
            notificationLabel = nil
        end
        
        targetCache = {}
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
    end
}
