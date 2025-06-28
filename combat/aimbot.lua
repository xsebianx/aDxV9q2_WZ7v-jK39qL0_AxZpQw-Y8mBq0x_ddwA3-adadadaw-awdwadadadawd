local aimEnabled = false
local fieldOfView = 30
local detectionRadius = fieldOfView  -- Ahora igual al FOV para consistencia
local closestTarget = nil
local fovCircle
local targetIndicator
local predictionFactor = 0.165

-- Configuración esencial para evitar detección
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Crear elementos visuales
local function createVisuals()
    if fovCircle then fovCircle:Remove() end
    if targetIndicator then targetIndicator:Remove() end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.5
    fovCircle.Radius = fieldOfView
    fovCircle.Color = Color3.fromRGB(255, 50, 50)
    fovCircle.Filled = false
    
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 6
    targetIndicator.Color = Color3.fromRGB(50, 255, 50)
    targetIndicator.Filled = true
end

-- Verificación de visibilidad con RaycastParams
local function isVisible(targetPart)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    return raycastResult and raycastResult.Instance:IsDescendantOf(targetPart.Parent)
end

-- Encontrar objetivo con prioridad de visibilidad
local function findOptimalTarget()
    local optimalTarget = nil
    local minAngle = math.rad(fieldOfView)
    local cameraDir = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local directionToTarget = (head.Position - Camera.CFrame.Position).Unit
                local angle = math.acos(cameraDir:Dot(directionToTarget))
                
                if angle < minAngle and isVisible(head) then
                    minAngle = angle
                    optimalTarget = player
                end
            end
        end
    end
    
    return optimalTarget
end

-- Predicción mejorada con ajuste balístico
local function predictPosition(target)
    if not target.Character then return nil end
    
    local head = target.Character:FindFirstChild("Head")
    local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
    if not head or not rootPart then return nil end
    
    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    local travelTime = distance / 1000  -- Velocidad de bala aproximada
    local velocity = rootPart.Velocity
    
    -- Ajuste para gravedad (solo si es necesario)
    local gravityAdjustment = if target.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall
        then Vector3.new(0, workspace.Gravity * travelTime^2, 0)
        else Vector3.zero
        
    return head.Position + velocity * travelTime - gravityAdjustment
end

-- Sistema de apuntado suavizado (menos detectable)
local function smoothAim(target)
    if not target then return end
    
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    
    -- Suavizado exponencial
    local delta = (targetPos - mousePos) * 0.3
    mousemoverel(delta.X, delta.Y)
end

-- Sistema de seguridad
local function safetyCheck()
    return LocalPlayer and LocalPlayer.Character and
           LocalPlayer.Character:FindFirstChild("Humanoid") and
           LocalPlayer.Character.Humanoid.Health > 0
end

-- Conexión principal
local renderStepped = RunService.RenderStepped:Connect(function()
    if not safetyCheck() then
        if fovCircle then fovCircle.Visible = false end
        if targetIndicator then targetIndicator.Visible = false end
        return
    end
    
    if aimEnabled then
        closestTarget = findOptimalTarget()
        
        if closestTarget then
            smoothAim(closestTarget)
            targetIndicator.Visible = true
            local headPos = closestTarget.Character.Head.Position
            local screenPos = Camera:WorldToViewportPoint(headPos)
            targetIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            targetIndicator.Visible = false
        end
        
        fovCircle.Visible = true
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        targetIndicator.Visible = false
        fovCircle.Visible = false
    end
end)

-- Controles
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimEnabled = false
        closestTarget = nil
    end
end)

-- Inicialización
createVisuals()

-- Manejo de respawns
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(createVisuals)
end)
