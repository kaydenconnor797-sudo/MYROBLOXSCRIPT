--[[
	Space Menu - made by K-Den!
	LocalScript for testing in your OWN game / Studio
	Put in: StarterPlayer > StarterPlayerScripts

	Tabs: ESP | Aim | Move | Visual | Tools | Settings
	Default keys (rebindable in the menu):
	  RightShift = open / close menu     F = fly
	  E = hold to aim-lock               Q = switch target
	  RightMouse = hold for aim assist   C = switch assist target
	  T = click-teleport (when enabled)

	Aim tab   : Aim-lock + Aim Assist (smooth camera pull)
	Visual tab: Lighting, Camera, Crosshair + FPS Booster
	Tools tab : Driver Assist (Auto Driver, AFK Prevention, Vehicle Avoidance, Dodge Settings)

	"Dev tools" in the Tools tab only work if you also install
	SpaceDevServer.lua (a Script) in ServerScriptService of YOUR place.

	Weapon control (Tools tab) writes RecoilScale / SpreadScale attributes
	on your equipped Tool. Your own weapon script must read them.

	Auto Driver drives a VehicleSeat (ThrottleFloat / SteerFloat) and also writes
	AutoThrottle / AutoSteer / AutoTargetSpeed attributes on the seat for custom
	vehicle scripts. Optional: Workspace.DriverRoute (Parts named 1,2,3...) = path.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

----------------------------------------------------------------
-- Settings
----------------------------------------------------------------
local S = {
	-- ESP
	ESP = true,
	Rainbow = false,
	Wallhack = true,
	ShowNames = true,
	HealthBars = true,
	Boxes = false,
	Skeletons = false,
	Tracers = false,
	ShowPlayers = true,
	ShowNPCs = true,
	TeamCheck = false,
	ESPMaxDist = 2000,
	ESPColor = Color3.fromRGB(255, 70, 70),

	-- Aim
	Aimlock = true,
	FOVEnabled = true,
	FOVRadius = 150,
	HardLock = true,
	Smoothing = 30,
	WallCheck = false,
	TargetPart = "Head",
	AimMode = "Hold",

	-- Movement
	WalkSpeedOn = false,
	WalkSpeed = 32,
	Fly = false,
	FlySpeed = 60,
	Noclip = false,
	InfJump = false,
	Invisible = false,
	ClickTP = false,

	-- Visual
	Fullbright = false,
	TimeOn = false,
	TimeOfDay = 14,
	CamFOVOn = false,
	CamFOV = 90,
	ZoomUnlock = false,
	ZoomMax = 300,
	Crosshair = false,
	CrosshairSize = 10,

	-- FPS Booster
	FPSBoost = false,
	FPSNoEffects = true,       -- particles, trails, beams, blur/bloom/etc.
	FPSSimpleMaterials = true, -- plastic material, no reflections, no part shadows
	FPSNoShadows = true,       -- Lighting.GlobalShadows off
	FPSLowQuality = true,      -- lowest render quality level
	FPSNoTerrainDeco = true,   -- grass and terrain decoration off

	-- Tools
	StatsPanel = false,
	ActiveList = true,
	Notifications = true,
	CatchRadiusOn = false,
	CatchRadius = 8,
	ThrowArcOn = false,
	ThrowSpeed = 60,
	ThrowAngle = 35,

	-- Weapon control (your own place)
	RecoilOn = false,
	RecoilScale = 10, -- percent of normal recoil that remains (0-100)
	SpreadScale = 10, -- percent of normal bullet spread that remains (0-100)

	-- Aim Assist (smooth camera pull)
	AssistOn = false,
	AssistFOVOn = true,
	AssistFOV = 120,
	AssistIndicator = true,
	AssistStrength = 45,
	AssistSmooth = 60,
	AssistMaxDist = 500,
	AssistPart = "Head",
	AssistTeamCheck = true,
	AssistWallCheck = true,
	AssistMode = "Hold",
	AssistKey = Enum.UserInputType.MouseButton2,
	AssistSwitchKey = Enum.KeyCode.C,

	-- Driver assist (vehicle testing, your own place)
	AFKOn = false,
	DriverOn = false,
	DriverSpeed = 40,   -- studs/second
	DriverAccel = 50,   -- acceleration/braking smoothness
	AvoidOn = false,
	AvoidDetect = 70,
	AvoidMinDist = 14,
	VehicleMinDist = 20,
	DodgeStrength = 60,
	SteerSmooth = 50,
	BrakeDist = 40,

	-- Look
	Theme = "Nebula",

	-- Keys
	AimKey = Enum.KeyCode.E,
	SwitchKey = Enum.KeyCode.Q,
	MenuKey = Enum.KeyCode.RightShift,
	FlyKey = Enum.KeyCode.F,
	TPKey = Enum.KeyCode.T,
}

-- settings that are never saved/loaded in profiles
local TRANSIENT = { Fly = true, CatchRadiusOn = true, ThrowArcOn = true }

local COLOR_PRESETS = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(70, 200, 255),
	Color3.fromRGB(90, 255, 120),
	Color3.fromRGB(255, 220, 70),
	Color3.fromRGB(255, 255, 255),
}
local colorIndex = 1

local TEXT = Color3.fromRGB(255, 255, 255)
local SUBTEXT = Color3.fromRGB(190, 190, 225)

----------------------------------------------------------------
-- Themes
----------------------------------------------------------------
local THEMES = {
	["Nebula"] = {
		accent = Color3.fromRGB(150, 110, 255), accent2 = Color3.fromRGB(70, 210, 255),
		bg0 = Color3.fromRGB(8, 7, 22), bg1 = Color3.fromRGB(20, 12, 46), bg2 = Color3.fromRGB(34, 14, 62),
		row = Color3.fromRGB(40, 34, 86), off = Color3.fromRGB(80, 74, 130),
	},
	["Aurora"] = {
		accent = Color3.fromRGB(40, 200, 140), accent2 = Color3.fromRGB(90, 190, 255),
		bg0 = Color3.fromRGB(4, 16, 20), bg1 = Color3.fromRGB(8, 30, 36), bg2 = Color3.fromRGB(10, 46, 46),
		row = Color3.fromRGB(18, 60, 62), off = Color3.fromRGB(60, 100, 104),
	},
	["Red Giant"] = {
		accent = Color3.fromRGB(255, 90, 70), accent2 = Color3.fromRGB(255, 180, 60),
		bg0 = Color3.fromRGB(22, 6, 8), bg1 = Color3.fromRGB(46, 12, 14), bg2 = Color3.fromRGB(70, 18, 16),
		row = Color3.fromRGB(84, 30, 32), off = Color3.fromRGB(120, 70, 70),
	},
	["Ocean"] = {
		accent = Color3.fromRGB(40, 150, 255), accent2 = Color3.fromRGB(80, 235, 235),
		bg0 = Color3.fromRGB(4, 10, 24), bg1 = Color3.fromRGB(8, 24, 52), bg2 = Color3.fromRGB(10, 40, 76),
		row = Color3.fromRGB(16, 52, 96), off = Color3.fromRGB(60, 90, 130),
	},
	["Sunset"] = {
		accent = Color3.fromRGB(255, 120, 80), accent2 = Color3.fromRGB(255, 80, 160),
		bg0 = Color3.fromRGB(24, 8, 22), bg1 = Color3.fromRGB(52, 14, 40), bg2 = Color3.fromRGB(80, 24, 50),
		row = Color3.fromRGB(88, 34, 62), off = Color3.fromRGB(130, 80, 100),
	},
	["Toxic"] = {
		accent = Color3.fromRGB(150, 255, 60), accent2 = Color3.fromRGB(230, 255, 90),
		bg0 = Color3.fromRGB(8, 14, 6), bg1 = Color3.fromRGB(16, 30, 10), bg2 = Color3.fromRGB(24, 46, 12),
		row = Color3.fromRGB(34, 62, 20), off = Color3.fromRGB(80, 110, 64),
	},
	["Sakura"] = {
		accent = Color3.fromRGB(255, 130, 190), accent2 = Color3.fromRGB(255, 200, 225),
		bg0 = Color3.fromRGB(26, 10, 22), bg1 = Color3.fromRGB(52, 20, 44), bg2 = Color3.fromRGB(78, 28, 62),
		row = Color3.fromRGB(92, 40, 74), off = Color3.fromRGB(140, 90, 118),
	},
	["Gold"] = {
		accent = Color3.fromRGB(255, 195, 50), accent2 = Color3.fromRGB(255, 235, 140),
		bg0 = Color3.fromRGB(16, 12, 4), bg1 = Color3.fromRGB(36, 28, 8), bg2 = Color3.fromRGB(58, 44, 10),
		row = Color3.fromRGB(70, 56, 18), off = Color3.fromRGB(116, 100, 62),
	},
	["Monochrome"] = {
		accent = Color3.fromRGB(235, 235, 235), accent2 = Color3.fromRGB(150, 150, 160),
		bg0 = Color3.fromRGB(8, 8, 10), bg1 = Color3.fromRGB(20, 20, 24), bg2 = Color3.fromRGB(34, 34, 40),
		row = Color3.fromRGB(44, 44, 52), off = Color3.fromRGB(86, 86, 96),
	},
	["Midnight"] = {
		accent = Color3.fromRGB(90, 100, 255), accent2 = Color3.fromRGB(170, 120, 255),
		bg0 = Color3.fromRGB(2, 2, 10), bg1 = Color3.fromRGB(8, 8, 28), bg2 = Color3.fromRGB(14, 12, 44),
		row = Color3.fromRGB(22, 22, 66), off = Color3.fromRGB(60, 62, 110),
	},
	["Lava"] = {
		accent = Color3.fromRGB(255, 60, 30), accent2 = Color3.fromRGB(255, 160, 20),
		bg0 = Color3.fromRGB(14, 2, 2), bg1 = Color3.fromRGB(36, 6, 4), bg2 = Color3.fromRGB(60, 12, 6),
		row = Color3.fromRGB(74, 20, 12), off = Color3.fromRGB(116, 62, 50),
	},
}
local THEME_ORDER = { "Nebula", "Aurora", "Red Giant", "Ocean", "Sunset", "Toxic", "Sakura", "Gold", "Monochrome", "Midnight", "Lava" }
local T = THEMES.Nebula
local themeFns = {}

local function themed(fn)
	fn()
	table.insert(themeFns, fn)
end

local function applyTheme(name)
	if not THEMES[name] then name = "Nebula" end
	S.Theme = name
	T = THEMES[name]
	for _, fn in ipairs(themeFns) do
		pcall(fn)
	end
end

-- controls register a function here so they can re-read S[...] (profiles, hotkeys)
local refreshers = {}
local function refreshUI()
	for _, fn in ipairs(refreshers) do
		pcall(fn)
	end
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function rainbowColor()
	return Color3.fromHSV((os.clock() * 0.25) % 1, 1, 1)
end

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function getAimPart(model)
	return model:FindFirstChild(S.TargetPart) or getRoot(model)
end

local function matches(input, key)
	return input.KeyCode == key or input.UserInputType == key
end

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = obj
	return c
end

----------------------------------------------------------------
-- GUI roots + notifications
----------------------------------------------------------------
local unloaded = false

local gui = Instance.new("ScreenGui")
gui.Name = "SpaceMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")

