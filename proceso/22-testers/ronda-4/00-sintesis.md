# Síntesis de la cuarta ronda (2026-11-16)

A pedido del autor jugaron solo el veterano de AoE4 y el jugador nuevo, con su memoria de las rondas 1–3. Además de lo suyo, se concentraron en **calidad de vida y usabilidad**. Informes: [veterano de AoE4](01-veterano-aoe4.md) y [nuevo en los RTS](02-nuevo-en-rts.md). Jugaron sobre main en `352136e`, con todo lo de la ronda 3 integrado.

## Lo que ya está a la altura (según ellos)

- **Controles:**
  - el autotest pasa sus 78 chequeos con mouse y teclado reales;
  - barra con ociosos y aldeanos por recurso, cola global, M, T, Tab y ocho marcadores;
  - barras de vida al pelear y grilla con nombre común y propio.
- **Hito:** costo real, aura al colocarlo y "Faltan 1:54 con 4 constructores".
- **Fin de partida:** la pantalla "supera a la de AoE4" (veterano).
- **Para el jugador nuevo:**
  - la primera partida en Fácil y sin sitios, con una línea que dice cómo se gana;
  - el "Granero y leñera" con su aviso de viaje largo;
  - el tutorial con mensajes durante la obra del hito (gana a las 11:10).
- **Caza:** el animal propio se carnea con clic derecho y del arbusto se pasa al arbusto.
- **Micro C2:** funciona. La mezcla de lanceros y honderos gana 4 de 5 sin micro y 5 de 5 manteniendo y escalonando.
- **Experta:** levanta 7 graneros en 20 minutos (antes, 55).

## Calidad de vida y usabilidad, por gravedad

| Gravedad | Qué | Quién | Estado |
|---|---|---|---|
| **Alta** | En el centro, la casilla Q muestra "Herramienta de tala" en vez de Aldeano y no se ve Explorador (todos los pueblos). Las investigaciones de depósito comparten la casilla: se dibuja una y se ejecuta otra | Nuevo | En curso (4n) |
| **Alta** | Con varios edificios elegidos, cada pulsación entrena en todos (5 cuarteles: Q = 5, Mayús+Q = 25); AoE4 entrena una por pulsación en el de cola más corta | Veterano | En curso (4o) |
| **Alta** | No hay teclas configurables, y los marcadores en F1–F4 chocan con los paneles para quien viene de AoE4 | Veterano | En curso (4o) |
| Alta | La fácil se multiplica cuando la atacan (de 39 a 147 de población): su tope no rige amenazada | Nuevo | En curso (4n) |
| Media | El aviso "A y clic en la base rival" no dice dónde está ni que hace falta asedio | Nuevo | En curso (4n) |
| Media | El tutorial no pide granjas: siguiéndolo, la comida se acaba hacia el minuto 8–10 | Nuevo | En curso (4n) |
| Media | H no recorre los centros; M y "," no centran la cámara; el panel de varias unidades no muestra la vida ni deja sacar con Mayús o Ctrl+clic | Veterano | En curso (4o) |
| Media | Nombres apagados o cortados en la grilla, el panel de aldeanos elegidos vacío, el edificio sin su nombre común, la ficha tapa el título del submenú, "Barrero" no dice qué guarda | Nuevo | En curso (4n) |
| Media | Avisos de la IA en IA contra IA; el cursor sobre un animal propio a veces dice "mover" | Ambos | En curso (4n, 4o) |
| Baja | Grupos no exclusivos y sin grupo 0; el círculo del centro sin explicar; `--demo=batalla` puede caer en un lago | Veterano | En curso (4o) |
| — | Se cae al cerrar (código 134, después del resultado) | Ambos | Sigue sin causa encontrada: está dentro del motor |

## Lo que sigue pidiendo el veterano

- Que la IA pegue de verdad al hito en obra: se acerca, pero no lo tira.
- Que dispute los sitios: la experta le ganó otra vez por sitios. Se integró la disputa (5b) después de que jugara.
- Mejoras por unidad.

## Plan

1. Integrar 4n (jugador nuevo) y 4o (veterano). Todo es interfaz y no mueve el balance, salvo el tope de la fácil.
2. El torneo 26 mide la IA que disputa sitios y la llama por vez.
3. Quinta ronda cuando estén 4n y 4o.
