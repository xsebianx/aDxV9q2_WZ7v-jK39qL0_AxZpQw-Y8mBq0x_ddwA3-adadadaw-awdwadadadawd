-- ESP Avanzado para Roblox
-- Versión 2.0 - Diseño desde cero

-- Configuración avanzada
local SETTINGS = {
    DEFAULT_COLOR = Color3.fromRGB(255, 50, 50),
    TEAM_CHECK = false,
    TEAM_COLOR = true,
    MAX_DISTANCE = 2000,
    TEXT_SIZE = 14,
    BOX_THICKNESS = 1,
    BOX_OUTLINE_THICKNESS = 3,
    HEALTH_COLOR = Color3.fromRGB(0, 255, 0),
    DISTANCE_COLOR = Color3.fromRGB(255, 255, 0),
    NAME_COLOR = Color3.fromRGB(255, 255, 255),
    FADE_DISTANCE = 800, -- Distancia para cambiar estilo
    FADE_COLOR = Color3.fromRGB(50, 150, 255),
    TEXT_OUTLINE = true,
    TEXT_CENTERED = true
}

-- Servicios
local RUN_SERVICE = game:GetService("RunService")
local PLAYERS = game:GetService("Players")
local TWEEN_SERVICE = game:GetService("TweenService")

-- Variables
local LOCAL_PLAYER = PLAYERS.LocalPlayer
local CAMERA = workspace.CurrentCamera
local ESP_ENABLED = false
local ESP_CACHE = {}
local ACTIVE_CONNECTIONS = {}
local RENDER_STEP_ACTIVE = false

-- Sistema de dibujo seguro
local DrawingLib = {}
do
    function DrawingLib.new(type, properties)
        local success, drawing = pcall(Drawing.new, type)
        if not success or not drawing then return nil end
        
        for prop, value in pairs(properties) do
            pcall(function()
                drawing[prop] = value
            end)
        end
        
        return drawing
    end

    function DrawingLib.safeRemove(drawing)
        if drawing and typeof(drawing) == "userdata" and drawing.Remove then
            pcall(drawing.Remove, drawing)
        end
    end

    function DrawingLib.safeSetVisible(drawing, visible)
        if drawing then
            pcall(function()
                drawing.Visible = visible
            end)
        end
    end
end

-- Sistema de ESP por jugador
local PlayerESP = {}
PlayerESP.__index = PlayerESP

function PlayerESP.new(player)
    local self = setmetatable({}, PlayerESP)
    self.player = player
    self.drawings = {}
    self.connections = {}
    self.active = true
    
    self:initializeDrawings()
    self:setupConnections()
    
    return self
end

function PlayerESP:initializeDrawings()
    self.drawings.box = DrawingLib.new("Square", {
        Thickness = SETTINGS.BOX_THICKNESS,
        Filled = false,
        Color = SETTINGS.DEFAULT_COLOR,
        Visible = false,
        ZIndex = 2
    })
    
    self.drawings.boxOutline = DrawingLib.new("Square", {
        Thickness = SETTINGS.BOX_OUTLINE_THICKNESS,
        Filled = false,
        Color = Color3.new(0, 0, 0),
        Visible = false,
        ZIndex = 1
    })
    
    self.drawings.name = DrawingLib.new("Text", {
        Color = SETTINGS.NAME_COLOR,
        Size = SETTINGS.TEXT_SIZE,
        Center = SETTINGS.TEXT_CENTERED,
        Outline = SETTINGS.TEXT_OUTLINE,
        Visible = false
    })
    
    self.drawings.health = DrawingLib.new("Text", {
        Color = SETTINGS.HEALTH_COLOR,
        Size = SETTINGS.TEXT_SIZE,
        Center = SETTINGS.TEXT_CENTERED,
        Outline = SETTINGS.TEXT_OUTLINE,
        Visible = false
    })
    
    self.drawings.distance = DrawingLib.new("Text", {
        Color = SETTINGS.DISTANCE_COLOR,
        Size = SETTINGS.TEXT_SIZE,
        Center = SETTINGS.TEXT_CENTERED,
        Outline = SETTINGS.TEXT_OUTLINE,
        Visible = false
    })
    
    -- Verificar que todos los dibujos se crearon
    for _, drawing in pairs(self.drawings) do
        if not drawing then
            self:destroy()
            return
        end
    end
