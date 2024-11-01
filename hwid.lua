local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")

-- HWIDs configurados directamente en el script
local authorizedHWIDs = {
    permanent = {
        ["9005F968-46DF-44FC-9C68-B173D505FF37"] = false, -- Ragnarok
        ["AQUI_VA_EL_HWID_DE_TU_COMPA"] = true, -- Reemplaza esto con el HWID de tu amigo
    },
    temporary = {
        ["DC61583D-84CD-48E1-8AB3-212434BDC519"] = true, -- Nomi
        ["3D413373-88F3-4D54-8A83-14E71290BF55"] = true, -- Carlos
        ["AQUI_VA_EL_HWID_DE_TU_COMPA_TEMPORAL"] = true, -- HWID temporal
    }
}

-- Variable para permitir acceso a todos los HWIDs
local allowAllHWIDs = true

-- Variables de tiempo
local passwordSetTime = nil
local hwidExpirationTime = 604800 -- 1 semana en segundos

-- Función para notificaciones de usuarios
local function notificarJugador(titulo, mensaje, duracion)
    StarterGui:SetCore("SendNotification", {
        Title = titulo;
        Text = mensaje;
        Duration = duracion;
    })
end

-- Función para cargar el menú remoto
local function cargarMenu()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xsebianx/awdadadawwadwadabadBVWBRwqddadda-adadadaw-awdwadadadawd/refs/heads/main/menu.lua"))()
    end)
   
    if success then
        notificarJugador("Acceso concedido", "¡HWID autorizado!", 5)
    else
        warn("Error al cargar el menú:", err)
        notificarJugador("Error", "No se pudo cargar el menú.", 5)
    end
    return success
end

-- Función para verificar el HWID del jugador
local function autorizarHWID(playerHWID, currentTime)
    if allowAllHWIDs then
        print("Acceso permitido para todos los HWIDs.")
        cargarMenu()
    elseif authorizedHWIDs.permanent[playerHWID] == true then
        print("Acceso permanente concedido.")
        passwordSetTime = nil -- Reiniciar el tiempo de la contraseña para acceso permanente
        cargarMenu()
    elseif authorizedHWIDs.temporary[playerHWID] == true then
        print("Acceso temporal concedido.")
        if passwordSetTime == nil then
            passwordSetTime = currentTime
            cargarMenu()
        else
            local elapsedTime = currentTime - passwordSetTime
            if elapsedTime < hwidExpirationTime then
                cargarMenu()
                notificarJugador("Acceso temporal", "¡Acceso temporal todavía válido!", 5)
            else
                -- Expiración del acceso temporal
                passwordSetTime = nil
                notificarJugador("Acceso expirado", "Tu acceso temporal ha expirado.", 5)
            end
        end
    else
        notificarJugador("Acceso denegado", "Tu HWID no está autorizado para jugar.", 5)
        wait(3)
        Players.LocalPlayer:Kick("Acceso denegado. Tu HWID no está autorizado.")
    end
end

-- Función principal para obtener y verificar el HWID del cliente
local function verificarHWID()
    local playerHWID = RbxAnalyticsService:GetClientId() -- Obtener el HWID del jugador
    local currentTime = os.time() -- Obtener el tiempo actual en segundos
    print("Comprobando acceso para HWID:", playerHWID)
    autorizarHWID(playerHWID, currentTime)
end

-- Ejecutar la verificación de HWID
verificarHWID()