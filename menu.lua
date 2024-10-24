-- Creación del GUI para DrakHub con colores
local DrakHub = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")
local MinimizeButton = Instance.new("TextButton")

local isMinimized = false
-- Categorías
local CombatButton = Instance.new("TextButton")
local VisualButton = Instance.new("TextButton")
local ExtraButton = Instance.new("TextButton")

-- Submenús
local CombatFrame = Instance.new("ScrollingFrame")
local VisualFrame = Instance.new("ScrollingFrame")
local ExtraFrame = Instance.new("ScrollingFrame")

-- Funcionalidades
local AimbotButton = Instance.new("TextButton")
local AimbotNPCButton = Instance.new("TextButton")
local ESPButton = Instance.new("TextButton")
local FlyButton = Instance.new("TextButton")
local VisorButton = Instance.new("TextButton")
local CrosshairButton = Instance.new("TextButton")
local ZoomButton = Instance.new("TextButton")

-- Propiedades generales de la GUI
DrakHub.Name = "DrakHub"
DrakHub.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
DrakHub.ResetOnSpawn = false

-- Frame principal con fondo degradado y borde
MainFrame.Name = "MainFrame"
MainFrame.Parent = DrakHub
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30) -- Color principal oscuro
MainFrame.BorderColor3 = Color3.fromRGB(85, 170, 255) -- Color de borde azul
MainFrame.BorderSizePixel = 2 -- Grosor del borde
MainFrame.Size = UDim2.new(0, 450, 0, 400)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
MainFrame.Active = true
MainFrame.Draggable = true
-- Esquinas redondeadas

UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Título del menú
Title.Name = "Title"
Title.Parent = MainFrame
Title.Text = "DrakHub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255) -- Color del texto blanco
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 40)

-- Botón de Combat con fondo degradado
CombatButton.Name = "CombatButton"
CombatButton.Parent = MainFrame
CombatButton.Text = "Combat"
CombatButton.Font = Enum.Font.Gotham
CombatButton.TextSize = 18
CombatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CombatButton.BackgroundColor3 = Color3.fromRGB(45, 85, 255) -- Azul intenso
CombatButton.Size = UDim2.new(0, 120, 0, 40)
CombatButton.Position = UDim2.new(0, 10, 0, 60)
local CombatUICorner = Instance.new("UICorner")
CombatUICorner.CornerRadius = UDim.new(0, 8)
CombatUICorner.Parent = CombatButton

-- Botón de Visual con fondo degradado
VisualButton.Name = "VisualButton"
VisualButton.Parent = MainFrame
VisualButton.Text = "Visual"
VisualButton.Font = Enum.Font.Gotham
VisualButton.TextSize = 18
VisualButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VisualButton.BackgroundColor3 = Color3.fromRGB(45, 255, 85) -- Verde intenso
VisualButton.Size = UDim2.new(0, 120, 0, 40)
VisualButton.Position = UDim2.new(0, 10, 0, 110)
local VisualUICorner = Instance.new("UICorner")
VisualUICorner.CornerRadius = UDim.new(0, 8)
VisualUICorner.Parent = VisualButton

-- Botón de Extra con fondo degradado
ExtraButton.Name = "ExtraButton"
ExtraButton.Parent = MainFrame
ExtraButton.Text = "Extra"
ExtraButton.Font = Enum.Font.Gotham
ExtraButton.TextSize = 18
ExtraButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExtraButton.BackgroundColor3 = Color3.fromRGB(255, 85, 45) -- Naranja intenso
ExtraButton.Size = UDim2.new(0, 120, 0, 40)
ExtraButton.Position = UDim2.new(0, 10, 0, 160)
local ExtraUICorner = Instance.new("UICorner")
ExtraUICorner.CornerRadius = UDim.new(0, 8)
ExtraUICorner.Parent = ExtraButton

