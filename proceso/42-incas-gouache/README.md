# 42 · Incas en gouache: prueba completa (2026-11-20)

> **Pedido (decisiones del autor):** estilo C, gouache; el alcance del experto en AoE también para el aldeano (un arte por unidad, sin versión por edad); las caras funcionan pero parecen viejas: adultos de 25 a 35 años, sin arrugas marcadas, y el hombre sin labios rosados. Una prueba completa con los incas, generada de cero con la receta afinada, con su propio HTML.

Página: [`index.html`](index.html). Las piezas se definen en `armar_piezas.py` (→ `piezas.json`) y se generan de a una con `generar.py`, que espera a tener 4 GB disponibles antes de cada imagen y rearma la página después de cada una. PNG fuera del repo, en `/mnt/games/01_Projects/comfyui/output/incas_gouache/`; en `img/`, JPG de 512 px y las comprobaciones `_rec.jpg`.

## Paso a paso

1. ComfyUI aislado con `arrancar_aislado.sh` (scope de systemd con tope de 14 GB), solo con FLUX.
2. Caras: dos rondas cortas. «in his/her late twenties» y «smooth unlined skin» las rejuvenecen; con «28 years old, a young adult» quedan adolescentes. La mujer se lee más andina con «Native American Quechua woman». Las caras quedan fijas por descripción (`CARA_M`, `CARA_F`).
3. 84 piezas: 18 unidades, 29 edificios, hitos y maravilla, 8 mejoras, 17 accesorios y 12 hojas 3D (aldeano, hondero y guerrero en 4 edades).
