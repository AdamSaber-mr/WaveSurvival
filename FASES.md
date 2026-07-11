# Spaceland Zombies — Faseplan & Voortgang

Een zombie wave survival game in Roblox, geïnspireerd op CoD Black Ops Zombies, met als map-thema **Spaceland** (het retro ruimte-pretpark uit Infinite Warfare Zombies). Gebouwd samen met Claude: plan eerst, dan fase voor fase bouwen en testen.

## Vaste afspraken

- **Multiplayer-proof vanaf dag 1**, solo getest
- **Functionaliteit eerst, visueel later** — placeholder-blokken tot de polish-fase
- **Gedempt kleurenpalet**: donkergrijs/blauwgrijs, spaarzaam paars/blauw neon
- Alle balansgetallen komen in `ReplicatedStorage/Config.luau`
- Geld & schade beslist altijd de server
- Per fase: bouwen → Claude checkt via MCP → Adam playtest → feedback → pas committen als Adam "fase klaar" zegt

## Fases

| # | Fase | Status |
|---|------|--------|
| 00 | GitHub-repo opzetten | ✅ Klaar |
| 0 | Script Sync fixen + place-bestand verhuizen | ✅ Klaar |
| 1 | Spawn-plein (Spaceland): plein, winkels, planters, gesplitste koopmuur + koopcirkel | ✅ Klaar |
| 2 | Zombies: spawnen op markers, achtervolgen, melee-aanval | ✅ Klaar |
| 3 | Startpistool: schieten (raycast), zombies doden | ✅ Klaar |
| 4 | Geld: +punten per hit/kill + geld-HUD | ✅ Klaar |
| 5 | Rondes: golven die zwaarder worden + ronde-HUD | ✅ Klaar |
| 6 | Deuren kopen: Main Street-muur opent (beide delen) via geld | ✅ Klaar |
| 7 | Wall-buys: wapens & ammo aan de muur + ammo/reload-systeem | ✅ Klaar |
| 8 | Mystery Box (roulette, take-window, Ray Gun) | ✅ Klaar |
| 9 | Perks (health, herlaad, snelheid) | ⏭️ Volgende |
| 10 | Dood, laatste overlevende, herstart | ⬜ |
| 11 | Polish: modellen, geluid, lighting, sfeer | ⬜ |

## De map tot nu toe (Fase 1)

- Vierkant spawn-plein 90×110, spawn achteraan onder de ★ SPACELAND ★-poortboog
- 6 winkelkraampjes: Astro Snacks, Moon Burger, Star Souvenirs (west) / Comet Candy, Laser Lanes, Orbit Outfits (oost)
- Middenlijn met 3 balken achter elkaar: struik-bak → park-map-scherm → struik-bak tussen de koopmuur
- Koopmuur naar Main Street in 2 delen (`Door_MainStreet`, $750) met CoD-stijl koopcirkel (ProximityPrompt) en "THIS AREA IS TEMPORARILY CLOSED"
- 8 onzichtbare zombie-spawnmarkers klaar voor Fase 2

> De map leeft in het Roblox place-bestand (`Wavestudio.rbxl`), niet in de script-mappen. Scripts komen vanaf Fase 2 in `ServerScriptService/`, `ReplicatedStorage/` en `StarterPlayerScripts/` via Script Sync.

## De zombies (Fase 2)

- 4 spawn-plekken (door Adam aangewezen): 2 achterhoeken naast de poort + ín Moon Burger + ín Orbit Outfits
- `ReplicatedStorage/Config.luau`: de regelknoppenkast (zombie: health 60, speed 8, damage 15, cooldown 1.2s; testgolf: 5)
- `ServerScriptService/ZombieFactory.luau`: bouwt de placeholder-zombie (groen, armen vooruit, rode neon-ogen)
- `ServerScriptService/ZombieAI.server.luau`: golf-loop → spawnen → dichtstbijzijnde levende speler achtervolgen → meppen met cooldown; springt als hij vastzit (toonbank!)
