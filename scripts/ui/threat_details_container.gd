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

func _ready() -> void:
	assign_heroes_button.pressed.connect(go_to_assign_heroes_scene)
	
func go_to_assign_heroes_scene():
	get_tree().change_scene_to_file("res://scenes/assign_heroes.tscn")

func update_selected_threat_req(req: RequestInboxThreat):
	var threat_request_config = req.config
	headline.text = threat_request_config.title
	description.text = threat_request_config.description
	threat_label.configure(threat_request_config.threat_type)
