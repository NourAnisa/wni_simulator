--!strict
-- WNI client controller: renders server snapshots, forwards button intents. Server is authoritative.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local function waitFor(parent: Instance, name: string): Instance
	local found = parent:WaitForChild(name, 10)
	assert(found, "WNI missing: " .. parent:GetFullName() .. "." .. name)
	return found
end

local shared = waitFor(RS, "WNI")
local Rules = require(waitFor(shared, "PrototypeRules") :: ModuleScript)
local Tarif = require(waitFor(shared, "TarifData") :: ModuleScript)
local remotes = waitFor(shared, "Remotes")
local requestAction = waitFor(remotes, "RequestAction") :: RemoteEvent
local stateUpdated = waitFor(remotes, "StateUpdated") :: RemoteEvent

local gui = script.Parent :: ScreenGui
local root = waitFor(gui, "Root")
local interfaceScale = waitFor(root, "InterfaceScale") :: UIScale

-- Responsive UI: sesuaikan skala seluruh antarmuka secara adaptif terhadap ukuran layar / device
local camera = WS.CurrentCamera or WS:WaitForChild("Camera") :: Camera
local function updateInterfaceScale()
	local vp = camera.ViewportSize
	if vp.X <= 0 or vp.Y <= 0 then return end
	-- Resolusi baseline standar: 1366 x 768
	local scaleX = vp.X / 1366
	local scaleY = vp.Y / 768
	local targetScale = math.min(scaleX, scaleY)
	interfaceScale.Scale = math.clamp(targetScale, 0.52, 1.25)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateInterfaceScale)
WS:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCam = WS.CurrentCamera
	if newCam then
		camera = newCam
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateInterfaceScale)
		updateInterfaceScale()
	end
end)
task.spawn(updateInterfaceScale)

local header = waitFor(root, "Header")
local hSub = waitFor(header, "Subtitle") :: TextLabel
local hRound = waitFor(header, "Round") :: TextLabel
local hConn = waitFor(header, "Connection") :: TextLabel
local hProfile = waitFor(header, "ProfileStats") :: TextLabel
local roster = waitFor(root, "Roster")
local rHead = waitFor(roster, "Heading") :: TextLabel

type SeatView = {frame: Frame, name: TextLabel, balance: TextLabel, team: TextLabel, avatar: TextLabel, base: Color3}
local seats: {SeatView} = {}
for seat = 1, Rules.PlayerCount do
	local f = waitFor(roster, "Seat" .. seat) :: Frame
	seats[seat] = {
		frame = f,
		name = waitFor(f, "PlayerName") :: TextLabel,
		balance = waitFor(f, "Balance") :: TextLabel,
		team = waitFor(f, "Team") :: TextLabel,
		avatar = waitFor(f, "AvatarStatus") :: TextLabel,
		base = f.BackgroundColor3,
	}
end

local panel = waitFor(root, "ActionPanel")
local status = waitFor(panel, "Status") :: TextLabel
local hint = waitFor(panel, "Hint") :: TextLabel
local buttons: {[string]: TextButton} = {
	Roll = waitFor(panel, "RollButton") :: TextButton,
	Buy = waitFor(panel, "BuyButton") :: TextButton,
	Ready = waitFor(panel, "ReadyButton") :: TextButton,
	Skip = waitFor(panel, "SkipButton") :: TextButton,
	Build = waitFor(panel, "BuildButton") :: TextButton,
	SkipBuild = waitFor(panel, "SkipBuildButton") :: TextButton,
	Bail = waitFor(panel, "BailButton") :: TextButton,
	ReturnLobby = waitFor(panel, "ReturnLobbyButton") :: TextButton,
}
local btnBase: {[string]: Color3} = {}
for k, b in buttons do
	btnBase[k] = b.TextColor3
end
local startupViewport = if WS.CurrentCamera then WS.CurrentCamera.ViewportSize else Vector2.new(1920, 1080)
local studioPhoneViewport = RunService:IsStudio() and startupViewport.X <= 1000 and startupViewport.Y <= 500
local mobileTouchMode = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or studioPhoneViewport

local function enforceMinimumTouchTarget(instance: Instance)
	if not instance:IsA("TextButton") then return end
	local existing = instance:FindFirstChild("MobileMinTouchTarget")
	local constraint = if existing and existing:IsA("UISizeConstraint") then existing else nil
	if not constraint then
		constraint = Instance.new("UISizeConstraint")
		constraint.Name = "MobileMinTouchTarget"
		constraint.Parent = instance
	end
	constraint.MinSize = if mobileTouchMode then Vector2.new(44, 28) else Vector2.zero
end

for _, descendant in root:GetDescendants() do
	enforceMinimumTouchTarget(descendant)
end
root.DescendantAdded:Connect(enforceMinimumTouchTarget)

local desktopActionPanelPosition = panel.Position
local desktopActionPanelSize = panel.Size
local desktopStatusPosition = status.Position
local desktopStatusSize = status.Size
local desktopHintPosition = hint.Position
local desktopHintSize = hint.Size
local desktopActionButtons: {[string]: {position: UDim2, size: UDim2}} = {}
for key, button in buttons do
	desktopActionButtons[key] = {position = button.Position, size = button.Size}
end

local propTile = waitFor(waitFor(root, "PropertyPanel"), "TileName") :: TextLabel
local propDetail = waitFor(waitFor(root, "PropertyPanel"), "Details") :: TextLabel
local dicePanel = waitFor(root, "DicePanel") :: Frame
local diceText = waitFor(dicePanel, "Result") :: TextLabel
local logPanel = waitFor(root, "LogPanel") :: Frame
local logText = waitFor(logPanel, "Entries") :: TextLabel

local TEAMC: {[string]: Color3} = {A = Color3.fromRGB(174, 221, 202), B = Color3.fromRGB(242, 196, 167)}
local HINTC = hint.TextColor3
local ERRC = Color3.fromRGB(255, 120, 120)
local OFFC = Color3.fromRGB(150, 150, 150)
local KINDS: {[string]: string} = {Start = "Petak START", Property = "Tanah", Tax = "Pajak Tahunan", Parking = "Parkiran Pungli", Fate = "Kartu Takdir", Disaster = "Kartu Musibah", Prison = "LAPAS", Court = "Pengadilan"}
local PHASES: {[string]: string} = {Waiting = "Lobi: menyatakan siap", AwaitRoll = "Menunggu lemparan dadu", AwaitBuy = "Keputusan pembelian tanah", AwaitBuild = "Kesempatan membangun", AwaitCardChoice = "Memilih tanah untuk kartu", Finished = "Pertandingan selesai", Cancelled = "Sesi dibatalkan"}
local function jailLabel(p: any): string
	return "  [LAPAS " .. p.jailTries .. "/3]"
end
local function bekasiLabel(p: any): string
	return if p.inBekasi then "  [BEKASI]" else ""
end

local propertyPanel = waitFor(root, "PropertyPanel") :: Frame
local cardToast = waitFor(root, "CardToast") :: Frame
local cardToastTitle = waitFor(cardToast, "Title") :: TextLabel
local cardToastMessage = waitFor(cardToast, "Message") :: TextLabel
local cardModal = waitFor(root, "CardDrawModal") :: Frame
local cardModalUI = {
	deck = waitFor(cardModal, "DeckLabel") :: TextLabel,
	title = waitFor(cardModal, "CardTitle") :: TextLabel,
	dice = waitFor(cardModal, "DiceBadge") :: TextLabel,
	desc = waitFor(cardModal, "CardDesc") :: TextLabel,
	confirm = waitFor(cardModal, "Confirm") :: TextButton,
	stroke = waitFor(cardModal, "ModalStroke") :: UIStroke,
	scale = waitFor(cardModal, "ModalScale") :: UIScale,
}
local specialToast = waitFor(root, "SpecialTileToast") :: Frame
local specialToastUI = {
	icon = waitFor(specialToast, "Icon") :: TextLabel,
	title = waitFor(specialToast, "Title") :: TextLabel,
	message = waitFor(specialToast, "Message") :: TextLabel,
	stroke = waitFor(specialToast, "AccentStroke") :: UIStroke,
}
local victoryPanel = waitFor(root, "VictoryPanel") :: Frame
local victoryContent = waitFor(victoryPanel, "Content") :: CanvasGroup
local victoryUI = {
	content = victoryContent,
	scale = waitFor(victoryContent, "VictoryScale") :: UIScale,
	title = waitFor(victoryContent, "Title") :: TextLabel,
	status = waitFor(victoryContent, "Status") :: TextLabel,
	scores = waitFor(victoryContent, "Scores") :: TextLabel,
	rematch = waitFor(victoryContent, "Rematch") :: TextButton,
	returnLobby = waitFor(victoryContent, "ReturnLobby") :: TextButton,
}
local trophyBanner = victoryContent:FindFirstChild("TrophyBanner") :: TextLabel?
local trophyStroke = if trophyBanner then trophyBanner:FindFirstChild("TrophyStroke") :: UIStroke? else nil
local buildPicker = waitFor(propertyPanel, "BuildPicker") :: Frame
local previousBuild = waitFor(buildPicker, "Previous") :: TextButton
local nextBuild = waitFor(buildPicker, "Next") :: TextButton
local buildCount = waitFor(buildPicker, "Count") :: TextLabel
local originalPanelSize = propertyPanel.Size
local originalDetailSize = propDetail.Size
local selectedBuildTile: number? = nil
local buildChoices: {number} = {}
local roomPanel = waitFor(root, "RoomPanel") :: Frame
local roomHeading = waitFor(roomPanel, "Heading") :: TextLabel
local roomInfo = waitFor(roomPanel, "RoomInfo") :: TextLabel
local roomMessage = waitFor(roomPanel, "Message") :: TextLabel
local roomCode = waitFor(roomPanel, "CodeInput") :: TextBox
local createRoom = waitFor(roomPanel, "CreateButton") :: TextButton
local joinRoom = waitFor(roomPanel, "JoinButton") :: TextButton
local leaveRoom = waitFor(roomPanel, "LeaveButton") :: TextButton
local matchmakingPanel = waitFor(root, "MatchmakingPanel") :: Frame
local matchmakingStatus = waitFor(matchmakingPanel, "Status") :: TextLabel
local queueButton = waitFor(matchmakingPanel, "QueueButton") :: TextButton
local cancelQueueButton = waitFor(matchmakingPanel, "CancelQueueButton") :: TextButton
local acceptMatchButton = waitFor(matchmakingPanel, "AcceptMatchButton") :: TextButton
local declineMatchButton = waitFor(matchmakingPanel, "DeclineMatchButton") :: TextButton
local lastRoomRequest = -math.huge
local lastQueueRequest = -math.huge
local latest: any = nil
local errUntil = 0
local errText = ""
local audio: any = nil
-- Late-bound UI helpers: forward-declared so early-defined refresh functions can call them.
local playPop: any = nil
local setRollPulse: any = nil
local setSeatGlow: any = nil
local refreshBotButton: any = nil
local showActionBanner: any = nil
local focusTile: any = nil
local restoreOverview: any = nil
local cameraToggle: TextButton? = nil
local applyResponsiveLayout: any = nil

local function send(action: string)
	local snap = latest
	if not snap then return end
	if action == "Build" then
		if not selectedBuildTile then return end
		requestAction:FireServer(action, snap.revision, snap.version, selectedBuildTile)
	else
		requestAction:FireServer(action, snap.revision, snap.version)
	end
end

local allowed: {[string]: boolean} = {}
local function setButton(key: string, enabled: boolean, text: string?)
	local b = buttons[key]
	allowed[key] = enabled
	b.Visible = enabled
	b.AutoButtonColor = enabled
	b.Active = enabled
	b.Selectable = enabled
	b.TextColor3 = if enabled then btnBase[key] else OFFC
	if text then b.Text = text end
end

local function applyActionLayout()
	if applyResponsiveLayout and WS.CurrentCamera then
		applyResponsiveLayout(WS.CurrentCamera.ViewportSize)
	end
end
applyActionLayout()

local function findMySeat(snap: any): number
	local ps = snap.players
	for seat = 1, #ps do
		if ps[seat].userId == player.UserId then return seat end
	end
	return 0
end

