# Paso 6 del juego tardío, primer par: los saberes de los mapuches y los guaraníes

Fecha: 2026-11-17. Etapa 26, **paso 6** del plan de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§3.2, §3.3 y §6).

> Pedido: implementar las mejoras propias y las unidades propias de los dos primeros pueblos que fija el §6. 8 mejoras y 3 unidades por pueblo, según el diseño revisado; las unidades con maquetas procedurales simples y glifo propio en `data/iconos.json`, sin modelos nuevos de Meshy. Cada mejora y unidad lleva en su ficha el saber que la inspira y su nivel de evidencia. Nada sagrado como arma. La grilla en su lugar, la IA que las compra o las entrena con criterio, y medir sin torneo (el orquestador corre el de cierre). Si un pueblo se pasa, bajar números en `data/`, no sacar contenido.

**Qué par:** el §6 fija el orden: «Primero guaraníes y mapuches, después Palmares y Etiopía, y por último incas y Ayutthaya». Este paso hace **mapuches y guaraníes**.

**Consultas:** se usó la opción por defecto de C-67 a C-97. La única que choca con el pedido es **C-80 a)** («las unidades nuevas esperan al arte»): el pedido del orquestador es entrar con maquetas procedurales, y así se hizo (ver Riesgos).

## Qué entró

Todo vive en `data/civs/<pueblo>.json → tecnologias_nuevas` y `unidades_nuevas`, marcado `propia`. Cada uno lleva `desc` (qué hace y el saber) y `evidencia` (nivel y fuente), y la ficha y la ayuda de la casilla los muestran («Saber propio · militar», «Élite de la edad IV», «Evidencia: Documentado…»). Los nombres no usan nada de lo que el diseño marca como sagrado (machi, rewe, kultrun, foye; opy, karai, mbaraka, takuapu): lo revisa `tests/saberes.gd`.

### Mapuches (§3.2)

| Edad | Mejora | Dónde | Qué hace en el juego | Evidencia | Cambio contra el diseño |
|---|---|---|---|---|---|
| II | Coseletes de cuero | ruka de guerra | +1 de armadura contra cuerpo a cuerpo al choque | Documentado (Góngora Marmolejo, González de Nájera) | — |
| II | Trigo y manzana | lof | Granjas +15 % | Documentado (Bengoa, Pinto, Rosales) | — |
| III | Hoyos y estacas | corral | Habilita el **hoyo con estacas** (20 de madera): 40 de daño y 4 s de frenado al que lo pisa, el doble a los montados; el rival lo ve a 2 casillas; se pierde al usarse | Documentado (Góngora Marmolejo, Vivar) | Lo cava el che (el aldeano), no el weichafe: la tropa no construye |
| III | Lawen (remedios) | ruka de guerra | El relevo cura 25 % más | Documentado tardío (Mösbach; Ovalle y Rosales) | El sanador (ampive) todavía no existe (resto del paso 4): la mejora cura por el relevo |
| III | Arreo en tropilla | corral | +1 cabeza arreada por minuto y el corral guarda 25 % más | Documentado (León Solís) | — |
| IV | Makuñ (el poncho) | lof | Cada lof da 4 de riqueza por minuto; lo vendido en el mercado rinde 20 % más | Documentado (León Solís, Villalobos, Bengoa) | No hay «telar del lof»: rinde el lof; sin los agasajos del parlamento |
| IV | Kawellu (remonta propia) | corral | +5 % de vida a los montados; jinete, kona de waiki y weichafe montado −10 % de costo | Documentado (Boccara, Villalobos) | Vida +10 → **+5 %** por el modelo (ver Medidas) |
| IV | Werken y pron | lof | La tropa va 10 % más rápido | Documentado (Boccara; Rosales y Febrés) | Sin el «+5 % de relevo por lof» ni la visión compartida: la niebla no tiene visión por mejora; queda «la junta a tiempo» |

