local fieldOfView = 30
local closestTarget = nil
local fovCircle, targetIndicator
local predictionFactor = 0.165
local targetLockDuration = 0.5
local lockStartTime = 0
local smoothingFactor = 0.3
local positionHistory = {}

-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local renderStepped

-- Función para crear elementos visuales
local function createVisuals()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if targetIndicator then pcall(function() targetIndicator:Remove() end) end
    
    -- Círculo de FOV
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.7
    fovCircle.Radius = fieldOfView
    fovCircle.Color = Color3.fromRGB(255, 50, 50)
    fovCircle.Filled = false
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    -- Indicador de objetivo
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 8
    targetIndicator.Color = Color3.fromRGB(50, 255, 50)
    targetIndicator.Filled = false
end

-- Verificación de visibilidad
local function isVisible(targetPart)
    if not targetPart then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    
    local raycastResult = workspace:Raycast(origin, direction * 1000, raycastParams)
    return raycastResult and raycastResult.Instance:IsDescendantOf(targetPart.Parent)
end

-- Encontrar objetivo más cercano
local function findClosestTarget()
    local bestTarget = nil
    local minAngle = math.rad(fieldOfView)
    local shortestDistance = math.huge
    local cameraDir = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(cameraDir:Dot(directionToTarget))
                local distance = (head.Position - Camera.CFrame.Position).Magnitude
                
                if angle < minAngle and distance < shortestDistance and isVisible(head) then
                    shortestDistance = distance
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget
end

-- Predicción de movimiento
local function predictPosition(target)
    if not target or not target.Character then return nil end
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    if not positionHistory[target] then positionHistory[target] = {} end
    
    table.insert(positionHistory[target], {
        position = head.Position,
        time = tick()
    })
    
    while #positionHistory[target] > 5 do
        table.remove(positionHistory[target], 1)
    end
    
    if #positionHistory[target] < 2 then
        return head.Position
    end
    
    local velocity = (positionHistory[target][#positionHistory[target]].position - 
                    positionHistory[target][1].position) / 
                    (positionHistory[target][#positionHistory[target]].time - 
                    positionHistory[target][1].time)
    
    return head.Position + velocity * predictionFactor
end

-- Seguimiento suavizado
local function preciseAim(target)
    if not target then return end
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    local delta = targetPos - mousePos
    
    mousemoverel(delta.X * smoothingFactor, delta.Y * smoothingFactor)
end

-- Verificación de seguridad
local function safetyCheck()
    if not LocalPlayer or not LocalPlayer.Character then return false end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0 and not UserInputService:GetFocusedTextBox()
end

-- Mantener objetivo
local function shouldKeepTarget(target)
    if not target then return false end
    if tick() - lockStartTime < targetLockDuration then return true end
    
    if not target.Character then return false end
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local cameraDir = Camera.CFrame.LookVector
    local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
    local angle = math.acos(cameraDir:Dot(directionToTarget))
    
    return angle < math.rad(fieldOfView) and isVisible(head)
end

-- Función principal del aimbot
local function aimbotLoop()
    if not safetyCheck() then
        if fovCircle then fovCircle.Visible = false end
        if targetIndicator then targetIndicator.Visible = false end
        closestTarget = nil
        return
    end
    
    -- Solo activar cuando se presiona el botón derecho
    local aiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if aiming then
        if not shouldKeepTarget(closestTarget) then
            closestTarget = findClosestTarget()
            lockStartTime = tick()
        end
        
        if closestTarget then
            preciseAim(closestTarget)
            if targetIndicator then
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
        
        if fovCircle then
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

-- Sistema de limpieza
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
end

-- Limpieza al cambiar de personaje o salir
LocalPlayer.CharacterRemoving:Connect(cleanUp)
game:BindToClose(cleanUp)

-- Al final de aimbot.lua, añade:
function enableAimbot()
    if not renderStepped then
        createVisuals()
        renderStepped = RunService.RenderStepped:Connect(aimbotLoop)
        print("Aimbot activado")
    end
end

function disableAimbot()
    if renderStepped then
        renderStepped:Disconnect()
        renderStepped = nil
        cleanUp()
        print("Aimbot desactivado")
    end
end

_G.enableAimbot = enableAimbot
_G.disableAimbot = disableAimbot