local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Configuración
local config = {
    size = 12,
    thickness = 1.5,
    gap = 4,
    color = Color3.fromRGB(0, 255, 0),
    showCenterDot = true,
    dynamicColor = true,
    targetColor = Color3.fromRGB(255, 0, 0)
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

-- Crear elementos del crosshair
local function createCrosshair()
    -- Limpiar elementos existentes
    for _, drawing in ipairs(crosshairLines) do
        if drawing then
            drawing:Remove()
        end
    end
    crosshairLines = {}
    
    -- 4 líneas principales
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = config.thickness
        line.Visible = false
        table.insert(crosshairLines, line)
    end
    
    -- Punto central
    if config.showCenterDot then
        centerDot = Drawing.new("Circle")
        centerDot.Thickness = 1
        centerDot.Radius = 1.5
        centerDot.Filled = true
        centerDot.Visible = false
        centerDot.Color = config.color
    end
end

-- Actualizar posición
local function updateCrosshair()
    local centerX = workspace.CurrentCamera.ViewportSize.X / 2
    local centerY = workspace.CurrentCamera.ViewportSize.Y / 2
    
    -- Color dinámico
    local color = config.color
    if config.dynamicColor and getTargetPlayer() then
        color = config.targetColor
    end
    
    -- Posiciones
    local gap = config.gap
    local size = config.size
    
    -- Asegurar que las líneas existen
    if #crosshairLines < 4 then
        createCrosshair()
    end
    
    -- Línea horizontal izquierda
    if crosshairLines[1] then
        crosshairLines[1].From = Vector2.new(centerX - gap - size, centerY)
        crosshairLines[1].To = Vector2.new(centerX - gap, centerY)
        crosshairLines[1].Color = color
    end
    
    -- Línea horizontal derecha
    if crosshairLines[2] then
        crosshairLines[2].From = Vector2.new(centerX + gap, centerY)
        crosshairLines[2].To = Vector2.new(centerX + gap + size, centerY)
        crosshairLines[2].Color = color
    end
    
    -- Línea vertical superior
    if crosshairLines[3] then
        crosshairLines[3].From = Vector2.new(centerX, centerY - gap - size)
        crosshairLines[3].To = Vector2.new(centerX, centerY - gap)
        crosshairLines[3].Color = color
    end
    
    -- Línea vertical inferior
    if crosshairLines[4] then
        crosshairLines[4].From = Vector2.new(centerX, centerY + gap)
        crosshairLines[4].To = Vector2.new(centerX, centerY + gap + size)
        crosshairLines[4].Color = color
    end
    
    -- Punto central
    if centerDot then
        centerDot.Position = Vector2.new(centerX, centerY)
        centerDot.Color = color
    end
end

-- API para el menú
local CrosshairAPI = {
    activate = function()
        if crosshairEnabled then return true end
        
        createCrosshair()
        crosshairEnabled = true
        
        for _, line in ipairs(crosshairLines) do
            if line then
                line.Visible = true
            end
        end
        
        if centerDot then
            centerDot.Visible = true
        end
        
        if renderConnection then
            renderConnection:Disconnect()
        end
        renderConnection = RunService.RenderStepped:Connect(updateCrosshair)
        
        return true
    end,
    
    deactivate = function()
        if not crosshairEnabled then return true end
        
        crosshairEnabled = false
        
        for _, line in ipairs(crosshairLines) do
            if line then
                line.Visible = false
            end
        end
        
        if centerDot then
            centerDot.Visible = false
        end
        
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        
        return true
    end
}

return CrosshairAPI