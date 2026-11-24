extends Node2D

## Velocidade em pixels por segundo.
@export var speed: float = 200.0

## Opcional: Callable(posicao_global: Vector2) -> bool que diz se o ponto está bloqueado.
## A cena (ex.: desert.gd) define; sem ela o personagem anda livremente, como antes.
var bloqueado: Callable

## "Raio" do corpo do personagem para colisão com tiles (px).
const RAIO := 16.0


func _process(delta: float) -> void:
	# As ações move_* já estão mapeadas para as setas (e WASD) no Input Map.
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction.is_zero_approx():
		return

	# Eixos separados: encostar numa parede ainda permite deslizar ao longo dela.
	var passo := direction * speed * delta
	if _livre(global_position + Vector2(passo.x, 0.0)):
		position.x += passo.x
	if _livre(global_position + Vector2(0.0, passo.y)):
		position.y += passo.y

	# Gira o indicador de direção do sprite, se existir (vem do character.tscn).
	if has_node(^"Pivot/FacingDirection"):
		$Pivot/FacingDirection.rotation = direction.angle()


func _livre(pos: Vector2) -> bool:
	if not bloqueado.is_valid():
		return true
	for canto in [Vector2(-RAIO, -RAIO), Vector2(RAIO, -RAIO), Vector2(-RAIO, RAIO), Vector2(RAIO, RAIO)]:
		if bloqueado.call(pos + canto):
			return false
	return true
