class_name ThreatDetailsContainer
extends MarginContainer

@onready var headline: RichTextLabel = %Headline
@onready var description: RichTextLabel = %Description
@onready var threat_type: Label = %TypeValue
@onready var exp_reward: Label = %ExpRewardValue
@onready var money: Label = %MoneyRewardValue
@onready var renown: Label = %RenownRewardValue
@onready var threat_label: ThreatLabel = %ThreatLabel

func update_selected_threat_req(req: RequestInboxThreat):
	var threat_request_config = req.config
	headline.text = threat_request_config.title
	description.text = threat_request_config.description
	threat_label.configure(threat_request_config.threat_type)
