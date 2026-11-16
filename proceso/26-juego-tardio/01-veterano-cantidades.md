# Cuánto contenido por civ, recompensas de edad y final de partida (veterano de AoE4)

Respuesta al pedido del autor (2026-11-16): "qué sería una buena cantidad de mejoras y opciones por civ, y diseñemos un final de partida y unas recompensas y progreso al subir de edad al nivel de AoE4".

**Cómo leer las cifras de AoE4.** Son de mi experiencia de juego, no de una tabla; las aproximadas o dudosas llevan [verificar]. Lo nuestro sale de `data/` (`unidades.json`, `tecnologias.json`, `edades.json`, `civs/*.json`).

## 0. Dónde estamos

| | Raíces hoy | AoE4, por civ [verificar] |
|---|---|---|
| Unidades militares base | 7: guerrero, hondero y explorador (I); lancero, jinete y ariete (II); arcabucero (III); ninguna en la IV | 15–20 a lo largo de las cuatro edades, con las de asedio |
| Unidades propias | 0 a 3: incas, boleador y awqa; Ayutthaya, elefantes y compañía japonesa; Etiopía, jinete noble; el resto solo cambia nombres y números | 2–4, más reemplazos de las comunes |
| Niveles por unidad | ninguno; en su lugar, un bono automático de ataque por edad (+10, +20, +35 %) | 3–4 niveles por línea (común, endurecido o veterano, élite), comprados en su edificio |
| Mejoras compartidas | 18: 7 de economía, 1 del motor propio (oficio), 2 de edificios y 8 militares (armas ×3, escudos ×3, marcha y adiestramiento) | 40–55: herrería con 12 (ataque y armadura, cuerpo a cuerpo y distancia, ×3), almacenes con 12–15, universidad con 6–8 y centro y defensa con 5–8 |
| Mejoras propias | 0 | 8–15 por civ |
| Hitos | 6 (2 por edad), con un efecto cada uno | 6 landmarks más 1 maravilla |
| Edad IV | en ≈ 15 % de las partidas; no trae nada nuevo salvo `armas_3` y `escudos_3` | edad imperial: pólvora, asedio pesado, élites, universidad y maravilla. En partidas de nivel medio y alto se llega bastante seguido [verificar el porcentaje] |

**El diagnóstico en una línea.** Subir de edad hoy da sobre todo un porcentaje de ataque automático, no opciones nuevas. Y la edad IV no tiene nada que buscar, por eso las partidas se deciden antes.

## 1. Cantidad buena por civ

Mi meta para Raíces no es copiar el volumen de AoE4, que es enorme y casi todo compartido, sino lo justo para que cada edad cambie la partida y cada civ tenga decisiones propias. Un desarrollador solo puede sostenerlo.

### 1.1 Unidades

| Edad | Compartidas: hoy | Compartidas: propuesta | Función |
|---|---|---|---|
| I | guerrero, hondero, explorador | guerrero, hondero, **lancero**, explorador | Como AoE4, el lancero en la I: la caballería temprana tiene respuesta |
| II | lancero, jinete, ariete | jinete, ariete, **hostigador montado** (jabalinas, rápido y frágil) | Es la unidad que kitea al choque, pedida desde la ronda 2 |
| III | arcabucero | arcabucero, **catapulta** (daño en área, rompe bloques de tropa), **sanador o religioso** (cura; en los sitios, donde corresponda a cada pueblo) | El asedio de área es la respuesta a las bolas grandes |
| IV | — | **cañón** (asedio pesado contra edificios y fortalezas), **tropa pesada de élite** (por civ: ver las propias) | El final necesita algo que rompa fortalezas y algo que valga la pena juntar |
| **Total** | 7 | **12** | AoE4: 15–20 [verificar] |

**Propias por civ: 3 por pueblo,** repartidas en las edades II, III y IV (no todas en la misma), y a lo sumo 1 de reemplazo. Hoy guaraníes, mapuches y Palmares tienen 0 unidades nuevas: son las que más necesitan.

