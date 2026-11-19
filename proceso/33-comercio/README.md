# 33 · Comercio: mercados neutrales, comerciante y rutas

> Pedido del autor (textual): «Avancemos con el comerciante. Los mercados neutrales tienen que estar siempre presentes, al menos 1 o 2. Consultá con el experto la mejor forma de hacerlo y cómo balancearlo. Eso va a incluir rutas y bloqueo de rutas, un cambio grande. Hagámoslo bien.»

Diseño a dos voces: **V**, el veterano competitivo de AoE4 (1v1, partidas cortas), y **C**, el constructor de partidas largas en equipo (AoE2 DE y AoE4). Parte del diseño 27 (§4.3, «el comerciante que camina») y de la etapa 32 (recursos del mapa). Las cifras de AoE van con **(aprox.)**: son de memoria de juego, no de una tabla oficial.

## 0. De dónde partimos

- **Mercado de hoy** (`edificios.mercado`, edad II, 175 de madera): compra y venta por lotes de 100 (`reglas.mercado`: precio 100, paso 3, piso 40, techo 300, comisión 30 %). `_cmd_trade` es instantáneo y no sale de la base: nada para cortar.
- **Riqueza en el mapa** (etapa 32): 4 700–6 000 por jugador. Un aldeano en la arcilla junta 0,7/s (42 por minuto bruto, ~35 con la caminata). En el 2v2 de 45 min, lo que falta al final es riqueza.
- **Neutrales que ya hay:** el ingenio (hostil, botín una vez, vuelve a los 6 min) y los sitios sagrados (renta 18/12/8). Lo disputado tiene techo: `disputado.tope_por_min` 15/40/80/120.
- **Diseño 27 aprobado:** comerciante en la IV, entre el mercado propio y uno aliado «o el ingenio neutral», que rinde más cuanto más lejos y se puede cortar. Bonos ya escritos en las fichas: amole +20 %, Palmares +15 %, astilleros de juncos −20 % de costo y +10 %, khlong lat +25 % de velocidad, Massawa «solo con una ruta abierta».
- **Ronda 8 (04, §4):** «los sitios no pagan» y «no hay vía de vuelta». El comercio es la segunda forma de ganar el mapa sin ganar la base.

## 1. Mercados neutrales

**Qué son.** Un edificio nuevo, `mercado_neutral`: sin dueño, **indestructible y no se captura** (como los puestos de comercio de AoE4). No dispara. Se lo «toma» por presencia (§4).

- **V:** «Indestructible sí. Si se puede romper, el primero que llega con el asedio cierra el comercio del rival para siempre, y eso es una pelea de un solo golpe.»
- **C:** «De acuerdo, pero quiero algo que defender ahí: si no, es un poste.» → Se lo defiende **estando**: la tropa enemiga al lado lo cierra (§4).
- **El ingenio no es mercado.** El diseño 27 decía «o el ingenio neutral». Los dos lo sacan: es un campamento hostil para saquear; y comerciar con un ingenio azucarero, que Palmares asalta para liberar gente, no se lee bien. **El ingenio no le tira al comerciante** (no lo persigue ni lo apunta), para que las rutas no dependan de dónde cayó.

**Cuántos y dónde** (`reglas.comercio.neutrales`):

| Partida | Lado (normal) | Neutrales | Dónde |
|---|---|---|---|
| 1v1 | 128 | **2** | Sobre la mediatriz entre las bases, a 8 casillas del borde, uno en cada punta |
| 2 equipos (2v2, 3v3, 4v4) | 176–240 | **2** (+1 al centro del borde lateral en mapa grande) | Sobre la mediatriz entre los dos equipos, en los bordes |
| 3 o más equipos / todos contra todos | 176–240 | **uno por hueco entre bases vecinas, tope 4** | En el borde, a mitad de camino entre dos bases del anillo (el sitio sagrado queda a un tercio hacia el centro, como hoy) |
| Campañas | — | los que diga el escenario | — |

- **Justicia:** sobre la mediatriz, cada neutral queda **a la misma distancia de cada base del lado enfrentado** (en 1v1, el `_mirror` ya lo da). Con equipos «juntos», el de atrás queda más lejos que el del frente: **eso es a propósito** (C: «el de atrás es el que comercia, como en AoE2»).
- **Equidad medida:** la distancia en línea de cada base a su neutral más cercano y al más lejano no difiere más de 3 % entre jugadores en la misma posición (`tests/equidad.gd`, como la piedra).
- **Mínimo 2 siempre** en escaramuza. Si un lugar cae en agua o está ocupado, se corre por la mediatriz hacia el centro (como los sitios desde la etapa 22); si no entra, va al otro borde.
- **Tamaño:** el número no cambia con chico o grande (salvo el +1 de grande en equipos); cambia la distancia, y la ganancia la sigue (§2).
- **AoE4 (aprox.):** 2–4 puestos neutrales en bordes de algunos mapas, no en todos. **AoE2:** sin neutrales; solo mercado aliado (en 1v1 no hay comercio por tierra). Nosotros: siempre, en todos.

