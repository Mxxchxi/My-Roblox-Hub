# Steal An Egg — v1.28
PlaceId: 107778070777162. Uses the existing universal Loader.

## Current workflow
Collect -> game redeems egg at the base boundary -> new egg UID appears -> Auto Place equips it and clicks a marked empty slot -> wait for Hatch! -> Auto Hatch approaches and holds the prompt.

Collection, placement and hatching start OFF and run sequentially. Close stops all movement and held input. Alt / RightShift hide or show the UI without stopping enabled automation.

## Auto Home and Collect
Auto Home identifies a uniquely owned plot from owner metadata or the exact account username on PlotSign. A unique delivery candidate is preferred over a SpawnPoint fallback. A spawn fallback is not a verified delivery trigger; observed game redemption can finish a trip before reaching the spawn. No nearest-plot ownership guess is made.

Walk is the default outbound mode; optional Tween is available. Loaded return uses Humanoid:MoveTo, without changing WalkSpeed. When walking stalls, up to two normal jump attempts per waypoint are allowed, with two seconds between attempts. Airborne characters are not repeatedly forced to jump.

FieldEggCarry.IsCarrying is read from an observed server event for the current character. GUI is fallback evidence. Equipped AssetEgg inventory tools are distinguished from field eggs. Successful boundary redemption is inferred from a recent FieldEggRedeemVerdict plus a newly added egg UID with a matching name; field carry disappearing alone is not success. An uncertain pickup pauses.

Manual delivery-point setup remains available in Settings. Automatic selection refreshes each session.

## Placement setup
1. Stop automation and unequip the egg.
2. Open Placement -> Mark empty slot.
3. Click an actual EMPTY slot in your own plot.
4. Repeat for additional empty slots, up to twelve; markers must be at least four studs apart.
5. Enable Auto Place. Enable Auto Hatch if desired.

Slots are marked per session and consumed once. The script does not infer that arbitrary floor parts are empty slots. Only clicked parts descended from the confirmed owned plot are accepted. Clear slots resets all markers; use it only after confirming they are empty.

Auto Place selects a Tool with ItemType=AssetEgg and a nonempty UID from character/Backpack, equips it, and uses native ground movement to approach. It temporarily aims the camera at the marked position, checks for occlusion, and sends a mouse click through VirtualInputManager. Camera state and mouse release are restored on failure. Executor support is not guaranteed; errors appear in the placement report.

A UID disappearing from both character and Backpack after the click, while the same living character remains, is recorded as placement inference. This is not direct verification of a world egg. Unequipping alone does not count. Missing confirmation stops the feature and reserves that slot to avoid repeated clicks.

## Auto Hatch
Only enabled exact Hatch! prompts in the confirmed owned base are targeted automatically. Detached SmartPromptPart prompts are accepted only when uniquely closest to the owned plot center, within 35 studs and at least five studs clearer than the next plot. Auto Hatch walks toward ready eggs within 150 studs, then holds within the smaller of seven studs and MaxActivationDistance. Three attempts per prompt and a four-second cooldown remain.

Prompt disappearance or disabling after input is logged, but is not reported as verified pet creation. Eggs must first be placed and finish growing. Hatching pauses while collecting, placing, carrying field eggs or holding an inventory egg.

## Reports and remaining work
Copy short / Copy all refresh live state. Reports include autoPlace attempts and UID removals, lastAttempt error/inputOK/worldPlacementVerified, carry state, home mapping, movement/jump recovery, inventory deltas, deliveries and bounded game-event history.

Automatic money collection was removed because the game already collects money.
Base/treadmill upgrades and speed training remain unimplemented pending game interaction mapping.

## Validation
From repository root:
~~~sh
python -m unittest discover -s tests -v
luac5.4 -p Games/StealAnEgg_Diagnostics.lua
lua5.4 tests/test_egg_collect.lua
~~~
73 simulated cases plus 4 Loader contracts pass locally, covering placement ownership, duplicate markers, egg selection, UID verification, single clicks, input failure and camera restoration as well as collection/hatch regressions. These are not Potassium/Roblox end-to-end tests. Forest collection has user report evidence; placement and automatic hatching still require in-game validation.