end

function PlayerESP:setupConnections()
    -- Detectar cambios en el personaje
    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:characterChanged(character)
    end))
    
    if self.player.Character then
        self:characterChanged(self.player.Character)
    end
    
    -- Detectar cuando el jugador abandona
    table.insert(self.connections, self.player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:destroy()
        end
    end))
end

function PlayerESP:characterChanged(character)
    -- Limpiar conexiones anteriores
    for _, conn in ipairs(self.connections) do
        if conn ~= self.connections[1] and conn ~= self.connections[2] then
            pcall(conn.Disconnect, conn)
        end
    end
    
    -- Seguir solo las conexiones básicas
    self.connections = {self.connections[1], self.connections[2]}
    
    -- Detectar muerte del personaje
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        table.insert(self.connections, humanoid.Died:Connect(function()
            self:updateVisibility(false)
        end))
    end
end

function PlayerESP:updateVisibility(visible)
    for _, drawing in pairs(self.drawings) do
        DrawingLib.safeSetVisible(drawing, visible and ESP_ENABLED)
    end
end

function PlayerESP:update()
    if not self.active then return end
    
    local character = self.player.Character
    if not character or not character.Parent then
        self:updateVisibility(false)
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        self:updateVisibility(false)
        return
    end
    
    local localCharacter = LOCAL_PLAYER.Character
    if not localCharacter then return end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    -- Conversión segura de posición
    local success, viewportPoint = pcall(function()
        return CAMERA:WorldToViewportPoint(humanoidRootPart.Position)
    end)
    
    if not success or not viewportPoint then
        self:updateVisibility(false)
        return
    end
    
    local position = Vector2.new(viewportPoint.X, viewportPoint.Y)
    local visible = viewportPoint.Z > 0
    local depth = viewportPoint.Z
    
    -- Calcular distancia
    local distance = (localRoot.Position - humanoidRootPart.Position).Magnitude
    
    -- Determinar si se debe mostrar
    local shouldShow = visible and depth <= SETTINGS.MAX_DISTANCE and ESP_ENABLED
    self:updateVisibility(shouldShow)
    
    if not shouldShow then return end
    
    -- Calcular tamaño del ESP
    local scaleFactor = 1 / (depth * math.tan(math.rad(CAMERA.FieldOfView / 2)) * 2) * 1000
    local width = math.round(4 * scaleFactor)
    local height = math.round(5 * scaleFactor)
    local x, y = math.round(position.X), math.round(position.Y)
    
    -- Determinar color
    local boxColor = SETTINGS.DEFAULT_COLOR
    if distance > SETTINGS.FADE_DISTANCE then
        boxColor = SETTINGS.FADE_COLOR
    elseif SETTINGS.TEAM_COLOR then
        pcall(function() boxColor = self.player.TeamColor.Color end)
    end
    
    -- Actualizar dibujos
    pcall(function()
        -- Caja principal
        self.drawings.box.Size = Vector2.new(width, height)
        self.drawings.box.Position = Vector2.new(x - width/2, y - height/2)
        self.drawings.box.Color = boxColor
        
        -- Contorno
        self.drawings.boxOutline.Size = Vector2.new(width, height)
        self.drawings.boxOutline.Position = Vector2.new(x - width/2, y - height/2)
        
        -- Texto: Nombre
        self.drawings.name.Text = self.player.Name
        self.drawings.name.Position = Vector2.new(x, y - height/2 - 15)
        
        -- Texto: Salud
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            self.drawings.health.Text = "❤️ " .. healthPercent .. "%"
            self.drawings.health.Position = Vector2.new(x, y - height/2 - 30)
        end
        
        -- Texto: Distancia
        self.drawings.distance.Text = "📏 " .. string.format("%.1f", distance)
        self.drawings.distance.Position = Vector2.new(x, y + height/2 + 10)
    end)
