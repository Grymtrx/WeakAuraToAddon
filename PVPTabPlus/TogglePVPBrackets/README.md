# TogglePVPBrackets

Simple QoL addon that hides the Rated Battleground and BG Blitz sections on the Conquest panel when the “Hide BGs” checkbox is enabled, letting you focus on Shuffle / 2v2 / 3v3 brackets.

## Features
- Adds a persistent “Hide BGs” toggle anchored next to the Join Battle button.
- When enabled, BG brackets are hidden and the remaining rows collapse upward, so Shuffle → 2s → 3s sit together.
- One click restores the default Conquest layout.

## Installation
1. Copy the `TogglePVPBrackets` folder to `World of Warcraft/_retail_/Interface/AddOns/`.
2. Restart the game or `/reload`.
3. Open the Conquest panel and use the checkbox beside the Join button.

## Notes
- Blizzard sometimes reorders PvP UI elements between patches; if the checkbox drifts, reopen an issue or adjust the anchor logic in `core.lua`.
- No SavedVariables — the state resets to “Hide BGs” on by default each login.
