-- SOS TAGS Standalone LocalScript
-- Put in StarterPlayerScripts
-- Random thought: if this breaks, blame lag demons, not me. (They are undefeated in every FPS since COD4.)

--------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:FindService("TextChatService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local SOS_ACTIVATE_MARKER = "𖺗"
local SOS_REPLY_MARKER = "¬"

local AK_MARKER_1 = "؍؍؍"
local AK_MARKER_2 = "؍"

local INIT_DELAY = 0.9

local TAG_W, TAG_H = 144, 36
local TAG_OFFSET_Y = 3

local ORB_SIZE = 18
local ORB_OFFSET_Y = 6.2

--------------------------------------------------------------------
-- ARRIVAL FX + POPUPS
--------------------------------------------------------------------
local OWNER_ARRIVAL_TEXT = "He has Arrived"
local OWNER_ARRIVAL_SOUND_ID = "rbxassetid://136954512002069"

local COOWNER_ARRIVAL_TEXT = "Hes Behind You"
local COOWNER_ARRIVAL_SOUND_ID = "rbxassetid://119023903778140"

local SIN_ARRIVAL_DEFAULT_SOUND_ID = "rbxassetid://87617059556991"

local INTRO_VOLUME_MULT = 0.30

local SOS_JOIN_PING_SOUND_ID = "rbxassetid://5773338685"
local SOS_JOIN_PING_VOLUME = 0.10

--------------------------------------------------------------------
-- ALWAYS SHOW TAGS
--------------------------------------------------------------------
local AlwaysShowTags = {
	-- [123456789] = true,
	[5105522471] = true
	[7887807265] = true
	[1575141882] = true
	[196988708] = true
	[2630250935] = true
}

--------------------------------------------------------------------
-- Optional per user intros (text popup, glitchy)
--------------------------------------------------------------------
local CustomUserIntros = {
	[7452991350] = {
		Text = "XTCY Has Been Summoned.",
		SoundId = "rbxassetid://120403072198402",
		TextColor = Color3.fromRGB(200, 0, 0),
	},
}

--------------------------------------------------------------------
-- ROLES DATA
--------------------------------------------------------------------
local ROLE_COLOR = {
	Normal = Color3.fromRGB(120, 190, 235),
	Owner  = Color3.fromRGB(255, 255, 80),
	CoOwner = Color3.fromRGB(255, 255, 80),
	Tester = Color3.fromRGB(60, 255, 90),
	Sin    = Color3.fromRGB(235, 70, 70),
	OG     = Color3.fromRGB(160, 220, 255),
	Custom = Color3.fromRGB(245, 245, 245),
}

local OwnerNames = {
	["deniskraily"] = true,
}

local OwnerUserIds = {
	[433636433] = true,
	[196988708] = true,
	[4926923208] = true,
}

local CoOwners = {
	[2630250935] = true,
	[9253548067] = true,
	[5348319883] = true,
}

local TesterUserIds = {
}

local SinProfiles = {
	[105995794]  = { SinName = "Lettuce" },
	[138975737]  = { SinName = "Music" },
	[9159968275] = { SinName = "Music" },
	[4659279349] = { SinName = "Trial" },
	[4495710706] = { SinName = "Games Design" },
	[1575141882] = { SinName = "Heart" },
	[118170824]  = { SinName = "Security" },
	[7870252435] = { SinName = "Security" },
	[3600244479] = { SinName = "PAWS" },
	[8956134409] = { SinName = "Cars" },
}

local OgProfiles = {
}

local CustomTags = {
	[8299334811] = { TagText = "OG Fake Cinny" },
	[7452991350] = { TagText = "OG XTCY" },
	[9072904295] = { TagText = "OG XTCY" },
	[7444930172] = { TagText = "OG XTCY" },
	[2630250935] = { TagText = "Co-Owner" },
	[754232813]  = { TagText = "OG Ghoul" },
	[4689208231] = { TagText = "OG Shiroyasha" },
}

--------------------------------------------------------------------
-- SPECIAL FX
--------------------------------------------------------------------
local FX_FOLDER_NAME = "SOS_SpecialFX"

local CMD_OWNER_ON = "Owner_on"
local CMD_OWNER_OFF = "Owner_off"
local CMD_COOWNER_ON = "CoOwner_on"
local CMD_COOWNER_OFF = "CoOwner_off"

local CMD_OWNER_COLOR_PREFIX = "Owner_color:"
local CMD_COOWNER_COLOR_PREFIX = "CoOwner_color:"

local CMD_OWNER_FX_PREFIX = "Owner_fx:"
local CMD_COOWNER_FX_PREFIX = "CoOwner_fx:"

--------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------
local SosUsers = {}
local AkUsers = {}

local SeenFirstActivation = false
local RepliedToActivationUserId = {}

local FxEnabled = {
	Owner = true,
	CoOwner = true,
}

local FxColorMode = {
	Owner = "Rainbow",
	CoOwner = "Rainbow",
}

local FxMode = {
	Owner = "Lines",
	CoOwner = "Glitch",
}

local gui
local statsPopup
local statsPopupLabel

local broadcastPanel
local broadcastSOS
local broadcastAK

local sfxPanel
local sfxOnBtn
local sfxOffBtn

local trailPanel
local trailArrow
local trailOpen = false
local trailTween = nil

local FxConnByUserId = {}
local TagFxConnByUserId = {}

local SinIntroShown = {}
local CustomIntroShown = {}

local JoinPopupByUserId = {}

--------------------------------------------------------------------
-- UI HELPERS
--------------------------------------------------------------------
local function makeCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = parent
	return c
end

local function makeStroke(parent, thickness, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(0, 0, 0)
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0.25
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function makeGlass(parent)
	parent.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	parent.BackgroundTransparency = 0.18

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(10, 10, 12)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 8)),
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.20),
	})
	grad.Parent = parent
