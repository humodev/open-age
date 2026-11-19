# 33 · 02 · Implementación del comercio (iteración 1b)

> Pedido: implementar el diseño aprobado (`README.md` de esta etapa, decisiones del 2026-11-19 en `CONSULTAS.md`) con los 8 pasos de su plan, un commit por paso. Bloques marcados `# --- comercio ---`; la lógica vive en `src/sim/sim_comercio.gd` (nuevo) para no pisar a los otros dos agentes (esport 1a y rendimiento).

## Paso a paso

| Paso | Qué quedó | Commit |
|---|---|---|
| 1 | Mercados neutrales en el generador (`SimComercio.place_1v1`, `place_n`), indestructibles, explorados desde el principio, con el nombre del terreno | a6dac93 |
| 2 | Comerciante: ida, carga (2 s), vuelta, descarga y cobro; fórmula, edad, tipo, pueblo y saturación; no cuenta para lo disputado; el ingenio no le tira | 12bda92 |
| 3 | Bloqueo: mercado tomado por presencia, camino cerrado, avisos con lugar | 1778353 (la simulación, con el 2) |
| 4 | Interfaz: ruta con clic derecho, punto de paso con Mayús, línea con flechas, botón «Rutas» del minimapa, ganancia esperada junto al cursor | 37c997a |
| 5 | Pueblos: nombres, `comercio_pct` (amole, moradores, astilleros), astilleros −20 % de costo, Massawa con ruta abierta | 28fbace |
| 6 | IA: comercia, torre en la ruta, defensa, corte con montados; `tools/comercio_medida.gd` | 608f995 |
| 7 | Arte: comerciante animado con la carga de su pueblo (solo a la vuelta), glifos, tres maquetas del neutral | e3f87d9 |
| 8 | Balance: A 220 → 200, la III 70 → 60 %; IA 4 / 10 / 16 (como el diseño) | 3757d92 y el último |

### 1. Mercados neutrales

- **1v1:** sobre la antidiagonal (la mediatriz entre las bases), a 8 casillas del borde, en las dos puntas; si el lugar no sirve, se corre por la mediatriz hacia el centro (x + y constante).
- **Mapas para N:** sobre la mediatriz real de las dos bases vecinas de cada hueco elegido (no la del rumbo de la tabla: el redondeo de las bases daba 5 % de diferencia), a `lado/2 − 10` del centro. Dos equipos: los dos huecos entre equipos (+1 sobre la mediatriz en mapa grande, a 3/5 del radio). Todos contra todos con N par > 4: un hueco de cada dos (cada base toca uno); con N impar, todos (la equidad gana al tope de 4).
- **Corrimiento común:** se busca un mismo corrimiento (hacia el centro y de costado) que sirva para todos; con dos equipos, solo hacia el centro (sobre la mediatriz). Si no hay, cada uno el suyo y, como último recurso con dos equipos, se rellena la orilla (el puerto).
- La huella se empareja a la altura del centro, se talan los árboles alrededor y los bosques no se generan a menos de 11 casillas. Se exige que se llegue por tierra desde una base vecina (con sus puertas abiertas: en fortines faltaba uno).
- **Desvío del diseño:** la distancia es en línea con raíz entera (`Sim.isqrt`, determinista), no octil: la octil no es igual en todos los rumbos y con 3, 5, 6 o 7 bases daba hasta 8 % de diferencia entre jugadores en el mismo lugar.
- `tests/equidad.gd` (nueva parte): siempre 2 o más; diferencia de la distancia al más cercano y al más lejano ≤ 3 % (1v1 y todos contra todos entre todos; con equipos, cada jugador con su espejo). Peor medido en 13 terrenos: **3 %**; antes de los arreglos, 163 % (fortines) y 22 % (6 todos contra todos).

### 2–3. Comerciante y bloqueo

