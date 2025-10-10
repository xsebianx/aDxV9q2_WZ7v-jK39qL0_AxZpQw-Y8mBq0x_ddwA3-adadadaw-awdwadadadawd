--[[
    DRAKHUB PREMIUM v3.2 - VERSIÓN DEFINITIVA FINAL (SIN ERRORES)
    Corrección definitiva de errores de temas mediante destrucción y recreación de elementos.
    Sistema de guardado mejorado y robusto.
]]

-- Servicios
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Heartbeat = RS.Heartbeat
local UserInputService = game:GetService("UserInputService")

-- Variables globales
local localPlayer = Players.LocalPlayer
local gui, mainFrame, dockIcon
local activeScripts = {}
local buttonStates = {}
local minimized = false
local notificationQueue = {}
local isShowingNotification = false

-- === SISTEMAS MEJORADOS ===

-- Pool de notificaciones para reutilización (mejora de rendimiento)
local notificationPool = {}
local activeNotifications = {}
local maxNotifications = 3

-- Sistema de caché para teletransporte (mejora de rendimiento y funcionalidad)
local locationCache = {}
local favoriteLocations = {}
local recentLocations = {}

-- Sistema de actualización optimizado (mejora de rendimiento)
local updateFunctions = {}
local lastUpdateTime = {}

-- === FUNCIÓN createElement MEJORADA ===
local function createElement(className, properties)
    local element = Instance.new(className)
    
    -- Establecer el padre primero para evitar problemas de referencia
    if properties.Parent then
        element.Parent = properties.Parent
        properties.Parent = nil -- Eliminar para no asignarlo de nuevo
    end
    
    for prop, value in pairs(properties) do
        if prop ~= "Gradient" then
            if element[prop] ~= nil then
                element[prop] = value
            end
        end
    end
    
    if properties.Gradient then
        local gradient = Instance.new("UIGradient")
        for gprop, gvalue in pairs(properties.Gradient) do
            if gradient[gprop] ~= nil then
                gradient[gprop] = gvalue
            end
        end
        gradient.Parent = element
    end
    
    return element
end

-- === DEFINICIÓN DE TEMAS ===
local THEMES = {
    Defecto = {
        MainColor = Color3.fromRGB(15, 15, 15),
        AccentColor = Color3.fromRGB(220, 20, 20),
        TextColor = Color3.fromRGB(245, 245, 245),
        ButtonColors = {
            Home = Color3.fromRGB(255, 193, 7),
            Combat = Color3.fromRGB(220, 20, 60),
            Visual = Color3.fromRGB(30, 136, 229),
            New = Color3.fromRGB(46, 204, 113),
            Extra = Color3.fromRGB(255, 143, 0)
        }
    },
    Azul = {
        MainColor = Color3.fromRGB(10, 25, 47),
        AccentColor = Color3.fromRGB(0, 123, 255),
        TextColor = Color3.fromRGB(230, 240, 255),
        ButtonColors = {
            Home = Color3.fromRGB(255, 193, 7),
            Combat = Color3.fromRGB(220, 20, 60),
            Visual = Color3.fromRGB(30, 136, 229),
            New = Color3.fromRGB(46, 204, 113),
            Extra = Color3.fromRGB(255, 143, 0)
        }
    },
    Verde = {
        MainColor = Color3.fromRGB(15, 30, 15),
        AccentColor = Color3.fromRGB(46, 204, 113),
        TextColor = Color3.fromRGB(230, 255, 230),
        ButtonColors = {
            Home = Color3.fromRGB(255, 193, 7),
            Combat = Color3.fromRGB(220, 20, 60),
            Visual = Color3.fromRGB(30, 136, 229),
            New = Color3.fromRGB(46, 204, 113),
            Extra = Color3.fromRGB(255, 143, 0)
        }
    },
    Morado = {
        MainColor = Color3.fromRGB(25, 15, 35),
        AccentColor = Color3.fromRGB(142, 68, 173),
        TextColor = Color3.fromRGB(245, 230, 255),
        ButtonColors = {
            Home = Color3.fromRGB(255, 193, 7),
            Combat = Color3.fromRGB(220, 20, 60),
            Visual = Color3.fromRGB(30, 136, 229),
            New = Color3.fromRGB(46, 204, 113),
            Extra = Color3.fromRGB(255, 143, 0)
        }
    }
}

local CONFIG = THEMES.Defecto

-- === SISTEMA DE CONFIGURACIÓN (CORREGIDO Y ROBUSTO) ===
local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new()
    local self = setmetatable({}, SettingsManager)
    self.currentTheme = "Defecto"
    return self
