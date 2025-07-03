local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Configuración optimizada
local BASE_SPEED = 30
local BOOST_SPEED = 65
local VERTICAL_SPEED = 25
local SMOOTHNESS = 0.2
local BOOST_KEY = Enum.KeyCode.LeftShift

-- Variables de estado
local flyEnabled = false
local isBoosting = false
local isAscending = false
local isDescending = false
local flyVelocity = Vector3.new(0, 0, 0)
local currentSpeed = BASE_SPEED
local flightConnection = nil
local inputConnection = nil
local screenGui = nil
local statusFrame = nil

-- API de vuelo mejorada
local FlyAPI = {
    active = false,
    
    activate = function()
        if FlyAPI.active then return end
        FlyAPI.active = true
        flyEnabled = true
        
        -- Obtener LocalPlayer con verificación en tiempo real
        local player = Players.LocalPlayer
        while not player do
            task.wait(0.1)
            player = Players.LocalPlayer
        end
        
        -- Crear interfaz si no existe
        if not screenGui then
            screenGui = Instance.new("ScreenGui")
            screenGui.Parent = player:WaitForChild("PlayerGui")
            screenGui.Name = "FlightStatus"
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

            statusFrame = Instance.new("Frame")
            statusFrame.Size = UDim2.new(0, 280, 0, 80)
            statusFrame.Position = UDim2.new(0.5, -140, 0.05, 0)
            statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            statusFrame.BackgroundTransparency = 0.25
            statusFrame.BorderSizePixel = 0
            statusFrame.Visible = true
            statusFrame.Parent = screenGui

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 12)
            UICorner.Parent = statusFrame

            local statusLabel = Instance.new("TextLabel")
            statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
            statusLabel.Text = "VUELO ACTIVADO"
            statusLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
            statusLabel.Font = Enum.Font.GothamBold
            statusLabel.TextSize = 16
            statusLabel.BackgroundTransparency = 1
            statusLabel.Parent = statusFrame

            local altitudeLabel = Instance.new("TextLabel")
            altitudeLabel.Size = UDim2.new(1, 0, 0.3, 0)
            altitudeLabel.Position = UDim2.new(0, 0, 0.3, 0)
            altitudeLabel.Text = "ALTITUD: 0 u"
            altitudeLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
            altitudeLabel.Font = Enum.Font.Gotham
            altitudeLabel.TextSize = 14
            altitudeLabel.BackgroundTransparency = 1
            altitudeLabel.Parent = statusFrame

            local controlsFrame = Instance.new("Frame")
            controlsFrame.Size = UDim2.new(1, 0, 0.4, 0)
            controlsFrame.Position = UDim2.new(0, 0, 0.6, 0)
            controlsFrame.BackgroundTransparency = 1
            controlsFrame.Parent = statusFrame

            local spaceIndicator = Instance.new("TextLabel")
            spaceIndicator.Size = UDim2.new(0.45, 0, 1, 0)
            spaceIndicator.Text = "ESPACIO: SUBIR"
            spaceIndicator.TextColor3 = Color3.fromRGB(150, 255, 150)
            spaceIndicator.Font = Enum.Font.Gotham
            spaceIndicator.TextSize = 12
            spaceIndicator.BackgroundTransparency = 1
            spaceIndicator.Parent = controlsFrame

            local shiftIndicator = Instance.new("TextLabel")
            shiftIndicator.Size = UDim2.new(0.45, 0, 1, 0)
            shiftIndicator.Position = UDim2.new(0.55, 0, 0, 0)
            shiftIndicator.Text = "SHIFT: BAJAR"
            shiftIndicator.TextColor3 = Color3.fromRGB(255, 150, 150)
            shiftIndicator.Font = Enum.Font.Gotham
            shiftIndicator.TextSize = 12
            shiftIndicator.BackgroundTransparency = 1
            shiftIndicator.Parent = controlsFrame
        else
            statusFrame.Visible = true
        end
        
        -- Iniciar conexiones
        flightConnection = RunService.Heartbeat:Connect(updateFlight)
        inputConnection = UserInputService.InputBegan:Connect(onInput)
    end,
    
    deactivate = function()
        if not FlyAPI.active then return end
        FlyAPI.active = false
        flyEnabled = false
        
        -- Limpiar conexiones
        if flightConnection then
            flightConnection:Disconnect()
            flightConnection = nil
        end
        
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
        
        -- Ocultar interfaz
        if statusFrame then
            statusFrame.Visible = false
        end
        
        -- Restablecer la velocidad del personaje
        local player = Players.LocalPlayer
        if player and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end
}

-- Sistema de boost mejorado con variabilidad
local function applyBoost()
    if not isBoosting then return end
    
    -- Aplicar boost con variación aleatoria para evitar detección
    local variation = math.random(-3, 3)
    local targetSpeed = BOOST_SPEED + variation
    
    -- Transición suave
    TweenService:Create(script, TweenInfo.new(0.3), {
        currentSpeed = targetSpeed
    }):Play()
end

-- Manejo de entrada de usuario
local function onInput(input, gameProcessed)
    if gameProcessed then return end
    
    -- Manejar boost con variabilidad
    if input.KeyCode == BOOST_KEY then
        isBoosting = true
        applyBoost()
    end
end

-- Función para actualizar el vuelo
local function updateFlight(dt)
    if not flyEnabled then return end

    local player = Players.LocalPlayer
    if not player or not player.Character then return end

    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Detener boost si se suelta la tecla
    if isBoosting and not UserInputService:IsKeyDown(BOOST_KEY) then
        isBoosting = false
        currentSpeed = BASE_SPEED
    end
    
    -- Obtener dirección de la cámara
    local cameraCF = Camera.CFrame
    local cameraLook = cameraCF.LookVector
    local horizontalLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    
    local horizontalDirection = Vector3.new(0, 0, 0)
    
    -- Control de movimiento horizontal
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        horizontalDirection = horizontalDirection + horizontalLook
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        horizontalDirection = horizontalDirection - horizontalLook
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        horizontalDirection = horizontalDirection - cameraCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        horizontalDirection = horizontalDirection + cameraCF.RightVector
    end
    
    -- Normalizar dirección horizontal
    if horizontalDirection.Magnitude > 0 then
        horizontalDirection = horizontalDirection.Unit
    end
    
    -- Control vertical manual
    local verticalDirection = 0
    isAscending = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    isDescending = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    
    if isAscending then
        verticalDirection = VERTICAL_SPEED
    elseif isDescending then
        verticalDirection = -VERTICAL_SPEED
    end
    
    -- Calcular velocidad objetivo
    local targetVelocity = horizontalDirection * currentSpeed
    targetVelocity = targetVelocity + Vector3.new(0, verticalDirection, 0)
    
    -- Suavizar el movimiento
    flyVelocity = flyVelocity:Lerp(targetVelocity, SMOOTHNESS)
    
    -- Aplicar movimiento con variación aleatoria
    local velocityVariation = Vector3.new(
        math.random(-0.5, 0.5),
        math.random(-0.2, 0.2),
        math.random(-0.5, 0.5)
    )
    
    rootPart.Velocity = flyVelocity + velocityVariation
end

return FlyAPI