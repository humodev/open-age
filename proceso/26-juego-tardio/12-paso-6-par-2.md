# Paso 6 del juego tardío, segundo par: los saberes de Etiopía y Palmares

Fecha: 2026-11-17. Etapa 26, **paso 6** del plan de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§3.4, §3.5 y §6).

> Pedido: el segundo par según el orden del §6 («Primero guaraníes y mapuches, después Palmares y Etiopía»). 8 mejoras y 3 unidades por pueblo, con su saber y su nivel de evidencia en la ficha; nada sagrado como arma; maquetas procedurales y glifo propio; la IA las compra o las entrena con `ia_propias`. Mismo patrón que el par 1 ([11-paso-6-par-1.md](11-paso-6-par-1.md)).

## Qué entró

Todo en `data/civs/<pueblo>.json → tecnologias_nuevas`, `unidades_nuevas` e `ia_propias`, marcado `propia`, con `desc` y `evidencia`. `tests/saberes.gd` suma a la lista de lo prohibido en los nombres: tabot, kebero, Lalibela, iglesia, calundu, nganga, kimbanda, capoeira.

### Etiopía (§3.4)

| Edad | Mejora | Dónde | Qué hace en el juego | Evidencia | Cambio contra el diseño |
|---|---|---|---|---|---|
| II | Maresha y ṭef | granero | Granjas +15 % | Documentado y arqueológico | Sin lo de la altura ni el gotära al mudarse |
| II | Actas de tierra en ge'ez | gult | El gult rinde 15 % más | Documentado | Sin «no deja de cobrar mientras la corte se muda» |
| III | Fäws y kosso | cuartel | El relevo cura 25 % más | Documentado (XVIII–XIX); debatido antes | Sin wägešša (resto del paso 4) ni la cura junto a la corte |
| III | Cota de malla | establo | +1 de armadura contra cuerpo a cuerpo al choque | Documentado | — |
| III | Amba | corte | La defensa en altura sube de 25 a 35 % | Documentado | Sin el tesoro de 400 que no se saquea |
| IV | Caravanas de amole | mercado | Lo vendido rinde 20 % más | Documentado | No hay comerciante que camine todavía (paso 7): rinde el mercado |
| IV | Pólvora de Massawa | mercado | +10 % de ataque a la pólvora **solo con un mercado propio en pie** (la ruta abierta) | Documentado (la importación) | La ruta es el mercado, sin el comerciante |
| IV | Orden del kätäma | corte | La corte nueva se arma en la mitad del tiempo | Documentado | — |

| Edad | Unidad | Qué hace | Evidencia |
|---|---|---|---|
| II | **Guerrero de gaša** (cuartel) | Choque a pie: la jabalina al cerrar (el primer golpe después de 5 s sin pelear pega 6 más) y +1 de armadura a distancia por el escudo. El šotäl, solo en la ficha (debatido) | Documentado |
| III | **Färäsäñña con cota** (establo) | Montado pesado: 220 de vida, armadura 3 | Documentado |
| IV | **Caballería de la corte** (élite, establo) | Montado rápido (2500), +6 contra la distancia | Documentado |

La élite del diseño son los **jinetes oromo aliados por tratado**. El diseño mismo dice: «consultar a académicos y comunidades oromo; si no, "Caballería de la corte"». Entra el nombre de reserva y se entrena: el tratado (riqueza al firmar, se rompe si se ataca un sitio aliado) queda para cuando se haga la consulta.

### Palmares (§3.5)

| Edad | Mejora | Dónde | Qué hace en el juego | Evidencia | Cambio contra el diseño |
|---|---|---|---|---|---|
| II | Roças e palmeiras | granero | Granjas +15 % y cada mocambo da 4 de riqueza por minuto | Documentado; la continuidad, debatida | Por mocambo, no por palmera junto al mocambo |
| II | Aviso de los mocambos | centro | Los mocambos ven 3 casillas más | Documentado | Sin el aviso a 10 casillas: queda la vista (la visión ya es compartida entre lo propio) |
| III | Forja de los mocambos | mocambo | Oficios +25 % y estrepes +50 % | Arqueológico (la técnica); documentado (Palmares); debatido (la herencia) | — |
| III | Sanguar | cuartel | La gente de guerra y los zagaieiros reciben 15 % menos de la distancia mientras se mueven | Documentado en Angola; debatido en Palmares | — |
| III | Kilombo | mocambo de guerra | De cada 4 que llegan por la fama, 1 entra como gente de guerra | Debatido | Se investiga en el mocambo de guerra (así «si hay un mocambo de guerra» vale solo) |
| IV | Trato con los moradores | mercado | Lo vendido rinde 40 % más (casi sin comisión) | Documentado | Sin comerciante (paso 7) |
| IV | Hierro de Angola Janga | mocambo | +1 de ataque al choque | Documentado / debatido (el volumen) | — |
| IV | Fojos e estrepes | mocambo | Estrepes +50 % y habilita el **fojo** (el mismo tipo `hoyo` de los mapuches: 40 de daño, el doble a los montados, frena 4 s, se ve a 2 casillas) | Documentado | Lo cava el aldeano, como el hoyo mapuche |

