-- esp.txt
-- ESP Profesional Mejorado para DrakHub Premium
-- ADVERTENCIA: Este script proporciona una ventaja injusta y es considerado trampa.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de scripting en Lua.

local ProfessionalESP = {
    Enabled = false,
    Players = {},
    Settings = {
        Boxes = true,
        CornerBoxes = false, -- Nuevo estilo
        Names = true,
        HealthBars = true,
        Tracers = true,
        Distance = true,
        Weapon = true, -- Nueva característica
        OffScreenArrows = true, -- Nueva característica
        TeamCheck = true,
        AllyColor = Color3.fromRGB(0, 255, 0),
        EnemyColor = Color3.fromRGB(255, 50, 50),
        TextSize = 14,
        Font = 2, -- 0: UI, 1: System, 2: Plex, 3: Monospace
        MaxDistance = 1500
    }
}

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Mapeo de fuentes numéricas
local FontMapping = {
    [0] = Drawing.Fonts.UI,
    [1] = Drawing.Fonts.System,
    [2] = Drawing.Fonts.Plex,
    [3] = Drawing.Fonts.Monospace
}

-- GUI de Configuración
local configGui, configFrame
local CONFIG_KEY = Enum.KeyCode.F4

-- Función para crear un ESP para un jugador
function ProfessionalESP:Create(player)
    if self.Players[player] then return end

    local esp = {
        Player = player,
        Connections = {},
        Drawings = {},
        -- Caché de partes para rendimiento
        Cache = {}
    }
    self.Players[player] = esp

    -- Crear dibujos
    local function createDrawing(type, props)
        local drawing = Drawing.new(type)
        for prop, value in pairs(props) do
            if prop == "Font" then
                drawing[prop] = FontMapping[value] or FontMapping[2]
            else
                drawing[prop] = value
            end
        end
        table.insert(esp.Drawings, drawing)
        return drawing
    end

    -- Caja (Estilo normal)
    esp.BoxOutline = createDrawing("Square", {
        Thickness = 3,
        Color = Color3.new(0, 0, 0),
        Filled = false,
        Visible = false
    })
    esp.Box = createDrawing("Square", {
        Thickness = 1,
        Color = self.Settings.EnemyColor,
        Filled = false,
        Visible = false
    })

    -- Caja (Estilo esquina)
    esp.Corner1 = createDrawing("Line", { Thickness = 1, Color = self.Settings.EnemyColor, Visible = false })
    esp.Corner2 = createDrawing("Line", { Thickness = 1, Color = self.Settings.EnemyColor, Visible = false })
    esp.Corner3 = createDrawing("Line", { Thickness = 1, Color = self.Settings.EnemyColor, Visible = false })
    esp.Corner4 = createDrawing("Line", { Thickness = 1, Color = self.Settings.EnemyColor, Visible = false })

    -- Barra de salud
    esp.HealthBarOutline = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(0, 0, 0),
        Filled = false,
        Visible = false
    })
    esp.HealthBar = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(0, 1, 0),
        Filled = true,
        Visible = false
    })

    -- Textos
    esp.NameText = createDrawing("Text", {
        Text = player.Name,
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font,
        Visible = false
    })
    esp.WeaponText = createDrawing("Text", { -- Nuevo texto para el arma
        Text = "",
        Size = self.Settings.TextSize - 2,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.fromRGB(1, 1, 1),
        Font = self.Settings.Font,
        Visible = false
    })
    esp.DistanceText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font,
        Visible = false
    })

    -- Tracer
    esp.Tracer = createDrawing("Line", {
        Thickness = 1,
        Color = self.Settings.EnemyColor,
        Visible = false
    })

    -- Flecha fuera de pantalla
    esp.OffScreenArrow = createDrawing("Line", {
        Thickness = 2,
        Color = self.Settings.EnemyColor,
        Visible = false
    })

    -- Conectar eventos
    esp.Connections.CharacterAdded = player.CharacterAdded:Connect(function()
        self:Update(player)
    end)

    if player.Character then
        self:Update(player)
    end
end

-- Verificar si el jugador está apuntando con un arma
function ProfessionalESP:IsAiming()
    if not LocalPlayer.Character then return false end
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local aimState = tool:FindFirstChild("Aim")
    if aimState and aimState.Value then return true end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

