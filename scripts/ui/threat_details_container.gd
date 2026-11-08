class_name ThreatDetailsContainer
extends MarginContainer

@export var enemy_preview_scene: PackedScene

@onready var headline: RichTextLabel = %Headline
@onready var description: RichTextLabel = %Description
@onready var threat_type: Label = %TypeValue
@onready var exp_reward: Label = %ExpRewardValue
@onready var money: Label = %MoneyRewardValue
@onready var renown: Label = %RenownRewardValue
@onready var threat_label: ThreatLabel = %ThreatLabel
@onready var assign_heroes_button: Button = %AssignHeroesButton
@onready var villain_previews: VBoxContainer = %VillainPreviews

var config: ThreatRequestConfig

func _ready() -> void:
	assign_heroes_button.pressed.connect(go_to_assign_heroes_scene)
	
func go_to_assign_heroes_scene():
	GameVariables.curr_threat_skirmish = ThreatSkirmish.new(config)
	get_tree().change_scene_to_file("res://scenes/assign_heroes.tscn")

func update_selected_threat_req(req: RequestInboxThreat):
	config = req.config
	headline.text = config.title
	description.text = config.description
	exp_reward.text = str(config.reward.exp_gain) + " XP"
	money.text = "$" + str(config.reward.money)
	renown.text = str(config.reward.renown)
	threat_label.configure(config.threat_type)
	for c in villain_previews.get_children():
		c.queue_free()
	for enemy_config in config.enemy_configs:
		var enemy_preview = enemy_preview_scene.instantiate() as EnemyPreview
		villain_previews.add_child(enemy_preview)
		enemy_preview.configure(enemy_config)
		enemy_preview.special_moves_label.hide()
		enemy_preview.stat_grid.hide()
