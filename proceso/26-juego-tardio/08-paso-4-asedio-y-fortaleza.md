# Paso 4 del juego tardío: el asedio que rompe y la defensa que aguanta

Fecha: 2026-11-16. Etapa 26, implementación del **paso 4** del plan de entrada de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§1.1, §2, §4.2 y §6). La consulta C-76 va por defecto (a): los hitos militares de la III y la IV dan su bono en aura. El torneo lo corre el orquestador al final del hito; acá se midió sin torneo.

> Pedido: asedio de área en la III con el nombre y la forma de cada pueblo (y lo que el diseño le da en su lugar a quien no lo tuvo); niveles del asedio que reemplacen el `bono_ataque_asedio` por edad sin perder poder; la fortaleza de la III con nombre por pueblo y maqueta procedural; mejoras de defensa; hitos militares de la III y la IV con aura. Cuidar la micro C2. La IA usa el asedio nuevo y levanta la defensa. Ningún número en el código.

## Qué cambió

**Asedio sin bono por edad**
- `data/edades.json`: sale `bono_ataque_asedio`.
- El asedio es una línea (`SimData.line_of` → `asedio`), con sus niveles en el edificio que lo entrena: `veterano_asedio` (III, +11 % de ataque y +5 % de vida) y `elite_asedio` (IV, +13 % y +5 %).
- El +10 % que daba la II pasó al ataque base: ariete 45 → 49, hondero de piedra caliente 32 → 35, cañón de tacuara 38 → 41.
- Con los niveles, el ataque queda igual que antes en las tres edades (`tests/asedio.gd`: 49/54/60, 35/38/43 y 41/45/50; solo el guaraní de la IV pega 1 menos, 50 contra 51).
- La IA compra el nivel apenas tiene una pieza de asedio (`reglas.ia_asedio.asedio_para_nivel`), aparte de las dos líneas con más tropa del paso 1.
- Las misiones que empiezan en la III o la IV lo reciben con `grant_age_purchases`, como los otros niveles.

**Asedio de área (III)**: `catapulta` en `data/unidades.json`. Mecánica nueva en `Sim._splash`:
- el golpe le llega a cada enemigo a `area` o menos del blanco, con su armadura, entero en el centro y `area_borde_pct` en el borde;
- busca en la grilla de enemigos (`_ehash`): no recorre el mapa;
- no daña a los propios;
- efecto `area` para la imagen: polvo en el círculo del golpe.

Hay tres claves nuevas de datos que sirven para cualquier unidad:
- `contadores` (los multiplicadores del que pega);
- `recibe` (lo que le pegan los demás);
- `bono_material` (contra edificios de madera o de piedra).

| Pueblo | Asedio de la III | Cómo |
|---|---|---|
| Tawantinsuyu | **Hondero de piedra caliente** | `reemplaza` al ariete desde la III: el ariete deja de entrenarse (los que hay siguen) y el nuevo pega en área y conserva parte del daño contra edificios |
| Mapuches | **Incendiarios** (sin área) | Gente a pie con antorchas: solo edificios, triple daño contra la madera y poco contra la piedra. La distancia los daña entero. En la ruka de guerra |
| Guaraníes | **Cañón de tacuara** | Reemplaza al ariete como el inca; se rompe a los 8 disparos |
| Etiopía | **Pieza ligera** | En el taller |
| Palmares | — | No tuvo asedio: en su lugar, la defensa (el baluarte con espinas) |
| Ayutthaya | **Cañón de muralla** | Metralla: más radio y menos daño |

**Fortaleza (III)**: `fortaleza` en `data/edificios.json` (3×3).
- Dispara andanadas como la torre, más fuerte, y aloja guarnición.
- La maqueta es procedural (`CivMeshes._fortress`): de piedra, con lienzos almenados, torres en las esquinas y torreón; de madera, con troncos aguzados, torres de postes y casa de vigía con techo de paja.

| Pueblo | Nombre | Material |
|---|---|---|
| Tawantinsuyu | Hatun pukara [verificar el compuesto] | piedra |
| Mapuches | Pukara (de frontera; Dillehay, 2007) | madera y tierra |
| Guaraníes | Trinchera de tacuara | madera |
| Etiopía | Fortaleza de amba | piedra |
| Palmares | Baluarte da cerca (nombre descriptivo [verificar]); con espinas, como la cerca | madera |
| Ayutthaya | Pom (ป้อม) | piedra |

