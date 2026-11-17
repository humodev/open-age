# Paso 6 del juego tardío, tercer par: los saberes de Tawantinsuyu y Ayutthaya

Fecha: 2026-11-17. Etapa 26, **paso 6** del plan de [docs/diseno/27-juego-tardio-y-saberes.md](../../docs/diseno/27-juego-tardio-y-saberes.md) (§3.1, §3.6 y §6).

> Pedido: el tercer par. 8 mejoras y 3 unidades por pueblo, con su saber y su nivel de evidencia en la ficha (la trepanación andina como sanación, el khipu, el recetario de Narai; nada sagrado como arma); maquetas procedurales y glifo propio; la IA las compra o las entrena con `ia_propias`; repartir si un edificio pasa de 11 investigaciones. Para el arte, el autor pidió que **cada unidad pueda verse distinta en cada pueblo**: la maqueta de cada unidad nueva lleva color, tocado y arma propios (`tropas.por_civ`). Mismo patrón que el par 2 ([12-paso-6-par-2.md](12-paso-6-par-2.md)).

## Qué entró

Todo en `data/civs/<pueblo>.json → tecnologias_nuevas`, `unidades_nuevas` e `ia_propias`, marcado `propia`, con `desc` y `evidencia`. `tests/saberes.gd` suma a lo prohibido en los nombres: huaca, wak'a, inti, qorikancha, wat, buda, phra si, sak yant.

### Tawantinsuyu (§3.1)

| Edad | Mejora | Dónde | Qué hace en el juego | Evidencia | Cambio contra el diseño |
|---|---|---|---|---|---|
| II | Ch'uñu y ch'arki | qollqa | Granjas y andenes +10 % | Documentado y arqueológico | Sin el tope de mit'a de la qollqa |
| II | Khipukamayuq | qollqa | El taller de tejido rinde 10 % más | Arqueológico y documentado; debatido lo narrativo | Sin la mit'a por runa de 3 a 4 |
| III | Cirugía de cráneo | kallanka (cuartel) | 1 de cada 5 guerreros, lanceros y levas que caen a golpes a 6 casillas de la kallanka (o la kallanka real) no muere: queda con la mitad de la vida y vuelve a ella | Arqueológico (fuerte) | Sin el hampikamayuq (no hay sanador); sin azar: una cuenta por jugador |
| III | Q'eswa chaka | qollqa | Caminos +5 % | Documentado; tradición viva (consulta) | Sin tender el camino sobre ríos |
| III | Champi, la porra de metal | kallanka (cuartel) | +1 de ataque al choque | Arqueológico | — |
| IV | Wayrachina | almacén de mina | Riqueza +20 % | Documentado y arqueológico | Toda la riqueza, no solo minas y sitios |
| IV | Warak'a trenzada | campo de tiro | +0,5 casillas a honderos y boleadores | Documentado y arqueológico | — |
| IV | Chaski en relevo | qollqa | Cada tramo de camino ve 4 casillas | Documentado | Sin el +20 % del chaski (no hay unidad chaski) |

| Edad | Unidad | Qué hace | Evidencia |
|---|---|---|---|
| II | Boleador | Ya estaba; ahora con ficha | Documentado |
| III | **Galgueros** (campo de tiro) | Piedras de área (60 % a los de al lado); enteras cuesta abajo (más el bono de altura), la mitad en el llano o cuesta arriba | Documentado |
| IV | **Jinete de Manco** (élite, Vilcabamba) | Lanza a caballo, +4 contra los montados; hasta 8 en la IV | Documentado |

La galga del diseño pega 60 «a todo lo que esté en la línea»: entra como daño de área alrededor del blanco. El jinete no pide caballos capturados.

### Ayutthaya (§3.6)

| Edad | Mejora | Dónde | Qué hace en el juego | Evidencia | Cambio contra el diseño |
|---|---|---|---|---|---|
| II | Khotchasat | kraal | +10 % de vida a los elefantes | Documentado | Sin el kraal más rápido; sin lo ritual |
| II | Cerámica de Si Satchanalai | mercado | Suai +15 % (tasa y tope) y el mercado da 4 de riqueza por minuto | Arqueológico (fuerte) | El horno es el mercado (no hay almacén); no se apaga en la IV |
| III | Recetario de Narai y nuat | centro | La tropa que pasa 8 s sin pelear sana 1 por segundo | Documentado | Sin mo ni mo luang (no hay sanador) |
| III | Arroz de crecida | centro | Arrozales +10 % | Documentado | Sin lo de que no se agoten en la IV |
| III | Barrio chino y puertos | mercado | Cada barrio extranjero da 6 de riqueza más por minuto | Documentado | Sin el tercer barrio |
| IV | Khlong lat | mercado | La tropa propia cruza el agua baja 25 % más rápido | Documentado | Sin cavar el canal |
| IV | Fundición real | taller | +10 % de ataque a la pólvora | Documentado | — |
| IV | Astilleros de juncos | mercado | Lo vendido rinde 15 % más | Documentado | Sin comerciante ni junco que se compre (paso 7) |

