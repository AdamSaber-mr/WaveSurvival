-- Config: de regelknoppenkast van de game.
-- Alle balansgetallen staan hier bij elkaar, zodat tweaken = één getal aanpassen.

local Config = {}

Config.Zombie = {
	Health = 60,           -- hoeveel schade een zombie aankan (pistool doet straks 30 → 2 schoten)
	WalkSpeed = 8,         -- loopsnelheid (speler = 16, dus zombies zijn langzamer)
	Damage = 15,           -- schade per mep aan de speler
	AttackCooldown = 1.2,  -- seconden pauze tussen twee meppen
	AttackRange = 4.5,     -- studs: zo dichtbij moet een zombie zijn om te kunnen meppen
	DespawnDelay = 2,      -- seconden dat een dode zombie blijft liggen
}

Config.Weapons = {
	Pistol = {
		Damage = 12,         -- zombie heeft 60 health → 5 schoten per kill (startwapen hoort zwak)
		FireCooldown = 0.35, -- seconden tussen twee schoten (ook al klik je sneller)
		Range = 200,         -- studs: verder dan dit vliegt de kogel niet
		MagSize = 12,        -- kogels in het magazijn
		ReserveMax = -1,     -- reserve-ammo (-1 = oneindig: startwapen raakt nooit écht leeg)
		ReloadTime = 1.2,    -- seconden herladen (heel magazijn tegelijk)
	},
	SMG = {
		Damage = 20,
		FireCooldown = 0.12,
		Range = 200,
		Auto = true,         -- muisknop vasthouden = blijven vuren
		Price = 1000,        -- wall-buy prijs
		AmmoPrice = 500,     -- ammo bijkopen bij het bord (CoD: halve wapenprijs)
		MagSize = 30,
		ReserveMax = 120,
		ReloadTime = 1.8,
	},
	Shotgun = {
		Damage = 16,         -- per kogeltje...
		Pellets = 6,         -- ...maar 6 kogeltjes per schot (96 totaal van dichtbij!)
		Spread = 3,          -- graden waaier: verder weg = meer missers
		FireCooldown = 0.9,
		Range = 100,
		Price = 1500,
		AmmoPrice = 750,
		MagSize = 8,
		ReserveMax = 32,
		ShellReload = true,      -- CoD-stijl: schelp voor schelp herladen...
		ShellReloadTime = 0.6,   -- ...elke 0,6s één erbij (en je mag tussendoor vuren!)
	},
	RayGun = {
		Damage = 100,        -- one-shot tot diep in de waves — dé hoofdprijs
		FireCooldown = 0.5,
		Range = 200,
		MagSize = 20,
		ReserveMax = 160,
		ReloadTime = 1.5,
		TracerColor = Color3.fromRGB(80, 255, 120), -- groene laser!
		BoxOnly = true,      -- alleen te winnen uit de Mystery Box
	},
}

Config.MysteryBox = {
	Price = 950,             -- CoD-klassieker
	RollTime = 3.5,          -- seconden roulette (namen flitsen, steeds langzamer)
	TakeTime = 10,           -- seconden om je prijs te pakken, anders... weg geld
	Pool = {
		{ Weapon = "SMG",     Weight = 40 },
		{ Weapon = "Shotgun", Weight = 40 },
		{ Weapon = "RayGun",  Weight = 20 },  -- de jackpot: 1 op 5
	},
}

Config.Economy = {
	StartMoney = 500,   -- startbedrag, net als in CoD Zombies
	HitReward = 10,     -- geld per raak schot
	KillReward = 100,   -- extra geld voor het dodelijke schot
}

Config.Rounds = {
	-- aantal zombies: BaseCount + (ronde - 1) * CountPerRound  → ronde 1: 5, ronde 2: 7, ronde 3: 9...
	BaseCount = 5,
	CountPerRound = 2,
	-- zombie-health: Zombie.Health + (ronde - 1) * HealthPerRound → ronde 1: 60 (2 schoten), ronde 3: 90 (3 schoten)...
	HealthPerRound = 15,
	-- zombie-snelheid: Zombie.WalkSpeed + (ronde - 1) * SpeedPerRound, nooit sneller dan MaxSpeed (speler = 16)
	SpeedPerRound = 0.4,
	MaxSpeed = 14,
	SpawnInterval = 1.2,      -- seconden tussen twee spawns binnen een ronde (CoD-stijl druppelen)
	RestBetweenRounds = 8,    -- adempauze tussen twee rondes
	FirstRoundDelay = 5,      -- seconden na start voordat ronde 1 begint
}

return Config
