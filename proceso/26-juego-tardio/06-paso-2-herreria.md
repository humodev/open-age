# Paso 2 del juego tardío: la herrería separada

Fecha: 2026-11-16. Etapa 26, implementación del **paso 2** del plan de entrada de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§1.1 y §6). Sigue al [paso 1](05-paso-1-niveles.md).

> Pedido: la herrería separada como en AoE4. Doce mejoras: ataque cuerpo a cuerpo, ataque a distancia, armadura contra cuerpo a cuerpo y armadura contra distancia, cada una en tres tandas (edades II, III y IV). Reemplazan a las armas y los escudos de hoy sin perder poder total (el modelo, ±2 % por edad). Íconos de glifo y textos. La IA la compra con una prioridad razonable, después de los niveles del paso 1. Números en `data/`.

## Dónde se investiga

El §1.1 del diseño dice: «**Herrería** (en el cuartel; no hace falta un edificio nuevo)». Por eso **no hay edificio nuevo** ni nombre por pueblo: las doce se investigan donde estaban armas y escudos, en el cuartel y en los demás edificios que entrenan tropa (`"en": {"militar": true}`).

Una excepción: no van en los edificios que además son almacén o centro (`sin_deposito`):
- el lof mapuche;
- el mocambo de Palmares;
- la qollqa inca.

La grilla de esos edificios ya está llena de economía. Con cuatro mejoras más, el lof y el mocambo pasaban a 12 investigaciones y el submenú solo tiene lugar para 11 (`tests/casillas.gd` lo marcó). Ahora el lof y el mocambo ya no necesitan submenú. Los tres pueblos tienen la herrería en su cuartel o en su casa de guerra.

## Qué cambió

**Datos** (`data/tecnologias.json`)
- Salen `armas_1..3` y `escudos_1..3`. Entran doce mejoras:

| Grupo | Clave | Nombres (I, II, III) | Efecto por tanda | Ícono |
|---|---|---|---|---|
| Ataque cuerpo a cuerpo | `ataque_cc_N` | Armas templadas, reforzadas, de maestría | +1, +1, +2 de ataque a `choque` y `linea` | `atacar~guerrero~N` |
| Ataque a distancia | `ataque_dist_N` | Proyectiles afinados, reforzados, de maestría | +1, +1, +2 de ataque a `distancia` | `atacar~hondero~N` |
| Armadura contra cuerpo a cuerpo | `armadura_cc_N` | Escudos de cuero, acolchados, de maestría | +1 de armadura contra cuerpo a cuerpo, a las tres funciones militares | `escudo~guerrero~N` |
| Armadura contra distancia | `armadura_dist_N` | Corazas de cuero, acolchadas, de maestría | +1 de armadura contra distancia, a las tres funciones militares | `escudo~hondero~N` |

- **Las cuentas cierran:** comprar las doce da lo mismo que daban armas y escudos. El ataque plano era a las tres funciones: ahora la mitad está en cuerpo a cuerpo y la otra mitad en distancia. Cada escudo de antes subía las dos armaduras: ahora sube una.
- **Clases:** los jinetes y los elefantes son de función `choque`, así que el ataque cuerpo a cuerpo los alcanza. El arcabucero es de función `distancia`.
- **El +10 % del paso 1** (el bono que antes daba gratis la edad II) se reparte entre las dos de ataque I:
  - `ataque_cc_1` lo da a choque, línea y montados;
  - `ataque_dist_1` lo da a distancia y pólvora.

  Las dos tienen `ia_prioridad`.
- **Costos.** Las dos de ataque I juntas cuestan lo que costaba `armas_1` (50 de alimento y 25 de riqueza cada una): son el reemplazo del bono gratis. Las demás cuestan el 60 % de la de antes cada una. Una tanda completa cuesta así un 10 % más (la I) o un 20 % más (la II y la III) que armas y escudos. Las doce, 2490 contra 2100 (+19 %).

| Tanda | Antes (armas + escudos) | Ahora (las cuatro) |
|---|---|---|
| I (edad II) | 100 alimento, 100 madera, 100 riqueza | 100 alimento, 120 madera, 110 riqueza |
| II (edad III) | 200, 200, 300 | 240, 240, 360 |
| III (edad IV) | 300, 300, 500 | 360, 360, 600 |

- **Tiempos:** 25, 30 y 40 s (antes 35, 45 y 60). Son el doble de mejoras en la misma cola del cuartel.
- **Casillas del cuartel:** A S D F (ataque cuerpo a cuerpo, ataque a distancia, armadura cuerpo, armadura distancia), Z los niveles, X marcha y C adiestramiento (antes A S marcha D y adiestramiento F).
- `data/reglas.json` → `ia_niveles.herreria`: `grupos` (2) y `reserva` (100).