end

function SettingsManager:applyTheme(themeName)
    -- Verificar que createElement esté disponible
    if not createElement then
        warn("[DRAKHUB] createElement no disponible en applyTheme")
        return
    end
    
    local theme = THEMES[themeName]
    if not theme then
        warn("Tema no encontrado: " .. tostring(themeName))
        return
    end
    
    -- Actualizar la tabla de configuración
    CONFIG.MainColor = theme.MainColor
    CONFIG.AccentColor = theme.AccentColor
    CONFIG.TextColor = theme.TextColor
    CONFIG.ButtonColors = theme.ButtonColors
    self.currentTheme = themeName

    -- Aplicar a la UI de forma segura (solo si mainFrame existe)
    if mainFrame and mainFrame.Parent then
        mainFrame.BackgroundColor3 = CONFIG.MainColor
        
        -- Actualizar UIStroke de forma segura
        local stroke = mainFrame:FindFirstChild("UIStroke")
        if stroke then 
            stroke:Destroy() 
        end
        
        -- Crear nuevo UIStroke con verificación
        if createElement then
            createElement("UIStroke", {
                Color = CONFIG.AccentColor, 
                Thickness = 2.5, 
                Parent = mainFrame
            })
        end
        
        -- Actualizar Header y su degradado
        local header = mainFrame:FindFirstChild("Header")
        if header then
            local gradient = header:FindFirstChild("UIGradient")
            if gradient then 
                gradient:Destroy() 
            end
            
            if createElement then
                createElement("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, CONFIG.AccentColor),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 20))
                    }),
                    Parent = header
                })
            end
        end
    end
    
    -- Actualizar botones de categoría de forma segura
    for name, color in pairs(CONFIG.ButtonColors) do
        local button = mainFrame and mainFrame:FindFirstChild(name.."Button")
        if button then
            button.BackgroundColor3 = color
        end
    end
    
    -- Mostrar notificación solo si showNotification está disponible
    if showNotification then
        showNotification("Tema '" .. themeName .. "' aplicado", CONFIG.AccentColor)
    end
end

function SettingsManager:saveSettings()
    -- Verificar que los servicios necesarios estén disponibles
    if not HttpService or not localPlayer then
        warn("[DRAKHUB] Servicios no disponibles para guardar configuración")
        return false
    end

    local settingsToSave = {
        theme = self.currentTheme,
        activeScripts = {}
    }
    
    -- Recopilar scripts activos de forma segura
    for name, state in pairs(buttonStates) do
        if state then
            table.insert(settingsToSave.activeScripts, name)
        end
    end

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(settingsToSave)
    end)

    if success and encoded then
        -- Buscar o crear el valor de configuración
        local settingsValue = localPlayer:FindFirstChild("DrakHubSettings")
        if not settingsValue then
            settingsValue = Instance.new("StringValue")
            settingsValue.Name = "DrakHubSettings"
            settingsValue.Parent = localPlayer
        end
        settingsValue.Value = encoded
        
        -- Mostrar notificación de éxito
        if showNotification then
            showNotification("Configuración guardada correctamente", Color3.fromRGB(46, 204, 113))
        end
        
        print("[DRAKHUB] Configuración guardada: " .. tostring(encoded))
        return true
    else
        -- Mostrar error detallado
        local errorMsg = "Error al guardar configuración: " .. tostring(encoded)
        warn("[DRAKHUB] " .. errorMsg)
        
        if showNotification then
            showNotification(errorMsg, Color3.fromRGB(231, 76, 60))
        end
        return false
    end
end

function SettingsManager:loadSettings()
    -- Verificar servicios necesarios
    if not HttpService or not localPlayer then
        warn("[DRAKHUB] Servicios no disponibles para cargar configuración")
        return nil
    end

    local settingsValue = localPlayer:FindFirstChild("DrakHubSettings")
    if settingsValue and settingsValue.Value ~= "" then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(settingsValue.Value)
        end)
        
        if success and decoded then
            -- Aplicar tema guardado de forma segura
            if decoded.theme and THEMES[decoded.theme] then
                -- Esperar a que la UI esté completamente cargada
                task.spawn(function()
                    task.wait(0.5) -- Pequeña espera para asegurar que createElement esté disponible
                    self:applyTheme(decoded.theme)
                end)
            end
            
            -- Mostrar notificación de carga exitosa
            task.wait(1.5)
            if showNotification then
                showNotification("Configuración cargada exitosamente", CONFIG.AccentColor)
            end
            
            return decoded
        else
            local errorMsg = "Error al decodificar configuración: " .. tostring(decoded)
            warn("[DRAKHUB] " .. errorMsg)
        end
    else
        -- Aplicar tema por defecto si no hay configuración guardada
        task.spawn(function()
            task.wait(0.5)
            self:applyTheme("Defecto")
        end)
    end
    return nil
