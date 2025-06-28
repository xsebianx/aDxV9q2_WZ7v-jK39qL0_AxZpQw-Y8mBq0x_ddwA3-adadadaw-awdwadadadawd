local aimEnabled = false
local fieldOfView = 30
local closestTarget = nil
local fovCircle, targetIndicator
local predictionFactor = 0.165

-- Servicios esenciales
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Crear elementos visuales básicos
local function createVisuals()
    if fovCircle then fovCircle:Remove() end
    if targetIndicator then targetIndicator:Remove() end
    
    -- Círculo de FOV
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.7
    fovCircle.Radius = fieldOfView
    fovCircle.Color = Color3.fromRGB(255, 50, 50)
    fovCircle.Filled = false
    
    -- Indicador de objetivo simple
    targetIndicator = Drawing.new("Circle")
    targetIndicator.Visible = false
    targetIndicator.Thickness = 2
    targetIndicator.Radius = 5
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
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit * distance * 1.2
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    return raycastResult == nil or raycastResult.Instance:IsDescendantOf(targetPart.Parent)
end

-- Encontrar objetivo más cercano
local function findClosestTarget()
    local closestPlayer = nil
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
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- Predicción básica
local function predictPosition(target)
    if not target or not target.Character then return nil end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return nil end
    
    return head.Position + head.Velocity * predictionFactor
end

-- Apuntado suavizado
local function smoothAim(target)
    if not target then return end
    
    local predictedPosition = predictPosition(target)
    if not predictedPosition then return end
    
    local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
    if not onScreen then return end
    
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local targetPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
    
    local delta = (targetPos - mousePos) * 0.3
    mousemoverel(delta.X, delta.Y)
end

-- Verificación de seguridad
local function safetyCheck()
    return LocalPlayer and 
           LocalPlayer.Character and 
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
        closestTarget = findClosestTarget()
        
        if closestTarget then
            smoothAim(closestTarget)
            if targetIndicator then
                targetIndicator.Visible = true
                local headPos = closestTarget.Character.Head.Position
                local screenPos = Camera:WorldToViewportPoint(headPos)
                targetIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
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
    end
end)

-- Controles
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and safetyCheck() then
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

-- Limpieza
game:BindToClose(function()
    renderStepped:Disconnect()
    if fovCircle then fovCircle:Remove() end
    if targetIndicator then targetIndicator:Remove() end
end)
