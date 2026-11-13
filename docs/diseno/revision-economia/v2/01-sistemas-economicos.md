# 01 · Sistemas económicos, ronda 2

Perfil: diseño de sistemas económicos. Parte de la ronda 1 ([`../01-sistemas-economicos.md`](../01-sistemas-economicos.md)), de la síntesis y de la investigación en [`../../investigacion-aoe4/`](../../investigacion-aoe4/). No fija números (D-008). Los porcentajes son objetivos para medir con el torneo.

## 1. El modelo revisado

**"Una riqueza, seis motores" sigue en pie, pero con tres correcciones.** Hay un solo recurso de riqueza, con la misma clave, los mismos costos y el mismo lugar en el HUD. Cada pueblo lo produce a su manera. Lo que cambia respecto de la ronda 1:

1. **Fuera el comercio como motor.** El trueque de Palmares y la venta en el almacén de Ayutthaya eran "comercio con otro nombre", y eso lo pueden hacer todos (criterio 2). Ahora los dos motores salen de algo que el jugador ya hace.
2. **Fuera la atención alta.** Las mulas de sal etíopes (viajes repetidos) y las ventanas del puerto (estar pendiente del reloj) se van. Cada motor pide una decisión de dónde o cuándo, y después funciona solo.
3. **Todo lo pasivo tiene tope y lugar.** Ningún motor es "construyo N y cobro N veces".

### Comparación con el favor de Age of Mythology

Es el precedente directo (investigación 03, §3): un sumidero común (unidades míticas) y un motor distinto por panteón. De ahí tomo esto:
- **Comparar curvas, no tasas.** Se mide la riqueza acumulada a los 5, 10 y 20 minutos, y el ajuste toca la forma de la curva, como Retold con los monumentos egipcios.
- **Piso pacífico para lo agresivo.** Retold les dio a los nórdicos caza, goteo y un techo blando. El malón y las correrías son variantes con techo; el motor pacífico alcanza solo.
- **Atención baja.** Se decide cuántos rezan o dónde va el oráculo; nadie cliquea cada tanto.

### Lo que enseña el catálogo de AoE4 sobre los ingresos pasivos

- **El pasivo que se apila se rompe**: Lancaster, el ganado malí y las cabañas rus terminaron con tope y ubicación (patrón 1). Por eso cada motor tiene un **techo** y una **decisión espacial**.
- **"Lo pongo y funciona" no da identidad**: los otomanos son planos; los malíes y los vikingos obligan a elegir veta o anexo (patrón 3). Por eso cada motor tiene un **dilema**.
- **El subproducto funciona**: el aceite bizantino y la plata macedonia no enseñan una tarea nueva (patrón 4). Lo uso en tres civs, cada una con otra fuente.
- **El goteo sin contrajuego cansa** (AoE3, §2.5): todo motor tiene una pieza atacable.

## 2. Los seis motores

Tipos según la tipología de la investigación 03, §10:
- **renta**: goteo sin trabajadores (2);
- **asignación**: trabajadores puestos en un edificio (3);
- **posición**: el lugar decide cuánto rinde (5);
- **botín**: recurso por combate (6);
- **crecimiento**: capital que crece (8);
- **conversión**: convertir una cosa en otra;
- **subproducto**: algo extra que sale de una tarea común.

| Civ | El motor, en palabras llanas | Pieza | Atención | Tope | Qué decisión pide |
|---|---|---|---|---|---|
| **Tawantinsuyu** | Los aldeanos generan "turnos de trabajo" solos. Un taller transforma, de forma continua, una parte de esos turnos en riqueza. | Conversión de un recurso que ya es subproducto | **Baja**: construir y, si hace falta, pausar | Cada taller convierte hasta una cantidad fija por minuto; cantidad de talleres por edad | Cuánto trabajo va a tela y cuánto a red y comida. Si tejés mucho, tu red crece lenta. *Nombre: taller de cumbi; la mit'a y la tela fina como bien de Estado (Murra)* |
| **Mapuches** | La riqueza **es** el rebaño. Cada corral hace crecer lo que tenés guardado un porcentaje por minuto, hasta un techo que fija la cantidad de corrales. Gastar achica la base que crece | Crecimiento | **Baja**: corrales; la decisión es cuándo gastar | Techo de crecimiento por corral; lo que lo excede no crece, pero no se pierde | ¿Gastar ya en guerreros o dejar crecer? Un rebaño grande es un blanco: si destruyen un corral, baja el techo. Variante agresiva: el botín del malón entra al rebaño (piso pacífico y techo blando). *Nombre: kulliñ; el ganado como banco vivo (`investigacion/mapuches.md`, M2)* |
| **Guaraníes** | Cada chacra da comida hasta agotarse y deja un yerbal: una fuente de riqueza donde estaba la chacra. Los aldeanos de la chacra pasan solos al yerbal. Cada base empieza con un yerbal viejo al lado | Subproducto con retardo (la sucesión del monte) | **Media**: replantar, como las granjas de todos | Los yerbales se agotan; la cantidad de chacras la limita la tierra libre | Dónde quemar: cerca de casa (seguro, pero ocupa espacio) o al borde del monte (expuesto, pero sirve para emboscar). Comida ahora contra riqueza después. *Nombre: roza y capuera, ka'a (Noelli et al.)* |
| **Etiopía** | Se "asigna tierra": un edificio barato y frágil sobre campo abierto que paga comida y riqueza sin trabajadores. Rinde menos si hay otro cerca y más cerca de la corte, que se puede mudar | Renta con posición | **Baja**: se ubica una vez | Cantidad por edad y castigo por amontonar | Dónde repartir la tierra: lejos rinde, pero es atacable; cerca de la corte paga más. Al mudar la corte, cambia qué tierras pagan bien. Variante: revocar una tierra devuelve parte del costo y abarata a los jinetes. *Nombre: gult (Berhane-Selassie)* |
| **Palmares** | Las chacras dan comida como todas, pero si están cerca de una casa de harina, una parte de lo que se entrega se vuelve riqueza **además** de la comida. Producir delata: cada casa de harina hace más visible al poblado escondido más cercano | Subproducto con exposición | **Baja**: construir la casa junto a las chacras | Tasa máxima por casa y un radio de chacras que cuentan | ¿Producir junto a la capital (ya visible) o junto a los poblados ocultos, a costa del secreto? Variante: incursiones a ingenios neutrales, con botín una sola vez. *Nombre: casa de farinha; la economía agrícola de Palmares (`investigacion/palmares.md`)* |
| **Ayutthaya** | Hay un solo almacén real por edad. Una parte de la madera que se entrega ahí se vuelve riqueza además de madera (los productos del monte eran monopolio de la corona). Junto al agua, rinde más | Subproducto con una sola posición | **Baja**: elegir el lugar; la tala sigue igual | Un almacén por edad y una tasa máxima por almacén | ¿Junto al mejor bosque (lejos y expuesto) o junto al agua y la casa? *Nombre: Phra Khlang, almacén real [verificar los productos del monte]* |

