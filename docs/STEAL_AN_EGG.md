# Steal An Egg — v1.53

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
| Egg data / selection | v1.49 user report confirms all 300 Directory categories captured, and v1.48 confirms six UID-linked field prompts. v1.50 adds actual game Rank selection; the user reports arrival without pickup. v1.51 fixes two reproduced arrival stalls; live retest is pending. |
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

## Compact complete Directory traversal (v1.49)

The user's v1.48 report confirms all three module loads succeeded in Potassium. Data.Assets exports a Directory table keyed by the game's AssetCategory, and definitions include `_id`, DisplayName, EarningRate, ModelWeight, Egg and Rarity. Data.Rarity exports Rarities with actual Rank values, including ties; AssetEarnings exports four functions whose parameters/formula remain unknown and were not invoked. The generic 256-entry snapshot captured only part of Directory because colors, animations, icons and sound tables consumed the same budget. Six nearby field prompts were UID-linked successfully, but field income remained unknown.

Read game data now projects Data.Assets.Directory separately into `eggSelection.definitionDiscovery.modules[1].directory`. Every enumerated source key gets its own record, sorted by exact category key/key type, without display-name merging or a preferred-category-only subset. The projection reads only these observed fields using raw table access:

- `_id`, `DisplayName`, `EarningRate`, optional `ModelWeight`
- `Egg.DisplayName`, optional `Egg.GrowthTime` and `Egg.WeightKg`
- `Rarity._id`, optional `Rarity.DisplayName`, and `Rarity.Rank`

Icons, colors, animation Instances, audio, drop/visual odds and other unrelated fields are not traversed or copied into Directory records. Generic Data.Assets snapshots omit Directory, ByRarity and Personalities by design, disclose those omissions, and retain their root key/type descriptions. Directory coverage has its own budget/completeness independent of the generic snapshot. EarningRate remains a catalog field, not confirmed actual per-second income: the user's Whale Shark catalog value was 700000 versus live inventory 630673, and Brr Brr Patapim was 1800 versus 5929. No calculation, field ranking or rarity-selection mode is added here.

Coverage fields distinguish `scanned`, `exported`, `totalEntries`, `traversalComplete`, `complete` and `requiredFieldsComplete`. `totalEntries` is exact only after source enumeration reaches the end; it is absent on byte/entry limit or cancellation. `observedAtLeast` identifies a lower bound when a cap is hit. `complete` means all keys/rows were captured without unsupported records, invalid scalar types or truncated text. Missing source fields remain unknown and are listed per row; they make `requiredFieldsComplete=false` with `recordsWithMissingFields`, even if every source row was read. Identity mismatches, duplicate definition IDs and shortened keys are flagged without collapsing entries or treating them as established field identities. Rank ties are preserved as game values.

Limits are explicit: at most 4096 Directory entries, a 2 MiB conservative JSON-byte budget for projected entry data, 160-byte text/key limits at UTF-8 boundaries, and a yield every 128 records. The conservative budget estimates worst-case JSON escaping rather than claiming an exact output-file byte count. Cancellation, malformed source schema, nonfinite/callable fields and unsupported row/key shapes are reported. Missing/non-table Directory never becomes an empty success. No exported functions or table index/pairs metamethods are invoked during projection.

The Eggs list and final Read game data status show Directory exported/total counts, coverage status and rows with missing fields. Use the same flow: start v1.49 with automation OFF, Eggs -> Read game data -> Copy eggs. Check the compact Directory report, not the intentionally omitted generic snapshot, for coverage. Live total species count and full-directory completion remain pending that next report. The same three manual module loads are used; no new module or Remote invocation is introduced, and Auto Place stays disabled.

Validation: 281 engine cases (15 new), 16 full-file startup/control-flow cases (one new), four Python Loader contracts and full Loader/egg source compilation. The new cases include a 400-category directory with 100 cosmetic properties per category, exact field/media separation, duplicate display names, tied ranks, unknown fields, unsupported/callable/nonfinite values, hostile metamethods, aliases/ID conflicts, invalid schema, byte limits, cancellation, UTF-8 limits, focused export integration and continued separation from Income selection. The UI case verifies the visible Directory count and compact Copy eggs payload after the actual Read game data callback in the service model. These are simulations; live v1.49 directory coverage is not yet verified.


## Selection by actual game Rank (v1.50)

