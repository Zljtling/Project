extends Node2D

const ROOT := "res://assets/pixelfx/"
var cache: Dictionary = {}
var active: Array[AnimatedSprite2D] = []

func clear_effects() -> void:
	for sprite in active:
		if is_instance_valid(sprite):
			sprite.queue_free()
	active.clear()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func load_effect(id: String) -> Dictionary:
	if cache.has(id):
		return cache[id]
	var leaf := id.get_file()
	var path := ROOT + id + "/" + leaf
	if not FileAccess.file_exists(path + ".json") or not ResourceLoader.exists(path + ".png"):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))
	if not data is Dictionary:
		return {}
	var source: Texture2D = load(path + ".png")
	var entries = data.get("frames", [])
	if entries is Dictionary:
		entries = entries.values()
	if entries.is_empty():
		return {}
	var frames := SpriteFrames.new()
	frames.set_animation_loop("default", false)
	frames.set_animation_speed("default", 12.0)
	for entry in entries:
		var rect: Dictionary = entry["frame"]
		var texture := AtlasTexture.new()
		texture.atlas = source
		texture.region = Rect2(float(rect["x"]), float(rect["y"]), float(rect["w"]), float(rect["h"]))
		frames.add_frame("default", texture, maxf(0.01, float(entry.get("duration", 83.333)) / 1000.0 * 12.0))
	var first: Dictionary = entries[0]["frame"]
	var pivot := Vector2(float(first["w"]) / 2.0, float(first["h"]) / 2.0)
	var metadata: Dictionary = data.get("meta", {}).get("pixelfx", {})
	var supplied = metadata.get("pivot", null)
	if supplied is Array and supplied.size() >= 2:
		pivot = Vector2(float(supplied[0]), float(supplied[1]))
	elif supplied is Dictionary:
		pivot = Vector2(float(supplied.get("x", pivot.x)), float(supplied.get("y", pivot.y)))
	cache[id] = {"frames": frames, "pivot": pivot}
	return cache[id]

func play_effect(id: String, point: Vector2, scale_value := 1.0) -> bool:
	for i in range(active.size() - 1, -1, -1):
		if not is_instance_valid(active[i]):
			active.remove_at(i)
	if active.size() >= 48:
		return false
	var data := load_effect(id)
	if data.is_empty():
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = data["frames"]
	sprite.centered = false
	sprite.offset = -data["pivot"]
	sprite.position = point
	sprite.scale = Vector2.ONE * scale_value
	add_child(sprite)
	active.append(sprite)
	sprite.animation_finished.connect(sprite.queue_free, CONNECT_ONE_SHOT)
	sprite.play("default")
	return true
