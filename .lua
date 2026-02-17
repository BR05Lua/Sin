local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

if RunService:IsServer() then return end

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Persistent lock (survives teleports)
local LOADER_LOCK_NAME = "StepsLoader_Lock"
if CoreGui:FindFirstChild(LOADER_LOCK_NAME) then
    warn("[StepsLoader] Already running")
    return
end
Instance.new("BoolValue", CoreGui).Name = LOADER_LOCK_NAME

local currentPlaceId = game.PlaceId

-- Removes any invisible junk (like a BOM) that might break the script
local function cleanLuaString(str)
    if not str or str == "" then return str end
    local start = 1
    while start <= #str do
        local b = str:byte(start)
        if b == 32 or b == 9 or b == 10 or b == 13 then
            start = start + 1
        elseif (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 95 or
                (b >= 48 and b <= 57) or
                b == 59 or b == 40 or b == 41 or b == 91 or b == 93 or b == 123 or b == 125 then
            break
        else
            start = start + 1
        end
    end
    return str:sub(start)
end

local function safeLoad(url, name)
    local success, result = pcall(game.HttpGet, game, url)
    if not success or type(result) ~= "string" or result == "" then
        warn("[StepsLoader] Failed to fetch:", url)
        return false
    end
    if result:sub(1, 100):match("<[Hh][Tt][Mm][Ll]") then
        warn("[StepsLoader] URL returned HTML, not Lua. Check URL:", url)
        return false
    end
    local cleaned = cleanLuaString(result)
    local fn, err = loadstring(cleaned)
    if not fn then
        warn("[StepsLoader] Loadstring error for", name, ":", err)
        return false
    end
    local ok, execErr = pcall(fn)
    if not ok then
        warn("[StepsLoader] Execution failed for", name, ":", execErr)
        return false
    end
    print("[StepsLoader] Loaded:", name)
    return true
end

-- ===== ADD YOUR SCRIPT URLs BELOW =====
-- Format: { name = "Display Name", url = "https://raw.link/your-script.lua", delay = 0.2 }
local steps = {
    { name = "SOS HUD", url = "https://raw.githubusercontent.com/BR05Lua/Sin/refs/heads/main/SOSMenu.lua", delay = 0.2 },
    { name = "Tag System", url = "https://raw.githubusercontent.com/BR05Lua/Sin/refs/heads/main/BR05TagSystem.lua", delay = 0.1 },
    { name = "Infinite Yield", url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", delay = 0.1 },
    -- To add more, just copy the line above and change the name and url.
    -- { name = "My Script", url = "https://example.com/script.lua", delay = 0.1 },
}

local function runSteps()
    for _, step in ipairs(steps) do
        safeLoad(step.url, step.name)
        if step.delay then task.wait(step.delay) end
    end
    print("[StepsLoader] Fully Loaded.")
end

runSteps()

while true do
    task.wait(1)
    if game.PlaceId ~= currentPlaceId then
        currentPlaceId = game.PlaceId
        task.wait(2)
        runSteps()
    end
end
