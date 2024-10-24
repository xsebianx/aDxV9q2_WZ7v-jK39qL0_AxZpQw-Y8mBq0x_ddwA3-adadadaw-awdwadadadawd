-- Variables globales
local jesusEnabled = false
local jesusFolder = workspace:FindFirstChild("JesusFolder") or Instance.new("Folder", workspace)
jesusFolder.Name = "JesusFolder"

local function onJesusToggle(enabled)
    jesusEnabled = enabled

    -- Si se desactiva, limpiar las plataformas y detener la función
    if not jesusEnabled then
        for _, v in pairs(jesusFolder:GetChildren()) do
            v:Destroy()
        end
        return
    end

    -- Verificar continuamente y crear plataformas si está habilitado
    while jesusEnabled do
        task.wait(0.1)

        local player = game.Players.LocalPlayer
        local character = player.Character

        if not character then
            continue
        end

        local head = character:FindFirstChild("Head")
        if not head then continue end

        local rayOrigin = head.Position + Vector3.new(0, 150, 0) + workspace.CurrentCamera.CFrame.LookVector * 5
        local rayDirection = Vector3.new(0, -300, 0)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {character}

        local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

        if rayResult and rayResult.Material == Enum.Material.Water then
            local platform = Instance.new("Part")
            platform.Size = Vector3.new(500, 1, 500)
            platform.Anchored = true
            platform.CanCollide = true
            platform.Position = rayResult.Position + Vector3.new(0, 0.3, 0) -- Ligeramente por encima de la superficie del agua
            platform.Material = Enum.Material.ForceField
            platform.Parent = jesusFolder
        end
    end
end

-- Función para activar la capacidad de caminar sobre el agua
function activateJesus()
    onJesusToggle(true) -- Activa la funcionalidad
end

-- Función para desactivar la capacidad de caminar sobre el agua
function disableJesus()
    onJesusToggle(false) -- Desactiva la funcionalidad
end

-- Asignar las funciones a las variables globales
_G.activateJesus = activateJesus
_G.disableJesus = disableJesus