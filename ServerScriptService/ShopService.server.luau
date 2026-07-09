-- ShopService: de winkelbediende bij elke koopmuur.
-- Houd je E ingedrukt bij een deur, dan checkt de server je saldo (kassaboek),
-- schrijft het bedrag af en laat beide muurdelen de grond in zakken.
-- De zone wordt daarna "ontgrendeld" — daar mogen dan ook zombies spawnen.

local TweenService = game:GetService("TweenService")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local map = workspace:WaitForChild("Map")
local doorsFolder = map:WaitForChild("Doors")

local function openDoor(doorModel)
	doorModel:SetAttribute("Opened", true)

	-- zone van het slot: ZombieService kijkt naar deze sticker op de Map
	local targetZone = doorModel:GetAttribute("TargetZone")
	if targetZone then
		map:SetAttribute("Unlocked_" .. targetZone, true)
	end

	-- beide muurdelen (en hun neon-randjes) zakken de grond in en verdwijnen
	for _, child in ipairs(doorModel:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^Barrier") then
			local prompt = child:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt:Destroy() -- niemand kan dubbel kopen
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
		-- korte feedback op het knopje zelf
		local originalText = prompt.ActionText
		prompt.ActionText = "Not enough money!"
		task.delay(1.5, function()
			if prompt.Parent then
				prompt.ActionText = originalText
			end
		end)
	end
end

-- alle koopmuren aansluiten (nu 1: Main Street; toekomstige deuren doen automatisch mee)
for _, doorModel in ipairs(doorsFolder:GetChildren()) do
	for _, descendant in ipairs(doorModel:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function(player)
				attemptPurchase(player, doorModel, descendant)
			end)
		end
	end
end