end

local settingsManager = SettingsManager.new()

-- === CONFIGURACIÓN PRINCIPAL MEJORADA ===
CONFIG.ShadowIntensity = 0.6
CONFIG.AnimationSpeed = 0.25
CONFIG.ScriptBaseURL = "https://raw.githubusercontent.com/xsebianx/aDxV9q2_WZ7v-jK39qL0_AxZpQw-Y8mBq0x_ddwA3-adadadaw-awdwadadadawd/main/"
CONFIG.NotificationDuration = 3
CONFIG.TeleportFadeTime = 0.3
CONFIG.MaxRecentLocations = 5
CONFIG.UpdateInterval = 0.1
CONFIG.KeyBinds = {
    ToggleUI = Enum.KeyCode.P,
    QuickTeleport = Enum.KeyCode.T
}

-- === SISTEMA DE ACTUALIZACIÓN OPTIMIZADO ===
local function addUpdateFunction(name, func, interval)
    updateFunctions[name] = {
        func = func,
        interval = interval or CONFIG.UpdateInterval
    }
    lastUpdateTime[name] = 0
end

local function removeUpdateFunction(name)
    updateFunctions[name] = nil
    lastUpdateTime[name] = nil
end

local updateConnection
local function startUpdateSystem()
    updateConnection = Heartbeat:Connect(function()
        local currentTime = tick()
        for name, updateData in pairs(updateFunctions) do
            if currentTime - (lastUpdateTime[name] or 0) >= updateData.interval then
                local success, err = pcall(updateData.func)
                if not success then
                    warn("Error en update function " .. name .. ": " .. tostring(err))
                end
                lastUpdateTime[name] = currentTime
            end
        end
    end)
end

local function stopUpdateSystem()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- === SISTEMA DE TELETRANSPORTE MEJORADO ===
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

local function cacheLocations()
    locationCache = {}
    local containerFolder = workspace:FindFirstChild("Interactable")
    containerFolder = containerFolder and containerFolder:FindFirstChild("Containers") or workspace:FindFirstChild("Containers")
    
    if containerFolder then
        for _, container in pairs(containerFolder:GetChildren()) do
            if container:IsA("Model") then
                local position = getSafeCFrame(container)
                if position then
                    locationCache[container.Name] = {
                        position = position,
                        model = container,
                        lastVisited = 0
                    }
                end
            end
        end
    end
end

local function addToRecent(locationName)
    for i, name in ipairs(recentLocations) do
        if name == locationName then
            table.remove(recentLocations, i)
            break
        end
    end
    table.insert(recentLocations, 1, locationName)
    if #recentLocations > CONFIG.MaxRecentLocations then
        table.remove(recentLocations, CONFIG.MaxRecentLocations)
    end
end

local function teleportTo(locationName, fadeEffect)
    if locationCache[locationName] then
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if fadeEffect then
                local fadeGui = Instance.new("ScreenGui")
                fadeGui.Parent = player:WaitForChild("PlayerGui")
                
                local fadeFrame = Instance.new("Frame")
                fadeFrame.Size = UDim2.new(1, 0, 1, 0)
                fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                fadeFrame.BackgroundTransparency = 1
                fadeFrame.Parent = fadeGui
                
                local fadeIn = TS:Create(fadeFrame, TweenInfo.new(CONFIG.TeleportFadeTime), {BackgroundTransparency = 0})
                fadeIn:Play()
                fadeIn.Completed:Wait()
                
                pcall(function()
                    player.Character.HumanoidRootPart.CFrame = locationCache[locationName].position
                    locationCache[locationName].lastVisited = tick()
                    addToRecent(locationName)
                end)
                
                local fadeOut = TS:Create(fadeFrame, TweenInfo.new(CONFIG.TeleportFadeTime), {BackgroundTransparency = 1})
                fadeOut:Play()
                fadeOut.Completed:Wait()
                
                fadeGui:Destroy()
            else
                pcall(function()
                    player.Character.HumanoidRootPart.CFrame = locationCache[locationName].position
                    locationCache[locationName].lastVisited = tick()
                    addToRecent(locationName)
                end)
            end
            return true
        end
    end
    return false
end

local function toggleFavorite(locationName)
    if favoriteLocations[locationName] then
        favoriteLocations[locationName] = nil
        return false
    else
        favoriteLocations[locationName] = true
        return true
    end
