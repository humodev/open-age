# Jugador de prueba 1, séptima ronda · Veterano competitivo de AoE4

Main en `da4d074`. Ronda corta: el autor está al límite de uso, así que medí con las herramientas y con pocas semillas.

## 1. Qué probé

| Qué | Comando |
|---|---|
| Mi script contra la experta, 40 minutos, boom y ataque al 14. **Nuevo:** compra toda investigación que le alcance con 100 de reserva | `godot --headless --path . -s scratchpad/testers/veterano7/apertura3.gd -- --civ=tawantinsuyu --rival=etiopia --min=40 --plan=boom --ataque=14 --const=4 --dif=experta` |
| Maravilla y final, IA contra IA (6 partidas) | `tools/maravilla_ia.gd -- --minutes=45 --seeds=1` |
| Saberes propios, 3 pueblos (5 partidas cada uno) | `tools/saberes_ia.gd -- --civ=palmares\|mapuches\|ayutthaya --minutes=30 --seeds=1` |
| Bancos de la experta (12 jugadores) | `tools/bancos.gd -- --minutes=25 --seeds=1 --dificultad=experta` |
| Grilla del aldeano y del cuartel en la III | `--demo=base --edad=3 --select=aldeano` y `--select=cuartel --banco=alimento:120,riqueza:40` |
| Batalla | `--demo=batalla --civ=tawantinsuyu --rival=etiopia --shot-at=10` |
| Controles y cierre | `godot --path . -- --autotest --civ=guaranies --terreno=llano` |

Mi script sigue sin micro y sin mercado, y junta poco alimento después del minuto 12. Tómenlo como un jugador flojo de economía, no como la vara.

## 2. Mis pedidos de la ronda 6

| Pedido | Quedó | Cómo lo comprobé |
|---|---|---|
| Consejo de «A y clic» | **Bien** | La hoja de atajos dice «primero a los soldados, después a los aldeanos y a lo que tira flechas» y el resumen de la pelea perdida dice «con A y clic van primero a los soldados» |
| Caída al cerrar (código 134) | **Bien** | El autotest y las tres capturas terminan con código 0 |
| Chequeo del autotest que fallaba de a ratos | **Bien** | 146 de 146, con otros dos Godot corriendo en la máquina |
| Experta: torre en el centro nuevo y ejército según el rival | **Bien** | Contra mí levantó 2 torres y tocó la campana. Mi ataque de 62 unidades al 14:00 no la quebró: tenía 50 aldeanos y a los 16:00 tenía 64. En la ronda 6 la dejaba en 20 |
| Experta en la III | **Sigue** | Edad III a los **18,2 min** de promedio (10 de 12 jugadores, `bancos`). Contra mí, 17:15. Ninguna antes de los 15:00 |
| Ver qué es cada soldado en el montón (Alt) | **Sigue** | §3.5 |

## 3. Lo nuevo

### 3.1 ¿Hay a dónde gastar en cada edad?

- **En la II, sí, y por fin con decisiones.** Mi script compró 10 cosas entre las 5:07 y las 12:09: tala, cantería, las 4 de la herrería, el khipukamayuq, marcha, mampostería y vigías. Es una herrería de verdad: ataque y armadura, cuerpo a cuerpo y a distancia, como en AoE4.
- **Después del 12 se trabó todo, por el alimento.** Herrería, niveles y escuela piden alimento y riqueza. Yo tenía 15 de alimento y 1445 de riqueza, y no compré nada más en 28 minutos.
  - Parte es culpa de mi script: granjas tarde y sin mercado.
  - Pero el patrón es claro: **la madera no tiene a dónde ir en el juego tardío.** Llegué a 17.934 de madera al minuto 35.
  - La experta también, en la IV: gasta por minuto 1648 de alimento y 293 de madera.
  - En AoE4 la madera sigue pidiéndose en asedio, barcos, arqueros y edificios. Acá conviene que la ayuda lo diga: «en la III, pasá aldeanos de la madera a las granjas».
- **En la III y la IV:** niveles veterano y élite (la experta gasta 400–1050 de riqueza en niveles), escuela y maravilla. Sí hay a dónde gastar, siempre que la partida llegue (§3.3).

### 3.2 Costos por recurso: ¿sobra riqueza?

- **Sobra menos.** La experta pasa con 400 o más de riqueza el **54 %** de los minutos de la II. Antes era 71 % y después del ajuste, 59 %.
- **Palmares sigue nadando en riqueza:** 1751 de banco al minuto 25. El mocambo rinde y no tiene dónde gastarla.
- **Lo que falta ahora es alimento.** El banco medio en la II es de 442 de alimento y 492 de riqueza: bien. Pero cuando todo pide alimento, la granja pasa a ser el cuello, como en AoE4. Me parece correcto.
- **El consejo del mercado** (si sobra riqueza, cambiala por alimento) es justo lo que me faltó a mí.

### 3.3 La maravilla y el final: ¿hay partida de 40 minutos?

**Todavía no, en la práctica.** En las 6 partidas de IA contra IA (dificultad normal, 45 minutos):

| Cómo terminó | Partidas | Minuto |
|---|---|---|
| Rendición | 2 | 16:15 y 22:02 |
| Sitios | 2 | 21:11 y 26:10 |
| Conquista | 1 | 18:41 |
| Abierta a los 45 | 1 | Etiopía en la IV a las 23:58, sin maravilla |

