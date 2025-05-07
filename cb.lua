local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local tweenService   = game:GetService("TweenService")
local players        = game:GetService("Players")
local localPlayer    = players.LocalPlayer
local mouse          = localPlayer:GetMouse()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
	Title = "kiwi.vip",
	Footer = "version: 1.1.2",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
    legit = Window:AddTab("Legitbot"),
	rage = Window:AddTab("Ragebot"),
    visuals = Window:AddTab("Visuals"),
    misc = Window:AddTab("Misc", "user"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local LeftGroupBox = Tabs.legit:AddLeftGroupbox("Aimbot")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == toggleKey then
        trigger = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == toggleKey then
        trigger = false
    end
end)

RunService.RenderStepped:Connect(function()
    if trigger then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        local target = mouse.Target and mouse.Target.Parent
        if target and target:FindFirstChildOfClass("Humanoid") then
            local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
            local targetPlayer = Players:GetPlayerFromCharacter(target)
            local targetPart = mouse.Target

            local isTargetValid = false
            if table.find(SelectedParts, "Head") and targetPart.Name == "Head" then
                isTargetValid = true
            elseif table.find(SelectedParts, "UpperTorso") and targetPart.Name == "UpperTorso" then
                isTargetValid = true
            elseif table.find(SelectedParts, "LowerTorso") and targetPart.Name == "LowerTorso" then
                isTargetValid = true
            elseif table.find(SelectedParts, "Arms") and (targetPart.Name == "LeftUpperArm" or targetPart.Name == "RightUpperArm" or targetPart.Name == "LeftLowerArm" or targetPart.Name == "RightLowerArm") then
                isTargetValid = true
            elseif table.find(SelectedParts, "Legs") and (targetPart.Name == "LeftUpperLeg" or targetPart.Name == "RightUpperLeg" or targetPart.Name == "LeftLowerLeg" or targetPart.Name == "RightLowerLeg") then
                isTargetValid = true
            end

            if isTargetValid and targetHumanoid.Health > 0 and targetPlayer and targetPlayer.Team ~= LocalPlayer.Team then
                mouse1press()
                wait(0.05)
                mouse1release()
                wait(TriggerDelay)
            end
        end
    end
end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera = workspace.CurrentCamera
local Weapons = ReplicatedStorage:FindFirstChild("Weapons")
local Debris = workspace:FindFirstChild("Debris")
local RayIgnore = workspace:FindFirstChild("Ray_Ignore")
local LocalPlayer = Players.LocalPlayer

local Ragebot = false
local Smooth = 1
local Teamcheck = false
local triggerbot = false
local fireRate = 0.0
local AutoWall = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Radius = 100
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Filled = false

local ViewLine = Drawing.new("Line")
ViewLine.Color = Color3.fromRGB(0, 255, 0)
ViewLine.Thickness = 1
ViewLine.Transparency = 1
ViewLine.Visible = false

local SelectedBones = { "Head", "Torso", "Arms", "Legs" }

local BodyPartGroups = {
    Head = { "Head" },
    Torso = { "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart" },
    Arms = { "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" },
    Legs = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" },
}

local function GetRaycastParams()
	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	if AutoWall then
		RaycastParams.IgnoreWater = true
	end
	return RaycastParams
end

local function IsVisible(target)
	if AutoWall then
		local origin = Camera.CFrame.Position
		local direction = (target.Position - origin)
		local result = workspace:Raycast(origin, direction, GetRaycastParams())
		if result then
			local hitInstance = result.Instance
			if hitInstance and hitInstance:IsDescendantOf(workspace) and hitInstance.CanCollide then
				return true
			end
		end
		return true
	else
		local origin = Camera.CFrame.Position
		local direction = (target.Position - origin)
		local result = workspace:Raycast(origin, direction, GetRaycastParams())
		return result == nil or (result.Instance and result.Instance:IsDescendantOf(target.Parent))
	end
end

local function GetBestTargetPart(character)
	for _, boneGroup in ipairs(SelectedBones) do
		local parts = BodyPartGroups[boneGroup]
		for _, partName in ipairs(parts) do
			local part = character:FindFirstChild(partName)
			if part and IsVisible(part) then
				return part
			end
		end
	end
	return nil
end

local function IsOnSameTeam(player)
	return player.Team == LocalPlayer.Team
end

local function GetClosestTarget()
	local closestTarget = nil
	local shortestDistance = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local bestPart = GetBestTargetPart(player.Character)
			if ((not Teamcheck) or (Teamcheck and not IsOnSameTeam(player))) and bestPart and humanoid and humanoid.Health > 0 then
				local screenPoint, onScreen = Camera:WorldToViewportPoint(bestPart.Position)
				if onScreen then
					local distanceToCrosshair = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
					if distanceToCrosshair < shortestDistance then
						closestTarget = bestPart
						shortestDistance = distanceToCrosshair
					end
				end
			end
		end
	end

	return closestTarget
end

RunService.RenderStepped:Connect(function()
	if Ragebot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local target = GetClosestTarget()
		if target then
			local screenPoint = Camera:WorldToViewportPoint(target.Position)
			local deltaX = (screenPoint.X - (Camera.ViewportSize.X / 2)) / Smooth
			local deltaY = (screenPoint.Y - (Camera.ViewportSize.Y / 2)) / Smooth

			mousemoverel(deltaX, deltaY)

			ViewLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
			ViewLine.To = Vector2.new(screenPoint.X, screenPoint.Y)
			ViewLine.Visible = true

			if triggerbot and not isFiring then
				isFiring = true
				mouse1press()
				task.wait(fireRate)
				mouse1release()
				isFiring = false
			end
		else
			ViewLine.Visible = false
		end
	else
		ViewLine.Visible = false
	end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

local AimbotEnabled = false
local VisibilityCheck = false
local AimSmoothness = 10
local FOVRadius = 100
local SmoothEnabled = true
local BoneSwitchTime = 1
local TargetBone = "Head"
local TeamCheckEnabled = false
local BoneSwitchEnabled = false
local type = "Mouse"
local fovEnabled = false
local SelectedHitboxes = {"Head", "UpperTorso", "LowerTorso"}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Radius = FOVRadius

local ViewLine = Drawing.new("Line")
ViewLine.Thickness = 1
ViewLine.Transparency = 1
ViewLine.Color = Color3.new(1, 1, 1)
ViewLine.Visible = false

local lineEnabled = false
local triggerbot = false
local fireRate = 0.1

local function GetRaycastParams()
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    return RaycastParams
end

local function toggleFOV(state)
    FOVCircle.Visible = state
end

local function toggleLine(state)
    lineEnabled = state
end

local function UpdateFOV()
    local ViewportSize = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)
    FOVCircle.Radius = FOVRadius
    FOVCircle.Visible = fovEnabled
end

local function IsVisible(target)
    if not VisibilityCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin).Unit * (target.Position - origin).Magnitude
    local result = workspace:Raycast(origin, direction, GetRaycastParams())
    return result == nil or (result.Instance and result.Instance:IsDescendantOf(target.Parent))
end

local function GetBoneParts(character)
    local parts = {}
    for _, hitbox in ipairs(SelectedHitboxes) do
        if hitbox == "Head" then
            local head = character:FindFirstChild("Head")
            if head then table.insert(parts, head) end
        elseif hitbox == "UpperTorso" then
            local upper = character:FindFirstChild("UpperTorso")
            if upper then table.insert(parts, upper) end
        elseif hitbox == "LowerTorso" then
            local lower = character:FindFirstChild("LowerTorso")
            if lower then table.insert(parts, lower) end
        elseif hitbox == "Arms" then
            for _, name in ipairs({"LeftArm", "RightArm", "LeftHand", "RightHand", "LeftUpperArm", "RightUpperArm"}) do
                local part = character:FindFirstChild(name)
                if part then table.insert(parts, part) end
            end
        elseif hitbox == "Legs" then
            for _, name in ipairs({"LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftUpperLeg", "RightUpperLeg"}) do
                local part = character:FindFirstChild(name)
                if part then table.insert(parts, part) end
            end
        end
    end
    return parts
end

local function IsOnSameTeam(player)
    return player.Team == LocalPlayer.Team
end

local function GetClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local ViewportSize = Camera.ViewportSize
    local CrosshairPos = Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if not TeamCheckEnabled or not IsOnSameTeam(player) then
                    local parts = GetBoneParts(player.Character)
                    for _, part in ipairs(parts) do
                        if part and IsVisible(part) then
                            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
                                local distanceToCrosshair = (targetPos - CrosshairPos).Magnitude
                                if distanceToCrosshair < shortestDistance and distanceToCrosshair < FOVRadius then
                                    closestTarget = part
                                    shortestDistance = distanceToCrosshair
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

task.spawn(function()
    while true do
        if BoneSwitchEnabled then
            if TargetBone == "Head" then
                TargetBone = "UpperTorso"
            elseif TargetBone == "UpperTorso" then
                TargetBone = "LowerTorso"
            elseif TargetBone == "LowerTorso" then
                TargetBone = "Arms"
            elseif TargetBone == "Arms" then
                TargetBone = "Legs"
            else
                TargetBone = "Head"
            end
        end
        task.wait(BoneSwitchTime)
    end
end)

