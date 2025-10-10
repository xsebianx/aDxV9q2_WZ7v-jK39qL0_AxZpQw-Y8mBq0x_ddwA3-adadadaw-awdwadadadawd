-- esp.txt
-- ESP Minimalista y Táctico para DrakHub Premium
-- ADVERTENCIA: Este script proporciona una ventaja injusta y es considerado trampa.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de scripting en Lua.

local ProfessionalESP = {
    Enabled = false,
    Players = {},
    ClosestPlayer = nil, -- Para el ESP inteligente
    Settings = {
        -- Configuración Minimalista por Defecto
        Boxes = false,
        CornerBoxes = true, -- Estilo limpio por defecto
        Names = true,
        HealthBars = false, -- Desactivado para reducir desorden
        Tracers = false,    -- Desactivado para reducir desorden
        Distance = false,   -- Desactivado para reducir desorden
        Weapon = true,
        OffScreenArrows = true,
        TeamCheck = true,
        -- Paleta de colores profesional y sutil
        AllyColor = Color3.fromRGB(150, 200, 255), -- Azul claro
        EnemyColor = Color3.fromRGB(200, 200, 200), -- Gris claro
        ClosestEnemyColor = Color3.fromRGB(255, 255, 255), -- Blanco brillante para el más cercano
        TextSize = 12, -- Texto más pequeño
        Font = 2,
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

-- Función para encontrar al jugador más cercano
function ProfessionalESP:FindClosestPlayer()
    local closestDistance = math.huge
    local closestPlayer = nil
    local myChar = LocalPlayer.Character
    if not myChar or not myChar.PrimaryPart then return nil end
    
    local myRootPos = myChar.PrimaryPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local char = player.Character
        if char and char.PrimaryPart then
            local distance = (char.PrimaryPart.Position - myRootPos).Magnitude
            if distance < closestDistance and distance < self.Settings.MaxDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    self.ClosestPlayer = closestPlayer
end

-- Función para crear un ESP para un jugador
function ProfessionalESP:Create(player)
    if self.Players[player] then return end

    local esp = {
        Player = player,
        Connections = {},
        Drawings = {},
        Cache = {}
    }
    self.Players[player] = esp

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

    -- Caja (Estilo esquina)
    esp.Corner1 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor, Visible = false })
    esp.Corner2 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor, Visible = false })
    esp.Corner3 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor, Visible = false })
    esp.Corner4 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor, Visible = false })

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
    esp.WeaponText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize - 1,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.fromRGB(1, 1, 1),
        Font = self.Settings.Font,
        Visible = false
    })

    -- Flecha fuera de pantalla
    esp.OffScreenArrow = createDrawing("Line", {
        Thickness = 1.5,
        Color = self.Settings.EnemyColor,
        Visible = false
    })

    esp.Connections.CharacterAdded = player.CharacterAdded:Connect(function()
        self:Update(player)
    end)

    if player.Character then
        self:Update(player)
    end
end

function ProfessionalESP:IsAiming()
    if not LocalPlayer.Character then return false end
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

function ProfessionalESP:Update(player)
    local esp = self.Players[player]
    if not esp then return end

    local character = player.Character
    if not character then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    local humanoid = esp.Cache.Humanoid or character:FindFirstChild("Humanoid")
    local head = esp.Cache.Head or character:FindFirstChild("Head")
    local rootPart = esp.Cache.HumanoidRootPart or character:FindFirstChild("HumanoidRootPart")

    if not esp.Cache.Humanoid then esp.Cache.Humanoid = humanoid end
    if not esp.Cache.Head then esp.Cache.Head = head end
    if not esp.Cache.HumanoidRootPart then esp.Cache.HumanoidRootPart = rootPart end

    if not humanoid or not head or not rootPart then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)

    -- Determinar color y si es el más cercano
    local isClosest = (player == self.ClosestPlayer)
    local color = self.Settings.EnemyColor
    if isClosest then
        color = self.Settings.ClosestEnemyColor
    elseif self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        color = self.Settings.AllyColor
    end
    
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > self.Settings.MaxDistance then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    -- Factor de transparencia: más brillante si está cerca, más desvanecido si está lejos
    local fadeFactor = isClosest and 1.0 or 0.4
    local isAiming = self:IsAiming()
    if isAiming then fadeFactor = fadeFactor * 0.3 end

    -- Lógica de dibujo
    if not headOnScreen then
        if self.Settings.OffScreenArrows then
            local screenCenter = Camera.ViewportSize / 2
            local angle = math.atan2(rootPos.Y - screenCenter.Y, rootPos.X - screenCenter.X)
            local arrowLength = 25
            local arrowTip = Vector2.new(
                screenCenter.X + math.cos(angle) * (screenCenter.Magnitude - 40),
                screenCenter.Y + math.sin(angle) * (screenCenter.Magnitude - 40)
            )
            local arrowBase = Vector2.new(
                arrowTip.X - math.cos(angle) * arrowLength,
                arrowTip.Y - math.sin(angle) * arrowLength
            )
            esp.OffScreenArrow.From = arrowBase
            esp.OffScreenArrow.To = arrowTip
            esp.OffScreenArrow.Color = color
            esp.OffScreenArrow.Transparency = fadeFactor
            esp.OffScreenArrow.Visible = true
        end
        for _, drawing in pairs(esp.Drawings) do
            if drawing ~= esp.OffScreenArrow then drawing.Visible = false end
        end
        return
    else
        esp.OffScreenArrow.Visible = false
    end

    -- Escalado más inteligente para evitar cajas gigantes
    local fovRad = math.rad(Camera.FieldOfView / 2)
    local scaleFactor = 1 / (headPos.Z * math.tan(fovRad)) * 800 -- Reducido de 1000
    local width = math.floor(30 * scaleFactor) -- Reducido de 40
    local height = math.floor(50 * scaleFactor) -- Reducido de 65
    local position = Vector2.new(headPos.X, headPos.Y) - Vector2.new(width / 2, height / 2)

    -- Actualizar Caja de Esquina
    if self.Settings.CornerBoxes then
        local cornerLength = width / 3
        esp.Corner1.From = position; esp.Corner1.To = position + Vector2.new(cornerLength, 0)
        esp.Corner2.From = position; esp.Corner2.To = position + Vector2.new(0, cornerLength)
        esp.Corner3.From = position + Vector2.new(width, height); esp.Corner3.To = position + Vector2.new(width - cornerLength, height)
        esp.Corner4.From = position + Vector2.new(width, height); esp.Corner4.To = position + Vector2.new(width, height - cornerLength)
        
        for _, corner in pairs({esp.Corner1, esp.Corner2, esp.Corner3, esp.Corner4}) do
            corner.Visible = true
            corner.Color = color
            corner.Transparency = fadeFactor
        end
    else
        for _, corner in pairs({esp.Corner1, esp.Corner2, esp.Corner3, esp.Corner4}) do
            corner.Visible = false
        end
    end

    -- Actualizar Nombre y Arma (solo en el más cercano para reducir desorden)
    local yOffset = 0
    if self.Settings.Names and isClosest then
        esp.NameText.Visible = not isAiming
        esp.NameText.Text = player.Name
        esp.NameText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2)
        esp.NameText.Color = color
        esp.NameText.Transparency = fadeFactor
        yOffset = self.Settings.TextSize + 2
    else
        esp.NameText.Visible = false
    end

    if self.Settings.Weapon and isClosest then
        local tool = character:FindFirstChildOfClass("Tool")
        local weaponName = tool and tool.Name or "Sin Arma"
        esp.WeaponText.Visible = not isAiming
        esp.WeaponText.Text = "[" .. weaponName .. "]"
        esp.WeaponText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2 - yOffset)
        esp.WeaponText.Color = Color3.new(0.7, 0.7, 0.7)
        esp.WeaponText.Transparency = fadeFactor
    else
        esp.WeaponText.Visible = false
    end