-- Submenú de Combat con borde personalizado
CombatFrame.Name = "CombatFrame"
CombatFrame.Parent = MainFrame
CombatFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70) -- Fondo oscuro
CombatFrame.BorderColor3 = Color3.fromRGB(85, 170, 255) -- Borde azul
CombatFrame.BorderSizePixel = 2
CombatFrame.Size = UDim2.new(0, 280, 0, 290)
CombatFrame.Position = UDim2.new(0, 140, 0, 60)
CombatFrame.Visible = false
CombatFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
CombatFrame.ScrollBarThickness = 6
local CombatFrameUICorner = Instance.new("UICorner")
CombatFrameUICorner.CornerRadius = UDim.new(0, 8)
CombatFrameUICorner.Parent = CombatFrame

-- Submenú de Visual con borde personalizado
VisualFrame.Name = "VisualFrame"
VisualFrame.Parent = MainFrame
VisualFrame.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
VisualFrame.BorderColor3 = Color3.fromRGB(45, 255, 85) -- Verde
VisualFrame.BorderSizePixel = 2
VisualFrame.Size = UDim2.new(0, 280, 0, 290)
VisualFrame.Position = UDim2.new(0, 140, 0, 60)
VisualFrame.Visible = false
VisualFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
VisualFrame.ScrollBarThickness = 6
local VisualFrameUICorner = Instance.new("UICorner")
VisualFrameUICorner.CornerRadius = UDim.new(0, 8)
VisualFrameUICorner.Parent = VisualFrame

-- Submenú de Extra con borde personalizado
ExtraFrame.Name = "ExtraFrame"
ExtraFrame.Parent = MainFrame
ExtraFrame.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
ExtraFrame.BorderColor3 = Color3.fromRGB(255, 85, 45) -- Naranja
ExtraFrame.BorderSizePixel = 2
ExtraFrame.Size = UDim2.new(0, 280, 0, 290)
ExtraFrame.Position = UDim2.new(0, 140, 0, 60)
ExtraFrame.Visible = false
ExtraFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
ExtraFrame.ScrollBarThickness = 6
local ExtraFrameUICorner = Instance.new("UICorner")
ExtraFrameUICorner.CornerRadius = UDim.new(0, 8)
ExtraFrameUICorner.Parent = ExtraFrame

-- Crear el botón Aimbot
local AimbotButton = Instance.new("TextButton")
AimbotButton.Name = "AimbotButton"
AimbotButton.Parent = CombatFrame
AimbotButton.Text = "Aimbot: Off"
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.TextSize = 20
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Color blanco para el texto
AimbotButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Color gris oscuro (igual que ESP)
AimbotButton.Size = UDim2.new(0, 240, 0, 40)  -- Tamaño igual al botón ESP
AimbotButton.Position = UDim2.new(0, 10, 0, 10)
AimbotButton.BorderSizePixel = 0  -- Sin borde
AimbotButton.BackgroundTransparency = 0.1  -- Ligera transparencia

-- Redondear esquinas
AimbotButton.AutoButtonColor = false
AimbotButton.ClipsDescendants = true
local cornerAimbot = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerAimbot.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas (igual que ESP)
cornerAimbot.Parent = AimbotButton

-- Efecto de hover (opcional)
AimbotButton.MouseEnter:Connect(function()
    AimbotButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)  -- Azul claro al pasar el mouse
end)

AimbotButton.MouseLeave:Connect(function()
    AimbotButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al gris oscuro original
end)

-- Botón Aimbot NPC
AimbotNPCButton = Instance.new("TextButton")  -- Crea el botón
AimbotNPCButton.Name = "AimbotNPCButton"
AimbotNPCButton.Parent = CombatFrame
AimbotNPCButton.Text = "Aimbot NPC: Off"
AimbotNPCButton.Font = Enum.Font.GothamBold
AimbotNPCButton.TextSize = 20  -- Tamaño del texto ajustado
AimbotNPCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotNPCButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Color inicial (igual al ESP y Aimbot)
AimbotNPCButton.Size = UDim2.new(0, 240, 0, 40)  -- Tamaño igual que el botón ESP
AimbotNPCButton.Position = UDim2.new(0, 10, 0, 60)  -- Posición bajo el botón Aimbot
AimbotNPCButton.BorderSizePixel = 0  -- Sin borde
AimbotNPCButton.BackgroundTransparency = 0.1  -- Ligera transparencia para suavidad

