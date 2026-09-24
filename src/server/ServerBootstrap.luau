--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local function child(parent: Instance, name: string): Instance
	local result = parent:WaitForChild(name, 5)
	assert(result, parent:GetFullName() .. "." .. name .. " missing")
	return result
end
local shared = child(ReplicatedStorage, "WNI")
local rulesModule = child(shared, "PrototypeRules")
local engineModule = child(script.Parent, "MatchEngine")
assert(rulesModule:IsA("ModuleScript") and engineModule:IsA("ModuleScript"), "Invalid modules")
local Rules = require(rulesModule)
local Engine = require(engineModule)
local buildingVisualsModule = child(script.Parent, "BuildingVisualService")
assert(buildingVisualsModule:IsA("ModuleScript"), "Invalid BuildingVisualService")
local BuildingVisuals = require(buildingVisualsModule)
local islandEnvModule = script.Parent:FindFirstChild("IslandEnvironmentService")
local IslandEnv = if islandEnvModule and islandEnvModule:IsA("ModuleScript") then require(islandEnvModule) else nil
local remotes = child(shared, "Remotes")
local request = child(remotes, "RequestAction")
local updated = child(remotes, "StateUpdated")
assert(request:IsA("RemoteEvent") and updated:IsA("RemoteEvent"), "Invalid remotes")
if not remotes:FindFirstChild("AchievementUnlocked") then
	local re = Instance.new("RemoteEvent")
	re.Name = "AchievementUnlocked"
	re.Parent = remotes
end
if not remotes:FindFirstChild("SpectatorCheer") then
	local sc = Instance.new("RemoteEvent")
	sc.Name = "SpectatorCheer"
	sc.Parent = remotes
end
local board = child(Workspace, "WNIBoard")
if IslandEnv and IslandEnv.generateEnvironment then
	task.spawn(function()
		IslandEnv.generateEnvironment(board)
	end)
end
local tileFolder = child(board, "Tiles")
local pawnFolder = child(board, "Pawns")
local bekasiDisplay = child(child(board, "Decorations"), "BekasiDisplay")
assert(bekasiDisplay:IsA("BasePart"), "Invalid BekasiDisplay")
local tiles: {BasePart} = {}
local pawns: {[number]: BasePart} = {}
local originalColors: {Color3} = {}
local tileSubtitles: {[number]: TextLabel} = {}
local originalSubtitles: {[number]: string} = {}
local originalSubtitleColors: {[number]: Color3} = {}
local buildingsFolder = (board:FindFirstChild("Buildings") :: Folder?)
if not buildingsFolder or not buildingsFolder:IsA("Folder") then
	local created = Instance.new("Folder")
	created.Name = "Buildings"
	created.Parent = board
	buildingsFolder = created
end
local definitions: {Engine.Tile} = {}
for index = 1, Rules.TileCount do
	local tile = child(tileFolder, string.format("Tile_%02d", index))
	assert(tile:IsA("BasePart"), "Invalid tile")
	local name = tile:GetAttribute("DisplayName")
	local kind = tile:GetAttribute("TileKind")
	assert(typeof(name) == "string" and typeof(kind) == "string", "Invalid tile metadata")
	tiles[index] = tile
	originalColors[index] = tile.Color
	local face = tile:FindFirstChild("Face")
	local subtitle = if face then face:FindFirstChild("Subtitle") else nil
	if subtitle and subtitle:IsA("TextLabel") then
		tileSubtitles[index] = subtitle
		originalSubtitles[index] = subtitle.Text
		originalSubtitleColors[index] = subtitle.TextColor3
	end
	definitions[index] = {name = name, kind = kind}
end
for index = 1, Rules.PlayerCount do
	local existing = pawnFolder:FindFirstChild("Pawn_" .. index)
	local pawn: BasePart
	if existing and existing:IsA("BasePart") then
		pawn = existing
	else
		pawn = Instance.new("Part")
		pawn.Name = "Pawn_" .. index
		pawn.Shape = Enum.PartType.Ball
		pawn.Size = Vector3.new(0.8, 0.8, 0.8)
		pawn.Material = Enum.Material.SmoothPlastic
		pawn.Anchored = true
		pawn.CanCollide = false
		pawn.CanTouch = false
		pawn.CanQuery = false
		pawn.CastShadow = false
		pawn.Transparency = 0.7
		pawn.Parent = pawnFolder
	end
	pawns[index] = pawn
