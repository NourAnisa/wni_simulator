--!strict
-- TurnService.luau
-- Mengatur alur giliran, lemparan dadu, dan pergerakan pemain

local TurnService = {}
TurnService.__index = TurnService

export type PlayerState = {
    userId: number,
    name: string,
    teamId: number, -- 1 atau 2 (2v2)
    tileIndex: number,
    money: number,
    inLapas: boolean,
    lapasTurns: number,
    isBankrupt: boolean,
}

local BoardData = require(script.Parent.Parent.shared.BoardData)

function TurnService.new()
    local self = setmetatable({}, TurnService)
    self.players = {} :: { [number]: PlayerState }
    self.turnOrder = {} :: { number }
    self.currentTurnIdx = 1
    self.isGameActive = false
    self.totalTiles = 18 -- Petak keliling utama 1..18
    return self
end

function TurnService:AddPlayer(player: Player, teamId: number)
    local state: PlayerState = {
        userId = player.UserId,
        name = player.DisplayName or player.Name,
        teamId = teamId,
        tileIndex = 1, -- Mulai di START
        money = 10000000, -- Modal awal Rp10.000.000
        inLapas = false,
        lapasTurns = 0,
        isBankrupt = false,
    }
    self.players[player.UserId] = state
    table.insert(self.turnOrder, player.UserId)
end

function TurnService:StartGame()
    if #self.turnOrder < 2 then
        warn("Butuh minimal 2 pemain untuk memulai sesi.")
        return false
    end
    self.isGameActive = true
    self.currentTurnIdx = 1
    print("[TurnService] Game WNI Simulator dimulai! Giliran pertama: " .. tostring(self:GetCurrentPlayer().name))
    return true
end

function TurnService:GetCurrentPlayer(): PlayerState
    local currentUserId = self.turnOrder[self.currentTurnIdx]
    return self.players[currentUserId]
end

-- Lempar 2 dadu dan gerakkan pemain
function TurnService:RollDiceAndMove(): (number, number, number)
    local pState = self:GetCurrentPlayer()
    if not pState or pState.isBankrupt then
        return 0, 0, 0
    end

    local d1 = math.random(1, 6)
    local d2 = math.random(1, 6)
    local totalSteps = d1 + d2

    local oldPos = pState.tileIndex
    local newPos = oldPos + totalSteps

    -- Cek jika melewati START (Petak 1)
    if newPos > self.totalTiles then
        newPos = newPos - self.totalTiles
        -- Tambahkan Gaji START Rp1.000.000
        pState.money += 1000000
        print(string.format("[START] %s melewati START dan menerima gaji Rp1.000.000! Saldo sekarang: Rp%d", pState.name, pState.money))
    end

    pState.tileIndex = newPos
    print(string.format("[Move] %s melempar [%d + %d = %d]. Mendarat di Petak %d (%s)", 
        pState.name, d1, d2, totalSteps, newPos, BoardData[newPos].name))

    return d1, d2, totalSteps
end

function TurnService:NextTurn()
    repeat
        self.currentTurnIdx += 1
        if self.currentTurnIdx > #self.turnOrder then
            self.currentTurnIdx = 1
        end
    until not self:GetCurrentPlayer().isBankrupt

    print(string.format("[TurnService] Giliran berikutnya: %s (Saldo: Rp%d)", 
        self:GetCurrentPlayer().name, self:GetCurrentPlayer().money))
end

return TurnService
