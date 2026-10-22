# Gomitas Express

Juego de gestión de almacén en 2D (vista desde arriba) hecho en **Godot 4.7** con GDScript.

Sos un operario de un almacén de gomitas Fini. Llegan pedidos de clientes y tenés que cumplirlos antes de que se cansen de esperar: **recoger** las gomitas de las estanterías, **preparar** el pedido en la mesa y **despacharlo** en el camión. Con el dinero ganado podés comprar robots que trabajan solos.

**Género:** gestión del tiempo / simulación con acción arcade · 1 jugador · español e inglés.

## Cómo jugar

| Tecla | Acción |
|---|---|
| WASD / flechas | Moverse |
| SHIFT | Correr (gasta energía) |
| E | Usar estación · **mantener E** para preparar pedidos y reparar robots |
| L | Cambiar idioma (español / inglés) |
| M | Silenciar / activar el sonido |
| ESC / P | Pausa |
| Mouse | Tablero de pedidos, tienda de robots y proveedor |

- Cada nivel dura un tiempo fijo. Al terminar, ganás de **1 a 3 estrellas** según el dinero juntado.
- Si un cliente se cansa de esperar, perdés una **vida** (hay 3) y pagás una multa.
- Entregar rápido da **propina** y sube el **combo** (hasta x3). Los pedidos **urgentes** pagan el doble.

## Niveles

| Nivel | Qué se agrega | Evento |
|---|---|---|
| 1 — Bodega Fini | Ciclo básico, pedidos en cola, montacargas | Hora pico |
| 2 — Turno de noche | Tablero de pedidos, robots que se atascan | Apagón |
| 3 — Almacén en la nieve | Hielo, stock y proveedor, robots con IA | Tormenta de nieve |

## Cómo abrirlo

1. Instalar [Godot 4.7](https://godotengine.org/download).
2. Clonar el repositorio:
   ```
   git clone https://github.com/juanparequena/GomitasExpress.git
   ```
3. En Godot: **Importar** → elegir `project.godot` → **F5** para jugar.

## Estructura del código

```
scripts/
  game/     reglas del juego (warehouse.gd), IA de robots (task_ai.gd), caminos A* (path_grid.gd)
  actors/   jugador, robots y montacargas
  data/     configuración de niveles, productos, imágenes y textos ES/EN
  world/    estaciones, escenario e iluminación
  ui/       HUD, pantalla de título
scenes/     niveles (level_1..3), jugador, HUD y título
assets/     imágenes de personajes, productos, objetos, vehículos e interfaz; música y efectos (audio/)
tools/      generate_audio.js crea los sonidos (node tools/generate_audio.js)
```

Para ajustar la dificultad (tiempo, metas de estrellas, paciencia de los clientes, eventos), modificá los valores de `scripts/data/levels.gd`.
