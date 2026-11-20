# 41 · Afinado del arte inca (2026-11-20)

> **Pedido:** «Quiero que generes un equipo de artistas, historiadores y expertos en prompting de IA para que tomen a los incas y lo intenten afinar, sin generar batches. Enfoquémonos en una unidad hasta encontrar el punto justo, luego un edificio, y todo así hasta lograr algo fino, y luego sí seguir generando. Mostrame lo que vayan generando.»
>
> **Cambio de dirección (autor, durante el paso 1):** «Me gustaría que busquemos un estilo más como pintado al óleo, o menos realista, porque no queda tan bueno.» Desde la ronda 7 cada ronda prueba tres direcciones: A óleo de caballete, B estilizado tipo AoE4/Total War, C gouache.

Página con todas las rondas, críticas y recetas: [`rondas.html`](rondas.html) (datos en `rondas.json`, se arma con `python3 armar_pagina.py`). Miniaturas JPG de 512 px en `img/`; los PNG originales quedan fuera del repo, en `/mnt/games/01_Projects/comfyui/output/afinado/`.

## Paso a paso

1. **Retrato del hondero, 4 edades** (rondas 1-20). Ganadora: ronda 20, FLUX schnell solo, dirección B. Prompts finales en `prompts_retrato_hondero.txt`.

## Tropiezos

- FLUX convierte en collar cualquier cordón con piedra cerca del pecho: la honda se resolvió con la piedra en la mano alzada, la bolsa de piedras y la honda cruzada sobre los hombros.
- «beardless» y «strong jaw» traen barba; lo resolvió poner al principio la cara depilada con su porqué histórico.
- SDXL + IP-Adapter con los retratos de Recraft copia bien el pincel y las caras, pero trae el realismo que el autor ya no quiere, y SDXL turbo no sigue prompts largos.
- `tools/generar_local.py` suma `--base` y `--fuerza` (img2img en SDXL y FLUX). En FLUX schnell con 4 pasos el img2img salta de «igual» (0.75) a «otra imagen» (0.85).
- Alternar FLUX y SDXL en cada imagen cuesta ~3 min por par (cambio de modelo en memoria): agrupar por modelo.

## Commits

- Paso 1: retrato del hondero.
