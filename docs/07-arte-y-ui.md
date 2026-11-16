# 07 — Arte e interfaz

Guía de estilo y de legibilidad. Sirve al pilar 4 (`01`, "Legibilidad AoE4") y respeta el pilar 5: el arte final llega en H3 (`02`, hitos).

## Dos etapas

| Etapa | Hitos | Estilo |
|---|---|---|
| **Maqueta** | H1–H2 | Formas primitivas, arcilla clara, colores de equipo. Prueba legibilidad y jugabilidad sin producir arte |
| **Final** | H3 en adelante | Estilizado, pocas piezas muy reutilizadas (`02`, riesgos). Se define al cerrar H2 |

La maqueta no es "cubos feos": es una maqueta de arquitecto bien iluminada. Todo lo que se aprende sobre siluetas, tamaños y contraste en esta etapa pasa directo al arte final.

## Requisitos de los modelos (pedido del autor, 2026-11-14)
Todo modelo nuevo se planifica con estas variantes desde el principio, no como agregado:
- **Construcción por etapas:** cada edificio necesita su obra en marcha además del terminado. Como mínimo, cimientos y estructura a medio levantar; idealmente 3 etapas (25, 60 y 100 %) que el juego elige según el avance de la obra.
- **Por edad:** edificios y unidades cambian de aspecto en cada edad, como en AoE4. Materiales más nobles, más altura y detalle, y equipo mejor en las unidades. Cada pueblo con su propio camino entre edades, sin un "medieval" genérico.
- **Por pueblo:** nada compartido entre civs salvo la naturaleza.
- **Margen en la huella** (2026-11-15): el modelo no llena hasta el borde de su huella. Entre edificios pegados queda un pasillo caminable dentro de la huella del más nuevo (`reglas.pasillo_entre_edificios`), y la unidad que lo cruza no debe atravesar paredes. El cuerpo principal va unos 0,3 casillas adentro de cada lado; aleros, cercos o toldos pueden llegar al borde.

Costo en Meshy: un edificio con 3 etapas de obra y 4 edades son 7 modelos en lugar de 1. Por eso se prioriza lo que más se ve (centro, casa, almacenes, cuarteles y aldeano) y el resto queda en la maqueta procedural hasta que haya créditos. El orden y el presupuesto por mes van en `proceso/19-arte-y-sonido`.

## Reglas de legibilidad

Valen para las dos etapas.

1. **Función por silueta.** Cada función tiene una forma que se reconoce sin color y en miniatura:
   - Civil: cuerpo chico, sin arma.
   - Choque: cuerpo ancho y un arma corta y pesada.
   - Distancia: cuerpo delgado, arma o brazo extendido.
   - Línea: escudo grande al frente y lanza vertical más alta que la unidad.
2. **El color es del equipo, no del tipo.** Las unidades son de material neutro y llevan el color de equipo en banda, escudo o estandarte. Ningún tipo de unidad usa un color de equipo como color propio.
3. **Edificios por proporción.** Cada edificio se distingue por su planta y su altura antes que por el detalle.
4. **Recursos por color natural.** Madera verde, piedra gris, riqueza dorada, alimento rojo sobre verde. Ninguno se confunde con un color de equipo.
5. **Escala cercana a AoE4** (2026-11-16, `proceso/24-tras-la-segunda-ronda/4p-escala.md`). La persona mide 0,75 casillas (`reglas.escala_visual.unidad_pct`); los soldados miden lo mismo que el aldeano y solo sobresalen la lanza o el tocado. En alturas de persona, medidas en el cuerpo y sin estandartes: casa unas 2, cuartel 2,5–3, centro 3–4, hito 5–6, torre 6 y árbol 4 (`altura_min_cm`, `arbol_alto_pct`). Las maquetas suben muros y techos por encima del zócalo, sin estirar puertas, cercos, gente ni estandartes; los modelos generados se estiran parejo hasta `estirar_modelo_max_pct`. Los animales van en proporción con la gente (`arte_animales.json → escala_pct`). La unidad tapada por un árbol o un edificio se ve como silueta del color del equipo (`shaders/silueta.gdshader`). Se mide con `tools/escala.gd`.
6. **Quién gana una pelea** se ve en las barras de vida y en las bajas, nunca solo en números.

## Paleta de maqueta

Los valores exactos viven en `src/game/palette.gd`; aquí, la intención.

| Uso | Color |
|---|---|
| Terreno | Verde oliva apagado, con variación suave |
| Arcilla (unidades y edificios) | Blanco cálido |
| Techos y piedra de edificios | Arcilla un tono más oscura |
| Jugadores 1 a 4 | Azul, rojo, violeta y ciruela; del 5 al 8, rosa, oliva, celeste y magenta |
| Riqueza | Dorado amarillo |
| Madera | Verde |
| Piedra | Gris azulado claro |
| Alimento | Rojo frambuesa |