end

local function ensureGui()
	if gui and gui.Parent then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "SOS_Tags_UI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function makeButton(parent, txt)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	b.BackgroundTransparency = 0.2
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Text = txt or "Button"
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Color3.fromRGB(245, 245, 245)
	b.Parent = parent
	makeCorner(b, 10)

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(200, 40, 40)
	st.Thickness = 1
	st.Transparency = 0.25
	st.Parent = b

	return b
end

local function isOwner(plr)
	return plr and ((OwnerNames[plr.Name] == true) or (OwnerUserIds[plr.UserId] == true))
end

local function isCoOwner(plr)
	return plr and (CoOwners[plr.UserId] == true)
end

local function canSeeBroadcastButtons()
	return isOwner(LocalPlayer) or isCoOwner(LocalPlayer)
end

local function canSeeTrailMenu()
	return isOwner(LocalPlayer) or isCoOwner(LocalPlayer)
end

--------------------------------------------------------------------
-- CHAT SEND
--------------------------------------------------------------------
local function trySendChat(text)
	do
		local ok, sent = pcall(function()
			if TextChatService and TextChatService.TextChannels then
				local general = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
				if general and general.SendAsync then
					general:SendAsync(text)
					return true
				end
			end
			return false
		end)
		if ok and sent == true then
			return true
		end
	end

	do
		local ok, sent = pcall(function()
			local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
			if events then
				local say = events:FindFirstChild("SayMessageRequest")
				if say and say.FireServer then
					say:FireServer(text, "All")
					return true
				end
			end
			return false
		end)
		if ok and sent == true then
			return true
		end
	end

	return false
end

--------------------------------------------------------------------
-- BROADCAST UI
--------------------------------------------------------------------
local function ensureBroadcastPanel()
	ensureGui()

	if not canSeeBroadcastButtons() then
		if broadcastPanel and broadcastPanel.Parent then
			broadcastPanel:Destroy()
		end
		broadcastPanel = nil
		broadcastSOS = nil
		broadcastAK = nil
		return
	end

	if broadcastPanel and broadcastPanel.Parent then return end

	broadcastPanel = Instance.new("Frame")
	broadcastPanel.Name = "BroadcastPanel"
	broadcastPanel.AnchorPoint = Vector2.new(0, 1)
	broadcastPanel.Position = UDim2.new(0, 10, 1, -10)
	broadcastPanel.Size = UDim2.new(0, 220, 0, 48)
	broadcastPanel.BorderSizePixel = 0
	broadcastPanel.Parent = gui
	makeCorner(broadcastPanel, 14)
	makeGlass(broadcastPanel)
	makeStroke(broadcastPanel, 2, Color3.fromRGB(200, 40, 40), 0.1)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = broadcastPanel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = broadcastPanel

	broadcastSOS = makeButton(broadcastPanel, "Broadcast SOS")
	broadcastSOS.Size = UDim2.new(0, 100, 0, 32)

	broadcastAK = makeButton(broadcastPanel, "Broadcast AK")
	broadcastAK.Size = UDim2.new(0, 100, 0, 32)
end

