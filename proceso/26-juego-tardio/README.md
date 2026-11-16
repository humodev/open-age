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
| 4 | Decisión: si rompe el balance, queda diseñado como contenido y se retoma con más contenido (modelos, animaciones) | por hacer |

## Pedido del autor: saberes de los pueblos

> "Me gusta la cantidad. Quisiera que nos pongamos creativos: se sabe que en Latinoamérica había pueblos que hacían operaciones cerebrales con éxito antes de la invasión española. Creo que es importante que tengamos la mente abierta a esas cosas de estos pueblos que, al ser exterminados, se perdió mucho de lo que sabían y hacían, por no poder ellos contar la historia, y porque se contaba por sus exterminadores."

**Criterio para el diseño:**
- Las mejoras y unidades propias de cada pueblo parten de sus **saberes**: medicina, ingeniería, agricultura, administración, metalurgia, navegación, astronomía. Se toman de la arqueología y de las fuentes propias, no de la mirada del conquistador. Ejemplo: la trepanación andina, con miles de cráneos con cirugía exitosa y tasas de supervivencia muy altas [verificar cifras].
- Cada saber lleva su **nivel de evidencia**: documentado, arqueológico o debatido. Así se cuenta lo que se borró sin caer en el mito al revés.
- Lo sagrado sigue con el mismo cuidado de la etapa 25: no se usa como bono de combate sin consulta.
