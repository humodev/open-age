# Catálogo de la interfaz pintada

Las texturas de la interfaz (`proceso/68-interfaz-pintada`): de dónde sale cada una, con qué receta y qué cuidar. Todas las hace `tools/interfaz_pintada.py` desde `data/interfaz.json → hud_estilo.pintado`, en `assets/ui/hud/`. Van al **doble de resolución**: el juego las dibuja a escala 0,5, así que a 4K se ven nítidas. Con `pintado.activo` en `false`, o si falta la superficie, el HUD vuelve al marco dibujado con código de `proceso/67` (`src/game/ui/marco_hud.gd`, primera mitad).

## Piezas

| Pieza | Archivo | Fuente | Tamaño | Dónde va |
|---|---|---|---|---|
| Papel con gouache | `superficie.webp` | FLUX (`papel_8` y la trama de `algodon_7`), sin costuras con Pillow | 1024² (512² en pantalla) | Fondo de todos los paneles, diálogos, ayudas y avisos |
| Faja del pueblo (9 cortes) | `<pueblo>/marco.png` | Tejida en código, hilo por hilo, desde los datos | 2c + 3 tiras (c = filas × 3 px) | Borde de los paneles; la del **jugador** |
| Tira de la faja | `<pueblo>/faja.png` | Igual | filas × período | Muestras y la hoja del README |
| Pieza de esquina | `<pueblo>/esquina.png` | Tejida, recortada en rombo | 49 px | Esquinas de arriba de los paneles grandes |
| Marca de agua | `<pueblo>/marca.webp` | El gouache del pueblo (`assets/ui/arte/<pueblo>/gouache/`) pasado a tinta hundida | 300² | Panel de la selección, abajo a la derecha |
| Cordón divisor | `divisor.png` | Tejido (cordón de dos cabos) | 96 × 12 | Líneas que separan (cabecera, grilla, barra) |
| Medallón | `medallon.png` | Dibujado con Pillow y el grano del papel | 256², 9 cortes de 22 | Alrededor del retrato |
| Botones | `boton_normal/hover/pressed/disabled.png` | Papel algo más claro y filete pintado | 96 × 64, 9 cortes de 12 | Botones de los diálogos, el menú y las opciones |

## Fajas por pueblo

| Pueblo | Motivo | Fuente y por qué se puede usar |
|---|---|---|
| Tawantinsuyu | `pallay_rombos`: rombos encadenados con contorno blanco, amarillo y centro oscuro sobre rojo de cochinilla | El *pallay* es el campo de dibujo de las fajas (*chumpi*) y mantas (*lliklla*) del sur andino (Cusco, Q'ero, Chinchero); los rombos son un motivo de uso diario. No se usa el *tocapu* (cuadros con signos de la élite inca, de sentido discutido). |
| Mapuches | `escalonado`: rombos escalonados encadenados, blanco y rojo sobre negro | Geometría del *witral* (telar) en fajas (*trariwe*) y mantas (*makuñ*), en las técnicas *ñimin* y *trarikan*. No se usan el *lukutuwe* ni el *wünyelfe*, que tienen sentido ceremonial. |
| Guaraníes | `sarga`: sarga de dos colores en espiga, tiras naturales horizontales y teñidas verticales | Cestería de tacuara y fibras (canastos *ajaka*, *panakũ*) de los pueblos guaraníes; la sarga es la técnica, sin figuras. |
| Etiopía | `tibeb`: guarda oscura con rombos de colores entre rayas rojas, sobre algodón blanco | El *tibeb* es la guarda tejida de la *netela* y el *gabi*. Algunos tibeb llevan cruces: **acá no**, solo rombos. |
| Palmares | `rafia`: entrelazado de rombos y zigzag en rafia natural, óxido y oscuro | Inspiración general en la rafia tejida de África centro-occidental (kongo, mbundu), de donde vino buena parte de la gente de Palmares, y en la cestería de palma de Pernambuco. No es un motivo documentado en Palmares. Sin el cosmograma kongo (*dikenga*). |
| Ayutthaya | `prajam_yam`: flor de cuatro pétalos en rombo, oro sobre laca negra | *Lai prajam yam*, motivo de textiles (*pha nung*) y cerámica *benjarong*. Sin Buda, sin deidades y sin el *kranok* de los frontones de templo. |
| Común (`neutro`) | `cordon`: cordón torcido ocre y tierra | Sin pueblo: menús y diálogos fuera de la partida. |

## Reglas

- **Lectura.** Ninguna textura que va debajo de texto (papel, centro de los botones, marca de agua sobre el papel) puede ser más clara que el `FONDO` de `tests/test_paleta.gd` (`26282b`). El generador lo recorta y la prueba lo mide (percentil 99,5 de luminancia). Así, todos los contrastes WCAG de la prueba valen sobre las texturas. La faja va al borde y la mitad cae afuera del panel (`faja_fuera`): no tapa texto.
- **Color del jugador.** La faja no usa el color del equipo; la cabecera de la selección, sí.
- **Fondos con significado.** Si un panel tiene un fondo de color (una fila elegida, un aviso), `EstiloPintado` deja el color y le pone solo el grano encima, sin faja.
- **Escala.** Todo se dibuja en unidades de la interfaz (1920×1080 de base), así que sigue a la escala de 1366×768 a 4K y al texto grande.

## Cómo recrear

```
python3 tools/interfaz_pintada.py --flux             # las fuentes de FLUX que falten (ComfyUI aislado) y todo lo demás
python3 tools/interfaz_pintada.py                    # solo el procesado (sin GPU, ~5 s)
python3 tools/interfaz_pintada.py --hoja hoja.jpg    # además, la hoja de muestras
godot --headless --path . --import                   # para que el juego tome las texturas nuevas
```

Para cambiar una faja: su entrada en `hud_estilo.pintado.pueblos` (colores, filas, período) y volver a correr el script. Un motivo nuevo se agrega en `matriz()` del script. Las fuentes de FLUX quedan en `proceso/68-interfaz-pintada/fuentes/` (fuera de Godot) y los prompts, en `FLUX` del script.
