-- esp.txt
-- ESP con Cajas Precisas y Barra de Vida Moderna
-- ADVERTENCIA: Este script proporciona una ventaja injusta y es considerado trampa.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de scripting en Lua.

local ModernESP = {
    Enabled = false,
    Players = {},
    Settings = {
        Boxes = true,
        Names = true,
        HealthBars = true,
        Distance = true,
        TeamCheck = true,
        EnemyColor = Color3.fromRGB(255, 50, 50),
        AllyColor = Color3.fromRGB(0, 255, 0),
        TextSize = 13,
        MaxDistance = 1000
    }
}

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI de Configuración
local configGui = nil
local configFrame = nil
local inputBeganConnection = nil
local CONFIG_KEY = Enum.KeyCode.F4

-- Función para crear un ESP para un jugador
function ModernESP:Create(player)
    if self.Players[player] then return end

    local esp = {
        Player = player,
        Connections = {},
        Drawings = {}
    }
    self.Players[player] = esp

    local function createDrawing(type, props)
        local drawing = Drawing.new(type)
        for prop, value in pairs(props) do
            drawing[prop] = value
        end
        table.insert(esp.Drawings, drawing)
        return drawing
    end

    -- Caja de Esquina (4 líneas)
    esp.Corner1 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor })
    esp.Corner2 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor })
    esp.Corner3 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor })
    esp.Corner4 = createDrawing("Line", { Thickness = 1.5, Color = self.Settings.EnemyColor })

    -- NUEVA: Barra de Vida Moderna (Horizontal)
    esp.HealthBarBg = createDrawing("Square", { Thickness = 0, Color = Color3.fromRGB(30, 30, 30), Filled = true })
    esp.HealthBarFill = createDrawing("Square", { Thickness = 0, Color = Color3.fromRGB(0, 1, 0), Filled = true })

    -- Textos
    esp.NameText = createDrawing("Text", {
        Text = player.Name,
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = Drawing.Fonts.UI
    })
    esp.DistanceText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = Drawing.Fonts.UI
    })

    -- Conectar eventos
    esp.Connections.CharacterAdded = player.CharacterAdded:Connect(function()
        self:Update(player)
    end)

    if player.Character then
        self:Update(player)
    end
end

-- Actualizar ESP para un jugador
function ModernESP:Update(player)
    local esp = self.Players[player]
    if not esp then return end

    local character = player.Character
    if not character then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local feet = character:FindFirstChild("LeftFoot") or character:FindFirstChild("RightFoot") or rootPart

    if not humanoid or not head or not rootPart or not feet then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    -- NUEVO: Cálculo de caja preciso
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    local feetPos = Camera:WorldToViewportPoint(feet.Position)
    
    if not onScreen then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    local boxHeight = math.abs(headPos.Y - feetPos.Y)
    local boxWidth = boxHeight * 0.6 -- Proporción estándar
    local boxCenter = Vector2.new(headPos.X, (headPos.Y + feetPos.Y) / 2)
    local position = boxCenter - Vector2.new(boxWidth / 2, boxHeight / 2)

    -- Determinar color
    local color = self.Settings.EnemyColor
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        color = self.Settings.AllyColor
    end

    -- Calcular distancia
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > self.Settings.MaxDistance then
        for _, drawing in pairs(esp.Drawings) do drawing.Visible = false end
        return
    end

    -- --- DIBUJAR ---
    
    -- NUEVO: Dibujar Caja de Esquina
    if self.Settings.Boxes then
        local cornerLength = boxWidth / 3
        local corners = {
            {From = position, To = position + Vector2.new(cornerLength, 0)},
            {From = position, To = position + Vector2.new(0, cornerLength)},
            {From = position + Vector2.new(boxWidth, boxHeight), To = position + Vector2.new(boxWidth - cornerLength, boxHeight)},
            {From = position + Vector2.new(boxWidth, boxHeight), To = position + Vector2.new(boxWidth, boxHeight - cornerLength)}
        }
        esp.Corner1.From = corners[1].From; esp.Corner1.To = corners[1].To
        esp.Corner2.From = corners[2].From; esp.Corner2.To = corners[2].To
        esp.Corner3.From = corners[3].From; esp.Corner3.To = corners[3].To
        esp.Corner4.From = corners[4].From; esp.Corner4.To = corners[4].To

        for _, corner in pairs({esp.Corner1, esp.Corner2, esp.Corner3, esp.Corner4}) do
            corner.Visible = true
            corner.Color = color
        end
    else
        for _, corner in pairs({esp.Corner1, esp.Corner2, esp.Corner3, esp.Corner4}) do
            corner.Visible = false
        end
    end

    -- NUEVO: Dibujar Barra de Vida Horizontal
    if self.Settings.HealthBars then
        local health = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barWidth = boxWidth
        local barHeight = 4
        local barY = position.Y - self.Settings.TextSize - 6 -- Justo encima de la caja
        
        esp.HealthBarBg.Visible = true
        esp.HealthBarBg.Position = Vector2.new(boxCenter.X - barWidth / 2, barY)
        esp.HealthBarBg.Size = Vector2.new(barWidth, barHeight)

        esp.HealthBarFill.Visible = true
        esp.HealthBarFill.Position = Vector2.new(boxCenter.X - barWidth / 2, barY)
        esp.HealthBarFill.Size = Vector2.new(barWidth * health, barHeight)
        esp.HealthBarFill.Color = Color3.new(1 - health, health, 0) -- Rojo a Verde
    else
        esp.HealthBarBg.Visible = false
        esp.HealthBarFill.Visible = false
    end

    -- Nombre (posicionado sobre la barra de vida)
    if self.Settings.Names then
        esp.NameText.Visible = true
        esp.NameText.Text = player.Name
        esp.NameText.Position = Vector2.new(boxCenter.X, position.Y - self.Settings.TextSize - 12)
        esp.NameText.Color = color
    else
        esp.NameText.Visible = false
    end

    -- Distancia
    if self.Settings.Distance then
        esp.DistanceText.Visible = true
        esp.DistanceText.Text = string.format("[%d m]", distance)
        esp.DistanceText.Position = Vector2.new(boxCenter.X, position.Y + boxHeight + 2)
    else
        esp.DistanceText.Visible = false
    end