RunService.RenderStepped:Connect(function()
    if AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestTarget()
        if target then
            local targetPos = Camera:WorldToScreenPoint(target.Position)

            if type == "Mouse" then
                local moveX = (targetPos.X - Mouse.X) / AimSmoothness
                local moveY = (targetPos.Y - Mouse.Y) / AimSmoothness
                mousemoverel(moveX, moveY)

            elseif type == "Camera" and Camera.CameraType == Enum.CameraType.Scriptable then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                local smoothFactor = SmoothEnabled and math.clamp(AimSmoothness / 100, 0.01, 1) or 1
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
            end

            if lineEnabled then
                ViewLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                ViewLine.To = Vector2.new(targetPos.X, targetPos.Y)
                ViewLine.Visible = true
            end

            if triggerbot then
                mouse1press()
                task.wait(fireRate)
                mouse1release()
            end
        else
            ViewLine.Visible = false
        end
    else
        ViewLine.Visible = false
    end
end)

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Aim Assist",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        AimbotEnabled = state
	end,
})

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Team Check",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        TeamCheckEnabled = state
	end,
})

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Vis Check",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        VisibilityCheck = state
	end,
})

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Bone Switch",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        BoneSwitchEnabled = state
	end,
})

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Fov Circle",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        fovEnabled = state
	end,
})
:AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 1, 1),
	Title = "Fov Color", 
	Transparency = 0, 

	Callback = function(color)
        FOVCircle.Color = color
	end,
})

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Target Line",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        lineEnabled = state
	end,
})
:AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 0, 0),
	Title = "Target Line Color", 
	Transparency = 0, 

	Callback = function(color)
       ViewLine.Color = color
	end,
})

LeftGroupBox:AddDropdown("MySearchableDropdown", {
	Values = { "Mouse", "Camera"},
	Default = 1,
	Searchable = true,
	Multi = false,
	Text = "",
	Callback = function(Value)
        type = value
	end,
})

LeftGroupBox:AddDropdown("MyMultiDropdown", {
    Values = {"Head", "UpperTorso", "LowerTorso", "Arms", "Legs"},
    Default = 1,
    Multi = false, 
    Text = "Hitboxes",
    Tooltip = "", 
    Callback = function(Value)
        SelectedHitboxes = Value
    end,
})

LeftGroupBox:AddSlider("MySlider", {
	Text = "Fov Radius",
	Default = 100,
	Min = 0,
	Max = 300,
	Rounding = 1,
	Compact = false,
	Tooltip = "",
	DisabledTooltip = "",
	Disabled = false,
	Visible = true,
    Callback = function(Value)
        FOVRadius = Value
        UpdateFOV()
    end,
})

LeftGroupBox:AddSlider("SmoothnessSlider", {
    Text = "Smoothness",
    Min = 1,
    Max = 100,
    Default = 5,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        AimSmoothness = Value
    end,
})

local RightLegit = Tabs.legit:AddRightGroupbox("Triggerbot")


RightLegit:AddToggle("MyToggle", {
	Text = "Triggerbot",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        trigger = state
	end,
})
:AddKeyPicker("KeyPicker", {

	Default = "MB2", 
	SyncToggleState = false,

	Mode = "Toggle", 

	Text = "Triggerbot", 
	NoUI = false, 

	Callback = function(key)
        toggleKey = key
	end,
})
RightLegit:AddDropdown("MyMultiDropdown", {
    Values = {"Head", "UpperTorso", "LowerTorso", "Arms", "Legs"},
    Default = 1,
    Multi = true, 
    Text = "Trigger Bones",
    Tooltip = "", 
    Callback = function(Value)
        SelectedParts = Value
    end,
})

RightLegit:AddSlider("MySlider", {
    Text = "Trigger Delay",
    Default = 0,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Tooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        TriggerDelay = Value
    end,
})

local RageLeft = Tabs.rage:AddLeftGroupbox("Ragebot")

RageLeft:AddToggle("MyToggle", {
	Text = "Enable",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = true, 
	Callback = function(state)
        Ragebot = state
	end,
})


RageLeft:AddDropdown("MyMultiDropdown", {
    Values = {"Head", "UpperTorso", "LowerTorso", "Arms", "Legs"},
    Default = 1,
    Multi = true, 
    Text = "Bones",
    Tooltip = "", 
    Callback = function(Value)
        SelectedBones = Value
    end,
})

RageLeft:AddToggle("MyToggle", {
	Text = "Autowall",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = true, 
	Callback = function(state)
        AutoWall = state
	end,
})

RageLeft:AddToggle("MyToggle", {
	Text = "Team Check",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        Teamcheck = state
	end,
})

local RageRight = Tabs.rage:AddRightGroupbox("Anti Aim")

local YawType = "Static"
local YawEnabled = false
local YawOffset = 0
local currentYaw = 0
local lastJitter = 0
local jitterSwitch = false
local fakeLagDelay = 0.1
local desyncDelay = 0.2
local fakeLagEnabled = false
local desyncEnabled = false
local lastLadderCheck = 0
local ladders = workspace:GetDescendants()
local nearLadder = false

RageRight:AddToggle("MyToggle", {
	Text = "Yaw",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = true, 
	Callback = function(state)
        YawEnabled = state
	end,
})

RageRight:AddDropdown("MyMultiDropdown", {
    Values = {"Static", "Jitter", "Spin", "UnHit"},
    Default = 1,
    Multi = false, 
    Text = "Yaw Type",
    Tooltip = "", 
    Callback = function(Value)
        YawType = Value
    end,
})

RageRight:AddSlider("MySlider", {
    Text = "Yaw Ammount",
    Default = 0,
    Min = 0,
    Max = 180,
    Rounding = 1,
    Compact = false,
    Tooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        YawOffset = Value
    end,
})

RageRight:AddToggle("MyToggle", {
	Text = "Fake Lag",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = true, 
	Callback = function(state)
        fakeLagEnabled = state
	end,
})

RageRight:AddSlider("MySlider", {
    Text = "Fake Lag Delay",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 0.1,
    Compact = false,
    Tooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        fakeLagDelay = Value
    end,
})

RageRight:AddToggle("MyToggle", {
	Text = "Desync",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = true, 
	Callback = function(state)
        desyncEnabled = state
	end,
})

RageRight:AddSlider("MySlider", {
    Text = "Desync Delay",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 0.1,
    Compact = false,
    Tooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        desyncDelay = Value
    end,
})

local function IsOnSameTeam(player)
    return player.Team == LocalPlayer.Team
end

