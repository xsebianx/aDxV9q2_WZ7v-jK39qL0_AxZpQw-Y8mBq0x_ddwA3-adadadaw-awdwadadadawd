-- esp.lua (Versión mejorada con limpieza garantizada)

-- Configuración
local SETTINGS = {
    DEFAULT_COLOR = Color3.fromRGB(255, 0, 0),
    MAX_DISTANCE = 2000,
    TEXT_SIZE = 14
}

-- Servicios
local RUN_SERVICE = game:GetService("RunService")
local PLAYERS = game:GetService("Players")
local CAMERA = workspace.CurrentCamera

-- Variables
local LOCAL_PLAYER = PLAYERS.LocalPlayer
local ESP_ENABLED = false
local ESP_CACHE = {}
local DRAWINGS_REGISTRY = {} -- Registro global de todos los objetos Drawing

-- Función para crear objetos Drawing con registro
local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    table.insert(DRAWINGS_REGISTRY, drawing)
    return drawing
end

-- Función para limpiar TODOS los objetos Drawing
local function cleanAllDrawings()
    for _, drawing in ipairs(DRAWINGS_REGISTRY) do
        pcall(function()
            if drawing and typeof(drawing) == "userdata" then
                drawing:Remove()
            end
        end)
    end
    DRAWINGS_REGISTRY = {}
    ESP_CACHE = {}
end

-- Crear ESP para un jugador
local function createPlayerESP(player)
    if ESP_CACHE[player] then return end
    
    local drawings = {
        box = createDrawing("Square", {
            Thickness = 1,
            Filled = false,
            Color = SETTINGS.DEFAULT_COLOR,
            Visible = false,
            ZIndex = 2
        }),
        
        boxOutline = createDrawing("Square", {
            Thickness = 3,
            Filled = false,
            Color = Color3.new(0, 0, 0),
            Visible = false,
            ZIndex = 1
        }),
        
        name = createDrawing("Text", {
            Color = Color3.new(1, 1, 1),
            Size = SETTINGS.TEXT_SIZE,
            Center = true,
            Outline = true,
            Visible = false
        }),
        
        health = createDrawing("Text", {
            Color = Color3.new(0, 1, 0),
            Size = SETTINGS.TEXT_SIZE,
            Center = true,
            Outline = true,
            Visible = false
        }),
        
        distance = createDrawing("Text", {
            Color = Color3.new(1, 1, 0),
            Size = SETTINGS.TEXT_SIZE,
            Center = true,
            Outline = true,
            Visible = false
        })
    }
    
    ESP_CACHE[player] = drawings
end

-- Actualizar ESP para un jugador
local function updatePlayerESP(player, drawings)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local success, viewportPoint = pcall(function()
        return CAMERA:WorldToViewportPoint(humanoidRootPart.Position)
    end)
    
    if not success then return end
    
    local position = Vector2.new(viewportPoint.X, viewportPoint.Y)
    local visible = viewportPoint.Z > 0
    local depth = viewportPoint.Z
    
    -- Actualizar visibilidad
    for _, drawing in pairs(drawings) do
        drawing.Visible = visible and depth <= SETTINGS.MAX_DISTANCE and ESP_ENABLED
    end
    
    if not drawings.box.Visible then return end
    
    -- Cálculos de posición y tamaño
    local scaleFactor = 1 / (depth * math.tan(math.rad(CAMERA.FieldOfView / 2)) * 2) * 1000
    local width = math.round(4 * scaleFactor)
    local height = math.round(5 * scaleFactor)
    local x, y = math.round(position.X), math.round(position.Y)
    
    -- Actualizar dibujos
    drawings.box.Size = Vector2.new(width, height)
    drawings.box.Position = Vector2.new(x - width/2, y - height/2)
    
    drawings.boxOutline.Size = drawings.box.Size
    drawings.boxOutline.Position = drawings.box.Position
    
    drawings.name.Text = player.Name
    drawings.name.Position = Vector2.new(x, y - height/2 - 15)
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        drawings.health.Text = "HP: " .. math.floor(humanoid.Health)
        drawings.health.Position = Vector2.new(x, y - height/2 - 30)
    end
    
    local distance = (LOCAL_PLAYER.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
    drawings.distance.Text = "Dist: " .. string.format("%.1f", distance)
    drawings.distance.Position = Vector2.new(x, y + height/2 + 10)
end

-- Eliminar ESP de un jugador
local function removePlayerESP(player)
    if not ESP_CACHE[player] then return end
    
    for _, drawing in pairs(ESP_CACHE[player]) do
        pcall(function()
            if drawing then drawing:Remove() end
        end)
    end
    
    ESP_CACHE[player] = nil
end

-- Inicializar ESP
local function initializeESP()
    -- Limpiar cualquier ESP previo
    cleanAllDrawings()
    
    -- Crear ESP para jugadores existentes
    for _, player in PLAYERS:GetPlayers() do
        if player ~= LOCAL_PLAYER then
            createPlayerESP(player)
        end
    end
    
    -- Conexiones
    PLAYERS.PlayerAdded:Connect(function(player)
        if player ~= LOCAL_PLAYER then
            createPlayerESP(player)
        end
    end)
    
    PLAYERS.PlayerRemoving:Connect(function(player)
        removePlayerESP(player)
    end)
    
    -- Bucle de actualización
    RUN_SERVICE:BindToRenderStep("ESP_Update", Enum.RenderPriority.Camera.Value, function()
        if not ESP_ENABLED then return end
        
        for player, drawings in pairs(ESP_CACHE) do
            if player and player.Parent then
                updatePlayerESP(player, drawings)
            else
                removePlayerESP(player)
            end
        end
    end)
end

-- Funciones globales
_G.enableESP = function()
    ESP_ENABLED = true
    initializeESP()
end

_G.disableESP = function()
    ESP_ENABLED = false
    cleanAllDrawings()
end

-- Inicialización segura
pcall(initializeESP)