- `unidades.comerciante`: III, 60 de alimento y 100 de madera, 25 s, 100 PV, 0/1 de armadura, 1 400 de velocidad, función `comercio` (ni aldeano ni militar).
- G = d·(d·A/L + B)/100, × edad × tipo (neutral 100, aliado 100 y +20 % creado para el aliado, propio 50) × pueblo × saturación (10 libres, −3 % cada uno, piso 60). Se fija al cargar y se cobra al volver; muerto en el camino, se pierde.
- Bloqueo al llegar: 6 o más de población militar enemiga a 6 casillas (+1,5 por la huella) y ninguna tropa propia o aliada → vuelve vacío y suceso `ruta_cortada` («tomado»). El camino que no llega al mercado (muralla que lo cierra) → «cerrado». Un aviso por ruta hasta que se reabra.
- Avisos (`alertas.gd`, dentro de los de la ronda 8): «Atacan a tus comerciantes · en la ruta a la feria», uno por ruta cada 30 s; «Ruta cortada en la feria (mercado tomado | camino cerrado)», con lugar y Espacio.
- `tests/comercio.gd`: fórmula en 5 distancias (18, 67, 147, 192, 280 contra ~18, 68, 148, 192, 282 del diseño), propio 50 %, III, II, enemigo, saturación, cobro al volver (no al cargar), libro «comercio», lo disputado en 0, muerte con carga, aliado +20 %, mercado tomado, aviso único, muralla, y los pueblos. **OK.**

### 4. Interfaz

Clic derecho de comerciantes en un mercado → ruta (`"ruta"`); Mayús + clic derecho en el suelo → punto de paso (`"ruta_paso"`), que queda para la próxima ruta. Mercado propio elegido + Mayús + clic derecho → punto de paso de sus comerciantes; reunión en un mercado → salen a la ruta. Línea punteada del color del jugador con flechas hacia el mercado propio; el neutral elegido muestra el radio de bloqueo (rojo si está tomado). Minimapa: rutas de lo elegido siempre; botón «$» (Rutas) para todas las propias y aliadas, y las enemigas con visión. Junto al cursor: «Ruta a mercado neutral · 81 casillas / ~120 de riqueza por viaje, ~60 por minuto cada uno».

Capturas: `capturas/paso4-ruta.png` (la ruta con punto de paso, revisada: la línea sale del mercado, dobla en el punto y sigue al neutral; el minimapa la muestra) y `capturas/paso7-feria.png` (la feria con toldos y banderín ocre, dos mercaderes jabarti cargando).

### 5. Pueblos

| Pueblo | Comerciante | Bono |
|---|---|---|
| Tawantinsuyu | Caravana de llamas [verificar: ¿comerciaba con mercados ajenos?] | — |
| Mapuches | Conchavador [verificar la fecha] | — |
| Guaraníes | Tropa de yerba [verificar] | — |
| Etiopía | Mercader jabarti | Caravanas de amole: +20 % al comerciante (antes era la venta); Pólvora de Massawa: +10 % solo con un viaje cobrado en los últimos 3 min |
| Palmares | Mascate [verificar] | Trato con los moradores: +15 % al comerciante (además de la venta) |
| Ayutthaya | Cargadores del río [verificar] | Astilleros de juncos: −20 % de costo y +10 % (además de la venta) |

Los marcados van a los historiadores. Pendiente: el *chaski en relevo* inca sobre la ruta y el animal de carga (llama, mula) del arte.

### 6. IA

`reglas.ia_comercio` y `dificultades.<n>.comercio`. Desde la III con mercado, si la arcilla cercana baja de 1 500 o hay un destino a 60 casillas o más: 4 en la III, 10 en la IV, 16 sin arcilla en casa (fácil 4). Elige destino por ganancia por minuto con la saturación; con dos cortes seguidos cambia. Torre a mitad de la ruta más usada (normal en adelante), tropa ociosa al comerciante golpeado. Difícil y experta cortan rutas con 6 comerciantes a la vista (3–6 montados a la mitad), sin salir mientras un aliado está en una oleada; la normal, solo cerca de su capital.

### 8. Balance

`tools/comercio_medida.gd -- --partida=1` (experta contra experta, llano), después de integrar main (sitios a 60/45/30):

| Partida | Semilla | Meta | Medido | Comerciantes muertos |
|---|---|---|---|---|
| 1v1, 30 min | 7 | ≤ 15 % antes del 25 | **13 %** (1 972 de 14 249) | 8 |
| 1v1, 30 min | 11 | ≤ 15 % antes del 25 | **14 %** (2 114 de 14 131) | 1 |
| 2v2, 45 min | 7 | 30–45 % después del 30 | **37 %** (14 686 de 39 653) | 45 |
| 2v2, 45 min | 11 | 30–45 % después del 30 | **20 %** (6 823 de 33 796) | 29 |