RunService.RenderStepped:Connect(function(deltaTime)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    if char.Humanoid.Health <= 0 then return end

    if not YawEnabled then
        char.Humanoid.AutoRotate = true
        return
    end

    local rootPart = char.HumanoidRootPart
    local basePos = rootPart.Position

    local closestEnemy, shortestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and not IsOnSameTeam(p) then
            local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local eHum = p.Character:FindFirstChild("Humanoid")
            if eRoot and eHum and eHum.Health > 0 then
                local dist = (eRoot.Position - basePos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestEnemy = eRoot
                end
            end
        end
    end

    if closestEnemy then
        if fakeLagEnabled and tick() - lastFakeLag < fakeLagDelay then
            return
        end
        lastFakeLag = tick()

        if desyncEnabled and tick() - lastDesync < desyncDelay then
            return
        end
        lastDesync = tick()

        char.Humanoid.AutoRotate = false
        local dir = (closestEnemy.Position - basePos).Unit
        local targetYaw = math.atan2(dir.X, dir.Z)

        if YawType == "Static" then
            targetYaw = targetYaw + math.rad(YawOffset)
            rootPart.CFrame = CFrame.new(basePos) * CFrame.Angles(0, targetYaw, 0)

        elseif YawType == "Jitter" then
            if tick() - lastJitter > 0.1 then
                jitterSwitch = not jitterSwitch
                lastJitter = tick()
            end
            local jitterAngle = jitterSwitch and math.rad(90) or math.rad(-90)
            targetYaw = targetYaw + jitterAngle + math.rad(YawOffset)
            rootPart.CFrame = CFrame.new(basePos) * CFrame.Angles(0, targetYaw, 0)

        elseif YawType == "Spin" then
            currentYaw = (currentYaw or 0) + math.rad(YawOffset) * deltaTime * 60
            rootPart.CFrame = CFrame.new(basePos) * CFrame.Angles(0, currentYaw, 0)

        elseif YawType == "UnHit" then
            rootPart.CFrame = CFrame.new(basePos) * CFrame.Angles(math.rad(180), targetYaw, 0)
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") and part ~= rootPart then
                    part.Velocity = Vector3.new(math.random(-50, 50), math.random(100, 200), math.random(-50, 50))
                end
            end
        end
    else
        char.Humanoid.AutoRotate = true
    end
end)

local turnDirection = 1
local pitchEnabled = false
local pitchLoop

RageRight:AddToggle("MyToggle", {
	Text = "Pitch",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = true, 
	Callback = function(state)
        pitchEnabled = state

        if pitchEnabled then
            if not pitchLoop then
                pitchLoop = task.spawn(function()
                    while pitchEnabled do
                        local args = {
                            [1] = turnDirection,
                            [2] = false
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ControlTurn"):FireServer(unpack(args))
                        task.wait()
                    end
                    pitchLoop = nil
                end)
            end
        else
            pitchEnabled = false
        end
	end,
})


RageRight:AddDropdown("MyMultiDropdown", {
    Values = {"Up", "Down"},
    Default = 1,
    Multi = false, 
    Text = "Pitch Type",
    Tooltip = "", 
    Callback = function(Value)
        turnDirection = (value == "Up") and 1 or -1
    end,
})

Library:OnUnload(function()
	print("Unloaded!")
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind 

local LeftMisc = Tabs.misc:AddLeftGroupbox("Gun Mods")
local RightMisc = Tabs.misc:AddRightGroupbox("Extra")

RightMisc:AddDropdown("MyMultiDropdown", {
    Values = {"Scope", "Smoke", "Flash", "Blood", "Bullet Holes"},
    Default = 1,
    Multi = true,
    Text = "Removals",
    Tooltip = "",
    Callback = function(selected)
        RemoveScope = false
        RemoveSmoke = false
        RemoveFlash = false
        RemoveBlood = false
        RemoveBulletsHoles = false

        for _, v in ipairs(selected) do
            if v == "Scope" then RemoveScope = true end
            if v == "Smoke" then RemoveSmoke = true end
            if v == "Flash" then RemoveFlash = true end
            if v == "Blood" then RemoveBlood = true end
            if v == "Bullet Holes" then RemoveBulletsHoles = true end
        end
    end,
})

RightMisc:AddToggle("MyToggle", {
    Text = "Bhop",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        Bhop = state
    end,
})

RightMisc:AddSlider("MySlider", {
    Text = "Bhop Speed",
    Default = 1,
    Min = 1,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        BhopSpeed = value
    end,
})

local NoSpreadEnabled = false
local NoRecoilEnabled = false
local NoSpread = 0

RightMisc:AddToggle("MyToggle", {
    Text = "Enable Spread",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        NoSpreadEnabled = state
    end,
})

RightMisc:AddSlider("MySlider", {
    Text = "Spread",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        if NoSpreadEnabled then
            NoSpread = value
            local weaponsFolder = game:GetService("ReplicatedStorage").Weapons
            if weaponsFolder then
                for _, Weapon in ipairs(weaponsFolder:GetChildren()) do
                    local Spread = Weapon:FindFirstChild("Spread")
                    if Spread then
                        Spread.Value = NoSpread / 10
                    end
                end
            end
        end
    end,
})

RightMisc:AddToggle("MyToggle", {
    Text = "Enable Recoil",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        NoRecoilEnabled = state
        Recoil = 0
    end,
})

RightMisc:AddSlider("MySlider", {
    Text = "Recoil",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        if NoRecoilEnabled then
            Recoil = value
            if Weapons then
                for _, Weapon in ipairs(Weapons:GetChildren()) do
                    local Spread = Weapon:FindFirstChild("Spread")
                    if Spread then
                        local RecoilInstance = Spread:FindFirstChild("Recoil")
                        if RecoilInstance and RecoilInstance:IsA("NumberValue") then
                            RecoilInstance.Value = value
                            for _, child in ipairs(RecoilInstance:GetChildren()) do
                                if child:IsA("NumberValue") then
                                    child.Value = value
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
})

local BulletsPerShotEnabled = false
local BulletsPerShotValue = 2

LeftMisc:AddToggle("MyToggle", {
    Text = "Enable Bullets Per Shot",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        BulletsPerShotEnabled = state
    end,
})

LeftMisc:AddSlider("MySlider", {
    Text = "Bullets Per Shot",
    Default = 2,
    Min = 1,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        if BulletsPerShotEnabled then
            BulletsPerShotValue = value
            for _, Weapon in ipairs(Weapons:GetChildren()) do
                local Bullets = Weapon:FindFirstChild("Bullets")
                if Bullets and Bullets:IsA("NumberValue") then
                    Bullets.Value = BulletsPerShotValue
                end
            end
        end
    end,
})

local originalValues = {
    RapidFire = {},
    InstantEquip = {},
    NoFireRate = {},
    NoReloadTime = {},
    InfiniteAmmo = {},
    ArmorPenetration = {},
    WallBang = {},
    InfiniteRange = {},
}

LeftMisc:AddToggle("MyToggle", {
    Text = "Rapid Fire",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local Auto = Weapon:FindFirstChild("Auto")
            if Auto and Auto:IsA("BoolValue") then
                if state then
                    if originalValues.RapidFire[Weapon] == nil then
                        originalValues.RapidFire[Weapon] = Auto.Value
                    end
                    Auto.Value = true
                else
                    if originalValues.RapidFire[Weapon] ~= nil then
                        Auto.Value = originalValues.RapidFire[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.RapidFire = {} end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "Instant Equip",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local Equip = Weapon:FindFirstChild("EquipTime")
            if Equip and Equip:IsA("NumberValue") then
                if state then
                    if originalValues.InstantEquip[Weapon] == nil then
                        originalValues.InstantEquip[Weapon] = Equip.Value
                    end
                    Equip.Value = 0.01
                else
                    if originalValues.InstantEquip[Weapon] ~= nil then
                        Equip.Value = originalValues.InstantEquip[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.InstantEquip = {} end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "No Fire Rate",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local fireRate = Weapon:FindFirstChild("FireRate")
            if fireRate and fireRate:IsA("NumberValue") then
                if state then
                    if originalValues.NoFireRate[Weapon] == nil then
                        originalValues.NoFireRate[Weapon] = fireRate.Value
                    end
                    fireRate.Value = 0
                else
                    if originalValues.NoFireRate[Weapon] ~= nil then
                        fireRate.Value = originalValues.NoFireRate[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.NoFireRate = {} end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "Infinite Ammo",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local ammo = Weapon:FindFirstChild("Ammo")
            local storedAmmo = Weapon:FindFirstChild("StoredAmmo")
            if ammo and storedAmmo and ammo:IsA("NumberValue") and storedAmmo:IsA("NumberValue") then
                if state then
                    if originalValues.InfiniteAmmo[Weapon] == nil then
                        originalValues.InfiniteAmmo[Weapon] = {
                            Ammo = ammo.Value,
                            StoredAmmo = storedAmmo.Value
                        }
                    end
                    ammo.Value = 9999999999
                    storedAmmo.Value = 9999999999
                else
                    local cached = originalValues.InfiniteAmmo[Weapon]
                    if cached then
                        ammo.Value = cached.Ammo
                        storedAmmo.Value = cached.StoredAmmo
                    end
                end
            end
        end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "No Reload Time",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local reloadTime = Weapon:FindFirstChild("ReloadTime")
            if reloadTime and reloadTime:IsA("NumberValue") then
                if state then
                    if originalValues.NoReloadTime[Weapon] == nil then
                        originalValues.NoReloadTime[Weapon] = reloadTime.Value
                    end
                    reloadTime.Value = 0.05
                else
                    if originalValues.NoReloadTime[Weapon] ~= nil then
                        reloadTime.Value = originalValues.NoReloadTime[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.NoReloadTime = {} end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "Armor Penetration",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local ArmorPen = Weapon:FindFirstChild("ArmorPenetration")
            if ArmorPen and ArmorPen:IsA("NumberValue") then
                if state then
                    if originalValues.ArmorPenetration[Weapon] == nil then
                        originalValues.ArmorPenetration[Weapon] = ArmorPen.Value
                    end
                    ArmorPen.Value = 999999
                else
                    if originalValues.ArmorPenetration[Weapon] ~= nil then
                        ArmorPen.Value = originalValues.ArmorPenetration[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.ArmorPenetration = {} end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "Infinite Range",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local Range = Weapon:FindFirstChild("Range")
            if Range then
                if state then
                    if originalValues.InfiniteRange[Weapon] == nil then
                        originalValues.InfiniteRange[Weapon] = Range.Value
                    end
                    Range.Value = 9999999999
                else
                    if originalValues.InfiniteRange[Weapon] ~= nil then
                        Range.Value = originalValues.InfiniteRange[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.InfiniteRange = {} end
    end,
})

LeftMisc:AddToggle("MyToggle", {
    Text = "Wall Bang",
    Tooltip = "",
    Default = false,
    Callback = function(state)
        for _, Weapon in ipairs(Weapons:GetChildren()) do
            local Pen = Weapon:FindFirstChild("Penetration")
            if Pen then
                if state then
                    if originalValues.WallBang[Weapon] == nil then
                        originalValues.WallBang[Weapon] = Pen.Value
                    end
                    Pen.Value = 99999999999999999
                else
                    if originalValues.WallBang[Weapon] ~= nil then
                        Pen.Value = originalValues.WallBang[Weapon]
                    end
                end
            end
        end
        if not state then originalValues.WallBang = {} end
    end,
})


local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local sounds = {
    ["Default Headshot"] = "rbxassetid://9119561046",
    ["Default Body"] = "rbxassetid://9114487369",
    Neverlose = "rbxassetid://8726881116",
    Gamesense = "rbxassetid://4817809188",
    One = "rbxassetid://7380502345",
    Bell = "rbxassetid://6534947240",
    Rust = "rbxassetid://1255040462",
    TF2 = "rbxassetid://2868331684",
    Slime = "rbxassetid://6916371803",
    ["Among Us"] = "rbxassetid://5700183626",
    Minecraft = "rbxassetid://4018616850",
    ["CS:GO"] = "rbxassetid://6937353691",
    Saber = "rbxassetid://8415678813",
    Baimware = "rbxassetid://3124331820",
    Osu = "rbxassetid://7149255551",
    ["TF2 Critical"] = "rbxassetid://296102734",
    Bat = "rbxassetid://3333907347",
    ["Call of Duty"] = "rbxassetid://5952120301",
    Bubble = "rbxassetid://6534947588",
    Pick = "rbxassetid://1347140027",
    Pop = "rbxassetid://198598793",
    Bruh = "rbxassetid://4275842574",
    Bamboo = "rbxassetid://3769434519",
    Crowbar = "rbxassetid://546410481",
    Weeb = "rbxassetid://6442965016",
    Beep = "rbxassetid://8177256015",
    Bambi = "rbxassetid://8437203821",
    Stone = "rbxassetid://3581383408",
    ["Old Fatality"] = "rbxassetid://6607142036",
    Click = "rbxassetid://8053704437",
    Ding = "rbxassetid://7149516994",
    Snow = "rbxassetid://6455527632",
    Laser = "rbxassetid://7837461331",
    Mario = "rbxassetid://2815207981",
    Steve = "rbxassetid://4965083997"
}


local function PlayHitSound(soundId)
    local customSound = Instance.new("Sound")
    customSound.SoundId = soundId
    customSound.Volume = 10
    customSound.Pitch = 1
    customSound.Parent = localPlayer:WaitForChild("PlayerGui")
    customSound:Play()
    customSound.Ended:Connect(function()
        customSound:Destroy()
    end)
end

local CustomHitSounds = false
local SelectedSound = sounds["Default Headshot"]

RightMisc:AddToggle("hitboxToggle", {
    Text = "Hitsounds",
    Callback = function(state)
        CustomHitSounds = state
    end,
})

RightMisc:AddDropdown("hitboxDropdown", {
    Values = {
        'Default Headshot', 'Neverlose', 'Gamesense', 'One', 'Bell',
        'Rust', 'TF2', 'Slime', 'Among Us', 'Minecraft', 'CS:GO',
        'Saber', 'Baimware', 'Osu', 'TF2 Critical', 'Bat', 'Call of Duty',
        'Bubble', 'Pick', 'Pop', 'Bruh', 'Bamboo', 'Crowbar', 'Weeb',
        'Beep', 'Bambi', 'Stone', 'Old Fatality', 'Click', 'Ding', 'Snow',
        'Laser', 'Mario', 'Steve', 'Snowdrake'
    },
    Default = 4,
    callback = function(selected)
        SelectedSound = sounds[selected]
    end,
})
local function onPlayerDamage()
    if CustomHitSounds and SelectedSound then
        PlayHitSound(SelectedSound)
    end
end

local sets = {}

task.spawn(function()
    while task.wait() do
        for i,v in next, players:GetPlayers() do
            if v == localPlayer then continue end

            if not localPlayer.Character then continue end
            if not localPlayer.Character:FindFirstChild("Humanoid") then continue end
            if not localPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end

            if not v.Character then continue end
            if not v.Character:FindFirstChild("Humanoid") then continue end
            if not v.Character:FindFirstChild("HumanoidRootPart") then continue end

            if (localPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude > 350 then continue end

            pcall(function()  
                if sets[v.UserId] > v.Character.Humanoid.Health then
                    onPlayerDamage()
                end
            end)

            sets[v.UserId] = v.Character.Humanoid.Health
        end
    end
end)

RightMisc:AddSlider("MySlider", {
	Text = "Hitsound Volume",
	Default = 1,
	Min = 0,
	Max = 10,
	Rounding = 1,
	Compact = false,
	Tooltip = "",
	DisabledTooltip = "",
	Disabled = false,
	Visible = true,
    Callback = function(Value)
        if customSound then
            customSound.Volume = value
        end
    end,
})

RightMisc:AddSlider("MySlider", {
	Text = "Hitsound Pitch",
	Default = 1,
	Min = 1,
	Max = 2,
	Rounding = 1,
	Compact = false,
	Tooltip = "",
	DisabledTooltip = "",
	Disabled = false,
	Visible = true,
    callback = function(value)
        if customSound then
            customSound.Pitch = value 
        end
    end,
})

RightMisc:AddToggle("MyToggle", {
	Text = "Unlock All",
	Tooltip = "Unlocks all skins",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function()
local Client = getsenv(game.Players.LocalPlayer.PlayerGui.Client)
 
local allSkins = {
{'M249_Aggressor'},
{'M249_Wolf'},
{'M249_P2020'},
{'M249_Spooky'},
{'M249_Lantern'},
{'M249_Halloween Treats'},
{'AWP_Grepkin'},
{'AWP_Instinct'},
{'AWP_Nerf'},
{'AWP_JTF2'},
{'AWP_Difference'},
{'AWP_Weeb'},
{'AWP_Pink Vision'},
{'AWP_Desert Camo'},
{'AWP_BloxersClub'},
{'AWP_Lunar'},
{'AWP_Scapter'},
{'AWP_Coffin Biter'},
{'AWP_Pear Tree'},
{'AWP_Northern Lights'},
{'AWP_Racer'},
{'AWP_Forever'},
{'AWP_Blastech'},
{'AWP_Abaddon'},
{'AWP_Retroactive'},
{'AWP_Pinkie'},
{'AWP_Autumness'},
{'AWP_Venomus'},
{'AWP_Hika'},
{'AWP_Silence'},
{'AWP_Kumanjayi'},
{'AWP_Dragon'},
{'AWP_Illusion'},
{'AWP_Regina'},
{'AWP_Quicktime'},
{'AWP_Toxic Nitro'},
{'AWP_Darkness'},
{'AWP_Oriental'},
{'AWP_Grim'},
{'AWP_Bloodborne'},
{'Sickle_Mummy'},
{'Sickle_Splattered'},
{'Sickle_Psychadelic'},
{'P2000_Comet'},
{'P2000_Golden Age'},
{'P2000_Apathy'},
{'P2000_Candycorn'},
{'P2000_Lunar'},
{'P2000_Ruby'},
{'P2000_Camo Dipped'},
{'P2000_Dark Beast'},
{'P2000_Pinkie'},
{'P2000_Silence'},
{'Flip Knife_Stock'},
{'Negev_Winterfell'},
{'Negev_Default'},
{'Negev_Quazar'},
{'Negev_Midnightbones'},
{'Negev_Wetland'},
{'Negev_Striped'},
{'Tec9_Gift Wrapped'},
{'Tec9_Ironline'},
{'Tec9_Skintech'},
{'Tec9_Stocking Stuffer'},
{'Tec9_Samurai'},
{'Tec9_Phol'},
{'Tec9_Charger'},
{'Tec9_Performer'},
{'Tec9_Seasoned'},
{'SawedOff_Spooky'},
{'SawedOff_Colorboom'},
{'SawedOff_Casino'},
{'SawedOff_Opal'},
{'SawedOff_Executioner'},
{'SawedOff_Sullys Blacklight'},
{'AUG_Phoenix'},
{'AUG_Dream Hound'},
{'AUG_Enlisted'},
{'AUG_Homestead'},
{'AUG_Sunsthetic'},
{'AUG_NightHawk'},
{'AUG_Maker'},
{'AUG_Graffiti'},
{'AUG_Chilly Night'},
{'AUG_Mystique'},
{'AUG_Soldier'},
{'Huntsman Knife_Stock'},
{'Huntsman Knife_Bloodwidow'},
{'Huntsman Knife_Crippled Fade'},
{'Huntsman Knife_Frozen Dream'},
{'Huntsman Knife_Geo Blade'},
{'Huntsman Knife_Hallows'},
{'Huntsman Knife_Marbleized'},
{'Huntsman Knife_Naval'},
{'Huntsman Knife_Ruby'},
{'Huntsman Knife_Splattered'},
{'Huntsman Knife_Wetland'},
{'Huntsman Knife_Monster'},
{'Huntsman Knife_Cozy'},
{'Huntsman Knife_Cosmos'},
{'Huntsman Knife_Digital'},
{'Huntsman Knife_Tropical'},
{'Huntsman Knife_Crimson Tiger'},
{'Huntsman Knife_Worn'},
{'Huntsman Knife_Egg Shell'},
{'Huntsman Knife_Twitch'},
{'Huntsman Knife_Honor Fade'},
{'Huntsman Knife_Consumed'},
{'Huntsman Knife_Goo'},
{'Huntsman Knife_Wrapped'},
{'Huntsman Knife_Aurora'},
{'Huntsman Knife_Ciro'},
{'Huntsman Knife_Drop-Out'},
{'Huntsman Knife_Spirit'},
{'Huntsman Knife_Spookiness'},
{'FiveSeven_Stigma'},
{'FiveSeven_Summer'},
{'FiveSeven_Gifted'},
{'FiveSeven_Midnight Ride'},
{'FiveSeven_Fluid'},
{'FiveSeven_Sub Zero'},
{'FiveSeven_Autumn Fade'},
{'FiveSeven_Mr. Anatomy'},
{'FiveSeven_Danjo'},
{'Falchion Classic_Late Night'},
{'DesertEagle_Glittery'},
{'DesertEagle_Grim'},
{'DesertEagle_Weeb'},
{'DesertEagle_Krystallos'},
{'DesertEagle_Honor-bound'},
{'DesertEagle_TC'},
{'DesertEagle_Xmas'},
{'DesertEagle_Scapter'},
{'DesertEagle_Cool Blue'},
{'DesertEagle_Survivor'},
{'DesertEagle_Ababa'},
{'DesertEagle_Heat'},
{'DesertEagle_ROLVe'},
{'DesertEagle_Independence'},
{'DesertEagle_Racer'},
{'DesertEagle_Pumpkin Buster'},
{'DesertEagle_Skin Committee'},
{'DesertEagle_DropX'},
{'DesertEagle_Crystal'},
{'DesertEagle_Blue Fur'},
{'DesertEagle_Cold Truth'},
{'DesertEagle_BloxersClub'},
{'DesertEagle_Guapo'},
{'G3SG1_Foliage'},
{'G3SG1_Hex'},
{'G3SG1_Amethyst'},
{'G3SG1_Autumn'},
{'G3SG1_Mahogany'},
{'G3SG1_Holly Bound'},
{'Karambit_Stock'},
{'Karambit_Bloodwidow'},
{'Karambit_Crippled Fade'},
{'Karambit_Frozen Dream'},
{'Karambit_Gold'},
{'Karambit_Hallows'},
{'Karambit_Jade Dream'},
{'Karambit_Marbleized'},
{'Karambit_Naval'},
{'Karambit_Ruby'},
{'Karambit_Splattered'},
{'Karambit_Twitch'},
{'Karambit_Wetland'},
{'Karambit_Scapter'},
{'Karambit_Lantern'},
{'Karambit_Glossed'},
{'Karambit_Cosmos'},
{'Karambit_Digital'},
{'Karambit_Topaz'},
{'Karambit_Crimson Tiger'},
{'Karambit_Egg Shell'},
{'Karambit_Worn'},
{'Karambit_Tropical'},
{'Karambit_Neonic'},
{'Karambit_Liberty Camo'},
{'Karambit_Ghost'},
{'Karambit_Consumed'},
{'Karambit_Goo'},
{'Karambit_Death Wish'},
{'Karambit_Pizza'},
{'Karambit_Festive'},
{'Karambit_Quicktime'},
{'Karambit_Racer'},
{'Karambit_Jester'},
{'Karambit_Ciro'},
{'Karambit_Drop-Out'},
{'Karambit_Peppermint'},
{'Karambit_Cob Web'},
{'USP_Skull'},
{'USP_Yellowbelly'},
{'USP_Crimson'},
{'USP_Jade Dream'},
{'USP_Racing'},
{'USP_Frostbite'},
{'USP_Nighttown'},
{'USP_Paradise'},
{'USP_Dizzy'},
{'USP_Kraken'},
{'USP_Worlds Away'},
{'USP_Unseen'},
{'USP_Holiday'},
{'USP_Survivor'},
{'USP_BloxersClub'},
{'MAC10_Pimpin'},
{'MAC10_Wetland'},
{'MAC10_Turbo'},
{'MAC10_Golden Rings'},
{'MAC10_Skeleboney'},
{'MAC10_Artists Intent'},
{'MAC10_Toxic'},
{'MAC10_Blaze'},
{'MAC10_Scythe'},
{'MAC10_Devil'},
{'Glock_Desert Camo'},
{'Glock_Day Dreamer'},
{'Glock_Wetland'},
{'Glock_Anubis'},
{'Glock_Midnight Tiger'},
{'Glock_Scapter'},
{'Glock_Gravestomper'},
{'Glock_Tarnish'},
{'Glock_Rush'},
{'Glock_Angler'},
{'Glock_Spacedust'},
{'Glock_Money Maker'},
{'Glock_RSL'},
{'Glock_White Sauce'},
{'Glock_Biotrip'},
{'Glock_Underwater'},
{'Glock_Hallows'},
{'Glock_BloxersClub'},
{'Fingerless Glove_Kimura'},
{'Fingerless Glove_Spookiness'},
{'Fingerless Glove_Patch'},
{'Fingerless Glove_Digital'},
{'Fingerless Glove_Scapter'},
{'Fingerless Glove_Crystal'},
{'MP7_Sunshot'},
{'MP7_Calaxian'},
{'MP7_Goo'},
{'MP7_Holiday'},
{'MP7_Silent Ops'},
{'MP7_Industrial'},
{'MP7_Reindeer'},
{'MP7_Cogged'},
{'MP7_Trauma'},
{'AK47_Hallows'},
{'AK47_Ace'},
{'AK47_Code Orange'},
{'AK47_Clown'},
{'AK47_Variant Camo'},
{'AK47_Eve'},
{'AK47_VAV'},
{'AK47_Quantum'},
{'AK47_Hypersonic'},
{'AK47_Mean Green'},
{'AK47_Bloodboom'},
{'AK47_Scapter'},
{'AK47_Skin Committee'},
{'AK47_Patch'},
{'AK47_Outlaws'},
{'AK47_Gifted'},
{'AK47_Ugly Sweater'},
{'AK47_Secret Santa'},
{'AK47_Precision'},
{'AK47_Outrunner'},
{'AK47_Godess'},
{'AK47_Maker'},
{'AK47_Ghost'},
{'AK47_Glo'},
{'AK47_Survivor'},
{'AK47_Shooting Star'},
{'AK47_Halo'},
{'AK47_Inversion'},
{'AK47_Plated'},
{'AK47_Quicktime'},
{'AK47_Yltude'},
{'AK47_Trinity'},
{'AK47_Toxic Nitro'},
{'AK47_Scythe'},
{'AK47_Neonline'},
{'AK47_Galaxy Corpse'},
{'AK47_Weeb'},
{'AK47_Super Weeb'},
{'AK47_BloxersClub'},
{'AK47_Jester'},
{'Galil_Hardware'},
{'Galil_Hardware 2'},
{'Galil_Toxicity'},
{'Galil_Frosted'},
{'Galil_Worn'},
{'Butterfly Knife_Stock'},
{'Butterfly Knife_Bloodwidow'},
{'Butterfly Knife_Crippled Fade'},
{'Butterfly Knife_Frozen Dream'},
{'Butterfly Knife_Hallows'},
{'Butterfly Knife_Jade Dream'},
{'Butterfly Knife_Marbleized'},
{'Butterfly Knife_Naval'},
{'Butterfly Knife_Ruby'},
{'Butterfly Knife_Splattered'},
{'Butterfly Knife_Twitch'},
{'Butterfly Knife_Wetland'},
{'Butterfly Knife_White Boss'},
{'Butterfly Knife_Scapter'},
{'Butterfly Knife_Reaper'},
{'Butterfly Knife_Icicle'},
{'Butterfly Knife_Cosmos'},
{'Butterfly Knife_Digital'},
{'Butterfly Knife_Topaz'},
{'Butterfly Knife_Tropical'},
{'Butterfly Knife_Crimson Tiger'},
{'Butterfly Knife_Egg Shell'},
{'Butterfly Knife_Worn'},
{'Butterfly Knife_Neonic'},
{'Butterfly Knife_Freedom'},
{'Butterfly Knife_Consumed'},
{'Butterfly Knife_Goo'},
{'Butterfly Knife_Inversion'},
{'Butterfly Knife_Wrapped'},
{'Butterfly Knife_Aurora'},
{'Butterfly Knife_Argus'},
{'Butterfly Knife_Snowfall'},
{'Butterfly Knife_Spooky'},
{'Strapped Glove_Cob Web'},
{'Strapped Glove_Kringle'},
{'Strapped Glove_Molten'},
{'Strapped Glove_Wisk'},
{'Strapped Glove_Grim'},
{'Strapped Glove_Racer'},
{'Strapped Glove_Drop-Out'},
{'Strapped Glove_BloxersClub'},
{'Sports Glove_Pumpkin'},
{'Sports Glove_CottonTail'},
{'Sports Glove_RSL'},
{'Sports Glove_Skulls'},
{'Sports Glove_Weeb'},
{'Sports Glove_Royal'},
{'Sports Glove_Majesty'},
{'Sports Glove_Hallows'},
{'Sports Glove_Hazard'},
{'Sports Glove_Calamity'},
{'Sports Glove_Twitch'},
{'Sports Glove_Dead Prey'},
{'MAG7_Molten'},
{'MAG7_Striped'},
{'MAG7_Frosty'},
{'MAG7_Outbreak'},
{'MAG7_Bombshell'},
{'MAG7_C4UTION'},
{'Handwraps_Mummy'},
{'Handwraps_Toxic Nitro'},
{'Handwraps_Green Hex'},
{'Handwraps_Purple Hex'},
{'Handwraps_Orange Hex'},
{'Handwraps_Spector Hex'},
{'Handwraps_Phantom Hex'},
{'Handwraps_Microbes'},
{'Handwraps_Wetland'},
{'Handwraps_Guts'},
{'Handwraps_Wraps'},
{'Handwraps_MMA'},
{'Handwraps_Ghoul Hex'},
{'XM_Red'},
{'XM_Spectrum'},
{'XM_Artic'},
{'XM_Atomic'},
{'XM_Campfire'},
{'XM_Predator'},
{'XM_MK11'},
{'XM_Endless Night'},
{'UMP_Militia Camo'},
{'UMP_Magma'},
{'UMP_Redline'},
{'UMP_Death Grip'},
{'UMP_Molten'},
{'UMP_Gum Drop'},
{'UMP_Orbit'},
{'Crowbar_Stock'},
{'M4A1_Toucan'},
{'M4A1_Animatic'},
{'M4A1_Desert Camo'},
{'M4A1_Wastelander'},
{'M4A1_BloxersClub'},
{'M4A1_Tecnician'},
{'M4A1_Impulse'},
{'M4A1_Burning'},
{'M4A1_Lunar'},
{'M4A1_Necropolis'},
{'M4A1_Jester'},
{'M4A1_Nightmare'},
{'M4A1_Heavens Gate'},
{'Scout_Xmas'},
{'Scout_Coffin Biter'},
{'Scout_Railgun'},
{'Scout_Hellborn'},
{'Scout_Hot Cocoa'},
{'Scout_Theory'},
{'Scout_Pulse'},
{'Scout_Monstruo'},
{'Scout_Flowing Mists'},
{'Scout_Neon Regulation'},
{'Scout_Posh'},
{'Scout_Darkness'},
{'CZ_Lightning'},
{'CZ_Orange Web'},
{'CZ_Festive'},
{'CZ_Spectre'},
{'CZ_Designed'},
{'CZ_Holidays'},
{'CZ_Hallow'},
{'Falchion Knife_Stock'},
{'Falchion Knife_Bloodwidow'},
{'Falchion Knife_Chosen'},
{'Falchion Knife_Crippled Fade'},
{'Falchion Knife_Frozen Dream'},
{'Falchion Knife_Hallows'},
{'Falchion Knife_Marbleized'},
{'Falchion Knife_Naval'},
{'Falchion Knife_Ruby'},
{'Falchion Knife_Splattered'},
{'Falchion Knife_Wetland'},
{'Falchion Knife_Zombie'},
{'Falchion Knife_Coal'},
{'Falchion Knife_Late Night'},
{'Falchion Knife_Cosmos'},
{'Falchion Knife_Digital'},
{'Falchion Knife_Topaz'},
{'Falchion Knife_Tropical'},
{'Falchion Knife_Crimson Tiger'},
{'Falchion Knife_Egg Shell'},
{'Falchion Knife_Worn'},
{'Falchion Knife_Neonic'},
{'Falchion Knife_Consumed'},
{'Falchion Knife_Freedom'},
{'Falchion Knife_Goo'},
{'Falchion Knife_Inversion'},
{'Falchion Knife_Wrapped'},
{'Falchion Knife_Festive'},
{'Falchion Knife_Racer'},
{'Falchion Knife_Toxic Nitro'},
{'Falchion Knife_Pumpkin'},
{'Falchion Knife_Cocoa'},
{'Falchion Knife_Kimura'},
{'Falchion Knife_Twilight'},
{'M4A4_Devil'},
{'M4A4_Pinkvision'},
{'M4A4_Desert Camo'},
{'M4A4_BOT[S]'},
{'M4A4_Precision'},
{'M4A4_Candyskull'},
{'M4A4_Scapter'},
{'M4A4_Toy Soldier'},
{'M4A4_Endline'},
{'M4A4_Pondside'},
{'M4A4_Ice Cap'},
{'M4A4_Pinkie'},
{'M4A4_Racer'},
{'M4A4_Stardust'},
{'M4A4_King'},
{'M4A4_Flashy Ride'},
{'M4A4_RayTrack'},
{'M4A4_Mistletoe'},
{'M4A4_Delinquent'},
{'M4A4_Quicktime'},
{'M4A4_Jester'},
{'M4A4_Darkness'},
{'MP9_Velvita'},
{'MP9_Blueroyal'},
{'MP9_Decked Halls'},
{'MP9_Cookie Man'},
{'MP9_Wilderness'},
{'MP9_Vaporwave'},
{'MP9_Cob Web'},
{'MP9_SnowTime'},
{'MP9_Control'},
{'P90_Skulls'},
{'P90_Redcopy'},
{'P90_Demon Within'},
{'P90_P-Chan'},
{'P90_Krampus'},
{'P90_Pine'},
{'P90_Elegant'},
{'P90_Northern Lights'},
{'P90_Argus'},
{'P90_Curse'},
{'SG_Yltude'},
{'SG_Knighthood'},
{'SG_Variant Camo'},
{'SG_Magma'},
{'SG_DropX'},
{'SG_Dummy'},
{'SG_Kitty Cat'},
{'SG_Drop-Out'},
{'SG_Control'},
{'Gut Knife_Bloodwidow'},
{'Gut Knife_Crippled Fade'},
{'Gut Knife_Frozen Dream'},
{'Gut Knife_Geo Blade'},
{'Gut Knife_Present'},
{'Gut Knife_Marbleized'},
{'Gut Knife_Naval'},
{'Gut Knife_Ruby'},
{'Gut Knife_Rusty'},
{'Gut Knife_Splattered'},
{'Gut Knife_Wetland'},
{'Gut Knife_Lurker'},
{'Gut Knife_Hallows'},
{'Gut Knife_Cosmos'},
{'Gut Knife_Digital'},
{'Gut Knife_Topaz'},
{'Gut Knife_Tropical'},
{'Gut Knife_Crimson Tiger'},
{'Gut Knife_Egg Shell'},
{'Gut Knife_Worn'},
{'Gut Knife_Neonic'},
{'Gut Knife_Banner'},
{'Gut Knife_Consumed'},
{'Gut Knife_Goo'},
{'Gut Knife_Wrapped'},
{'Gut Knife_Holly'},
{'Gut Knife_Cob Web'},
{'R8_Violet'},
{'R8_Hunter'},
{'R8_Spades'},
{'R8_Exquisite'},
{'R8_TG'},
{'P250_BloxersClub'},
{'P250_Green Web'},
{'P250_TC250'},
{'P250_Amber'},
{'P250_Frosted'},
{'P250_Solstice'},
{'P250_Equinox'},
{'P250_Goldish'},
{'P250_Shark'},
{'P250_Midnight'},
{'P250_Bomber'},
{'Nova_Terraformer'},
{'Nova_Tiger'},
{'Nova_Black Ice'},
{'Nova_Sharkesh'},
{'Nova_Paradise'},
{'Nova_Starry Night'},
{'Nova_Cookie'},
{'Nova_Tricked'},
{'Nova_Defective'},
{'Nova_Oath'},
{'Bearded Axe_Beast'},
{'Bearded Axe_Splattered'},
{'Cleaver_Spider'},
{'Cleaver_Splattered'},
{'Cleaver_ImageLabel'},
{'Bayonet_Stock'},
{'Bayonet_Frozen Dream'},
{'Bayonet_Geo Blade'},
{'Bayonet_Hallows'},
{'Bayonet_Intertwine'},
{'Bayonet_Marbleized'},
{'Bayonet_Naval'},
{'Bayonet_Sapphire'},
{'Bayonet_Splattered'},
{'Bayonet_Twitch'},
{'Bayonet_Wetland'},
{'Bayonet_Easy-Bake'},
{'Bayonet_Crow'},
{'Bayonet_UFO'},
{'Bayonet_Silent Night'},
{'Bayonet_Ciro'},
{'Bayonet_Digital'},
{'Bayonet_Topaz'},
{'Bayonet_Tropical'},
{'Bayonet_Crimson Tiger'},
{'Bayonet_Egg Shell'},
{'Bayonet_Worn'},
{'Bayonet_Neonic'},
{'Bayonet_RSL'},
{'Bayonet_Consumed'},
{'Bayonet_Banner'},
{'Bayonet_Goo'},
{'Bayonet_Ghastly'},
{'Bayonet_Candy Cane'},
{'Bayonet_Mariposa'},
{'Bayonet_Aequalis'},
{'Bayonet_Festive'},
{'Bayonet_Wrapped'},
{'Bayonet_Delinquent'},
{'Bayonet_Racer'},
{'Bayonet_Decor'},
{'Bayonet_Kimura'},
{'Bayonet_Haunted'},
{'Bayonet_BloxersClub'},
{'Bayonet_Cosmos'},
{'Famas_Abstract'},
{'Famas_Haunted Forest'},
{'Famas_Goliath'},
{'Famas_Redux'},
{'Famas_Toxic Rain'},
{'Famas_Centipede'},
{'Famas_Medic'},
{'Famas_Cogged'},
{'Famas_KugaX'},
{'Famas_Shocker'},
{'Famas_MK11'},
{'Famas_Imprisioned'},
{'Bizon_Festive'},
{'Bizon_Shattered'},
{'Bizon_Oblivion'},
{'Bizon_Sergeant'},
{'Bizon_Saint Nick'},
{'Bizon_Autumic'},
}
 
local isUnlocked
 
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
 
local isUnlocked
 
mt.__namecall = newcclosure(function(self, ...)
   local args = {...}
   if getnamecallmethod() == "InvokeServer" and tostring(self) == "Hugh" then
       return
   end
   if getnamecallmethod() == "FireServer" then
       if args[1] == LocalPlayer.UserId then
           return
       end
       if string.len(tostring(self)) == 38 then
           if not isUnlocked then
               isUnlocked = true
               for i,v in pairs(allSkins) do
                   local doSkip
                   for i2,v2 in pairs(args[1]) do
                       if v[1] == v2[1] then
                           doSkip = true
                       end
                   end
                   if not doSkip then
                       table.insert(args[1], v)
                   end
               end
           end
           return
       end
       if tostring(self) == "DataEvent" and args[1][4] then
           local currentSkin = string.split(args[1][4][1], "_")[2]
           if args[1][2] == "Both" then
               LocalPlayer["SkinFolder"]["CTFolder"][args[1][3]].Value = currentSkin
               LocalPlayer["SkinFolder"]["TFolder"][args[1][3]].Value = currentSkin
           else
               LocalPlayer["SkinFolder"][args[1][2] .. "Folder"][args[1][3]].Value = currentSkin
           end
       end
   end
   return oldNamecall(self, ...)
end)
   
setreadonly(mt, true)
 
Client.CurrentInventory = allSkins
 
local TClone, CTClone = LocalPlayer.SkinFolder.TFolder:Clone(), game.Players.LocalPlayer.SkinFolder.CTFolder:Clone()
LocalPlayer.SkinFolder.TFolder:Destroy()
LocalPlayer.SkinFolder.CTFolder:Destroy()
TClone.Parent = LocalPlayer.SkinFolder
CTClone.Parent = LocalPlayer.SkinFolder
end
})

local world = Tabs.visuals:AddRightGroupbox("World")
local esp = Tabs.visuals:AddLeftGroupbox("Esp")

local BonePairs = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"},
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ESPLines = {}
local SkeletonESPEnabled = false
local SkeletonColor = Color3.fromRGB(255, 0, 0)

local function IsOnSameTeam(player)
	return player.Team == LocalPlayer.Team
end

esp:AddToggle("MyToggle", {
	Text = "Skeleton ESP",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
		SkeletonESPEnabled = state
		if not state then
			for _, items in pairs(ESPLines) do
				for _, obj in pairs(items.Lines) do obj.Visible = false end
				if items.HeadCircle then items.HeadCircle.Visible = false end
			end
		end
	end,
})
:AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 1, 1),
	Title = "Fov Color", 
	Transparency = 0, 

	Callback = function(col)
		SkeletonColor = col
		for _, items in pairs(ESPLines) do
			for _, obj in pairs(items.Lines) do obj.Color = col end
			if items.HeadCircle then items.HeadCircle.Color = col end
		end
	end,
})

Players.PlayerRemoving:Connect(function(player)
	local items = ESPLines[player]
	if items then
		for _, line in pairs(items.Lines) do
			line:Remove()
		end
		if items.HeadCircle then
			items.HeadCircle:Remove()
		end
		ESPLines[player] = nil
	end
end)

RunService.RenderStepped:Connect(function()
	if not SkeletonESPEnabled then return end

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not IsOnSameTeam(player) then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				if not ESPLines[player] then
					ESPLines[player] = { Lines = {} }

					for i = 1, #BonePairs do
						local line = Drawing.new("Line")
						line.Thickness = 1
						line.Color = SkeletonColor
						line.Visible = false
						ESPLines[player].Lines[i] = line
					end

					local circle = Drawing.new("Circle")
					circle.Radius = 4
					circle.Filled = false
					circle.Color = SkeletonColor
					circle.Thickness = 1
					circle.Visible = false
					ESPLines[player].HeadCircle = circle
				end

				for i, pair in ipairs(BonePairs) do
					local part1 = character:FindFirstChild(pair[1])
					local part2 = character:FindFirstChild(pair[2])
					local line = ESPLines[player].Lines[i]

					if part1 and part2 and line then
						local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
						local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)

						if vis1 and vis2 then
							line.From = Vector2.new(pos1.X, pos1.Y)
							line.To = Vector2.new(pos2.X, pos2.Y)
							line.Visible = true
						else
							line.Visible = false
						end
					elseif line then
						line.Visible = false
					end
				end

				local head = character:FindFirstChild("Head")
				local circle = ESPLines[player].HeadCircle
				if head and circle then
					local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
					if onScreen then
						circle.Position = Vector2.new(headPos.X, headPos.Y)
						circle.Visible = true
					else
						circle.Visible = false
					end
				end
			else
				if ESPLines[player] then
					for _, line in pairs(ESPLines[player].Lines) do line.Visible = false end
					if ESPLines[player].HeadCircle then ESPLines[player].HeadCircle.Visible = false end
				end
			end
		end
	end
end)

world:AddToggle("MyToggle", {
	Text = "Third Person",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        ThirdPerson = state
	end,
})

world:AddSlider("NightModeBrightnessSlider", {
    Text = "Third Person Distance",
    Default = 10,
    Min = 0,
    Max = 100,
    Callback = function(Value)
        ThirdPersonDistance = value
    end,
})

world:AddSlider("NightModeBrightnessSlider", {
    Text = "Fov Changer",
    Default = 80,
    Min = 0,
    Max = 120,
    Callback = function(Value)
        FieldOfView = value
    end,
})

world:AddToggle("MyToggle", {
	Text = "Arm Chams",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        ArmsChams = state
	end,
})

world:AddToggle("MyToggle", {
	Text = "View Model Chams",
	Tooltip = "",
	DisabledTooltip = "", 
	Default = false, 
	Disabled = false, 
	Visible = true, 
	Risky = false, 
	Callback = function(state)
        GunsChams = state
	end,
})
:AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 1, 1),
	Title = "", 
	Transparency = 0, 

	Callback = function(color)
        ChamsColor = color
	end,
})

RunService.RenderStepped:Connect(function()
    if Bhop == true then
        if LocalPlayer.Character ~= nil and UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalPlayer.PlayerGui.GUI.Main.GlobalChat.Visible == false then
            LocalPlayer.Character.Humanoid.Jump = true
            local Speed = BhopSpeed or 100
            local Dir = Camera.CFrame.LookVector * Vector3.new(1,0,1)
            local Move = Vector3.new()

            Move = UserInputService:IsKeyDown(Enum.KeyCode.W) and Move + Dir or Move
            Move = UserInputService:IsKeyDown(Enum.KeyCode.S) and Move - Dir or Move
            Move = UserInputService:IsKeyDown(Enum.KeyCode.D) and Move + Vector3.new(-Dir.Z,0,Dir.X) or Move
            Move = UserInputService:IsKeyDown(Enum.KeyCode.A) and Move + Vector3.new(Dir.Z,0,-Dir.X) or Move
            if Move.Unit.X == Move.Unit.X then
                Move = Move.Unit
                LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(Move.X * Speed, LocalPlayer.Character.HumanoidRootPart.Velocity.Y, Move.Z * Speed)
            end
        end
    end
    task.wait()
end)

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local NightModeEnabled = false
local NightModeColor = Color3.fromRGB(50, 50, 50)
local NightModeBrightness = 0.2

local function updateNightMode()
    if NightModeEnabled then
        Lighting.Ambient = NightModeColor
        Lighting.OutdoorAmbient = NightModeColor
        Lighting.Brightness = NightModeBrightness
        Lighting.EnvironmentDiffuseScale = 0.1
        Lighting.EnvironmentSpecularScale = 0
    else
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end
end

world:AddToggle("NightModeToggle", {
    Text = "Night Mode",
    Callback = function(state)
        NightModeEnabled = state
        updateNightMode()
    end,
})
:AddColorPicker("NightModeColorPicker", {
    Default = Color3.new(1, 1, 1),
    Callback = function(color)
        NightModeColor = color
        if NightModeEnabled then updateNightMode() end
    end,
})

world:AddSlider("NightModeBrightnessSlider", {
    Text = "Night Mode Brightness",
    Default = 100,
    Min = 0,
    Max = 10,
    Callback = function(Value)
        NightModeBrightness = Value / 100
        if NightModeEnabled then updateNightMode() end
    end,
})

-- Fog
local FogEnabled = false
local FogStart = 500
local FogEnd = 1000
local FogColor = Color3.fromRGB(255, 0, 0)

local function updateFog()
    if FogEnabled then
        Lighting.FogStart = FogStart
        Lighting.FogEnd = FogEnd
        Lighting.FogColor = FogColor
    else
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.FogColor = Color3.new(1, 1, 1)
    end
end

world:AddToggle("FogToggle", {
    Text = "Fog",
    Callback = function(state)
        FogEnabled = state
        updateFog()
    end,
})
:AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 1, 1),
	Title = "", 
	Transparency = 0, 

	Callback = function(color)
        FogColor = color
        updateFog()
	end,
})

