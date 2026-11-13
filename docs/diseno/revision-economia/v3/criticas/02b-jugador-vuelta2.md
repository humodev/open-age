# Ronda 3 · Crítica 02b — El jugador competitivo, segunda vuelta

Leí [`03-diseno-revisado.md`](../03-diseno-revisado.md) contra lo que pedí en [`02-jugador-competitivo.md`](02-jugador-competitivo.md). Sigo mirando como Conqueror de AoE4: qué haría en ranked, qué abusaría y qué me aburriría. Las cuentas salen de las tablas del 03. Cuando adivino, lo digo.

---

## 0. Veredicto corto

- **Mejoró mucho.** Aceptaron casi todo lo que pedí y lo resolvieron bien en tres casos: el kawiñ (faenar con tope), la corte que se funda sin carpa y el arreo en el núcleo. La tabla §3.0, con forma, de qué se alimenta y cómo se pierde, es exactamente la respuesta a "los cuatro edificios se sienten iguales".
- **Ayutthaya dejó de ser un campamento maderero con +X %**, pero solo a medias: ahora es "un campamento maderero que camina". Ya tiene decisión y riesgo; todavía le falta el momento.
- **Aparecieron problemas nuevos**, y uno es serio:
  1. **Guaraníes llegan a la edad III a las 10:20**, entre 3,5 y 4,5 minutos antes que el resto. En ranked eso es un plan obligatorio de castillo rápido.
  2. **La corte etíope nueva es gratis y se puede fundar cada 5 minutos con fiesta ×2**: corre el riesgo de volverse un ritual, y además es un centro urbano adelantado gratis.
  3. **El regimiento quedó tan recortado** que "señor" es siempre la respuesta: se perdió la mejor decisión de la primera versión.
  4. **"Con el edificio en combate, los oficios paran"** vuelve a Palmares la víctima de un solo arquero que pica el mocambo.
  5. **El arreo no tiene adónde ir** cuando los corrales están llenos, que es casi siempre.
- **Esfuerzo:** ahora sí lo siento parejo hacia arriba; nadie pide demasiado. La diferencia está abajo (Palmares y guaraníes piden poco), y eso no me molesta si hay decisiones. Palmares casi no las tiene en el motor.

---

## 1. ¿Se sienten distintas? ¿Ayutthaya dejó de ser "+X %"?

| Civ | Antes | Ahora | ¿Mismo edificio con otro nombre? |
|---|---|---|---|
| Tawantinsuyu | Edificio de renta con mantenimiento | Conversión que depende de **gente viva**: si te matan runa, cae la tela | No, pero en pantalla sigue siendo "un edificio que da 24". La diferencia la sentís solo cuando te matan runa |
| Mapuches | Capital vivo | Capital vivo + arreo | No. Es la más distinta junto con Palmares |
| Guaraníes | Sucesión | Sucesión que se resiembra sola + dejar crecer o quemar | No |
| Etiopía | Renta por cercanía, corte inmóvil | Renta por cercanía, corte que se funda | No, ahora sí: el mapa económico se mueve |
| Palmares | Gente adentro | Gente adentro con nombre de oficio | No (y sigue sin encolar aldeanos) |
| Ayutthaya | Campamento maderero +25 % | Depósito que camina, 600 pv, población 2 | **Ya no**, aunque se acerca |

**Ayutthaya, en detalle.** Lo que cambió para bien:
- **Ahora hay riesgo.** Un elefante de 600 pv que cuesta 160 y carga el 0,8 AE es una presa que se ve. Contra mapuches o Etiopía, cuidarlo es parte del juego. Eso es lo que el campamento fijo no tenía.
- **Hay una decisión real de fuente.** El segundo elefante a la piedra no es capricho, porque la edad III pide 200 de piedra y la IV 400. Madera rinde un poco más de riqueza por trabajador (34 × 25 % ≈ 8,5 contra 26 × 25 % ≈ 6,5), pero la piedra la necesitás igual. Es una decisión parecida a la de dónde poner el campamento minero en AoE4, que no es gran cosa pero es real.
- **No necesita bosque**, y eso la vuelve viable en cualquier mapa.

