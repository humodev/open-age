# Paso 7 del juego tardío: la maravilla, el final de partida y que se llegue a la IV

Fecha: 2026-11-17. Etapa 26, **paso 7** del plan de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§4 y §6).

> Pedido:
> - una maravilla por pueblo en la IV, con el nombre y la forma del diseño revisado por los historiadores (nada sagrado como arma; lo que no se puede construir no se construye), en maqueta procedural con la escala nueva;
> - victoria por maravilla con cuenta regresiva como en AoE4, visible para todos, con aviso y activable en las opciones de partida;
> - que la IA quiera subir a la IV y que ataque o defienda una maravilla;
> - lo que el §4 y el §6 piden para el final;
> - en la interfaz, la cuenta en el HUD, la ficha y el aviso con sonido.
>
> Medir sin torneo: la meta es la IV en el 40–60 % de las partidas de 45 minutos, y que la maravilla no sea la forma dominante de ganar.

## Qué cambió

### La maravilla (datos)

**`data/edificios.json` → `maravilla`:** lo común, tal como C-78 a):
- costo de 1500 de madera, 1500 de piedra y 1500 de riqueza;
- obra de 600 s con 10 constructores (`tiempo_ms` es el de uno; la obra decreciente da ×3/12);
- huella de 6×6, 9000 de vida, edad IV.

**`data/civs/<pueblo>.json` → `edificios.maravilla`:** nombre, ficha con fuentes, forma (`arte`) y efecto (`efectos_maravilla`) de cada pueblo, según el §3 del diseño. El aldeano la construye (`construye`); las facciones de IA, no.

| Pueblo | Maravilla | Mientras está en pie |
|---|---|---|
| Tawantinsuyu | Ollantaytambo | Cuando entran 3 soldados enemigos al llano junto al agua (a 12 casillas), se inunda: andan a la mitad 45 s, una vez cada 5 minutos |
| Mapuches | El gran koyagtun | Sin enemigos a 4 casillas, los rivales no toman los sitios sagrados a 15 casillas |
| Guaraníes, vía misión | La plaza y el cabildo de la tava (`requiere_hito: mision`) | El potirõ suma el doble por constructor |
| Guaraníes, vía monte | Aldea grande del monte (`maravilla_monte`, `requiere_hito: monte`, C-85 a) | La tropa escondida en el monte se ve desde la mitad de la distancia |
| Etiopía | Fasil Gəbbi | La corte no se muda (ni la corte nueva ni el empaque) y los gult rinden +25 % |
| Palmares | Cerca do Outeiro da Barriga (`impide_hito: pacto_cucau`) | La fama no se pierde por el tope y la acogida cuesta la mitad. **Sitiada** (C-97 a): no cae (le queda 1 de vida), y con tropa enemiga a 3 casillas la cuenta vuelve a empezar |
| Ayutthaya | Krung Si Ayutthaya y Pom Phet | El agua baja a 15 casillas de la capital frena 30 % a la tropa enemiga, salvo a 4 casillas de una torre o un fuerte suyo |

**Decisiones por defecto respetadas:**
- **Sin lo sagrado:**
  - el koyagtun no muestra el rito (ni canelo ni sacrificio);
  - Fasil Gəbbi va sin las iglesias del recinto y sin la cruz de la torre, que el castillo común sí lleva;
  - el cabildo no es la fachada de la iglesia;
  - la aldea del monte no tiene bastones rituales;
  - Krung Si no tiene el wat (C-79 a).
- **Lo que no se puede construir no se construye:**
  - no hay Lalibela, Wat Phra Si Sanphet ni *tekoha guasu*;
  - con el Pacto de Cucaú, la Cerca no se puede levantar (C-68 a).
- **Ningún efecto da combate directo:** todos son de movimiento, sitios, economía u obra.
- **Lalibela como hito:** sigue siendo la forma del monasterio etíope (`arte_hitos.json`). No es la maravilla, y la C-69 no se tocó en este paso.

`data/reglas.json`:
- `maravilla.victoria_ms`: 15 minutos;
- `puntaje.por_maravilla`: 1000, porque la maravilla en pie suma puntos en el tiempo límite (§4.4.5);
- `opciones_partida.menu.maravilla`: prendida.

### Simulación (`src/sim/`, todo entero)

**`sim.gd`:**
- `wonder_of`, `build_block` (una por jugador, `requiere_hito`, `impide_hito`, corte fija) y `has_done_hito` (los jugadores guardan `hitos_hechos`).
- `_wonders`, una vez por segundo: la cuenta `maravilla_ms`, la sitiada y `win(pid, "maravilla")`. No corre con `maravilla_sin_victoria` ni en las misiones.
- `wonder_left_s`.
- Sucesos nuevos: `maravilla_obra`, `maravilla`, `maravilla_cae`, `maravilla_sitiada` e `inundacion`.
- El puntaje suma la maravilla en pie.