| Edad | Unidad | Qué hace | Evidencia |
|---|---|---|---|
| II | **Zagaieiro** (cuartel) | Tiro corto (3 casillas), +2 contra el choque | Documentado (las lanzas); a verificar la palabra |
| III | **Guarnição da cerca** (cuartel) | Línea con +2 de armadura a 3 casillas de una cerca, puerta o baluarte propios | Documentado |
| IV | **Capitão de mocambo** (élite, cuartel) | Choque con mando: la tropa propia a 5 casillas pega 1 más | Documentado |

El diseño dice que el zagaieiro «arroja la lanza y después pelea con ella»: entra como tirador de tiro corto, sin el cambio de modo.

## Código

- **`sim.gd`:** efectos nuevos en `_apply_effects` (`oficios_pct`, `espinas_pct`, `altura_pct`, `renta_pct`, `esquiva_pct`, `ataque_ruta_pct`, `kilombo`, `vision_edificio`); la pólvora con la ruta en `attack_pct`; las espinas con su porcentaje en `_hit`; la armadura junto a la cerca en `effective_armor`; el mando en `effective_attack`.
- **`sim_mods.gd`:** la ruta abierta cada segundo (`_has_built`), la renta del gult con su porcentaje, el kilombo en `_welcome`, los oficios, la amba en `damage`, el sanguar (`dodge`, solo para quien tiene oficios), `near_wall` y `_command_aura` (el mando, cada segundo, solo si hay capitães).
- **`sim_fog.gd`:** `vision_extra` por dueño y tipo de edificio.
- **IA:** solo datos (`ia_propias.orden`, `unidades` y `trampas` de Palmares, que cava fojos con el mismo `_dig_traps`).
- **Interfaz:** los textos de los efectos nuevos (`controller.gd`; `obra_pct` ahora nombra los edificios). 22 glifos nuevos en `iconos_saberes.gd` (16 mejoras y 6 unidades), sin cruces, iglesias ni símbolos religiosos. Maquetas en `civ_meshes.gd`: el escudo redondo de la gaša, la cota gris, las zagaias a la espalda, la estaca de la guarnição y el banderín liso del capitão.
- **Grilla:** el cuartel de Palmares llegaba a 13 investigaciones y el mocambo a 12; el hierro y los fojos van al mocambo y el aviso a la capital.

## Medidas

- **`tools/civ_diag.gd --seeds=6`** (30 partidas por pueblo, 30 min; «sin» = `--set="<civ>/ia_propias/orden=[];<civ>/ia_propias/unidades=[]"`; [pruebas/12-civ-diag.txt](pruebas/12-civ-diag.txt)):
  - **Etiopía: 11 → 11 de 30 (36 %).** Las propias no la mueven; compra poco (maresha y actas en 6 partidas, el resto casi nunca) porque llega tarde a la III y la IV.
  - **Palmares: 21 → 17 de 30 (70 → 56 %).** La primera corrida dio 19 (63 %, sobre el tope de 62): se bajó la renta de las roças por mocambo de 6 a 4 y el zagaieiro pasó de 10 a 20 de riqueza. Pierde 4 contra la base, justo el límite: el zagaieiro y la guarnição le sacan honderos y gente de guerra a la mezcla. La base ya estaba en 70 %, por encima del tope.
- **Pruebas** ([pruebas/12-pruebas.txt](pruebas/12-pruebas.txt)): `test_determinism.gd` OK, **mismo hash** (2203695307); `saberes.gd` 146 comprobaciones OK ([pruebas/12-saberes.txt](pruebas/12-saberes.txt)); `casillas.gd` (540 grillas), `grilla.gd`, `iconos.gd` OK; `campaign_smoke.gd` sin errores (25 escenarios); autotest con Palmares en llano OK. Sin capturas nuevas: el pedido pidió no sacar extra.

## Riesgos

- Los oromo aliados, el aviso a 10 casillas, el tesoro de la amba y el gotära quedan para cuando estén la consulta, el comerciante y la mudanza con cobro.
- Conflictos: `sim.gd`, `sim_mods.gd`, `sim_fog.gd`, `controller.gd`, `civ_meshes.gd`, `iconos.gd`, `iconos_saberes.gd`, `data/iconos.json`, `tests/saberes.gd` (marcados «--- paso 6, par 2 ---»).
