# 6f. Los arietes y la primera victoria contra la fácil

**Pedido** (ronda 7, jugador nuevo, prioridad alta): con su plan (ahorrar en la I, hito a los ~8 min,
taller y arietes, atacar con 15 + 2) ya no le gana a la fácil: 0 de 2, cuando en la ronda 6 eran 3 de 4.
Los honderos le tiran los 10 arietes.

## Qué se midió

`tools/primera_victoria.gd` ahora anota el daño que recibe cada ariete, por atacante: `[daño, golpes]`.

- **Los honderos no tienen ningún bono contra el asedio.** El «ariete» guaraní es el cañón de tacuara
  (140 de vida, 6 de armadura a distancia): cada piedra le saca 1, el daño mínimo, igual que en la ronda 6.
  Semilla 21: 627 golpes de 1. Lo tiran a fuerza de goteo y por eso figuran como los que lo matan.
  `contadores`/`recibe`, el aura C-76, los niveles de asedio, las torres y la fortaleza no cambian
  nada acá: la fácil no tiene torres ni llega a la III.
- Lo que cambió es la pelea: en la ronda 6 los honderos le hacían 59 golpes a los arietes y 332 de daño
  a la tropa, y ahora 627 y 3995. La fácil defiende mejor y el ataque se queda sin escolta.

## Bisección (semilla 21, la misma herramienta en cada commit)

Una sola semilla es muy ruidosa (ed7861e y f6418e3 ganan y 578b1f0 pierde), pero el cambio de
fondo está en el **paso 1 del juego tardío** (f6418e3, integrado en 578b1f0): la tropa dejó de subir
de ataque con la edad (+10 % en la II), y la IA, «en todas las dificultades», se compra lo que lo
reemplaza (`ia_niveles`: la herrería I de ataque cuerpo a cuerpo y a distancia, con `ia_prioridad`).
El principiante no sabe que existe y no la compra. Antes, los dos subían igual con la edad. Ahora
solo sube la fácil, y sus honderos le pegan más fuerte a la tropa que escolta los arietes.

## Arreglo

En data/reglas.json, la fácil lleva `"niveles": false`, y `sim_ai._levels` lo respeta. La fácil
ya no investigaba nada (`investiga: false`); ahora tampoco compra estos niveles. Las demás dificultades
siguen igual.

## Resultado (pruebas/6f-primera-victoria.txt)

| Semilla | Antes | Después |
|---|---|---|
| 7 | sin terminar, 10 arietes perdidos | gana a las 27:59 (rendición), 5 perdidos |
| 21 | sin terminar, 10 perdidos | gana a las 26:26, 6 perdidos |
| 3 | gana a las 24:41 | gana a las 28:08 |
| **Total** | **1 de 3** | **3 de 3** |

## Pruebas

- Determinismo: OK, hash sin cambio (2203695307). La fácil no entra en esa partida o no llega a comprar en sus 3000 ticks.
- Rendimiento (bench): 9,54 ms de promedio.
- asedio.gd y jugabilidad.gd: OK. civ_smoke: sin errores.
- No se tocó el combate, así que no se corrió micro_matriz.

Queda abierto: los arietes siguen muriendo por goteo (1 por piedra) cuando el ataque se estanca.
Esto no cambió desde la ronda 6.
