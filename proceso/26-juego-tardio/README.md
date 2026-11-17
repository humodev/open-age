# 26 · Juego tardío, recompensas de edad y pendientes de diseño (desde 2026-11-16)

## Pedido del autor
> "Agrupá todos los errores históricos importantes que cometimos y todas las sugerencias del jugador experto que pueden mejorar el gameplay, y sumémoslas al diseño. Preguntale al experto qué sería una buena cantidad de mejoras y opciones por civ, y probemos diseñar un final de partida y recompensas y progreso al subir de edad al nivel de AoE4. Si eso rompe el balance, lo pausamos y lo retomamos con más contenido."

Contexto: hoy la edad IV no trae unidades nuevas, hay 18 mejoras compartidas y ninguna propia por civ. Las partidas se deciden antes del final: la edad III llega a los 15–20 min y la IV, en cerca del 15 % de las partidas.

## Plan
| Paso | Qué | Documento |
|---|---|---|
| 1 | **Hecho.** El veterano: cantidad buena de unidades, mejoras y opciones por civ; recompensas por edad; el final de partida de AoE4; riesgos y orden | [01-veterano-cantidades.md](01-veterano-cantidades.md) |
| 2 | **Hecho.** Recopilación: 51 errores históricos (H-01 a H-51) y 27 pedidos del veterano (J-01 a J-27), con prioridad y orden | [docs/diseno/26-pendientes-historia-y-juego.md](../../docs/diseno/26-pendientes-historia-y-juego.md) |
| 3 | **Hecho.** Diseño del juego tardío y de los saberes: 8 mejoras y 3 unidades propias por pueblo, cada una con su nivel de evidencia y su fuente; una maravilla por pueblo; el progreso por edad; un modelo numérico (`tools/modelo_progreso.py`). En el paso 1 el poder no cambia (0 a −2 %). Consultas C-75 a C-83. **Revisado por los tres historiadores** ([América Latina](02-revision-america-latina.md), [África](03-revision-africa.md), [Asia](04-revision-asia.md)): nada quedó para sacar sin reemplazo; correcciones en el §0 del diseño; consultas C-84 a C-97 | [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) |
| 4 | **Paso 1 implementado (f6418e3):** sin bono de ataque por edad en la tropa; armas_1 suma +10 % y hay niveles veterano (III) y élite (IV) por línea, que la IA compra cerca de un minuto después de llegar a cada edad. El asedio y los edificios conservan el bono por edad. Mismo hash y modelo neutro. **Torneo 32** ([resultados](pruebas/32-torneo-paso-1.txt), 10 semillas):
  - Tawantinsuyu 50 %, mapuches 64 %, guaraníes 70 %, Etiopía 36 %, Palmares 40 %, Ayutthaya 40 %.
  - La dispersión baja de 32–72 a 36–70.
  - Palmares baja 12 puntos (de 52 a 40) y pasa el ±7 de la regla, pero queda en la banda y el conjunto mejora: **el paso 1 queda**, con Palmares en observación.
  - La edad IV, en 16 de 150 partidas (el paso 1 no busca moverla).
  - Rendimiento, solo en la máquina: 9,31 ms de promedio y 93 de peor caso. | [05-paso-1-niveles.md](05-paso-1-niveles.md) |
