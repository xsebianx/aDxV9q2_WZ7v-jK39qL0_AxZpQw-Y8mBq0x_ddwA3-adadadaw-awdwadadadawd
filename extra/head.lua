local players = game:GetService("Players")

-- Función para cambiar el tamaño de la cabeza y hacerla transparente
local function expandHead(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:FindFirstChild("Head")

    if head then
        head.Size = Vector3.new(10, 10, 10)
        head.Transparency = 0.5
        head.CanCollide = false -- Desactivar colisiones de la cabeza
    end
end

-- Conectar el evento de reaparición para cada jugador
local function setupRespawnListener(player)
    player.CharacterAdded:Connect(function(character)
        expandHead(player)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            player.CharacterAdded:Wait()
            expandHead(player)
        end)
    end)
end

-- Activar la expansión de la cabeza
function activateHeadExpand()
    for _, player in pairs(players:GetPlayers()) do
        expandHead(player)
    end
end

-- Desactivar la expansión de la cabeza
function disableHeadExpand()
    for _, player in pairs(players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("Head") then
            local head = character.Head
            head.Size = Vector3.new(2, 1, 1)
            head.Transparency = 0
            head.CanCollide = true -- Restablecer las colisiones
        end
    end
end

-- Conectar al evento PlayerAdded
players.PlayerAdded:Connect(setupRespawnListener)

-- Aplicar a los jugadores existentes
for _, player in pairs(players:GetPlayers()) do
    setupRespawnListener(player)
    expandHead(player)
end

-- Asignar las funciones a las variables globales
_G.activateHeadExpand = activateHeadExpand
_G.disableHeadExpand = disableHeadExpand
