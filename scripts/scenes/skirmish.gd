class_name Skirmish
extends Node2D

## One round between two teams. Each team has its lead on the field and the
## rest on the bench, ready to tag in. Side A is the player's (left), side B
## the opponent's (right). Each team shares one health bar and one block bar;
## the round ends when a team's health is empty.
##
## Note: inside this file, always write the enum as `Skirmish.Side`, not
## `Side`. Skirmish and SkirmishEntity reference each other, and GDScript
## then treats the short and long names as different types.

signal finished(winner: Skirmish.Side)

enum Side { A, B }

const SIDE_A_START := Vector2(400.0, 700.0)
const SIDE_B_START := Vector2(1400.0, 700.0)
# Benched heroes wait off-screen below the arena.
const SIDE_A_BENCH := Vector2(400.0, 1200.0)
const SIDE_B_BENCH := Vector2(1400.0, 1200.0)
# Delay between the deciding hit and `finished`, so the body can land and fade first
const OUTRO_SECONDS := 1.5
const STATUS_ROW := preload("res://prefabs/ui/skirmish/skirmish_status_row.tscn")
# Level range for the random heroes used when the scene runs on its own.
const DEBUG_LEVEL_RANGE := Vector2i(1, 6)

const HEALTH_BAR_BG := preload("res://prefabs/styles/health_bar_bg.tres")
const SIDE_A_HEALTH_FILL := preload("res://prefabs/styles/hero_health_bar.tres")
const SIDE_B_HEALTH_FILL := preload("res://prefabs/styles/villain_health_bar.tres")
const BLOCK_BAR_COLOR := Color(0.35, 0.65, 1.0)
const BLOCK_BAR_BROKEN_TINT := Color(0.45, 0.45, 0.45)
const SUPER_BAR_COLOR := Color(1.0, 0.8, 0.25)
const SUPER_READY_PULSE := Color(1.4, 1.3, 0.8)
# The super announcement: camera zoom on the hero and a big banner
const SUPER_BANNER_SECONDS := 0.9
const SUPER_CAMERA_ZOOM := 1.35
const SUPER_BANNER_TOP := 215.0

# TUNE: tag assists, fired by the hero who tags in.
# Heal: share of the team's max health restored.
const ASSIST_HEAL_FRACTION := 0.08
# Strike Boost: the incoming hero hits this much harder for this long.
const STRIKE_BOOST_DAMAGE := 1.3
const STRIKE_BOOST_SECONDS := 6.0
# Guard Boost refills the block bar (and fixes a broken guard), then blocked
# hits drain this much less for this long.
const GUARD_BOOST_DRAIN := 0.5
const GUARD_BOOST_SECONDS := 6.0
const HEAL_COLOR := Color(0.35, 1.0, 0.45)
const HEAL_POPUP_OFFSET := Vector2(0.0, -200.0)
const ASSIST_LINES := {
	Hero.Assist.HEAL: "I'll patch you up!",
	Hero.Assist.STRIKE_BOOST: "Let's hit harder!",
	Hero.Assist.GUARD_BOOST: "Shields up!",
}
# AI supers that need range wait until the target is this close (horizontally).
const AI_SUPER_RANGE := {
	Hero.PowerType.ELEMENTAL: 900.0,
	Hero.PowerType.PHYSICAL: 450.0,
}

# Wall layout, authored at this resolution and scaled to the current viewport
const WALL_BASE_SIZE := Vector2(1920.0, 1080.0)
const SIDE_WALL_THICKNESS := 80.0
const BOTTOM_WALL_CENTER_Y := 1000.0
const BOTTOM_WALL_HEIGHT := 136.375
# The top wall's lower edge sits on the horizon (see Background/Ground band fractions)
const TOP_WALL_CENTER_Y := 150.0
const TOP_WALL_HEIGHT := 320.0
const TOP_WALL_SIDE_INSET := 15.0

@export var entity_scene: PackedScene