-- Actualizar ESP para un jugador
function ProfessionalESP:Update(player)
    local esp = self.Players[player]
    if not esp then return end

    local character = player.Character
    if not character then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    -- Usar caché de partes para rendimiento
    local humanoid = esp.Cache.Humanoid or character:FindFirstChild("Humanoid")
    local head = esp.Cache.Head or character:FindFirstChild("Head")
    local rootPart = esp.Cache.HumanoidRootPart or character:FindFirstChild("HumanoidRootPart")

    -- Actualizar caché si es necesario
    if not esp.Cache.Humanoid then esp.Cache.Humanoid = humanoid end
    if not esp.Cache.Head then esp.Cache.Head = head end
    if not esp.Cache.HumanoidRootPart then esp.Cache.HumanoidRootPart = rootPart end

    if not humanoid or not head or not rootPart then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)

    -- Determinar color según equipo
    local color = self.Settings.EnemyColor
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        color = self.Settings.AllyColor
    end

    -- Calcular distancia
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > self.Settings.MaxDistance then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    -- Verificar si el jugador está apuntando
    local isAiming = self:IsAiming()
    local fadeFactor = isAiming and 0.3 or 1.0

    -- --- LÓGICA DE DIBUJO ---
    
    -- Si está fuera de pantalla, mostrar flecha y ocultar el resto
    if not headOnScreen then
        if self.Settings.OffScreenArrows then
            local screenCenter = Camera.ViewportSize / 2
            local angle = math.atan2(rootPos.Y - screenCenter.Y, rootPos.X - screenCenter.X)
            local arrowLength = 30
            local arrowTip = Vector2.new(
                screenCenter.X + math.cos(angle) * (screenCenter.Magnitude - 50),
                screenCenter.Y + math.sin(angle) * (screenCenter.Magnitude - 50)
            )
            local arrowBase = Vector2.new(
                arrowTip.X - math.cos(angle) * arrowLength,
                arrowTip.Y - math.sin(angle) * arrowLength
            )
            
            esp.OffScreenArrow.From = arrowBase
            esp.OffScreenArrow.To = arrowTip
            esp.OffScreenArrow.Color = color
            esp.OffScreenArrow.Visible = true
        end

        -- Ocultar todo lo demás
        for _, drawing in pairs(esp.Drawings) do
            if drawing ~= esp.OffScreenArrow then
                drawing.Visible = false
            end
        end
        return
    else
        esp.OffScreenArrow.Visible = false
    end

    -- Calcular tamaño de la caja
    local fovRad = math.rad(Camera.FieldOfView / 2)
    local scaleFactor = 1 / (headPos.Z * math.tan(fovRad)) * 1000
    local width = math.floor(40 * scaleFactor)
    local height = math.floor(65 * scaleFactor)
    local position = Vector2.new(headPos.X, headPos.Y) - Vector2.new(width / 2, height / 2)

    -- Actualizar Caja (Normal o Esquina)
    if self.Settings.Boxes then
        if self.Settings.CornerBoxes then
            local cornerLength = width / 4
            esp.Box.Visible = false; esp.BoxOutline.Visible = false
            -- Esquina superior izquierda
            esp.Corner1.From = position; esp.Corner1.To = position + Vector2.new(cornerLength, 0)
            esp.Corner2.From = position; esp.Corner2.To = position + Vector2.new(0, cornerLength)
            -- Esquina inferior derecha
            esp.Corner3.From = position + Vector2.new(width, height); esp.Corner3.To = position + Vector2.new(width - cornerLength, height)
            esp.Corner4.From = position + Vector2.new(width, height); esp.Corner4.To = position + Vector2.new(width, height - cornerLength)
            esp.Corner1.Visible = true; esp.Corner2.Visible = true; esp.Corner3.Visible = true; esp.Corner4.Visible = true
            esp.Corner1.Color = color; esp.Corner2.Color = color; esp.Corner3.Color = color; esp.Corner4.Color = color
            esp.Corner1.Transparency = fadeFactor; esp.Corner2.Transparency = fadeFactor; esp.Corner3.Transparency = fadeFactor; esp.Corner4.Transparency = fadeFactor
        else
            esp.BoxOutline.Visible = true; esp.Box.Visible = true
            esp.Corner1.Visible = false; esp.Corner2.Visible = false; esp.Corner3.Visible = false; esp.Corner4.Visible = false
            esp.BoxOutline.Position = position - Vector2.new(1, 1)
            esp.BoxOutline.Size = Vector2.new(width + 2, height + 2)
            esp.BoxOutline.Transparency = fadeFactor
            esp.Box.Position = position
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Color = color
            esp.Box.Transparency = fadeFactor
        end
    else
        esp.Box.Visible = false; esp.BoxOutline.Visible = false
        esp.Corner1.Visible = false; esp.Corner2.Visible = false; esp.Corner3.Visible = false; esp.Corner4.Visible = false
    end

    -- Actualizar Barra de Salud
    if self.Settings.HealthBars then
        local health = humanoid.Health / humanoid.MaxHealth
        local barWidth = 4
        local barHeight = height * health
        
        esp.HealthBarOutline.Visible = true
        esp.HealthBarOutline.Position = position - Vector2.new(6, 0)
        esp.HealthBarOutline.Size = Vector2.new(barWidth + 2, height + 2)
        esp.HealthBarOutline.Transparency = fadeFactor
        
        esp.HealthBar.Visible = true
        esp.HealthBar.Position = position - Vector2.new(5, 0) + Vector2.new(0, height - barHeight)
        esp.HealthBar.Size = Vector2.new(barWidth, barHeight)
        esp.HealthBar.Color = Color3.new(1 - health, health, 0)
        esp.HealthBar.Transparency = fadeFactor
    else
        esp.HealthBarOutline.Visible = false
        esp.HealthBar.Visible = false
    end

    -- Actualizar Nombre y Arma
    local yOffset = 0
    if self.Settings.Names then
        esp.NameText.Visible = not isAiming
        esp.NameText.Text = player.Name
        esp.NameText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2)
        esp.NameText.Color = color
        esp.NameText.Transparency = fadeFactor
        yOffset = self.Settings.TextSize + 2
    else
        esp.NameText.Visible = false
    end

    if self.Settings.Weapon then
        local tool = character:FindFirstChildOfClass("Tool")
        local weaponName = tool and tool.Name or "Sin Arma"
        esp.WeaponText.Visible = not isAiming
        esp.WeaponText.Text = "[" .. weaponName .. "]"
        esp.WeaponText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2 - yOffset)
        esp.WeaponText.Color = Color3.new(0.8, 0.8, 0.8)
        esp.WeaponText.Transparency = fadeFactor
        yOffset = yOffset + self.Settings.TextSize - 2
    else
        esp.WeaponText.Visible = false
    end

    -- Actualizar Distancia
    if self.Settings.Distance then
        esp.DistanceText.Visible = not isAiming
        esp.DistanceText.Text = string.format("[%d m]", distance)
        esp.DistanceText.Position = position + Vector2.new(width / 2, height + 2)
        esp.DistanceText.Transparency = fadeFactor
    else
        esp.DistanceText.Visible = false
    end

    -- Actualizar Tracer
    if self.Settings.Tracers then
        esp.Tracer.Visible = true
        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Transparency = fadeFactor
    else
        esp.Tracer.Visible = false
    end
