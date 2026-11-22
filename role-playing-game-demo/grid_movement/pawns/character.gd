extends Node2D

## Velocidade em pixels por segundo.
@export var speed: float = 200.0


func _process(delta: float) -> void:
	# As ações move_* já estão mapeadas para as setas (e WASD) no Input Map.
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction.is_zero_approx():
		return

	position += direction * speed * delta

	# Gira o indicador de direção do sprite, se existir (vem do character.tscn).
	if has_node(^"Pivot/FacingDirection"):
		$Pivot/FacingDirection.rotation = direction.angle()