@export_group("Standalone testing")
## Heroes per side when the scene runs on its own (lead + tag-ins).
@export_range(1, 4) var debug_team_size := 2

@export_group("UI Elements")
@export var tag_in_button_scene: PackedScene

## Every hero on each side, lead first.
var team_a: Array[SkirmishEntity] = []
var team_b: Array[SkirmishEntity] = []
var _active := {Skirmish.Side.A: null, Skirmish.Side.B: null}
var _finished := false
var _status_rows: Array[SkirmishStatusRow] = []
var _lineup_a: Array[Hero] = []
var _lineup_b: Array[Hero] = []
var _has_lineups := false
var _auto_tag_side_a := false
## Each side's shared bars, and the HUD bars showing them.
var _team_health := {}
var _block_bars := {}
var _health_views := {}
var _block_bar_views := {}
var _meters := {}
var _meter_views := {}
## Supers asked for (by the player's button) and waiting for the hero to be free.
var _super_requested := {Skirmish.Side.A: false, Skirmish.Side.B: false}
var _super_playing := false
var _super_button: Button
var _super_banner: VBoxContainer
var _super_banner_title: Label
var _super_banner_hero: Label

@onready var director: TagDirector = $TagDirector

@onready var _left_wall: StaticBody2D = $VWall
@onready var _right_wall: StaticBody2D = $VWall2
@onready var _bottom_wall: StaticBody2D = $HWall
@onready var _top_wall: StaticBody2D = $HWall2

@onready var tag_in_buttons: HBoxContainer = %TagInButtons
@onready var special_moves: HBoxContainer = %SpecialMoves
@onready var _combo_counters := {
	Skirmish.Side.A: %SideAComboCounter as ComboCounter,
	Skirmish.Side.B: %SideBComboCounter as ComboCounter,
}


## Call before adding the scene to the tree. Each lineup is lead first, then
## the tag-ins. Without it, the scene makes random debug teams. The opponent
## (side B) always tags on its own; set `auto_tag_side_a` for the player's
## side to as well (the Skirmish Runner does).
func configure(lineup_a: Array[Hero], lineup_b: Array[Hero], auto_tag_side_a := false) -> void:
	_lineup_a = lineup_a
	_lineup_b = lineup_b
	_auto_tag_side_a = auto_tag_side_a
	_has_lineups = true


static func other_side(side: Skirmish.Side) -> Skirmish.Side:
	return Skirmish.Side.B if side == Skirmish.Side.A else Skirmish.Side.A


static func start_for(side: Skirmish.Side) -> Vector2:
	return SIDE_A_START if side == Skirmish.Side.A else SIDE_B_START


static func bench_for(side: Skirmish.Side) -> Vector2:
	return SIDE_A_BENCH if side == Skirmish.Side.A else SIDE_B_BENCH


## Which way a tag-in runs on from: each side enters from its own edge.
static func entry_direction(side: Skirmish.Side) -> float:
	return -1.0 if side == Skirmish.Side.A else 1.0


func _ready() -> void:
	get_viewport().size_changed.connect(_update_walls)
	_update_walls()
	if not _has_lineups:
		print("[WARN] Skirmish not configured - using random debug teams...")
		_make_debug_lineups()
	team_a = _spawn_team(_lineup_a, Skirmish.Side.A)
	team_b = _spawn_team(_lineup_b, Skirmish.Side.B)
	for side: Skirmish.Side in [Skirmish.Side.A, Skirmish.Side.B]:
		_team_health[side] = TeamHealth.create(_total_health(team_for(side)))
		_block_bars[side] = BlockBar.create(CombatStats.block_bar_size(_average_defense(team_for(side))))
		_meters[side] = SuperMeter.new()
	var auto_tag: Array[Skirmish.Side] = [Skirmish.Side.B]
	if _auto_tag_side_a:
		auto_tag.append(Skirmish.Side.A)
	director.set_auto_tag_sides(auto_tag)
	_build_status_rows()
	_build_tag_in_buttons()
	_build_super_button()


