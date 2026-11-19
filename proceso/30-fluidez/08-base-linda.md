# Frente 7 · La base linda

**Pedido.** Este frente toma tres puntos del constructor de la ronda 7 ([04-constructor-fluidez.md](../22-testers/ronda-7/04-constructor-fluidez.md), §6):

- **C14:** banderas más chicas, solo donde importan y con opción para ocultarlas.
- **C25:** modo foto.
- **C24:** tierra pisada, pilas de recurso, granjas que cambian y tocones.

Todo es vista: la simulación no se toca. Los números están en `data/arte_base.json`.

## Qué entró

- **Estandartes** (`Meshes._banner`, `CivMeshes.building`, `bandera_para`):
  - Por defecto los llevan solo los centros, los hitos, las maravillas, las fortalezas y los edificios de producción militar.
  - Miden el 70 % de antes.
  - En **Opciones → Interfaz → Estandartes de los edificios** hay tres modos: «Centros, hitos y cuarteles», «En todos los edificios» y «Ocultos».
  - Si se cambia el modo durante la partida, los edificios se rehacen solos.
  - Las unidades conservan sus estandartes.
- **Modo foto:** con **O** se oculta la interfaz y desaparecen los anillos de selección. La tecla se reasigna en Opciones → Teclas (acción `modo_foto`, en `data/interfaz.json`).
- **Tierra pisada** (`src/game/base_linda.gd`):
  - La vista lleva un mapa de tránsito de los aldeanos que se mueven y se ven. Cada píxel de la mezcla del suelo vale media casilla.
  - Por encima de un umbral, el canal de tierra del suelo sube en escalones de 1/32, hasta un 72 %.
  - La textura se sube cada 2 s, y solo si cambió algo.
  - El agua no se pisa.
  - Alrededor de los edificios ya había tierra pisada. Ahora se suma la de los viajes al depósito.
- **Pilas:**
  - Cada depósito suma lo que traen los aldeanos; el evento `deposit` llega con `aux`, el depósito al que volvió el aldeano.
  - Lo guardado se gasta un 20 % por minuto.
  - Hay cuatro tamaños de pila: leña apilada, piedras, cántaros de riqueza y bolsas con un canasto de comida.
  - Las pilas van sobre el frente que mira a la cámara. En los centros son más chicas.
- **Granjas:**
  - Si un campesino trabaja la granja, el cultivo recorre un ciclo de 90 s de juego: brote, verde, espiga y maduro, y vuelve a empezar.
  - Si nadie la trabaja, queda en barbecho, con un rastrojo bajo y seco.
  - Se arma con una sola malla por granja y cuatro materiales en total.
  - Los andenes en ladera quedan como estaban.
- **Tocones:** el árbol talado deja un tocón. Todos van en un único MultiMesh, con un tope de 3000; al llenarse, se reusan los más viejos.

## Costo (200 aldeanos en pantalla, `tools/aldeanos_animados.gd --modo=fps`)

La máquina tenía una carga de 33 a 36 (siete agentes en paralelo), así que el total de la vista varía ±3 ms entre rondas.

| | vista (mediana de 5 rondas) | «actualizar» (sin cambios, mide la carga) | base linda sola |
|---|---|---|---|
| Antes | 14,4 ms | 3,1 ms | — |
| Después | 18,0 ms | 3,6 ms | **0,20 a 0,48 ms** por cuadro (a 11–15 fps) |

- El costo propio sale de un contador aparte (`base_linda.us`, que la herramienta ahora imprime).
- El resto de la diferencia es carga de la máquina: «actualizar», que no se tocó, también subió un 17 %.
- La primera versión de la tierra pisada costaba de 0,8 a 1 ms. Bajó a la mitad con dos cambios:
  - arreglos empaquetados en lugar de `get_pixel` en cada paso;
  - la lista de granjas se rehace cada 5 s, en lugar de recorrer todo lo dibujado.

## Pruebas

- **Determinismo:** OK, hash **3059812827**, el mismo que antes.
- **`tools/base_linda.gd`:** 6 de 6, con eventos reales.
  - El modo foto oculta la interfaz y la devuelve con la misma tecla.
  - Los tres modos de estandartes rehacen los edificios.
- **Autotest con Palmares:** 219 OK. Falla una comprobación de tiempo del frente 1: «aviso anticipado de población» en una corrida, y la cola de producción en otras ([pruebas/08-autotest-palmares.txt](pruebas/08-autotest-palmares.txt)).
  - **Causa:** son comprobaciones que dependen de cuántos cuadros pasan antes de que se termine de entrenar un aldeano.
  - **Comparación:** con esta carga, la versión de antes del frente (d18ea28) también falla («Mayús + clic derecho saca 5 (3)»). Antes, con menos carga, había pasado dos veces.
  - Con `BaseLinda.render` apagado también falla, así que no viene del costo por cuadro.

## Capturas

Las dos capturas son de la misma partida: semilla 7, guaraníes contra mapuches, llano, a los 20:00.

- [Antes](capturas/08-base-linda/antes-20min.jpg) · [Después](capturas/08-base-linda/despues-20min.jpg) · [Detalle lado a lado](capturas/08-base-linda/antes-despues-detalle.jpg) · [Modo foto](capturas/08-base-linda/modo-foto.jpg)
- Al revisarlas se ve:
  - Antes había una bandera azul en cada casa, almacén y granja; ahora no están.
  - El bosque talado queda como un claro de tocones sobre tierra pisada.
  - Hay leña apilada junto al almacén de madera.
  - Las hileras de las granjas tienen cultivo.
  - Las partidas son iguales hasta el cuadro: misma población, mismos recursos y mismos sitios.

## Tropiezos

- `Meshes._banner` no sabe en qué edificio está. Por eso CivMeshes fija el estandarte (`bandera_on`, `bandera_k`) antes de armar cada edificio y lo suma a la clave del caché. Así, al cambiar la opción, las mallas se rearman.
- Los modelos GLB llevaban su estandarte aparte, con `team_banner`, y había que filtrarlo también.
- En la prueba de estandartes quedaban «pendientes» los edificios del rival bajo la niebla. Es lo correcto: se rehacen cuando se ven.

## Queda para después

- Más zoom lejano en modo foto (no se tocó `rts_camera.gd`).
- Planos sin pagar (C20) y muralla de piedra (C19): están en consulta.

## Commits

- fd6a00a: captura de antes.
- 312bf78: estandartes, tierra pisada, pilas, cultivo, tocones y modo foto.
- afa4307: tierra pisada más barata, lista de granjas, sin anillos en modo foto, `tools/base_linda.gd`.
- Este commit: documento, capturas en JPG y prueba.
