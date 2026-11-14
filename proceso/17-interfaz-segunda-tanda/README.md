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

- **Parte B · cursores, grilla de comandos, avisos y errores puntuales** → [`02-cursores-grilla-avisos.md`](02-cursores-grilla-avisos.md): doce cursores contextuales dibujados con los glifos del juego; grilla del aldeano con submenús Economía (Q) y Militar (W), casillas fijas por función en las seis civs e hitos Z economía / X militar con íconos distintos; avisos con fondo, color por tipo y pila, Espacio e Inicio para saltar; fila de grupos de control; HUD vacío que no tapa y cámara inicial sobre la capital; arreglos de Palmares, "Tutorial 0/1", 33/8 explicado y subtítulo sin "· " suelto. Autotest OK en las seis civs y prueba nueva `tests/grilla.gd`.