Lo que todavía le falta:
- **En la práctica, el elefante es un campamento maderero que no hace falta reconstruir.** En AoE4 hago un campamento nuevo cuando se aleja el bosque: es una orden. Acá muevo el elefante: es la misma orden. La decisión de "cerca o lejos" existe, pero la mayoría de las veces la respuesta va a ser "al lado de los leñadores, del lado de mi base".
- **Trampa para el jugador:** "si entregan en otro depósito, el rey no cobra". Si Ayutthaya puede construir campamentos madereros comunes, el principiante va a perder riqueza sin saberlo y el experto nunca los va a construir. **Sáquenle el campamento maderero y la mina** (`sin_edificios`), como a los mongoles las casas. Así el elefante es *el* depósito, y la identidad queda forzada en el buen sentido.
- **El momento** (captura de manadas) quedó para la fase 2. Sin él, Ayutthaya se juega bien pero no se cuenta después.

Nota: pasó de 4 a 6. Con el kraal, sería 8.

---

## 2. ¿Las decisiones son reales?

Cuento solo las que tienen dos respuestas viables según el rival, el mapa o el momento.

### Tawantinsuyu — 1 real y 1 a medias
- **Reserva 0 / 60 / 120: a medias.** Es un ajuste que se pone una vez (60) y se olvida. Mejor que el interruptor por taller, porque se pierde el clic, pero no es una decisión que se repita.
- **Cuántos talleres contra cuánta leva: real.** Con 3 de mit'a por runa desde la III y 50 runa justas para 5 talleres, una leva grande le saca tela de verdad. Bien.
- **Qué conectar: obvia.** El propio diseño lo admite.
- **Regalo de cumbi:** sería la segunda decisión real, pero está en la fase 2.

### Mapuches — 2 reales y 1 obvia
- **Dónde va el corral: real.** La separación de 8 casillas es una regla legible y obliga a dispersar. Mejor que la vecindad invisible.
- **Malón al rival o a lo neutral: real.**
- **Kawiñ: obvio, pero ya no es un problema.** Cuatro cabezas a 30 son 120 de alimento. Lo pierdo en riqueza: 120 s sin cría más 4 × 35 s para volver a llenar, unas 11–12 cabeza·minuto, o sea ~45 de riqueza. 120 de alimento por 45 de riqueza justo antes del hito es siempre buen negocio. **Todos los mapuches van a hacer kawiñ en todos los corrales antes de cada hito.** Es un paso del orden de construcción, no una decisión. Como tiene tope (uno por corral y por edad), no es ritual. Lo acepto así, pero no lo cuenten como decisión.

### Guaraníes — 1 real
- **Dejar crecer o quemar: real**, y bien diseñada. Es un ajuste global, no cuesta clics, y la respuesta cambia según el momento ("quemo hasta el hito y después dejo crecer").
- **Dónde abrir rozas nuevas: real**, pero de poco peso.
- **Misión o monte:** real si sigue viva.

### Etiopía — 2 reales, 1 que se rompió
- **Cuándo y adónde fundar la corte: real** desde la edad III (flanco seguro o centro disputado). En la edad II es obvia: "cuando se acaba la arcilla, al flanco", y el aviso te lo dice.
- **Dónde va el gult: obvio** (a ≤ 14 de la corte).
- **Señor o regimiento: se rompió.** Ahora es −10 % por gult, hasta −20 %, solo para jinetes que salen a ≤ 14 casillas. Dos gult de regimiento dejan de pagar ~42 de amole y 6 de alimento por minuto. A 70 a + 35 r, el −20 % ahorra 21 recursos por jinete: **para empatar hay que sacar dos jinetes por minuto sin parar**, desde un establo a ≤ 14 casillas. Eso es caballería masiva todo el tiempo, y aun así apenas empata. En ranked nadie hace regimiento.
  - El que intentaba romperlo tenía razón en que −30 % desde la edad I era demasiado. Pero el arreglo correcto era **la edad**, no el porcentaje.
  - Propuesta: −15 % por gult hasta −30 %, desde la edad II, con la restricción de las 14 casillas. O que el regimiento, en lugar de abaratar, **reponga** jinetes (uno gratis cada 90 s por gult), al estilo del *Warcamp* macedonio. Así es un plan de ejército de verdad.

