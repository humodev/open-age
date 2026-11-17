# 29 · Resumen de lo hecho desde el corte de uso (2026-11-16 y 17)

> Pedido del autor: "Cuando todo lo que está corriendo termine hacé un resumen de todo y dejalo en el progreso."

El corte de uso frenó tres agentes a mitad de su tarea, y se retomaron desde donde estaban. Desde entonces entraron 34 commits, en 12 frentes, todos con sus pruebas. El detalle de cada frente está en su documento; acá va lo esencial.

## 1. Errores e IA

| Frente | Qué se hizo | Resultado | Detalle |
|---|---|---|---|
| **Recurso inalcanzable** (6c) | Un aldeano mandado a comida encerrada entre árboles se deslizaba contra ellos sin contar como trabado, y se quedaba ahí para siempre. Ahora, si el camino no llega, ese recurso queda anotado como inalcanzable para ese jugador y el aldeano busca otro del mismo tipo. Afectaba a todas las dificultades y al jugador | En una semilla, la IA normal tenía los 21 aldeanos del alimento parados y no salía de la edad I. Ahora: edad II y el triple de recolectado. Prueba nueva en `jugabilidad` | [6c](../24-tras-la-segunda-ronda/6c-recurso-inalcanzable.md) |
| **IA experta: edades y defensa** (6b) | 8 constructores en el hito, ejército mínimo según el rival que ve, una torre en cada centro nuevo y campana en los centros | Edad II a los 7:23 en promedio (antes, 9:25). Llegan a la III en 20 minutos el doble de expertas. Aguanta el primer ataque del veterano, no el segundo. **La III antes de los 15:00 sigue sin cumplirse** | [6b](../24-tras-la-segunda-ronda/6b-experta-edades-y-defensa.md) |

## 2. Balance: dos diagnósticos con causa encontrada

Método nuevo (`tools/civ_diag.gd`): repite los mismos 50 cruces del torneo de una civ y prueba variantes con dosis creciente. Encontró la causa en los dos casos en que seis ajustes a ciegas no habían movido nada.

| Pueblo | Causa | Ajuste | Efecto |
|---|---|---|---|
| **Guaraníes** (5e) | La casa del arco costaba 100 de madera (el campo de tiro común, 150) y era más chica. La IA levantaba 5 y tenía el doble de ejército desde el minuto 15. El sigilo y la emboscada pesaban el 0,3 % del daño | Casa del arco a 150; sigue de 2×2 porque se levanta en el monte | 76 → 44 % |
| **Mapuches** (5f) | El weichafe rápido (1750) y barato (55/20) desde la edad I: el rival pierde 26 aldeanos por partida. La riqueza del ganado paga la herrería, que ahora se paga en riqueza | Weichafe al costo común (60/25). Sigue rápido, porque esa es su identidad | 70 → 58 % (torneo 36) |

## 3. Juego tardío (etapa 26): pasos 1 a 4 de 7