end
local roomModule = child(script.Parent, "RoomService")
local profileModule = child(script.Parent, "ProfileService")
local matchmakingModule = child(script.Parent, "MatchmakingService")
local configModule = child(script.Parent, "ExperienceConfig")
local admissionModule = child(script.Parent, "MatchAdmissionService")
local routingModule = child(script.Parent, "MatchRoutingService")
local globalMatchmakingModule = child(script.Parent, "GlobalMatchmakingService")
assert(roomModule:IsA("ModuleScript"), "RoomService missing")
assert(profileModule:IsA("ModuleScript"), "ProfileService missing")
assert(matchmakingModule:IsA("ModuleScript"), "MatchmakingService missing")
assert(configModule:IsA("ModuleScript"), "ExperienceConfig missing")
assert(admissionModule:IsA("ModuleScript"), "MatchAdmissionService missing")
assert(routingModule:IsA("ModuleScript"), "MatchRoutingService missing")
assert(globalMatchmakingModule:IsA("ModuleScript"), "GlobalMatchmakingService missing")
local RoomService = require(roomModule)
local ProfileService = require(profileModule)
local MatchmakingService = require(matchmakingModule)
local ExperienceConfig = require(configModule)
local MatchAdmissionService = require(admissionModule)
local MatchRoutingService = require(routingModule)
local GlobalMatchmakingService = require(globalMatchmakingModule)
local avatarPawnModule = child(script.Parent, "AvatarPawnService")
local botAIModule = child(script.Parent, "BotAIService")
assert(avatarPawnModule:IsA("ModuleScript"), "AvatarPawnService missing")
assert(botAIModule:IsA("ModuleScript"), "BotAIService missing")
local AvatarPawnService = require(avatarPawnModule)
local BotAIService = require(botAIModule)
local avatarPawns = AvatarPawnService.new()
local botAI = BotAIService.new()
local leaderboardModule = script.Parent:FindFirstChild("LeaderboardService")
local LeaderboardService = if leaderboardModule and leaderboardModule:IsA("ModuleScript") then require(leaderboardModule) else nil
local rooms = RoomService.new(function() return Engine.new(definitions) end)
local profiles = ProfileService.new()
local routing = MatchRoutingService.new()
local globalMatchmaking = GlobalMatchmakingService.new()
local useGlobalMatchmaking = globalMatchmaking:isEnabled()
local globalTeleporting: {[number]: string} = {}
local nextGlobalMatchmakingPoll = 0
local function routeAcceptedRoster(roster: {any}): (string, string?)
	if not ExperienceConfig.canTeleportToMatch() or game.PlaceId == ExperienceConfig.MatchPlaceId then
		return "fallback", nil
	end
	local playersToTeleport: {Player} = {}
	local rosterUserIds: {number} = {}
	for index, entry in roster do
		local player = Players:GetPlayerByUserId(entry.userId)
		if not player then
			return "failed", "Roster berubah sebelum teleport ke Match server."
		end
		playersToTeleport[index] = player
		rosterUserIds[index] = entry.userId
	end
	local reservation, reservationError = routing:createReservation()
	if not reservation then
		return "failed", reservationError or "Gagal membuat reserved Match server."
	end
	local teleported, teleportError = routing:teleportPlayers(playersToTeleport, reservation, rosterUserIds)
	if not teleported then
		routing:clearReconnectRoster(rosterUserIds)
		return "failed", teleportError or "Teleport ke Match server gagal."
	end
	return "routed", "Semua pemain menerima. Memindahkan ke Match server..."
end
local matchmaking = MatchmakingService.new(rooms, routeAcceptedRoster)
local engine = rooms.engine
local recordedMatches: {[string]: boolean} = {}
local lastRequest: {[Player]: number} = {}
local animations: {[number]: Tween} = {}
local teleportRetries: {[number]: number} = {}
local isMatchPlace = ExperienceConfig.MatchPlaceId > 0 and game.PlaceId == ExperienceConfig.MatchPlaceId
local isLobbyPlace = ExperienceConfig.LobbyPlaceId > 0 and game.PlaceId == ExperienceConfig.LobbyPlaceId
local admissionMatchId: string? = nil
local admissionRoster: {number}? = nil
local admissionProposalId: string? = nil
local admissionDeadline = 0
local admissionRoomReady = false
local admittedPlayers: {[number]: Player} = {}
local terminalRouteCleared = false

local function sameRoster(left: {number}, right: {number}): boolean
	if #left ~= #right then return false end
	for index = 1, #left do
		if left[index] ~= right[index] then return false end
	end
	return true
end

local function updateBoard()
	for seat, pawn in pawns do
		local participant = engine.players[seat]
		local position = if participant then participant.position else 1
		local destination
		if participant and participant.inBekasi then
			-- Banjir Bandang: pion dievakuasi ke area Bekasi di luar lintasan (README 31).
			local offset = Vector3.new((seat - 2.5) * 1.35, bekasiDisplay.Size.Y / 2 + 1.2, 0)
			destination = bekasiDisplay.CFrame:PointToWorldSpace(offset)
		else
			local tile = tiles[position]
			local offset = Vector3.new((seat - 2.5) * 1.35, 1.2, 0)
			destination = tile.CFrame:PointToWorldSpace(offset)
		end
		
		local transparency = if participant and not participant.eliminated then 0 else 0.7
		
		-- Mini-Me Avatar Pawn: gunakan avatar dinamis jika tersedia
		local avatarModel = avatarPawns:getPawn(seat)
		if avatarModel then
			avatarPawns:setTransparency(seat, transparency)
			if avatarModel.PrimaryPart then
				local currentPos = avatarModel.PrimaryPart.Position
				if (currentPos - destination).Magnitude > 0.05 then
					avatarPawns:tweenToPosition(seat, CFrame.new(destination))
				end
			end
		else
			-- Fallback ke BasePart statis
			pawn.Transparency = transparency
			if (pawn.Position - destination).Magnitude > 0.05 then
				if animations[seat] then animations[seat]:Cancel() end
				local tween = TweenService:Create(pawn, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = destination})
				animations[seat] = tween
				tween:Play()
			end
		end
	end
	for index, tile in tiles do
		local owner = engine.owners[index]
		local isToll = engine.tolls ~= nil and engine.tolls[index] == true
		tile:SetAttribute("OwnerSeat", owner or 0)
		tile:SetAttribute("IsToll", isToll)
		local subtitle = tileSubtitles[index]
		if subtitle then
			subtitle.Text = if isToll then "TOL • TIDAK DIJUAL" else originalSubtitles[index]
			subtitle.TextColor3 = if isToll then Color3.fromRGB(255, 221, 133) else originalSubtitleColors[index]
		end
		local SOLO_TILE_COLORS = {
			[1] = Color3.fromRGB(245, 205, 95),  -- Emas Sultan
			[2] = Color3.fromRGB(120, 190, 255), -- Biru Laut
			[3] = Color3.fromRGB(120, 230, 160), -- Hijau Zamrud
			[4] = Color3.fromRGB(255, 140, 140), -- Merah Delima
		}
		if isToll then
			tile.Color = Color3.fromRGB(65, 76, 83)
		elseif owner then
			if engine.gameMode == "SoloFFA" then
				tile.Color = SOLO_TILE_COLORS[owner] or Color3.fromRGB(200, 200, 200)
			else
				tile.Color = if Rules.teamForSeat(owner) == "A" then Color3.fromRGB(174, 221, 202) else Color3.fromRGB(242, 196, 167)
			end
		else
			tile.Color = originalColors[index]
		end
	end
	for index, tile in tiles do
		local level = engine.buildings[index] or 0
		local isToll = (engine.tolls and engine.tolls[index]) or false
		local owner = engine.owners[index]
		local team = if owner and owner > 0 then (if engine.gameMode == "SoloFFA" then tostring(owner) else Rules.teamForSeat(owner)) else nil
		BuildingVisuals.update(buildingsFolder, tile, index, level, isToll, team)
	end
