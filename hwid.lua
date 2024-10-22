local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- HWIDs configurados directamente en el script
local permanentHWIDs = {
    "9005F968-46DF-44FC-9C68-B173D505FF37",
    "22"
}

local temporaryHWIDs = {
    "DC61583D-84CD-48E1-8AB3-212434BDC519",
    "33"
}

-- Variables de tiempo
local passwordSetTime = nil -- Para almacenar el tiempo cuando se ingresó la contraseña temporal
local hwidExpirationTime = 604800 -- 604800 segundos = 1 semana

-- Función para obtener el HWID del cliente
local function getClientHWID()
    return RbxAnalyticsService:GetClientId()
end

-- Función para verificar el HWID del jugador
local function checkHWID()
    local playerHWID = getClientHWID() -- Obtener el HWID del jugador
    local currentTime = os.time() -- Obtener el tiempo actual en segundos

    -- Verificar si el HWID está autorizado para acceso permanente
    if table.find(permanentHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso permanente!")
        -- Aquí puedes añadir la funcionalidad adicional para acceso permanente
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))() -- Cambia la URL por el script permanente

    -- Verificar si el HWID está autorizado para acceso temporal
    elseif table.find(temporaryHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso temporal!")

        -- Comprobar el tiempo de acceso
        if passwordSetTime == nil then
            passwordSetTime = currentTime -- Guardar el tiempo cuando se autorizó el HWID
            print("Acceso temporal concedido por una semana.")
            -- Aquí puedes añadir la funcionalidad adicional para acceso temporal
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))() -- Cambia la URL por el script temporal

        else
            local elapsedTime = currentTime - passwordSetTime -- Calcular el tiempo transcurrido
            if elapsedTime < hwidExpirationTime then
                print("¡Acceso temporal todavía válido!")
                -- Aquí puedes añadir la funcionalidad adicional para acceso temporal
                loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))() -- Cambia la URL por el script temporal
            else
                print("El acceso temporal ha expirado.")
                passwordSetTime = nil -- Reiniciar el tiempo
            end
        end

    else
        -- Notificar al jugador que su HWID no está autorizado
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Acceso denegado";
            Text = "Tu HWID no está autorizado para jugar.";
            Duration = 5;
        })

        -- Esperar un momento para que el jugador vea el mensaje antes de expulsarlo
        wait(3)
        print("HWID no autorizado. Expulsando al jugador...")
        Players.LocalPlayer:Kick("Acceso denegado. Tu HWID no está autorizado.")
    end
end

-- Ejecutar la verificación de HWID
checkHWID()
