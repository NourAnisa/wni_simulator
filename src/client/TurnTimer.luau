--!strict
-- TurnTimer: urgency countdown for the local player's turn (client-only).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("TurnTimerFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local TurnTimerFX = require(fxModule)
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local ALERT_THRESHOLD = 5
local active = false
local lastCountdownSecond = -1
local buzzerPlayed = false

stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local phase = current.phase
	local running = phase == "AwaitRoll" or phase == "AwaitBuy" or phase == "AwaitBuild" or phase == "AwaitCardChoice"
	local mySeat = 0
	if typeof(current.players) == "table" then
		for seat = 1, #current.players do
			local p = current.players[seat]
			if typeof(p) == "table" and p.userId == player.UserId then mySeat = seat break end
		end
	end
	local paused = current.room and current.room.pausedForReconnect == true
	local myTurn = running and not paused and mySeat > 0 and current.activeSeat == mySeat
	if not myTurn then
		if active then TurnTimerFX.stopCountdown() end
		active = false
		lastCountdownSecond = -1
		buzzerPlayed = false
		return
	end
	if typeof(current.deadline) ~= "number" then return end
	local remaining = math.max(0, math.ceil(current.deadline - Workspace:GetServerTimeNow()))
	if remaining <= 0 then
		if not buzzerPlayed then
			buzzerPlayed = true
			TurnTimerFX.stopCountdown()
			TurnTimerFX.playBuzzer()
		end
		active = false
		return
	end
	if remaining <= ALERT_THRESHOLD then
		if not active then
			active = true
			lastCountdownSecond = remaining
			TurnTimerFX.startCountdown(remaining)
		elseif remaining ~= lastCountdownSecond then
			lastCountdownSecond = remaining
			TurnTimerFX.startCountdown(remaining)
		end
	else
		if active then TurnTimerFX.stopCountdown() end
		active = false
		lastCountdownSecond = -1
	end
end)
