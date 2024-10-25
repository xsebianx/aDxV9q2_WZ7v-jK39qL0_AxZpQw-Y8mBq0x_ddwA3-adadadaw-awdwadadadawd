-- Variables globales
local ammo = game.ReplicatedStorage:FindFirstChild("AmmoTypes")
local originalVelocities = {}

-- Función para guardar las velocidades originales
local function storeOriginalVelocities()
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            if v:IsA("Folder") then
                originalVelocities[v.Name] = v:GetAttribute("MuzzleVelocity") or 3100
            end
        end
    else
        print("No se encontró la carpeta AmmoTypes en ReplicatedStorage.")
    end
end

-- Función para activar Instant Hit
_G.activateInstantHit = function()
    storeOriginalVelocities() -- Guarda las velocidades originales

    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            if v:IsA("Folder") then
                v:SetAttribute("MuzzleVelocity", 3200) -- Establece velocidad de impacto instantáneo
                print("MuzzleVelocity establecido en 3200 para:", v.Name)
            end
        end
    end
end

-- Función para desactivar Instant Hit
_G.disableInstantHit = function()
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            if v:IsA("Folder") then
                local originalVelocity = originalVelocities[v.Name] or 3100
                v:SetAttribute("MuzzleVelocity", originalVelocity) -- Restablece la velocidad original
                print("MuzzleVelocity restablecido a", originalVelocity, "para:", v.Name)
            end
        end
    end
end