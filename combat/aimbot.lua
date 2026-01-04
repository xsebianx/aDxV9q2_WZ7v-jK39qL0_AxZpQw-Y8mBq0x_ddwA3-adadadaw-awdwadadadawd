local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local predictionFactor = 0.15
local minTargetDistance = 5
local maxFOV = 90
local smoothingFactor = 0.3
local humanizationEnabled = true
local renderStepped
local keybindConnection
local playerRemovingConnection
local headOffset = Vector3.new(0, 0.2, 0)
local lastDelta = Vector2.new(0, 0)
local visibilityCache = {}
local visibilityCacheDuration = 0.1
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true
local transparentMaterials = {
    [Enum.Material.Glass] = true,
    [Enum.Material.ForceField] = true,
    [Enum.Material.Neon] = true,
    [Enum.Material.Plastic] = true,
    [Enum.Material.Air] = true,
    [Enum.Material.Water] = true
}

local playerCache = {}
local cacheTimeout = 0.5

local playerData = {}

local notificationGui = nil
local notificationFrame = nil
local notificationLabel = nil
local notificationIcon = nil
local notificationStroke = nil

local configGui = nil
local configFrame = nil

local function createNotification()
    if notificationGui then return end
    
    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "AimbotNotification"
    notificationGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    notificationFrame.BackgroundTransparency = 0.7
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Size = UDim2.new(0, 220, 0, 30)
    notificationFrame.Position = UDim2.new(0.5, -110, 0.02, 0)
    notificationFrame.Visible = false
    notificationFrame.Parent = notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    notificationStroke = Instance.new("UIStroke")
    notificationStroke.Color = Color3.new(0, 1, 0)
    notificationStroke.Thickness = 1
    notificationStroke.Parent = notificationFrame
    
    notificationIcon = Instance.new("ImageLabel")
    notificationIcon.Name = "Icon"
    notificationIcon.Image = "rbxassetid://3926307971"
    notificationIcon.ImageRectOffset = Vector2.new(324, 364)
    notificationIcon.ImageRectSize = Vector2.new(36, 36)
    notificationIcon.Size = UDim2.new(0, 20, 0, 20)
    notificationIcon.Position = UDim2.new(0, 5, 0.5, -10)
    notificationIcon.BackgroundTransparency = 1
    notificationIcon.ImageColor3 = Color3.new(0, 1, 0)
    notificationIcon.Parent = notificationFrame
    
    notificationLabel = Instance.new("TextLabel")
    notificationLabel.Name = "Label"
    notificationLabel.Text = "OBJETIVO VISIBLE"
    notificationLabel.TextColor3 = Color3.new(1, 1, 1)
    notificationLabel.Font = Enum.Font.GothamMedium
    notificationLabel.TextSize = 14
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.Size = UDim2.new(0, 160, 1, 0)
    notificationLabel.Position = UDim2.new(0, 30, 0, 0)
    notificationLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationLabel.Parent = notificationFrame
end

local function updateNotification(state)
    if not notificationFrame then return end
    
    if state == nil then
        notificationFrame.Visible = false
        return
    end
    
    notificationFrame.Visible = true
    
    if state == "visible" then
        notificationLabel.Text = "OBJETIVO VISIBLE"
        notificationIcon.ImageColor3 = Color3.new(0, 1, 0)
        notificationStroke.Color = Color3.new(0, 1, 0)
    elseif state == "oculto" then
        notificationLabel.Text = "OBJETIVO OCULTO"
        notificationIcon.ImageColor3 = Color3.new(1, 0.5, 0)
        notificationStroke.Color = Color3.new(1, 0.5, 0)
    end
end

local function now()
    return os.clock()
end

