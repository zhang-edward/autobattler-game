class_name ThreatDetailsContainer
extends MarginContainer

@export var enemy_preview_scene: PackedScene

@onready var headline: RichTextLabel = %Headline
@onready var description: RichTextLabel = %Description
@onready var threat_type: Label = %TypeValue
@onready var exp_reward: Label = %ExpRewardValue
@onready var threat_label: ThreatLabel = %ThreatLabel
@onready var action_button: Button = %ActionButton
@onready var villain_previews: VBoxContainer = %VillainPreviews

var config: ThreatRequestConfig

signal on_action_pressed()

func _ready() -> void:
	action_button.pressed.connect(func(): on_action_pressed.emit())

func update_selected_threat_req(threat_req_config: ThreatRequestConfig):
	config = threat_req_config
	headline.text = config.title
	description.text = config.description
	exp_reward.text = str(config.reward.exp_gain) + " XP"
	threat_label.configure(config.threat_type)
	for c in villain_previews.get_children():
		c.queue_free()
	for enemy_config in config.enemy_configs:
		var enemy_preview = enemy_preview_scene.instantiate() as EnemyPreview
		villain_previews.add_child(enemy_preview)
		enemy_preview.configure(enemy_config)
		enemy_preview.special_moves_label.hide()
		enemy_preview.stat_grid.hide()
