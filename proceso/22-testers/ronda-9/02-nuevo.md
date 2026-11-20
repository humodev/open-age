# Ronda 9 · Jugador nuevo en los RTS

> Perfil: nunca jugué un RTS en serio; me importa entender qué pasa en mi pueblo sin leer un manual.
> Probé el tutorial nuevo, la Guía (G) con sus lecciones, «¿Cómo se usa?», los consejos de la fácil,
> la cola en rojo y los mensajes, la partida contra la fácil, guardar y cargar, y los íconos y cursores
> nuevos. 2026-11-19, `main` en `97f2648`.

## Cómo lo medí
- `tools/primera_victoria.gd -- --seeds=7,21,3 --min=30 --dif=facil` (plan del principiante).
- Mensajes: `--aivai --civ=guaranies --rival=mapuches --dificultad=facil --seed=7 --aprendizaje=si --contar-avisos=20`.
- `tests/guardado.gd`.
- Tres capturas a 1366×768: [tutorial al 1:15](capturas/nuevo-1_tutorial.jpg),
  [lección de muralla con aldeanos elegidos](capturas/nuevo-2_leccion.jpg) y
  [contra la fácil al 5:06](capturas/nuevo-3_consejos.jpg).

## ¿Le sigo ganando a la fácil?
**Sí, y mejor que antes: 2 de 3.**

| Semilla | Resultado | Tropa perdida |
|---|---|---|
| 7 | Gana a las 17:29 (se rinde) | 14 |
| 21 | Sin terminar a las 30:00 | 33 |
| 3 | Gana a las 24:44 (se rinde) | 14 |

En la ronda 7, con las semillas 21 y 7, eran 0 de 2. La 21 sigue dura: hay un solo ataque al minuto 13 y
después no hay plan. A un novato le pasaría lo mismo: no sabe qué hacer cuando el primer ataque no alcanza.

## Qué se entiende
- **Las lecciones de la Guía.** Las tres partes (*qué es*, *cuándo conviene* y *un consejo*) son cortas y
  hablan como una persona («Es cara: no amurallés todo»). Las leí todas sin aburrirme. Me gustan los
  números que salen de las reglas («2 de población militar a N casillas»).
- **El tutorial** ahora cierra el círculo: el sitio sagrado «da riqueza mientras tenga guardia», después
  me pide que ponga 2 guerreros y, al llegar a la II, que compre Armas templadas. El último mensaje me
  manda a la Guía para lo demás. No me deja la sensación de que me faltó media partida.
- **La cola de arriba.** Una casilla por edificio, gris si está quieto y roja si está trabado. Es lo más
  útil que entró para mí: sé que algo anda mal sin abrir nada.
- **Los mensajes, que ahora son menos.** En 20 minutos contra la fácil, con los consejos prendidos, son 55
  (casi 3 por minuto). Los consejos de aprendizaje salieron solo 2 veces (repetición y herrería), así que
  no abruman.
- **Guardar y cargar**: `GUARDADO: OK` en los 8 casos. La carga con foto tarda 0,8 a 1,8 s.
- **Los cursores nuevos** se leen bien. El de atacar, rojo entero, se distingue de un vistazo.

## Qué confunde
1. **La G tiene dos funciones.** La Guía se abre y se cierra con G («Cerrar (G)»), y la lección de muralla dice
   «G pone una puerta». Si estoy colocando la muralla y quiero releer cómo se hacía, ¿qué pasa? No lo sé.
   En el tutorial, Z también es el hito de economía y la campana del centro.
2. **En el tutorial, dos mensajes se pisan** (captura 1, al 1:15). La Guía dice «arrastrá el mouse sobre tus
   aldeanos» y, a la vez, arriba sale «Un edificio de producción sin producir… Ctrl + clic en una unidad:
   se repite sola. Clic derecho en un gris: no avisar más». Me habla de Ctrl + clic y de grises antes de
   que sepa elegir a un aldeano. Además, el cuadro de la Guía tapa a los aldeanos que me pide elegir.