| 5 | **Paso 2 integrado (56032a5):** herrería en el cuartel (como dice el diseño §1.1), con 12 mejoras: ataque cuerpo a cuerpo y a distancia, y armadura contra cada uno, en 3 tandas (II, III y IV). Reemplaza a armas y escudos con el mismo poder total; el modelo y la micro dan igual. El lof, el mocambo y la qollqa no la tienen, porque no entra en su submenú. Mismo hash. Palmares 1: el objetivo secundario «protegé a los aldeanos» falla a los 2:48 en la prueba de humo, porque la IA rival cambia el orden de compra. Confirmación en el torneo del hito | [06-paso-2-herreria.md](06-paso-2-herreria.md) |
| 6 | **Paso 4 integrado (460098f):** asedio y fortaleza.
  - **Asedio:** sin bono por edad (niveles veterano y élite). Asedio de área en la III con forma por pueblo: hondero de piedra caliente, cañón de tacuara, pieza ligera, cañón de muralla, incendiarios mapuches contra la madera; Palmares, sin asedio.
  - **Fortaleza de la III** por pueblo, y mejoras de defensa.
  - **Hitos militares con aura (C-76 a):** es lo que más mueve. Según el modelo, el ejército lejos de casa pierde en la IV entre −14 y −39 % (Palmares, el que más).
  - **Área:** se bajaron los números del diseño, porque 2 catapultas decidían cualquier pelea.
  - **IA contra IA:** las partidas duran unos 3 minutos más, y levantan 9 fortalezas en 19 llegadas a la III, sin que caiga ninguna.
  - **Pruebas:** mismo hash; asedio, jugabilidad y autotest OK.
  - Si el torneo del hito castiga a Palmares: `aura_hito.militar.combate_desde_edad: 0`. | [08-paso-4-asedio-y-fortaleza.md](08-paso-4-asedio-y-fortaleza.md) |