| Pueblo | Tiene | Le faltarían (ideas para el diseño con los historiadores) |
|---|---|---|
| Tawantinsuyu | boleador, awqa | una de la IV |
| Mapuches | (kona como variante) | una de la II y una de la IV |
| Guaraníes | — | tres |
| Etiopía | jinete noble (variante) | una de la III y una de la IV |
| Palmares | — | tres |
| Ayutthaya | elefantes, compañía japonesa | completa con lo que tiene |

### 1.2 Niveles por unidad (veterano y élite)

| | Propuesta | AoE4 [verificar] |
|---|---|---|
| Niveles | 3: común (al aparecer), **veterano** (edad III) y **élite** (edad IV) | 3–4: early, hardened o veteran, elite |
| Por línea | choque, distancia, línea, montados y pólvora: 5 líneas × 2 mejoras = **10 mejoras** | una por unidad y nivel |
| Efecto por nivel | +15–20 % de vida y +1–2 de ataque y armadura, como datos por línea | parecido |
| Dónde | en el edificio que la produce | igual |
| Costo | veterano ≈ 300 de recursos; élite ≈ 600, con riqueza | del orden de 150 a 1000 [verificar] |

- **Lo más importante:** sacar el **bono automático de ataque por edad** (`edades.json`, `bono_ataque`, +10/20/35 %) y reemplazarlo por estos niveles. AoE4 no lo tiene.
- Hoy subir de edad mejora a todo el ejército gratis. Con niveles, mejorar es una decisión de composición: ¿subo a élite los honderos o los lanceros?

### 1.3 Mejoras compartidas

| Grupo | Hoy | Propuesta | Notas |
|---|---|---|---|
| Ataque y armadura (herrería) | armas ×3 y escudos ×3, para todos | **12**: ataque cuerpo a cuerpo ×3, ataque a distancia ×3, armadura cuerpo a cuerpo ×3 y armadura a distancia ×3 (edades II, III y IV) | Como ya existen dos armaduras (C-31), separar ataque y armadura por clase es natural |
| Economía | 7: tala ×2, riqueza, piedra, cestas y riego ×2 | **12**: alimento ×3 (caza y granja), madera ×3, riqueza ×2, piedra ×1, carga ×1, velocidad del aldeano ×1 y vida del aldeano ×1 (como textiles) | La tercera de cada recurso en la IV: la economía del final |
| Edificios y defensa | 2: mampostería y vigías | **6**: mampostería ×2, aspilleras, torre con arma pesada (III), fortaleza más resistente (IV) y reparación más rápida | |
| "Universidad" (edad IV) | — | **6**: +20 % de daño de la pólvora, +20 % de vida de la infantería, +15 % de daño del asedio, alcance del asedio, reconstrucción del asedio en campo y +1 de alcance a la distancia | La edad IV necesita su lista. En AoE4 la universidad es uno de los motivos para llegar [verificar la edad de la universidad] |
| Marcha y adiestramiento | 2 | 2 | Quedan |
| **Total compartido** | 18 | **≈ 48**, más 10 niveles | AoE4: 40–55, más niveles [verificar] |

### 1.4 Propias por civ