local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = gui

local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.AnchorPoint = Vector2.new(1, 0)
toastHolder.Position = UDim2.new(1, -14, 0, 14)
toastHolder.Size = UDim2.fromOffset(240, 300)
toastHolder.BackgroundTransparency = 1
toastHolder.ZIndex = 50
toastHolder.Parent = gui
do
	local tl = Instance.new("UIListLayout")
	tl.Padding = UDim.new(0, 6)
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Parent = toastHolder
end

local toastCount = 0
local function notify(text)
	if unloaded or not S.Notifications then return end
	toastCount += 1
	local toast = Instance.new("CanvasGroup")
	toast.Size = UDim2.fromOffset(230, 30)
	toast.BackgroundColor3 = Color3.fromRGB(14, 12, 34)
	toast.BorderSizePixel = 0
	toast.GroupTransparency = 1
	toast.LayoutOrder = toastCount
	toast.Parent = toastHolder
	corner(toast, 8)
	local st = Instance.new("UIStroke")
	st.Thickness = 1.5
	st.Color = T.accent
	st.Parent = toast
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(10, 0)
	l.Size = UDim2.new(1, -20, 1, 0)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 12
	l.TextColor3 = TEXT
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = toast
	TweenService:Create(toast, TweenInfo.new(0.2), { GroupTransparency = 0 }):Play()
	task.delay(2.2, function()
		pcall(function()
			local tw = TweenService:Create(toast, TweenInfo.new(0.3), { GroupTransparency = 1 })
			tw.Completed:Connect(function()
				toast:Destroy()
			end)
			tw:Play()
		end)
	end)
