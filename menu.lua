--[[
    DRAKHUB PREMIUM v3.2
    Versión final con correcciones y optimizaciones
]]

-- Servicios
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Variables globales
local localPlayer = Players.LocalPlayer
local gui, mainFrame
local activeScripts = {}
local buttonStates = {}
local minimized = false
local notificationQueue = {}
local isShowingNotification = false

-- CONFIGURACIÓN PRINCIPAL -----------------------------------------------------
local CONFIG = {
    MainColor = Color3.fromRGB(15, 15, 15),
    AccentColor = Color3.fromRGB(220, 20, 20),
    TextColor = Color3.fromRGB(245, 245, 245),
    ButtonColors = {
        Home = Color3.fromRGB(255, 193, 7),
        Combat = Color3.fromRGB(220, 20, 60),
        Visual = Color3.fromRGB(30, 136, 229),
        New = Color3.fromRGB(46, 204, 113),
        Extra = Color3.fromRGB(255, 143, 0)
    },
    ShadowIntensity = 0.6,
    AnimationSpeed = 0.25,
    ScriptBaseURL = "https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/main/"
}

-- CÓDIGO DEL TELEPORT MENU INTEGRADO ------------------------------------------
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

-- FUNCIÓN createElement CORREGIDA ---------------------------------------------
local function createElement(className, properties)
    local element = Instance.new(className)
    
    for prop, value in pairs(properties) do
        if prop ~= "Parent" and prop ~= "Gradient" then
            if element[prop] ~= nil then
                element[prop] = value
            end
        end
    end
    
    -- Manejo especial para gradientes
    if properties.Gradient then
        local gradient = Instance.new("UIGradient")
        for gprop, gvalue in pairs(properties.Gradient) do
            if gradient[gprop] ~= nil then
                gradient[gprop] = gvalue
            end
        end
        gradient.Parent = element
    end
    
    if properties.Parent then
        element.Parent = properties.Parent
    end
    
    return element
end

local function createShadow(parent, sizeMultiplier)
    sizeMultiplier = sizeMultiplier or 20
    return createElement("ImageLabel", {
        Name = "Shadow",
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = CONFIG.ShadowIntensity,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, sizeMultiplier, 1, sizeMultiplier),
        Position = UDim2.new(0, -sizeMultiplier/2, 0, -sizeMultiplier/2),
        BackgroundTransparency = 1,
        ZIndex = -1,
        Parent = parent
    })
end

-- FUNCIÓN createButton CORREGIDA ----------------------------------------------
local function createButton(name, text, position, color, hoverColor)
    local button = createElement("TextButton", {
        Name = name,
        Text = "   " .. text,  -- Espacios para simular padding izquierdo
        Font = Enum.Font.GothamSemibold,
        TextSize = 18,
        TextColor3 = CONFIG.TextColor,
        BackgroundColor3 = color,
        Size = UDim2.new(0, 120, 0, 40),
        Position = position,
        AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left  -- Texto alineado a la izquierda
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = button
    })
    
    createElement("UIStroke", {
        Color = Color3.new(0.1, 0.1, 0.1),
        Thickness = 1.5,
        Parent = button
    })
    
    local icon = createElement("ImageLabel", {
        Name = "Icon",
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0.5, -10),
        BackgroundTransparency = 1,
        Parent = button
    })
    
    button.MouseEnter:Connect(function()
        TS:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
        TS:Create(icon, TweenInfo.new(0.15), {ImageColor3 = Color3.new(1, 1, 1)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        TS:Create(icon, TweenInfo.new(0.2), {ImageColor3 = CONFIG.TextColor}):Play()
    end)
    
    return button
end

-- FRAME DE CATEGORÍA CON SCROLLING --------------------------------------------
local function createCategoryFrame(name, position, color)
    local frame = createElement("Frame", {
        Name = name,
        BackgroundColor3 = Color3.new(0.12, 0.12, 0.12),
        Size = UDim2.new(0, 450, 0, 300),
        Position = position,
        Visible = false,
        ClipsDescendants = true,
        BackgroundTransparency = 0.95
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = frame
    })
    
    createElement("UIStroke", {
        Color = color,
        Thickness = 2,
        Parent = frame
    })
    
    createShadow(frame, 25)
    
    local scrollFrame = createElement("ScrollingFrame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = color,
        Parent = frame
    })
    
    -- Layout para los botones
    createElement("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame
    })
    
    return frame, scrollFrame
end

