# Síntesis de la quinta ronda (2026-11-16)

Jugaron el veterano de AoE4 y el jugador nuevo, igual que en la cuarta, sobre main en `f6234d5`. Informes: [veterano de AoE4](01-veterano-aoe4.md) y [nuevo en los RTS](02-nuevo-en-rts.md). Ronda anterior: [cuarta](../ronda-4/00-sintesis.md).

## Arreglos de la cuarta ronda

- **Veterano: 9 de 9 bien.** Teclas configurables con perfil AoE4, una unidad por pulsación al edificio de cola más corta, H, retratos con vida, M, grupos exclusivos y grupo 0, sin avisos de la IA en IA contra IA, el círculo del centro y la demo de batalla. El autotest pasa de 78 a 101 chequeos.
- **Jugador nuevo: 9 de 10 bien.** Aldeano y Explorador visibles en el centro, cursor sobre el animal propio, granja en el tutorial (que se gana a las 11:07), nombres prendidos la primera vez, retratos, "Centro · Oga guasu", círculo explicado y aviso "atacá" con rumbo y asedio.
  - Lo que no se cumple del todo es la fácil atacada: el tope anda (36–58 de población contra 147), pero todavía no se le gana.

## Escala

- "Es el cambio que más acercó la sensación a AoE4 en cinco rondas: el bosque se lee como bosque y la ciudad al minuto 12 parece un pueblo" (veterano).
- **Medida** (`tools/escala.gd`):
  - persona de 0,75 casillas;
  - en alturas de persona: casa 1,3–2,2, cuartel 2,5–3,1, centro 2,3–4,3 (y 3,0–4,6 de ancho), árbol 4,0;
  - el aldeano mide unos 33 px en pantalla.
- **No alcanza:**
  - la velocidad (C-65) hace falta ya: con la gente más chica, el aldeano anda 1,5 personas por segundo (AoE4 ≈ 0,8);
  - el centro necesita la huella de 5×5 (C-66); los hitos, ya no tanto.
- **El jugador nuevo** encuentra a los aldeanos por el disco azul. El tapyi, el campo de tiro y el cuartel se parecen demasiado (techos de paja).

## Lo que sigue, por gravedad

| Gravedad | Qué | Quién | Estado |
|---|---|---|---|
| **Alta** | El jugador nuevo no le gana a la fácil: 13 ataques con 19–29 soldados y arietes no tiran ni un edificio, y nada explica por qué | Nuevo | En curso (4q: por qué falla el ataque, fácil ganable, resumen de la pelea) |
| **Alta** | Velocidad de las unidades | Veterano | Consulta C-65 |
| **Alta** | Centro de 5×5 | Veterano | Consulta C-66 |
| Media | La experta llega a 100 aldeanos y juntó 47 000 contra 14 000, pero no pasa de la edad II en 26 minutos | Veterano | Pendiente |
| Media | Atajos globales (campana, todos los aldeanos, todos los edificios de producción); los 8 marcadores en la lista; barras de vida finas; el "Zz" de ocioso más chico que la cabeza; mercado, ruka y venado en escala | Veterano | En curso (4r) |
| Media | El tapyi, el campo de tiro y el cuartel no se distinguen; "Hito · edad II" cortado; hoja de atajos | Nuevo | En curso (4q) |
| — | Se cae al cerrar (código 134) | Ambos | Sigue sin causa encontrada: está dentro del motor |

## Plan

1. Integrar 4q (primera victoria) y 4r (vista del veterano).
2. Con el balance de los guaraníes cerrado (torneos 27–28), probar la velocidad (C-65 por defecto: 72, con torneo propio).
3. Sexta ronda con los dos.