end

----------------------------------------------------------------
-- Target registry + ESP objects
----------------------------------------------------------------
local targets = {} -- [model] = data

local R15_BONES = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6_BONES = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local function newLine(parent)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.Visible = false
	f.ZIndex = 1
	f.Parent = parent
	return f
end

local function setLine(f, a, b, color)
	local d = b - a
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Size = UDim2.fromOffset(d.Magnitude, 1.5)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.BackgroundColor3 = color
	f.Visible = true
end

local function createESP(model, hum)
	local root = getRoot(model)
	local player = Players:GetPlayerFromCharacter(model)

	local hl = Instance.new("Highlight")
	hl.Name = "SpaceESP"
	hl.FillTransparency = 0.65
	hl.OutlineTransparency = 0
	hl.Adornee = model
	hl.Enabled = false
	hl.Parent = model

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 36)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = root
	bb.Enabled = false
	bb.Parent = espFolder

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = bb

	local hpBack = Instance.new("Frame")
	hpBack.Position = UDim2.new(0.1, 0, 0, 24)
	hpBack.Size = UDim2.new(0.8, 0, 0, 6)
	hpBack.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	hpBack.BackgroundTransparency = 0.2
	hpBack.BorderSizePixel = 0
	hpBack.Parent = bb
	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBack

	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.ZIndex = 1
	box.Parent = espFolder
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Thickness = 1.5
	boxStroke.Parent = box

	return {
		hum = hum, hl = hl, bb = bb, label = label,
		hpBack = hpBack, hpFill = hpFill,
		box = box, boxStroke = boxStroke,
		tracer = newLine(espFolder), skel = {},
		player = player,
		isPlayer = player ~= nil,
		name = player and player.DisplayName or model.Name,
	}
