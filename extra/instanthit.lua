-- Valores para el retroceso
local Default = 230
local Min = 0
local Max = 300
local Rounding = 0  -- Ajusta si necesitas redondeo

-- Definimos el valor predeterminado de retroceso y la velocidad de salida
local instantHitVelocity = 3200
local defaultVelocity = 1000  -- Velocidad por defecto cuando Instant Hit está desactivado
local noRecoilEnabled = false  -- Estado inicial del no recoil

-- Función para generar un valor aleatorio de retroceso
local function generateRecoil()
    -- Asegúrate de que Max sea mayor que Min
    if Max <= Min then
        error("Max debe ser mayor que Min para generar un valor aleatorio.")
    end
    return math.random(Min, Max)
end

-- Función para establecer la fuerza de retroceso en todos los tipos de munición
local function setRecoilStrength(strength)
    local ammo = game:GetService("ReplicatedStorage"):FindFirstChild("AmmoTypes")
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            v:SetAttribute("RecoilStrength", strength)
        end
    else
        warn("AmmoTypes no encontrado en ReplicatedStorage")
    end
end

-- Función para establecer la velocidad de salida de los proyectiles
local function setMuzzleVelocity(velocity)
    local ammo = game:GetService("ReplicatedStorage"):FindFirstChild("AmmoTypes")
    if ammo then
        for _, v in pairs(ammo:GetChildren()) do
            v:SetAttribute("MuzzleVelocity", velocity)
        end
    else
        warn("AmmoTypes no encontrado en ReplicatedStorage")
    end
end

-- Inicializar valores
setMuzzleVelocity(defaultVelocity)
setRecoilStrength(Default)

-- Función para activar el "Instant Hit"
function activateInstantHit()
    setMuzzleVelocity(instantHitVelocity)
    setRecoilStrength(noRecoilEnabled and 0 or Default)  -- Si noRecoil está activado, establece el retroceso a 0
    print("Instant Hit activado")
end

-- Función para desactivar el "Instant Hit"
function disableInstantHit()
    setMuzzleVelocity(defaultVelocity)
    setRecoilStrength(Default)  -- Restablece el retroceso a su valor predeterminado
    print("Instant Hit desactivado")
end

-- Función para activar el "No Recoil"
function activateNoRecoil()
    noRecoilEnabled = true
    setRecoilStrength(0)  -- Establece el retroceso a 0
    print("No Recoil activado")
end

-- Función para desactivar el "No Recoil"
function disableNoRecoil()
    noRecoilEnabled = false
    setRecoilStrength(Default)  -- Restablece el retroceso a su valor predeterminado
    print("No Recoil desactivado")
end

-- Asignar las funciones a las variables globales
_G.activateInstantHit = activateInstantHit
_G.disableInstantHit = disableInstantHit
_G.activateNoRecoil = activateNoRecoil
_G.disableNoRecoil = disableNoRecoil

-- Ejemplo de uso: Cambia el retroceso usando la función generateRecoil
local recoilValue = generateRecoil()
print("Valor de retroceso generado: " .. recoilValue)