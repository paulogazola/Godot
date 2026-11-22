extends Node2D

# Colisão elástica entre bolas de mesma massa: trocam a componente da
# velocidade ao longo da normal do choque.
#
# A quantidade de bolas é controlada por ball_count (Inspetor ou código).
# Mudar o valor em tempo de execução adiciona/remove bolas na hora.
# Teclas: seta para cima / "+" aumenta, seta para baixo / "-" diminui.

const BallScript := preload("res://ball.gd")
const MAX_BALLS := 500
const SPAWN_TRIES := 30

@export_range(0, MAX_BALLS) var ball_count := 5:
	set(value):
		ball_count = clampi(value, 0, MAX_BALLS)
		if is_node_ready():
			_sync_ball_count()

@export var ball_radius := 15.0
@export var min_speed := 250.0
@export var max_speed := 400.0

var _balls: Array[Node2D] = []


func _ready() -> void:
	_sync_ball_count()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_UP, KEY_EQUAL, KEY_KP_ADD:
			ball_count += 1
		KEY_DOWN, KEY_MINUS, KEY_KP_SUBTRACT:
			ball_count -= 1


# Ajusta a quantidade de bolas na cena até bater com ball_count.
func _sync_ball_count() -> void:
	while _balls.size() < ball_count:
		_spawn_ball()
	while _balls.size() > ball_count:
		var ball: Node2D = _balls.pop_back()
		remove_child(ball)
		ball.queue_free()


func _spawn_ball() -> void:
	var bounds := get_viewport_rect().size
	var ball := Node2D.new()
	ball.set_script(BallScript)
	ball.radius = ball_radius
	ball.color = Color.from_hsv(randf(), 0.7, 0.95)
	ball.velocity = Vector2.from_angle(randf() * TAU) * randf_range(min_speed, max_speed)
	ball.position = _find_free_position(bounds, ball_radius)
	ball.name = "Ball%d" % (_balls.size() + 1)
	_balls.append(ball)
	add_child(ball)


# Sorteia uma posição que não sobreponha bolas existentes; se não achar
# em SPAWN_TRIES tentativas, usa a última (a colisão separa depois).
func _find_free_position(bounds: Vector2, radius: float) -> Vector2:
	var pos := Vector2.ZERO
	for i in SPAWN_TRIES:
		pos = Vector2(
			randf_range(radius, bounds.x - radius),
			randf_range(radius, bounds.y - radius))
		var free := true
		for other in _balls:
			if pos.distance_to(other.position) < radius + other.radius:
				free = false
				break
		if free:
			return pos
	return pos


func _physics_process(_delta: float) -> void:
	for i in _balls.size():
		for j in range(i + 1, _balls.size()):
			_collide(_balls[i], _balls[j])


func _collide(a: Node2D, b: Node2D) -> void:
	var diff := b.position - a.position
	var min_dist: float = a.radius + b.radius
	var dist := diff.length()
	if dist >= min_dist or dist == 0.0:
		return

	var normal := diff / dist

	# separa as bolas para não ficarem sobrepostas
	var overlap := min_dist - dist
	a.position -= normal * overlap / 2.0
	b.position += normal * overlap / 2.0

	# só troca velocidade se estiverem se aproximando
	var approach: float = (a.velocity - b.velocity).dot(normal)
	if approach <= 0.0:
		return
	a.velocity -= normal * approach
	b.velocity += normal * approach