func _exit_tree() -> void:
	get_tree().paused = false


func _process(delta: float) -> void:
	for side: Skirmish.Side in _block_bars:
		var bar: BlockBar = _block_bars[side]
		if not _finished:
			bar.tick(delta)
		var block_view: ProgressBar = _block_bar_views[side]
		block_view.max_value = bar.max_value
		block_view.value = bar.value
		block_view.modulate = BLOCK_BAR_BROKEN_TINT if bar.is_broken else Color.WHITE
		var health: TeamHealth = _team_health[side]
		var health_view: ProgressBar = _health_views[side]
		health_view.max_value = health.max_value
		health_view.value = health.value
		var meter: SuperMeter = _meters[side]
		var meter_view: ProgressBar = _meter_views[side]
		meter_view.max_value = SuperMeter.MAX_VALUE
		meter_view.value = meter.value
		meter_view.modulate = SUPER_READY_PULSE if meter.is_full() else Color.WHITE
	_process_supers()
	_refresh_super_button()
	for row in _status_rows:
		row.set_active_highlight(is_instance_valid(row.entity) and row.entity.is_active and not row.entity.is_dead)
	for button: TagInButton in tag_in_buttons.get_children():
		var hero := button.hero_to_switch_to
		button.visible = not _finished and is_instance_valid(hero) and not hero.is_dead and not hero.is_active
		# Clickable whenever no tag is already on its way. If the hero on the
		# field is busy, the tag queues and happens as soon as they're free.
		button.button.disabled = director.is_busy() or not can_request_tag(Skirmish.Side.A, hero)

	var sorted := $Battlefield.get_children()
	sorted.sort_custom(func(a, b): return a.position.y < b.position.y)
	for i in sorted.size():
		sorted[i].z_index = (i + 1) * 4


func _make_debug_lineups() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var used_names := {}
	for lineup in [_lineup_a, _lineup_b]:
		for i in debug_team_size:
			var level := rng.randi_range(DEBUG_LEVEL_RANGE.x, DEBUG_LEVEL_RANGE.y)
			lineup.append(LeagueGenerator.generate_hero_at_level(rng, level, used_names))


# Re-fits the four boundary walls to the current viewport so they stay on the screen edges
func _update_walls() -> void:
	var vp := get_viewport_rect().size
	var scale_y := vp.y / WALL_BASE_SIZE.y
	_place_wall(_left_wall, Vector2(0.0, vp.y * 0.5), Vector2(SIDE_WALL_THICKNESS, vp.y))
	_place_wall(_right_wall, Vector2(vp.x, vp.y * 0.5), Vector2(SIDE_WALL_THICKNESS, vp.y))
	_place_wall(_bottom_wall, Vector2(vp.x * 0.5, BOTTOM_WALL_CENTER_Y * scale_y), Vector2(vp.x, BOTTOM_WALL_HEIGHT * scale_y))
	_place_wall(_top_wall, Vector2(vp.x * 0.5, TOP_WALL_CENTER_Y * scale_y), Vector2(vp.x - TOP_WALL_SIDE_INSET * 2.0, TOP_WALL_HEIGHT * scale_y))


# Centres the wall's body on `center` and sizes its rectangle collider to `size`
func _place_wall(wall: StaticBody2D, center: Vector2, size: Vector2) -> void:
	wall.position = center
	var collider := wall.get_node("CollisionShape2D") as CollisionShape2D
	collider.position = Vector2.ZERO
	(collider.shape as RectangleShape2D).size = size


# ----- teams -----

func team_for(side: Skirmish.Side) -> Array[SkirmishEntity]:
	return team_a if side == Skirmish.Side.A else team_b


func all_entities() -> Array[SkirmishEntity]:
	return team_a + team_b


func is_finished() -> bool:
	return _finished


func health_for(side: Skirmish.Side) -> TeamHealth:
	return _team_health.get(side)


func block_bar_for(side: Skirmish.Side) -> BlockBar:
	return _block_bars.get(side)


