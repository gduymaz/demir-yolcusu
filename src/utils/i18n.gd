## Module: i18n.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node

const FALLBACK_LOCALE := "tr"
const SUPPORTED_LOCALES := ["tr", "en"]

var _translations: Dictionary = {}

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	_load_locale("tr")
	_load_locale("en")

## Handles `t`.
func t(key: String, params: Array = []) -> String:
	if key.is_empty():
		return ""

	var locale: String = _resolve_locale()
	var value: String = _lookup(locale, key)
	if value.is_empty():
		value = _lookup(FALLBACK_LOCALE, key)
	if value.is_empty():
		value = key

	if params.is_empty():
		return value
	return value % params

## Lifecycle/helper logic for `_resolve_locale`.
func _resolve_locale() -> String:
	var forced: String = OS.get_environment("DEMIR_LANG").strip_edges().to_lower()
	if SUPPORTED_LOCALES.has(forced):
		return forced

	var current: String = TranslationServer.get_locale().to_lower()
	for locale in SUPPORTED_LOCALES:
		if current.begins_with(locale):
			return locale

	return FALLBACK_LOCALE

## Lifecycle/helper logic for `_load_locale`.
func _load_locale(locale: String) -> void:
	var path: String = "res://src/data/i18n_%s.json" % locale
	if not FileAccess.file_exists(path):
		_translations[locale] = {}
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_translations[locale] = {}
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_translations[locale] = {}
		return

	_translations[locale] = parsed

## Lifecycle/helper logic for `_lookup`.
func _lookup(locale: String, key: String) -> String:
	var locale_map: Dictionary = _translations.get(locale, {})
	return str(locale_map.get(key, ""))
