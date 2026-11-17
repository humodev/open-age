# Paso 3 del juego tardío: la economía del final y la escuela de la edad IV

Fecha: 2026-11-16. Etapa 26, implementación del **paso 3** del plan de entrada de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§1.1, §1.3, §4.3 y §6). Se hizo en paralelo con los pasos 2 (herrería) y 4 (asedio y fortaleza), y se fusionó con los dos antes de las pruebas finales.

> Pedido: la economía III y IV (la tercera mejora de cada recurso en la IV, la vida y la velocidad del aldeano) y la escuela de la IV de cada pueblo, con su nombre y sus seis mejoras compartidas (las ocho propias son el paso 6). La IA las compra con prioridad razonable. Ningún número en el código. Medir sin torneo: el modelo, partidas IA contra IA (a qué minuto compra, cuánto junta en la IV, si llega más a la IV) y las pruebas de siempre.

## Qué cambió

**Datos** (todo lo nuevo lleva `paso: 3` o `--- paso 3 ---`)
- `data/tecnologias.json`, un bloque entre `riego_2` y `mampostería`:
  - economía, como en la tabla de §1.1: `vel_aldeano` (II, +10 % de velocidad), `vida_aldeano` (III, +30 % de vida; después de la velocidad, en la misma casilla del centro), `orfebreria_2` (III, riqueza +15 %), `hachas_3` (IV, madera +15 %), `riego_3` (IV, «la granja como sostén», granja +15 %) y `cestas_2` (IV, +3 de carga);
  - la escuela: `escuela_choque` (+10 % de vida del choque a pie), `escuela_polvora` (+10 % de ataque de la pólvora), `escuela_asedio` (+15 % del asedio contra edificios), `escuela_reparar` (los aldeanos reparan el asedio), `escuela_alcance` (+1 casilla de centros, torres e hitos) y `escuela_registros` (−10 % en las mejoras de la IV).
- `data/civs/<pueblo>.json` → `escuela` (nombre, ficha con las fuentes del §1.3 y los edificios donde se investiga, además de la capital) y `tecnologias.escuela_registros` (el nombre propio):

| Pueblo | Escuela | Dónde (además de la capital) | Registros |
|---|---|---|---|
| Tawantinsuyu | Yachaywasi | la kallanka real | Khipu |
| Mapuches | Trawün de los weupife | el parlamento | El pron |
| Guaraníes | Escritura del cabildo y talleres (vía monte: Óga guasu) | la tava y el aty guasu | Actas del cabildo (vía monte: La memoria del óga guasu) |
| Etiopía | Talleres de Gondar | el recinto de Gondar | Ṣäḥafe tə'əzaz |
| Palmares | Oficinas do Macaco | el Macaco | La memoria de los mocambos |
| Ayutthaya | Phra Khlang | (el wang es la capital) | Chindamani |

  El diseño pone la escuela en edificios que ya existen (la columna «Edificio» del §1.3 y «No necesita arte» del §6): no hay edificio ni maqueta nueva.
- `data/reglas.json`: `ia_compras_tardias` (orden de compra de la IA, reserva, junta desde la IV) y `sitios.renta_edad_pct` (+50 % de renta de los sitios en la IV, §4.3).
- `data/interfaz.json` → `grilla.fijas.escuela`: la casilla del botón de la escuela (F).

**Simulación** (`src/sim/`, todo entero)
- Efectos nuevos en `_apply_effects`: `asedio_pct`, `asedio_reparable` y `costo_tec_pct`. `vida_pct` y `velocidad_pct` con `funciones: ["civil"]` ya existían: son las del aldeano.
- `Sim.tech_cost(pid, tech)`: el costo con el descuento de los registros. Lo usan `_cmd_research`, la grilla y la IA del paso 3.
- `tech_here`: `en: {"escuela": true}` vale en la capital y en `civ.escuela.edificios`.
- El oficio del asedio suma en `_hit` solo si el blanco es un edificio (con el paso 4 el asedio de área también pega a la tropa).
- Reparación en el campo: clic derecho de un aldeano sobre el asedio propio dañado (`can_repair_unit`); repara a la velocidad de su entrenamiento, con la reparación rápida del paso 4.
- `sim_mods.gd`: la renta de los sitios por la edad del dueño.
- **IA** (`sim_ai.gd`, `_late_buys`): normal, difícil y experta (las que investigan). Después de los niveles y antes de la tropa, compra en el orden de `ia_compras_tardias`, una por turno, con el costo más la reserva y si no junta para un hito. Si la primera que le sirve no alcanza, no pasa a otra más barata. Desde la IV **junta** para ella, como los niveles (salvo con la base atacada). Salta la mejora de una línea que su pueblo no entrena y las del asedio si no tiene asedio. Tiene `hachas_2` y `riego_2` en la lista, porque sin ellas no compraba nunca la tercera.

