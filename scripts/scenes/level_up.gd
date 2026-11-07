class_name LevelUp
extends Node2D

@export var level_up_new_ability_scene: PackedScene
@export var level_up_stat_row_scene: PackedScene

@onready var curr_offensive_abilities: SpecialAbilityGrid = %CurrOffensiveAbilities
@onready var curr_defensive_abilities: SpecialAbilityGrid = %CurrDefensiveAbilities
@onready var ability_list: VBoxContainer = %AbilityList
@onready var stat_list: VBoxContainer = %StatList
@onready var confirm_button: Button = %Confirm
@onready var new_ability_header: Label = %NewAbilityHeader
@onready var subtitle: Label = %Subtitle
@onready var stats_remaining_label: Label = %StatsRemaining

var hero_config: EntityConfig
var stat_points_to_distribute := 3
var selected_new_ability: LevelUpNewAbility

func _ready() -> void:
	if GameVariables.selected_hero_for_threat == null:
		GameVariables.selected_hero_for_threat = GameVariables.generate_random_entity_configs(1, EntityConfig.EntityType.HERO)[0]
		GameVariables.selected_hero_for_threat.level = 2
	hero_config = GameVariables.selected_hero_for_threat
	subtitle.text = hero_config.entity_name + " has reached level " + str(hero_config.level)
	stats_remaining_label.text = "Points Remaining: " + str(stat_points_to_distribute)
	add_level_up_stat_row("Strength", hero_config.strength)
	add_level_up_stat_row("Defense", hero_config.defense)	
	add_level_up_stat_row("Skill", hero_config.skill)
	add_level_up_stat_row("Agility", hero_config.agility)
	add_level_up_stat_row("Vitality", hero_config.vitality)
	add_level_up_stat_row("Charisma", hero_config.charisma)
	confirm_button.pressed.connect(apply_and_transition_to_roster)
	setup_curr_ability_list(hero_config)
	setup_new_ability_list(hero_config)
	
func setup_new_ability_list(config: EntityConfig):
	if GameVariables.levels_for_new_ability.has(config.level):
		new_ability_header.text = "Learn a new ability"
		var all_hero_ability_names = config.abilities.map(func (a: Ability): return a.ability_name)
		var all_abilities = GameVariables.get_all_abilities()
		all_abilities.shuffle()
		all_abilities = all_abilities.filter(func (a: Ability): return !all_hero_ability_names.has(a.ability_name))
		var new_abilities_to_pick_from = all_abilities.slice(0, 3)
		for a in new_abilities_to_pick_from:
			var level_up_new_ability = level_up_new_ability_scene.instantiate() as LevelUpNewAbility
			ability_list.add_child(level_up_new_ability)
			level_up_new_ability.configure(a)
			level_up_new_ability.on_select.connect(select_ability_to_acquire)
	else:
		var level_for_next_ability = 0
		for level in GameVariables.levels_for_new_ability:
			if config.level < level:
				level_for_next_ability = level
				break
		new_ability_header.text = "New ability available at Lv " + str(level_for_next_ability)
		
func select_ability_to_acquire(a: LevelUpNewAbility):
	if selected_new_ability != null:
		selected_new_ability.dehighlight()
	selected_new_ability = a
	selected_new_ability.highlight()
	
func setup_curr_ability_list(config: EntityConfig):
	var off_abilities = config.abilities.filter(func(a: Ability): return a.category == Ability.Category.OFFENSIVE)
	var def_abilities = config.abilities.filter(func(a: Ability): return a.category == Ability.Category.DEFENSIVE)
	curr_offensive_abilities.heading_label.text = "Offensive"
	curr_defensive_abilities.heading_label.text = "Defensive"
	curr_offensive_abilities.configure_from_abilities(off_abilities)
	curr_defensive_abilities.configure_from_abilities(def_abilities)

func apply_and_transition_to_roster():
	if selected_new_ability != null:
		hero_config.abilities.append(selected_new_ability.ability)
	get_tree().change_scene_to_file("res://scenes/roster.tscn")

func add_level_up_stat_row(stat_name: String, stat_value: int):
	var level_up_stat_row = level_up_stat_row_scene.instantiate() as LevelUpStatRow
	stat_list.add_child(level_up_stat_row)
	level_up_stat_row.configure(self, stat_name, stat_value)
	level_up_stat_row.on_increase.connect(increase_stat)
	level_up_stat_row.on_decrease.connect(decrease_stat)

func increase_stat(stat_key: String):
	stat_points_to_distribute -= 1
	hero_config[stat_key] += 1
	stats_remaining_label.text = "Points Remaining: " + str(stat_points_to_distribute)

func decrease_stat(stat_key: String):
	stat_points_to_distribute += 1
	hero_config[stat_key] -= 1
	stats_remaining_label.text = "Points Remaining: " + str(stat_points_to_distribute)