| Edad | Unidad | Qué hace | Evidencia |
|---|---|---|---|
| II | Elefante de guerra (chang suek) | Ya estaba | Documentado |
| III | **Ngao** (cuartel) | Línea con guja, +6 contra montados y elefantes | Documentado |
| IV | **Defensores de Suan Phlu** (élite, cuartel) | Línea con +2 de armadura a 3 casillas de una cerca, puerta, torre o fortaleza propias | Documentado; el armamento, a verificar |

## Código

- **`sim.gd`:** efectos nuevos (`camino_pct`, `suai_pct`, `regen_tropa`, `trepanacion`); la trepanación en `_hit` cuando la vida llega a 0; el suai con su porcentaje en `_tribute`; los fuertes de la armadura junto a la cerca.
- **`sim_mods.gd`:** `trepan` (cuenta de 20 en 20, sin azar; vuelve a la kallanka con `order_move`), la sanación del recetario en `_regen`, las galgas en `damage`, `camino_pct` en la velocidad del camino y `near_wall(..., fuertes)`.
- **IA:** solo datos (`ia_propias.orden` y `unidades`; los galgueros quedan fuera de la lista, ver Medidas).
- **Interfaz:** textos de los efectos nuevos (`controller.gd`); 20 glifos en `iconos_saberes.gd` (16 mejoras y 4 unidades): el tumi sin cráneo, el recetario con mortero, sin wat ni imágenes.
- **Arte (pedido del autor):** `tropas.por_civ` lleva ahora `tela`, `tocado` (`llawtu`, `lomphok`, `pano`) y `tocado_color`, además del arma. Los lee el soldado animado (`tropa_animada.gd`, armas nuevas `guja` y `galga`) y la maqueta fija (`civ_meshes.gd`, que ahora recibe el pueblo). Galgueros: tela parda, llawtu rojo y la piedra en la mano; jinete de Manco: tela oscura y llawtu dorado; ngao: tela azul, lomphok dorado y guja; defensores: tela negra azulada, paño atado, lanza larga y escudo redondo. Cualquier unidad, también compartida, puede tener su entrada por pueblo.
- **Grilla:** ningún edificio pasa de 11 investigaciones. El campo de tiro inca (5 unidades y 9 investigaciones) pasa a usar el submenú; el resto, en la qollqa (4), el almacén de mina, el mercado (4 de Ayutthaya), el centro de Ayutthaya (10, en el submenú) y el taller.

## Medidas

- **`tools/civ_diag.gd --seeds=6`** (30 partidas por pueblo, 30 min; «sin» = `--set="<civ>/ia_propias/orden=[];<civ>/ia_propias/unidades=[]"`; [pruebas/13-civ-diag.txt](pruebas/13-civ-diag.txt)):
  - **Tawantinsuyu: 16 → 13 de 30 (53 → 43 %).** La primera corrida dio 10 (pierde 6, sobre el límite de 4). Más baratos el ch'uñu (100) y el khipukamayuq (100) y sin comprar mientras ahorra para el hito (`ahorrando: false`): siguió en 10. Separando: solo las mejoras, 15; solo las unidades, 11. Los galgueros, primeros en la lista de producción, le hacían guardar mit'a y riqueza para una unidad que casi no entrenaba: salieron de `ia_propias.unidades` (los entrena el jugador; la IA, el jinete de Manco). Final: 13, pierde 3.
  - **Ayutthaya: 15 → 15 de 30 (50 %).** Compra la cerámica (25 partidas), el arroz (13), el khotchasat (10) y el recetario (8); entrena unos 4 ngao por partida; los defensores, casi nunca (llega poco a la IV).
- **Pruebas** ([pruebas/13-pruebas.txt](pruebas/13-pruebas.txt)): `test_determinism.gd` OK; `saberes.gd` OK, ahora con el tercer par ([pruebas/13-saberes.txt](pruebas/13-saberes.txt)); `casillas.gd` (540 grillas), `grilla.gd`, `iconos.gd` OK; `civ_smoke.gd` y `campaign_smoke.gd` sin SCRIPT ERROR; `bench.gd` 9,63 ms de promedio; autotest con Ayutthaya en llano OK. Sin capturas: el pedido pidió no sacar extra.

## Riesgos

- Sin sanador (hampikamayuq, mo, mo luang), sin comerciante y sin caminos sobre ríos: lo que dependía de eso quedó en la ficha.
- Conflictos: `sim.gd`, `sim_mods.gd`, `controller.gd`, `civ_meshes.gd`, `tropa_animada.gd`, `world_view.gd`, `iconos.gd`, `iconos_saberes.gd`, `data/iconos.json`, `data/arte_animaciones.json`, `tests/saberes.gd` (marcados «--- paso 6, par 3 ---»).