end

-- === SISTEMA DE NOTIFICACIONES MEJORADO Y CORREGIDO ===
local function getNotificationFromPool()
    if not gui then
        warn("[DRAKHUB] getNotificationFromPool llamado antes de que la GUI se inicializara.")
        return nil
    end

    if #notificationPool > 0 then
        local notif = table.remove(notificationPool)
        notif.Parent = gui
        return notif
    else
        local notif = createElement("Frame", {
            Name = "Notification",
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
            Size = UDim2.new(0, 300, 0, 60),
            Position = UDim2.new(1, 320, 0.8, 0),
            Parent = gui
        })
        
        createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = notif})
        createElement("UIStroke", {Color = Color3.fromRGB(100, 100, 120), Thickness = 1, Parent = notif})
        
        local label = createElement("TextLabel", {
            Name = "Label",
            Text = "",
            Font = Enum.Font.GothamSemibold,
            TextSize = 16,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            TextWrapped = true,
            Parent = notif
        })
        
        return notif
    end
end

local function returnNotificationToPool(notif)
    notif.Parent = nil
    table.insert(notificationPool, notif)
end

function showNotification(message, color, duration)
    duration = duration or CONFIG.NotificationDuration
    
    if not gui then
        warn("[DRAKHUB] showNotification llamado antes de que la GUI se inicializara. Mensaje: " .. tostring(message))
        return
    end
    
    if #activeNotifications >= maxNotifications then
        table.insert(notificationQueue, {message, color, duration})
        return
    end
    
    local notif = getNotificationFromPool()
    if not notif then return end

    notif.Label.Text = message
    notif.UIStroke.Color = color or CONFIG.AccentColor
    
    table.insert(activeNotifications, notif)
    local yPos = 0.8 - (#activeNotifications - 1) * 0.08
    
    notif.Position = UDim2.new(1, 320, yPos, 0)
    local enterTween = TS:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -320, yPos, 0)
    })
    enterTween:Play()
    
    task.spawn(function()
        task.wait(duration)
        
        local exitTween = TS:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Position = UDim2.new(1, 320, yPos, 0)
        })
        exitTween:Play()
        exitTween.Completed:Wait()
        
        for i, activeNotif in ipairs(activeNotifications) do
            if activeNotif == notif then
                table.remove(activeNotifications, i)
                break
            end
        end
        
        returnNotificationToPool(notif)
        
        if #notificationQueue > 0 then
            local nextNotif = table.remove(notificationQueue, 1)
            showNotification(nextNotif[1], nextNotif[2], nextNotif[3])
        end
    end)
end

-- === CÓDIGO DEL TELEPORT MENU INTEGRADO ===
local TeleportMenuAPI = {
    active = false,
    screenGui = nil
}

-- === ANIMACIÓN DE NEÓN OPTIMIZADA ===
local function createOptimizedNeonBorder(parent)
    local neonBorder = Instance.new("Frame")
    neonBorder.Size = UDim2.new(1, 6, 1, 6)
    neonBorder.Position = UDim2.new(0, -3, 0, -3)
    neonBorder.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    neonBorder.BorderSizePixel = 0
    neonBorder.ZIndex = 0
    neonBorder.Parent = parent
    
    local uigradient = Instance.new("UIGradient")
    uigradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 30, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255))
    })
    uigradient.Rotation = 90
    uigradient.Parent = neonBorder

    local animating = true
    local function animate()
        if not animating or not neonBorder or not neonBorder.Parent then
            return
        end
        
        local time = tick() % 2
        uigradient.Offset = Vector2.new(0, -time + (time >= 1 and 2 or 0))
        
        task.wait(0.03)
        if animating then
            task.spawn(animate)
        end
    end
    
    task.spawn(animate)
    
    neonBorder.Destroying:Connect(function()
        animating = false
    end)
    
    return neonBorder
end

