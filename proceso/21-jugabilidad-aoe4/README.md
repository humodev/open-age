# 21 · Jugabilidad al estilo AoE4: estudio e implementación (desde 2026-11-14 22:00)

## Pedido del autor
> "Por ahora me está costando, pero puede ser un tema de skill. Necesitamos varias cosas para acercarnos a un gameplay como el de Age of Empires 4. Ahora parece más al 1 por algunas cosas puntuales."
>
> "Necesitamos mejorar mucho y crear features que hacen de la jugabilidad una experiencia agradable, como pueden ser la agrupación de diferentes tropas. Que las unidades que son enviadas a algo en grupo, si son aldeanos y se los manda a caminar, lo hagan ordenados en bloque y se esperen para llegar juntos; si se los manda a un trabajo puntual cerca, está bien que vayan todos corriendo para llegar antes; si se los manda muy lejos, que se agrupen. Los oficiales militares siempre agrupados, formaciones militares, etc."
>
> "Por ejemplo, mandar a construir un almacén de arcilla al lado de la arcilla y que los aldeanos rápidamente comiencen a recolectar eso cuando terminan de hacerlo; que haya diferentes almacenes para diferentes cosas, ajustar precios obvio. Si alguna civ no tiene todos y tiene unificado está bien, pero si no nos quedamos cortos. Lo mismo para los militares: si arqueros, caballos, infantería, asedio, todo sale del mismo lugar, no tiene mucho sentido, la madera pasa a ser un poco innecesaria de colectar, etc."
>
> "Creo que necesitamos hacer ahora un estudio más serio de Age of Empires en todos estos sentidos, revisar en qué nos quedamos cortos, qué podemos adoptar y llevarlo adelante."

## Punto de partida (verificado en `data/edificios.json`)
- **Un solo almacén para todo:** `deposito` recibe alimento, madera, piedra y riqueza, igual que el centro.
- **Un solo cuartel para todo el ejército:** `cuartel` produce guerrero, hondero, lancero y ariete.
- **Movimiento:** los grupos se mueven cada unidad por su cuenta, sin formación ni velocidad común.

## Plan
1. **Estudio, con un equipo de agentes de perfiles distintos:**
   - (a) investigación de AoE4 (y AoE2 donde sirva) sobre movimiento de grupos y formaciones, almacenes, edificios de producción, y comodidades de economía y de órdenes;
   - (b) auditoría de nuestro juego contra esa lista;
   - (c) crítica de diseño: qué conviene adoptar, adaptado a nuestros pueblos y no como copia.
2. Plan priorizado en `docs/diseno/jugabilidad/`, con lo que cambia en datos y en la simulación.
3. Implementación por pasos, cada uno con su prueba, determinismo, banco y captura.

