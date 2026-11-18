class_name DefenseArt
extends RefCounted

const GRASS = preload("res://assets/simple_tower_defense/Environment/Grass/spr_grass_02.png")
const GROUND = preload("res://assets/simple_tower_defense/Environment/Tile Set/spr_tile_set_ground.png")
const STONE = preload("res://assets/simple_tower_defense/Environment/Tile Set/spr_tile_set_stone.png")
const TOWERS = {
	"bolt": preload("res://assets/simple_tower_defense/Towers/Combat Towers/spr_tower_archer.png"),
	"blast": preload("res://assets/simple_tower_defense/Towers/Combat Towers/spr_tower_cannon.png"),
	"frost": preload("res://assets/simple_tower_defense/Towers/Combat Towers/spr_tower_ice_wizard.png"),
	"venom": preload("res://assets/simple_tower_defense/Towers/Combat Towers/spr_tower_poison_wizard.png"),
	"storm": preload("res://assets/simple_tower_defense/Towers/Combat Towers/spr_tower_lightning_tower.png"),
	"pierce": preload("res://assets/simple_tower_defense/Towers/Combat Towers/spr_tower_crossbow.png"),
	"banner": preload("res://assets/simple_tower_defense/Towers/Non-Combat Towers/spr_normal_tower_01_green.png")}
const ENEMIES = [
	preload("res://assets/simple_tower_defense/Enemies/spr_normal_slime.png"),
	preload("res://assets/simple_tower_defense/Enemies/spr_goblin.png"),
	preload("res://assets/simple_tower_defense/Enemies/spr_skeleton.png")]
const ARMORED = preload("res://assets/simple_tower_defense/Enemies/spr_king_slime.png")
const CASTLE = preload("res://assets/simple_tower_defense/Towers/Castle/spr_castle_blue.png")
const ENTRANCE = preload("res://assets/simple_tower_defense/Towers/Castle/spr_castle_red.png")
const PROJECTILES = {
	"bolt": preload("res://assets/simple_tower_defense/Towers/Combat Towers Projectiles/spr_tower_archer_projectile.png"),
	"blast": preload("res://assets/simple_tower_defense/Towers/Combat Towers Projectiles/spr_tower_cannon_projectile.png"),
	"frost": preload("res://assets/simple_tower_defense/Towers/Combat Towers Projectiles/spr_tower_ice_wizard_projectile.png"),
	"venom": preload("res://assets/simple_tower_defense/Towers/Combat Towers Projectiles/spr_tower_poison_wizard_projectile.png"),
	"storm": preload("res://assets/simple_tower_defense/Towers/Combat Towers Projectiles/spr_tower_lightning_tower_projectile.png"),
	"pierce": preload("res://assets/simple_tower_defense/Towers/Combat Towers Projectiles/spr_tower_crossbow_projectile.png")}
const DECORATIONS = [
	preload("res://assets/simple_tower_defense/Environment/Decoration/spr_tree_01_normal.png"),
	preload("res://assets/simple_tower_defense/Environment/Decoration/spr_tree_02_spruce.png"),
	preload("res://assets/simple_tower_defense/Environment/Decoration/spr_rock_02.png"),
	preload("res://assets/simple_tower_defense/Environment/Decoration/spr_mushroom_01.png")]

static func tower_texture(id: String) -> Texture2D:
	return TOWERS.get(id, TOWERS.bolt)

static func tower_frames(id: String) -> int:
	return 4 if id == "banner" else 1
