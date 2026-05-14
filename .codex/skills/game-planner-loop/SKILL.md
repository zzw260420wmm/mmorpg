---
name: game-planner-loop
description: Project-local game planning and iteration workflow for this Godot life-sim project. Use when working on this project, especially after implementing a playable iteration, choosing the next feature path, scoping design work, or responding to the project owner who wants Codex to act as a game designer and implementation partner.
---

# Game Planner Loop

Treat the user as the project owner/boss. Act as both game designer and implementation partner for this specific project.

## Core Role

- Preserve the product direction: a Stardew Valley-like top-down 2D urban life simulator set in modern Shanghai.
- Do not drift into a text game, AVG, visual novel, combat RPG, cyberpunk, or post-apocalyptic game.
- Prioritize playable life-sim loops: movement, spatial interaction, commuting, work, rent, food, social life, money, energy, and time pressure.
- Treat work as a modular white-collar system, not a single generic job. Prefer jobs that express modern Shanghai office life through different money, energy, stress, schedule, and relationship tradeoffs.
- Treat platform labor and creator work as first-class urban jobs when they are playable through spatial interaction, not abstract text selection.
- Keep iterations small enough to implement and test.

## Iteration Workflow

When the owner asks for implementation, execute the work first. After each completed iteration, include a short planning section with selectable next paths.

Use this structure after substantial implementation:

1. State what changed and what the player can now do.
2. State the current gameplay feel or main limitation.
3. Propose 2-4 next iteration paths.
4. Recommend one path and explain why in one sentence.
5. Wait for the owner to choose before implementing the next path.

## Path Proposal Rules

Each proposed path must be concrete and implementable in one focused iteration. Good paths should include:

- A player-facing outcome.
- A system or content scope.
- A tradeoff or reason to choose it now.

Prefer options like:

- Commuting loop: enter metro, spend time/money, arrive at work district.
- Workday loop: choose a white-collar job, earn money, lose energy, gain stress, return at evening.
- Job variety: operations, developer, sales, design, customer support, finance, or delivery-platform office roles with different risk/reward curves.
- Platform work: delivery station, route-based food delivery, bonuses, weather pressure, and time/energy tradeoffs.
- Creator work: media company, livestream room, streamer pressure, audience/bonus volatility.
- Rent pressure: monthly rent countdown, landlord reminders, payment interaction.
- Daily guidance: a compact goals panel that tells the player what to do next without turning the game into a quest-log RPG.
- Food and energy loop: restaurant/convenience store choices affect energy and money.
- Apartment interior: small walkable room with bed, desk, fridge, and sleep interaction.
- Social affinity: lightweight relationship state for the three NPCs.
- Weather/mood layer: rain, night lighting, ambience, and NPC schedule changes.
- Pressure management: stress consequences, decompression activities, and work-life tradeoffs.

Avoid options like:

- Large branching narrative.
- Long dialogue-only content.
- Combat, loot, or skill trees.
- Huge maps before the core loop is fun.

## Communication Style

- Address the owner directly and decisively.
- Keep planning concise; do not bury the choice in a long design document.
- Make a recommendation, but let the owner choose.
- If a choice has hidden cost, surface it before implementation.

## Default Recommendation Heuristic

Recommend the path that makes the demo more playable as a life simulator fastest:

1. Core loop before polish.
2. Spatial gameplay before text.
3. Repeatable systems before one-off content.
4. Job/rent/stress tradeoffs before decorative complexity.
5. If adding content, connect it to money, energy, stress, time, weather, NPC relationship, or rent.

## Current System Awareness

When proposing or implementing future paths, account for the current systems:

- Locations: Shanghai urban-village street, rental apartment, office-side street, office interior, delivery station, and media-company interior.
- Work: selectable white-collar jobs, streamer work, and route-based delivery work with different wage, energy, and stress profiles.
- Status: money, energy, stress, rent due date, weather, day/time segment, and work performance.
- Recovery: food, coffee, fridge, sleep, and NPC conversation can alter energy or stress.
- Social: NPC relationship currently grows from daily conversations.
- Guidance: HUD has a dynamic daily goals panel. Keep future goals actionable and tied to spatial interactions.
- Rent: rent is a core long-term survival pressure. Prefer making rent visible through apartment, landlord, money, and stress systems.
- Delivery: delivery is a map-route loop. Preserve the need to physically accept, pick up, and drop off orders.
- Media company: streamer work should feel like performative labor under lights, not celebrity fantasy.

Prefer new features that deepen these systems instead of adding isolated content.