## Takes `amount` off `side`'s health. Returns true if that emptied it,
## which ends the round.
func deal_team_damage(side: Skirmish.Side, amount: int) -> bool:
	if _finished:
		return false
	var emptied := health_for(side).take(amount)
	if emptied:
		_finish(other_side(side))
	return emptied


func _total_health(team: Array[SkirmishEntity]) -> int:
	var total := 0
	for e in team:
		total += e.entity_config.get_max_health()
	return total


func _average_defense(team: Array[SkirmishEntity]) -> float:
	if team.is_empty():
		return 0.0
	var total := 0
	for e in team:
		total += e.entity_config.defense
	return float(total) / team.size()


## The hero on the field for `side`.
func active_for(side: Skirmish.Side) -> SkirmishEntity:
	return _active[side]


## Records who's on the field after a tag.
func swap_refs(side: Skirmish.Side, incoming: SkirmishEntity) -> void:
	_active[side] = incoming


## Whether a tag to `incoming` can be asked for: they're on `side`'s bench
## and the round isn't over. The tag itself waits until can_tag().
func can_request_tag(side: Skirmish.Side, incoming: SkirmishEntity) -> bool:
	return not _finished and incoming != null and is_instance_valid(incoming) \
		and not incoming.is_dead and not incoming.is_active and team_for(side).has(incoming)


## Whether `incoming` can tag in for `side` right now: they're benched, and
## whoever is on the field is free (see SkirmishEntity.can_tag_out).
func can_tag(side: Skirmish.Side, incoming: SkirmishEntity) -> bool:
	if not can_request_tag(side, incoming):
		return false
	var current := active_for(side)
	if current != null and is_instance_valid(current):
		if current.is_dead or current.state_machine == null or not current.can_tag_out():
			return false
	return true


func _spawn_team(lineup: Array[Hero], side: Skirmish.Side) -> Array[SkirmishEntity]:
	var battlefield := $Battlefield as Node2D
	var team: Array[SkirmishEntity] = []
	for i in lineup.size():
		var config := EntityConfig.from_hero(lineup[i])
		config.reset_all_in_round_vars()
		var entity := entity_scene.instantiate() as SkirmishEntity
		entity.name = config.entity_name
		entity.skirmish = self
		battlefield.add_child(entity)
		entity.configure_from_entity_config(config, side)
		entity.character_moment_rolled.connect(_play_character_moment.bind(entity))
		entity.took_hit.connect(_on_entity_took_hit.bind(entity))
		entity.combo_ended.connect(_on_entity_combo_ended.bind(entity))
		# The lead starts on the field; everyone else waits on the bench.
		if i == 0:
			entity.position = start_for(side)
			entity.set_active(true)
			_active[side] = entity
		else:
			entity.position = bench_for(side)
			entity.set_active(false)
		team.append(entity)
	return team


# ----- UI -----

## Each side's HUD: team health, team block bar, then a row per hero.
func _build_status_rows() -> void:
	for side: Skirmish.Side in [Skirmish.Side.A, Skirmish.Side.B]:
		var container := (%SideAStatuses if side == Skirmish.Side.A else %SideBStatuses) as VBoxContainer
		var health_fill := SIDE_A_HEALTH_FILL if side == Skirmish.Side.A else SIDE_B_HEALTH_FILL
		_health_views[side] = _add_bar_view(container, "Health", health_fill, 16.0)
		var block_fill := StyleBoxFlat.new()
		block_fill.bg_color = BLOCK_BAR_COLOR
		_block_bar_views[side] = _add_bar_view(container, "Block", block_fill, 10.0)
		var super_fill := StyleBoxFlat.new()
		super_fill.bg_color = SUPER_BAR_COLOR
		_meter_views[side] = _add_bar_view(container, "Super", super_fill, 10.0)
		for entity in team_for(side):
			var row := STATUS_ROW.instantiate() as SkirmishStatusRow
			container.add_child(row)
			row.configure(entity)
			_status_rows.append(row)


