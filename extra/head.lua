local players = game:GetService("Players")
local runService = game:GetService("RunService")

local decorHeads = {}
local headExpansionEnabled = true
local HEAD_SCALE = 10

local function createDecorHead(realHead)
    local decorHead = Instance.new("Part")
    decorHead.Name = "DecorHead"
    decorHead.Shape = Enum.PartType.Ball
    decorHead.Size = realHead.Size * HEAD_SCALE
    decorHead.Material = Enum.Material.Neon
    decorHead.Color = Color3.new(1, 0, 0)
    decorHead.Transparency = 0.4
    decorHead.CanCollide = false
    decorHead.CanQuery = false
    decorHead.CanTouch = false
    decorHead.Anchored = true
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = realHead
    
    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = attachment
    alignPos.RigidityEnabled = true
    alignPos.MaxForce = 10000
    alignPos.Responsiveness = 200
    alignPos.Parent = decorHead
    
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

local function applyHeadExpansion(character)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local realHead = character:FindFirstChild("Head")
    if not realHead then return end
    
    if decorHeads[realHead] then return end
    
    local decorHead, attachment, alignPos, highlight = createDecorHead(realHead)
    
    decorHeads[realHead] = {
        decorHead = decorHead,
        attachment = attachment,
        alignPos = alignPos,
        highlight = highlight,
        humanoid = humanoid
    }
    
    realHead.Transparency = 1
    
    decorHeads[realHead].deathConnection = humanoid.Died:Connect(function()
        if decorHeads[realHead] then
            decorHead:Destroy()
            attachment:Destroy()
            decorHeads[realHead] = nil
        end
    end)
end

local function restoreHead(character)
    if not character then return end
    
    local realHead = character:FindFirstChild("Head")
    if not realHead or not decorHeads[realHead] then return end
    
    realHead.Transparency = 0
    
    local data = decorHeads[realHead]
    if data.deathConnection then
        data.deathConnection:Disconnect()
    end
    if data.decorHead then
        data.decorHead:Destroy()
    end
    if data.attachment then
        data.attachment:Destroy()
    end
    
    decorHeads[realHead] = nil
end

local function handleHeadExpansion(player)
    if player == players.LocalPlayer then return end
    
    local function setup(character)
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then
            character:WaitForChild("Humanoid", 3)
        end
        
        if headExpansionEnabled then
            applyHeadExpansion(character)
        end
    end
    
    player.CharacterAdded:Connect(setup)
    
    if player.Character then
        setup(player.Character)
    end
end

function disableHeadExpand()
    headExpansionEnabled = false
    
    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            restoreHead(player.Character)
        end
    end
    
    decorHeads = {}
end

function enableHeadExpand()
    headExpansionEnabled = true
    
    for _, player in pairs(players:GetPlayers()) do
        if player ~= players.LocalPlayer then
            handleHeadExpansion(player)
        end
    end
end

for _, player in pairs(players:GetPlayers()) do
    if player ~= players.LocalPlayer then
        handleHeadExpansion(player)
    end
end

players.PlayerAdded:Connect(function(player)
    if player ~= players.LocalPlayer then
        handleHeadExpansion(player)
    end
end)

return {
    activate = enableHeadExpand,
    deactivate = disableHeadExpand,
    isActive = function() return headExpansionEnabled end
}
