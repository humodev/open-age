# Ronda 8 · Jugabilidad competitiva, a dos voces

> Aclaración del autor sobre el informe 03: «Red, lobby y repeticiones OBVIAMENTE faltan, pero lo más importante es a nivel jugabilidad, competitividad». Acá no se habla de infraestructura: solo de cómo se juega una partida entre dos que quieren ganar.

**Voces:** **V** = veterano competitivo de AoE4 (rankeadas, torneos). **C** = constructor de partidas largas en equipo (AoE2 DE, AoE4).
**Método:** lectura de `data/` (unidades, edificios, edades, tecnologías, reglas y los 6 pueblos), `docs/05-mecanicas-nucleo.md`, el torneo 39 (`proceso/26-juego-tardio/pruebas/39-torneo-paso-6-completo.txt`, 150 partidas de IA contra IA, 30 min) y nuestras rondas 7 y 8. No corrimos Godot. Los números de AoE4 y AoE2 son de memoria y aproximados. **Advertencia de los dos:** todo lo medido es IA contra IA; las cuentas de este informe son a mano y hay que confirmarlas con la matriz de micro y el modelo de progreso.

## 0. Números base

| Qué | Raíces | AoE4 (aprox.) |
|---|---|---|
| Inicio | 6 aldeanos, 1 explorador; 200 A, 200 M, 100 P, 100 R | 6 aldeanos y explorador; parecido |
| Aldeano | 50 A, 18 s; alimento 1,0/s, carne 1,2, granja 0,75, madera 0,85, piedra y riqueza 0,7 | 50 A, 20 s; tasas parecidas |
| Hito II | 500 A + 300 R, **190 s** | 400 A + 200 O, ~150 s |
| Hito III | 1000 A + 600 R + **200 P**, **220 s** | 1200 A + 600 O, ~190 s |
| Hito IV | 1800 A + 1200 R + **400 P**, **250 s** | ~2000 A + 1500 O |
| Centro | 400 M + 300 P, 120 s | 400 M + 300 P |
| Piedra del mapa | **1600 por jugador** (2 afloramientos de 800, igual en todo tamaño) | bastante más; renovable de hecho por mineros |
| Sitios | 3; renta **18/12/8 R por minuto** (+50 % en la IV); se toman desde la I; cuenta desde el min 15 | ~100 O por minuto cada uno desde la III |
| Triángulo (`reglas.bonos`) | línea +6 contra choque; distancia +4 contra línea; choque +6 contra distancia | lancero +17 contra caballo; arquero +5/+10 contra ligera |

Tiempos reales (IA): II de la difícil a los **5:56** (1v3, ronda 8); III de la experta a los **17–18 min** (ronda 7, `bancos`); IV a los **26:42** de mediana (paso 7). Torneo 39: **97 de 150 por puntos** al minuto 30; ninguna partida se cierra antes del **11:24**; en las 93 partidas decididas entre jugadores de distinta edad, **gana el de edad mayor en 89**.

## 1. Diversidad de estrategias

Órdenes viables (cuentas a mano, jugador humano ajustado):

| Orden | Cómo | Cuándo pega | Qué cuesta |
|---|---|---|---|
| **Raid de la I** (Etiopía, mapuches) | cuartel al 1:30; 4 o 5 guerreros (Etiopía: 80 A + 40 R, 160 PV, 2,1 de velocidad) | ~4:30 sobre la madera | 160–200 R de los 300 del hito: la II se atrasa 1:30–2:00 |
| **II rápida + timing** | hito al ~2:50 con 3 constructores, II a ~5:30; 2 cuarteles, lanceros y jinetes o la unidad de la II del pueblo | 8–10 min | poco: es la línea estándar |
| **Boom de dos centros** | segundo centro en la II: 400 M + **300 P** | se paga al min 14–16 | consume 300 de los 1600 de piedra; con la III (200) y la IV (400) queda para 2 torres |
| **III rápida** | II ~5:30, hito III al ~9:30 (1800 de recursos más aldeanos), III a ~13:00 | catapulta y fortaleza al 14–15 | 220 s de obra expuesta y la piedra de la III |
| **Torre** | torre de la II (50 M + 150 P, 45 s) junto a la madera rival; con 5 adentro tira 6 flechas de 9,9 cada 1,5 s (~40 de daño por segundo) | 7–9 min | 150 P de 1600; el ariete (49 × 4 contra edificios) la tira en ~15 s |

