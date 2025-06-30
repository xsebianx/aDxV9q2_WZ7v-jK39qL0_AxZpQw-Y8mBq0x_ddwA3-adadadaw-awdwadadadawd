-- Head.lua - Cabeza grande elevada con manejo robusto de errores
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- API principal
local HeadAPI = {
    active = false,
    connections = {},
    scaledPlayers = {}
}

-- Configuración
local HEAD_SCALE = 10.0  -- Factor de escala para las cabezas
local HEAD_ELEVATION = 5.0  -- Altura adicional para evitar colisiones
local LOCAL_PLAYER = Players.LocalPlayer
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)  -- Color al recibir daño
local MAX_WAIT_TIME = 5  -- Tiempo máximo de espera para la cabeza (segundos)

-- Función segura para obtener la cabeza con manejo de errores
local function safeGetHead(character)
    if not character then return nil end
    
    -- Intentar encontrar la cabeza directamente
    local head = character:FindFirstChild("Head")
    if head then return head end
    
    -- Esperar a que aparezca la cabeza
    local startTime = tick()
    while tick() - startTime < MAX_WAIT_TIME do
        head = character:FindFirstChild("Head")
        if head then return head end
        RunService.Heartbeat:Wait()
    end
    
    -- Si no se encuentra después de esperar
    warn("[HEAD WARNING] No se encontró cabeza en el personaje después de "..MAX_WAIT_TIME.." segundos")
    return nil
end

-- Función para expandir la cabeza elevada con manejo de errores
local function expandHead(player)
    if not player or player == LOCAL_PLAYER then return end
    if HeadAPI.scaledPlayers[player] then return end  -- Evitar duplicados
    
    local character = player.Character
    if not character then return end
    
    -- Esperar segura para la cabeza
    local head = safeGetHead(character)
    if not head then return end
    
    -- Clonar la cabeza para mantener animaciones
    local headClone = head:Clone()
    headClone.Name = "BigHeadClone"
    headClone.Size = head.Size * HEAD_SCALE
    headClone.Transparency = 0.3
    headClone.Material = Enum.Material.Neon
    headClone.Color = Color3.fromRGB(255, 50, 50)
    headClone.CanCollide = false
    
    -- Ocultar la cabeza original
    head.Transparency = 1
    local originalName = head.Name
    head.Name = "OriginalHeadHidden"
    
    -- Posicionar el clon elevado
    headClone.Parent = character
    
    -- Crear un punto de anclaje elevado
    local anchor = Instance.new("Part")
    anchor.Name = "HeadAnchor"
    anchor.Size = Vector3.new(0.1, 0.1, 0.1)
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.Anchored = false
    anchor.Parent = character
    
    -- Posicionar el anclaje sobre la cabeza original
    local headPosition = head.Position
    anchor.CFrame = CFrame.new(headPosition.X, headPosition.Y + HEAD_ELEVATION, headPosition.Z)
    
    -- Conectar con weld
    local weld = Instance.new("Weld")
    weld.Part0 = anchor
    weld.Part1 = headClone
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = headClone
    
    -- Mover el anclaje con el personaje
    local movementConnection
    movementConnection = RunService.Heartbeat:Connect(function()
        if not HeadAPI.active or not player.Character or not head or not anchor then
            if movementConnection then movementConnection:Disconnect() end
            return
        end
        
        -- Manejo seguro de posición
        pcall(function()
            local headPosition = head.Position
            anchor.CFrame = CFrame.new(headPosition.X, headPosition.Y + HEAD_ELEVATION, headPosition.Z)
        end)
    end)
    
    -- Efecto visual al recibir daño
    local lastDamageTime = 0
    local damageConnection
    damageConnection = head.Touched:Connect(function(part)
        if not HeadAPI.active then return end
        if tick() - lastDamageTime < 0.2 then return end
        
        lastDamageTime = tick()
        
        -- Destello de daño
        pcall(function()
            local tween = TweenService:Create(headClone, TweenInfo.new(0.1), {
                Color = DAMAGE_COLOR
            })
            tween:Play()
            
            tween.Completed:Wait()
            
            if headClone and headClone.Parent then
                TweenService:Create(headClone, TweenInfo.new(0.2), {
                    Color = Color3.fromRGB(255, 50, 50)
                }):Play()
            end
        end)
    end)
    
    -- Guardar referencias
    HeadAPI.scaledPlayers[player] = {
        originalHead = head,
        headClone = headClone,
        anchor = anchor,
        movementConnection = movementConnection,
        damageConnection = damageConnection,
        originalTransparency = 0,  -- Guardamos la transparencia original como 0
        originalName = originalName
    }
