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
local espEnabled = false -- Desactivado por defecto
local espCache = {}
local connections = {} -- Tabla para almacenar las conexiones

-- Funciones
local newVector2, newColor3, newDrawing = Vector2.new, Color3.new, Drawing.new
local tan, rad = math.tan, math.rad
local round = function(...)
    local a = {}
    for i, v in next, table.pack(...) do
        a[i] = math.round(v)
    end
    return unpack(a)
end

local wtvp = function(...)
    local a, b = camera.WorldToViewportPoint(camera, ...)
    return newVector2(a.X, a.Y), b, a.Z
end

local function createEsp(player)
    local drawings = {}
    drawings.box = newDrawing("Square")
    drawings.box.Thickness = 1
    drawings.box.Filled = false
    drawings.box.Color = settings.defaultcolor
    drawings.box.Visible = false
    drawings.box.ZIndex = 2

    drawings.boxoutline = newDrawing("Square")
    drawings.boxoutline.Thickness = 3
    drawings.boxoutline.Filled = false
    drawings.boxoutline.Color = newColor3()
    drawings.boxoutline.Visible = false
    drawings.boxoutline.ZIndex = 1

    drawings.name = newDrawing("Text")
    drawings.name.Color = newColor3(255, 255, 255)
    drawings.name.Size = 20
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Visible = false

    drawings.health = newDrawing("Text")
    drawings.health.Color = newColor3(0, 255, 0)
    drawings.health.Size = 20
    drawings.health.Center = true
    drawings.health.Outline = true
    drawings.health.Visible = false

    drawings.distance = newDrawing("Text")
    drawings.distance.Color = newColor3(255, 0, 0)
    drawings.distance.Size = 20
    drawings.distance.Center = true
    drawings.distance.Outline = true
    drawings.distance.Visible = false

    espCache[player] = drawings
end

local function updateEsp(player, esp)
    local character = player and player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local position, visible, depth = wtvp(humanoidRootPart.Position)
            esp.box.Visible = visible and depth <= maxDistance
            esp.boxoutline.Visible = visible and depth <= maxDistance
            esp.name.Visible = visible and depth <= maxDistance
            esp.health.Visible = visible and depth <= maxDistance
            esp.distance.Visible = visible and depth <= maxDistance

            if visible then
                local scaleFactor = 1 / (depth * tan(rad(camera.FieldOfView / 2)) * 2) * 1000
                local width, height = round(2 * scaleFactor, 2.5 * scaleFactor)
                local x, y = round(position.X, position.Y)

                local distance = (localPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).magnitude

                if distance > 800 then
                    esp.box.Color = Color3.fromRGB(0, 0, 255)
                else
                    esp.box.Color = settings.teamcolor and player.TeamColor.Color or settings.defaultcolor
                end

                esp.box.Size = newVector2(width, height)
                esp.box.Position = newVector2(round(x - width / 2, y - height / 2))

                esp.boxoutline.Size = esp.box.Size
                esp.boxoutline.Position = esp.box.Position

                local textScale = distance <= 800 and 0.8 or 0.75
                local nameAndDistanceScale = distance <= 800 and 1.2 or 0.75

                esp.name.Text = player.Name
                esp.name.Position = newVector2(x, y - height / 2 - 20)
                esp.name.Size = 16 * nameAndDistanceScale

                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    esp.health.Text = string.format("Vida: %.0f%%", humanoid.Health / humanoid.MaxHealth * 100)
                    esp.health.Position = newVector2(x, y - height / 2 - 40)
                    esp.health.Size = 16 * textScale
                end

                esp.distance.Text = string.format("Distancia: %.2f", distance)
                esp.distance.Position = newVector2(x, y + height / 2 + 20)
                esp.distance.Size = 16 * nameAndDistanceScale
            end
        end
    else
        esp.box.Visible = false
        esp.boxoutline.Visible = false
        esp.name.Visible = false
        esp.health.Visible = false
        esp.distance.Visible = false
    end
end

local function removeEsp(player)
    if espCache[player] then
        for _, drawing in pairs(espCache[player]) do
            drawing:Remove()
        end
        espCache[player] = nil
    end
end

local function clearAllEsp()
    for player in pairs(espCache) do
        removeEsp(player)
    end
    espCache = {}
end

-- Función para activar el ESP
function enableESP()
    if espEnabled then return end -- Si ya está activo, no hacer nada
    
    espEnabled = true
    
    -- Crear ESP para jugadores existentes
    for _, player in next, players:GetPlayers() do
        if player ~= localPlayer and not espCache[player] then
            createEsp(player)
        end
    end
    
    -- Conexiones con PlayerAdded y PlayerRemoving
    if not connections.playerAdded then
        connections.playerAdded = players.PlayerAdded:Connect(function(player)
            createEsp(player)
        end)
    end
    
    if not connections.playerRemoving then
        connections.playerRemoving = players.PlayerRemoving:Connect(function(player)
            removeEsp(player)
        end)
    end
    
    -- Conexión de renderizado
    if not connections.render then
        connections.render = runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
            for player, drawings in next, espCache do
                if settings.teamcheck and player.Team == localPlayer.Team then
                    continue
                end
                if drawings and player ~= localPlayer then
                    updateEsp(player, drawings)
                end
            end
        end)
    end
end

-- Función para desactivar el ESP
function disableESP()
    if not espEnabled then return end -- Si ya está desactivado, no hacer nada
    
    espEnabled = false
    
    -- Ocultar todos los ESP
    for _, drawings in pairs(espCache) do
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
    end
    
    -- Desconectar conexiones
    if connections.playerAdded then
        connections.playerAdded:Disconnect()
        connections.playerAdded = nil
    end
    
    if connections.playerRemoving then
        connections.playerRemoving:Disconnect()
        connections.playerRemoving = nil
    end
    
    if connections.render then
        runService:UnbindFromRenderStep("esp")
        connections.render = nil
    end
end

-- Función para limpiar completamente el ESP
function cleanESP()
    disableESP()
    clearAllEsp()
end

-- Asignar las funciones a las variables globales
_G.enableESP = enableESP
_G.disableESP = disableESP
_G.cleanESP = cleanESP

-- Limpieza cuando el script se destruye
game:BindToClose(cleanESP)