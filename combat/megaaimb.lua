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

-- Obtener servicios necesarios
local RunService = game:GetService("RunService")

-- Conexiones
local mouseButton2DownConnection
local mouseButton2UpConnection
local heartbeatConnection

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

-- Conectar eventos del mouse
local function connectMouseEvents()
    if mouseButton2DownConnection then
        mouseButton2DownConnection:Disconnect()
    end
    if mouseButton2UpConnection then
        mouseButton2UpConnection:Disconnect()
    end
    
    mouseButton2DownConnection = mouse.Button2Down:Connect(function()
        if megAimbEnabled then
            aimbotEnabled = true
        end
    end)
    
    mouseButton2UpConnection = mouse.Button2Up:Connect(function()
        aimbotEnabled = false
        clearAllHighlights()
    end)
end

-- Conectar loop principal
local function connectHeartbeat()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if aimbotEnabled and megAimbEnabled then
            pcall(checkEnemies)  -- Ejecutar con protección contra errores
        end
    end)
end

-- Desconectar todos los eventos
local function disconnectAllEvents()
    if mouseButton2DownConnection then
        mouseButton2DownConnection:Disconnect()
        mouseButton2DownConnection = nil
    end
    
    if mouseButton2UpConnection then
        mouseButton2UpConnection:Disconnect()
        mouseButton2UpConnection = nil
    end
    
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

-- API para el menú
local MegaAimbAPI = {
    activate = function()
        if megAimbEnabled then return true end
        
        megAimbEnabled = true
        aimbotEnabled = false
        
        -- Reiniciar conexiones
        disconnectAllEvents()
        connectMouseEvents()
        connectHeartbeat()
        
        return true
    end,
    
    deactivate = function()
        if not megAimbEnabled then return true end
        
        megAimbEnabled = false
        aimbotEnabled = false
        
        -- Limpiar y desconectar
        clearAllHighlights()
        disconnectAllEvents()
        
        return true
    end,
    
    isActive = function()
        return megAimbEnabled
    end
}

return MegaAimbAPI
