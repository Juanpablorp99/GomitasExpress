class_name Levels
## Configuración de los 3 niveles. Para ajustar la dificultad, cambia los números aquí.
## Cada nivel es una escena distinta (scenes/levels/level_N.tscn) que usa warehouse.gd
## con `level_number` = N. Las posiciones de estanterías, montacargas, etc. están en la escena.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const SCENES := [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]

## name / intro: claves de lang.gd
## room: tamaño del almacén en píxeles · zoom: zoom de la cámara (menos = se ve más lejos)
## products: gomitas que aparecen en el nivel (deben tener su estantería en la escena)
## duration: segundos que dura el nivel
## stars: dinero necesario al terminar para 1, 2 y 3 estrellas (con menos de la 1ª se pierde)
## board: true = tablero para elegir pedidos · false = se te asignan solos, en orden
## board_size: pedidos a la vez (en espera + el tuyo)
## first_order: primer pedido fijo (tutorial) o {} para que sea aleatorio
## max_products: máximo de gomitas distintas en un pedido
## patience_base / patience_per_product: segundos de espera del cliente
## urgent_chance: probabilidad de que un pedido sea URGENTE
## robots: se pueden comprar robots · ai: los robots eligen pedidos con IA (task_ai.gd)
## breakdowns: los robots se atascan y hay que repararlos
## supplier: el stock se acaba y hay que pedir al proveedor · initial_stock: stock inicial
## promo: un producto en promoción aparece más en los pedidos
## events: eventos sorpresa posibles ("rush", "spill", "blackout", "storm")
## ice: zonas de hielo resbaladizo · spill_spots: dónde pueden aparecer derrames
## dock: base de carga de los robots · start_money: dinero con el que empieza el nivel
## Cada nivel suma pocas mecánicas nuevas y tiene un solo tipo de evento sorpresa:
##   N1: pedidos en cola + montacargas · evento: hora pico
##   N2: + tablero y robots que se atascan · evento: apagón
##   N3: + hielo, stock/proveedor y robots con IA · evento: tormenta
const CONFIG := [
	{   # NIVEL 1 — Bodega Fini: tú solo, con un montacargas y la hora pico
		"name": "LEVEL_NAME_1", "intro": "LEVEL_INTRO_1",
		"room": Vector2(1440, 960), "zoom": 0.85,
		"products": ["osos", "raton", "gusanos"],
		"duration": 150.0, "stars": [40, 75, 110],
		"board": false, "board_size": 2, "first_order": {"osos": 5}, "max_products": 2,
		"patience_base": 45.0, "patience_per_product": 12.0, "urgent_chance": 0.2,
		"robots": false, "ai": false, "breakdowns": false,
		"supplier": false, "initial_stock": 30, "promo": false,
		"events": ["rush"], "ice": [],
		"spill_spots": [],
		"dock": Rect2(), "start_money": 0,
	},
	{   # NIVEL 2 — Centro de distribución de noche: tablero, robots que se atascan y apagones
		"name": "LEVEL_NAME_2", "intro": "LEVEL_INTRO_2",
		"room": Vector2(2080, 1280), "zoom": 0.75,
		"products": ["osos", "raton", "gusanos", "dentaduras"],
		"duration": 180.0, "stars": [90, 160, 240],
		"board": true, "board_size": 4, "first_order": {}, "max_products": 3,
		"patience_base": 65.0, "patience_per_product": 15.0, "urgent_chance": 0.3,
		"robots": true, "ai": false, "breakdowns": true,
		"supplier": false, "initial_stock": 30, "promo": false,
		"events": ["blackout"], "ice": [],
		"spill_spots": [],
		"dock": Rect2(72, 1106, 270, 118), "start_money": 0,
	},
	{   # NIVEL 3 — Almacén en la nieve: hielo, tormenta, stock, proveedor y robots con IA
		"name": "LEVEL_NAME_3", "intro": "LEVEL_INTRO_3",
		"room": Vector2(2080, 1280), "zoom": 0.75,
		"products": ["osos", "raton", "gusanos", "dentaduras", "fresas", "colas"],
		"duration": 180.0, "stars": [100, 180, 260],
		"board": true, "board_size": 5, "first_order": {}, "max_products": 3,
		"patience_base": 70.0, "patience_per_product": 15.0, "urgent_chance": 0.35,
		"robots": true, "ai": true, "breakdowns": true,
		"supplier": true, "initial_stock": 20, "promo": false,
		"events": ["storm"],
		"ice": [Rect2(802, 324, 254, 111), Rect2(1357, 608, 222, 118), Rect2(421, 916, 238, 103)],
		"spill_spots": [],
		"dock": Rect2(72, 1106, 270, 118), "start_money": 40,
	},
]

const HEARTS := 3                  # vidas por nivel
const EXPIRE_PENALTY := 8          # multa en $ cuando un pedido se vence
const MIN_ITEM_QTY := 2            # unidades mínimas y máximas de cada gomita en un pedido
const MAX_ITEM_QTY := 5
const URGENT_REWARD_MULT := 2      # un pedido URGENTE paga el doble...
const URGENT_TIME_MULT := 0.7      # ...pero el cliente espera menos
const TIP_THRESHOLD := 0.5         # si entregas con más de la mitad del tiempo...
const TIP_RATE := 0.3              # ...ganas una propina del 30% y sube el COMBO
const COMBO_STEP := 0.5            # cada entrega rápida seguida suma x0.5 al pago (máx. x3)
const COMBO_MAX := 3.0
const PACK_TIME := 1.5             # segundos manteniendo E para preparar un pedido
const REPAIR_TIME := 1.2           # segundos manteniendo E para reparar un robot
const EVENT_INTERVAL := [25.0, 40.0]   # cada cuánto puede pasar un evento sorpresa
const EVENT_DURATION := {"rush": 20.0, "spill": 25.0, "blackout": 12.0, "storm": 15.0}


static func get_config(level_number: int) -> Dictionary:
	return CONFIG[level_number - 1]


static func count() -> int:
	return CONFIG.size()