La paleta es apta para daltonismo. Los equipos 1 a 4, los recursos y la vida buena y mala se distinguen en visión normal, con deuteranopía, con protanopía y con tritanopía:
- ΔE de 20 o más entre equipos y de 25 o más entre equipo y recurso;
- lo mide `tests/test_paleta.gd`.

Opciones ofrece, además, modos para cada tipo de daltonismo y el modo "yo, aliados y rivales" (`Palette.aplicar`). El color nunca va solo:
- los recursos tienen glifo propio;
- la vida baja también titila;
- "no alcanza" escribe lo que falta;
- "bloqueado" lleva candado.

Luz: un sol cálido de tarde con sombras suaves, cielo frío y oclusión ambiental. La sombra es lo que da volumen a la maqueta.

## Cámara

- Perspectiva con lente larga y ángulo alto, para que el mapa se lea casi como un plano sin perder volumen.
- Zoom limitado entre una vista de batalla y una vista táctica.
- Desplazamiento con teclado, bordes de pantalla y arrastre con botón del medio.

## Interfaz

Distribución (convención del género, sin copiar piezas):

```
┌──────────────────────────────────────────────────────────┐
│ alimento madera piedra riqueza  población      edad · reloj │
│                                                          │
│                         (mapa)                           │
│                                                          │
│ ┌────────┐ ┌───────────────────────────┐ ┌────────────┐ │
│ │minimapa│ │ selección: retrato, vida, │ │ comandos   │ │
│ │        │ │ datos o grilla de grupo,  │ │ grilla 4×3 │ │
│ │        │ │ cola de producción        │ │ con atajos │ │
│ └────────┘ └───────────────────────────┘ └────────────┘ │
└──────────────────────────────────────────────────────────┘
```

- **Grilla de comandos** con atajos por posición (`Q W E R` / `A S D F` / `Z X C V`). La posición de un comando es estable entre unidades, edificios y civilizaciones. El aldeano muestra dos submenús, `Q` Economía y `W` Militar y defensa, y los hitos de la edad siguiente en `Z` (economía) y `X` (militar); dentro de cada submenú, cada edificio tiene casilla fija por función (tabla en `data/interfaz.json` → `grilla`). `S` detiene y `F` refugia en aldeanos y tropas; `V` o `Esc` vuelve de un submenú. Con aldeanos y tropas elegidos a la vez (proceso/24, 6a), la grilla es la del tipo más numeroso de la selección (si empatan, la militar), con una pestaña arriba que lo dice, y `Tab` pasa a la otra: `Z X C V` son los hitos o las formaciones según cuál se ve. En el hito, la casilla dice «Hito» y «Edad II» en dos renglones. Con la opción "Mostrar nombres en la grilla", cada casilla lleva el nombre común arriba ("Casa", "Granero") y el propio del pueblo abajo, más tenue ("Oga", "Paiol"). Los almacenes se nombran y se dibujan por lo que reciben en ese pueblo (`interfaz.json` → `grilla.comunes_deposito`): el tapyi guaraní, que recibe alimento y madera, es "Granero y leñera" (en dos renglones, sin el propio) con los dos recursos encimados en el ícono; la qollqa lleva el alimento en una esquina de su ícono (proceso/24, 4m). Los nombres vienen prendidos la primera vez (proceso/24, 4n).
- **Grilla de los edificios** (proceso/24, 4n): lo que entrena va en la primera fila, con el aldeano siempre en `Q` y el explorador en `W` (`interfaz.json` → `grilla.unidades_fijas`); la campana en `Z`, el cumbi o desarmar la corte en `X` y la guarnición en `V`. Las investigaciones van a su `ranura` en un almacén y, en un edificio que entrena, a su casilla de `grilla.investigaciones_con_tropa` (en el centro: `A` tala, `S` cantería, `D` riqueza, `E` cestas, `R` mampostería, `F` vigías, `C` riego); las militares, en `A S D F` como en el cuartel. Si una casilla está ocupada, va a la primera libre; si no entran todas (el lof capital), van juntas al submenú «Investigaciones». Nunca hay dos comandos en una casilla, y la grilla, la tecla, el clic y la ficha leen la misma (`Controller.cmd_at`); lo verifica `tests/casillas.gd` en los edificios de las seis civilizaciones y en cada edad.
- **Cursores contextuales**: el cursor dice qué hará el clic derecho antes de darlo (mover, atacar, recolectar cada recurso, construir, reparar, refugiarse, depositar, punto de reunión, no se puede). El cursor y el clic derecho eligen el mismo blanco, y una unidad de la propia selección pierde contra lo que tiene al lado (el animal que el aldeano va a carnear).
- **Información sobre costos** al pasar el mouse; lo que no se puede pagar se muestra apagado con el recurso faltante resaltado.
- **Fin de la partida**: "Victoria" en dorado, "Derrota" en naranja y "Empate" en un azul neutro (`Palette.UI_NEUTRAL`).
- **Avisos** breves al centro, con fondo, ícono y color por tipo (ataque, decisión, hito, información), apilados sin pisarse. Los que tienen lugar en el mapa se pueden saltar con `Espacio` (último ataque) e `Inicio` (recorre los anteriores) o con un clic.
- **Grupos de control** visibles en una fila sobre el panel de selección, con número, tipo y cantidad.
- **Sin selección**, el panel de selección y la grilla se ocultan para no tapar el mapa.
- Paneles oscuros y semitransparentes, esquinas apenas redondeadas, texto claro. Sin texturas decorativas en la etapa de maqueta.

