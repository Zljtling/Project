class_name ESActorAppearance
extends Resource

@export_enum("player", "enemy") var placeholder := "player"
@export var texture: Texture2D
@export var animations: SpriteFrames
@export var sprite_scale := Vector2.ONE
@export var sprite_offset := Vector2.ZERO
@export var idle_animation := "idle"
@export var move_animation := "run"