| 7 | **Paso 3 integrado (896a985):** economía del final y escuela de la IV.
  - **Economía:** velocidad (II) y vida (III) del aldeano, una tercera tanda de tala, granja y carga en la IV, y los sitios rinden +50 % en la IV.
  - **Escuela de la IV:** con nombre por pueblo (Yachaywasi, Trawün de los weupife, Escritura del cabildo, Talleres de Gondar, Oficinas do Macaco, Phra Khlang), con 6 mejoras comunes y «los registros» propios de cada pueblo (khipu, pron, actas, Ṣäḥafe tə'əzaz, memoria de los mocambos, Chindamani).
  - **No cumple la meta del §6:** la IA llega a la IV en 22 % con y sin el paso. Llegar depende de que la IA quiera subir y del paso 7.
  - **Pruebas:** mismo hash; juego tardío, casillas (504 grillas) y autotest OK. | [07-paso-3-economia-y-escuela.md](07-paso-3-economia-y-escuela.md) |
| 8 | **Torneo del hito (34)** ([resultados](pruebas/34-torneo-hito-pasos-2-4.txt)), pasos 2, 3 y 4 juntos:
  - Todas entre 42 y 60 %: Tawantinsuyu 52, mapuches 60 (antes 70), guaraníes 42, Etiopía 46, Palmares 58 (antes 46: el aura no la castigó), Ayutthaya 42.
  - Es la banda más pareja hasta ahora: **los pasos 2 a 4 quedan**.
  - Las partidas por destrucción de hitos bajan de 82 a 64, porque se alargan.
  - **La IV aparece en 7 partidas (antes, 16):** la fortaleza y el asedio frenan el ritmo. Que se llegue a la IV es el trabajo del paso 7 y de que la IA quiera subir. | hecho |
| 9 | **Costos por recurso (ece45e8)**, pedido del autor ("acumulo riqueza…"):
  - El veterano de AoE4 midió que en la II había 400 o más de riqueza quieta el 71 % del tiempo.
  - La herrería y las mejoras militares de la II y la III pasan a riqueza y alimento, sin madera, con el mismo tiempo de aldeano.
  - Riqueza quieta: 59 % del tiempo. La III llega a los 17,5 min (antes, 18,3).
  - Su consejo al jugador: el mercado como salida de la riqueza que sobra. **Torneo 35** ([resultados](pruebas/35-torneo-costos.txt)): Tawantinsuyu 52, mapuches **70** (antes 60), guaraníes 48, Etiopía 34, Palmares 58, Ayutthaya 38.
  - Los costos quedan: la riqueza se usa, que era el pedido.
  - Los mapuches vuelven a 70 %, con la herrería pagada en riqueza (su riqueza viene de la kona y del malón). Su diagnóstico (5f) se hace sobre esta base.
  - Las partidas por destrucción de hitos bajan a 53 y la IV aparece en 5 partidas. | [09-costos-por-recurso.md](09-costos-por-recurso.md) |
| 10 | **Paso 7 integrado (0dafcb7):** maravilla y final de partida.
  - **Maravilla por pueblo en la IV:** Ollantaytambo, gran koyagtun, la tava o la aldea grande del monte, Fasil Gəbbi, la Cerca do Outeiro da Barriga (sitiada, no cae) y Krung Si Ayutthaya y Pom Phet.
  - **Victoria por maravilla:** 15 minutos de cuenta, que ven todos; es opción de partida.
  - **La IA sube a la IV** y ataca primero la maravilla rival.
  - **Rendición** en todas las dificultades.
  - **IA contra IA (45 min):** la IV en el **61 %** de las partidas (antes, 5 %), a los 26:42 de mediana. Ninguna partida se gana por maravilla, y el camino más rápido supera los 50 minutos.
  - **Pruebas:** mismo hash; maravilla (45 comprobaciones), campañas y autotest OK.
  - **No entró:** el comerciante que camina, que espera arte (C-80). **Torneo 37** ([resultados](pruebas/37-torneo-paso-7.txt)): Tawantinsuyu 46, mapuches 62, guaraníes 40, Etiopía 42, Palmares 66, Ayutthaya 44.
  - Todas entre 40 y 66 %: el paso 7 queda.
  - Palmares sube 6 puntos, dentro del ruido (±7), pero queda en el borde de la banda: en observación. Si en el torneo del par 1 del paso 6 sigue en 66 % o más, se diagnostica con `tools/civ_diag.gd`.
  - El torneo es de 30 minutos, así que no mide la maravilla. | [10-paso-7-maravilla-y-final.md](10-paso-7-maravilla-y-final.md) |
| 11 | Decisión: si un paso rompe el balance, queda diseñado como contenido y se retoma con más contenido (modelos, animaciones) | por hacer |

## Pedido del autor: saberes de los pueblos

> "Me gusta la cantidad. Quisiera que nos pongamos creativos: se sabe que en Latinoamérica había pueblos que hacían operaciones cerebrales con éxito antes de la invasión española. Creo que es importante que tengamos la mente abierta a esas cosas de estos pueblos que, al ser exterminados, se perdió mucho de lo que sabían y hacían, por no poder ellos contar la historia, y porque se contaba por sus exterminadores."

**Criterio para el diseño:**
- Las mejoras y unidades propias de cada pueblo parten de sus **saberes**: medicina, ingeniería, agricultura, administración, metalurgia, navegación, astronomía. Se toman de la arqueología y de las fuentes propias, no de la mirada del conquistador. Ejemplo: la trepanación andina, con miles de cráneos con cirugía exitosa y tasas de supervivencia muy altas [verificar cifras].
- Cada saber lleva su **nivel de evidencia**: documentado, arqueológico o debatido. Así se cuenta lo que se borró sin caer en el mito al revés.
- Lo sagrado sigue con el mismo cuidado de la etapa 25: no se usa como bono de combate sin consulta.

## Cómo se mide desde ahora (2026-11-16)

> El autor: "Prefiero que avancemos de esa manera, porque si no vamos a gastar muchos tokens solo en torneos y frenar el avance. Tenemos que acelerar la implementación."

- Cada cambio se ajusta con herramientas dirigidas: el diagnóstico que repite las mismas semillas, la matriz de micro y el modelo de progreso.
- Los cambios independientes se agrupan.
- Se confirma con **un torneo de 10 semillas por hito**: al final de cada paso del juego tardío o antes de una ronda de jugadores.
- Un torneo por cambio solo para cambios amplios de IA o simulación.
- Los pasos se implementan en paralelo, cada uno en su worktree.
