local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

if RunService:IsServer() then return end

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local playerGui = player:WaitForChild("PlayerGui")

local LOADER_LOCK_NAME = "StepsLoader_Lock"
if CoreGui:FindFirstChild(LOADER_LOCK_NAME) then
    warn("[StepsLoader] Already running")
    return
end
Instance.new("BoolValue", CoreGui).Name = LOADER_LOCK_NAME

local currentPlaceId = game.PlaceId

local function safeLoad(url)
    local success, result = pcall(game.HttpGet, game, url)
    if success and result and result ~= "" then
        local fn, err = loadstring(result)
        if fn then
            pcall(fn)
        else
            warn("[StepsLoader] Loadstring error:", err, "for:", url)
        end
    else
        warn("[StepsLoader] Failed to fetch:", url)
    end
end

local steps = {
    { name = "SOS HUD", url = "https://raw.githubusercontent.com/BR05Lua/.../refs/heads/main/SOSMenu.lua", delay = 0.2 },
    { name = "Tag System", url = "https://raw.githubusercontent.com/BR05Lua/.../refs/heads/main/BR05TagSystem.lua", delay = 0.1 },
    { name = "Infinite Yield", url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", delay = 0.1 },
    -- if u guys wanna use this loader and make your own then remember this bellow
    -- { name = "My Script", url = "https://example.com/script.lua", delay = 0.1 },
}

local function runSteps()
    for _, step in ipairs(steps) do
        pcall(safeLoad, step.url)
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
