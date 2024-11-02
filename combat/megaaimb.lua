-- Variables para el aimbot
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local aimbotEnabled = false
local megAimbEnabled = false -- Estado del Megaaimb
local fov = 60 -- Grados del campo de visión
local maxDistance = 800 -- Alcance máximo
local highlightedEnemies = {}

-- Función para crear un Highlight en el enemigo
local function highlightEnemy(enemy)
    local highlight = Instance.new("Highlight")
    highlight.Parent = enemy.Character
    highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Color verde
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Color rojo para el contorno
    table.insert(highlightedEnemies, highlight)
end

-- Función para eliminar el Highlight del enemigo
local function unhighlightEnemy(enemy)
    for _, highlight in ipairs(highlightedEnemies) do
        if highlight.Parent == enemy.Character then
            highlight:Destroy()
            break
        end
    end
end

-- Función para chequear enemigos y teletransportar
local function checkEnemies()
    local closestEnemy = nil
    local closestDistance = maxDistance + 1

    for _, enemy in ipairs(game.Players:GetPlayers()) do
        if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local enemyPosition = enemy.Character.HumanoidRootPart.Position
            local playerPosition = player.Character.HumanoidRootPart.Position
            local distance = (playerPosition - enemyPosition).magnitude
            
            -- Verificar el ángulo del FOV
            local directionToEnemy = (enemyPosition - playerPosition).unit
            local camera = workspace.CurrentCamera
            local cameraDirection = camera.CFrame.lookVector
            
            local angle = math.acos(cameraDirection:Dot(directionToEnemy)) * (180 / math.pi)
            
            if distance <= maxDistance and angle <= fov then
                if distance < closestDistance then
                    closestDistance = distance
                    closestEnemy = enemy
                end
                highlightEnemy(enemy) -- Resaltar enemigo
            else
                unhighlightEnemy(enemy) -- Quitar resaltado si está fuera del rango
            end
        end
    end

    -- Teletransportar al enemigo más cercano si está dentro del rango
    if closestEnemy and closestDistance <= maxDistance then
        closestEnemy.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5) -- Teletransportar a la posición frente al jugador
    end
end

-- Conectar el mouse derecho para activar y desactivar el aimbot
mouse.Button2Down:Connect(function()
    if megAimbEnabled then
        aimbotEnabled = true
        while aimbotEnabled do
            checkEnemies()
            wait(0.1) -- Esperar un poco antes de la siguiente verificación
        end
    end
end)

mouse.Button2Up:Connect(function()
    aimbotEnabled = false
    -- Limpiar todos los highlights cuando se suelta el clic
    for _, enemy in ipairs(game.Players:GetPlayers()) do
        if enemy.Character then
            unhighlightEnemy(enemy)
        end
    end
end)

-- Función para activar el Megaaimb
function activateMegaaimb()
    megAimbEnabled = true -- Activa la funcionalidad
end

-- Función para desactivar el Megaaimb
function disableMegaaimb()
    megAimbEnabled = false -- Desactiva la funcionalidad
end

-- Asignar las funciones a las variables globales
_G.activateMegaaimb = activateMegaaimb
_G.disableMegaaimb = disableMegaaimb