extends RefCounted
class_name GameSettings

const SETTINGS_PATH := "user://settings.json"
const SAVE_PATH := "user://progress.json"

static func defaults() -> Dictionary:
	return {
		"ai_mode": "offline",
		"provider_profiles": [
			{"name": "Gemini Teacher", "provider": "gemini", "model": "gemini-2.5-flash", "credential_name": ""},
			{"name": "Gemini NPC", "provider": "gemini", "model": "gemini-2.5-flash", "credential_name": ""},
			{"name": "Local Tutor", "provider": "ollama", "endpoint": "http://127.0.0.1:11434", "model": ""}
		],
		"graphics": {"resolution": "1280x720", "quality": "low"}
	}

static func load_json(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return fallback.duplicate(true)

static func save_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

static func load_settings() -> Dictionary:
	return load_json(SETTINGS_PATH, defaults())

static func save_settings(data: Dictionary) -> bool:
	return save_json(SETTINGS_PATH, data)

static func load_progress() -> Dictionary:
	return load_json(SAVE_PATH, {"completed_lessons": [], "correct_answers": 0})

static func save_progress(data: Dictionary) -> bool:
	return save_json(SAVE_PATH, data)
