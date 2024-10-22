-- Asegúrate de que 'plr' se refiera al jugador correcto
local plr = game.Players.LocalPlayer -- Debe estar en un contexto donde LocalPlayer es accesible

-- Variable para el estado del visor
local visorEnabled = true

-- Función para actualizar el estado del visor
local function updateVisor()
    if plr and plr:FindFirstChild("PlayerGui") then
        local playerGui = plr.PlayerGui
        if playerGui:FindFirstChild("MainGui") then
            local visor = playerGui.MainGui.MainFrame.ScreenEffects:FindFirstChild("Visor")
            if visor then
                visor.Visible = visorEnabled
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

-- Llama a la función al inicio para asegurarte de que el visor esté visible
updateVisor()

-- Función para manejar la activación y desactivación del visor
_G.toggleVisor = function(state)
    visorEnabled = state -- Cambia el estado del visor
    updateVisor() -- Actualiza la visibilidad del visor
end