**Simulación** (`src/sim/`, todo entero)
- El efecto `armadura` acepta `contra`: `cuerpo` (modificador `armadura_c:<función>`) o `distancia` (`armadura_d:<función>`). Sin `contra`, suma a las dos como antes (`armadura:<función>`). Así siguen andando los hitos y las mejoras de los pueblos.
- `Sim.armor_bonus(pid, función, distancia)`: lo usan `effective_armor` y la ficha.
- `tech_here`: `en.sin_deposito` deja afuera a los edificios con `deposito`.
- **IA** (`sim_ai.gd`):
  - `_levels` compra primero las dos de ataque I (`ia_prioridad`), como antes `armas_1`, y en todas las dificultades.
  - `_smith`, nuevo, va **después de la tropa** y antes de `_research`, y solo en las dificultades que investigan (la fácil no). No compra en un turno en que compró o juntó para un nivel, ni mientras ahorra para el hito. Elige dos grupos:
    1. el ataque de la clase con más tropa propia (cuerpo a cuerpo o distancia);
    2. la armadura contra la clase con más tropa rival a la vista.

    Compra la tanda que falte de cada uno, solo si después le sobra la `reserva` de cada recurso: no junta para la herrería. Los otros dos grupos los compra `_research` con lo que sobra, como cualquier investigación.
  - `grant_age_purchases` no cambia: las misiones que empiezan en la II o más reciben las dos de ataque I (lo mismo que antes `armas_1`) y los niveles de su edad.

**Interfaz** (sin arte nuevo)
- Glifo `base~clase~tanda` (`glyphs.gd`, `_herreria`):
  - el arma (`atacar`) o el escudo;
  - la clase abajo a la derecha (guerrero: cuerpo a cuerpo; hondero: distancia), sobre un círculo oscuro como en los almacenes;
  - la tanda en palotes dorados arriba a la derecha (I, II, III). Los galones de los niveles son otra cosa y no se confunden.
- Textos de los efectos (`Controller.effects_text`):
  - «+1 de ataque de la tropa cuerpo a cuerpo · +10% de ataque de choque a pie, la línea, los montados»;
  - «+1 de armadura de toda la tropa contra distancia».
- Ficha de la unidad: la armadura «cuerpo · distancia» suma cada una lo suyo.
- Capturas:
  - [capturas/06-cuartel-herreria.jpg](capturas/06-cuartel-herreria.jpg): la grilla del cuartel guaraní en la II, con la herrería en A S D F;
  - [capturas/06-ficha-armas.jpg](capturas/06-ficha-armas.jpg) y [capturas/06-ficha-corazas.jpg](capturas/06-ficha-corazas.jpg): las fichas.

**Herramientas y documentos**
- `tools/modelo_progreso.py`:
  - lee la herrería de `data/` («herreria_N» son las cuatro de la tanda N);
  - las armas y los escudos de antes quedan congelados en el modelo (`HERRERIA_ANTES`) para la columna «hoy»;
  - entiende `armadura` con `contra`.
- `tools/niveles_ia.gd`: la columna de `armas_1` pasa a «ataque I (cc, dist)» y suma una columna con cada tanda de la herrería (ac/ad/rc/rd y la tanda).
- `docs/05-mecanicas-nucleo.md`: `armadura` con `contra`, `sin_deposito`, la sección «Herrería» y la IA.

## Medidas

**Modelo** ([pruebas/06-modelo-progreso.txt](pruebas/06-modelo-progreso.txt)). Las tres tablas dan **exactamente los mismos números** que antes del paso 2, con y sin `--vara-fija`: solo cambian los títulos. Δ de la tabla 1, igual que en el paso 1:

| | Δ II | Δ III | Δ IV |
|---|---|---|---|
| Los seis pueblos | 0 % | 0 a −1 % | −1 a −2 % |

Es lo esperable: el gasto típico compra las cuatro de cada tanda y la suma es la misma de antes. Lo que cambia es el **cómo**: quien compra solo el ataque de su clase y la armadura contra la clase rival tiene la mitad de la herrería por algo más de la mitad del costo.

**Micro** ([pruebas/06-micro.txt](pruebas/06-micro.txt) y [pruebas/06-micro-matriz.txt](pruebas/06-micro-matriz.txt)):
- `tests/micro.gd`: **idéntico** al paso 1.
- `micro_matriz --variantes=5` en la II, sin compras y con `--compras` (ahora las dos de ataque I en lugar de `armas_1`): **24 de 24 celdas iguales** al paso 1. **La micro C2 sigue igual:** el kiteo escalonado gana (4/5) y el kiteo malo pierde (0/5).

**La IA compra** ([pruebas/06-niveles-ia.txt](pruebas/06-niveles-ia.txt); `tools/niveles_ia.gd`). 6 partidas por dificultad (12 jugadores), de 40 minutos; la fácil, de 30. Mediana y rango:

| Dificultad | Las dos de ataque I tras la II | 1.er veterano tras la III | 1.ª herrería no prioritaria tras la II | 1.ª de la tanda II tras la III |
|---|---|---|---|---|
| Fácil | 0:55 (0:51–1:45) | — | — (no investiga) | — |
| Normal | 1:08 (0:51–1:36) | 1:45 (0:48–3:21) | 5:16 (1:01–24:19) | 2:31 (1:56–8:05) |
| Difícil | 1:02 (0:53–1:56) | 1:38 (0:58–2:07) | 7:40 (2:21–25:50) | 2:47 (0:53–3:54) |
| Experta | 1:03 (0:40–1:51) | 1:20 (1:00–2:14) | 3:16 (2:23–14:36) | 2:48 (0:39–3:38) |

