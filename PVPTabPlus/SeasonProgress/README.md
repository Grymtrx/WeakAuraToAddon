# Season Progress

Displays a simple progress bar that visualizes how much of the current PvP season has elapsed. Converted from a WeakAura concept so players still have a lightweight reference even if the WA API changes or is removed.

## Features
- Compact bar anchored next to the Conquest “Join Battle” button (only visible when that panel is open).
- Automatically recalculates once per second and persists data between sessions.
- Season window and title can be updated via slash commands (saved in SavedVariables).

## Commands
- `/spd MM-DD-YYYY MM-DD-YYYY` – sets the season start/end dates.
- `/spn My Custom Title` – sets the label shown above the bar.

## Installation
1. Copy `SeasonProgress` into `World of Warcraft/_retail_/Interface/AddOns/`.
2. Restart the game or `/reload`.
3. Use the slash commands above to set your desired season window.

## Credits
- Original WeakAura concept by the Season Progress WA author (noted on Wago).
- Addon implementation by Grymtrx / Codex.
