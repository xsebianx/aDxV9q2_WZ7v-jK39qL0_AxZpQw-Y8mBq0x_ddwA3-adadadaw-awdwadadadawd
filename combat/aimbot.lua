-- Servicios esencialesss
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Variables optimizadas
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local predictionFactor = 0.18
local smoothingFactor = 0.04
local renderStepped
local targetCache = {}
local playerList = Players:GetPlayers()
local headOffset = Vector3.new(0, 0.2, 0)  -- Compensación para apuntar a la cabeza

-- Sistema de notificación visual
local notificationGui = nil
local notificationLabel = nil

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
    notificationLabel.Font = Enum.Font.GothamBlack
    notificationLabel.TextSize = 18
    notificationLabel.TextStrokeColor3 = Color3.new(0, 0.2, 0)
    notificationLabel.TextStrokeTransparency = 0.3
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.Size = UDim2.new(0, 200, 0, 40)
    notificationLabel.Position = UDim2.new(0.5, -100, 0.02, 0)  -- Parte superior, centrado
    notificationLabel.Visible = false
    notificationLabel.Parent = notificationGui
    
    -- Efecto de brillo
    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 1, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.5, 1, 0.5)),
        ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0))
    })
    glow.Transparency = NumberSequence.new(0.5)
    glow.Rotation = 90
    glow.Parent = notificationLabel
end

-- Actualizar notificación
local function updateNotification(visible)
    if not notificationLabel then return end
    notificationLabel.Visible = visible
end

-- Sistema avanzado de predicción de cabeza
local function predictHeadPosition(target)
    if not target or not target.Character then return nil end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Calcular velocidad real (incluyendo movimiento del mouse del objetivo)
    local velocity = head.AssemblyLinearVelocity
    
    -- Predecir posición futura con compensación de ping
    local pingCompensation = 0.15  -- 150ms
    return head.Position + (velocity * (predictionFactor + pingCompensation)) + headOffset
end

-- Sistema de seguimiento directo a la cabeza
local function directHeadAim()
    local bestTarget = nil
    local bestHeadPos = nil
    local minDistance = math.huge
    
    for _, player in ipairs(playerList) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local headPos = predictHeadPosition(player)
        if not headPos then continue end
        
        local screenPos = Camera:WorldToViewportPoint(headPos)
        if screenPos.Z < 0 then continue end  -- Detrás de la cámara
        
        -- Calcular distancia desde el centro de la pantalla
        local mousePos = UserInputService:GetMouseLocation()
        local centerDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if centerDist < minDistance then
            minDistance = centerDist
            bestTarget = player
            bestHeadPos = headPos
        end
    end
    
    return bestTarget, bestHeadPos
end

-- Movimiento de mouse ultra rápido y preciso
local function rapidMouseMove(targetPos)
    if not targetPos then return end
    
    local screenPos = Camera:WorldToViewportPoint(targetPos)
    if screenPos.Z < 0 then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
    local delta = (targetScreenPos - mousePos)
    
    -- Movimiento directo (sin suavizado) para máxima velocidad
    mousemoverel(delta.X, delta.Y)
end

-- Sistema de seguimiento adaptativo
local function adaptiveAim()
    local target, headPos = directHeadAim()
    
    -- Actualizar notificación
    updateNotification(target ~= nil)
    
    if not target or not headPos then return end
    
    -- Fase 1: Movimiento rápido inicial
    rapidMouseMove(headPos)
    
    -- Fase 2: Ajuste fino (opcional)
    if (headPos - Camera.CFrame.Position).Magnitude > 50 then
        task.wait(0.02)
        local refinedPos = predictHeadPosition(target)
        rapidMouseMove(refinedPos)
    end
end

-- Loop principal de alta precisión
local function precisionLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        adaptiveAim()
    else
        updateNotification(false)
    end
end

-- API para el hub
return {
    activate = function()
        -- Configuración profesional
        predictionFactor = 0.15
        smoothingFactor = 0.01
        
        -- Crear notificación
        createNotification()
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(precisionLoop)
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
        if options.headOffset then headOffset = options.headOffset end
    end
}
