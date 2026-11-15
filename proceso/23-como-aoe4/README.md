# 23 · Hacia AoE4, con identidad propia (desde 2026-11-15 20:00)

## Pedido del autor
> "Siguiendo el feedback que nos pidieron, si los encaramos de la misma forma que lo ha resuelto AoE4, ¿cómo lo haríamos?"
>
> "Me gustó todo lo sugerido para hacerlo más como AoE4, vayamos por ahí, siempre manteniendo identidad del sur global y las peculiaridades de cada civ, pero llevemos el trabajo en esa dirección."

Respuestas a C-31 a C-34: sí a todo, en ese orden.

## Qué se toma de AoE4 y qué no
- **Se toma:**
  - bonos planos por clase y dos armaduras;
  - ovejas, ciervos y jabalíes; granjas tardías y trabajo para el explorador;
  - hitos de 190/220/250 s que se usan;
  - las comodidades de órdenes y selección, la cola global y las bengalas;
  - el "arte de la guerra" y cinco dificultades;
  - la cuenta regresiva visible de los sitios;
  - rivales con civ propia, aspecto por edad, voces y una maravilla por pueblo;
  - las opciones de partida.
- **No se toma, a propósito:**
  - sitios por presencia y no por monjes;
  - aldeanos en bloque cuando van lejos (pedido del autor);
  - la economía asimétrica de cada pueblo (fama, mit'a, corte, roza), que es la identidad de Raíces.
- **Cada cosa se adapta a la región:** los animales son llamas, guanacos, pecaríes, tapires, cabras y búfalos; las formaciones incluyen la columna para el Qhapaq Ñan; las auras son las de los hitos propios (ushnu, wat).

## Plan
| # | Qué | Quién | Mueve el balance | Prueba |
|---|---|---|---|---|
| A | Cerrar el balance actual: mapuches 84 %, Tawantinsuyu 24 %, edad II de Ayutthaya | Líder | sí | Salud de la IA, torneo de 5 semillas en paralelo |
| B | Órdenes y comodidades como AoE4 (ver abajo) | Agente 1 | no | Autotest, `tests/grilla.gd`, capturas |
| C | Aprender a jugar (ver abajo) | Agente 2 | no | Autotest, `campaign_smoke`, capturas |
| D | Rivales con civ propia en las campañas: Adal, Toungoo y Konbaung, chankas, cayambes y cañaris, tupíes; y revisión de nombres | Agente 3 | no (solo campañas) | `campaign_smoke`, `civ_smoke` |
| E | Combate como AoE4: bonos planos por clase, armadura contra cuerpo a cuerpo y contra distancia, kiteo y fuego concentrado | Líder | **sí** | Prueba de micro fija, salud de la IA, torneo |
| F | Comida temprana como AoE4: animales por región para arrear, caza que pelea, menos arbustos, granjas más tarde, explorador con trabajo | Líder | **sí** | Economía en paz (granjas hacia el minuto 7–9), salud, torneo |
| G | Hitos como AoE4: obra de 190/220/250 s y auras según el lugar | Líder | **sí** | Edades en paz, salud, torneo |
| H | IA intermedia, difícil+ y experta (80–100 aldeanos, segundo centro) | Líder | no (la normal no cambia) | Salud de la IA por dificultad |
| I | Opciones de partida: victoria (conquista, sitios sí o no, tiempo límite), recursos y edad iniciales, equipos juntos o mezclados | Más adelante | no | Autotest |
| J | Arte y sonido con los créditos del mes: tropas propias, centro y casa por edad, hitos con su arquitectura, voces | Más adelante | no | Capturas |

**B, órdenes y comodidades:**
- botón de aldeanos ociosos con número y otro de militares ociosos;
- cantidad de aldeanos por recurso en la barra de recursos;
- seleccionar todos los militares, los militares ociosos y todos los edificios de un tipo;
- marcadores de cámara;
- cola global de producción arriba, con clic para ir al edificio;
- mantener posición y patrullar;
- elegir formación (bloque, línea, abierta, columna) y el rumbo arrastrando;
- bengalas con Alt + clic en el mapa o el minimapa, a las que responde la IA aliada;
- pedirle recursos al aliado, y frases de la IA en el chat.

**C, aprender a jugar:**
- tutorial que pide alimento y riqueza, avisa el ataque, falla si se pierden todos los aldeanos y enseña cámara y sitios;
- avisos que enseñan, que se pueden apagar en Opciones;
- cuenta regresiva grande de los sitios sagrados;
- pantalla de fin con gráficos de la partida a lo largo del tiempo;
- nombres en la grilla (opción);
- registro para releer los mensajes de la guía;
- el menú en Fácil la primera vez.

Orden de los cambios de balance: A, después E, F y G, de a uno, con un torneo de 5 semillas entre cada uno. B, C y D corren en paralelo y se integran cuando terminan.

## Paso a paso
1. **(20:00) Etapa abierta.** Respuestas anotadas en `CONSULTAS.md`. Se lanzan los agentes 1, 2 y 3, cada uno en su copia del repositorio.
2. **Parte C, aprender a jugar (agente 2).** Tutorial que se gana haciéndole caso y que falla con motivo, avisos que enseñan (apagables), cuenta grande de los sitios, pantalla de fin que explica por qué y da consejos, nombres en la grilla, registro de la Guía (F7) y el menú en Fácil la primera vez. Detalle en [`03-aprender-a-jugar.md`](03-aprender-a-jugar.md); consultas C-35 y C-36.
