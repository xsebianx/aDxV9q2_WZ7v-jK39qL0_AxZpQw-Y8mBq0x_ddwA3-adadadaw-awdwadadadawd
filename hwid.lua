local player = game.Players.LocalPlayer

-- HWIDs autorizados (ejemplos ficticios)
local permanentHWIDs = {
    "11", -- HWID permanente
    "11"  -- Otro HWID permanente
}

local temporaryHWIDs = {
    "11", -- HWID temporal
    "11"  -- Otro HWID temporal
}

-- Variables de tiempo
local passwordSetTime = nil -- Para almacenar el tiempo cuando se ingresó la contraseña temporal
local hwidExpirationTime = 604800 -- 604800 segundos = 1 semana

-- Simulación de obtener el HWID del jugador
local function getHWID()
    -- Aquí puedes implementar tu lógica para obtener el HWID real
    return "9005F968-46DF-44FC-9C68-B173D505FF37" -- Reemplaza con la lógica real
end

local playerHWID = getHWID()

local function checkHWID()
    local currentTime = os.time() -- Obtener el tiempo actual en segundos

    -- Verificar si el HWID está autorizado para acceso permanente
    if table.find(permanentHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso permanente!")
        -- Aquí puedes añadir la funcionalidad adicional para acceso permanente
        loadstring(game:HttpGet("URL_DE_TU_SCRIPT_PERMANENTE"))() -- Cambia la URL por el script permanente
        return -- Salir de la función después de ejecutar el script

    -- Verificar si el HWID está autorizado para acceso temporal
    elseif table.find(temporaryHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso temporal!")

        -- Comprobar el tiempo de acceso
        if passwordSetTime == nil then
            passwordSetTime = currentTime -- Guardar el tiempo cuando se autorizó el HWID
            print("Acceso temporal concedido por una semana.")
            -- Aquí puedes añadir la funcionalidad adicional para acceso temporal
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))() -- Cambia la URL por el script temporal
            return -- Salir de la función después de ejecutar el script

        else
            local elapsedTime = currentTime - passwordSetTime -- Calcular el tiempo transcurrido
            if elapsedTime < hwidExpirationTime then
                print("¡Acceso temporal todavía válido!")
                -- Aquí puedes añadir la funcionalidad adicional para acceso temporal
                loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))() -- Cambia la URL por el script temporal
                return -- Salir de la función después de ejecutar el script
            else
                print("El acceso temporal ha expirado.")
                passwordSetTime = nil -- Reiniciar el tiempo
            end
        end
    else
        print("Acceso denegado. Este HWID no está autorizado.")
        player:Kick("Tu HWID no está autorizado para acceder al servidor.") -- Expulsar al jugador
    end
end

-- Ejecutar la verificación de HWID
checkHWID()
