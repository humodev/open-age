# Paso 1 del juego tardío: niveles veterano y élite en lugar del bono por edad

Fecha: 2026-11-16. Etapa 26, implementación del **paso 1** del plan de entrada de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§1.1, §1.2 y §6). Consulta C-77 sin respuesta: va por defecto (a), arrancar por acá.

> Pedido: sacar el bono automático de ataque por edad de las **unidades** (los edificios conservan el suyo) y devolver ese poder en el mismo cambio, con cosas que se compran: la herrería I con +10 %, el nivel veterano en la III y el élite en la IV, por línea, en el edificio que entrena la línea. Íconos de glifo y textos en la ficha. La IA de todas las dificultades los compra a tiempo. Medir con el modelo, la micro y partidas.

## Qué cambió

**Datos**
- `data/edades.json`: `bono_ataque` → `bono_ataque_edificio` (0, 10, 20 y 35 %), y `bono_ataque_asedio` con los mismos valores (ver «Decisiones»).
- `data/tecnologias.json`:
  - `armas_1` suma, además de su +1, `ataque_pct` +10 % a las cinco líneas, y lleva `ia_prioridad`.
  - 10 niveles: `veterano_<línea>` (III, 150 de alimento y 150 de riqueza, 45 s; +5 % de ataque y +5 % de vida) y `elite_<línea>` (IV, requiere el veterano; 300 y 300, 60 s; +10 % de ataque y +5 % de vida). Líneas: `choque`, `distancia`, `linea`, `montados` y `polvora`.
  - Se investigan con `"en": {"linea": …}`: en **cualquier edificio que entrene esa línea**. Por ejemplo, Etiopía tiene los montados en el establo y en la remonta.
- `data/reglas.json` → `ia_niveles`: `lineas_primero` (2), `tropa_minima` (2), `ahorrando` y `junta`.

**Simulación** (`src/sim/`, todo entero)
- `SimData.line_of(def)`: la línea sale de `polvora`, después `montado` o `elefante`, y si no, de la función. El asedio y los civiles no tienen línea.
- `SimData.lines_made_by(edificio)`. Al fusionar un pueblo, se borran los niveles de las líneas que no entrena en ningún edificio. Quedan así:
  - guaraníes: sin montados;
  - Etiopía: sin choque (su guerrero es montado);
  - mapuches: sin pólvora;
  - Palmares: sin montados;
  - pueblos solo de IA del Tawantinsuyu: choque, distancia y línea.
- `Sim.effective_attack` = `(ataque + mejoras planas) × (100 + attack_pct) / 100`:
  - `attack_pct` de un edificio y del asedio sale de la edad;
  - el de la tropa, de `atk_pct:<línea>` (efecto nuevo `ataque_pct`).
- `vida_pct` también acepta `lineas` (`vida_l:<línea>` en `_apply_stats`).
- `Sim.line_level(pid, def)` para la interfaz.
- `Sim.grant_age_purchases(pid, edad)`: da `armas_1` y los niveles hasta esa edad.
  - Lo usa `SimScenario` para el jugador y los rivales que empiezan una misión en la II o más: así las misiones quedan como antes.
  - Lo usa `micro_matriz --compras`.
- **IA** (`sim_ai.gd`, `_levels`), antes de la tropa y en **todas** las dificultades, también en la fácil, que no investiga otra cosa:
  1. compra lo que tiene `ia_prioridad` (`armas_1`);
  2. después, los niveles de las dos líneas con más tropa: primero los veteranos, después los élites;
  3. sin tropa, toma las líneas que más edificios entrenan.

  Una compra por turno. El costo queda apartado hasta el final del turno, porque la orden se paga en el tick siguiente.

  Si todavía no alcanza, **junta**: aparta lo que ya tiene de ese costo para que la tropa no lo gaste, salvo con la base atacada. El resto de los niveles los compra `_research` cuando sobra, como cualquier investigación.

