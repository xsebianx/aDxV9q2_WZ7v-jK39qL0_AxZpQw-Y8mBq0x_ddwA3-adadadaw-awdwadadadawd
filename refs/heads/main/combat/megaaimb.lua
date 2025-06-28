-- Variables para el aimbot
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local aimbotEnabled = false
local megAimbEnabled = false
local fov = 60
local maxDistance = 800
local highlightedEnemies = {}
local lastTeleportTime = 0
local teleportCooldown = 0.2

-- Función para crear un Highlight en el enemigo
local function highlightEnemy(enemy)
    if not enemy.Character then return end
    if highlightedEnemies[enemy] then return end
    
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
            local distance = (playerPosition - enemyPosition).Magnitude
            
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
            unhighlightEnemy(enemy)
        end
    end

    -- Teletransportar al enemigo más cercano con ajustes de posición (FRENTE AL JUGADOR)
    if closestEnemy and closestEnemy.Character and closestEnemy.Character:FindFirstChild("HumanoidRootPart") then
        local now = tick()
        
        -- Cooldown para evitar detección
        if now - lastTeleportTime >= teleportCooldown then
            lastTeleportTime = now
            
            -- CALCULAR POSICIÓN FRENTE AL JUGADOR
            local playerCFrame = playerCharacter.HumanoidRootPart.CFrame
            local lookVector = playerCFrame.LookVector  -- Dirección hacia donde mira el jugador
            
            -- Posicionar 5 unidades frente al jugador y 1 unidad arriba
            local teleportPosition = playerCFrame.Position + (lookVector * 5) + Vector3.new(0, 1, 0)
            
            -- Crear nuevo CFrame manteniendo la rotación original del enemigo
            local enemyRotation = closestEnemy.Character.HumanoidRootPart.CFrame - closestEnemy.Character.HumanoidRootPart.CFrame.Position
            local newCFrame = CFrame.new(teleportPosition) * enemyRotation
            
            -- Aplicar posición y resetear velocidad
            closestEnemy.Character.HumanoidRootPart.CFrame = newCFrame
            closestEnemy.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            closestEnemy.Character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
            
            -- Forzar al enemigo a mirar hacia el jugador para facilitar el disparo
            closestEnemy.Character.HumanoidRootPart.CFrame = CFrame.new(
                teleportPosition,
                playerCharacter.HumanoidRootPart.Position
            )
        end
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

-- Cambiar nombres de funciones para que coincidan
function enableMegaaimb()
    megAimbEnabled = true
end

function disableMegaaimb()
    megAimbEnabled = false
    aimbotEnabled = false
    -- Limpiar highlights
end

_G.enableMegaaimb = enableMegaaimb  -- Usar "enable" en lugar de "activate"
_G.disableMegaaimb = disableMegaaimb