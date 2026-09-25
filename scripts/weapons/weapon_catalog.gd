class_name WeaponCatalog
extends RefCounted

const Definition = preload("res://scripts/weapons/weapon_definition.gd")

static func definitions() -> Array[Definition]:
	var result: Array[Definition] = []
	result.append(_entry(&"arrow", "res://assets/Props/Weapons/Ranged/Arrow.png", 12.0, 0.80, Definition.TRAJECTORY_STRAIGHT, Definition.AIM_DIRECTED, 1, 760.0, 0.0, Vector2.RIGHT))
	result.append(_entry(&"shuriken_pair", "res://assets/Props/Weapons/Shuriken/__Other_Shuriken_000.png", 8.0, 1.05, Definition.TRAJECTORY_STRAIGHT, Definition.AIM_RANDOM, 2, 680.0, 0.0, Vector2.RIGHT))
	result.append(_entry(&"mage_arc", "res://assets/Props/Weapons/Mage/Medieval Mage.png", 20.0, 1.45, Definition.TRAJECTORY_BALLISTIC, Definition.AIM_DIRECTED, 1, 560.0, 720.0, Vector2.RIGHT))
	result.append(_entry(&"forward_blade", "res://assets/Props/Weapons/Swords/Barbarian Warrior.png", 15.0, 0.95, Definition.TRAJECTORY_STRAIGHT, Definition.AIM_FORWARD, 1, 720.0, 0.0, Vector2.RIGHT))
	result.append(_entry(&"determined_blade", "res://assets/Props/Weapons/Swords/Death_Knight.png", 17.0, 1.20, Definition.TRAJECTORY_STRAIGHT, Definition.AIM_DETERMINED, 1, 700.0, 0.0, Vector2(1.0, -0.22)))
	result.append(_entry(&"triple_mage", "res://assets/Props/Weapons/Mage/Pumpkin Head Guy.png", 10.0, 1.70, Definition.TRAJECTORY_STRAIGHT, Definition.AIM_DIRECTED, 3, 640.0, 0.0, Vector2.RIGHT))
	return result

static func _entry(id: StringName, asset_path: String, damage: float, interval: float, trajectory: StringName, aim_mode: StringName, target_count: int, speed: float, gravity: float, determined_direction: Vector2) -> Definition:
	var result := Definition.new(id)
	result.asset_path = asset_path
	result.damage = damage
	result.fire_interval = interval
	result.trajectory = trajectory
	result.aim_mode = aim_mode
	result.target_count = target_count
	result.projectile_speed = speed
	result.gravity = gravity
	result.determined_direction = determined_direction
	return result

static func by_id(id: StringName) -> Definition:
	for definition: Definition in definitions():
		if definition.id == id:
			return definition
	return null

static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition: Definition in definitions():
		result.append(definition.id)
	result.sort()
	return result