**Interfaz**
- La escuela es un botón con su nombre (casilla F, glifo nuevo `escuela`: una cuerda con cuerdas colgantes y nudos) que abre su submenú con las seis mejoras. Aparece desde la IV y mientras queden mejoras. El título del submenú es el nombre de la escuela; Esc y clic derecho vuelven.
- La ficha de una mejora de la escuela dice «Escuela de la edad IV · <nombre>»; el costo es el de verdad (con los registros).
- Textos de los efectos: «+10 % de velocidad de los aldeanos», «+15 % de ataque del asedio contra edificios», «−10 % de costo de las mejoras de la edad IV», etc. El texto de la edad IV dice «Escuela: <nombre> (6 mejoras, en la capital)».
- Capturas (Guaraníes en la IV, con un cambio local en `main.gd` para poner la edad que no está en el commit):
  - [capturas/07-capital-iv.jpg](capturas/07-capital-iv.jpg): el oga guasu con la escuela en F;
  - [capturas/07-escuela-guarani.jpg](capturas/07-escuela-guarani.jpg): el submenú «Escritura del cabildo y talleres» con las seis, los registros como «Actas del cabildo».

**Herramientas, pruebas y documentos**
- `tools/modelo_progreso.py`: la escuela se lee de `data/` (antes vivía en `PROPUESTA`); `--economia` agrega las tablas 4 y 5 (lo que junta un aldeano por edad y el repago de cada mejora).
- `tools/economia_tardia_ia.gd` (nuevo): partidas IA contra IA con el minuto de cada edad y de cada compra del paso 3, lo recolectado por minuto en la IV y, con `--sin-paso3`, la misma partida sin nada del paso 3.
- `tests/juego_tardio.gd` (nuevo): cada mejora hace lo que dice.
- `tests/casillas.gd`: revisa el submenú de la escuela y que la capital de cada pueblo lo tenga en la IV.
- `docs/05-mecanicas-nucleo.md`: los efectos nuevos y la sección «Economía del final y escuela de la IV».

## Decisiones

- **La escuela de combate da vida al choque a pie**, no a todo el choque: el diseño dice «infantería de choque», y el modelo de antes la sumaba también a los montados (`funciones: choque`). Con la línea, en el modelo bajan los montados de la IV (kona ×1,94 → ×1,87, jinete etíope ×1,87 → ×1,80, elefante ×1,91 → ×1,85) y el salto IV/III de mapuches, Etiopía y Ayutthaya (×1,55 → ×1,50, ×1,34 → ×1,29, ×1,50 → ×1,46). Los demás no cambian.
- **Las misiones no reciben las compras del paso 3 con la edad** (`grant_age_purchases` no cambia): antes ninguna edad las daba, así que las misiones que empiezan en la III o la IV quedan como antes.
- **Los costos son tentativos**, en el orden de los de hoy: 250 a 600 por mejora de economía y 350 a 500 por mejora de la escuela.

## Medidas

**Modelo** ([pruebas/07-modelo-progreso.txt](pruebas/07-modelo-progreso.txt)). La tabla 1 no cambia. Tabla 4, lo que junta un aldeano por minuto con toda la economía de su edad (supuestos de distancia en el modelo):

| | III | IV antes del paso 3 | IV con el paso 3 | IV / III |
|---|---|---|---|---|
| Madera | 44,4 | 42,9 | 51,1 | ×1,15 |
| Granja | 53,6 | 52,8 | 60,2 | ×1,12 |
| Piedra | 34,3 | 33,2 | 36,5 | ×1,06 |
| Riqueza | 37,1 | 33,2 | 39,7 | ×1,07 |

El veterano pedía que la economía creciera un 15–25 % en la IV: con 15 % de tasa queda en el borde de abajo para la madera y por debajo para la granja. Las de la IV se pagan solas en 3 a 9 minutos con 15 aldeanos. Los registros cuestan 400 y ahorran 817 si se compra todo lo de la IV (se pagan desde el 49 %).

**Partidas IA contra IA** ([pruebas/07-economia-tardia-ia.txt](pruebas/07-economia-tardia-ia.txt); `tools/economia_tardia_ia.gd`, normal, 45 minutos, 3 semillas, 18 partidas y 36 jugadores por modo; con el paso 2 y sin el 4):