end
local function clearTerminalRoute()
	if terminalRouteCleared or not isMatchPlace or not admissionRoomReady then return end
	if engine.phase ~= "Finished" and engine.phase ~= "Cancelled" then return end
	local roster = admissionRoster
	if not roster then return end
	terminalRouteCleared = true
	routing:clearReconnectRoster(roster)
end

local function recordFinishedMatch()
	if engine.phase ~= "Finished" then return end
	local matchId = engine.matchId
	if typeof(matchId) ~= "string" or matchId == "" or recordedMatches[matchId] then return end
	recordedMatches[matchId] = true
	local winningTeam: string? = nil
	if string.sub(engine.result, 1, 12) == "TIM A MENANG" then
		winningTeam = "A"
	elseif string.sub(engine.result, 1, 12) == "TIM B MENANG" then
		winningTeam = "B"
	end
	for _, participant in engine.players do
		if participant.isBot == true then continue end
		local outcome = if winningTeam == nil then "draw" elseif participant.team == winningTeam then "win" else "loss"
		task.spawn(function()
			profiles:recordMatch(participant.userId, matchId, outcome, tostring(engine.result or ""))
			if outcome == "win" and (participant.cash or 0) < 1000000 then
				profiles:unlockAchievement(participant.userId, "survive_bankrupt")
			end
			if LeaderboardService then
				local p = profiles:get(participant.userId)
				LeaderboardService.updatePlayerXP(participant.userId, p.xp)
				local player = Players:GetPlayerByUserId(participant.userId)
				if player and outcome == "win" then
					LeaderboardService.trackMission(participant.userId, "win_match", 1)
					LeaderboardService.sendMissions(player)
				end
			end
		end)
	end
end

local function snapshotFor(player: Player): any
	local snapshot = rooms:snapshot(player.UserId)
	local profile = profiles:get(player.UserId)
	snapshot.profile = {
		matches = profile.matches,
		wins = profile.wins,
		losses = profile.losses,
		draws = profile.draws,
		xp = profile.xp or 0,
		level = profile.level or 1,
		coins = profile.coins or 1000,
		title = profile.title or "Warga Biasa",
		diceSkin = profile.diceSkin or "Classic",
		matchHistory = profile.matchHistory or {},
		achievements = profile.achievements or {},
		dailyStreak = profiles:getDailyStreakInfo(player.UserId),
		unlockedSkins = profile.unlockedSkins or {Classic = true},
	}
	snapshot.matchmaking = if useGlobalMatchmaking then globalMatchmaking:snapshot(player.UserId) else matchmaking:snapshot(player.UserId)
	snapshot.routing = {
		isMatchPlace = isMatchPlace,
		canReturnToLobby = isMatchPlace and ExperienceConfig.canReturnToLobby(),
	}
	return snapshot
end

local syncAvatarPawns = function() end
local function broadcast()
	engine = rooms.engine
	recordFinishedMatch()
	clearTerminalRoute()
	syncAvatarPawns()
	updateBoard()
	for _, recipient in Players:GetPlayers() do
		updated:FireClient(recipient, snapshotFor(recipient))
	end
end
local function synchronize(player: Player, message: string?)
	local snapshot = snapshotFor(player)
	snapshot.error = message
	updated:FireClient(player, snapshot)
end

-- Mini-Me Avatar Pawn: sinkronkan avatar dinamis dengan roster server.
local avatarSpawnPending: {[number]: number} = {}
local function cleanupAvatarForSeat(seat: number)
	avatarSpawnPending[seat] = nil
	avatarPawns:destroyPawn(seat)
	if pawns[seat] then
		pawns[seat].Transparency = 0.7
	end
end