--------------------------------------------------------------------
-- SFX PANEL
--------------------------------------------------------------------
local function ensureSfxPanel()
	ensureGui()

	local show = isOwner(LocalPlayer) or isCoOwner(LocalPlayer)
	if not show then
		if sfxPanel and sfxPanel.Parent then sfxPanel:Destroy() end
		sfxPanel, sfxOnBtn, sfxOffBtn = nil, nil, nil
		return
	end

	if sfxPanel and sfxPanel.Parent then return end

	sfxPanel = Instance.new("Frame")
	sfxPanel.Name = "SfxPanel"
	sfxPanel.AnchorPoint = Vector2.new(0, 1)
	sfxPanel.Position = UDim2.new(0, 10, 1, -64)
	sfxPanel.Size = UDim2.new(0, 220, 0, 44)
	sfxPanel.BorderSizePixel = 0
	sfxPanel.Parent = gui
	makeCorner(sfxPanel, 14)
	makeGlass(sfxPanel)
	makeStroke(sfxPanel, 2, Color3.fromRGB(200, 40, 40), 0.1)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = sfxPanel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = sfxPanel

	sfxOnBtn = makeButton(sfxPanel, "SFX ON")
	sfxOnBtn.Size = UDim2.new(0, 100, 0, 30)

	sfxOffBtn = makeButton(sfxPanel, "SFX OFF")
	sfxOffBtn.Size = UDim2.new(0, 100, 0, 30)

	sfxOnBtn.MouseButton1Click:Connect(function()
		if isOwner(LocalPlayer) then
			FxEnabled.Owner = true
			trySendChat(CMD_OWNER_ON)
		elseif isCoOwner(LocalPlayer) then
			FxEnabled.CoOwner = true
			trySendChat(CMD_COOWNER_ON)
		end
	end)

	sfxOffBtn.MouseButton1Click:Connect(function()
		if isOwner(LocalPlayer) then
			FxEnabled.Owner = false
			trySendChat(CMD_OWNER_OFF)
		elseif isCoOwner(LocalPlayer) then
			FxEnabled.CoOwner = false
			trySendChat(CMD_COOWNER_OFF)
		end
	end)
end

--------------------------------------------------------------------
-- STATS POPUP
--------------------------------------------------------------------
local function ensureStatsPopup()
	ensureGui()
	if statsPopup and statsPopup.Parent then return end

	statsPopup = Instance.new("Frame")
	statsPopup.Name = "SOS_StatsPopup"
	statsPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	statsPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
	statsPopup.Size = UDim2.new(0, 380, 0, 170)
	statsPopup.BorderSizePixel = 0
	statsPopup.Visible = false
	statsPopup.Parent = gui
	makeCorner(statsPopup, 14)
	makeGlass(statsPopup)
	makeStroke(statsPopup, 2, Color3.fromRGB(200, 40, 40), 0.1)

	statsPopupLabel = Instance.new("TextLabel")
	statsPopupLabel.BackgroundTransparency = 1
	statsPopupLabel.Size = UDim2.new(1, -18, 1, -54)
	statsPopupLabel.Position = UDim2.new(0, 9, 0, 10)
	statsPopupLabel.Font = Enum.Font.Gotham
	statsPopupLabel.TextSize = 14
	statsPopupLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	statsPopupLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsPopupLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsPopupLabel.TextWrapped = true
	statsPopupLabel.Text = ""
	statsPopupLabel.Parent = statsPopup

	local closeBtn = makeButton(statsPopup, "Close")
	closeBtn.AnchorPoint = Vector2.new(0.5, 1)
	closeBtn.Position = UDim2.new(0.5, 0, 1, -10)
	closeBtn.Size = UDim2.new(0, 140, 0, 34)
	closeBtn.MouseButton1Click:Connect(function()
		statsPopup.Visible = false
	end)
end

local function destroyTagGui(char, name)
	if not char then return end
	local old = char:FindFirstChild(name)
	if old then old:Destroy() end
end

--------------------------------------------------------------------
-- ROLE RESOLUTION
--------------------------------------------------------------------
local function getSosRole(plr)
	if not plr then return nil end

	if isOwner(plr) then
		return "Owner"
	end

	if isCoOwner(plr) then
		return "CoOwner"
	end

	if CustomTags[plr.UserId] then
		return "Custom"
	end

	if OgProfiles[plr.UserId] then
		return "OG"
	end

	local allowed = (SosUsers[plr.UserId] == true) or (AlwaysShowTags[plr.UserId] == true)
	if not allowed then
		return nil
	end

	if TesterUserIds[plr.UserId] then
		return "Tester"
	end

	if SinProfiles[plr.UserId] then
		return "Sin"
	end

	return "Normal"
end

local function getRoleColor(plr, role)
	return ROLE_COLOR[role] or Color3.fromRGB(240, 240, 240)
end

local function getTopLine(plr, role)
	if role == "Owner" then return "Owner" end
	if role == "CoOwner" then return "Co-Owner" end
	if role == "Tester" then return "SOS Tester" end

	if role == "Sin" then
		local prof = SinProfiles[plr.UserId]
		if prof and prof.SinName and #tostring(prof.SinName) > 0 then
			return "The Sin of " .. tostring(prof.SinName)
		end
		return "The Sin of ???"
	end

	if role == "OG" then
		return "OG"
	end

	if role == "Custom" then
		local prof = CustomTags[plr.UserId]
		if prof and prof.TagText and #tostring(prof.TagText) > 0 then
			return tostring(prof.TagText)
		end
		return "Custom"
	end

	return "SOS User"
end

