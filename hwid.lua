local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- HWIDs configurados directamente en el script
local permanentHWIDs = {
    "tu-hwid-aqui", -- Reemplaza esto con tu HWID real
}

local temporaryHWIDs = {
    "DC61583D-84CD-48E1-8AB3-212434BDC519",
    "33"
}

-- Variables de tiempo
local passwordSetTime = nil
local hwidExpirationTime = 604800 -- 604800 segundos = 1 semana

-- Función para obtener el HWID del cliente
local function getClientHWID()
    return RbxAnalyticsService:GetClientId()
end

-- Función para verificar el HWID del jugador
local function checkHWID()
    local playerHWID = getClientHWID() -- Obtener el HWID del jugador
    print("HWID del cliente:", playerHWID)  -- Imprimir el HWID para depuración
    local currentTime = os.time() -- Obtener el tiempo actual en segundos

    -- Verificar si el HWID está autorizado para acceso permanente
    if table.find(permanentHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso permanente!")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()

    -- Verificar si el HWID está autorizado para acceso temporal
    elseif table.find(temporaryHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso temporal!")

        -- Comprobar el tiempo de acceso
        if passwordSetTime == nil then
            passwordSetTime = currentTime
            print("Acceso temporal concedido por una semana.")
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()

        else
            local elapsedTime = currentTime - passwordSetTime
            if elapsedTime < hwidExpirationTime then
                print("¡Acceso temporal todavía válido!")
                loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()
            else
                print("El acceso temporal ha expirado.")
                passwordSetTime = nil
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