## Paso a paso
1. **(22:10) Estudio, primera vuelta: dos agentes en paralelo.**
   - **Referencia de AoE4** ([01-referencia-aoe4.md](../../docs/diseno/jugabilidad/01-referencia-aoe4.md), 70 fuentes: archivos del juego publicados por aoe4world, wiki, notas de parche, respuestas de desarrolladores en el foro):
     - **formación militar:** se arma sola, en un rectángulo de doble ancho que fondo, con choque adelante, distancia atrás y asedio al final, y todo el grupo a la velocidad del más lento; los rezagados corren +40 %;
     - **los aldeanos no forman en AoE4,** a propósito según un desarrollador: que esperen al grupo en viajes largos, como pide el autor, sería algo propio de Raíces;
     - **almacenes:** molino, maderero y minero a 50 de madera; quien construye uno empieza solo a recolectar lo más cercano;
     - **producción:** cuartel en la edad I; arquería y establo en la II (150 de madera cada uno); taller de asedio en la III (250). Ninguna civ unifica estos edificios;
     - **comodidades** que llegaron después del lanzamiento: patrullar, cola global de producción, seleccionar todos los edificios de un tipo, volver al trabajo;
     - **puntos débiles del estudio:** el ritmo de partida es la sección con menos datos.
   - **Auditoría de nuestro juego** ([02-auditoria.md](../../docs/diseno/jugabilidad/02-auditoria.md)), con mediciones propias:
     - **sin noción de grupo:** 24 unidades mandadas a 40 casillas llegan con 21 s de diferencia y se estiran hasta 14 casillas; los jinetes llegan 20 s antes que los lanceros, y las unidades se cruzan porque los lugares se reparten por número;
     - **al terminar un almacén,** el aldeano vuelve a lo que juntaba antes, no a lo que tiene al lado;
     - **la simulación ya admite almacenes de un solo recurso** (la qollqa inca funciona así): separarlos es sobre todo datos, interfaz e IA;
     - **un cuartel de 150 de madera** produce todo en cinco de seis civs;
     - **la madera** pesa 26–33 % de lo recolectado y no sobra, pero no decide nada porque un edificio alcanza para todo el ejército;
     - **fallas encontradas de paso:**
       - lo encolado con Mayús detrás de recolectar nunca sale;
       - Ayutthaya no puede investigar `hachas`, `canteria` ni `orfebreria` (no tiene depósito);
       - los mapuches no pueden investigar `cestas`, `riego` ni `mamposteria` (no tienen centro);
       - las proporciones de aldeanos de la IA están escritas en el código.
   - **Sigue:** un tercer agente, crítico de diseño, propone qué adoptar y cómo adaptarlo a cada pueblo, con historia y números (`03-propuesta.md`). Después, el plan por pasos.
2. **(22:40) Estudio, segunda vuelta: propuesta de diseño criticada** ([03-propuesta.md](../../docs/diseno/jugabilidad/03-propuesta.md)), hecha por un tercer agente con los dos estudios.
   - **Grupos con ancla:** un punto virtual sigue un solo camino (un A* por grupo, no uno por unidad) a la velocidad del más lento, y cada unidad sigue su lugar en la formación.
     - Todo en enteros, con una tabla de 16 rumbos en lugar de trigonometría.
     - Los rezagados corren +40 % (+25 % los aldeanos), pero no si pelearon hace menos de 3 s.
     - El grupo espera hasta 8 s a quien quedó a más de 5 casillas.
   - **Orden de la formación:** sigue nuestro triángulo de contadores, no el de AoE4: adelante la línea, después el choque, la distancia, el asedio y el apoyo, con los montados en las alas. Cuatro formaciones (bloque, línea, abierta, columna), más "suelto" con Alt para retirarse.
   - **Aldeanos:** hasta 16 casillas cada uno va por su cuenta; más lejos, en bloque, y se sueltan a 6 casillas del trabajo.
   - **Almacenes:** granero, leñera y barrero comunes, con nombre propio en cada pueblo. Las excepciones tienen fundamento:
     - los mapuches llevan todo al lof;
     - Ayutthaya cobra con el elefante y suma solo un almacén de arcilla;
     - Palmares usa el mocambo como leñera;
     - Etiopía lleva lo excavado a la corte.
   - **Producción militar por función:** cuartel (choque y línea), campo de tiro (distancia), corral de guerra (montados, edad II) y taller (asedio, edad II). Cinco de seis pueblos se apartan del molde con fundamento.
   - **Plan de 11 pasos,** de lo barato y reversible a lo que mueve el balance (almacenes y cuarteles al final), con un solo cambio de balance por torneo. Lo adopto como plan de esta etapa.
   - **Preguntas al autor:** C-25 a C-30 en `CONSULTAS.md`. Mientras no contestes, sigo con la opción por defecto.