world:AddSlider("FogStartSlider", {
    Text = "Fog Start",
    Default = 500,
    Min = 0,
    Max = 10000,
    Callback = function(Value)
        FogStart = Value
        updateFog()
    end,
})

world:AddSlider("FogEndSlider", {
    Text = "Fog End",
    Default = 1000,
    Min = 0,
    Max = 10000,
    Callback = function(Value)
        FogEnd = Value
        updateFog()
    end,
})
local function setPotatoMode(state)
    if state then
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.FogColor = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(0, 0, 0)
    else
        Lighting.GlobalShadows = true
        updateNightMode()
        updateFog()
    end
end

world:AddToggle("PotatoModeToggle", {
    Text = "Potato Mode",
    Callback = setPotatoMode,
})

local Lighting = game:GetService("Lighting")

local Skyboxes = {
    ["Red Mountains"] = "rbxassetid://109507439405212",
    ["Red Galaxy"] = "rbxassetid://16553683517",
    ["Nebula"] = "rbxassetid://108530355323087",
    ["Purple Mountains"] = "rbxassetid://16932794531"
}

local CustomSkyboxEnabled = false
local SelectedSkybox = "Purple Mountains"

local function setSkybox(assetId)
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "CustomSky"
        sky.Parent = Lighting
    end

    sky.SkyboxBk = assetId
    sky.SkyboxDn = assetId
    sky.SkyboxFt = assetId
    sky.SkyboxLf = assetId
    sky.SkyboxRt = assetId
    sky.SkyboxUp = assetId