syncAvatarPawns = function()
	if not engine or not engine.players then return end
	for seat = 1, Rules.PlayerCount do
		local participant = engine.players[seat]
		local expectedUserId = if participant then participant.userId else nil
		local currentUserId = avatarPawns:getUserId(seat)

		if currentUserId and currentUserId ~= expectedUserId then
			cleanupAvatarForSeat(seat)
			currentUserId = nil
		end

		if not participant then
			if currentUserId then cleanupAvatarForSeat(seat) end
		else
			local player = Players:GetPlayerByUserId(participant.userId)
			if not currentUserId and (player or participant.isBot == true or participant.userId < 0) and avatarSpawnPending[seat] ~= participant.userId then
				avatarSpawnPending[seat] = participant.userId
				local userId = participant.userId
				local position = participant.position or 1
				local tile = tiles[position]
				local offset = Vector3.new((seat - 2.5) * 1.35, 1.2, 0)
				local startCFrame = tile.CFrame * CFrame.new(offset)
				task.spawn(function()
					local prof = if player then profiles:get(userId) else nil
					local roleTitle = if prof then prof.title else (participant.role or "Warga")
					local spawned = avatarPawns:spawnPawn(seat, player, startCFrame, roleTitle, participant.name, userId)
					if avatarSpawnPending[seat] == userId then
						avatarSpawnPending[seat] = nil
					end
					local latestParticipant = engine.players[seat]
					if not latestParticipant or latestParticipant.userId ~= userId then
						if avatarPawns:getUserId(seat) == userId then cleanupAvatarForSeat(seat) end
						return
					end
					if spawned and pawns[seat] then
						pawns[seat].Transparency = 1
						updateBoard()
					end
				end)
			end
		end
	end
end

local function onPlayerAdded(player: Player)
	task.spawn(function()
		profiles:load(player)
	end)
	local now = Workspace:GetServerTimeNow()
	if isLobbyPlace then
		local reconnectRoute = routing:getReconnectRoute(player.UserId)
		if reconnectRoute then
			local reconnectProposalId: string? = nil
			if useGlobalMatchmaking then
				local proposal = globalMatchmaking:getPlayerProposal(player.UserId)
				reconnectProposalId = if proposal then proposal.id else nil
			end
			local teleported, teleportError = routing:teleportReconnect(player, reconnectProposalId)
			if teleported then
				return
			end
			synchronize(player, teleportError or "Reconnect otomatis ke Match server gagal.")
			return
		end
	end
	if isMatchPlace then
		local admission, admissionError = MatchAdmissionService.fromPlayer(player)
		if not admission then
			player:Kick(admissionError or "Akses Match server tidak valid.")
			return
		end
		if admissionMatchId == nil then
			admissionMatchId = admission.matchId
			admissionRoster = table.clone(admission.roster)
			admissionProposalId = admission.matchmakingProposalId
			admissionDeadline = now + ExperienceConfig.RosterArrivalSeconds
		elseif admission.matchId ~= admissionMatchId or admissionRoster == nil or not sameRoster(admissionRoster, admission.roster) then
			player:Kick("Roster atau Match ID tidak sesuai dengan sesi reserved server ini.")
			return
		elseif not admissionRoomReady and admission.matchmakingProposalId ~= admissionProposalId then
			player:Kick("Proposal matchmaking tidak sesuai dengan sesi reserved server ini.")
			return
		end
		if admissionRoomReady then
			if engine.matchId ~= admission.matchId then
				player:Kick("Match ID sesi aktif tidak sesuai.")
				return
			end
			local reconnected = rooms:reconnect(player.UserId, now)
			if reconnected then
				routing:refreshSession(player.UserId)
				broadcast()
			else
				synchronize(player, "Sesi pertandingan sudah berjalan dan akun ini tidak menunggu reconnect.")
			end
			return
		end
		admittedPlayers[player.UserId] = player
		local readyRoster = admissionRoster
		if readyRoster == nil then return end
		local rosterEntries = {}
		for _, userId in readyRoster do
			local admitted = admittedPlayers[userId]
			if not admitted or admitted.Parent ~= Players then
				synchronize(player, "Menunggu anggota roster lain masuk ke Match server...")
				return
			end
			table.insert(rosterEntries, {userId = userId, name = admitted.DisplayName})
		end
		local created, createMessage = rooms:createMatchmadeRoster(rosterEntries)
		if not created then
			player:Kick(createMessage or "Gagal membentuk roster pertandingan.")
			return
		end
		engine = rooms.engine
		engine.matchId = admission.matchId
		admissionRoomReady = true
		broadcast()
		return
	end
	local reconnected = rooms:reconnect(player.UserId, now)
	if reconnected then
		broadcast()
	else
		synchronize(player, nil)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player: Player)
	lastRequest[player] = nil
	teleportRetries[player.UserId] = nil
	local wasGlobalTeleporting = globalTeleporting[player.UserId] ~= nil
	globalTeleporting[player.UserId] = nil
	if isMatchPlace then admittedPlayers[player.UserId] = nil end
	local queueChanged = if useGlobalMatchmaking then globalMatchmaking:handlePlayerLeaving(player.UserId, wasGlobalTeleporting) else matchmaking:removePlayer(player.UserId)
	local roomChanged, heldForReconnect = rooms:markDisconnected(player.UserId, Workspace:GetServerTimeNow(), ExperienceConfig.ReconnectSeconds)
	if isMatchPlace and heldForReconnect then
		routing:armReconnect(player.UserId)
	end
	if queueChanged or roomChanged then broadcast() end
	if not heldForReconnect then profiles:release(player.UserId) end
