extends Node

signal on_create_block_text(unit: Node2D)
signal on_create_damage_text(unit: Node2D, hitbox: HitboxComponent)

const FLASH_MATERIAL = preload("uid://coi4nu8ohpgeo")
const FLOATING_TEXT_SCENE = preload("uid://bmy2qb3fuvnts")

var player: Player

func get_chance_sucess(chance: float) -> bool:
	var random := randf_range(0, 1.0)
	if random < chance:
		return true
	return false
