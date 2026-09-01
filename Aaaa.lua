-- Audio Perception System - Executor Script (Enhanced GUI)
-- Client-side script for Roblox exploit/executor.
-- Uses custom sliders, modern UI, and efficient management.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("Audio Perception System: LocalPlayer not found. Script must run on client.")
    return
end

-- ==============================
-- 1. CREATE SOUND GROUPS
-- ==============================

local GameAudioGroup = Instance.new("SoundGroup")
GameAudioGroup.Name = "GameAudioGroup"
GameAudioGroup.Parent = SoundService

local MusicGroup = Instance.new("SoundGroup")
MusicGroup.Name = "MusicGroup"
MusicGroup.Parent = SoundService

local SFXGroup = Instance.new("SoundGroup")
SFXGroup.Name = "SFXGroup"
SFXGroup.Parent = SoundService

local VoiceMaskGroup = Instance.new("SoundGroup")
VoiceMaskGroup.Name = "VoiceMaskGroup"
VoiceMaskGroup.Parent = SoundService

local perPlayerGroups = {}       -- userId -> SoundGroup
local perPlayerBaseVolumes = {}  -- userId -> number (0-1)

-- ==============================
-- 2. SOUND CLASSIFICATION AND RELOCATION
-- ==============================

local function classifySound(sound)
    local name = sound.Name:lower()
    local parentName = sound.Parent and sound.Parent.Name:lower() or ""
    local combined = name .. " " .. parentName
    if combined:find("music") or combined:find("bgm") or combined:find("ambient") then
        return MusicGroup
    elseif combined:find("sfx") or combined:find("sound") or combined:find("ui") or combined:find("effect") then
        return SFXGroup
    else
        return GameAudioGroup
    end
end

local function moveSoundsToGroups()
    local function scan(instance)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("Sound") then
                child.SoundGroup = classifySound(child)
            end
            scan(child)
        end
    end
    scan(workspace)
    scan(game:GetService("ReplicatedStorage"))
    scan(game:GetService("Lighting"))
    scan(game:GetService("StarterGui"))
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            scan(player.Character)
        end
    end
end

moveSoundsToGroups()

spawn(function()
    while true do
        moveSoundsToGroups()
        wait(5)
    end
end)

-- ==============================
-- 3. CUSTOM SLIDER CLASS
-- ==============================

local Slider = {}
Slider.__index = Slider

