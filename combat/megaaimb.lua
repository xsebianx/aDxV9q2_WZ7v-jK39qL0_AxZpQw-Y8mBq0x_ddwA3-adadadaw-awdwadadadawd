-- Variables para el aimbot
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local aimbotEnabled = false
local megAimbEnabled = false
local fov = 60
local maxDistance = 800
local highlightedEnemies = {}  -- Ahora almacena [enemigo] = highlight 

-- Función para crear un Highlight en el enemigo
local function highlightEnemy(enemy)
    if highlightedEnemies[enemy] then return end  -- Evitar duplicados
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = enemy.Character
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlightedEnemies[enemy] = highlight
end

-- Función para eliminar el Highlight del enemigo
local function unhighlightEnemy(enemy)
    if highlightedEnemies[enemy] then
        highlightedEnemies[enemy]:Destroy()
        highlightedEnemies[enemy] = nil
    end
end

-- Función para chequear enemigos y teletransportar
local function checkEnemies()
    local closestEnemy = nil
    local closestDistance = maxDistance + 1
    local playerCharacter = player.Character
    local camera = workspace.CurrentCamera
    
    if not (playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")) then 
        return 
    end
    
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local cameraDirection = camera.CFrame.LookVector
    
    for _, enemy in ipairs(game.Players:GetPlayers()) do
        if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local enemyPosition = enemy.Character.HumanoidRootPart.Position
            local distance = (playerPosition - enemyPosition).magnitude
            
            -- Verificar el ángulo del FOV
            local directionToEnemy = (enemyPosition - playerPosition).Unit
            local angle = math.deg(math.acos(cameraDirection:Dot(directionToEnemy)))
            
            if distance <= maxDistance and angle <= fov then
                highlightEnemy(enemy)
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestEnemy = enemy
                end
            else
                unhighlightEnemy(enemy)
            end
        else
            unhighlightEnemy(enemy)  -- Limpiar si el enemigo no es válido
        end
    end

    -- Teletransportar al enemigo más cercano
    if closestEnemy and closestEnemy.Character and closestEnemy.Character:FindFirstChild("HumanoidRootPart") then
        closestEnemy.Character.HumanoidRootPart.CFrame = playerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    end
end

-- Conectar el mouse derecho
mouse.Button2Down:Connect(function()
    if megAimbEnabled then
        aimbotEnabled = true
    end
end)

mouse.Button2Up:Connect(function()
    aimbotEnabled = false
    -- Limpiar todos los highlights
    for enemy, highlight in pairs(highlightedEnemies) do
        highlight:Destroy()
    end
    highlightedEnemies = {}
end)

-- Loop principal usando RunService
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
    if aimbotEnabled and megAimbEnabled then
        checkEnemies()
    end
end)

-- Funciones de activación/desactivación
function activateMegaaimb()
    megAimbEnabled = true
    print("MegaAim activado")
end

function disableMegaaimb()
    megAimbEnabled = false
    aimbotEnabled = false
    print("MegaAim desactivado")
end

-- Asignar a globales
_G.activateMegaaimb = activateMegaaimb
_G.disableMegaaimb = disableMegaaimb
