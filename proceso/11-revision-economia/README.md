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
9. **Ronda 2 del equipo.** Los cinco perfiles retoman su trabajo con la investigación y con la consigna común [`v2/00-consigna.md`](../../docs/diseno/revision-economia/v2/00-consigna.md). Criterios obligatorios:
   - atención pareja, baja o media, sin rituales;
   - lo que pueden hacer todos no es identidad;
   - lo pasivo, con tope y con decisión de dónde;
   - lo agresivo, con piso pacífico;
   - el subproducto de algo que ya se hace;
   - límites a la dependencia territorial;
   - cada mecánica explicada primero en palabras llanas.

   Se reemplazan las mecánicas de Ayutthaya y Palmares, que se apoyaban en el comercio, y el asesor histórico responde la pregunta del oro.
10. **Observación del autor (2026-11-13)** sobre la ronda 2:
    > "Lo de que tiene que estar oculto, y que si lo ven ya pierde valor, me parece raro: en el endgame casi todo está descubierto, hay outposts, muchas tropas por todo el mapa, traders; no va a haber lugar dónde poner las cosas. La salina chica va a estar siempre, pero ¿qué puede hacer cada civ desde eso? En Age el oro es una riqueza que siempre está ahí para minear, pero algunas civs tienen engines mejores que solo minear. ¿Acá tenemos esa posibilidad? ¿Cómo conviven estas diferentes mecánicas? Hay cosas que creo que el equipo las piensa una vez y no vuelve a analizar con más contexto y desde diferentes perspectivas. Antes de implementar debemos afinar al máximo: teorizarlas, planificar cómo va a resultar desde el comienzo hasta el final del juego, si está balanceado, si conlleva el mismo esfuerzo para todos."

    Conclusiones:
    - Se descarta todo motor que dependa de estar oculto.
    - Cada civ tiene que explicar su relación con la fuente común: cómo la aprovecha mejor o distinto, como las minas de pozo malíes, el ovoo mongol o el aceite bizantino.
    - Se cambia el método de trabajo.
11. **Método nuevo (ronda 3 en adelante):**
    1. **Un diseñador líder consolida** un solo diseño, un motor por civ, con:
       - la relación con la salina y las fuentes comunes;
       - la línea de tiempo de la partida: minutos 0–5, 5–15, 15–30 y final con el mapa revelado;
       - el costo de atención por fase.
    2. **Críticas cruzadas desde varias perspectivas:**
       - romperlo (endgame, abusos, mapa revelado);
       - jugador competitivo;
       - jugador nuevo;
       - programador de la IA;
       - historiador.
    3. **Modelo numérico antes de tocar el juego:** un script que simula, minuto a minuto, los ingresos de cada civ y las órdenes que pide al jugador.
    4. **El líder revisa y vuelve a las críticas** hasta pasar una lista de control escrita:
       - esfuerzo parejo;
       - nada dominante ni inútil;
       - nada que se rompa en el final;
       - nada que dependa de un solo lugar;
       - entendible en palabras llanas;
       - jugable por la IA;
       - fiel a la historia.

    Recién entonces se presenta al autor y, si lo aprueba, se implementa.
12. **Cerró la ronda 2** con el informe de balance ([v2/05](../../docs/diseno/revision-economia/v2/05-balance-y-aperturas.md)):
    - **Métricas de atención medibles:** pendientes de la mecánica propia, órdenes propias por minuto y decisiones por edad.
    - **Reglas para lo pasivo:** repago de 5 a 8 minutos y como máximo 0,8 aldeanos por renta.
    - **Peso del motor propio:** entre 30 y 60 % de la riqueza al minuto 15.
    - **Medido hoy:** Tawantinsuyu pide 2,2 órdenes por minuto por los caminos, y la mit'a pasa el 43 % del tiempo en el tope.
13. **Preguntas del autor para la ronda 3:**
    > "¿Por qué la sal? ¿Estaba disponible en todos estos lugares?"
    > "Deberían poder jugar en un mapa sin agua e igual tener una estrategia viable; si no, el juego se desarma."

    **Arranca la ronda 3** con la consigna [`v3/00-consigna.md`](../../docs/diseno/revision-economia/v3/00-consigna.md): las diez observaciones del autor, las preguntas A a F y una lista de control de 10 puntos. Primero, un diseñador líder consolida un diseño único con números iniciales.