function Slider.new(parent, label, min, max, default, callback)
    local self = setmetatable({}, Slider)
    self.Min = min
    self.Max = max
    self.Value = default
    self.Callback = callback

    -- Container
    self.Container = Instance.new("Frame")
    self.Container.Size = UDim2.new(1, 0, 0, 30)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = parent

    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Size = UDim2.new(0, 80, 1, 0)
    self.Label.BackgroundTransparency = 1
    self.Label.Text = label
    self.Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.Label.Font = Enum.Font.SourceSans
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Container

    -- Slider Background
    self.Background = Instance.new("Frame")
    self.Background.Size = UDim2.new(1, -140, 0, 10)
    self.Background.Position = UDim2.new(0, 80, 0.5, -5)
    self.Background.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    self.Background.BorderSizePixel = 0
    self.Background.Parent = self.Container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 5)
    bgCorner.Parent = self.Background

    -- Fill
    self.Fill = Instance.new("Frame")
    self.Fill.Size = UDim2.new(0, 0, 1, 0)
    self.Fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    self.Fill.BorderSizePixel = 0
    self.Fill.Parent = self.Background

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 5)
    fillCorner.Parent = self.Fill

    -- Knob
    self.Knob = Instance.new("TextButton")
    self.Knob.Size = UDim2.new(0, 18, 0, 18)
    self.Knob.Position = UDim2.new(0, -9, 0.5, -9)
    self.Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.Knob.BorderSizePixel = 0
    self.Knob.Text = ""
    self.Knob.AutoButtonColor = false
    self.Knob.Parent = self.Background

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = self.Knob

    -- Value label
    self.ValueLabel = Instance.new("TextLabel")
    self.ValueLabel.Size = UDim2.new(0, 50, 1, 0)
    self.ValueLabel.Position = UDim2.new(1, -50, 0, 0)
    self.ValueLabel.BackgroundTransparency = 1
    self.ValueLabel.Text = string.format("%.2f", default)
    self.ValueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.ValueLabel.Font = Enum.Font.SourceSans
    self.ValueLabel.TextSize = 14
    self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.ValueLabel.Parent = self.Container

    -- Update visual
    self:UpdateVisual()

    -- Dragging logic
    local dragging = false
    local function updateFromMouse(input)
        local relativeX = input.Position.X - self.Background.AbsolutePosition.X
        local percent = math.clamp(relativeX / self.Background.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * percent
        self:SetValue(value)
    end

    self.Knob.MouseButton1Down:Connect(function()
        dragging = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    -- Also allow click on background to set value
    self.Background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateFromMouse(input)
            dragging = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end)

    return self
end

function Slider:SetValue(value)
    self.Value = math.clamp(value, self.Min, self.Max)
    self.ValueLabel.Text = string.format("%.2f", self.Value)
    self:UpdateVisual()
    if self.Callback then
        self.Callback(self.Value)
    end
end

function Slider:UpdateVisual()
    local percent = (self.Value - self.Min) / (self.Max - self.Min)
    self.Fill.Size = UDim2.new(percent, 0, 1, 0)
    self.Knob.Position = UDim2.new(percent, -9, 0.5, -9)
end

-- ==============================
-- 4. GUI CONSTRUCTION
-- ==============================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AudioPerceptionGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 480)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 80, 80)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Audio Perception System"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close button (optional)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0.5, -15)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 16
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 15)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Content area with scrolling
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, 0, 1, -40)
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
ContentFrame.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentFrame

-- Helper to create section headers
local function AddSectionHeader(text)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 24)
    header.Position = UDim2.new(0, 10, 0, 0)
    header.BackgroundTransparency = 1
    header.Text = text
    header.TextColor3 = Color3.fromRGB(0, 170, 255)
    header.Font = Enum.Font.SourceSansBold
    header.TextSize = 14
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = #ContentLayout:GetChildren() + 1
    header.Parent = ContentFrame
    return header
end

-- Helper to create a spacing element
local function AddSpacer(height)
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, height)
    spacer.BackgroundTransparency = 1
    spacer.LayoutOrder = #ContentLayout:GetChildren() + 1
    spacer.Parent = ContentFrame
    return spacer
end

-- ==============================
-- 5. GLOBAL AUDIO SLIDERS
-- ==============================

AddSectionHeader("Global Audio")

local vcSlider = Slider.new(ContentFrame, "VC Volume", 0, 1, 0.5, function(val)
    VoiceMaskGroup.Volume = val
end)
vcSlider.Container.LayoutOrder = #ContentLayout:GetChildren()

local gameSlider = Slider.new(ContentFrame, "Game Volume", 0, 1, 0.5, function(val)
    GameAudioGroup.Volume = val
end)
gameSlider.Container.LayoutOrder = #ContentLayout:GetChildren()

local musicSlider = Slider.new(ContentFrame, "Music Volume", 0, 1, 0.5, function(val)
    MusicGroup.Volume = val
end)
musicSlider.Container.LayoutOrder = #ContentLayout:GetChildren()

local sfxSlider = Slider.new(ContentFrame, "SFX Volume", 0, 1, 0.5, function(val)
    SFXGroup.Volume = val
end)
sfxSlider.Container.LayoutOrder = #ContentLayout:GetChildren()

AddSpacer(10)

-- ==============================
-- 6. DISTANCE ENGINE SETTINGS
-- ==============================

AddSectionHeader("Distance Engine")

local distanceEnabled = false
local maxDistance = 50

-- Toggle for distance
local distanceToggleContainer = Instance.new("Frame")
distanceToggleContainer.Size = UDim2.new(1, -20, 0, 30)
distanceToggleContainer.Position = UDim2.new(0, 10, 0, 0)
distanceToggleContainer.BackgroundTransparency = 1
distanceToggleContainer.LayoutOrder = #ContentLayout:GetChildren()
distanceToggleContainer.Parent = ContentFrame