end

local function destroyESP(data)
	if data.hl then data.hl:Destroy() end
	if data.bb then data.bb:Destroy() end
	if data.box then data.box:Destroy() end
	if data.tracer then data.tracer:Destroy() end
	for _, l in ipairs(data.skel) do l:Destroy() end
end

local function passesTypeFilter(data)
	if data.isPlayer then return S.ShowPlayers end
	return S.ShowNPCs
end

local function isTeammate(data)
	if not S.TeamCheck or not data.player then return false end
	return LP.Team ~= nil and data.player.Team == LP.Team
end

local function refreshTargets()
	local seen = {}
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("Humanoid") then
			local m = d.Parent
			if m and m:IsA("Model") and m ~= LP.Character and d.Health > 0 and getRoot(m) then
				seen[m] = true
				if not targets[m] then
					targets[m] = createESP(m, d)
				end
			end
		end
	end
	for m, data in pairs(targets) do
		if not seen[m] or not m:IsDescendantOf(Workspace) then
			destroyESP(data)
			targets[m] = nil
		end
	end
end

local function hideScreen(data)
	data.box.Visible = false
	data.tracer.Visible = false
	for _, l in ipairs(data.skel) do l.Visible = false end
end

local function updateSkeleton(model, data, color)
	local list = model:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
	for i, pair in ipairs(list) do
		local line = data.skel[i]
		if not line then
			line = newLine(espFolder)
			data.skel[i] = line
		end
		local pa, pb = model:FindFirstChild(pair[1]), model:FindFirstChild(pair[2])
		if pa and pb and pa:IsA("BasePart") and pb:IsA("BasePart") then
			local a = Camera:WorldToViewportPoint(pa.Position)
			local b = Camera:WorldToViewportPoint(pb.Position)
			if a.Z > 0 and b.Z > 0 then
				setLine(line, Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), color)
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end
	for i = #list + 1, #data.skel do
		data.skel[i].Visible = false
	end
end

