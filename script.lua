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
		p.Color = Color3.fromRGB(163, 162, 165)
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = base * CFrame.new(offset)
		p.Parent = m
		return p
	end
	local dummyRoot = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
	dummyRoot.Transparency = 1
	dummyRoot.CanCollide = false
	part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
	part("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0))
	part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0))
	part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0))
	part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
	part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 100
	hum.Health = 100
	hum.Parent = m
	m.PrimaryPart = dummyRoot
	m.Parent = dummyFolder
	notify("Spawned " .. m.Name)
end

local function clearDummies()
	if dummyFolder then
		dummyFolder:ClearAllChildren()
	end
	notify("Dummies cleared")
end

-- Spectate
local function stopSpectate()
	spectateModel = nil
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		Camera.CameraSubject = hum
	end
end

local function spectateNext()
	local list = {}
	for model, data in pairs(targets) do
		if data.hum.Health > 0 then
			table.insert(list, model)
		end
	end
	table.sort(list, function(a, b)
		return targets[a].name < targets[b].name
	end)
	if #list == 0 then
		notify("Nothing to spectate")
		return
	end
	local idx = spectateModel and table.find(list, spectateModel) or 0
	idx = idx % #list + 1
	spectateModel = list[idx]
	Camera.CameraSubject = targets[spectateModel].hum
	notify("Spectating " .. targets[spectateModel].name)
end

-- Movement helpers
local function unstuck()
	local char = LP.Character
	local root = char and getRoot(char)
	if root then
		S.Fly = false
		refreshUI()
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = root.CFrame + Vector3.new(0, 8, 0)
		notify("Popped up 8 studs")
	end
end

local function clickTP()
	local char = LP.Character
	local root = char and getRoot(char)
	if not root then return end
	local m = UIS:GetMouseLocation()
	local ray = Camera:ViewportPointToRay(m.X, m.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local res = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if res then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(res.Position + Vector3.new(0, 4, 0)) * (root.CFrame - root.CFrame.Position)
		notify("Teleported")
	else
		notify("No surface under cursor")
	end
end

-- Dev server (your own place only, see SpaceDevServer.lua)
local dev = { remote = nil, ok = false, config = {} }

local function devCall(action, ...)
	if not dev.ok then
		notify("Dev server not available (own place only)")
		return nil
	end
	local args = { ... }
	local ok, res = pcall(function()
		return dev.remote:InvokeServer(action, table.unpack(args))
	end)
	if not ok then
		notify("Dev server error")
		return nil
	end
	return res
end

-- Profiles (file API if present, your dev server if connected, else this session only)
local PROFILE_FILE = "SpaceMenu_Profiles.json"
local profiles = {} -- name -> encoded settings table
local hasFiles = (writefile ~= nil) and (readfile ~= nil) and (isfile ~= nil)

local function encodeSettings()
	local out = {}
	for k, v in pairs(S) do
		if not TRANSIENT[k] then
			local t = typeof(v)
			if t == "boolean" or t == "number" or t == "string" then
				out[k] = v
			elseif t == "Color3" then
				out[k] = { c = { v.R, v.G, v.B } }
			elseif t == "EnumItem" then
				out[k] = { e = tostring(v.EnumType), n = v.Name }
			end
		end
	end
	return out
end

local function decodeInto(data)
	for k, v in pairs(data) do
		if S[k] ~= nil and not TRANSIENT[k] then
			local t = typeof(S[k])
			if (t == "boolean" or t == "number" or t == "string") and typeof(v) == t then
				S[k] = v
			elseif t == "Color3" and type(v) == "table" and type(v.c) == "table" then
				S[k] = Color3.new(v.c[1], v.c[2], v.c[3])
			elseif t == "EnumItem" and type(v) == "table" and v.e and v.n then
				local ok, item = pcall(function()
					return Enum[v.e][v.n]
				end)
				if ok and item then S[k] = item end
			end
		end
	end
end

local function persistProfiles()
	if hasFiles then
		pcall(function()
			writefile(PROFILE_FILE, HttpService:JSONEncode(profiles))
		end)
	end
	if dev.ok then
		pcall(function()
			dev.remote:InvokeServer("setProfiles", profiles)
		end)
	end
end

local function loadPersistedProfiles()
	if hasFiles then
		local ok, res = pcall(function()
			if isfile(PROFILE_FILE) then
				return HttpService:JSONDecode(readfile(PROFILE_FILE))
			end
			return nil
		end)
		if ok and type(res) == "table" then
			for k, v in pairs(res) do profiles[k] = v end
		end
	end
	if dev.ok then
		local ok, res = pcall(function()
			return dev.remote:InvokeServer("getProfiles")
		end)
		if ok and type(res) == "table" then
			for k, v in pairs(res) do
				if profiles[k] == nil then profiles[k] = v end
			end
		end
	end
end

loadPersistedProfiles()

----------------------------------------------------------------
-- Main window
----------------------------------------------------------------
local main = Instance.new("CanvasGroup")
main.Name = "Main"
main.Size = UDim2.fromOffset(400, 500)
main.Position = UDim2.new(0.5, -200, 0.5, -250)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.GroupTransparency = 1
main.Visible = false
main.ZIndex = 20
main.Parent = gui
corner(main, 14)

local bgFrame = Instance.new("Frame")
bgFrame.Name = "Backdrop"
bgFrame.Size = UDim2.fromScale(1, 1)
bgFrame.BackgroundColor3 = Color3.new(1, 1, 1)
bgFrame.BorderSizePixel = 0
bgFrame.ZIndex = 0
bgFrame.Parent = main
local bgGrad = Instance.new("UIGradient")
bgGrad.Rotation = 90
bgGrad.Parent = bgFrame
themed(function()
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.bg0),
		ColorSequenceKeypoint.new(0.55, T.bg1),
		ColorSequenceKeypoint.new(1, T.bg2),
	})
end)

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.Color = Color3.new(1, 1, 1)
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = main
local strokeGrad = Instance.new("UIGradient")
strokeGrad.Parent = mainStroke
themed(function()
	strokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.accent),
		ColorSequenceKeypoint.new(0.5, T.accent2),
		ColorSequenceKeypoint.new(1, T.accent),
	})
end)
task.spawn(function()
	while main.Parent and not unloaded do
		strokeGrad.Rotation = (os.clock() * 40) % 360
		task.wait()
	end
end)

local scale = Instance.new("UIScale")
scale.Scale = 0.92
scale.Parent = main

-- starfield
local starLayer = Instance.new("Frame")
starLayer.Name = "Stars"
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundTransparency = 1
starLayer.ZIndex = 0
starLayer.Parent = main

local stars = {}
local rng = Random.new(1337)
for i = 1, 70 do
	local s = Instance.new("Frame")
	local size = rng:NextInteger(1, 3)
	s.Size = UDim2.fromOffset(size, size)
	s.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
	s.BackgroundColor3 = (i % 7 == 0) and Color3.fromRGB(150, 220, 255) or Color3.new(1, 1, 1)
	s.BackgroundTransparency = rng:NextNumber(0.1, 0.8)
	s.BorderSizePixel = 0
	s.ZIndex = 0
	s.Parent = starLayer
	corner(s, 3).CornerRadius = UDim.new(1, 0)
	stars[i] = s
end

local planet = Instance.new("Frame")
planet.Size = UDim2.fromOffset(46, 46)
planet.Position = UDim2.new(1, -70, 1, -78)
planet.BackgroundColor3 = Color3.new(1, 1, 1)
planet.BackgroundTransparency = 0.35
planet.BorderSizePixel = 0
planet.ZIndex = 0
planet.Parent = starLayer
corner(planet, 23).CornerRadius = UDim.new(1, 0)
local planetGrad = Instance.new("UIGradient")
planetGrad.Rotation = 45
planetGrad.Parent = planet
themed(function()
	planetGrad.Color = ColorSequence.new(T.accent, T.accent2)
end)

task.spawn(function()
	while main.Parent and not unloaded do
		for _ = 1, 4 do
			local s = stars[rng:NextInteger(1, #stars)]
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(0.4, 1.2), Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut, 0, true), { BackgroundTransparency = rng:NextNumber(0.0, 0.95) }):Play()
		end
		task.wait(0.25)
	end
end)

-- title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(14, 10, 34)
title.BackgroundTransparency = 0.1
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "  ✦ SPACE MENU  •  made by K-Den!"
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = main

