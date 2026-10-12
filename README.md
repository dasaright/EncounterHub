# Encounter Hub 2 Desktop

Native Windows application for controlling multiple Encounter ReBuilt bots, styled to match TacoBot's current Qt desktop: dark panels, Segoe UI, teal accents, rounded buttons and compact tables.

## Install / taskbar

Download **EncounterHub-Windows.zip** from [Releases](https://github.com/dasaright/EncounterHub/releases/latest), extract the whole EncounterHub folder to a permanent writable location, and run **EncounterHub.exe**. No Python installation is required. Right-click its running taskbar icon and choose **Pin to taskbar**. The Application menu can also create a desktop shortcut. Keep the `_internal` folder and adjacent Python files; the executable loads updateable modules from beside itself.

Existing script installations migrate to the executable automatically after updating and reopening. Settings stay in `%LOCALAPPDATA%\EncounterHub\settings.json`.

## Controls

Columns: Select, Character, Bot Status, Command, Disable Rendering, Always on Top, Pause, Resume, Trade, Stop, Launch. Qt lays out cell controls directly; All column borders can be dragged. Custom widths are saved and remain fixed when the window resizes; horizontal scrolling preserves space at narrow sizes. Fit Columns resets the layout to fit the window and restores automatic sizing until you manually drag a border again. Horizontal scrolling preserves controls at narrow window sizes. Both checkbox columns synchronize with the actual bot and respect disabled bot controls. Row actions do not change bulk selections.

Stop waits for that bot executable to exit, then closes its owned game clients. Normal Close closes all supervisor-owned bot/game sessions. Windows job objects restrict shutdown to tracked descendants; unrelated clients are not matched by name or PID.

## Updates without interrupting bots

**Check for Updates** is above **Update Now**. Checking does not install code. When a newer bundle is available, Update Now downloads and validates every file from the commit that was checked, installs with rollback, and restarts only the hub GUI. The background supervisor retains ownership of active bots and games, and the reopened hub detects and reconnects those sessions automatically. Queued GUI commands are cancelled at restart; processes continue uninterrupted. Regular Close still stops owned sessions.

If the GUI unexpectedly exits, reopen the executable and it reconnects to the supervisor's active sessions. It does not claim or close unrelated manually launched Guild Wars clients. The local supervisor uses an authenticated loopback socket and stores its endpoint in `%LOCALAPPDATA%\EncounterHub\supervisor.json`. Do not manually delete that file while sessions are running.

The first migration from 1.x requires closing the old hub once; its old ownership model cannot preserve jobs across a restart. Subsequent 2.x Update Now restarts preserve bots. The supervisor keeps its running version until normal Close stops all jobs; the next launch starts the updated supervisor.

## Development

Install `requirements.txt` for source development, run `hub.py`, and use `python -m unittest discover -s tests -v`. To publish app changes, bump VERSION in app_main.py and run `python tools/build_manifest.py`, then commit code and all three manifests together. GitHub Actions tests Windows ownership/reconnection and Qt controls, builds a windowless PyInstaller executable, smoke-tests it, and publishes a release ZIP plus SHA-256. Runtime source updates do not change the packaged Python/Qt runtime; changes to runtime dependencies need a new executable build.

The legacy `bundle.json` remains a five-file migration manifest so 1.x Check for Updates can install the upgraded bootstrap. The native desktop checks `desktop-bundle.json` for the full Qt application.

Newly launched bot windows minimize once startup is confirmed. Show Selected restores them without re-minimizing. Reconnected windows keep their existing state. The per-row Trade button requests Trade Mode for that character, using the same pause-then-trade behavior as the bulk command.