local distanceToggleLabel = Instance.new("TextLabel")
distanceToggleLabel.Size = UDim2.new(0, 80, 1, 0)
distanceToggleLabel.BackgroundTransparency = 1
distanceToggleLabel.Text = "Enabled"
distanceToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
distanceToggleLabel.Font = Enum.Font.SourceSans
distanceToggleLabel.TextSize = 14
distanceToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
distanceToggleLabel.Parent = distanceToggleContainer

local distanceToggleButton = Instance.new("TextButton")
distanceToggleButton.Size = UDim2.new(0, 50, 0, 24)
distanceToggleButton.Position = UDim2.new(1, -50, 0.5, -12)
distanceToggleButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
distanceToggleButton.BorderSizePixel = 0
distanceToggleButton.Text = "OFF"
distanceToggleButton.TextColor3 = Color3.new(1, 1, 1)
distanceToggleButton.Font = Enum.Font.SourceSansBold
distanceToggleButton.TextSize = 14
distanceToggleButton.Parent = distanceToggleContainer

local distanceToggleCorner = Instance.new("UICorner")
distanceToggleCorner.CornerRadius = UDim.new(0, 6)
distanceToggleCorner.Parent = distanceToggleButton

distanceToggleButton.MouseButton1Click:Connect(function()
    distanceEnabled = not distanceEnabled
    distanceToggleButton.Text = distanceEnabled and "ON" or "OFF"
    distanceToggleButton.BackgroundColor3 = distanceEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 50, 50)
end)

-- Max Distance slider
local maxDistSlider = Slider.new(ContentFrame, "Max Distance", 10, 200, 50, function(val)
    maxDistance = val
end)
maxDistSlider.Container.LayoutOrder = #ContentLayout:GetChildren()

AddSpacer(10)

-- ==============================
-- 7. MASTER OVERRIDE & SETTINGS
-- ==============================

AddSectionHeader("Master & Safety")

local masterFixButton = Instance.new("TextButton")
masterFixButton.Size = UDim2.new(1, -20, 0, 30)
masterFixButton.Position = UDim2.new(0, 10, 0, 0)
masterFixButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
masterFixButton.BorderSizePixel = 0
masterFixButton.Text = "Fix Master Volume to 1"
masterFixButton.TextColor3 = Color3.new(1, 1, 1)
masterFixButton.Font = Enum.Font.SourceSansBold
masterFixButton.TextSize = 14
masterFixButton.LayoutOrder = #ContentLayout:GetChildren()
masterFixButton.Parent = ContentFrame

local masterFixCorner = Instance.new("UICorner")
masterFixCorner.CornerRadius = UDim.new(0, 6)
masterFixCorner.Parent = masterFixButton

masterFixButton.MouseButton1Click:Connect(function()
    SoundService.MasterVolume = 1
    -- Brief visual feedback
    masterFixButton.Text = "Fixed!"
    wait(0.5)
    masterFixButton.Text = "Fix Master Volume to 1"
end)

-- Limiter toggle
local limiterEnabled = false
local compressor = nil

local limiterToggleContainer = Instance.new("Frame")
limiterToggleContainer.Size = UDim2.new(1, -20, 0, 30)
limiterToggleContainer.Position = UDim2.new(0, 10, 0, 0)
limiterToggleContainer.BackgroundTransparency = 1
limiterToggleContainer.LayoutOrder = #ContentLayout:GetChildren()
limiterToggleContainer.Parent = ContentFrame

local limiterLabel = Instance.new("TextLabel")
limiterLabel.Size = UDim2.new(0, 80, 1, 0)
limiterLabel.BackgroundTransparency = 1
limiterLabel.Text = "Limiter"
limiterLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
limiterLabel.Font = Enum.Font.SourceSans
limiterLabel.TextSize = 14
limiterLabel.TextXAlignment = Enum.TextXAlignment.Left
limiterLabel.Parent = limiterToggleContainer