- **V:** «En AoE4 conviven cinco planes porque cada uno tiene respuesta y premio. Acá domina **subir de edad y defender con la guarnición**: el centro con 15 adentro tira 17 flechas de 5 cada 2 s (~42 por segundo, un guerrero cada 3 o 4 s), el aldeano camina 1,25 y nada de la I lo persigue sin perder contra el centro. El raid pega en la madera lejana y nada más; la riqueza que gasta atrasa la II casi dos minutos, y la edad decide 89 de 93 partidas.» **Impacto alto.**
- **C:** «Los dos planes "lentos" (boom y torre) se comen la misma piedra que la III y la IV. Con 1600 por jugador, el boom de tres centros (600 P) te deja sin la IV salvo que compres en el mercado. No hay elección entre boom y torre: hay una sola bolsa.» **Impacto alto.**
- **Propuestas:** (a) **piedra a ~3000 por jugador** más una veta disputada en el centro (dentro del análisis de recursos que pidió el autor); (b) **hitos de 190/220/250 s a 150/180/210 s**, para que la III rápida llegue al 10–11 como en AoE4 y sea un plan, no un sacrificio; (c) que la III no pida piedra o pida 100, y que la piedra vaya a defensa y expansión (como AoE4, donde la piedra es para centros, torres y muros).

## 2. Contadores y contrajuego

- **El triángulo de la I está cojo** (alto). El choque (guerrero) está en la I para todos; la línea (lancero), solo para mapuches y Tawantinsuyu (`edad_min: 1`); el resto, desde la II. El hondero contra el guerrero hace 7 cada 1,75 s: tarda 30 s en matarlo y muere en 5. Contra el guerrero rápido etíope de la I no hay unidad que lo pare, solo la guarnición. **Propuesta:** lancero en la I para todos, **como AoE4**.
- **Los bonos son chicos frente al ataque** (alto). Lancero contra jinete: 8 + 6 − 1 = 13 por golpe; el jinete le gana mano a mano en tiempo (17,5 s contra 19,6 s) y el lancero gana solo por costo (95 contra 170). En AoE4 el lancero triplica su daño contra el caballo. **V:** «Un contador que gana por costo y no en la pelea no se lee en la pantalla: el que mira ve que el caballo ganó.» **Propuesta:** línea +6 → **+12** contra choque (o +6 más contra `montado`), distancia +4 → **+6**, choque +6 → **+8**; ajustar con la matriz de micro hasta que el contador gane 1 a 1 a igual cantidad.
- **El arcabucero no vale lo que cuesta** (medio). 16 cada 3,2 s (5 por segundo) por 130 de costo; el hondero, 7 cada 1,75 s (4 por segundo) por 75. A igual gasto el hondero hace un 40 % más de daño y tiene más vida. No hay armadura que justifique el golpe grande hasta la herrería III. **Propuesta:** cadencia 3200 → **2500** o un bono contra armadura (+4 contra línea y choque con armadura ≥ 2, **como la pólvora de AoE4**).
- **El elefante de Ayutthaya en la II** (medio, a medir): 640 PV, 3/3 de armadura, 22 de ataque en área de 1,6 casillas, por 280. Sin bono propio contra él, 4 lanceros (380) tardan ~22 s y el área los pega a todos; el hondero le hace 4 por golpe. **Propuesta:** matriz de micro con 4 a 6 lanceros; si gana a igual costo, área 1600 → **1200**, o el lancero suma bono contra `montado` y el elefante lo es.
- **Asedio de área** (bien, con un hueco). La catapulta tiene contrajuego claro: el choque le pega ×1,5 y muere en ~10 s con un jinete; la distancia, al 40 %. **Pero** el impacto inmediato (D-021) hace que el tiro no se pueda esquivar: ver §5.
- **Fortaleza** (bien). 3500 PV, 4 de armadura; el ariete (49 × 4 = 196 cada 3 s) la tira en ~55 s con uno, en ~14 s con cuatro, y los incendiarios mapuches castigan las de madera. Tiene respuesta.
- **Maravilla** (alto, ya aprobado en parte). 2400 s de obra (21 min con 10 constructores) y 15 min de cuenta. Respuesta posible (9000 PV, la IA experta la ataca), pero nadie la ve venir. **Propuesta, además de lo aprobado:** la maravilla en obra **revela su lugar a todos** (como AoE4) y su cuenta baja a **10 min** en el modo competitivo.

## 3. Información y scouting

