-- Servicios esencialesdd
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables optimizadas para Estado de Anarquía
local predictionFactor
local smoothingFactor
local hitboxPriority = {"Head", "HumanoidRootPart", "UpperTorso"}  -- Prioridad de hitboxes
local renderStepped
local positionHistory = {}
local currentTarget = nil
local targetLock = false
local lastAimTime = 0

-- Fallback para mousemoverel (compatible con todos los exploits)
if not mousemoverel then
    mousemoverel = function(x, y)
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            mouse:MoveTo(mouse.X + x, mouse.Y + y)
        end)
    end
end

-- Verificación de visibilidad específica para Estado de Anarquía
local function isVisible(part)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if result then
        local hitPart = result.Instance
        while hitPart do
            if hitPart:IsDescendantOf(part.Parent) then
                return true
            end
            hitPart = hitPart.Parent
        end
    end
    
    return not result
end

-- Obtener el mejor hitbox disponible (optimizado para el juego)
local function getOptimalHitbox(target)
    if not target or not target.Character then return nil end
    
    -- Buscar hitboxes en orden de prioridad
    for _, hitboxName in ipairs(hitboxPriority) do
        local hitbox = target.Character:FindFirstChild(hitboxName)
        if hitbox and isVisible(hitbox) then
            return hitbox
        end
    end
    
    -- Fallback: Buscar cualquier parte visible
    for _, part in ipairs(target.Character:GetChildren()) do
        if part:IsA("BasePart") and isVisible(part) then
            return part
        end
    end
    
    return nil
end

-- Sistema de predicción simplificado pero efectivo
local function calculatePrediction(target, hitbox)
    if not target or not hitbox then return hitbox.Position end
    
    -- Solo usar velocidad actual para predicción (más estable)
    local velocity = hitbox.AssemblyLinearVelocity
    return hitbox.Position + (velocity * predictionFactor)
end

-- Sistema de selección de objetivos para Estado de Anarquía
local function findAnarchyTarget()
    local bestTarget = nil
    local bestHitbox = nil
    local bestScore = -math.huge
    local cameraPos = Camera.CFrame.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local hitbox = getOptimalHitbox(player)
            
            if humanoid and humanoid.Health > 0 and hitbox then
                local distance = (hitbox.Position - cameraPos).Magnitude
                local score = 0
                
                -- Priorizar objetivos cercanos
                score = score + (1000 / distance)
                
                -- Priorizar por hitbox
                if hitbox.Name == "Head" then
                    score = score + 100
                elseif hitbox.Name == "HumanoidRootPart" then
                    score = score + 75
                else
                    score = score + 50
                end
                
                -- Priorizar objetivos que miran hacia ti
                local targetHead = player.Character:FindFirstChild("Head")
                if targetHead then
                    local targetDirection = (cameraPos - targetHead.Position).Unit
                    local targetLook = targetHead.CFrame.LookVector
                    local angle = math.deg(math.acos(targetLook:Dot(targetDirection)))
                    if angle < 90 then
                        score = score + 80  -- Bonus si el objetivo te está mirando
                    end
                end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = player
                    bestHitbox = hitbox
                end
            end
        end
    end
    
    return bestTarget, bestHitbox
end

-- Sistema de seguimiento optimizado para el juego
local function anarchyAim(target, hitbox)
    if not target or not hitbox then return end
    
    local predictedPosition = calculatePrediction(target, hitbox)
    
    local success, screenPosition = pcall(function()
        return Camera:WorldToViewportPoint(predictedPosition)
    end)
    
    if not success then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPosition.X, screenPosition.Y)
    local delta = (targetPos - mousePos)
    
    -- Sistema de suavizado adaptativo
    local dynamicSmoothing = smoothingFactor
    
    -- Aplicar más fuerza cuando se acaba de activar
    if (tick() - lastAimTime) < 0.5 then
        dynamicSmoothing = smoothingFactor * 0.7
    end
    
    mousemoverel(
        delta.X * dynamicSmoothing,
        delta.Y * dynamicSmoothing
    )
end

-- Verificación de seguridad específica
local function safetyCheck()
    if not LocalPlayer then return false end
    if not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

-- Loop principal optimizado
local function aimbotLoop()
    local success, err = pcall(function()
        if not safetyCheck() then
            currentTarget = nil
            targetLock = false
            return
        end
        
        local aiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if aiming then
            local target, hitbox = findAnarchyTarget()
            
            if target and hitbox then
                if currentTarget ~= target then
                    currentTarget = target
                    targetLock = false
                    lastAimTime = tick()
                end
                
                anarchyAim(target, hitbox)
            else
                currentTarget = nil
                targetLock = false
            end
        else
            currentTarget = nil
            targetLock = false
        end
    end)
    
    if not success then
        warn("[ANARCHY AIMBOT ERROR]", err)
        currentTarget = nil
        targetLock = false
    end
end

-- API para Estado de Anarquía
return {
    activate = function()
        -- Configuración optimizada para Estado de Anarquía
        predictionFactor = 0.22   -- Predicción media
        smoothingFactor = 0.1     -- Suavizado equilibrado
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        positionHistory = {}
        currentTarget = nil
        targetLock = false
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
        if options.hitboxPriority then hitboxPriority = options.hitboxPriority end
    end
}
