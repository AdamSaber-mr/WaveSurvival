-- ShopService: de winkelbediende bij elke koopmuur.
-- Houd E vast bij een deur → server checkt saldo → beide muurdelen zakken de grond in.
-- Bij een GAME-RESET komen alle gekochte deuren weer netjes terug (uit de backup-kast)
-- en gaan de zones weer op slot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local map = workspace:WaitForChild("Map")
local doorsFolder = map:WaitForChild("Doors")

-- backup-kast: van elke deur een verse kopie bewaren vóór er ooit iets opengaat
local backups = Instance.new("Folder")
backups.Name = "DoorBackups"
backups.Parent = ServerStorage
for _, doorModel in ipairs(doorsFolder:GetChildren()) do
	doorModel:Clone().Parent = backups
end

local function showMessage(prompt, message)
	local originalText = prompt.ActionText
	prompt.ActionText = message
	task.delay(1.5, function()
		if prompt.Parent then
			prompt.ActionText = originalText
		end
	end)
end

local function openDoor(doorModel)
	doorModel:SetAttribute("Opened", true)

	local targetZone = doorModel:GetAttribute("TargetZone")
	if targetZone then
		map:SetAttribute("Unlocked_" .. targetZone, true)
	end

	for _, child in ipairs(doorModel:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^Barrier") then
			local prompt = child:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt:Destroy()
			end
			local sink = TweenService:Create(child, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = child.CFrame * CFrame.new(0, -16, 0),
			})
			sink:Play()
			task.delay(1.3, function()
				child:Destroy()
			end)
		end
	end

	print(("[Winkel] %s geopend → zone %s ontgrendeld"):format(doorModel.Name, tostring(targetZone)))
end

local function attemptPurchase(player, doorModel, prompt)
	if doorModel:GetAttribute("Opened") then
		return
	end
	local cost = doorModel:GetAttribute("Cost") or 0
	if EconomyService.spend(player, cost) then
		openDoor(doorModel)
	else
		showMessage(prompt, "Not enough money!")
	end
end

-- prompts van een deur aansluiten (bij start én na herstel uit de backup-kast)
local function wireDoor(doorModel)
	for _, descendant in ipairs(doorModel:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function(player)
				attemptPurchase(player, doorModel, descendant)
			end)
		end
	end
end

for _, doorModel in ipairs(doorsFolder:GetChildren()) do
	wireDoor(doorModel)
end

-- GAME-RESET: alle deuren terugzetten en de zones weer op slot doen
task.spawn(function()
	local resetEvent = ServerStorage:WaitForChild("GameReset")
	resetEvent.Event:Connect(function()
		for _, backup in ipairs(backups:GetChildren()) do
			local current = doorsFolder:FindFirstChild(backup.Name)
			if current then
				current:Destroy() -- restjes (bak, struik) opruimen
			end
			local fresh = backup:Clone()
			fresh.Parent = doorsFolder
			wireDoor(fresh)

			local targetZone = fresh:GetAttribute("TargetZone")
			if targetZone then
				map:SetAttribute("Unlocked_" .. targetZone, nil)
			end
		end
		print("[Winkel] Reset — alle deuren staan weer dicht")
	end)
end)
