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

-- Evitar ejecución duplicada
if _G.megaAimbotLoaded then return end
_G.megaAimbotLoaded = true

-- Función para crear un Highlight en el enemigo
local function highlightEnemy(enemy)
    if not enemy or not enemy.Character then return end
    
    -- Limpiar highlight existente si es necesario
    if highlightedEnemies[enemy] then
        highlightedEnemies[enemy]:Destroy()
    end
    
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
    
    if not (playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")) then 
        return 
    end
    
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local camera = workspace.CurrentCamera
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

    -- Teletransportar al enemigo más cercano
    if closestEnemy and closestEnemy.Character and closestEnemy.Character:FindFirstChild("HumanoidRootPart") then
        local now = tick()
        
        if now - lastTeleportTime >= teleportCooldown then
            lastTeleportTime = now
            
            local playerCFrame = playerCharacter.HumanoidRootPart.CFrame
            local lookVector = playerCFrame.LookVector
            
            -- Posicionar 5 unidades frente al jugador
            local teleportPosition = playerCFrame.Position + (lookVector * 5) + Vector3.new(0, 1, 0)
            
            -- Orientar al enemigo hacia el jugador
            local newCFrame = CFrame.new(teleportPosition, playerCharacter.HumanoidRootPart.Position)
            
            closestEnemy.Character.HumanoidRootPart.CFrame = newCFrame
            closestEnemy.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            closestEnemy.Character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

-- Limpiar todos los highlights
local function clearAllHighlights()
    for enemy, highlight in pairs(highlightedEnemies) do
        if highlight then
            highlight:Destroy()
        end
    end
    highlightedEnemies = {}
end

-- Conectar el mouse derecho
mouse.Button2Down:Connect(function()
    if megAimbEnabled then
        aimbotEnabled = true
    end
end)

mouse.Button2Up:Connect(function()
    aimbotEnabled = false
    clearAllHighlights()
end)

-- Loop principal usando RunService
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
    if aimbotEnabled and megAimbEnabled then
        pcall(checkEnemies)  -- Ejecutar con protección contra errores
    end
end)

-- API pública para el menú
local MegaAimbAPI = {
    activate = function()
        megAimbEnabled = true
        print("MegaAim activado")
        return true
    end,
    
    deactivate = function()
        megAimbEnabled = false
        aimbotEnabled = false
        
        -- Limpiar highlights
        for enemy, highlight in pairs(highlightedEnemies) do
            if highlight then
                highlight:Destroy()
            end
        end
        highlightedEnemies = {}
        
        print("MegaAim desactivado")
        return true
    end,
    
    isActive = function()
        return megAimbEnabled
    end,
    
    updateSettings = function(newFov, newDistance)
        fov = newFov or fov
        maxDistance = newDistance or maxDistance
        return true
    end
}

return MegaAimbAPI