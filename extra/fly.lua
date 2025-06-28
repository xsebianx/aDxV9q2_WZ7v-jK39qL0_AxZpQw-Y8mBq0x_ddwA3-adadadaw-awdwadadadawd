-- fly.lua (script de vuelo real)
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("HumanoidRootPart")

local flySpeed = 50
local flying = false
local flyConnection

local function startFlying()
    if flying then return end
    flying = true
    humanoid.PlatformStand = true
    
    local bg = Instance.new("BodyGyro")
    bg.P = 10000
    bg.D = 1000
    bg.MaxTorque = Vector3.new(100000, 100000, 100000)
    bg.CFrame = torso.CFrame
    bg.Parent = torso
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.Parent = torso
    
    flyConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local direction = Vector3.new()
            
            if input.KeyCode == Enum.KeyCode.W then
                direction = direction + Vector3.new(0,0,-1)
            elseif input.KeyCode == Enum.KeyCode.S then
                direction = direction + Vector3.new(0,0,1)
            elseif input.KeyCode == Enum.KeyCode.A then
                direction = direction + Vector3.new(-1,0,0)
            elseif input.KeyCode == Enum.KeyCode.D then
                direction = direction + Vector3.new(1,0,0)
            elseif input.KeyCode == Enum.KeyCode.Space then
                direction = direction + Vector3.new(0,1,0)
            elseif input.KeyCode == Enum.KeyCode.LeftShift then
                direction = direction + Vector3.new(0,-1,0)
            end
            
            direction = direction.Unit * flySpeed
            bv.Velocity = (torso.CFrame:VectorToWorldSpace(direction))
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

-- Funciones globales requeridas por el menú
_G.activateFly = startFlying
_G.disableFly = stopFlying

return {
    activate = startFlying,
    deactivate = stopFlying
}