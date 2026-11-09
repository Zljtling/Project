extends RefCounted
## Balance values and pure rolls live apart from world/UI code.
const WEAPON_CHANCE := {"supply": 0.12, "chest": 0.25, "mob": 0.005, "elite": 1.0, "boss": 1.0}

static func weapon_stars(kind: String, roll: float) -> int:
	return 2 if kind == "boss" or (kind == "elite" and roll >= 0.5) else 1
const ARMOR_CHANCE := 0.02 # Total chest equipment chance; not 2% per suit.
const OUTSIDE_MATERIAL_CHANCE := 0.05
const INSIDE_MATERIAL_CHANCE := 0.30
const SUPPLIES := 10
const CHESTS := 7 # Plus one castle chest.
const SHOPS := 3
const MIN_CACHE_DISTANCE := 650.0

static func weapon_drops(kind: String, roll: float) -> bool:
	return roll < float(WEAPON_CHANCE.get(kind, 0.0))

static func armor_drop(roll: float, suit_roll: float) -> String:
	if roll >= ARMOR_CHANCE:
		return ""
	return "poison" if suit_roll < 0.5 else "fire"

static func material_drops(in_field: bool, roll: float) -> bool:
	return roll < (INSIDE_MATERIAL_CHANCE if in_field else OUTSIDE_MATERIAL_CHANCE)
