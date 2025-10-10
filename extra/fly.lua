-- fly.txt
-- ADVERTENCIA: Este script proporciona ventajas de movimiento que pueden ser consideradas trampas.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de scripting en Lua.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- === CONFIGURACIÓN (AJUSTABLE DESDE EL MENÚ F3) ===
local BASE_SPEED = 40
local BOOST_SPEED = 80
local VERTICAL_SPEED = 25
local ACCELERATION = 50 -- Unidades/segundo^2 para la aceleración suave
local BODY_MOVER_P = 5000 -- Potencia de los BodyMovers (más alto = más rígido)

-- === TECLAS ===
local BOOST_KEY = Enum.KeyCode.LeftControl
local NOCLIP_KEY = Enum.KeyCode.N
local CONFIG_KEY = Enum.KeyCode.F3

-- === ESTADO DEL VUELO ===
local flyEnabled = false
local isBoosting = false
local noClipEnabled = false
local currentSpeed = 0
local targetSpeed = BASE_SPEED

-- === REFERENCIAS ===
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- === COMPONENTES DE FÍSICA ===
local bodyVelocity
local bodyGyro

-- === UI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlightUIScreenGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local statusFrame
local speedFill
local noClipLabel

-- === CONEXIONES ===
local flightConnection
local characterAddedConnection
local inputBeganConnection

-- === SISTEMA DE NO-CLIP (MANUAL) ===
local function setNoClip(enabled)
    noClipEnabled = enabled
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
            end
        end
    end
    if noClipLabel then
        noClipLabel.Text = "NO-CLIP: " .. (enabled and "ON" or "OFF")
        noClipLabel.TextColor3 = enabled and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(150, 150, 150)
    end
end

-- === CREAR UI MEJORADA ===
local function createUI()
    if statusFrame then statusFrame:Destroy() end
    
    statusFrame = Instance.new("Frame")
    statusFrame.Name = "FlightStatusFrame"
    statusFrame.Size = UDim2.new(0, 280, 0, 100)
    statusFrame.Position = UDim2.new(0.5, -140, 0.05, 0)
    statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    statusFrame.BackgroundTransparency = 0.25
    statusFrame.BorderSizePixel = 0
    statusFrame.Visible = false
    statusFrame.Parent = screenGui

    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 12)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 5)
    statusLabel.Text = "VUELO ACTIVADO"
    statusLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 16
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = statusFrame

    local altitudeLabel = Instance.new("TextLabel")
    altitudeLabel.Name = "AltitudeLabel"
    altitudeLabel.Size = UDim2.new(1, 0, 0, 20)
    altitudeLabel.Position = UDim2.new(0, 0, 0, 30)
    altitudeLabel.Text = "ALTITUD: 0 u"
    altitudeLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
    altitudeLabel.Font = Enum.Font.Gotham
    altitudeLabel.TextSize = 14
    altitudeLabel.BackgroundTransparency = 1
    altitudeLabel.Parent = statusFrame

    -- Barra de velocidad
    local speedBarFrame = Instance.new("Frame")
    speedBarFrame.Size = UDim2.new(0.8, 0, 0, 8)
    speedBarFrame.Position = UDim2.new(0.1, 0, 0.55, 0)
    speedBarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    speedBarFrame.BorderSizePixel = 0
    speedBarFrame.Parent = statusFrame
    Instance.new("UICorner", speedBarFrame).CornerRadius = UDim.new(0, 4)

    speedFill = Instance.new("Frame")
    speedFill.Name = "SpeedFill"
    speedFill.Size = UDim2.new(0, 0, 1, 0)
    speedFill.Position = UDim2.new(0, 0, 0, 0)
    speedFill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    speedFill.BorderSizePixel = 0
    speedFill.Parent = speedBarFrame
    Instance.new("UICorner", speedFill).CornerRadius = UDim.new(0, 4)

    -- Indicador de No-Clip
    noClipLabel = Instance.new("TextLabel")
    noClipLabel.Name = "NoClipLabel"
    noClipLabel.Size = UDim2.new(1, 0, 0, 20)
    noClipLabel.Position = UDim2.new(0, 0, 0.75, 0)
    noClipLabel.Text = "NO-CLIP: OFF"
    noClipLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    noClipLabel.Font = Enum.Font.Gotham
    noClipLabel.TextSize = 12
    noClipLabel.BackgroundTransparency = 1
    noClipLabel.Parent = statusFrame
    
    return statusFrame