-- BOTÓN DE CARACTERÍSTICA CON DESPLAZAMIENTO ----------------------------------
local function createFeatureButton(parent, name, text, color)
    local button = createElement("TextButton", {
        Name = name,
        Text = "   " .. text,  -- Espacios para simular padding
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = CONFIG.TextColor,
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 45),
        AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left,  -- Alineación izquierda
        Parent = parent
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = button
    })
    
    createElement("UIStroke", {
        Color = Color3.new(0.15, 0.15, 0.15),
        Thickness = 1.5,
        Parent = button
    })
    
    local hoverColor = Color3.new(
        math.min(color.R * 1.3, 1),
        math.min(color.G * 1.3, 1),
        math.min(color.B * 1.3, 1)
    )
    
    local statusIndicator = createElement("Frame", {
        Name = "Status",
        BackgroundColor3 = Color3.fromRGB(150, 40, 40),
        Size = UDim2.new(0, 8, 0.7, 0),
        Position = UDim2.new(1, -15, 0.15, 0),
        AnchorPoint = Vector2.new(1, 0),
        Parent = button
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = statusIndicator
    })
    
    button.MouseEnter:Connect(function()
        TS:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return button, statusIndicator
end

-- NOTIFICACIONES MEJORADAS ---------------------------------------------------
local function showNotification(message, color)
    if isShowingNotification then
        table.insert(notificationQueue, {message, color})
        return
    end
    
    isShowingNotification = true
    local notif = createElement("TextLabel", {
        Name = "Notification",
        Text = message,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = CONFIG.TextColor,
        BackgroundColor3 = color or CONFIG.AccentColor,
        Size = UDim2.new(0, 300, 0, 50),
        Position = UDim2.new(0.5, -150, 1, 60),
        AnchorPoint = Vector2.new(0.5, 0)
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = notif
    })
    
    createElement("UIStroke", {
        Color = Color3.new(0.1, 0.1, 0.1),
        Thickness = 2,
        Parent = notif
    })
    
    createShadow(notif, 20)
    
    notif.Parent = gui
    
    -- Animación de entrada
    local enterTween = TS:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -150, 1, -70)
    })
    
    enterTween:Play()
    task.wait(2)
    
    -- Animación de salida
    local exitTween = TS:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -150, 1, 60)
    })
    
    exitTween:Play()
    exitTween.Completed:Wait()
    
    notif:Destroy()
    isShowingNotification = false
    
    -- Procesar siguiente notificación
    if #notificationQueue > 0 then
        local nextNotif = table.remove(notificationQueue, 1)
        showNotification(nextNotif[1], nextNotif[2])
    end
end

-- CARGA DE SCRIPTS CORREGIDA CON RESPALDO PARA TELEPORTMENU -------------------
local function loadScript(category, scriptName)
    local url = CONFIG.ScriptBaseURL..category:lower().."/"..scriptName:lower()..".lua"
    
    print("[DRAKHUB] Intentando cargar script: "..url)
    
    local success, result = pcall(function()
        -- Intento 1: Usar loadstring
        local httpContent = game:HttpGet(url, true)  -- true para reintentos
        local loadedFunction, errorMsg = loadstring(httpContent)
        
        if loadedFunction then
            return loadedFunction()
        else
            error(errorMsg or "Error en loadstring")
        end
    end)
    
    if success then
        -- Verificar que el script devuelve una API válida
        if type(result) == "table" and result.activate then
            activeScripts[scriptName] = result
            showNotification(scriptName.." cargado", Color3.fromRGB(46, 204, 113))
            return true
        else
            -- Si es TeleportMenu, intentamos el respaldo local
            if scriptName == "TeleportMenu" then
                warn("El script TeleportMenu no devolvió una API válida, usando respaldo local")
                activeScripts[scriptName] = TeleportMenuAPI
                showNotification("TeleportMenu (local) cargado", Color3.fromRGB(46, 204, 113))
                return true
            else
                showNotification(scriptName..": API inválida", Color3.fromRGB(231, 76, 60))
                warn("El script "..scriptName.." no devolvió una API válida")
                return false
            end
        end
    else
        -- Manejo de errores de carga
        warn("Error cargando "..scriptName..": "..tostring(result))
        
        -- Respaldo específico para TeleportMenu
        if scriptName == "TeleportMenu" then
            warn("Usando respaldo local para TeleportMenu")
            activeScripts[scriptName] = TeleportMenuAPI
            showNotification("TeleportMenu (local) cargado", Color3.fromRGB(46, 204, 113))
            return true
        end
        
        showNotification("Error: "..scriptName, Color3.fromRGB(231, 76, 60))
        return false
    end
end

