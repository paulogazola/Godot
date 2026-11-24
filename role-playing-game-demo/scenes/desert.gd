extends Node2D
## Controlador da cena do deserto: decide o que fica nítido/esmaecido conforme o jogador
## está fora ou dentro de uma Casa (e em qual andar), trata escadas e colisão com paredes.
##
## Regra de visibilidade:
##   Fora:   mundo exterior (chao, decoracao, fachadas) nítido; todos os interiores ocultos.
##   Dentro: exterior esmaecido; só o andar atual da casa atual nítido.

const EXTERIOR_NITIDO := Color(1, 1, 1, 1)
const EXTERIOR_ESMAECIDO := Color(0.55, 0.55, 0.65, 0.3)
const INTERIOR_NITIDO := Color(1, 1, 1, 1)
const INTERIOR_OCULTO := Color(1, 1, 1, 0)
const SEM_CELULA := Vector2i(-99999, -99999)

@export var tempo_fade: float = 0.3

@onready var personagem: Node2D = $Character
@onready var camera: Camera2D = $decoracao/Camera2D

var casas: Array[Casa] = []
var _exterior: Array[CanvasItem] = []
var casa_atual: Casa = null
var andar: int = 0
## Célula da escada em que acabamos de chegar: só reage a ela depois que o jogador sair dela
## (senão subir e descer ficariam alternando para sempre).
var _celula_ignorada: Vector2i = SEM_CELULA
var _tween: Tween


func _ready() -> void:
	_exterior = [$chao, $decoracao]
	for filho in get_children():
		if filho is Casa:
			casas.append(filho)
			_exterior.append(filho.fachada)
	personagem.bloqueado = _bloqueado
	_atualizar_visual(false)


func _process(_delta: float) -> void:
	# A câmera original ficava parada; aqui ela passa a seguir o personagem.
	camera.global_position = personagem.global_position

	var nova_casa: Casa = null
	var cel := SEM_CELULA
	for c in casas:
		var cel_c := c.celula(personagem.global_position)
		if c.esta_dentro(cel_c):
			nova_casa = c
			cel = cel_c
			break

	if nova_casa != casa_atual:
		# Entrou ou saiu pela porta.
		casa_atual = nova_casa
		andar = 0
		_celula_ignorada = SEM_CELULA
		_atualizar_visual(true)
		return

	if casa_atual == null or cel == _celula_ignorada:
		return
	_celula_ignorada = SEM_CELULA
	match casa_atual.transicao(cel, andar):
		"sobe":
			_mudar_andar(andar + 1, cel)
		"desce":
			_mudar_andar(andar - 1, cel)


func _mudar_andar(novo: int, cel: Vector2i) -> void:
	if novo < 0 or novo >= casa_atual.andares.size():
		return
	andar = novo
	_celula_ignorada = cel
	_atualizar_visual(true)


func _atualizar_visual(animado: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)

	var cor_exterior := EXTERIOR_ESMAECIDO if casa_atual else EXTERIOR_NITIDO
	for no in _exterior:
		_aplicar(no, cor_exterior, animado)

	for c in casas:
		for i in c.andares.size():
			var ativo := c == casa_atual and i == andar
			_aplicar(c.andares[i], INTERIOR_NITIDO if ativo else INTERIOR_OCULTO, animado)

	# Dentro da casa o personagem precisa ficar acima do piso do andar em que está.
	personagem.z_index = casa_atual.z_do_jogador(andar) if casa_atual else 0


func _aplicar(no: CanvasItem, cor: Color, animado: bool) -> void:
	if animado:
		_tween.tween_property(no, "modulate", cor, tempo_fade)
	else:
		no.modulate = cor


## Chamado pelo personagem antes de andar: true se o ponto (global) bate numa parede/móvel.
func _bloqueado(pos_global: Vector2) -> bool:
	for c in casas:
		var andar_ref := andar if c == casa_atual else 0
		if c.bloqueia(c.celula(pos_global), andar_ref):
			return true
	return false
