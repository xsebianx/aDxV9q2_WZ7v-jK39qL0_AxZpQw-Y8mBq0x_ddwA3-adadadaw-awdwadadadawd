-- ESP Profesional para DrakHub Premium (Versión Mejorada)
local ProfessionalESP = {
    Enabled = false,
    Players = {},
    LastUpdate = 0,  -- Para optimización de rendimiento
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
        MaxDistance = 1000
    }
}

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Mapeo de fuentes numéricas
local FontMapping = {
    [0] = Drawing.Fonts.UI,
    [1] = Drawing.Fonts.System,
    [2] = Drawing.Fonts.Plex,
    [3] = Drawing.Fonts.Monospace
}

-- Función segura para evitar errores en dibujos
local function safeSet(drawing, props)
    pcall(function()
        for prop, value in pairs(props) do
            drawing[prop] = value
        end
    end)
end

-- Función para calcular tamaño dinámico de caja
local function calculateDynamicSize(character, headPos)
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not humanoid or not head then 
        return Vector2.new(40, 65)  -- Tamaño predeterminado
    end

    -- Calcular altura real del personaje
    local height = humanoid.HipHeight * 2 + head.Size.Y * 2
    local width = height * 0.6  -- Proporción ancho/altura
    
    -- Ajustar por distancia y FOV
    local scaleFactor = 1 / (headPos.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
    return Vector2.new(width * scaleFactor, height * scaleFactor)
end

-- Función para crear un ESP para un jugador
function ProfessionalESP:Create(player)
    if self.Players[player] then return end

    local esp = {
        Player = player,
        Connections = {},
        Drawings = {}
    }
    self.Players[player] = esp

    -- Función interna para crear dibujos con configuración inicial
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
        Filled = false,
        ZIndex = 1
    })

    esp.Box = createDrawing("Square", {
        Thickness = 1,
        Color = self.Settings.EnemyColor,
        Filled = false,
        ZIndex = 2
    })

    -- Barra de salud
    esp.HealthBarOutline = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(0, 0, 0),
        Filled = false,
        ZIndex = 3
    })

    esp.HealthBar = createDrawing("Square", {
        Thickness = 1,
        Color = Color3.new(0, 1, 0),
        Filled = true,
        ZIndex = 4
    })

    -- Textos
    esp.NameText = createDrawing("Text", {
        Text = player.Name,
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font,
        ZIndex = 5
    })

    esp.DistanceText = createDrawing("Text", {
        Text = "",
        Size = self.Settings.TextSize,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Color = Color3.new(1, 1, 1),
        Font = self.Settings.Font,
        ZIndex = 6
    })

    -- Tracer
    esp.Tracer = createDrawing("Line", {
        Thickness = 1,
        Color = self.Settings.EnemyColor,
        ZIndex = 7
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
function ProfessionalESP:Update(player)
    local esp = self.Players[player]
    if not esp then return end

    local character = player.Character
    if not character then
        for _, drawing in pairs(esp.Drawings) do
            safeSet(drawing, {Visible = false})
        end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not head or not rootPart then 
        for _, drawing in pairs(esp.Drawings) do
            safeSet(drawing, {Visible = false})
        end
        return
    end

    -- Calcular posición en pantalla
    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos = Camera:WorldToViewportPoint(rootPart.Position)

    if not headOnScreen then
        for _, drawing in pairs(esp.Drawings) do
            safeSet(drawing, {Visible = false})
        end
        return
    end

    -- Calcular tamaño dinámico de la caja
    local size = calculateDynamicSize(character, headPos)
    local width = math.floor(size.X)
    local height = math.floor(size.Y)
    local position = Vector2.new(headPos.X, headPos.Y) - Vector2.new(width / 2, height / 2)

    -- Calcular distancia
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > self.Settings.MaxDistance then
        for _, drawing in pairs(esp.Drawings) do
            safeSet(drawing, {Visible = false})
        end
        return
    end

    -- Determinar color base según equipo
    local baseColor = self.Settings.EnemyColor
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        baseColor = self.Settings.AllyColor
    end

    -- Configuración de color por estado (solo para enemigos)
    local boxColor = baseColor
    if not (self.Settings.TeamCheck and player.Team == LocalPlayer.Team) then
        local healthRatio = humanoid.Health / humanoid.MaxHealth
        if healthRatio < 0.3 then
            boxColor = Color3.new(1, 0.2, 0.2)  -- Rojo intenso
        elseif healthRatio < 0.6 then
            boxColor = Color3.new(1, 1, 0.4)    -- Amarillo
        end
    end

    -- Actualizar caja
    if self.Settings.Boxes then
        safeSet(esp.BoxOutline, {
            Visible = true,
            Position = position - Vector2.new(1, 1),
            Size = Vector2.new(width + 2, height + 2)
        })
        
        safeSet(esp.Box, {
            Visible = true,
            Position = position,
            Size = Vector2.new(width, height),
            Color = boxColor
        })
    else
        safeSet(esp.BoxOutline, {Visible = false})
        safeSet(esp.Box, {Visible = false})
    end

    -- Actualizar barra de salud
    if self.Settings.HealthBars then
        local health = humanoid.Health / humanoid.MaxHealth
        local barWidth = 4
        local barHeight = height * health
        
        safeSet(esp.HealthBarOutline, {
            Visible = true,
            Position = position - Vector2.new(6, 0),
            Size = Vector2.new(barWidth + 2, height + 2)
        })
        
        safeSet(esp.HealthBar, {
            Visible = true,
            Position = position - Vector2.new(5, 0) + Vector2.new(0, height - barHeight),
            Size = Vector2.new(barWidth, barHeight),
            Color = Color3.new(1 - health, health, 0)
        })
    else
        safeSet(esp.HealthBarOutline, {Visible = false})
        safeSet(esp.HealthBar, {Visible = false})
    end

    -- Actualizar nombre
    safeSet(esp.NameText, {
        Visible = self.Settings.Names,
        Text = player.Name,
        Position = position + Vector2.new(width / 2, -self.Settings.TextSize - 2),
        Color = baseColor
    })

    -- Actualizar distancia
    safeSet(esp.DistanceText, {
        Visible = self.Settings.Distance,
        Text = string.format("[%d]", distance),
        Position = position + Vector2.new(width / 2, height + 2),
        Color = baseColor
    })

    -- Actualizar tracer
    safeSet(esp.Tracer, {
        Visible = self.Settings.Tracers,
        From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y),
        To = Vector2.new(rootPos.X, rootPos.Y),
        Color = baseColor
    })
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
            pcall(function() drawing:Remove() end)
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
        
        -- Loop de actualización optimizado
        self.UpdateLoop = RunService.RenderStepped:Connect(function(deltaTime)
            self.LastUpdate = self.LastUpdate + deltaTime
            if self.LastUpdate >= 0.1 then  -- Actualizar 10 veces/segundo
                self:UpdateAll()
                self.LastUpdate = 0
            end
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
