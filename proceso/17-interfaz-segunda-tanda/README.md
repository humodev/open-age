# 17 · Interfaz, segunda tanda (desde 2026-11-14)

## Pedido del autor
> "Move forward with 1, 3 and 4. Start 5 if you think you can. Don't stop and keep documenting in proceso, but for real this time."

El punto 3 es la segunda tanda de interfaz que propuso la auditoría ([`docs/diseno/interfaz/00-auditoria.md`](../../docs/diseno/interfaz/00-auditoria.md)):
- escala de la interfaz;
- paleta apta para daltonismo;
- cursores contextuales;
- grilla de comandos estable;
- avisos con jerarquía y tecla de salto;
- opciones accesibles desde el menú y guardadas;
- errores puntuales: texto pisado en la capital de Palmares, "Tutorial 0/4" y la población 33/8 de una misión mapuche.

## Paso a paso

- **Parte A, escala, paleta y opciones** ([detalle](01-escala-paleta-opciones.md)):
  - escala de la interfaz automática o elegida (80 a 150 %), legible de 1366×768 a 4K;
  - paleta apta para daltonismo con modos y prueba propia;
  - estados de la grilla a 4,5:1;
  - menú de opciones guardado en `user://opciones.cfg`, desde el menú principal y la pausa;
  - `--ventana=ANCHOxALTO` para las capturas.