local function isTargetVisible(player)
    local character = player and player.Character
    if not character then return false end

    local cache = visibilityCache[player.UserId]
    if cache and (now() - cache.time) < visibilityCacheDuration then
        return cache.visible
    end

    local origin = Camera.CFrame.Position
    local head = character:FindFirstChild("Head")
    if not head then return false end
    local headPosition = head.Position + Vector3.new(0, -0.1, 0)

    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

    local pointsToCheck = {
        headPosition,
        headPosition + Vector3.new(0, -1.5, 0),
        headPosition + Vector3.new(0, -3, 0)
    }

    local visiblePoints = 0

    for _, point in ipairs(pointsToCheck) do
        local direction = (point - origin).Unit
        local distance = (point - origin).Magnitude
        local result = Workspace:Raycast(origin, direction * distance, raycastParams)

        if not result then
            visiblePoints = visiblePoints + 1
        else
            local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
            if hitCharacter == character then
                visiblePoints = visiblePoints + 1
            else
                local hitPart = result.Instance
                local material = hitPart.Material
                local transparency = hitPart.Transparency

                local isTransparent = transparentMaterials[material] == true
                local hasCollision = hitPart.CanCollide and hitPart.CanQuery
                local isCustomNoCollide = hitPart:GetAttribute("NoAimObstruction") == true

                if isTransparent or transparency > 0.7 or not hasCollision or isCustomNoCollide then
                    visiblePoints = visiblePoints + 1
                end
            end
        end
    end

    local visible = visiblePoints >= 2
    visibilityCache[player.UserId] = {visible = visible, time = now()}
    return visible
end

local function clampVelocity(vec, maxMag)
    local mag = vec.Magnitude
    if mag > maxMag then
        return vec.Unit * maxMag
    end
    return vec
end