-- Redondear esquinas
AimbotNPCButton.AutoButtonColor = false
AimbotNPCButton.ClipsDescendants = true
local cornerAimbotNPC = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerAimbotNPC.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas (igual que ESP)
cornerAimbotNPC.Parent = AimbotNPCButton

-- Efecto de hover (opcional)
AimbotNPCButton.MouseEnter:Connect(function()
    AimbotNPCButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)  -- Color al pasar el mouse (azul claro)
end)

AimbotNPCButton.MouseLeave:Connect(function()
    AimbotNPCButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al color original (gris oscuro)
end)

local SilenAimButton = Instance.new("TextButton")
SilenAimButton.Name = "SilenAimButton"
SilenAimButton.Parent = CombatFrame
SilenAimButton.Text = "Silent Aim: Off"
SilenAimButton.Font = Enum.Font.GothamBold
SilenAimButton.TextSize = 20
SilenAimButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Color blanco para el texto
SilenAimButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Color gris oscuro (igual que ESP)
SilenAimButton.Size = UDim2.new(0, 240, 0, 40)  -- Tamaño igual al botón ESP
SilenAimButton.Position = UDim2.new(0, 10, 0, 110)
SilenAimButton.BorderSizePixel = 0  -- Sin borde
SilenAimButton.BackgroundTransparency = 0.1  -- Ligera transparencia

-- Redondear esquinas
SilenAimButton.AutoButtonColor = false
SilenAimButton.ClipsDescendants = true
local cornerAimbot = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerAimbot.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas (igual que ESP)
cornerAimbot.Parent = SilenAimButton

-- Efecto de hover (opcional)
SilenAimButton.MouseEnter:Connect(function()
    SilenAimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)  -- Azul claro al pasar el mouse
end)

SilenAimButton.MouseLeave:Connect(function()
    SilenAimButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al gris oscuro original
end)

-- Funcionalidades de Visual
local VisorButton = Instance.new("TextButton")
VisorButton.Name = "VisorButton"
VisorButton.Parent = VisualFrame
VisorButton.Text = "Visor: Off"
VisorButton.Font = Enum.Font.GothamBold
VisorButton.TextSize = 18
VisorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VisorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
VisorButton.Size = UDim2.new(0, 240, 0, 40)
VisorButton.Position = UDim2.new(0, 10, 0, 60)
VisorButton.BorderSizePixel = 0
VisorButton.BackgroundTransparency = 0.1

-- Redondear esquinas
VisorButton.AutoButtonColor = false
VisorButton.ClipsDescendants = true
local cornerVisor = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerVisor.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas
cornerVisor.Parent = VisorButton

-- Efecto de hover (opcional)
VisorButton.MouseEnter:Connect(function()
    VisorButton.BackgroundColor3 = Color3.fromRGB(144, 238, 144)  -- Color verde clarito al pasar el mouse
end)

VisorButton.MouseLeave:Connect(function()
    VisorButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al color original
end)

-- Funcionalidades de Crosshair
local CrosshairButton = Instance.new("TextButton")
CrosshairButton.Name = "CrosshairButton"
CrosshairButton.Parent = VisualFrame
CrosshairButton.Text = "Crosshair: Off"
CrosshairButton.Font = Enum.Font.GothamBold
CrosshairButton.TextSize = 18
CrosshairButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CrosshairButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CrosshairButton.Size = UDim2.new(0, 240, 0, 40)
CrosshairButton.Position = UDim2.new(0, 10, 0, 110) -- Ajustar posición para que esté más abajo
CrosshairButton.BorderSizePixel = 0
CrosshairButton.BackgroundTransparency = 0.1

-- Redondear esquinas
CrosshairButton.AutoButtonColor = false
CrosshairButton.ClipsDescendants = true
local cornerCrosshair = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerCrosshair.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas
cornerCrosshair.Parent = CrosshairButton

-- Efecto de hover (opcional)
CrosshairButton.MouseEnter:Connect(function()
    CrosshairButton.BackgroundColor3 = Color3.fromRGB(144, 238, 144)  -- Color verde clarito al pasar el mouse
end)

CrosshairButton.MouseLeave:Connect(function()
    CrosshairButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al color original
end)

