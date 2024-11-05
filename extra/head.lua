local players = game:GetService("Players")

-- Función para crear una cabeza expandida
local function createExpandedHead(character)
    local head = character:FindFirstChild("Head")
    if head then
        -- Crear una nueva parte para la cabeza expandida
        local expandedHead = Instance.new("Part")
        expandedHead.Name = "ExpandedHead"
        expandedHead.Size = Vector3.new(10, 10, 10)
        expandedHead.Transparency = 0.5
        expandedHead.Anchored = false
        expandedHead.CanCollide = false
        expandedHead.Massless = true
        expandedHead.Parent = character

        -- Posicionar la cabeza expandida en la misma posición que la cabeza original
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = head
        weld.Part1 = expandedHead
        weld.Parent = head
    end
end

-- Función para eliminar la cabeza expandida
local function removeExpandedHead(character)
    local expandedHead = character:FindFirstChild("ExpandedHead")
    if expandedHead then
        expandedHead:Destroy()
    end
end

-- Función para expandir la cabeza del jugador
local function expandHead(player)
    local character = player.Character or player.CharacterAdded:Wait()
    createExpandedHead(character)

    -- Conectar el evento de muerte para expandir la cabeza de nuevo al reaparecer
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        humanoid:WaitForChild("HealthChanged")
        wait(0.1)
        player.CharacterAdded:Wait()
        expandHead(player)
    end)
end

-- Función para activar la expansión de la cabeza
function activateHeadExpand()
    for _, player in pairs(players:GetPlayers()) do
        expandHead(player)
    end
end

-- Función para desactivar la expansión de la cabeza
function disableHeadExpand()
    for _, player in pairs(players:GetPlayers()) do
        local character = player.Character
        if character then
            removeExpandedHead(character)
        end
    end
end

-- Conectar a los eventos de jugador
players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        expandHead(player)
    end)
end)

-- Aplicar la función a los jugadores que ya están en el juego
for _, player in pairs(players:GetPlayers()) do
    if player ~= players.LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            expandHead(player)
        end)
        expandHead(player)
    end
end

-- Asignar las funciones a las variables globales
_G.activateHeadExpand = activateHeadExpand
_G.disableHeadExpand = disableHeadExpand