local limiterButton = Instance.new("TextButton")
limiterButton.Size = UDim2.new(0, 50, 0, 24)
limiterButton.Position = UDim2.new(1, -50, 0.5, -12)
limiterButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
limiterButton.BorderSizePixel = 0
limiterButton.Text = "OFF"
limiterButton.TextColor3 = Color3.new(1, 1, 1)
limiterButton.Font = Enum.Font.SourceSansBold
limiterButton.TextSize = 14
limiterButton.Parent = limiterToggleContainer

local limiterCorner = Instance.new("UICorner")
limiterCorner.CornerRadius = UDim.new(0, 6)
limiterCorner.Parent = limiterButton

limiterButton.MouseButton1Click:Connect(function()
    limiterEnabled = not limiterEnabled
    limiterButton.Text = limiterEnabled and "ON" or "OFF"
    limiterButton.BackgroundColor3 = limiterEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 50, 50)
    if limiterEnabled then
        if not compressor then
            compressor = Instance.new("CompressorSoundEffect")
            compressor.Name = "LimiterCompressor"
            compressor.Threshold = -6
            compressor.Ratio = 10
            compressor.Attack = 0.01
            compressor.Release = 0.1
            compressor.Parent = SoundService
        end
    else
        if compressor then
            compressor:Destroy()
            compressor = nil
        end
    end
end)

-- Safety mode toggle
local safetyMode = true

local safetyToggleContainer = Instance.new("Frame")
safetyToggleContainer.Size = UDim2.new(1, -20, 0, 30)
safetyToggleContainer.Position = UDim2.new(0, 10, 0, 0)
safetyToggleContainer.BackgroundTransparency = 1
safetyToggleContainer.LayoutOrder = #ContentLayout:GetChildren()
safetyToggleContainer.Parent = ContentFrame

local safetyLabel = Instance.new("TextLabel")
safetyLabel.Size = UDim2.new(0, 80, 1, 0)
safetyLabel.BackgroundTransparency = 1
safetyLabel.Text = "Safety Mode"
safetyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
safetyLabel.Font = Enum.Font.SourceSans
safetyLabel.TextSize = 14
safetyLabel.TextXAlignment = Enum.TextXAlignment.Left
safetyLabel.Parent = safetyToggleContainer

local safetyButton = Instance.new("TextButton")
safetyButton.Size = UDim2.new(0, 50, 0, 24)
safetyButton.Position = UDim2.new(1, -50, 0.5, -12)
safetyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
safetyButton.BorderSizePixel = 0
safetyButton.Text = "ON"
safetyButton.TextColor3 = Color3.new(1, 1, 1)
safetyButton.Font = Enum.Font.SourceSansBold
safetyButton.TextSize = 14
safetyButton.Parent = safetyToggleContainer

local safetyCorner = Instance.new("UICorner")
safetyCorner.CornerRadius = UDim.new(0, 6)
safetyCorner.Parent = safetyButton

safetyButton.MouseButton1Click:Connect(function()
    safetyMode = not safetyMode
    safetyButton.Text = safetyMode and "ON" or "OFF"
    safetyButton.BackgroundColor3 = safetyMode and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 50, 50)
end)

AddSpacer(10)

-- ==============================
-- 8. PER-PLAYER MIXER
-- ==============================

AddSectionHeader("Per-Player Volume")

local playersScrolling = Instance.new("ScrollingFrame")
playersScrolling.Size = UDim2.new(1, -20, 0, 150)
playersScrolling.Position = UDim2.new(0, 10, 0, 0)
playersScrolling.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
playersScrolling.BorderSizePixel = 0
playersScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScrolling.ScrollBarThickness = 4
playersScrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
playersScrolling.LayoutOrder = #ContentLayout:GetChildren()
playersScrolling.Parent = ContentFrame

local playersCorner = Instance.new("UICorner")
playersCorner.CornerRadius = UDim.new(0, 6)
playersCorner.Parent = playersScrolling

