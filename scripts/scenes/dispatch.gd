class_name Dispatch
extends Node2D

@export var threat_req_scene: PackedScene
@onready var request_container: VBoxContainer = %RequestContainer
@onready var num_threats_label: Label = %NumThreatsLabel
@onready var threat_details_container: ThreatDetailsContainer = %ThreatDetailsContainer
@onready var sidebar_menu: SidebarMenu = %SidebarMenu

var selected_threat_req: RequestInboxThreat

func _ready() -> void:
	threat_details_container.hide()
	update_threat_requests()
	sidebar_menu.select_option(sidebar_menu.request_inbox_option)
	sidebar_menu.on_advance_day.connect(update_threat_requests)
	
func update_threat_requests():
	if GameVariables.threat_request_configs.is_empty():
		GameVariables.threat_request_configs = GameVariables.generate_random_threat_requests(randi_range(3, 5))
	for c in request_container.get_children():
		c.queue_free()
	for config in GameVariables.threat_request_configs:
		var threat_req = threat_req_scene.instantiate() as RequestInboxThreat
		request_container.add_child(threat_req)
		threat_req.configure_from_config(config)
		threat_req.button.pressed.connect(select_threat_req.bind(threat_req))
	num_threats_label.text = str(GameVariables.threat_request_configs.size()) + " threats awaiting response"	
	
func select_threat_req(req: RequestInboxThreat):
	if selected_threat_req != null:
		selected_threat_req.deselect()
	selected_threat_req = req
	selected_threat_req.select()
	threat_details_container.show()
	threat_details_container.update_selected_threat_req(selected_threat_req)
