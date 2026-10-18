class_name Dispatch
extends Node2D

@export var threat_req_scene: PackedScene
@onready var request_container: VBoxContainer = %RequestContainer
@onready var num_threats_label: Label = %NumThreatsLabel
@onready var threat_details_container: ThreatDetailsContainer = %ThreatDetailsContainer

var selected_threat_req: RequestInboxThreat

func _ready() -> void:
	if GameVariables.threat_request_configs.is_empty():
		GameVariables.threat_request_configs = GameVariables.generate_random_threat_requests(randi_range(3, 5))
	for config in GameVariables.threat_request_configs:
		var threat_req = threat_req_scene.instantiate() as RequestInboxThreat
		request_container.add_child(threat_req)
		threat_req.configure_from_config(config)
		var cb = Callable(self, "select_threat_req").bind(threat_req)
		threat_req.button.pressed.connect(cb)
	num_threats_label.text = str(GameVariables.threat_request_configs.size()) + " threats awaiting response"
	threat_details_container.hide()
	
func select_threat_req(req: RequestInboxThreat):
	if selected_threat_req != null:
		selected_threat_req.deselect()
	selected_threat_req = req
	selected_threat_req.select()
	threat_details_container.show()
	threat_details_container.update_selected_threat_req(selected_threat_req)
