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
| Jugador 1 | Azul |
| Jugador 2 | Rojo terracota |
| Riqueza | Dorado |
| Madera | Verde profundo |
| Piedra | Gris azulado |
| Alimento | Rojo baya |

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

- **Grilla de comandos** con atajos por posición (`Q W E R` / `A S D F` / `Z X C V`). La posición de un comando es estable entre unidades y edificios.
- **Información sobre costos** al pasar el mouse; lo que no se puede pagar se muestra apagado con el recurso faltante resaltado.
- **Avisos** breves al centro: edad alcanzada, recursos insuficientes, población llena, ataque a la base.
- Paneles oscuros y semitransparentes, esquinas apenas redondeadas, texto claro. Sin texturas decorativas en la etapa de maqueta.

## Controles

| Acción | Entrada |
|---|---|
| Seleccionar | Clic izquierdo; arrastrar para seleccionar en grupo |
| Agregar o quitar de la selección | Mayúsculas + clic |
| Seleccionar todas las del mismo tipo en pantalla | Doble clic |
| Orden contextual | Clic derecho (mover, atacar, recolectar, construir, entregar) |
| Ataque en movimiento | `A` y clic izquierdo |
| Detener | `S` con unidades seleccionadas |
| Grupos | `Ctrl + 1…9` para asignar, `1…9` para seleccionar |
| Aldeano inactivo | `.` |
| Centro | `H` |
| Mover la cámara | Flechas, bordes de pantalla, botón del medio |
| Menú | `Esc` |

## Pendiente para H3

- Estilo final y presupuesto de piezas por civilización.
- Retratos y voces en la lengua de cada civilización (pilar 3).
- Audio: guía propia.
