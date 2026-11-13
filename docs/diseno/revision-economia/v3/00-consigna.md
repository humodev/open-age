# Ronda 3 · Consigna (2026-11-13)

Esta ronda deja atrás "cada agente piensa una vez". Ahora hay **un diseño único, criticado desde varias perspectivas, medido con un modelo numérico y revisado hasta pasar una lista de control.** No se implementa nada hasta que el autor lo apruebe.

## Material
- Ronda 1: `../0*.md` y la síntesis `../00-sintesis.md`.
- Ronda 2: `../v2/0*.md`, con su consigna `../v2/00-consigna.md`.
- Investigación: `../../investigacion-aoe4/01..03`.
- Historia del repositorio: `../../../investigacion/*.md`.
- Datos y código actuales:
  - `data/reglas.json`, que incluye los 11 tipos de mapa en `terrenos`;
  - `data/civs/*.json`;
  - `src/sim/sim.gd`, `src/sim/sim_mods.gd` y `src/sim/sim_ai.gd`.

## Todo lo que dijo el autor (en orden)
1. "Si tenés una mina de oro ahí, y la riqueza es otra cosa, ¿para qué está?"
2. "¿Los mapuches tienen que dañar edificios enemigos para conseguir riqueza? ¿Cómo van a hacer al comienzo?"
3. "Si el recurso está lejos y en otro lado, al perder esa región ya perdiste. El juego se vuelve controlar ese recurso."
4. "No entiendo de qué van las mecánicas detrás de los nombres indígenas (que me encantan)."
5. "Hay mecánicas que requieren estar pendiente de algo, rápidamente; es distinto a poner a picar." Y: "Si una es tradear, ya es un problema: tradear van a poder todos."
6. "Lo de estar oculto y que si lo ven pierde valor es raro: en el endgame casi todo está descubierto, hay outposts, tropas por todo el mapa."
7. "La salina chica va a estar siempre, pero ¿qué puede hacer cada civ desde eso? En Age el oro siempre está para minar, pero algunas civs tienen engines mejores que solo minar. ¿Cómo conviven las mecánicas?"
8. "¿Por qué la sal? ¿Estaba disponible en todos estos lugares?"
9. "Hay civs que dependen de un río, pero deberían poder jugar en un mapa sin agua e igual tener una estrategia viable; si no, el juego se desarma."
10. "Antes de implementar hay que afinar al máximo: teorizar, planificar cómo resulta desde el comienzo hasta el final del juego, si está balanceado, si conlleva el mismo esfuerzo para todos."

## Preguntas que esta ronda tiene que cerrar
- **A. La fuente común.**
  - ¿Qué es el depósito que tiene toda base? ¿Sal, metal, piedra fina, un nombre neutro? ¿Fue accesible para los seis pueblos? Si no lo fue, ¿qué fuente común es honesta para todos?
  - ¿Cómo se ve y cómo se llama?
- **B. Capas.** Cada civ tiene que explicar dos capas:
  - **Capa 1:** cómo usa la fuente común. Puede ser igual que las demás o de forma mejor o distinta, como las minas de pozo malíes, el ovoo mongol o el aceite bizantino.
  - **Capa 2:** su motor propio.

  Hay que explicar también cómo conviven las dos capas y cuál conviene en cada momento.
- **C. Terreno.**
  - Cada civ, en cada uno de los 11 tipos de mapa, necesita una estrategia viable. Agua, ladera, monte o llano dan una bonificación, nunca son requisito.
  - Tabla civ × terreno con el efecto esperado: un ±% razonable y el plan B.
  - Las campañas con nombre pueden favorecer a una civ, y está bien. La escaramuza no.
- **D. Vida completa.** Cada civ con su línea de tiempo:
  - 0–5 min;
  - 5–15 min;
  - 15–30 min;
  - final, con el mapa revelado, outposts y tropas por todos lados.

  Nada que se rompa en el final.
- **E. Esfuerzo.** Órdenes por minuto que pide la economía propia de cada civ en cada fase, sin contar recolectar ni encolar aldeanos. Parejas, con tolerancia de ×1,5 entre la que más pide y la que menos.
- **F. Prohibido:**
  - motores que dependan de estar oculto;
  - comercio genérico como identidad;
  - temporizadores que hay que cliquear;
  - recursos que deciden la partida por un solo lugar;
  - pasivos sin tope.

## Lista de control para aprobar el diseño
| # | Criterio | Cómo se verifica |
|---|---|---|
| 1 | Cada civ tiene las dos capas claras, en palabras llanas | Ficha de 5 líneas |
| 2 | Esfuerzo parejo por fase (±×1,5) | Modelo numérico |
| 3 | Curvas de riqueza acumulada a los 5, 10, 20 y 30 min dentro de ±15 % de la media | Modelo numérico |
| 4 | Edad II entre 6:30 y 9:00 y edad III antes de 20:00 sin tocar lo disputado, en todas las civs | Modelo numérico |
| 5 | Viable en los 11 mapas | Tabla civ × terreno; luego el torneo |
| 6 | Nada se rompe con el mapa revelado | Crítica del que intenta romperlo |
| 7 | Ninguna mecánica es comercio genérico ni depende de estar oculto | Revisión |
| 8 | Lo disputado tiene techo por edad y remontada | Modelo numérico |
| 9 | La IA puede jugarlo con reglas simples | Crítica del programador de IA |
| 10 | Fiel a la historia o con simplificación declarada | Crítica del historiador |