| Edad | Unidad | Qué hace | Evidencia |
|---|---|---|---|
| II | **Weichafe montado** (`infanteria_montada`, en el corral) | Anda a caballo (velocidad 2100, el weichafe 1750) y pelea a pie, como el weichafe; la lanza contra caballería no le hace el extra. Tarda **1 s en desmontar** cuando llega a pelear después de 5 s sin combate. 75 de alimento + 30 de riqueza | Documentado (González de Nájera; Boccara) |
| III | Incendiarios | Ya estaban (paso 4) | Documentado (la quema) |
| IV | **Kona de waiki** (élite, en el corral) | Lancero montado pesado (línea a caballo): +8 contra los montados; la **carga** (primer golpe después de 5 s sin pelear) pega 8 más y frena 1,5 s | Documentado (Ovalle; Rosales) |

### Guaraníes (§3.3)

| Edad | Mejora | Dónde | Qué hace en el juego | Evidencia | Cambio contra el diseño |
|---|---|---|---|---|---|
| II | Kokue (roza en policultivo) | tapyi | Rozas +15 % y 25 % más de duración | Documentado y arqueológico (Montoya; Noelli) | — |
| II | Ygá (canoas) | tapyi | Las tropas cruzan los vados 30 % más rápido; el aldeano que junta a 2 casillas del agua carga 2 más | Documentado (cartas anuas; Furlong) | En el juego el vado no frena: «sin frenar» pasa a «más rápido» |
| III | Pohã ñana (remedios del monte) | aty de guerra | La tropa junto al monte, 6 s sin pelear, sana 1 de vida por segundo | Documentado; la autoría, debatida (Montenegro; Montoya) | Sin sanador todavía: queda la parte del monte |
| III | Óga de takuára | oga guasu | Casas y almacenes −30 % de obra y −20 % de madera; potirõ +2 % por constructor | Documentado (Montoya; Susnik; Noelli) | — |
| III | Defensa de Mbororé | taller de tacuara | Cañón de tacuara +25 % y +1 casilla de alcance; arqueros a 2 casillas del agua +1 de armadura | Documentado (cartas anuas; Furlong; Avellaneda y Quarleri) | — |
| IV | Ka'a plantada (misión) / Ka'a ka'aguy (monte) | el hito de la vía | Yerbales +25 % | Documentado; la germinación, debatida (Garavaglia) | La yerba plantada de C-67 a) todavía no existe como mecánica: las dos versiones dan lo mismo; la ficha dice lo de la encomienda |
| IV | U'y hatã (flecha dura) | campo de tiro | +1 de ataque a la distancia | Documentado (Schmidl; Montoya) | — |
| IV | Imprenta (misión) / Aty (monte) | taller (pide la misión) / hito del monte | Imprenta: −15 % en todas las mejoras. Aty: emboscada +25 % | Documentado (Furlong; Neumann / Susnik; Meliá) | — |

| Edad | Unidad | Qué hace | Evidencia |
|---|---|---|---|
| II | **Ygá (canoa)** (en el tapyi, con agua a 5 casillas) | Solo anda por el agua, lleva 6, sin combate (D-020). Clic derecho de la tropa o los aldeanos sobre la canoa para subir; «Desembarcar» baja en la orilla a 2 casillas o menos. Si se hunde, nadan a la orilla (3 casillas) o se ahogan | Documentado (cartas anuas; Furlong) |
| III | Cañón de tacuara | Ya estaba (paso 4) | Documentado (Mbororé) |
| IV | **Caballería de las misiones** (élite de la vía misión, en el pueblo de misión) | Jinete de lanza: +4 contra la distancia. La ficha nombra a Sepé Tiaraju y dice que la frase es tradición | Documentado (Ganson; Avellaneda y Quarleri); la frase, tradición (Golin) |
| IV | **Ka'aguygua** (élite de la vía monte, en el hito del monte libre) | Choque con +2 de armadura junto al monte | Documentado (Susnik; Meliá) |

La élite de la misión era «a elección» (jinete o milicia de a pie) en el diseño: entra el jinete, porque la milicia de a pie ya está (la milicia arcabucera y el lancero de la misión).

