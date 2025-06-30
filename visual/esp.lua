-- ESP Profesional para DrakHub Premium
local ProfessionalESP = {
    Enabled = false,
    Players = {},
    NPCs = {},
    Objects = {},
    Settings = {
        Boxes = true,
        BoxType = "2D", -- "2D" o "3D"
        Names = true,
        HealthBars = true,
        Tracers = true,
        Distance = true,
        TeamCheck = true, -- Mostrar enemigos en rojo
        AllyColor = Color3.fromRGB(0, 255, 0),
        EnemyColor = Color3.fromRGB(255, 50, 50),
        NPCColor = Color3.fromRGB(255, 255, 0),
        ObjectColor = Color3.fromRGB(100, 150, 255),
        MaxDistance = 1000, -- Distancia máxima de renderizado
        TextSize = 14,
        Font = Enum.Font.GothamBold
    }
}

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Función para crear un ESP para un jugador
function ProfessionalESP:Create(player)
    if self.Players[player] then return end

    local esp = {
        Player = player,
        Connections = {},
        Drawings = {}
    }
    self.Players[player] = esp

    -- Crear dibujos
    local function createDrawing(type, props)
        local drawing = Drawing.new(type)
        for prop, value in pairs(props) do
            drawing[prop] = value
        end
        table.insert(esp.Drawings, drawing)
        return drawing
    end

    esp.BoxOutline = createDrawing("Square", {
        Thickness = 3,
        Color = Color3.new(0, 0, 0),
        Transparency = 1,
        Filled = false
    })

    esp.Box = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(1, 1, 1),
        Transparency = 1,
        Filled = false
    })

    esp.HealthBarOutline = createDrawing("Line", {
        Thickness = 3,
        Color = Color3.new(0, 0, 0),
        Transparency = 1
    })

    esp.HealthBar = createDrawing("Line", {
        Thickness = 1,
        Color = Color3.new(1, 1, 1),
        Transparency = 1
    })

    esp.HealthText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font
    })

    esp.NameText = createDrawing("Text", {
        Text = player.Name,
        Size = self.Settings.TextSize,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font
    })

    esp.DistanceText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font
    })

    esp.Tracer = createDrawing("Line", {
        Thickness = 1,
        Color = Color3.new(1, 1, 1),
        Transparency = 1
    })

    -- Conectar eventos
    esp.Connections.CharacterAdded = player.CharacterAdded:Connect(function(character)
        self:Update(player)
    end)

    esp.Connections.HumanoidChanged = player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        if humanoid then
            esp.Connections.HealthChanged = humanoid.HealthChanged:Connect(function()
                self:Update(player)
            end)
        end
    end)

    self:Update(player)
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

    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not head or not rootPart then return end

    -- Calcular posición en pantalla
    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos = Camera:WorldToViewportPoint(rootPart.Position)

    if not headOnScreen then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

    -- Determinar color según equipo
    local color = self.Settings.EnemyColor
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        color = self.Settings.AllyColor
    end

    -- Calcular tamaño de la caja
    local headOffset = Vector2.new(0, 20)
    local rootOffset = Vector2.new(0, -30)
    local scaleFactor = 1 / (headPos.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
    local width = math.floor(40 * scaleFactor)
    local height = math.floor(65 * scaleFactor)
    local position = Vector2.new(headPos.X, headPos.Y) - Vector2.new(width / 2, height / 2) - headOffset

    -- Actualizar caja
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

    -- Actualizar barra de salud
    if self.Settings.HealthBars then
        local health = humanoid.Health / humanoid.MaxHealth
        local barHeight = height * health
        local barPosition = position + Vector2.new(-6, height - barHeight)

        esp.HealthBarOutline.Visible = true
        esp.HealthBarOutline.From = barPosition - Vector2.new(1, 0)
        esp.HealthBarOutline.To = barPosition + Vector2.new(0, barHeight) - Vector2.new(1, 0)
        
        esp.HealthBar.Visible = true
        esp.HealthBar.From = barPosition
        esp.HealthBar.To = barPosition + Vector2.new(0, barHeight)
        esp.HealthBar.Color = Color3.new(1 - health, health, 0)
        
        esp.HealthText.Visible = true
        esp.HealthText.Text = tostring(math.floor(humanoid.Health))
        esp.HealthText.Position = barPosition - Vector2.new(10, 0)
    else
        esp.HealthBarOutline.Visible = false
        esp.HealthBar.Visible = false
        esp.HealthText.Visible = false
    end

    -- Actualizar nombre
    esp.NameText.Visible = self.Settings.Names
    esp.NameText.Text = player.Name
    esp.NameText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2)

    -- Actualizar distancia
    if self.Settings.Distance then
        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        esp.DistanceText.Visible = true
        esp.DistanceText.Text = string.format("%d studs", distance)
        esp.DistanceText.Position = position + Vector2.new(width / 2, height + 2)
    else
        esp.DistanceText.Visible = false
    end

    -- Actualizar tracer
    if self.Settings.Tracers then
        esp.Tracer.Visible = true
        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
        esp.Tracer.Color = color
    else
        esp.Tracer.Visible = false
    end
end

-- Eliminar ESP de un jugador
function ProfessionalESP:Remove(player)
    local esp = self.Players[player]
    if esp then
        -- Desconectar eventos
        for _, conn in pairs(esp.Connections) do
            conn:Disconnect()
        end
        
        -- Eliminar dibujos
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
        -- Iniciar ESP para todos los jugadores
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self:Create(player)
            end
        end
        
        -- Conectar eventos para nuevos jugadores
        self.PlayerAdded = Players.PlayerAdded:Connect(function(player)
            self:Create(player)
        end)
        
        self.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            self:Remove(player)
        end)
        
        -- Loop de actualización
        self.UpdateLoop = RunService.RenderStepped:Connect(function()
            self:UpdateAll()
        end)
    else
        -- Desconectar eventos
        if self.PlayerAdded then
            self.PlayerAdded:Disconnect()
        end
        if self.PlayerRemoving then
            self.PlayerRemoving:Disconnect()
        end
        if self.UpdateLoop then
            self.UpdateLoop:Disconnect()
        end
        
        -- Eliminar todos los ESPs
        for player in pairs(self.Players) do
            self:Remove(player)
        end
    end
end

-- Actualizar configuraciones
function ProfessionalESP:UpdateSettings(settings)
    for setting, value in pairs(settings) do
        if self.Settings[setting] ~= nil then
            self.Settings[setting] = value
        end
    end
    self:UpdateAll()
end

-- API para integrar con DrakHub
return {
    activate = function()
        ProfessionalESP:Toggle(true)
    end,
    deactivate = function()
        ProfessionalESP:Toggle(false)
    end,
    updateSettings = function(settings)
        ProfessionalESP:UpdateSettings(settings)
    end
}
