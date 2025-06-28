-- Configuraciones
local settings = {
    defaultcolor = Color3.fromRGB(255, 0, 0),
    teamcheck = false,
    teamcolor = true
}

-- Servicios
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Variables
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local maxDistance = 2000
local espEnabled = false
local espCache = {}
local connections = {}
local renderStepBound = false

-- Funciones seguras
local function safeWtvp(position)
    if not camera then
        camera = workspace.CurrentCamera
        if not camera then return nil end
    end
    
    local success, result = pcall(function()
        return camera:WorldToViewportPoint(position)
    end)
    
    return success and result or nil
end

local function safeCreateDrawing(type, props)
    local success, drawing = pcall(Drawing.new, type)
    if not success or not drawing then return nil end
    
    for prop, value in pairs(props) do
        pcall(function()
            drawing[prop] = value
        end)
    end
    
    return drawing
end

local function safeCreateEsp(player)
    if not player or not player.Parent or espCache[player] then return end
    
    local drawings = {
        box = safeCreateDrawing("Square", {
            Thickness = 1,
            Filled = false,
            Color = settings.defaultcolor,
            Visible = false,
            ZIndex = 2
        }),
        
        boxoutline = safeCreateDrawing("Square", {
            Thickness = 3,
            Filled = false,
            Color = Color3.new(),
            Visible = false,
            ZIndex = 1
        }),
        
        name = safeCreateDrawing("Text", {
            Color = Color3.new(1, 1, 1),
            Size = 20,
            Center = true,
            Outline = true,
            Visible = false
        }),
        
        health = safeCreateDrawing("Text", {
            Color = Color3.new(0, 1, 0),
            Size = 20,
            Center = true,
            Outline = true,
            Visible = false
        }),
        
        distance = safeCreateDrawing("Text", {
            Color = Color3.new(1, 0, 0),
            Size = 20,
            Center = true,
            Outline = true,
            Visible = false
        })
    }
    
    -- Verificar que todos los dibujos se crearon correctamente
    for _, drawing in pairs(drawings) do
        if not drawing then
            for _, d in pairs(drawings) do
                pcall(function() if d then d:Remove() end end)
            end
            return
        end
    end
    
    espCache[player] = drawings
end

local function safeUpdateEsp(player, esp)
    if not player or not player:IsDescendantOf(game) then
        return false
    end

    local character = player.Character
    if not character or not character:IsDescendantOf(workspace) then
        return false
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart or not humanoidRootPart:IsDescendantOf(workspace) then
        return false
    end

    local localCharacter = localPlayer.Character
    if not localCharacter then return false end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end

    local viewportResult = safeWtvp(humanoidRootPart.Position)
    if not viewportResult then return false end

    local position = Vector2.new(viewportResult.X, viewportResult.Y)
    local visible = viewportResult.Z > 0
    local depth = viewportResult.Z

    local function setDrawingVisibility(drawing, visibleState)
        if drawing then
            pcall(function()
                drawing.Visible = visibleState
            end)
        end
    end

    local shouldShow = visible and depth <= maxDistance
    
    setDrawingVisibility(esp.box, shouldShow)
    setDrawingVisibility(esp.boxoutline, shouldShow)
    setDrawingVisibility(esp.name, shouldShow)
    setDrawingVisibility(esp.health, shouldShow)
    setDrawingVisibility(esp.distance, shouldShow)

    if not shouldShow then return true end

    -- Cálculos seguros
    local scaleFactor = 1 / (depth * math.tan(math.rad(camera.FieldOfView / 2)) * 2) * 1000
    local width, height = math.round(2 * scaleFactor), math.round(2.5 * scaleFactor)
    local x, y = math.round(position.X), math.round(position.Y)

    local distance = (localRoot.Position - humanoidRootPart.Position).Magnitude

    local boxColor = settings.defaultcolor
    if distance > 800 then
        boxColor = Color3.fromRGB(0, 0, 255)
    elseif settings.teamcolor then
        pcall(function() boxColor = player.TeamColor.Color end)
    end

    pcall(function()
        if esp.box then
            esp.box.Size = Vector2.new(width, height)
            esp.box.Position = Vector2.new(x - width / 2, y - height / 2)
            esp.box.Color = boxColor
        end

        if esp.boxoutline then
            esp.boxoutline.Size = Vector2.new(width, height)
            esp.boxoutline.Position = Vector2.new(x - width / 2, y - height / 2)
        end

        local textScale = distance <= 800 and 0.8 or 0.75
        local nameAndDistanceScale = distance <= 800 and 1.2 or 0.75

        if esp.name then
            esp.name.Text = player.Name
            esp.name.Position = Vector2.new(x, y - height / 2 - 20)
            esp.name.Size = 16 * nameAndDistanceScale
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and esp.health then
            local healthPercent = math.round((humanoid.Health / humanoid.MaxHealth) * 100)
            esp.health.Text = string.format("Vida: %d%%", healthPercent)
            esp.health.Position = Vector2.new(x, y - height / 2 - 40)
            esp.health.Size = 16 * textScale
        end

        if esp.distance then
            esp.distance.Text = string.format("Distancia: %.2f", distance)
            esp.distance.Position = Vector2.new(x, y + height / 2 + 20)
            esp.distance.Size = 16 * nameAndDistanceScale
        end
    end)

    return true