**Interfaz** (sin arte nuevo)
- Glifo `línea^n` (`glyphs.gd`): el glifo de la línea (guerrero, hondero, lancero, jinete, arcabuz) con uno o dos galones dorados.
- Panel de la unidad: «Choque · Veterano» junto a la función. El ataque es el de verdad (13 para un guerrero veterano con `armas_1`).
- Ficha de la unidad: renglón «Nivel», con el nivel y la línea, y el porcentaje en el ataque. La ficha de un edificio muestra su porcentaje por edad.
- Texto de los efectos: «+5% de ataque de la tropa de choque a pie · +5% de vida de la tropa de choque a pie», y «de toda la tropa» en `armas_1`.
- Texto de la edad: la III y la IV dicen «Nivel veterano (élite) para cada línea, en el edificio que la entrena». El porcentaje por edad ahora dice «Ataque de edificios y asedio +N %».
- Capturas:
  - [capturas/05-cuartel-niveles.jpg](capturas/05-cuartel-niveles.jpg): el cuartel guaraní en la III de *Esta tierra tiene dueño*, con el élite de choque y el de línea en Z y X, bloqueados hasta la IV;
  - [capturas/05-guerrero-veterano.jpg](capturas/05-guerrero-veterano.jpg): el panel del guerrero.

**Herramientas y documentos**
- `tools/modelo_progreso.py` lee el paso 1 de `data/` (antes estaba en `PROPUESTA`). «Hoy» es el bono que conservan los edificios y las mejoras sin `ataque_pct`.
- `tools/modelo_micro.py` ya no suma el bono a la tropa.
- `tools/micro_matriz.gd` suma `--compras`.
- Nuevo `tools/niveles_ia.gd`: minuto de cada edad, de `armas_1` y de cada nivel en partidas IA contra IA.
- `tests/jugabilidad.gd`: la sonda de «toda tecnología tiene dónde investigarse» mira las unidades del pueblo para los niveles.
- `docs/05-mecanicas-nucleo.md`: efecto `ataque_pct`, `vida_pct` por línea, «Niveles por línea», la fórmula del ataque y las edades.

## Decisiones

- **El asedio conserva el bono por edad** (`bono_ataque_asedio`, igual al de los edificios). El diseño no le da niveles al asedio hasta el paso 4. Sin el bono, el ariete tiraría edificios un 26 % más lento en la IV y las partidas se alargarían por un efecto que el modelo no mide. Queda en `data/`: si el autor lo quiere sacar, se pone en 0.
- **Las misiones dan lo que daba la edad.** En 15 de las 25 misiones alguien empieza en la II o más. `grant_age_purchases` les da `armas_1` y los niveles de su edad: es lo mismo que antes y un +1 de ataque más. La lista por misión está en [pruebas/05-smoke.txt](pruebas/05-smoke.txt).
- **La IA junta para el nivel.** La primera versión compraba solo cuando ya alcanzaba. La tropa que cuesta riqueza la gastaba antes de llegar a 150, y el primer veterano tardaba una mediana de 1:44 a 2:33 después de la III, con casos de 6:38. Juntando, queda en 0:55 a 1:37. El caso de 9:45 es Etiopía, que perdió su centro.

## Medidas

**Modelo** ([pruebas/05-modelo-progreso.txt](pruebas/05-modelo-progreso.txt)). Leyendo `data/`, la tabla 1 da **lo mismo que el diseño**:

| | Δ II | Δ III | Δ IV |
|---|---|---|---|
| Los seis pueblos | 0 % | 0 a −1 % | −1 a −2 % |

Con la vara fija, 0 % en todas las celdas.

**Micro** ([pruebas/05-micro.txt](pruebas/05-micro.txt) y [pruebas/05-micro-matriz.txt](pruebas/05-micro-matriz.txt)):
- `tests/micro.gd` sale **idéntico**: las peleas son de la edad I y en la retirada el jugador 0 no pega.
- `micro_matriz` en la II, comparada con antes:
  - **sin compras:** cambian solo las peleas con guerrero, porque el guerrero de la II pierde 1 de ataque (12 → 11). En las demás, el hondero (7) y el lancero (8) redondean igual con y sin el 10 %. La mezcla de lancero y hondero contra guerreros pasa de 4/5 a 5/5. Guerrero contra guerrero (espejo) pasa de 4/5 a 3/5. Guerrero y hondero contra lancero y hondero, de 5/5 a 3/5;
  - **con compras** (`armas_1` en los dos bandos): el ganador es el mismo en 22 de los 24 casos. Los dos que cambian son espejos o casi espejos: guerrero contra guerrero, de 4/5 a 2/5, y mezcla contra honderos, de 5/5 a 4/5. **La micro C2 sigue igual:** el kiteo escalonado sigue ganando (4/5) y el kiteo malo sigue perdiendo (0/5).

