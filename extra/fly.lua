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
    
    flyConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local direction = Vector3.new()
            local cf = torso.CFrame
            
            if input.KeyCode == Enum.KeyCode.W then
                direction = cf.LookVector
            elseif input.KeyCode == Enum.KeyCode.S then
                direction = -cf.LookVector
            elseif input.KeyCode == Enum.KeyCode.A then
                direction = -cf.RightVector
            elseif input.KeyCode == Enum.KeyCode.D then
                direction = cf.RightVector
            elseif input.KeyCode == Enum.KeyCode.Space then
                direction = Vector3.new(0, 1, 0)
            elseif input.KeyCode == Enum.KeyCode.LeftShift then
                direction = Vector3.new(0, -1, 0)
            end
            
            bv.Velocity = direction * flySpeed
        end
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
