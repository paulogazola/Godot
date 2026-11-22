extends Node2D

@export var radius := 15.0
@export var color := Color(0.95, 0.45, 0.2)
@export var velocity := Vector2(380.0, 290.0)


func _process(delta: float) -> void:
	var bounds := get_viewport_rect().size
	position += velocity * delta

	if position.x < radius:
		position.x = radius
		velocity.x = absf(velocity.x)
	elif position.x > bounds.x - radius:
		position.x = bounds.x - radius
		velocity.x = -absf(velocity.x)

	if position.y < radius:
		position.y = radius
		velocity.y = absf(velocity.y)
	elif position.y > bounds.y - radius:
		position.y = bounds.y - radius
		velocity.y = -absf(velocity.y)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)
