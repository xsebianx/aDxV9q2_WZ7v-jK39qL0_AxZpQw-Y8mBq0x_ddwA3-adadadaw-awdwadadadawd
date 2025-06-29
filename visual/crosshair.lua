local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Configuración simplificada
local config = {
    size = 12,          -- Tamaño de las líneas
    thickness = 1.5,    -- Grosor de las líneas
    gap = 4,            -- Espacio en el centro
    color = Color3.fromRGB(0, 255, 0),  -- Color principal
    showCenterDot = true,-- Mostrar punto central
    dynamicColor = true, -- Cambiar color al apuntar a jugadores
    targetColor = Color3.fromRGB(255, 0, 0)  -- Color cuando apuntas a un jugador
}

-- Variables
local crosshairEnabled = false
local crosshairLines = {}
local centerDot
local renderConnection

-- Detectar si está apuntando a un jugador
local function getTargetPlayer()
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    
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

-- Crear elementos del crosshair simplificado
local function createCrosshair()
    -- Limpiar elementos existentes
    for _, drawing in ipairs(crosshairLines) do
        drawing:Remove()
    end
    crosshairLines = {}
    
    -- Solo 4 líneas principales (sin contornos)
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = config.thickness
        line.Visible = false
        table.insert(crosshairLines, line)
    end
    
    -- Punto central simple
    if config.showCenterDot then
        centerDot = Drawing.new("Circle")
        centerDot.Thickness = 1
        centerDot.Radius = 1.5
        centerDot.Filled = true
        centerDot.Visible = false
        centerDot.Color = config.color
    end
end

-- Actualizar posición (versión simplificada)
local function updateCrosshair()
    local centerX = workspace.CurrentCamera.ViewportSize.X / 2
    local centerY = workspace.CurrentCamera.ViewportSize.Y / 2
    
    -- Color dinámico
    local color = config.color
    if config.dynamicColor and getTargetPlayer() then
        color = config.targetColor
    end
    
    -- Posiciones de las líneas
    local gap = config.gap
    local size = config.size
    
    -- Línea horizontal izquierda
    crosshairLines[1].From = Vector2.new(centerX - gap - size, centerY)
    crosshairLines[1].To = Vector2.new(centerX - gap, centerY)
    crosshairLines[1].Color = color
    
    -- Línea horizontal derecha
    crosshairLines[2].From = Vector2.new(centerX + gap, centerY)
    crosshairLines[2].To = Vector2.new(centerX + gap + size, centerY)
    crosshairLines[2].Color = color
    
    -- Línea vertical superior
    crosshairLines[3].From = Vector2.new(centerX, centerY - gap - size)
    crosshairLines[3].To = Vector2.new(centerX, centerY - gap)
    crosshairLines[3].Color = color
    
    -- Línea vertical inferior
    crosshairLines[4].From = Vector2.new(centerX, centerY + gap)
    crosshairLines[4].To = Vector2.new(centerX, centerY + gap + size)
    crosshairLines[4].Color = color
    
    -- Punto central
    if centerDot then
        centerDot.Position = Vector2.new(centerX, centerY)
        centerDot.Color = color
    end
end

-- API para el menú DrakHub
local CrosshairAPI = {
    activate = function()
        -- Activar el crosshair
        if crosshairEnabled then return end
        
        crosshairEnabled = true
        createCrosshair()
        
        for _, line in ipairs(crosshairLines) do
            line.Visible = true
        end
        
        if centerDot then
            centerDot.Visible = true
        end
        
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(updateCrosshair)
        end
        
        return true
    end,
    
    deactivate = function()
        -- Desactivar el crosshair
        if not crosshairEnabled then return end
        
        crosshairEnabled = false
        
        for _, line in ipairs(crosshairLines) do
            line.Visible = false
            line:Remove()
        end
        crosshairLines = {}
        
        if centerDot then
            centerDot.Visible = false
            centerDot:Remove()
            centerDot = nil
        end
        
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        
        return true
    end,
    
    -- Opcional: Funciones para cambiar configuración
    setColor = function(newColor)
        config.color = newColor
    end,
    
    setSize = function(newSize)
        config.size = newSize
        if crosshairEnabled then
            createCrosshair() -- Recrear con nuevo tamaño
            for _, line in ipairs(crosshairLines) do
                line.Visible = true
            end
            if centerDot then
                centerDot.Visible = true
            end
        end
    end
}

return CrosshairAPI