3. **(23:00) Primeros arreglos, adelantados del plan (pasos 2 y 3) porque son chicos y claros:**
   - **Al terminar un almacén, quien lo levantó recolecta** lo más cercano que ese almacén recibe (`_do_build`), como en AoE4. Antes volvía a lo que juntaba antes o se quedaba ocioso. Prueba nueva `tests/jugabilidad.gd`: tres aldeanos levantan un depósito junto al bosque y al terminar los tres cortan madera.
   - **Tecnologías por capacidad, no por tipo de edificio:**
     - el campo `en` de `tecnologias.json` dice dónde se investiga: `{"deposito": "madera"}` vale en cualquier edificio que reciba madera, y `{"tipo": "centro"}` en el centro o la capital;
     - una sola función, `Sim.tech_here`, la usan la simulación, la grilla y la IA;
     - arregla las fallas de la auditoría: Ayutthaya investiga tala, cantería y orfebrería en su centro, y los mapuches cestas, riego y mampostería en el lof;
     - la prueba revisa que, en cada civ, toda tecnología tenga dónde investigarse.
   - Determinismo, autotest con Ayutthaya, mapuches y guaraníes, `tests/grilla.gd` y `civ_smoke` sin errores.
4. **(23:20) Paso 1 del plan: línea de base y números al dato.**
   - **Números al dato:** la separación entre lugares de un grupo (750), el radio en que un constructor ayuda en otra obra (10 000), las proporciones de aldeanos de la IA y la distancia a la que la IA considera lejos un almacén (4500) pasaron de `sim.gd` y `sim_ai.gd` a `reglas.json` (`grupo`, `ia_economia`), sin cambiar los valores. Determinismo OK.
   - **Prueba nueva `tests/grupos.gd`:** reproduce la medición de la auditoría y es la base que los pasos de formación tienen que mejorar.

     | Caso | Diferencia de llegada | Dispersión al llegar | Estiramiento en la marcha |
     |---|---|---|---|
     | 24 militares mixtos a 40 casillas | 23,4 s | 2,4 casillas | 12,9 casillas |
     | 12 aldeanos a 40 casillas | 4,7 s | 1,4 | 2,8 |
     | 12 aldeanos a 6 casillas | 3,8 s | 1,4 | 2,7 |

     Los militares llegan desparramados en el tiempo y se estiran casi 13 casillas en el camino, porque cada uno va a su velocidad. Los aldeanos, todos iguales, casi no se estiran. Objetivo de la propuesta: llegada ≤ 3 s y dispersión ≤ 4 casillas (`--objetivo=1` lo exige).
5. **(00:00) Pasos 4 y 5 del plan: formación y grupo en marcha** (`src/sim/sim_groups.gd`).
   - **Cómo funciona:**
     - un ancla virtual sigue un solo camino A* para todo el grupo, a la velocidad del más lento;
     - cada miembro camina hacia su lugar en la formación, relativo al ancla y al rumbo (tabla de 16 rumbos en enteros);
     - los rezagados a más de 0,8 casillas corren +40 % (+25 % los aldeanos);
     - si alguien queda a más de 5 casillas, el ancla espera hasta 8 s y después lo suelta;
     - mientras alguien pelea, el ancla se planta, y al terminar cada uno vuelve a su lugar, no a un punto suelto;
     - si el lugar cae sobre algo sólido o la unidad se traba, sigue al ancla: pasa en fila por los vados;
     - el grupo se disuelve al llegar.
   - **Formación por bandas**, de adelante hacia atrás: línea, choque, distancia, asedio y apoyo; los montados en las alas. Dentro de cada banda los lugares se asignan sin cruces (adelante primero, después de izquierda a derecha).
   - **Cuándo se forma:** con 2 o más unidades a 12 casillas o menos del centro de la selección; las de afuera van solas. Solo aldeanos: en bloque únicamente si el destino está a más de 16 casillas, y si no, cada uno corre a su trabajo, como pidió el autor. La orden `move` con `"suelto": true` no forma (para la retirada; falta el botón y Alt en la interfaz).
   - **Números:** todos en `reglas.json → grupo`. El estado del grupo entra en el hash. Determinismo OK.
   - **Resultado** (`tests/grupos.gd`, [resultado](pruebas/05-grupos.txt)):

     | Caso | Llegada (antes → ahora) | Estiramiento en la marcha |
     |---|---|---|
     | 24 militares mixtos a 40 casillas | 23,4 s → **1,1 s** | 12,9 → **4,0 casillas** |
     | 12 aldeanos a 40 casillas (en bloque) | 4,7 s → **0,3 s** | 2,8 → 2,5 |
     | 12 aldeanos a 6 casillas (cada uno) | 3,8 s → 3,8 s | sin cambio, como se quería |

     Cumple los objetivos de la propuesta (llegada ≤ 3 s, dispersión ≤ 4). El banco de 200 unidades mejoró: el peor tick bajó de 78 a 46 ms, porque un grupo pide un camino y no 200.
   - **Captura** (`--demo=formacion --civ=mapuches`, nueva): 24 unidades mixtas desparramadas junto a la base, mandadas al centro. Segundo 1 y segundo 7: el bloque marcha junto, con los jinetes en las alas.

     | Salida | En marcha |
     |---|---|
     | ![](formacion-salida.jpg) | ![](formacion-en-marcha.jpg) |
   - `civ_smoke` sin errores, autotest OK y 2v2 de 10 minutos sin fuego amigo.
   - **Falta, por orden del plan:**
     - ataque a un blanco lejano en formación (paso 6);
     - aldeanos en bloque al mandarlos a recolectar o construir lejos, con escolta (paso 7);
     - formaciones elegibles, Alt para ir suelto y el rumbo con el arrastre (paso 8);
     - un torneo para ver si el balance se movió.