- **Bien:** el panel de Edad (F4) muestra la edad de cada rival y el minuto en que llegó, **como la barra de AoE4**. El combate no tiene azar. La elección de hito se ve solo explorando: eso es justo y premia al explorador.
- **El explorador sirve, pero se queda corto** (medio). Velocidad 2,1 y 11 de visión; el arreo de rebaños le da trabajo económico, **como las ovejas de AoE4**. Pero lo alcanzan el jinete (2,2), el guerrero etíope (2,1) y la infantería montada (2,1), y no hay vista fija barata en la I: la torre es de la II y pide piedra. **Propuesta:** un **puesto de vigía en la I** (75 M, sin ataque, 10 casillas de visión, **como el puesto de AoE4**) y el explorador a 2,3.
- **Sigilo y mocambos ocultos** (medio). Tres pueblos tienen sigilo (mapuches, guaraníes, Palmares) y Palmares tiene mocambos ocultos. **V:** «Lo oculto está bien si hay una regla pública para revelarlo.» **Propuesta:** fijar y mostrar en la ficha la regla: se revela al atacar, al recolectar, o con una unidad enemiga a 3 casillas; el explorador revela a 5.
- **Hito de la II que pide la maravilla** (medio, ya pedido): decirlo en la ficha. Es información escondida para el propio jugador.

## 4. Control del mapa

- **Los sitios no pagan** (alto). 18 R por minuto el primero, 38 los tres: un aldeano en la riqueza junta 42. Tener los tres sitios vale menos que un aldeano. En AoE4 tres sitios rinden ~300 de oro por minuto, unos 7 aldeanos. Además, `disputado.tope_por_min` corta lo que sale de lo disputado en **15/40/80/120** por minuto según la edad. **V:** «Hoy el sitio es solo la amenaza de la victoria. Nadie sale de la base por 18 de riqueza.» **Propuesta:** renta **60/45/30** por minuto, que se tomen **desde la II** (en AoE4, desde la III) y el tope a **15/80/160/240**.
- **El aura económica del hito** (+15 % de recolección a 9 casillas) premia ponerlo junto al recurso: es una decisión de colocación buena, **como el aura de los landmarks de AoE4**.
- **El aura militar local de la III y la IV** (medio). Cura 2 PV por segundo y da el bono de combate solo cerca del hito. **C:** «Me encanta: pelear en casa es más fuerte.» **V:** «Por eso mismo empuja a encerrarse: quien ataca pelea siempre sin aura.» Junto con la fortaleza y la empalizada a 4 de madera, el juego **premia esperar**. **Propuesta:** dejar el aura y **dibujar su radio** siempre; si la matriz da más de un 15 % de ventaja al que defiende, bajar el radio de 9 a 7 casillas.
- **Caminos** (bajo). El +30 % de velocidad de los caminos inca es control del mapa de verdad (cortarlos frena). Bien así.
- **Mapas** (medio). En el torneo 39, **fortines** termina por puntos en 10 de 11 partidas; **mesetas**, decidida en 9 de 14. El mapa decide el ritmo más que el pueblo. **C:** «Bien: es Arena contra Arabia.» **V:** «Bien si es un pool con nombre que se veta, no un terreno al azar.»

## 5. Techo de habilidad

- **El tiro del asedio no se esquiva** (alto). Con impacto inmediato (D-021) el área de la catapulta pega siempre. En AoE2 y AoE4 esquivar el mangonel y splitear es la micro que más separa. **Propuesta:** solo para el asedio de área, un tiempo de vuelo fijo en ticks (por ejemplo 8 ticks) contra el **punto** donde estaba el blanco; sigue siendo entero y determinista. Y **atacar el suelo** (pedido de la ronda 7).
- **Splitear sirve poco** (medio). La formación separa a 0,75 casillas y el área mide 1,0 (1,3 la de Ayutthaya, 1,6 el elefante): siempre caen 3 a 5. **Propuesta:** un botón de **formación abierta** (separación ×2) y la tecla de dispersar.
- **Kitear depende de la velocidad** (medio). Hondero 1,25 contra lancero 1,1: se puede. Contra guerrero (1,35) o jinete (2,2), no. Eso está bien (el choque es el contador). Falta confirmar con la matriz de micro que detenerse a tirar no castiga de más.
- **Focus fire** existe (orden directa sigue al blanco) y la prioridad automática (militar > aldeano > edificio) es la de AoE4.
- **Automatismos** (medio). La repetición de producción con tope de aldeanos (80) es la «auto-queue» de AoE4: **V** la acepta en rankeadas porque AoE4 la tiene; **C** también. Lo que achata es otra cosa: los consejos que dicen «Tenés ejército y recursos de sobra: atacá o subí de edad» (`consejos.gd`) y el «Población llena» repetido. **Propuesta:** en el modo competitivo, **sin consejos de decisión**; queda el aviso de ataque. Coincide con lo que pidió el autor («el usuario debería darse cuenta solo»).
- **La masa gana** (alto, ya señalado). Con bonos chicos, área inevitable e impacto inmediato, el combate es más de cantidad que de manejo (90 contra 20 en la ronda 8). Las propuestas de §2 y §5 apuntan a esto.

