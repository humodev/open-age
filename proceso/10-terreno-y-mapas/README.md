# 10 · Terreno y mapas (desde 2026-11-13)

Plan: [`docs/10-terreno-y-mapas.md`](../../docs/10-terreno-y-mapas.md).

## Pedido del autor
"Mejorar muchísimo el terreno y los tipos de mapa; que los mapas se parezcan a sitios reales (…), en la campaña algo más realista (…), que en lugar de ser un bloque que sobresale del piso se note como continuación, como en el Age."

Respuestas a las consultas el mismo día:
- Nombre: **Raíces**.
- Civilizaciones: aprobadas.
- Música: conseguir lo que se pueda.
- Meshy: gastar lo necesario, de forma eficiente.
- Prioridad: arrancar con el terreno (C-06).

## Punto de partida
Los edificios generados se apoyan sobre un pasto uniforme y parecen bloques sueltos.

![](00-antes-capitales-sobre-pasto-uniforme.jpg)

## Paso a paso
1. **Respuestas de las consultas** registradas y aplicadas: el juego pasa a llamarse Raíces (D-029) y se usa Meshy según haga falta (D-030). Se lanzó un agente para buscar música libre por región.
2. **Materiales del suelo.** Cinco juegos de texturas CC0 de ambientCG (pasto, pasto seco, tierra, barro y roca), reducidos a 512 px (1,1 MB). El shader nuevo hace cuatro cosas:
   - Mezcla el pasto a dos escalas para que no se note la repetición.
   - Pone pasto seco según el bioma y la altura.
   - Pone barro en las orillas.
   - Aplica roca triplanar en las laderas.

   Lo que es tierra pisada se pinta en un mapa de mezcla de 2 píxeles por casilla.
3. **Edificios integrados al suelo.** Cada edificio pinta tierra pisada a su alrededor al aparecer, lleva una sombra de contacto y los modelos generados se hunden unos centímetros. Se sacaron las bases grises de los edificios procedurales, que se veían como baldosas. Pendiente: regenerar sin base de diorama los modelos de Meshy que la traen, como la corte etíope.

| Antes | Suelo con texturas | Sin plintos |
|---|---|---|
| ![](00-antes-capitales-sobre-pasto-uniforme.jpg) | ![](01-suelo-con-texturas-etiopia.jpg) | ![](02-edificios-sin-plinto-mapuches.jpg) |