local function updateESP(color, myRoot)
	local vp = Camera.ViewportSize
	for model, data in pairs(targets) do
		local root = getRoot(model)
		local hum = data.hum
		local show = false
		local dist = 0
		if S.ESP and root and hum.Health > 0 and passesTypeFilter(data) and not isTeammate(data) then
			dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
			show = dist <= S.ESPMaxDist
		end

		data.hl.Enabled = show
		data.bb.Enabled = show and (S.ShowNames or S.HealthBars)

		if not show then
			hideScreen(data)
		else
			data.hl.DepthMode = S.Wallhack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
			data.hl.FillColor = color
			data.hl.OutlineColor = color
			data.bb.AlwaysOnTop = S.Wallhack
			data.label.Visible = S.ShowNames
			data.hpBack.Visible = S.HealthBars
			if S.ShowNames then
				data.label.Text = string.format("%s  [%d HP]  %dm", data.name, math.floor(hum.Health), math.floor(dist))
				data.label.TextColor3 = color
			end
			if S.HealthBars then
				local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
				data.hpFill.Size = UDim2.fromScale(r, 1)
				data.hpFill.BackgroundColor3 = Color3.fromHSV(r * 0.33, 1, 1)
			end

			local rp, onScreen = Camera:WorldToViewportPoint(root.Position)
			local visible = onScreen and rp.Z > 0

			if S.Boxes and visible then
				local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.8, 0))
				local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
				local h = math.abs(bottom.Y - top.Y)
				local w = h * 0.55
				data.box.Position = UDim2.fromOffset(rp.X - w / 2, math.min(top.Y, bottom.Y))
				data.box.Size = UDim2.fromOffset(w, h)
				data.boxStroke.Color = color
				data.box.Visible = true
			else
				data.box.Visible = false
			end

			if S.Tracers and visible then
				setLine(data.tracer, Vector2.new(vp.X / 2, vp.Y), Vector2.new(rp.X, rp.Y), color)
			else
				data.tracer.Visible = false
			end

			if S.Skeletons then
				updateSkeleton(model, data, color)
			else
				for _, l in ipairs(data.skel) do l.Visible = false end
			end
		end
	end
end

----------------------------------------------------------------
-- Aim logic
----------------------------------------------------------------
local aimHeld = false
local switchRequested = false
local currentTarget = nil
local visited = {}
local spectateModel = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function hasLineOfSight(part, model)
	local ignore = { model }
	if LP.Character then table.insert(ignore, LP.Character) end
	local origin = Camera.CFrame.Position
	local dir = part.Position - origin

	for _ = 1, 6 do
		rayParams.FilterDescendantsInstances = ignore
		local result = Workspace:Raycast(origin, dir, rayParams)
		if not result then return true end
		local hit = result.Instance
		if hit.Transparency >= 0.95 or (hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")) then
			table.insert(ignore, hit)
			origin = result.Position
			dir = part.Position - origin
		else
			return false
		end
	end
	return true
end

local aimStats = { seen = 0, offscreen = 0, fov = 0, wall = 0 }

local function getCandidates(ignoreFOV)
	local list = {}
	aimStats.seen, aimStats.offscreen, aimStats.fov, aimStats.wall = 0, 0, 0, 0
	local mouse = UIS:GetMouseLocation()
	for model, data in pairs(targets) do
		if data.hum.Health > 0 and passesTypeFilter(data) and not isTeammate(data) then
			aimStats.seen += 1
			local part = getAimPart(model)
			if part then
				local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen and pos.Z > 0 then
					local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
					if not (ignoreFOV or not S.FOVEnabled or d <= S.FOVRadius) then
						aimStats.fov += 1
					elseif S.WallCheck and not hasLineOfSight(part, model) then
						aimStats.wall += 1
					else
						table.insert(list, { model = model, dist = d })
					end
				else
					aimStats.offscreen += 1
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.dist < b.dist end)
	return list
end

----------------------------------------------------------------
-- FOV circle
----------------------------------------------------------------
local fov = Instance.new("Frame")
fov.Name = "FOVCircle"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.BackgroundTransparency = 1
fov.Visible = false
fov.Parent = gui
corner(fov, 999).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.5
fovStroke.Color = Color3.new(1, 1, 1)
fovStroke.Parent = fov

----------------------------------------------------------------
-- Feature logic (called from UI)
----------------------------------------------------------------
-- Test dummies (client-side only, anchored, show up as NPC targets)
local dummyFolder
local dummyCount = 0

local function spawnDummy()
	local char = LP.Character
	local root = char and getRoot(char)
	if not root then
		notify("No character yet")
		return
	end
	if not dummyFolder or not dummyFolder.Parent then
		dummyFolder = Instance.new("Folder")
		dummyFolder.Name = "SpaceMenuDummies"
		dummyFolder.Parent = Workspace
	end
	dummyCount += 1
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
	flat = flat.Unit
	local pos = root.Position + flat * 12
	local base = CFrame.lookAt(pos, Vector3.new(root.Position.X, pos.Y, root.Position.Z))

	local m = Instance.new("Model")
	m.Name = "Dummy " .. dummyCount
	local function part(name, size, offset)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = Color3.fromRGB(163, 162, 