end

local function safeRemoveEsp(player)
    if not espCache[player] then return end
    
    for _, drawing in pairs(espCache[player]) do
        pcall(function()
            if drawing and typeof(drawing) == "userdata" then
                drawing:Remove()
            end
        end)
    end
    
    espCache[player] = nil
end

-- Función para limpiar completamente el ESP
local function cleanUpESP()
    for player in pairs(espCache) do
        safeRemoveEsp(player)
    end
    
    espCache = {}
    
    -- Desconectar solo las conexiones específicas
    for _, conn in ipairs(connections) do
        if conn ~= renderStepConnection then
            pcall(function() 
                if typeof(conn) == "RBXScriptConnection" then
                    conn:Disconnect() 
                end
            end)
        end
    end
    
    connections = {}
end

-- Conexiones para jugadores (siempre activas)
local function safePlayerAdded(player)
    if player ~= localPlayer then
        safeCreateEsp(player)
    end
end

local function safePlayerRemoving(player)
    safeRemoveEsp(player)
end

-- Principal
local function initializeESP()
    -- Limpiar cualquier instancia previa
    cleanUpESP()

    -- Crear ESP para jugadores existentes
    for _, player in players:GetPlayers() do
        safePlayerAdded(player)
    end

    -- Configurar conexiones
    connections[#connections+1] = players.PlayerAdded:Connect(safePlayerAdded)
    connections[#connections+1] = players.PlayerRemoving:Connect(safePlayerRemoving)
end

-- Inicialización segura
local success, err = pcall(initializeESP)
if not success then
    warn("ESP initialization failed:", err)
end

-- Manejo del render step
local function startRenderStep()
    if renderStepBound then return end
    
    renderStepConnection = runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
        if not espEnabled then
            for _, drawings in pairs(espCache) do
                for _, drawing in pairs(drawings) do
                    pcall(function() 
                        if drawing then drawing.Visible = false end
                    end)
                end
            end
            return
        end

        for player, drawings in pairs(espCache) do
            if not pcall(safeUpdateEsp, player, drawings) then
                safeRemoveEsp(player)
            end
        end
    end)
    
    connections[#connections+1] = renderStepConnection
    renderStepBound = true
end

-- Exportar funciones para control externo
_G.enableESP = function()
    espEnabled = true
    startRenderStep()
end

_G.disableESP = function()
    espEnabled = false
    cleanUpESP()
    renderStepBound = false
end

return {
    Enable = _G.enableESP,
    Disable = _G.disableESP
}