-- Crear el botón de vuelo
local FlyButton = Instance.new("TextButton")
FlyButton.Name = "FlyButton"
FlyButton.Parent = ExtraFrame
FlyButton.Text = "Fly: Off"  -- Estado inicial
FlyButton.Font = Enum.Font.GothamBold
FlyButton.TextSize = 18
FlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FlyButton.Size = UDim2.new(0, 240, 0, 40)
FlyButton.Position = UDim2.new(0, 10, 0, 10) -- Ajustar posición
FlyButton.BorderSizePixel = 0
FlyButton.BackgroundTransparency = 0.1

-- Redondear esquinas
FlyButton.AutoButtonColor = false
FlyButton.ClipsDescendants = true
local cornerFly = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerFly.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas
cornerFly.Parent = FlyButton

-- Efecto de hover (opcional)
FlyButton.MouseEnter:Connect(function()
    FlyButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)  -- Color verde clarito al pasar el mouse
end)

FlyButton.MouseLeave:Connect(function()
    FlyButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al color original
end)


-- Funcionalidades del menú
CombatButton.MouseButton1Click:Connect(function()
    CombatFrame.Visible = not CombatFrame.Visible
    VisualFrame.Visible = false
    ExtraFrame.Visible = false
end)
VisualButton.MouseButton1Click:Connect(function()
    VisualFrame.Visible = not VisualFrame.Visible
    CombatFrame.Visible = false
    ExtraFrame.Visible = false
end)
ExtraButton.MouseButton1Click:Connect(function()
    ExtraFrame.Visible = not ExtraFrame.Visible
    CombatFrame.Visible = false
    VisualFrame.Visible = false
end)

-- Toggle Aimbot
local aimbotEnabled = false
AimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        AimbotButton.Text = "Aimbot: On"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/combat/aimbot.lua"))()
    else
        AimbotButton.Text = "Aimbot: Off"
        if _G.disableAimbot then
            _G.disableAimbot()
        end
    end
end)

-- Toggle Aimbot NPC
local npcAimbotEnabled = false
AimbotNPCButton.MouseButton1Click:Connect(function()
    npcAimbotEnabled = not npcAimbotEnabled
    if npcAimbotEnabled then
        AimbotNPCButton.Text = "Aimbot NPC: On"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/combat/aimbotnpc.lua"))()
    else
        AimbotNPCButton.Text = "Aimbot NPC: Off"
        if _G.disableAimbotNPC then
            _G.disableAimbotNPC()
        end
    end
end)

SilenAimButton.MouseButton1Click:Connect(function()
    isSilentAimEnabled = not isSilentAimEnabled -- Cambiar el estado de Silent Aim
    if isSilentAimEnabled then
        SilenAimButton.Text = "Silent Aim: On"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/combat/silentaimb.lua"))() -- Cargar el script de Silent Aim
        activateSilentAim() -- Activar Silent Aim
    else
        SilenAimButton.Text = "Silent Aim: Off"
        if _G.disableSilentAim then
            _G.disableSilentAim() -- Desactivar Silent Aim
        end
    end
end)

-- Conectar el evento del botón
VisorButton.MouseButton1Click:Connect(function()
    visorEnabled = not visorEnabled
    _G.toggleVisor = visorEnabled -- Actualiza el estado en _G.toggleVisor
    if visorEnabled then
        VisorButton.Text = "Visor: On"
        -- Cargar el visor
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/visual/visor.lua"))()
    else
        VisorButton.Text = "Visor: Off"
        -- Desactivar el visor
        if _G.disableVisor then
            _G.disableVisor() -- Asegúrate de que esta función esté definida en tu script de visor
        end
    end
end)

local flyEnabled = false

FlyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        FlyButton.Text = "Fly: On"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/extra/fly.lua"))()
    else
        FlyButton.Text = "Fly: Off"
        if _G.disableFly then
            _G.disableFly() -- Desactivar el vuelo
        end
    end
end)


-- Funcionalidad para minimizar el menú con la tecla "P"
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        isMinimized = not isMinimized
        MainFrame.Visible = not isMinimized
    end
end)

