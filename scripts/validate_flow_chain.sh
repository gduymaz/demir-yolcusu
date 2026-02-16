#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

pass() { printf "[PASS] %s\n" "$1"; }
fail() { printf "[FAIL] %s\n" "$1"; exit 1; }

assert_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  if rg --quiet --line-number "$pattern" "$file"; then
    pass "$msg"
  else
    fail "$msg"
  fi
}

assert_exists() {
  local path="$1"
  local msg="$2"
  if [[ -f "$path" ]]; then
    pass "$msg"
  else
    fail "$msg"
  fi
}

assert_exists "src/scenes/splash/splash_scene.tscn" "Splash scene exists"
assert_exists "src/scenes/main_menu/main_menu.tscn" "MainMenu scene exists"
assert_exists "src/scenes/garage/garage_scene.tscn" "Garage scene exists"
assert_exists "src/scenes/map/map_scene.tscn" "Map scene exists"
assert_exists "src/scenes/travel/travel_scene.tscn" "Travel scene exists"
assert_exists "src/scenes/station/station_scene.tscn" "Station scene exists"
assert_exists "src/scenes/summary/summary_scene.tscn" "Summary scene exists"

assert_contains "project.godot" 'run/main_scene="res://src/scenes/splash/splash_scene.tscn"' "Main scene is Splash"
assert_contains "src/scenes/splash/splash_scene.gd" 'SceneTransition.transition_to\("res://src/scenes/main_menu/main_menu.tscn"\)' "Splash -> MainMenu transition"
assert_contains "src/scenes/main_menu/main_menu.gd" 'SceneTransition.transition_to\("res://src/scenes/garage/garage_scene.tscn"\)' "MainMenu Slot action -> Garage transition"
assert_contains "src/scenes/garage/garage_scene.gd" 'SceneTransition.transition_to\("res://src/scenes/map/map_scene.tscn"\)' "Garage -> Map transition"
assert_contains "src/scenes/map/map_scene.gd" 'SceneTransition.transition_to\("res://src/scenes/travel/travel_scene.tscn"\)' "Map -> Travel transition"
assert_contains "src/scenes/travel/travel_scene.gd" 'SceneTransition.transition_to\("res://src/scenes/station/station_scene.tscn"\)' "Travel -> Station transition"
assert_contains "src/scenes/station/station_flow_manager.gd" 'SceneTransition.transition_to\("res://src/scenes/travel/travel_scene.tscn"\)' "Station -> Travel transition"
assert_contains "src/scenes/station/station_flow_manager.gd" 'SceneTransition.transition_to\("res://src/scenes/summary/summary_scene.tscn"\)' "Station -> Summary transition"
assert_contains "src/scenes/summary/summary_scene.gd" 'SceneTransition.transition_to\("res://src/scenes/map/map_scene.tscn"\)' "Summary -> Map transition"

printf "\nFlow chain validation completed successfully.\n"
