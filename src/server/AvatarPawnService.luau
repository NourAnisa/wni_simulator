--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local AvatarPawnService = {}
AvatarPawnService.__index = AvatarPawnService

local PAWN_SCALE = 0.6

export type Service = typeof(setmetatable({} :: {
	pawns: {[number]: Model},
	userIds: {[number]: number},
	animations: {[number]: Tween},
	tweenValues: {[number]: CFrameValue},
}, AvatarPawnService))

local function createSeatBadge(head: BasePart, seat: number): BillboardGui
	local badge = Instance.new("BillboardGui")
	badge.Name = "SeatBadge"
	badge.Size = UDim2.fromOffset(88, 30)
	badge.StudsOffset = Vector3.new(0, 1.6, 0)
	badge.AlwaysOnTop = true
	badge.MaxDistance = 90
	badge.Adornee = head
	badge.Parent = head

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 34, 36)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(245, 236, 207)
	label.TextStrokeTransparency = 0.65
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "P" .. seat
	label.Parent = badge

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize = 9
	textLimit.MaxTextSize = 16
	textLimit.Parent = label

	return badge
end

local function prepareModel(model: Model)
	model:ScaleTo(PAWN_SCALE)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.BreakJointsOnDeath = false
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end

	for _, instance in model:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.Anchored = true
			instance.CanCollide = false
			instance.CanTouch = false
			instance.CanQuery = false
			instance.Massless = true
			instance.CastShadow = true
		end
	end
end

function AvatarPawnService.new(): Service
	local self = setmetatable({}, AvatarPawnService) :: any
	self.pawns = {}
	self.userIds = {}
	self.animations = {}
	self.tweenValues = {}
	return self
end

function AvatarPawnService:destroyPawn(seat: number)
	local tween = self.animations[seat]
	if tween then
		tween:Cancel()
		self.animations[seat] = nil
	end
	local value = self.tweenValues[seat]
	if value then
		value:Destroy()
		self.tweenValues[seat] = nil
	end
	local model = self.pawns[seat]
	if model then
		model:Destroy()
		self.pawns[seat] = nil
	end
	self.userIds[seat] = nil
end

function AvatarPawnService:spawnPawn(seat: number, player: Player, startPosition: CFrame): boolean
	if self.pawns[seat] then
		self:destroyPawn(seat)
	end

	local descriptionSuccess, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	end)
	if not descriptionSuccess or not description then
		warn("[AvatarPawnService] Gagal mengambil HumanoidDescription untuk seat " .. seat)
		return false
	end

	local modelSuccess, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not modelSuccess or not model or not model:IsA("Model") then
		warn("[AvatarPawnService] Gagal membuat rig R15 untuk seat " .. seat)
		return false
	end

	model.Name = "MiniMe_" .. seat
	local rootPart = model:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		model:Destroy()
		warn("[AvatarPawnService] Rig R15 seat " .. seat .. " tidak memiliki HumanoidRootPart")
		return false
	end

	model.PrimaryPart = rootPart
	prepareModel(model)

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		createSeatBadge(head, seat)
	end

	model:PivotTo(startPosition)
	local board = Workspace:WaitForChild("WNIBoard", 5)
	local pawnFolder = board and board:WaitForChild("Pawns", 5)
	if not pawnFolder then
		model:Destroy()
		warn("[AvatarPawnService] Folder WNIBoard.Pawns tidak tersedia")
		return false
	end

	model.Parent = pawnFolder
	self.pawns[seat] = model
	self.userIds[seat] = player.UserId
	return true
end

function AvatarPawnService:getPawn(seat: number): Model?
	return self.pawns[seat]
end

function AvatarPawnService:getUserId(seat: number): number?
	return self.userIds[seat]
end

function AvatarPawnService:tweenToPosition(seat: number, targetCFrame: CFrame, duration: number?)
	local model = self.pawns[seat]
	if not model or not model.Parent then return end

	local oldTween = self.animations[seat]
	if oldTween then oldTween:Cancel() end
	local oldValue = self.tweenValues[seat]
	if oldValue then oldValue:Destroy() end

	local value = Instance.new("CFrameValue")
	value.Name = "PawnTween"
	value.Value = model:GetPivot()
	self.tweenValues[seat] = value

	local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		local current = self.pawns[seat]
		if current == model and current.Parent then
			current:PivotTo(value.Value)
		end
	end)

	local tween = TweenService:Create(
		value,
		TweenInfo.new(duration or 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Value = targetCFrame}
	)
	self.animations[seat] = tween
	tween.Completed:Once(function()
		connection:Disconnect()
		if self.animations[seat] == tween then self.animations[seat] = nil end
		if self.tweenValues[seat] == value then
			self.tweenValues[seat] = nil
			value:Destroy()
		end
	end)
	tween:Play()
end

function AvatarPawnService:setTransparency(seat: number, transparency: number)
	local model = self.pawns[seat]
	if not model then return end

	for _, instance in model:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.Transparency = if instance.Name == "HumanoidRootPart" then 1 else transparency
		elseif instance:IsA("Decal") then
			instance.Transparency = transparency
		end
	end
end

return AvatarPawnService