- Solo **1 de 12 jugadores** llegó a la IV. Ninguna maravilla puesta. La herramienta del autor midió la IV en el 61 % con 3 semillas; mi semilla salió muy por debajo, así que conviene mirar la dispersión.
- **El problema no es la maravilla, son los sitios:** se gana por sitios a los 21 minutos, antes de que exista la IV.
  - En AoE4 los sitios sagrados aparecen en la III y la cuenta es larga. Si acá se ganan antes de la IV, la maravilla nunca entra en juego.
  - **Pedido:** que la victoria por sitios no se pueda cerrar antes del minuto 25–30, o que su cuenta crezca con la edad.
- **En 30 minutos (`saberes`), 5 de 15 partidas llegan a la IV.** En `bancos`, 2 de 12 jugadores.

### 3.4 Lo propio de cada pueblo

| Pueblo | Mejoras propias que compra la IA (de 8) | Unidades propias |
|---|---|---|
| Palmares | 0 a 4, casi todas después del minuto 20 | zagaieiro (41), guarnição (15). Capitão de mocambo: ninguno |
| Mapuches | 1 a 3. Coseletes en las 5 partidas, desde el minuto 11 | infantería montada (69), incendiarios (10). Kona: ninguno, y ningún hoyo cavado |
| Ayutthaya | 1 a 5. Cerámica en las 5 partidas, desde el minuto 11 | ngao (35). Defensores de Suan Phlu: ninguno |

- **Lo bueno:** las que entran cambian el ejército. El mapuche juega de montado y el palmarino de zagaieiro.
- **Lo malo:** la identidad llega tarde.
  - En AoE4 la tecnología única y la unidad única definen la partida desde la II o la III, entre el minuto 10 y el 15.
  - Acá la mayoría se compra después del 20, y de las 3 unidades propias de cada pueblo, la IA usa 1 o 2.
  - Los galgueros tawantinsuyu, según el paso 6, la IA no los entrena.
- No pude probar a mano si las mejoras «se sienten». Con estos datos, un rival de la IA no ve la mitad del pueblo.

### 3.5 Íconos, color por edad y estados ([captura 1](capturas/veterano/01-grillas-aldeano-cuartel.jpg))

- **Bien:**
  - el ámbar con la cifra que falta en lugar del costo («−30 alimento», «−110 riqueza») se lee de un vistazo;
  - el hito bloqueado, rayado y con candado, se distingue al toque del que solo es caro;
  - los íconos son distintos entre sí y las letras Q W E R / A S D F / Z X C V están en cada casilla.
- **Mal:**
  - **la grilla del cuartel está llena en la III:** 12 de 12, con 2 tropas, 2 niveles, 4 de herrería y 4 propias o generales. ¿Dónde entra lo de la IV, el élite y la tanda 3 de la herrería? Si hay una segunda página, no se ve que exista;
  - la franja del color por edad es una línea de 2 px en el borde izquierdo y casi no se ve. En AoE4 el número romano en la esquina se lee mejor;
  - los nombres se cortan («Cirugía de cráne…», «Choque veterano»).

### 3.6 Soldados animados ([captura 2](capturas/veterano/02-batalla.jpg))

- **De lejos siguen siendo manchas:** el disco de color dice de quién es cada uno, que es lo que más importa.
- En una captura quieta no se juzga el paso, pero las poses ya varían dentro del montón, y eso se agradece.
- **Lancero o guerrero no se distingue** en la zoom de juego. Sigue mi pedido: con Alt, la función sobre la unidad, como ya se hace sobre los techos.

## 4. Pedidos, por gravedad

| Gravedad | Pedido | Por qué |
|---|---|---|
| **Alta** | Que la victoria por sitios no cierre la partida antes de la IV (mínimo de minutos, o cuenta que crece con la edad) | 2 de 6 partidas terminan por sitios a los 21–26 minutos. La maravilla y el juego tardío quedan sin jugarse |
| **Alta** | La experta en la III antes del 15:00 | Sigue en 18 minutos. Es el pedido de las rondas 5 y 6 |
| **Media** | Que la IA compre lo propio antes, entre el 10 y el 15, y use las 3 unidades propias | Capitão, kona, Suan Phlu y galgueros no salen. Sin eso, el rival no ve la identidad del pueblo |
| **Media** | Grilla del cuartel llena en la III: que se vea que hay más (página, o herrería en otro edificio) | 12 de 12 antes de la IV |
| **Media** | Un destino para la madera en la III y la IV, o un consejo de reasignar aldeanos | 17.934 de madera quieta en mi partida; todo lo tardío pide alimento y riqueza |
| Baja | Palmares: dónde gastar la riqueza del mocambo | 1751 de banco al 25 |
| Baja | Color por edad más visible (número romano o franja más gruesa); nombres sin cortar | Captura 1 |
| Baja | Alt muestra la función sobre las unidades | Captura 2. Pedido de la ronda 6 |

## Capturas

1. [Grilla del aldeano y del cuartel, edad III](capturas/veterano/01-grillas-aldeano-cuartel.jpg)
2. [Batalla, Tawantinsuyu contra Etiopía, segundo 10](capturas/veterano/02-batalla.jpg)
3. [Base mapuche en la III, aldeanos elegidos](capturas/veterano/03-base-mapuche-edad3.jpg)