**Identidad por terreno** (solo nombre y aspecto; la mecánica es la misma). Es un lugar de nadie: no toma el nombre de un pueblo jugable.

| Terrenos | Neutral | Aspecto |
|---|---|---|
| llano, bosque, bosque templado, mesetas, fortines | **Feria** | ramada con toldos, bultos y cántaros |
| río, delta, selva y río, islas | **Puerto de río** (en la orilla, se llega por tierra) | muelle con pilotes, canoas amarradas |
| altiplano, valle de altura, sierra, montaña | **Feria de altura** (*qhatu* en la sierra colonial [verificar]) | corral de pirca, mantas, llamas echadas |

Lo andino va como **feria**, no como tambo: el tambo era del Estado inca y no un mercado (Murra, 1975); el Tawantinsuyu ya tiene su tambo propio. *Qhatu* es palabra colonial (el «gato» de Potosí), por eso el [verificar] y la consulta a los historiadores.

## 2. Comerciante

**La unidad** (`unidades.comerciante`): se hace en el mercado propio.

| | Raíces | AoE2 carreta (aprox.) | AoE4 mercader (aprox.) |
|---|---|---|---|
| Edad | **III** (rinde 70 %) y **IV** (100 %) | Castillos | Feudal |
| Costo | **60 alimento + 100 madera**, 25 s, 1 de población | 100 madera + 50 oro | barato, sin oro |
| Velocidad | **1 400** (aldeano 1 250, montado 2 100–2 200) | algo más rápido que el aldeano | ídem |
| Vida, armadura | **100 PV**, 0 cuerpo / 1 distancia | ~70 | ~100 |
| Carga | no es carga: el viaje vale lo que diga la fórmula | ídem | ídem |

Se paga en madera (que sobra, etapa 32) y alimento: no compite con la riqueza que trae.

**Fórmula** (enteros; `d` en casillas, `L` lado del mapa):

    d  = distancia octil entre los centros de los dos mercados = max(dx,dy) + min(dx,dy)·414/1000
    G  = d · (d · A / L + B) / 100                    con A = 220, B = 10
    G' = G · edad_pct · tipo_pct · pueblo_pct · saturacion_pct / 100⁴

Cuadrática en la distancia y normalizada por el lado, como la de AoE2; la de AoE4 tiene la misma forma (aprox.). La distancia es **en línea**, no la caminada: un rodeo por murallas no paga más, cuesta tiempo. Cobra **al volver al mercado propio** (ida, 2 s de carga, vuelta, 2 s de descarga): el riesgo es el viaje entero. La riqueza viaja a la vista, con la carga dibujada.

| Mapa (L) | d | Riqueza por viaje | Ida y vuelta | Por minuto (IV) | En la III |
|---|---|---|---|---|---|
| 1v1 (128) | 30 | 18 | 47 s | 23 | 16 |
| 1v1 (128) | 60 | 68 | 90 s | 45 | 32 |
| 1v1 (128) | 90 (neutral) | 148 | 133 s | **67** | 47 |
| 2v2 (176) | 120 (aliado de atrás o neutral) | 192 | 175 s | **66** | 46 |
| 4v4 (240) | 170 | 282 | 247 s | **69** | 48 |

Un aldeano en la arcilla saca ~35–42 por minuto. **El comerciante le gana desde unas 60 casillas.**

**Con quién** (`tipo_pct`):

| Destino | Raíces | AoE2 (aprox.) | AoE4 (aprox.) |
|---|---|---|---|
| Neutral | **100 %** | no hay | sí, la ruta principal |
| Mercado aliado | **100 %, y el aliado recibe 20 % extra** (creado, no descontado) | sí, igual que cualquier otro | sí |
| Mercado propio | **50 %** | no se puede [verificar] | no se puede [verificar] |

