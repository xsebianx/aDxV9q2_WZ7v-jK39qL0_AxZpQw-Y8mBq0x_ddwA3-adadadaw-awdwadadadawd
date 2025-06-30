-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- Variables optimizadas para obstáculos
local predictionFactor
local smoothingFactor
local hitboxPriority = {"Head", "HumanoidRootPart", "UpperTorso"} 
local renderStepped
local currentTarget = nil
local lastAimTime = 0
local obstacleIgnoreList = {}
local raycastParams = RaycastParams.new()

-- Configurar parámetros de raycast para ignorar vegetación
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

-- Fallback para mousemoverel
if not mousemoverel then
    mousemoverel = function(x, y)
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            mouse:MoveTo(mouse.X + x, mouse.Y + y)
        end)
    end
end

-- Verificación de visibilidad mejorada para estructuras y vegetación
local function isVisible(part)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    -- Actualizar lista de objetos a ignorar
    local ignoreList = {LocalPlayer.Character}
    for _, obj in ipairs(obstacleIgnoreList) do
        if obj and obj.Parent then
            table.insert(ignoreList, obj)
        end
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local result = Workspace:Raycast(origin, direction * distance, raycastParams)
    
    -- Si hay resultado, verificar si es un obstáculo ignorable
    if result then
        local hitPart = result.Instance
        
        -- Verificar si es vegetación u objeto ignorable
        local material = hitPart.Material
        local isVegetation = material == Enum.Material.Grass or 
                            material == Enum.Material.LeafyGrass or
                            material == Enum.Material.Sand
        
        -- Verificar si es una estructura delgada
        local isThinStructure = hitPart.Transparency > 0.5 or 
                               (hitPart.Size.Magnitude < 3 and material ~= Enum.Material.Concrete)
        
        -- Si es vegetación o estructura delgada, considerar visible
        if isVegetation or isThinStructure then
            return true
        end
        
        -- Verificar si es el propio jugador
        local hitParent = hitPart.Parent
        while hitParent do
            if hitParent == part.Parent then
                return true
            end
            hitParent = hitParent.Parent
        end
        
        return false
    end
    
    return true
end

-- Obtener el mejor hitbox disponible (optimizado para obstáculos)
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

-- Sistema de selección de objetivos para obstáculos
local function findTargetThroughObstacles()
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
                
                -- Bonus por visibilidad clara (sin obstáculos)
                if isVisible(hitbox) then
                    score = score + 80
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

-- Sistema de seguimiento optimizado para entornos complejos
local function preciseAim(target, hitbox)
    if not target or not hitbox then return end
    
    local predictedPosition = calculatePrediction(target, hitbox)
    
    local success, screenPosition = pcall(function()
        return Camera:WorldToViewportPoint(predictedPosition)
    end)
    
    if not success or not screenPosition then return end
    
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

-- Detectar y registrar obstáculos comunes
local function detectCommonObstacles()
    obstacleIgnoreList = {}
    
    -- Buscar vegetación común
    local vegetationNames = {"Grass", "Bush", "Tree", "Foliage", "Leaves"}
    for _, name in ipairs(vegetationNames) do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:find(name) and obj:IsA("BasePart") then
                table.insert(obstacleIgnoreList, obj)
            end
        end
    end
    
    -- Buscar estructuras delgadas
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj.Transparency > 0.7 or obj.Size.Magnitude < 2 then
                table.insert(obstacleIgnoreList, obj)
            end
        end
    end
end

-- Verificación de seguridad
local function safetyCheck()
    if not LocalPlayer then return false end
    if not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

-- Loop principal mejorado
local function aimbotLoop()
    local success, err = pcall(function()
        if not safetyCheck() then
            currentTarget = nil
            return
        end
        
        local aiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if aiming then
            -- Actualizar detección de obstáculos periódicamente
            if tick() % 5 < 0.1 then
                detectCommonObstacles()
            end
            
            local target, hitbox = findTargetThroughObstacles()
            
            if target and hitbox then
                if currentTarget ~= target then
                    currentTarget = target
                    lastAimTime = tick()
                end
                
                preciseAim(target, hitbox)
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    end)
    
    if not success then
        warn("[ANARCHY AIMBOT ERROR]", err)
        currentTarget = nil
    end
end

-- API para Estado de Anarquía con obstáculos
return {
    activate = function()
        -- Configuración optimizada para entornos complejos
        predictionFactor = 0.25   -- Predicción ligeramente mayor
        smoothingFactor = 0.08    -- Más rápido para reaccionar
        
        -- Detectar obstáculos iniciales
        detectCommonObstacles()
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        currentTarget = nil
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
        if options.hitboxPriority then hitboxPriority = options.hitboxPriority end
    end
}
