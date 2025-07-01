-- Verificar visibilidad real del objetivo
local function isTargetVisible(part)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction * distance, raycastParams)
    
    -- Si no hay resultado o el resultado es el propio jugador
    if not result then return true end
    
    local hitParent = result.Instance
    while hitParent do
        if hitParent:IsDescendantOf(part.Parent) then
            return true
        end
        hitParent = hitParent.Parent
    end
    
    return false
end