## Información en el mundo

Lo que pasa en la partida se lee sobre el mapa, sin abrir paneles (`src/game/ui/mundo_*.gd`):

- **Barras de vida** sobre lo dañado, lo seleccionado, lo que está bajo el mouse y las unidades que pelean (unos segundos después de cada golpe, `interfaz.json` → `mundo.barras_combate_s`); en obra, el progreso con porcentaje y constructores.
- **Textos flotantes**: "+N" de cada entrega en un depósito propio (se suman si caen juntas, con tope), golpes fuertes y "¡Edad II!".
- **Al colocar un edificio**: alcance (y el de las defensas propias), radio de la campana, aura del hito en el suelo con lo que queda adentro, casillas que bloquean en rojo con el motivo, rendimiento del lugar (ladera, agua), máximo por edad ("2/3"), separación mínima y conexión por caminos.
- **Indicadores**: "Zz" sobre los aldeanos ociosos, ícono del recurso que recolecta cada aldeano, punto de reunión con línea, orden en curso y órdenes en cola como líneas punteadas numeradas, alcance de torres seleccionadas.
- **Sitios sagrados**: zona de captura con el color de quien lo tiene y anillo de progreso con el color de quien lo toma.
- **Minimapa**: destello donde te pegan, sitios sagrados con su dueño, arcilla disputada, aldeanos ociosos; clic derecho para mover, encolar o fijar el punto de reunión.

## Controles

| Acción | Entrada |
|---|---|
| Seleccionar | Clic izquierdo; arrastrar para seleccionar en grupo |
| Agregar o quitar de la selección | Mayúsculas + clic |
| Seleccionar todas las del mismo tipo en pantalla | Doble clic |
| Orden contextual | Clic derecho (mover, atacar, recolectar, construir, entregar) |
| Ataque en movimiento | `A` y clic izquierdo |
| Detener | `S` con unidades seleccionadas |
| Grupos | `Ctrl + 1…9` para asignar, `Mayús + 1…9` para sumar la selección, `1…9` para seleccionar (doble toque centra) |
| Ir al último ataque o suceso | `Espacio`; `Inicio` recorre los anteriores |
| Marcadores de cámara (8) | `Ctrl + Alt + 1…8` guarda, `Alt + 1…8` vuelve; `F7…F9` son atajos de los tres primeros (`Ctrl + F7…F9` guarda). Con `Alt` porque `Ctrl + número` son los grupos |
| Submenús del aldeano | `Q` Economía, `W` Militar; `Esc`, `V` o clic derecho sobre la grilla vuelve |
| Aldeano inactivo | `.` |
| Centro | `H` |
| Encolar órdenes | Mayúsculas + clic derecho (o + `A` y clic): se cumplen una tras otra |
| Ver alcances, todas las barras de vida y el ícono de función sobre cada edificio y cada unidad a la vista (choque, distancia, línea, asedio, explorador, aldeano) | Mantener `Alt` |
| Con aldeanos y tropas elegidos a la vez, cambiar de grilla | `Tab` (la acción `produccion`; sin selección mixta recorre los edificios que entrenan) |
| Hoja de atajos de una pantalla | `F12` (acción `atajos`, reasignable) o desde la pausa |
| Mover la cámara | Flechas, bordes de pantalla, botón del medio |
| Menú | `Esc` |

## Pendiente para H3

- Estilo final y presupuesto de piezas por civilización.
- Retratos y voces en la lengua de cada civilización (pilar 3).
- Audio: guía propia.
