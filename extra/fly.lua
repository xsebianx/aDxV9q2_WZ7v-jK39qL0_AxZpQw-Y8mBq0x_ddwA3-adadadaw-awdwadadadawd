local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 100  -- ¡Velocidad máxima!
local flying = false
local flyConnection

local function startFlying()
    if flying then return end
    flying = true
    
    -- Crear efectos visuales obvios
    local fire = Instance.new("Fire")
    fire.Size = 5
    fire.Heat = 0
    fire.Color = Color3.new(0, 0.5, 1)
    fire.SecondaryColor = Color3.new(0, 1, 1)
    fire.Parent = torso
    
    local sparkles = Instance.new("Sparkles")
    sparkles.SparkleColor = Color3.new(0, 1, 1)
    sparkles.Parent = torso
    
    -- Sistema de vuelo hiper-simple
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        
        local camera = workspace.CurrentCamera
        local moveDir = Vector3.new()
        
        -- Controles directos
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camera.CFrame.LookVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camera.CFrame.LookVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camera.CFrame.RightVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camera.CFrame.RightVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir + Vector3.new(0, -1, 0)
        end
        
        -- ¡Aplicar movimiento directamente!
        if moveDir.Magnitude > 0 then
            torso.Velocity = moveDir.Unit * flySpeed
        else
            torso.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    
    -- Eliminar efectos
    for _, effect in ipairs(torso:GetChildren()) do
        if effect:IsA("Fire") or effect:IsA("Sparkles") then
            effect:Destroy()
        end
    end
    
    -- Detener movimiento
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    torso.Velocity = Vector3.new(0, 0, 0)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

return {
    activate = startFlying,
    deactivate = stopFying
}