func _add_bar_view(container: VBoxContainer, title: String, fill: StyleBox, height: float) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 150.0
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(180.0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", HEALTH_BAR_BG)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	container.add_child(row)
	return bar


## One tag-in button per side-A hero. Only benched heroes' buttons show.
func _build_tag_in_buttons() -> void:
	for entity in team_a:
		var button := tag_in_button_scene.instantiate() as TagInButton
		tag_in_buttons.add_child(button)
		button.init(entity)
		button.on_click.connect(_on_tag_in_pressed)


func _on_tag_in_pressed(entity: SkirmishEntity) -> void:
	if director.is_busy() or not can_request_tag(Skirmish.Side.A, entity):
		return
	director.request_manual_tag(Skirmish.Side.A, entity)


# ----- supers -----

func meter_for(side: Skirmish.Side) -> SuperMeter:
	return _meters.get(side)


func add_meter(side: Skirmish.Side, amount: float) -> void:
	if not _finished and _meters.has(side):
		meter_for(side).add(amount)


## Whether `side` can fire its super right now: the meter is full, nothing
## else is playing, and the hero on the field is free.
func can_super(side: Skirmish.Side) -> bool:
	if _finished or _super_playing or director.is_busy() or not meter_for(side).is_full():
		return false
	var hero := active_for(side)
	return hero != null and is_instance_valid(hero) and hero.can_start_super()


## The player asks for a super. It fires as soon as the hero is free.
func request_super(side: Skirmish.Side) -> void:
	if meter_for(side).is_full():
		_super_requested[side] = true


func _process_supers() -> void:
	for side: Skirmish.Side in [Skirmish.Side.A, Skirmish.Side.B]:
		var wants: bool = _super_requested[side] \
			or (director.auto_tag_sides.has(side) and _ai_wants_super(side))
		if wants and can_super(side):
			_super_requested[side] = false
			_play_super(side)
			return


## AI sides fire as soon as the meter is full, except ranged supers, which
## wait until the opponent is lined up and close enough.
func _ai_wants_super(side: Skirmish.Side) -> bool:
	if not meter_for(side).is_full():
		return false
	var hero := active_for(side)
	var target := active_for(other_side(side))
	if hero == null or target == null or not is_instance_valid(target) or target.is_dead:
		return false
	var power_type := hero.entity_config.power_type
	if power_type == Hero.PowerType.TRANSFORMATION:
		return true
	# Attacking supers wait for a target that can be hit (not mid get-up)
	if not target.hurtbox.monitorable:
		return false
	if not AI_SUPER_RANGE.has(power_type):
		return true
	var gap := target.position - hero.position
	return absf(gap.x) <= AI_SUPER_RANGE[power_type] and absf(gap.y) <= IsometryUtils.Y_AXIS_HIT_RANGE


## The super's cutscene (the hero calls its name), then the super itself.
func _play_super(side: Skirmish.Side) -> void:
	var hero := active_for(side)
	_super_playing = true
	meter_for(side).spend()
	# Holds tags off while the cutscene plays
	director.is_playing = true
	await director.cutscene.darken_screen(hero.position + Vector2(0.0, -130.0), [hero])
	director.cutscene.focus(hero.position + Vector2(0.0, -120.0), SUPER_CAMERA_ZOOM)
	_super_banner_title.text = hero.entity_config.super_name().to_upper() + "!"
	_super_banner_hero.text = hero.entity_config.entity_name
	_super_banner.show()
	await get_tree().create_timer(SUPER_BANNER_SECONDS).timeout
	_super_banner.hide()
	await director.cutscene.release()
	director.is_playing = false
	_super_playing = false
	if not _finished and is_instance_valid(hero) and hero.is_active and not hero.is_dead:
		hero.state_machine.transition_to(hero.super_state)


func _build_super_button() -> void:
	_build_super_banner()
	_super_button = Button.new()
	_super_button.custom_minimum_size = Vector2(240.0, 82.0)
	_super_button.add_theme_font_size_override("font_size", 20)
	_super_button.pressed.connect(request_super.bind(Skirmish.Side.A))
	special_moves.add_child(_super_button)


## Big gold "NOVA BEAM!" with the hero's name under it, shown while a super
## is announced.
func _build_super_banner() -> void:
	_super_banner = VBoxContainer.new()
	_super_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_super_banner.offset_top = SUPER_BANNER_TOP
	_super_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	_super_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_super_banner_title = _banner_label(84, SUPER_BAR_COLOR)
	_super_banner_hero = _banner_label(32, Color.WHITE)
	_super_banner.add_child(_super_banner_title)
	_super_banner.add_child(_super_banner_hero)
	_super_banner.hide()
	$HUD/Root.add_child(_super_banner)


func _banner_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", maxi(font_size / 6, 6))
	return label


func _refresh_super_button() -> void:
	var hero := active_for(Skirmish.Side.A)
	var super_name := hero.entity_config.super_name() if hero != null and is_instance_valid(hero) else ""
	var full := meter_for(Skirmish.Side.A).is_full()
	_super_button.visible = not _finished
	_super_button.disabled = not full or _super_requested[Skirmish.Side.A] or _super_playing
	if _super_requested[Skirmish.Side.A]:
		_super_button.text = "SUPER\n%s (ready next)" % super_name
	else:
		_super_button.text = "SUPER\n%s" % super_name
	_super_button.modulate = SUPER_READY_PULSE if full else Color.WHITE


# ----- assists -----

static func assist_line(assist: Hero.Assist) -> String:
	return ASSIST_LINES[assist]


## Fires the assist of a hero who just tagged in.
func apply_assist(hero: SkirmishEntity) -> void:
	if _finished or hero == null or not is_instance_valid(hero):
		return
	match hero.entity_config.assist:
		Hero.Assist.HEAL:
			heal_team(hero, roundi(health_for(hero.side).max_value * ASSIST_HEAL_FRACTION))
		Hero.Assist.STRIKE_BOOST:
			hero.entity_config.add_boost("strike_boost", STRIKE_BOOST_SECONDS, STRIKE_BOOST_DAMAGE)
		Hero.Assist.GUARD_BOOST:
			block_bar_for(hero.side).refill()
			hero.entity_config.add_boost("guard_boost", GUARD_BOOST_SECONDS, 1.0, 1.0, 1.0, GUARD_BOOST_DRAIN)


## Heals `hero`'s team and pops the amount healed over them in green.
func heal_team(hero: SkirmishEntity, amount: int) -> void:
	var health := health_for(hero.side)
	var before := health.value
	health.heal(amount)
	var healed := health.value - before
	if healed > 0:
		EffectManager.spawn_popup(hero.global_position + Vector2(0.0, hero.z) + HEAL_POPUP_OFFSET, "+%d" % healed, HEAL_COLOR)


# ----- fight events -----

func _on_entity_took_hit(combo_hits: int, is_punish: bool, entity: SkirmishEntity) -> void:
	# The combo belongs to the attacking side.
	var counter: ComboCounter = _combo_counters[other_side(entity.side)]
	if combo_hits >= 2:
		counter.show_hits(combo_hits)
	if is_punish:
		counter.show_punish()


func _on_entity_combo_ended(entity: SkirmishEntity) -> void:
	(_combo_counters[other_side(entity.side)] as ComboCounter).end_combo()


func _play_character_moment(entity: SkirmishEntity) -> void:
	if _finished or director.is_playing:
		return
	await director.cutscene.darken_screen(entity.position, [entity])
	director.cutscene.speak(entity, "I won't give up!")
	ScreenShake.shake_horizontal(8.0, 1)
	await director.cutscene.character_moment(entity)
	await director.cutscene.release()


func _finish(winner: Skirmish.Side) -> void:
	if _finished:
		return
	_finished = true
	# Short delay before running finish logic
	await get_tree().create_timer(OUTRO_SECONDS).timeout
	finished.emit(winner)
