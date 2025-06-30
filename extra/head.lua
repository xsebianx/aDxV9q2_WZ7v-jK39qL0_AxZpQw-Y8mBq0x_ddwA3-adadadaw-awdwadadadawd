local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Tabla para rastrear las cabezas decorativas
local decorHeads = {}
local headExpansionEnabled = true

-- Tamaño de cabeza aumentado (10 veces más grande)
local HEAD_SCALE = 3

-- Función para crear una cabeza decorativa que no interfiere con los cuerpos
local function createDecorHead(realHead)
    -- Crear una parte esférica para la cabeza decorativa
    local decorHead = Instance.new("Part")
    decorHead.Name = "DecorHead"
    decorHead.Shape = Enum.PartType.Ball
    decorHead.Size = realHead.Size * HEAD_SCALE
    decorHead.Material = Enum.Material.Neon
    decorHead.Color = Color3.new(1, 0, 0) -- Rojo
    decorHead.Transparency = 0.4
    decorHead.CanCollide = false
    decorHead.CanQuery = false
    decorHead.CanTouch = false
    decorHead.Anchored = true  -- Importante para no afectar la física
    
    -- Crear un punto de unión para seguir la cabeza real
    local attachment = Instance.new("Attachment")
    attachment.Parent = realHead
    
    -- Usar un AlignPosition para seguir la cabeza sin física
    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = attachment
    alignPos.RigidityEnabled = true
    alignPos.MaxForce = 10000
    alignPos.Responsiveness = 200
    alignPos.Parent = decorHead
    
    -- Añadir un resaltado para mejor visibilidad
    local highlight = Instance.new("Highlight")
    highlight.Name = "HeadHighlight"
    highlight.FillColor = Color3.new(1, 0.5, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.new(1, 1, 0)
    highlight.OutlineTransparency = 0.3
    highlight.Parent = decorHead
    
    decorHead.Parent = workspace
    
    return decorHead, attachment, alignPos, highlight
end

-- Función para aplicar la expansión de cabeza
local function applyHeadExpansion(character)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local realHead = character:FindFirstChild("Head")
    if not realHead then return end
    
    -- Si ya tenemos una cabeza decorativa, no crear otra
    if decorHeads[realHead] then return end
    
    -- Crear cabeza decorativa
    local decorHead, attachment, alignPos, highlight = createDecorHead(realHead)
    
    -- Guardar referencia
    decorHeads[realHead] = {
        decorHead = decorHead,
        attachment = attachment,
        alignPos = alignPos,
        highlight = highlight,
        humanoid = humanoid
    }
end

-- Función para restaurar la cabeza original
local function restoreHead(character)
    if not character then return end
    
    local realHead = character:FindFirstChild("Head")
    if not realHead or not decorHeads[realHead] then return end
    
    -- Eliminar elementos decorativos
    local data = decorHeads[realHead]
    if data.decorHead then
        data.decorHead:Destroy()
    end
    if data.attachment then
        data.attachment:Destroy()
    end
    
    decorHeads[realHead] = nil
end

-- Función principal para manejar la expansión de cabeza
local function handleHeadExpansion(player)
    if player == players.LocalPlayer then return end
    
    local function setupCharacter(character)
        if not character then return end
        
        -- Esperar a que el personaje esté completamente cargado
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then
            character:WaitForChild("Humanoid", 3)
        end
        
        if headExpansionEnabled then
            applyHeadExpansion(character)
        end
        
        -- Actualizar posición de la cabeza decorativa
        if decorHeads[character] then
            decorHeads[character].updateConnection = runService.Heartbeat:Connect(function()
                if decorHeads[character] and decorHeads[character].decorHead then
                    decorHeads[character].decorHead.Position = character.Head.Position
                end
            end)
        end
    end
    
    player.CharacterAdded:Connect(setupCharacter)
    
    if player.Character then
        setupCharacter(player.Character)
    end
end

-- Función para desactivar completamente la expansión
function disableHeadExpand()
    headExpansionEnabled = false
    
    -- Restaurar todos los personajes
    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            restoreHead(player.Character)
        end
    end
    
    -- Limpiar datos
    decorHeads = {}
end

-- Función para activar la expansión
function enableHeadExpand()
    headExpansionEnabled = true
    
    -- Aplicar a todos los jugadores
    for _, player in pairs(players:GetPlayers()) do
        if player ~= players.LocalPlayer then
            handleHeadExpansion(player)
        end
    end
end

-- Inicializar con los jugadores existentes
for _, player in pairs(players:GetPlayers()) do
    if player ~= players.LocalPlayer then
        handleHeadExpansion(player)
    end
end

-- Manejar nuevos jugadores
players.PlayerAdded:Connect(function(player)
    if player ~= players.LocalPlayer then
        handleHeadExpansion(player)
    end
end

-- API para el hub
return {
    activate = enableHeadExpand,
    deactivate = disableHeadExpand,
    isActive = function() return headExpansionEnabled end
}