The user's v1.49 report confirms Directory captured all 300 entries: traversalComplete, complete and requiredFieldsComplete are true, with zero field errors, invalid records, missing-field rows or identity conflicts. Data.Rarity was captured completely and contains actual tied Rank values. The generic Data.Assets snapshot intentionally omits Directory and therefore remains complete=false; that unrelated flag does not invalidate the separate complete Directory observation.

The Eggs Mode button now cycles Nearest -> Rarity -> Income -> Preferred -> Nearest. Nearest remains the startup default; selecting Rarity does not load modules automatically. Read game data remains a manual action with automation stopped. After loading the same three allowlisted modules, the hub builds a category index and refreshes the visible list. No game earnings functions or new Remote calls are used.

Rarity matches a fresh, non-carried field record to its prompt using the existing explicit_uid or unique_position binding, then uses the record's exact AssetCategory to look up Directory.categoryKey. The category key must equal the definition _id, be untruncated and unique. Directory.Rarity._id and its positive finite integer Rank must agree with the complete Data.Rarity.Rarities observation. Definitions with ambiguous identity, invalid Rank or contradictory canonical rank are skipped. Display names and egg names are never category identifiers. Missing or invalid EarningRate and other unrelated fields do not prevent a valid Rank; incomplete Directory traversal or missing/incomplete canonical Rarity observations block the index. Canonical snapshot text/key truncation now marks the snapshot incomplete. A new read invalidates previous ranks immediately, including on error, timeout or cancellation.

Among approachable UID-linked prompts within the existing 250-stud and height limits, accepted eggs sort by game Rank descending, then current distance ascending, then UID for a deterministic exact tie. Equal ranks such as Mythic/Rainbow remain equal; no name-based tier ordering is invented. Unknown species, stale or ambiguous UID bindings and explicit category/rarity conflicts are skipped without falling back to Nearest. Scope is the readable, approachable prompt set, not every spawn in the entire map. A disabled prompt can be an approach target under the existing approach rules; pickup still requires the normal activation checks.

The collector checks the current highest-ranked candidate again after travel and before input. A better target appearing, a changed UID/species/rank, or a disappeared/stale binding defers pickup until reselection. Rank metadata includes rarityBinding, catalogDefinition and source paths. Copy eggs / Copy short expose catalog.knownRarity, catalog.rarityRanking (readiness, category/skipped counts, bounded issues and tie policy) and catalog.rarityRankingApplied. Capture-time definitionDiscovery/snapshot rankingApplied flags remain false because those blocks describe observation, while the catalog flag describes the active selection. The list shows Rank and the reason for skipping unknown eggs. Base EarningRate is never assigned to incomePerSecond, and Directory display names are not injected into Preferred name matching. Auto Place remains disabled and no money automation is added.

Live test: run the usual main Loader and confirm v1.50. Leave automation OFF, open Eggs, press Read game data and wait for the result. Change Mode from NEAREST to RARITY, then Scan eggs after fresh field updates arrive. Inspect knownRarity, rank provenance and eligibility with Copy eggs. Enable Collect to verify the selected highest Rank in the reachable set and nearest choice among tied ranks. Stop Collect before changing modes. Share Copy eggs or Copy short if ranks remain unknown or the chosen target differs. This release has not yet been validated in live Potassium.

Validation: 311 simulated engine cases (30 new), 20 full-file startup/control-flow cases (four new), four Python Loader contracts, and full Lua 5.4 source compilation. New cases exercise real-rank sorting and travel/pickup, ties independent of catalog income, exact category IDs despite shared display names, UID/rank provenance, unknown/invalid/conflicting/stale/carried/removed targets, canonical aliases, partial coverage and identity conflicts, missing income independence, rescan invalidation, post-travel reselection, truncated identities, all four mode controls, no implicit module loading, visible readiness/export and active-Collect mode locking. Tests are simulations, not live game success.


## Rarity arrival without pickup (v1.51)

The user reports that v1.50 walks to the egg but does not collect it. Without a new runtime export, the exact live blocker is not confirmed. Two relevant v1.50 failures were reproduced before editing: when a disabled prompt enables shortly after arrival the collector returns before waiting for that enable, and when an equal-Rank egg becomes closer during travel the post-travel check cancels an otherwise valid pickup. The old repeated selection can remain at a permanently disabled highest-ranked egg.