end)
game:BindToClose(function()
	profiles:saveAll()
	task.wait(1.5)
end)
request.OnServerEvent:Connect(function(player: Player, action: any, revision: any, version: any, targetTile: any)
	local now = Workspace:GetServerTimeNow()
	if now - (lastRequest[player] or -math.huge) < Rules.RequestInterval then return end
	lastRequest[player] = now
	if action == "Sync" then synchronize(player, nil); return end
	if action == "SetDiceSkin" then
		local skinKey = tostring(version or targetTile or revision or "")
		if skinKey ~= "" then
			local ok = profiles:setDiceSkin(player.UserId, skinKey)
			if ok then
				broadcast()
			else
				synchronize(player, "Skin dadu belum terbuka atau tidak valid.")
			end
		end
		return
	end
	if action == "BuyDiceSkin" then
		local skinKey = tostring(version or targetTile or revision or "")
		if skinKey ~= "" then
			local ok, msg = profiles:buyDiceSkin(player.UserId, skinKey)
			if ok then
				broadcast()
			else
				synchronize(player, msg)
			end
		end
		return
	end
	if action == "ClaimDailyStreak" then
		local ok, msg, coins, xp = profiles:claimDailyStreak(player.UserId)
		if ok then
			if LeaderboardService then
				local p = profiles:get(player.UserId)
				LeaderboardService.updatePlayerXP(player.UserId, p.xp)
			end
			broadcast()
		else
			synchronize(player, msg)
		end
		return
	end
	if action == "SpectatorCheer" then
		local cheerRemote = remotes:FindFirstChild("SpectatorCheer")
		if cheerRemote and cheerRemote:IsA("RemoteEvent") then
			local cheererName = player.DisplayName or player.Name
			local reaction = if typeof(targetTile) == "string" then targetTile else "🌸"
			cheerRemote:FireAllClients(player.UserId, cheererName, reaction)
		end
		return
	end
	if action == "ReturnLobby" then
		if typeof(revision) ~= "number" or revision ~= revision or revision % 1 ~= 0 or revision < 0 or revision > 1000000000 then return end
		if typeof(version) ~= "string" or version ~= Rules.Version or targetTile ~= nil then return end
		if not isMatchPlace or not ExperienceConfig.canReturnToLobby() then
			synchronize(player, "Teleport kembali ke Lobby belum tersedia.")
			return
		end
		if not rooms.members[player.UserId] or (engine.phase ~= "Finished" and engine.phase ~= "Cancelled") then
			synchronize(player, "Kembali ke Lobby hanya tersedia setelah pertandingan berakhir.")
			return
		end
		local teleported, teleportError = routing:teleportLobby(player)
		if not teleported then synchronize(player, teleportError) end
		return
	end
	if isMatchPlace and (action == "Queue" or action == "CancelQueue" or action == "AcceptMatch" or action == "DeclineMatch" or action == "CreateRoom" or action == "JoinRoom" or action == "LeaveRoom") then
		synchronize(player, "Aksi lobby tidak tersedia di Match server.")
		return
	end
	if action == "Queue" or action == "CancelQueue" then
		if typeof(revision) ~= "number" or revision ~= revision or revision % 1 ~= 0 or revision < 0 or revision > 1000000000 then return end
		if typeof(version) ~= "string" or version ~= Rules.Version then
			synchronize(player, "Versi aturan tidak cocok.")
			return
		end
		if targetTile ~= nil then return end
		local ok, message
		if useGlobalMatchmaking then
			if rooms.members[player.UserId] then
				synchronize(player, "Kamu sudah berada dalam room.")
				return
			end
			if action == "Queue" then
				if globalMatchmaking:isQueued(player.UserId) or globalMatchmaking:getPlayerProposal(player.UserId) then
					synchronize(player, "Kamu sudah berada dalam matchmaking global.")
					return
				end
				ok, message = globalMatchmaking:enqueue(player, os.time())
				if ok then globalMatchmaking:tryCreateProposal() end
			else
				local proposal = globalMatchmaking:getPlayerProposal(player.UserId)
				if proposal then
					ok, message = globalMatchmaking:respond(player.UserId, false, proposal.revision)
				else
					ok = globalMatchmaking:remove(player.UserId)
					message = if ok then "Keluar dari antrean matchmaking global." else "Gagal keluar dari antrean global."
				end
			end
		else
			if revision ~= matchmaking.revision then
				synchronize(player, "Antrean berubah; coba kembali.")
				return
			end
			if action == "Queue" then
				ok, message = matchmaking:join(player, now)
				if ok then
					local formed, formedMessage = matchmaking:tryFormMatch(now)
					if formed then message = formedMessage end
				end
			else
				ok, message = matchmaking:leave(player.UserId)
			end
		end
		if ok then broadcast() else synchronize(player, message) end
		return
	end
	if action == "AcceptMatch" or action == "DeclineMatch" then
		if typeof(revision) ~= "number" or revision ~= revision or revision % 1 ~= 0 or revision < 0 or revision > 1000000000 then return end
		if typeof(version) ~= "string" or version ~= Rules.Version then
			synchronize(player, "Versi aturan tidak cocok.")
			return
		end
		if targetTile ~= nil then return end
		local ok, message
		if useGlobalMatchmaking then
			ok, message = globalMatchmaking:respond(player.UserId, action == "AcceptMatch", revision)
		else
			if revision ~= matchmaking.revision then
				synchronize(player, "Konfirmasi match berubah; coba kembali.")
				return
			end
			ok, message = matchmaking:respond(player.UserId, action == "AcceptMatch", now)
		end
		if ok then broadcast() else synchronize(player, message) end
		return
	end
	if action == "QuickPlaySolo" then
		if isMatchPlace then
			synchronize(player, "Quick Play hanya tersedia di server utama.")
			return
		end
		if rooms.code ~= nil and rooms:count() == 0 then
			rooms:closeIfEmpty()
		end
		if not rooms.members[player.UserId] then
			if rooms.code == nil then
				local created, createErr = rooms:handle(player.UserId, player.DisplayName, "CreateRoom", rooms.revision, nil, now)
				if not created then
					synchronize(player, createErr or "Gagal membuat room Quick Play.")
					return
				end
			else
				local joined, joinErr = rooms:handle(player.UserId, player.DisplayName, "JoinRoom", rooms.revision, rooms.code, now)
				if not joined then
					synchronize(player, "Room sedang berjalan: " .. tostring(joinErr))
					return
				end
			end
		end
		if engine.phase == "Waiting" then
			engine.gameMode = "SoloFFA"
			botAI:fillEmptySeats(rooms, now)
			botAI:readyWaitingBots(rooms, now)
			local readyOk, readyMsg = engine:handle(player.UserId, "Ready", engine.revision, now, nil)
			if not readyOk then
				synchronize(player, readyMsg or "Gagal menyatakan siap.")
			end
			broadcast()
		else
			synchronize(player, "Pertandingan sudah berjalan.")
		end
		return
	end
	if action == "CreateRoom" or action == "JoinRoom" or action == "LeaveRoom" then
		local matchmakingBusy = if useGlobalMatchmaking then (globalMatchmaking:isQueued(player.UserId) or globalMatchmaking:getPlayerProposal(player.UserId) ~= nil) else (matchmaking:isQueued(player.UserId) or matchmaking:isPending(player.UserId))
		if action ~= "LeaveRoom" and matchmakingBusy then
			synchronize(player, "Selesaikan matchmaking terlebih dahulu.")
			return
		end
		if rooms.code ~= nil and rooms:count() == 0 then
			rooms:closeIfEmpty()
		end
		if not useGlobalMatchmaking and action == "CreateRoom" and (matchmaking:count() > 0 or matchmaking:hasProposal()) then
			synchronize(player, "Matchmaking sedang aktif di server ini.")
			return
		end
		if typeof(revision) ~= "number" or revision ~= revision or revision % 1 ~= 0 or revision < 0 or revision > 1000000000 then return end
		if typeof(version) ~= "string" or version ~= Rules.Version then
			synchronize(player, "Versi aturan tidak cocok.")
			return
		end
		if action == "JoinRoom" then
			if typeof(targetTile) ~= "string" or #targetTile > 6 then
				synchronize(player, "Kode room tidak sah.")
				return
			end
		elseif targetTile ~= nil then
			return
		end
		local ok, message = rooms:handle(player.UserId, player.DisplayName, action, revision, targetTile, now)
		if ok then broadcast() else synchronize(player, message) end
		return
	end
	if not rooms.members[player.UserId] then
		synchronize(player, "Buat room atau gabung dengan kode terlebih dahulu.")
		return
	end
	if rooms:hasReconnectGrace() then
		synchronize(player, "Pertandingan sedang dipause menunggu pemain reconnect.")
		return
	end
	if action == "FillBots" then
		if not isMatchPlace and engine.phase == "Waiting" and rooms:count() < Rules.PlayerCount then
			botAI:fillEmptySeats(rooms, now)
			botAI:readyWaitingBots(rooms, now)
			broadcast()
		end
		return
	end
	if action ~= "Ready" and action ~= "Roll" and action ~= "Buy" and action ~= "Skip" and action ~= "Build" and action ~= "SkipBuild" and action ~= "Bail" and action ~= "Rematch" and action ~= "PlayCard" and action ~= "SelectCardLand" and action ~= "SkipCardChoice" and action ~= "ChooseTeam" and action ~= "RequestTeamSwap" and action ~= "AcceptTeamSwap" and action ~= "CancelTeamSwap"
		and action ~= "BailoutTeammate" and action ~= "BailTeammateFromJail" and action ~= "BuyStock" and action ~= "SellStock" and action ~= "SetGameMode" and action ~= "SelectRole" and action ~= "ClaimCoinFlip" then return end
	if typeof(revision) ~= "number" or revision ~= revision or revision % 1 ~= 0 or revision < 0 or revision > 1000000000 then return end
	if typeof(version) ~= "string" or version ~= Rules.Version then
		synchronize(player, "Versi aturan tidak cocok.")
		return
	end
	if action == "Build" or action == "SelectCardLand" then
		if typeof(targetTile) ~= "number" or targetTile ~= targetTile or targetTile % 1 ~= 0 or targetTile < 1 or targetTile > Rules.TileCount then
			synchronize(player, "Pilih tanah yang sah untuk dibangun.")
			return
		end
	elseif action == "RequestTeamSwap" then
		if typeof(targetTile) ~= "number" or targetTile ~= targetTile or targetTile % 1 ~= 0 or targetTile < 1 or targetTile > Rules.PlayerCount then
			synchronize(player, "Pilih pemain tujuan yang sah.")
			return
		end
	elseif action == "ChooseTeam" then
		if targetTile ~= "A" and targetTile ~= "B" then
			synchronize(player, "Pilih Tim A atau Tim B.")
			return
		end
	elseif action == "SetGameMode" or action == "SelectRole" then
		if typeof(targetTile) ~= "string" then
			synchronize(player, "Pilihan tidak sah.")
			return
		end
	elseif action == "BuyStock" or action == "SellStock" then
		if typeof(targetTile) ~= "table" then
			synchronize(player, "Parameter saham tidak sah.")
			return
		end
	elseif action == "BailoutTeammate" or action == "BailTeammateFromJail" then
		-- targetTile can be nil
	elseif action == "PlayCard" then
		if typeof(targetTile) ~= "table" then
			synchronize(player, "Pilihan kartu tidak sah.")
			return
		end
		local cardId, choice = targetTile.cardId, targetTile.choice
		if (cardId ~= "KaburAjaDulu" and cardId ~= "OrangDalam") or typeof(choice) ~= "number" then
			synchronize(player, "Kartu atau pilihan tidak sah.")
			return
		end
		local maximum = if cardId == "KaburAjaDulu" then Rules.TileCount else 6
		if choice ~= choice or choice % 1 ~= 0 or choice < 1 or choice > maximum then
			synchronize(player, "Pilihan di luar batas.")
			return
		end
		targetTile = {cardId = cardId, choice = choice}
	elseif targetTile ~= nil then
		synchronize(player, "Target tanah tidak berlaku untuk aksi ini.")
		return
	end
	if action == "Ready" and not isMatchPlace and engine.phase == "Waiting" and rooms:count() < Rules.PlayerCount then
		if revision ~= engine.revision then
			synchronize(player, "Keadaan berubah; coba kembali.")
			return
		end
		botAI:fillEmptySeats(rooms, now)
		botAI:readyWaitingBots(rooms, now)
		revision = engine.revision
	end
	local ok, message = engine:handle(player.UserId, action, revision, now, targetTile)
	if ok then
		broadcast()
		task.spawn(function()
			local seat = engine:seatFor(player.UserId)
			if not seat then return end
			if action == "PlayCard" then
				profiles:unlockAchievement(player.UserId, "card_master")
			elseif action == "Bail" then
				profiles:unlockAchievement(player.UserId, "escape_jail")
			elseif action == "Buy" then
				local landCount = 0
				for _, owner in engine.owners do
					if owner == seat then landCount += 1 end
				end
				if landCount >= 4 then
					profiles:unlockAchievement(player.UserId, "land_tycoon")
				end
				-- Monopoli check
				local myTeam = engine.players[seat] and engine.players[seat].team
				if myTeam then
					for _, cluster in ipairs({
						{2, 3, 5, 6, 8}, {10, 11, 13, 14, 16},
						{18, 19, 21, 22, 24}, {26, 27, 29, 30, 32}, {34, 35, 37, 38, 40},
					}) do
						local allMine = true
						for _, t in ipairs(cluster) do
							local o = engine.owners[t]
							if not o or (engine.players[o] and engine.players[o].team ~= myTeam) then
								allMine = false; break
							end
						end
						if allMine then
							profiles:unlockAchievement(player.UserId, "monopoly_king")
							break
						end
					end
				end
			end
		end)
	else
		synchronize(player, message)
	end
end)
local function markGlobalTeleportFailure(player: Player, route: any, reason: string)
	routing:clearReconnectRoster(route.roster)
	if useGlobalMatchmaking then
		local proposalId = globalTeleporting[player.UserId]
		if not proposalId then
			local proposal = globalMatchmaking:getPlayerProposal(player.UserId)
			proposalId = if proposal then proposal.id else nil
		end
		if proposalId then globalMatchmaking:markRouteFailed(proposalId, reason) end
	end
	globalTeleporting[player.UserId] = nil
	synchronize(player, reason)
