# 15 · Interfaz — 02 · Paneles de información de la partida

## Pedido del autor
> "Mejorar la interfaz todo lo posible, no solo mover o mejorar lo que ya hay, sino darle al jugador mucha más información de lo que está pasando en el juego."

Esta parte: los **paneles de información**. Las fichas al pasar el mouse y los indicadores en el mundo los hacen otros dos agentes.

## Qué se hizo
Todo vive en `src/game/ui/panel_*.gd`. Los enganches en `hud.gd` y `main.gd` son mínimos y están marcados con `# --- paneles ---`.

| Tecla | Panel | Qué muestra |
|---|---|---|
| F2 o botón | **Economía** | Ingreso por minuto de cada recurso, incluido el propio (últimos 60 s, a partir del libro de orígenes). Banco y aldeanos por recurso. Barra de aldeanos por tarea, con los ociosos en rojo. Riqueza por origen con barras, total y por minuto. Tabla de todo lo juntado por origen. Barra "Lo disputado: N / tope" con la explicación. Recurso propio con su tope, de dónde sale y en qué se gasta (todo leído de los datos). Sitios sagrados con su dueño y la captura en curso |
| F4 o botón | **Avance de edad** | Qué falta para el próximo hito: recursos con barra, tiempo estimado al ritmo de ahora, aldeanos, hito en obra y población. Las dos opciones con su eje (economía o militar, del campo `eje`), descripción, efecto, renta, máximos extra, qué entrena y costo. Qué habilita la edad. Edad de cada jugador y la hora en que la alcanzó |
| F1, botón o pausa | **Cómo juega mi pueblo** | Ficha de la civ armada desde `data/civs/*.json`: frase, región, descripción, motor propio (recurso propio, acogida, caminos, obra colectiva, saqueo, liberación, conversiones y rentas, con sus números), lo que tiene y los demás no, fuerte en, flojo en (debilidad y edificios que no tiene), hitos por edad con su eje y efecto, consejos y controles. Reemplaza al diálogo de ayuda viejo, que ya mezclaba ficha y controles |
| F5 o clic | **Registro de sucesos** | Lista desplegable con hora: ataques, combates resumidos (perdiste N, abatiste N), edificios terminados y perdidos, edificios enemigos destruidos, investigaciones, edades propias y del rival (con el hito y su eje), sitios tomados y derrotas. Clic en un suceso con lugar: la cámara va ahí y el minimapa marca el punto. Rueda: recorre la lista |
| F6 | **Puntaje en vivo** | Una fila chica por jugador con su edad y su puntaje. Fórmula en `data/interfaz.json` |
| Al terminar | **Fin de partida** | Comparación entre jugadores (edad, puntaje, población, recursos y riqueza juntados, unidades, bajas, edificios construidos, destruidos y perdidos, investigaciones, órdenes por minuto), con el mejor de cada fila resaltado. Gráfico en el tiempo, con muestras de la interfaz cada 30 s: población, aldeanos, ejército, recursos juntados, riqueza y puntaje. Riqueza por origen de cada jugador. Línea de tiempo de edades con el hito elegido |

Los avisos centrales no se tocaron. El registro guarda lo que pasó, pero no suma avisos nuevos (regla de la crítica 04: decisión, pérdida e hito).

## Paso a paso
1. Leí `hud.gd`, `main.gd`, `sim.gd`, `sim_mods.gd`, el diseño final v3 (§3.2 lo disputado, §3.7 interfaz, §11 fichas) y la crítica del jugador nuevo.
2. `panel_datos.gd` junta todo sin tocar la simulación. Una vez por segundo guarda una foto del libro de orígenes, que sirve para el ingreso por minuto. Cada 30 s guarda una muestra por jugador para los gráficos. Arma el registro con los eventos de cada tick.
3. Paneles dibujados a mano, como el resto del HUD: mismas fuentes (`Hud.font`, `Hud.font_b`), `Hud.panel_box` y `Palette`.
4. `--panel=economia,edad,pueblo,sucesos,puntaje,fin` en `main.gd` abre paneles antes de una captura.
5. El autotest suma 6 pasos: F2 abre la economía, la ✕ la cierra, F4 abre la edad, F1 abre y cierra la ficha, F5 despliega el registro y el clic en un suceso mueve la cámara.

## Tropiezos
- **`sim.disputed_room()` escribe en la simulación.** La primera vez crea los baldes de lo disputado (`players[pid]["disp"]`), y esos baldes entran en `state_hash()`. Si la interfaz la llamaba, el hash de una partida con interfaz dejaba de coincidir con el de la misma partida sin interfaz. El panel calcula lo disputado leyendo los baldes sin crearlos ni rotarlos (`panel_datos.gd → disputed()`).
- **Los bloqueos del HUD no miran la visibilidad.** `Hud.blocks()` recorre `_blockers` con `get_global_rect()`, así que un panel oculto seguía tapando clics del mapa. Cada panel entra en `_blockers` al mostrarse y sale al ocultarse.
- **Botonera.** Cuatro botones en 330 px cortaban los nombres. Quedaron tres (Economía, Edad, Mi pueblo); el puntaje se alterna con F6.
- **Campañas.** El panel tapaba a medias los objetivos (fondo con transparencia) y se leían los dos textos encimados. Ahora el fondo de los paneles laterales es opaco.

## Pruebas
- `godot --path . -- --autotest --civ=guaranies --terreno=llano --mute` → **AUTOTEST: OK** (19 pasos: los 13 de antes y 6 nuevos).
- `tests/test_determinism.gd` → **DETERMINISMO: OK**. La simulación no se tocó.
- Capturas en IA contra IA, en una partida normal, en campaña (Palmares, misión 0) y con varias civs (tawantinsuyu, mapuches, palmares, ayutthaya), sin errores de script.

## Capturas
- [Economía y registro desplegado, minuto 10 (Tawantinsuyu)](02-economia-y-sucesos.jpg)
- [Avance de edad, minuto 7](02-avance-de-edad.jpg)
- [Cómo juega mi pueblo (Mapuches)](02-mi-pueblo.jpg)
- [Fin de partida, minuto 20 (Palmares contra Etiopía)](02-fin-de-partida.jpg)

## Pedidos a la simulación (no se tocó `src/sim/`)
1. **`disputed_used(pid)` de solo lectura** en `Sim`, para que la interfaz y la IA no repitan la cuenta de los baldes.
2. **Gasto por destino en `stats`** (unidades, edificios, investigaciones, hitos, mercado). Hoy se ve lo que entra pero no en qué se fue.
3. **Lo perdido por tope:** cuánto recurso propio y cuánto de lo disputado se perdió por llegar al techo. Serviría para el aviso de decisión "Lo disputado llegó a su tope".
4. **`by` en los eventos `alert`**: quién ataca, para poner el color del atacante en el registro cuando hay más de un rival.
5. **Visto en IA contra IA:** Palmares llegó a 159 de población con techo de 156. La acogida o la liberación parecen pasarse del techo; queda para revisar.

## Commits
- Paneles de información de la partida (este commit).