end

-- === FUNCIÓN PRINCIPAL DE VUELO (CORREGIDA PARA COLISIONES) ===
local function updateFlight(dt)
    if not flyEnabled or not rootPart or not bodyVelocity or not bodyGyro then return end

    -- Actualizar referencias del personaje por si respawn
    character = player.Character
    if not character then return end
    rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Lógica de boost
    if isBoosting and not UserInputService:IsKeyDown(BOOST_KEY) then
        isBoosting = false
    end
    targetSpeed = isBoosting and BOOST_SPEED or BASE_SPEED

    -- Sistema de aceleración suave
    if currentSpeed < targetSpeed then
        currentSpeed = math.min(currentSpeed + ACCELERATION * dt, targetSpeed)
    elseif currentSpeed > targetSpeed then
        currentSpeed = math.max(currentSpeed - ACCELERATION * dt, targetSpeed)
    end
    
    -- Actualizar UI
    if statusFrame and statusFrame.Visible then
        local altitudeLabel = statusFrame:FindFirstChild("AltitudeLabel")
        if altitudeLabel then
            altitudeLabel.Text = "ALTITUD: " .. math.floor(rootPart.Position.Y) .. " u"
        end
        if speedFill then
            local speedPercentage = currentSpeed / BOOST_SPEED
            speedFill:TweenSize(UDim2.new(speedPercentage, 0, 1, 0), "Out", "Quad", 0.1, true)
        end
    end
    
    -- Calcular dirección de movimiento
    local cameraCF = camera.CFrame
    local cameraLook = cameraCF.LookVector
    local horizontalLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    local horizontalDirection = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then horizontalDirection += horizontalLook end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then horizontalDirection -= horizontalLook end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then horizontalDirection -= cameraCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then horizontalDirection += cameraCF.RightVector end
    
    -- Control vertical
    local verticalDirection = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then verticalDirection = VERTICAL_SPEED end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then verticalDirection = -VERTICAL_SPEED end
    
    -- Aplicar movimiento de forma más inteligente para evitar bugs de colisión
    local targetVelocity
    if horizontalDirection.Magnitude > 0 then
        horizontalDirection = horizontalDirection.Unit
        targetVelocity = horizontalDirection * currentSpeed + Vector3.new(0, verticalDirection, 0)
    else
        targetVelocity = Vector3.new(0, verticalDirection, 0)
    end
    
    -- Aplicar la velocidad calculada con BodyMovers
    bodyVelocity.Velocity = targetVelocity
    bodyGyro.CFrame = cameraCF -- Mantiene al personaje orientado a la cámara
end

-- === FUNCIÓN PARA ACTIVAR/DESACTIVAR EL VUELO (VERSIÓN FINAL) ===
local function toggleFlight()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        -- Activar
        statusFrame.Visible = true
        
        -- Crear BodyMovers
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.P = BODY_MOVER_P
        bodyVelocity.Parent = rootPart
        
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = BODY_MOVER_P
        bodyGyro.CFrame = camera.CFrame
        bodyGyro.Parent = rootPart

        -- Iniciar loop
        if not flightConnection then
            flightConnection = RunService.Heartbeat:Connect(updateFlight)
        end
    else
        -- Desactivar
        statusFrame.Visible = false
        
        -- <<< INICIO DE LA DESACTIVACIÓN FINAL Y CORREGIDA >>>
        
        -- 1. Destruir los BodyMovers para devolver el control al Humanoid
        if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end

        -- 2. ASEGURARSE DE QUE EL NO-CLIP ESTÉ DESACTIVADO AL ATERRIZAR
        -- Esto es crucial para que el personaje no quede flotando si el usuario lo activó manualmente.
        if noClipEnabled then
            setNoClip(false)
        end
        
        -- <<< FIN DE LA DESACTIVACIÓN FINAL Y CORREGIDA >>>
        
        -- Limpiar conexión y resetear estado
        if flightConnection then
            flightConnection:Disconnect()
            flightConnection = nil
        end
        isBoosting = false
        currentSpeed = 0
    end
