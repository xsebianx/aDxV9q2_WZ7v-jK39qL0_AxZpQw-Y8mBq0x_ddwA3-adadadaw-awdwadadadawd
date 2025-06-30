-- ESP Profesional para DrakHub Premium (Versión Completa Corregida)
local ProfessionalESP = {
    Enabled = false,
    Players = {},
    Settings = {
        Boxes = true,
        Names = true,
        HealthBars = true,
        Tracers = true,
        Distance = true,
        TeamCheck = true,
        AllyColor = Color3.fromRGB(0, 255, 0),
        EnemyColor = Color3.fromRGB(255, 50, 50),
        TextSize = 14,
        Font = 2, -- 0: UI, 1: System, 2: Plex, 3: Monospace
        MaxDistance = 3000
    }
}

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Mapeo de fuentes numéricas
local FontMapping = {
    [0] = Drawing.Fonts.UI,
    [1] = Drawing.Fonts.System,
    [2] = Drawing.Fonts.Plex,
    [3] = Drawing.Fonts.Monospace
}

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
            if prop == "Font" then
                drawing[prop] = FontMapping[value] or FontMapping[2] -- Default to Plex
            else
                drawing[prop] = value
            end
        end
        table.insert(esp.Drawings, drawing)
        return drawing
    end

    -- Caja
    esp.BoxOutline = createDrawing("Square", {
        Thickness = 3,
        Color = Color3.new(0, 0, 0),
        Filled = false
    })

    esp.Box = createDrawing("Square", {
        Thickness = 1,
        Color = self.Settings.EnemyColor,
        Filled = false
    })

    -- Barra de salud
    esp.HealthBarOutline = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(0, 0, 0),
        Filled = false
    })

    esp.HealthBar = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(0, 1, 0),
        Filled = true
    })

    -- Textos
    esp.NameText = createDrawing("Text", {
        Text = player.Name,
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font
    })

    esp.DistanceText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font
    })

    -- Tracer
    esp.Tracer = createDrawing("Line", {
        Thickness = 1,
        Color = self.Settings.EnemyColor
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
    
    -- Verificar si tiene un arma equipada
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    -- Verificar si el arma tiene un estado de apuntado
    local aimState = tool:FindFirstChild("Aim")
    if aimState and aimState.Value then
        return true
    end
    
    -- Verificar si está presionando el botón derecho
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

    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not head or not rootPart then 
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end

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

    -- Calcular tamaño de la caja (CORRECCIÓN APLICADA)
    local fovRad = math.rad(Camera.FieldOfView / 2)
    local scaleFactor = 1 / (headPos.Z * math.tan(fovRad)) * 1000
    local width = math.floor(40 * scaleFactor)
    local height = math.floor(65 * scaleFactor)
    local position = Vector2.new(headPos.X, headPos.Y) - Vector2.new(width / 2, height / 2)

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
    local fadeFactor = isAiming and 0.3 or 1.0  -- Factor de transparencia
    
    -- Actualizar caja
    if self.Settings.Boxes then
        esp.BoxOutline.Visible = true
        esp.BoxOutline.Position = position - Vector2.new(1, 1)
        esp.BoxOutline.Size = Vector2.new(width + 2, height + 2)
        esp.BoxOutline.Transparency = fadeFactor
        
        esp.Box.Visible = true
        esp.Box.Position = position
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Color = color
        esp.Box.Transparency = fadeFactor
    else
        esp.BoxOutline.Visible = false
        esp.Box.Visible = false
    end

    -- Actualizar barra de salud
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

    -- Actualizar nombre
    esp.NameText.Visible = self.Settings.Names and not isAiming  -- Ocultar nombre al apuntar
    esp.NameText.Text = player.Name
    esp.NameText.Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2)
    esp.NameText.Color = color
    esp.NameText.Transparency = fadeFactor

    -- Actualizar distancia
    esp.DistanceText.Visible = self.Settings.Distance and not isAiming  -- Ocultar distancia al apuntar
    esp.DistanceText.Text = string.format("[%d]", distance)
    esp.DistanceText.Position = position + Vector2.new(width / 2, height + 2)
    esp.DistanceText.Transparency = fadeFactor

    -- Actualizar tracer
    esp.Tracer.Visible = self.Settings.Tracers
    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
    esp.Tracer.Color = color
    esp.Tracer.Transparency = fadeFactor
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
