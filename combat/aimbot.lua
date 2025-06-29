-- Configuración ajustable
local config = {
    fieldOfView = 35,             -- Ángulo máximo de detección
    predictionFactor = 0.165,      -- Factor de predicción de movimiento
    targetLockDuration = 0.75,     -- Tiempo de bloqueo de objetivo
    smoothingFactor = 0.25,        -- Suavizado de movimiento (0.1-0.5)
    maxHistoryPoints = 5,          -- Puntos para cálculo de velocidad
    visibilityChecks = 3,          -- Número de checks de visibilidad
    fovColor = Color3.fromRGB(255, 70, 50),
    targetColor = Color3.fromRGB(50, 255, 100),
    requireRightMouse = true,      -- Requerir botón derecho para activar
    humanizeAim = true,            -- Movimientos más humanos
    stealthMode = false            -- Modo sigiloso (sin dibujos)
}

-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local renderStepped

-- Variables internas
local closestTarget = nil
local fovCircle, targetIndicator
local lockStartTime = 0
local positionHistory = {}
local humanizeOffset = Vector2.new(0, 0)
local lastHumanizeTime = 0

-- Función para crear elementos visuales
local function createVisuals()
    if config.stealthMode then return end
    
    if fovCircle then fovCircle:Remove() end
    if targetIndicator then targetIndicator:Remove() end
    
    -- Círculo de FOV
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.7
    fovCircle.Radius = config.fieldOfView
    fovCircle.Color = config.fovColor
    fovCircle.Filled = false
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    -- Indicador de objetivo
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 8
    targetIndicator.Color = config.targetColor
    targetIndicator.Filled = false
end

