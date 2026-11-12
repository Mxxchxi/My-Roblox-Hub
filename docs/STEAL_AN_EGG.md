# Steal An Egg — v1.48

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
194 simulated cases and 4 Loader contract tests pass. The complete Lua chunk compiles locally. These checks cover cash parsing, unknown/conflicting balances, exclusion of premium controls, missing callbacks, level confirmation/no-result stop, native treadmill approach and previous automation guards. They are not Potassium/server tests and do not guarantee absence of anti-cheat kicks.

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

## Prioritized field records and focused export (v1.44)

The user's v1.43 report showed eight empty proxy-prompt metadata records and zero known income. Server field updates did arrive, including the actual `UpdatedRecords` / `RemovedUids` batch shape, but generic diagnostics kept arbitrary first keys and reduced CFrames to userdata placeholders. Income mode correctly blocked pickup when no rate was readable; two earlier Forest deliveries occurred in Nearest mode.

The observer now captures identity and relevant fields before cosmetic properties can truncate them: UID aliases, AssetCategory, DisplayName/EggName, rarity, supported per-second rate fields, mutations, AreaId, carry state, and Position/BottomCFrame/BoundsCFrame/CFrame/PivotCFrame. CFrame positions and Vector3 coordinates are normalized into JSON-safe x/y/z values. Bounded key-name lists reveal other available fields without inventing their semantics. Supported Stats per-second values have their own prioritized capture. Generic samples remain for compatibility.

UpdatedRecords and FieldEggShifted populate a private session cache of at most 256 identities; at most 128 updates/removals are processed per batch. FieldEggGone and RemovedUids invalidate cached entries. Diagnostic samples retain at most four canonical records per event and three events. The cache never replays payloads or requests a game snapshot Remote.

Field metadata is linked by an explicit prompt UID first. For attribute-free CarryAreaEgg proxies, a labelled `unique_position` correlation requires exactly one fresh, non-carried record within 1.5 horizontal studs and eight vertical studs using one of its observed anchors, and no second cached CarryAreaEgg prompt at that anchor. Records older than 120 seconds are excluded. Ambiguous records/prompts, wrong explicit UIDs and conflicting metadata do not receive a guessed identity or score. Position correlation is an inference among observed records, not an authoritative server identity contract; live mapping still requires verification.

The Eggs counter now separates nearby prompts, linked identities and known incomes. AssetCategory is shown as a category when an actual egg name is absent, without converting categories into guessed egg names. Income still requires explicit finite per-second data; absent rates are not replaced by rarity, name, size or price estimates. No rarity quality order is invented.

Use **Eggs -> Scan eggs -> Copy eggs** after ordinary field updates arrive. Copy eggs exports only `{kind:"egg_data", eggSelection:...}` through the existing clipboard/readback/fallback flow. This includes prompt coordinates, `catalog.fieldData` cache/freshness diagnostics, typed field samples and metadata binding methods. Copy short still includes the same data with the larger report. No collection action is needed to scan. If zero fresh records are present, keep the hub open for natural updates and rescan; do not enable Income expecting it to choose unknown eggs.

Nineteen new simulated cases verify prioritized UID/CFrame capture, observed batch schema, unique and explicit identity links, linked-income collection, ambiguity/age/carried/range guards, invalidation, UID conflicts, cache eviction/reinsertion, Stats rates, conflicting income, batch/report limits and focused export coordinates. Total: 194 Lua cases and four Loader contracts, plus full source compilation. The code is tested on a feature branch before main is advanced; live field-rate mapping remains pending. Auto Place stays disabled.

## Read-only income and rarity source discovery (v1.45)

The user's v1.44 report contains 65 fresh field records and five unique positional links to Lake categories Duckling, Catfish and Frog, among ten nearby prompt entries. Their complete 16-field schema contains identity, category, cosmetic/size, state and positions, but no income or rarity. The five closer unmatched prompts and Lake collection remain unverified. A successful identity link is not evidence of a monetary ranking.

