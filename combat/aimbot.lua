-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables optimizadas para rendimiento
local predictionFactor = 0.25
local smoothingFactor = 0.08
local hitboxPriority = {"Head", "HumanoidRootPart", "UpperTorso"}
local currentTarget = nil
local lastAimTime = 0
local lastInputTime = 0

-- Caché para cálculos recurrentes
local targetCache = {}
local playerList = Players:GetPlayers()
local cameraPos = Camera.CFrame.Position

-- Función optimizada para movimiento del mouse
local function optimizedMouseMove(deltaX, deltaY)
    local now = tick()
    -- Limitar movimientos a 60 por segundo
    if now - lastInputTime > 0.016 then
        lastInputTime = now
        mousemoverel(deltaX, deltaY)
    end
end

-- Verificación de visibilidad simplificada
local function quickVisibilityCheck(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    -- Raycast rápido con filtros básicos
    local result = workspace:Raycast(origin, direction * distance, {
        FilterType = Enum.RaycastFilterType.Blacklist,
        FilterDescendantsInstances = {LocalPlayer.Character},
        IgnoreWater = true
    })
    
    return not result
end

-- Sistema de predicción ligero
local function fastPrediction(hitbox)
    return hitbox.Position + (hitbox.AssemblyLinearVelocity * predictionFactor)
end

-- Selección de objetivos optimizada
local function findFastTarget()
    local bestScore = -math.huge
    local bestHitbox = nil
    cameraPos = Camera.CFrame.Position  -- Actualizar solo cuando sea necesario
    
    -- Usar caché de jugadores para evitar llamadas costosas
    if #playerList ~= #Players:GetPlayers() then
        playerList = Players:GetPlayers()
    end
    
    for _, player in ipairs(playerList) do
        if player == LocalPlayer then continue end
        
        -- Usar caché de personajes
        local character = targetCache[player] or player.Character
        if not character then continue end
        targetCache[player] = character
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Buscar hitbox prioritario
        for _, hitboxName in ipairs(hitboxPriority) do
            local hitbox = character:FindFirstChild(hitboxName)
            if hitbox then
                local distance = (hitbox.Position - cameraPos).Magnitude
                local score = 1000 / distance
                
                if score > bestScore then
                    bestScore = score
                    bestHitbox = hitbox
                end
                break  -- Solo un hitbox por jugador
            end
        end
    end
    
    return bestHitbox
end

-- Sistema de seguimiento ultra-ligero
local function lightAim()
    local hitbox = findFastTarget()
    if not hitbox then return end
    
    local predictedPos = fastPrediction(hitbox)
    local screenPos, visible = Camera:WorldToViewportPoint(predictedPos)
    
    if visible then
        local mousePos = UserInputService:GetMouseLocation()
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        local delta = (targetPos - mousePos)
        
        optimizedMouseMove(
            delta.X * smoothingFactor,
            delta.Y * smoothingFactor
        )
    end
end

-- Loop principal optimizado
local connection
local function aimbotLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        lightAim()
    end
end

-- API de alto rendimiento
return {
    activate = function()
        if not connection then
            connection = RunService.RenderStepped:Connect(aimbotLoop)
        end
    end,
    
    deactivate = function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        targetCache = {}
    end
}
