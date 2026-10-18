class_name RequestInboxThreat
extends PanelContainer

@onready var threat_name: Label = %ThreatName
@onready var exp_details: Label = %ExpirationDetails
@onready var lvl_req: Label = %LvlReq
@onready var threat_label: ThreatLabel = %ThreatLabel
@onready var button: Button = $Button

var config: ThreatRequestConfig

func configure_from_config(threat_req_config: ThreatRequestConfig):
	config = threat_req_config
	threat_name.text = threat_req_config.title
	exp_details.text = "Expires in " + str(threat_req_config.expiry_days) + " days"
	lvl_req.text = "Lv. " + str(threat_req_config.level_requirement)
	threat_label.configure(threat_req_config.threat_type)

func deselect():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/req_inbox_stylebox.tres"))
	
func select():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/req_inbox_selected_stylebox.tres"))