**La IA compra** ([pruebas/05-niveles-ia.txt](pruebas/05-niveles-ia.txt); `tools/niveles_ia.gd`). 6 partidas por dificultad, 12 jugadores, de 40 minutos (la fácil, de 30). Mediana y rango:

| Dificultad | `armas_1` después de llegar a la II | 1.er veterano después de la III | Llegó a la III sin veterano | 1.er élite después de la IV |
|---|---|---|---|---|
| Fácil (tope en la II; 30 min) | 0:42 (0:36–1:17) | — | — | — |
| Normal | 0:54 (0:30–1:40) | 0:55 (0:46–3:01) | 1 de 8 | 1:01 (n = 1) |
| Difícil | 0:51 (0:30–1:53) | 1:37 (0:48–9:45) | 0 de 8 | 1:49 (1:10–1:49, n = 2) |
| Experta | 0:53 (0:29–1:12) | 1:01 (0:45–1:53) | 1 de 7 | — (ninguna llegó a la IV en 40 min) |

- Compra primero las dos líneas con más tropa (casi siempre distancia y choque) y en uno a tres minutos, la tercera.
- Los que no tienen veterano al final llegaron a la III y perdieron la base enseguida (Etiopía contra Guaraníes, mapuches experta).
- El élite llega uno o dos minutos después de la IV.

**Determinismo, bench y humo** ([pruebas/05-determinismo-bench.txt](pruebas/05-determinismo-bench.txt) y [pruebas/05-smoke.txt](pruebas/05-smoke.txt)):
- `test_determinism.gd`: **el hash no cambia** (2203695307). La prueba corre 3000 ticks en la edad I, donde no hay bono ni niveles.
- `bench.gd`: promedio de 11,7 ms y peor tick de 111 ms con 200 unidades (presupuesto: 100 ms). Es el mismo orden que antes del cambio: el peor tick suele pasar el presupuesto en esta máquina con el torneo corriendo al lado.
- `civ_smoke.gd`, `campaign_smoke.gd` y `jugabilidad.gd`: sin errores.
- Autotest con guaraníes en llano: `AUTOTEST: OK`. Al salir, Godot aborta («corrupted size vs. prev_size»), después de terminar el autotest.

## Tropiezos

- La primera prueba con `pgrep -f niveles_ia` se esperaba a sí misma: el `until` llevaba el mismo texto. Se ancló con `^godot`.
- En una partida, Etiopía pasó diez minutos sin comprar nada en la III. No era la compra: había perdido el centro y la IA no piensa la economía sin centro (`think` vuelve al principio).
- La captura con `--select` elige todos los del tipo, y la misión no trae cuartel. Para las dos capturas se cambió `main.gd` en local (elegir uno y levantar un cuartel); ese cambio se revirtió y no está en el commit.

## Riesgos y lo que queda

- **El torneo lo corre el orquestador** (±7 puntos por civ contra el anterior y tiempos de edad iguales).
  - La IA ahora aparta 100 + 50 en la II, 150 + 150 por veterano y 300 + 300 por élite. En las partidas de prueba la III llegó a la misma hora o antes (mediana normal 16:53 contra 19:02 de la primera versión), pero son 12 jugadores por dificultad.
- **El jugador humano** que no compra los niveles pelea con 8–9 % menos en la III y ~20 % menos en la IV (modelo). Es el cambio buscado, pero el tutorial no lo enseña todavía.
- **El asedio sigue con bono por edad** (decisión de arriba): conviene una consulta al autor.
- **Las misiones** dan un +1 de ataque más que antes (por `armas_1`) a todos los que empiezan en la II o más.