- La columna de ataque I es **la segunda** de las dos: la primera llega como `armas_1` en el paso 1 (0:42 a 0:54), y la otra unos 25 s después, en la misma cola.
- **Tiempos de edad, en los mismos cruces** (pueblo, rival y dificultad) que en el paso 1. Diferencia de la mediana:

| Dificultad | Llegada a la II | Llegada a la III | Llegaron a la III solo en el paso 1 | Llegaron a la III solo en el paso 2 |
|---|---|---|---|---|
| Normal | +0 s | +13 s | 0 | 3 |
| Difícil | 0 s | −1 s | 2 | 3 |
| Experta | −48 s | −28 s | 1 | 5 |

  Las edades llegan igual y algunos jugadores más llegan a la III.
- **El veterano**, en la normal, llega más tarde que en el paso 1 (1:45 contra 0:55). En la difícil (1:38 contra 1:37) y en la experta (1:20 contra 1:01), casi igual.
- En la II compra primero la armadura (no hay ataque II todavía) y en la III, el ataque de su clase, 2 a 3 minutos después de llegar. La tanda III se ve en los pocos que llegan a la IV (guaraníes en la normal: ad3 y ac3 dos minutos después de la IV).

**Determinismo, bench y humo** ([pruebas/06-determinismo-bench.txt](pruebas/06-determinismo-bench.txt) y [pruebas/06-smoke.txt](pruebas/06-smoke.txt)):
- `test_determinism.gd`: **el hash no cambia** (2203695307). La prueba corre 3000 ticks en la edad I, donde no hay herrería.
- `bench.gd`: 9,0 ms de promedio y 94 de peor tick en la primera corrida. Después, con siete procesos de Godot de otros agentes al mismo tiempo, 12,8 y 126, y 13,5 y 151. El bench no tiene IA ni investigaciones: lo único del paso 2 en su camino es una búsqueda más en `effective_armor`.
- `civ_smoke.gd`, `campaign_smoke.gd`, `jugabilidad.gd` y `casillas.gd` (480 grillas): sin errores.
- **Misiones:** cada jugador que empieza en la II o más trae las dos de ataque I y los mismos niveles que en el paso 1. La lista está en la prueba de humo.
- Autotest con guaraníes en llano: `AUTOTEST: OK`. Al salir, Godot aborta («corrupted size vs. prev_size»), después de terminar el autotest, como en el paso 1.

## Tropiezos

- **La primera versión de la IA** compraba la herrería dentro de `_levels`: antes de la tropa y también mientras ahorraba para el hito. Con la reserva de 100, gastaba en armaduras lo que juntaba para la III.
  - En tres cruces de la normal la III llegó 4 a 10 minutos más tarde: Ayutthaya contra Etiopía, 29:25 contra 18:27; Etiopía contra Guaraníes, 24:29 contra 18:43.
  - Se cortó esa tanda y `_smith` pasó a ir después de la tropa y sin ahorrar para el hito. Las dos tandas están en la prueba.
- `tests/casillas.gd` marcó el lof y el mocambo: 12 investigaciones en un submenú de 11. De ahí `sin_deposito`.
- El nombre «Armas de mano templadas» no entraba en la casilla (la primera captura). Volvieron los nombres de antes, «Armas templadas, reforzadas y de maestría», para el ataque cuerpo a cuerpo.
- `campaign_smoke`: en *Cuatro fraguas* (Palmares 1), el objetivo secundario «protegé a los aldeanos» queda «fallado» a los 3 minutos. En el paso 1 estaba «activo». En la prueba nadie juega del lado del jugador. Con `_smith` apagado en memoria, el objetivo sigue «activo». La columna rival (normal, edad II) compra la armadura contra cuerpo a cuerpo primero en lugar de la de distancia, el resto de sus compras se corre unos segundos y el ataque mata a un aldeano quieto a los 2:48. No es un error del motor de escenarios ni de la misión: es la IA que cambia de minuto.

## Riesgos y lo que queda

- **El torneo lo corre el orquestador:** ±7 puntos por civ contra el torneo 32 y tiempos de edad iguales.
- **Más gasto para el mismo poder:** las doce cuestan un 19 % más que las seis de antes. La IA no compra las doce (dos grupos con prioridad y el resto con lo que sobra), así que en partida puede pelear con algo menos de armadura que antes contra la clase que no ve.
- **La armadura según lo que se ve:** la IA elige la armadura por la tropa rival **a la vista** en ese turno. Sin nada a la vista, compra la de cuerpo a cuerpo.
- **El humano** que compre solo su clase gasta menos y tiene lo que necesita. Es el cambio buscado (decidir), pero el tutorial todavía no lo enseña.
- **Diseño completo** (paso 4): la herrería III de ataque pasa a +1. En `data/` sigue en +2 (lo de hoy). El modelo ya lo simula en la tabla 2.
