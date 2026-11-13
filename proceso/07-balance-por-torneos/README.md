# 07 · Balance por torneos (2026-11-13, 01:49 a 09:51)

Commits: `71905ea`, `7a89027`, `30e94a4`, `b762edb`.

`tests/torneo.gd` enfrenta a todas las civilizaciones contra todas, ida y vuelta, en partidas de hasta 30 minutos con la IA. Los resultados completos están en `torneo-1.txt` a `torneo-4.txt`. La tabla cuenta victorias por destrucción y por puntos sobre 10 partidas:

| Civilización | Torneo 1 | Torneo 2 | Torneo 3 | Torneo 4 |
|---|---|---|---|---|
| Palmares | 9 | 8 | 7 | 7 |
| Guaraníes | 8 | 6 | 6 | 6 |
| Ayutthaya | 5 | 8 | 6 | 6 |
| Tawantinsuyu | 4 | 5 | 7 | 6 |
| Etiopía | 4 | 3 | 2 | 3 |
| Mapuches | 1 | 1 | 2 | 2 |

## Qué se cambió en cada ronda (solo datos)
1. **Tras el torneo 1**: bajan los guaraníes (potirõ, arquero, roza) y Palmares (fama, acogida, espinas); suben mapuches y Etiopía.
2. **Tras el torneo 2**: el elefante es más débil y más caro; el lof y el kona mapuches son más fuertes; el jinete etíope tiene más vida.
3. **Antes del torneo 3**: la IA aprendió incursiones (malón y correría) y caminos incas.
4. **Tras el torneo 3**: el jinete etíope pasa a ocupar 1 de población y el weichafe pega más.
5. **Tras el torneo 4**: lof más barato, más relevo y lanza larga desde la edad I para los mapuches; más renta del gult para Etiopía.

## Lectura
- Las partidas se definen más: en el torneo 1 terminaron por destrucción 15 de 30, y desde el torneo 2, unas 22.
- Mapuches y Etiopía siguen abajo en IA contra IA. Parte del problema es de la IA, que no explota el enjambre de lof ni la corte que se muda. Conviene probarlos jugados por una persona.