local playersLayout = Instance.new("UIListLayout")
playersLayout.Padding = UDim.new(0, 5)
playersLayout.Parent = playersScrolling

-- Function to create a per-player slider inside the scrolling frame
local function createPerPlayerSlider(player)
    local userId = player.UserId
    if perPlayerGroups[userId] then return end

    -- SoundGroup for this player
    local group = Instance.new("SoundGroup")
    group.Name = "VoiceMask_Player_" .. userId
    group.Parent = SoundService
    perPlayerGroups[userId] = group
    perPlayerBaseVolumes[userId] = 0.5

    -- Container row
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = playersScrolling

    -- Player name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 60, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    -- Slider for this player (using our custom Slider class, but we need to adapt it to fit in row)
    -- We'll create a simplified slider: background frame, fill, knob, but with fixed width.
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -70, 0, 10)
    bg.Position = UDim2.new(0, 60, 0.5, -5)
    bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bg.BorderSizePixel = 0
    bg.Parent = row

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 5)
    bgCorner.Parent = bg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 5)
    fillCorner.Parent = fill

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0.5, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Parent = bg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 30, 1, 0)
    valueLabel.Position = UDim2.new(1, -30, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "0.50"
    valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    valueLabel.Font = Enum.Font.SourceSans
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    -- Dragging logic
    local dragging = false
    local function updateFromMouse(input)
        local relativeX = input.Position.X - bg.AbsolutePosition.X
        local percent = math.clamp(relativeX / bg.AbsoluteSize.X, 0, 1)
        perPlayerBaseVolumes[userId] = percent
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -8, 0.5, -8)
        valueLabel.Text = string.format("%.2f", percent)
        updatePlayerVolume(player)
    end

    knob.MouseButton1Down:Connect(function()
        dragging = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end)
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateFromMouse(input)
            dragging = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    -- Store references for later updates
    local sliderData = {
        player = player,
        fill = fill,
        knob = knob,
        valueLabel = valueLabel,
        bg = bg,
    }
    perPlayerGroups[userId].SliderData = sliderData

    playersScrolling.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 10)
end

local function removePerPlayerSlider(player)
    local userId = player.UserId
    if perPlayerGroups[userId] then
        perPlayerGroups[userId]:Destroy()
        perPlayerGroups[userId] = nil
        perPlayerBaseVolumes[userId] = nil
    end
    -- Find and destroy the corresponding row
    for _, child in ipairs(playersScrolling:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("TextLabel") and child.TextLabel.Text == player.Name then
            child:Destroy()
            break
        end
    end
    playersScrolling.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 10)
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createPerPlayerSlider(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removePerPlayerSlider(player)
end)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createPerPlayerSlider(player)
    end
end

-- ==============================
-- 9. DISTANCE ENGINE UPDATE LOOP
-- ==============================

local function updatePlayerVolume(player)
    local userId = player.UserId
    local group = perPlayerGroups[userId]
    if not group then return end

    local base = perPlayerBaseVolumes[userId] or 0.5
    local finalVolume = base

    if distanceEnabled and player.Character and LocalPlayer.Character then
        local root1 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local root2 = player.Character:FindFirstChild("HumanoidRootPart")
        if root1 and root2 then
            local dist = (root1.Position - root2.Position).Magnitude
            local factor = math.clamp(1 - (dist / maxDistance), 0, 1)
            finalVolume = base * factor
        else
            finalVolume = 0
        end
    end

    if safetyMode then
        finalVolume = math.clamp(finalVolume, 0, 1)
    end

    group.Volume = finalVolume
end

RunService.RenderStepped:Connect(function()
    -- Master volume override
    SoundService.MasterVolume = 1

    -- Update per-player volumes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updatePlayerVolume(player)
        end
    end
end)

-- ==============================
-- 10. INITIAL VOLUMES
-- ==============================

VoiceMaskGroup.Volume = 0.5
GameAudioGroup.Volume = 0.5
MusicGroup.Volume = 0.5
SFXGroup.Volume = 0.5