end

-- Eliminar ESP de un jugador
function ModernESP:Remove(player)
    local esp = self.Players[player]
    if esp then
        for _, conn in pairs(esp.Connections) do conn:Disconnect() end
        for _, drawing in pairs(esp.Drawings) do drawing:Remove() end
        self.Players[player] = nil
    end
end

-- Actualizar todos los ESPs
function ModernESP:UpdateAll()
    for player in pairs(self.Players) do
        self:Update(player)
    end
end

-- Alternar ESP
function ModernESP:Toggle(state)
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
    end
end

-- === MENÚ DE CONFIGURACIÓN SIMPLE ===
local function createConfigGui()
    if configGui then
        configGui.Enabled = not configGui.Enabled
        return
    end

    configGui = Instance.new("ScreenGui")
    configGui.Name = "ESPConfigGui"
    configGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    configGui.ResetOnSpawn = false

    configFrame = Instance.new("Frame")
    configFrame.Size = UDim2.new(0, 250, 0, 200)
    configFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
    configFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = configGui
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "Configuración ESP"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.BackgroundTransparency = 1
    title.Parent = configFrame

    local function createToggle(optionName, yPos)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 30)
        button.Position = UDim2.new(0, 10, 0, yPos)
        button.Text = optionName .. ": " .. (ModernESP.Settings[optionName] and "ON" or "OFF")
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.Gotham
        button.TextSize = 13
        button.BackgroundColor3 = ModernESP.Settings[optionName] and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
        button.BorderSizePixel = 0
        button.Parent = configFrame
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

        button.MouseButton1Click:Connect(function()
            ModernESP.Settings[optionName] = not ModernESP.Settings[optionName]
            button.Text = optionName .. ": " .. (ModernESP.Settings[optionName] and "ON" or "OFF")
            button.BackgroundColor3 = ModernESP.Settings[optionName] and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
        end)
    end

    createToggle("Boxes", 40)
    createToggle("Names", 80)
    createToggle("HealthBars", 120)
    createToggle("Distance", 160)
end

-- === API PARA CONTROL EXTERNO ===
return {
    activate = function()
        ModernESP:Toggle(true)
        if not inputBeganConnection then
            inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == CONFIG_KEY then
                    createConfigGui()
                end
            end)
        end
    end,
    
    deactivate = function()
        ModernESP:Toggle(false)
        if inputBeganConnection then
            inputBeganConnection:Disconnect()
            inputBeganConnection = nil
        end
        if configGui then
            configGui:Destroy()
            configGui = nil
            configFrame = nil
        end
    end,
    
    updateSettings = function(settings)
        for k, v in pairs(settings) do
            if ModernESP.Settings[k] ~= nil then
                ModernESP.Settings[k] = v
            end
        end
    end
}
