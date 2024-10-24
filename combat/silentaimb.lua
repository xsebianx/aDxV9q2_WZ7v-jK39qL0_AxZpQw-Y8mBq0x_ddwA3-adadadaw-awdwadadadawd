local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local isSilentAimEnabled = false
local fovRadius = 100
local fovCircle
local targetCharacter
local fakeCamera
local predictionValue = 0.125 -- Valor de predicción (deltaTime) para la posición futura

-- Función para crear el círculo FOV
local function createFovCircle()
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "FovGui"

    fovCircle = Instance.new("Frame", screenGui)
    fovCircle.Name = "FovCircle"
    fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
    fovCircle.BackgroundTransparency = 1
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)

    local outline = Instance.new("ImageLabel", fovCircle)
    outline.Size = UDim2.new(1, 0, 1, 0)
    outline.BackgroundTransparency = 1
    outline.Image = "rbxassetid://7075853722"
    outline.ImageTransparency = 0.5
    outline.AnchorPoint = Vector2.new(0.5, 0.5)
    outline.Position = UDim2.new(0.5, 0, 0.5, 0)

    fovCircle.Visible = false
end

-- Función para crear la parte de la cámara falsa
local function createFakeCamera()
    fakeCamera = Instance.new("Part")
    fakeCamera.Name = "FakeCamera"
    fakeCamera.Size = Vector3.new(1, 1, 1)
    fakeCamera.Anchored = true
    fakeCamera.CanCollide = false
    fakeCamera.Transparency = 1
    fakeCamera.Parent = workspace
end

-- Función para predecir la posición del objetivo basado en la velocidad
local function predictTargetPosition(target, deltaTime)
    local head = target:FindFirstChild("Head")
    if head and target:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = target.HumanoidRootPart
        local velocity = humanoidRootPart.AssemblyLinearVelocity
        local currentPosition = head.Position
        return currentPosition + velocity * deltaTime
    end
    return nil
end

-- Función para encontrar el enemigo dentro del círculo FOV
local function findTargetWithinFovCircle()
    local player = game.Players.LocalPlayer
    local mouse = player:GetMouse()
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray = Ray.new(unitRay.Origin, unitRay.Direction * 5000)
    local hit, position = workspace:FindPartOnRay(ray, player.Character)

    if hit and hit.Parent then
        local character = hit.Parent
        if character:FindFirstChild("Head") and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            -- Comprobar si el objetivo está dentro del círculo FOV
            local screenPoint = camera:WorldToScreenPoint(character.Head.Position)
            local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
            if distanceFromCenter <= fovRadius then
                return character
            end
        end
    end

    return nil
end

-- Función para manejar el Silent Aim con predicción
local function handleSilentAim()
    if not isSilentAimEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        return
    end

    if not targetCharacter then
        targetCharacter = findTargetWithinFovCircle()
    end

    if targetCharacter then
        local head = targetCharacter:FindFirstChild("Head")
        if head then
            -- Predecir la futura posición del objetivo usando predictionValue
            local predictedPosition = predictTargetPosition(targetCharacter, predictionValue)

            -- Actualizar la cámara falsa para apuntar a la posición predicha o a la cabeza
            if fakeCamera then
                fakeCamera.CFrame = CFrame.new(camera.CFrame.Position, predictedPosition or head.Position)
            end

            -- Simular que la cámara apunta hacia el objetivo
            if camera:FindFirstChild("ViewModel") then
                local vm = camera.ViewModel
                local aimPart = vm:FindFirstChild("AimPart")
                local aimPartCanted = vm:FindFirstChild("AimPartCanted")

                if aimPart and aimPartCanted then
                    -- Apuntar hacia la posición predicha o a la cabeza
                    local aimPosition = predictedPosition or head.Position
                    aimPart.CFrame = CFrame.new(camera.CFrame.Position, aimPosition)
                    aimPartCanted.CFrame = CFrame.new(camera.CFrame.Position, aimPosition)
                end
            end
        end
    end
end

-- Función para actualizar la visibilidad y posición del círculo FOV
local function updateFovCircle()
    local mouse = game.Players.LocalPlayer:GetMouse()
    if fovCircle then
        fovCircle.Position = UDim2.new(0, mouse.X - fovRadius, 0, mouse.Y - fovRadius)
        fovCircle.Visible = isSilentAimEnabled
    end
end

-- Función para activar el Silent Aim
function activateSilentAim()
    isSilentAimEnabled = true
    fovCircle.Visible = true
    targetCharacter = nil  -- Reiniciar el objetivo bloqueado al activar
end

-- Función para desactivar el Silent Aim
function disableSilentAim()
    isSilentAimEnabled = false
    fovCircle.Visible = false
    targetCharacter = nil  -- Reiniciar el objetivo bloqueado al desactivar
end

-- Asignar la función de desactivación a la variable global
_G.disableSilentAim = disableSilentAim

-- Inicializar el círculo FOV y la cámara falsa
createFovCircle()
createFakeCamera()

-- Ejemplo de bucle para comprobar y actualizar continuamente
game:GetService("RunService").RenderStepped:Connect(function()
    updateFovCircle()
    handleSilentAim()
end)

-- Escuchar eventos de inicio y fin de entrada del ratón (clic derecho) para bloquear el apuntado
local userInputService = game:GetService("UserInputService")
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and not gameProcessed then -- Botón derecho del ratón
        if isSilentAimEnabled then
            targetCharacter = findTargetWithinFovCircle()
        end
    end
end)

userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        targetCharacter = nil  -- Desbloquear el apuntado al soltar el botón derecho del ratón
    end
end)