| Paso | Qué entró |
|---|---|
| 1 · Niveles | Sin bono de ataque gratis por edad: la tropa compra los niveles veterano (III) y élite (IV) de su línea. La IA los compra cerca de un minuto después de subir |
| 2 · Herrería | 12 mejoras al estilo AoE4: ataque cuerpo a cuerpo y a distancia, y armadura contra cada uno, en 3 tandas. Reemplazan a armas y escudos con el mismo poder total |
| 3 · Economía y escuela de la IV | Velocidad y vida del aldeano, tercera tanda de tala, granja y carga, y sitios que rinden +50 % en la IV. La escuela de cada pueblo (Yachaywasi, Trawün de los weupife, Escritura del cabildo, Talleres de Gondar, Oficinas do Macaco, Phra Khlang) con «los registros» propios (khipu, pron, actas, Ṣäḥafe tə'əzaz, memoria de los mocambos, Chindamani) |
| 4 · Asedio y fortaleza | Asedio sin bono por edad. Asedio de área en la III con forma por pueblo: hondero de piedra caliente, cañón de tacuara, pieza ligera, cañón de muralla, e incendiarios mapuches contra la madera; Palmares, sin asedio. Fortaleza de la III por pueblo, mejoras de defensa, y hitos militares con aura |

- **Torneo del hito (34):** todas entre 42 y 60 %, la banda más pareja hasta ahora.
- **Queda pendiente:** la edad IV aparece poco (5 a 7 de 150 partidas). Lo resuelven el paso 7 (maravilla y final) y que la IA quiera subir.
- **Pasos 5 a 7:** unidades compartidas nuevas (necesitan arte), lo propio de cada pueblo de a dos, y maravilla y final.

## 4. Costos por recurso (pedido del autor: "acumulo riqueza…")

- **Lo que midió el veterano de AoE4:** en la II había 400 o más de riqueza quieta el 71 % del tiempo, porque la herrería y las mejoras militares pedían casi nada de riqueza y se pagaban con madera.
- **Lo que cambió:** pasaron a riqueza y alimento, como el oro en AoE4, con el mismo tiempo de aldeano.
- **Resultado:** la riqueza queda quieta el 59 % del tiempo, y la III llega antes en 4 de 6 pueblos.
- **Su consejo:** si sobra riqueza en la II, cambiala por alimento en el mercado.

Detalle en [09](../26-juego-tardio/09-costos-por-recurso.md).

## 5. Interfaz y arte

| Frente | Qué se hizo |
|---|---|
| **Íconos y estados** (etapa 28) | 69 íconos propios, sin repetidos en una grilla, que se pueden cambiar por imágenes desde `data/iconos.json`. Un color por edad (violeta, pizarra, verde y celeste), legible para daltónicos. Estados de color en lugar del candado: ámbar si falta recurso, oscurecido y rayado si está bloqueado, tilde, cola y población. En la ayuda flotante, el rojo queda solo para lo que bloquea; antes no se refrescaba después de juntar o subir de edad |
| **Aldeanos animados** (etapa 27) | Esqueleto y animaciones de KayKit (CC0), con la ropa y las herramientas de cada pueblo: 10 estados, y el paso no patina. Cuesta +1 a 1,5 ms con 200 aldeanos. Se vuelve a la figura anterior con `--animaciones=0`. De lejos se ven más claros que los de Meshy (C-98) |

## 6. Forma de trabajo

- **Torneo por hito, no por cambio** (pedido del autor): se ajusta con herramientas dirigidas y se confirma con un torneo de 10 semillas al cerrar cada hito.
- **Implementación en paralelo:** los pasos 2, 3 y 4 se hicieron a la vez, cada uno en su copia del repositorio.

## Torneos de este período (10 semillas, 150 partidas)

| Torneo | Cambio | Taw. | Map. | Gua. | Eti. | Pal. | Ayu. |
|---|---|---|---|---|---|---|---|
| 30 | Antes del corte | 42 | 66 | 76 | 38 | 46 | 32 |
| 31 | Recurso inalcanzable | 48 | 60 | 72 | 36 | 52 | 32 |
| 32 | Paso 1 (niveles) | 50 | 64 | 70 | 36 | 40 | 40 |
| 33 | Casa del arco guaraní | 54 | 70 | 44 | 44 | 46 | 42 |
| 34 | Pasos 2 a 4 | 52 | 60 | 42 | 46 | 58 | 42 |
| 35 | Costos por recurso | 52 | 70 | 48 | 34 | 58 | 38 |
| [36](../24-tras-la-segunda-ronda/pruebas/36-torneo-weichafe.txt) | Weichafe al costo común | 56 | 58 | 48 | 38 | 60 | 40 |

**Cierre:** las seis civs quedan entre 38 y 60 %, con todo lo nuevo junto. Ninguna supera la banda.

## Consultas abiertas para el autor

- **C-98:** aspecto de los aldeanos animados. Opciones: a) seguir animados y riggear los modelos de Meshy; b) volver a Meshy quietos; c) colores más terrosos ya. Por defecto, a + c. También: ¿un tono de piel por pueblo? ¿Riggear los aldeanos de Meshy antes que los soldados?
- **Siguen abiertas de antes:** C-66 (huellas de 5×5), C-67 a C-97 (las de los historiadores) y las consultas a comunidades antes de publicar.

## Qué sigue

1. **Paso 7 (maravilla y final):** que se llegue a la IV.
2. **Paso 6:** lo propio de cada pueblo, de a dos.
3. **Animaciones de soldados:** combate, arma y escudo; caballos y elefantes aparte.
4. **Ronda de jugadores** con todo lo nuevo.
5. **Pendientes chicos:**
   - el cierre de Godot que aborta al salir;
   - el objetivo «protegé a los aldeanos» de Palmares 1, que ahora falla en la prueba de humo;
   - la experta en la III antes de los 15:00.
