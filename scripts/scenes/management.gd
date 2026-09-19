class_name Management
extends Node2D

@export var lineup_hero_scene: PackedScene
@export var reserve_row_scene: PackedScene
@onready var lineup_container: HBoxContainer = %LineupContainer
@onready var reserve_container: VBoxContainer = %ReserveContainer