local titleLine = Instance.new("Frame")
titleLine.Size = UDim2.new(1, 0, 0, 2)
titleLine.Position = UDim2.new(0, 0, 1, -2)
titleLine.BackgroundColor3 = Color3.new(1, 1, 1)
titleLine.BorderSizePixel = 0
titleLine.ZIndex = 4
titleLine.Parent = title
local titleGrad = Instance.new("UIGradient")
titleGrad.Parent = titleLine
themed(function()
	titleGrad.Color = ColorSequence.new(T.accent, T.accent2)
end)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -12, 0, 12)
hint.Position = UDim2.new(0, 0, 1, -16)
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextColor3 = SUBTEXT
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.ZIndex = 4
hint.Parent = main
local function updateHint()
	hint.Text = S.MenuKey.Name .. " hide  |  " .. S.FlyKey.Name .. " fly"
end
updateHint()
table.insert(refreshers, updateHint)

do -- dragging
	local dragging, dragStart, startPos
	title.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, main.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

----------------------------------------------------------------
-- Tabs + pages
----------------------------------------------------------------
local TABS = { "ESP", "Aim", "Move", "Visual", "Tools", "Settings" }
local pageList = {}
local tabBtns = {}
local currentTab = "ESP"
local cur -- the page currently being built

local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.fromOffset(8, 46)
tabBar.Size = UDim2.new(1, -16, 0, 28)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 3
tabBar.Parent = main

local function paintTabs()
	for n, b in pairs(tabBtns) do
		b.BackgroundColor3 = (n == currentTab) and T.accent or T.row
	end
end
themed(paintTabs)

local function showTab(name)
	currentTab = name
	for n, p in pairs(pageList) do
		p.frame.Visible = (n == name)
	end
	paintTabs()
end

for i, name in ipairs(TABS) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / #TABS, -4, 1, 0)
	b.Position = UDim2.new((i - 1) / #TABS, 2, 0, 0)
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = TEXT
	b.Text = name
	b.ZIndex = 4
	b.Parent = tabBar
	corner(b, 7)
	b.Activated:Connect(function()
		showTab(name)
	end)
	tabBtns[name] = b

	local sf = Instance.new("ScrollingFrame")
	sf.Name = name
	sf.Position = UDim2.fromOffset(8, 80)
	sf.Size = UDim2.new(1, -16, 1, -100)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 3
	sf.CanvasSize = UDim2.new()
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Visible = false
	sf.ZIndex = 2
	sf.Parent = main
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = sf
	themed(function()
		sf.ScrollBarImageColor3 = T.accent2
	end)
	pageList[name] = { frame = sf, order = 0 }
end

local function nextOrder()
	cur.order += 1
	return cur.order
end

----------------------------------------------------------------
-- UI builders (all add to `cur`)
----------------------------------------------------------------
local function newRow(h)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, h)
	row.BackgroundTransparency = 0.05
	row.BorderSizePixel = 0
	row.LayoutOrder = nextOrder()
	row.ZIndex = 2
	row.Parent = cur.frame
	corner(row, 8)
	local st = Instance.new("UIStroke")
	st.Transparency = 0.6
	st.Parent = row
	themed(function()
		row.BackgroundColor3 = T.row
		st.Color = T.accent
	end)
	return row
end

local function rowLabel(row, text)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(12, 0)
	l.Size = UDim2.new(1, -110, 0, 32)
	l.Font = Enum.Font.Gotham
	l.TextSize = 13
	l.TextColor3 = TEXT
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.ZIndex = 3
	l.Parent = row
	return l
end

local function addSection(text)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = nextOrder()
	l.Size = UDim2.new(1, -6, 0, 22)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = "✦ " .. string.upper(text)
	l.ZIndex = 3
	l.Parent = cur.frame
	themed(function()
		l.TextColor3 = T.accent2
	end)
end

local function addNotice(text, h)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -6, 0, h or 44)
	f.BackgroundColor3 = Color3.fromRGB(70, 30, 10)
	f.BackgroundTransparency = 0.05
	f.BorderSizePixel = 0
	f.LayoutOrder = nextOrder()
	f.ZIndex = 2
	f.Parent = cur.frame
	corner(f, 8)
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 170, 40)
	st.Thickness = 1.5
	st.Parent = f
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(10, 0)
	l.Size = UDim2.new(1, -20, 1, 0)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 12
	l.TextWrapped = true
	l.TextColor3 = Color3.fromRGB(255, 200, 80)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.ZIndex = 3
	l.Parent = f
end

local function addInfo(text, h)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = nextOrder()
	l.Size = UDim2.new(1, -6, 0, h or 20)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextSize = 12
	l.TextWrapped = true
	l.TextColor3 = SUBTEXT
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.Text = text
	l.ZIndex = 3
	l.Parent = cur.frame
	return l
end

local tInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- `silent` = skip the generic ON/OFF toast (major systems announce themselves)
local function addToggle(text, key, silent)
	local row = newRow(32)
	rowLabel(row, text)

	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -12, 0.5, 0)
	track.Size = UDim2.fromOffset(40, 20)
	track.BorderSizePixel = 0
	track.ZIndex = 3
	track.Parent = row
	corner(track, 10)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.ZIndex = 4
	knob.Parent = track
	corner(knob, 8)

	local function render(animate)
		local on = S[key]
		local goalTrack = { BackgroundColor3 = on and T.accent or T.off }
		local goalKnob = { Position = on and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) }
		if animate then
			TweenService:Create(track, tInfo, goalTrack):Play()
			TweenService:Create(knob, tInfo, goalKnob):Play()
		else
			track.BackgroundColor3 = goalTrack.BackgroundColor3
			knob.Position = goalKnob.Position
		end
	end
	local function refresh()
		render(false)
	end
	themed(refresh)
	table.insert(refreshers, refresh)

	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.fromScale(1, 1)
	btn.Text = ""
	btn.ZIndex = 5
	btn.Parent = row
	btn.Activated:Connect(function()
		S[key] = not S[key]
		render(true)
		if not silent then
			notify(text .. (S[key] and ": ON" or ": OFF"))
		end
	end)
end

local function addSlider(text, key, min, max)
	local row = newRow(48)
	local lbl = rowLabel(row, text)
	lbl.Size = UDim2.new(1, -90, 0, 30)
	local val = Instance.new("TextLabel")
	val.BackgroundTransparency = 1
	val.AnchorPoint = Vector2.new(1, 0)
	val.Position = UDim2.new(1, -12, 0, 0)
	val.Size = UDim2.fromOffset(60, 32)
	val.Font = Enum.Font.GothamBold
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.ZIndex = 3
	val.Parent = row

	local bar = Instance.new("Frame")
	bar.Position = UDim2.new(0, 12, 0, 34)
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.BorderSizePixel = 0
	bar.ZIndex = 3
	bar.Parent = row
	corner(bar, 3)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 4
	fill.Parent = bar
	corner(fill, 3)
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Parent = fill
	themed(function()
		bar.BackgroundColor3 = T.off
		val.TextColor3 = T.accent2
		fillGrad.Color = ColorSequence.new(T.accent, T.accent2)
	end)

	local function set(v, animate)
		v = math.clamp(math.floor(v + 0.5), min, max)
		S[key] = v
		val.Text = tostring(v)
		local size = UDim2.fromScale((v - min) / (max - min), 1)
		if animate then
			TweenService:Create(fill, TweenInfo.new(0.06), { Size = size }):Play()
		else
			fill.Size = size
		end
	end
	set(S[key], false)
	table.insert(refreshers, function()
		set(S[key], false)
	end)

	local dragging = false
	local function fromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		set(min + rel * (max - min), true)
	end

	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Position = UDim2.new(0, 0, 0, 28)
	hit.Size = UDim2.new(1, 0, 0, 20)
	hit.ZIndex = 5
	hit.Parent = row
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(i.Position.X)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			fromX(i.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function styleButton(b)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = TEXT
	b.AutoButtonColor = true
	b.ZIndex = 4
	corner(b, 6)
	local bs = Instance.new("UIStroke")
	bs.Thickness = 1.5
	bs.Parent = b
	themed(function()
		b.BackgroundColor3 = T.accent
		bs.Color = T.accent2
	end)
end

local function addButton(text, getLabel, onClick)
	local row = newRow(32)
	rowLabel(row, text)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -8, 0.5, 0)
	b.Size = UDim2.fromOffset(100, 24)
	b.Text = getLabel()
	b.Parent = row
	styleButton(b)
	b.Activated:Connect(function()
		onClick(b)
		b.Text = getLabel()
	end)
	table.insert(refreshers, function()
		b.Text = getLabel()
	end)
	return b
end

local listening -- { key = "AimKey", btn = TextButton }
local function addBind(text, key)
	addButton(text, function()
		return S[key].Name
	end, function(btn)
		listening = { key = key, btn = btn }
		btn.Text = "press key..."
	end)
end