end

local SelectedSkybox = "Purple Mountins"

world:AddToggle("CustomSkyboxToggle", {
    Text = "Enable Custom Skybox",
    Callback = function(state)
        CustomSkyboxEnabled = state
        if CustomSkyboxEnabled and Skyboxes[SelectedSkybox] then
            setSkybox(Skyboxes[SelectedSkybox])
        end
    end,
})

world:AddDropdown("SkyboxDropdown", {
    Values = {"Red Mountains", "Red Galaxy", "Nebula", "Purple Mountains"},
    Default = 4,
    Callback = function(Value)
        if Skyboxes[Value] then
            setSkybox(Skyboxes[Value])
        end
    end,
})

local ArmColor = ArmColor or Color3.fromRGB(200, 200, 200)

RunService.RenderStepped:Connect(function()
    if GunsChams == true then
        for _, Stuff in ipairs(workspace.Camera:GetChildren()) do
            if Stuff:IsA("Model") and Stuff.Name == "Arms" then
                for _, AnotherStuff in ipairs(Stuff:GetChildren()) do
                    if AnotherStuff:IsA("MeshPart") or AnotherStuff:IsA("BasePart") then
                        AnotherStuff.Color = ChamsColor or Color3.fromRGB(200,200,200)
                        AnotherStuff.Material = Enum.Material.ForceField
                    end
                end
            end
        end
    else
        for _, Stuff in ipairs(workspace.Camera:GetChildren()) do
            if Stuff:IsA("Model") and Stuff.Name == "Arms" then
                for _, AnotherStuff in ipairs(Stuff:GetChildren()) do
                    if AnotherStuff:IsA("MeshPart") or AnotherStuff:IsA("BasePart") then
                        AnotherStuff.Color = ChamsColor or Color3.fromRGB(200,200,200)
                        AnotherStuff.Material = Enum.Material.Plastic
                    end
                end
            end
        end            
    end
    task.wait()
end)

