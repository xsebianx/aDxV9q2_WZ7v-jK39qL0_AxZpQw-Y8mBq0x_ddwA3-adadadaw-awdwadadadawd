-- teleportMenu.lua

_G.teleportMenuActive = _G.teleportMenuActive or false

local function showTeleportMenu()
    if not _G.teleportMenuActive then
        _G.teleportMenuActive = true

        local player = game.Players.LocalPlayer
        local playerGui = player.PlayerGui

        -- Crear el GUI para el menú
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "TeleportMenuGui"
        screenGui.Parent = playerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 350, 0, 450)
        frame.Position = UDim2.new(0.7, 0, 0.2, 0)
        frame.BackgroundTransparency = 0.5
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
        frame.Parent = screenGui

        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(0, 10)
        uicorner.Parent = frame

        local shadow = Instance.new("ImageLabel")
        shadow.Size = UDim2.new(1, 10, 1, 10)
        shadow.Position = UDim2.new(0, -5, 0, -5)
        shadow.Image = "rbxassetid://1316045217"
        shadow.ImageTransparency = 0.5
        shadow.BackgroundTransparency = 1
        shadow.ZIndex = 0
        shadow.Parent = frame

        local dragging = false
        local dragStart = nil
        local startPos = nil
        frame.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        frame.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        frame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        local drakHubTitle = Instance.new("TextLabel")
        drakHubTitle.Size = UDim2.new(1, 0, 0, 30)
        drakHubTitle.Position = UDim2.new(0, 0, 0, 0)
        drakHubTitle.Text = "DrakHub"
        drakHubTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
        drakHubTitle.TextSize = 24
        drakHubTitle.BackgroundTransparency = 1
        drakHubTitle.Font = Enum.Font.GothamBold
        drakHubTitle.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.Position = UDim2.new(0, 0, 0, 30)
        title.Text = "Teletransportarse"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 20
        title.BackgroundTransparency = 1
        title.Parent = frame

        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -40, 0, 5)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        closeButton.TextSize = 16
        closeButton.Font = Enum.Font.GothamBold
        closeButton.Parent = frame

        closeButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
            _G.teleportMenuActive = false
        end)

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -10, 0, 30)
        searchBox.Position = UDim2.new(0, 5, 0, 70)
        searchBox.PlaceholderText = "Buscar..."
        searchBox.Text = ""
        searchBox.TextColor3 = Color3.fromRGB(0, 0, 0)
        searchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        searchBox.TextSize = 16
        searchBox.Parent = frame

        local containerList = Instance.new("ScrollingFrame")
        containerList.Size = UDim2.new(1, 0, 0, 350)
        containerList.Position = UDim2.new(0, 0, 0, 110)
        containerList.BackgroundTransparency = 0.5
        containerList.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        containerList.Parent = frame
        containerList.ScrollingDirection = Enum.ScrollingDirection.Y
        containerList.CanvasSize = UDim2.new(0, 0, 0, 0)

        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 10)
        listCorner.Parent = containerList

        local function updateContainerList(filter)
            for _, child in pairs(containerList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            local offset = 0
            for _, container in pairs(workspace.Interactable.Containers:GetChildren()) do
                if container:IsA("Model") and container.Name ~= "HumanoidRootPart" then
                    if not filter or string.find(container.Name:lower(), filter:lower()) then
                        local button = Instance.new("TextButton")
                        button.Size = UDim2.new(1, 0, 0, 40)
                        button.Position = UDim2.new(0, 0, 0, offset)
                        button.Text = container.Name
                        button.TextColor3 = Color3.fromRGB(255, 255, 255)
                        button.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
                        button.TextSize = 16
                        button.TextWrapped = true
                        button.Parent = containerList

                        local buttonCorner = Instance.new("UICorner")
                        buttonCorner.CornerRadius = UDim.new(0, 10)
                        buttonCorner.Parent = button

                        button.MouseButton1Click:Connect(function()
                            if container.PrimaryPart then
                                player.Character.HumanoidRootPart.CFrame = container.PrimaryPart.CFrame
                            else
                                player.Character.HumanoidRootPart.CFrame = container:GetModelCFrame()
                            end
                        end)

                        offset = offset + 40
                    end
                end
            end
            containerList.CanvasSize = UDim2.new(0, 0, 0, offset)
        end

        updateContainerList()
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            updateContainerList(searchBox.Text)
        end)
    end
end

local function hideTeleportMenu()
    if _G.teleportMenuActive then
        local playerGui = game.Players.LocalPlayer.PlayerGui
        local screenGui = playerGui:FindFirstChild("TeleportMenuGui")
        if screenGui then
            screenGui:Destroy()
        end
        _G.teleportMenuActive = false
    end
end

_G.showTeleportMenu = showTeleportMenu
_G.hideTeleportMenu = hideTeleportMenu