local function advancedPrediction(target)
    if not target or target == LocalPlayer then return nil end
    local character = target.Character
    if not character then return nil end
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local distance = (head.Position - Camera.CFrame.Position).Magnitude
    if distance < minTargetDistance then return nil end

    playerData[target.UserId] = playerData[target.UserId] or {}
    playerData[target.UserId].PositionHistory = playerData[target.UserId].PositionHistory or {}

    local history = playerData[target.UserId].PositionHistory
    local currentTime = now()

    table.insert(history, {position = head.Position, time = currentTime})
    while history[1] and (currentTime - history[1].time) > 0.35 do
        table.remove(history, 1)
    end

    if #history >= 2 then
        local newest = history[#history]
        local previous = history[#history - 1]
        local timeDiff = math.max(newest.time - previous.time, 1e-3)
        local velocity = clampVelocity((newest.position - previous.position) / timeDiff, 75)

        playerData[target.UserId].LastVelocity = velocity

        if #history >= 3 then
            local mid = history[#history - 1]
            local oldest = history[#history - 2]
            local oldVelocity = clampVelocity((mid.position - oldest.position) / math.max(mid.time - oldest.time, 1e-3), 75)
            local acceleration = clampVelocity((velocity - oldVelocity) / timeDiff, 120)
            return head.Position + (velocity * predictionFactor) + (0.5 * acceleration * predictionFactor * predictionFactor) + headOffset
        else
            return head.Position + (velocity * predictionFactor) + headOffset
        end
    end

    return head.Position + headOffset
end

local function calculateThreatLevel(player)
    local character = player.Character
    if not character then return 0 end

    local head = character:FindFirstChild("Head")
    if not head then return 0 end

    local distance = (head.Position - Camera.CFrame.Position).Magnitude

    local threatLevel = math.max(0, 100 - distance)

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local myRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if rootPart and myRootPart then
        local lookVector = rootPart.CFrame.LookVector
        local toPlayerVector = (myRootPart.Position - rootPart.Position).Unit
        local dotProduct = lookVector:Dot(toPlayerVector)

        if dotProduct > 0.8 then
            threatLevel = threatLevel + 30
        end
    end

    return math.min(100, threatLevel)
end

local function smoothAim(targetScreenPos, factor)
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (targetScreenPos - mousePos)
    local smoothedDelta = lastDelta:lerp(delta, factor or smoothingFactor)
    lastDelta = smoothedDelta
    mousemoverel(smoothedDelta.X, smoothedDelta.Y)
end

local function humanizeAim(targetScreenPos, factor)
    if not humanizationEnabled then
        smoothAim(targetScreenPos, factor)
        return
    end
    
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (targetScreenPos - mousePos)
    
    local jitter = Vector2.new(math.random(-20, 20) / 100, math.random(-20, 20) / 100)
    delta = delta + jitter
    
    local delay = math.random(5, 15) / 1000
    task.wait(delay)
    
    smoothAim(targetScreenPos, factor)
end

local function isCacheValid(player)
    local cached = playerCache[player.UserId]
    return cached and (now() - cached.timestamp) < cacheTimeout
end

local function updateCache(player, position)
    if position then
        playerCache[player.UserId] = {position = position, timestamp = now()}
    end
end

local function precisionAim()
    local bestTarget = nil
    local bestHeadPos = nil
    local bestScore = math.huge
    
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local maxRadius = math.tan(math.rad(maxFOV / 2)) * viewportSize.Y / 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then continue end
        
        local headPos
        if isCacheValid(player) then
            headPos = playerCache[player.UserId].position
        else
            headPos = advancedPrediction(player)
            updateCache(player, headPos)
        end
        
        if not headPos then continue end
        
        local screenPos = Camera:WorldToViewportPoint(headPos)
        if screenPos.Z < 0 then continue end
        
        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local distanceFromCenter = (screenPoint - center).Magnitude
        if distanceFromCenter > maxRadius then continue end

        local toTarget = (headPos - Camera.CFrame.Position)
        if toTarget.Magnitude < 1e-3 then continue end
        local lookDir = Camera.CFrame.LookVector
        local angle = math.deg(math.acos(math.clamp(lookDir:Dot(toTarget.Unit), -1, 1)))
        if angle > (maxFOV / 2) then continue end
        
        local mousePos = UserInputService:GetMouseLocation()
        local screenDistance = (screenPoint - mousePos).Magnitude
        
        local threat = calculateThreatLevel(player)
        local score = screenDistance * (1 - threat / 200)
        
        if score < bestScore then
            bestScore = score
            bestTarget = player
            bestHeadPos = headPos
        end
    end
    
    local visibilityState = nil
    if bestTarget and bestTarget.Character then
        if isTargetVisible(bestTarget) then
            visibilityState = "visible"
        else
            visibilityState = "oculto"
        end
    end
    updateNotification(visibilityState)
    
    if bestTarget and bestHeadPos and visibilityState == "visible" then
        local screenPos = Camera:WorldToViewportPoint(bestHeadPos)
        local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
        local velocity = playerData[bestTarget.UserId] and playerData[bestTarget.UserId].LastVelocity
        local speed = velocity and velocity.Magnitude or 0
        local distance = (bestHeadPos - Camera.CFrame.Position).Magnitude
        local dynamicSmoothing = math.clamp(smoothingFactor * (1 + (distance / 120)) / math.max(1, speed / 25), 0.05, 1)
        humanizeAim(targetScreenPos, dynamicSmoothing)
    end
end

local function stableLoop()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        precisionAim()
    else
        updateNotification(nil)
    end
end

local function createConfigGui()
    if configGui then
        configGui.Enabled = not configGui.Enabled
        return
    end

    configGui = Instance.new("ScreenGui")
    configGui.Name = "AimbotConfig"
    configGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    configGui.ResetOnSpawn = false
    configGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    configFrame = Instance.new("Frame")
    configFrame.Size = UDim2.new(0, 300, 0, 420)
    configFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
    configFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = configGui
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "CONFIGURACIÓN AIMBOT"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = configFrame

    local function createSlider(option, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, yPos)
        label.Text = option.name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = configFrame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 50, 0, 20)
        valueLabel.Position = UDim2.new(1, -60, 0, yPos)
        valueLabel.Text = tostring(option.value)
        valueLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextSize = 14
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = configFrame

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -20, 0, 4)
        slider.Position = UDim2.new(0, 10, 0, yPos + 25)
        slider.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        slider.BorderSizePixel = 0
        slider.Parent = configFrame
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 2)

        local sliderButton = Instance.new("TextButton")
        sliderButton.Size = UDim2.new(0, 16, 0, 16)
        sliderButton.BackgroundColor3 = Color3.new(0, 1, 0)
        sliderButton.BorderSizePixel = 0
        sliderButton.Parent = slider
        Instance.new("UICorner", sliderButton).CornerRadius = UDim.new(0, 8)
        
        local percentage = (option.value - option.min) / (option.max - option.min)
        sliderButton.Position = UDim2.new(percentage, -8, 0, -6)

        local dragging = false
        local function updateSlider(input)
            local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            sliderButton.Position = UDim2.new(relativeX, -8, 0, -6)
            local value = option.min + (option.max - option.min) * relativeX
            valueLabel.Text = string.format("%.2f", value)
            _G[option.id] = value
        end

        sliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end
    
    local options = {
        {name = "Factor de Predicción", value = predictionFactor, min = 0, max = 0.5, id = "predictionFactor"},
        {name = "FOV Máximo", value = maxFOV, min = 30, max = 180, id = "maxFOV"},
        {name = "Distancia Mínima", value = minTargetDistance, min = 0, max = 100, id = "minTargetDistance"},
        {name = "Factor de Suavizado", value = smoothingFactor, min = 0.05, max = 1, id = "smoothingFactor"},
    }

    for i, option in ipairs(options) do
        createSlider(option, 60 + (i-1) * 80)
    end
    
    local humanizeButton = Instance.new("TextButton")
    humanizeButton.Size = UDim2.new(1, -20, 0, 30)
    humanizeButton.Position = UDim2.new(0, 10, 0, 380)
    humanizeButton.Text = "Humanización: " .. (humanizationEnabled and "ON" or "OFF")
    humanizeButton.TextColor3 = Color3.new(1, 1, 1)
    humanizeButton.Font = Enum.Font.Gotham
    humanizeButton.TextSize = 14
    humanizeButton.BackgroundColor3 = humanizationEnabled and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
    humanizeButton.BorderSizePixel = 0
    humanizeButton.Parent = configFrame
    Instance.new("UICorner", humanizeButton).CornerRadius = UDim.new(0, 5)

    humanizeButton.MouseButton1Click:Connect(function()
        humanizationEnabled = not humanizationEnabled
        humanizeButton.Text = "Humanización: " .. (humanizationEnabled and "ON" or "OFF")
        humanizeButton.BackgroundColor3 = humanizationEnabled and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
    end)
end

return {
    activate = function()
        createNotification()
        if not renderStepped then
            renderStepped = RunService.RenderStepped:Connect(stableLoop)
        end
        if not keybindConnection then
            keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
                    createConfigGui()
                end
            end)
        end
        if not playerRemovingConnection then
            playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
                playerData[player.UserId] = nil
                playerCache[player.UserId] = nil
                visibilityCache[player.UserId] = nil
            end)
        end
    end,
    
    deactivate = function()
        if renderStepped then
            renderStepped:Disconnect()
            renderStepped = nil
        end
        if keybindConnection then
            keybindConnection:Disconnect()
            keybindConnection = nil
        end
        if playerRemovingConnection then
            playerRemovingConnection:Disconnect()
            playerRemovingConnection = nil
        end
        if notificationGui then
            notificationGui:Destroy()
            notificationGui = nil
        end
        if configGui then
            configGui:Destroy()
            configGui = nil
        end
        playerCache = {}
        playerData = {}
        visibilityCache = {}
    end,
    
    configure = function(options)
        if options.predictionFactor then predictionFactor = options.predictionFactor end
        if options.headOffset then headOffset = options.headOffset end
        if options.minTargetDistance then minTargetDistance = options.minTargetDistance end
        if options.maxFOV then maxFOV = options.maxFOV end
        if options.smoothingFactor then smoothingFactor = options.smoothingFactor end
    end
}