local function addButtons3(a, fa, b, fb, c, fc)
	local row = newRow(32)
	local defs = { { a, fa }, { b, fb }, { c, fc } }
	for i, d in ipairs(defs) do
		local btn = Instance.new("TextButton")
		btn.Position = UDim2.new((i - 1) / 3, 6, 0.5, -12)
		btn.Size = UDim2.new(1 / 3, -10, 0, 24)
		btn.Text = d[1]
		btn.Parent = row
		styleButton(btn)
		btn.Activated:Connect(d[2])
	end
end

local function addTextBox(text, default)
	local row = newRow(32)
	local lbl = rowLabel(row, text)
	lbl.Size = UDim2.new(0.4, 0, 0, 32)
	local tb = Instance.new("TextBox")
	tb.AnchorPoint = Vector2.new(1, 0.5)
	tb.Position = UDim2.new(1, -8, 0.5, 0)
	tb.Size = UDim2.new(0.55, 0, 0, 24)
	tb.BackgroundColor3 = Color3.fromRGB(14, 12, 34)
	tb.BorderSizePixel = 0
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 12
	tb.TextColor3 = TEXT
	tb.PlaceholderColor3 = SUBTEXT
	tb.Text = default or ""
	tb.ClearTextOnFocus = false
	tb.ZIndex = 4
	tb.Parent = row
	corner(tb, 6)
	return tb
end

----------------------------------------------------------------
-- ESP tab
----------------------------------------------------------------
cur = pageList.ESP
addSection("ESP")
addToggle("ESP", "ESP")
addToggle("Rainbow ESP", "Rainbow")
addToggle("Wallhack (see through walls)", "Wallhack")
addToggle("Names / HP / distance", "ShowNames")
addToggle("Health bars", "HealthBars")
addToggle("Boxes", "Boxes")
addToggle("Skeletons", "Skeletons")
addToggle("Tracer lines", "Tracers")
addSection("Filters")
addToggle("Players", "ShowPlayers")
addToggle("NPCs", "ShowNPCs")
addToggle("Team check (hide teammates)", "TeamCheck")
addSlider("ESP max distance", "ESPMaxDist", 50, 2000)
addButton("ESP color", function() return "Cycle" end, function()
	colorIndex = colorIndex % #COLOR_PRESETS + 1
	S.ESPColor = COLOR_PRESETS[colorIndex]
end)

----------------------------------------------------------------
-- Aim tab
----------------------------------------------------------------
cur = pageList.Aim
local status = addInfo("Target: none", 34)
addSection("Aim-lock")
addToggle("Aim-lock", "Aimlock")
addToggle("FOV circle (on/off)", "FOVEnabled")
addSlider("FOV radius", "FOVRadius", 30, 500)
addToggle("Hard lock (no aim drift)", "HardLock")
addSlider("Smoothing (when hard lock off)", "Smoothing", 0, 95)
addToggle("Wall check (aim only visible)", "WallCheck")
addButton("Target part", function() return S.TargetPart end, function()
	S.TargetPart = (S.TargetPart == "Head") and "HumanoidRootPart" or "Head"
end)
addButton("Aim mode", function() return S.AimMode end, function()
	S.AimMode = (S.AimMode == "Hold") and "Toggle" or "Hold"
	aimHeld = false
end)
addBind("Aim key", "AimKey")
addBind("Switch target key", "SwitchKey")

-- Aim Assist (smooth camera pull)
local AX = {} -- shared between the new UI and the new logic blocks
addSection("Aim Assist")
AX.status = addInfo("Assist: off", 20)
addToggle("Aim Assist", "AssistOn", true)
addToggle("FOV-based target selection", "AssistFOVOn")
addSlider("Assist FOV radius", "AssistFOV", 20, 500)
addToggle("Small FOV indicator", "AssistIndicator")
addSlider("Assist strength", "AssistStrength", 1, 100)
addSlider("Smoothing", "AssistSmooth", 0, 95)
addSlider("Max assist distance", "AssistMaxDist", 20, 2000)
addButton("Target part", function() return S.AssistPart end, function()
	S.AssistPart = (S.AssistPart == "Head") and "HumanoidRootPart" or "Head"
end)
addToggle("Team check", "AssistTeamCheck")
addToggle("Wall / visibility check", "AssistWallCheck")
addButton("Activation mode", function() return S.AssistMode end, function()
	S.AssistMode = (S.AssistMode == "Hold") and "Toggle" or "Hold"
	AX.held = false
end)
addBind("Assist key", "AssistKey")
addBind("Assist switch target key", "AssistSwitchKey")

----------------------------------------------------------------
-- Move tab
----------------------------------------------------------------
local WARN = "⚠ WARNING: This may not work in some games. Anti-cheat can block it or kick you. Safest in your own place / Studio."

cur = pageList.Move
addSection("Speed")
addToggle("WalkSpeed", "WalkSpeedOn")
addSlider("WalkSpeed value", "WalkSpeed", 16, 150)
addSection("Flight")
addToggle("Fly", "Fly")
addSlider("Fly speed", "FlySpeed", 10, 250)
addBind("Fly key", "FlyKey")
addNotice(WARN)
addToggle("Noclip", "Noclip")
addToggle("Infinite jump", "InfJump")
addToggle("Invisible (only you see this)", "Invisible")
addSection("Teleport")
addToggle("Click teleport", "ClickTP")
addBind("Teleport key", "TPKey")
addButton("Unstuck (pop up)", function() return "Click" end, unstuck)
addNotice(WARN)
addSection("Spectate")
addButton("Spectate next", function() return "Next" end, spectateNext)
addButton("Stop spectating", function() return "Stop" end, stopSpectate)

----------------------------------------------------------------
-- Visual tab
----------------------------------------------------------------
cur = pageList.Visual
addSection("Lighting")
addToggle("Fullbright", "Fullbright")
addToggle("Time of day override", "TimeOn")
addSlider("Time of day (hour)", "TimeOfDay", 0, 24)
addSection("Camera")
addToggle("Custom camera FOV", "CamFOVOn")
addSlider("Camera FOV", "CamFOV", 40, 120)
addToggle("Unlock third-person zoom", "ZoomUnlock")
addSlider("Max zoom distance", "ZoomMax", 20, 1000)
addSection("Crosshair")
addToggle("Crosshair overlay", "Crosshair")
addSlider("Crosshair size", "CrosshairSize", 4, 40)

----------------------------------------------------------------
-- Tools tab
----------------------------------------------------------------
cur = pageList.Tools
addSection("Test dummies")
addInfo("Spawns local-only dummy NPCs in front of you to test ESP and aim.", 34)
addButton("Spawn dummy", function() return "Spawn" end, spawnDummy)
addButton("Remove all dummies", function() return "Clear" end, clearDummies)
addSection("Dev tools (your own place)")
addNotice("These only work if SpaceDevServer.lua is installed in YOUR place and you are its owner (or you're in Studio). Anywhere else they stay disabled.", 56)
local devStatusLabel = addInfo("Dev server: checking...", 20)
addButton("Respawn ball", function() return "Respawn" end, function()
	local r = devCall("respawnBall")
	if r then notify(r.msg or "Done") end
end)
addButton("Set ball home here", function() return "Set" end, function()
	local r = devCall("setHome")
	if r then notify(r.msg or "Done") end
end)
addButton("Teleport me to ball", function() return "Teleport" end, function()
	local r = devCall("tpToBall")
	if r then notify(r.msg or "Done") end
end)
addToggle("Catch radius preview", "CatchRadiusOn")
addSlider("Catch radius (studs)", "CatchRadius", 2, 40)
addToggle("Throw arc preview", "ThrowArcOn")
addSlider("Throw speed", "ThrowSpeed", 10, 150)
addSlider("Throw angle (deg)", "ThrowAngle", 5, 80)
addSection("Weapon control (your own place)")
addInfo("Writes RecoilScale / SpreadScale attributes on your equipped tool. Your weapon script must read them.", 46)
addToggle("Recoil + spread reduction", "RecoilOn")
addSlider("Recoil remaining (%)", "RecoilScale", 0, 100)
addSlider("Spread remaining (%)", "SpreadScale", 0, 100)

-- Driver Assist (vehicle testing)
addSection("Driver Assist")
addNotice("For testing in YOUR place. Sit in a VehicleSeat first. Any manual W/A/S/D, arrow key or thumbstick input instantly turns Auto Driver off.", 56)
AX.driverStatus = addInfo("Driver: off", 20)
addToggle("Auto Driver", "DriverOn", true)
addSlider("Target speed (studs/s)", "DriverSpeed", 5, 150)
addSlider("Acceleration smoothness", "DriverAccel", 1, 100)
addSection("AFK Prevention")
addToggle("AFK Prevention", "AFKOn", true)
addInfo("Keeps you active while seated. Stops when you leave the vehicle.", 20)
addSection("Vehicle Avoidance")
addToggle("Automatic avoidance", "AvoidOn", true)
addSlider("Minimum safe distance", "AvoidMinDist", 4, 60)
addSection("Dodge Settings")
addSlider("Dodge strength", "DodgeStrength", 10, 100)
addSlider("Detection distance", "AvoidDetect", 15, 200)
addSlider("Steering smoothness", "SteerSmooth", 0, 100)
addSlider("Braking distance", "BrakeDist", 10, 150)
addSlider("Minimum vehicle distance", "VehicleMinDist", 4, 80)

