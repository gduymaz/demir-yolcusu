# Phase 10 Smoke + Performance Checklist

Date: 2026-02-16
Owner: Codex

## 1) Flow Chain Validation

Run:

```bash
./run.sh flow
```

Expected:
- Splash -> MainMenu
- MainMenu -> Slot -> Garage
- Garage -> Map
- Map -> Travel
- Travel <-> Station
- Station -> Summary
- Summary -> Map

Result:
- [x] Static transition chain check passed

## 2) Automated Smoke

Run:

```bash
./run.sh headless
./run.sh test
```

Expected:
- No parse errors
- Full test suite green

Result:
- [x] Headless parse passed
- [x] Tests passed (366/366)

## 3) Manual Gameplay Smoke (Touch + Mouse)

Session target: 15-20 minutes

- [ ] Splash visible for ~2 sec then transitions to menu
- [ ] MainMenu buttons all work (Start/New, Continue, Settings, Achievements)
- [ ] Slot 1/2/3 load/new/delete independently
- [ ] Garage drag-drop wagons works without visual artifact
- [ ] Map start/end station selection works
- [ ] Travel speed toggle works (1x/2x)
- [ ] Station boarding, refuel, cargo, shop interactions work
- [ ] Summary return to map works
- [ ] Pause overlay (travel/station) resume/settings/main menu works

## 4) Audio Smoke

- [ ] BGM switches by scene (menu/garage-map/station-travel/summary)
- [ ] SFX reacts to money earned/spent
- [ ] SFX reacts to boarding/lost passenger
- [ ] SFX reacts to random event, quest complete, cargo delivered
- [ ] Station arrival announcement cue plays
- [ ] Missing import-ready asset does not crash gameplay

## 5) Performance Quick Check

Target device: mobile portrait 540x960

- [ ] Average FPS >= 30 during station scene peak load
- [ ] No visible hitch on scene transitions
- [ ] Memory remains stable during 20 min loop session

## 6) Debug Log Review

Run:

```bash
./run.sh debug
```

Then inspect latest file under `logs/`:

- [ ] No recurring parser/runtime error
- [ ] No repetitive severe warning flood
- [ ] Scene transitions and trip summary logs look consistent

## Notes
- Audio files must be import-ready in Godot for actual playback; otherwise AudioManager falls back silently and writes a single warning.
- This checklist complements `docs/checklist.md` and is phase-closure focused.