**`sim_mods.gd`, sección «Maravillas»:**
- `wonder_fx` y `_wonder_tick`, una vez por segundo;
- el agua que frena se arma con `_low_water`, guardada medio minuto;
- la inundación (`_flood`) y la crecida (`_rising`);
- los ganchos en la velocidad, los sitios, la renta, la acogida, el tope del recurso propio, la detección y la obra.

**`sim_data.gd`:** `hereda` en `edificios_nuevos`. La maravilla de la vía monte parte de la común.

### Final de partida (§4 y §6, paso 7)

**Hecho:**
- maravilla y victoria por maravilla;
- la maravilla en pie suma puntos;
- **rendición en todas las dificultades** (§4.4.4): normal, difícil y experta se rinden si perdieron 10 edificios, tienen menos de un tercio del mayor ejército rival visto y les atacan la capital (`dificultades.<nivel>.rendicion`). La fácil, como antes.

**Lo demás del §4 ya estaba** con el paso 3 (sitios +50 % en la IV, tercera tanda de economía, la granja como sostén) y el paso 4 (fortaleza, asedio).

**No entró el comerciante que camina** (§4.3.2):
- C-80 a) dice que una unidad nueva espera al arte;
- en 1 contra 1 su único destino sería el ingenio, que hoy es hostil y le dispara.

Queda para retomar, con una consulta (ver Riesgos).

**Frase al rendirse:** la IA dice «se rinde» en el aviso. No se escribieron frases de cada pueblo, para no inventar citas.

### IA (`sim_ai.gd`; `reglas.ia_edad_iv` e `ia_maravilla`; normal, difícil y experta)

- **Subir a la IV** (`_wants_up`). Desde la III, ahorra para el hito **sin pausa** cuando se cumplen tres cosas:
  - tiene 30 aldeanos;
  - tiene el ejército mínimo de la edad;
  - el rival no le saca más del 150 % de ejército (el mayor que vio en 3 minutos).

  Antes ahorraba un tercio del tiempo.
- **Vender lo que sobra** (`_trade`). Si a la meta le falta algo y la riqueza no alcanza, vende lo que pasa de la meta en más de 200.

  El diagnóstico (Tawantinsuyu contra Ayutthaya, semilla 5065) mostró a la IA en la III durante 29 minutos con 1800 de madera y 1700 de alimento, y la piedra quieta en 245.
- **Maravilla** (`_wants_wonder`, `_keeps_wonder`). Tres minutos después de llegar a la IV, ahorra para ella como para un hito y manda 10 constructores. Necesita:
  - 35 aldeanos y 20 de tropa;
  - que el rival no le saque ejército;
  - que no haya una maravilla rival.

  Mientras junta no compra niveles ni torres, y con la base atacada sigue juntando si tiene tropa. Una vez decidida, sigue mientras le quede la mitad de la tropa: sin ese compromiso, el banco se iba en tropa cada vez que bajaba un soldado y no se levantó ninguna.
- **Maravilla rival** (`_hit_wonder`). Es el blanco antes que cualquier otro:
  - en obra, con 6 o más;
  - terminada, con lo que haya.

  La propia en obra se defiende como el hito en obra.
- **El objetivo del ahorro:** `_goal`, `_goal_cost` y `_goal_builders` reemplazan al hito fijo en la economía, la construcción, la producción, el mercado y la expansión. Con un hito, el resultado es el mismo que antes.

### Interfaz

- **Grilla:** la maravilla va en la raíz del aldeano, en la casilla C (`interfaz.json → grilla.fijas.maravilla`), solo desde la IV. Con candado y motivo si no se puede («Requiere el hito Misión», «Pacto de Cucaú cerró este camino», «Ya hay una maravilla»). La ayuda da el efecto con los números de los datos (`Controller.wonder_text`).
- **Ícono propio:** `maravilla`, una obra de tres cuerpos con estandarte, sin símbolos sagrados (`iconos.gd`, `data/iconos.json`).
- **Cuenta grande arriba al centro** (`CuentaGrande`), con el color del dueño:
  - la propia: «OLLANTAYTAMBO EN PIE · GANÁS SI RESISTE»;
  - la rival: «ROJO: FASIL GƏBBI · DESTRUILA».

  Si corren a la vez las cuentas de los sitios y de la maravilla, se muestra la que termina antes.
- **Panel de la edad:** «Maravilla: gana en 14:57» o «¡Maravilla rival! …».
- **Ficha:**
  - el rol «Maravilla de la edad IV»;
  - el efecto y cómo gana;
  - la barra de la cuenta;
  - «Sitiada: con tropa enemiga adentro la cuenta no corre».