### Palmares — 1 real
- **Correría o esperar la fama: real.**
- **Desalojar oficios: casi nunca.** La IA "no tiene nada que decidir en los oficios", y el diseño lo dice en §8.5. Para un humano es casi igual: se llenan solos y nadie desaloja salvo emergencia.
- **El sumidero de fama a gente de guerra** (40 de fama + 30 a con la población llena) es muy lindo y vuelve la fama sobrante en ejército. Pero no es una decisión: es automático.

### Ayutthaya — 2 reales
- **A qué fuente va cada elefante: real** (ver §1).
- **Arriesgarlo lejos o no: real** contra civs con caballería; contra civs lentas, casi obvia.
- **Qué barrio:** sigue siendo una decisión militar, no económica.

**Resumen:** el diseño dice 2 o 3 por civ. Yo cuento entre 1 y 2 de verdad. Es suficiente si cada una pesa, y en la mayoría pesa. Las dos que más me preocupan son el regimiento roto y Palmares, que solo tiene la correría.

---

## 3. ¿Planes obligatorios o civs aburridas?

### Planes obligatorios

1. **Guaraníes, castillo rápido a las 10:20. Es el problema más grande de esta versión.** Las otras cinco llegan entre las 13:50 y las 14:40. Tres o cuatro minutos de edad III antes que el rival, en un juego tipo Age, son una victoria casi automática si la civ tiene algo fuerte en la III (la milicia arcabucera sale en la III). El modelo lo atribuye a la arcilla que se agota primero, pero para el jugador da igual de dónde venga: **la roza da tanta comida que la guaraní siempre va a hacer castillo rápido**, y la pregunta "dejar crecer o quemar" se resuelve en "quemar hasta la III".
   - La palanca que propone el diseño (arcilla de +14 % a +7 %) ataca la riqueza. **El cuello de la III es el alimento**, y el alimento sobra por la roza (60 netos contra 36 de la granja).
   - Propuesta: roza a 1000 de tasa (en vez de 1100), o modo "quemar" al 50 % en vez del 70 %. Hay que medir en el torneo la III de los guaraníes con la IA real antes de tocar otra cosa.
2. **Etiopía: "señor" siempre** (ver arriba).
3. **Mapuches: kawiñ antes de cada hito.** Aceptable, es un paso del orden de construcción.
4. **Ayutthaya: elefante al lado de los leñadores.** Aceptable si se le saca el campamento común.

### Abusos nuevos que yo probaría en ranked

| Civ | Abuso | Por qué funciona | Arreglo |
|---|---|---|---|
| Etiopía | **Fundar corte cada 5 minutos para cobrar la fiesta** | El cimiento es gratis, se levanta solo en 60 s, y la fiesta da ×2 a los gult a ≤ 14 casillas durante 60 s. Con 5 gult de 21 son ~105 de amole extra por mudanza, gratis. Si dos claros a ≤ 12 de una misma arcilla cubren los mismos gult, me mudo de uno a otro cada 5 minutos | Fiesta solo si la corte nueva está a ≥ 20 casillas de la anterior, o solo cuando la arcilla de la vieja se agotó. O que la corte nueva cueste algo (madera, piedra) |
| Etiopía | **Centro urbano adelantado gratis** | En la edad III fundo una corte nueva junto a la arcilla del centro: es un centro urbano completo, con flechas, gratis y en 60 s. En AoE4, un centro adelantado cuesta 400 de piedra | Que la corte nueva nazca con menos vida (50 %) y se complete en 120 s, o que fundar en el centro cueste piedra |
| Palmares (víctima) | **Un arquero pica el mocambo y los oficios paran** | "En combate" con cualquier daño. Si 3 oficios dan 45 r/min, un arquero de 50 de recursos que tira una flecha cada 10 s los apaga | "En combate" solo si hay enemigos a ≤ 4 casillas o si el edificio perdió más del 10 % de vida en los últimos 20 s. O que bajen a la mitad en vez de parar. Las estrepes ya castigan al que se acerca: el que tira de lejos no paga nada |
| Ayutthaya | **Elefante como escudo** | 600 pv y población 2. Si el rival le apunta, ¿lo uso como tanque? | Que no pueda acompañar ejército: armadura a distancia 0, y que las torres y unidades lo prioricen. O que no tenga ataque y huya solo |
| Mapuches | **Arreo sin lugar = 40 de alimento** | Con los corrales llenos (casi siempre, porque crían cada 35 s), cada cabeza se vuelve 40 de alimento: el malón es una fuente de comida con tope de 120 por minuto. No es un abuso, pero **mata el momento**: la cabeza no camina, se vuelve comida | Ver §4 |

