# Proyecto Sur (nombre provisional) — Índice

RTS histórico con la calidad, legibilidad y asimetría de Age of Empires IV, protagonizado por civilizaciones del sur global, c. 1400–1800. Lo desarrolla una sola persona con agentes de IA. Este índice es lo primero que lee cualquier agente.

## Reglas para agentes

1. Antes de cualquier tarea, leer este índice y `04-decisiones.md`.
2. Cada dato vive en un solo documento. Si hace falta en otro, se enlaza; no se copia.
3. Los números (costos, vida, daño, tiempos) van en archivos de datos, nunca en prosa. Los documentos describen intención y reglas; los datos son la fuente de verdad del balance.
4. Las decisiones cerradas no se reabren. Para cambiarlas se agrega una entrada "Propuesta" en `04-decisiones.md` y se espera aprobación.
5. Toda afirmación histórica lleva `[verificar]` hasta tener una fuente citada en la ficha de la civilización.
6. Si dos documentos se contradicen, gana `04-decisiones.md`; después, el documento de número más bajo. Además, avisar de la contradicción.
7. Ninguna civilización nueva ni mecánica nueva entra sin pasar los tests de asimetría de `01-vision-y-pilares.md`.

## Mapa de documentos

| Archivo | Contenido | Estado |
|---|---|---|
| `00-indice.md` | Este índice y las reglas | Vigente |
| `01-vision-y-pilares.md` | Qué es el juego, pilares, reglas de asimetría | Borrador v1 |
| `02-alcance-y-epoca.md` | Época, edades, recursos, alcance, hitos, riesgos | Borrador v1 |
| `03-matriz-de-roles.md` | Las 4 civilizaciones iniciales, función por función | Borrador v1 |
| `04-decisiones.md` | Decisiones cerradas y abiertas | Vigente |
| `05-mecanicas-nucleo.md` | Economía, combate, contadores, victoria | Borrador v1 |
| `civs/<nombre>.md` | Ficha por civilización; plantilla en `civs/_plantilla.md` | Seis fichas; los datos vigentes están en `data/civs/` |
| `06-arquitectura.md` | Motor, simulación determinista, datos, multijugador | Borrador v1 |
| `07-arte-y-ui.md` | Guía de estilo, legibilidad, interfaz, controles | Borrador v1 |
| `08-ia-rival.md` | Comportamiento de la IA de escaramuza | Borrador v1 |
| `09-estado.md` | Estado de los hitos y próximos pasos | Vigente |
| `investigacion/` | Informes de investigación histórica y de referencia (no son decisiones) | Vigente: 7 informes |
| `campanas/` | Índice y criterios de las seis campañas; los datos ejecutables están en `data/campanas/` | Vigente |
| `data/civs/*.json` | Las seis civilizaciones como datos: reemplazos, unidades y edificios propios, hitos y módulos | Vigente |
| `../proceso/` | Registro paso a paso del desarrollo y consultas al autor | Vigente |
| `data/*.json` | Números de balance (fuente de verdad, D-008) | Vigente |

## Glosario mínimo

- **Función**: papel que cumple una unidad o mecánica (movilidad, choque, distancia, línea, asedio, defensa). Ver `03-matriz-de-roles.md`.
- **Riqueza**: cuarto recurso, equivalente funcional del oro. Cada civilización la obtiene de forma distinta.
- **Adopción**: mecánica por la que una civilización incorpora caballo, hierro o pólvora por captura, comercio o alianza.
- **Slice**: versión mínima jugable con calidad final (ver hitos en `02-alcance-y-epoca.md`).
