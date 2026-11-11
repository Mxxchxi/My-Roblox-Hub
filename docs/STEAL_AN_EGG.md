# Steal An Egg — v1.37

PlaceId: 107778070777162. Load through the existing universal Loader.
All automation starts OFF. Runtime validation on Potassium is still required.

## Status
| Feature | Implementation and evidence |
|---|---|
| Collect / native return / Auto Home | User reports confirm Forest redemption and subsequent collection. Lake is not fully verified. |
| Auto Hatch | Walks to ready owned-base Hatch! prompts and holds input. Actual pet creation remains unverified. |
| Base / treadmill upgrades | Implemented using mapped soft-currency UI callbacks, affordability checks and level-change confirmation. Offline tested only. |
| Speed training | Walks to owned TreadmillBottom and observes SpeedGained notifications. Offline tested only. |
| Auto Place | Disabled in release after user-reported BAC kicks. No UI toggle can enable it. |
| Money collection | Removed: the game collects money automatically. |

## Auto Place remains disabled
The release constant AUTO_PLACE_ENABLED=false prevents equip, movement and clicks from Auto Place before any action is attempted. Historical placement code is unreachable through the feature. Stop the previously running script before updating. This does not establish the detection mechanism or certify other executor automation as accepted by the game. Place eggs manually.

## Upgrades
The Upgrade button cycles OFF -> BASE -> TREADMILL -> BOTH -> OFF.
BOTH picks the cheapest affordable mapped option. Disable Collect to allow this module to run.

Only the explicitly observed PlotUpgrade/TreadmillUpgrade -> Sign -> SurfaceGui -> Frame -> Upgrade or FirstUpgrade controls are considered. RobuxUpgrade is excluded. Prices must parse as dollar-prefixed in-game amounts such as $1M / $15K. No Robux purchase prompt is accepted or confirmed.

The balance must be found unambiguously in Cash/Money/Coins player attributes or matching numeric leaderstats values. Missing/conflicting balance information blocks purchases rather than guessing. The game's live currency schema is not yet verified.

Existing client callbacks are dispatched only if the executor supplies firesignal AND getconnections and a handler is observed on MouseButton1Click or Activated. Exactly one signal is dispatched, without fallback double-clicking. Missing callback mapping blocks the action. No guessed Remote arguments and no VirtualInputManager purchase clicks are used.

The module walks within range, then rechecks plot ownership, current level and affordability. Each action is separated by at least eight seconds. A strictly higher displayed level confirms an observed upgrade. If no level change is seen within ten seconds, the module turns OFF without retrying the purchase.

## Speed training
Turn Train ON while Collect is OFF. The module uses the uniquely owned plot's observed TreadmillBottom, moves there through Humanoid:MoveTo, and stays/repositions on the belt. It never writes WalkSpeed or sends guessed speed-gain Remote commands.

RE/Treadmill/SpeedGained is observed read-only and counted in training.events. This is notification evidence, not a claimed numerical gain; the server payload contract is not interpreted. If no notification arrives, the UI reports waiting. Extra game-specific video/input requirements, if present, need live validation.

Upgrades take priority over training while a purchase result is pending. Hatch and Collect movement are serialized with these systems. Collect enabled pauses upgrades/training. Close stops all automation and active movement. Turning training OFF stops its movement; turning an active upgrade mode OFF cancels its approach.

## Hatch
Place eggs manually in the base, then turn Auto Hatch ON. Only enabled exact Hatch! prompts in the owned base are eligible. Detached prompts must be uniquely closest to the owned plot center within 35 studs with a five-stud margin over the next plot.

Auto Hatch walks toward ready eggs within 150 studs, then holds within the smaller of seven studs and MaxActivationDistance. It waits while collecting/placing/carrying, with a four-second cooldown and three attempts per prompt. Input success or prompt disappearance is not claimed as pet creation.

## Collect and Home
Auto Home matches explicit owner metadata or the exact account username on PlotSign. It rejects ambiguous plots and prefers a delivery candidate over a disclosed spawn fallback.

WALK is the default outbound mode; optional Tween remains available. Loaded return uses native movement. Current-character FieldEggCarry.IsCarrying events take priority over GUI evidence. A recent redemption event plus a matching new inventory UID can complete return before reaching SpawnPoint. Normal walking-stall recovery may try two jumps per waypoint with cooldown; there is no repeated midair jump.

Forest successes are supported by user reports; not all areas are verified. Alt/RightShift hide/show the hub without stopping automation; Close stops it.

## Reports
Copy short refreshes live state without Scan. It contains:
- autoCollect.upgrades: mode, last, pending, observed level increases
- autoCollect.training: enabled, last, events, lastEventAt
- autoCollect.autoHome, lastReturn, carryState and inventory observations
- autoHatch.lastAttempt with inputOK/promptChanged/resultVerified
- autoPlace.available=false and bounded event/slot diagnostics

## Local validation
~~~sh
python -m unittest discover -s tests -v
luac5.4 -p Games/StealAnEgg_Diagnostics.lua
lua5.4 tests/test_egg_collect.lua
~~~
96 simulated cases and 4 Loader contract tests pass. The complete Lua chunk compiles locally. These checks cover cash parsing, unknown/conflicting balances, exclusion of premium controls, missing callbacks, level confirmation/no-result stop, native treadmill approach and previous automation guards. They are not Potassium/server tests and do not guarantee absence of anti-cheat kicks.
