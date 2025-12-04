# Fix TotemFrame
---

This addon packages the original WeakAura fix by **Chrisliebär** as a load-on-startup solution so that  
`/click TotemFrameTotem# RightButton 1` macros continue to work after the Dragonflight UI overhaul.  
It simply recreates the hidden secure buttons Blizzard removed, mirroring the original WeakAura's behavior.

**Primary Use Case:**  
Restoration Druid PvP macros — particularly **Shadowmeld + Cancel Treants**.

![IMG](https://i.imgur.com/pIx50zQ.png)

**Without this functionality, you cannot cancel Treants, causing you to remain in combat when Shadowmelding to drink.**

---

## Chrisliebär’s Original Description

The Dragonflight UI revamp has changed how the TotemFrame is working now. This means that macros such as /click TotemFrameTotem1 RightButton 1 will no longer work, since these frames no longer exist.

This WeakAura recreates these frames, so existing macros will continue to work, since there is currently no other way that I'm aware of, to cancel "Totems" with macros. I've seen a few macros that recreate the needed UI frames on demand, but these will fail to work in combat, which is the reason this WeakAura will create them on UI load.

After you have imported this WeakAura, you can continue using macros such as these, to get rid of totems and other things. Keep in mind that the last 1 is actually required now.

```
/click TotemFrameTotem1 RightButton 1
/click TotemFrameTotem2 RightButton 1
/click TotemFrameTotem3 RightButton 1
/click TotemFrameTotem4 RightButton 1
```
Sadly, there is no way to reference individual totems, as Blizzard removed this feature a long time ago.

## Not Working? (Quick Fix)

If the macro above doesn't work for you, then remove the 1 after 'RightButton'.  Providing 0(or nothing) simulates a KeyUp trigger while 1 simulates a KeyDown trigger event.
```
/click TotemFrameTotem1 RightButton
/click TotemFrameTotem2 RightButton
/click TotemFrameTotem3 RightButton
/click TotemFrameTotem4 RightButton
```
## Credit
This solution was originally created by **Chrisliebär** as a WeakAura.  
All I've done is convert it into a standalone addon, especially important now that WeakAuras will no longer be supported in the *Midnight* expansion.

Original WeakAura: https://wago.io/VCKfcshwE/1