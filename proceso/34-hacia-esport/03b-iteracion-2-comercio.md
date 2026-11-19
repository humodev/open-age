# Iteración 2 · frente 2b: bloqueo de rutas y comercio en el 1v1

En la iteración 1, la revisión de los expertos encontró que el bloqueo de rutas no se activaba nunca (0 en 20 partidas) y que el comercio llegaba tarde al 1v1. El agente cerró el código (commits 0f72aaa y d4a9d4b). Las medidas finales las corrió el orquestador, porque al agente lo cortaban antes de terminar.

## Qué cambió

- **Corte de ruta:** basta con 3 o más de población militar enemiga, sin tropa propia ni aliada, a 8 casillas del mercado de destino o a 6 del comerciante que va de ida (`reglas.comercio.bloqueo`).
- **El comerciante espera:** se queda fuera del corte y retoma cuando se libera. A los 120 s sin que se libere, vuelve vacío.
- **Aviso:** con el lugar del corte, uno por ruta cada `aviso_ms`.
- **IA:**
  - corta con montados en el mercado neutral de la ruta rival, y le alcanza con ver 3 comerciantes;
  - si un comerciante suyo espera, manda tropa a despejar (`ia_comercio.despeja`).
- **1v1:**
  - comerciante desde la II al 40 % (`comercio.uno_contra_uno`), y en equipos desde la III;
  - tope de la IA por edad de [0, 2, 3, 4];
  - hasta 2 comerciantes aunque ahorre para el hito, solo si el rival le lleva edad.

## Medidas (experta, llano)

| Partida | Comercio en la riqueza | Cortes | Comerciantes muertos |
|---|---|---|---|
| 1v1, semilla 7, antes del minuto 25 | 7 % (meta ≤ 15 %) | 6 cortes y 14 esperas | 0 |
| 1v1, semilla 11, antes del minuto 23 | 6 % (meta ≤ 15 %) | 0 | 0 |
| 2v2, semilla 3, del minuto 30 al 45 | 28 % (meta 30–45 %) | 23 cortes y 50 esperas | 30 |

- **El bloqueo ya funciona.** En la iteración 1 hubo 0 cortes en 20 partidas; ahora hay 23 en un solo 2v2.
- **El 1v1 queda dentro de la meta en las dos semillas.** La semilla 11, que antes daba 18 %, ahora da 6 %, porque el último cambio limitó los 2 comerciantes de la IA al que va atrás en edad. No hizo falta tocar `por_edad_1v1`.
- **El 2v2 queda en 28 %,** dos puntos debajo de la meta, con mucha más pelea por las rutas. Se revisa en la próxima ronda de los expertos.
- **Primera victoria** (8 semillas, sin el frente 2a): 7 de 8.

## Pruebas

Determinismo, comercio (con casos de corte, espera, retoma y despeje), equidad y equipos: OK. El hash, con todo lo de la iteración 2, es 366120853.