----------------------------------------------------------------
-- Settings tab
----------------------------------------------------------------
cur = pageList.Settings
addSection("Look")
addButton("Theme", function() return S.Theme end, function()
	local i = table.find(THEME_ORDER, S.Theme) or 0
	applyTheme(THEME_ORDER[i % #THEME_ORDER + 1])
	notify("Theme: " .. S.Theme)
end)
addBind("Menu key", "MenuKey")
addSection("Overlays")
addToggle("Notifications", "Notifications")
addToggle("Active features list", "ActiveList")
addToggle("Stats panel (FPS / ping)", "StatsPanel")
addSection("Profiles")
local profileBox = addTextBox("Profile name", "default")
local profileInfo = addInfo("", 52)

local function storageText()
	local parts = {}
	if hasFiles then table.insert(parts, "file") end
	if dev.ok then table.insert(parts, "your server") end
	if #parts == 0 then
		return "this session only (no file API or dev server found)"
	end
	return table.concat(parts, " + ")
end

local function refreshProfileList()
	local names = {}
	for n in pairs(profiles) do table.insert(names, n) end
	table.sort(names)
	profileInfo.Text = "Saved: " .. (#names > 0 and table.concat(names, ", ") or "(none)")
		.. "\nStorage: " .. storageText()
end
refreshProfileList()

local function profileName()
	local n = string.gsub(profileBox.Text, "^%s*(.-)%s*$", "%1")
	return n
end

addButtons3("Save", function()
	local n = profileName()
	if n == "" then notify("Type a profile name first") return end
	profiles[n] = encodeSettings()
	persistProfiles()
	refreshProfileList()
	notify("Saved profile: " .. n)
end, "Load", function()
	local n = profileName()
	local p = profiles[n]
	if not p then notify("No profile named " .. n) return end
	decodeInto(p)
	applyTheme(S.Theme)
	refreshUI()
	notify("Loaded profile: " .. n)
end, "Delete", function()
	local n = profileName()
	if not profiles[n] then notify("No profile named " .. n) return end
	profiles[n] = nil
	persistProfiles()
	refreshProfileList()
	notify("Deleted profile: " .. n)
end)

addSection("Menu")
addButton("Destroy menu", function() return "Unload" end, function()
	for k, v in pairs(S) do
		if type(v) == "boolean" then S[k] = false end
	end
	unloaded = true
	task.wait(0.1)
	pcall(function() RunService:UnbindFromRenderStep("SpaceMenuUpdate") end)
	pcall(stopSpectate)
	for _, d in pairs(targets) do destroyESP(d) end
	if dummyFolder then dummyFolder:Destroy() end
	gui:Destroy()
end)

showTab("ESP")
refreshUI()

-- menu open/close animation
local menuOpen = false
local function setMenu(open)
	menuOpen = open
	if open then main.Visible = true end
	TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ GroupTransparency = open and 0 or 1 }):Play()
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = open and 1 or 0.92 }):Play()
	if not open then
		task.delay(0.26, function()
			if not menuOpen then main.Visible = false end
		end)
	end
end
setMenu(true)

----------------------------------------------------------------
-- Input
----------------------------------------------------------------
local function isOverMenu()
	if not main.Visible then return false end
	local m = UIS:GetMouseLocation()
	local p, s = main.AbsolutePosition, main.AbsoluteSize
	return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end

local function isKeyHeld(key)
	if key.EnumType == Enum.KeyCode then
		return UIS:IsKeyDown(key)
	end
	return UIS:IsMouseButtonPressed(key) and not isOverMenu()
end

UIS.InputBegan:Connect(function(input, gp)
	-- key rebinding
	if listening then
		if input.KeyCode == Enum.KeyCode.Escape then
			listening.btn.Text = S[listening.key].Name
			listening = nil
			return
		end
		local v
		if input.UserInputType == Enum.UserInputType.Keyboard then
			v = input.KeyCode
		elseif input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3 then
			v = input.UserInputType
		end
		if v then
			S[listening.key] = v
			listening.btn.Text = v.Name
			listening = nil
			updateHint()
		end
		return
	end

	if UIS:GetFocusedTextBox() then return end

	if matches(input, S.MenuKey) then
		setMenu(not menuOpen)
		return
	end

	if matches(input, S.FlyKey) then
		S.Fly = not S.Fly
		refreshUI()
		notify("Fly: " .. (S.Fly and "ON" or "OFF"))
		return
	end

	if S.ClickTP and matches(input, S.TPKey) and not isOverMenu() then
		clickTP()
		return
	end

	local isMouseInput = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseButton3
		or input.UserInputType == Enum.UserInputType.Touch

	if matches(input, S.AimKey) and not (isMouseInput and isOverMenu()) then
		if S.AimMode == "Toggle" then
			aimHeld = not aimHeld
		else
			aimHeld = true
		end
	end
	if matches(input, S.SwitchKey) then
		switchRequested = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if S.AimMode == "Hold" and matches(input, S.AimKey) then
		aimHeld = false
	end
end)

----------------------------------------------------------------
-- Per-frame: ESP + FOV + Aim-lock
----------------------------------------------------------------
RunService:BindToRenderStep("SpaceMenuUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
	Camera = Workspace.CurrentCamera
	local color = S.Rainbow and rainbowColor() or S.ESPColor
	local myRoot = LP.Character and getRoot(LP.Character)

	updateESP(color, myRoot)

	-- stop spectating if the target is gone
	if spectateModel then
		local d = targets[spectateModel]
		if not d or d.hum.Health <= 0 then
			stopSpectate()
			notify("Spectate target left")
		end
	end

	-- FOV circle
	local mouse = UIS:GetMouseLocation()
	fov.Visible = S.FOVEnabled
	fov.Size = UDim2.fromOffset(S.FOVRadius * 2, S.FOVRadius * 2)
	fov.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	fovStroke.Color = S.Rainbow and color or T.accent2

	-- Aim-lock
	if S.AimMode == "Hold" then
		aimHeld = isKeyHeld(S.AimKey) and not listening and not UIS:GetFocusedTextBox()
	end

	if spectateModel or not (S.Aimlock and aimHeld) then
		currentTarget = nil
		visited = {}
		switchRequested = false
		if spectateModel then
			status.Text = "Aim paused (spectating)"
		elseif S.Aimlock then
			status.Text = "Aim: idle (" .. S.AimMode .. " " .. S.AimKey.Name .. ")"
		else
			status.Text = "Aim-lock: OFF"
		end
		return
	end

	local fullList = getCandidates(true)
	local stillValid = false
	if currentTarget then
		for _, c in ipairs(fullList) do
			if c.model == currentTarget then stillValid = true break end
		end
	end

	if switchRequested then
		switchRequested = false
		if currentTarget then visited[currentTarget] = true end
		local pick
		for _, c in ipairs(fullList) do
			if not visited[c.model] then pick = c.model break end
		end
		if not pick then
			visited = {}
			for _, c in ipairs(fullList) do
				if c.model ~= currentTarget then pick = c.model break end
			end
			if currentTarget then visited[currentTarget] = true end
		end
		if pick then
			currentTarget = pick
			stillValid = true
		end
	end

	if not stillValid then
		local fovList = getCandidates(false)
		currentTarget = fovList[1] and fovList[1].model or nil
		visited = {}
	end

	if currentTarget and targets[currentTarget] then
		status.Text = "Target: " .. targets[currentTarget].name
		local part = getAimPart(currentTarget)
		if part then
			local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
			if S.HardLock then
				Camera.CFrame = goal
			else
				local a = 1 - (S.Smoothing / 100)
				a = 1 - (1 - a) ^ (dt * 60)
				Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(a, 0, 1))
			end
		end
	else
		getCandidates(false)
		status.Text = string.format("No target (seen %d | off-screen %d | outside FOV %d | behind wall %d)",
			aimStats.seen, aimStats.offscreen, aimStats.fov, aimStats.wall)
	end
end)

-- start tracking targets
task.spawn(function()
	while not unloaded do
		pcall(refreshTargets)
		task.wait(0.5)
	end
end)