## 6. Ritmo y momentos de decisión

- **Las edades son lentas** (alto). 190 + 220 + 250 = 660 s de obra; la III llega al 17–18 en la experta. En AoE4 la III rápida está al 9–10 y la estándar al 12–14. Las ventanas de ataque reales del torneo: un racimo al **16–17 min** (Palmares: 7 de sus 13 victorias) y otro al **19–22** (mapuches). Nada antes del 11. **Propuesta:** la de §1 (b).
- **Invertir o defender sí hay** (bien). El hito en obra se puede atacar (`ia_hito_en_obra`) y es el blanco más rico, **como el landmark de AoE4**. Es el mejor momento de decisión del juego.
- **El snowball de la edad** (alto). 89 de 93: el de mayor edad gana. Parte es correlación (la mejor economía sube antes), pero desde el paso 1 la edad trae herrería, veterano y élite, y el aura local suma. No hay vía de vuelta: los sitios no pagan, no hay reliquias y quien pierde la capital y los hitos pierde con 25 aldeanos vivos. **Propuesta:** (a) sitios que paguen (§4), que es el comeback de AoE4: ganar el mapa sin ganar la base; (b) que el centro extra cuente para no perder mientras tenga guarnición (`victoria.hitos`), **como AoE4 con cualquier centro**; (c) medir en el modelo cuánto vale una edad de ventaja a igual economía.
- **El final** (medio, aprobado): escuelas excluyentes y élite cara dan decisión en la IV.

## 7. Asimetría de los seis pueblos

| Pueblo | Plan reconocible antes del 15 (datos) | Torneo 39 | Veredicto |
|---|---|---|---|
| **Mapuches** | raid: lancero en la I, guerrero a 1,75, infantería montada de la II (2,1), malón | 62 %, **16 decididas** (16–25 min) | claro y temprano |
| **Palmares** | timing: zagaieiro de la II (bono contra choque), cerca con estrepes, sin aldeanos | 64 %, 7 victorias entre 15:48 y 16:54 | claro; el más fuerte |
| **Etiopía** | guerrero de la I rápido y duro (160 PV, 13, 2,1); defensa en altura | 44 %, 8 decididas | claro, pero el raid de la I no paga (§1) |
| **Ayutthaya** | elefante y compañía japonesa (85 R) en la II, arcabucero de la II | 52 %, 10 decididas | claro; el elefante, a medir |
| **Tawantinsuyu** | awqa y lancero en la I, caminos, mit'a; «arranque lento» | 44 %, 6 decididas | se nota después del 20 |
| **Guaraníes** | roza, sigilo, sin torre | 34 %, **0 decididas**: las 17 victorias son por puntos | **no tiene cómo cerrar una partida** |

- **V:** «Cuatro de seis tienen identidad antes del 15, mejor de lo que dijimos en la ronda 7. Guaraníes y Tawantinsuyu no: uno no gana nunca por destrucción y el otro aparece tarde.» **Propuesta:** a cada uno, una herramienta de la II que cierre: emboscada guaraní (+50 % al primer golpe desde el monte con sigilo) o la ygá con desembarco como plan de raid; y el boleador inca de la II con frenado útil contra caballería (hoy 4 de ataque).
- **Lo que nunca se usa** (medio): galgueros (la IA no los entrena), capitão do mocambo, kona, defensores de Suan Phlu (ronda 7); el arcabucero común (§2). **C:** «En humanos van a aparecer más, pero si la IA no los usa, nadie aprende a contestarlos.»
- **Lo obligatorio** (medio): el mercado para la piedra de la IV (ronda 8, ambos) y la guarnición del centro como única defensa de la I. Las dos se resuelven con §1 (a) y §2.

## 8. Varianza y situacionalidad