### ¿Alguna aburrida?

- **Tawantinsuyu es la más "normal" de esta versión.** El núcleo no tiene momento (el cumbi es fase 2), la reserva se pone una vez y el taller da 24. Se juega bien y tiene la tensión mit'a contra leva, pero en una partida no hay nada que no haría otra civ. **Pido que el regalo de cumbi pase al núcleo**, como el arreo. Son 120 de mit'a por un ingenio neutral: no es una pieza cara de programar si el ingenio ya existe como `owner = -1`.
- **Palmares tiene un motor aburrido y una civ apasionante.** No encolar, la fama que se vuelve ejército y los liberados que caminan son geniales; los oficios, en cambio, son "se llenan solos y no los toco". Está bien que sea la civ de baja atención económica, porque la atención va al ejército. Pero si encima un arquero le apaga los oficios, el jugador de Palmares va a pasar la partida persiguiendo hostigadores, y eso no es divertido.

---

## 4. ¿Quedaron los momentos memorables?

| Civ | Momento pedido | Estado | ¿Funciona? |
|---|---|---|---|
| Mapuches | Arreo que vuelve caminando | **Núcleo** | **A medias.** Con los corrales llenos, la cabeza se vuelve 40 de alimento y no camina. La persecución solo existe si hay lugar |
| Etiopía | Corte que acampa, con fiesta | **Núcleo** (la fiesta en la tabla de costos figura en la fase 2; hay que aclararlo) | **Sí**, si se corrige la fiesta repetible. "Fundo la corte junto al centro en la III" es la jugada que se recuerda |
| Ayutthaya | Elefante de trabajo + kraal | Elefante en el núcleo; manadas en la fase 2 | Elefante, sí. La captura es lo que se contaría, y no está |
| Palmares | Liberados que vuelven a pie | **Núcleo** | **Sí.** Y la liberación de edificios habitados del rival es incluso mejor de lo que pedí |
| Guaraníes | Monte que cambia de color + emboscada desde el yerbal | Color, sí (es imagen); emboscada en la fase 2 | **Débil.** El cambio de color no es un momento, es un fondo de pantalla. La emboscada sí lo sería |
| Tawantinsuyu | Regalo de cumbi | Fase 2 | **No está.** |

**El arreo necesita adónde ir.** Propuestas, de menor a mayor:
- las cabezas del arreo **siempre caminan** hasta el corral más cercano, aunque esté lleno, y al llegar se vuelven alimento. La persecución existe siempre; el premio cambia;
- o el corral acepta **cabezas de más por encima del tope** durante 3 minutos (el arreo "rebalsa"), y se las puede kawiñar aunque ya hayas hecho el de esa edad;
- o el arreo puede **fundar un corral**: si llegan 3 cabezas a un lof sin corral, se arma uno solo. Eso es "la riqueza camina y se reproduce" literal.

**Núcleo contra fase 2.** De los seis momentos, en el núcleo quedan tres (arreo, corte, liberados) y medio (el elefante sin el kraal). Pido que **el cumbi y la emboscada desde el yerbal** suban al núcleo. Son las dos civs que hoy no tienen nada que contar después de la partida. La captura de manadas puede esperar, porque Ayutthaya ya ganó identidad con el elefante.

---

## 5. ¿El esfuerzo y la atención se sienten parejos?

**Mucho mejor.** La regla "nada periódico por debajo de 90 s" se cumple a mi ojo en las seis. Lo que antes me preocupaba se fue:
- el faenar dejó de ser un ritual (kawiñ con tope);
- la mudanza etíope dejó de ser un pico de micro (no hay carpa que escoltar);
- la cola de rozas se volvió resiembra sin bandera.