3. **«¿Cómo se usa?» no parece un botón.** Es un textito gris arriba del panel de la selección (captura 3).
   Lo encontré porque lo buscaba. Y con la Guía abierta queda tapado (captura 2).
4. **La lección de muralla aparece siendo guaraní**, que no tiene muralla (captura 2). «¿Cómo se usa?» la
   filtra bien, pero el índice de la Guía muestra las 11 a todos, sin distinguir las que mi pueblo tiene.
5. **Las teclas cambian según lo elegido**, y las lecciones las nombran sueltas: «D los mantiene en el
   lugar» (soldados), pero con aldeanos la D es «Reparar (zona)»; «R y clic en el suelo» (catapulta);
   «F» (escuela). Para un novato cada lección es una tecla más que recordar.
6. **«Se acabó el alimento acá: buscá otra»**: ¿otra qué? Falta la palabra (fuente, mata).
7. **Los avisos de recursos sin gastar** son un tercio de lo que veo: 19 de 55 («Estás juntando riqueza /
   alimento / madera / piedra que no gastás»). Los cuatro juntos parecen un reto. Además, «Autoguardado»
   sale 4 veces como mensaje, y para mí es ruido.
8. **Tres mensajes distintos de población** en poco tiempo («sin lugar en ~N s», «hay más gente que lugar»
   y «Población llena»). Con uno que diga «construí casas» me alcanza.
9. **El índice de lecciones** no marca cuáles ya leí ni cuáles tocan en mi edad. Las 11 tienen el mismo
   peso; la maravilla y la escuela de la IV están al lado de la cola, que uso al minuto 1.

## Qué falta, por gravedad

### Alta (me frena o me hace perder)
- **Después del primer ataque no hay plan.** En la semilla 21 nadie gana en 30 minutos. Ni los consejos ni
  la Guía dicen qué hacer si el ataque no rompe la base: rearmar, traer asedio, cuidar los sitios. Pido
  un consejo de la fácil que diga «tu ataque no alcanzó: juntá más tropa y asedio» después de una derrota
  lejos de casa (el mensaje «Perdiste N soldados lejos de casa» ya existe; le falta el qué hacer).
- **Los mensajes del tutorial no deberían pisarse.** Mientras habla la Guía, los consejos genéricos
  («edificio sin producir») tienen que esperar o no salir.

### Media (me confunde)
- **«¿Cómo se usa?» tiene que parecer un botón**: con marco, ícono «?» y tecla. Y no debe quedar tapado por la Guía.
- **Mostrar en el índice de la Guía solo las lecciones de mi pueblo**, o atenuar las otras, y
  ordenarlas por edad («Edad I: cola, repetición…»).
- **Juntar los cuatro avisos de recursos sin gastar en uno** («Te sobra: alimento 710, riqueza 242 → mercado
  o tropa»). Y sacar «Autoguardado» de los mensajes (que alcance un ícono).
- **La tecla G**: o la puerta va en otra tecla, o la lección aclara que con la muralla en la mano G es la puerta.

### Baja (detalle)
- «Se acabó el alimento acá: buscá otra» → «buscá otra fuente».
- Marcar las lecciones leídas, y que la de la cola se abra sola la primera vez que una casilla se pone roja.
- Los íconos de recurso que flotan sobre los aldeanos (el maíz magenta) llenan la pantalla
  cuando hay 20 trabajando (captura 3). Para mí, menos es más.

## Resumen
El aprendizaje está mucho mejor armado: el tutorial termina con lo que de verdad importa (guardia y
herrería), la Guía tiene lecciones cortas y amables, y la cola de arriba me avisa sin hablar. Lo que más
me molesta es que, cuando por fin me están enseñando algo, otro mensaje me habla de otra cosa, y que
el botón de ayuda del panel no se vea. Gano a la fácil 2 de 3; la que no gano es porque, después del
primer ataque, nadie me dice qué sigue.