end

-- === MENÚ DE CONFIGURACIÓN ===
local configGui, configFrame
local function createConfigGui()
    if configGui then
        configGui.Enabled = not configGui.Enabled
        return
    end

    configGui = Instance.new("ScreenGui")
    configGui.Name = "FlyConfigGui"
    configGui.Parent = player:WaitForChild("PlayerGui")
    configGui.ResetOnSpawn = false
    configGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    configFrame = Instance.new("Frame")
    configFrame.Size = UDim2.new(0, 300, 0, 350)
    configFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    configFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = configGui
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "CONFIGURACIÓN DE VUELO"
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
            valueLabel.Text = string.format("%.0f", value)
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
        {name = "Velocidad Base", value = BASE_SPEED, min = 10, max = 200, id = "BASE_SPEED"},
        {name = "Velocidad de Boost", value = BOOST_SPEED, min = 20, max = 400, id = "BOOST_SPEED"},
        {name = "Velocidad Vertical", value = VERTICAL_SPEED, min = 10, max = 100, id = "VERTICAL_SPEED"},
        {name = "Aceleración", value = ACCELERATION, min = 10, max = 200, id = "ACCELERATION"},
    }

    for i, option in ipairs(options) do
        createSlider(option, 60 + (i-1) * 70)
    end
end

-- === MANEJO DE ENTRADA ===
local function onInput(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == BOOST_KEY and flyEnabled then
        isBoosting = true
    end
    if input.KeyCode == NOCLIP_KEY and flyEnabled then
        -- El no-clip sigue siendo un toggle manual durante el vuelo
        setNoClip(not noClipEnabled)
    end
    if input.KeyCode == CONFIG_KEY then
        createConfigGui()
    end
end

-- === GESTIÓN DE PERSONAJE (RESPAWN) ===
local function onCharacterAdded(char)
    character = char
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    -- Si el vuelo estaba activo, reactivarlo para el nuevo personaje
    if flyEnabled then
        -- Desactivar y reactivar para que se re-configure todo
        flyEnabled = false -- Engañar a la función para que entre en modo de activación
        toggleFlight()
    end
end

-- === API PARA CONTROL EXTERNO ===
local FlyAPI = {
    isActive = function() return flyEnabled end,
    activate = function()
        if not flyEnabled then toggleFlight() end
        -- Conectar eventos
        if not inputBeganConnection then
            inputBeganConnection = UserInputService.InputBegan:Connect(onInput)
        end
        if not characterAddedConnection then
            characterAddedConnection = player.CharacterAdded:Connect(onCharacterAdded)
        end
    end,
    deactivate = function()
        if flyEnabled then toggleFlight() end
        -- Desconectar eventos
        if inputBeganConnection then
            inputBeganConnection:Disconnect()
            inputBeganConnection = nil
        end
        if characterAddedConnection then
            characterAddedConnection:Disconnect()
            characterAddedConnection = nil
        end
        if configGui then
            configGui:Destroy()
            configGui = nil
        end
    end
}

-- Cargar configuración desde _G si existe
task.spawn(function()
    while true do
        if _G.BASE_SPEED then BASE_SPEED = _G.BASE_SPEED end
        if _G.BOOST_SPEED then BOOST_SPEED = _G.BOOST_SPEED end
        if _G.VERTICAL_SPEED then VERTICAL_SPEED = _G.VERTICAL_SPEED end
        if _G.ACCELERATION then ACCELERATION = _G.ACCELERATION end
        task.wait(1)
    end
end)


-- Inicializar UI
createUI()

-- Devolver la API
return FlyAPI
