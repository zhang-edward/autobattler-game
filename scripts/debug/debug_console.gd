extends CanvasLayer

## Tactical Debug Console
## Toggle with the "~" (backtick/quoteleft) key from anywhere in-game.
## Type `help` for a list of commands.

var panel: PanelContainer
var output: RichTextLabel
var input: LineEdit
var console_open := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_open(false)
	log_line("Tactical Debug Console ready. Type 'help' for commands.", "yellow")

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0, 240)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	output = RichTextLabel.new()
	output.bbcode_enabled = true
	output.custom_minimum_size = Vector2(0, 200)
	output.scroll_following = true
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_theme_color_override("default_color", Color.WHITE)
	vbox.add_child(output)

	input = LineEdit.new()
	input.placeholder_text = "Type a command ('help' for list)"
	input.text_submitted.connect(_on_command_submitted)
	vbox.add_child(input)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			_set_open(not console_open)
			get_viewport().set_input_as_handled()

func _set_open(open: bool) -> void:
	console_open = open
	panel.visible = open
	if open:
		input.grab_focus()
	else:
		input.release_focus()

func log_line(text: String, color: String = "white") -> void:
	if output == null:
		return
	output.append_text("[color=%s]%s[/color]\n" % [color, text])

func _on_command_submitted(text: String) -> void:
	input.clear()
	var trimmed := text.strip_edges()
	if trimmed == "":
		return
	log_line("> " + trimmed, "gray")
	_execute_command(trimmed)

func _execute_command(raw: String) -> void:
	var parts := raw.split(" ", false)
	if parts.is_empty():
		return
	var cmd := String(parts[0]).to_lower()
	var args := parts.slice(1)
	match cmd:
		"help":
			_cmd_help()
		"list", "listentities":
			_cmd_list_entities()
		"sethealth":
			_cmd_sethealth(args)
		"setbehavior":
			_cmd_setbehavior(args)
		"unlockbehavior":
			_cmd_unlockbehavior(args)
		"civilians":
			_cmd_civilians(args)
		_:
			log_line("Unknown command: '%s'. Type 'help'." % cmd, "red")

func _get_tactical_encounter() -> TacticalEncounter:
	var found := _find_tactical_encounter(get_tree().root)
	if found == null:
		log_line("No tactical encounter found in the current scene tree.", "red")
	return found

func _find_tactical_encounter(node: Node) -> TacticalEncounter:
	if node is TacticalEncounter:
		return node
	for child in node.get_children():
		var result := _find_tactical_encounter(child)
		if result != null:
			return result
	return null

func _cmd_help() -> void:
	log_line("Commands:", "yellow")
	log_line("  list", "white")
	log_line("      Lists heroes/villains/civilians with their index and current health.")
	log_line("  sethealth <target> <amount>", "white")
	log_line("      target = all | heroes | villains | civilians | hero:<i> | villain:<i> | civ:<i>")
	log_line("  setbehavior <villain_index> <hunt_hero|hunt_civilian>", "white")
	log_line("      Overrides and locks a villain's AI target until unlocked.")
	log_line("  unlockbehavior <villain_index>", "white")
	log_line("      Releases a behavior override so the AI reassigns normally again.")
	log_line("  civilians <n>", "white")
	log_line("      Sets the live civilian count, spawning or removing to match.")

func _cmd_list_entities() -> void:
	var game := _get_tactical_encounter()
	if game == null:
		return
	for i in range(game.hero_entities.size()):
		var h := game.hero_entities[i]
		if is_instance_valid(h):
			log_line("hero:%d   %s   hp=%d/%d" % [i, h.entity_config.entity_name, h.entity_config.curr_health, h.entity_config.max_health])
	for i in range(game.villain_entities.size()):
		var v := game.villain_entities[i] as VillainTacticalEntity
		if is_instance_valid(v):
			var behavior = v.villain_btree.blackboard.get_value(AssignBehavior.BEHAVIOR_KEY)
			var locked = v.villain_btree.blackboard.get_value(AssignBehavior.BEHAVIOR_LOCKED) == true
			log_line("villain:%d   %s   hp=%d/%d   behavior=%s%s" % [i, v.entity_config.entity_name, v.entity_config.curr_health, v.entity_config.max_health, str(behavior), " (locked)" if locked else ""])
	for i in range(game.civilian_entities.size()):
		var c := game.civilian_entities[i] as CivilianTacticalEntity
		if is_instance_valid(c):
			log_line("civ:%d   hp=%d/%d" % [i, int(c.health_bar.value), int(c.health_bar.max_value)])

func _cmd_sethealth(args: Array) -> void:
	if args.size() < 2:
		log_line("Usage: sethealth <target> <amount>", "red")
		return
	var target := String(args[0]).to_lower()
	if not String(args[1]).is_valid_int():
		log_line("Amount must be an integer.", "red")
		return
	var amount := int(args[1])
	var game := _get_tactical_encounter()
	if game == null:
		return

	match target:
		"all":
			_apply_health(game.hero_entities, amount)
			_apply_health(game.villain_entities, amount)
			_apply_civilian_health(game.civilian_entities, amount)
		"heroes":
			_apply_health(game.hero_entities, amount)
		"villains":
			_apply_health(game.villain_entities, amount)
		"civilians":
			_apply_civilian_health(game.civilian_entities, amount)
		_:
			var pieces := target.split(":")
			if pieces.size() != 2 or not String(pieces[1]).is_valid_int():
				log_line("Unknown target: '%s'" % target, "red")
				return
			var idx := int(pieces[1])
			match String(pieces[0]):
				"hero":
					_apply_health_single(game.hero_entities, idx, amount, false)
				"villain":
					_apply_health_single(game.villain_entities, idx, amount, false)
				"civ":
					_apply_health_single(game.civilian_entities, idx, amount, true)
				_:
					log_line("Unknown target: '%s'" % target, "red")

