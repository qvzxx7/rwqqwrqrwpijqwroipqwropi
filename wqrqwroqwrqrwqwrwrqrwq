-- config things --
local cfg      = getgenv().Config
local victim   = tonumber(cfg.victim)
local helper   = cfg.helper or ""
local level    = tonumber(cfg.level) or 0
local streak   = tonumber(cfg.streak) or 0
local elo      = tonumber(cfg.elo) or 0
local keys     = cfg.keys
local premium  = cfg.premium
local verified = cfg.verified
local platform = tostring(cfg.platform or "DESKTOP"):upper()
local join     = cfg.join
local nudge    = cfg.nudge ~= false   -- set cfg.nudge = false to disable

-- discord popup --
local rq = syn and syn.request or http_request or request or http.request
if rq then
	pcall(function()
		rq({
			Url = "http://127.0.0.1:6463/rpc?v=1",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" },
			Body = game:GetService("HttpService"):JSONEncode({
				cmd = "INVITE_BROWSER",
				args = { code = "rivalscomp" },
				nonce = game:GetService("HttpService"):GenerateGUID(false)
			}),
		})
	end)
end

repeat task.wait() until game:IsLoaded()

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if getgenv()._spoofCleanup then pcall(getgenv()._spoofCleanup) end

if join ~= "discord.gg/rivalscomp" then
	LocalPlayer:Kick("don't remove the discord.gg/rivalscomp watermark please")
	return
end

-- target, with timeout so a typo'd helper can't hang you
local friend = LocalPlayer
if helper ~= "" then
	friend = Players:WaitForChild(helper, 15) or LocalPlayer
end

-- victim data
local okFetch, raw = pcall(game.HttpGet, game, "https://users.roblox.com/v1/users/" .. tostring(victim), true)
if not okFetch or not raw or raw == "" then
	warn("[spoofer] couldn't fetch victim " .. tostring(victim))
	return
end
local decodedData = HttpService:JSONDecode(raw)
local spoofName   = decodedData.name

-- identity swap
friend.Name                  = spoofName
friend.UserId                = decodedData.id
friend.CharacterAppearanceId = decodedData.id
friend.DisplayName           = decodedData.displayName

local function applyStats()
	pcall(function() friend:SetAttribute("Level", level) end)
	pcall(function() friend:SetAttribute("StatisticDuelsWinStreak", streak) end)
	if elo > 0 then pcall(function() friend:SetAttribute("DisplayELO", elo) end) end
	local cls = friend:FindFirstChild("CustomLeaderstats")
	if cls then
		local lv = cls:FindFirstChild("Level")
		if lv then lv.Value = level end
		local ws = cls:FindFirstChild("Win Streak")
		if ws then ws.Value = streak end
	end
end

local dressing = false
local function Char()
	local char = friend.Character
	if not (char and char:FindFirstChild("Humanoid")) then return end
	if dressing then return end
	dressing = true

	local okApp, appearance = pcall(Players.GetCharacterAppearanceAsync, Players, decodedData.id)
	if okApp and appearance and char.Parent then
		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
				v:Destroy()
			end
		end
		local hum = char:FindFirstChild("Humanoid")
		for _, v in ipairs(appearance:GetChildren()) do
			if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
				v.Parent = char
			elseif v:IsA("Accessory") and hum then
				hum:AddAccessory(v)
			end
		end
		if char.Parent then
			local parent = char.Parent
			char.Parent = nil
			task.wait()
			char.Parent = parent
		end
	end
	dressing = false
end

-- wait for a live character before touching anything
local waited = 0
while not (friend.Character and friend.Character:FindFirstChild("Humanoid")) and waited < 30 do
	task.wait(0.1); waited = waited + 0.1
end

if friend.Character then
	friend.Character.Name = spoofName
	local hum = friend.Character:FindFirstChild("Humanoid")
	if hum then hum.DisplayName = decodedData.displayName end
end

applyStats()
Char()