--------------------------------------------------------------------
-- CLICK ACTIONS
--------------------------------------------------------------------
local function teleportToPlayer(plr)
	if not plr or plr == LocalPlayer then return end

	local myChar = LocalPlayer.Character
	local theirChar = plr.Character
	if not myChar or not theirChar then return end

	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	local theirHRP = theirChar:FindFirstChild("HumanoidRootPart")
	if not myHRP or not theirHRP then return end

	local targetCf = theirHRP.CFrame * CFrame.new(0, 0, -4)

	pcall(function()
		if myChar.PivotTo then
			myChar:PivotTo(targetCf)
		else
			myHRP.CFrame = targetCf
		end
	end)
end

local function showPlayerStats(plr)
	ensureStatsPopup()
	if not statsPopup then return end

	local ageDays = plr.AccountAge or 0
	local role = getSosRole(plr)
	local roleLine = role and getTopLine(plr, role) or "No SOS tag"
	local akLine = AkUsers[plr.UserId] and "AK: Yes" or "AK: No"

	local txt = ""
	txt = txt .. "User: " .. plr.Name .. "\n"
	txt = txt .. "UserId: " .. tostring(plr.UserId) .. "\n"
	txt = txt .. "AccountAge: " .. tostring(ageDays) .. " days\n\n"
	txt = txt .. "Role: " .. roleLine .. "\n"
	txt = txt .. akLine .. "\n"

	statsPopupLabel.Text = txt
	statsPopup.Visible = true
end

local function makeTagButtonCommon(btn, plr)
	local function act()
		local holdingCtrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		if holdingCtrl then
			showPlayerStats(plr)
		else
			teleportToPlayer(plr)
		end
	end

	btn.MouseButton1Click:Connect(act)
	pcall(function()
		btn.Activated:Connect(act)
	end)
end

--------------------------------------------------------------------
-- SPECIAL FX CORE (FIXED COMMANDS)
--------------------------------------------------------------------
local function disconnectFxConn(userId)
	local c = FxConnByUserId[userId]
	if c then
		pcall(function() c:Disconnect() end)
	end
	FxConnByUserId[userId] = nil
end

local function clearSpecialFx(plr)
	if not plr or not plr.Character then return end
	disconnectFxConn(plr.UserId)

	local char = plr.Character
	local folder = char:FindFirstChild(FX_FOLDER_NAME)
	if folder then folder:Destroy() end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local oldLight = hrp:FindFirstChild("SOS_FxLight")
		if oldLight then oldLight:Destroy() end
	end

	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("Attachment") and (inst.Name == "TrailA0" or inst.Name == "TrailA1") then
			inst:Destroy()
		end
	end
end

local function makeTrailOnPart(part, parentFolder)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Position = Vector3.new(0, 0, -math.max(part.Size.Z * 0.5, 0.2))
	a0.Parent = part

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Position = Vector3.new(0, 0, math.max(part.Size.Z * 0.5, 0.2))
	a1.Parent = part

	local tr = Instance.new("Trail")
	tr.Name = "RunTrail"
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.Brightness = 2
	tr.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.45, 0.22),
		NumberSequenceKeypoint.new(1, 1.00),
	})
	tr.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65),
		NumberSequenceKeypoint.new(0.6, 0.25),
		NumberSequenceKeypoint.new(1, 0.00),
	})
	tr.Lifetime = 0.12
	tr.Enabled = false
	tr.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	tr.Parent = parentFolder

	return tr
end

local function resolveFxMode(isOwnerRole)
	return isOwnerRole and (FxMode.Owner or "Lines") or (FxMode.CoOwner or "Lines")
end

local function normalizeMode(s)
	s = tostring(s or "")
	s = s:gsub("%s+", "")
	s = s:lower()
	return s
end

local function resolveFxColor(mode, t)
	local m = normalizeMode(mode)
	if m == "rainbow" or m == "rgb" then
		return Color3.fromHSV((t * 0.18) % 1, 1, 1)
	end
	if m == "ice" then return Color3.fromRGB(140, 235, 255) end
	if m == "red" then return Color3.fromRGB(255, 60, 60) end
	if m == "neon" then return Color3.fromRGB(60, 255, 120) end
	if m == "sun" then return Color3.fromRGB(255, 220, 80) end
	if m == "violet" then return Color3.fromRGB(170, 120, 255) end
	if m == "white" then return Color3.fromRGB(245, 245, 245) end
	if m == "silver" then return Color3.fromRGB(170, 170, 170) end
	if m == "black" then return Color3.fromRGB(15, 15, 15) end
	return Color3.fromRGB(245, 245, 245)
end

