# 46 · Animaciones de los soldados y texto grande

## Pedido

Dos pendientes livianos de `docs/09-estado.md`:

- **A) Soldados animados.** La fila de animaciones decía «Faltan los soldados»: extender el sistema de KayKit de los aldeanos (`proceso/27`) a los soldados (quieto, caminar, golpe de cerca y a distancia, morir), solo en la vista y sin usar nada sagrado como arma.
- **B) Texto grande.** El último pendiente de la interfaz, segunda tanda (`proceso/17`): una opción guardada en `user://opciones.cfg` que agrande la letra del HUD y se siga leyendo bien, con los números en `data/`.

## Resultado

### A) Los soldados ya estaban animados

Al revisar, el pedido A ya estaba hecho: es el **paso 2 de la etapa 27** ([`27-animaciones/02-soldados.md`](../27-animaciones/02-soldados.md), commit `c06f80e`). Los soldados a pie de los seis pueblos y de los rivales de campaña usan el esqueleto de KayKit con quieto, guardia, caminar y trote, golpe con una mano, con dos y con dos armas, estocada, arco (tensar y soltar), honda y jabalina (`Throw`), arcabuz (disparo, recarga y apunte), recibir un golpe o bloquearlo y dos muertes. El golpe va a tiempo con la cadencia de la simulación y la marcha no patina. Lo sagrado quedó afuera de la tropa desde `proceso/24` (4h). Lo que quedaba mal era la fila de `09-estado.md`, que no se había actualizado: ahora dice lo que falta de verdad (caballos, elefantes y jinetes, sección 4 de `02-soldados.md`, y riggear los modelos de Meshy, C-98).

No se tocó código de animación. Se comprobó en la partida: [soldados guaraníes contra etíopes, animados](capturas/05-soldados-animados-texto-grande.jpg) (`--demo=batalla`), con el texto grande puesto.

### B) Texto grande

- **Opción:** Opciones → Interfaz → «Texto grande» ([captura](capturas/04-opciones-texto-grande.jpg)). Se guarda en `user://opciones.cfg` (`interfaz.texto_grande`), «Restablecer» la apaga, y para capturas y pruebas está `--texto=grande` (esas corridas no leen el archivo).
- **Cómo agranda:** `Hud.ts(n)` devuelve el tamaño de letra que corresponde a `n`. Con la opción, lo multiplica por `factor_pct` (125) sin pasar de `tope_px` (20): la letra chica es la que más crece (11 → 14, 13 → 16, 15 → 19) y los títulos de 20 o más quedan igual. Así no se rompe la jerarquía ni se salen los títulos de sus paneles. Los dos valores están en `data/interfaz.json → texto_grande`.
- **Dónde:** se envolvieron en `Hud.ts` los 174 tamaños literales de la interfaz (barra de arriba, reloj, ficha, grilla, avisos, cola, paneles F1–F6, Guía, menú, opciones, campañas, minimapa) y los ocho que venían en variables (ayudas de la ficha, consejos de la grilla, el globo del mundo, los temas de Label y botones del HUD y del diálogo de opciones). Las mediciones de ancho usan el mismo tamaño que el dibujo, así que lo que ya se ajustaba al ancho (`EstadoCasilla._fit`) se sigue ajustando.
- **Al cambiarla:** lo dibujado a mano toma el tamaño nuevo al cuadro siguiente; el tema del HUD se rehace (`Opciones.aplicar_texto`). Los paneles armados con controles (el mismo diálogo, el menú) lo toman al volver a abrirse.
- **Comparación** a 1920×1080, guaraníes en llano a los 3 s: [normal](capturas/01-texto-normal.jpg) y [grande](capturas/02-texto-grande.jpg); [la ficha de una unidad con texto grande](capturas/03-ficha-texto-grande.jpg) (los renglones no se pisan).
- **No es lo mismo que la escala:** «Escala de la interfaz» agranda todo (paneles, íconos y letra); «Texto grande» solo la letra, dentro de los mismos paneles. Se pueden combinar.

## Paso a paso

1. Leí `09-estado.md`, `proceso/27` y `proceso/17`. La carpeta 27 ya tenía el paso 2 de los soldados, así que A quedó en verificar y corregir el estado.
2. Un script de un solo uso (en el scratchpad, no en el repo) recorrió `src/game/**/*.gd` y envolvió en `Hud.ts(…)` el argumento de tamaño de `draw_string`, `draw_string_outline`, `draw_multiline_string`, `get_string_size`, `get_multiline_string_size`, `_fit`, `_fit_lineas`, `add_theme_font_size_override` y `set_font_size`, solo cuando era un número literal. Los que venían en variables se arreglaron a mano.
3. `Hud.ts` lee `data/interfaz.json` una vez; sin la opción devuelve el mismo número, así que con la opción apagada nada cambia.
4. La opción en el diálogo, en `cargar`, `guardar` y `restablecer`, y `--texto=` en `main.gd`.
5. `tests/test_opciones.gd` suma la ida y vuelta de la opción y cinco comprobaciones de `Hud.ts` (crece, no pasa del tope, deja los títulos, nunca achica, apagada no cambia nada).
6. Capturas y autotest.

## Tropiezos

- **«Aliment» cortado** en la muestra de colores de las opciones: el nombre tiene 74 px de ancho fijo y a 19 px no entraba. Ahora se ajusta con `EstadoCasilla._fit`.
- **El renglón del globo del mundo** tenía 19 px de alto fijo; con la letra de 18 se pisaba. Ahora el alto sale del tamaño de letra.
- **`--shot` no crea la carpeta:** la primera captura falló porque el worktree no tenía `screenshots/`.
- **Worktree sin importar:** hubo que correr `godot --headless --import` antes de las pruebas.

## Pruebas

Todas con `systemd-run --user --scope -p MemoryMax=4G`, de a una.

- `tests/test_opciones.gd`: **OPCIONES: OK** (`pruebas/test_opciones.txt`).
- `tests/test_paleta.gd`: **PALETA: OK** (`pruebas/test_paleta.txt`).
- `tests/test_determinism.gd`: **DETERMINISMO: OK**, `hash=3059812827` (`pruebas/test_determinism.txt`). No se tocó `src/sim/`.
- Autotest con ventana, `--civ=guaranies --terreno=llano`: **AUTOTEST: OK** a la primera (`pruebas/autotest-guaranies.txt`).
- Capturas revisadas: las cinco de `capturas/`.

## Lo que falta

- Los paneles armados con controles toman el tamaño nuevo al reabrirse, no al momento.
- Las etiquetas del mundo que ya escalan con el zoom (los «Zz» de los ociosos, los números flotantes) no cambian con la opción.
- Para las animaciones: caballos, elefantes y jinetes (`27-animaciones/02-soldados.md`, sección 4) y los detalles de su «Lo que falta».

## Commits

- `Proceso 46: texto grande en las opciones y estado de las animaciones de los soldados`
