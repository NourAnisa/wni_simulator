--!strict

local AudioHelper = {}
AudioHelper.__index = AudioHelper

type AudioHelperObject = {
	folder: Instance,
	sfxMuted: boolean,
	bgmMuted: boolean,
	playSfx: (self: AudioHelperObject, soundName: string, pitchVariation: boolean?) -> (),
	startBgm: (self: AudioHelperObject) -> (),
	stopBgm: (self: AudioHelperObject) -> (),
	setSfxMuted: (self: AudioHelperObject, muted: boolean) -> (),
	setBgmMuted: (self: AudioHelperObject, muted: boolean) -> (),
	setMuted: (self: AudioHelperObject, muted: boolean) -> (),
	isMuted: (self: AudioHelperObject) -> boolean,
}

local ALIASES: {[string]: string} = {
	Dice = "RollDice",
	DiceRoll = "RollDice",
	Card = "CardDraw",
	JailSiren = "SirenLapas",
	Victory = "WinJingle",
}

local function findSound(folder: Instance, soundName: string): Sound?
	local resolved = ALIASES[soundName] or soundName
	local instance = folder:FindFirstChild(resolved)
	if instance and instance:IsA("Sound") then
		return instance
	end
	return nil
end

function AudioHelper.new(folder: Instance): AudioHelperObject
	local self = setmetatable({}, AudioHelper) :: any
	self.folder = folder
	self.sfxMuted = false
	self.bgmMuted = false
	return self
end

function AudioHelper:playSfx(soundName: string, pitchVariation: boolean?)
	if self.sfxMuted then return end
	local template = findSound(self.folder, soundName)
	if not template or template.SoundId == "" then return end

	local voice = template:Clone()
	voice.Name = "_Playing_" .. soundName
	voice.Looped = false
	if pitchVariation then
		local factor = 0.96 + (math.random() * 0.08)
		voice.PlaybackSpeed = math.clamp(template.PlaybackSpeed * factor, 0.5, 2)
	end
	voice.Parent = self.folder
	voice.Ended:Once(function()
		if voice.Parent then voice:Destroy() end
	end)
	voice:Play()
	task.delay(12, function()
		if voice.Parent then voice:Destroy() end
	end)
end

function AudioHelper:startBgm()
	local bgm = findSound(self.folder, "BGM")
	if not bgm then return end
	bgm.Looped = true
	if self.bgmMuted then
		bgm:Stop()
	elseif not bgm.IsPlaying then
		bgm:Play()
	end
end

function AudioHelper:stopBgm()
	local bgm = findSound(self.folder, "BGM")
	if bgm then bgm:Stop() end
end

function AudioHelper:setSfxMuted(muted: boolean)
	self.sfxMuted = muted
end

function AudioHelper:setBgmMuted(muted: boolean)
	self.bgmMuted = muted
	if muted then
		self:stopBgm()
	else
		self:startBgm()
	end
end

function AudioHelper:setMuted(muted: boolean)
	self:setSfxMuted(muted)
	self:setBgmMuted(muted)
end

function AudioHelper:isMuted(): boolean
	return self.sfxMuted and self.bgmMuted
end

return AudioHelper
