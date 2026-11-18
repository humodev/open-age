# Síntesis de la octava ronda: 1 contra N (2026-11-18)

> Pedido del autor: poner a los expertos contra más IA (1v3, 1v6), con la partida a medida (etapa 31), para que lleguen al final y encuentren mejoras al diseño.

Informes: [veterano](01-veterano-1vN.md) y [constructor](02-constructor-1vN.md). Se jugó sobre main con el juego tardío completo, los frentes 1 a 4 de fluidez y la partida a medida.

## Resultado de las partidas

| Partida | Veterano | Constructor |
|---|---|---|
| 1v3 | Contra 3 fáciles, con guaraníes: llega a la IV a los 36:28, pone la maravilla y gana a los 59:17. Contra 3 difíciles cae a los 10–11 minutos | Contra 3 normales cae antes del 25, en los tres intentos |
| 1v6 | Contra 6 normales cae a los 12 minutos. Contra 6 fáciles, con mapuches, pierde a los 20 y a los 26 | Llega a la IV a los 29 y gana por sitios a los 44:33 |
| 2v4 | — | Llega a la IV a los 40 y pierde por sitios a los 55:11. La IA aliada cae a los 18 |

Parte de las derrotas tempranas vienen de los guiones, que suben de edad más tarde que la IA. Aun así, los dos coinciden en el mismo problema: el 1vN no está pensado para el que juega solo.

## Lo que anda bien

- **El final tiene contenido y se usa todo:**
  - la escuela;
  - ataque y armadura 3;
  - las élites;
  - lo propio de cada pueblo (la imprenta guaraní, lo inca);
  - la maravilla, que depende del hito de la II (eso, bien decidido).
- **Producción continua de aldeanos:** la repetición con tope anduvo sola los 60 minutos.
- **La empalizada en anillo aguanta y no traba caminos:** de 0 a 5 aldeanos frenados con 100 aldeanos y 4 puertas.
- **A ×1 la simulación alcanza** con 7 jugadores (25–47 ms por tick).

## Lo que sigue, por gravedad

| Gravedad | Qué | Quién |
|---|---|---|
| **Alta** | **Las IA de un equipo atacan todas juntas** al único humano: 6 fáciles son 90 soldados a los 15–17 minutos, y 3 rivales juntas desde el minuto 8. Tienen que escalonar los ataques | Los dos |
| **Alta** | **No hay compensación para el que juega solo en el 1vN.** Propuesta: recursos extra o minutos de gracia, como opción de partida | Veterano |
| **Alta** | **Falta piedra.** Hay 1600 por jugador y el mapa grande no suma; a los 30–55 minutos se acaba. El inca pasó 34 minutos trabado en la II con 10 000 de madera, esperando 200 de piedra. Propuesta: piedra según el mapa, o que se renueve en la III y la IV | Constructor |
| **Alta** | **Ninguna IA compra en el mercado** lo que le falta | Constructor |
| **Alta** | **Rendimiento:** el 1v6 llega a 27 ms por tick, con picos de 100 a 315 ms. A ×4 no alcanza el tiempo | Los dos |
| **Media** | **La IV necesita decisiones y un sumidero de recursos.** Quedan 10 000 de alimento y 52 000 de madera sin uso. Propuesta: escuelas excluyentes y una unidad de élite cara | Veterano |
| **Media** | **Contrajuego a la maravilla:** que se avise y se marque en el minimapa, que la IA la ataque, una obra más corta (con 10 constructores tardó 21 minutos) y que la cuenta de sitios se frene mientras hay una maravilla en obra | Los dos |
| **Media** | **Los avisos saturan:** «Población llena» salió 292 veces en 15 minutos, y hubo unos 10 avisos por minuto con picos de 24. Hacen falta prioridad y agrupación | Los dos |
| **Media** | Muralla de piedra (C-101), con un equivalente para los pueblos que no tienen torre ni empalizada | Constructor |
| **Media** | Que avise cuando hay aldeanos encerrados por la propia empalizada. Al veterano le quedaron 87 encerrados | Veterano |
| Baja | Que la ficha de la maravilla diga qué hito pide | Veterano |
| Baja | La IA aliada no aguanta: cayó a los 18 en el 2v4 | Constructor |

## Plan propuesto

1. **IA en equipo y 1vN** (la IA en sim_ai):
   - que el equipo escalone sus ataques;
   - que la IA use el mercado;
   - una opción de partida «ventaja del que juega solo»;
   - una IA aliada más sólida.
2. **Economía del final** (en data, y en la sim lo mínimo):
   - piedra según el mapa y renovable en la III y la IV;
   - un sumidero en la IV: escuelas excluyentes y una élite cara;
   - contrajuego a la maravilla.
3. **Avisos** (en la interfaz): prioridad y agrupación, aviso de aldeanos encerrados, y que la ficha de la maravilla diga qué hito pide.
4. **Rendimiento con 7 jugadores:** perfilar los picos del 1v6 y la caché de caminos (es el frente 6 de fluidez).
5. Muralla de piedra, si se confirma C-101.

## Decisiones del autor (2026-11-18)

| Propuesta | Decisión |
|---|---|
| IA de un equipo que escalona sus ataques | **Sí** |
| Ventaja para el que juega solo en 1vN | **No.** "¿Age lo tiene? Hay que ser muy, muy bueno para ganar un mapa así." Antes de cualquier ventaja hay que revisar el mapa: recursos, tamaño, etc. |
| Piedra según el mapa y renovable | **Analizar los recursos en general:** dónde están y en qué cantidad. "Siento que estamos bastante por debajo de Age en un mapa normal", aunque Age tiene mapas más escasos o más abundantes a propósito |
| La IA usa el mercado | **Sí** |
| Sumidero en la IV: escuelas excluyentes y élite cara | **Sí.** Sumidero = algo valioso en qué gastar lo que sobra |
| Contrajuego a la maravilla: alerta, marca en el minimapa, que la IA la ataque, obra más corta | **Sí** |
| Frenar la cuenta de sitios con una maravilla en obra | **No**, no está relacionado |
| Avisos con prioridad y agrupados | **No. Hacia AoE:** la cola de producción siempre a la vista, y en rojo, trabada, cuando la población está al máximo. "El juego tiene demasiados mensajes de que no estás gastando; el usuario debería darse cuenta solo." Hay que sacar mensajes |
| Aviso de aldeanos encerrados por la propia empalizada | **No** ("skill issue") |
| Muralla de piedra (C-101) | **Sí**, en la edad II, como se propuso |
| Rendimiento con 7 jugadores | **Sí:** probar y hacerlo bien |
| Nueva pregunta a los jugadores | ¿Qué tan lejos está el juego de algo que se pueda jugar profesionalmente, estilo esports? |