func _apply_health(entities: Array, amount: int) -> void:
	for e in entities:
		if is_instance_valid(e):
			_set_entity_health(e, amount)

func _apply_civilian_health(entities: Array, amount: int) -> void:
	for e in entities:
		if is_instance_valid(e):
			_set_civilian_health(e, amount)

func _apply_health_single(entities: Array, idx: int, amount: int, is_civilian: bool) -> void:
	if idx < 0 or idx >= entities.size() or not is_instance_valid(entities[idx]):
		log_line("No entity at index %d" % idx, "red")
		return
	if is_civilian:
		_set_civilian_health(entities[idx], amount)
	else:
		_set_entity_health(entities[idx], amount)

func _set_entity_health(entity: TacticalEntity, amount: int) -> void:
	var ec := entity.entity_config
	ec.curr_health = clampi(amount, 0, ec.max_health)
	entity.refresh_health_bar()
	log_line("Set %s health to %d/%d" % [ec.entity_name, ec.curr_health, ec.max_health], "green")
	if ec.curr_health <= 0:
		entity.defeat()

func _set_civilian_health(civ: CivilianTacticalEntity, amount: int) -> void:
	var max_hp := int(civ.health_bar.max_value)
	civ.health_bar.value = clampi(amount, 0, max_hp)
	log_line("Set civilian health to %d/%d" % [int(civ.health_bar.value), max_hp], "green")
	if civ.health_bar.value <= 0:
		civ.die()

func _cmd_setbehavior(args: Array) -> void:
	if args.size() < 2:
		log_line("Usage: setbehavior <villain_index> <hunt_hero|hunt_civilian>", "red")
		return
	if not String(args[0]).is_valid_int():
		log_line("Villain index must be an integer.", "red")
		return
	var idx := int(args[0])
	var behavior := String(args[1]).to_lower()
	if behavior != AssignBehavior.HUNT_HERO and behavior != AssignBehavior.HUNT_CIVILIAN:
		log_line("Behavior must be 'hunt_hero' or 'hunt_civilian'.", "red")
		return
	var game := _get_tactical_encounter()
	if game == null:
		return
	if idx < 0 or idx >= game.villain_entities.size() or not is_instance_valid(game.villain_entities[idx]):
		log_line("No villain at index %d" % idx, "red")
		return
	var villain := game.villain_entities[idx] as VillainTacticalEntity
	var bb := villain.villain_btree.blackboard
	bb.set_value(AssignBehavior.BEHAVIOR_KEY, behavior)
	bb.set_value(AssignBehavior.BEHAVIOR_UPDATED_TS, Time.get_ticks_msec())
	bb.set_value(AssignBehavior.BEHAVIOR_LOCKED, true)
	# Beehave's Selector/Sequence composites remember which branch was
	# running and skip re-checking earlier siblings' conditions on later
	# ticks. Without this, the blackboard value changes but the villain
	# stays stuck in whatever branch it was already running. Interrupting
	# the tree clears that memory so it fully re-evaluates from root next tick.
	villain.villain_btree.interrupt()
	log_line("villain:%d behavior locked to '%s'" % [idx, behavior], "green")

func _cmd_unlockbehavior(args: Array) -> void:
	if args.size() < 1 or not String(args[0]).is_valid_int():
		log_line("Usage: unlockbehavior <villain_index>", "red")
		return
	var idx := int(args[0])
	var game := _get_tactical_encounter()
	if game == null:
		return
	if idx < 0 or idx >= game.villain_entities.size() or not is_instance_valid(game.villain_entities[idx]):
		log_line("No villain at index %d" % idx, "red")
		return
	var villain := game.villain_entities[idx] as VillainTacticalEntity
	var bb := villain.villain_btree.blackboard
	bb.set_value(AssignBehavior.BEHAVIOR_LOCKED, false)
	# Clear the assigned behavior outright rather than waiting on the TTL,
	# since RootSequence's own composite memory means AssignBehavior may not
	# get ticked again until something resets the tree anyway (see setbehavior).
	bb.set_value(AssignBehavior.BEHAVIOR_KEY, null)
	villain.villain_btree.interrupt()
	log_line("villain:%d behavior unlocked; AI will reassign next tick" % idx, "green")

func _cmd_civilians(args: Array) -> void:
	if args.size() < 1 or not String(args[0]).is_valid_int():
		log_line("Usage: civilians <n>", "red")
		return
	var n := int(args[0])
	var game := _get_tactical_encounter()
	if game == null:
		return
	game.debug_set_civilian_count(n)
	log_line("Civilian count set to %d" % n, "green")
