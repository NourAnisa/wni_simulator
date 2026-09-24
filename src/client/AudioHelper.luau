--!strict
-- AudioHelper.luau
-- Manajemen audio klien: SFX dinamis, auto-instantiation sound template, dan crossfade BGM adaptif (Lobby -> Match -> Climax).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioConfig = require(ReplicatedStorage:WaitForChild("WNI"):WaitForChild("AudioConfig"))

local AudioHelper = {}
AudioHelper.__index = AudioHelper

export type AudioHelperObject = {
	folder: Instance,
	sfxMuted: boolean,
	bgmMuted: boolean,
	currentBgm: Sound?,
	playSfx: (self: AudioHelperObject, soundName: string, pitchVariation: boolean?) -> (),
	crossfadeBgm: (self: AudioHelperObject, trackKey: string, duration: number?) -> (),
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
	BGM = "LobbyBGM",
}

local function findSound(folder: Instance, soundName: string): Sound?
	local resolved = ALIASES[soundName] or soundName
	local instance = folder:FindFirstChild(resolved)
	if instance and instance:IsA("Sound") then
		return instance
	end
	return nil
end

local function ensureTemplates(folder: Instance)
	-- Pastikan sound template SFX ada
	for sfxName, data in pairs(AudioConfig.SFX) do
		local existing = folder:FindFirstChild(sfxName)
		if not existing then
			local s = Instance.new("Sound")
			s.Name = sfxName
			s.SoundId = data.Id
			s.Volume = data.Volume
			s.Looped = false
			s.Parent = folder
		end
	end

	-- Pastikan sound template BGM ada
	for bgmKey, data in pairs(AudioConfig.BGM) do
		local trackName = bgmKey .. "BGM"
		local existing = folder:FindFirstChild(trackName)
		if not existing then
			local s = Instance.new("Sound")
			s.Name = trackName
			s.SoundId = data.Id
			s.Volume = data.Volume
			s.Looped = data.Looped
			s.Parent = folder
		end
	end
end

function AudioHelper.new(folder: Instance): AudioHelperObject
	local self = setmetatable({}, AudioHelper) :: any
	self.folder = folder
	self.sfxMuted = false
	self.bgmMuted = false
	self.currentBgm = nil

	ensureTemplates(folder)
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
		local factor = 0.94 + (math.random() * 0.12)
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

function AudioHelper:crossfadeBgm(trackKey: string, duration: number?)
	local fadeTime = duration or 1.2
	local trackName = (trackKey .. "BGM")
	local targetSound = self.folder:FindFirstChild(trackName)
	if not targetSound or not targetSound:IsA("Sound") then
		targetSound = self.folder:FindFirstChild("LobbyBGM")
	end
	if not targetSound or not targetSound:IsA("Sound") then return end

	if self.currentBgm == targetSound and targetSound.IsPlaying then
		return
	end

	local targetVolume = targetSound:GetAttribute("BaseVolume") :: number?
	if not targetVolume then
		targetVolume = targetSound.Volume
		targetSound:SetAttribute("BaseVolume", targetVolume)
	end

	-- Fade Out BGM lama
	if self.currentBgm and self.currentBgm.IsPlaying then
		local old = self.currentBgm
		local fadeOut = TweenService:Create(old, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = 0})
		fadeOut.Completed:Once(function()
			old:Stop()
			old.Volume = old:GetAttribute("BaseVolume") or 0.3
		end)
		fadeOut:Play()
	end

	self.currentBgm = targetSound

	if not self.bgmMuted then
		targetSound.Volume = 0
		targetSound.Looped = true
		targetSound:Play()
		TweenService:Create(targetSound, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume = targetVolume}):Play()
	end
end

function AudioHelper:startBgm()
	if self.bgmMuted then return end
	if self.currentBgm then
		if not self.currentBgm.IsPlaying then
			self.currentBgm:Play()
		end
	else
		self:crossfadeBgm("Lobby", 0.8)
	end
end

function AudioHelper:stopBgm()
	if self.currentBgm then
		self.currentBgm:Stop()
	end
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
