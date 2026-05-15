---
name: encoding-guard
description: Project-local source encoding guard for this Godot life-sim project. Use whenever editing GDScript, scenes, UI text, dialogue, shop data, NPC data, localization, or fixing mojibake/garbled characters to keep files UTF-8 safe and prevent corrupted strings.
---

# Encoding Guard

Treat source text as UTF-8 and protect it deliberately.

## Workflow

- Prefer ASCII strings in code until a verified localization pass is requested.
- Do not copy existing mojibake into new or edited strings. Replace corrupted user-facing text with clean placeholder copy.
- Use `apply_patch` for normal edits. If bulk rewriting is unavoidable, write files explicitly as UTF-8 without BOM.
- Avoid PowerShell `Set-Content` without an explicit UTF-8 encoding.
- Keep large user-facing text in a localization/resource file rather than inline GDScript when the text will be Chinese-heavy.

## Validation

- After editing `.gd`, `.tscn`, `.tres`, `.cfg`, or `.md` files, scan touched files for odd unescaped quote counts.
- Scan touched source files for replacement characters and common UTF-8/GBK mojibake clusters. Do not paste suspicious glyphs into new source just to document them.
- If a file contains unrelated mojibake, do not normalize broad content during unrelated feature work. Fix syntax-breaking or touched text first, then call out the remaining cleanup.