**Mejoras de defensa** (`data/tecnologias.json`):

| Mejora | Edad | Dónde | Efecto |
|---|---|---|---|
| Aspilleras | III | fortaleza | +1 flecha por andanada a todo lo que dispara |
| Mampostería II | III | centro, después de la I | +20 % de vida a los edificios |
| Fortaleza reforzada | IV | fortaleza | +30 % de vida y +2 flechas a la fortaleza |
| Reparación rápida | IV | fortaleza | reparación al doble |

Efectos nuevos: `edificio_flechas`, `edificio_vida_pct` con `tipos` y `reparacion_pct`. La andanada se cuenta en `Sim.volley_shots`, que también usan el panel y la ficha.

**Hitos militares con aura (C-76 a)**:
- `reglas.aura_hito.militar.combate_desde_edad: 3`.
- Al terminar un hito militar que lleva a la III o la IV, su bono de combate (ataque, armadura con o sin `contra`, vida, velocidad, ataque %) no se suma al jugador. Queda en `players[pid].aura_combate`.
- Cada segundo, `Sim._aura_combat` marca qué tropa propia está a `radio` (9 casillas) del hito en pie (`SimEntity.aura_bits`). `effective_attack`, `effective_armor` y `_apply_stats` suman lo del aura.
- Lo que no es de combate (vida de edificios, recolección) sigue global, y los hitos de la II también.
- La ficha del hito dice «A 9 casillas del hito o menos: …».
- Con `combate_desde_edad: 0` todo vuelve a ser global: es el interruptor si el torneo lo pide.

**IA** (`sim_ai.gd`, bloques `# --- paso 4 ---`):
- `_siege_units` elige el asedio contra edificios (el ariete, su reemplazo de la III o los incendiarios) y el de área.
- El de área sale si el rival tiene `enemigos_min` militares y el ejército propio `ejercito_min`, hasta 1 + oleada / `oleadas_por_unidad` (tope `tope`).
- Con los dos, entrena el que falta más: en la primera versión el ariete llenaba el taller y Etiopía no sacó ninguna pieza de área en 45 minutos.
- `_fortress`: una fortaleza (`fortalezas` por dificultad; por defecto 1) junto al centro, del lado del rival, con 25 aldeanos o más y **solo cuando no ahorra para el hito**. Con la reserva de la piedra del hito no la levantaba nadie.
- Las mejoras de defensa las compra `_research` cuando sobra, como las demás.

**Interfaz**:
- Glifos `catapulta` y `fortaleza`; maqueta de pieza de campaña (cureña, ruedas y caño) para la pieza ligera y el cañón de muralla; antorcha para los incendiarios.
- El botón del ariete no aparece cuando lo reemplaza otro.
- Ficha: «Nivel · el asedio» y «Área: 1,0 casillas · 40 % en el borde». La edad dice «Ataque de edificios +N %» (ya no «y asedio»).
- Demo nueva `--demo=asedio`: la fortaleza, el asedio de la III y un bloque rival.

**Herramientas y pruebas**
- `tests/asedio.gd` (nueva): ataque del asedio por edad, área, reemplazo, aura, fortaleza y material.
- `tools/asedio_ia.gd` (nueva): partidas IA contra IA con asedio y fortalezas; con `--caida`, cuánto tarda en caer una defensa.
- `tests/bench.gd -- --asedio`: 20 catapultas entre las 200 unidades.
- `tools/modelo_progreso.py` lee la regla del aura de `data/` (`--hitos-globales` para comparar con antes).
- `tools/modelo_micro.py` ya no suma el bono del asedio.
- `docs/05-mecanicas-nucleo.md`: efectos nuevos, «Asedio y defensas» (paso 4), el ataque y las edades.

## Decisiones

- **Números del área, distintos del diseño.** Con los del diseño (20 de ataque, 1,2 casillas, 50 % en el borde y casi inmune a la distancia, como el ariete), dos catapultas en una mezcla de 20 le ganaban **5 de 5** a la mezcla igual sin asedio, con cualquier micro: mantener y escalonar, o formación abierta. Rompía la C2.
  - Se probaron cuatro variantes ([pruebas/08-micro-asedio.txt](pruebas/08-micro-asedio.txt)).
  - Queda: 16 de ataque, 1 casilla, 40 % en el borde y armadura a distancia 1, y la distancia le pega el 40 % (`recibe`).
  - Así, a 20 contra 20 el asedio gana de 2 a 3 de 5 según el lado. A 10 contra 10 (una catapulta) no alcanza: el asedio de área es para las bolas grandes, como pide el diseño.
  - El choque sigue siendo la respuesta: 3 guerreros le ganan a 2 catapultas solas 4 de 5. La distancia sola no: 6 honderos contra 2 catapultas, 0 de 5.
