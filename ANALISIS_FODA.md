# Gomitas Express — Análisis y FODA

## Resumen
Juego de gestión/acción top-down 2D en **Godot 4.7** (GDScript, ~3.700 líneas). El jugador es operario de un almacén de gomitas FINI.
Ciclo: **PEDIDO → RECOGER (estanterías) → PREPARAR (mantener E 1,5s) → DESPACHAR (camión) → $**. 3 niveles de duración fija (150/180/180 s); al final, 1-3 estrellas según el dinero. Se pierde por tiempo (sin llegar a 1★), por 3 vidas (pedidos vencidos) o por bancarrota (N3).

| Nivel | Novedades |
|---|---|
| 1 Bodega | Solo, pedidos asignados en cola, 1 montacargas, evento "hora pico", pedido tutorial fijo |
| 2 Noche | Tablero para elegir pedidos, robots comprables ($35, máx 3) que se atascan (reparar con E), promo, derrames, apagón (luces 2D) |
| 3 Nieve | Hielo, tormenta (−30% velocidad), stock finito + proveedor (lotes, flete, recepción con 6 huecos), robots con **IA de puntajes** + A* |

Sistemas: propina (>50% de paciencia restante = +30%), combo x1→x3 (solo jugador), urgentes (x2 de pago, x0,6 de tiempo), sprint con stamina, aturdimiento por montacargas (se pierden las gomitas sueltas), ES/EN con la tecla L.

**Arquitectura:** `warehouse.gd` (939 líneas) = reglas + estado; `levels.gd`/`products.gd` = datos de balance; `hud.gd` = solo vista; `scenery.gd` = todo dibujado con `_draw()`; contrato "worker" (`order`/`carrying`/`items`) compartido entre jugador y robot; `task_ai.gd` (scoring) + `path_grid.gd` (AStarGrid2D).

---

## FODA

### Fortalezas
- **Bucle central claro y escalable**: cada nivel suma 1-2 mecánicas sobre la base (buena curva de aprendizaje).
- **Configuración por datos**: todo el balance está en `levels.gd`/`products.gd`, con comentarios; es fácil de ajustar.
- **Reglas compartidas jugador/robot** (`get_blocked_reason` / `use_station`): sin lógica duplicada y coherente.
- **IA explicable**: puntaje con pesos (urgencia, valor, distancia, tamaño, otros robots) + descarte por stock y por tiempo estimado con camino A* real. Se muestra en pantalla → muy defendible académicamente.
- **Mucho feedback**: flecha al objetivo, hint de E con el motivo del bloqueo, barras de paciencia, estados de robot, mensajes de colores.
- **Variedad de presión**: eventos aleatorios, peligros físicos (hielo, derrames, montacargas) y económicos (stock, flete, bancarrota).
- **Bilingüe** completo y código muy documentado en español.
- Identidad visual coherente (tema gomitas, iluminación nocturna, nieve, pantalla de título animada).

### Debilidades
- **Sin audio**: ni música ni SFX (es lo que más le resta "juego terminado").
- **Sin pausa (Esc), sin guardado** (`stars_won` es estático y se pierde al cerrar), sin selector de niveles ni menú de opciones; no hay soporte de gamepad.
- **Botones "PRÓXIMAMENTE"** en la tienda (robot rápido, cinta transportadora) → se nota incompleto; la cinta se dibuja pero no hace nada.
- **Robots inmunes a peligros**: atraviesan hielo, derrames, montacargas y tormenta; no colisionan con el jugador ni entre sí (son Node2D que usan `move_toward`).
- **Pérdida silenciosa de stock**: si vence un pedido o te choca un montacargas, las gomitas ya descontadas de la estantería desaparecen (en N3 puede ser injusto).
- Combo solo para el jugador; los robots no tienen upgrades ni una progresión propia.
- **Deuda técnica**: `warehouse.gd` hace demasiado (god object); estados como strings (`"productos"`, `"pedido"`, `"caja"`, fases) en lugar de enums; pedidos como `Dictionary` sin tipar; `_next_order_later()` usa `await` con un timer, lo que puede dar error si se recarga la escena durante la espera.
- `estimate_time` de la IA usa el centro de las estaciones y no el punto de acceso (subestima un poco).
- Texto con `fallback_font` (sin tipografía propia); juice limitado (sin partículas, screen shake ni tweens de entrega).
- Balance no verificado con datos (metas de estrellas fijadas a mano).

### Oportunidades
- **Audio + juice**: SFX de recoger/empacar/entregar/choque, música por nivel, partículas de $, shake al chocar → gran mejora con poco código.
- Implementar las mejoras ya anunciadas (robot rápido, cinta) → la tienda pasa a tener decisiones reales.
- Pausa, guardado de estrellas (`ConfigFile`), selector de niveles, récords por nivel, modo infinito/arcade.
- Hacer que los robots sufran los peligros (resbalan, se aturden) → refuerza la mecánica de reparación y la IA (evitar zonas peligrosas en A* con pesos).
- Tutorial interactivo en N1 y onboarding de tablero/proveedor.
- Export web (itch.io) para mostrarlo; gamepad; accesibilidad (daltonismo: los productos se distinguen solo por color/icono).
- Refactor ligero (enums, clase `Order`, separar `OrderSystem`/`SupplyChain`) para facilitar las próximas mejoras.

### Amenazas
- **Plazo del parcial**: el alcance ya es amplio; agregar features puede romper sistemas acoplados en `warehouse.gd`.
- **Dificultad mal calibrada**: N2/N3 empiezan con $0/$40 y el robot cuesta $35; si el jugador no entiende el tablero, puede frustrarse rápido.
- Uso de la **marca real FINI** y de arte generado con IA (Gemini): sirve para un trabajo académico, pero es un riesgo legal/de evaluación si se publica.
- **Godot 4.7** (versión muy reciente): posibles incompatibilidades con la versión del evaluador o entre exports.
- Rendimiento: muchos `_draw()` y `get_nodes_in_group()` por frame (hoy alcanza, pero escala mal si se agregan más entidades).

---

## Prioridades sugeridas (impacto / esfuerzo)
1. Audio básico + pausa (Esc).
2. Quitar o implementar los botones "PRÓXIMAMENTE".
3. Robots afectados por peligros / con colisión simple.
4. Guardado de estrellas + selector de niveles.
5. Revisar balance (metas de estrellas, costo del robot) con partidas de prueba.