local function ensureSpecialFx(plr, role)
	if not plr or not plr.Character then return end

	local isOwnerRole = (role == "Owner")
	local isCoOwnerRole = (role == "CoOwner") or isCoOwner(plr)
	local isSpecial = isOwnerRole or isCoOwnerRole

	if not isSpecial then
		clearSpecialFx(plr)
		return
	end

	local enabled = isOwnerRole and (FxEnabled.Owner ~= false) or (FxEnabled.CoOwner ~= false)
	if not enabled then
		clearSpecialFx(plr)
		return
	end

	local char = plr.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	clearSpecialFx(plr)

	local folder = Instance.new("Folder")
	folder.Name = FX_FOLDER_NAME
	folder.Parent = char

	local mode = resolveFxMode(isOwnerRole)
	local trails = nil
	local light = nil
	local hl = nil

	if mode == "Lines" then
		trails = {}
		for _, inst in ipairs(char:GetDescendants()) do
			if inst:IsA("BasePart") and inst.Name ~= "HumanoidRootPart" then
				trails[#trails + 1] = makeTrailOnPart(inst, folder)
			end
		end
	elseif mode == "Lighting" then
		light = Instance.new("PointLight")
		light.Name = "SOS_FxLight"
		light.Range = 16
		light.Brightness = 0
		light.Enabled = true
		light.Parent = hrp
	elseif mode == "Glitch" then
		hl = Instance.new("Highlight")
		hl.Name = "SOS_FxHighlight"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillTransparency = 0.35
		hl.OutlineTransparency = 0.1
		hl.Parent = folder
		hl.Adornee = char
	end

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not folder or not folder.Parent then
			disconnectFxConn(plr.UserId)
			return
		end

		local speed = hrp.Velocity.Magnitude
		local moving = speed > 1.5

		local colorMode = isOwnerRole and FxColorMode.Owner or FxColorMode.CoOwner
		local c = resolveFxColor(colorMode, os.clock())

		if trails then
			for _, tr in ipairs(trails) do
				tr.Enabled = moving
				tr.Color = ColorSequence.new(c)
			end
		end

		if light then
			light.Brightness = moving and 2.6 or 0
			light.Color = c
		end

		if hl then
			local pulse = (math.sin(os.clock() * 10) * 0.5 + 0.5)
			hl.FillTransparency = 0.25 + (pulse * 0.35)
			hl.OutlineTransparency = 0.05 + (pulse * 0.25)
			hl.FillColor = c
			hl.OutlineColor = Color3.fromRGB(0, 0, 0)
		end
	end)

	FxConnByUserId[plr.UserId] = conn
end

--------------------------------------------------------------------
-- ARRIVAL SOUND + JOIN POPUP
--------------------------------------------------------------------
local function playArrivalSound(parentGui, soundId, volume)
	if not soundId or soundId == "" then return end
	local s = Instance.new("Sound")
	s.Name = "ArrivalSfx"
	s.SoundId = soundId
	s.Volume = volume or 0.9
	s.Looped = false
	s.Parent = parentGui
	pcall(function() s:Play() end)
	task.delay(6, function()
		if s and s.Parent then s:Destroy() end
	end)
end

local function showJoinTpPopup(plr)
	if not plr then return end
	if plr.UserId == LocalPlayer.UserId then return end
	ensureGui()

	local old = JoinPopupByUserId[plr.UserId]
	if old and old.Parent then old:Destroy() end
	JoinPopupByUserId[plr.UserId] = nil

	local frame = Instance.new("Frame")
	frame.Name = "SOS_JoinPopup"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0.08, 0)
	frame.Size = UDim2.new(0, 520, 0, 70)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = 7000
	frame.Parent = gui
	makeCorner(frame, 14)
	makeStroke(frame, 2, Color3.fromRGB(200, 40, 40), 0.55)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 16, 0, 10)
	title.Size = UDim2.new(1, -160, 0, 22)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.TextTransparency = 1
	title.ZIndex = 7001
	title.Text = plr.Name .. " Has Joined"
	title.Parent = frame

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.new(0, 16, 0, 34)
	hint.Size = UDim2.new(1, -160, 0, 18)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 13
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextColor3 = Color3.fromRGB(200, 200, 200)
	hint.TextTransparency = 1
	hint.ZIndex = 7001
	hint.Text = "Press to tp to them"
	hint.Parent = frame

	local tpBtn = Instance.new("TextButton")
	tpBtn.Name = "TP"
	tpBtn.AnchorPoint = Vector2.new(1, 0.5)
	tpBtn.Position = UDim2.new(1, -14, 0.5, 0)
	tpBtn.Size = UDim2.new(0, 120, 0, 42)
	tpBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	tpBtn.BackgroundTransparency = 1
	tpBtn.BorderSizePixel = 0
	tpBtn.AutoButtonColor = true
	tpBtn.Text = "TP"
	tpBtn.Font = Enum.Font.GothamBlack
	tpBtn.TextSize = 16
	tpBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
	tpBtn.TextTransparency = 1
	tpBtn.ZIndex = 7002
	tpBtn.Parent = frame
	makeCorner(tpBtn, 12)
	makeStroke(tpBtn, 2, Color3.fromRGB(200, 40, 40), 0.35)

	tpBtn.MouseButton1Click:Connect(function()
		teleportToPlayer(plr)
	end)

	JoinPopupByUserId[plr.UserId] = frame

	local tinf = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tout = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	TweenService:Create(frame, tinf, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(title, tinf, { TextTransparency = 0 }):Play()
	TweenService:Create(hint, tinf, { TextTransparency = 0 }):Play()
	TweenService:Create(tpBtn, tinf, { BackgroundTransparency = 0.18, TextTransparency = 0 }):Play()

	task.delay(1.65, function()
		if not frame or not frame.Parent then return end
		TweenService:Create(frame, tout, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, tout, { TextTransparency = 1 }):Play()
		TweenService:Create(hint, tout, { TextTransparency = 1 }):Play()
		TweenService:Create(tpBtn, tout, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()

		task.delay(0.25, function()
			if frame and frame.Parent then frame:Destroy() end
		end)
	end)
end

local function showGlitchTextPopup(text, soundId, textColor)
	ensureGui()
	if type(text) ~= "string" or text == "" then return end

	local frame = Instance.new("Frame")
	frame.Name = "SOS_GlitchTextIntro"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 720, 0, 120)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.ZIndex = 6000
	frame.Parent = gui
	makeCorner(frame, 16)
	makeStroke(frame, 2, Color3.fromRGB(200, 40, 40), 0.35)

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -20, 1, -20)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 42
	label.TextWrapped = true
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(245, 245, 245)
	label.TextStrokeTransparency = 0.25
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.ZIndex = 6001
	label.Parent = frame

	if soundId and soundId ~= "" then
		playArrivalSound(gui, soundId, 0.9 * INTRO_VOLUME_MULT)
	end

	task.delay(1.2, function()
		if frame and frame.Parent then frame:Destroy() end
	end)