end

function PlayerESP:destroy()
    self.active = false
    
    -- Eliminar dibujos
    for _, drawing in pairs(self.drawings) do
        DrawingLib.safeRemove(drawing)
    end
    self.drawings = {}
    
    -- Desconectar conexiones
    for _, conn in ipairs(self.connections) do
        pcall(conn.Disconnect, conn)
    end
    self.connections = {}
    
    -- Eliminar de la caché
    ESP_CACHE[self.player] = nil
end

-- Sistema principal del ESP
local ESPManager = {}
do
    function ESPManager.initialize()
        -- Crear ESP para jugadores existentes
        for _, player in PLAYERS:GetPlayers() do
            if player ~= LOCAL_PLAYER then
                ESPManager.addPlayer(player)
            end
        end
        
        -- Configurar conexiones
        ACTIVE_CONNECTIONS.playerAdded = PLAYERS.PlayerAdded:Connect(ESPManager.addPlayer)
        ACTIVE_CONNECTIONS.playerRemoving = PLAYERS.PlayerRemoving:Connect(ESPManager.removePlayer)
    end
    
    function ESPManager.addPlayer(player)
        if player == LOCAL_PLAYER then return end
        if ESP_CACHE[player] then return end
        
        ESP_CACHE[player] = PlayerESP.new(player)
    end
    
    function ESPManager.removePlayer(player)
        local esp = ESP_CACHE[player]
        if esp then
            esp:destroy()
        end
    end
    
    function ESPManager.startRenderStep()
        if RENDER_STEP_ACTIVE then return end
        
        ACTIVE_CONNECTIONS.renderStep = RUN_SERVICE:BindToRenderStep("ESP_Update", Enum.RenderPriority.Camera.Value, function()
            for player, esp in pairs(ESP_CACHE) do
                if player and player.Parent then
                    esp:update()
                else
                    ESPManager.removePlayer(player)
                end
            end
        end)
        
        RENDER_STEP_ACTIVE = true
    end
    
    function ESPManager.cleanup()
        -- Eliminar todos los ESP
        for player in pairs(ESP_CACHE) do
            ESPManager.removePlayer(player)
        end
        
        -- Desconectar conexiones
        for name, conn in pairs(ACTIVE_CONNECTIONS) do
            if name ~= "playerAdded" and name ~= "playerRemoving" then
                pcall(conn.Disconnect, conn)
            end
        end
        
        -- Mantener solo las conexiones básicas
        ACTIVE_CONNECTIONS = {
            playerAdded = ACTIVE_CONNECTIONS.playerAdded,
            playerRemoving = ACTIVE_CONNECTIONS.playerRemoving
        }
        
        RENDER_STEP_ACTIVE = false
    end
    
    function ESPManager.enable()
        if ESP_ENABLED then return end
        ESP_ENABLED = true
        ESPManager.startRenderStep()
    end
    
    function ESPManager.disable()
        if not ESP_ENABLED then return end
        ESP_ENABLED = false
        ESPManager.cleanup()
    end
end

-- Inicialización segura
local function safeInitialize()
    local success, err = pcall(ESPManager.initialize)
    if not success then
        warn("[ESP] Initialization failed:", err)
        return false
    end
    return true
end

-- Exportar funciones
_G.enableESP = function()
    if not safeInitialize() then return end
    ESPManager.enable()
end

_G.disableESP = function()
    ESPManager.disable()
end

return {
    Enable = _G.enableESP,
    Disable = _G.disableESP
}