--!strict
-- DiceVisualizer: rolls 3D dice on the board when the snapshot dice change (client-only).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("Dice3DFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local Dice3DFX = require(fxModule)
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local lastSnapshot: any = nil
stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local phase = current.phase
	if phase == "Waiting" or phase == "Finished" or phase == "Cancelled" then return end
	local previous = lastSnapshot
	lastSnapshot = current
	if typeof(current.dice) ~= "table" then return end
	local d1, d2 = current.dice[1], current.dice[2]
	if typeof(d1) ~= "number" or typeof(d2) ~= "number" or d1 < 1 or d2 < 1 then return end
	local changed = true
	if typeof(previous) == "table" and typeof(previous.dice) == "table" then
		changed = previous.dice[1] ~= d1 or previous.dice[2] ~= d2
	end
	if changed then
		local skin = (typeof(current.profile) == "table" and current.profile.diceSkin) or "Classic"
		Dice3DFX.rollDice3D(d1, d2, skin)
	end
end)
