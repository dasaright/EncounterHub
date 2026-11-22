# Encounter Hub 2 Desktop

Native Windows application for controlling multiple Encounter ReBuilt bots, styled to match TacoBot's current Qt desktop: dark panels, Segoe UI, teal accents, rounded buttons and compact tables.

## Install / taskbar

Download **EncounterHub-Windows.zip** from [Releases](https://github.com/dasaright/EncounterHub/releases/latest), extract the whole EncounterHub folder to a permanent writable location, and run **EncounterHub.exe**. No Python installation is required. The main folder contains only `EncounterHub.exe`, `_internal`, and `Encounter ReBuilt`. Python support files and update manifests live in `_internal`; the bot source, compiled bot, Images, and Config live in `Encounter ReBuilt`. Right-click the running taskbar icon and choose **Pin to taskbar**.

Existing script installations migrate to the executable automatically after updating and reopening. Settings stay in `%LOCALAPPDATA%\EncounterHub\settings.json`.

## Controls

Columns: Select, Account, Character, Farm, Bot Status, Command, Disable Rendering, Always on Top, Pause, Resume, Trade, Stop, Launch, Buy Cons, Automatically Craft, Manually Craft, Put in Storage. There is one row per Guild Wars account: characters in `characters.ini` that share a login email are grouped together, and the Account name can be edited in place. **Farm** chooses the routine (Ministerial = the Encounter quest, Fiber = the Drazach Thicket fiber farm), and **Character** is the character that account plays for the selected farm. Type a new name in Character to add it to the account (the hub copies that account's login lines in `characters.ini`). Farm and Character are locked while the account's bot runs. The hub writes `Config\farms.ini` (`[Farms] character=farm`), which the bot reads to pick its routine. The two crafting dropdowns are saved per account and default to Full Conset. Qt lays out cell controls directly; all column borders can be dragged. Custom widths are saved and remain fixed when the window resizes; horizontal scrolling preserves space at narrow sizes. Fit Columns resets the layout to fit the window and restores automatic sizing until you manually drag a border again. Both checkbox columns synchronize with the actual bot and respect disabled bot controls. Row actions do not change bulk selections.

Stop waits for that bot executable to exit, then closes its owned game clients. Normal Close closes all supervisor-owned bot/game sessions. Windows job objects restrict shutdown to tracked descendants; unrelated clients are not matched by name or PID.

## Updates without interrupting bots

**Check for Updates** is above **Update Now**. Checking does not install code. When a newer bundle is available, Update Now downloads and validates the desktop and AutoIt bot files from the same commit, migrates old root-level support files and the existing Config folder into the clean layout, installs with rollback, attempts to recompile the AutoIt bot with the local Aut2Exe compiler, updates the saved bot path, and restarts only the hub GUI. If the old bot executable is still in use, the new executable is staged alongside it and used for future launches. The background supervisor retains ownership of active bots and games, and the reopened hub detects and reconnects those sessions automatically. Queued GUI commands are cancelled at restart; processes continue uninterrupted. Regular Close still stops owned sessions.

If the GUI unexpectedly exits, reopen the executable and it reconnects to the supervisor's active sessions. It does not claim or close unrelated manually launched Guild Wars clients. The local supervisor uses an authenticated loopback socket and stores its endpoint in `%LOCALAPPDATA%\EncounterHub\supervisor.json`. Do not manually delete that file while sessions are running.

The first migration from 1.x requires closing the old hub once; its old ownership model cannot preserve jobs across a restart. Subsequent 2.x Update Now restarts preserve bots. The supervisor keeps its running version until normal Close stops all jobs; the next launch starts the updated supervisor.


## Conset Supply Manager

The Supply Manager window holds the global Buy Cons settings that every farm works around, plus market prices. With Automatic replenishment enabled, each bot checks **bank + carried gold** after every run; at the gold trigger it pauses its farm, runs the account's **Automatically Craft** profile (Full Conset, Res Scrolls, ...) until the affordable gold is spent, then resumes the farm. **Buy Cons** queues the account's **Manually Craft** profile at the next safe checkpoint. The bot polls its own character's request, so separate accounts do not consume one another's requests.

## Fiber farm

Select **Fiber** in the Farm column and a Ranger (R/A) in Character. The character needs the quest "A New Escort"; the bot recruits Pyre Fierceshot and loads both builds itself. It farms Dragon Moss in Drazach Thicket from Saint Anjeka's Shrine (route ported from gw-suite's fiber bot), salvages dragon roots during runs, and cleans its inventory at the normal merchant when bags fill or salvage kits run out. When the stored fiber (bags, storage and the material tab) reaches the Supply Manager's fiber threshold (default 6,500), it travels to Embark Beach, buys the bones missing to match the fiber at Shad (stored bones are used first), crafts Scrolls of Resurrection at Alcus Nailbiter, stores the scrolls and leftovers, and resumes. Bones are bought and crafted in rounds sized to the free bag slots, and a gold reserve (default 30,000) is never spent. The global gold trigger above applies to the Fiber farm too. The farm lives in `Encounter ReBuilt - PUBLIC/Files/FiberFarm.au3`.

## Vaettir farm

Select **Vaettir** in the Farm column; it plays the account's Assassin from the Characters tab. The route is ported from gw-suite's Vaettir bot: from Longeye's Ledge through Bjora Marches into Jaga Moraine, taking the Norn blessing, pulling the left and right groups while staying alive (Shadow Form, Shroud of Distress, Way of Perfection, Channeling, Heart of Shadow), balling them and killing with Wastrel's Demise and Arcane Echo, then rezoning through Bjora. Build `OwVUI2h5lPP8Id2BkAiAvpLBTAA` (A/Me). It picks up gold items, lockpicks, glacial stones, black dye, event drops and weapons to salvage; mesmer tomes and Deeprunner's map pieces can be enabled with `[Vaettir] PickUpMesmerTomes=true` / `PickUpMapPieces=true` in `Config\supply.ini`. The global gold trigger applies here too. The farm lives in `Encounter ReBuilt - PUBLIC/Files/VaettirFarm.au3`.

## Rare weapons (Fiber and Vaettir)

Both farms salvage non-gold weapons for materials and never sell or salvage: gold dual-vamp weapons, gw-suite's perfect shields, and every shield the Encounter farm's item filter keeps (its shield mod table on a rare skin, a req 9 shield, or a max-armor req 8 / req 7 shield). Those are moved to storage.

## Development

Install `requirements.txt` for source development, run `hub.py`, and use `python -m unittest discover -s tests -v`. To publish app changes, bump VERSION in app_main.py and push to `main`. GitHub Actions regenerates all three update manifests, builds the Windows desktop ZIP, and publishes a versioned GitHub Release with a SHA-256 file. Each version tag is published only once; ordinary commits without a version bump do not replace an existing release. Runtime source updates do not change the packaged Python/Qt runtime; changes to runtime dependencies need a new executable build.

The legacy `bundle.json` remains a five-file migration manifest so 1.x Check for Updates can install the upgraded bootstrap. The native desktop checks `desktop-bundle.json` for the full Qt application.

Newly launched bot windows minimize once startup is confirmed. Show Selected restores them without re-minimizing. Reconnected windows keep their existing state. The per-row Trade button requests Trade Mode for that character, using the same pause-then-trade behavior as the bulk command.

If startup needs attention, the hub looks for an enabled Start button with the correct character selected, sends one recovery Start click, and watches for startup confirmation for up to two minutes. It never substitutes Pause/Resume for Start or retries repeatedly after an unsuccessful recovery. If no usable Start control is available within 30 seconds, it retains the Needs attention status.

The rightmost Put in Storage column mirrors the bot’s Statistics-tab count of golden items put in storage (not Count/Run). It refreshes every two seconds through the background worker, including for minimized bot windows. Unavailable counts display a dash; the final read remains visible after stopping, and a new launch starts a new displayed session.

## Icon update (2.0.5)

Encounter Hub uses its own taco pierced by an anime-style dagger icon. The window, title artwork, taskbar, new desktop shortcuts and newly built executable share the same image. Use Check for Updates, then Update Now to install the desktop artwork and restart the hub while active bots continue running. Existing shortcuts referencing the old executable icon can be recreated with Create Desktop Shortcut and pinned again. The release executable embeds the new icon; earlier executables retain their original embedded file icon until replaced with the new executable build.

Source artwork: assets/taco-dagger.png and assets/taco-dagger.ico. The ICO is also embedded in qt_app.py so existing updater allowlists can deliver it in one update. Generated with the built-in image tool from TacoBot's current taco: preserve the taco identity and add an anime-style fantasy dagger piercing through it, crisp app-icon composition, transparent background, no text or gore.

## Building the bot

`Encounter_ReBuilt.exe` must be compiled inside a GwAu3 checkout (it includes `../../../API/_GwAu3.au3`).
`tools/build_bot.ps1` copies the bot sources from `Encounter ReBuilt - PUBLIC` into
`<GwAu3>\Scripts\EncounterHub\Encounter ReBuilt`, runs Au3Check (failing only on errors in the bot's own files),
compiles a 32-bit exe with Aut2Exe, swaps it in (keeping the previous exe as `Encounter_ReBuilt.exe.previous`),
and copies the new exe back into this repository:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build_bot.ps1 [-GwAu3Root <path>] [-AutoItRoot <path>]
```

Running bots keep the old build until they are relaunched. `tools/relaunch_character.ps1 -Character "<name>"`
restarts one character through its Encounter Hub row; run it elevated, like the hub.

## Live market prices

When a bot quotes trader prices during a supply run it writes them to `Config\market.prices.ini` in the bot folder
(at most once a minute across all bots). Encounter Hub picks them up automatically and uses them for the
per-item and Full Conset costs in the Supply Manager.
