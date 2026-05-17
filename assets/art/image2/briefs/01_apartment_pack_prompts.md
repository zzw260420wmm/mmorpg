# Image2 Brief: Apartment Interior Pack

## Concept Prompt

```text
Use case: stylized-concept
Asset type: game environment concept reference
Primary request: a small modern Shanghai rental apartment interior for a top-down urban life simulator
Scene/backdrop: cramped shared rental room, old building, humid city atmosphere, bed, cheap desk with laptop, small fridge, rent notice, laundry rack, shoe rack, cardboard boxes, narrow door, two windows
Style/medium: high-quality 2D game art, grounded slice-of-life anime, East Asian indie game sensibility
Composition/framing: orthographic top-down / three-quarter top-down room layout, readable gameplay space, no characters
Lighting/mood: soft tungsten indoor light, muted rainy blue-gray shadows outside windows, cozy but financially pressured
Color palette: warm gray, aged concrete, faded green, muted blue, tungsten yellow, dusty red blanket, no oversaturation
Materials/textures: worn tile floor, slightly damp wall, cheap wood furniture, old metal fridge, fabric laundry, cardboard boxes
Constraints: clean navigable floor area, clear interaction objects, no readable text, no logos, no watermark
Avoid: cyberpunk, luxury apartment, fantasy, sci-fi, post-apocalypse, gacha style, hyper-saturated colors
```

Suggested size: `2048x1152`.

## TileSet Prompt

```text
Use case: stylized-concept
Asset type: Godot TileSet atlas
Primary request: apartment interior tileset for a modern Shanghai urban life simulator
Scene/backdrop: old shared rental apartment surfaces
Subject: 8 columns by 4 rows atlas, each cell is a separate 64x64 top-down game tile; include old floor tile, worn floor, wood floor, doorway concrete, bathroom tile, damp floor, old rug, dark corner floor; warm gray wall, peeling wall, damp green wall, baseboard wall, window wall, wooden door wall, cracked wall, night wall; small overlay tiles for shadow, dampness, dirty corner, laundry line, window, door, cardboard notice
Style/medium: high-quality hand-painted 2D game tile art with pixel-game readability, not simple pixel blocks
Composition/framing: exact atlas grid, separated cells, tileable edges, orthographic top-down / front-facing wall pieces
Lighting/mood: soft tungsten interior light with muted blue-gray shadows
Color palette: warm gray, aged concrete, faded green, muted blue, dusty brown, sparse tungsten yellow
Constraints: no text, no labels, no watermark, no large cast shadows crossing tile boundaries, consistent scale
Avoid: photorealism, cyberpunk neon overload, fantasy patterns, luxury materials
```

Required final game layout: `512x256`, 64x64 cells, 8 columns x 4 rows.

## Prop Atlas Prompt

```text
Use case: stylized-concept
Asset type: Godot prop atlas
Primary request: apartment furniture and prop atlas for a modern Shanghai urban life simulator
Scene/backdrop: cheap shared rental apartment
Subject: 4 columns by 3 rows atlas, each cell is a separate 128x128 prop with generous padding: bed with dusty red blanket, cheap desk with laptop and cup, small old fridge, rent notice paper, laundry rack with clothes, shoe rack, cardboard box stack, old window, small sink counter, apartment door, worn floor rug, one blank reserved cell
Style/medium: high-quality 2D game prop art, top-down / three-quarter top-down, grounded slice-of-life anime, readable at small scale
Composition/framing: isolated props in a clean grid, no labels, no merged objects
Lighting/mood: soft tungsten indoor light, subtle ambient occlusion, no harsh cast shadows
Color palette: muted warm gray, faded green, dusty red, old wood brown, tungsten yellow accents
Constraints: transparent-safe plain background, no readable text, no logos, no watermark, consistent scale
Avoid: luxury furniture, cyberpunk, fantasy, sci-fi, clutter that hides silhouettes
```

Required final game layout: `512x384`, 128x128 cells, 4 columns x 3 rows.

