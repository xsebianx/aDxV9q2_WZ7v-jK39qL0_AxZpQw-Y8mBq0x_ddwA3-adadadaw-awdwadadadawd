-- esp.txtss
-- ESP Simple y Funcional
-- ADVERTENCIA: Este script proporciona una ventaja injusta y es considerado trampa.
-- Se proporciona únicamente con fines educativos para demostrar técnicas de scripting en Lua.

local SimpleESP = {
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
local inputBeganConnection = nil -- Guardamos la conexión para poder desconectarla
local CONFIG_KEY = Enum.KeyCode.F4

-- Función para crear un ESP para un jugador
function SimpleESP:Create(player)
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

    -- Caja
    esp.BoxOutline = createDrawing("Square", { Thickness = 2, Color = Color3.new(0, 0, 0), Filled = false })
    esp.Box = createDrawing("Square", { Thickness = 1, Color = self.Settings.EnemyColor, Filled = false })

    -- Barra de salud
    esp.HealthBarOutline = createDrawing("Square", { Thickness = 1, Color = Color3.new(0, 0, 0), Filled = false })
    esp.HealthBar = createDrawing("Square", { Thickness = 1, Color = Color3.new(0, 1, 0), Filled = true })

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
function SimpleESP:Update(player)
    local esp = self.Players[player]
    if not esp then return end

    local character = player.Character
    if not character then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not head or not rootPart then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    -- Determinar color
    local color = self.Settings.EnemyColor
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        color = self.Settings.AllyColor
    end

    -- Calcular tamaño y posición
    local scaleFactor = 1000 / headPos.Z
    local width = 40 * scaleFactor
    local height = 60 * scaleFactor
    local position = Vector2.new(headPos.X - width / 2, headPos.Y - height / 2)

    -- Calcular distancia
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > self.Settings.MaxDistance then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    -- --- DIBUJAR ---
    
    -- Caja
    if self.Settings.Boxes then
        esp.BoxOutline.Visible = true
        esp.BoxOutline.Position = position - Vector2.new(1, 1)
        esp.BoxOutline.Size = Vector2.new(width + 2, height + 2)
        
        esp.Box.Visible = true
        esp.Box.Position = position
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Color = color
    else
        esp.BoxOutline.Visible = false
        esp.Box.Visible = false
    end

    -- Barra de salud
    if self.Settings.HealthBars then
        local health = humanoid.Health / humanoid.MaxHealth
        local barWidth = 4
        local barHeight = height * health
        
        esp.HealthBarOutline.Visible = true
        esp.HealthBarOutline.Position = position - Vector2.new(6, 0)
        esp.HealthBarOutline.Size = Vector2.new(barWidth + 2, height + 2)
        
        esp.HealthBar.Visible = true
        esp.HealthBar.Position = position - Vector2.new(5, 0) + Vector2.new(0, height - barHeight)
        esp.HealthBar.Size = Vector2.new(barWidth, barHeight)
        esp.HealthBar.Color = Color3.new(1 - health, health, 0)
    else
        esp.HealthBarOutline.Visible = false
        esp.HealthBar.Visible = false
    end

    -- Nombre
    if self.Settings.Names then
        esp.NameText.Visible = true
        esp.NameText.Text = player.Name
        esp.NameText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2)
        esp.NameText.Color = color
    else
        esp.NameText.Visible = false
    end

    -- Distancia
    if self.Settings.Distance then
        esp.DistanceText.Visible = true
        esp.DistanceText.Text = string.format("[%d]", distance)
        esp.DistanceText.Position = position + Vector2.new(width / 2, height + 2)
    else
        esp.DistanceText.Visible = false
    end
end

-- Eliminar ESP de un jugador
function SimpleESP:Remove(player)
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
function SimpleESP:UpdateAll()
    for player in pairs(self.Players) do
        self:Update(player)
    end
end

-- Alternar ESP
function SimpleESP:Toggle(state)
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
        button.Text = optionName .. ": " .. (SimpleESP.Settings[optionName] and "ON" or "OFF")
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.Gotham
        button.TextSize = 13
        button.BackgroundColor3 = SimpleESP.Settings[optionName] and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
        button.BorderSizePixel = 0
        button.Parent = configFrame
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

        button.MouseButton1Click:Connect(function()
            SimpleESP.Settings[optionName] = not SimpleESP.Settings[optionName]
            button.Text = optionName .. ": " .. (SimpleESP.Settings[optionName] and "ON" or "OFF")
            button.BackgroundColor3 = SimpleESP.Settings[optionName] and Color3.new(0, 0.5, 0) or Color3.new(0.5, 0, 0)
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
        SimpleESP:Toggle(true)
        -- Conectar el evento de la tecla F4 al activar
        if not inputBeganConnection then
            inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == CONFIG_KEY then
                    createConfigGui()
                end
            end)
        end
    end,
    
    deactivate = function()
        -- 1. Desactivar el ESP
        SimpleESP:Toggle(false)
        
        -- 2. Desconectar el evento de F4 para que no se pueda abrir más
        if inputBeganConnection then
            inputBeganConnection:Disconnect()
            inputBeganConnection = nil
        end
        
        -- 3. Destruir la GUI de configuración si existe
        if configGui then
            configGui:Destroy()
            configGui = nil
            configFrame = nil
        end
    end,
    
    updateSettings = function(settings)
        for k, v in pairs(settings) do
            if SimpleESP.Settings[k] ~= nil then
                SimpleESP.Settings[k] = v
            end
        end
    end
}