6. **(00:50) Paso 7 del plan: aldeanos en bloque cuando el trabajo está lejos.**
   - **Grupo con tarea:** el grupo puede llevar una tarea pendiente (`then`). Al clic derecho sobre un recurso, un cimiento, un almacén o un edificio propio a más de 16 casillas, la selección marcha en bloque. A 6 casillas del destino (`aldeanos_suelta_dist`) se disuelve y cada uno hace lo pedido: recolectar, construir, entregar o refugiarse.
   - **Cimientos lejanos:** al poner un cimiento lejos, los constructores también van en bloque.
   - **Cerca, nada cambia:** cada uno corre a su trabajo, como pidió el autor.
   - **La IA** da las mismas órdenes, así que sus aldeanos también marchan juntos a lo lejano.
   - **Pruebas** (`tests/jugabilidad.gd`, [resultado](pruebas/07-jugabilidad.txt)):
     - 6 aldeanos mandados a una arcilla a 54 casillas marchan en grupo y, al llegar, los seis recolectan. Reciben la orden de recolectar todos en el mismo tick, cuando el grupo se disuelve; la prueba no mide cuándo pisa cada uno la arcilla;
     - 3 aldeanos mandados a algo cercano van directo, sin grupo.
   - **Captura** (`--demo=bloque`, nueva, con la cámara puesta por la demo): 10 aldeanos guaraníes cruzan el campo en dos filas de cinco hacia la arcilla del centro, segundo 20.

     ![](aldeanos-en-bloque.jpg)
   - **Tropiezo:** la primera captura mostraba a los aldeanos quietos junto a una arcilla, y parecía una falla del grupo. Era la demo: buscaba la arcilla entre las entidades activas, donde los recursos no están, y nunca dio la orden. Con la búsqueda corregida, el grupo avanza parejo; 47 casillas a paso de aldeano son unos 40 s.
   - Determinismo OK, banco de 200 unidades en 7,8 ms de promedio y 45 de peor tick, `tests/grupos.gd` OK y autotest OK.
7. **(01:05) Parte del paso 8: ir suelto.**
   - **Alt + clic derecho** manda sin formación: cada uno a su velocidad, para retirarse. Es lo más pedido en el foro de AoE4 (referencia, §6). El marcador sale en rojo para que se note que va suelto.
   - **La IA** se retira suelta cuando saca unidades de la base rival (`_leash`).
   - La ayuda (F1) lo explica.
   - **Falta del paso 8:** elegir la formación (bloque, línea, abierta, columna) y el rumbo con el arrastre.
   - Autotest OK y determinismo OK.
