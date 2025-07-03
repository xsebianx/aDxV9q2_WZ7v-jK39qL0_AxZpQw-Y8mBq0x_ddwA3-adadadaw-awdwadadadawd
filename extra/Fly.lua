local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Configuración
local BASE_SPEED = 40
local BOOST_SPEED = 40
local VERTICAL_SPEED = 25
local SMOOTHNESS = 0.2
local BOOST_KEY = Enum.KeyCode.LeftControl
local ACTIVATION_KEY = Enum.KeyCode.F

-- Estado del vuelo
local flyEnabled = false
local currentSpeed = BASE_SPEED
local flyVelocity = Vector3.new()
local isBoosting = false

-- Referencias
local player = Players.LocalPlayer
local character = player.Character
local rootPart = character and character:FindFirstChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlightUIScreenGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Elementos UI
local statusFrame
local flightConnection

-- Crear UI simplificada
local function createUI()
    if statusFrame then statusFrame:Destroy() end
    
    statusFrame = Instance.new("Frame")
    statusFrame.Name = "FlightStatusFrame"
    statusFrame.Size = UDim2.new(0, 280, 0, 80)
    statusFrame.Position = UDim2.new(0.5, -140, 0.05, 0)
    statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    statusFrame.BackgroundTransparency = 0.25
    statusFrame.BorderSizePixel = 0
    statusFrame.Visible = false
    statusFrame.Parent = screenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = statusFrame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
    statusLabel.Text = "VUELO ACTIVADO"
    statusLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 16
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = statusFrame

    local altitudeLabel = Instance.new("TextLabel")
    altitudeLabel.Name = "AltitudeLabel"
    altitudeLabel.Size = UDim2.new(1, 0, 0.3, 0)
    altitudeLabel.Position = UDim2.new(0, 0, 0.3, 0)
    altitudeLabel.Text = "ALTITUD: 0 u"
    altitudeLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
    altitudeLabel.Font = Enum.Font.Gotham
    altitudeLabel.TextSize = 14
    altitudeLabel.BackgroundTransparency = 1
    altitudeLabel.Parent = statusFrame

    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsFrame"
    controlsFrame.Size = UDim2.new(1, 0, 0.4, 0)
    controlsFrame.Position = UDim2.new(0, 0, 0.6, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = statusFrame

    local spaceIndicator = Instance.new("TextLabel")
    spaceIndicator.Name = "SpaceIndicator"
    spaceIndicator.Size = UDim2.new(0.45, 0, 1, 0)
    spaceIndicator.Text = "ESPACIO: SUBIR"
    spaceIndicator.TextColor3 = Color3.fromRGB(150, 255, 150)
    spaceIndicator.Font = Enum.Font.Gotham
    spaceIndicator.TextSize = 12
    spaceIndicator.BackgroundTransparency = 1
    spaceIndicator.Parent = controlsFrame

    local shiftIndicator = Instance.new("TextLabel")
    shiftIndicator.Name = "ShiftIndicator"
    shiftIndicator.Size = UDim2.new(0.45, 0, 1, 0)
    shiftIndicator.Position = UDim2.new(0.55, 0, 0, 0)
    shiftIndicator.Text = "SHIFT: BAJAR"
    shiftIndicator.TextColor3 = Color3.fromRGB(255, 150, 150)
    shiftIndicator.Font = Enum.Font.Gotham
    shiftIndicator.TextSize = 12
    shiftIndicator.BackgroundTransparency = 1
    shiftIndicator.Parent = controlsFrame
    
    return statusFrame
end

-- Crear UI inicial
statusFrame = createUI()

-- Sistema de boost
local function applyBoost()
    if isBoosting then
        currentSpeed = BOOST_SPEED + math.random(-3, 3)
    else
        currentSpeed = BASE_SPEED
    end
end

-- Función para actualizar el vuelo
local function updateFlight(dt)
    if not flyEnabled then return end

    -- Actualizar referencias del personaje
    character = player.Character
    if not character then return end
    
    rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not rootPart then return end
    
    -- Detener boost si se suelta la tecla
    if isBoosting and not UserInputService:IsKeyDown(BOOST_KEY) then
        isBoosting = false
    end
    
    applyBoost()  -- Aplicar boost si es necesario
    
    -- Actualizar altitud en UI
    if statusFrame and statusFrame.Visible then
        local altitudeLabel = statusFrame:FindFirstChild("AltitudeLabel")
        if altitudeLabel then
            local altitude = math.floor(rootPart.Position.Y)
            altitudeLabel.Text = "ALTITUD: "..altitude.." u"
        end
    end
    
    -- Obtener dirección de la cámara
    local cameraCF = camera.CFrame
    local cameraLook = cameraCF.LookVector
    local horizontalLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    
    local horizontalDirection = Vector3.new(0, 0, 0)
    
    -- Movimiento WASD
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
    
    -- Normalizar dirección
    if horizontalDirection.Magnitude > 0 then
        horizontalDirection = horizontalDirection.Unit
    end
    
    -- Control vertical
    local verticalDirection = 0
    local isAscending = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local isDescending = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    
    if isAscending then
        verticalDirection = VERTICAL_SPEED
    elseif isDescending then
        verticalDirection = -VERTICAL_SPEED
    end
    
    -- Calcular velocidad
    local targetVelocity = horizontalDirection * currentSpeed
    targetVelocity = targetVelocity + Vector3.new(0, verticalDirection, 0)
    
    -- Suavizar movimiento
    flyVelocity = flyVelocity:Lerp(targetVelocity, SMOOTHNESS)
    
    -- Aplicar movimiento con variación
    local velocityVariation = Vector3.new(
        math.random(-0.5, 0.5),
        math.random(-0.2, 0.2),
        math.random(-0.5, 0.5)
    )
    
    rootPart.Velocity = flyVelocity + velocityVariation
end

-- API para control externo
local FlyAPI = {
    isActive = function()
        return flyEnabled
    end,
    
    activate = function()
        if not flyEnabled then
            toggleFlight()
        end
    end,
    
    deactivate = function()
        if flyEnabled then
            toggleFlight()
        end
    end
}

-- Función para alternar el estado de vuelo
local function toggleFlight()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        -- Activar
        statusFrame.Visible = true
        
        -- Iniciar conexión de actualización
        flightConnection = RunService.Heartbeat:Connect(updateFlight)
    else
        -- Desactivar
        statusFrame.Visible = false
        
        -- Limpiar conexión
        if flightConnection then
            flightConnection:Disconnect()
            flightConnection = nil
        end
        
        -- Resetear velocidad
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        -- Resetear estado de boost
        isBoosting = false
        currentSpeed = BASE_SPEED
    end
end

-- Manejo de entrada (modificado para usar toggleFlight)
local function onInput(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == ACTIVATION_KEY then
        toggleFlight()
    end
    
    -- Manejar boost solo cuando el vuelo está activo
    if flyEnabled and input.KeyCode == BOOST_KEY then
        isBoosting = true
    end
end

-- Conectar evento de entrada
UserInputService.InputBegan:Connect(onInput)

-- Manejar respawn del personaje
player.CharacterAdded:Connect(function(char)
    character = char
    char:WaitForChild("Humanoid").Died:Connect(function()
        if flyEnabled then
            toggleFlight()
        end
    end)
end)

-- Devolver la API al final del script
return FlyAPI