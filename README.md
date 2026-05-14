# Shanghai Drift Life Demo

Godot 4 2D pixel-art life simulation prototype set in modern Shanghai.

## Controls

- WASD: Move
- E: Interact / advance dialogue / leave shop
- 1-9: Buy items while in a shop
- Esc: Close shop

## Current Demo Scope

- Top-down free movement with camera follow
- Programmatic pixel-style TileMap map expanded into a compressed real-Shanghai layout
- Small Shanghai urban village area with rental room, convenience store, metro entrance, and restaurant
- Real-world Shanghai anchors: Huangpu River, Suzhou Creek, Puxi/Pudong split, People's Square, the Bund, Lujiazui, and Xujiahui
- More real Shanghai daily-life points: wet market, community clinic, talent apartment, and rental agency
- Time system: morning, afternoon, evening, late night
- HUD with date, time segment, money, and energy
- Seven NPCs with fixed routes, dialogue, time-segment behavior, and readable job identities
- Interaction system for dialogue, shop, and sleeping
- Sleeping advances to the next day and restores energy
- Apartment interior with bed, fridge, desk, and exit door
- Walkable metro station interior with ticket machines, route map, fare gates, and exit
- Metro commute/work loop: enter station, pay fare at the gate, arrive at the office, earn wage, return in the evening
- Convenience store and restaurant food choices that trade money for energy
- Wet market food choices as cheaper daily recovery options
- Community clinic visit that costs money but restores energy and reduces stress
- Work performance based on current energy and weather, affecting wage and fatigue
- Weather cycle with rain visuals, rainy tinting, and commute penalties
- Lightweight NPC relationship growth from daily conversations
- Expanded office-side street with office entrance and coffee stand
- Stress system affected by work, rain, late nights, food, sleep, and conversation
- Office interior with selectable white-collar jobs: operations, developer, and sales
- Rent cycle with apartment rent payment, overdue stress, and landlord reminders
- Dynamic daily goals panel that points players toward rent, work, food, stress relief, and sleep
- Delivery station job loop: accept an order, pick up food, deliver to the rental building, and earn money
- Media company interior with a streamer job that trades lower base pay for high pressure and bonus potential
- Reusable pixel-art atlas pipeline for shared tiles, props, characters, and HUD icons
- Player and NPC drawing now reuses the shared four-direction character atlas
- Ambient profession NPCs now include a delivery rider, streamer, white-collar worker, and metro commuter
- Apartment, office, and media-company interiors now reuse shared tile-atlas flooring and wall textures

## Project Structure

- `scenes/world/main.tscn`: project entry scene
- `scenes/player/player.tscn`: player scene
- `scenes/npc/npc.tscn`: reusable NPC scene
- `scenes/ui/hud.tscn`: HUD scene
- `scripts/core/game.gd`: game assembly and high-level flow
- `scripts/core/time_manager.gd`: date, time segment, money, and energy state
- `scripts/core/art_assets.gd`: shared atlas regions and drawing helpers
- `scripts/world/city_map.gd`: map, TileMap, collision, buildings, interactables
- `scripts/world/apartment_interior.gd`: walkable rental-room interior
- `scripts/world/metro_station_interior.gd`: walkable metro station and commute gate
- `scripts/world/media_company_interior.gd`: walkable livestream/media-company interior
- `scripts/world/world_interactable.gd`: interactable hotspots
- `scripts/entities/player.gd`: movement, facing, camera, interaction scan
- `scripts/entities/npc.gd`: NPC routes, dialogue, and visual drawing
- `scripts/ui/hud.gd`: status UI, prompt, dialogue, shop UI
- `scripts/tools/generate_pixel_art_assets.ps1`: regenerates project-local pixel-art atlases
- `assets/art/ART_ASSET_GUIDE.md`: atlas usage and art-direction notes

## Notes

The first version intentionally uses generated placeholder pixel art, so the game is playable without external art assets. Replace the generated drawing code with sprites and real tiles later without changing the system boundaries.

## Suggested Test Route

1. Walk to the rental-room door and press E to enter the apartment.
2. Use the fridge for a small energy recovery, then leave through the door.
3. Explore the expanded Shanghai layout: People's Square, the Bund, Lujiazui, Xujiahui, Huangpu River, and Suzhou Creek are compressed into the playable map.
4. Walk to the metro entrance and press E to enter the station.
5. Inside the metro station, inspect the ticket machine or route map, then press E at the gate before evening to commute to the office.
6. Inside the office, choose operations, developer, or sales work at a workstation.
7. Walk east to the office-side street and inspect the office entrance directly if you want to enter without using metro.
8. Buy food or coffee to trade money for energy and stress changes.
9. Talk to each NPC once per day to raise relationship and reduce stress.
10. Check the apartment rent notice and pay rent when it is due.
11. Visit the wet market for cheaper food, or the community clinic when stress and fatigue are high.
12. Check the talent apartment and rental agency to understand future housing pressure.
13. Walk to the delivery station, accept a food-delivery order, pick up food at the restaurant, and deliver it to the rental building.
14. Enter the media company and start the streamer job from the livestream set.
15. Return to the apartment bed and sleep to advance to the next day and change weather.