end

local function tryShowSinIntro(userId)
	local plr = Players:GetPlayerByUserId(userId)
	if not plr then return end
	if plr.UserId == LocalPlayer.UserId then return end
	if SinIntroShown[userId] then return end
	SinIntroShown[userId] = true

	local prof = SinProfiles[userId]
	local sinName = (prof and prof.SinName) and tostring(prof.SinName) or "Unknown"
	local introText = (prof and prof.ArrivalText) or ("The Sin of " .. sinName .. " Has Arrived")
	local introSound = (prof and prof.ArrivalSoundId) or SIN_ARRIVAL_DEFAULT_SOUND_ID

	showGlitchTextPopup(introText, introSound, Color3.fromRGB(235, 70, 70))
end

local function tryShowCustomUserIntro(userId)
	local plr = Players:GetPlayerByUserId(userId)
	if not plr then return end
	if CustomIntroShown[userId] then return end

	local intro = CustomUserIntros[userId]
	if not intro then return end

	CustomIntroShown[userId] = true

	local introText = intro.Text or (plr.Name .. " Has Joined")
	local introSound = intro.SoundId
	local introColor = intro.TextColor or Color3.fromRGB(245, 245, 245)

	showGlitchTextPopup(introText, introSound, introColor)
end

--------------------------------------------------------------------
-- TAGS (MINIMAL, keeps your flow)
--------------------------------------------------------------------
local function createSosRoleTag(plr)
	if not plr then return end
	local char = plr.Character
	if not char then return end

	local role = getSosRole(plr)
	ensureSpecialFx(plr, role)

	if not role then
		destroyTagGui(char, "SOS_RoleTag")
		return
	end

	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local adornee = (head and head:IsA("BasePart")) and head or ((hrp and hrp:IsA("BasePart")) and hrp or nil)
	if not adornee then return end

	destroyTagGui(char, "SOS_RoleTag")

	local roleColor = getRoleColor(plr, role)

	local bb = Instance.new("BillboardGui")
	bb.Name = "SOS_RoleTag"
	bb.Adornee = adornee
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, TAG_W, 0, TAG_H)
	bb.StudsOffset = Vector3.new(0, TAG_OFFSET_Y, 0)
	bb.Parent = char

	local btn = Instance.new("TextButton")
	btn.Name = "ClickArea"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.Parent = bb
	makeCorner(btn, 10)

	btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	btn.BackgroundTransparency = 0.22
	makeStroke(btn, 2, roleColor, 0.05)

	local top = Instance.new("TextLabel")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, -10, 0, 18)
	top.Position = UDim2.new(0, 5, 0, 3)
	top.Font = Enum.Font.GothamBold
	top.TextSize = 13
	top.TextXAlignment = Enum.TextXAlignment.Center
	top.TextYAlignment = Enum.TextYAlignment.Center
	top.Text = getTopLine(plr, role)
	top.TextColor3 = Color3.fromRGB(245, 245, 245)
	top.ZIndex = 3
	top.Parent = btn

	local bottom = Instance.new("TextLabel")
	bottom.BackgroundTransparency = 1
	bottom.Size = UDim2.new(1, -10, 0, 16)
	bottom.Position = UDim2.new(0, 5, 0, 19)
	bottom.Font = Enum.Font.Gotham
	bottom.TextSize = 12
	bottom.TextXAlignment = Enum.TextXAlignment.Center
	bottom.TextYAlignment = Enum.TextYAlignment.Center
	bottom.Text = plr.Name
	bottom.TextColor3 = Color3.fromRGB(230, 230, 230)
	bottom.ZIndex = 4
	bottom.Parent = btn

	makeTagButtonCommon(btn, plr)
