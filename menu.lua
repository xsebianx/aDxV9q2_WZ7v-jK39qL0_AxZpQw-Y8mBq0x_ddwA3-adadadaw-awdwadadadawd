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
local HackDetectorButton = Instance.new("TextButton")
local VisorButton = Instance.new("TextButton")

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

local AimbotButton = Instance.new("TextButton") -- Asegúrate de crear el botón primero
AimbotButton.Name = "AimbotButton"
AimbotButton.Parent = CombatFrame
AimbotButton.Text = "Aimbot: Off"
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.TextSize = 20
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Color blanco para el texto
AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 150, 250) -- Color azul más brillante
AimbotButton.Size = UDim2.new(0, 240, 0, 50)
AimbotButton.Position = UDim2.new(0, 10, 0, 10)
AimbotButton.BorderSizePixel = 0 -- Sin borde
AimbotButton.BackgroundTransparency = 0 -- Opaco
AimbotButton.AutoButtonColor = false -- Para controlar el color al hacer clic

-- Mejora de la forma del botón
AimbotButton.ClipsDescendants = true
local corner = Instance.new("UICorner") -- Añadir esquinas redondeadas
corner.CornerRadius = UDim.new(0, 12) -- Radio de las esquinas
corner.Parent = AimbotButton

-- Botón Aimbot NPC
AimbotNPCButton = Instance.new("TextButton") -- Crea el botón
AimbotNPCButton.Name = "AimbotNPCButton"
AimbotNPCButton.Parent = CombatFrame
AimbotNPCButton.Text = "Aimbot NPC: Off"
AimbotNPCButton.Font = Enum.Font.GothamBold
AimbotNPCButton.TextSize = 18
AimbotNPCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotNPCButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255) -- Azul claro
AimbotNPCButton.Size = UDim2.new(0, 240, 0, 40)
AimbotNPCButton.Position = UDim2.new(0, 10, 0, 60) -- Posición debajo del botón Aimbot

-- Crear el botón ESP
ESPButton.Name = "ESPButton"
ESPButton.Parent = VisualFrame
ESPButton.Text = "ESP: Off"
ESPButton.Font = Enum.Font.GothamBold
ESPButton.TextSize = 20  -- Aumenté el tamaño del texto
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Color de fondo más claro
ESPButton.Size = UDim2.new(0, 250, 0, 50)  -- Tamaño del botón un poco más grande
ESPButton.Position = UDim2.new(0, 20, 0, 20)  -- Posición ajustada para un poco de margen
ESPButton.BorderSizePixel = 0  -- Sin borde
ESPButton.BackgroundTransparency = 0.2  -- Transparencia para un efecto más suave

-- Opcional: Añadir un efecto de esquina redondeada
ESPButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  -- Un color de fondo oscuro
ESPButton.Size = UDim2.new(0, 240, 0, 40)
ESPButton.Position = UDim2.new(0.5, -120, 0, 10)  -- Centrado horizontalmente
ESPButton.BorderSizePixel = 0  -- Sin borde
ESPButton.BackgroundTransparency = 0.3  -- Hacerlo un poco más transparente

-- Crear un efecto de hover (opcional)
ESPButton.MouseEnter:Connect(function()
    ESPButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)  -- Color más claro al pasar el mouse
end)

ESPButton.MouseLeave:Connect(function()
    ESPButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Volver al color original
end)


-- Funcionalidades de Visual
local VisorButton = Instance.new("TextButton") -- Asegúrate de crear la instancia del botón
VisorButton.Name = "VisorButton" -- Cambié el nombre aquí
VisorButton.Parent = VisualFrame
VisorButton.Text = "Visor: Off" -- Cambié el texto para que se refiera al visor
VisorButton.Font = Enum.Font.GothamBold
VisorButton.TextSize = 18
VisorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VisorButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
VisorButton.Size = UDim2.new(0, 240, 0, 40)
VisorButton.Position = UDim2.new(0, 10, 0, 60) -- Cambié la posición para que esté debajo de ESP

-- Funcionalidades de Extra
HackDetectorButton.Name = "HackDetectorButton"
HackDetectorButton.Parent = ExtraFrame
HackDetectorButton.Text = "Hack Detector: Off"
HackDetectorButton.Font = Enum.Font.GothamBold
HackDetectorButton.TextSize = 18
HackDetectorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HackDetectorButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
HackDetectorButton.Size = UDim2.new(0, 240, 0, 40)
HackDetectorButton.Position = UDim2.new(0, 10, 0, 10)

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

local espEnabled = false
ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ESPButton.Text = "ESP: On"
        -- Cargar el script de ESP
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/visual/ESP.lua"))()
    else
        ESPButton.Text = "ESP: Off"
        -- Desactivar el ESP
        if _G.disableESP then
            _G.disableESP() -- Asegúrate de que esta función esté definida en tu script de ESP
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

-- Toggle HackDetector
local hackDetectorEnabled = false
HackDetectorButton.MouseButton1Click:Connect(function()
    hackDetectorEnabled = not hackDetectorEnabled
    if hackDetectorEnabled then
        HackDetectorButton.Text = "Hack Detector: On"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/extra/detector.lua"))()
    else
        HackDetectorButton.Text = "Hack Detector: Off"
        if _G.disableHackDetector then
            _G.disableHackDetector()
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
