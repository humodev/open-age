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
| 6 | Decisión: si un paso rompe el balance, queda diseñado como contenido y se retoma con más contenido (modelos, animaciones) | por hacer |

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