- **Avisos con lugar**, que saltan con un clic y señalan el minimapa: empezó, terminó, cayó, sitiada, inunda. **Todos la ven**, aun con la niebla (`WorldView.fog_state`).
- **Sonido:**
  - la propia terminada suena con la fanfarria del pueblo (sintetizada y ya revisada sin instrumentos sagrados, proceso/24, 4h);
  - la rival, con la alerta de la interfaz;
  - cuando cae, con el aviso de edad.

  No se usa la campana.
- **Menú:** interruptor «Maravilla» en Victoria (`--maravilla=no`, opt `maravilla_sin_victoria`). El resumen dice «… o por maravilla (15 minutos en pie)».
- **Maquetas** (`hitos_meshes.gd`, `data/arte_hitos.json`): las siete formas, con categoría de escala propia (`escala_visual.altura_min_cm.maravilla`: 720). `--demo=maravilla` pone la del pueblo terminada.

**Capturas:** [Tawantinsuyu](capturas/10-maravilla-tawantinsuyu.jpg), [mapuches](capturas/10-maravilla-mapuches.jpg), [guaraníes (las dos vías)](capturas/10-maravilla-guaranies.jpg), [Etiopía](capturas/10-maravilla-etiopia.jpg), [Palmares](capturas/10-maravilla-palmares.jpg) y [Ayutthaya](capturas/10-maravilla-ayutthaya.jpg).

### Herramientas y pruebas

- **`tools/maravilla_ia.gd` (nueva):** partidas IA contra IA como el torneo (mapa al azar). Da el minuto de cada edad, cada maravilla puesta, terminada o caída, lo que le faltaba a su cuenta y cómo terminó la partida. `--sin-paso7` apaga lo del paso 7 con el mismo código.
- **`tests/maravilla.gd` (nueva):** 45 comprobaciones de reglas y efectos.
- **`tests/grilla.gd`:** la maravilla va en la raíz, como los hitos.
- **Documentos:** `docs/05-mecanicas-nucleo.md` (victoria y rendición) y `docs/08-ia-rival.md` (edad IV y maravilla).

## Medidas

### 45 minutos, normal, 18 partidas, mismas semillas

Resultados en [pruebas/10-maravilla-ia-45.txt](pruebas/10-maravilla-ia-45.txt).

| | Sin el paso 7 | Con el paso 7 |
|---|---|---|
| **Partidas con la IV** | **1 de 18 (5 %)** | **11 de 18 (61 %)** |
| … de las que duran 25 min o más | 1 de 10 | 9 de 10 |
| Jugadores en la IV (mediana) | 1 (39:24) | 14 (26:42; de 19:48 a 38:36) |
| Jugadores en la III (mediana) | 20 (18:48) | 21 (19:00) |
| Maravillas puestas / terminadas / ganadas | 0 / 0 / 0 | 1 / 0 / 0 |
| Fin | conquista 9, sitios 6, abiertas 3 | sitios 5, conquista 4, rendición 4, abiertas 5 |
| Duración media | 29,5 min | 30,1 min |

Versiones intermedias, con las mismas semillas:
- solo el ahorro sin pausa: **22 %**;
- con la venta de lo que sobra: **50 %**, pero ninguna maravilla;
- con el compromiso con la maravilla: **61 %**, y una maravilla.

### 60 minutos, normal, 18 partidas, otras semillas (3 a 5)

Resultados en [pruebas/10-maravilla-ia-60.txt](pruebas/10-maravilla-ia-60.txt). Con estas semillas hay espejos: el par se arma como en el torneo.

- **La IV:** 13 de 18 partidas (72 %), y 13 de las 14 que duran 25 minutos o más. 18 jugadores; mediana 28:54.
- **Maravillas:**
  - **4 puestas**, entre los minutos 31 y 58;
  - **una cayó en obra** a los 21 segundos, por el ataque prioritario del rival;
  - **una terminó** (52:52) y seguía en pie a los 60 con 7:53 por delante;
  - **ninguna partida terminó por maravilla.**
- **Fin:** rendición 6, sitios 4, conquista 3, abiertas 5. Duración media: 41,8 min.

### Lectura

- **La meta de la IV se cumple:** 61 % en 45 minutos, en el borde de arriba del 40–60 %, contra 5 % sin el paso.
  - Las partidas que no llegan terminan antes de los 25 minutos, por sitios o por conquista.
  - Cuando la partida dura, casi siempre se llega.
- **La maravilla no domina:**
  - ninguna partida termina por maravilla, en 45 ni en 60 minutos, y ninguna termina antes de tiempo;
  - la más rápida posible: la IV a los 20, 3 minutos de espera, juntar 4500 y 10 de obra, más 15 de cuenta, da más de 50 minutos;
  - hoy la maravilla es una amenaza de partida larga, como en AoE4.
