local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local flyEnabled = false
local flySpeed = 2 -- Aumentar la velocidad horizontal
local liftSpeed = 0.5 -- Velocidad de elevación
local fallSpeed = 0.5 -- Velocidad de caída
local isFlying = false

-- Guardar gravedad original para restaurarla después del vuelo
local originalGravity = workspace.Gravity

-- Función para iniciar el vuelo
local function startFly()
    isFlying = true
    humanoid:ChangeState(Enum.HumanoidStateType.Physics) -- Cambiar el estado del personaje
    workspace.Gravity = 0 -- Eliminar la gravedad al volar

    -- Conectar el ciclo de vuelo
    RunService.RenderStepped:Connect(function()
        if not isFlying then return end
        -- Vector de movimiento
        local moveDirection = Vector3.new(0, 0, 0)
        -- Subir cuando se presiona la barra espaciadora
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, liftSpeed, 0) -- Subir lentamente
        else
            moveDirection = moveDirection + Vector3.new(0, -fallSpeed, 0) -- Caer lentamente
        end
        -- Movimiento horizontal (W, A, S, D)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + (character.PrimaryPart.CFrame.LookVector * flySpeed) -- Avanzar
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - (character.PrimaryPart.CFrame.LookVector * flySpeed) -- Retroceder
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - (character.PrimaryPart.CFrame.RightVector * flySpeed) -- Izquierda
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + (character.PrimaryPart.CFrame.RightVector * flySpeed) -- Derecha
        end
        -- Aplicar movimiento al `HumanoidRootPart`
        rootPart.Velocity = Vector3.new(moveDirection.X * 10, moveDirection.Y * 10, moveDirection.Z * 10) -- Aumentar la velocidad para un movimiento más fluido
    end)
end

-- Función para detener el vuelo y restaurar la gravedad
local function stopFly()
    isFlying = false
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) -- Restaurar estado normal del humanoide
    workspace.Gravity = originalGravity -- Restaurar la gravedad original
    rootPart.Velocity = Vector3.new(0, 0, 0) -- Detener cualquier movimiento al dejar de volar
end

-- Función para alternar entre vuelo activado/desactivado
local function toggleFly()
    flyEnabled = not flyEnabled
    if flyEnabled then
        startFly()
    else
        stopFly()
    end
end

-- Hacer la función accesible globalmente
_G.disableFly = stopFly

-- Activar el vuelo con la tecla 'F'
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.I then
        toggleFly()
    end
end)

-- Reiniciar si el personaje muere o se respawnea
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")

    if isFlying then
        stopFly() -- Detener vuelo si el personaje es nuevo
    end
end)