Antes de ajustar (A 220, III 70 %, sitios 18/12/8): 1v1 17 %, 2v2 49 %. Con A 200, la III al 60 % y la IA con 8 en la IV, el 2v2 dio 29 y 45 % antes de integrar main; con los sitios de 1a (60/45/30) bajó a 36 y 20 %, y se volvió a 10 en la IV y 16 sin arcilla (37 y 20 %). En la semilla 11 el equipo de abajo perdió 40 comerciantes: la parte baja porque la ruta se peleó (lo que pedía C: un ataque a una ruta que decide algo). La meta 1 se cumple; la 2, en una de dos semillas (promedio 28 %). Próxima palanca, sin tocar el 1v1: el aliado (+20 → +30 %) o A solo en mapas de 176 o más.

Números finales en `reglas.comercio`: A **200**, B 10, edad_pct [0, 0, **60**, 100], tipo_pct 100/100/50, aliado +20 %, saturación 10/3/60, carga 2 s, bloqueo 6 casillas y 6 de población, aviso 30 s, ruta abierta 3 min. IA: 4 / 10 / 16. Partidas en `pruebas-1b/`.

Tabla sin partida (en la IV, sin saturación, mercado a 8 casillas de la capital; llano y río dan igual):

| Mapa | L | Neutrales | d (cerca / lejos) | Por viaje | Por minuto | Aliado (d, por min) |
|---|---|---|---|---|---|---|
| 1v1 | 128 | 2 | 86 / 88 | 123 / 129 | 58 / 59 | – |
| 2v2 | 176 | 2 | 55 / 119 | 39 / 172 | 28 / 59 | 74, 37 |
| 2v2 grande | 216 | 3 | 69 / 156 | 50 / 240 | 29 / 63 | 102, 42 |
| 3v3 | 208 | 2 | 50 / 155 | 29 / 246 | 23 / 65 | 65, 28 |
| 4v4 | 240 | 2 | 46 / 187 | 22 / 308 | 18 / 68 | 63, 24 |
| 4 todos | 176 | 4 | 55 / 119 | 39 / 172 | 28 / 59 | – |

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | OK, hash **916860075** (main 3870415820; con `sin_mercados` da exactamente 3870415820) |
| `tests/bench.gd` | 8,2 ms de promedio, peor 64,7 ms |
| `tests/comercio.gd` (nuevo) | OK |
| `tests/equidad.gd` | OK (neutrales: peor 2 %) |
| `tests/equipos.gd` | OK |
| `tests/casillas.gd` | OK (600 grillas) |
| `tests/grilla.gd` | OK |
| `tests/iconos.gd` | OK (745 grillas) |
| `tests/civ_smoke.gd` | sin errores (antes de integrar main) |
| `--autotest --civ=etiopia --terreno=llano` | OK, 230 comprobaciones, con las nuevas de la ruta |
| `tools/primera_victoria.gd` 7, 21, 3 | **1 de 3** (main: 2 de 3). Con los mercados apagados da 2 de 3 como main: la partida es idéntica hasta el minuto 8 y se separa por un depósito de 10 de riqueza (efecto mariposa del mapa; la IA fácil no llega a la III). En 1, 2, 4, 5 y 6: 2 de 5. Queda abierto. |

## Tropiezos

- La octil no es pareja en todos los rumbos (ver paso 1). Los ríos pasan justo por los huecos entre bases: hubo que correr todos los neutrales del mismo lado.
- En bosque y montaña casi no hay 3×3 plano: se empareja la huella en vez de pedirla plana.
- En fortines el camino de prueba no pasaba las puertas propias (se buscaba con las puertas cerradas para todos).
- El neutral sin explorar no se podía elegir: ahora todos lo conocen desde el principio.
- Con los sitios de la iteración 1a (60/45/30) la riqueza de los sitios subió y la parte del comercio en el 2v2 bajó de 45 % a 20–36 %; se volvió a la cantidad de comerciantes del diseño.
- La primera victoria bajó de 2 de 3 a 1 de 3 sin que el comercio intervenga: en 1v1 los neutrales ahora van después de los bosques y sin talar, pero la partida igual diverge al minuto 8.
- El autotest «la veta chica avisa que se agota» falla a veces (ya lo decía 32/03); no lo toca el comercio.

## Commits

a6dac93, 12bda92, 1778353, 37c997a, 28fbace, 608f995, e3f87d9, 3757d92, f75a7b2 (merge de main) y el del balance final con este documento.
