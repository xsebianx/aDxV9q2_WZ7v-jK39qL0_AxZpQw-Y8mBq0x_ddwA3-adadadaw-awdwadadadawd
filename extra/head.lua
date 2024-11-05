local players = game:GetService("Players")

-- Función para cambiar el tamaño de la cabeza y hacerla transparente
local function expandHead(player)
    if player == players.LocalPlayer then return end -- No aplicar al jugador local

    local character = player.Character or player.CharacterAdded:Wait() -- Esperar hasta que el personaje esté disponible
    local head = character:FindFirstChild("Head")
    if head then
        -- Guardar el tamaño original de la cabeza
        if not head:FindFirstChild("OriginalSize") then
            local originalSize = Instance.new("Vector3Value")
            originalSize.Name = "OriginalSize"
            originalSize.Value = head.Size
            originalSize.Parent = head
        end

        -- Cambiar el tamaño de la cabeza
        head.Size = Vector3.new(10, 10, 10) -- Ajusta el tamaño a un valor más grande
        head.Transparency = 0.5 -- 0 es opaco, 1 es completamente transparente
        head.Massless = true -- Hacer la cabeza sin masa para no afectar la física del personaje

        -- Ajustar el Mesh si existe
        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            mesh.Scale = Vector3.new(10, 10, 10)
        end
    end

    -- Conectar el evento de muerte para expandir la cabeza de nuevo al reaparecer
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        humanoid:WaitForChild("HealthChanged") -- Esperar a que cambie la salud antes de destruir el personaje
        wait(0.1) -- Esperar un momento para dar tiempo a que el personaje se elimine
        player.CharacterAdded:Wait() -- Esperar a que aparezca un nuevo personaje
        expandHead(player) -- Expandir la cabeza del nuevo personaje
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
        if character and character:FindFirstChild("Head") then
            local head = character.Head
            local originalSize = head:FindFirstChild("OriginalSize")
            if originalSize then
                head.Size = originalSize.Value -- Restablecer tamaño a los valores originales
                head.Transparency = 0 -- Hacerla opaca
                head.Massless = false -- Restaurar la masa de la cabeza

                -- Ajustar el Mesh si existe
                local mesh = head:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh.Scale = Vector3.new(1, 1, 1)
                end

                originalSize:Destroy() -- Eliminar el valor original
            end
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
    if player ~= players.LocalPlayer then -- Asegúrate de no aplicar a ti mismo
        player.CharacterAdded:Connect(function(character)
            expandHead(player)
        end)
        -- También expande la cabeza de los jugadores existentes
        expandHead(player)
    end
end

-- Asignar las funciones a las variables globales
_G.activateHeadExpand = activateHeadExpand
_G.disableHeadExpand = disableHeadExpand