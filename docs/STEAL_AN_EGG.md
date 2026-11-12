# Steal An Egg — v1.43

PlaceId: 107778070777162. Load through the existing universal Loader.
All automation and placement recording start OFF. Evidence below separates user-reported game results from offline checks.

## Status
| Feature | Implementation and evidence |
|---|---|
| Collect / native return / Auto Home | User reports confirm Forest redemption and subsequent collection. Lake is not fully verified. |
| Auto Hatch | User reports confirm the one-shot hatch test and continuous hatching of all ready eggs on v1.39. The script still does not independently verify pet creation. |
| Base / treadmill upgrades | Implemented using mapped soft-currency UI callbacks, affordability checks and level-change confirmation. Offline tested only. |
| Speed training | User reports confirm walking onto the treadmill, speed increasing and the OFF control working on v1.39. |
| Record Placement | User's v1.42 report confirms one Bear Egg UID left inventory and exactly one visible matching owned render appeared at the click; worldEggAppearanceVerified=true. This is client evidence only. |
| Egg data / selection | New v1.43 nearby catalog, income ranking and user-defined name priorities. Offline tested; live field metadata mapping remains to be verified. |
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
175 simulated cases and 4 Loader contract tests pass. The complete Lua chunk compiles locally. These checks cover cash parsing, unknown/conflicting balances, exclusion of premium controls, missing callbacks, level confirmation/no-result stop, native treadmill approach and previous automation guards. They are not Potassium/server tests and do not guarantee absence of anti-cheat kicks.

## Manual placement handoff (v1.38)

Open **Placement → Manual placement**. This stops Collect, Hatch, upgrades and training, cancels movement, releases any held prompt and waits up to eight seconds for running work to finish. On success the hub hides. Equip the inventory egg yourself, walk to your own base and click the empty slot through the normal game controls. Alt reopens the hub; automation stays OFF until you enable it again.

This mode does not equip, activate or click the egg, choose a target, move the camera, send placement Remotes, or verify a successful placement. Auto Place remains disabled. Slot marking is optional and does not establish server acceptance of a slot.

The previous disabled implementation uses VirtualInputManager mouse input. That code path is a possible variable to remove from a reproduction, not a proven explanation of BAC-8515/BAC-3515. No authoritative public definition of those game-specific codes was found. Manual input does not guarantee that the executor or other scripts will be accepted by the game's checks. To isolate normal game placement, test without the executor/scripts; contact the experience creator if normal placement also triggers removal.

Validation: 102 simulated Lua cases, including six manual handoff cases (no equip/click/camera changes, worker completion and timeout, prompt release, character/carry checks and slot-preparation exclusion). The complete Lua chunk compiles. These are not live Roblox tests.

## Hatch validation update (v1.39)

Both Auto Hatch and Test Hatch once require a confirmed owned base and refuse input while carrying or equipping an egg. Automatic input requires the approach to report ready; cancellation or failed navigation must not fall through into a nearby hatch attempt. The one-shot test does not walk the character. Diagnostics now expose ownedPlotConfirmed and carryBlocked, and each attempt records manualTest and ownedPlot. Pet creation remains unverified by these observations.

Nine additional simulated hatch cases cover a single owned prompt, carrying, unknown ownership, disabled/wrong/out-of-range prompts, other workers/scanning, prompt changes without false pet confirmation, input error cleanup, cooldown/attempt cap, and cancelled navigation. Total: 111 cases plus four Loader contract tests; complete source compilation passes locally. No live hatch input was performed by the development environment.

