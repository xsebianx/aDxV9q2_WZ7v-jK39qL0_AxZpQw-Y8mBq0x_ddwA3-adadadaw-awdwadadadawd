-- Asegúrate de que 'plr' se refiera al jugador correcto
local plr = game.Players.LocalPlayer -- Debe estar en un contexto donde LocalPlayer es accesible

-- Variable para el estado del visor
local visorVisible = false

-- Función para actualizar el estado del visor
local function updateVisorVisibility()
    if plr and plr:FindFirstChild("PlayerGui") then
        local playerGui = plr.PlayerGui
        if playerGui:FindFirstChild("MainGui") then
            local visor = playerGui.MainGui.MainFrame.ScreenEffects:FindFirstChild("Visor")
            if visor then
                visor.Visible = visorVisible
            else
                warn("Visor no encontrado.")
            end
        else
            warn("MainGui no encontrado.")
        end
    else
        warn("PlayerGui no encontrado.")
    end
end

-- Función para habilitar o deshabilitar el visor
local function toggleVisor()
    visorVisible = not visorVisible
    updateVisorVisibility() -- Actualiza la visibilidad del visor
end

-- Exponer la función de alternancia globalmente
_G.toggleVisor = toggleVisor

-- Llama a la función al inicio para asegurarte de que el visor esté visible
updateVisorVisibility()