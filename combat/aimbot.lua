-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Variables protegidas contra errores
local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local ZOOM_SPEED = 3
local MAX_ZOOM = 10
local MIN_ZOOM = 70
local DEFAULT_ZOOM = 70
local currentZoom = DEFAULT_ZOOM
local zoomSensitivityFactor = 1.0
local predictionFactor = 0.25
local smoothingFactor = 0.08
local renderStepped
local targetCache = {}
local playerList = Players:GetPlayers()
local lastInputTime = 0

-- Función segura para obtener la cámara
local function getSafeCamera()
    return Workspace:FindFirstChildOfClass("Camera") or Workspace.CurrentCamera
end

-- Sistema de zoom corregido (dirección invertida)
local function safeUpdateZoom(direction)
    local success, err = pcall(function()
        local cam = getSafeCamera()
        if not cam then return end
        
        -- CORRECCIÓN: Invertir la dirección para comportamiento natural
        local zoomDirection = direction > 0 and -1 or 1
        currentZoom = math.clamp(currentZoom + (zoomDirection * ZOOM_SPEED), MAX_ZOOM, MIN_ZOOM)
        
        cam.FieldOfView = currentZoom
        
        -- Ajustar sensibilidad según zoom
        zoomSensitivityFactor = math.clamp(DEFAULT_ZOOM / currentZoom, 0.5, 2.0)
    end)
    
    if not success then
        warn("[ZOOM ERROR]", err)
    end
end

-- Función optimizada para movimiento del mouse con ajuste de zoom
local function safeMouseMove(deltaX, deltaY)
    pcall(function()
        -- Limitar movimientos a 60 por segundo
        local now = tick()
        if now - lastInputTime > 0.016 then
            lastInputTime = now
            
            -- Aplicar ajuste de sensibilidad por zoom
            deltaX = deltaX * zoomSensitivityFactor
            deltaY = deltaY * zoomSensitivityFactor
            
            mousemoverel(deltaX, deltaY)
        end
    end)
end

-- Sistema de selección de objetivos optimizado
local function findFastTarget()
    local bestScore = -math.huge
    local bestHitbox = nil
    local cam = getSafeCamera()
    if not cam then return nil end
    
    local cameraPos = cam.CFrame.Position
    
    -- Actualizar lista de jugadores solo si cambió
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
        for _, hitboxName in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
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

-- Sistema de predicción con protección
local function safePrediction(hitbox)
    if not hitbox then return nil end
    
    return pcall(function()
        return hitbox.Position + (hitbox.AssemblyLinearVelocity * predictionFactor)
    end)
end

-- Sistema de seguimiento seguro con zoom
local function safeAim()
    local cam = getSafeCamera()
    if not cam then return end
    
    local hitbox = findFastTarget()
    if not hitbox then return end
    
    local success, predictedPos = safePrediction(hitbox)
    if not success or not predictedPos then return end
    
    local screenPos, visible = pcall(function()
        return cam:WorldToViewportPoint(predictedPos)
    end)
    
    if not success or not visible then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
    local delta = (targetPos - mousePos)
    
    safeMouseMove(
        delta.X * smoothingFactor,
        delta.Y * smoothingFactor
    )
end

-- Manejar rueda del mouse para zoom con protección y dirección corregida
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        -- CORRECCIÓN: Usar el valor directo sin inversión
        safeUpdateZoom(input.Position.Y)
    end
end)

-- Restablecer zoom al soltar botones
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        pcall(function()
            local cam = getSafeCamera()
            if cam then
                cam.FieldOfView = DEFAULT_ZOOM
            end
            currentZoom = DEFAULT_ZOOM
            zoomSensitivityFactor = 1.0
        end)
    end
end)

-- Loop principal protegido
local function safeAimbotLoop()
    pcall(function()
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            safeAim()
        end
    end)
end

-- API para el hub con protección completa
return {
    activate = function()
        -- Inicializar cámara
        camera = getSafeCamera()
        if camera then
            camera.FieldOfView = DEFAULT_ZOOM
        end
        
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(safeAimbotLoop)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        
        pcall(function()
            local cam = getSafeCamera()
            if cam then
                cam.FieldOfView = DEFAULT_ZOOM
            end
            currentZoom = DEFAULT_ZOOM
            zoomSensitivityFactor = 1.0
            targetCache = {}
        end)
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
        if options.zoomSpeed then ZOOM_SPEED = options.zoomSpeed end
        if options.maxZoom then MAX_ZOOM = options.maxZoom end
        if options.minZoom then MIN_ZOOM = options.minZoom end
        
        -- Corrección adicional para dirección del zoom
        if options.invertZoomDirection then
            ZOOM_DIRECTION_MULTIPLIER = -1
        else
            ZOOM_DIRECTION_MULTIPLIER = 1
        end
    end
}