Ninguno es comercio ni pide atención alta. Se diferencian por lo que los alimenta (trabajo, stock, comida con retardo, tierra, comida, madera) y por lo que arriesgan (red, rebaño, espacio, tierra lejana, secreto, bosque).

## 3. Implementación en el motor actual

**Lo que ya existe** (`src/sim/sim_mods.gd`, `src/sim/sim.gd`):
- `renta` (`_rents`): la base del gult.
- `recurso_propio` (`por_aldeano`, `tope_por_edificio`): los turnos incas ya salen de los aldeanos.
- `saqueo`: el malón pasa a dar `riqueza` en vez de `kullin`.
- `cantidad` y `deja` (`_exhaust`): la chacra guaraní, tal cual.
- `bono_agua_pct` y `permite_ladera`: el almacén siamés junto al agua y los andenes.
- `oculto` y `acoge`: los poblados de Palmares.
- `deposito`: el almacén real y la casa de harina.

**Piezas nuevas** (siete, todas como parámetros de módulo; ningún caso escrito a mano):

1. **`conversion`** en un edificio: `{de: {mita: n}, a: {riqueza: m}}` por minuto, que solo corre si hay stock. Es una renta con consumo y sirve para el taller inca.
2. **`interes_pct` y `tope_crecimiento_por_edificio`** en `recurso_propio`, permitiendo `clave: "riqueza"` (la fusión del kulliñ). Ojo: hoy el `tope` **recorta** el stock. Para la riqueza tiene que limitar solo lo que crece, no lo guardado.
3. **`subproducto`** al entregar: `{recurso: "madera", da: "riqueza", pct: n, tope_min: m}`, con `radio_fuentes` opcional (chacras cerca de la casa de harina). Se engancha en `_do_return`. Sirve para Palmares y Ayutthaya.
4. **`max_por_edad`** por tipo de edificio (almacén real, gult, talleres).
5. **Modificadores de renta por posición**: `separacion` (rinde menos si hay otro igual en el radio) y `bono_cerca_de: {tipo, radio, pct}` (el gult cerca de la corte).
6. **`exposicion`**: la casa de harina suma exposición al poblado oculto más cercano. Si pasa el umbral, el poblado deja de estar oculto. Es el módulo ya previsto en la investigación de Palmares.
7. **Pase automático a la fuente que deja**: el aldeano que agotó la chacra sigue en el yerbal que quedó en su lugar. Es un ajuste chico en `_exhaust`.

Para la IA, todo es "construí X cerca de Y" o "gastá cuando tengas Z". No hay micro.

## 4. El mapa: qué hay en casa y qué se disputa

**Junto a cada base** (el motor propio alcanza solo para avanzar de edad):
- **Kit común simétrico**: frutos, bosque cercano, piedra y una **salina chica** que se agota, en lugar de la mina dorada. Es la vía común y segura.
- **Paisaje por civ**, que siempre es una **bonificación y nunca un requisito**. Todos los motores funcionan en llano:
  - Tawantinsuyu, una ladera para terrazas;
  - mapuches, pradera (más techo por corral);
  - guaraníes, monte y un **yerbal viejo** que da riqueza desde el minuto 0;
  - Etiopía, pradera abierta para repartir tierras;
  - Palmares, monte o sierra para esconder poblados;
  - Ayutthaya, agua junto a un bosque, para el almacén.

**Disputado** (un plus, con techo por edad según la síntesis: 10 % de la riqueza en la edad I, 25 % en la II, 35–40 % en la III y 45–50 % en la IV):
- **Salina grande a media distancia**, una por jugador y simétrica: es el primer roce.
- **Salinas o ferias en el centro**, junto a los sitios sagrados. Rinden menos en el segundo y el tercer punto del mismo dueño y se agotan.
- **Ingenios neutrales con guardia**: botín una sola vez para las correrías y los malones, y se rehacen con más guardia.

Prueba que valida todo: la IA que **nunca sale de casa** llega a la edad III antes del minuto 20 con cada una de las seis civs, y en el torneo la riqueza acumulada a los 5, 10 y 20 minutos queda dentro de una banda común para los seis motores.
