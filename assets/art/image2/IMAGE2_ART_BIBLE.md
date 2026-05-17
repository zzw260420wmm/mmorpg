# Image2 Art Bible

This file defines the production target for replacing the current programmer-art assets with high-quality Image2-driven game art.

## Project Identity

- Modern Shanghai urban life simulator.
- Top-down 2D, readable like a life-sim, not a side-scroller or visual novel.
- Grounded slice-of-life anime atmosphere.
- Warm but pressured: cheap rooms, humid streets, late commutes, rent anxiety.
- East Asian indie game sensibility with restrained detail.

## Visual Quality Target

Use high-quality illustrated assets, not simple pixel blocks. The new art should still remain gameplay-safe:

- Clear silhouettes at small size.
- Clean top-down or three-quarter top-down perspective.
- Consistent scale between character, furniture, buildings, and props.
- Moderate detail density; never painterly clutter that hides interaction points.
- Soft tungsten light, muted blue-gray shadows, aged concrete, faded green, rainy asphalt, sparse warm neon.

## Avoid

- Cyberpunk overload.
- Fantasy, sci-fi, post-apocalypse, combat RPG details.
- Gacha character polish or idol-like styling.
- Hyper-saturated mobile-game color.
- Pure black shadows or pure white highlights.
- Text baked into art unless the prompt explicitly asks for it.

## Asset Families

1. Apartment Interior Pack
   - First priority because the demo already has a visual TileMap workflow for the room.
   - Needs floors, walls, door/window pieces, bed, desk, fridge, rent notice, laundry rack, shoe rack, cardboard boxes, small kitchen/sink.

2. Street Props Pack
   - Scooters, vending machines, AC units, utility poles, wet pavement patches, food signs, shopfront fragments.
   - Supports the main walking loop and minimap destinations.

3. Character Pack
   - Player, landlord, shopkeeper, drifter girl, delivery rider, office worker, streamer, metro commuter.
   - Keep them tired, believable, urban, practical.

4. Workplace Pack
   - Office desks, monitors, meeting clutter, delivery station shelves, media-company livestream equipment.

5. UI/HUD Pack
   - Status icons and phone dock icons.
   - Must be legible at 16-32 px display sizes.

## Integration Rule

Do not replace gameplay nodes with decorative images. Keep collisions, interactions, inventory, rent, time, and NPC logic separate from art. Image2 output should become:

- TileSet source textures.
- Sprite/prop atlases.
- Character atlases.
- UI icon atlases.
- Optional scene concept references.

