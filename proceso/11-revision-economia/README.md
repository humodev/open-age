# 11 · Revisión de la economía (desde 2026-11-13)

## Pedido del autor
> "En las pruebas del mapa todo empieza como Age of Empires 4: tenés unos frutos, el oro cerca, etc. Y eso hace que se confunda. Si tenés una mina de oro ahí, y la riqueza es otra cosa, y el oro no te da nada, ¿para qué está? Y las fuentes de riqueza que estás marcando son muy determinantes de un estilo de juego. ¿Los mapuches tienen que dañar edificios enemigos para conseguir riquezas? ¿Cómo van a hacer al comienzo? ¿Empezar a atacar de primera? ¿Será por eso que siempre les va re mal? Creo que esto necesita un pensamiento más profundo (…) equipos de agentes con diferentes perfiles que tendrían dentro de un equipo de diseñadores de juegos RTS."

## Punto de partida
- **Recursos comunes**: alimento, madera, piedra y riqueza. El depósito dorado del mapa da riqueza a todos, pero se ve y se ubica como el oro de AoE4.
- **Fuentes propias de riqueza**:
  - Renta del cumbi, de los yerbales, del gult y de los barrios.
  - Saqueo con el malón y las correrías.
- **Quinto recurso**: lo tienen tres civilizaciones (mit'a, kulliñ y fama).
- **HUD**: el ícono y el nombre "riqueza" son los mismos para las seis.

## Equipo
Cinco agentes con perfiles distintos. Leen el repositorio sin tocarlo y escriben en [`docs/diseno/revision-economia/`](../../docs/diseno/revision-economia/):

| # | Perfil | Pregunta |
|---|---|---|
| 01 | Diseñador de sistemas económicos (AoE, AoM, Northgard, Against the Storm) | ¿Qué modelo de recursos? |
| 02 | Diseñador de facciones asimétricas (StarCraft, AoE4, CoH) | ¿Cada civilización tiene caminos viables desde el minuto 0? |
| 03 | UX y mapas: legibilidad y jugador nuevo | ¿El mapa y el HUD cuentan la historia de la civilización? |
| 04 | Asesor histórico | ¿Qué era la riqueza para cada pueblo y de dónde salía en paz? |
| 05 | Balance competitivo y aperturas | ¿Cómo son los primeros 8 minutos y por qué rinden mal mapuches y Etiopía? |

## Paso a paso
1. Se lanzó el equipo (en curso).
2. Llegaron cuatro de los cinco informes: UX y mapas, facciones, historia y sistemas económicos. Coinciden en el diagnóstico: en la edad I las seis civs sacan la riqueza del mismo yacimiento junto a la base. El malón mapuche da kulliñ, no riqueza, y el gult etíope rinde menos que un aldeano en la mina.
3. **Observación del autor (2026-11-13)**, sobre la idea de sacar la riqueza común de la base y llevarla lejos (salinas, ferias en el centro):
   > "Que el cuarto recurso esté tan lejos y en otro lado significa que no debería ser TAN determinante, ¿no? Si no, una vez que perdés esa región te quedás sin ese recurso y ya perdiste. El juego se vuelve controlar ese recurso y nada más, y deja al rival sin opciones. Ojo con eso."

   Se les pasó a los perfiles de sistemas económicos, facciones y balance. Cada uno agrega a su documento una sección "Dependencia territorial": qué parte de la riqueza puede ser disputable en cada edad, cómo se remonta al perder el centro y cómo medirlo en el torneo.
4. Llegó el quinto informe, el de balance, con partidas medidas: a los mapuches no les falta riqueza en la apertura. Pierden en el medio juego por la IA (elige el rewe militar y queda trabada ahorrando) y por la poca vida de sus edificios de victoria. Etiopía, en cambio, tiene un problema de diseño: el gult cuesta alimento justo cuando falta y paga riqueza, que le sobra.
5. **Síntesis** en [`docs/diseno/revision-economia/00-sintesis.md`](../../docs/diseno/revision-economia/00-sintesis.md): el diagnóstico compartido, el modelo "una riqueza, seis motores", los límites de la dependencia territorial, las discrepancias entre perfiles y el orden de trabajo. Decisiones para el autor: C-10 a C-13 en `CONSULTAS.md`. No se aplicó ningún cambio al juego.
6. **Observación del autor (2026-11-13)**, después de leer la síntesis explicada sin nombres:
   > "Siento que hay algunas mecánicas de algunas civs que requieren acción para obtener riqueza, además de poner algo a hacer, como poner a picar, y cuando se acabe la mina ir a picar a otro lado. Es algo diferente tener que estar pendiente de algo, rápidamente. Que una sea tradear ya es un problema, porque tradear van a poder todos: se siente que ellos no tuvieran mecánica."

   Quedan dos criterios nuevos:
   - el **costo de atención** de cada mecánica tiene que ser parejo entre civs;
   - una mecánica que pueden hacer todas, como el comercio, **no cuenta como identidad**.
7. **Fase de investigación** antes de volver al equipo. Tres agentes escriben en [`docs/diseno/investigacion-aoe4/`](../../docs/diseno/investigacion-aoe4/):
   - **01:** el catálogo de mecánicas económicas de todas las civs de AoE4, con su costo de atención y su historia de parches.
   - **02:** la voz de los jugadores: foros, Reddit, notas de parche, prensa y creadores.
   - **03:** otros RTS. AoE2, AoE3 (con los africanos), el favor de Age of Mythology, el macro de StarCraft II, Northgard y Company of Heroes.

   Después, los cinco perfiles revisan sus propuestas con ese material.
8. Llegó la investigación, en [`docs/diseno/investigacion-aoe4/`](../../docs/diseno/investigacion-aoe4/):
   - **01, catálogo de las 25 civs y variantes de AoE4** (hasta *Raiders of the North*, octubre de 2026): mecánicas con números de los archivos del juego, historia de parches y tasas de victoria del parche 17.0 (aoe4world). Patrones:
     - lo pasivo acumulable siempre terminó recortado;
     - la atención alta solo se tolera si rinde;
     - "lo pongo y funciona" no da identidad (otomanos, 42 %);
     - dan identidad las mecánicas que obligan a decidir dónde y qué (malíes, vikingos);
     - un buen recurso propio es el subproducto de algo que el jugador ya hace.
   - **02, la voz de los jugadores**, de los foros oficiales, las notas de parche y la prensa. Reddit no se pudo leer. Lecciones:
     - nada de órdenes manuales repetidas;
     - los puntos se controlan con desgaste y sin reinicio;
     - el comercio se diferencia por la relación de cada civ con la ruta.
   - **03, otros RTS.** Age of Mythology ya demostró en 2002 "una riqueza, seis motores" con el favor. Además:
     - el favor nórdico, que sale de pelear, necesitó un piso pacífico en Retold;
     - estar pendiente de algo suma si cada uso es una decisión, y es tedio si es un ritual;
     - la civ comerciante necesita un verbo, un producto o un socio propio;
     - los frenos contra la bola de nieve limitan al que gana, no le pagan al que pierde.
   - **Límites:** se agotó el cupo de búsquedas web y algunos datos quedaron marcados [no verificado de primera mano].