end

-- Eliminar ESP de un jugador
function ProfessionalESP:Remove(player)
    local esp = self.Players[player]
    if esp then
        for _, conn in pairs(esp.Connections) do
            conn:Disconnect()
        end
        for _, drawing in pairs(esp.Drawings) do
            drawing:Remove()
        end
        self.Players[player] = nil
    end
end

-- Actualizar todos los ESPs
function ProfessionalESP:UpdateAll()
    for player in pairs(self.Players) do
        self:Update(player)
    end
end

-- Alternar ESP
function ProfessionalESP:Toggle(state)
    self.Enabled = state
    
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self:Create(player)
            end
        end
        
        self.PlayerAdded = Players.PlayerAdded:Connect(function(player)
            self:Create(player)
        end)
        
        self.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            self:Remove(player)
        end)
        
        self.UpdateLoop = RunService.RenderStepped:Connect(function()
            self:UpdateAll()
        end)
    else
        if self.PlayerAdded then self.PlayerAdded:Disconnect() end
        if self.PlayerRemoving then self.PlayerRemoving:Disconnect() end
        if self.UpdateLoop then self.UpdateLoop:Disconnect() end
        
        for player in pairs(self.Players) do
            self:Remove(player)
        end
    end
end

-- === MENÚ DE CONFIGURACIÓN ===
local function createConfigGui()
    if configGui then
        configGui.Enabled = not configGui.Enabled
        return
    end

    configGui = Instance.new("ScreenGui")
    configGui.Name = "ESPConfigGui"
    configGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    configGui.ResetOnSpawn = false
    configGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    configFrame = Instance.new("Frame")
    configFrame.Size = UDim2.new(0, 320, 0, 500)
    configFrame.Position = UDim2.new(0.5, -160, 0.5, -250)
    configFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = configGui
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "CONFIGURACIÓN ESP"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = configFrame

    local function createToggle(optionName, yPos)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 30)
        button.Position = UDim2.new(0, 10, 0, yPos)
        button.Text = optionName .. ": " .. (ProfessionalESP.Settings[optionName] and "ON" or "OFF")
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.BackgroundColor3 = ProfessionalESP.Settings[optionName] and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
        button.BorderSizePixel = 0
        button.Parent = configFrame
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)

        button.MouseButton1Click:Connect(function()
            ProfessionalESP.Settings[optionName] = not ProfessionalESP.Settings[optionName]
            button.Text = optionName .. ": " .. (ProfessionalESP.Settings[optionName] and "ON" or "OFF")
            button.BackgroundColor3 = ProfessionalESP.Settings[optionName] and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
        end)
    end

    local toggleOptions = {"Boxes", "CornerBoxes", "Names", "HealthBars", "Tracers", "Distance", "Weapon", "OffScreenArrows", "TeamCheck"}
    for i, option in ipairs(toggleOptions) do
        createToggle(option, 50 + (i-1) * 35)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == CONFIG_KEY then
        createConfigGui()
    end
end)

-- API para integrar con DrakHub
return {
    activate = function()
        ProfessionalESP:Toggle(true)
    end,
    deactivate = function()
        ProfessionalESP:Toggle(false)
    end,
    updateSettings = function(settings)
        for k, v in pairs(settings) do
            if ProfessionalESP.Settings[k] ~= nil then
                ProfessionalESP.Settings[k] = v
            end
        end
    end
}