end

local function createAkOrbTag(plr)
	if not plr then return end
	local char = plr.Character
	if not char then return end

	if not AkUsers[plr.UserId] then
		destroyTagGui(char, "SOS_AKTag")
		return
	end

	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local adornee = (head and head:IsA("BasePart")) and head or ((hrp and hrp:IsA("BasePart")) and hrp or nil)
	if not adornee then return end

	destroyTagGui(char, "SOS_AKTag")

	local bb = Instance.new("BillboardGui")
	bb.Name = "SOS_AKTag"
	bb.Adornee = adornee
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, ORB_SIZE, 0, ORB_SIZE)
	bb.StudsOffset = Vector3.new(0, ORB_OFFSET_Y, 0)
	bb.Parent = char

	local btn = Instance.new("TextButton")
	btn.Name = "ClickArea"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BorderSizePixel = 0
	btn.Text = "AK"
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 10
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextYAlignment = Enum.TextYAlignment.Center
	btn.TextColor3 = Color3.fromRGB(255, 60, 60)
	btn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	btn.BackgroundTransparency = 0.12
	btn.Parent = bb
	makeCorner(btn, 999)
	makeStroke(btn, 1, Color3.fromRGB(0, 0, 0), 0.25)

	makeTagButtonCommon(btn, plr)
end

local function refreshAllTagsForPlayer(plr)
	if not plr or not plr.Character then return end
	createSosRoleTag(plr)
	createAkOrbTag(plr)
end

local function hookPlayer(plr)
	if not plr then return end
	plr.CharacterAdded:Connect(function()
		task.wait(0.12)
		refreshAllTagsForPlayer(plr)
	end)
	if plr.Character then
		task.defer(function()
			refreshAllTagsForPlayer(plr)
		end)
	end
end

--------------------------------------------------------------------
-- SOS AND AK UPDATES
--------------------------------------------------------------------
local function textHasAk(text)
	if type(text) ~= "string" then return false end
	if text == AK_MARKER_1 or text == AK_MARKER_2 then return true end
	if text:find(AK_MARKER_1, 1, true) then return true end
	if text:find(AK_MARKER_2, 1, true) then return true end
	return false
end

local function onSosActivated(userId)
	if typeof(userId) ~= "number" then return end
	SosUsers[userId] = true

	if SinProfiles[userId] then
		tryShowSinIntro(userId)
	end

	tryShowCustomUserIntro(userId)

	local plr = Players:GetPlayerByUserId(userId)
	if plr then refreshAllTagsForPlayer(plr) end
end

local function onAkSeen(userId)
	if typeof(userId) ~= "number" then return end
	AkUsers[userId] = true
	local plr = Players:GetPlayerByUserId(userId)
	if plr then refreshAllTagsForPlayer(plr) end
end

--------------------------------------------------------------------
-- COMMANDS (OWNER COOWNER ONLY) - FIXED + REBUILDS
--------------------------------------------------------------------
local function rebuildSpecialFxFor(plr)
	if not plr then return end
	local role = getSosRole(plr)
	ensureSpecialFx(plr, role)
end

local function rebuildAllSpecialFx()
	for _, p in ipairs(Players:GetPlayers()) do
		if isOwner(p) or isCoOwner(p) then
			rebuildSpecialFxFor(p)
		end
	end
end