**Eggs -> Scan sources** now inspects client-readable attributes and named StringValue/NumberValue/IntValue objects, relevant ModuleScript paths, and income/rarity TextLabels. Stop Collect, Hatch, training, upgrades and placement recording before pressing it. Yielded scans have independent node/queue budgets for ReplicatedStorage (6000), PlayerGui (4000), PlacedEggRenders (2000), Backpack (256) and Character (256). Packages/networking, scripts, the hub's own UI and the top-level ReplicatedStorage.Assets visual tree are skipped. Data/Shared/Config/Definitions are prioritized. Relevant data module paths are preferred over generic controller paths, with a maximum of 40 module candidates, 40 field objects and 16 labels. Explicit income/rarity fields are preferred over identity-only objects at the field report cap. Errors, cancellation and traversal/output limits are disclosed.

This discovery does not read Source, execute or decompile game modules, request Remote snapshots, replay events, move the character or synthesize input. A ModuleScript path is a lead for investigation, not its exported table contents. Attributes and value objects preserve their path, parent and identity-unverified status. Income-like fields with unknown semantics, Price, Rate, rarity weights and multipliers are diagnostic values only; they do not become income per second. Hidden TextLabels are marked hidden and cannot establish current identity or earnings. Source discovery does not change selection scores or resolve missing income.

The naturally arriving `RE/EggWorld/FieldEggRaritiesShown` event is now observed, together with focused `FieldEggRedeemVerdict` samples. Four observation-only source events are retained, with two arguments, depth four, 24 entries per table and a shared 160-entry budget per event. Supported identity, income and rarity fields are captured ahead of cosmetics. Cycles and truncation are marked. These unknown event schemas are not merged into field identities or rankings.

After scanning, press **Copy eggs** and provide the result. `eggSelection.sourceDiscovery` contains source candidates, values, labels and scan completeness; `sourceEvents` contains passive event samples even when no source scan has run. Copy short includes the same evidence. If the game has an ordinary action that displays egg rarities, the user can use that normal game action and copy again; the hub does not request it. Actual income/rarity data availability is pending the next live report.

Validation: 210 simulated Lua cases, four Python Loader contracts and full Lua source compilation. The 16 new cases cover read-only module inspection, named values, unknown economic fields, bounded traversal/results/events, source priority, own-UI exclusions, hidden labels, nonfinite values, cycles, cancellation, error recovery, focused exports and separation from selection. Actual in-game source discovery has not yet been tested. Auto Place remains disabled.

## Tool Configuration income and UID binding (v1.46)

The user's v1.45 source report found `perSecond`, `perSecondDisplay` and lowercase `rarity` on direct `Backpack.<Tool>.Configuration` attributes. Examples include Whale Shark 630673/Cosmic, Brr Brr Patapim 5929/Legendary and multiple Bird tools with different rates. Matching paths and names do not uniquely identify instances: several Bird and Chicken tools share the same full path. These are inventory Tool observations, not a proven source of income for field eggs. Data.Assets, Data.Rarity and Shared.Util.AssetEarnings remain module path leads only. The v1.45 report's empty field cache indicates no field updates captured in that run, not a regression established by the source scan.

**Eggs -> Scan eggs -> Copy eggs** now includes `eggSelection.catalog.tools`. This separate catalog inspects direct Backpack and Character Tool instances and their direct child named Configuration of class Configuration. It reads explicit UID aliases (`UID`, `Uid`, `uid`, `EggUID`, `EggUid`, `FieldEggUid`), canonical `perSecond` / supported per-second fields, `rarity` / supported rarity names, and optional OwnerUserId from attributes or named scalar value children. `perSecondDisplay` is recorded separately and never replaces missing canonical income or overrides a different unrounded rate. No nested/sibling Configuration, ObjectValue target, matching name, game module or Remote is used to supply a Tool's identity or income.

Each Tool gets a weakly referenced session-local `ref`, so even missing-UID Tools and equal full paths remain separate. This ref is only a diagnostic handle, never a substitute UID. Full observed UID, UID evidence, field provenance, raw values, attribute key names, container, ItemType, and configuration count are retained. Unknown uuid-like attribute values are diagnostic only, allowing the next live report to reveal another identity scheme without guessing one.

`uidBinding.status=unique_observed_uid` means the observed UID is nonempty, consistent, unique among the scanned Tool instances, with complete per-Tool reading and local containment. This is client observation, not proof of server ownership: `serverOwnershipVerified=false`. Missing/invalid/conflicting UID, duplicate UID, multiple Configurations, incomplete reads/traversal, changed containment or an explicit foreign/conflicting owner block eligibility. Every valid UID in conflicting evidence also participates in duplicate detection, so a contradictory Tool cannot make another instance appear unique. The same Tool appearing in both container snapshots is deduplicated by instance, not by name or UID.

