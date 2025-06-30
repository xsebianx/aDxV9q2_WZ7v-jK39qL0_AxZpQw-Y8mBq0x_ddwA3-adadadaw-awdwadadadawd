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

-- Función ultra rápida para movimiento de mouse
local function optimizedMouseMove(deltaX, deltaY)
    local now = tick()
    if now - lastInputTime > 0.016 then  -- 60 FPS máximo
        lastInputTime = now
        mousemoverel(deltaX, deltaY)
    end
end

-- Sistema de predicción mejorado para cualquier distancia
local function calculatePrecisionPrediction(hitbox)
    if not hitbox then return nil end
    
    -- Predicción base (90% de los casos)
    local basePrediction = hitbox.Position + (hitbox.AssemblyLinearVelocity * predictionFactor)
    
    -- Predicción para movimiento lateral rápido
    local horizontalVelocity = Vector3.new(
        hitbox.AssemblyLinearVelocity.X,
        0,
        hitbox.AssemblyLinearVelocity.Z
    )
    
    if horizontalVelocity.Magnitude > 25 then
        return basePrediction + (horizontalVelocity.Unit * 1.5)
    end
    
    return basePrediction
end

-- Sistema de detección de objetivos sin límites
local function findAnyVisiblePart(target)
    if not target or not target.Character then return nil end
    
    -- Primero intentar partes prioritarias
    for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
        local part = target.Character:FindFirstChild(partName)
        if part then
            return part
        end
    end
    
    -- Buscar cualquier parte visible
    for _, part in ipairs(target.Character:GetChildren()) do
        if part:IsA("BasePart") then
            return part
        end
    end
    
    return nil
end

-- Sistema de selección de objetivos sin restricciones
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

-- Sistema de seguimiento pixel-perfect
local function pixelPerfectAim()
    local target, part = findOptimalTarget()
    if not target or not part then return end
    
    local predictedPos = calculatePrecisionPrediction(part)
    if not predictedPos then return end
    
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

-- Loop principal ultra eficiente
local function aimbotLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        pixelPerfectAim()
    end
end

-- API simplificada para el hub
return {
    activate = function()
        -- Configuración profesional
        predictionFactor = 0.18   -- Predicción precisa
        smoothingFactor = 0.04    -- Movimientos suaves pero rápidos
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        targetCache = {}
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
    end
}