RunService.RenderStepped:Connect(function()
    if ArmsChams == true then
        for _, Stuff in ipairs(workspace.Camera:GetChildren()) do
            if Stuff:IsA("Model") and Stuff.Name == "Arms" then
                for _, AnotherStuff in ipairs(Stuff:GetChildren()) do
                    if AnotherStuff:IsA("Model") and AnotherStuff.Name ~= "AnimSaves" then
                        for _, Arm in ipairs(AnotherStuff:GetChildren()) do
                            if Arm:IsA("BasePart") then
                                Arm.Transparency = 1
                                Arm.Color = ArmColor -- Apply the color
                                for _, StuffInArm in ipairs(Arm:GetChildren()) do
                                    if StuffInArm:IsA("BasePart") then
                                        StuffInArm.Material = Enum.Material.ForceField
                                        StuffInArm.Color = ArmColor or Color3.fromRGB(200, 200, 200)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        for _, Stuff in ipairs(workspace.Camera:GetChildren()) do
            if Stuff:IsA("Model") and Stuff.Name == "Arms" then
                for _, AnotherStuff in ipairs(Stuff:GetChildren()) do
                    if AnotherStuff:IsA("Model") and AnotherStuff.Name ~= "AnimSaves" then
                        for _, Arm in ipairs(AnotherStuff:GetChildren()) do
                            if Arm:IsA("BasePart") then
                                Arm.Transparency = 0
                                Arm.Color = ArmColor 
                                for _, StuffInArm in ipairs(Arm:GetChildren()) do
                                    if StuffInArm:IsA("BasePart") then
                                        StuffInArm.Material = Enum.Material.Plastic
                                        StuffInArm.Color = ArmColor or Color3.fromRGB(200, 200, 200)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    task.wait()
end)


        RunService.RenderStepped:Connect(function()
    if ThirdPerson == true then
        if LocalPlayer.CameraMinZoomDistance ~= ThirdPersonDistance or 10 then
            LocalPlayer.CameraMinZoomDistance = ThirdPersonDistance or 10
            LocalPlayer.CameraMaxZoomDistance = ThirdPersonDistance or 10
            workspace.ThirdPerson.Value = true
        end
    else
        if LocalPlayer.Character ~= nil then
            LocalPlayer.CameraMinZoomDistance = 0
            LocalPlayer.CameraMaxZoomDistance = 0
            workspace.ThirdPerson.Value = false
        end
    end
    task.wait()
end)

