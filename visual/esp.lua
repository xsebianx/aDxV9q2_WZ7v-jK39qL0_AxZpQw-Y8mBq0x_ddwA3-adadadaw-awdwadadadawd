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
local espEnabled = false -- Cambiado a false por defecto
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

-- Botón para activar/desactivar ESP
local ESPButton = Instance.new("TextButton")
ESPButton.Name = "ESPButton"
ESPButton.Parent = VisualFrame
ESPButton.Text = "ESP: Off"
ESPButton.Font = Enum.Font.GothamBold
ESPButton.TextSize = 18
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ESPButton.Size = UDim2.new(0, 240, 0, 40)
ESPButton.Position = UDim2.new(0, 10, 0, 10)

-- Añadir esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = ESPButton

-- Efecto de hover
ESPButton.MouseEnter:Connect(function()
    ESPButton.BackgroundColor3 = Color3.fromRGB(75, 75, 150)
end)

ESPButton.MouseLeave:Connect(function()
    ESPButton.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
end)

-- Función para alternar el estado del ESP
ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPButton.Text = espEnabled and "ESP: On" or "ESP: Off"
end)

-- Principal
for _, player in next, players:GetPlayers() do
    if player ~= localPlayer then
        createEsp(player)
    end
end

-- Conexiones con PlayerAdded y PlayerRemoving
connections[#connections+1] = players.PlayerAdded:Connect(function(player)
    createEsp(player)
end)

connections[#connections+1] = players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

connections[#connections+1] = runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
    if espEnabled then
        for player, drawings in next, espCache do
            if settings.teamcheck and player.Team == localPlayer.Team then
                continue
            end
            if drawings and player ~= localPlayer then
                updateEsp(player, drawings)
            end
        end
    else
        for _, drawings in pairs(espCache) do
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
        end
    end
end)
