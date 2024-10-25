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
    end
end

-- Función para activar Instant Hit
local function activateInstantHit()
    storeOriginalVelocities()
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            if v:IsA("Folder") then
                v:SetAttribute("MuzzleVelocity", 3200)
            end
        end
    end
end

-- Función para desactivar Instant Hit
local function disableInstantHit()
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            if v:IsA("Folder") then
                local originalVelocity = originalVelocities[v.Name] or 3100
                v:SetAttribute("MuzzleVelocity", originalVelocity)
            end
        end
    end
end

-- Exposición de funciones globales
_G.activateInstantHit = activateInstantHit
_G.disableInstantHit = disableInstantHit

-- Toggle para activar/desactivar Instant Hit
aimtab:AddToggle('InstantHit', {
    Text = 'Instant Hit',
    Default = false,

    Callback = function(enabled)
        if enabled then
            _G.activateInstantHit()
        else
            _G.disableInstantHit()
        end
    end
})

-- Slider para ajustar la fuerza del retroceso
aimtab:AddSlider('RecoilStrength', {
    Text = 'Recoil Slider',
    Default = 230,
    Min = 0,
    Max = 300,
}):OnChanged(function(State)
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            v:SetAttribute("RecoilStrength", State)
        end
    end
end)