-- CONSTRUCCIÓN DE LA UI -------------------------------------------------------
local function createMainUI()
    -- Crear GUI principal
    gui = createElement("ScreenGui", {
        Name = "DrakHubPremium",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = localPlayer:WaitForChild("PlayerGui")
    })
    
    -- Marco principal
    mainFrame = createElement("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = CONFIG.MainColor,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Active = true,
        Draggable = true,
        Parent = gui
    })
    
    -- Efecto de vidrio
    createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0.95,
        Active = false,
        Parent = mainFrame
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = mainFrame
    })
    
    createElement("UIStroke", {
        Color = CONFIG.AccentColor,
        Thickness = 2.5,
        Parent = mainFrame
    })
    
    createShadow(mainFrame, 30)
    
    -- Cabecera
    local header = createElement("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 0.8,
        Parent = mainFrame
    })
    
    createElement("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.AccentColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 20))
        }),
        Parent = header
    })
    
    -- Título
    createElement("TextLabel", {
        Name = "Title",
        Text = "DRΛKHUB PREMIUM",
        Font = Enum.Font.GothamBlack,
        TextSize = 20,
        TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0.8,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = header
    })
    
    -- Separador
    createElement("Frame", {
        Name = "Separator",
        BackgroundColor3 = CONFIG.AccentColor,
        Size = UDim2.new(1, -40, 0, 2),
        Position = UDim2.new(0, 20, 0, 50),
        Parent = mainFrame
    })
    
    -- Botones de categoría
    local categories = {
        {name = "Home", text = "INICIO", pos = UDim2.new(0, 10, 0, 60)},
        {name = "Combat", text = "COMBATE", pos = UDim2.new(0, 10, 0, 110)},
        {name = "Visual", text = "VISUAL", pos = UDim2.new(0, 10, 0, 160)},
        {name = "New", text = "NUEVO", pos = UDim2.new(0, 10, 0, 210)},
        {name = "Extra", text = "EXTRA", pos = UDim2.new(0, 10, 0, 260)}
    }
    
    local categoryButtons = {}
    for _, cat in ipairs(categories) do
        categoryButtons[cat.name] = createButton(
            cat.name.."Button",
            cat.text,
            cat.pos,
            CONFIG.ButtonColors[cat.name],
            Color3.new(
                math.min(CONFIG.ButtonColors[cat.name].R * 1.3, 1),
                math.min(CONFIG.ButtonColors[cat.name].G * 1.3, 1),
                math.min(CONFIG.ButtonColors[cat.name].B * 1.3, 1)
            )
        )
        categoryButtons[cat.name].Parent = mainFrame
    end
    
    -- Frames de categoría con desplazamiento
    local categoryFrames = {}
    local contentFrames = {}
    local frameInfo = {
        {name = "Combat", color = CONFIG.ButtonColors.Combat},
        {name = "Visual", color = CONFIG.ButtonColors.Visual},
        {name = "New", color = CONFIG.ButtonColors.New},
        {name = "Extra", color = CONFIG.ButtonColors.Extra}
    }
    
    for _, info in ipairs(frameInfo) do
        local frame, content = createCategoryFrame(
            info.name.."Frame",
            UDim2.new(0, 140, 0, 60),
            info.color
        )
        frame.Parent = mainFrame
        categoryFrames[info.name] = frame
        contentFrames[info.name] = content
    end
    
    -- PANTALLA DE BIENVENIDA MEJORADA SIN BOTÓN DE ACCESO RÁPIDO --------------
    local welcomeFrame = createElement("Frame", {
        Name = "WelcomeFrame",
        BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
        Size = UDim2.new(0, 450, 0, 300),
        Position = UDim2.new(0, 140, 0, 60),
        Parent = mainFrame
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = welcomeFrame
    })
    
    createElement("UIStroke", {
        Color = CONFIG.AccentColor,
        Thickness = 2,
        Parent = welcomeFrame
    })
    
    createShadow(welcomeFrame, 25)
    
    -- Logo central
    local logo = createElement("ImageLabel", {
        Image = "rbxassetid://3926305904", -- Icono de Roblox
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0.5, -40, 0.2, -40),
        BackgroundTransparency = 1,
        ImageColor3 = CONFIG.AccentColor,
        Parent = welcomeFrame
    })
    
    -- Título mejorado
    createElement("TextLabel", {
        Name = "WelcomeText",
        Text = "BIENVENIDO A DRΛKHUB",
        Font = Enum.Font.GothamBlack,
        TextSize = 26,
        TextColor3 = CONFIG.TextColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0.4, 0),
        Parent = welcomeFrame
    })
    
    -- Versión
    createElement("TextLabel", {
        Text = "VERSIÓN PREMIUM v3.2",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = CONFIG.AccentColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0.5, 0),
        Parent = welcomeFrame
    })
    
    -- Descripción
    createElement("TextLabel", {
        Text = "El hub más completo para mejorar tu experiencia de juego",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0.6, 0),
        Parent = welcomeFrame
    })
    
    -- Estadísticas (simuladas)
    local statsFrame = createElement("Frame", {
        Size = UDim2.new(0.8, 0, 0, 60),
        Position = UDim2.new(0.1, 0, 0.7, 0),
        BackgroundTransparency = 1,
        Parent = welcomeFrame
    })
    
    local stats = {
        {text = "SCRIPTS: 8", color = CONFIG.ButtonColors.Combat},
        {text = "ACTIVOS: 0", color = CONFIG.ButtonColors.Visual},
        {text = "USUARIOS: 1", color = CONFIG.ButtonColors.New}
    }
    
    for i, stat in ipairs(stats) do
        local posX = (i-1) * 0.33
        createElement("TextLabel", {
            Text = stat.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = stat.color,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.33, 0, 1, 0),
            Position = UDim2.new(posX, 0, 0, 0),
            Parent = statsFrame
        })
    end
    
    return categoryButtons, categoryFrames, contentFrames, welcomeFrame