end

-- Restaura la cabeza a su estado normal con manejo de errores
local function restoreHead(player)
    local data = HeadAPI.scaledPlayers[player]
    if not data then return end
    
    -- Restaurar cabeza original con protección
    pcall(function()
        if data.originalHead and data.originalHead.Parent then
            data.originalHead.Transparency = data.originalTransparency
            data.originalHead.Name = data.originalName
        end
    end)
    
    -- Eliminar elementos creados con protección
    pcall(function()
        if data.headClone and data.headClone.Parent then
            data.headClone:Destroy()
        end
    end)
    
    pcall(function()
        if data.anchor and data.anchor.Parent then
            data.anchor:Destroy()
        end
    end)
    
    -- Desconectar eventos con protección
    pcall(function()
        if data.movementConnection then
            data.movementConnection:Disconnect()
        end
    end)
    
    pcall(function()
        if data.damageConnection then
            data.damageConnection:Disconnect()
        end
    end)
    
    HeadAPI.scaledPlayers[player] = nil
end

-- Maneja nuevos jugadores con protección
local function handlePlayerAdded(player)
    if not HeadAPI.active then return end
    pcall(expandHead, player)
end

-- Maneja cambio de personaje con protección
local function handleCharacterAdded(player, character)
    if not HeadAPI.active then return end
    
    -- Esperar a que el personaje esté listo
    local success = pcall(function()
        character:WaitForChild("HumanoidRootPart", MAX_WAIT_TIME)
        task.wait(0.5)  -- Espera adicional para asegurar estabilidad
        expandHead(player)
    end)
    
    if not success then
        warn("[HEAD ERROR] Error al cargar personaje de "..player.Name)
    end
end

-- Activar el script con protección completa
function HeadAPI.activate()
    if HeadAPI.active then return false end
    HeadAPI.active = true
    
    -- Manejar jugadores existentes con protección
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER then
            pcall(function()
                if player.Character then
                    expandHead(player)
                end
                
                -- Conectar evento para cambio de personaje
                local conn = player.CharacterAdded:Connect(function(char)
                    pcall(handleCharacterAdded, player, char)
                end)
                table.insert(HeadAPI.connections, conn)
            end)
        end
    end
    
    -- Conectar nuevos jugadores
    local newPlayerConn = Players.PlayerAdded:Connect(function(p)
        pcall(handlePlayerAdded, p)
    end)
    table.insert(HeadAPI.connections, newPlayerConn)
    
    return true
end

-- Desactivar el script con protección completa
function HeadAPI.deactivate()
    if not HeadAPI.active then return false end
    HeadAPI.active = false
    
    -- Desconectar eventos con protección
    for _, conn in ipairs(HeadAPI.connections) do
        pcall(conn.Disconnect, conn)
    end
    HeadAPI.connections = {}
    
    -- Restaurar todos los jugadores con protección
    for player in pairs(HeadAPI.scaledPlayers) do
        pcall(restoreHead, player)
    end
    HeadAPI.scaledPlayers = {}
    
    return true
end

-- Manejo seguro de errores
function HeadAPI.safeActivate()
    local success, err = pcall(HeadAPI.activate)
    if not success then
        warn("[HEAD CRITICAL ERROR] Activation failed:", err)
        return false
    end
    return true
end

function HeadAPI.safeDeactivate()
    local success, err = pcall(HeadAPI.deactivate)
    if not success then
        warn("[HEAD CRITICAL ERROR] Deactivation failed:", err)
        return false
    end
    return true
end

return HeadAPI
