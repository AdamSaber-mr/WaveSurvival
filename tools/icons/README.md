# HUD-iconen (zelf getekend, geen emojis)

Getekend op 2026-07-16 met de Pillow-scripts in deze map (1024px, verkleind
naar 256px voor scherpe randen). Stijl: retro-kermis — creme/goud/bruin/rood
met dikke donkere outline (62, 34, 20). Geüpload naar Adams Roblox-account.

| Bestand | Gebruik | Asset-ID |
| --- | --- | --- |
| icon_ticket.png | HUD tickets-teller (HUDClient `ticketIcon`) | rbxassetid://82095401815766 |
| icon_maddash.png | Fate-kaart MAD DASH (Config.Cards.Icon) | rbxassetid://129576819690037 |
| icon_powershot.png | Fate-kaart POWER SHOT (Config.Cards.Icon) | rbxassetid://86446365245304 |
| icon_ironhide.png | Fate-kaart IRON HIDE (Config.Cards.Icon) | rbxassetid://89240286861643 |
| icon_juggernog.png | Perk-tegel Juggernog (HUDClient `PERK_ICONS`) | rbxassetid://121265421190966 |
| icon_speedcola.png | Perk-tegel Speed Cola (HUDClient `PERK_ICONS`) | rbxassetid://133332284525232 |
| icon_staminup.png | Perk-tegel Stamin-Up (HUDClient `PERK_ICONS`) | rbxassetid://70428971793765 |

Opnieuw genereren: `python3 draw_icons.py` en `python3 draw_perk_icons.py`
(vereist Pillow). Opnieuw uploaden kan via de Studio MCP `upload_image`
(bestanden via een lokale `python3 -m http.server` aanbieden) — daarna de
nieuwe asset-ID's bijwerken in `ReplicatedStorage/Config.luau` (kaarten) en
`StarterPlayerScripts/HUDClient.client.luau` (ticket + perks).
