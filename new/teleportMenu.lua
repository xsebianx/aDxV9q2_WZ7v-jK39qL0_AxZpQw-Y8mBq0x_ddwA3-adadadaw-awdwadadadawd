-- teleportMenu.lua (versión final corregida y optimizada para DrakHub)

local TeleportMenuAPI = {
    active = false,
    screenGui = nil
}

local function getSafeCFrame(model)
    if model.PrimaryPart then
        return model.PrimaryPart.CFrame
    end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            return part.CFrame
        end
    end
    return nil
end

local function showTeleportMenu()
    if TeleportMenuAPI.active then
        return
    end
    
    TeleportMenuAPI.active = true
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Limpiar GUI existente
    if TeleportMenuAPI.screenGui then
        TeleportMenuAPI.screenGui:Destroy()
        TeleportMenuAPI.screenGui = nil
    end
    
    -- Crear el GUI para el menú
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportMenuGui"
    screenGui.Parent = playerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TeleportMenuAPI.screenGui = screenGui

    -- Marco principal con diseño de neón
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 500)
    frame.Position = UDim2.new(0.5, -200, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Borde de neón animado
    local neonBorder = Instance.new("Frame")
    neonBorder.Size = UDim2.new(1, 6, 1, 6)
    neonBorder.Position = UDim2.new(0, -3, 0, -3)
    neonBorder.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    neonBorder.BorderSizePixel = 0
    neonBorder.ZIndex = 0
    neonBorder.Parent = frame
    
    local uigradient = Instance.new("UIGradient")
    uigradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 30, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255))
    })
    uigradient.Rotation = 90
    uigradient.Parent = neonBorder

    -- Animación de neón
    coroutine.wrap(function()
        while neonBorder and neonBorder.Parent do
            uigradient.Offset = Vector2.new(0, 0)
            for i = 0, 1, 0.01 do
                if not neonBorder then break end
                uigradient.Offset = Vector2.new(0, -i)
                task.wait(0.03)
            end
            for i = 0, 1, 0.01 do
                if not neonBorder then break end
                uigradient.Offset = Vector2.new(0, i-1)
                task.wait(0.03)
            end
        end
    end)()

    -- Esquinas redondeadas
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 12)
    uicorner.Parent = frame

    -- Título con efecto de texto brillante
    local titleContainer = Instance.new("Frame")
    titleContainer.Size = UDim2.new(1, 0, 0, 50)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Text = "DRAKHUB - TELEPORT"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBlack
    title.BackgroundTransparency = 1
    title.Parent = titleContainer

    -- Efecto de brillo en el título
    local titleGlow = title:Clone()
    titleGlow.TextColor3 = Color3.fromRGB(255, 50, 50)
    titleGlow.TextTransparency = 0.7
    titleGlow.ZIndex = title.ZIndex - 1
    titleGlow.Parent = titleContainer

    -- Botón de cierre con efecto hover
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    closeButton.AutoButtonColor = false
    closeButton.Parent = frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    -- Efecto hover para el botón de cierre
    closeButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(
            closeButton,
            TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}
        ):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(
            closeButton,
            TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}
        ):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        TeleportMenuAPI.deactivate()
    end)

    -- Barra de búsqueda con estilo moderno
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(1, -20, 0, 40)
    searchContainer.Position = UDim2.new(0, 10, 0, 60)
    searchContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    searchContainer.Parent = frame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchContainer
    
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 24, 0, 24)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -12)
    searchIcon.Image = "rbxassetid://3926305904"
    searchIcon.ImageRectOffset = Vector2.new(964, 324)
    searchIcon.ImageRectSize = Vector2.new(36, 36)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Parent = searchContainer
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -40, 1, 0)
    searchBox.Position = UDim2.new(0, 40, 0, 0)
    searchBox.PlaceholderText = "Buscar ubicaciones..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.BackgroundTransparency = 1
    searchBox.TextSize = 16
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchContainer

    -- Lista de contenedores con scroll
    local containerList = Instance.new("ScrollingFrame")
    containerList.Size = UDim2.new(1, -20, 0, 380)
    containerList.Position = UDim2.new(0, 10, 0, 110)
    containerList.BackgroundTransparency = 1
    containerList.ScrollBarThickness = 6
    containerList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    containerList.Parent = frame
    containerList.ScrollingDirection = Enum.ScrollingDirection.Y
    containerList.CanvasSize = UDim2.new(0, 0, 0, 0)

    -- Función para crear botones de teletransporte con efecto hover
    local function createTeleportButton(name, position, parent, offset)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 50)
        button.Position = UDim2.new(0, 0, 0, offset)
        button.Text = name
        button.TextColor3 = Color3.fromRGB(220, 220, 220)
        button.TextSize = 18
        button.Font = Enum.Font.GothamSemibold
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        button.AutoButtonColor = false
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = parent
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 15)
        padding.Parent = button
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        
        local highlight = Instance.new("Frame")
        highlight.Size = UDim2.new(1, 0, 1, 0)
        highlight.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        highlight.BackgroundTransparency = 1
        highlight.ZIndex = 2
        highlight.Parent = button
        
        local highlightCorner = buttonCorner:Clone()
        highlightCorner.Parent = highlight
        
        -- Efecto hover
        button.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(
                button,
                TweenInfo.new(0.2),
                {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}
            ):Play()
            game:GetService("TweenService"):Create(
                highlight,
                TweenInfo.new(0.2),
                {BackgroundTransparency = 0.8}
            ):Play()
        end)
        
        button.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(
                button,
                TweenInfo.new(0.2),
                {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}
            ):Play()
            game:GetService("TweenService"):Create(
                highlight,
                TweenInfo.new(0.2),
                {BackgroundTransparency = 1}
            ):Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            -- Efecto de clic
            game:GetService("TweenService"):Create(
                highlight,
                TweenInfo.new(0.1),
                {BackgroundTransparency = 0.5}
            ):Play()
            game:GetService("TweenService"):Create(
                highlight,
                TweenInfo.new(0.1),
                {BackgroundTransparency = 0.8}
            ):Play()
            
            -- Teletransporte seguro
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    player.Character.HumanoidRootPart.CFrame = position
                end)
            end
        end)
        
        return button
    end

    -- Actualizar la lista de contenedores
    local function updateContainerList(filter)
        for _, child in pairs(containerList:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local offset = 0
        local containerFolder = workspace:FindFirstChild("Interactable")
        containerFolder = containerFolder and containerFolder:FindFirstChild("Containers") or workspace:FindFirstChild("Containers")
        
        if containerFolder then
            for _, container in pairs(containerFolder:GetChildren()) do
                if container:IsA("Model") then
                    local position = getSafeCFrame(container)
                    if not position then
                        warn("No se pudo obtener posición para: "..container.Name)
                        continue
                    end
                    
                    if not filter or string.find(container.Name:lower(), filter:lower()) then
                        local button = createTeleportButton(container.Name, position, containerList, offset)
                        offset = offset + 55
                    end
                end
            end
        end
        
        -- Mostrar mensaje si no hay contenedores
        if offset == 0 then
            local message = Instance.new("TextLabel")
            message.Size = UDim2.new(1, 0, 0, 50)
            message.Text = "No se encontraron contenedores"
            message.TextColor3 = Color3.fromRGB(200, 200, 200)
            message.BackgroundTransparency = 1
            message.Parent = containerList
            offset = offset + 55
        end
        
        containerList.CanvasSize = UDim2.new(0, 0, 0, offset)
    end

    -- Botón de actualización
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 100, 0, 30)
    refreshButton.Position = UDim2.new(0.5, -50, 1, -40)
    refreshButton.Text = "Actualizar"
    refreshButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    refreshButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    refreshButton.TextSize = 16
    refreshButton.Font = Enum.Font.GothamMedium
    refreshButton.Parent = frame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton
    
    refreshButton.MouseButton1Click:Connect(function()
        updateContainerList(searchBox.Text)
    end)

    updateContainerList()
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        updateContainerList(searchBox.Text)
    end)

    -- Hacer el marco arrastrable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    frame.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

TeleportMenuAPI.activate = function()
    if not TeleportMenuAPI.active then
        showTeleportMenu()
    else
        -- Si ya está activo, solo traer al frente
        if TeleportMenuAPI.screenGui then
            TeleportMenuAPI.screenGui.Enabled = true
        end
    end
end

TeleportMenuAPI.deactivate = function()
    if TeleportMenuAPI.active then
        TeleportMenuAPI.active = false
        if TeleportMenuAPI.screenGui then
            TeleportMenuAPI.screenGui:Destroy()
            TeleportMenuAPI.screenGui = nil
        end
    end
end

TeleportMenuAPI.isActive = function()
    return TeleportMenuAPI.active
end

-- IMPORTANTE: Retornar la API para que funcione con el loader
return TeleportMenuAPI