-- Variables para el estado del Crosshair ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
local crosshairEnabled = false

-- Función para alternar el Crosshair
CrosshairButton.MouseButton1Click:Connect(function()
    crosshairEnabled = not crosshairEnabled
    CrosshairButton.Text = crosshairEnabled and "Crosshair: On" or "Crosshair: Off"
    
    if crosshairEnabled then
        -- Mostrar el crosshair
        crosshair.Visible = true
        crosshairVertical.Visible = true
    else
        -- Ocultar el crosshair
        crosshair.Visible = false
        crosshairVertical.Visible = false
    end
end)

-- Configuración del Crosshair
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- Crear Crosshair
local crosshair = Drawing.new("Line")
crosshair.Thickness = 2
crosshair.Color = Color3.fromRGB(255, 255, 255)

local crosshairVertical = Drawing.new("Line")
crosshairVertical.Thickness = 2
crosshairVertical.Color = Color3.fromRGB(255, 255, 255)

-- Actualizar la posición del Crosshair
RunService.RenderStepped:Connect(function()
    local centerX = workspace.CurrentCamera.ViewportSize.X / 2
    local centerY = workspace.CurrentCamera.ViewportSize.Y / 2
    
    crosshair.From = Vector2.new(centerX - 10, centerY)
    crosshair.To = Vector2.new(centerX + 10, centerY)
    
    crosshairVertical.From = Vector2.new(centerX, centerY - 10)
    crosshairVertical.To = Vector2.new(centerX, centerY + 10)
    
    -- Mantener la visibilidad del crosshair según el estado
    crosshair.Visible = crosshairEnabled
    crosshairVertical.Visible = crosshairEnabled
end)

-- Configuraciones del ESP ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
                local width, height = round(4 * scaleFactor, 5 * scaleFactor)
                local x, y = round(position.X, position.Y)

                -- Obtener la distancia entre el jugador local y el objetivo
                local distance = (localPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).magnitude

                -- Cambiar el color si la distancia es mayor a 800
                if distance > 800 then
                    esp.box.Color = Color3.fromRGB(0, 0, 255)  -- Azul para jugadores lejanos
                else
                    esp.box.Color = settings.teamcolor and player.TeamColor.Color or settings.defaultcolor  -- Rojo por defecto o color de equipo
                end

                esp.box.Size = newVector2(width, height)
                esp.box.Position = newVector2(round(x - width / 2, y - height / 2))

                esp.boxoutline.Size = esp.box.Size
                esp.boxoutline.Position = esp.box.Position

                -- Ajustar el tamaño del texto y cuadros en función de la distancia
                local textScale = distance <= 800 and 1.25 or 1  -- Hacer un 25% más grandes los que están cerca (<= 800)
                local nameAndDistanceScale = distance <= 800 and 1.5 or 1 -- Aumentar un 50% más para el nombre y la distancia

                -- Actualizar etiquetas de nombre, vida y distancia
                esp.name.Text = player.Name
                esp.name.Position = newVector2(x, y - height / 2 - 20)
                esp.name.Size = 16 * nameAndDistanceScale  -- Aumentar el tamaño del nombre

                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    esp.health.Text = string.format("Vida: %.0f%%", humanoid.Health / humanoid.MaxHealth * 100)
                    esp.health.Position = newVector2(x, y - height / 2 - 40)
                    esp.health.Size = 16 * textScale  -- Tamaño normal para la vida
                end

                esp.distance.Text = string.format("Distancia: %.2f", distance)
                esp.distance.Position = newVector2(x, y + height / 2 + 20)
                esp.distance.Size = 16 * nameAndDistanceScale  -- Aumentar el tamaño de la distancia
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
ESPButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
ESPButton.Size = UDim2.new(0, 240, 0, 40)
ESPButton.Position = UDim2.new(0, 10, 0, 10)

-- Añadir esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = ESPButton

-- Efecto de hover
ESPButton.MouseEnter:Connect(function()
    ESPButton.BackgroundColor3 = Color3.fromRGB(144, 238, 144)  -- Color verde clarito al pasar el mouse
end)

ESPButton.MouseLeave:Connect(function()
    ESPButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al color original
end)

