-- Variables para almacenar elementos de UI
local enemyMenu
local enemyLabels = {}
local enemySpheres = {}
local detectionRadius = 300 -- Radio de detección para el enemigo
local detectEnabled = false -- Variable para el estado de detección

-- Función para activar la detección
function activateDetect()
    detectEnabled = true -- Activar la detección
    print("Detección activada.") -- Confirmar que se ha activado
end

-- Función para desactivar la detección
function disableDetect()
    detectEnabled = false -- Desactivar la detección
    print("Detección desactivada.") -- Confirmar que se ha desactivado
end

-- Asignar las funciones a las variables globales
_G.activateDetect = activateDetect
_G.disableDetect = disableDetect

-- Crear un mini menú para mostrar enemigos
local function createEnemyMenu()
    local screenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    enemyMenu = Instance.new("ScrollingFrame", screenGui)
    enemyMenu.Size = UDim2.new(0, 220, 0, 140) -- Tamaño del menú
    enemyMenu.Position = UDim2.new(0.8, 0, 0.1, 0) -- Posición a la derecha del mapa
    enemyMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Color de fondo
    enemyMenu.BackgroundTransparency = 0.8 -- Fondo semi-transparente
    enemyMenu.CanvasSize = UDim2.new(0, 0, 0, 0) -- Tamaño del canvas para el desplazamiento
    enemyMenu.ScrollBarThickness = 10 -- Grosor de la barra de desplazamiento

    local title = Instance.new("TextLabel", enemyMenu)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "Enemigos Cercanos"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.TextStrokeTransparency = 0.5 -- Añadir contorno al texto

    -- Crear espacio para mostrar enemigos
    for i = 1, 20 do -- Aumentar el número de etiquetas para permitir más enemigos
        local enemyLabel = Instance.new("TextLabel", enemyMenu)
        enemyLabel.Size = UDim2.new(1, 0, 0, 20)
        enemyLabel.Position = UDim2.new(0, 0, 0, 30 + (i - 1) * 25)
        enemyLabel.BackgroundTransparency = 1
        enemyLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        enemyLabel.Visible = false
        enemyLabel.TextStrokeTransparency = 0.5 -- Añadir contorno al texto de los enemigos
        table.insert(enemyLabels, enemyLabel) -- Agregar a la lista de etiquetas
    end
end

-- Crear una esfera para marcar enemigos
local function createSphere()
    local sphere = Instance.new("BillboardGui")
    sphere.Size = UDim2.new(0, 30, 0, 30) -- Cambiar tamaño de la esfera
    sphere.AlwaysOnTop = true
    sphere.LightInfluence = 0
    local image = Instance.new("ImageLabel", sphere)
    image.Size = UDim2.new(1, 0, 1, 0)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://3944703587" -- ID de la imagen de la esfera
    image.ImageColor3 = Color3.fromRGB(255, 0, 0)
    return sphere
end

-- Función para verificar y apuntar a los enemigos
local function checkForEnemies()
    if not detectEnabled then return end -- Verificar si la detección está habilitada

    local players = game.Players:GetPlayers()
    local localPlayer = game.Players.LocalPlayer
    local enemyCount = 0

    -- Ocultar todas las etiquetas de enemigos
    for _, label in pairs(enemyLabels) do
        label.Visible = false
    end

    -- Limpiar esferas existentes
    for _, sphere in pairs(enemySpheres) do
        sphere:Destroy() -- Destruir la esfera
    end
    enemySpheres = {} -- Reiniciar la lista de esferas

    for _, player in pairs(players) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local enemyPosition = player.Character.HumanoidRootPart.Position
            local distance = (localPlayer.Character.HumanoidRootPart.Position - enemyPosition).magnitude
            
            if distance <= detectionRadius then
                enemyCount += 1
                -- Actualizar el mini menú con el nombre del enemigo
                if enemyCount <= #enemyLabels then
                    enemyLabels[enemyCount].Text = player.Name
                    enemyLabels[enemyCount].Visible = true
                end

                -- Crear y posicionar la esfera
                local sphere = createSphere()
                sphere.Parent = player.Character.HumanoidRootPart
                sphere.Adornee = player.Character.HumanoidRootPart
                table.insert(enemySpheres, sphere) -- Guardar la esfera en la lista
            end
        end
    end

    -- Ajustar el tamaño del canvas del menú según la cantidad de enemigos
    enemyMenu.CanvasSize = UDim2.new(0, 0, 0, 30 + enemyCount * 25)

    -- Mostrar o ocultar el menú según si hay enemigos
    enemyMenu.Visible = enemyCount > 0
end

-- Crear los elementos de UI
createEnemyMenu()

-- Conectar la función de verificación en cada ciclo si la detección está activada
game:GetService("RunService").RenderStepped:Connect(checkForEnemies)

-- Mensaje para confirmar que el script se ha ejecutado
print("El sistema de detección de enemigos está activado. Usa _G.activateDetect() para activarlo y _G.disableDetect() para desactivarlo.")