----------------------------------------------------------------
-- WalkSpeed
----------------------------------------------------------------
do
	local origSpeed
	LP.CharacterAdded:Connect(function() origSpeed = nil end)

	RunService.Heartbeat:Connect(function()
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if S.WalkSpeedOn then
			if not origSpeed then origSpeed = hum.WalkSpeed end
			hum.WalkSpeed = S.WalkSpeed
		elseif origSpeed then
			hum.WalkSpeed = origSpeed
			origSpeed = nil
		end
	end)
end

----------------------------------------------------------------
-- Fly (WASD = move, Space = up, LeftCtrl = down)
-- Yaw-only rotation + no PlatformStand = no sinking into the floor
----------------------------------------------------------------
do
	local flyVel, flyGyro
	local wasFlying = false

	local function stopFly()
		if flyVel then flyVel:Destroy() flyVel = nil end
		if flyGyro then flyGyro:Destroy() flyGyro = nil end
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and getRoot(char)
		if hum then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		if root then
			local _, yaw = root.CFrame:ToOrientation()
			root.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, yaw, 0)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end

	LP.CharacterAdded:Connect(function()
		flyVel, flyGyro, wasFlying = nil, nil, false
	end)

	RunService.RenderStepped:Connect(function()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and getRoot(char)
		if not (S.Fly and hum and root and hum.Health > 0) then
			if wasFlying then
				wasFlying = false
				if root and hum then stopFly() else flyVel, flyGyro = nil, nil end
			end
			return
		end

		if not wasFlying then
			wasFlying = true
			root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
			flyVel = Instance.new("BodyVelocity")
			flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			flyVel.Velocity = Vector3.zero
			flyVel.Parent = root
			flyGyro = Instance.new("BodyGyro")
			flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			flyGyro.P = 9e4
			flyGyro.Parent = root
		end

		hum:ChangeState(Enum.HumanoidStateType.Freefall)

		local cf = Workspace.CurrentCamera.CFrame
		local dir = Vector3.zero
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		end
		flyVel.Velocity = dir.Magnitude > 0 and dir.Unit * S.FlySpeed or Vector3.zero

		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if look.Magnitude > 0.01 then
			flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + look)
		end
	end)
end

----------------------------------------------------------------
-- Noclip
----------------------------------------------------------------
do
	local noclipOrig = {}
	RunService.Stepped:Connect(function()
		local char = LP.Character
		if not char then return end
		if S.Noclip or S.Fly then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					if noclipOrig[p] == nil then noclipOrig[p] = p.CanCollide end
					p.CanCollide = false
				end
			end
		elseif next(noclipOrig) then
			for p, v in pairs(noclipOrig) do
				if p.Parent then p.CanCollide = v end
			end
			noclipOrig = {}
		end
	end)
end