-- Función para alternar el estado del ESP
ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled -- Alternar el estado
    ESPButton.Text = espEnabled and "ESP: On" or "ESP: Off" -- Actualizar el texto del botón
end)

-- Principal
for _, player in next, players:GetPlayers() do
    if player ~= localPlayer then
        createEsp(player)
    end
end

table.insert(connections, players.PlayerAdded:Connect(function(player)
    createEsp(player)
end))

table.insert(connections, players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end))

table.insert(connections, runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
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
end))

-- jesus +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Configuración inicial de Jesús
local jesusEnabled = false
local jesusFolder = workspace:FindFirstChild("JesusFolder") or Instance.new("Folder", workspace)
jesusFolder.Name = "JesusFolder"

local function onJesusToggle(enabled)
    jesusEnabled = enabled

    -- Si se desactiva, limpiar las plataformas y detener la función
    if not jesusEnabled then
        for _, v in pairs(jesusFolder:GetChildren()) do
            v:Destroy()
        end
        return
    end

    -- Verificar continuamente y crear plataformas si está habilitado
    while jesusEnabled do
        task.wait(0.1)

        local player = game.Players.LocalPlayer
        local character = player.Character

        if not character then
            continue
        end

        local head = character:FindFirstChild("Head")
        if not head then continue end

        local rayOrigin = head.Position + Vector3.new(0, 150, 0) + workspace.CurrentCamera.CFrame.LookVector * 5
        local rayDirection = Vector3.new(0, -300, 0)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {character}

        local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

        if rayResult and rayResult.Material == Enum.Material.Water then
            local platform = Instance.new("Part")
            platform.Size = Vector3.new(500, 1, 500)
            platform.Anchored = true
            platform.CanCollide = true
            platform.Position = rayResult.Position + Vector3.new(0, 0.3, 0) -- Ligeramente por encima de la superficie del agua
            platform.Material = Enum.Material.ForceField
            platform.Parent = jesusFolder
        end
    end
end

-- Crear el botón de caminar sobre agua
local JesusButton = Instance.new("TextButton")
JesusButton.Name = "JesusButton"
JesusButton.Parent = ExtraFrame
JesusButton.Text = "Jesus: Off"  -- Estado inicial
JesusButton.Font = Enum.Font.GothamBold
JesusButton.TextSize = 18
JesusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
JesusButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
JesusButton.Size = UDim2.new(0, 240, 0, 40)
JesusButton.Position = UDim2.new(0, 10, 0, 60) -- Ajustar posición
JesusButton.BorderSizePixel = 0
JesusButton.BackgroundTransparency = 0.1

-- Redondear esquinas
JesusButton.AutoButtonColor = false
JesusButton.ClipsDescendants = true
local cornerJesus = Instance.new("UICorner")  -- Añadir esquinas redondeadas
cornerJesus.CornerRadius = UDim.new(0, 12)  -- Radio de las esquinas
cornerJesus.Parent = JesusButton

-- Efecto de hover (opcional)
JesusButton.MouseEnter:Connect(function()
    JesusButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)  -- Color naranja al pasar el mouse
end)

JesusButton.MouseLeave:Connect(function()
    JesusButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)  -- Volver al color original
end)

-- Lógica para alternar la función de caminar sobre agua
JesusButton.MouseButton1Click:Connect(function()
    -- Alternar estado
    local currentState = JesusButton.Text:match("On") -- Verifica si el texto contiene "On"

    if currentState then
        -- Si está "On", cambiar a "Off"
        onJesusToggle(false)  -- Desactivar la función
        JesusButton.Text = "Jesus: Off"  -- Actualizar el texto
    else
        -- Si está "Off", cambiar a "On"
        onJesusToggle(true)  -- Activar la función
        JesusButton.Text = "Jesus: On"  -- Actualizar el texto
    end
end)

-- Implementación del toggle (opcional, ya que ya se maneja con el botón)
aimtab:AddToggle('jesus', {
    Text = 'caminar sobre el agua',
    Tooltip = 'Te permite caminar sobre el agua',
    Default = false,

    Callback = function(value)
        onJesusToggle(value)
    end
})