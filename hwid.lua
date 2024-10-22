local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")

-- Cargar HWIDs desde el archivo Lua en GitHub
local hwidConfig = loadstring(game:HttpGet("https://raw.githubusercontent.com/tu_usuario/tu_repositorio/main/hwids.lua"))() -- Cambia la URL a la ubicación de hwids.lua en tu repositorio

local permanentHWIDs = hwidConfig.permanentHWIDs
local temporaryHWIDs = hwidConfig.temporaryHWIDs

-- Variables de tiempo
local passwordSetTime = nil
local hwidExpirationTime = 604800 -- 1 semana en segundos

local function getClientHWID()
    return RbxAnalyticsService:GetClientId()
end

local function checkHWID()
    local playerHWID = getClientHWID()
    local currentTime = os.time()

    if table.find(permanentHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso permanente!")
        -- Cargar el script correspondiente para acceso permanente
        loadstring(game:HttpGet("https://raw.githubusercontent.com/tu_usuario/tu_repositorio/main/permanent_script.lua"))() -- Cambia la URL por el script permanente

    elseif table.find(temporaryHWIDs, playerHWID) then
        print("¡HWID autorizado para acceso temporal!")

        -- Comprobar el tiempo de acceso
        if passwordSetTime == nil then
            passwordSetTime = currentTime
            print("Acceso temporal concedido por una semana.")
            -- Cargar el script correspondiente para acceso temporal
            loadstring(game:HttpGet("https://raw.githubusercontent.com/tu_usuario/tu_repositorio/main/temporary_script.lua"))() -- Cambia la URL por el script temporal

        else
            local elapsedTime = currentTime - passwordSetTime
            if elapsedTime < hwidExpirationTime then
                print("¡Acceso temporal todavía válido!")
                -- Cargar el script correspondiente para acceso temporal
                loadstring(game:HttpGet("https://raw.githubusercontent.com/tu_usuario/tu_repositorio/main/temporary_script.lua"))() -- Cambia la URL por el script temporal
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
