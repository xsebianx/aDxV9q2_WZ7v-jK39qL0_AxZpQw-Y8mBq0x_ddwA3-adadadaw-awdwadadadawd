-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Configuración
local detectionRadius = 550 -- Radio de detección para el enemigo
local detectEnabled = false -- Estado de detección
local refreshRate = 0.2 -- Segundos entre actualizaciones

-- Variables
local enemyMenu = nil
local enemyLabels = {}
local enemySpheres = {}
local lastUpdate = 0
local detectionConnection = nil

-- Crear un mini menú para mostrar enemigos
local function createEnemyMenu()
    if enemyMenu and enemyMenu.Parent then
        enemyMenu:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DetectGui"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    enemyMenu = Instance.new("ScrollingFrame")
    enemyMenu.Name = "EnemyMenu"
    enemyMenu.Parent = screenGui
    enemyMenu.Size = UDim2.new(0, 220, 0, 140)
    enemyMenu.Position = UDim2.new(0.8, 0, 0.1, 0)
    enemyMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    enemyMenu.BackgroundTransparency = 0.8
    enemyMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
    enemyMenu.ScrollBarThickness = 8
    enemyMenu.Visible = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = enemyMenu
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = enemyMenu
    stroke.Color = Color3.fromRGB(100, 0, 0)
    stroke.Thickness = 1
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = enemyMenu
    title.Size = UDim2.new(1, -10, 0, 30)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.Text = "ENEMIGOS CERCANOS"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.TextStrokeTransparency = 0.5
    
    -- Crear espacio para mostrar enemigos
    for i = 1, 10 do
        local enemyLabel = Instance.new("TextLabel")
        enemyLabel.Name = "EnemyLabel"..i
        enemyLabel.Parent = enemyMenu
        enemyLabel.Size = UDim2.new(1, -10, 0, 20)
        enemyLabel.Position = UDim2.new(0, 5, 0, 40 + (i - 1) * 25)
        enemyLabel.BackgroundTransparency = 1
        enemyLabel.Font = Enum.Font.GothamMedium
        enemyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        enemyLabel.TextSize = 14
        enemyLabel.TextXAlignment = Enum.TextXAlignment.Left
        enemyLabel.Visible = false
        
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"..i
        distanceLabel.Parent = enemyMenu
        distanceLabel.Size = UDim2.new(0.3, -5, 0, 20)
        distanceLabel.Position = UDim2.new(0.7, 5, 0, 40 + (i - 1) * 25)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distanceLabel.TextSize = 14
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
        distanceLabel.Visible = false
        
        table.insert(enemyLabels, {name = enemyLabel, distance = distanceLabel})
    end
    
    return enemyMenu
end

-- Crear una esfera para marcar enemigos
local function createSphere()
    local sphere = Instance.new("BillboardGui")
    sphere.Size = UDim2.new(0, 30, 0, 30)
    sphere.AlwaysOnTop = true
    sphere.LightInfluence = 0
    
    local image = Instance.new("ImageLabel")
    image.Name = "EnemyIndicator"
    image.Size = UDim2.new(1, 0, 1, 0)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://3944703587"
    image.ImageColor3 = Color3.fromRGB(255, 50, 50)
    image.Parent = sphere
    
    return sphere
end

-- Función para verificar y apuntar a los enemigos
local function checkForEnemies()
    if not detectEnabled or not localPlayer.Character then return end
    if not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local currentTime = os.clock()
    if currentTime - lastUpdate < refreshRate then return end
    lastUpdate = currentTime
    
    local players = Players:GetPlayers()
    local localRoot = localPlayer.Character.HumanoidRootPart
    local enemyCount = 0
    
    -- Ocultar todas las etiquetas de enemigos
    for _, labelPair in ipairs(enemyLabels) do
        labelPair.name.Visible = false
        labelPair.distance.Visible = false
    end
    
    -- Limpiar esferas de enemigos que ya no están en el radio
    for player, sphere in pairs(enemySpheres) do
        if not player:IsDescendantOf(Players) or 
           not player.Character or 
           not player.Character:FindFirstChild("HumanoidRootPart") or
           (localRoot.Position - player.Character.HumanoidRootPart.Position).magnitude > detectionRadius then
            sphere:Destroy()
            enemySpheres[player] = nil
        end
    end
    
    for _, player in ipairs(players) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local enemyPosition = player.Character.HumanoidRootPart.Position
            local distance = (localRoot.Position - enemyPosition).magnitude
            
            if distance <= detectionRadius then
                enemyCount += 1
                
                -- Actualizar el mini menú
                if enemyCount <= #enemyLabels then
                    enemyLabels[enemyCount].name.Text = player.Name
                    enemyLabels[enemyCount].name.Visible = true
                    
                    enemyLabels[enemyCount].distance.Text = string.format("%.0f", distance).."m"
                    enemyLabels[enemyCount].distance.Visible = true
                end
                
                -- Crear o actualizar esfera
                if not enemySpheres[player] then
                    enemySpheres[player] = createSphere()
                    enemySpheres[player].Parent = player.Character
                    enemySpheres[player].Adornee = player.Character.HumanoidRootPart
                end
            end
        end
    end
    
    -- Ajustar el tamaño del canvas del menú
    if enemyMenu then
        enemyMenu.CanvasSize = UDim2.new(0, 0, 0, 40 + enemyCount * 25)
        enemyMenu.Visible = enemyCount > 0
    end
end

-- Función para activar la detección
function activateDetect()
    if detectEnabled then return end
    
    detectEnabled = true
    createEnemyMenu()
    
    if not detectionConnection then
        detectionConnection = RunService.Heartbeat:Connect(checkForEnemies)
    end
    
    return true
end

-- Función para desactivar la detección
function disableDetect()
    if not detectEnabled then return end
    
    detectEnabled = false
    
    if detectionConnection then
        detectionConnection:Disconnect()
        detectionConnection = nil
    end
    
    -- Ocultar todas las etiquetas de enemigos
    for _, labelPair in ipairs(enemyLabels) do
        labelPair.name.Visible = false
        labelPair.distance.Visible = false
    end
    
    -- Limpiar esferas existentes
    for _, sphere in pairs(enemySpheres) do
        sphere:Destroy()
    end
    enemySpheres = {}
    
    -- Ocultar menú
    if enemyMenu then
        enemyMenu.Visible = false
    end
    
    return true
end

-- Función para limpiar completamente
function cleanDetect()
    disableDetect()
    
    if enemyMenu and enemyMenu.Parent then
        enemyMenu.Parent:Destroy()
        enemyMenu = nil
    end
end

-- Asignar las funciones a las variables globales
_G.activateDetect = activateDetect
_G.disableDetect = disableDetect
_G.cleanDetect = cleanDetect

-- Limpieza al cerrar el juego
game:BindToClose(cleanDetect)