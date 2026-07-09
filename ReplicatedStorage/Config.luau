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

Config.Spawning = {
	TestCount = 5,         -- aantal zombies per testgolf (echte rondes komen in fase 5)
	SpawnInterval = 0.8,   -- seconden tussen twee spawns binnen een golf
	WaveRestDelay = 5,     -- seconden rust nadat een hele golf is uitgeschakeld
}

return Config