- **El ariete inca y el guaraní pasan a la ranura de área** (lo dice el diseño), pero solo **desde la III**: en la II siguen como hoy. La alternativa, sacarlos de la II, dejaba a dos pueblos sin asedio en la II, con un riesgo de balance que no se puede medir sin torneo.
  - Desde la III conservan parte del daño contra edificios (`contadores.edificio` 700 y 600).
  - El precio: rompen fortalezas peor que un ariete. Tres cañones de tacuara no tiran una trinchera, porque se rompen antes.
- **La fortaleza aguanta y no tranca la partida**:
  - 3 arietes con los niveles la tiran en **61 s**; a una torre, en 22 s.
  - El choque solo (15 guerreros), los incendiarios solos o el asedio de área solos **no** la tiran.
  - En partidas, la IA la levanta en 9 de las 19 veces que llega a la III, entre el minuto 18 y el 30. La atacaron 3 veces y ninguna cayó: la IA ataca la capital y los hitos, no la fortaleza.
- **No se tocó la herrería III** (el plan del paso 4 la baja a +1): es del paso 2, y el aura ya baja la IV.
- **Sin el sanador, el cañón de la IV ni el ataque al suelo (J-05)**: no estaban en el pedido. Quedan para el resto del paso 4.

## Medidas

**Micro** ([pruebas/08-micro-asedio.txt](pruebas/08-micro-asedio.txt)):
- La matriz por defecto en la III con compras (sin asedio) da **las mismas filas** que main: la micro C2 sin asedio no cambia.
- Con asedio y los números finales:

| A | B | A gana |
|---|---|---|
| mezcla de 20 | mezcla de 16 + 2 catapultas | 2/5 (diseño: 0/5) |
| mezcla de 16 + 2 catapultas | mezcla de 20 | 5/5 (diseño: 5/5) |
| mezcla de 20, formación abierta | mezcla de 16 + 2 catapultas | 2/5 (diseño: 0/5) |
| mezcla de 10 | mezcla de 7 + 1 catapulta | 5/5 |
| 3 guerreros | 2 catapultas | 4/5 |
| 6 honderos | 2 catapultas | 0/5 |

Mantener y escalonar contra el asedio llega al tope de 150 s con los dos bandos vivos: el asedio no puede entrar y la mezcla no lo alcanza.

**Modelo** ([pruebas/08-modelo-progreso.txt](pruebas/08-modelo-progreso.txt)). El aura saca del ejército que ataca lejos los hitos militares de la III y la IV. Contra el rival de la misma edad con las reglas de antes:

| | Δ III | Δ IV |
|---|---|---|
| Tawantinsuyu | −18 % | −29 % |
| Mapuches | −8 % | −25 % |
| Guaraníes | −8 % | −26 % |
| Etiopía | −8 % | −19 % |
| Palmares | **−21 %** | **−39 %** |
| Ayutthaya | −1 % | −14 % |

- Es lo que el diseño busca («lo que más baja la inflación de la IV»): ese poder pasa a defender cerca del hito.
- Pero no es parejo. Palmares (ferraria y guerra de Zumbi) y los incas (kallanka real y Vilcabamba) pierden más; Ayutthaya, casi nada.
- La tabla 3 (≤ ×2) no cambia: dos líneas incas en ×2,01 y ×2,06, como antes.

**Partidas IA contra IA** ([pruebas/08-asedio-ia.txt](pruebas/08-asedio-ia.txt); normal, 45 min, 12 partidas, las mismas semillas que main):
- **Terminan 9 de 12** (main: 10 de 12). La duración media de las que terminan es **31,9 min** (main: 29,1).
- El ganador es el mismo en las 8 partidas que terminan en las dos versiones.
- Llegan a la III 19 jugadores (main: 16) y a la IV, 3 (main: 3).
- Asedio de área: lo usan los incas (hasta 14 piezas y 220 disparos), los guaraníes y Etiopía. Ayutthaya no sacó ninguno: casi nunca juntó tropa ni madera en la III.
- Nivel del asedio: lo compran 13 de los 16 que tienen asedio (Palmares no tiene), casi siempre de 1 a 3 minutos después de llegar a la III (una vez, 5).
- **Cuánto tarda en caer una base con fortaleza:** en estas partidas no cayó ninguna. La de Ayutthaya recibió 3630 de daño (3480 del asedio) en 5 minutos y quedó en pie.
- Con la herramienta `--caida`:

