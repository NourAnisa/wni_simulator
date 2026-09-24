--!strict
-- EmoteServer.luau
-- Layanan server-authoritative untuk menerima dan memvalidasi reaksi emotikon pemain.
-- Memeriksa whitelist emoji, menerapkan rate limit anti-spam, dan menyiarkan ke seluruh client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local emoteRemote = remotes:WaitForChild("PlayerEmote", 10)
if not emoteRemote or not emoteRemote:IsA("RemoteEvent") then return end

local ALLOWED_EMOJIS = {
	["😂"] = true,
	["😭"] = true,
	["😎"] = true,
	["🔥"] = true,
	["💀"] = true,
	["👑"] = true,
	["💸"] = true,
	["👋"] = true,
	-- Pesan Chat Cepat (Quick Chat)
	["Sewa please! 😭"] = true,
	["Monopoli kita! 👑"] = true,
	["Pungli lagi?! 💸"] = true,
	["Hoki banget! 🔥"] = true,
	["Ampun bang! 🙏"] = true,
	["GGWP! 🏆"] = true,
	["Begal nih bos! 💀"] = true,
	["Kabur dulu ah! 💨"] = true,
}

local COOLDOWN_SECONDS = 1.5
local lastEmoteTime: {[number]: number} = {}

local function findSeatByPlayer(player: Player): number?
	local board = Workspace:FindFirstChild("WNIBoard")
	if not board then return nil end
	local pawnsFolder = board:FindFirstChild("Pawns")
	if not pawnsFolder then return nil end

	-- Cek kepemilikan avatar pawn atau nama
	for seat = 1, 4 do
		local pawn = pawnsFolder:FindFirstChild(string.format("Pawn_%d", seat))
			or pawnsFolder:FindFirstChild(string.format("MiniMe_%d", seat))

		if pawn then
			local ownerAttr = pawn:GetAttribute("OwnerUserId")
			if ownerAttr == player.UserId then
				return seat
			end
			-- Fallback: nama pawn
			if pawn:GetAttribute("PlayerName") == player.Name then
				return seat
			end
		end
	end

	-- Jika belum ada atribut, fallback cari seat dari urutan pemain di server
	local allPlayers = Players:GetPlayers()
	for i, p in ipairs(allPlayers) do
		if p == player then
			return i
		end
	end

	return 1
end

emoteRemote.OnServerEvent:Connect(function(player: Player, emojiText: any)
	if typeof(emojiText) ~= "string" or not ALLOWED_EMOJIS[emojiText] then
		return
	end

	local now = os.clock()
	local lastTime = lastEmoteTime[player.UserId] or 0
	if now - lastTime < COOLDOWN_SECONDS then
		return -- Abaikan jika spam terlalu cepat
	end
	lastEmoteTime[player.UserId] = now

	local seat = findSeatByPlayer(player)
	if not seat or seat <= 0 or seat > 4 then
		seat = 1
	end

	-- Siarkan ke seluruh client di dalam game
	emoteRemote:FireAllClients(seat, emojiText)
end)

Players.PlayerRemoving:Connect(function(player)
	lastEmoteTime[player.UserId] = nil
end)
