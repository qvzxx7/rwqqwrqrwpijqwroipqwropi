-- ================= config =================
local cfg = getgenv().Config or {}
local victim   = tonumber(cfg.victim)
local helper   = cfg.helper or ""
local level    = tonumber(cfg.level) or 0
local streak   = tonumber(cfg.streak) or 0
local elo      = tonumber(cfg.elo) or 0
local keys     = cfg.keys
local premium  = cfg.premium and true or false
local verified = cfg.verified and true or false
local platform = tostring(cfg.platform or "DESKTOP"):upper()
local join     = cfg.join

-- flip these off one by one until your gun works
local OPT = {
	rename   = true,    -- rewrite LocalPlayer.Name + Character.Name
	userId   = true,    -- rewrite LocalPlayer.UserId
	avatar   = true,    -- swap in the victim's avatar
	reparent = false,   -- the Parent=nil / Parent=back refresh (was always on)
	hook     = false,   -- global game.__index hook (only needed for premium/verified)
	settle   = 3,       -- seconds to let the game finish loading first
}

-- ================= boot =================
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

if getgenv()._spoofCleanup then pcall(getgenv()._spoofCleanup) end

if join ~= "discord.gg/rivalscomp" then
	LP:Kick("don't remove the discord.gg/rivalscomp watermark please")
	return
end

-- wait for a genuinely live game, not just IsLoaded
repeat task.wait(0.25) until LP.Character and LP.Character:FindFirstChild("Humanoid") and LP:FindFirstChild("PlayerGui")
task.wait(OPT.settle)

-- ================= target + data =================
local target = LP
if helper ~= "" then
	target = Players:WaitForChild(helper, 15) or LP
end
local origName = target.Name

local okFetch, raw = pcall(game.HttpGet, game, "https://users.roblox.com/v1/users/" .. tostring(victim), true)
if not okFetch or not raw or raw == "" then
	warn("[spoof] victim fetch failed: " .. tostring(victim))
	return
end
local decodedData = HttpService:JSONDecode(raw)
local spoofName = decodedData.name

-- ================= identity =================
if OPT.rename then
	target.Name = spoofName
	target.DisplayName = decodedData.displayName
	if target.Character then target.Character.Name = spoofName end
end
if OPT.userId then
	pcall(function() target.UserId = decodedData.id end)
end
pcall(function() target.CharacterAppearanceId = decodedData.id end)

-- ================= avatar =================
local dressing = false
local function dress()
	if not OPT.avatar or dressing then return end
	local char = target.Character
	if not (char and char:FindFirstChild("Humanoid")) then return end
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
		if OPT.reparent and char.Parent then
			local par = char.Parent
			char.Parent = nil
			task.wait()
			char.Parent = par
		end
	end
	dressing = false
end

-- ================= stats =================
local function applyStats()
	if OPT.rename then
		pcall(function() target:SetAttribute("Level", level) end)
		pcall(function() target:SetAttribute("StatisticDuelsWinStreak", streak) end)
		if elo > 0 then pcall(function() target:SetAttribute("DisplayELO", elo) end) end
		local cls = target:FindFirstChild("CustomLeaderstats")
		if cls then
			local lv = cls:FindFirstChild("Level");       if lv then lv.Value = level end
			local ws = cls:FindFirstChild("Win Streak");  if ws then ws.Value = streak end
		end
	end
	if premium then  pcall(function() target.MembershipType = Enum.MembershipType.Premium end) end
	if verified then pcall(function() target.HasVerifiedBadge = true end) end
end

applyStats()
dress()

local respawnConn = target.CharacterAdded:Connect(function(char)
	task.wait(0.4)
	char:WaitForChild("Humanoid", 5)
	if OPT.rename then char.Name = spoofName end
	applyStats()
	dress()
end)

-- ================= premium / verified hook (only if asked) =================
if OPT.hook and hookmetamethod then
	local oldIndex
	oldIndex = hookmetamethod(game, "__index", function(self, key)
		if self == target then
			if key == "MembershipType" and premium then return Enum.MembershipType.Premium end
			if key == "HasVerifiedBadge" and verified then return true end
		end
		return oldIndex(self, key)
	end)
end

-- ================= UI =================
local imagetable = {
	["DESKTOP"] = "rbxassetid://17136633356",
	["MOBILE"]  = "rbxassetid://17136633510",
	["CONSOLE"] = "rbxassetid://17136633629",
	["VR"]      = "rbxassetid://17136765745",
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

local function matches(text)
	if not text then return false end
	return string.find(text, "@" .. origName, 1, true) or string.find(text, "@" .. spoofName, 1, true)
end

local acc, statAcc = 0, 0
local uiConn = RunService.Heartbeat:Connect(function(dt)
	statAcc = statAcc + dt
	if statAcc >= 1 then statAcc = 0; applyStats() end

	acc = acc + dt
	if acc < 0.1 then return end
	acc = 0

	local char = target.Character
	local nametag = walk(char, "HumanoidRootPart", "Nametag", "Frame", "Player")
	if nametag then
		if nametag:IsA("TextLabel") and OPT.rename == false then nametag.Text = "@" .. spoofName end
		local ctrl = walk(char, "HumanoidRootPart", "Nametag", "Frame", "Player", "Controls")
		if ctrl then ctrl.Image = icon end
	end

	local pg = LP:FindFirstChild("PlayerGui")
	local duel = walk(pg, "MainGui", "MainFrame", "DuelInterfaces", "DuelInterface")
	if not duel then return end

	local board = walk(duel, "Scoreboard", "Container")
	if board then
		for _, v in ipairs(board:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "Username" and matches(v.Text) then
				v.Text = "@" .. spoofName
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
			if v:IsA("TextLabel") and v.Name == "Username" and matches(v.Text) then
				v.Text = "@" .. spoofName
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
	pcall(function() uiConn:Disconnect() end)
end