| Defensa | Atacante | Cae en |
|---|---|---|
| fortaleza sola | 3 arietes | 61 s |
| fortaleza con 10 adentro | 3 arietes y 10 lanceros | 84 s (mueren 10 de 13) |
| fortaleza | 3 catapultas | no cae |
| fortaleza | 15 guerreros | no cae |
| fortaleza | 6 incendiarios | no cae |

**Primera victoria** ([pruebas/08-primera-victoria.txt](pruebas/08-primera-victoria.txt)): **idéntica a main**. Gana 2 de 3 contra la fácil, a los mismos minutos; los arietes de la II pegan lo mismo (49).

**Determinismo, rendimiento y humo** ([pruebas/08-pruebas.txt](pruebas/08-pruebas.txt)):
- `test_determinism.gd`: **el hash no cambia** (2203695307). Corre en la edad I.
- `bench.gd`: el promedio es de 9,9 y 10,4 ms (main: 10,7 y 11,6 ms, alternados y con la misma carga), y 10,6 ms con 20 catapultas: **el área no cuesta**. El peor tick pasa los 100 ms igual que en main: la máquina tenía otros diez procesos de Godot.
- `asedio.gd`, `civ_smoke.gd`, `campaign_smoke.gd`, `jugabilidad.gd` y `casillas.gd`: sin errores.
- Autotest con guaraníes en llano: `AUTOTEST: OK`.

**Capturas** (`--demo=asedio --edad=3`):
- [capturas/08-asedio-etiopia.jpg](capturas/08-asedio-etiopia.jpg): la fortaleza de amba, tres piezas ligeras y el golpe de área («-18») sobre un bloque;
- [capturas/08-asedio-guaranies.jpg](capturas/08-asedio-guaranies.jpg): la trinchera de tacuara y los cañones de tacuara;
- [capturas/08-asedio-mapuches.jpg](capturas/08-asedio-mapuches.jpg): la pukara de madera y los incendiarios con antorcha.

## Tropiezos

- **El área pegaba dos veces.** La catapulta tiene `area`, como los elefantes, y entraba también en el daño de área viejo: el borde recibía más que el centro (24 contra 20). Ahora el camino viejo es solo para quien no tiene `area_borde_pct`.
- **La IA no sacaba asedio de área**: el ariete tenía prioridad y llenaba el taller. Ahora entrena el que falta más.
- **Nadie levantaba la fortaleza**: la condición pedía la piedra del hito siguiente además del costo. Ahora la levanta cuando no ahorra para el hito.
- **`--caida` no medía nada al principio**:
  - sin capitales, la partida terminaba en el tick 5;
  - el centro del mapa de la semilla 9 tenía un paso cerrado y los arietes quedaban trabados.

  Se dejan las capitales y se usa la disposición de `micro_matriz` (semilla 3, llano).
- Merge con el paso 2 (herrería) a mitad de camino. Hubo conflictos en `edades.json` (el `_doc`) y en `sim.gd` (`effective_armor`). El aura respeta la armadura con `contra` del paso 2 (`aura_armor`).

## Riesgos y lo que queda

- **El aura es lo que más mueve el balance** (−14 a −39 % en la IV para el ejército que ataca). Palmares, en observación desde el torneo 32 (40 %), es el que más pierde. Si el torneo lo ve mal: `combate_desde_edad: 0` vuelve a lo de antes sin tocar código, o se compensa a Palmares.
- **Partidas un poco más largas** (+3 min de media y una más sin terminar en 12). El asedio y la fortaleza alargan la III; la meta del plan es de 25 a 35 minutos.
- **Incas y guaraníes rompen peor las fortalezas desde la III** (sin ariete).
- Pendiente del paso 4 completo: sanador, cañón o pieza pesada de la IV, ataque al suelo (J-05), galgas (altura) y herrería III a +1. Los modelos son maquetas: el arte de las cuatro piezas y las seis fortalezas sigue pendiente (C-80).
- Nombres a verificar: *Hatun pukara*, *Baluarte da cerca*, *puen lek*, el pasaje de Castanhoso sobre los cañones de 1541 y la trinchera de las misiones en Furlong.