local function applyCommandFrom(uid, text)
	local plr = Players:GetPlayerByUserId(uid)

	if text == CMD_OWNER_ON and plr and isOwner(plr) then
		FxEnabled.Owner = true
		rebuildSpecialFxFor(plr)
		return true
	end
	if text == CMD_OWNER_OFF and plr and isOwner(plr) then
		FxEnabled.Owner = false
		rebuildSpecialFxFor(plr)
		return true
	end

	if text == CMD_COOWNER_ON and plr and isCoOwner(plr) then
		FxEnabled.CoOwner = true
		rebuildSpecialFxFor(plr)
		return true
	end
	if text == CMD_COOWNER_OFF and plr and isCoOwner(plr) then
		FxEnabled.CoOwner = false
		rebuildSpecialFxFor(plr)
		return true
	end

	if text:sub(1, #CMD_OWNER_COLOR_PREFIX) == CMD_OWNER_COLOR_PREFIX and plr and isOwner(plr) then
		local mode = text:sub(#CMD_OWNER_COLOR_PREFIX + 1)
		if mode ~= "" then FxColorMode.Owner = mode end
		-- colour updates live, but rebuilding makes it feel instant if mode depends on object type
		rebuildSpecialFxFor(plr)
		return true
	end

	if text:sub(1, #CMD_COOWNER_COLOR_PREFIX) == CMD_COOWNER_COLOR_PREFIX and plr and isCoOwner(plr) then
		local mode = text:sub(#CMD_COOWNER_COLOR_PREFIX + 1)
		if mode ~= "" then FxColorMode.CoOwner = mode end
		rebuildSpecialFxFor(plr)
		return true
	end

	if text:sub(1, #CMD_OWNER_FX_PREFIX) == CMD_OWNER_FX_PREFIX and plr and isOwner(plr) then
		local mode = text:sub(#CMD_OWNER_FX_PREFIX + 1)
		if mode ~= "" then FxMode.Owner = mode end
		rebuildSpecialFxFor(plr)
		return true
	end

	if text:sub(1, #CMD_COOWNER_FX_PREFIX) == CMD_COOWNER_FX_PREFIX and plr and isCoOwner(plr) then
		local mode = text:sub(#CMD_COOWNER_FX_PREFIX + 1)
		if mode ~= "" then FxMode.CoOwner = mode end
		rebuildSpecialFxFor(plr)
		return true
	end

	return false
end

--------------------------------------------------------------------
-- CHAT HANDLING
--------------------------------------------------------------------
local function maybeReplyToActivation(uid)
	if typeof(uid) ~= "number" then return end
	if uid == LocalPlayer.UserId then return end

	if not SeenFirstActivation then
		SeenFirstActivation = true
		return
	end

	if RepliedToActivationUserId[uid] then return end
	RepliedToActivationUserId[uid] = true
	trySendChat(SOS_REPLY_MARKER)
end

local function handleIncoming(uid, text)
	if typeof(uid) ~= "number" then return end
	if type(text) ~= "string" then return end

	if applyCommandFrom(uid, text) then
		return
	end

	if text == SOS_ACTIVATE_MARKER then
		local plr = Players:GetPlayerByUserId(uid)
		if plr and uid ~= LocalPlayer.UserId then
			playArrivalSound(gui or ensureGui(), SOS_JOIN_PING_SOUND_ID, SOS_JOIN_PING_VOLUME)
			showJoinTpPopup(plr)
		end

		onSosActivated(uid)
		maybeReplyToActivation(uid)
		return
	end

	if text == SOS_REPLY_MARKER then
		onSosActivated(uid)
		return
	end

	if textHasAk(text) then
		onAkSeen(uid)
		return
	end
end

local function hookChatListeners()
	-- Incoming (new chat)
	if TextChatService and TextChatService.MessageReceived then
		TextChatService.MessageReceived:Connect(function(msg)
			if not msg then return end
			local text = msg.Text or ""
			local src = msg.TextSource
			if not src or not src.UserId then return end
			handleIncoming(src.UserId, text)
		end)
	end

	-- Outgoing (fix: ensures YOUR commands always work even if Chatted is dead)
	if TextChatService and TextChatService.SendingMessage then
		TextChatService.SendingMessage:Connect(function(msg)
			if not msg then return end
			local text = msg.Text or ""
			handleIncoming(LocalPlayer.UserId, text)
		end)
	end

	-- Legacy fallback
	local function hookChatted(plr)
		pcall(function()
			plr.Chatted:Connect(function(message)
				handleIncoming(plr.UserId, message)
			end)
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		hookChatted(plr)
	end
	Players.PlayerAdded:Connect(hookChatted)
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------
local function init()
	ensureGui()
	ensureStatsPopup()
	ensureBroadcastPanel()
	ensureSfxPanel()

	if broadcastSOS then
		broadcastSOS.MouseButton1Click:Connect(function()
			onSosActivated(LocalPlayer.UserId)
			trySendChat(SOS_ACTIVATE_MARKER)
		end)
	end

	if broadcastAK then
		broadcastAK.MouseButton1Click:Connect(function()
			onAkSeen(LocalPlayer.UserId)
			trySendChat(AK_MARKER_1)
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		hookPlayer(plr)
	end

	Players.PlayerAdded:Connect(function(plr)
		hookPlayer(plr)
		RepliedToActivationUserId[plr.UserId] = nil
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if plr then
			clearSpecialFx(plr)
			disconnectFxConn(plr.UserId)
			RepliedToActivationUserId[plr.UserId] = nil
			SinIntroShown[plr.UserId] = nil
			CustomIntroShown[plr.UserId] = nil

			local p = JoinPopupByUserId[plr.UserId]
			if p and p.Parent then p:Destroy() end
			JoinPopupByUserId[plr.UserId] = nil
		end
	end)

	hookChatListeners()

	onSosActivated(LocalPlayer.UserId)
	trySendChat(SOS_ACTIVATE_MARKER)

	-- If you are Owner/CoOwner, make sure FX exists instantly
	rebuildAllSpecialFx()

	print("SOS Tags loaded. Commands fixed: Owner_color / Owner_fx / CoOwner_color / CoOwner_fx.")
end

task.delay(INIT_DELAY, init)