end

-- CONFIGURACIÓN DE FUNCIONALIDADES CORREGIDA ----------------------------------
local function setupCategorySwitching(categoryButtons, categoryFrames, welcomeFrame)
    for name, button in pairs(categoryButtons) do
        button.MouseButton1Click:Connect(function()
            -- Ocultar todos los frames de categoría
            for _, frame in pairs(categoryFrames) do
                frame.Visible = false
            end
            
            -- Ocultar también la pantalla de bienvenida
            welcomeFrame.Visible = false
            
            if name == "Home" then
                welcomeFrame.Visible = true
            else
                if categoryFrames[name] then
                    categoryFrames[name].Visible = true
                end
            end
        end)
    end
end

local function setupFeatureToggle(button, statusIndicator, featureName, category)
    buttonStates[featureName] = false
    
    button.MouseButton1Click:Connect(function()
        local newState = not buttonStates[featureName]
        buttonStates[featureName] = newState
        
        TS:Create(statusIndicator, TweenInfo.new(0.2), {
            BackgroundColor3 = newState and 
                Color3.fromRGB(40, 180, 70) or Color3.fromRGB(180, 40, 40)
        }):Play()
        
        if newState then
            -- Cargar y activar script
            if not activeScripts[featureName] then
                if loadScript(category, featureName) then
                    if activeScripts[featureName] and activeScripts[featureName].activate then
                        local success, err = pcall(activeScripts[featureName].activate)
                        if success then
                            showNotification(featureName.." ACTIVADO", Color3.fromRGB(46, 204, 113))
                        else
                            showNotification("Error activando: "..featureName, Color3.fromRGB(231, 76, 60))
                            warn("Error activating "..featureName..": "..tostring(err))
                            buttonStates[featureName] = false
                            TS:Create(statusIndicator, TweenInfo.new(0.2), {
                                BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                            }):Play()
                            activeScripts[featureName] = nil
                        end
                    end
                else
                    buttonStates[featureName] = false
                    TS:Create(statusIndicator, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                    }):Play()
                end
            else
                -- Reactivar si ya está cargado
                if activeScripts[featureName].activate then
                    activeScripts[featureName].activate()
                    showNotification(featureName.." REACTIVADO", Color3.fromRGB(46, 204, 113))
                end
            end
        else
            -- Desactivar script
            if activeScripts[featureName] and activeScripts[featureName].deactivate then
                local success, err = pcall(activeScripts[featureName].deactivate)
                if success then
                    showNotification(featureName.." DESACTIVADO", Color3.fromRGB(231, 76, 60))
                else
                    showNotification("Error desactivando: "..featureName, Color3.fromRGB(231, 76, 60))
                    warn("Error deactivating "..featureName..": "..tostring(err))
                end
                -- Limpiar referencia
                activeScripts[featureName] = nil
            end
        end
    end)
end

