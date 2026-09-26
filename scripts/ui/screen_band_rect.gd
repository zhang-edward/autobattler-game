extends ColorRect

## Keeps this ColorRect stretched to a horizontal band of the viewport,
## e.g. top_fraction=0.0, bottom_fraction=0.287 covers the top ~29% of
## the screen. Re-applies whenever the window/viewport is resized.

@export_range(0.0, 1.0, 0.001) var top_fraction: float = 0.0
@export_range(0.0, 1.0, 0.001) var bottom_fraction: float = 1.0

func _ready() -> void:
	get_viewport().size_changed.connect(_update_rect)
	_update_rect()

func _update_rect() -> void:
	var vp_size := get_viewport_rect().size
	position = Vector2(0.0, vp_size.y * top_fraction)
	size = Vector2(vp_size.x, vp_size.y * (bottom_fraction - top_fraction))
