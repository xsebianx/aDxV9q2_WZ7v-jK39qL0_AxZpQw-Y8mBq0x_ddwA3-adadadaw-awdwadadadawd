-- Variables globales
local ammo = game.ReplicatedStorage:FindFirstChild("AmmoTypes")
local originalVelocities = {}
local DEFAULT_VELOCITY = 3100
local INSTANT_HIT_VELOCITY = 3200

-- Función para guardar las velocidades originales
local function storeOriginalVelocities()
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            if v:IsA("Folder") and not originalVelocities[v.Name] then
                originalVelocities[v.Name] = v:GetAttribute("MuzzleVelocity") or DEFAULT_VELOCITY
            end
        end
    else
        warn("No se encontró la carpeta AmmoTypes en ReplicatedStorage.")
    end
end

-- Función para activar Instant Hit
local function activateInstantHit()
    if not ammo then return end

    storeOriginalVelocities() -- Guarda las velocidades originales solo si no se ha hecho antes

    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            v:SetAttribute("MuzzleVelocity", INSTANT_HIT_VELOCITY) -- Establece velocidad de impacto instantáneo
            print("MuzzleVelocity establecido en", INSTANT_HIT_VELOCITY, "para:", v.Name)
        end
    end
end

-- Función para desactivar Instant Hit
local function disableInstantHit()
    if not ammo then return end

    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            local originalVelocity = originalVelocities[v.Name] or DEFAULT_VELOCITY
            v:SetAttribute("MuzzleVelocity", originalVelocity) -- Restablece la velocidad original
            print("MuzzleVelocity restablecido a", originalVelocity, "para:", v.Name)
        end
    end
end

-- Expone las funciones globalmente si es necesario
_G.activateInstantHit = activateInstantHit
_G.disableInstantHit = disableInstantHit