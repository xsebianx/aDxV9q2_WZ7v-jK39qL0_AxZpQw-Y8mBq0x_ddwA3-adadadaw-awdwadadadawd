-- Variables globales
local ammo = game.ReplicatedStorage:FindFirstChild("AmmoTypes")
local originalVelocities = {}
local originalRecoilValues = {}

-- Asegúrate de que la carpeta AmmoTypes exista
if not ammo then
    error("No se encontró la carpeta AmmoTypes en ReplicatedStorage.")
end

-- Función para guardar las velocidades y valores de retroceso originales
local function storeOriginalValues()
    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            originalVelocities[v.Name] = v:GetAttribute("MuzzleVelocity") or 3100
            originalRecoilValues[v.Name] = v:GetAttribute("RecoilStrength") or 230 -- Valor por defecto para RecoilStrength
        end
    end
end

-- Función para activar Instant Hit
local function activateInstantHit()
    storeOriginalValues() -- Guarda las velocidades y retrocesos originales
    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            v:SetAttribute("MuzzleVelocity", 3200) -- Establece velocidad de impacto instantáneo
        end
    end
end

-- Función para desactivar Instant Hit
local function disableInstantHit()
    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            local originalVelocity = originalVelocities[v.Name] or 3100
            v:SetAttribute("MuzzleVelocity", originalVelocity) -- Restablece la velocidad original
        end
    end
end

-- Función para desactivar retroceso
local function norecoil()
    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            v:SetAttribute("RecoilStrength", 0) -- Establece RecoilStrength en 0
        end
    end
end

-- Toggle para activar/desactivar Instant Hit
aimtab:AddToggle('InstantHit', {
    Text = 'Instant Hit',
    Tooltip = 'Instant Hit',
    Default = false,

    Callback = function(enabled)
        if enabled then
            activateInstantHit()
        else
            disableInstantHit()
        end
    end
})

-- Slider para ajustar RecoilStrength
aimtab:AddSlider('RecoilStrength', {
    Text = 'Recoil Slider',
    Default = 230,
    Min = 0,
    Max = 300,
    Rounding = 0,
    Compact = false,
}):OnChanged(function(State)
    for _, v in pairs(ammo:GetChildren()) do
        if v:IsA("Folder") then
            if State == 0 then
                norecoil() -- Llama a la función norecoil si el slider está en 0
            else
                v:SetAttribute("RecoilStrength", State) -- Establece el retroceso al valor del slider
            end
        end
    end
end)

-- Toggle para activar/desactivar No Recoil
aimtab:AddToggle('NoRecoil', {
    Text = 'No Recoil',
    Default = false,

    Callback = function(enabled)
        if enabled then
            norecoil() -- Llama a la función norecoil
        else
            -- Restaura los valores originales de retroceso
            for _, v in pairs(ammo:GetChildren()) do
                if v:IsA("Folder") then
                    local originalRecoil = originalRecoilValues[v.Name] or 230
                    v:SetAttribute("RecoilStrength", originalRecoil) -- Valor por defecto
                end
            end
        end
    end
})

-- Exponer las funciones si es necesario
_G.activateInstantHit = activateInstantHit
_G.disableInstantHit = disableInstantHit
_G.norecoil = norecoil