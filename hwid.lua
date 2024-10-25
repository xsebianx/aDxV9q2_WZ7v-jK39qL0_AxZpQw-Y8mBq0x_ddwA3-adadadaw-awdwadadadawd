local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- HWIDs configurados directamente en el script
local permanentHWIDs = {
    "9005F968-46DF-44FC-9C68-B173D505FF37", -- Ragnarok
    "NUEVO-HWID-AQUI" -- Reemplaza con el nuevo HWID que deseas agregar
}

local temporaryHWIDs = {
    "DC61583D-84CD-48E1-8AB3-212434BDC519", -- Nomi
    "3D413373-88F3-4D54-8A83-14E71290BF55" -- Carlos
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
    local currentTime = os.time() -- Obtener el tiempo actual en segundos

    -- Debug: imprimir el HWID del jugador
    print("HWID del jugador:", playerHWID)

    -- Verificar si el HWID está autorizado para acceso permanente
    if table.find(permanentHWIDs, playerHWID) then
        -- Intentar cargar el menú
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()
        end)

        if not success then
            -- Si hay un error al cargar el menú, imprimir en la consola
            warn("Error al cargar el menú:", err)
        else
            -- Notificar que el acceso fue concedido
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Acceso concedido";
                Text = "¡HWID autorizado para acceso permanente!";
                Duration = 5;
            })
        end

    -- Verificar si el HWID está autorizado para acceso temporal
    elseif table.find(temporaryHWIDs, playerHWID) then
        -- Comprobar el tiempo de acceso
        if passwordSetTime == nil then
            passwordSetTime = currentTime
            -- Intentar cargar el menú
            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()
            end)

            if not success then
                warn("Error al cargar el menú:", err)
            else
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Acceso concedido";
                    Text = "¡HWID autorizado para acceso temporal!";
                    Duration = 5;
                })
            end

        else
            local elapsedTime = currentTime - passwordSetTime
            if elapsedTime < hwidExpirationTime then
                -- Intentar cargar el menú
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()
                end)

                if not success then
                    warn("Error al cargar el menú:", err)
                else
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Acceso concedido";
                        Text = "¡Acceso temporal todavía válido!";
                        Duration = 5;
                    })
                end
            else
                -- Expiración del acceso temporal
                passwordSetTime = nil
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Acceso expirado";
                    Text = "Tu acceso temporal ha expirado.";
                    Duration = 5;
                })
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
        Players.LocalPlayer:Kick("Acceso denegado. Tu HWID no está autorizado.")
    end
end

-- Ejecutar la verificación de HWID
checkHWID()