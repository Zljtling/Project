class_name ESRunObjectives
extends Node

signal acquired(part: String)
const PARTS := {"core": "驱动核心", "prism": "稳相棱镜", "gear": "校准齿轮"}
var world: Node2D
var found := {"core": false, "prism": false, "gear": false}
var next_guarantee := 1800.0
var bounty: ESEnemy
var extracting := false
var extraction_progress := 0.0
var extraction_origin := Vector2.ZERO

func count() -> int:
	var result := 0
	for part in found:
		if found[part]:
			result += 1
	return result

func missing() -> Array[String]:
	var result: Array[String] = []
	for part in found:
		if not found[part]:
			result.append(part)
	return result

func acquire(part: String) -> bool:
	if not found.has(part) or found[part]:
		return false
	found[part] = true
	if is_instance_valid(bounty) and bounty.get_meta("key_part", "") == part:
		bounty.remove_meta("key_part")
		bounty = null
		next_guarantee = maxf(1800.0, world_age() + 240.0)
	world.apply_component_growth()
	acquired.emit(part)
	world.notify("获得%s · 基础属性提高 · 部件 %d/3" % [PARTS[part], count()], 7.0)
	if world.has_method("play_fx"):
		world.play_fx("pickups/collect-burst", world.player.position, 1.6)
	return true

func world_age() -> float:
	return (world.cycle_index - 1) * world.cycle_duration + world.cycle_duration - world.cycle_left

func update(delta: float, held: bool) -> void:
	if extracting:
		if not held or world.player.position.distance_to(extraction_origin) > 24.0 or world.player.position.distance_to(prism_position()) > 70.0 or world.player.hurt_flash > 0.0:
			extracting = false
			extraction_progress = 0.0
			world.notify("提取中断：保持位置并按住 E，受伤会打断。")
		else:
			extraction_progress += delta
			if extraction_progress >= 3.5:
				extracting = false
				acquire("prism")
	if count() == 3 or world_age() < next_guarantee:
		return
	if is_instance_valid(bounty) and bounty.alive:
		return
	for enemy in world.enemies:
		if enemy.alive and enemy.get("boss_kind") == "hunter":
			bounty = enemy
			break
	if not is_instance_valid(bounty) or not bounty.alive:
		bounty = world.spawn_boss("hunter")
	var part := missing()[0]
	bounty.set_meta("key_part", part)
	world.notify("保底线索：标记 BOSS 携带%s。按 M 查看位置。" % PARTS[part], 8.0)

func begin_extraction() -> bool:
	if found["prism"] or world.in_dungeon or world.player.position.distance_to(prism_position()) > 70:
		return false
	extracting = true
	extraction_progress = 0.0
	extraction_origin = world.player.position
	return true

func prism_position() -> Vector2:
	if world.has_method("poison_prism_position"):
		return world.poison_prism_position()
	return world.field_center("poison") + Vector2(0, -220)

func craft_gear() -> bool:
	if found["gear"] or world.in_dungeon:
		return false
	var facility: Dictionary = world.nearest_facility()
	var p: ESRunProgression = world.progression
	if facility.is_empty() or facility["kind"] != "forge" or p.parts < 75 or p.materials["poison"] < 8 or p.materials["fire"] < 8:
		return false
	p.parts -= 75
	p.materials["poison"] -= 8
	p.materials["fire"] -= 8
	return acquire("gear")

func boss_defeated(enemy: ESEnemy) -> void:
	var remaining := missing()
	if remaining.is_empty():
		return
	var part: String = enemy.get_meta("key_part", "")
	if part not in remaining:
		var chance := 0.04 + minf(world_age() / 3600.0 * 0.20, 0.20)
		if world.rng.randf() >= chance:
			return
		part = remaining[world.rng.randi_range(0, remaining.size() - 1)]
	acquire(part)
	if enemy == bounty:
		bounty = null
		next_guarantee = maxf(1800.0, world_age() + 240.0)

func target_description() -> String:
	if count() == 3:
		return "部件齐备：前往固定地牢入口"
	if is_instance_valid(bounty) and bounty.alive:
		return "追踪携带部件的 BOSS · M 查看地图"
	if not found["prism"]:
		return "准备防毒装备，前往毒领域提取棱镜"
	if not found["gear"]:
		return "搜集零件与元素材料，到锻造房组装齿轮"
	return "挑战 BOSS 寻找核心；时间保底会提供明确目标"
