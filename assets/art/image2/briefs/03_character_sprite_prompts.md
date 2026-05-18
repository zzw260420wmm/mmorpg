# Character Sprite Prompt Brief

Purpose: generate or refine game-ready character sprites for the Shanghai urban life simulator while preserving the existing four-direction atlas layout.

## Global Character Prompt

young Chinese urban character, top-down 2D indie game sprite, 2D hand-drawn cartoon style, not pixel art, simple clean silhouette, stylized believable proportions, minimal facial details, clean line art, simple cel shading, modern casual clothing, cozy urban slice-of-life atmosphere, grounded modern Shanghai life, slightly tired but emotionally readable, muted warm gray palette, faded green, muted blue, tungsten yellow accents, rainy asphalt tones, Stardew-like gameplay readability, game-ready character sheet, front side back views, walking animation poses, transparent background, consistent art direction

Avoid: cyberpunk overload, sci-fi city, fantasy armor, idol fashion, gacha character styling, hyper-saturated mobile-game colors, over-rendered realism, western comic style, pure black shadows, pure white highlights.

## Atlas Layout

- Cell size: 64x64 source cells, displayed smaller in-game for readable top-down proportions.
- Columns: player_grad, landlord, shopkeeper, drifter_girl, delivery_rider, office_worker, streamer, metro_commuter.
- Rows: down idle, down walk, up idle, up walk, left idle, left walk, right idle, right walk.
- Keep each figure centered, feet near the bottom of the cell, with generous transparent padding.
- Character art should be smooth hand-drawn/cel-shaded, while the map may remain tile-based.

## Character Notes

- player_grad: recent graduate in muted blue jacket, cheap backpack or tote detail, sneakers, slightly anxious but capable.
- landlord: older local landlord, warm brown shirt, practical posture, key pouch or rent-book detail.
- shopkeeper: convenience-store owner, faded green work shirt, small receipt or food item detail.
- drifter_girl: young migrant worker, muted red casual jacket, tote bag, tired but warm expression.
- delivery_rider: yellow delivery uniform, helmet, delivery box, strong silhouette from above.
- office_worker: white-collar colleague, gray office wear, tie or lanyard, laptop bag detail.
- streamer: media-company worker, muted pink/red styling, small headset/light detail, not idol-like.
- metro_commuter: ordinary commuter, gray jacket, green tote or backpack, anonymous crowd feeling.

## Production Constraints

- Prioritize readability when displayed around 27px tall in-game.
- Use clear profession silhouettes before adding decorative detail.
- Keep colors restrained and compatible with the existing Shanghai street, apartment, office, delivery station, and media company palettes.
- Do not add text inside the sprite cells.

## Environment Match

- Characters and buildings should now share a non-pixel, hand-drawn cartoon language.
- Buildings may stay grid-aligned for collision and navigation, but their visible rendering should use rounded forms, clean line art, simple cel shading, and grounded Shanghai urban details.