Rarity now waits up to two seconds in activation range for the game to enable the selected prompt, checking Collect/active/scan/character/health/carry state, prompt presence/range, UID, category and Rank on each wait. It still requires the normal enabled/action/hold/range activation checks before input. If the game keeps that prompt disabled, its UID is temporarily excluded from Rarity selection for eight seconds so another eligible egg can be tried. The exclusion follows replacement prompt proxies, is bounded to 64 UIDs, and clears when its retry expires or the same UID changes category/Rank. Starting Collect clears temporary exclusions. Waiting does not increment input-attempt counts and never changes Prompt.Enabled or invokes game Remotes.

The selected target stays committed through travel when another equal-Rank egg becomes closer. Initial selection still breaks equal Rank by distance. A strictly higher-ranked accepted target, changed identity/category/Rank, expired field binding, or failed activation check still prevents stale input. If a previously deferred UID's retry expires while traveling to a lower-ranked egg, that known disabled prompt does not preempt the committed trip until it enables; this prevents timer expiry from repeatedly starving valid pickup.

Copy eggs now includes a focused collection block with enabled/phase/last/attempts, promptWait, lastMovement and lastInput. Copy short also exposes promptWait. Catalog entries expose blockedReason and catalog.deferred counts, and the visible list explains temporary skips/retry time. If all eligible prompts are temporarily blocked, Collect says it is waiting to retry instead of claiming rarity data is missing.

Validation: both new reproduction cases fail against v1.50 and pass with the fix. The final suite passes 327 engine cases (16 new), 21 full-file startup/control-flow cases (one new), four Python Loader contracts and full Lua 5.4 compilation. Cases cover delayed enable with Walk/Tween, permanent disable and next-target selection, an already-near disabled prompt, bounded wait/retry, stop/removal/UID changes during wait, higher-Rank arrival, tied-Rank stability, proxy replacement, changed identity, mode isolation, bounded exclusion memory, timer expiry during a trip and collection diagnostics through the actual Copy eggs callback. These are simulations. The user's live Potassium retest remains required; this change does not establish that a particular disabled game prompt should be usable.

Retest with the usual Loader, confirm v1.51, leave automation OFF, Eggs -> Read game data -> Mode: RARITY -> Scan eggs, then enable Collect. A prompt that remains disabled should receive a temporary skip and another eligible egg should be tried. If arrival still produces no pickup, use Copy eggs while the symptom is visible and provide the collection block plus eggSelection.catalog; these include wait/input status without needing to resend all 300 Directory rows.


## Continuous Collect without automatic PAUSED state (v1.52)

After v1.51 the user reported Collect switching to PAUSED and explicitly requested removal of that automatic pause. No runtime export identified which pause path fired. The previous implementation switched Collect OFF after one unconfirmed pickup, unavailable home/return/delivery conditions, or a runtime error. These operation-driven paths now use a scheduled retry while Collect stays ON, with phase WAITING_RETRY and a visible reason/countdown.

Unconfirmed pickup and input failure wait five seconds before reevaluating normal carry, identity, ownership and activation conditions. Rarity temporarily defers that UID using the existing eight-second rule so other eligible eggs can be tried. Per-prompt attempts still have a four-second minimum spacing and a three-attempt batch, but the batch automatically resets thirty seconds after its last input instead of requiring an OFF/ON toggle. Repeated operation errors receive the same five-second wait; they remain visible rather than spinning without a delay. Missing or invalid home, blocked return, or unverified delivery also remain ON and retry after the wait. Unverified input/delivery is never labeled successful.

Pickup retry retains its pre-input inventory baseline internally. If field carrying is detected during the wait, the collector clears that wait, retains the baseline and dispatches the normal return path immediately. A late new inventory UID clears the pickup wait and is counted once without claiming its acquisition source. Copy eggs collection.retry and Copy short retry expose only bounded reason/kind/time/remainingSeconds fields; internal character references and inventory baselines are not serialized. The scheduler gives retry reasons/countdowns priority over the generic nearest-prompt text, and the actual button remains Collect: ON. The release has no Collect: PAUSED state.

OFF cancels pending retries and movement. Closing the hub, respawn, a user carry marker, and explicitly choosing manual placement/recording still stop collection as intentional lifecycle/handoff actions. Starting Collect clears old retry state. The new automatic retry does not enable disabled prompts, change carry state, remove activation/range checks, or enable Auto Place.

Validation: 336 simulated engine cases (nine new, with prior automatic-stop expectations updated to the requested ON/retry behavior), 22 full-file startup/control-flow cases (one new), four Python Loader contracts and full Lua 5.4 source compilation. Cases verify automatic retry without toggling, thirty-second batch reset, OFF cancelling later input, late field-carry delivery with the original baseline, late inventory evidence counted once, temporary runtime-fault recovery, home recovery, Rarity trying another UID, exported countdowns, and the actual scheduler keeping the button ON while displaying an unavailable-home retry. Live pickup success on Potassium is not established by these simulations.

