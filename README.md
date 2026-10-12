# Encounter Hub

Windows Python launcher for multiple instances of the existing Encounter ReBuilt bot.

## Setup

1. Install Python 3.10 or newer with Tcl/Tk (the standard Windows installer includes it).
2. Download this repository using **Code → Download ZIP** and extract it to a writable folder.
3. Double-click **Launch Hub.vbs**, accept the administrator prompt, then choose your existing `Encounter_ReBuilt.exe`.
4. Check any number of characters and click **Launch Selected**.

No pip dependencies or AutoIt installation are required. Keep `hub.py`, `app_main.py`, and `Launch Hub.vbs` together. The VBS launcher uses windowless Python so no black console stays open. Create a desktop shortcut to `Launch Hub.vbs` if desired. The older CMD entry point forwards to this launcher, but may briefly show a console; use the VBS file directly to avoid it entirely. The original bot and its Config/Files/Images stay in their existing folder.

## Commands

Use the same checked characters for **Pause**, **Resume**, **Trade Mode**, **Open Lockboxes**, **Show**, or **Stop**.
Trade and lockbox requests pause farming, wait for the current run to finish, then select that mode. Already active modes are not toggled off. Trade Mode honors the original bot's restrictions (including Guild Hall sell location). A new command replaces the previous queued request. Waiting commands time out after 30 minutes.

Stop force-stops the selected bot processes, leaving their Guild Wars clients tracked until hub exit. **Closing the hub terminates all bot and game processes owned by this hub session, then waits for them to exit.** Other Guild Wars clients are left alone. The GW PIDs column shows each bot’s currently owned `Gw.exe` processes, including relaunches. Each bot is launched suspended, assigned to a private Windows Job with kill-on-close, then resumed. Windows tracks its descendants without relying on process names, window titles, or parent PID polling. If ownership assignment fails, that bot is stopped before it can launch a game. Only bots launched in the current hub session are controlled; existing bot instances are not adopted. Close previous bot instances before launching those characters again. Use separate accounts for simultaneous game sessions.

Selections and the bot path are saved in `%LOCALAPPDATA%\EncounterHub\settings.json`. Account passwords are neither read nor uploaded by the hub.

## Automatic updates

At startup, `hub.py` checks `dasaright/EncounterHub` on GitHub's `main` branch and updates `app_main.py` before opening the GUI. **Check for Updates** also downloads new app code while the hub stays open; reopen the hub to use it. Downloading an update does not stop running bots. Closing the hub to activate it also closes this hub’s bots and game clients. Settings and the original bot files are preserved.

The updater retrieves the manifest and source from the same immutable commit, checks SHA-256, checks Python syntax, keeps `app_main.py.backup`, and atomically replaces the app file. If GitHub is offline or an update fails validation, it uses the installed app. Repository maintainers control the downloaded code; the updater uses no GitHub token. **Check for Updates updates the complete allowlisted bundle**, including `hub.py` and both launchers. All files are verified before any are installed, backups are kept, and failed installations roll back files already replaced. `update.json` remains compatible with older hubs, while `bundle.json` describes the complete update. An older hub upgrades its app with its existing Check for Updates button; after reopening, the new app automatically upgrades the updater and launcher files. No manual ZIP download is needed for this migration.

## Publishing changes

Edit `app_main.py`, bump `VERSION`, and run `python tools/build_manifest.py` to refresh `update.json` and `bundle.json`. Commit all changed code and manifests together to `main`. Run `python -m unittest discover -s tests` before publishing. All installations check the updated manifest on their next launch.

## Validation and limits

Unit tests cover command routing, update validation, offline/error behavior, and atomic installation. Windows control calls are designed against the provided bot's exact AutoIt controls. Live Guild Wars testing is required on Windows. Started status confirms the character-specific bot window, not successful farming; sent commands mean button-click requests, not task completion. Bot dialogs or missing account configuration require attention in the original bot window.

## Switching from the previous launcher

Use **Check for Updates** in your existing hub, then close and reopen it. The upgraded app installs the full launcher bundle. Use `Launch Hub.vbs` afterward for console-free startup. Saved selections and the bot path remain intact. Bots created before this ownership upgrade cannot be adopted safely; close those old bot/game windows manually once before launching new instances through version 1.1.0.