end

TeleportService.TeleportInitFailed:Connect(function(player: Player, _result: Enum.TeleportResult, errorMessage: string, placeId: number, _options: TeleportOptions)
	if not isLobbyPlace or placeId ~= ExperienceConfig.MatchPlaceId then return end
	local route = routing:getReconnectRoute(player.UserId)
	if not route then return end
	local retryNumber = (teleportRetries[player.UserId] or 0) + 1
	teleportRetries[player.UserId] = retryNumber
	if retryNumber > ExperienceConfig.TeleportRetryCount then
		markGlobalTeleportFailure(player, route, "Teleport ke Match gagal setelah beberapa percobaan. Kamu dapat antre kembali.")
		return
	end
	task.delay(1, function()
		if player.Parent ~= Players then return end
		local retried, retryError = routing:teleportReconnect(player, globalTeleporting[player.UserId])
		if not retried then
			if retryNumber >= ExperienceConfig.TeleportRetryCount then
				markGlobalTeleportFailure(player, route, retryError or errorMessage or "Teleport ke Match gagal.")
			else
				synchronize(player, retryError or "Teleport gagal; mencoba ulang...")
			end
		end
	end)
end)
local function processGlobalMatchmaking()
	if not useGlobalMatchmaking then return false end
	local changed = false
	local proposalCreated = globalMatchmaking:tryCreateProposal()
	if proposalCreated then changed = true end
	local handled: {[string]: boolean} = {}
	for _, localPlayer in Players:GetPlayers() do
		local proposal = globalMatchmaking:getPlayerProposal(localPlayer.UserId)
		if proposal and not handled[proposal.id] then
			handled[proposal.id] = true
			local state, resolved = globalMatchmaking:resolveProposal(proposal.id)
			if resolved then
				if state == "declined" then
					globalMatchmaking:requeue(resolved, resolved.declinedBy, false)
					changed = true
				elseif state == "expired" then
					globalMatchmaking:requeue(resolved, nil, true)
					changed = true
				elseif state == "route_failed" then
					local rosterUserIds: {number} = {}
					for index, entry in resolved.roster do rosterUserIds[index] = entry.userId end
					routing:clearReconnectRoster(rosterUserIds)
					for _, entry in resolved.roster do
						local rosterPlayer = Players:GetPlayerByUserId(entry.userId)
						if rosterPlayer then
							globalTeleporting[entry.userId] = nil
							globalMatchmaking:remove(entry.userId)
							synchronize(rosterPlayer, resolved.routeFailed or "Match global dibatalkan karena salah satu teleport gagal. Silakan antre kembali.")
						end
					end
					changed = true
				elseif state == "accepted" then
					if resolved.route == nil and globalMatchmaking:claimRouting(resolved.id) then
						local reservation, reservationError = routing:createReservation()
						if reservation then
							if not globalMatchmaking:publishRoute(resolved.id, reservation) then
								globalMatchmaking:releaseRoutingClaim(resolved.id)
							end
						else
							globalMatchmaking:releaseRoutingClaim(resolved.id)
							warn("[WNI] Global matchmaking reservation failed: " .. tostring(reservationError))
						end
						local _, refreshed = globalMatchmaking:resolveProposal(resolved.id)
						if refreshed then resolved = refreshed end
					end
					if typeof(resolved.route) == "table" and typeof(resolved.route.matchId) == "string" and typeof(resolved.route.accessCode) == "string" then
						local rosterUserIds: {number} = {}
						local localPlayers: {Player} = {}
						for index, entry in resolved.roster do
							rosterUserIds[index] = entry.userId
							local rosterPlayer = Players:GetPlayerByUserId(entry.userId)
							if rosterPlayer and globalTeleporting[entry.userId] ~= resolved.id then
								table.insert(localPlayers, rosterPlayer)
							end
						end
						if #localPlayers > 0 then
							for _, rosterPlayer in localPlayers do globalTeleporting[rosterPlayer.UserId] = resolved.id end
							local reservation = {
								matchId = resolved.route.matchId,
								accessCode = resolved.route.accessCode,
								privateServerId = if typeof(resolved.route.privateServerId) == "string" then resolved.route.privateServerId else "",
								createdAt = if typeof(resolved.route.createdAt) == "number" then resolved.route.createdAt else os.time(),
								proposalId = resolved.id,
							}
							local teleported, teleportError = routing:teleportPlayers(localPlayers, reservation, rosterUserIds)
							if not teleported then
								local failureReason = teleportError or "Teleport global ke Match server gagal."
								globalMatchmaking:markRouteFailed(resolved.id, failureReason)
								routing:clearReconnectRoster(rosterUserIds)
								for _, rosterPlayer in localPlayers do
									globalTeleporting[rosterPlayer.UserId] = nil
									synchronize(rosterPlayer, failureReason)
								end
							else
								changed = true
							end
						end
					end
				end
			end
		end
	end
	return changed
