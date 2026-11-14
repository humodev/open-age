# 07 — Arte e interfaz

Guía de estilo y de legibilidad. Sirve al pilar 4 (`01`, "Legibilidad AoE4") y respeta el pilar 5: el arte final llega en H3 (`02`, hitos).

## Dos etapas

| Etapa | Hitos | Estilo |
|---|---|---|
| **Maqueta** | H1–H2 | Formas primitivas, arcilla clara, colores de equipo. Prueba legibilidad y jugabilidad sin producir arte |
| **Final** | H3 en adelante | Estilizado, pocas piezas muy reutilizadas (`02`, riesgos). Se define al cerrar H2 |

La maqueta no es "cubos feos": es una maqueta de arquitecto bien iluminada. Todo lo que se aprende sobre siluetas, tamaños y contraste en esta etapa pasa directo al arte final.

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
5. **Escala de juego, no realista.** Las unidades son más grandes de lo real respecto de los edificios, para leerse con la cámara de juego.
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

- **Grilla de comandos** con atajos por posición (`Q W E R` / `A S D F` / `Z X C V`). La posición de un comando es estable entre unidades, edificios y civilizaciones. El aldeano muestra dos submenús, `Q` Economía y `W` Militar y defensa, y los hitos de la edad siguiente en `Z` (economía) y `X` (militar); dentro de cada submenú, cada edificio tiene casilla fija por función (tabla en `data/interfaz.json` → `grilla`). `S` detiene y `F` refugia en aldeanos y tropas; `V` o `Esc` vuelve de un submenú.
- **Cursores contextuales**: el cursor dice qué hará el clic derecho antes de darlo (mover, atacar, recolectar cada recurso, construir, reparar, refugiarse, depositar, punto de reunión, no se puede).
- **Información sobre costos** al pasar el mouse; lo que no se puede pagar se muestra apagado con el recurso faltante resaltado.
- **Avisos** breves al centro, con fondo, ícono y color por tipo (ataque, decisión, hito, información), apilados sin pisarse. Los que tienen lugar en el mapa se pueden saltar con `Espacio` (último ataque) e `Inicio` (recorre los anteriores) o con un clic.
- **Grupos de control** visibles en una fila sobre el panel de selección, con número, tipo y cantidad.
- **Sin selección**, el panel de selección y la grilla se ocultan para no tapar el mapa.
- Paneles oscuros y semitransparentes, esquinas apenas redondeadas, texto claro. Sin texturas decorativas en la etapa de maqueta.

## Información en el mundo

Lo que pasa en la partida se lee sobre el mapa, sin abrir paneles (`src/game/ui/mundo_*.gd`):

- **Barras de vida** sobre lo dañado, lo seleccionado y lo que está bajo el mouse; en obra, el progreso con porcentaje y constructores.
- **Textos flotantes**: "+N" de cada entrega en un depósito propio (se suman si caen juntas, con tope), golpes fuertes y "¡Edad II!".
- **Al colocar un edificio**: alcance (y el de las defensas propias), radio de la campana, casillas que bloquean en rojo con el motivo, rendimiento del lugar (ladera, agua), máximo por edad ("2/3"), separación mínima y conexión por caminos.
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
| Submenús del aldeano | `Q` Economía, `W` Militar; `Esc`, `V` o clic derecho sobre la grilla vuelve |
| Aldeano inactivo | `.` |
| Centro | `H` |
| Encolar órdenes | Mayúsculas + clic derecho (o + `A` y clic): se cumplen una tras otra |
| Ver alcances y todas las barras de vida | Mantener `Alt` |
| Mover la cámara | Flechas, bordes de pantalla, botón del medio |
| Menú | `Esc` |

## Pendiente para H3

- Estilo final y presupuesto de piezas por civilización.
- Retratos y voces en la lengua de cada civilización (pilar 3).
- Audio: guía propia.
