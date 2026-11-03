
-- Emergency Hamburg Avatar Loader
-- For use in your own Roblox experience

local Players = game:GetService("Players")
local cfg = getgenv().Config

if not cfg then
    warn("Config not found!")
    return
end

local victim = tonumber(cfg.victim)
local helper = cfg.helper or ""

local premium = cfg.premium or false
local verified = cfg.verified or false

if not victim then
    warn("Invalid victim UserId!")
    return
end

-- Select target character
local player

if helper ~= "" then
    player = Players:FindFirstChild(helper)
else
    player = Players.LocalPlayer
end

if not player then
    warn("Helper player not found!")
    return
end

-- Load avatar appearance
local function LoadAvatar(character)
    local humanoid = character:WaitForChild("Humanoid")

    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(victim)
    end)

    if not success then
        warn("Failed to get avatar:", description)
        return
    end

    local applied, err = pcall(function()
        humanoid:ApplyDescriptionAsync(description)
    end)

    if not applied then
        warn("Failed to apply avatar:", err)
        return
    end

    print("Avatar appearance loaded!")
end

if player.Character then
    task.spawn(LoadAvatar, player.Character)
end

player.CharacterAdded:Connect(function(character)
    task.spawn(LoadAvatar, character)
end)

print("Avatar loader started!")
