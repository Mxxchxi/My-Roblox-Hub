# Steal An Egg — v1.16
PlaceId: 107778070777162. Uses the existing universal Loader.

## Setup
1. Run the Loader in Potassium after the map loads.
2. Stand on your own base's actual egg delivery trigger.
3. Open Settings and press **Set delivery point here**, while Collect is stopped.
4. Unequip inventory eggs. Enable Collect.
5. Use Alt (press and release) or RightShift to hide/show the hub. Hiding keeps automation running; Close stops it.

The delivery point lasts for this script session. It is not guessed from the nearest plot. On a new server or after reloading, set it again.

## Collection cycle
The exact observed CarryAreaEgg / Steal / Egg prompt is tracked. Targets may have a disabled distance-dependent prompt while approaching, but input requires an enabled prompt and a living character inside the smaller of 8 studs and MaxActivationDistance.

The nearest directly reachable target within 250 studs on approximately the same level is approached by Tween. Movement speed is clamped to 8–24 studs/s. Solid obstructions are respected. This is straight-line movement, not full pathfinding.

After input, the script waits up to 3 seconds for carry state or a new inventory egg UID. One unconfirmed input pauses the loop. Names alone are not treated as unique eggs.

When the field carry UI is active, Collect returns to the explicitly configured delivery point within 600 studs. Return stops on cancellation, death, respawn, an obstruction, or field carry disappearing before arrival.

At home the script waits up to 5 seconds for the game to accept the egg. A delivery is inferred only after field carry clears continuously for at least 1 second and a new AssetEgg UID appears compared with the pre-pickup inventory. The state then returns to SEEKING. Carry disappearing without a new UID does not count as delivery.

No placement Remote is invoked. If the game requires a manual placement prompt instead of a delivery trigger, the loop pauses and reports that the game did not accept the egg. The current dataset does not establish that prompt or Remote argument contract.

## Carry detection
- DropHeldEgg.Button with all GUI ancestors visible/enabled: field-carry UI evidence.
- Equipped Tool with ItemType=AssetEgg: an inventory egg is equipped; collection waits until it is unequipped.
- Explicit user marker: a manual stop signal, not a verified game result.

A reported Raccoon Egg Tool proved the old UI-only detector could miss inventory eggs. These sources are now separated in carryState. Equipped inventory eggs alone do not establish field pickup success.

UID snapshots include the character and Backpack. Moving an existing UID between those containers is not a new acquisition. Missing UIDs or truncated inventories suppress acquisition claims. A new UID observed after input is temporal evidence; it does not by itself prove which game action caused the addition.

## Hatch and other systems
Auto Hatch remains an opt-in nearby Hatch! prompt test, default OFF, max 7 studs, 4-second cooldown and 3 attempts per prompt per toggle. It does not verify the resulting pet.

| Feature | Current implementation |
|---|---|
| Neon UI, Alt/RightShift, drag/minimize | Implemented; requires client verification |
| Collect + Tween | Game reports show input and field-carry UI evidence |
| Configured return + delivery loop | Implemented; simulated tests only |
| Hatch | Input test; actual hatch result unverified |
| Collect money | Not implemented; interaction mapping missing |
| Upgrade base/treadmill | Not implemented; UI/Remote contracts missing |
| Speed training | Not implemented; interaction mapping missing |

Remote names such as AskBaseTierRaise, CoinsGathered and SpeedGained do not establish callable client commands. This version does not send guessed arguments or label unavailable features as working.

## Reports
Copy short / Copy all / Save file refresh live state without another Scan. Reports include:
- autoCollect.phase, lastInput, lastMovement.stopReason and endDistance
- deliveryPointSet, lastReturn, deliveriesObserved
- carryState and fresh carryEvidence
- inventoryBeforeCount / inventoryAfterCount / inventoryAdded
- autoHatch live state

If clipboard readback cannot be verified, the full text is selected for Ctrl+C. Clipboard transfer between PCs is separate. Generic report scans are bounded and may omit GUI/world data; live carry and inventory checks do not rely on that scan.

## Validation
Run from repository root:
~~~sh
python -m unittest discover -s tests -v
luac5.4 -p Games/StealAnEgg_Diagnostics.lua
lua5.4 tests/test_egg_collect.lua
~~~
32 simulated Auto Collect cases and 4 Loader contract tests pass locally. Tests cover carry state, inventory deltas, cancellation, disabled prompts, range limits, return, obstacles, false delivery prevention and no-result pauses. They are not a Potassium or Roblox server test.