`eligibleForIncome` additionally requires a finite nonnegative canonical rate without conflicting rate observations. Zero is valid. Rates with missing UID remain visible with their warning status, but are not ranked as UID-linked income. Eligible inventory tools sort first by income, followed by unlinked observations. This ranking is for inspection only; it does not equip, place, sell, collect or otherwise activate a Tool. Existing field selection and AssetEgg delivery/placement inventory checks remain separate. `kind=asset_egg_tool` requires observed ItemType AssetEgg; other Tools are labelled generically rather than guessed to be hatched pets.

Limits: 1000 direct children per container, 256 observed Tool instances, 64 direct children per Tool/Configuration, at most two Configurations inspected, and 40 exported entries. Traversal, per-record and output completeness are reported separately. Inventory traversal truncation blocks unique-UID eligibility for that scan. Output truncation still reports aggregate counts and the best observed eligible entries without claiming a full export or server-confirmed best item. The Eggs list shows Tool refs, rates, rarity, UID prefixes and binding status, separately from field egg income counts. Copy eggs exports full UIDs and evidence.

Validation: 237 simulated Lua cases (27 new), four Python Loader contracts and Lua 5.4 full-source compilation. New scenarios cover same-name instances, missing/duplicate/conflicting UID, UID only in Configuration, unknown/numeric UID, scalar value children, display rounding, invalid/conflicting/zero income, multiple/nested Configurations, equip transitions, duplicate snapshots, containment/owner failures, traversal/output limits and separation from field scoring. Live UID availability and binding remain pending user testing. Auto Place remains disabled.

## Scoped audit and fault handling (v1.47)

Reviewed the Steal An Egg script's startup, UI controls/lifecycle, metadata and field selection, collection/return, ownership, hatch, training, upgrades, manual placement/recording, diagnostics/export, and shared Loader/registry/CI integration. Roll A Stickman's gameplay implementation was not changed or subjected to a new live test.

The supplied v1.46 focused export confirms the Tool reader ran successfully: 40 Tools, 38 UID-linked income records, zero duplicate UIDs, complete traversal and no metadata errors. The remaining two Tools are Gear (Bat and Trap), not missing animal identities. ItemType Asset is observed on the 38 income-bearing Tools. The scan had ten unlinked nearby egg prompts, zero field income and zero Income-mode accepted targets; the one cached field UID referred to a far-away Cosmic record. This is a data-availability limitation, not evidence of a failed Configuration reader or a UI-startup failure. The file contains no error stack establishing a runtime crash. Inventory earnings are not copied to field eggs by matching names/categories.

Confirmed defects fixed:

| Area | Before | v1.47 behavior |
| --- | --- | --- |
| Plot ownership | The first local match could override a contradictory owner; a foreign Owner value could fall through to a stale sign | Conflicting explicit values/attributes reject ownership; foreign owner attributes on PlotSign also reject its stale text |
| Hatch after movement | Ownership was resolved before approach but could change before input | Resolve owned plot again after approach; changed ownership sends no Hatch input |
| Egg inventory confirmation | Different AssetEgg Tools sharing a UID were collapsed into a complete snapshot | Mark duplicate/invalid UID snapshots incomplete so they cannot confirm acquisition or placement; deduplicate the same instance across container snapshots |
| Currency upgrades | NaN/infinite/negative currency could enter affordability logic; an overflowed price or replaced control was insufficiently guarded | Reject invalid numeric amounts, nonfinite prices, changed price and replaced button after movement |
| UI startup | Camera dimensions near zero could produce negative scale; hub order was implicit | Positive bounded scale while camera initializes; explicit DisplayOrder 1000 |
| Worker faults | Collect/Hatch could remain enabled following an unexpected exception; an egg-list render error could terminate the main scheduler | Pause Collect, switch Hatch OFF, release held input/stop movement; isolate egg rendering and export `eggSelection.runtimeErrors.ui` |
| Loader lookup/errors | A malformed non-table commit object could kill startup instead of falling back; runtime errors omitted stack context | Validate the object type before reading SHA; retain stack traceback when available |