local respawnConn = friend.CharacterAdded:Connect(function(char)
	task.wait(0.3)
	char:WaitForChild("Humanoid", 5)
	applyStats()
	Char()
end)

local statsConn = friend.ChildAdded:Connect(function(child)
	if child.Name == "CustomLeaderstats" then
		task.wait(0.1)
		applyStats()
	end
end)

-- premium / verified
if hookmetamethod then
	local oldIndex
	oldIndex = hookmetamethod(game, "__index", function(self, key)
		if self == friend then
			if key == "MembershipType" and premium then return Enum.MembershipType.Premium end
			if key == "HasVerifiedBadge" and verified then return true end
		end
		return oldIndex(self, key)
	end)
else
	warn("[spoofer] no hookmetamethod - premium/verified spoof skipped")
end

-- fire CharacterAdded once so RIVALS rebuilds your fighter after the reparent
if nudge and friend == LocalPlayer and friend.Character then
	local c = friend.Character
	friend.Character = nil
	task.wait()
	friend.Character = c
end

local imagetable = {
	["DESKTOP"] = "rbxassetid://17136633356",
	["MOBILE"]  = "rbxassetid://17136633510",
	["CONSOLE"] = "rbxassetid://17136633629",
	["VR"]      = "rbxassetid://17136765745"
}
local icon = imagetable[platform] or imagetable.DESKTOP

local function walk(root, ...)
	local node = root
	for _, name in ipairs({...}) do
		if not node then return nil end
		if name == "Parent" then node = node.Parent else node = node:FindFirstChild(name) end
	end
	return node
end

local acc, statAcc = 0, 0
local uiConn = RunService.Heartbeat:Connect(function(dt)
	statAcc = statAcc + dt
	if statAcc >= 1 then
		statAcc = 0
		applyStats()
	end

	acc = acc + dt
	if acc < 0.1 then return end
	acc = 0

	local ctrl = walk(friend.Character, "HumanoidRootPart", "Nametag", "Frame", "Player", "Controls")
	if ctrl then ctrl.Image = icon end

	local pg   = LocalPlayer:FindFirstChild("PlayerGui")
	local duel = walk(pg, "MainGui", "MainFrame", "DuelInterfaces", "DuelInterface")
	if not duel then return end

	local board = walk(duel, "Scoreboard", "Container")
	if board then
		for _, v in ipairs(board:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "Username"
				and string.find(v.Text, "@" .. spoofName, 1, true) then
				local t = walk(v, "Parent", "Container", "TeammateSlot", "Container", "Controls")
				if t then t.Image = icon end
			end
		end
	end

	local teams = walk(duel, "Top", "Scores", "Teams")
	if teams then
		for _, v in ipairs(teams:GetDescendants()) do
			if v:IsA("ImageLabel") and v.Name == "Headshot"
				and string.find(v.Image, tostring(victim), 1, true) then
				local t = walk(v, "Parent", "Controls")
				if t then t.Image = icon end
			end
		end
	end

	local winners = walk(duel, "FinalResults", "Winners", "Players")
	if winners then
		for _, v in ipairs(winners:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "Username"
				and string.find(v.Text, "@" .. spoofName, 1, true) then
				local t = walk(v, "Parent", "Parent", "Controls")
				if t then t.Image = icon end
			end
		end
	end

	local currency = walk(pg, "MainGui", "MainFrame", "Lobby", "Currency", "Container")
	if currency then
		for _, v in ipairs(currency:GetDescendants()) do
			if v.Name == "Icon" and keys and v.Image == "rbxassetid://17860673529" then
				local t = walk(v, "Parent", "Parent", "Title")
				if t then t.Text = tostring(keys) end
			end
		end
	end
end)

getgenv()._spoofCleanup = function()
	pcall(function() respawnConn:Disconnect() end)
	pcall(function() statsConn:Disconnect() end)
	pcall(function() uiConn:Disconnect() end)
end