-- Verificación de visibilidad mejorada
local function isVisible(targetPart)
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - origin).Unit
    local distance = (targetPos - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    -- Múltiples rayos para mayor precisión
    for i = 1, config.visibilityChecks do
        local offset = Vector3.new(
            (math.random() - 0.5) * 0.5,
            (math.random() - 0.5) * 0.5,
            (math.random() - 0.5) * 0.5
        )
        
        local raycastResult = workspace:Raycast(
            origin, 
            (direction + offset).Unit * distance, 
            raycastParams
        )
        
        if raycastResult then
            if not raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
                return false
            end
        end
    end
    
    return true
end

-- Encontrar objetivo más cercano con prioridad
local function findClosestTarget()
    local bestTarget = nil
    local minAngle = math.rad(config.fieldOfView)
    local cameraDir = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and head and root then
                local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(cameraDir:Dot(directionToTarget))
                
                if angle < minAngle and isVisible(head) then
                    minAngle = angle
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget
end

-- Predicción de movimiento mejorada
local function predictPosition(target)
    if not target or not target.Character then return nil end
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    if not positionHistory[target] then positionHistory[target] = {} end
    
    -- Agregar nuevo punto
    table.insert(positionHistory[target], {
        position = head.Position,
        time = tick()
    })
    
    -- Mantener solo los puntos necesarios
    while #positionHistory[target] > config.maxHistoryPoints do
        table.remove(positionHistory[target], 1)
    end
    
    -- Calcular velocidad promedio
    if #positionHistory[target] < 2 then
        return head.Position
    end
    
    local totalVelocity = Vector3.new(0, 0, 0)
    local totalTime = 0
    
    for i = 2, #positionHistory[target] do
        local deltaPos = positionHistory[target][i].position - positionHistory[target][i-1].position
        local deltaTime = positionHistory[target][i].time - positionHistory[target][i-1].time
        
        if deltaTime > 0 then
            totalVelocity = totalVelocity + (deltaPos / deltaTime)
            totalTime = totalTime + deltaTime
        end
    end
    
    local avgVelocity = totalVelocity / (#positionHistory[target] - 1)
    return head.Position + avgVelocity * config.predictionFactor
end

-- Generar offset humano
local function generateHumanizeOffset()
    if not config.humanizeAim then return Vector2.new(0, 0) end
    
    local now = tick()
    if now - lastHumanizeTime < 0.5 then return humanizeOffset end
    
    lastHumanizeTime = now
    humanizeOffset = Vector2.new(
        (math.random() - 0.5) * 10,
        (math.random() - 0.5) * 10
    )
    
    return humanizeOffset
end

-- Seguimiento suavizado con comportamiento humano
local function preciseAim(target)
    if not target then return end
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local humanOffset = generateHumanizeOffset()
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y) + humanOffset
    local delta = targetPos - mousePos
    
    mousemoverel(
        delta.X * config.smoothingFactor, 
        delta.Y * config.smoothingFactor
    )
end

-- Verificación de seguridad mejorada
local function safetyCheck()
    if not LocalPlayer or not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    if UserInputService:GetFocusedTextBox() then return false end
    
    return true
end

-- Mantener objetivo con criterios mejorados
local function shouldKeepTarget(target)
    if not target then return false end
    if tick() - lockStartTime < config.targetLockDuration then return true end
    
    if not target.Character then return false end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local cameraDir = Camera.CFrame.LookVector
    local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
    local angle = math.acos(cameraDir:Dot(directionToTarget))
    
    return angle < math.rad(config.fieldOfView * 1.5) and isVisible(head)
end

-- Función principal del aimbot
local function aimbotLoop()
    if not safetyCheck() then
        if fovCircle then fovCircle.Visible = false end
        if targetIndicator then targetIndicator.Visible = false end
        closestTarget = nil
        return
    end
    
    -- Solo activar cuando se presiona el botón derecho si está configurado
    local aiming = true
    if config.requireRightMouse then
        aiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    
    if aiming then
        if not shouldKeepTarget(closestTarget) then
            closestTarget = findClosestTarget()
            lockStartTime = tick()
            positionHistory = {}  -- Resetear historial al cambiar objetivo
        end
        
        if closestTarget then
            preciseAim(closestTarget)
            
            if targetIndicator and not config.stealthMode then
                targetIndicator.Visible = true
                local head = closestTarget.Character:FindFirstChild("Head")
                if head then
                    local screenPos = Camera:WorldToViewportPoint(head.Position)
                    targetIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        else
            if targetIndicator then targetIndicator.Visible = false end
        end
        
        if fovCircle and not config.stealthMode then
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        end
    else
        if fovCircle then fovCircle.Visible = false end
        if targetIndicator then targetIndicator.Visible = false end
        closestTarget = nil
    end
end

-- Inicializar el sistema
createVisuals()
renderStepped = RunService.RenderStepped:Connect(aimbotLoop)

-- Sistema de limpieza mejorado
local function cleanUp()
    if fovCircle then 
        fovCircle:Remove()
        fovCircle = nil
    end
    
    if targetIndicator then 
        targetIndicator:Remove()
        targetIndicator = nil
    end
    
    if renderStepped then
        renderStepped:Disconnect()
        renderStepped = nil
    end
    
    positionHistory = {}
    closestTarget = nil
end

-- Limpieza al cambiar de personaje o salir
LocalPlayer.CharacterRemoving:Connect(cleanUp)
game:BindToClose(cleanUp)

-- API de configuración
function setAimbotConfig(newConfig)
    for key, value in pairs(newConfig) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
    
    if newConfig.stealthMode ~= nil or newConfig.showFOV ~= nil then
        createVisuals()
    end
end

function getAimbotConfig()
    return config
end

-- Control del aimbot
function enableAimbot()
    if not renderStepped then
        createVisuals()
        renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
    end
end

function disableAimbot()
    if renderStepped then
        renderStepped:Disconnect()
        renderStepped = nil
        cleanUp()
    end
end

-- Exponer API
_G.enableAimbot = enableAimbot
_G.disableAimbot = disableAimbot
_G.setAimbotConfig = setAimbotConfig
_G.getAimbotConfig = getAimbotConfig