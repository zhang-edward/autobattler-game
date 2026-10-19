class_name ThreatDetailsContainer
extends MarginContainer

@onready var headline: RichTextLabel = %Headline
@onready var description: RichTextLabel = %Description
@onready var threat_type: Label = %TypeValue
@onready var exp_reward: Label = %ExpRewardValue
@onready var money: Label = %MoneyRewardValue
@onready var renown: Label = %RenownRewardValue
@onready var threat_label: ThreatLabel = %ThreatLabel
@onready var assign_heroes_button: Button = %AssignHeroesButton

var config: ThreatRequestConfig

func _ready() -> void:
	assign_heroes_button.pressed.connect(go_to_assign_heroes_scene)
	
func go_to_assign_heroes_scene():
	GameVariables.selected_threat_request_config = config
	get_tree().change_scene_to_file("res://scenes/assign_heroes.tscn")

func update_selected_threat_req(req: RequestInboxThreat):
	config = req.config
	headline.text = config.title
	description.text = config.description
	threat_label.configure(config.threat_type)