Retest with the usual Loader, confirm v1.52, read game data for Rarity, then enable Collect. It should remain ON and automatically reevaluate failures. If it remains unable to acquire eggs, Copy eggs while the symptom is visible; the first collection block includes the last input error/outcome and current retry reason, which are needed to identify the game's live blocker.


## Automatic egg discovery on Collect ON; Eggs UI removed (v1.53)

The user requested automatic egg detection when Collect is enabled and removal of the Eggs UI. The Eggs tab, separate frame/list, Scan eggs, Read game data, Scan sources, Copy eggs, preferred-name editor and their callbacks are removed. Remaining tabs are Automation, Placement, Diagnostics and Settings. Settings contains a compact Priority control switching Rarity / Nearest while Collect is OFF. Rarity is now the default priority; automation itself still starts OFF. Legacy Income/Preferred selection and source-reading functions remain internal for compatibility/tests, but are not exposed by the simplified control.

Collect ON now prepares the required data before pickup. In Rarity mode, it automatically requires the same three exact allowlisted game modules, captures Directory/canonical ranks and builds the UID/category index. This explicitly requested automatic behavior supersedes earlier manual-only module-loading notes. Roblox require may run the modules' initialization/dependencies; exported earnings functions are still never invoked. Nearest mode uses the live prompt cache without loading Rank modules. The existing initial prompt discovery plus prompt lifecycle and passive field events continue to update the cache, and each collection selection refreshes nearby candidates automatically. No repeated broad source scan or guessed snapshot Remote call is added. If no fresh UID-linked field records have arrived from the game yet, Rarity waits for those updates rather than guessing a species or rank.

Successful definition/index data is reused for the session, including subsequent OFF/ON cycles; successful loads are not repeated every scheduler tick. Failed or unavailable data keeps Collect ON in DISCOVERING and retries after fifteen seconds. A module still loading after its five-second observation deadline is not loaded again until its pending initialization has completed. Automatic discovery exposes status/running/attempts/result/reason and retry countdown in eggSelection.automaticDiscovery. Existing pickup/return retries from v1.52 continue separately.

An ON/OFF generation token and continuation checks cancel observation when Collect is stopped, the hub closes, or a new Collect session supersedes the old one. Cancellation is checked between module loads, during the observation wait and while traversing Directory. Late initialization output is ignored; the hub does not attempt to cancel the game's initialization itself. A field-carrying character proceeds through the existing return flow before data preparation. Discovery uses the existing scan/movement lock, and rechecks the Collect session and character before movement/input. Priority changes are blocked during active Collect/preparation.

Diagnostics -> Copy short now creates a current focused collect_status report without requiring Scan / Refresh first. It includes autoCollect with selection, automatic discovery, definitions, input/return/retry diagnostics and autoHatch. Copy all and Save file retain the full diagnostic scan workflow. The automatic preparation reason/countdown is prioritized in the Collect status display. The nearest-prompt attempt count is also read from its actual current attempt state. Auto Place remains disabled.

Validation: 348 simulated engine cases (12 new), 20 current full-file startup/control-flow cases (obsolete Eggs-UI cases replaced), four Python Loader contracts and full Lua 5.4 source compilation. New engine cases cover ON-to-discovery-to-highest-Rank pickup without manual scan, no initialization while OFF, cache reuse, failure/backoff, OFF cancellation, rapid OFF/ON generations, non-duplication of pending timeouts, cancellation during Directory capture, new field updates using cached definitions, Nearest without module loads, carrying-before-initialization and diagnostic state. Full-file cases verify all remaining tabs and removed controls, default Rarity, automatic loading through the actual Collect scheduler, cached OFF/ON, priority locking, failed-read backoff, OFF during module initialization, immediate Copy short without a prior diagnostic scan, Loader startup, lifecycle cleanup and existing controls. These simulations do not establish live pickup success in Potassium.

Retest: run the usual Loader, confirm v1.53, and press Collect ON. No Eggs-page scan/read action is needed. Priority defaults to Rarity; Settings -> Priority: NEAREST selects the nearest-prompt behavior when Collect is OFF. If collection does not proceed, Diagnostics -> Copy short includes the live discovery and pickup status.