- **Bien:** sin azar en el combate; la trepanación devuelve 1 de cada 5 por cuenta, no por dado; el generador es simétrico por giro.
- **Auras de hito** (medio): el aura militar local hace que la misma pelea gane uno u otro según dónde pase, y no se ve. Dibujar el radio (§4).
- **Afloramientos de piedra** (alto, **C**): con 1600 por jugador, dónde caen y cuánto queda decide la III y la IV. Es azar del mapa disfrazado.
- **Mapas** (medio): 1 de 11 decididas en fortines contra 9 de 14 en mesetas. Bien como variedad; mal si toca al azar en un torneo. **Propuesta:** pool fijo de 5 mapas con veto.
- **Unidades que ganan solas** (medio): el elefante de la II y la catapulta antes del ajuste del paso 4 (2 ganaban cualquier pelea). Regla de los dos: ninguna unidad debe ganar 1 contra su contador a igual costo en la matriz de micro.

## 9. Los 15 cambios que más competitividad dan

| # | Cambio | Dónde | Impacto | Esfuerzo |
|---|---|---|---|---|
| 1 | Bonos del triángulo: línea +12 contra choque, distancia +6, choque +8 (ajustar con la matriz) | `reglas.bonos` | Alto | Bajo |
| 2 | Lancero en la I para todos | `unidades.lancero.edad_min` | Alto | Bajo |
| 3 | Sitios: renta 60/45/30, desde la II; tope disputado 15/80/160/240 | `reglas.sitios`, `disputado` | Alto | Bajo |
| 4 | Hitos 150/180/210 s (III rápida al 10–11) | `edades.json` | Alto | Bajo |
| 5 | Piedra ~3000 por jugador y una veta central disputada; III con 100 P o sin piedra | generador, `edades.json` | Alto | Medio |
| 6 | Asedio de área con tiempo de vuelo al punto (esquivable) y atacar el suelo | `sim.gd`, D-021 | Alto | Alto |
| 7 | Formación abierta (separación ×2) y dispersar | `reglas.grupo`, interfaz | Medio | Medio |
| 8 | Arcabucero: cadencia 2500 o bono contra armadura | `unidades.arcabucero` | Medio | Bajo |
| 9 | Una herramienta de cierre de la II para guaraníes y Tawantinsuyu | `data/civs` | Medio | Medio |
| 10 | Puesto de vigía de la I (75 M, visión 10) y explorador a 2,3 | `edificios`, `unidades` | Medio | Bajo |
| 11 | Modo competitivo sin consejos de decisión | `interfaz.json`, `consejos.gd` | Medio | Bajo |
| 12 | Radio del aura militar dibujado; bajar a 7 si da más de 15 % al que defiende | interfaz, `aura_hito` | Medio | Bajo |
| 13 | Regla pública de revelado del sigilo y de los mocambos | `data/civs`, ficha | Medio | Medio |
| 14 | Elefante de la II: medir y, si hace falta, área 1600 → 1200 | `data/civs/ayutthaya.json` | Medio | Bajo |
| 15 | Pool fijo de 5 mapas con veto y la maravilla visible desde que se pone | `reglas.terrenos`, interfaz | Medio | Medio |

Ya aprobados por el autor y que suman a esto: escuelas excluyentes y élite cara, contrajuego a la maravilla, muralla de piedra en la II, la IA que usa el mercado.

## 10. Dónde coinciden y dónde no

**Coinciden:**
- el triángulo existe pero **se lee poco**: los bonos son chicos y la I no tiene línea (1 y 2);
- los sitios no pagan lo suficiente para salir de la base (3);
- el asedio de área necesita contrajuego de manejo, no solo de composición (6 y 7);
- guaraníes no tienen cómo cerrar una partida;
- todo esto hay que medirlo con la matriz de micro antes de dar números finales, porque lo único medido es IA contra IA.

**No coinciden:**
- **Encerrarse o moverse (el desacuerdo principal).** **V:** «La empalizada a 4 de madera, el aura local, la fortaleza y la guarnición del centro hacen que esperar sea siempre lo seguro. Subiría la empalizada a 8 de madera, bajaría el radio del aura y pagaría los sitios: el que se mueve tiene que ganar más.» **C:** «Encerrarse es una estrategia, no un error. Pagaría los sitios, sí, pero la empalizada barata se queda: la respuesta al muro es el ariete y los incendiarios, y el formato largo tiene que existir como la Arena de AoE2.»
- **Qué ajustar primero.** **V:** el ritmo (hitos más cortos, cambio 4) y el triángulo. **C:** la piedra (cambio 5): «con 1600 por jugador, ningún otro número de la III o la IV es justo».
- **El aura militar local.** **V** la quiere visible y más chica; **C**, tal como está.
- **La duración.** **V** apunta a partidas de 20 a 30 minutos con la III rápida al 10. **C** acepta acortar los hitos si la piedra alcanza para jugar la IV.