- **La rendición** aparece en 4 de 18 (45 min) y 6 de 18 (60 min). En 45 minutos reemplaza a conquistas que ya estaban decididas: con las mismas semillas y sin el paso, tres de esas partidas terminaban por conquista con el mismo ganador entre 0:13 y 5:30 después. La cuarta (guaraníes contra Palmares) quedaba abierta sin el paso; con él, llega a la IV y termina por rendición a los 43.
- **Rendimiento:** `bench.gd` da 9,74 ms de promedio y 98,5 de peor caso (antes, 9,0–13,7 y 93–151, según la carga de la máquina). Los efectos de las maravillas solo corren con una en pie.

## Tropiezos

- **La primera versión llegaba a la IV en el 22 %:** la IA se quedaba en la III con el banco lleno de lo que no hacía falta y le faltaba piedra o riqueza (diagnóstico minuto a minuto). Se resolvió vendiendo lo que sobra.
- **Con la IV resuelta, ninguna maravilla.** La IA juntaba 1600 de riqueza y 1260 de piedra, y al minuto siguiente lo gastaba:
  - una torre, porque había piedra;
  - los niveles;
  - tropa, cada vez que su ejército bajaba de 20 o la atacaban.

  Se resolvió con el compromiso (`_keeps_wonder`), sin niveles ni torre mientras junta y juntando también con la base atacada si tiene tropa.
- **Un error de tipos en `menu.gd`** (`ways[...]` sin tipo) solo aparecía al abrir el juego con ventana, no en las pruebas sin cabeza.
- **El castillo de Gondar lleva la cruz** de la edad en la torre alta. En Fasil Gəbbi se saca, porque el diseño pide el recinto sin lo eclesiástico.
- **La línea de la cuenta en el panel de la edad** se salía por abajo: pasó a la derecha de «Sitios».

## Riesgos y lo que queda

- **El torneo lo corre el orquestador.** Más partidas en la IV cambian el balance:
  - la escuela, los élites y el asedio pesado entran en juego;
  - la IA guarda en la III en lugar de gastar en tropa, así que un rival agresivo puede castigarla. Por eso mira el ejército rival;
  - la rendición nueva puede mover los porcentajes por pueblo (Palmares y guaraníes se rinden en las dos medidas).
- **Hash:** `test_determinism.gd` da el mismo hash (2203695307). Corre en la edad I y no ve nada del paso 7.
- **El comerciante que camina no está.** Consulta propuesta para el autor (no la agregué a CONSULTAS.md, por el pedido):
  - a) entra con el arte de los comerciantes, cuando haya;
  - b) entra ya con la maqueta del aldeano, entre el mercado propio y uno aliado. Para 1 contra 1 hace falta un puesto neutral de comercio, porque el ingenio es hostil.
- **Interpretaciones del diseño que conviene confirmar:**
  - «la obra colectiva no tiene tope»: hoy el potirõ no tiene tope, así que se leyó como «suma el doble por constructor»;
  - «la fama no baja»: se leyó como «no se pierde por el tope»;
  - la inundación inca es automática: el diseño no dice quién la dispara;
  - Ollantaytambo y la crecida solo hacen algo si hay agua cerca: en mapas llanos sin río no dan nada.
- **Las maquetas** son de maqueta (D-015) y las fichas llevan los [verificar] del diseño. Las consultas a comunidades (§7) siguen pendientes: Ollantaytambo, el koyagtun, la Barriga y las dos guaraníes.
- **Posibles conflictos al fusionar:**
  - `data/reglas.json`: dificultades normal, difícil y experta; el bloque nuevo antes de `sitios`; `puntaje`; `opciones_partida.menu`; `escala_visual`;
  - `data/civs/*.json`: la primera línea de `edificios` y `construye`; los guaraníes, también la primera de `edificios_nuevos`;
  - `src/sim/sim_ai.gd`: `think`, `_wants_hito`, `_production`, `_buildings`, `_trade`, `_surrenders`, `_military`, `_threat`, `_levels`;
  - `src/sim/sim.gd`: `_cmd_build`, `_complete`, `_hit`, `_kill`, `score`, `step`, `_cmd_pack`;
  - `src/sim/sim_mods.gd`: `speed`, `_sacred`, `_rents`, `_welcome`, `_own_resource`, `detected_by`, `build_step`;
  - `controller.gd`, `hud.gd`, `ficha.gd`, `menu.gd`, `main.gd` (`match_opts` y `_demo`), `hitos_meshes.gd`, `civ_meshes.gd`, `world_view.gd`;
  - `data/arte_hitos.json` y `data/interfaz.json`.