end

function ProfessionalESP:Remove(player)
    local esp = self.Players[player]
    if esp then
        for _, conn in pairs(esp.Connections) do conn:Disconnect() end
        for _, drawing in pairs(esp.Drawings) do drawing:Remove() end
        self.Players[player] = nil
    end
end

function ProfessionalESP:UpdateAll()
    -- Primero, encontrar al más cercano
    self:FindClosestPlayer()
    -- Luego, actualizar a todos con esa información
    for player in pairs(self.Players) do
        self:Update(player)
    end
end

function ProfessionalESP:Toggle(state)
    self.Enabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then self:Create(player) end
        end
        self.PlayerAdded = Players.PlayerAdded:Connect(function(player) self:Create(player) end)
        self.PlayerRemoving = Players.PlayerRemoving:Connect(function(player) self:Remove(player) end)
        self.UpdateLoop = RunService.RenderStepped:Connect(function() self:UpdateAll() end)
    else
        if self.PlayerAdded then self.PlayerAdded:Disconnect() end
        if self.PlayerRemoving then self.PlayerRemoving:Disconnect() end
        if self.UpdateLoop then self.UpdateLoop:Disconnect() end
        for player in pairs(self.Players) do self:Remove(player) end
        self.ClosestPlayer = nil
    end
end

-- === MENÚ DE CONFIGURACIÓN CON PREAJUSTES (COMPLETO) ===
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

    -- Botón de Preajuste Minimalista
    local presetButton = Instance.new("TextButton")
    presetButton.Size = UDim2.new(1, -20, 0, 35)
    presetButton.Position = UDim2.new(0, 10, 0, 380)
    presetButton.Text = "Aplicar Modo Minimalista"
    presetButton.TextColor3 = Color3.new(1, 1, 1)
    presetButton.Font = Enum.Font.GothamBold
    presetButton.TextSize = 14
    presetButton.BackgroundColor3 = Color3.fromRGB(0, 0.4, 0.8)
    presetButton.BorderSizePixel = 0
    presetButton.Parent = configFrame
    Instance.new("UICorner", presetButton).CornerRadius = UDim.new(0, 5)

    presetButton.MouseButton1Click:Connect(function()
        -- Aplicar configuración minimalista
        ProfessionalESP.Settings.Boxes = false
        ProfessionalESP.Settings.CornerBoxes = true
        ProfessionalESP.Settings.Names = true
        ProfessionalESP.Settings.HealthBars = false
        ProfessionalESP.Settings.Tracers = false
        ProfessionalESP.Settings.Distance = false
        ProfessionalESP.Settings.Weapon = true
        ProfessionalESP.Settings.OffScreenArrows = true
        
        -- Actualizar texto de los botones (requiere refrescar la GUI)
        configGui:Destroy()
        configGui = nil
        createConfigGui() -- Re-abre la GUI con los nuevos valores
    end)
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
        -- <<< INICIO DE LA CORRECCIÓN >>>
        -- Asegurarse de que la GUI de configuración también se destruya
        if configGui then
            configGui:Destroy()
            configGui = nil
            configFrame = nil
        end
        -- <<< FIN DE LA CORRECCIÓN >>>
    end,
    updateSettings = function(settings)
        for k, v in pairs(settings) do
            if ProfessionalESP.Settings[k] ~= nil then
                ProfessionalESP.Settings[k] = v
            end
        end
    end
}