RunService.RenderStepped:Connect(function()
    if RemoveScope == true then
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.ImageTransparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.ImageTransparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Size = UDim2.new(2,0,2,0)
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Position = UDim2.new(-0.5,0,-0.5,0)
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.ImageTransparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.Blur.ImageTransparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame1.Transparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame2.Transparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame3.Transparency = 1
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame4.Transparency = 1
    else
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.ImageTransparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.ImageTransparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Size = UDim2.new(1,0,1,0)
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Position = UDim2.new(0,0,0,0)
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.ImageTransparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.Blur.ImageTransparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame1.Transparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame2.Transparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame3.Transparency = 0
        LocalPlayer.PlayerGui.GUI.Crosshairs.Frame4.Transparency = 0
    end
    task.wait()
end)

RunService.RenderStepped:Connect(function()
    if RemoveFlash == true then
        LocalPlayer.PlayerGui.Blnd.Enabled = false
    else
        LocalPlayer.PlayerGui.Blnd.Enabled = true
    end
    task.wait()
end)

RunService.RenderStepped:Connect(function()
    if RemoveBulletsHoles == true then
        for i,v in pairs(Debris:GetChildren()) do
            if v.Name == "Bullet" then
                v:Remove()
            end
        end
    end
    task.wait()
end)

RunService.RenderStepped:Connect(function()
    if RemoveSmoke == true then
        for i,v in pairs(RayIgnore.Smokes:GetChildren()) do
            if v.Name == "Smoke" then
                v:Remove()
            end
        end
    end                    
    task.wait()
end)
RunService.RenderStepped:Connect(function()
    if RemoveBlood == true then
        for i,v in pairs(Debris:GetChildren()) do
            if v.Name == "SurfaceGui" then
                v:Remove()
            end
        end
    end
    task.wait()
end)

RunService.RenderStepped:Connect(function()
    Camera.FieldOfView = FieldOfView or 80
    task.wait()
end)