New `tests/test_runtime_smoke.lua` executes the full Loader and full Steal An Egg script against an isolated Roblox service/Instance model. It covers construction of all tabs with automation OFF, tiny camera viewport, controls before a humanoid exists, Alt/restore, disabled Auto Place, rerun cleanup/close, successful Loader boot, malformed/unavailable lookup fallback, compile-error reporting, unsupported place, isolated egg-list errors/export, and Hatch fault shutdown. Background game loops are queued, not exercised against a real Roblox server. This is startup/control-flow simulation, not visual rendering, executor compatibility, live networking or game-physics verification.

Validation: 251 engine cases (14 new regression cases), 13 full-file startup/control-flow cases, four Python Loader contracts, and full Loader/egg Lua 5.4 compilation. CI now runs the runtime smoke suite as well as the existing checks. No production game Remote, arbitrary game module execution or placement input was added; Auto Place stays disabled.

Remaining live work: retest v1.47 on Potassium, verify the corrected failure/cancellation paths in game as needed, capture field metadata for the nearby prompts, and establish a real per-egg income/rarity source before enabling quality-based field collection. Earlier user-reported Auto Hatch, training, Forest collection/return and manual world-appearance passes remain historical live results; they are not newly revalidated by this audit. Base/treadmill upgrades and Lake collection still lack confirmed live success. Source scan/output caps remain disclosed rather than treated as full-map coverage.

## Explicit game-data module export inspection (v1.48)

The user selected further investigation of field-egg income. Earlier scans established useful module paths but did not inspect their exported data. The new **Eggs -> Read game data** button explicitly requests the exports of exactly three observed ModuleScripts:

- ReplicatedStorage.Data.Assets
- ReplicatedStorage.Data.Rarity
- ReplicatedStorage.Shared.Util.AssetEarnings

This is a separate manual operation from the existing passive Scan sources. It uses Roblox `require`, which can run a module's initialization and dependencies; it is not a passive property read. The UI states that it loads three game modules. It never runs at hub startup, never broad-loads discovered modules, and blocks the button while automation or another scan is active. The reader itself does not call game Remotes, decompile/read Source, invoke exported functions or modify returned tables. A returned earnings function is reported as a function, not invoked with guessed parameters. This change provides inspection tooling; no actual module exports have yet been supplied from the live game, so the income formula remains unverified.

Paths are resolved through unique named children, with a 512-child scope limit at each level and a final ModuleScript class check. Missing, ambiguous and non-module targets receive explicit status. Each direct load gets a five-second observation deadline in a separate task. Timeout stops further loads, ignores late output, and prevents another read while the previous load remains pending. The observer does not attempt to cancel the game's module initialization, which may continue after the observation times out or the hub closes. Errors and cancelled observation release the hub scan lock; they are exported for inspection. Loaded/error/unavailable counts avoid treating an empty or failed scan as proof that earnings data was found.

`eggSelection.definitionDiscovery` is included in Copy eggs and Copy short. Each loaded export reports its returned type, bounded raw snapshot, top-level key names/types, completion status and limits. Snapshots use raw table operations without invoking index/pairs metamethods, retain cycle/depth/truncation markers, and limit each module to 256 entries, 32 entries per table and depth four, with 96 top-level key descriptions. Strings/keys are bounded at UTF-8 boundaries. Canonical known income/rarity keys and container keys receive priority. Up to 16 observed Category values from linked field entries and inventory Tool Category attributes get priority; display names are not substituted as category identifiers.

All snapshots remain observations. No guessed schema, generic Income/BaseIncome, rarity order, static category value, weight or multiplier is automatically converted into a field-egg score. Existing Income selection still requires established per-prompt/per-UID rates. The next live export must establish whether Data.Assets contains definitions, an accessor API or another shape, and whether AssetEarnings returns callable calculation logic or data.

To test: start v1.48, leave all automation OFF, open Eggs, press Read game data, wait for the status, then Copy eggs and provide the resulting JSON. Scan sources remains available for passive inspection without loading modules. Auto Place remains disabled.

Validation: 266 simulated engine cases (15 new), 15 full-script startup/control-flow cases (two new), four Python Loader contracts, and full Lua 5.4 source compilation. Cases cover exact module allowlist, manual-only loading, active-automation blocking, exported-function non-invocation, preferred category keys, hostile table metamethods, cycles/limits, missing/ambiguous/non-module paths, load errors/recovery, timeout/late output, cancellation, scan locking, focused export separation from field scoring, and UTF-8 boundaries. Live game data exports and Potassium module-loading support remain unverified.
