# Runtime lifecycle and regression checks

Godot 4.7.2 Mono is the current validation target. Gameplay and resource data
remain in the existing scenes and resource files.

## Ownership and extension points

- `LevelController` owns routing, the settings window, the result snapshot, and
  the current session ID. `finish_battle()` is idempotent; it snapshots results,
  cancels projectiles, stops the battle, and opens one result screen.
- `return_to_menu()` releases the battle and player before opening the menu.
  `return_to_menu("level1")` starts a fresh battle after the same teardown.
- Persistent systems register with `Main.register_session_module(node)` and
  implement `reset_session()`. Reset must be repeatable, release session-owned
  children and references, and retain only reusable resources or bounded pools.
  Register new systems here instead of adding cleanup branches to the router.
- Async work on a persistent system captures `LevelController.session_id` and
  checks it after waits. Skills use `_session_valid()`; disposed units must be
  checked with `is_instance_valid()` before accessing properties.
- Wave spawners are children of their wave manager. Projectile completion and
  cancellation belong to each projectile; the persistent barrage system does
  not create permanent per-shot signals. Skill projectiles have a lifetime bound.
- Buff templates remain outside the tree until applied copies are owned by their
  target. The skill, item, or talent must release its detached templates on exit.
  Temporary effects and helper nodes must be owned by the battle or a registered
  system, never by the scene-tree root.
- Floating text returns to a bounded idle pool, stops processing while idle, and
  reinitializes its animation on reuse. Resource directory catalogs are cached
  by directory; service-specific catalogs and icons use separate dictionaries.
- Viewport textures are bound inside each live scene instance. Do not serialize
  parent-scene overrides that refer to a child's local `SubViewport` path.

## Running the checks

From PowerShell 7 in the project directory:

```powershell
./tests/run_game_checks.ps1
./tests/run_game_checks.ps1 -Scenario menu-exit
./tests/run_game_checks.ps1 -Scenario combat-exit
./tests/run_game_checks.ps1 -Renderer headless
```

Use `-GodotExecutable <absolute path>` for another installation. The runner
checks exit codes, completion markers, all engine errors/warnings, and enforces
a process timeout. The headless run permits only the known dummy-renderer
sampler diagnostic; Forward+ must produce no diagnostics.

The full check instantiates all enemy types in the formal wave configuration
and all reachable building upgrades, exercises building, upgrading, active
skills, damage, recovery, talent selection, item drop/pickup, settings, defeat,
direct restart, and three returns to the menu. It checks bounded node counts,
orphan nodes, projectile cancellation, and effects cleanup. The other scenarios
verify menu exit and shutdown during battle without requiring a successful
return to the menu first.

Logs and Forward+ screenshots (`qa_menu.png`, `qa_settings.png`, `qa_battle.png`,
`qa_result.png`) are written under ignored `.godot/`. Visual inspection remains
necessary for new UI changes; calling button handlers in these checks does not
replace physical mouse/keyboard input testing.

Language selection remains disabled because translations are not implemented.
Graphics presets, settings persistence, cancellation of settings previews, and
final-clear victory are now implemented. See `rts-demo-improvements.md` for
the compatibility boundaries and the RTS quality regression scenario.

The runner now inspects stdout and stderr as well as the log file. Earlier
log-only results did not cover diagnostics emitted after the logger closed.
The RTS quality scenario adds transaction, upgrade ownership, animation binding,
pressure sampling, terminal ordering, and twenty session restart checks.

## Validation recorded on 2026-10-24

- Forward+ full flow, menu exit, and combat exit all passed the strict runner.
- Resource audit: 39 enemy types and 17 reachable building tiers.
- Three menu samples after teardown: 423 scene nodes each; 0 orphan nodes each.
- All three runtime logs contained no engine errors, warnings, or exit leaks.
- Menu, settings, battle, and result screenshots were inspected.
- Automated editor termination still reported `Scan thread aborted` and editor
  resource cleanup diagnostics. This is separate from the clean runtime results;
  interactive editor shutdown has not been verified because the native UI helper
  failed to initialize. Do not interpret the gameplay checks as an editor-wide
  leak guarantee.