| | Propuesta | AoE4 [verificar] |
|---|---|---|
| Mejoras propias | **8 por civ:** 2 en la II, 3 en la III y 3 en la IV. Por lo menos 1 de economía, 1 militar y 1 que potencie su mecánica (mit'a, malón, roza, corte, fama, tributo) | 8–15 |
| Hitos | 6, como hoy, más **1 maravilla** en la edad IV (ya prevista en la etapa 23) | 6 + 1 |
| Unidades propias | 3 | 2–4 |

**Reparto compartido y propio:** de ≈ 66 mejoras por civ (48 compartidas, 10 niveles y 8 propias), ≈ 88 % es compartido y ≈ 12 % propio. En unidades, 12 compartidas y 3 propias: 80 % y 20 %. AoE4 está en un orden parecido [verificar]. La identidad la dan las mecánicas (que nosotros ya tenemos más fuertes que AoE4), los hitos y las propias.

## 2. Recompensas al subir de edad

**En AoE4 [verificar los detalles]:**
- **Edad II (feudal):** hombre de armas, arquería y establo, herrería, mejoras de nivel II y torres de piedra. Abre el juego militar de verdad.
- **Edad III (castillos):** caballero y ballestero, asedio (mangonel, springald), monjes y reliquias, torreón, nivel veterano de las unidades y segunda tanda de herrería. Es el "salto de poder" más grande.
- **Edad IV (imperial):** pólvora (cañoneros, bombardas, culverinas), trebuchet, universidad, élites, tercera tanda de herrería, maravilla y la mejor economía.
- **El landmark** de cada edad da un efecto fuerte y distinto según cuál se elija.
- **No hay bono de ataque automático:** el poder llega por lo que se puede comprar después de subir.

**Qué propongo que dé cada edad acá:**

| Edad | Desbloquea | Poder que da | Por qué vale la pena subir | Cuándo conviene no subir |
|---|---|---|---|---|
| **II** | corral y taller; hostigador montado, jinete y ariete; herrería I; mejoras de economía II; segundo centro; mercado | 1.ª tanda de ataque y armadura; la segunda propia de la civ | Sin la II no hay respuesta a la caballería ni al asedio; el segundo centro duplica los aldeanos | Si el rival viene con todo en la I y el hito (500 + 300) te deja sin tropa |
| **III** | catapulta, arcabucero, sanador; **nivel veterano**; herrería II; fortaleza o torre pesada; 3 propias; mejoras de economía III | El salto de poder más grande: veteranos (+15–20 % de vida y +1–2 de ataque) y asedio de área | Sin la III tus bolas de tropa pierden contra el área y tu ejército es de nivel común | Si tenés ventaja militar en la II: pegar y no ahorrar 1000 + 600 + 200 (como el "feudal all-in" de AoE4) |
| **IV** | cañón, tropa pesada de élite, **nivel élite**, herrería III, "universidad" (6), 3 propias, maravilla, tercera mejora de cada recurso | El tope de cada línea y lo único que rompe fortalezas rápido | Una partida pareja a los 25–30 minutos se gana acá: la economía crece +15–25 % y el ejército sube a élite | Si podés cerrar en la III; la IV cuesta 1800 + 1200 + 400 y 250 s de obra |

**El cambio de fondo:** que el poder no venga del porcentaje automático sino de **lo que se puede comprar después de subir**. Así cada subida es una decisión (subo y me quedo sin tropa, o peleo ahora) y la ventaja se construye.

## 3. El final de partida (edad IV)

**Qué lo hace interesante en AoE4 [verificar los detalles]:**
- **Asedio que rompe** (trebuchets y bombardas) contra **defensa que aguanta** (torreones y muros de piedra): el final es atacar posiciones, no solo ejércitos.
- **Unidades tope** caras y fuertes, y la **pólvora**, que cambia la composición.
- **Mejoras imperiales** (universidad, élites): hay en qué gastar lo que sobra.
- **Economía del final:**
  - el oro y la piedra de las vetas se agotan;
  - la riqueza pasa al comercio entre mercados, las reliquias, los sitios y la pesca;
  - las granjas son infinitas.

  El mapa se vuelve una pelea por el comercio y los sitios.
- **Cómo terminan las partidas:**
  - destruir los landmarks;
  - sitios sagrados (10 min);
  - maravilla (aguantarla en pie un rato largo; 15 min [verificar]);
  - o el rival se rinde.

  La población tope (200) hace que las peleas finales sean grandes y se repongan.

**Qué nos falta, en orden:**
1. **Asedio que rompa y defensa que aguante:** hoy hay solo ariete y torre. Faltan la catapulta (III), el cañón (IV) y una fortaleza o torre pesada (III).
2. **Algo que comprar en la IV:** niveles élite, la "universidad" y la tercera mejora de cada recurso.
3. **Economía del final:**
   - que la riqueza de la arcilla y las vetas se agote y obligue al comercio entre mercados (comerciantes que caminan; hoy el mercado solo cambia);
   - sitios que rindan más en la IV;
   - una mejora que haga las granjas el sostén.
4. **La maravilla,** una por pueblo, con su cuenta regresiva y victoria.
5. **Rendición de la IA** cuando pierde (ya la tiene la fácil; extenderla a todas) para que el final no sea cazar edificios.
6. **Un final más largo:** que la edad III llegue a los 15–20 min (como hoy) y la IV a los 22–28, en lugar de que la partida se resuelva en la III.

## 4. Riesgos para el balance y orden de entrada

**Riesgos:**
- **Sacar el bono de ataque por edad** cambia todos los combates y la IA tiene que comprar los niveles a tiempo. Si no, se debilita. Es el riesgo más grande.
- **Inflación de poder:** demasiados % que se acumulan (herrería, niveles, universidad, propias) pueden volver imposibles las peleas entre edades distintas. Regla: **ninguna línea más de ×2 de su poder base en la IV, sumando todo.**
- **La IA tiene que aprender a investigar:** orden de compra por edad y por composición. Si no, el humano que investiga le gana siempre, y el torneo de IA contra IA no ve el problema.
- **Asedio de área:** puede romper la micro C2 (las bolas de la mezcla). Se mide con `tools/micro_matriz.gd` con catapultas.
- **Ruido del torneo:** cada tanda de contenido mueve todo. Con 10 semillas (±7 puntos) va un cambio por torneo, como en la etapa 24.
- **Contenido sin arte:** unidades nuevas sin modelo propio se confunden en la batalla, que ya es una mancha. Cada unidad nueva necesita silueta y función con Alt.

**Orden propuesto** (cada paso con su torneo; si uno rompe, se pausa y queda como contenido):

| Paso | Qué | Por qué en este orden | Prueba |
|---|---|---|---|
| 1 | **Niveles veterano y élite** para las líneas que ya existen, y **sacar el bono por edad**, en el mismo cambio, para que el poder total por edad quede igual | Cambia el "cómo" sin cambiar el "cuánto"; la IA aprende a investigar | Micro C2, torneo; el poder de la III con veteranos ≈ el de hoy con +20 % |
| 2 | **Herrería separada** (12) en lugar de armas y escudos (6) | Compartido, sin arte nuevo | Torneo |
| 3 | **Economía III** (la tercera de cada recurso) y **"universidad"** (6) | Le da contenido a la IV sin unidades nuevas | Edades en paz: que la IV llegue a los 22–28 min |
| 4 | **Asedio:** catapulta (III), cañón (IV) y fortaleza o torre pesada | Lo que hace interesante el final; necesita arte y una IA que lo use | Micro con asedio; partidas de 45 min |
| 5 | **Lancero a la edad I y hostigador montado en la II** | Toca la apertura de todos: después de que el resto se asiente | Torneo y la prueba de la primera victoria del jugador nuevo |
| 6 | **Propias por civ:** 8 mejoras y 1–3 unidades, de a dos pueblos por vez, empezando por guaraníes, mapuches y Palmares (las que no tienen nada) | Cada pueblo se balancea aparte | Torneo por par |
| 7 | **Maravilla** y **economía del final** (comercio que camina, agotamiento de la riqueza) | Lo más grande: cambia cómo se gana | Partidas de 45–60 min y opciones de partida |

**Meta medible del conjunto:** en partidas de 45 minutos entre IAs normales, la edad IV en el **40–60 %** de las partidas (hoy ≈ 15 %) y la duración media en **25–35 minutos**. Si un paso baja la IV o vuelve a la civ dominante (más del 66 % en el torneo), se pausa.
