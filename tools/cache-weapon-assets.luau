-- BRONCACHE voor de wapens — normaal hoef je dit NOOIT te draaien.
--
-- LET OP: de twee bronmodellen zijn NIET MEER TE DOWNLOADEN. Zowel de
-- commandobalk als de plugin krijgen sinds 2026-07-21 "User is not authorized
-- to access Asset" op InsertService:LoadAsset — de makers hebben ze op privé
-- gezet of verwijderd. De enige overgebleven kopie staat nu in de place zelf:
--
--     ServerStorage.SourceAssets.Asset_5722821580   (QZ-wapenpakket)
--     ServerStorage.SourceAssets.Asset_434887296    (Ray Gun)
--
-- ==> VERWIJDER DIE MAP NOOIT. Zonder die map kan tools/build-weapons.luau de
--     wapens niet meer bouwen en zijn ze definitief weg.
--
-- Hoe de cache toen wél gevuld is: niet met InsertService, maar met Studio's
-- eigen "asset invoegen" (de Toolbox / de MCP-plugin), die een andere route
-- naar de Creator Store gebruikt en de modellen nog wél mocht ophalen. Zoek in
-- de Toolbox op de asset-ID, sleep het model in ServerStorage en hernoem het
-- naar "Asset_<id>".
--
-- Dit script is alleen nog een noodgreep voor als LoadAsset ooit weer werkt,
-- of als je een ANDER bronmodel wilt gaan gebruiken (pas dan ASSETS aan).

local InsertService = game:GetService("InsertService")
local ss = game:GetService("ServerStorage")

local ASSETS = {
	5722821580, -- QUARANTINE-Z GUN WEAPON AMMO PACK LOW POLY (M1911, UMP45, Shotgun)
	434887296,  -- Ray Gun (CoD-replica)
}

local folder = ss:FindFirstChild("SourceAssets")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "SourceAssets"
	folder.Parent = ss
end

for _, assetId in ipairs(ASSETS) do
	local ok, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		-- bestaande cache NIET slopen als het downloaden mislukt
		warn("[SourceAssets] " .. assetId .. " kon niet geladen worden (" .. tostring(result)
			.. ") — bestaande cache blijft staan.")
	else
		for _, d in ipairs(result:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true -- anders valt het pack uit elkaar op de baseplate
			end
		end
		local old = folder:FindFirstChild("Asset_" .. assetId)
		if old then old:Destroy() end
		result.Name = "Asset_" .. assetId
		result.Parent = folder
		print("[SourceAssets] gecachet: " .. assetId .. " (" .. #result:GetDescendants() .. " onderdelen)")
	end
end
