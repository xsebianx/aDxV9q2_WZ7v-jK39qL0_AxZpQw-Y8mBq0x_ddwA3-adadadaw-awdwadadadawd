local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local crosshairEnabled = false  -- Variable para activar/desactivar el crosshair

-- Crear Crosshair
local crosshair = Drawing.new("Line")
crosshair.Thickness = 2
crosshair.Color = Color3.fromRGB(255, 255, 255)

local crosshairVertical = Drawing.new("Line")
crosshairVertical.Thickness = 2
crosshairVertical.Color = Color3.fromRGB(255, 255, 255)

-- Función para activar el crosshair
local function enableCrosshair()
    crosshairEnabled = true
end

-- Función para desactivar el crosshair
local function disableCrosshair()
    crosshairEnabled = false
    crosshair.Visible = false
    crosshairVertical.Visible = false
end

-- Actualizar la posición del Crosshair
local function updateCrosshair()
    if crosshairEnabled then
        local centerX = workspace.CurrentCamera.ViewportSize.X / 2
        local centerY = workspace.CurrentCamera.ViewportSize.Y / 2
        
        crosshair.From = Vector2.new(centerX - 10, centerY)
        crosshair.To = Vector2.new(centerX + 10, centerY)
        
        crosshairVertical.From = Vector2.new(centerX, centerY - 10)
        crosshairVertical.To = Vector2.new(centerX, centerY + 10)
        
        crosshair.Visible = true
        crosshairVertical.Visible = true
    end
end

-- Conectar la actualización a RenderStepped
RunService.RenderStepped:Connect(updateCrosshair)

-- Exponer las funciones globalmente para que puedan ser llamadas desde fuera
_G.enableCrosshair = enableCrosshair
_G.disableCrosshair = disableCrosshair