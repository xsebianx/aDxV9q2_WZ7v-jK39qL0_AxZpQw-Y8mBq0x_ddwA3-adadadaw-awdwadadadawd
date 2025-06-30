-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuración de zoom
local ZOOM_SPEED = 3
local MAX_ZOOM = 10
local MIN_ZOOM = 70
local DEFAULT_ZOOM = 70
local currentZoom = DEFAULT_ZOOM
local isZooming = false
local zoomSensitivityFactor = 1.0

-- Variables del aimbot (versión ligera)
local predictionFactor = 0.25
local smoothingFactor = 0.08
local renderStepped
local targetCache = {}
local playerList = Players:GetPlayers()

-- Sistema de zoom suave
local function updateZoom(direction)
    currentZoom = math.clamp(currentZoom - (direction * ZOOM_SPEED), MAX_ZOOM, MIN_ZOOM)
    Camera.FieldOfView = currentZoom
    
    -- Ajustar sensibilidad según zoom
    zoomSensitivityFactor = math.clamp(DEFAULT_ZOOM / currentZoom, 0.5, 2.0)
end

-- Función optimizada para movimiento del mouse con ajuste de zoom
local function zoomAwareMouseMove(deltaX, deltaY)
    -- Aplicar ajuste de sensibilidad por zoom
    deltaX = deltaX * zoomSensitivityFactor
    deltaY = deltaY * zoomSensitivityFactor
    
    mousemoverel(deltaX, deltaY)
end

-- Sistema de predicción ligero con ajuste de zoom
local function zoomAwarePrediction(hitbox)
    local basePrediction = hitbox.Position + (hitbox.AssemblyLinearVelocity * predictionFactor)
    
    -- Ajuste adicional para mantener precisión con zoom extremo
    if currentZoom < 30 then
        return basePrediction + (hitbox.AssemblyLinearVelocity * 0.05)
    end
    
    return basePrediction
end

-- Sistema de seguimiento con soporte para zoom
local function zoomAwareAim()
    local hitbox = findFastTarget()
    if not hitbox then return end
    
    local predictedPos = zoomAwarePrediction(hitbox)
    local screenPos, visible = Camera:WorldToViewportPoint(predictedPos)
    
    if visible then
        local mousePos = UserInputService:GetMouseLocation()
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        local delta = (targetPos - mousePos)
        
        zoomAwareMouseMove(
            delta.X * smoothingFactor,
            delta.Y * smoothingFactor
        )
    end
end

-- Manejar rueda del mouse para zoom
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        updateZoom(input.Position.Y)
        isZooming = true
    end
end)

-- Restablecer zoom al soltar botones
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Camera.FieldOfView = DEFAULT_ZOOM
        currentZoom = DEFAULT_ZOOM
        isZooming = false
    end
end)

-- Loop principal con soporte para zoom
local function aimbotLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        zoomAwareAim()
    end
end

-- API para el hub
return {
    activate = function()
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        Camera.FieldOfView = DEFAULT_ZOOM
        currentZoom = DEFAULT_ZOOM
        targetCache = {}
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
    end
}