- **C:** «El aliado tiene que ganar algo: en un 2v2 el de atrás comercia con el del frente y los dos ponen el pellejo.» **V:** «Que no sea el doble, o en equipo nadie mina.» → **+20 % al aliado**.
- **Propio al 50 %:** V lo quería prohibido (se comercia adentro de la base, sin riesgo). C lo pide para el todos contra todos sin aliados. Queda al 50 %: con dos mercados en las puntas de una base ancha (d ≈ 40) da ~15 por minuto, peor que un aldeano.

**Rendimiento decreciente** (no hay tope duro, como en AoE): por jugador y por mercado destino, los primeros **10** comerciantes rinden 100 %; cada uno más baja **3 %** a todos los de esa ruta, con piso de **60 %** (20 comerciantes → 70 % → rinden como 14). Dos neutrales y un aliado son tres rutas: abrir otra paga. **No cuenta para `disputado`**: ya tiene su riesgo y su techo propio.

## 3. Rutas

- **Camino:** el más corto del buscador de caminos de hoy, calculado al asignar y guardado por ruta; se recalcula solo si queda bloqueado (muralla nueva). No hay camino fijo: V: «la ruta fija se aprende y se emboscan siempre en el mismo lugar»; C: «la libre se mete por el medio del rival». **Acuerdo:** la más corta, y el jugador puede poner **un punto de paso** (clic con Mayús desde el mercado o el comerciante) que la desvía.
- **Cómo se ve:** al seleccionar un comerciante o un mercado, la ruta como línea punteada en el suelo y en el minimapa, con flechas en el sentido de la carga. Botón «Rutas» en el minimapa para verlas todas (propias y de aliados); las enemigas solo donde hay visión. A pedido, no siempre.
- **Caminos y agua:** el comerciante usa los modificadores de movimiento que ya hay: el Qhapaq Ñan (+30 %, +5 % con *Q'eswa chaka*), los vados con *Ygá* (+30 %), el *khlong lat* (+25 %). No hay comercio por agua (sin combate naval, D-020). El camino **no cambia la ganancia**, solo el tiempo: el inca que pavimenta la ruta gana ~30 % más por minuto, y el que corta el camino se lo saca.

## 4. Bloqueo y protección

Cómo se corta una ruta, de más barato a más caro:

1. **Matar comerciantes.** 100 PV: un montado lo mata en 3–4 golpes. Es lo principal, como en AoE.
2. **Torres o tropa en el camino.** La torre le tira; el comerciante **no se desvía solo** (como en AoE2): muere o el dueño le pone un punto de paso.
3. **Murallas o empalizadas que obligan a rodear.** El camino se recalcula; la ganancia no cambia y el viaje se alarga. Una muralla que cierra del todo deja la ruta **cortada** (aviso).
4. **Tomar el mercado (presencia).** Si al llegar hay **6 o más de población militar enemiga** a **6 casillas** del neutral (o del mercado aliado) y **ninguna tropa propia o aliada**, no se descarga: el comerciante vuelve vacío y el dueño recibe «Ruta cortada en ...». Es la forma de «capturar» sin dueño. **V:** «Así se pelea el mercado como un sitio, sin que sea un sitio.»
5. **Romper el mercado del dueño** (el propio sí se destruye): corta todas sus rutas.

Contrajuego del dueño: escolta (los comerciantes en grupo se siguen con la orden de seguir que ya hay), **torres en la mitad de la ruta**, la otra punta (siempre hay 2 neutrales), la ruta aliada, y un **mercado adelantado** (acorta d y gana menos, pero es más seguro).

**Avisos** (dentro de lo que dejó la etapa 32: «ataques por zona y tipo, con lugar y Espacio»):

- «Atacan a tus comerciantes» con lugar, **uno por ruta cada 30 s** (no por comerciante).
- «Ruta cortada» (mercado tomado o camino cerrado), con lugar, una vez hasta que se reabra.
- Nada más: ni «viaje terminado» ni «comerciante creado» (aprendizaje, si acaso).

## 5. Balance

- **Cuándo conviene:** desde unas 60 casillas el comerciante saca más por población que el aldeano; en la III rinde 70 %, así que en 1v1 recién empata con la arcilla. Paga lo que costó en ~2,5 min.
- **Economía tardía como AoE2:** la arcilla de casa se agota (C-16) y la lejana se pelea; el comercio es lo que queda cuando las vetas se acaban. En la IV es la riqueza **renovable** del juego junto con los sitios (y la granja para el alimento).
- **V, que no domine el 1v1 corto:** sale en la III (minuto 17–18 en la experta) al 70 %, se mata fácil y tarda 2 min en pagarse. Meta: **en 1v1, ≤ 15 % de la riqueza antes del minuto 25**.
- **C, que valga en el largo en equipo:** el aliado suma 20 %, los mapas grandes rinden ~70/min por comerciante y no hay tope duro. Meta: **en 2v2 de 45 min, 30–45 % de la riqueza después del 30**, y que al menos un ataque a una ruta decida algo (comerciantes muertos > 10).
- **Números iniciales** en `data/reglas.json → comercio`: A 220, B 10, edad_pct [0,0,70,100], tipo_pct {neutral 100, aliado 100, propio 50}, aliado_extra_pct 20, saturacion {libres 10, paso 3, piso 60}, carga_ms 2000, bloqueo {radio 6000, pob_min 6}, aviso_ms 30000.
- **Cómo se mide:**
  - `tools/comercio_medida.gd` (sin partida): por terreno y tamaño, la distancia de cada base a cada neutral y a cada aliado, la riqueza por viaje y por minuto (tabla de §2), y la equidad.
  - `tools/recursos_partida.gd` con `--comercio=1`: cada minuto, riqueza por fuente (arcilla, sitios, comercio, mercado), comerciantes vivos y muertos, rutas cortadas. 1v1 30 min y 2v2 45 min, 2 semillas, IA experta contra experta.
  - Torneo por hito (no por paso): `tests/torneo.gd -- --minutes=30 --seeds=2` al cerrar la etapa.

## 6. IA

- **Cuándo comercia:** desde la III si tiene mercado y (a) su arcilla cercana está por debajo de 1 500, o (b) hay un aliado o neutral a 60 casillas o más. Arranca con 4, sube a 10 en la IV y a 16 si la arcilla propia se acabó; reparte entre rutas para no saturar. La fácil, máximo 4.
- **Cómo protege:** una torre en la mitad de la ruta más usada (normal en adelante); si avisan que atacan comerciantes, manda a la defensa al lugar (la respuesta que ya hay, con el lugar del aviso); si la ruta queda cortada dos veces seguidas, cambia de destino.
- **Cómo ataca la del rival** (difícil y experta): si ve 6 o más comerciantes enemigos en una ruta, manda un grupo montado (3–6) a cortarla a mitad de camino; con equipos, coordina con los turnos de ataque de la etapa 32 (no sale a la ruta mientras su aliado está en una oleada). La normal solo corta si pasan cerca de su base.

## 7. Identidad por pueblo

Nombres y bonos que ya están en el diseño 27 y en las fichas. Nada sagrado. Los pueblos sin entrada usan «Comerciante» y «Mercado» hasta que sus historiadores digan.

| Pueblo | Comerciante | Bono propio |
|---|---|---|
| Tawantinsuyu | **Caravana de llamas** (de intercambio, no de mercado; Murra, 1975) | Ninguno nuevo: el Qhapaq Ñan ya acelera; *chaski en relevo* da visión sobre el camino de la ruta |
| Mapuches | **Conchavador** (conchavo de ganado y ponchos, siglo XVIII) | *Ponchos*: venta +20 % (ya está); el neutral de su terreno se llama «Feria» como su frontera |
| Guaraníes | **Tropa de yerba** (la yerba bajaba en balsas hasta Santa Fe) [verificar] | *Ygá*: vados +30 % (ya está) |
| Etiopía | **Mercader *jabarti*** con la caravana de *amole* (Pankhurst, 1961) | *Caravanas de amole*: el comerciante rinde +20 %; *Pólvora de Massawa*: +10 % **con una ruta abierta** (un viaje cobrado en los últimos 3 min) |
| Palmares | **Mascate** (vendedor ambulante) [verificar] | *Trato con los moradores*: +15 % al comerciante |
| Ayutthaya | **Barca del río** (*ruea*, เรือ): en tierra, cargadores con la vara al hombro | *Astilleros de juncos*: −20 % de costo y +10 %; *khlong lat*: +25 % de velocidad en el canal |

**Desacuerdo menor:** C quería que el inca no comercie con neutrales (redistribuía, no comerciaba). V: «un pueblo sin la economía tardía en el 4v4 es injugable». Queda: comercia con todos, con el nombre de intercambio; la consulta va a los historiadores.

## 8. Arte

- **Hasta tener modelos, maqueta procedural** (pide responder C-80 con «b» para esta unidad):
  - **Comerciante:** la figura animada del aldeano con la carga del pueblo (`arte_animaciones.tropas.por_civ.comerciante`: `carga` = fardo, cántaro, barras, cesto, vara) y, si lleva animal, el de `arte_animales` (llama, mula, buey). Vacío a la ida, cargado a la vuelta.
  - **Neutral:** tres maquetas por terreno (§1), con un banderín ocre sin color de jugador y un anillo en el suelo del radio de bloqueo cuando está seleccionado; se tiñe de rojo si está tomado.
- **Con modelo:** llama con alforjas, mula con barras de sal, cargadores con vara, jinete con fardos de ponchos. La ruta en el suelo, decal punteado del color del jugador.
- Solo imagen: la simulación no lo lee y el hash no cambia.

## 9. Plan de implementación

Cada paso se prueba solo. La simulación sigue entera: distancia octil sin raíz, multiplicaciones y divisiones enteras, sin `Time` ni azar fuera del `rng` de la partida.

| Paso | Qué | Simulación | data/ | Pruebas |
|---|---|---|---|---|
| 1 | Mercados neutrales en el generador (2 a 4, mediatriz, bordes, corrimiento si cae al agua) | `sim.gd` (generador), `mercado_neutral` indestructible | `edificios.mercado_neutral`, `reglas.comercio.neutrales`, `terrenos.*.neutral` | `test_determinism` (hash nuevo), `equidad.gd` (+ distancia a neutrales), `bench` |
| 2 | Comerciante y ciclo ida–carga–vuelta–cobro, con la fórmula y la saturación | estado nuevo en la unidad, `ledger(...,"comercio",...)` | `unidades.comerciante`, `reglas.comercio` | `tests/comercio.gd` nuevo: fórmula en 5 distancias, propio 50 %, aliado +20 %, saturación, cobro al volver |
| 3 | Bloqueo: presencia en el mercado, ruta recalculada, ingenio que no apunta comerciantes, avisos | `sim.gd`, `sim_mods.gd` | `reglas.comercio.bloqueo` | `comercio.gd`: muralla que rodea, 6 de pob enemiga que cierra, aviso uno por ruta |
| 4 | Interfaz: orden de ruta (clic derecho en mercado), punto de paso, línea, botón «Rutas» del minimapa | controlador y minimapa | `interfaz.json` | autotest con guaraníes y llano + captura |
| 5 | Pueblos: nombres, `comercio_pct`, Massawa con ruta abierta, astilleros | `sim_mods.gd` (efecto nuevo) | `civs/*.json` | `civ_smoke.gd` |
| 6 | IA: comercia, protege, corta | `sim_ai.gd` | `reglas.ia_comercio` por dificultad | `civ_smoke`, `equipos.gd`, `recursos_partida --comercio=1` |
| 7 | Arte: maquetas del comerciante y de los tres neutrales | solo vista | `arte_animaciones`, `arte_edificios` | captura con `--shot` |
| 8 | Balance con las metas de §5 | — | `reglas.comercio` | `comercio_medida.gd`, 1v1 30 min y 2v2 45 min, torneo 30 min × 2 semillas |

## 10. Dónde coinciden y dónde no

**Coinciden:** neutrales indestructibles y siempre presentes (mínimo 2); fórmula cuadrática por distancia en línea; cobrar al volver; matar comerciantes como el corte principal; tomar por presencia; sin comercio por agua; sin tope duro, con rendimiento decreciente; avisos por ruta, no por unidad.

**El desacuerdo principal: la edad.** V lo quería **solo en la IV**, como el diseño 27 («en la III el 1v1 se vuelve una carrera a la ruta»). C lo quería **desde la III a pleno** («la arcilla de casa se acaba al 25 y la IV llega al 21; sin comercio en la III, el equipo de atrás no tiene qué hacer»). **Queda: desde la III al 70 %**, y el paso 8 decide con las dos metas de §5. Si en 1v1 pasa del 15 % antes del 25, se sube a la IV.

**Otros:** propio a mercado propio (V: prohibido; C: igual que el resto) → 50 %. El aliado (V: igual; C: doble) → +20 % para el aliado. El inca y el neutral (§7) → consulta.

## Consultas propuestas para el autor (van a `CONSULTAS.md` al integrar)

1. Edad del comerciante: III al 70 % *(por defecto)* · solo IV (diseño 27).
2. Comercio entre mercados propios: 50 % *(por defecto)* · prohibido.
3. C-80 para el comerciante y el neutral: maqueta propia *(por defecto aquí)* · esperar el arte.
4. Nombres a revisar por los historiadores: *qhatu*, «tropa de yerba», «mascate», y si el inca comercia con neutrales.

## Commits

Ninguno todavía (documento de diseño).