Live check: reload the normal Loader, keep Collect/Train/Upgrade/Auto Hatch OFF, place an egg manually in your base and wait for Hatch!, unequip all eggs, stand within seven studs (and the prompt's own activation distance), then press Test Hatch once once. Verify the egg actually hatches in the game before enabling the continuous loop. If no pet appears, copy the refreshed short report and do not repeatedly retry.

## Record Placement (v1.40)

Open **Placement -> Record placement: OFF** to arm one recording. This uses the manual placement handoff to turn off all automation, cancel movement, release a held prompt and wait for workers to stop. The owned plot must be confirmed. The hub hides after arming. Select an inventory egg yourself and click an empty slot in your base within 60 seconds. Wait at least eight seconds after the click, reopen with Alt, then use **Copy short**. Recording turns OFF automatically. Pressing its button while ON cancels; Close/respawn also cancels. Other automation controls are blocked during recording.

The recorder reads UIS.InputBegan; it does not synthesize input, equip/activate a Tool, steer the camera, send placement Remotes or hook outgoing calls. It ignores processed GUI clicks and hub clicks. Captured data under `autoCollect.placementRecording.records` includes the equipped egg UID/name, player and hit positions, screen coordinates, the raw mouse target and up to four ancestry levels with bounded slot/ownership attributes, inventory observations and a bounded sample of already-observed incoming events. The most recent three recordings are retained in memory; Copy short/Copy all include them.

A game handler can remove the Tool before the input listener reads it. In that case a read-only equipped-egg sample at most 250 ms old may be used, explicitly labelled `equippedSource=recent_read_only_sample` with `beforeSampleAgeMs`. No UID is guessed when no usable sample exists. Only one click is analyzed per recording; additional world clicks are counted as overlapping input rather than separate placement successes.

A UID must be absent from a complete inventory snapshot for at least 0.5 seconds before `inventoryUIDRemoved=true`. Merely moving the egg to Backpack does not count. After eight seconds the status becomes `uid_removal_observed` or `placement_unconfirmed`. Every record keeps `worldPlacementVerified=false`: UID removal, target ancestry and temporally nearby events do not prove that the server accepted a placement. A detached target outside the static plot is recorded with `target.inOwnedPlot=false`, which is ancestry evidence rather than a placement rejection. There is no anti-cheat bypass or guarantee added by this recorder.

Thirteen new simulated cases exercise recorder observation, no generated placement input or camera change, stable UID removal, unequipping, incomplete inventories, invalid/processed clicks, detached targets, overlapping clicks, cancellation, timeouts, bounded event/history retention and recent versus stale egg samples. Total: 124 Lua cases and four Loader contracts pass locally. Full source compilation passes; actual recorder behavior still requires a game test.

## World appearance check (v1.41)

The same **Placement -> Record placement** button now captures a bounded world baseline when armed, then checks the world every 0.5 seconds during the existing eight-second post-click window. Select an inventory egg and place it manually once; reopen the hub after eight seconds and send Copy short. Auto Place remains disabled and this observer generates no placement actions.

The baseline covers up to 2,048 objects in the owned plot and a spatial query of at most 128 parts within 32 studs of the player. The post-click query is centered on the hit point. The known World.Build map root and local character are excluded from the spatial query; Tool and humanoid-model descendants are excluded from world candidates. Truncation/query errors are disclosed and disqualify matches that depend on incomplete coverage. These are bounded client observations, not a global server snapshot. Spatial query behavior follows [WorldRoot:GetPartBoundsInRadius](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#GetPartBoundsInRadius).

The record gains `worldBefore`, `worldResult` and `worldEggAppearanceVerified`. A positive appearance requires all of:
- Exact case-sensitive UID evidence from UID/Uid/EggUID/EggUid/AssetUID/AssetUid, or an exact UUID-shaped instance name.
- The UID was not present in the baseline's observed scope; reused instances may qualify only when assigned a fresh UID.
- Visible part geometry, position within eight studs of the click, and owned-plot ancestry or explicit matching OwnerUserId without conflicting ownership.
- A complete baseline/current scan for that ownership scope. Detached matches also require the hit to be within 24 studs of the baseline query origin so the candidate area is covered by its 32-stud radius.
- Exactly one independent matching object group (nested model/part copies are grouped), persisting at least 0.5 seconds, and stable removal of the same UID from a complete inventory observation.

A positive local result sets `status=world_egg_appearance_observed` and `worldEggAppearanceVerified=true`. `worldPlacementVerified` and `worldResult.serverAcceptanceVerified` remain false: observing a client-side egg is not an authoritative placement acknowledgement. No anti-cheat cause or acceptance guarantee is inferred.

Up to six nearby new/unmatched candidates are reported with paths, names, positions, known identity/ownership attributes, visibility and match information. Name-only or UID-less objects, foreign/unknown ownership, duplicates, stale UID evidence, invisible models, disappearing eggs and incomplete relevant coverage do not produce a positive flag. This diagnostic output allows the game's actual placement representation to be checked without guessing Remote arguments. The detector has not yet been verified against a placed egg in the live game.

Nineteen additional simulated cases cover exact/fresh/reused UID appearances, complete inventory requirements, wrong/name-only/distant IDs, foreign and detached ownership, duplicate/nested identities, disappearing/invisible geometry, Tool exclusion, bounded/incomplete scans, plot changes and UUID names. Total: 143 Lua cases and four Loader contracts pass locally; the complete source compiles.

## Observed placed-render namespace (v1.42)

The user's v1.41 report contains a new Model under `Workspace.PlacedEggRenders` named `<UserId>_<32hex UID>`, with the exact recorded egg UID as its suffix and its pivot exactly at the click. Its visible meshes and stable inventory removal were observed, but the generic detector did not parse this name as identity/ownership and the spatial query was capped. This explains the false-negative detector result; it does not explain the historical BAC kicks.

v1.42 parses this name only for direct Model children of the actual `Workspace.PlacedEggRenders` root. The decimal owner prefix must match the local player's UserId, and the UID suffix must match exactly. The parser does not apply to unrelated folders, nested lookalikes, decals or names with extra suffixes. Conflicting OwnerUserId attributes still reject a match.

A separate bounded scan enumerates up to 512 direct render-root children and up to 2,048 descendants of locally owned render Models. Complete before/after namespace coverage can validate local appearance even if the general spatial query is incomplete. Root-list/descendant truncation is reported through `worldResult.before/after.renderComplete`, with `renderRootFound` and `renderVisited`. When absent in the baseline, the root is explicitly reported absent; a newly created complete root can then be compared. Generic plot/spatial scopes keep their previous checks.

Candidate diagnostics now include `placedRender`, `renderOwnerUserId` and UID evidence with key `PlacedEggRenderName`; `worldResult.localUserId` makes the owner comparison auditable. The distance, visible geometry, unique matching group, stable presence, complete inventory removal and previous-UID rejection rules remain required. `worldPlacementVerified` and server acceptance remain unverified. Auto Place stays disabled.

Ten new simulated cases cover the reported owner_UID namespace with capped spatial queries, foreign owners, wrong folders/UIDs, malformed names, conflicting ownership, pre-existing renders, duplicate identities, namespace truncation and invisible geometry. Total: 153 Lua cases plus four Loader contracts pass locally, and full source compilation passes. Repeat one manual placement with Record placement and send Copy short to verify the new mapping live.

## Egg data and selection (v1.43)

Open the new **Eggs** tab, stop Collect, and press **Scan eggs** near the field eggs you want to inspect. The catalog shows up to 12 nearby approachable field prompts with observed name, exact UID, rarity text, income per second, distance and missing data. Copy short refreshes data and exports `autoCollect.eggSelection` with source paths, bounded raw attributes, conflicts, selected-target evidence and up to eight inventory egg names/metadata. The scan does not move the character or collect eggs. Raw data is session-only.

The mode button cycles **NEAREST -> INCOME -> PREFERRED -> NEAREST**. NEAREST is the default and preserves the existing nearest-ready/nearest-approach behavior. INCOME selects the highest readable income per second within the existing approach range, even when a lower-value egg is ready nearby; equal income uses distance. PREFERRED uses up to ten comma/semicolon/newline-separated egg names in the order supplied, matching exact trimmed names case-insensitively; press Apply names to save the list for this session. In both advanced modes, unknown/unlisted targets are skipped and there is no silent fallback to NEAREST. Stop Collect/Record placement before changing mode or priorities, then enable Collect to use the chosen strategy.

Income is accepted only from finite nonnegative numeric values or plain numeric strings in `IncomePerSecond`, `CashPerSecond`, `MoneyPerSecond` or `CoinsPerSecond`. These aliases are candidate mappings, not a confirmed contract for this game. Rates with formatted/unknown units remain unknown. Price and rarity names are not interpreted as income or an invented quality order. Conflicting identity or income sources suppress advanced selection. Income/source data must be validated with the real game before treating this mode as a verified best-egg collector.

Metadata is read from explicit attributes/named value children or labels on the prompt, up to three containing objects (stopping at folders, Workspace and the local character), and bounded explicit ObjectValue links named Target/Egg/EggModel into Workspace. Tool names are accepted only for inventory tools. No nearest-render identity guess, client module execution, hidden API call or new game Remote invocation is used to obtain stats. The existing FieldEggShifted/FieldEggBatchShifted incoming events are observed read-only; at most three bounded samples, with limited nested records, are retained for mapping the game's actual schema. Their payloads are not replayed or used as scores without an established identity link.

The range, ground-level checks, action filter, cooldown and attempt cap still apply. Target UID and policy eligibility are rechecked after moving. The last selection and pickup record include the metadata used. Missing field stats pause advanced-mode pickup with a visible explanation; open Eggs/Copy short to inspect which data is missing. Public catalog output is capped and says when truncated. Scan near eggs, wait for an ordinary field update if needed, and send Copy short to establish live names/UID/stat fields.

Twenty-two added simulated cases cover metadata/provenance, unknown/ambiguous values, highest-income traversal versus nearby low-income eggs, nearest-mode preservation, tie distance, user-defined preferences, range/action/cooldown guards, changed metadata/UID during travel, bounded catalogs/event samples and explicit object links. Total: 175 Lua cases and four Loader contracts pass locally. The whole script compiles, including Lua's top-level local-variable limit; helper/UI tables keep the added functionality within that limit. The new UI and actual field statistics still require a live game test. Auto Place remains disabled.
