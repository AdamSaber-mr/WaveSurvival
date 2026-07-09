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
		Damage = 30,        -- zombie heeft 60 health → precies 2 schoten per kill (CoD-stijl)
		FireCooldown = 0.35, -- seconden tussen twee schoten (ook al klik je sneller)
		Range = 200,         -- studs: verder dan dit vliegt de kogel niet
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