local function showTeleportMenu()
    if TeleportMenuAPI.active then
        return
    end
    
    TeleportMenuAPI.active = true
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    if TeleportMenuAPI.screenGui then
        TeleportMenuAPI.screenGui:Destroy()
        TeleportMenuAPI.screenGui = nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportMenuGui"
    screenGui.Parent = playerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TeleportMenuAPI.screenGui = screenGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 500)
    frame.Position = UDim2.new(0.5, -200, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    createOptimizedNeonBorder(frame)

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 12)
    uicorner.Parent = frame

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

    local titleGlow = title:Clone()
    titleGlow.TextColor3 = Color3.fromRGB(255, 50, 50)
    titleGlow.TextTransparency = 0.7
    titleGlow.ZIndex = title.ZIndex - 1
    titleGlow.Parent = titleContainer

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
    
    closeButton.MouseEnter:Connect(function()
        TS:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TS:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        TeleportMenuAPI.deactivate()
    end)

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

    local containerList = Instance.new("ScrollingFrame")
    containerList.Size = UDim2.new(1, -20, 0, 380)
    containerList.Position = UDim2.new(0, 10, 0, 110)
    containerList.BackgroundTransparency = 0.2
    containerList.ScrollBarThickness = 12
    containerList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    containerList.Parent = frame
    containerList.ScrollingDirection = Enum.ScrollingDirection.Y
    containerList.CanvasSize = UDim2.new(0, 0, 0, 0)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = containerList

    local function createTeleportButton(name, position, parent, isFavorite, isRecent)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = "   " .. name
        button.TextColor3 = Color3.fromRGB(220, 220, 220)
        button.TextSize = 18
        button.Font = Enum.Font.GothamSemibold
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        button.AutoButtonColor = false
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Size = UDim2.new(1, 0, 0, 50)
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

        local indicator = Instance.new("TextLabel")
        indicator.Size = UDim2.new(0, 50, 1, 0)
        indicator.Position = UDim2.new(1, -50, 0, 0)
        indicator.BackgroundTransparency = 1
        indicator.Text = ""
        indicator.TextColor3 = Color3.fromRGB(255, 255, 100)
        indicator.TextSize = 14
        indicator.Font = Enum.Font.GothamBold
        indicator.Parent = button
        if isFavorite then
            indicator.Text = "★"
        elseif isRecent then
            indicator.Text = "↻"
        end
        
        button.MouseEnter:Connect(function()
            TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
            TS:Create(highlight, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
            TS:Create(highlight, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            TS:Create(highlight, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
            TS:Create(highlight, TweenInfo.new(0.1), {BackgroundTransparency = 0.8}):Play()
            
            if teleportTo(name, true) then
                showNotification("Teletransportado a: " .. name, Color3.fromRGB(46, 204, 113))
            end
        end)

        button.MouseButton2Click:Connect(function()
            if toggleFavorite(name) then
                showNotification("Añadido a favoritos: " .. name, Color3.fromRGB(255, 193, 7))
                indicator.Text = "★"
            else
                showNotification("Eliminado de favoritos: " .. name, Color3.fromRGB(231, 76, 60))
                indicator.Text = ""
            end
        end)
        
        return button
    end

    local function updateContainerList(filter)
        for _, child in pairs(containerList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local addedLocations = {}
        local offset = 0

        for name, _ in pairs(favoriteLocations) do
            if locationCache[name] and (not filter or string.find(name:lower(), filter:lower())) then
                createTeleportButton(name, locationCache[name].position, containerList, true, false)
                addedLocations[name] = true
                offset = offset + 55
            end
        end

        for _, name in ipairs(recentLocations) do
            if locationCache[name] and not addedLocations[name] and (not filter or string.find(name:lower(), filter:lower())) then
                createTeleportButton(name, locationCache[name].position, containerList, false, true)
                addedLocations[name] = true
                offset = offset + 55
            end
        end

        for name, data in pairs(locationCache) do
            if not addedLocations[name] and (not filter or string.find(name:lower(), filter:lower())) then
                createTeleportButton(name, data.position, containerList, false, false)
                offset = offset + 55
            end
        end
        
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
        cacheLocations()
        updateContainerList(searchBox.Text)
        showNotification("Lista de ubicaciones actualizada", Color3.fromRGB(46, 204, 113))
    end)

    cacheLocations()
    updateContainerList()
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        updateContainerList(searchBox.Text)
    end)

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

-- === SISTEMA DE RESPALDO (PLACEHOLDERS) PARA SCRIPTS ===
local PlaceholderAPI = {}
PlaceholderAPI.__index = PlaceholderAPI

function PlaceholderAPI.new(scriptName)
    local self = setmetatable({}, PlaceholderAPI)
    self.scriptName = scriptName
    self.active = false
    return self
end

function PlaceholderAPI:activate()
    if not self.active then
        self.active = true
        print("[DRAKHUB] " .. self.scriptName .. " (placeholder) activado.")
    end
end

function PlaceholderAPI:deactivate()
    if self.active then
        self.active = false
        print("[DRAKHUB] " .. self.scriptName .. " (placeholder) desactivado.")
    end
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

-- === FUNCIÓN createButton CORREGIDA ===
local function createButton(name, text, position, color, hoverColor)
    local button = createElement("TextButton", {
        Name = name,
        Text = "   " .. text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 18,
        TextColor3 = CONFIG.TextColor,
        BackgroundColor3 = color,
        Size = UDim2.new(0, 120, 0, 40),
        Position = position,
        AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = button})
    createElement("UIStroke", {Color = Color3.new(0.1, 0.1, 0.1), Thickness = 1.5, Parent = button})
    
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

-- === FRAME DE CATEGORÍA CON SCROLLING ===
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
    
    createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = frame})
    createElement("UIStroke", {Color = color, Thickness = 2, Parent = frame})
    createShadow(frame, 25)
    
    local scrollFrame = createElement("ScrollingFrame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 8,
        ScrollBarImageColor3 = color,
        Parent = frame
    })
    
    createElement("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame
    })
    
    return frame, scrollFrame
