local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Configuración del crosshair (puedes personalizar estos valores)
local config = {
    size = 15,          -- Tamaño de las líneas
    thickness = 2,      -- Grosor de las líneas
    gap = 3,            -- Espacio en el centro
    color = Color3.fromRGB(0, 255, 0),  -- Color principal
    outlineColor = Color3.fromRGB(0, 0, 0),  -- Color del contorno
    showCenterDot = true,  -- Mostrar punto central
    dynamicColor = true,   -- Cambiar color al apuntar a jugadores
    targetColor = Color3.fromRGB(255, 0, 0)  -- Color cuando apuntas a un jugador
}

-- Variables
local crosshairEnabled = false
local crosshairLines = {}
local centerDot
local renderConnection

-- Crear elementos del crosshair
local function createCrosshair()
    -- Limpiar elementos existentes
    for _, drawing in ipairs(crosshairLines) do
        if drawing then
            drawing:Remove()
        end
    end
    crosshairLines = {}
    
    -- Crear líneas (horizontal, vertical y contornos)
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.Thickness = config.thickness
        line.Visible = false
        table.insert(crosshairLines, line)
    end
    
    -- Crear punto central
    if config.showCenterDot then
        centerDot = Drawing.new("Circle")
        centerDot.Thickness = 1
        centerDot.Radius = 1
        centerDot.Filled = true
        centerDot.Visible = false
    end
    
    -- Asignar colores
    crosshairLines[1].Color = config.outlineColor  -- Horizontal outline 1
    crosshairLines[2].Color = config.outlineColor  -- Horizontal outline 2
    crosshairLines[3].Color = config.color        -- Horizontal main
    crosshairLines[4].Color = config.outlineColor  -- Vertical outline 1
    crosshairLines[5].Color = config.outlineColor  -- Vertical outline 2
    crosshairLines[6].Color = config.color        -- Vertical main
    crosshairLines[7].Color = config.outlineColor  -- Center outline
    crosshairLines[8].Color = config.color        -- Center main
    
    if centerDot then
        centerDot.Color = config.color
    end
end

-- Actualizar posición y visibilidad
local function updateCrosshair()
    local centerX = workspace.CurrentCamera.ViewportSize.X / 2
    local centerY = workspace.CurrentCamera.ViewportSize.Y / 2
    
    -- Calcular posiciones
    local leftX = centerX - config.size - config.gap
    local rightX = centerX + config.size + config.gap
    local topY = centerY - config.size - config.gap
    local bottomY = centerY + config.size + config.gap
    
    -- Línea horizontal (con contorno)
    crosshairLines[1].From = Vector2.new(leftX - 1, centerY - 1)
    crosshairLines[1].To = Vector2.new(centerX - config.gap - 1, centerY - 1)
    crosshairLines[2].From = Vector2.new(centerX + config.gap + 1, centerY - 1)
    crosshairLines[2].To = Vector2.new(rightX + 1, centerY - 1)
    crosshairLines[3].From = Vector2.new(leftX, centerY)
    crosshairLines[3].To = Vector2.new(centerX - config.gap, centerY)
    
    -- Línea vertical (con contorno)
    crosshairLines[4].From = Vector2.new(centerX - 1, topY - 1)
    crosshairLines[4].To = Vector2.new(centerX - 1, centerY - config.gap - 1)
    crosshairLines[5].From = Vector2.new(centerX - 1, centerY + config.gap + 1)
    crosshairLines[5].To = Vector2.new(centerX - 1, bottomY + 1)
    crosshairLines[6].From = Vector2.new(centerX, topY)
    crosshairLines[6].To = Vector2.new(centerX, centerY - config.gap)
    
    -- Centro (con contorno)
    crosshairLines[7].From = Vector2.new(centerX - config.gap, centerY - 1)
    crosshairLines[7].To = Vector2.new(centerX + config.gap, centerY - 1)
    crosshairLines[8].From = Vector2.new(centerX - config.gap, centerY)
    crosshairLines[8].To = Vector2.new(centerX + config.gap, centerY)
    
    -- Punto central
    if centerDot then
        centerDot.Position = Vector2.new(centerX, centerY)
    end
    
    -- Cambiar color si está apuntando a un jugador
    if config.dynamicColor then
        local target = getTargetPlayer()
        for i = 3, #crosshairLines do
            crosshairLines[i].Color = target and config.targetColor or config.color
        end
        if centerDot then
            centerDot.Color = target and config.targetColor or config.color
        end
    end
end

-- Detectar si está apuntando a un jugador
local function getTargetPlayer()
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Crear un rayo desde la cámara
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)
            if player and player ~= localPlayer then
                return player
            end
        end
    end
    return nil
end

-- Función para activar el crosshair
function enableCrosshair()
    if crosshairEnabled then return end
    
    crosshairEnabled = true
    createCrosshair()
    
    -- Activar visibilidad
    for _, line in ipairs(crosshairLines) do
        line.Visible = true
    end
    
    if centerDot then
        centerDot.Visible = true
    end
    
    -- Conectar la actualización
    if not renderConnection then
        renderConnection = RunService.RenderStepped:Connect(updateCrosshair)
    end
end

-- Función para desactivar el crosshair
function disableCrosshair()
    if not crosshairEnabled then return end
    
    crosshairEnabled = false
    
    -- Desactivar visibilidad
    for _, line in ipairs(crosshairLines) do
        line.Visible = false
    end
    
    if centerDot then
        centerDot.Visible = false
    end
    
    -- Desconectar la actualización
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

-- Función para cambiar configuración
function setCrosshairConfig(newConfig)
    for key, value in pairs(newConfig) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
    
    -- Recrear el crosshair si está activo
    if crosshairEnabled then
        createCrosshair()
    end
end

-- Asignar funciones globales
_G.enableCrosshair = enableCrosshair
_G.disableCrosshair = disableCrosshair
_G.setCrosshairConfig = setCrosshairConfig

-- Opcional: Activar automáticamente al cargar
-- enableCrosshair()