----------------------------------------------------------------
-- Infinite jump
----------------------------------------------------------------
UIS.JumpRequest:Connect(function()
	if not S.InfJump then return end
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

----------------------------------------------------------------
-- Invisible (client-side only: hides your character on YOUR screen)
----------------------------------------------------------------
do
	local wasInvisible = false
	RunService.RenderStepped:Connect(function()
		local char = LP.Character
		if not char then return end
		if S.Invisible then
			wasInvisible = true
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 1
				elseif d:IsA("Decal") then
					d.Transparency = 1
				end
			end
		elseif wasInvisible then
			wasInvisible = false
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 0
				elseif d:IsA("Decal") then
					d.Transparency = 0
				end
			end
		end
	end)
end

----------------------------------------------------------------
-- Visuals: fullbright, time of day, FOV, zoom unlock, crosshair
----------------------------------------------------------------
do
	local lightOrig, origFOV, origTime, origZoom

	local cross = Instance.new("Frame")
	cross.Name = "Crosshair"
	cross.AnchorPoint = Vector2.new(0.5, 0.5)
	cross.Position = UDim2.fromScale(0.5, 0.5)
	cross.Size = UDim2.fromOffset(0, 0)
	cross.BackgroundTransparency = 1
	cross.Visible = false
	cross.ZIndex = 10
	cross.Parent = gui
	local function crossPart(anchor, pos)
		local f = Instance.new("Frame")
		f.AnchorPoint = anchor
		f.Position = pos
		f.BorderSizePixel = 0
		f.ZIndex = 10
		f.Parent = cross
		return f
	end
	local cl = crossPart(Vector2.new(1, 0.5), UDim2.fromOffset(-4, 0))
	local cr = crossPart(Vector2.new(0, 0.5), UDim2.fromOffset(4, 0))
	local cu = crossPart(Vector2.new(0.5, 1), UDim2.fromOffset(0, -4))
	local cd = crossPart(Vector2.new(0.5, 0), UDim2.fromOffset(0, 4))
	local dot = crossPart(Vector2.new(0.5, 0.5), UDim2.fromOffset(0, 0))
	dot.Size = UDim2.fromOffset(3, 3)

	RunService.RenderStepped:Connect(function()
		if S.Fullbright then
			if not lightOrig then
				lightOrig = {
					Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd,
					GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
				}
			end
			Lighting.Brightness = 2
			Lighting.FogEnd = 1e6
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		elseif lightOrig then
			for k, v in pairs(lightOrig) do Lighting[k] = v end
			lightOrig = nil
		end

		if S.TimeOn then
			if not origTime then origTime = Lighting.ClockTime end
			Lighting.ClockTime = S.TimeOfDay
		elseif origTime then
			Lighting.ClockTime = origTime
			origTime = nil
		end

		local cam = Workspace.CurrentCamera
		if S.CamFOVOn then
			if not origFOV then origFOV = cam.FieldOfView end
			cam.FieldOfView = S.CamFOV
		elseif origFOV then
			cam.FieldOfView = origFOV
			origFOV = nil
		end

		if S.ZoomUnlock then
			if not origZoom then origZoom = { LP.CameraMaxZoomDistance, LP.CameraMinZoomDistance } end
			LP.CameraMaxZoomDistance = S.ZoomMax
			LP.CameraMinZoomDistance = 0.5
		elseif origZoom then
			LP.CameraMaxZoomDistance = origZoom[1]
			LP.CameraMinZoomDistance = origZoom[2]
			origZoom = nil
		end

		cross.Visible = S.Crosshair
		if S.Crosshair then
			local n = S.CrosshairSize
			cl.Size = UDim2.fromOffset(n, 2)
			cr.Size = UDim2.fromOffset(n, 2)
			cu.Size = UDim2.fromOffset(2, n)
			cd.Size = UDim2.fromOffset(2, n)
			for _, f in ipairs({ cl, cr, cu, cd, dot }) do
				f.BackgroundColor3 = T.accent2
			end
		end
	end)
end

----------------------------------------------------------------
-- Overlays: active-features list + stats panel
----------------------------------------------------------------
do
	local ACTIVE_ITEMS = {
		{ "ESP", "ESP" }, { "Aim-lock", "Aimlock", "AimKey" }, { "Fly", "Fly", "FlyKey" },
		{ "Noclip", "Noclip" }, { "Invisible", "Invisible" }, { "Infinite jump", "InfJump" },
		{ "WalkSpeed", "WalkSpeedOn" }, { "Click TP", "ClickTP", "TPKey" },
		{ "Fullbright", "Fullbright" }, { "Time override", "TimeOn" }, { "Custom FOV", "CamFOVOn" },
		{ "Zoom unlock", "ZoomUnlock" }, { "Crosshair", "Crosshair" },
		{ "Catch radius", "CatchRadiusOn" }, { "Throw arc", "ThrowArcOn" },
		{ "Recoil control", "RecoilOn" },
		{ "Aim Assist", "AssistOn", "AssistKey" }, { "Auto Driver", "DriverOn" },
		{ "AFK Prevention", "AFKOn" }, { "Avoidance", "AvoidOn" },
	}

	local function makePanel(anchor, pos)
		local f = Instance.new("Frame")
		f.AnchorPoint = anchor
		f.Position = pos
		f.AutomaticSize = Enum.AutomaticSize.XY
		f.Size = UDim2.fromOffset(0, 0)
		f.BackgroundColor3 = Color3.fromRGB(10, 8, 26)
		f.BackgroundTransparency = 0.25
		f.BorderSizePixel = 0
		f.ZIndex = 30
		f.Visible = false
		f.Parent = gui
		corner(f, 8)
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = f
		local st = Instance.new("UIStroke")
		st.Thickness = 1.5
		st.Parent = f
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AutomaticSize = Enum.AutomaticSize.XY
		l.Size = UDim2.fromOffset(0, 0)
		l.Font = Enum.Font.GothamBold
		l.TextSize = 12
		l.TextColor3 = TEXT
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.ZIndex = 31
		l.Parent = f
		return f, l, st
	end

	local listFrame, listLabel, listStroke = makePanel(Vector2.new(0, 1), UDim2.new(0, 14, 1, -14))
	local statFrame, statLabel, statStroke = makePanel(Vector2.new(0, 0), UDim2.new(0, 14, 0, 14))

	local fps = 60
	RunService.RenderStepped:Connect(function(dt)
		if dt > 0 then fps = fps * 0.9 + (1 / dt) * 0.1 end
	end)

	task.spawn(function()
		while not unloaded do
			listStroke.Color = T.accent
			statStroke.Color = T.accent2

			local lines = {}
			for _, item in ipairs(ACTIVE_ITEMS) do
				if S[item[2]] then
					local line = "● " .. item[1]
					if item[3] then line = line .. "  [" .. S[item[3]].Name .. "]" end
					table.insert(lines, line)
				end
			end
			listFrame.Visible = S.ActiveList and #lines > 0
			if #lines > 0 then
				listLabel.Text = "ACTIVE\n" .. table.concat(lines, "\n")
			end

			statFrame.Visible = S.StatsPanel
			if S.StatsPanel then
				local ping = 0
				pcall(function()
					ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				local count = 0
				for _ in pairs(targets) do count += 1 end
				statLabel.Text = string.format("FPS %d   Ping %d ms\nPlayers %d   Targets %d",
					math.floor(fps), ping, #Players:GetPlayers(), count)
			end
			task.wait(0.25)
		end
	end)
end

----------------------------------------------------------------
-- Dev viz: catch radius sphere + throw arc (only when dev server says OK)
----------------------------------------------------------------
do
	local vizFolder, sphere, landing
	local arcParts = {}
	local ARC_STEPS = 40

	local function getViz()
		if not vizFolder or not vizFolder.Parent then
			vizFolder = Instance.new("Folder")
			vizFolder.Name = "SpaceMenuViz"
			vizFolder.Parent = Workspace
		end
		return vizFolder
	end

	local function vizPart(shape)
		local p = Instance.new("Part")
		p.Shape = shape
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = getViz()
		return p
	end

	local function hideArc()
		for _, p in ipairs(arcParts) do p.Transparency = 1 end
		if landing then landing.Transparency = 1 end
	end

	RunService.RenderStepped:Connect(function()
		local char = LP.Character
		local root = char and getRoot(char)

		if dev.ok and S.CatchRadiusOn and root then
			if not sphere or not sphere.Parent then
				sphere = vizPart(Enum.PartType.Ball)
				sphere.Material = Enum.Material.ForceField
				sphere.Transparency = 0.7
			end
			sphere.Color = T.accent2
			sphere.Size = Vector3.one * (S.CatchRadius * 2)
			sphere.CFrame = CFrame.new(root.Position)
		elseif sphere then
			sphere:Destroy()
			sphere = nil
		end

		if dev.ok and S.ThrowArcOn and root then
			local look = Workspace.CurrentCamera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
			flat = flat.Unit
			local a = math.rad(S.ThrowAngle)
			local vel = (flat * math.cos(a) + Vector3.yAxis * math.sin(a)) * S.ThrowSpeed
			local origin = root.Position + Vector3.new(0, 1.5, 0) + flat * 1.5
			local g = Vector3.new(0, -Workspace.Gravity, 0)

			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char, getViz() }

			local prev = origin
			local hitPos
			local used = 0
			for i = 1, ARC_STEPS do
				local t = i * 0.07
				local p = origin + vel * t + 0.5 * g * t * t
				local res = Workspace:Raycast(prev, p - prev, params)
				if res then
					hitPos = res.Position
					break
				end
				used = i
				local part = arcParts[i]
				if not part then
					part = vizPart(Enum.PartType.Ball)
					part.Material = Enum.Material.Neon
					part.Size = Vector3.new(0.4, 0.4, 0.4)
					arcParts[i] = part
				end
				part.Color = T.accent2
				part.Transparency = 0.2
				part.Position = p
				prev = p
			end
			for i = used + 1, #arcParts do
				arcParts[i].Transparency = 1
			end
			if hitPos then
				if not landing or not landing.Parent then
					landing = vizPart(Enum.PartType.Ball)
					landing.Material = Enum.Material.Neon
					landing.Size = Vector3.new(1.4, 1.4, 1.4)
				end
				landing.Color = T.accent
				landing.Transparency = 0.1
				landing.Position = hitPos
			elseif landing then
				landing.Transparency = 1
			end
		else
			hideArc()
		end
	end)
end

----------------------------------------------------------------
-- Weapon control: publishes RecoilScale / SpreadScale on the equipped Tool
-- (your own weapon script reads these attributes)
----------------------------------------------------------------
do
	local lastTool

	local function applyScale(tool, recoil, spread)
		if tool:GetAttribute("RecoilScale") ~= recoil then tool:SetAttribute("RecoilScale", recoil) end
		if tool:GetAttribute("SpreadScale") ~= spread then tool:SetAttribute("SpreadScale", spread) end
	end

	RunService.Heartbeat:Connect(function()
		if unloaded then return end
		local char = LP.Character
		local tool = char and char:FindFirstChildOfClass("Tool")

		if lastTool and lastTool ~= tool and lastTool.Parent then
			applyScale(lastTool, 1, 1) -- restore defaults on the tool you put away
		end
		lastTool = tool
		if not tool then return end

		if S.RecoilOn then
			applyScale(tool, S.RecoilScale / 100, S.SpreadScale / 100)
		else
			applyScale(tool, 1, 1)
		end
	end)
end

----------------------------------------------------------------
-- Major-system notifications (also fire after profile loads / auto-stops)
----------------------------------------------------------------
local systemReason = {}
local function setSystem(key, value, reason)
	S[key] = value
	systemReason[key] = reason
	refreshUI()
end

do
	local NAMES = {
		AssistOn = "Aim Assist", AFKOn = "AFK Prevention",
		DriverOn = "Auto Driver", AvoidOn = "Vehicle Avoidance",
	}
	local last = {}
	for k in pairs(NAMES) do last[k] = S[k] end
	task.spawn(function()
		while not unloaded do
			for k, name in pairs(NAMES) do
				if S[k] ~= last[k] then
					last[k] = S[k]
					local why = systemReason[k]
					systemReason[k] = nil
					notify(name .. (S[k] and ": ON" or ": OFF") .. (why and ("  (" .. why .. ")") or ""))
				end
			end
			task.wait(0.1)
		end
	end)
end

----------------------------------------------------------------
-- Aim Assist: gentle, smoothed camera pull (never a hard snap)
----------------------------------------------------------------
do
	local assistTarget
	local visitedA = {}
	local prevHeld, prevSwitch = false, false
	local listenStamp = 0
	AX.held = false

	local ind = Instance.new("Frame")
	ind.Name = "AssistIndicator"
	ind.AnchorPoint = Vector2.new(0.5, 0.5)
	ind.BackgroundTransparency = 1
	ind.Visible = false
	ind.Parent = gui
	corner(ind, 999).CornerRadius = UDim.new(1, 0)
	local indStroke = Instance.new("UIStroke")
	indStroke.Thickness = 1
	indStroke.Transparency = 0.45
	indStroke.Parent = ind

	local function aimCenter()
		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
			return Camera.ViewportSize / 2
		end
		return UIS:GetMouseLocation()
	end

	-- returns screen distance + aim part if the model is a valid assist target
	local function evaluate(model, data, center, camPos)
		if data.hum.Health <= 0 then return nil end
		if not passesTypeFilter(data) then return nil end
		if S.AssistTeamCheck and data.player and LP.Team ~= nil and data.player.Team == LP.Team then return nil end
		local part = model:FindFirstChild(S.AssistPart) or getRoot(model)
		if not part then return nil end
		if (part.Position - camPos).Magnitude > S.AssistMaxDist then return nil end
		local p, on = Camera:WorldToViewportPoint(part.Position)
		if not on or p.Z <= 0 then return nil end
		local d = (Vector2.new(p.X, p.Y) - center).Magnitude
		if S.AssistFOVOn and d > S.AssistFOV then return nil end
		if S.AssistWallCheck and not hasLineOfSight(part, model) then return nil end
		return d, part
	end

	local function gather(center, camPos)
		local list = {}
		for model, data in pairs(targets) do
			local d, part = evaluate(model, data, center, camPos)
			if d then table.insert(list, { model = model, d = d, part = part }) end
		end
		table.sort(list, function(a, b) return a.d < b.d end)
		return list
	end

	RunService:BindToRenderStep("SpaceMenuAssist", Enum.RenderPriority.Camera.Value + 2, function(dt)
		if unloaded then return end
		Camera = Workspace.CurrentCamera
		local center = aimCenter()

		-- small FOV indicator
		ind.Visible = S.AssistOn and S.AssistIndicator and S.AssistFOVOn
		if ind.Visible then
			ind.Size = UDim2.fromOffset(S.AssistFOV * 2, S.AssistFOV * 2)
			ind.Position = UDim2.fromOffset(center.X, center.Y)
			indStroke.Color = assistTarget and T.accent or T.accent2
		end

		-- input (polled, so rebinding a key never triggers the assist)
		if listening then listenStamp = os.clock() end
		local blocked = listening ~= nil or UIS:GetFocusedTextBox() ~= nil or (os.clock() - listenStamp) < 0.25
		local heldNow = (not blocked) and isKeyHeld(S.AssistKey)
		local switchNow = (not blocked) and isKeyHeld(S.AssistSwitchKey)
		local pressed = heldNow and not prevHeld
		local switchPressed = switchNow and not prevSwitch
		prevHeld, prevSwitch = heldNow, switchNow
		if S.AssistMode == "Toggle" then
			if pressed then AX.held = not AX.held end
		else
			AX.held = heldNow
		end

		-- yield to the hard Aim-lock while it is actively tracking, and to spectating
		local lockBusy = S.Aimlock and aimHeld and currentTarget ~= nil
		if not (S.AssistOn and AX.held) or spectateModel or lockBusy then
			assistTarget = nil
			visitedA = {}
			AX.status.Text = S.AssistOn and ("Assist: idle (" .. S.AssistMode .. " " .. S.AssistKey.Name .. ")") or "Assist: off"
			return
		end

		local camPos = Camera.CFrame.Position
		local curPart

		-- release when the target leaves FOV / range / sight or dies
		if assistTarget then
			local data = targets[assistTarget]
			local d, part
			if data then d, part = evaluate(assistTarget, data, center, camPos) end
			if d then curPart = part else assistTarget = nil end
		end

		-- target switching
		if switchPressed then
			local list = gather(center, camPos)
			if assistTarget then visitedA[assistTarget] = true end
			local pick
			for _, c in ipairs(list) do
				if not visitedA[c.model] and c.model ~= assistTarget then pick = c break end
			end
			if not pick then
				visitedA = {}
				if assistTarget then visitedA[assistTarget] = true end
				for _, c in ipairs(list) do
					if c.model ~= assistTarget then pick = c break end
				end
			end
			if pick then
				assistTarget, curPart = pick.model, pick.part
				notify("Assist target: " .. targets[pick.model].name)
			end
		end

		-- acquire the closest-to-crosshair target
		if not assistTarget then
			local list = gather(center, camPos)
			if list[1] then
				assistTarget, curPart = list[1].model, list[1].part
				visitedA = {}
			end
		end

		if assistTarget and curPart then
			AX.status.Text = "Assist: " .. targets[assistTarget].name
			local camCF = Camera.CFrame
			local goal = CFrame.lookAt(camCF.Position, curPart.Position)
			local angle = math.acos(math.clamp(camCF.LookVector:Dot(goal.LookVector), -1, 1))
			if angle > math.rad(0.15) then
				local strength = S.AssistStrength / 100
				local base = math.clamp(strength * (1 - (S.AssistSmooth / 100) * 0.9), 0, 0.95)
				local a = 1 - (1 - base) ^ (dt * 60)               -- frame-rate independent ease
				local maxStep = math.rad(30 + 330 * strength) * dt  -- speed cap: never a snap
				local step = math.min(angle * a, maxStep)
				Camera.CFrame = camCF:Lerp(goal, step / angle)
			end
		else
			AX.status.Text = "Assist: no target in range"
		end
	end)

	task.spawn(function()
		repeat task.wait(0.25) until unloaded
		pcall(function() RunService:UnbindFromRenderStep("SpaceMenuAssist") end)
	end)
end

----------------------------------------------------------------
-- Driver Assist + AFK Prevention + Vehicle Avoidance (your own place)
-- Drives a VehicleSeat by writing ThrottleFloat / SteerFloat (the same
-- properties Roblox's default vehicle controls write). It also publishes
-- AutoThrottle / AutoSteer / AutoTargetSpeed attributes on the seat so a
-- custom vehicle script can read them instead.
----------------------------------------------------------------
do
	local VirtualUser = game:GetService("VirtualUser")
	local FAN = {}
	for a = -60, 60, 12 do table.insert(FAN, math.rad(a)) end -- 11 rays, index 6 = straight ahead
	local MAX_STEER = math.rad(35)
	local DRIVE_KEYS = {
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
	}

	local st = {
		active = false, seat = nil, wasSeated = false, warned = false,
		steer = 0, throttle = 0, w = 0, wTarget = 0, avoidAngle = 0,
		pathDir = Vector3.zAxis, pathOrigin = Vector3.zero, route = nil, wp = 1,
		clear = {}, veh = {}, hasScan = false, nextScan = 0,
		threatDist = math.huge, threatReq = 10,
		model = nil, halfW = 3, halfL = 6,
		lastPulse = os.clock(), nextStatus = 0,
	}
	local vehCache = setmetatable({}, { __mode = "k" })
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude

	local function flat(v)
		local f = Vector3.new(v.X, 0, v.Z)
		if f.Magnitude < 1e-3 then return nil end
		return f.Unit
	end

	local function isVehiclePart(inst)
		local m = inst:FindFirstAncestorOfClass("Model")
		for _ = 1, 4 do
			if not m or m == Workspace then return false end
			local c = vehCache[m]
			if c == nil then
				c = m:FindFirstChildWhichIsA("VehicleSeat", true) ~= nil
				vehCache[m] = c
			end
			if c then return true end
			m = m.Parent and m.Parent:IsA("Model") and m.Parent or nil
		end
		return false
	end

	-- distance to the first solid obstacle along dir (ramps / non-collidable parts are ignored)
	local function castClear(origin, dir, len)
		local t = 0
		for _ = 1, 4 do
			local res = Workspace:Raycast(origin + dir * t, dir * (len - t), rp)
			if not res then return len end
			local dist = (res.Position - origin):Dot(dir)
			if res.Normal.Y > 0.7 or not res.Instance.CanCollide then
				t = dist + 0.5
				if t >= len then return len end
			else
				return math.max(dist, 0), res.Instance
			end
		end
		return len
	end

	local function scan(seat, fwd, right)
		local base = seat.Position + Vector3.yAxis * 1.5 + fwd * st.halfL
		local detect = S.AvoidDetect
		local lat = right * (st.halfW * 0.8)
		for i, a in ipairs(FAN) do
			local dir = fwd * math.cos(a) + right * math.sin(a)
			local d1, h1 = castClear(base + lat, dir, detect)
			local d2, h2 = castClear(base - lat, dir, detect)
			local d, h = d1, h1
			if d2 < d1 then d, h = d2, h2 end
			st.clear[i] = d
			st.veh[i] = h ~= nil and isVehiclePart(h)
		end
	end

	-- phi = angle (rad, + = right) of where the path wants to go, relative to the car's nose
	local function decide(phi)
		local n = #FAN
		local mid = math.floor((n + 1) / 2)
		local gi = math.clamp(math.floor((phi - FAN[1]) / (FAN[2] - FAN[1]) + 0.5) + 1, 1, n)
		local function req(i) return st.veh[i] and S.VehicleMinDist or S.AvoidMinDist end
		local dF, dG = st.clear[mid], st.clear[gi]
		local threatDist, threatReq = dF, req(mid)
		if dG < dF then threatDist, threatReq = dG, req(gi) end
		st.threatDist, st.threatReq = threatDist, threatReq

		local react = math.max(S.AvoidDetect * 0.8, threatReq + 6)
		local raw = math.clamp(1 - (threatDist - threatReq) / (react - threatReq), 0, 1)
		st.wTarget = math.clamp(raw * (S.DodgeStrength / 50), 0, 1)

		-- best escape heading: widest clear corridor, close to the intended direction
		local best, bestScore = mid, -math.huge
		for i = 1, n do
			local corridor = math.huge
			for j = math.max(1, i - 1), math.min(n, i + 1) do
				corridor = math.min(corridor, st.clear[j] - req(j))
			end
			local score = math.min(corridor, S.AvoidDetect) / S.AvoidDetect
				- 0.35 * math.abs(FAN[i] - phi) / math.rad(120)
			if FAN[i] ~= 0 and st.avoidAngle ~= 0 and (FAN[i] > 0) == (st.avoidAngle > 0) then
				score += 0.06 -- hysteresis: don't dither left/right
			end
			if score > bestScore then best, bestScore = i, score end
		end
		st.avoidAngle = FAN[best]
	end

	local function loadRoute()
		local folder = Workspace:FindFirstChild("DriverRoute") -- optional: Folder of Parts named 1,2,3...
		if not folder then return nil end
		local pts = {}
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("BasePart") then table.insert(pts, c) end
		end
		table.sort(pts, function(a, b)
			local na, nb = tonumber(a.Name), tonumber(b.Name)
			if na and nb then return na < nb end
			return a.Name < b.Name
		end)
		return #pts > 0 and pts or nil
	end

	local function manualInput(hum)
		if UIS:GetFocusedTextBox() then return false end
		for _, k in ipairs(DRIVE_KEYS) do
			if UIS:IsKeyDown(k) then return true end
		end
		for _, g in ipairs(UIS:GetConnectedGamepads()) do
			for _, s in ipairs(UIS:GetGamepadState(g)) do
				if s.KeyCode == Enum.KeyCode.Thumbstick1 and s.Position.Magnitude > 0.35 then return true end
				if (s.KeyCode == Enum.KeyCode.ButtonR2 or s.KeyCode == Enum.KeyCode.ButtonL2) and s.Position.Z > 0.3 then
					return true
				end
			end
		end
		if UIS.TouchEnabled and not UIS.KeyboardEnabled and hum.MoveDirection.Magnitude > 0.1 then
			return true
		end
		return false
	end

	local function release()
		local seat = st.seat
		if seat and seat.Parent then
			pcall(function()
				seat.ThrottleFloat = 0
				seat.SteerFloat = 0
			end)
			seat:SetAttribute("AutoThrottle", nil)
			seat:SetAttribute("AutoSteer", nil)
			seat:SetAttribute("AutoTargetSpeed", nil)
		end
		st.active, st.seat, st.hasScan = false, nil, false
		AX.driverStatus.Text = "Driver: off"
	end

	-- AFK prevention (only while seated)
	LP.Idled:Connect(function()
		if unloaded or not S.AFKOn then return end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.SeatPart) then return end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
		end)
	end)

	RunService:BindToRenderStep("SpaceMenuDriver", Enum.RenderPriority.Input.Value + 5, function(dt)
		if unloaded then
			if st.active then release() end
			return
		end
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		local now = os.clock()

		-- leaving the vehicle stops the whole system
		if seat then
			st.wasSeated = true
		elseif st.wasSeated then
			st.wasSeated = false
			if S.DriverOn then setSystem("DriverOn", false, "left vehicle") end
			if S.AFKOn then setSystem("AFKOn", false, "left vehicle") end
		end

		-- AFK pulse (backup to the Idled event)
		if S.AFKOn and seat and now - st.lastPulse > 120 then
			st.lastPulse = now
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		end

		if not seat then st.warned = false end
		if S.DriverOn and seat and not seat:IsA("VehicleSeat") and not st.warned then
			st.warned = true
			notify("Auto Driver needs a VehicleSeat")
		end

		local canDrive = S.DriverOn and seat ~= nil and seat:IsA("VehicleSeat")
		if not canDrive then
			if st.active then release() end
			return
		end

		-- manual takeover: immediately hands control back
		if manualInput(hum) then
			setSystem("DriverOn", false, "manual takeover")
			release()
			return
		end

		-- (re)start
		if not st.active or st.seat ~= seat then
			st.active, st.seat = true, seat
			st.pathDir = flat(seat.CFrame.LookVector) or Vector3.zAxis
			st.pathOrigin = seat.Position
			st.steer, st.throttle, st.w, st.wTarget, st.avoidAngle = 0, 0, 0, 0, 0
			st.hasScan = false
			st.route = loadRoute()
			st.wp = 1
			if st.route then
				local bestD = math.huge
				for i, p in ipairs(st.route) do
					local d = (p.Position - seat.Position).Magnitude
					if d < bestD then bestD, st.wp = d, i end
				end
			end
			local m = seat:FindFirstAncestorOfClass("Model")
			st.model = m
			if m then
				local sz = m:GetExtentsSize() -- assumes the model is aligned with the seat
				st.halfW = math.clamp(sz.X / 2, 1.5, 6)
				st.halfL = math.clamp(sz.Z / 2, 3, 12)
			end
			notify(st.route and ("Driver: following DriverRoute (" .. #st.route .. " pts)") or "Driver: holding current heading")
		end

		local cf = seat.CFrame
		local fwd = flat(cf.LookVector)
		if not fwd then return end
		local right = fwd:Cross(Vector3.yAxis)
		local pos = seat.Position

		-- intended path direction
		local goalDir
		local wpPart = st.route and st.route[st.wp]
		if wpPart and wpPart.Parent then
			local to = flat(wpPart.Position - pos)
			if (Vector3.new(wpPart.Position.X, 0, wpPart.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 15 then
				st.wp = st.wp % #st.route + 1
				wpPart = st.route[st.wp]
				to = wpPart and flat(wpPart.Position - pos)
			end
			goalDir = to or fwd
		else
			local off = pos - st.pathOrigin
			off = Vector3.new(off.X, 0, off.Z)
			local lateral = off - st.pathDir * off:Dot(st.pathDir)
			if lateral.Magnitude > 0.5 then
				local k = math.clamp(lateral.Magnitude / 30, 0, 0.7)
				goalDir = (st.pathDir - lateral.Unit * k).Unit -- gently steer back to the line
			else
				goalDir = st.pathDir
			end
		end
		local phi = math.atan2(goalDir:Dot(right), goalDir:Dot(fwd))

		-- obstacle / vehicle scan (20 Hz)
		if S.AvoidOn then
			if now >= st.nextScan then
				st.nextScan = now + 0.05
				rp.FilterDescendantsInstances = { st.model or seat.Parent, char }
				scan(seat, fwd, right)
				decide(phi)
				st.hasScan = true
			end
		else
			st.hasScan = false
		end

		-- dodge blend: ramps in fast, eases back to the path slowly
		local wT = (S.AvoidOn and st.hasScan) and st.wTarget or 0
		local blendRate = (wT > st.w) and 8 or math.max(0.4, 4 - 0.035 * S.SteerSmooth)
		st.w += (wT - st.w) * (1 - math.exp(-blendRate * dt))
		local psi = phi + (st.avoidAngle - phi) * st.w

		-- steering
		local steerTarget = math.clamp(psi / MAX_STEER, -1, 1)
		local steerRate = math.max(2, 20 - 0.18 * S.SteerSmooth)
		st.steer += (steerTarget - st.steer) * (1 - math.exp(-steerRate * dt))

		-- speed / braking
		local fs = seat.AssemblyLinearVelocity:Dot(cf.LookVector)
		local want = S.DriverSpeed * (1 - 0.35 * math.abs(st.steer))
		local emergency = false
		if S.AvoidOn and st.hasScan then
			local r = st.threatReq
			local bd = math.max(S.BrakeDist, r + 2)
			if st.threatDist < bd then
				want = want * math.clamp((st.threatDist - r) / (bd - r), 0, 1)
				emergency = st.threatDist < r
			end
		end
		local tt = math.clamp((want - fs) * 0.2, -1, 1)
		if fs < 1.5 then tt = math.max(tt, 0) end -- brake to a stop, never reverse
		if emergency and fs > 1.5 then
			st.throttle = -1
		else
			local rate = 12 - 0.1 * S.DriverAccel
			if tt < st.throttle then rate *= 1.5 end
			st.throttle += (tt - st.throttle) * (1 - math.exp(-rate * dt))
		end

		seat.ThrottleFloat = st.throttle
		seat.SteerFloat = st.steer
		seat:SetAttribute("AutoThrottle", st.throttle)
		seat:SetAttribute("AutoSteer", st.steer)
		seat:SetAttribute("AutoTargetSpeed", want)

		if now >= st.nextStatus then
			st.nextStatus = now + 0.2
			AX.driverStatus.Text = string.format("Driver: %d / %d studs/s | steer %.2f | dodge %d%%",
				math.floor(fs + 0.5), S.DriverSpeed, st.steer, math.floor(st.w * 100))
		end
	end)

	task.spawn(function()
		repeat task.wait(0.25) until unloaded
		pcall(function() RunService:UnbindFromRenderStep("SpaceMenuDriver") end)
	end)
end

----------------------------------------------------------------
-- Connect to the dev server (if the place has SpaceDevServer.lua)
----------------------------------------------------------------
task.spawn(function()
	local rf = ReplicatedStorage:WaitForChild("SpaceDevRF", 6)
	if not rf then
		devStatusLabel.Text = "Dev server: not found (expected outside your own place)"
		return
	end
	local ok, res = pcall(function()
		return rf:InvokeServer("auth")
	end)
	if ok and type(res) == "table" and res.ok then
		dev.remote = rf
		dev.ok = true
		dev.config = res.config or {}
		devStatusLabel.Text = "Dev server: connected (ball: " .. tostring(dev.config.ballName) .. ")"
		loadPersistedProfiles()
		refreshProfileList()
	else
		devStatusLabel.Text = "Dev server: found, but you are not authorized"
	end
end)
