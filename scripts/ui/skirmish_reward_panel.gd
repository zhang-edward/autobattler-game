class_name SkirmishRewardPanel
extends PanelContainer

@onready var reward_name: Label = %Name
@onready var value: Label = %Value

func setup_reward(n: String, amt: int):
	reward_name.text = n
	value.text = "+" + str(amt)