| | Con el paso 3 | Sin el paso 3 (mismas semillas) |
|---|---|---|
| Llegan a la III | 24 de 36 | 28 de 36 |
| Llegan a la IV | 4 de 36 (4 de 18 partidas, 22 %) | 4 de 36 (4 de 18, 22 %) |
| Mediana de la III / de la IV | 18:57 / 33:46 | 20:31 / 30:46 |
| Recolectado por minuto en la IV (mediana) | 1080 (n = 3) | 1318 (n = 4) |
| Duración media | 33,4 min | 32,1 min |

Cuándo compra (desde que llega a la edad de la mejora):

| Mejora | Cuántos la compraron | Mediana después de la edad |
|---|---|---|
| Sendas de trabajo (II) | 25 de 35 | 9:26 (0:33–25:15) |
| Tejidos de abrigo (III) | 15 de 24 | 3:52 |
| Talleres de la riqueza (III) | 5 de 24 | 4:31 |
| Registros (IV) | 2 de 4 | 4:17 |
| Tala de monte alto (IV) | 2 de 4 | 6:17 |
| Fardos de carga / Barbecho y abono (IV) | 1 de 4 cada una | 8–9 min |

Lectura:
- **El paso 3 no hace llegar más a la IV.** Es lo esperable: lo que da está casi todo **después** de llegar. La meta del 40–60 % de partidas en la IV (§6) no depende de este paso: con la IA de hoy, en 45 minutos llega a la IV un 22 % con y sin el paso 3 (la diferencia en la III y en lo recolectado está dentro del ruido: 4 jugadores en la IV).
- **La primera versión no juntaba** y en la IV no compraba nada en diez minutos: la tropa gastaba todo (5 jugadores en la IV, ninguna compra de la IV; está en el mismo archivo). Juntando, compra los registros a los 4 minutos y sigue con una por minuto, pero el élite va primero y con él se va casi todo.
- **La velocidad del aldeano llega tarde** (mediana 9 minutos después de la II): en la II la IA junta para el hito de la III y no compra mientras tanto (`ahorrando: false`). Si el torneo pide la economía antes, se pone en `true` para esa mejora o se la deja comprar mientras junta.

**Pruebas** ([pruebas/07-pruebas.txt](pruebas/07-pruebas.txt)), con main fusionado (pasos 2 y 4):
- `test_determinism.gd`: **el hash no cambia** (2203695307): la prueba corre en la edad I.
- `bench.gd`: promedio 13,0–13,7 ms y peor tick 149–151 ms (presupuesto 100 ms), con Godot de otros agentes corriendo al lado. El paso 3 no agrega nada por tick en la edad I salvo un recorrido corto de la IA.
- `juego_tardio.gd`, `casillas.gd` (504 grillas), `jugabilidad.gd`, `civ_smoke.gd` y `campaign_smoke.gd`: sin errores.
- Autotest con guaraníes en llano: `AUTOTEST: OK`.

## Tropiezos

- El botón de la escuela iba primero entre las investigaciones; en el lof mapuche, que entrena tropa, el submenú «Investigaciones» ya estaba lleno y la escuela no aparecía. Pasó a una casilla fija (F).
- Con la escuela en F, la capital en la IV con todo por comprar tiene 9 investigaciones y van al submenú «Investigaciones (9)» (captura). Ya pasaba sin la escuela con la velocidad y la vida del aldeano.
- La IA no compraba la tala ni el riego de la IV: no compraba antes la segunda. Se agregaron `hachas_2` y `riego_2` a su lista.
- Al fusionar el paso 4, el bono del asedio por edad ya no estaba en `attack_pct`: el oficio del asedio pasó a `_hit`, contra edificios.

## Riesgos y lo que queda

- **El torneo lo corre el orquestador.** Las medidas son de 18 partidas por modo y de la IA normal; pocas llegan a la IV, así que lo de la IV tiene n = 2 a 4.
- **La IV en el 40–60 %** necesita otra cosa: la IA tiene que querer subir (y el paso 7, la economía que camina). El paso 3 da en qué gastar al llegar, no un motivo para llegar antes.
- **Conflictos con otros pasos:** `data/tecnologias.json` (bloque propio antes de `mampostería`), `sim.gd` (`_apply_effects`, `_hit`, `tech_here`, `_cmd_research`), `sim_ai.gd` (`think`, `_late_buys`), `controller.gd` (la grilla de investigaciones y `effects_text`) y `reglas.json` (línea propia antes de `sitios`). Los pasos 2 y 4 ya están fusionados.
- El descuento de los registros vale para todas las mejoras de la IV, también la herrería III y los élites: la IA de los niveles todavía aparta el costo sin descuento (un poco de más durante un turno).
- La IA no repara el asedio en el campo; solo el jugador.
