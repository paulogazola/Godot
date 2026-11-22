extends Walker

func _process(_delta: float) -> void:
	var input_direction := get_input_direction()
	# We only move in integer increments.
	input_direction = input_direction.round()

	if input_direction.is_zero_approx():
		return

	update_look_direction(input_direction)

	var target_position: Vector2 = grid.request_move(self, input_direction)
	if target_position:
		move_to(target_position)
	elif active:
		bump()

	# "position" é a posição do próprio jogador (o nó em que este script está).
	# Está em pixels. Para saber a CÉLULA do grid, converta com local_to_map().
	var celula: Vector2i = grid.local_to_map(position)
	if celula.x == 3 and celula.y == 2:
		print("Jogador está na célula (3, 2)")


func get_input_direction() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
