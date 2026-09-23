--!strict
-- FloatingFX (client): rises a +/- money label from a world position.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local RISE_STUDS = 4.5
local LIFE = 1.4

local GREEN = Color3.fromRGB(120, 235, 140)
local RED = Color3.fromRGB(255, 96, 96)

local function formatAmount(amount: number): string
	local s = tostring(math.floor(math.abs(amount)))
	local reversed = string.reverse(s)
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1.")
	grouped = string.reverse(grouped)
	if string.sub(grouped, 1, 1) == "." then
		grouped = string.sub(grouped, 2)
	end
	return grouped
end

local function worldLabel(): TextLabel
	local holder = Instance.new("Part")
	holder.Name = "FloatingFXAnchor"
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "Float"
	gui.Size = UDim2.fromScale(6, 1.6)
	gui.AlwaysOnTop = true
	gui.Parent = holder
	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0.35
	label.TextStrokeColor3 = Color3.fromRGB(10, 20, 18)
	label.Parent = gui
	return label
end

local FloatingFX = {}

function FloatingFX.showMoney(position: Vector3, amount: number)
	local isNegative = amount < 0
	local label = worldLabel()
	label.TextColor3 = if isNegative then RED else GREEN
	label.Text = (if isNegative then "-" else "+") .. "Rp" .. formatAmount(amount)
	label.TextTransparency = 0
	local part = label.Parent.Parent :: BasePart
	part.Position = position + Vector3.new((math.random() - 0.5) * 1.2, 1.6, (math.random() - 0.5) * 1.2)
	part.Parent = workspace
	local rise = TweenService:Create(part, TweenInfo.new(LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = part.Position + Vector3.new(0, RISE_STUDS, 0)})
	local fade = TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, LIFE - 0.35), {TextTransparency = 1})
	rise:Play()
	fade:Play()
	Debris:AddItem(part, LIFE + 0.2)
end

return FloatingFX
