class_name Management
extends Node2D

@export var lineup_hero_scene: PackedScene
@export var reserve_row_scene: PackedScene
@onready var lineup_container: HBoxContainer = %LineupContainer
@onready var reserves_container: VBoxContainer = %ReservesContainer
@onready var recruits_container: VBoxContainer = %RecruitsContainer
@onready var money_label: Label = %Money
@onready var top_nav_bar: TopNavBar = %TopNavBar

var selected_reserve_row: ReserveRow = null

func _ready() -> void:
	var hero_starting_lineup = GameVariables.player_lineup
	if hero_starting_lineup.is_empty():
		hero_starting_lineup = GameVariables.generate_random_entity_configs(5, EntityConfig.EntityType.HERO)
	var all_prospects = GameVariables.captured_villain_prospects + GameVariables.civilian_hero_prospects
	for ec in hero_starting_lineup:
		var entity_config = ec as EntityConfig
		var lineup_hero = lineup_hero_scene.instantiate() as LineupHero
		lineup_container.add_child(lineup_hero)
		lineup_hero.setup(entity_config)
		lineup_hero.on_select.connect(move_reserve_into_lineup)
	for ec in GameVariables.player_reserves:
		var entity_config = ec as EntityConfig
		var reserve_row = add_reserve_row_entity_config(ec, reserves_container)
		reserve_row.on_select.connect(select_reserve)
	for prospect in all_prospects:
		var reserve_row = add_reserve_row_prospect(prospect, recruits_container)
		reserve_row.on_recruit.connect(recruit_entity)
		
func recruit_entity(row: ReserveRow):
	var entity_config = row.entity_config
	if entity_config.recruit_cost <= GameVariables.money:
		GameVariables.money -= entity_config.recruit_cost
		money_label.text = "$" + str(GameVariables.money)
		entity_config.recruit_cost = -1
		row.is_recruitable = false
		row.setup(entity_config)
		recruits_container.remove_child(row)
		reserves_container.add_child(row)
		
func select_reserve(row: ReserveRow):
	if selected_reserve_row != null:
		selected_reserve_row.dehighlight()
	selected_reserve_row = row
	row.highlight()
	
func move_reserve_into_lineup(lineup_hero: LineupHero):
	if selected_reserve_row != null:
		var lh_ec = lineup_hero.entity_config
		lineup_hero.setup(selected_reserve_row.entity_config)
		selected_reserve_row.setup(lh_ec)
		selected_reserve_row.dehighlight()
		selected_reserve_row = null

func add_reserve_row_entity_config(e: EntityConfig, container: VBoxContainer):
	var reserve_row = reserve_row_scene.instantiate() as ReserveRow
	container.add_child(reserve_row)
	reserve_row.setup_entity_config(e)
	return reserve_row
	
func add_reserve_row_prospect(p: Prospect, container: VBoxContainer):
	var reserve_row = reserve_row_scene.instantiate() as ReserveRow
	container.add_child(reserve_row)
	reserve_row.setup_prospect(p)
	return reserve_row