end

for _, player in Players:GetPlayers() do onPlayerAdded(player) end
updateBoard()
task.spawn(function()
	while script:IsDescendantOf(game) do
		local now = Workspace:GetServerTimeNow()
		if isMatchPlace and not admissionRoomReady and admissionDeadline > 0 and now >= admissionDeadline then
			admissionDeadline = 0
			if admissionProposalId then
				globalMatchmaking:markRouteFailed(admissionProposalId, "Roster pertandingan tidak lengkap dalam batas waktu kedatangan ke Match server.")
			end
			if admissionRoster then routing:clearReconnectRoster(admissionRoster) end
			for _, admitted in admittedPlayers do
				if admitted.Parent == Players then
					local returned, returnError = routing:teleportLobby(admitted)
					if not returned then
						admitted:Kick(returnError or "Roster pertandingan tidak lengkap dalam batas waktu kedatangan.")
					end
				end
			end
			table.clear(admittedPlayers)
		end
		local reconnectExpired, expiredUserIds = rooms:expireReconnects(now)
		if reconnectExpired then
			for _, userId in expiredUserIds do profiles:release(userId) end
		end
		local engineChanged = false
		if not rooms:hasReconnectGrace() then
			engineChanged = botAI:tick(rooms, now)
			if not engineChanged then engineChanged = engine:tick(now) end
		end
		local matchmakingChanged = false
		if useGlobalMatchmaking then
			if now >= nextGlobalMatchmakingPoll then
				nextGlobalMatchmakingPoll = now + 1
				matchmakingChanged = processGlobalMatchmaking()
			end
		else
			local matchmakingRevision = matchmaking.revision
			matchmakingChanged = matchmaking:tick(now)
			if not matchmaking:hasProposal() and matchmaking:count() >= Rules.PlayerCount then
				matchmaking:tryFormMatch(now)
			end
			if matchmaking.revision ~= matchmakingRevision then matchmakingChanged = true end
		end
		if LeaderboardService then LeaderboardService.tick(now) end
		if reconnectExpired or engineChanged or matchmakingChanged then broadcast() end
		task.wait(0.25)
	end
end)
print("[WNI] Prototype server initialized: four players, authoritative turns and economy.")
