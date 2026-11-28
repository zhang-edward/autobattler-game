class_name BoostIcon
extends Node2D

## A round badge shown over a hero's head while a boost is active: a sword
## for Strike Boost, a shield for Guard Boost, a star for Power Up. The ring
## around it empties as the boost runs out.

const RADIUS := 16.0
const RING_WIDTH := 3.0
const STYLES := {
	"strike_boost": {"color": Color(0.95, 0.45, 0.15), "icon": "sword"},
	"guard_boost": {"color": Color(0.25, 0.55, 1.0), "icon": "shield"},
	"power_up": {"color": Color(0.85, 0.6, 0.1), "icon": "star"},
	"heal": {"color": Color(0.25, 0.75, 0.35), "icon": "cross"},
}
## The icon for each tag assist (used on the Tag In buttons).
const ASSIST_ICONS := {
	Hero.Assist.HEAL: "heal",
	Hero.Assist.STRIKE_BOOST: "strike_boost",
	Hero.Assist.GUARD_BOOST: "guard_boost",
}

var boost_name := ""
## 1.0 when the boost starts, 0.0 when it ends.
var fraction := 1.0:
	set(value):
		fraction = value
		queue_redraw()


func _draw() -> void:
	var style: Dictionary = STYLES.get(boost_name, {"color": Color.GRAY, "icon": "star"})
	draw_circle(Vector2.ZERO, RADIUS + RING_WIDTH, Color(0, 0, 0, 0.6))
	draw_circle(Vector2.ZERO, RADIUS, style.color)
	draw_arc(Vector2.ZERO, RADIUS + RING_WIDTH * 0.5, -PI / 2.0, -PI / 2.0 + TAU * fraction, 32, Color.WHITE, RING_WIDTH, true)
	match style.icon:
		"sword":
			_draw_sword()
		"shield":
			_draw_shield()
		"cross":
			_draw_cross()
		_:
			_draw_star()


func _draw_sword() -> void:
	# Blade, crossguard and grip, pointing up
	draw_colored_polygon(PackedVector2Array([Vector2(0, -11), Vector2(2.5, -8), Vector2(2.5, 4), Vector2(-2.5, 4), Vector2(-2.5, -8)]), Color.WHITE)
	draw_rect(Rect2(-7, 4, 14, 2.5), Color.WHITE)
	draw_rect(Rect2(-1.5, 6.5, 3, 5), Color.WHITE)


func _draw_shield() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -9), Vector2(8, -9), Vector2(8, 1), Vector2(0, 10), Vector2(-8, 1)]), Color.WHITE)


func _draw_cross() -> void:
	draw_rect(Rect2(-2.5, -9, 5, 18), Color.WHITE)
	draw_rect(Rect2(-9, -2.5, 18, 5), Color.WHITE)


func _draw_star() -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := 10.0 if i % 2 == 0 else 4.5
		var a := -PI / 2.0 + i * TAU / 10.0
		points.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, Color.WHITE)
