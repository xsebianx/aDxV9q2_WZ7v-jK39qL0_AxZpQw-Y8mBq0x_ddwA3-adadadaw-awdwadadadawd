local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 50
local flying = false
local flyConnection
local bg, bv  -- Variables compartidas para ambos métodos

local function startFlying()
    if flying then return end
    flying = true
    humanoid.PlatformStand = true
    
    bg = Instance.new("BodyGyro")
    bg.P = 10000
    bg.D = 1000
    bg.MaxTorque = Vector3.new(100000, 100000, 100000)
    bg.CFrame = torso.CFrame
    bg.Parent = torso
    
    bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.Parent = torso
    
    -- Control mejorado con movimiento relativo a la cámara
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        
        local camera = workspace.CurrentCamera
        local direction = Vector3.new()
        
        -- Movimiento relativo a la cámara
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        -- Aplicar velocidad solo si hay dirección
        if direction.Magnitude > 0 then
            bv.Velocity = direction.Unit * flySpeed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Actualizar la rotación para seguir la cámara
        bg.CFrame = camera.CFrame
    end)
end

local function stopFlying()
    if not flying then return end
    flying = false
    humanoid.PlatformStand = false
    
    if bg then bg:Destroy() end
    if bv then bv:Destroy() end
    if flyConnection then flyConnection:Disconnect() end
end

return {
    activate = startFlying,
    deactivate = stopFlying
}
