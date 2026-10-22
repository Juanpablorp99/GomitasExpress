class_name Lang
## Textos del juego en español (es) e inglés (en).
## Se cambia de idioma con la tecla L o el botón de arriba (Lang.toggle()).
## Para añadir un texto nuevo: agrega una clave aquí con "es" y "en"
## y en el código usa Lang.t("CLAVE").

static var current := "es"

const TEXTS := {
	# --- Pedido y HUD ---
	"ORDER": {"es": "PEDIDO #%03d", "en": "ORDER #%03d"},
	"REWARD": {"es": "RECOMPENSA: $%d", "en": "REWARD: $%d"},
	"MONEY": {"es": "DINERO: $%d", "en": "MONEY: $%d"},
	"STATUS": {"es": "ESTADO: %s", "en": "STATUS: %s"},
	"STATUS_PENDING": {"es": "PENDIENTE", "en": "PENDING"},
	"STATUS_PICKING": {"es": "RECOGIENDO PRODUCTOS", "en": "PICKING PRODUCTS"},
	"STATUS_READY_TO_PACK": {"es": "LISTO PARA PREPARAR", "en": "READY TO PACK"},
	"STATUS_PACKED": {"es": "PREPARADO", "en": "PACKED"},
	"STATUS_COMPLETED": {"es": "COMPLETADO", "en": "COMPLETED"},
	"STEP_PICK": {"es": "Recoger %s", "en": "Pick up %s"},
	"STEP_PACK": {"es": "Preparar en PREPARACIÓN", "en": "Pack at PACKING ZONE"},
	"STEP_DELIVER": {"es": "Entregar en CAMIÓN", "en": "Deliver to TRUCK"},
	"NEXT_ORDER_COMING": {"es": "Siguiente pedido en camino...", "en": "Next order on the way..."},
	"NO_ORDER": {"es": "SIN PEDIDO", "en": "NO ORDER"},
	"PICK_FROM_BOARD": {"es": "Elige un pedido en el TABLERO", "en": "Pick an order on the BOARD"},
	"CARRYING": {"es": "LLEVAS: %s", "en": "CARRYING: %s"},
	"CARRYING_NOTHING": {"es": "nada", "en": "nothing"},
	"CARRYING_ORDER": {"es": "PEDIDO #%03d PREPARADO", "en": "ORDER #%03d PACKED"},
	"CARRYING_BOX": {"es": "CAJA DEL PROVEEDOR (%d %s)", "en": "SUPPLIER BOX (%d %s)"},
	"TIME_LEFT": {"es": "TIEMPO: %ds", "en": "TIME: %ds"},
	"URGENT": {"es": "¡URGENTE!", "en": "URGENT!"},
	"LEVEL_GOAL": {"es": "Meta: $%d · $%d · $%d (1-3 estrellas)", "en": "Goal: $%d · $%d · $%d (1-3 stars)"},
	"LANG_BUTTON": {"es": "[L] ENGLISH", "en": "[L] ESPAÑOL"},

	# --- Niveles ---
	"LEVEL_NAME_1": {"es": "NIVEL 1 — BODEGA FINI", "en": "LEVEL 1 — FINI WAREHOUSE"},
	"LEVEL_NAME_2": {"es": "NIVEL 2 — TURNO DE NOCHE", "en": "LEVEL 2 — NIGHT SHIFT"},
	"LEVEL_NAME_3": {"es": "NIVEL 3 — ALMACÉN EN LA NIEVE", "en": "LEVEL 3 — SNOWY WAREHOUSE"},
	"LEVEL_INTRO_1": {
		"es": "Atiende los pedidos en orden: recoge las gomitas, mantén E en la mesa\npara prepararlas y llévalas al camión.\n\nCada cliente tiene un TIEMPO de espera: si se acaba, pierdes una VIDA.\nEntrega rápido para ganar PROPINA y subir el COMBO.\n¡Cuidado con el MONTACARGAS! Si te choca, se te caen las gomitas.",
		"en": "Handle the orders in turn: pick the gummies, hold E at the table\nto pack them and take them to the truck.\n\nEvery customer has a WAITING TIME: if it runs out, you lose a LIFE.\nDeliver fast to earn a TIP and build your COMBO.\nWatch out for the FORKLIFT! If it hits you, you drop your gummies.",
	},
	"LEVEL_INTRO_2": {
		"es": "Turno de noche en el gran centro de distribución.\n¡Gomita nueva: DENTADURAS!\n\nVarios pedidos llegan al TABLERO: elige los tuyos.\nLos ROBOTS de la TIENDA ayudan, pero a veces se ATASCAN: ve a repararlos (mantén E).\nOjo con los APAGONES.",
		"en": "Night shift at the big distribution center.\nNew gummy: DENTURES!\n\nSeveral orders arrive on the BOARD: pick yours.\nSHOP ROBOTS help, but sometimes they GET STUCK: go repair them (hold E).\nWatch out for BLACKOUTS.",
	},
	"LEVEL_INTRO_3": {
		"es": "¡Llegó el invierno! 2 gomitas nuevas: BESOS DE FRESA y COLAS.\n\nEl HIELO resbala y puede venir una TORMENTA de nieve.\nEl STOCK se acaba: pide cajas al PROVEEDOR y repón las estanterías.\nLos ROBOTS ahora usan IA: eligen el pedido más urgente y cercano.",
		"en": "Winter is here! 2 new gummies: STRAWBERRY KISSES and COLAS.\n\nICE is slippery and a SNOWSTORM may come.\nSTOCK runs out: order boxes from the SUPPLIER and restock the shelves.\nROBOTS now use AI: they pick the most urgent and closest order.",
	},
	"CONTROLS": {
		"es": "WASD / flechas: mover · SHIFT: correr · E: usar (mantén E para preparar y reparar) · L: idioma · M: sonido · ESC: pausa · F11: pantalla completa",
		"en": "WASD / arrows: move · SHIFT: run · E: use (hold E to pack and repair) · L: language · M: sound · ESC: pause · F11: fullscreen",
	},
	# --- Pausa ---
	"PAUSE_BUTTON": {"es": "[ESC] PAUSA", "en": "[ESC] PAUSE"},
	"PAUSE_TITLE": {"es": "PAUSA", "en": "PAUSED"},
	"PAUSE_RESUME": {"es": "CONTINUAR", "en": "RESUME"},
	"PAUSE_RESTART": {"es": "REINICIAR NIVEL", "en": "RESTART LEVEL"},
	"PAUSE_MENU": {"es": "MENÚ PRINCIPAL", "en": "MAIN MENU"},
	"PRESS_ENTER_START": {"es": "Presiona ENTER para empezar", "en": "Press ENTER to start"},
	"TITLE_NEW_GAME": {"es": "NUEVA PARTIDA", "en": "NEW GAME"},
	"TITLE_LOAD": {"es": "CARGAR PARTIDA", "en": "LOAD GAME"},
	# --- Ranuras de guardado y selector de niveles ---
	"SLOTS_LOAD_TITLE": {"es": "CARGAR PARTIDA", "en": "LOAD GAME"},
	"SLOTS_SAVE_TITLE": {"es": "¿GUARDAR PARTIDA?", "en": "SAVE GAME?"},
	"SLOTS_LOAD_HINT": {"es": "Elige la partida que quieres continuar.", "en": "Choose the game you want to continue."},
	"SLOTS_SAVE_HINT": {"es": "Elige una ranura para guardar tu progreso.", "en": "Choose a slot to save your progress."},
	"SLOTS_AUTOSAVED": {"es": "Tu progreso se guardó automáticamente en la ranura %d.\nTambién puedes guardarlo en otra.", "en": "Your progress was saved automatically in slot %d.\nYou can also save it in another one."},
	"SLOT_EMPTY": {"es": "RANURA %d  —  VACÍA", "en": "SLOT %d  —  EMPTY"},
	"SLOT_INFO": {"es": "RANURA %d  ·  NIVEL %d  ·  %d/%d ESTRELLAS  ·  %s", "en": "SLOT %d  ·  LEVEL %d  ·  %d/%d STARS  ·  %s"},
	"SLOT_IN_USE": {"es": "(EN USO)", "en": "(IN USE)"},
	"SLOTS_CONFIRM": {"es": "La ranura %d ya tiene una partida.\n¿Quieres sobreescribirla?", "en": "Slot %d already has a saved game.\nDo you want to overwrite it?"},
	"SLOTS_YES": {"es": "SÍ, SOBREESCRIBIR", "en": "YES, OVERWRITE"},
	"SLOTS_NO": {"es": "NO", "en": "NO"},
	"SLOTS_SAVED": {"es": "¡Partida guardada en la ranura %d!", "en": "Game saved in slot %d!"},
	"SLOTS_SAVE_ERROR": {"es": "No se pudo guardar la partida.", "en": "The game could not be saved."},
	"SLOTS_LOAD_ERROR": {"es": "No se pudo cargar esa partida.", "en": "That game could not be loaded."},
	"SLOTS_SKIP": {"es": "CONTINUAR SIN GUARDAR", "en": "CONTINUE WITHOUT SAVING"},
	"SLOTS_CONTINUE": {"es": "CONTINUAR", "en": "CONTINUE"},
	"SLOTS_BACK": {"es": "VOLVER", "en": "BACK"},
	"LEVELS_TITLE": {"es": "ELEGIR NIVEL", "en": "CHOOSE LEVEL"},
	"LEVEL_LOCKED": {"es": "BLOQUEADO", "en": "LOCKED"},
	"LEVEL_BEST": {"es": "MEJOR: $%d", "en": "BEST: $%d"},
	"LEVEL_NOT_PLAYED": {"es": "SIN COMPLETAR", "en": "NOT COMPLETED"},
	"PAUSE_LEVELS": {"es": "ELEGIR NIVEL", "en": "CHOOSE LEVEL"},
	"TITLE_LANGUAGE": {"es": "IDIOMA: ESPAÑOL", "en": "LANGUAGE: ENGLISH"},
	"TITLE_QUIT": {"es": "SALIR", "en": "QUIT"},
	"TITLE_SUBTITLE": {"es": "¡Distribuye gomitas Fini lo más rápido que puedas!", "en": "Deliver Fini gummies as fast as you can!"},
	"LEVEL_WON": {
		"es": "¡NIVEL COMPLETADO!\n\nPedidos entregados: %d\nDinero: $%d\n\nPresiona ENTER para continuar",
		"en": "LEVEL COMPLETE!\n\nOrders delivered: %d\nMoney: $%d\n\nPress ENTER to continue",
	},
	"LEVEL_FAILED_TIME": {
		"es": "¡SE ACABÓ EL TIEMPO!\n\nNo llegaste a la meta de $%d (tienes $%d).\n\nPresiona ENTER para reintentar",
		"en": "TIME'S UP!\n\nYou didn't reach the $%d goal (you have $%d).\n\nPress ENTER to try again",
	},
	"LEVEL_FAILED_HEARTS": {
		"es": "¡TE QUEDASTE SIN VIDAS!\n\nDemasiados clientes se cansaron de esperar.\n\nPresiona ENTER para reintentar",
		"en": "OUT OF LIVES!\n\nToo many customers got tired of waiting.\n\nPress ENTER to try again",
	},
	"GAME_COMPLETE": {
		"es": "¡JUEGO COMPLETADO!\n\nNivel 1: %d/3 estrellas\nNivel 2: %d/3 estrellas\nNivel 3: %d/3 estrellas\n\nGracias por jugar GOMITAS EXPRESS\nPresiona ENTER para jugar otra vez",
		"en": "GAME COMPLETE!\n\nLevel 1: %d/3 stars\nLevel 2: %d/3 stars\nLevel 3: %d/3 stars\n\nThanks for playing GOMITAS EXPRESS\nPress ENTER to play again",
	},

	# --- Mensajes grandes ---
	"MSG_NEW_ORDER": {"es": "NUEVO PEDIDO #%03d", "en": "NEW ORDER #%03d"},
	"MSG_NEW_URGENT": {"es": "¡PEDIDO URGENTE #%03d!", "en": "URGENT ORDER #%03d!"},
	"MSG_ORDER_COMPLETED": {"es": "¡PEDIDO COMPLETADO!\n+$%d", "en": "ORDER COMPLETED!\n+$%d"},
	"MSG_ORDER_COMPLETED_TIP": {"es": "¡PEDIDO COMPLETADO!\n+$%d  (+$%d de propina)", "en": "ORDER COMPLETED!\n+$%d  (+$%d tip)"},
	"MSG_ORDER_PACKED": {"es": "PEDIDO PREPARADO", "en": "ORDER PACKED"},
	"MSG_ORDER_EXPIRED": {"es": "¡EL CLIENTE DEL PEDIDO #%03d SE CANSÓ!\n-1 VIDA  -$%d", "en": "ORDER #%03d CUSTOMER LEFT!\n-1 LIFE  -$%d"},
	"MSG_TIME_ALMOST_UP": {"es": "¡QUEDAN 30 SEGUNDOS!", "en": "30 SECONDS LEFT!"},
	"MSG_COMBO": {"es": "¡COMBO %s!", "en": "COMBO %s!"},
	"FX_BONK": {"es": "¡PUM!", "en": "BONK!"},
	"MSG_FORKLIFT_HIT": {"es": "¡CUIDADO CON EL MONTACARGAS!", "en": "WATCH OUT FOR THE FORKLIFT!"},
	"MSG_FORKLIFT_DROP": {"es": "¡TE CHOCÓ EL MONTACARGAS!\nSe te cayeron las gomitas", "en": "THE FORKLIFT HIT YOU!\nYou dropped your gummies"},
	"MSG_ROBOT_BROKEN": {"es": "¡%s ATASCADO!\nVe a repararlo (mantén E)", "en": "%s IS STUCK!\nGo repair it (hold E)"},
	"MSG_ROBOT_REPAIRED": {"es": "¡%s REPARADO!", "en": "%s REPAIRED!"},
	"MSG_EVENT_RUSH": {"es": "¡HORA PICO!\nLlegan más pedidos", "en": "RUSH HOUR!\nMore orders incoming"},
	"MSG_EVENT_SPILL": {"es": "¡DERRAME EN EL PASILLO!\nCuidado, resbala", "en": "SPILL IN THE AISLE!\nCareful, it's slippery"},
	"MSG_EVENT_BLACKOUT": {"es": "¡APAGÓN!", "en": "BLACKOUT!"},
	"MSG_EVENT_STORM": {"es": "¡TORMENTA DE NIEVE!\nTe mueves más lento", "en": "SNOWSTORM!\nYou move slower"},
	"EVENT_rush": {"es": "¡HORA PICO! %ds", "en": "RUSH HOUR! %ds"},
	"EVENT_spill": {"es": "DERRAME %ds", "en": "SPILL %ds"},
	"EVENT_blackout": {"es": "¡APAGÓN! %ds", "en": "BLACKOUT! %ds"},
	"EVENT_storm": {"es": "TORMENTA %ds", "en": "SNOWSTORM %ds"},
	"COMBO": {"es": "COMBO %s", "en": "COMBO %s"},
	"QUEUE": {"es": "EN ESPERA: %s", "en": "WAITING: %s"},
	"HOLD_E": {"es": "[MANTÉN E] %s", "en": "[HOLD E] %s"},
	"MSG_SUPPLY_ORDERED": {"es": "PEDIDO AL PROVEEDOR\n-$%d", "en": "SUPPLIER ORDER\n-$%d"},
	"MSG_SUPPLY_ARRIVED": {"es": "¡LLEGÓ EL PROVEEDOR!\nLleva las cajas a las estanterías", "en": "SUPPLIER ARRIVED!\nTake the boxes to the shelves"},
	"MSG_PROMO": {"es": "¡PROMO DE %s!\nSe van a pedir más", "en": "%s PROMO!\nMore orders coming"},
	"MSG_ORDER_ASSIGNED": {"es": "PEDIDO #%03d → %s", "en": "ORDER #%03d → %s"},
	"MSG_ROBOT_BOUGHT": {"es": "¡%s COMPRADO!", "en": "%s PURCHASED!"},

	# --- Acciones y motivos de bloqueo ---
	"ACTION_PICK": {"es": "Recoger %s", "en": "Pick up %s"},
	"ACTION_PACK": {"es": "Preparar pedido", "en": "Pack order"},
	"ACTION_DELIVER": {"es": "Entregar pedido al camión", "en": "Deliver order to the truck"},
	"ACTION_RESTOCK": {"es": "Reponer %s (+%d)", "en": "Restock %s (+%d)"},
	"ACTION_TAKE_BOX": {"es": "Tomar caja de %s", "en": "Take box of %s"},
	"ACTION_RETURN_BOX": {"es": "Dejar la caja en RECEPCIÓN", "en": "Leave the box at RECEIVING"},
	"ACTION_REPAIR": {"es": "Reparar %s", "en": "Repair %s"},
	"BLOCK_NO_ORDERS": {"es": "No hay pedidos pendientes", "en": "No pending orders"},
	"BLOCK_NO_STOCK": {"es": "Sin stock: quedan %d %s", "en": "Out of stock: %d %s left"},
	"BLOCK_WRONG_SHELF": {"es": "Esta caja va en la estantería de %s", "en": "This box goes on the %s shelf"},
	"BLOCK_SHELF_FULL": {"es": "La estantería está llena", "en": "The shelf is full"},
	"BLOCK_HANDS_FULL": {"es": "Tienes las manos ocupadas", "en": "Your hands are full"},
	"BLOCK_NO_BOXES": {"es": "No hay cajas en RECEPCIÓN", "en": "No boxes at RECEIVING"},
	"BLOCK_DROP_BOX": {"es": "Primero deja la caja en su estantería", "en": "First put the box on its shelf"},
	"BLOCK_NO_ORDER_ASSIGNED": {"es": "No tienes pedido: elige uno en el TABLERO", "en": "You have no order: pick one on the BOARD"},
	"BLOCK_HAS_PACKED_ORDER": {"es": "Ya llevas un pedido preparado: llévalo al CAMIÓN", "en": "You already have a packed order: take it to the TRUCK"},
	"BLOCK_NOT_IN_ORDER": {"es": "Este pedido no lleva %s", "en": "This order doesn't include %s"},
	"BLOCK_ALREADY_PICKED": {"es": "Ya recogiste %s", "en": "You already picked up %s"},
	"BLOCK_ORDER_READY": {"es": "El pedido ya está listo: llévalo al CAMIÓN", "en": "The order is ready: take it to the TRUCK"},
	"BLOCK_PICK_FIRST": {"es": "Primero recoge los productos del pedido", "en": "First pick up the order's products"},
	"BLOCK_MISSING": {"es": "Faltan: %s", "en": "Missing: %s"},
	"BLOCK_PACK_FIRST": {"es": "Primero prepara el pedido en la ZONA DE PREPARACIÓN", "en": "First pack the order at the PACKING ZONE"},
	"BLOCK_NEED_PACKED": {"es": "Necesitas un pedido preparado", "en": "You need a packed order"},

	# --- Almacén ---
	"PREP_ZONE": {"es": "ZONA DE PREPARACIÓN", "en": "PACKING ZONE"},
	"DISPATCH_ZONE": {"es": "DESPACHO / CAMIÓN", "en": "DISPATCH / TRUCK"},
	"DELIVER_HERE": {"es": "ENTREGA AQUÍ", "en": "DELIVER HERE"},
	"ROBOT_DOCK": {"es": "BASE DE ROBOTS", "en": "ROBOT DOCK"},
	"RECEIVING_ZONE": {"es": "RECEPCIÓN", "en": "RECEIVING"},
	"OUT_OF_STOCK": {"es": "AGOTADO", "en": "SOLD OUT"},

	# --- Productos ---
	"PRODUCT_osos": {"es": "OSOS", "en": "BEARS"},
	"PRODUCT_raton": {"es": "RATÓN", "en": "MICE"},
	"PRODUCT_gusanos": {"es": "GUSANOS ÁCIDOS", "en": "SOUR WORMS"},
	"UNIT_osos": {"es": "CAJAS", "en": "BOXES"},
	"UNIT_raton": {"es": "UNIDADES", "en": "UNITS"},
	"UNIT_gusanos": {"es": "BOLSAS", "en": "BAGS"},
	"PRODUCT_dentaduras": {"es": "DENTADURAS", "en": "DENTURES"},
	"PRODUCT_huevos": {"es": "HUEVOS FRITOS", "en": "FRIED EGGS"},
	"PRODUCT_platanos": {"es": "PLÁTANOS", "en": "BANANAS"},
	"PRODUCT_fresas": {"es": "BESOS DE FRESA", "en": "STRAWBERRY KISSES"},
	"PRODUCT_colas": {"es": "COLAS", "en": "COLA BOTTLES"},
	"UNIT_dentaduras": {"es": "BOLSAS", "en": "BAGS"},
	"UNIT_huevos": {"es": "CAJAS", "en": "BOXES"},
	"UNIT_platanos": {"es": "BOLSAS", "en": "BAGS"},
	"UNIT_fresas": {"es": "CAJAS", "en": "BOXES"},
	"UNIT_colas": {"es": "BOLSAS", "en": "BAGS"},
	"DESCRIBE": {"es": "%d %s DE %s", "en": "%d %s OF %s"},

	# --- Tienda y robots ---
	"SHOP_TITLE": {"es": "TIENDA DE AUTOMATIZACIÓN", "en": "AUTOMATION SHOP"},
	"SHOP_ROBOT": {"es": "ROBOT RECOLECTOR — $%d", "en": "PICKER ROBOT — $%d"},
	"SHOP_ROBOT_MAX": {"es": "ROBOT RECOLECTOR — MÁXIMO", "en": "PICKER ROBOT — MAX"},
	"SHOP_ROBOT_INFO": {"es": "Toma pedidos libres solo, pero es lento y a veces se atasca. Reasígnalos en el TABLERO.", "en": "Takes free orders on its own, but it's slow and sometimes gets stuck. Reassign them on the BOARD."},
	"SHOP_FAST_ROBOT": {"es": "ROBOT RÁPIDO — PRÓXIMAMENTE", "en": "FAST ROBOT — COMING SOON"},
	"SHOP_CONVEYOR": {"es": "CINTA TRANSPORTADORA — PRÓXIMAMENTE", "en": "CONVEYOR BELT — COMING SOON"},
	"SHOP_AI_NOTE": {
		"es": "En el NIVEL 3 los robots usarán IA para elegir pedidos según urgencia, tiempo de espera y distancia.",
		"en": "In LEVEL 3 robots will use AI to pick orders based on urgency, waiting time and distance.",
	},
	"SHOP_AI_ACTIVE": {
		"es": "IA ACTIVA: cada robot elige el pedido con mejor puntaje (urgencia + tiempo de espera + valor - distancia).",
		"en": "AI ACTIVE: each robot picks the order with the best score (urgency + waiting time + value - distance).",
	},
	"ROBOT_AI_CHOICE": {"es": "IA: eligió #%03d (puntaje %.2f)", "en": "AI: chose #%03d (score %.2f)"},
	"BOARD_AI_SCORE": {"es": "IA %.2f", "en": "AI %.2f"},
	"ROBOT_WAITING": {"es": "Esperando pedido", "en": "Waiting for an order"},
	"ROBOT_PICKING": {"es": "Recogiendo %s", "en": "Picking %s"},
	"ROBOT_PACKING": {"es": "Preparando pedido", "en": "Packing order"},
	"ROBOT_DELIVERING": {"es": "Entregando al camión", "en": "Delivering to truck"},
	"ROBOT_RETURNING": {"es": "Volviendo a la base", "en": "Returning to dock"},
	"ROBOT_RESTING": {"es": "Descansando", "en": "Resting"},
	"ROBOT_NO_STOCK": {"es": "Esperando stock", "en": "Waiting for stock"},
	"ROBOT_BROKEN": {"es": "¡ATASCADO! Repárame", "en": "STUCK! Repair me"},

	# --- Tablero de pedidos (Niveles 2 y 3) ---
	"BOARD_TITLE": {"es": "TABLERO DE PEDIDOS", "en": "ORDER BOARD"},
	"BOARD_ME": {"es": "YO", "en": "ME"},
	"BOARD_FREE": {"es": "LIBRE", "en": "FREE"},
	"BOARD_BUSY": {"es": "EN CURSO", "en": "IN PROGRESS"},
	"BOARD_NO_STOCK": {"es": "SIN STOCK", "en": "NO STOCK"},
	"PROMO": {"es": "PROMO: %s (se pide más)", "en": "PROMO: %s (more demand)"},

	# --- Pestañas del HUD ---
	"TAB_ORDER": {"es": "PEDIDO #%03d — %s", "en": "ORDER #%03d — %s"},
	"TAB_ORDER_NONE": {"es": "PEDIDO: ninguno (ve al TABLERO)", "en": "ORDER: none (see the BOARD)"},
	"TAB_SUPPLIER": {"es": "PROVEEDOR", "en": "SUPPLIER"},
	"TAB_SUPPLIER_TRUCK": {"es": "PROVEEDOR — camión en %ds", "en": "SUPPLIER — truck in %ds"},
	"TAB_SUPPLIER_BOXES": {"es": "PROVEEDOR — %d cajas en RECEPCIÓN", "en": "SUPPLIER — %d boxes at RECEIVING"},
	"TAB_SHOP": {"es": "TIENDA — robots %d/%d", "en": "SHOP — robots %d/%d"},
	"TAB_BOARD": {"es": "TABLERO — %d pedidos libres", "en": "BOARD — %d free orders"},

	# --- Proveedor y bancarrota (Nivel 3) ---
	"SUPPLIER_TITLE": {"es": "PROVEEDOR", "en": "SUPPLIER"},
	"SUPPLIER_ROW": {"es": "%s  $%d/caja", "en": "%s  $%d/box"},
	"SUPPLIER_INFO": {"es": "Cajas de %d u. · Recepción: %d/%d", "en": "Boxes of %d u. · Receiving: %d/%d"},
	"SUPPLIER_ORDER": {"es": "PEDIR — $%d (flete $%d)", "en": "ORDER — $%d (freight $%d)"},
	"SUPPLIER_IN_TRANSIT": {"es": "CAMIÓN EN CAMINO: %ds", "en": "TRUCK ON THE WAY: %ds"},
	"SUPPLIER_ETA": {"es": "PROVEEDOR: %ds", "en": "SUPPLIER: %ds"},
	"GAME_OVER": {
		"es": "¡BANCARROTA!\n\nTe quedaste sin stock y sin dinero para reponer.\nPedidos entregados: %d\n\nPresiona ENTER para reintentar",
		"en": "BANKRUPT!\n\nYou ran out of stock and money to restock.\nOrders delivered: %d\n\nPress ENTER to try again",
	},
}


## Devuelve el texto de la clave en el idioma actual (o la clave si no existe).
static func t(key: String) -> String:
	if not TEXTS.has(key):
		return key
	return TEXTS[key][current]


static func toggle() -> void:
	current = "en" if current == "es" else "es"
	SaveManager.save_settings()   # el idioma elegido se recuerda al volver a abrir el juego