end

-- === BOTÓN DE CARACTERÍSTICA CLÁSICO ===
local function createFeatureButton(parent, name, text, color)
    local button = createElement("TextButton", {
        Name = name,
        Text = "   " .. text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = CONFIG.TextColor,
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 45),
        AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    
    createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = button})
    createElement("UIStroke", {Color = Color3.new(0.15, 0.15, 0.15), Thickness = 1.5, Parent = button})
    
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
    
    createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = statusIndicator})
    
    button.MouseEnter:Connect(function()
        TS:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return button, statusIndicator
end

-- === CARGA DE SCRIPTS CORREGIDA CON RESPALDO GENERAL ===
local function loadScript(category, scriptName)
    local url = CONFIG.ScriptBaseURL..category:lower().."/"..scriptName:lower()..".lua"
    
    print("[DRAKHUB] Cargando: "..scriptName)
    
    local success, result = pcall(function()
        local httpContent = game:HttpGet(url, true)
        local loadedFunction, errorMsg = loadstring(httpContent)
        
        if loadedFunction then
            return loadedFunction()
        else
            error(errorMsg or "Error en loadstring")
        end
    end)
    
    if success then
        if type(result) == "table" and result.activate then
            activeScripts[scriptName] = result
            showNotification(scriptName.." cargado", Color3.fromRGB(46, 204, 113))
            return true
        else
            warn("El script "..scriptName.." no devolvió una API válida. Usando respaldo local.")
            local fallbackAPI = (scriptName == "TeleportMenu" and TeleportMenuAPI) or PlaceholderAPI.new(scriptName)
            activeScripts[scriptName] = fallbackAPI
            showNotification(scriptName.." (placeholder) cargado", Color3.fromRGB(241, 196, 15))
            return true
        end
    else
        warn("Error cargando "..scriptName..": "..tostring(result)..". Usando respaldo local.")
        
        local fallbackAPI = (scriptName == "TeleportMenu" and TeleportMenuAPI) or PlaceholderAPI.new(scriptName)
        activeScripts[scriptName] = fallbackAPI
        
        if scriptName == "TeleportMenu" then
            showNotification("TeleportMenu (local) cargado", Color3.fromRGB(46, 204, 113))
        else
            showNotification(scriptName.." (placeholder) cargado", Color3.fromRGB(241, 196, 15))
        end
        
        return true
    end
end

-- === CONSTRUCCIÓN DE LA UI ===
local function createMainUI()
    gui = createElement("ScreenGui", {
        Name = "DrakHubPremium",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = localPlayer:WaitForChild("PlayerGui")
    })
    
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
    
    createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0.95,
        Active = false,
        Parent = mainFrame
    })
    
    createElement("UICorner", {CornerRadius = UDim.new(0, 14), Parent = mainFrame})
    createElement("UIStroke", {Color = CONFIG.AccentColor, Thickness = 2.5, Parent = mainFrame})
    createShadow(mainFrame, 30)
    
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
    
    createElement("Frame", {
        Name = "Separator",
        BackgroundColor3 = CONFIG.AccentColor,
        Size = UDim2.new(1, -40, 0, 2),
        Position = UDim2.new(0, 20, 0, 50),
        Parent = mainFrame
    })
    
    local categories = {
        {name = "Home", text = "INICIO", pos = UDim2.new(0, 10, 0, 60)},
        {name = "Combat", text = "COMBATE", pos = UDim2.new(0, 10, 0, 110)},
        {name = "Visual", text = "VISUAL", pos = UDim2.new(0, 10, 0, 160)},
        {name = "New", text = "NUEVO", pos = UDim2.new(0, 10, 0, 210)},
        {name = "Extra", text = "EXTRA", pos = UDim2.new(0, 10, 0, 260)},
        {name = "Settings", text = "AJUSTES", pos = UDim2.new(0, 10, 0, 310)}
    }
    
    local categoryButtons = {}
    for _, cat in ipairs(categories) do
        local color = CONFIG.ButtonColors[cat.name] or Color3.fromRGB(100, 100, 100)
        categoryButtons[cat.name] = createButton(
            cat.name.."Button",
            cat.text,
            cat.pos,
            color,
            Color3.new(
                math.min(color.R * 1.3, 1),
                math.min(color.G * 1.3, 1),
                math.min(color.B * 1.3, 1)
            )
        )
        categoryButtons[cat.name].Parent = mainFrame
    end
    
    local categoryFrames = {}
    local contentFrames = {}
    local frameInfo = {
        {name = "Combat", color = CONFIG.ButtonColors.Combat},
        {name = "Visual", color = CONFIG.ButtonColors.Visual},
        {name = "New", color = CONFIG.ButtonColors.New},
        {name = "Extra", color = CONFIG.ButtonColors.Extra},
        {name = "Settings", color = Color3.fromRGB(100, 100, 100)}
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
    
    -- Crear contenido para el menú de ajustes
    local settingsContent = contentFrames.Settings
    local yOffset = 10
    
    createElement("TextLabel", {
        Text = "Selector de Tema:",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = CONFIG.TextColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, yOffset),
        Parent = settingsContent
    })
    yOffset = yOffset + 40

    for themeName, _ in pairs(THEMES) do
        local themeButton = createElement("TextButton", {
            Text = themeName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 16,
            TextColor3 = CONFIG.TextColor,
            BackgroundColor3 = Color3.fromRGB(50, 50, 60),
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, yOffset),
            Parent = settingsContent
        })
        createElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = themeButton})
        
        themeButton.MouseButton1Click:Connect(function()
            settingsManager:applyTheme(themeName)
        end)
        yOffset = yOffset + 40
    end
    
    local saveButton = createElement("TextButton", {
        Text = "Guardar Configuración",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(46, 204, 113),
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, yOffset + 20),
        Parent = settingsContent
    })
    createElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = saveButton})
    
    saveButton.MouseButton1Click:Connect(function()
        local success = settingsManager:saveSettings()
        if not success then
            warn("[DRAKHUB] Falló el guardado de configuración")
        end
    end)
    
    settingsContent.CanvasSize = UDim2.new(0, 0, 0, yOffset + 80)

    -- Pantalla de bienvenida
    local welcomeFrame = createElement("Frame", {
        Name = "WelcomeFrame",
        BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
        Size = UDim2.new(0, 450, 0, 300),
        Position = UDim2.new(0, 140, 0, 60),
        Parent = mainFrame
    })
    
    createElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = welcomeFrame})
    createElement("UIStroke", {Color = CONFIG.AccentColor, Thickness = 2, Parent = welcomeFrame})
    createShadow(welcomeFrame, 25)
    
    local logo = createElement("ImageLabel", {
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0.5, -40, 0.2, -40),
        BackgroundTransparency = 1,
        ImageColor3 = CONFIG.AccentColor,
        Parent = welcomeFrame
    })
    
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
    
    dockIcon = createElement("ImageButton", {
        Name = "DockIcon",
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(1, -60, 1, -60),
        BackgroundColor3 = CONFIG.AccentColor,
        Visible = false,
        Parent = gui
    })
    createElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = dockIcon})
    createElement("UIStroke", {Color = Color3.fromRGB(255,255,255), Thickness = 2, Parent = dockIcon})

    return categoryButtons, categoryFrames, contentFrames, welcomeFrame