## Código

### Simulación (`src/sim/`, todo entero; mismo hash)
- **`sim.gd`:** los efectos nuevos en `_apply_effects` (`relevo_pct`, `arreo_extra`, `corral_pct`, `renta`, `mercado_venta_pct`, `costo_unidad_pct`, `costo_edificio_pct`, `obra_pct`, `cantidad_pct`, `velocidad_vado_pct`, `carga_rio`, `regen_monte`, `potiro_extra`, `alcance`, `armadura_rio`, `emboscada_pct`, `habilita`); `reach_of` (alcance con mejoras); la carga en `_hit`; el desmonte en `_do_attack`; la armadura del monte y la del río en `effective_armor`; `build_cost` y `train_cost` con los descuentos; `requiere_tec` en `build_block` y `requiere_hito` en `research_block`; `train_block` (la canoa necesita agua).
- **Canoas:** `solid_for` (la canoa solo pisa agua), `_path_for`, `water_tile_near`, `_unload`; subir a una unidad con `guarnicion` (`_cmd_target`, `_do_garrison`, `reglas.canoa.alcance_embarque`); bajar (`_cmd_ungarrison`); hundirse (`_kill`). `sim_map.gd`: una grilla de caminos de agua (`find_boat_path`, `nearest_water`) que se arma la primera vez que se usa.
- **`sim_mods.gd`:** trampas (`traps`, `tick_traps`, solo si hay); el relevo con `relevo_pct` y la cura del monte (`regen_monte`, `in_forest`); la renta por tipo de edificio; la velocidad en el vado; el potirõ; la emboscada; la detección propia del hoyo (`deteccion`); el arreo y el corral con sus mejoras.
- **IA (`sim_ai.gd`):** `_own_buys` (la lista `ia_propias.orden` de cada pueblo con condiciones), `_dig_traps` (los hoyos delante de la base) y las unidades propias primero en `_counter_order` hasta su `max_pct`. Las propias no entran en la compra genérica de lo que sobra.

### Interfaz
- **Ficha y ayuda:** rol «Saber propio · …» o «Élite de la edad IV», la descripción y «Evidencia: …» (`ficha.gd`, `controller.gd`). Los textos de los efectos nuevos (`effects_text`). El costo de entrenar y de construir con los descuentos de las mejoras. La canoa: grilla con «Desembarcar (n/6)» y cursor de subir.
- **Grilla:** el hoyo en la casilla E del menú militar (`interfaz.json`). Las mejoras se repartieron para que ningún edificio pase de 11 investigaciones (el tope del submenú): las de mecánica en el corral, las de la vía en sus hitos o en el taller (la imprenta pide la misión y la de la otra vía no se muestra).
- **Íconos:** 23 glifos propios en `src/game/ui/iconos_saberes.gd` (17 mejoras, 5 unidades y el hoyo), nombrados en `data/iconos.json` (`tipos` y `tecnologias`). Sin símbolos sagrados ni cruces.
- **Maquetas** (`civ_meshes.gd`): la canoa (casco de un tronco con dos remeros), el weichafe a caballo, la lanza larga y el banderín del jinete de las misiones, las ramas del ka'aguygua. `--demo=saberes` arma la escena.

### Herramientas y pruebas
- **`tests/saberes.gd` (nueva):** cantidades por edad, ficha y evidencia, nada sagrado en los nombres, y que cada mejora y unidad haga lo que dice (82 comprobaciones).
- **`tools/saberes_ia.gd` (nueva):** qué compra y entrena la IA, y los hoyos.
- **`tools/modelo_progreso.py --propias`:** tabla 6, lo que suman los saberes propios por edad; lee de `data/` los pueblos que ya los tienen.
- **Documentos:** `docs/05-mecanicas-nucleo.md` (saberes propios) y `docs/08-ia-rival.md`.

## Medidas

MEDIDAS

## Tropiezos

TROPIEZOS

## Riesgos

RIESGOS
