--!strict
-- TurnHaloFX.luau
-- Visualisasi 3D penunjuk giliran aktif (Active Turn Halo & Bouncing Arrow) di atas pion pemain.
-- Memudahkan pemain dan penonton melihat secara instan siapa yang sedang mendapat giliran bermain.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TurnHaloFX = {}

local haloModel: Model? = nil
local pointerPart: BasePart? = nil
local ringPart: BasePart? = nil
local pointLight: PointLight? = nil
local billboardLabel: TextLabel? = nil
local targetInstance: Instance? = nil

local renderConnection: RBXScriptConnection? = nil
local currentBasePos = Vector3.new(0, 0, 0)
local isGliding = false

local function ensureHalo(): Model
	if haloModel and haloModel:IsDescendantOf(Workspace) then
		return haloModel
	end

	local model = Instance.new("Model")
	model.Name = "ActiveTurnHalo"

	-- 1. Pointer Kristal Mengambang (Diamond / Arrow)
	local pointer = Instance.new("Part")
	pointer.Name = "Pointer"
	pointer.Size = Vector3.new(0.8, 1.2, 0.8)
	pointer.Material = Enum.Material.Neon
	pointer.Color = Color3.fromRGB(255, 215, 60)
	pointer.CanCollide = false
	pointer.CastShadow = false
	pointer.Anchored = true
	pointer.Parent = model
	pointerPart = pointer

	-- Buat bentuk kristal piramida ganda / diamond via SpecialMesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(0.7, 1.3, 0.7)
	mesh.Parent = pointer

	-- 2. Cincin Cahaya Melingkar di bawah kristal
	local ring = Instance.new("Part")
	ring.Name = "HaloRing"
	ring.Size = Vector3.new(2.0, 0.1, 2.0)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 230, 100)
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Anchored = true
	ring.Parent = model
	ringPart = ring

	local ringMesh = Instance.new("SpecialMesh")
	ringMesh.MeshType = Enum.MeshType.Cylinder
	ringMesh.Scale = Vector3.new(1.0, 0.4, 1.0)
	ringMesh.Parent = ring

	-- 3. PointLight Halus
	local light = Instance.new("PointLight")
	light.Name = "GlowLight"
	light.Color = Color3.fromRGB(255, 215, 60)
	light.Range = 9.0
	light.Brightness = 2.2
	light.Parent = pointer
	pointLight = light

	-- 4. BillboardGui Teks Giliran
	local bb = Instance.new("BillboardGui")
	bb.Name = "TurnNotice"
	bb.Size = UDim2.fromScale(7.0, 1.6)
	bb.StudsOffset = Vector3.new(0, 1.4, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = pointer
	bb.Parent = pointer

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "GILIRANMU!"
	label.TextColor3 = Color3.fromRGB(255, 230, 70)
	label.TextSize = 20
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = bb
	billboardLabel = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(25, 20, 10)
	stroke.Thickness = 2.5
	stroke.Parent = label

	model.PrimaryPart = pointer
	model.Parent = Workspace
	haloModel = model

	-- Loop pergerakan rotasi & mengambang (bobbing)
	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(function()
			if not haloModel or not haloModel:IsDescendantOf(Workspace) or not targetInstance then
				return
			end

			local targetPos: Vector3? = nil
			if targetInstance:IsA("BasePart") then
				targetPos = targetInstance.Position
			elseif targetInstance:IsA("Model") then
				local root = targetInstance.PrimaryPart or targetInstance:FindFirstChildWhichIsA("BasePart")
				if root then targetPos = root.Position end
			end

			if targetPos and not isGliding then
				currentBasePos = targetPos + Vector3.new(0, 4.2, 0)
			end

			local t = os.clock()
			local bobY = math.sin(t * 3.5) * 0.28
			local rotAngle = t * 1.8

			if pointerPart and pointerPart:IsDescendantOf(Workspace) then
				pointerPart.CFrame = CFrame.new(currentBasePos + Vector3.new(0, bobY, 0))
					* CFrame.Angles(0, rotAngle, math.sin(t * 2) * 0.15)
			end

			if ringPart and ringPart:IsDescendantOf(Workspace) then
				ringPart.CFrame = CFrame.new(currentBasePos + Vector3.new(0, -0.6 + (bobY * 0.5), 0))
					* CFrame.Angles(0, -rotAngle * 1.2, 0)
			end
		end)
	end

	return model
end

function TurnHaloFX.setTarget(pawn: Instance?, playerName: string, isLocalPlayer: boolean, teamColor: Color3?)
	if not pawn then
		TurnHaloFX.hide()
		return
	end

	local model = ensureHalo()
	targetInstance = pawn

	local themeColor = if isLocalPlayer
		then Color3.fromRGB(60, 235, 255)
		else (teamColor or Color3.fromRGB(255, 215, 60))

	if pointerPart then pointerPart.Color = themeColor end
	if ringPart then ringPart.Color = themeColor end
	if pointLight then pointLight.Color = themeColor end

	if billboardLabel then
		if isLocalPlayer then
			billboardLabel.Text = "⭐ GILIRANMU! ⭐"
			billboardLabel.TextColor3 = Color3.fromRGB(100, 250, 255)
		else
			billboardLabel.Text = "GILIRAN: " .. string.upper(playerName)
			billboardLabel.TextColor3 = themeColor
		end
	end

	-- Gliding tween jika berpindah target
	local newPos: Vector3? = nil
	if pawn:IsA("BasePart") then
		newPos = pawn.Position + Vector3.new(0, 4.2, 0)
	elseif pawn:IsA("Model") then
		local root = pawn.PrimaryPart or pawn:FindFirstChildWhichIsA("BasePart")
		if root then newPos = root.Position + Vector3.new(0, 4.2, 0) end
	end

	if newPos then
		if currentBasePos.Magnitude > 0.1 then
			isGliding = true
			local tweenObj = Instance.new("Vector3Value")
			tweenObj.Value = currentBasePos
			local tw = TweenService:Create(
				tweenObj,
				TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Value = newPos}
			)
			tw:Play()
			local conn: RBXScriptConnection? = nil
			conn = tweenObj.Changed:Connect(function(val)
				currentBasePos = val
			end)
			tw.Completed:Once(function()
				if conn then conn:Disconnect() end
				tweenObj:Destroy()
				isGliding = false
			end)
		else
			currentBasePos = newPos
		end
	end

	model.Parent = Workspace
end

function TurnHaloFX.hide()
	targetInstance = nil
	if haloModel and haloModel:IsDescendantOf(Workspace) then
		haloModel.Parent = nil
	end
end

return TurnHaloFX