end

-- === CONFIGURACIÓN DE FUNCIONALIDADES ===
local function setupCategorySwitching(categoryButtons, categoryFrames, welcomeFrame)
    for name, button in pairs(categoryButtons) do
        button.MouseButton1Click:Connect(function()
            for _, frame in pairs(categoryFrames) do
                frame.Visible = false
            end
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
                if activeScripts[featureName].activate then
                    activeScripts[featureName].activate()
                    showNotification(featureName.." REACTIVADO", Color3.fromRGB(46, 204, 113))
                end
            end
        else
            if activeScripts[featureName] and activeScripts[featureName].deactivate then
                local success, err = pcall(activeScripts[featureName].deactivate)
                if success then
                    showNotification(featureName.." DESACTIVADO", Color3.fromRGB(231, 76, 60))
                else
                    showNotification("Error desactivando: "..featureName, Color3.fromRGB(231, 76, 60))
                    warn("Error deactivating "..featureName..": "..tostring(err))
                end
                activeScripts[featureName] = nil
            end
        end
    end)
end

-- === FUNCIÓN DE MINIMIZACIÓN A ÍCONO ===
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
    
    createElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = minimizeButton})
    createElement("UIStroke", {Color = CONFIG.AccentColor, Thickness = 1.5, Parent = minimizeButton})
    
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        if minimized then
            mainFrame.Visible = false
            dockIcon.Visible = true
            minimizeButton.Text = "⛶"
        else
            mainFrame.Visible = true
            dockIcon.Visible = false
            minimizeButton.Text = "⬜"
        end
    end)
    
    dockIcon.MouseButton1Click:Connect(function()
        minimized = false
        mainFrame.Visible = true
        dockIcon.Visible = false
        minimizeButton.Text = "⬜"
    end)
    
    UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == defaultKey then
            minimizeButton:Activate()
        end
    end)
