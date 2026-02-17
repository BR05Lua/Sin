local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

if RunService:IsServer() then return end

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local LOADER_LOCK_NAME = "StepsLoader_Lock"
if CoreGui:FindFirstChild(LOADER_LOCK_NAME) then
    warn("[StepsLoader] Already running")
    return
end
Instance.new("BoolValue", CoreGui).Name = LOADER_LOCK_NAME

local currentPlaceId = game.PlaceId

local function cleanLuaString(str)
    if not str or str == "" then return str end
    local bytes = {str:byte(1, 3)}
    if #bytes >= 3 and bytes[1] == 239 and bytes[2] == 187 and bytes[3] == 191 then
        str = str:sub(4)
    end
    str = str:gsub("^%s+", "")
    return str
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

local steps = {
    { name = "SOS HUD", url = "https://raw.githubusercontent.com/BR05Lua/Sin/refs/heads/main/SOSMenu.lua", delay = 0.2 },
    { name = "Tag System", url = "https://raw.githubusercontent.com/BR05Lua/Sin/refs/heads/main/BR05TagSystem.lua", delay = 0.1 },
    { name = "Infinite Yield", url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", delay = 0.1 },
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