-- BOTÓN PARA MINIMIZAR CON DESPLAZAMIENTO -------------------------------------
local function setupMinimizeToggle(defaultKey)
    local minimizeButton = createElement("TextButton", {
        Text = "⬜",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = CONFIG.TextColor,
        BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -40, 0, 10),
        AutoButtonColor = false,
        Parent = mainFrame
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = minimizeButton
    })
    
    createElement("UIStroke", {
        Color = CONFIG.AccentColor,
        Thickness = 1.5,
        Parent = minimizeButton
    })
    
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        if minimized then
            TS:Create(mainFrame, tweenInfo, {
                Size = UDim2.new(0, 50, 0, 50),
                Position = UDim2.new(1, -60, 0, 10)
            }):Play()
            minimizeButton.Text = "⛶"
        else
            TS:Create(mainFrame, tweenInfo, {
                Size = UDim2.new(0, 600, 0, 400),
                Position = UDim2.new(0.5, -300, 0.5, -200)
            }):Play()
            minimizeButton.Text = "⬜"
        end
    end)
    
    -- Configuración de tecla
    UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == defaultKey then
            minimizeButton:Activate()
        end
    end)
end

-- INICIALIZACIÓN PRINCIPAL ----------------------------------------------------
local function init()
    -- Crear UI
    local categoryButtons, categoryFrames, contentFrames, welcomeFrame = createMainUI()
    
    -- Configurar eventos
    setupCategorySwitching(categoryButtons, categoryFrames, welcomeFrame)
    setupMinimizeToggle(Enum.KeyCode.P)
    
    -- Configurar características con desplazamiento
    local features = {
        -- Combat (solo Aimbot y MegaAimb)
        {name = "Aimbot", category = "combat", frame = contentFrames.Combat, 
         color = Color3.fromRGB(80, 30, 30)},
        
        {name = "MegaAimb", category = "combat", frame = contentFrames.Combat, 
         color = Color3.fromRGB(80, 30, 30)},
        
        -- Visual (solo Crosshair, Detect y ESP)
        {name = "Crosshair", category = "visual", frame = contentFrames.Visual, 
         color = Color3.fromRGB(30, 30, 80)},
        
        {name = "Detect", category = "visual", frame = contentFrames.Visual, 
         color = Color3.fromRGB(30, 30, 80)},
        
        {name = "ESP", category = "visual", frame = contentFrames.Visual, 
         color = Color3.fromRGB(30, 30, 80)},
        
        -- New
        {name = "TeleportMenu", category = "new", frame = contentFrames.New, 
         color = Color3.fromRGB(30, 80, 30)},
        
        -- Extra
        {name = "Fly", category = "extra", frame = contentFrames.Extra, 
         color = Color3.fromRGB(80, 80, 30)},
        
        {name = "Head", category = "extra", frame = contentFrames.Extra, 
         color = Color3.fromRGB(80, 80, 30)}
    }
    
    -- Crear botones de características con desplazamiento
    for i, feature in ipairs(features) do
        local button, indicator = createFeatureButton(
            feature.frame,
            feature.name.."Button",
            feature.name,
            feature.color
        )
        
        setupFeatureToggle(button, indicator, feature.name, feature.category)
    end
    
    -- Ajustar tamaño del canvas para desplazamiento
    for name, frame in pairs(contentFrames) do
        local height = 0
        for _, feature in ipairs(features) do
            if feature.category == name:lower() then
                height = height + 55
            end
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, height + 10)
    end
    
    -- Mostrar notificación de bienvenida
    task.delay(1, function()
        showNotification("DRAKHUB PREMIUM INICIADO", CONFIG.AccentColor)
    end)
end

-- Iniciar UI con animación de entrada
task.spawn(function()
    -- Crear pantalla de carga inicial
    local loader = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0.05, 0.05, 0.05),
        Parent = localPlayer:WaitForChild("PlayerGui")
    })
    
    local logo = createElement("ImageLabel", {
        Image = "rbxassetid://3926307971", -- Icono de Roblox
        Size = UDim2.new(0, 150, 0, 150),
        Position = UDim2.new(0.5, -75, 0.5, -75),
        BackgroundTransparency = 1,
        Parent = loader
    })
    
    local loadingText = createElement("TextLabel", {
        Text = "CARGANDO DRAKHUB PREMIUM...",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = CONFIG.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.7, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        Parent = loader
    })
    
    -- Animación de carga
    task.spawn(function()
        for _ = 1, 4 do
            for i = 1, 3 do
                loadingText.Text = "CARGANDO DRAKHUB PREMIUM" .. string.rep(".", i)
                task.wait(0.5)
            end
        end
    end)
    
    -- Simular tiempo de carga
    task.wait(2)
    
    -- Inicializar UI
    init()
    
    -- Animación de salida del loader
    TS:Create(loader, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
    TS:Create(logo, TweenInfo.new(0.8), {ImageTransparency = 1}):Play()
    TS:Create(loadingText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
    
    task.wait(0.8)
    loader:Destroy()
end)
