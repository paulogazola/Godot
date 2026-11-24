class_name Casa
extends Node2D
## Prédio com vários andares.
##
## Filhos esperados (todos TileMapLayer, na mesma posição/TileSet do deserto):
##   Fachada -> visual EXTERIOR (telhado + parede da frente + porta). Faz parte do "mundo de fora".
##   Andar0, Andar1, ... -> INTERIOR de cada andar, na mesma área da fachada (vista de dentro).
##
## Quem decide o que fica nítido/esmaecido é o desert.gd; esta classe só responde perguntas
## sobre a casa ("esta célula é interior?", "bloqueia?", "tem escada?").

## Células em que o jogador é considerado "dentro da casa". As coordenadas são LOCAIS à casa
## (origem = célula do canto superior esquerdo): as camadas filhas ficam em (0,0) e o nó Casa
## é posicionado na grade do deserto, então várias instâncias funcionam sem conversão manual.
## É só o piso: paredes e porta ficam de fora de propósito (a porta é a fronteira).
@export var area_interna: Rect2i = Rect2i(1, 1, 5, 3)

## Distância em z_index entre um andar e o seguinte (o jogador fica no meio do andar atual).
const Z_BASE_ANDAR := 10
const Z_ENTRE_ANDARES := 10

@onready var fachada: TileMapLayer = $Fachada
var andares: Array[TileMapLayer] = []


func _ready() -> void:
	for filho in get_children():
		if filho is TileMapLayer and filho.name.begins_with("Andar"):
			andares.append(filho)
	for i in andares.size():
		andares[i].z_index = z_do_andar(i)


## z_index em que o jogador deve ficar quando está no andar `i` (acima do piso daquele andar).
func z_do_jogador(i: int) -> int:
	return z_do_andar(i) + Z_ENTRE_ANDARES / 2


func z_do_andar(i: int) -> int:
	return Z_BASE_ANDAR + i * Z_ENTRE_ANDARES


func celula(pos_global: Vector2) -> Vector2i:
	return fachada.local_to_map(fachada.to_local(pos_global))


func esta_dentro(cel: Vector2i) -> bool:
	return area_interna.has_point(cel)


## Dentro da área interna vale o interior do andar; fora dela vale a fachada.
func _dados(cel: Vector2i, andar: int) -> TileData:
	var camada: TileMapLayer = andares[andar] if esta_dentro(cel) else fachada
	return camada.get_cell_tile_data(cel)


## Custom data "bloqueia" (bool) do tile na célula.
func bloqueia(cel: Vector2i, andar: int) -> bool:
	var td := _dados(cel, andar)
	return td != null and td.get_custom_data(&"bloqueia")


## Custom data "transicao" (String) do tile na célula: "", "sobe" ou "desce".
func transicao(cel: Vector2i, andar: int) -> String:
	var td := _dados(cel, andar)
	return "" if td == null else td.get_custom_data(&"transicao")