end

-- === INICIALIZACIÓN PRINCIPAL ===
local function init()
    startUpdateSystem()
    
    local categoryButtons, categoryFrames, contentFrames, welcomeFrame = createMainUI()
    
    setupCategorySwitching(categoryButtons, categoryFrames, welcomeFrame)
    setupMinimizeToggle(CONFIG.KeyBinds.ToggleUI)
    
    local features = {
        {name = "Aimbot", category = "combat", frame = contentFrames.Combat, color = Color3.fromRGB(80, 30, 30)},
        {name = "MegaAimb", category = "combat", frame = contentFrames.Combat, color = Color3.fromRGB(80, 30, 30)},
        {name = "Novaaimb", category = "combat", frame = contentFrames.Combat, color = Color3.fromRGB(80, 30, 30)},
        {name = "Crosshair", category = "visual", frame = contentFrames.Visual, color = Color3.fromRGB(30, 30, 80)},
        {name = "Detect", category = "visual", frame = contentFrames.Visual, color = Color3.fromRGB(30, 30, 80)},
        {name = "ESP", category = "visual", frame = contentFrames.Visual, color = Color3.fromRGB(30, 30, 80)},
        {name = "TeleportMenu", category = "new", frame = contentFrames.New, color = Color3.fromRGB(30, 80, 30)},
        {name = "Fly", category = "extra", frame = contentFrames.Extra, color = Color3.fromRGB(80, 80, 30)},
        {name = "Head", category = "extra", frame = contentFrames.Extra, color = Color3.fromRGB(80, 80, 30)}
    }
    
    for i, feature in ipairs(features) do
        local button, statusIndicator = createFeatureButton(
            feature.frame,
            feature.name.."Button",
            feature.name,
            feature.color
        )
        
        setupFeatureToggle(button, statusIndicator, feature.name, feature.category)
    end
    
    for name, frame in pairs(contentFrames) do
        local height = 0
        for _, feature in ipairs(features) do
            if feature.category == name:lower() then
                height = height + 55
            end
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, height + 10)
    end
    
    -- Cargar configuración después de que todo esté inicializado
    task.spawn(function()
        task.wait(1) -- Esperar a que la UI esté completamente cargada
        local loadedSettings = settingsManager:loadSettings()
        if loadedSettings and loadedSettings.activeScripts then
            task.wait(1)
            for _, scriptName in ipairs(loadedSettings.activeScripts) do
                local button = mainFrame:FindFirstChild(scriptName.."Button")
                if button then
                    local statusIndicator = button:FindFirstChild("Status")
                    if statusIndicator then
                        button:MouseButton1Click()
                    end
                end
            end
        end
    end)

    task.delay(1, function()
        showNotification("DRAKHUB PREMIUM INICIADO", CONFIG.AccentColor)
    end)
end

-- Iniciar UI con animación de entrada
task.spawn(function()
    local loader = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0.05, 0.05, 0.05),
        Parent = localPlayer:WaitForChild("PlayerGui")
    })
    
    local logo = createElement("ImageLabel", {
        Image = "rbxassetid://3926307971",
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
    
    task.spawn(function()
        for _ = 1, 4 do
            for i = 1, 3 do
                loadingText.Text = "CARGANDO DRAKHUB PREMIUM" .. string.rep(".", i)
                task.wait(0.5)
            end
        end
    end)
    
    task.wait(2)
    
    init()
    
    TS:Create(loader, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
    TS:Create(logo, TweenInfo.new(0.8), {ImageTransparency = 1}):Play()
    TS:Create(loadingText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
    
    task.wait(0.8)
    loader:Destroy()
end)