Mi tabla de atención, de jugador, actualizada:

| Civ | Qué hay que mirar | Cada cuánto | Atención |
|---|---|---|---|
| Tawantinsuyu | Mit'a neta; runa que mueren | 2 min | Media-baja |
| Mapuches | Corrales dispersos; arreo en camino | 1–2 min cuando hay malón | **Media**, la más alta, y está bien: es su juego |
| Guaraníes | Modo del monte; madera para resembrar | 3–5 min | Baja |
| Etiopía | Cuándo fundar; dónde quedan los gult | 5 min | Baja-media |
| Palmares | Hostigadores en el mocambo (si sigue el "en combate") | Cada vez que pican | **Baja, o alta y molesta** si no se corrige |
| Ayutthaya | Dónde está cada elefante; que no lo cacen | 2–3 min | Media-baja |

La relación entre la más y la menos exigente ronda ×2, pero ahora la diferencia viene de **cuánta acción militar pide la civ** (mapuches persiguen y son perseguidos), no de clics de economía. Eso no me molesta: es identidad. Estoy de acuerdo con la vara nueva del diseño (umbrales absolutos y nada por encima de 1,5 veces la mediana) y con declarar el ×1,7 hacia abajo.

**Un pedido de medición:** cuando se implemente, contar en `atencion.gd` cuántas veces un edificio de oficio entra en "combate" por partida. Si pasa de 10, el jugador de Palmares está pagando un impuesto de atención que la tabla no ve.

---

## 6. Notas: ganas de jugarla

| Civ | Antes | Ahora | Por qué |
|---|---|---|---|
| Mapuches | 8 | **8** | Kawiñ resuelto y arreo en el núcleo. No sube por el arreo que se vuelve comida sin caminar. Con el arreo que siempre camina, 9 |
| Guaraníes | 8 | **8** | Dejar crecer o quemar es una decisión linda. Pero hoy es la mejor civ por castillo rápido, y eso a la larga aburre (todos la van a jugar igual). Con la emboscada desde el yerbal, 9 |
| Etiopía | 7 | **8** | La corte que se funda es la mejor mejora de la versión. Baja medio punto por el regimiento roto y la fiesta repetible |
| Palmares | 8 | **7** | Sigue siendo la civ "vikinga", con la liberación de edificios habitados y la fama que se vuelve ejército. Baja por el "en combate" que la expone a hostigamiento barato y porque el motor no tiene decisiones |
| Ayutthaya | 4 | **6** | El elefante le dio riesgo y fuente. Le falta sacar el campamento común y el kraal para tener su momento |
| Tawantinsuyu | 6 | **6** | Mejor sistema (reserva, piso de 1/3, mit'a por runa), misma sensación. Sin cumbi en el núcleo, no hay momento |

---

## 7. Pedidos, en orden

1. **Medir y frenar el castillo rápido guaraní** (10:20). La palanca es la comida de la roza, no la arcilla.
2. **Arreglar la fiesta etíope repetible** y el **centro adelantado gratis** (distancia mínima entre cortes para cobrar la fiesta; corte nueva con menos vida o con costo en el centro).
3. **Devolverle peso al regimiento**: −15 % hasta −30 % desde la edad II, o reposición de jinetes.
4. **Definir "en combate" para los oficios** de modo que un solo arquero de lejos no los apague.
5. **Que el arreo siempre camine**, aunque no haya lugar en el corral.
6. **Sacarle a Ayutthaya el campamento maderero y la mina comunes**, para que el elefante sea el depósito.
7. **Subir al núcleo el regalo de cumbi y la emboscada desde el yerbal.**
8. **Aclarar si la fiesta etíope es núcleo o fase 2**: §3.4 la da por hecha y §8.2 la pone en la fase 2.

**Lo que está muy bien y no tocaría:**
- kawiñ con tope por corral y por edad;
- corte que se funda sin carpa y sin cortar la producción;
- separación mínima en lugar de vecindad oculta;
- reserva de mit'a con piso de 1/3;
- dejar crecer o quemar;
- liberación de edificios habitados con los liberados a pie;
- fama sobrante que paga ejército;
- tope absoluto por minuto de lo disputado, con barra;
- ninguna renta de hito.