local function describeTile(snap: any, position: number, mySeat: number): (string, string)
	local board = WS:FindFirstChild("WNIBoard")
	local tilesFolder = board and board:FindFirstChild("Tiles")
	local part = if tilesFolder then tilesFolder:FindFirstChild(string.format("Tile_%02d", position)) else nil
	local tileName = if part and typeof(part:GetAttribute("DisplayName")) == "string"
		then part:GetAttribute("DisplayName")
		else string.format("Petak %d", position)
	local kind = if part and typeof(part:GetAttribute("TileKind")) == "string" then part:GetAttribute("TileKind") else ""
	local lines: {string} = {KINDS[kind] or (if #kind > 0 then kind else "Petak")}
	if kind == "Property" and snap.tolls and snap.tolls[position] == true then
		return tileName .. " — TOL", "TOL hingga pertandingan ini berakhir.\nTidak dapat dibeli atau dibangun.\nTidak ada sewa pada aturan prototipe saat ini."
	end
	if kind == "Property" then
		local ownerSeat: number = snap.owners[position] or 0
		local level = (snap.buildings and snap.buildings[position]) or 0
		local levelNames = {"Tanah kosong", "Subsidi 1", "Subsidi 2", "Rumah OKB"}
		local tariff = Tarif.get(position)
		local rent = tariff.rents[level + 1]
		table.insert(lines, "Harga Tanah: " .. Rules.formatMoney(tariff.price))
		table.insert(lines, "Level Bangunan: " .. levelNames[level + 1])
		table.insert(lines, "Sewa Saat Ini: " .. Rules.formatMoney(rent))
		if ownerSeat <= 0 then
			table.insert(lines, "Pemilik: Belum dimiliki")
		else
			local owner = snap.players[ownerSeat]
			local mine = if mySeat > 0 then snap.players[mySeat] else nil
			if owner then
				if mySeat > 0 and ownerSeat == mySeat then
					table.insert(lines, "Pemilik: Kamu • bebas sewa")
				elseif owner.rentSuppressed then
					table.insert(lines, "Pemilik: " .. owner.name .. " • sewa dinonaktifkan")
				elseif owner.inJail then
					table.insert(lines, "Pemilik: " .. owner.name .. " • ditahan, sewa masuk Negara termasuk dari rekan")
				elseif mine and mine.team == owner.team then
					table.insert(lines, "Pemilik: " .. owner.name .. " (rekan Tim " .. owner.team .. ") • bebas sewa")
				else
					table.insert(lines, "Pemilik: " .. owner.name .. " (Tim " .. owner.team .. ") • lawan membayar sewa ke pemilik")
				end
			end
		end
	elseif kind == "Tax" then
		table.insert(lines, "Denda tetap: " .. Rules.formatMoney(Rules.TaxAmount))
	elseif kind == "Parking" then
		table.insert(lines, "Biaya parkir: " .. Rules.formatMoney(Rules.ParkingAmount))
	elseif kind == "Fate" then
		table.insert(lines, "Kartu Takdir asli: efek bervariasi per kartu (beberapa butuh dadu).")
	elseif kind == "Disaster" then
		table.insert(lines, "Kartu Musibah asli: efek bervariasi per kartu (beberapa butuh dadu).")
	elseif kind == "Prison" then
		table.insert(lines, "Mendarat biasa: kunjungan. Jika ditahan: dadu kembar, bayar jaminan, atau bebas pada giliran ketiga (aturan prototipe).")
	elseif kind == "Court" then
		table.insert(lines, "Satu dadu: 5-6 menerima kompensasi; 3-4 denda dan LAPAS; 1-2 bayar 50% uang tunai dan LAPAS.")
	elseif kind == "Start" then
		table.insert(lines, "Gaji " .. Rules.formatMoney(Rules.StartSalary) .. " saat melewati START.")
	end
	return tileName, table.concat(lines, "\n")
end

local function refreshBuildPicker(snap: any)
	local mySeat = findMySeat(snap)
	local choosing = snap.phase == "AwaitBuild" and mySeat > 0 and snap.activeSeat == mySeat and not snap.players[mySeat].eliminated
	buildPicker.Visible = choosing
	buildChoices = {}
	if not choosing then
		selectedBuildTile = nil
		propertyPanel.Size = originalPanelSize
		propDetail.Size = originalDetailSize
		return
	end
	local participant = snap.players[mySeat]
	local board = WS:FindFirstChild("WNIBoard")
	local tilesFolder = board and board:FindFirstChild("Tiles")
	for index = 1, Rules.TileCount do
		local tile = tilesFolder and tilesFolder:FindFirstChild(string.format("Tile_%02d", index))
		local level = (snap.buildings and snap.buildings[index]) or 0
		if snap.owners[index] == mySeat and level < 3 and tile and tile:GetAttribute("TileKind") == "Property" then
			local tariff = Tarif.get(index)
			local cost = if level >= 2 then tariff.buildOKB else tariff.buildSubsidi
			if typeof(cost) == "number" and cost >= 0 and participant.cash >= cost then
				table.insert(buildChoices, index)
			end
		end
	end
	local selectedOrdinal = if selectedBuildTile then table.find(buildChoices, selectedBuildTile) else nil
	if not selectedOrdinal then
		selectedBuildTile = buildChoices[1]
		selectedOrdinal = if #buildChoices > 0 then 1 else nil
	end
	propertyPanel.Size = UDim2.fromScale(originalPanelSize.X.Scale, if mobileTouchMode then 0.62 else 0.50)
	propDetail.Size = UDim2.fromScale(0.86, if mobileTouchMode then 0.24 else 0.29)
	buildCount.Text = tostring(selectedOrdinal or 0) .. " / " .. tostring(#buildChoices)
	previousBuild.Active = #buildChoices > 1
	previousBuild.Selectable = #buildChoices > 1
	previousBuild.AutoButtonColor = #buildChoices > 1
	nextBuild.Active = #buildChoices > 1
	nextBuild.Selectable = #buildChoices > 1
	nextBuild.AutoButtonColor = #buildChoices > 1
	setButton("Build", selectedBuildTile ~= nil, "Bangun pilihan")
	local index = selectedBuildTile
	if not index then
		propTile.Text = "Tidak ada tanah tersedia"
		propDetail.Text = "Tidak ada tanah milikmu yang dapat ditingkatkan dengan saldo saat ini. Pilih Lewati."
		return
	end
	local name = describeTile(snap, index, mySeat)
	local level = (snap.buildings and snap.buildings[index]) or 0
	local tariff = Tarif.get(index)
	local cost = if level >= 2 then tariff.buildOKB else tariff.buildSubsidi
	local levelNames = {"Subsidi 1", "Subsidi 2", "Rumah OKB"}
	propTile.Text = name
	propDetail.Text = "Upgrade ke: " .. levelNames[level + 1]
		.. "\nBiaya Bangun: " .. Rules.formatMoney(cost)
		.. "\nSisa Uang: " .. Rules.formatMoney(participant.cash - cost)
		.. "\nSewa Setelah Upgrade: " .. Rules.formatMoney(tariff.rents[level + 2])
end

local teamButtons: {[string]: TextButton} = {
	A = waitFor(roomPanel, "TeamAButton") :: TextButton,
	B = waitFor(roomPanel, "TeamBButton") :: TextButton,
}
local swapControls = waitFor(roomPanel, "SwapControls") :: Frame
local swapTarget = waitFor(swapControls, "Target") :: TextLabel
local swapPrevious = waitFor(swapControls, "Previous") :: TextButton
local swapNext = waitFor(swapControls, "Next") :: TextButton
local swapRequest = waitFor(swapControls, "Request") :: TextButton
local swapAccept = waitFor(swapControls, "Accept") :: TextButton
local swapCancel = waitFor(swapControls, "Cancel") :: TextButton
local roomDescription = waitFor(roomPanel, "Description") :: TextLabel
local swapOrdinal = 1
local swapSeats: {number} = {}
local function refreshMatchmaking(snap: any)
	local mm = snap.matchmaking
	local room = snap.room
	if typeof(mm) ~= "table" or typeof(room) ~= "table" then
		matchmakingPanel.Visible = false
		return
	end
	local canShow = room.member ~= true
	matchmakingPanel.Visible = canShow
	if not canShow then return end
	local queued = mm.queued == true
	local matchFound = mm.matchFound == true
	local accepted = mm.accepted == true
	local isGlobal = mm.global == true or mm.localServerOnly == false
	queueButton.Visible = not queued and not matchFound
	queueButton.Active = not queued and not matchFound
	queueButton.Selectable = queueButton.Active
	queueButton.AutoButtonColor = queueButton.Active
	cancelQueueButton.Visible = queued and not matchFound
	cancelQueueButton.Active = queued and not matchFound
	cancelQueueButton.Selectable = cancelQueueButton.Active
	cancelQueueButton.AutoButtonColor = cancelQueueButton.Active
	acceptMatchButton.Visible = matchFound and not accepted
	acceptMatchButton.Active = matchFound and not accepted
	acceptMatchButton.Selectable = acceptMatchButton.Active
	acceptMatchButton.AutoButtonColor = acceptMatchButton.Active
	declineMatchButton.Visible = matchFound
	declineMatchButton.Active = matchFound
	declineMatchButton.Selectable = matchFound
	declineMatchButton.AutoButtonColor = matchFound
	if matchFound then
		local remaining = math.max(0, math.ceil((mm.deadline or 0) - WS:GetServerTimeNow()))
		if accepted then
			matchmakingStatus.Text = string.format(if isGlobal then "Match global diterima ✓\nMenunggu pemain lain • %d/4 • %ds" else "Match diterima ✓\nMenunggu pemain lain • %d/4 • %ds", mm.acceptedCount or 0, remaining)
		else
			matchmakingStatus.Text = string.format(if isGlobal then "MATCH GLOBAL DITEMUKAN!\nTerima dalam %ds • %d/4 sudah menerima" else "MATCH DITEMUKAN!\nTerima dalam %ds • %d/4 sudah menerima", remaining, mm.acceptedCount or 0)
		end
	elseif queued then
		matchmakingStatus.Text = string.format(if isGlobal then "Antrean global aktif • posisi %d\n%d pemain lintas server • butuh %d lagi" else "Antrean aktif • posisi %d\n%d/4 pemain • butuh %d lagi", mm.position or 0, mm.count or 0, mm.needed or 0)
	else
		matchmakingStatus.Text = string.format(if isGlobal then "Belum antre • %d pemain tersedia lintas server" else "Belum antre • %d/4 pemain di server ini", mm.count or 0)
	end
end

local function sendQueue(action: string)
	local snap = latest
	if not snap or typeof(snap.matchmaking) ~= "table" then return end
	if os.clock() - lastQueueRequest < 0.3 then return end
	lastQueueRequest = os.clock()
	requestAction:FireServer(action, snap.matchmaking.revision, snap.version)
end
queueButton.Activated:Connect(function() if queueButton.Active then sendQueue("Queue") end end)
cancelQueueButton.Activated:Connect(function() if cancelQueueButton.Active then sendQueue("CancelQueue") end end)
acceptMatchButton.Activated:Connect(function() if acceptMatchButton.Active then sendQueue("AcceptMatch") end end)
declineMatchButton.Activated:Connect(function() if declineMatchButton.Active then sendQueue("DeclineMatch") end end)

local function refreshRoom(snap: any)
	local room = snap.room
	if typeof(room) ~= "table" then roomPanel.Visible = false; return end
	local inMatch = snap.phase ~= "Waiting" and snap.phase ~= "Finished" and snap.phase ~= "Cancelled"
	if inMatch then
		roomPanel.Visible = false
		return
	end
	local mm = snap.matchmaking
	local matchmakingLocked = typeof(mm) == "table" and (mm.queued == true or mm.matchFound == true)
	local member = room.member == true
	local preparation = room.phase == "Waiting"
	local finished = room.phase == "Finished" or room.phase == "Cancelled"
	roomPanel.Visible = not member or preparation or finished
	panel.Visible = member
	roomCode.Visible = not member

	if applyResponsiveLayout and WS.CurrentCamera then
		applyResponsiveLayout(WS.CurrentCamera.ViewportSize)
	end
	local function control(button: TextButton, visible: boolean, enabled: boolean)
		button.Visible = visible
		button.Active = enabled
		button.Selectable = enabled
		button.AutoButtonColor = enabled
		button.TextTransparency = if enabled then 0 else 0.55
	end
	control(createRoom, not member, not member and not matchmakingLocked and not room.exists)
	control(joinRoom, not member, not member and not matchmakingLocked and room.exists and preparation and room.count < room.capacity)
	control(leaveRoom, member and (preparation or finished), member and (preparation or finished))
	local teamCounts = {A = 0, B = 0}
	local myTeam: string? = nil
	for _, participant in snap.players do
		if teamCounts[participant.team] ~= nil then teamCounts[participant.team] += 1 end
		if participant.userId == player.UserId then myTeam = participant.team end
	end
	for team, button in teamButtons do
		local mine = myTeam == team
		button.Text = string.format("TIM %s (%d/2)%s", team, teamCounts[team], if mine then " - KAMU" else "")
		control(button, member and preparation, member and preparation and not mine and teamCounts[team] < 2)
	end
	swapControls.Visible = member and preparation
	roomDescription.Visible = not swapControls.Visible
	refreshBotButton(snap)
	swapSeats = {}
	for seat, p in snap.players do
		if myTeam and p.team ~= myTeam then table.insert(swapSeats, seat) end
	end
	swapOrdinal = math.clamp(swapOrdinal, 1, math.max(1, #swapSeats))
	local pending = snap.teamSwap
	local involved = pending and (pending.fromUserId == player.UserId or pending.toUserId == player.UserId)
	local receiving = pending and pending.toUserId == player.UserId
	local unexpired = pending and WS:GetServerTimeNow() < pending.expiresAt
	control(swapPrevious, not pending, #swapSeats > 1)
	control(swapNext, not pending, #swapSeats > 1)
	control(swapRequest, not pending, member and preparation and #swapSeats > 0)
	control(swapAccept, receiving == true, receiving == true and unexpired == true)
	control(swapCancel, involved == true, involved == true and unexpired == true)
	swapCancel.Text = if receiving then "TOLAK" else "BATALKAN"
	if pending then
		local fromName, toName = "Pemain", "Pemain"
		for _, p in snap.players do
			if p.userId == pending.fromUserId then fromName = p.name end
			if p.userId == pending.toUserId then toName = p.name end
		end
		swapTarget.Text = fromName .. " meminta tukar dengan " .. toName
	else
		local targetSeat = swapSeats[swapOrdinal]
		local target = if targetSeat then snap.players[targetSeat] else nil
		swapTarget.Text = if target then "Tukar dengan " .. target.name .. " (Tim " .. target.team .. ")" else "Menunggu pemain dari tim lain"
	end
	if member then
		local leader = ""
		for _, participant in snap.players do
			if participant.userId == room.leaderId then leader = participant.name; break end
		end
		roomInfo.Text = string.format("KODE: %s | %d/%d pemain", room.code or "", room.count, room.capacity)
		roomMessage.Text = if typeof(snap.error) == "string" and #snap.error > 0 then snap.error else "Ketua: " .. leader .. ". Bagikan kode kepada teman dalam server ini."
		roomCode.Text = ""
	else
		roomInfo.Text = if room.exists then "Room tersedia di server ini" else "Belum ada room"
		roomMessage.Text = if typeof(snap.error) == "string" and #snap.error > 0 then snap.error else (if room.exists then "Minta kode kepada teman. Kode belum mendukung perpindahan antarserver." else "Buat room untuk memulai persiapan empat pemain.")
		status.Text = "Buat atau gabung room"
		setButton("Ready", false)
		buttons.Ready.Visible = false
		buttons.Roll.Visible = false
	end
end

local function sendSwap(action: string)
	local snap = latest
	if not snap or snap.phase ~= "Waiting" or not snap.room or not snap.room.member then return end
	if os.clock() - lastRoomRequest < 0.3 then return end
	local target = if action == "RequestTeamSwap" then swapSeats[swapOrdinal] else nil
	if action == "RequestTeamSwap" and not target then return end
	lastRoomRequest = os.clock()
	requestAction:FireServer(action, snap.revision, snap.version, target)
end
swapPrevious.Activated:Connect(function()
	if latest and #swapSeats > 1 then swapOrdinal = (swapOrdinal - 2) % #swapSeats + 1; refreshRoom(latest) end
end)
swapNext.Activated:Connect(function()
	if latest and #swapSeats > 1 then swapOrdinal = swapOrdinal % #swapSeats + 1; refreshRoom(latest) end
end)
swapRequest.Activated:Connect(function() if swapRequest.Active then sendSwap("RequestTeamSwap") end end)
swapAccept.Activated:Connect(function() if swapAccept.Active then sendSwap("AcceptTeamSwap") end end)
swapCancel.Activated:Connect(function() if swapCancel.Active then sendSwap("CancelTeamSwap") end end)

for team, button in teamButtons do
	button.Activated:Connect(function()
		local snap = latest
		if not snap or not button.Active or snap.phase ~= "Waiting" then return end
		if os.clock() - lastRoomRequest < 0.3 then return end
		lastRoomRequest = os.clock()
		requestAction:FireServer("ChooseTeam", snap.revision, snap.version, team)
	end)
end

local function sendRoom(action: string)
	local snap = latest
	if not snap or typeof(snap.room) ~= "table" then return end
	if os.clock() - lastRoomRequest < 0.3 then return end
	lastRoomRequest = os.clock()
	local code: string? = nil
	if action == "JoinRoom" then
		code = string.upper((string.gsub(roomCode.Text, "%s", "")))
		if #code ~= 6 then
			roomMessage.Text = "Masukkan kode room 6 karakter."
			return
		end
	end
	requestAction:FireServer(action, snap.room.revision, snap.version, code)
end

local function refresh(snap: any)
	local players = snap.players
	local mySeat = findMySeat(snap)
	local activeSeat: number = snap.activeSeat
	local active = if activeSeat >= 1 and activeSeat <= #players then players[activeSeat] else nil
	local phase: string = snap.phase
	local myTurn = mySeat > 0 and activeSeat == mySeat and not players[mySeat].eliminated
	local over = phase == "Finished" or phase == "Cancelled"

	if phase == "Waiting" then
		hRound.Text = "Lobi"
	elseif over then
		hRound.Text = "Selesai"
	else
		hRound.Text = "Ronde " .. snap.round .. " / " .. Rules.MaxRounds
	end
	dicePanel.Visible = phase ~= "Waiting"
	hSub.Text = if over and #snap.result > 0 then snap.result else "NUSANTARA • 2v2"
	hConn.Text = "🟢 Online"
	local profile = snap.profile
	if typeof(profile) == "table" then
		hProfile.Text = string.format("🏆 %d Menang • 💀 %d Kalah (Main: %d)", profile.wins or 0, profile.losses or 0, profile.matches or 0)
	else
		hProfile.Text = "🏆 0 Menang • 💀 0 Kalah"
	end

	local readyCount = 0
	for _, p in players do
		if p.ready then readyCount += 1 end
	end
	rHead.Text = string.format("Peserta %d/%d", #players, Rules.PlayerCount)
	for seat = 1, Rules.PlayerCount do
		local v = seats[seat]
		local p = players[seat]
		if p then
			local marker = if seat == activeSeat then "\u{25B6} " else ""
			local reconnectSuffix = ""
			if p.connected == false then
				local reconnectRemaining = math.max(0, math.ceil((p.reconnectUntil or 0) - WS:GetServerTimeNow()))
				reconnectSuffix = string.format("  (terputus %ds)", reconnectRemaining)
			end
			local suffix = if p.eliminated then "  (bangkrut)" else bekasiLabel(p)
			v.name.Text = marker .. p.name .. suffix .. reconnectSuffix
			v.balance.Text = Rules.formatMoney(p.cash)
			v.team.Text = "Tim " .. p.team .. (if p.ready and phase == "Waiting" then "  -  Siap" else "")
			v.team.TextColor3 = TEAMC[p.team] or Color3.new(1, 1, 1)
			v.frame.BackgroundColor3 = if seat == activeSeat then v.base:Lerp(Color3.new(1, 1, 1), 0.35) else v.base
		else
			v.name.Text = "Kursi kosong"
			v.balance.Text = "-"
			v.team.Text = "Kursi " .. seat
			v.team.TextColor3 = OFFC
			v.frame.BackgroundColor3 = v.base
		end
	end

	if phase == "Waiting" then
		local mine = if mySeat > 0 then players[mySeat] else nil
		setButton("Ready", mine ~= nil, if mine and mine.ready then "Batal Siap" else "Nyatakan Siap")
		setButton("Roll", false)
		setButton("Buy", false)
		setButton("Skip", false)
		setButton("Build", false)
		setButton("SkipBuild", false)
		setButton("Bail", false)
		setButton("ReturnLobby", false)
		status.Text = string.format("Menunggu peserta siap (%d/%d)", readyCount, Rules.PlayerCount)
	elseif over then
		local canRematch = phase == "Finished" and mySeat > 0 and not snap.rematchUnavailable
		local voted = mySeat > 0 and snap.rematchVotes and snap.rematchVotes[mySeat]
		setButton("Ready", canRematch, if voted then "Batal Main Lagi" else "Main Lagi")
		setButton("Roll", false)
		setButton("Buy", false)
		setButton("Skip", false)
		setButton("Build", false)
		setButton("SkipBuild", false)
		setButton("Bail", false)
		local canReturnLobby = mySeat > 0 and snap.routing and snap.routing.canReturnToLobby == true
		setButton("ReturnLobby", canReturnLobby, "KEMBALI LOBBY")
		status.Text = if #snap.result > 0 then snap.result else (PHASES[phase] or phase)
	else
		local pausedForReconnect = snap.room and snap.room.pausedForReconnect == true
		setButton("Ready", false)
		setRollPulse(phase == "AwaitRoll" and myTurn and not pausedForReconnect)
		setButton("Roll", not pausedForReconnect and phase == "AwaitRoll" and myTurn)
		setButton("Buy", not pausedForReconnect and phase == "AwaitBuy" and myTurn)
		setButton("Skip", not pausedForReconnect and phase == "AwaitBuy" and myTurn)
		setButton("Build", not pausedForReconnect and phase == "AwaitBuild" and myTurn)
		setButton("SkipBuild", not pausedForReconnect and phase == "AwaitBuild" and myTurn, "Lewati")
		setButton("Bail", not pausedForReconnect and phase == "AwaitRoll" and myTurn and players[mySeat].inJail)
		setButton("ReturnLobby", false)
		if active then
			local jailTag = if active.inJail then jailLabel(active) else ""
			status.Text = string.format("Giliran: %s (Tim %s)%s%s%s", active.name, active.team, jailTag, bekasiLabel(active), if myTurn then "  -  GILIRANMU!" else "")
			if not myTurn then hint.Text = "Menunggu " .. active.name .. "..." end
		else
			status.Text = "Menunggu giliran..."
		end
	end

	local d1, d2 = snap.dice[1], snap.dice[2]
	local newDiceText = if d1 > 0 then string.format("\u{1F3B2}  %d + %d  =  %d", d1, d2, d1 + d2) else "\u{1F3B2}  -"
	if diceText.Text ~= newDiceText then
		diceText.Text = newDiceText
		if d1 > 0 then
			playPop(dicePanel, 0.82, 1.15)
		end
	end

	logText.Text = table.concat(snap.logs, "\n")

	if active then
		local tileName, details = describeTile(snap, active.position, mySeat)
		propTile.Text = tileName
		propDetail.Text = details
	else
		propTile.Text = "Papan prototipe"
		propDetail.Text = "Info petak tampil saat pertandingan berjalan."
	end
	for seat = 1, Rules.PlayerCount do
		setSeatGlow(seat, phase ~= "Waiting" and not over and seat == activeSeat)
	end
end

local function updateHint()
	local snap = latest
	if not snap then return end
	if os.clock() < errUntil and #errText > 0 then
		hint.TextColor3 = ERRC
		hint.Text = errText
		return
	end
	hint.TextColor3 = HINTC
	local mySeat = findMySeat(snap)
	if snap.room and snap.room.pausedForReconnect then
		local reconnectName = "pemain"
		local reconnectRemaining = 0
		for _, participant in snap.players do
			if participant.connected == false then
				reconnectName = participant.name
				reconnectRemaining = math.max(0, math.ceil((participant.reconnectUntil or 0) - WS:GetServerTimeNow()))
				break
			end
		end
		hint.Text = string.format("Pertandingan dipause: menunggu %s reconnect • %ds", reconnectName, reconnectRemaining)
		return
	end
	local phase: string = snap.phase
	if (phase == "AwaitBuy" or (phase == "AwaitRoll" and mySeat > 0 and not snap.players[mySeat].inJail)) and mySeat > 0 and snap.activeSeat == mySeat then
		local remaining = math.max(0, math.ceil(snap.deadline - WS:GetServerTimeNow()))
		hint.Text = if phase == "AwaitRoll" then string.format("Lempar dadu - waktu %ds", remaining) else string.format("Beli atau lewati - waktu %ds", remaining)
	elseif phase == "AwaitBuild" and mySeat > 0 and snap.activeSeat == mySeat then
		local remaining = math.max(0, math.ceil(snap.deadline - WS:GetServerTimeNow()))
		hint.Text = string.format("Pilih tanah dengan < >, lalu Bangun atau Lewati - %ds", remaining)
	elseif phase == "AwaitRoll" and mySeat > 0 and snap.activeSeat == mySeat and snap.players[mySeat].inJail then
		local remaining = math.max(0, math.ceil(snap.deadline - WS:GetServerTimeNow()))
		hint.Text = string.format("Coba dadu kembar atau bayar jaminan; bebas otomatis giliran ke-3 - %ds", remaining)
	elseif phase == "AwaitCardChoice" and mySeat > 0 and snap.activeSeat == mySeat then
		local remaining = math.max(0, math.ceil(snap.deadline - WS:GetServerTimeNow()))
		hint.Text = string.format("Pilih tanah untuk kartu - waktu %ds", remaining)
	elseif phase == "Waiting" then
		hint.Text = if mySeat > 0 then "Nyatakan siap setelah semua peserta bergabung." else "Gunakan Buat Room atau Gabung Kode terlebih dahulu."
	elseif phase == "Finished" then
		if snap.rematchUnavailable then
			hint.Text = "Peserta keluar; main ulang dengan tim yang sama tidak tersedia."
		else
			local votes = 0
			for _, voted in (snap.rematchVotes or {}) do
				if voted then votes += 1 end
			end
			hint.Text = string.format("Main lagi: %d/%d setuju. Uang dan aset direset saat semua setuju.", votes, Rules.PlayerCount)
		end
	elseif phase == "Cancelled" then
		hint.Text = "Sesi berakhir karena peserta terputus."
	else
		hint.Text = ""
	end
end

for k in buttons do
	setButton(k, false)
end
hConn.Text = "Menyambung ke server..."

buttons.Roll.Activated:Connect(function() if allowed.Roll then send("Roll") end end)
buttons.Buy.Activated:Connect(function() if allowed.Buy then send("Buy") end end)
buttons.Skip.Activated:Connect(function() if allowed.Skip then send("Skip") end end)
buttons.Ready.Activated:Connect(function()
	if allowed.Ready and latest then
		send(if latest.phase == "Finished" then "Rematch" else "Ready")
	end
end)
local function cycleBuild(direction: number)
	if not latest or not buildPicker.Visible or #buildChoices < 2 then return end
	local ordinal = if selectedBuildTile then table.find(buildChoices, selectedBuildTile) else nil
	selectedBuildTile = buildChoices[((ordinal or 1) - 1 + direction) % #buildChoices + 1]
	refreshBuildPicker(latest)
end
previousBuild.Activated:Connect(function() cycleBuild(-1) end)
nextBuild.Activated:Connect(function() cycleBuild(1) end)
buttons.Build.Activated:Connect(function() if allowed.Build then send("Build") end end)
buttons.SkipBuild.Activated:Connect(function() if allowed.SkipBuild then send("SkipBuild") end end)
buttons.Bail.Activated:Connect(function() if allowed.Bail then send("Bail") end end)
buttons.ReturnLobby.Activated:Connect(function() if allowed.ReturnLobby then send("ReturnLobby") end end)

createRoom.Activated:Connect(function() if createRoom.Active then sendRoom("CreateRoom") end end)
joinRoom.Activated:Connect(function() if joinRoom.Active then sendRoom("JoinRoom") end end)
leaveRoom.Activated:Connect(function() if leaveRoom.Active then sendRoom("LeaveRoom") end end)
roomCode.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed and joinRoom.Active then sendRoom("JoinRoom") end
end)

local CardData = require(waitFor(shared, "CardData") :: ModuleScript)
local handPanel = waitFor(root, "HandPanel") :: Frame
local handButton = waitFor(root, "HandButton") :: TextButton
local handName = waitFor(handPanel, "CardName") :: TextLabel
local handDescription = waitFor(handPanel, "Description") :: TextLabel
local handChoice = waitFor(handPanel, "Choice") :: TextLabel
local handMessage = waitFor(handPanel, "Message") :: TextLabel
local useCard = waitFor(handPanel, "Use") :: TextButton
local previousCard = waitFor(handPanel, "PreviousCard") :: TextButton
local nextCard = waitFor(handPanel, "NextCard") :: TextButton
local previousChoice = waitFor(handPanel, "PreviousChoice") :: TextButton
local nextChoice = waitFor(handPanel, "NextChoice") :: TextButton
local closeHand = waitFor(handPanel, "Close") :: TextButton
local skipCardChoice = waitFor(handPanel, "SkipChoice") :: TextButton

local desktopLayout = {
	headerPos = header.Position,
	headerSize = header.Size,
	roundPos = hRound.Position,
	roundSize = hRound.Size,
	profilePos = hProfile.Position,
	profileSize = hProfile.Size,
	connPos = hConn.Position,
	connSize = hConn.Size,
	mutePos = if header:FindFirstChild("MuteButton") then (header:FindFirstChild("MuteButton") :: any).Position else UDim2.new(1, -14, 0.5, 0),
	muteSize = if header:FindFirstChild("MuteButton") then (header:FindFirstChild("MuteButton") :: any).Size else UDim2.new(0, 32, 0, 32),
	rosterPos = roster.Position,
	rosterSize = roster.Size,
	logPos = logPanel.Position,
	logSize = logPanel.Size,
	seatPos = {} :: {[number]: UDim2},
	seatSize = {} :: {[number]: UDim2},
	roomPos = roomPanel.Position,
	roomSize = roomPanel.Size,
	roomHeadPos = roomHeading.Position,
	roomHeadSize = roomHeading.Size,
	roomDescPos = roomDescription.Position,
	roomDescSize = roomDescription.Size,
	roomInfoPos = roomInfo.Position,
	roomInfoSize = roomInfo.Size,
	roomCodePos = roomCode.Position,
	roomCodeSize = roomCode.Size,
	createRoomPos = createRoom.Position,
	createRoomSize = createRoom.Size,
	joinRoomPos = joinRoom.Position,
	joinRoomSize = joinRoom.Size,
	leaveRoomPos = leaveRoom.Position,
	leaveRoomSize = leaveRoom.Size,
	teamAPos = teamButtons.A.Position,
	teamASize = teamButtons.A.Size,
	teamBPos = teamButtons.B.Position,
	teamBSize = teamButtons.B.Size,
	roomMessagePos = roomMessage.Position,
	roomMessageSize = roomMessage.Size,
	swapPos = swapControls.Position,
	swapSize = swapControls.Size,
	swapTargetPos = swapTarget.Position,
	swapTargetSize = swapTarget.Size,
	swapPrevPos = swapPrevious.Position,
	swapPrevSize = swapPrevious.Size,
	swapNextPos = swapNext.Position,
	swapNextSize = swapNext.Size,
	swapReqPos = swapRequest.Position,
	swapReqSize = swapRequest.Size,
	swapAccPos = swapAccept.Position,
	swapAccSize = swapAccept.Size,
	swapCanPos = swapCancel.Position,
	swapCanSize = swapCancel.Size,
	mmPos = matchmakingPanel.Position,
	mmSize = matchmakingPanel.Size,
	mmModePos = if matchmakingPanel:FindFirstChild("Mode") then (matchmakingPanel:FindFirstChild("Mode") :: any).Position else UDim2.fromScale(0.08, 0.22),
	mmModeSize = if matchmakingPanel:FindFirstChild("Mode") then (matchmakingPanel:FindFirstChild("Mode") :: any).Size else UDim2.fromScale(0.84, 0.16),
	mmStatusPos = matchmakingStatus.Position,
	mmStatusSize = matchmakingStatus.Size,
	queueBtnPos = queueButton.Position,
	queueBtnSize = queueButton.Size,
	cancelBtnPos = cancelQueueButton.Position,
	cancelBtnSize = cancelQueueButton.Size,
	acceptBtnPos = acceptMatchButton.Position,
	acceptBtnSize = acceptMatchButton.Size,
	declineBtnPos = declineMatchButton.Position,
	declineBtnSize = declineMatchButton.Size,
	botBtnPos = if panel:FindFirstChild("BotButton") then (panel:FindFirstChild("BotButton") :: any).Position else UDim2.fromScale(0.68, 0.74),
	botBtnSize = if panel:FindFirstChild("BotButton") then (panel:FindFirstChild("BotButton") :: any).Size else UDim2.fromScale(0.28, 0.24),
	handPanelPos = handPanel.Position,
	handPanelSize = handPanel.Size,
	handButtonPos = handButton.Position,
	handButtonSize = handButton.Size,
}
for s = 1, Rules.PlayerCount do
	desktopLayout.seatPos[s] = seats[s].frame.Position
	desktopLayout.seatSize[s] = seats[s].frame.Size
end

applyResponsiveLayout = function(viewport: Vector2)
	local isMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or viewport.Y <= 550 or viewport.X <= 1000
	mobileTouchMode = isMobile

	local muteBtn = header:FindFirstChild("MuteButton")
	local mmMode = matchmakingPanel:FindFirstChild("Mode")
	local botBtn = panel:FindFirstChild("BotButton")

	if isMobile then
		-- Header: offset past Roblox TopBar buttons (Roblox menu + Chat)
		header.Position = UDim2.new(0, 115, 0, 6)
		header.Size = UDim2.new(1, -135, 0, 42)

		-- Header internal items: no collision between round, stats, online, and mute
		hRound.Position = UDim2.new(0.30, 0, 0.5, 0)
		hRound.Size = UDim2.new(0, 75, 0, 24)

		hProfile.Position = UDim2.new(1, -180, 0.5, 0)
		hProfile.Size = UDim2.new(0, 105, 0, 24)
		hProfile.TextScaled = true

		hConn.Position = UDim2.new(1, -66, 0.5, 0)
		hConn.Size = UDim2.new(0, 48, 0, 24)
		hConn.TextScaled = true

		if muteBtn and muteBtn:IsA("GuiObject") then
			muteBtn.Position = UDim2.new(1, -15, 0.5, 0)
			muteBtn.Size = UDim2.new(0, 24, 0, 24)
		end

		-- Roster & LogPanel: perfectly calculated so Roster bottom never touches LogPanel top
		roster.Position = UDim2.new(0.015, 0, 0, 52)
		roster.Size = UDim2.new(0.19, 0, 0.44, 0)
		for seat = 1, Rules.PlayerCount do
			seats[seat].frame.Position = UDim2.new(0.05, 0, 0.12 + (seat - 1) * 0.215, 0)
			seats[seat].frame.Size = UDim2.new(0.90, 0, 0.185, 0)
		end

		-- LogPanel starts at 44% + 56px (4px below Roster bottom) and extends to 8px before screen bottom
		logPanel.Position = UDim2.new(0.015, 0, 0.44, 56)
		logPanel.Size = UDim2.new(0.19, 0, 0.56, -64)

		-- RoomPanel (center): cleanly below Header, no overlap with MatchmakingPanel
		local inWaitingRoom = latest and latest.room and latest.room.member and latest.room.phase == "Waiting"
		if inWaitingRoom then
			roomPanel.AnchorPoint = Vector2.new(0.5, 0)
			roomPanel.Position = UDim2.new(0.5, 0, 0, 48)
			roomPanel.Size = UDim2.new(0.52, 0, 0, 142)
			panel.AnchorPoint = Vector2.new(0.5, 1)
			panel.Position = UDim2.new(0.5, 0, 1, -6)
			panel.Size = UDim2.new(0.52, 0, 0, 92)

			roomHeading.Position = UDim2.new(0.04, 0, 0, 4)
			roomHeading.Size = UDim2.new(0.92, 0, 0, 16)
			roomInfo.Position = UDim2.new(0.04, 0, 0, 22)
			roomInfo.Size = UDim2.new(0.92, 0, 0, 15)

			swapControls.Position = UDim2.new(0.04, 0, 0, 39)
			swapControls.Size = UDim2.new(0.92, 0, 0, 38)
			swapTarget.Position = UDim2.new(0.12, 0, 0, 0)
			swapTarget.Size = UDim2.new(0.76, 0, 0, 14)
			swapPrevious.Position = UDim2.new(0, 0, 0, 0)
			swapPrevious.Size = UDim2.new(0.10, 0, 0, 14)
			swapNext.Position = UDim2.new(0.90, 0, 0, 0)
			swapNext.Size = UDim2.new(0.10, 0, 0, 14)
			swapRequest.Position = UDim2.new(0.20, 0, 0, 16)
			swapRequest.Size = UDim2.new(0.60, 0, 0, 20)
			swapAccept.Position = UDim2.new(0.05, 0, 0, 16)
			swapAccept.Size = UDim2.new(0.42, 0, 0, 20)
			swapCancel.Position = UDim2.new(0.53, 0, 0, 16)
			swapCancel.Size = UDim2.new(0.42, 0, 0, 20)

			teamButtons.A.Position = UDim2.new(0.04, 0, 0, 80)
			teamButtons.A.Size = UDim2.new(0.32, 0, 0, 26)
			leaveRoom.Position = UDim2.new(0.38, 0, 0, 80)
			leaveRoom.Size = UDim2.new(0.24, 0, 0, 26)
			teamButtons.B.Position = UDim2.new(0.64, 0, 0, 80)
			teamButtons.B.Size = UDim2.new(0.32, 0, 0, 26)

			roomMessage.Position = UDim2.new(0.04, 0, 0, 108)
			roomMessage.Size = UDim2.new(0.92, 0, 0, 30)
		else
			roomPanel.AnchorPoint = Vector2.new(0, 0)
			roomPanel.Position = UDim2.fromScale(0.22, 0.15)
			roomPanel.Size = UDim2.fromScale(0.48, 0.77)
			panel.AnchorPoint = Vector2.new(0.5, 1)
			panel.Position = UDim2.new(0.5, 0, 1, -6)
			panel.Size = UDim2.new(0.52, 0, 0, 92)

			roomHeading.Position = UDim2.fromScale(0.06, 0.04)
			roomHeading.Size = UDim2.fromScale(0.88, 0.11)
			roomDescription.Position = UDim2.fromScale(0.06, 0.16)
			roomDescription.Size = UDim2.fromScale(0.88, 0.13)
			roomInfo.Position = UDim2.fromScale(0.06, 0.30)
			roomInfo.Size = UDim2.fromScale(0.88, 0.11)
			roomCode.Position = UDim2.fromScale(0.08, 0.43)
			roomCode.Size = UDim2.fromScale(0.84, 0.14)
			createRoom.Position = UDim2.fromScale(0.08, 0.60)
			createRoom.Size = UDim2.fromScale(0.40, 0.16)
			joinRoom.Position = UDim2.fromScale(0.52, 0.60)
			joinRoom.Size = UDim2.fromScale(0.40, 0.16)
			roomMessage.Position = UDim2.fromScale(0.06, 0.79)
			roomMessage.Size = UDim2.fromScale(0.88, 0.17)
		end

		-- MatchmakingPanel (right): cleanly below Header, no overlap with RoomPanel
		matchmakingPanel.Position = UDim2.fromScale(0.72, 0.15)
		matchmakingPanel.Size = UDim2.fromScale(0.26, 0.77)
		if mmMode and mmMode:IsA("GuiObject") then
			mmMode.Position = UDim2.fromScale(0.08, 0.18)
			mmMode.Size = UDim2.fromScale(0.84, 0.12)
		end
		matchmakingStatus.Position = UDim2.fromScale(0.06, 0.32)
		matchmakingStatus.Size = UDim2.fromScale(0.88, 0.22)
		queueButton.Position = UDim2.fromScale(0.08, 0.58)
		queueButton.Size = UDim2.fromScale(0.84, 0.17)
		cancelQueueButton.Position = UDim2.fromScale(0.08, 0.78)
		cancelQueueButton.Size = UDim2.fromScale(0.84, 0.17)
		acceptMatchButton.Position = UDim2.fromScale(0.08, 0.58)
		acceptMatchButton.Size = UDim2.fromScale(0.84, 0.17)
		declineMatchButton.Position = UDim2.fromScale(0.08, 0.78)
		declineMatchButton.Size = UDim2.fromScale(0.84, 0.17)

		-- ActionPanel (bottom center)
		status.Position = UDim2.new(0.04, 0, 0, 3)
		status.Size = UDim2.new(0.92, 0, 0, 15)
		hint.Position = UDim2.new(0.04, 0, 0, 18)
		hint.Size = UDim2.new(0.92, 0, 0, 13)

		local primaryPos = UDim2.new(0.50, 0, 0, 33)
		local leftPos = UDim2.new(0.26, 0, 0, 33)
		local rightPos = UDim2.new(0.74, 0, 0, 33)
		local halfSize = UDim2.new(0.44, 0, 0, 30)
		local fullSize = UDim2.new(0.92, 0, 0, 30)

		buttons.Ready.AnchorPoint = Vector2.new(0.5, 0)
		buttons.Ready.Position = primaryPos
		buttons.Ready.Size = fullSize

		buttons.Roll.AnchorPoint = Vector2.new(0.5, 0)
		buttons.Roll.Position = primaryPos
		buttons.Roll.Size = fullSize

		for _, key in {"Buy", "Build"} do
			buttons[key].AnchorPoint = Vector2.new(0.5, 0)
			buttons[key].Position = leftPos
			buttons[key].Size = halfSize
		end
		for _, key in {"Skip", "SkipBuild", "Bail", "ReturnLobby"} do
			buttons[key].AnchorPoint = Vector2.new(0.5, 0)
			buttons[key].Position = rightPos
			buttons[key].Size = halfSize
		end

		if botBtn and botBtn:IsA("GuiObject") then
			botBtn.AnchorPoint = Vector2.new(0.5, 0)
			botBtn.Position = UDim2.new(0.50, 0, 0, 66)
			botBtn.Size = UDim2.new(0.92, 0, 0, 22)
		end

		-- HandPanel
		handPanel.Position = UDim2.fromScale(0.22, 0.14)
		handPanel.Size = UDim2.fromScale(0.56, 0.78)
		closeHand.Position = UDim2.fromScale(0.84, 0.03)
		closeHand.Size = UDim2.fromScale(0.12, 0.18)
		previousCard.Position = UDim2.fromScale(0.04, 0.16)
		previousCard.Size = UDim2.fromScale(0.12, 0.18)
		nextCard.Position = UDim2.fromScale(0.84, 0.16)
		nextCard.Size = UDim2.fromScale(0.12, 0.18)
		previousChoice.Position = UDim2.fromScale(0.04, 0.54)
		previousChoice.Size = UDim2.fromScale(0.12, 0.18)
		nextChoice.Position = UDim2.fromScale(0.84, 0.54)
		nextChoice.Size = UDim2.fromScale(0.12, 0.18)
		handName.Position = UDim2.fromScale(0.19, 0.16)
		handName.Size = UDim2.fromScale(0.62, 0.18)
		handDescription.Position = UDim2.fromScale(0.06, 0.35)
		handDescription.Size = UDim2.fromScale(0.88, 0.18)
		handChoice.Position = UDim2.fromScale(0.19, 0.54)
		handChoice.Size = UDim2.fromScale(0.62, 0.18)
		handMessage.Position = UDim2.fromScale(0.06, 0.73)
		handMessage.Size = UDim2.fromScale(0.88, 0.07)
		useCard.Position = UDim2.fromScale(0.20, 0.81)
		useCard.Size = UDim2.fromScale(0.60, 0.18)
		skipCardChoice.Position = UDim2.fromScale(0.58, 0.81)
		skipCardChoice.Size = UDim2.fromScale(0.38, 0.18)

		handButton.Position = UDim2.new(1, -16, 1, -16)
		handButton.Size = UDim2.new(0, 140, 0, 36)

		buildPicker.Position = UDim2.fromScale(0.06, 0.66)
		buildPicker.Size = UDim2.fromScale(0.88, 0.28)
		previousBuild.Size = UDim2.fromScale(0.30, 1)
		nextBuild.Position = UDim2.fromScale(0.70, 0)
		nextBuild.Size = UDim2.fromScale(0.30, 1)
		buildCount.Position = UDim2.fromScale(0.32, 0)
		buildCount.Size = UDim2.fromScale(0.36, 1)

		if cameraToggle then
			cameraToggle.Position = UDim2.new(1, -16, 1, -100)
			cameraToggle.Size = UDim2.new(0, 130, 0, 32)
		end
	else
		-- Desktop layout
		header.Position = desktopLayout.headerPos
		header.Size = desktopLayout.headerSize
		hRound.Position = desktopLayout.roundPos
		hRound.Size = desktopLayout.roundSize
		hProfile.Position = desktopLayout.profilePos
		hProfile.Size = desktopLayout.profileSize
		hConn.Position = desktopLayout.connPos
		hConn.Size = desktopLayout.connSize
		if muteBtn and muteBtn:IsA("GuiObject") then
			muteBtn.Position = desktopLayout.mutePos
			muteBtn.Size = desktopLayout.muteSize
		end

		roster.Position = desktopLayout.rosterPos
		roster.Size = desktopLayout.rosterSize
		for seat = 1, Rules.PlayerCount do
			seats[seat].frame.Position = desktopLayout.seatPos[seat]
			seats[seat].frame.Size = desktopLayout.seatSize[seat]
		end
		logPanel.Position = desktopLayout.logPos
		logPanel.Size = desktopLayout.logSize

		roomPanel.AnchorPoint = Vector2.new(0, 0)
		roomPanel.Position = desktopLayout.roomPos
		roomPanel.Size = desktopLayout.roomSize
		roomHeading.Position = desktopLayout.roomHeadPos
		roomHeading.Size = desktopLayout.roomHeadSize
		roomDescription.Position = desktopLayout.roomDescPos
		roomDescription.Size = desktopLayout.roomDescSize
		roomInfo.Position = desktopLayout.roomInfoPos
		roomInfo.Size = desktopLayout.roomInfoSize
		roomCode.Position = desktopLayout.roomCodePos
		roomCode.Size = desktopLayout.roomCodeSize
		createRoom.Position = desktopLayout.createRoomPos
		createRoom.Size = desktopLayout.createRoomSize
		joinRoom.Position = desktopLayout.joinRoomPos
		joinRoom.Size = desktopLayout.joinRoomSize
		leaveRoom.Position = desktopLayout.leaveRoomPos
		leaveRoom.Size = desktopLayout.leaveRoomSize
		teamButtons.A.Position = desktopLayout.teamAPos
		teamButtons.A.Size = desktopLayout.teamASize
		teamButtons.B.Position = desktopLayout.teamBPos
		teamButtons.B.Size = desktopLayout.teamBSize
		roomMessage.Position = desktopLayout.roomMessagePos
		roomMessage.Size = desktopLayout.roomMessageSize

		swapControls.Position = desktopLayout.swapPos
		swapControls.Size = desktopLayout.swapSize
		swapTarget.Position = desktopLayout.swapTargetPos
		swapTarget.Size = desktopLayout.swapTargetSize
		swapPrevious.Position = desktopLayout.swapPrevPos
		swapPrevious.Size = desktopLayout.swapPrevSize
		swapNext.Position = desktopLayout.swapNextPos
		swapNext.Size = desktopLayout.swapNextSize
		swapRequest.Position = desktopLayout.swapReqPos
		swapRequest.Size = desktopLayout.swapReqSize
		swapAccept.Position = desktopLayout.swapAccPos
		swapAccept.Size = desktopLayout.swapAccSize
		swapCancel.Position = desktopLayout.swapCanPos
		swapCancel.Size = desktopLayout.swapCanSize

		matchmakingPanel.Position = desktopLayout.mmPos
		matchmakingPanel.Size = desktopLayout.mmSize
		if mmMode and mmMode:IsA("GuiObject") then
			mmMode.Position = desktopLayout.mmModePos
			mmMode.Size = desktopLayout.mmModeSize
		end
		matchmakingStatus.Position = desktopLayout.mmStatusPos
		matchmakingStatus.Size = desktopLayout.mmStatusSize
		queueButton.Position = desktopLayout.queueBtnPos
		queueButton.Size = desktopLayout.queueBtnSize
		cancelQueueButton.Position = desktopLayout.cancelBtnPos
		cancelQueueButton.Size = desktopLayout.cancelBtnSize
		acceptMatchButton.Position = desktopLayout.acceptBtnPos
		acceptMatchButton.Size = desktopLayout.acceptBtnSize
		declineMatchButton.Position = desktopLayout.declineBtnPos
		declineMatchButton.Size = desktopLayout.declineBtnSize

		panel.AnchorPoint = Vector2.new(0.5, 1)
		panel.Position = desktopActionPanelPosition
		panel.Size = desktopActionPanelSize
		status.Position = desktopStatusPosition
		status.Size = desktopStatusSize
		hint.Position = desktopHintPosition
		hint.Size = desktopHintSize
		for key, original in desktopActionButtons do
			buttons[key].AnchorPoint = Vector2.new(0.5, 0)
			buttons[key].Position = original.position
			buttons[key].Size = original.size
		end
		if botBtn and botBtn:IsA("GuiObject") then
			botBtn.AnchorPoint = Vector2.new(0.5, 0)
			botBtn.Position = desktopLayout.botBtnPos
			botBtn.Size = desktopLayout.botBtnSize
		end

		handPanel.Position = desktopLayout.handPanelPos
		handPanel.Size = desktopLayout.handPanelSize
		handButton.Position = desktopLayout.handButtonPos
		handButton.Size = desktopLayout.handButtonSize

		if cameraToggle then
			cameraToggle.Position = UDim2.new(1, -20, 1, -112)
			cameraToggle.Size = UDim2.new(0, 140, 0, 34)
		end
	end
end

local landOrdinal = 1
local wasChoosingLand = false
local function ownLandChoice(): any
	if not latest or latest.phase ~= "AwaitCardChoice" then return nil end
	local seat = findMySeat(latest)
	local pending = latest.cardChoice
	if seat > 0 and pending and pending.seat == seat and latest.activeSeat == seat and not latest.players[seat].eliminated then return pending end
	return nil
end
local handOrdinal = 1
local cardChoice = 1
local handMatchId: string? = nil
local lastCardRequest = -math.huge
local function ownHand(): ({string}, any, number)
	if not latest then return {}, nil, 0 end
	local seat = findMySeat(latest)
	local participant = if seat > 0 then latest.players[seat] else nil
	return if participant then (participant.hand or {}) else {}, participant, seat
end
local function cardControl(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.Selectable = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = if enabled then 0 else 0.55
end

local function feedbackScale(target: GuiObject): UIScale
	local existing = target:FindFirstChild("FeedbackScale")
	if existing and existing:IsA("UIScale") then return existing end
	local scale = Instance.new("UIScale")
	scale.Name = "FeedbackScale"
	scale.Scale = 1
	scale.Parent = target
	return scale
end

playPop = function(target: GuiObject, startScale: number, peakScale: number)
	local scale = feedbackScale(target)
	scale.Scale = startScale
	local rise = TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = peakScale})
	local settle = TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
	rise:Play()
	rise.Completed:Once(function()
		settle:Play()
	end)
end

local cardToastGeneration = 0
local function showCardToast(message: string)
	cardToastGeneration += 1
	local generation = cardToastGeneration
	cardToastTitle.Text = "KARTU DITERIMA"
	cardToastMessage.Text = message
	cardToast.Visible = true
	cardToast.BackgroundTransparency = 0.20
	cardToastTitle.TextTransparency = 0
	cardToastMessage.TextTransparency = 0
	playPop(cardToast, 0.78, 1.08)
	local fade = TweenService:Create(cardToast, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	local fadeTitle = TweenService:Create(cardToastTitle, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
	local fadeMessage = TweenService:Create(cardToastMessage, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
	task.delay(2.2, function()
		if generation ~= cardToastGeneration or not cardToast:IsDescendantOf(game) then return end
		fade:Play()
		fadeTitle:Play()
		fadeMessage:Play()
		fade.Completed:Once(function()
			if generation == cardToastGeneration then
				cardToast.Visible = false
				cardToast.BackgroundTransparency = 0.05
				cardToastTitle.TextTransparency = 0
				cardToastMessage.TextTransparency = 0
			end
		end)
	end)
end

local cardModalGeneration = 0
local MODAL_GOLD = Color3.fromRGB(196, 148, 58)
local MODAL_DANGER = Color3.fromRGB(168, 48, 48)
local function showCardModal(logLine: string)
	local cardName, deckName, die = logLine:match("menarik (.-) %((%u%a+), dadu (%d)%)%.")
	if not cardName then
		local nameOnly, deckOnly = logLine:match("menarik (.-) %((%u%a+)%)%.")
		cardName, deckName = nameOnly, deckOnly
	end
	if not cardName then
		cardName = logLine:match("menarik (.-)%.")
	end
	if not cardName or #cardName == 0 then return end
	local accent = if deckName == "Musibah" then MODAL_DANGER else MODAL_GOLD
	cardModalUI.deck.Text = string.upper(deckName or "KARTU")
	cardModalUI.deck.TextColor3 = accent
	cardModalUI.stroke.Color = accent
	cardModalUI.title.Text = cardName
	local definition = CardData.get((cardName:gsub(" ", "")))
	cardModalUI.desc.Text = if definition and definition.note then definition.note else "Efek kartu diterapkan server. Periksa log untuk detail hasilnya."
	if die then
		cardModalUI.dice.Visible = true
		cardModalUI.dice.Text = "DADU " .. die
	else
		cardModalUI.dice.Visible = false
	end
	cardModalGeneration += 1
	local generation = cardModalGeneration
	cardModalUI.scale.Scale = 1
	cardModal.Visible = true
	playPop(cardModal, 0.82, 1.06)
	local function closeModal()
		if generation ~= cardModalGeneration or not cardModal:IsDescendantOf(game) then return end
		local fade = TweenService:Create(cardModalUI.scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.94})
		fade:Play()
		fade.Completed:Once(function()
			if generation == cardModalGeneration then cardModal.Visible = false end
		end)
	end
	cardModalUI.confirm.Activated:Once(closeModal)
	task.delay(4.5, closeModal)
end

local specialToastGeneration = 0
local SPECIAL_TILE_STYLE: {[string]: {icon: string, title: string, message: string, color: Color3}} = {
	Prison = {icon = "LAPAS", title = "MASUK AREA LAPAS", message = "Perhatikan status tahanan dan opsi jaminan pada giliranmu.", color = Color3.fromRGB(224, 82, 82)},
	Court = {icon = "ADIL", title = "PENGADILAN", message = "Putusan petak sedang diproses sesuai hasil dadu.", color = Color3.fromRGB(238, 193, 74)},
	Parking = {icon = "P", title = "PARKIRAN PUNGLI", message = "Biaya parkir berlaku sesuai aturan pertandingan.", color = Color3.fromRGB(231, 142, 66)},
}

local function showSpecialTileToast(kind: string)
	local style = SPECIAL_TILE_STYLE[kind]
	if not style then return end
	specialToastGeneration += 1
	local generation = specialToastGeneration
	specialToastUI.icon.Text = style.icon
	specialToastUI.icon.TextColor3 = style.color
	specialToastUI.title.Text = style.title
	specialToastUI.title.TextColor3 = style.color
	specialToastUI.message.Text = style.message
	specialToastUI.stroke.Color = style.color
	specialToast.BackgroundTransparency = 0.18
	specialToastUI.icon.TextTransparency = 0
	specialToastUI.title.TextTransparency = 0
	specialToastUI.message.TextTransparency = 0
	specialToast.Visible = true
	playPop(specialToast, 0.84, 1.06)
	task.delay(2.4, function()
		if generation ~= specialToastGeneration or not specialToast:IsDescendantOf(game) then return end
		local fade = TweenService:Create(specialToast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		TweenService:Create(specialToastUI.icon, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		TweenService:Create(specialToastUI.title, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		TweenService:Create(specialToastUI.message, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		fade:Play()
		fade.Completed:Once(function()
			if generation == specialToastGeneration then specialToast.Visible = false end
		end)
	end)
end

local avatarGenerations: {number} = {0, 0, 0, 0}
local function updateAvatarIndicators(previous: any, current: any)
	local oldPlayers = if typeof(previous) == "table" and typeof(previous.players) == "table" then previous.players else {}
	local newPlayers = if typeof(current.players) == "table" then current.players else {}
	for seat = 1, Rules.PlayerCount do
		local indicator = seats[seat].avatar
		local oldPlayer = oldPlayers[seat]
		local newPlayer = newPlayers[seat]
		if not newPlayer then
			avatarGenerations[seat] += 1
			indicator.Visible = false
		elseif not oldPlayer or oldPlayer.userId ~= newPlayer.userId then
			avatarGenerations[seat] += 1
			local generation = avatarGenerations[seat]
			indicator.Text = "• Memuat Avatar..."
			indicator.TextTransparency = 1
			indicator.Visible = true
			TweenService:Create(indicator, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			task.delay(1.6, function()
				if generation ~= avatarGenerations[seat] or not indicator:IsDescendantOf(game) then return end
				local fade = TweenService:Create(indicator, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
				fade:Play()
				fade.Completed:Once(function()
					if generation == avatarGenerations[seat] then indicator.Visible = false end
				end)
			end)
		end
	end
end

local victoryClosing = false
local function setVictoryButton(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.Selectable = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = if enabled then 0 else 0.55
end

local function refreshVictoryContent(snap: any)
	local teamA, teamB = 0, 0
	for _, participant in snap.players do
		if participant.team == "A" then teamA += participant.cash or 0 end
		if participant.team == "B" then teamB += participant.cash or 0 end
	end
	victoryUI.title.Text = "PERTANDINGAN SELESAI"
	local resultText = tostring(snap.result or "")
	local winnerA = string.find(resultText, "TIM A MENANG", 1, true) ~= nil
	local winnerB = string.find(resultText, "TIM B MENANG", 1, true) ~= nil
	if trophyBanner then
		if winnerA or winnerB then
			trophyBanner.Text = "\u{1F3C6}  " .. resultText
			trophyBanner.TextColor3 = if winnerA then Color3.fromRGB(174, 221, 202) else Color3.fromRGB(242, 196, 167)
			if trophyStroke then
				trophyStroke.Color = if winnerA then Color3.fromRGB(80, 170, 140) else Color3.fromRGB(214, 130, 90)
			end
			trophyBanner.Visible = true
		else
			trophyBanner.Visible = false
		end
	end
	victoryUI.status.Text = if typeof(snap.result) == "string" and #snap.result > 0 then snap.result else "Hasil pertandingan telah ditetapkan server."
	victoryUI.scores.Text = "SALDO AKHIR TIM\nTim A  •  " .. Rules.formatMoney(teamA) .. "\nTim B  •  " .. Rules.formatMoney(teamB)
	local mySeat = findMySeat(snap)
	local canRematch = mySeat > 0 and not snap.rematchUnavailable
	local voted = mySeat > 0 and snap.rematchVotes and snap.rematchVotes[mySeat]
	victoryUI.rematch.Text = if voted then "BATAL MAIN LAGI" else "MAIN LAGI"
	setVictoryButton(victoryUI.rematch, canRematch)
	local canReturn = mySeat > 0 and snap.routing and snap.routing.canReturnToLobby == true
	setVictoryButton(victoryUI.returnLobby, canReturn)
end

local function showVictory(snap: any, animate: boolean)
	refreshVictoryContent(snap)
	victoryClosing = false
	if not victoryPanel.Visible then
		victoryPanel.Visible = true
		animate = true
	end
	if animate then
		victoryPanel.BackgroundTransparency = 1
		victoryContent.GroupTransparency = 1
		victoryUI.scale.Scale = 0.90
		TweenService:Create(victoryPanel, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.34}):Play()
		TweenService:Create(victoryContent, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
		TweenService:Create(victoryUI.scale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		if audio then
			local resultText = tostring(snap.result or "")
			local winnerA = string.find(resultText, "TIM A MENANG", 1, true) ~= nil
			local winnerB = string.find(resultText, "TIM B MENANG", 1, true) ~= nil
			local mySeat = findMySeat(snap)
			local myTeam = if mySeat > 0 and snap.players and snap.players[mySeat] then snap.players[mySeat].team else ""
			local won = (winnerA and myTeam == "A") or (winnerB and myTeam == "B")
			if won then
				audio:playSfx("WinJingle", false)
			else
				audio:playSfx("LoseJingle", false)
			end
		end
	end
end

local function hideVictory()
	if not victoryPanel.Visible or victoryClosing then return end
	victoryClosing = true
	TweenService:Create(victoryPanel, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
	local fade = TweenService:Create(victoryContent, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
	TweenService:Create(victoryUI.scale, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.96}):Play()
	fade:Play()
	fade.Completed:Once(function()
		victoryPanel.Visible = false
		victoryClosing = false
	end)
end

victoryUI.rematch.Activated:Connect(function()
	if victoryUI.rematch.Active and latest and latest.phase == "Finished" and allowed.Ready then
		send("Rematch")
	end
end)
victoryUI.returnLobby.Activated:Connect(function()
	if victoryUI.returnLobby.Active and latest and latest.phase == "Finished" and allowed.ReturnLobby then
		send("ReturnLobby")
	end
end)

local function updateVictory(previous: any, current: any)
	if current.phase == "Finished" then
		local entering = typeof(previous) ~= "table" or previous.phase ~= "Finished"
		showVictory(current, entering)
	elseif victoryPanel.Visible then
		hideVictory()
	end
end

local function playSnapshotFeedback(previous: any, current: any)
	if typeof(previous) ~= "table" or typeof(current) ~= "table" then return end
	local currentSeat = findMySeat(current)
	if currentSeat <= 0 then return end

	if typeof(previous.owners) == "table" and typeof(current.owners) == "table" then
		for tileIndex = 1, Rules.TileCount do
			local oldOwner = previous.owners[tileIndex] or 0
			local newOwner = current.owners[tileIndex] or 0
			if oldOwner == 0 and newOwner == currentSeat then
				playPop(propertyPanel, 0.90, 1.06)
				break
			end
		end
	end

	local previousSeat = findMySeat(previous)
	local previousParticipant = if previousSeat > 0 then previous.players[previousSeat] else nil
	local currentParticipant = current.players[currentSeat]

	if previousParticipant and currentParticipant and audio then
		local oldCash = previousParticipant.cash or 0
		local newCash = currentParticipant.cash or 0
		if newCash < oldCash then
			audio:playSfx("CashSpend", true)
		elseif newCash > oldCash then
			audio:playSfx("CashIncome", true)
		end

		if previousParticipant.inJail ~= true and currentParticipant.inJail == true then
			audio:playSfx("SirenLapas", false)
		end

		if typeof(previous.buildings) == "table" and typeof(current.buildings) == "table" then
			for tileIndex = 1, Rules.TileCount do
				local oldLevel = previous.buildings[tileIndex] or 0
				local newLevel = current.buildings[tileIndex] or 0
				if newLevel > oldLevel and current.owners[tileIndex] == currentSeat then
					audio:playSfx("BuildUpgrade", true)
					break
				end
			end
		end
	end

	if previousParticipant and currentParticipant and previousParticipant.position ~= currentParticipant.position then
		focusTile(currentParticipant.position)
		local board = WS:FindFirstChild("WNIBoard")
		local tilesFolder = board and board:FindFirstChild("Tiles")
		local tile = tilesFolder and tilesFolder:FindFirstChild(string.format("Tile_%02d", currentParticipant.position))
		local kind = if tile then tile:GetAttribute("TileKind") else nil
		if typeof(kind) == "string" then showSpecialTileToast(kind) end
	end
	local previousHand = if previousParticipant and typeof(previousParticipant.hand) == "table" then previousParticipant.hand else {}
	local currentHand = if currentParticipant and typeof(currentParticipant.hand) == "table" then currentParticipant.hand else {}
	if #currentHand > #previousHand then
		playPop(handButton, 0.78, 1.16)
		if handPanel.Visible then
			playPop(handPanel, 0.88, 1.05)
		end
	end

	local previousNewest = if typeof(previous.logs) == "table" then previous.logs[1] else nil
	local currentNewest = if typeof(current.logs) == "table" then current.logs[1] else nil
	if typeof(currentNewest) == "string" and currentNewest ~= previousNewest and currentParticipant then
		local mentionsPlayer = string.find(currentNewest, currentParticipant.name, 1, true) ~= nil
		local drewCard = string.find(currentNewest, "menarik", 1, true) ~= nil
		if mentionsPlayer and drewCard then
			showCardToast(currentNewest)
			showCardModal(currentNewest)
			if audio then audio:playSfx("CardDraw", true) end
		end
	end

	if audio and previous.phase ~= "Finished" and current.phase == "Finished" then
		audio:stopBgm()
		local teamA, teamB = 0, 0
		for _, participant in current.players do
			if participant.team == "A" then teamA += participant.cash or 0 end
			if participant.team == "B" then teamB += participant.cash or 0 end
		end
		local myTeam = currentParticipant.team
		local won = (myTeam == "A" and teamA > teamB) or (myTeam == "B" and teamB > teamA)
		if teamA ~= teamB then
			audio:playSfx(if won then "WinJingle" else "LoseJingle", false)
		end
	elseif audio and previous.phase == "Finished" and current.phase ~= "Finished" then
		audio:startBgm()
	end
end

local function refreshHand()
	local hand, participant, seat = ownHand()
	local pending = ownLandChoice()
	if pending then
		if not wasChoosingLand or handMatchId ~= latest.matchId then landOrdinal = 1 end
		wasChoosingLand = true
		handMatchId = latest.matchId
		handPanel.Visible = true
		handButton.Visible = false
		closeHand.Visible = false
		previousCard.Visible = false
		nextCard.Visible = false
		local options = pending.options or {}
		landOrdinal = math.clamp(landOrdinal, 1, math.max(1, #options))
		local target = options[landOrdinal]
		local definition = CardData.get(pending.id)
		handName.Text = if definition then definition.name else pending.id
		handDescription.Text = if definition then definition.note else "Pilih tanah untuk kartu ini."
		handChoice.Text = if target then tostring(landOrdinal) .. "/" .. #options .. " - " .. describeTile(latest, target, seat) else "Tidak ada tanah yang memenuhi syarat"
		useCard.Text = "PILIH TANAH"
		if mobileTouchMode then
			useCard.Position = UDim2.fromScale(0.04, 0.81)
			useCard.Size = UDim2.fromScale(0.50, 0.18)
		else
			useCard.Position = UDim2.fromScale(0.05, 0.84)
			useCard.Size = UDim2.fromScale(0.50, 0.11)
		end
		skipCardChoice.Visible = pending.canSkip == true
		cardControl(skipCardChoice, pending.canSkip == true)
		cardControl(useCard, target ~= nil)
		cardControl(previousChoice, #options > 1)
		cardControl(nextChoice, #options > 1)
		handMessage.Text = if pending.canSkip then "Pilih tanah lawan atau Lewati. Saat waktu habis: dilewati." else "Saat waktu habis: tanah sah pertama dipilih otomatis."
		if typeof(latest.error) == "string" and #latest.error > 0 then handMessage.Text = latest.error end
		return
	end
	if wasChoosingLand then handPanel.Visible = false; wasChoosingLand = false end
	closeHand.Visible = true
	previousCard.Visible = true
	nextCard.Visible = true
	skipCardChoice.Visible = false
	useCard.Text = "GUNAKAN KARTU"
	if mobileTouchMode then
		useCard.Position = UDim2.fromScale(0.20, 0.81)
		useCard.Size = UDim2.fromScale(0.60, 0.18)
	else
		useCard.Position = UDim2.fromScale(0.22, 0.84)
		useCard.Size = UDim2.fromScale(0.56, 0.11)
	end
	local inMatch = latest and latest.phase ~= "Waiting" and latest.phase ~= "Finished" and latest.phase ~= "Cancelled"
	handButton.Visible = participant ~= nil and inMatch == true
	handButton.Text = "KARTU SAYA (" .. #hand .. ")"
	if not handButton.Visible or handMatchId ~= latest.matchId then
		handPanel.Visible = false
		handOrdinal = 1
		cardChoice = 1
	end
	handMatchId = if latest then latest.matchId else nil
	handOrdinal = math.clamp(handOrdinal, 1, math.max(1, #hand))
	local id = hand[handOrdinal]
	local definition = if id then CardData.get(id) else nil
	local supported = id == "KaburAjaDulu" or id == "OrangDalam" or id == "DoaOrangTua"
	local maximum = if id == "KaburAjaDulu" then Rules.TileCount elseif id == "OrangDalam" then 6 else 3
	cardChoice = math.clamp(cardChoice, 1, maximum)
	handName.Text = if definition then definition.name .. " (" .. handOrdinal .. "/" .. #hand .. ")" else "Belum ada kartu simpanan"
	handDescription.Text = if definition then definition.note else "Kartu simpanan yang kamu peroleh akan muncul di sini."
	if id == "KaburAjaDulu" then
		local tileName = describeTile(latest, cardChoice, seat)
		handChoice.Text = "Tujuan " .. cardChoice .. ": " .. tileName
	elseif id == "OrangDalam" then
		handChoice.Text = "Dadu Musibah berikutnya: " .. cardChoice
	elseif id == "DoaOrangTua" then
		local TIERS = {"high", "mid", "low"}
		local TIER_LABELS = {high = "✅ Aman (5-6)", mid = "⚠️ Sedang (3-4)", low = "❌ Berat (1-2)"}
		local tierKey = TIERS[cardChoice] or "high"
		handChoice.Text = "Tier: " .. (TIER_LABELS[tierKey] or tierKey)
	else
		handChoice.Text = "-"
	end
	local canUse = supported and participant ~= nil and not participant.eliminated and latest.phase == "AwaitRoll" and latest.activeSeat == seat
	if id == "OrangDalam" and participant and participant.insiderDie then canUse = false end
	if id == "DoaOrangTua" and participant and participant.doaTier then canUse = false end
	cardControl(useCard, canUse)
	cardControl(previousCard, #hand > 1)
	cardControl(nextCard, #hand > 1)
	cardControl(previousChoice, supported)
	cardControl(nextChoice, supported)
	local statusMsg = if participant and id == "OrangDalam" and participant.insiderDie
		then "Orang Dalam sudah siap: dadu " .. participant.insiderDie .. "."
		elseif participant and id == "DoaOrangTua" and participant.doaTier
		then "Doa Orang Tua sudah siap: tier " .. (participant.doaTier or "") .. "."
		elseif canUse then "Sekali pakai. Pastikan pilihanmu sebelum menggunakan kartu."
		else "Gunakan sebelum melempar dadu pada giliranmu."
	handMessage.Text = statusMsg
	if latest and typeof(latest.error) == "string" and #latest.error > 0 then handMessage.Text = latest.error end
end
handButton.Activated:Connect(function()
	handPanel.Visible = not handPanel.Visible
	refreshHand()
end)
closeHand.Activated:Connect(function() handPanel.Visible = false end)
local function cycleCard(direction: number)
	local hand = ownHand()
	if #hand < 2 then return end
	handOrdinal = (handOrdinal - 1 + direction) % #hand + 1
	cardChoice = 1
	refreshHand()
end
previousCard.Activated:Connect(function() cycleCard(-1) end)
nextCard.Activated:Connect(function() cycleCard(1) end)
local function cycleCardChoice(direction: number)
	local pending = ownLandChoice()
	if pending then
		local count = #pending.options
		if count > 1 then landOrdinal = (landOrdinal - 1 + direction) % count + 1 end
		refreshHand()
		return
	end
	local hand = ownHand()
	local id = hand[handOrdinal]
	if id ~= "KaburAjaDulu" and id ~= "OrangDalam" and id ~= "DoaOrangTua" then return end
	local maximum = if id == "KaburAjaDulu" then Rules.TileCount elseif id == "OrangDalam" then 6 else 3
	cardChoice = (cardChoice - 1 + direction) % maximum + 1
	refreshHand()
end
previousChoice.Activated:Connect(function() cycleCardChoice(-1) end)
nextChoice.Activated:Connect(function() cycleCardChoice(1) end)
useCard.Activated:Connect(function()
	refreshHand()
	if not useCard.Active or not latest or os.clock() - lastCardRequest < 0.3 then return end
	local pending = ownLandChoice()
	if pending then
		local target = pending.options[landOrdinal]
		if not target then return end
		lastCardRequest = os.clock()
		requestAction:FireServer("SelectCardLand", latest.revision, latest.version, target)
		return
	end
	local hand = ownHand()
	local id = hand[handOrdinal]
	if not id then return end
	lastCardRequest = os.clock()
	local choice: any = cardChoice
	if id == "DoaOrangTua" then
		local TIERS = {"high", "mid", "low"}
		choice = TIERS[cardChoice] or "high"
	end
	requestAction:FireServer("PlayCard", latest.revision, latest.version, {cardId = id, choice = choice})
end)

skipCardChoice.Activated:Connect(function()
	local pending = ownLandChoice()
	if not pending or not pending.canSkip or not latest or os.clock() - lastCardRequest < 0.3 then return end
	lastCardRequest = os.clock()
	requestAction:FireServer("SkipCardChoice", latest.revision, latest.version)
end)

local viewportConnection: RBXScriptConnection? = nil
local function updateInterfaceScale()
	interfaceScale.Scale = 1
	local cam = WS.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	if applyResponsiveLayout then
		applyResponsiveLayout(vp)
	end
end

local function bindViewport()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = WS.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateInterfaceScale)
	end
	updateInterfaceScale()
end

WS:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
bindViewport()

-- Phase 2 client polish: local-only SFX, onboarding, and panel transitions.
local uiSounds = waitFor(gui, "UISounds")
local AudioHelper = require(waitFor(gui, "AudioHelper") :: ModuleScript)
audio = AudioHelper.new(uiSounds)
audio:startBgm()
local clickSound = waitFor(uiSounds, "Click") :: Sound
local diceSound = waitFor(uiSounds, "RollDice") :: Sound
local cardSound = waitFor(uiSounds, "CardDraw") :: Sound

local function playUISound(sound: Sound)
	if root:GetAttribute("AudioMuted") == true then return end
	if audio then
		audio:playSfx(sound.Name, sound.Name == "Click" or sound.Name == "RollDice")
		return
	end
	sound:Stop()
	sound.TimePosition = 0
	sound:Play()
end

local function initPolishUI()
	local cameraFollow = false
	local cameraTween: Tween? = nil
	local overviewCF: CFrame? = nil
	local actionBanner = waitFor(root, "ActionBanner") :: Frame
	local bannerLabel = waitFor(actionBanner, "Text") :: TextLabel
	local botButton = waitFor(panel, "BotButton") :: TextButton
	local GOLD_GLOW = Color3.fromRGB(255, 208, 84)
	local function overviewCFrame(): CFrame
		local cam = WS.CurrentCamera
		if cam and overviewCF then return overviewCF end
		local board = WS:FindFirstChild("WNIBoard")
		local pivot = board and board:GetPivot() or CFrame.new(9, 9, 8)
		return CFrame.new(pivot.Position + Vector3.new(0, 132, 72), pivot.Position)
	end
	local function tweenCameraTo(targetCF: CFrame, duration: number)
		local cam = WS.CurrentCamera
		if not cam then return end
		if cameraTween then cameraTween:Cancel() end
		cameraTween = TweenService:Create(cam, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CFrame = targetCF})
		cameraTween:Play()
	end
	focusTile = function(position: number)
		if not cameraFollow then return end
		local board = WS:FindFirstChild("WNIBoard")
		local tilesFolder = board and board:FindFirstChild("Tiles")
		local tile = tilesFolder and tilesFolder:FindFirstChild(string.format("Tile_%02d", position))
		local anchor = tile and tile:FindFirstChild("PawnAnchor")
		local cam = WS.CurrentCamera
		if not (anchor and cam) then return end
		local tilePos = anchor.WorldPosition
		tweenCameraTo(CFrame.new(tilePos + Vector3.new(0, 9, 9), tilePos), 0.5)
	end
	restoreOverview = function()
		if not cameraFollow then return end
		tweenCameraTo(overviewCFrame(), 0.7)
	end

	local bannerGeneration = 0
	local bannerScale = feedbackScale(actionBanner)
	showActionBanner = function(text: string)
		bannerGeneration += 1
		local generation = bannerGeneration
		bannerLabel.Text = text
		actionBanner.Visible = true
		actionBanner.BackgroundTransparency = 0.12
		bannerLabel.TextTransparency = 0
		bannerScale.Scale = 0.82
		TweenService:Create(bannerScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(actionBanner, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.12}):Play()
		TweenService:Create(bannerLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		task.delay(1.5, function()
			if generation ~= bannerGeneration or not actionBanner:IsDescendantOf(game) then return end
			local fade = TweenService:Create(actionBanner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
			TweenService:Create(bannerLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
			fade:Play()
			fade.Completed:Once(function()
				if generation == bannerGeneration then actionBanner.Visible = false end
			end)
		end)
	end

	local seatGlowStrokes: {UIStroke?} = {}
	local seatGlowTweens: {Tween?} = {}
	for seat = 1, Rules.PlayerCount do
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 0
		stroke.Color = GOLD_GLOW
		stroke.Parent = seats[seat].frame
		seatGlowStrokes[seat] = stroke
	end
	setSeatGlow = function(seat: number, on: boolean)
		local stroke = seatGlowStrokes[seat]
		if not stroke then return end
		local old = seatGlowTweens[seat]
		if old then old:Cancel() seatGlowTweens[seat] = nil end
		if on then
			local t = TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 2.4, Transparency = 0.25})
			t:Play()
			seatGlowTweens[seat] = t
		else
			local t = TweenService:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 0, Transparency = 0})
			t:Play()
			seatGlowTweens[seat] = t
		end
	end
	local rollPulse: Tween? = nil
	setRollPulse = function(on: boolean)
		if rollPulse then rollPulse:Cancel() rollPulse = nil end
		local scale = feedbackScale(buttons.Roll)
		if on then
			scale.Scale = 1
			local t = TweenService:Create(scale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.07})
			t:Play()
			rollPulse = t
		else
			scale.Scale = 1
		end
	end
	local lastBotRequest = -math.huge
	refreshBotButton = function(snap: any)
		local room = snap.room
		local inMatch = snap.phase ~= "Waiting" and snap.phase ~= "Finished" and snap.phase ~= "Cancelled"
		local show = not inMatch and typeof(room) == "table" and room.member == true and room.phase == "Waiting" and room.count < room.capacity
		botButton.Visible = show
		botButton.Active = show
		botButton.Selectable = show
		botButton.AutoButtonColor = show
	end
	botButton.Activated:Connect(function()
		if not botButton.Active or not latest or os.clock() - lastBotRequest < 0.3 then return end
		local room = latest.room
		if typeof(room) ~= "table" or room.phase ~= "Waiting" then return end
		lastBotRequest = os.clock()
		requestAction:FireServer("FillBots", room.revision, latest.version)
	end)
	local lastDiceBanner: string? = nil
	local boundSfxButtons: {[TextButton]: boolean} = {}
	local function bindButtonSfx(instance: Instance)
		if not instance:IsA("TextButton") or boundSfxButtons[instance] then return end
		boundSfxButtons[instance] = true
		instance.Activated:Connect(function()
			playUISound(clickSound)
			if instance == buttons.Roll then
				playUISound(diceSound)
			end
		end)
	end
	for _, descendant in root:GetDescendants() do
		bindButtonSfx(descendant)
	end
	root.DescendantAdded:Connect(bindButtonSfx)
	-- CardDraw SFX is driven by the authoritative snapshot transition in playSnapshotFeedback.

	local tutorial = waitFor(root, "TutorialPanel") :: Frame
	local muteButton = header:FindFirstChild("MuteButton") :: TextButton?
	if muteButton then
		muteButton.Activated:Connect(function()
			local gui = root.Parent
			local soundsFolder = gui and gui:FindFirstChild("UISounds")
			local isMuted = muteButton:GetAttribute("Muted") == true
			isMuted = not isMuted
			muteButton:SetAttribute("Muted", isMuted)
			root:SetAttribute("AudioMuted", isMuted)
			if audio then audio:setMuted(isMuted) end
			muteButton.Text = if isMuted then "🔇" else "🔊"
			if soundsFolder then
				for _, s in ipairs(soundsFolder:GetChildren()) do
					if s:IsA("Sound") then
						if not s:GetAttribute("OriginalVol") then
							s:SetAttribute("OriginalVol", s.Volume)
						end
						s.Volume = if isMuted then 0 else (s:GetAttribute("OriginalVol") or 0.5)
					end
				end
			end
		end)
	end
	local tutorialState = {
		fade = waitFor(tutorial, "FadeGroup") :: CanvasGroup,
		card = nil :: any,
		ui = nil :: any,
		pages = {
			"Tujuanmu adalah membangun kekayaan bersama tim dan bertahan sampai pertandingan selesai. Semua uang, tanah, kartu, dan giliran ditentukan server.",
			"Masuk atau buat room, pilih Tim A atau Tim B, lalu tekan SIAP. Pertandingan dimulai setelah empat pemain siap dan susunan tim valid.",
			"Saat giliranmu, tekan LEMPAR DADU. Jika mendarat di tanah kosong, kamu dapat membeli. Tanah milikmu dapat ditingkatkan saat fase pembangunan jika saldo mencukupi.",
			"Kartu Takdir dan Musibah dapat memberi efek langsung atau disimpan di tangan. Perhatikan LAPAS, Pengadilan, pajak, parkiran, dan informasi sewa pada panel properti."
		},
		index = 1,
		pending = true,
		closing = false,
	}
	tutorialState.card = waitFor(tutorialState.fade, "Card") :: Frame
	tutorialState.ui = {
		fade = tutorialState.fade,
		card = tutorialState.card,
		page = waitFor(tutorialState.card, "Page") :: TextLabel,
		body = waitFor(tutorialState.card, "Body") :: TextLabel,
		previous = waitFor(tutorialState.card, "Previous") :: TextButton,
		next = waitFor(tutorialState.card, "Next") :: TextButton,
		skip = waitFor(tutorialState.card, "Skip") :: TextButton,
		scale = feedbackScale(tutorialState.card),
	}

	local function refreshTutorial()
		tutorialState.index = math.clamp(tutorialState.index, 1, #tutorialState.pages)
		tutorialState.ui.page.Text = string.format("LANGKAH %d / %d", tutorialState.index, #tutorialState.pages)
		tutorialState.ui.body.Text = tutorialState.pages[tutorialState.index]
		tutorialState.ui.previous.Active = tutorialState.index > 1
		tutorialState.ui.previous.Selectable = tutorialState.ui.previous.Active
		tutorialState.ui.previous.AutoButtonColor = tutorialState.ui.previous.Active
		tutorialState.ui.previous.TextTransparency = if tutorialState.ui.previous.Active then 0 else 0.55
		tutorialState.ui.next.Text = if tutorialState.index == #tutorialState.pages then "SELESAI" else "LANJUT"
	end

	showTutorial = function()
		if tutorial.Visible then return end
		tutorialState.closing = false
		refreshTutorial()
		tutorial.BackgroundColor3 = Color3.fromRGB(10, 16, 18)
		tutorial.BackgroundTransparency = 1
		tutorialState.fade.GroupTransparency = 1
		tutorialState.ui.scale.Scale = 0.94
		tutorial.Visible = true
		TweenService:Create(tutorial, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.45}):Play()
		TweenService:Create(tutorialState.fade, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
		TweenService:Create(tutorialState.ui.scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end

	local function hideTutorial()
		if not tutorial.Visible or tutorialState.closing then return end
		tutorialState.closing = true
		TweenService:Create(tutorial, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		local fadeTween = TweenService:Create(tutorialState.fade, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
		TweenService:Create(tutorialState.ui.scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.96}):Play()
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			tutorial.Visible = false
			tutorialState.closing = false
		end)
	end

	tutorialState.ui.previous.Activated:Connect(function()
		if tutorialState.index > 1 then
			tutorialState.index -= 1
			refreshTutorial()
		end
	end)
	tutorialState.ui.next.Activated:Connect(function()
		if tutorialState.index >= #tutorialState.pages then
			hideTutorial()
		else
			tutorialState.index += 1
			refreshTutorial()
		end
	end)
	tutorialState.ui.skip.Activated:Connect(hideTutorial)

	showTutorialIfPending = function(phase: string)
		if tutorialState.pending then
			tutorialState.pending = false
			if phase ~= "Finished" and phase ~= "Cancelled" then
				task.defer(showTutorial)
			end
		end
	end

	do
		local btn = Instance.new("TextButton")
		cameraToggle = btn
		btn.Name = "CameraToggle"
		btn.AnchorPoint = Vector2.new(1, 1)
		btn.Position = UDim2.new(1, -20, 1, -112)
		btn.Size = UDim2.new(0, 140, 0, 34)
		btn.BackgroundColor3 = Color3.fromRGB(24, 46, 42)
		btn.Font = Enum.Font.GothamBold
		btn.Text = "KAMERA BEBAS"
		btn.TextColor3 = Color3.fromRGB(210, 224, 214)
		btn.TextSize = 12
		btn.TextScaled = false
		btn.Parent = root
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(56, 98, 88)
		stroke.Thickness = 1
		stroke.Parent = btn
		local constraint = Instance.new("UISizeConstraint")
		constraint.Name = "MobileMinTouchTarget"
		constraint.MinSize = Vector2.new(44, 34)
		constraint.Parent = btn
		btn.Activated:Connect(function() 
			cameraFollow = not cameraFollow
			if cameraFollow then
				overviewCF = overviewCFrame()
				btn.Text = "IKUTI PION"
				local seatNow = findMySeat(latest or {})
				local posNow = if seatNow > 0 and latest and latest.players[seatNow] then latest.players[seatNow].position else nil
				if posNow then focusTile(posNow) else restoreOverview() end
			else
				btn.Text = "KAMERA BEBAS"
				tweenCameraTo(overviewCFrame(), 0.7)
			end
		end)
		if applyResponsiveLayout and WS.CurrentCamera then
			applyResponsiveLayout(WS.CurrentCamera.ViewportSize)
		end
	end
end
initPolishUI()

stateUpdated.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	local previous = latest
	latest = payload
	if typeof(payload.error) == "string" and #payload.error > 0 then
		errText = payload.error
		errUntil = os.clock() + 4
	end
	refresh(payload)
	refreshBuildPicker(payload)
	refreshRoom(payload)
	refreshMatchmaking(payload)
	refreshHand()
	updateHint()
	updateAvatarIndicators(previous, payload)
	updateVictory(previous, payload)
	playSnapshotFeedback(previous, payload)
	if typeof(previous) == "table" and previous.phase ~= payload.phase then restoreOverview() end
	if showTutorialIfPending then
		showTutorialIfPending(payload.phase)
	end
	if audio then
		if payload.phase == "Waiting" or payload.phase == "Preparation" or payload.phase == "Ended" then
			audio:crossfadeBgm("Lobby", 1.2)
		elseif payload.phase == "Active" then
			if typeof(payload.round) == "number" and payload.round >= 6 then
				audio:crossfadeBgm("Climax", 1.0)
			else
				audio:crossfadeBgm("Match", 1.2)
			end
		end
	end
end)

task.spawn(function()
	while script:IsDescendantOf(game) do
		updateHint()
		if latest then refreshMatchmaking(latest) end
		task.wait(0.25)
	end
end)

requestAction:FireServer("Sync", 0, Rules.Version)
