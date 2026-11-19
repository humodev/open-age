# 36 · Aprendizaje: lecciones, tutorial con el núcleo nuevo y consejos

> Pedido del autor: «No perder de vista al jugador del día a día, que no es profesional». Entraron
> muchas mecánicas que el tutorial no enseña: comercio y rutas, sitios con guarnición, muralla de
> piedra, herrería, veterano y élite, escuela de la IV, maravilla, asedio de área y ataque al suelo,
> repetición, cola en rojo y mercado.

## Qué entró

1. **Lecciones en la Guía (G).**
   - Son 11, en `data/lecciones.json`: cola, repetición, herrería, sitios con guardia, veterano y élite, mercado, comercio, muralla, asedio de área, escuela y maravilla.
   - Cada una tiene tres partes cortas: *qué es*, *cuándo conviene* y *un consejo*.
   - Los números salen de `reglas.json` mediante marcadores como `{reglas:sitios.guarnicion_pob}` o `{min:maravilla.victoria_ms}`. Así, el texto no queda viejo cuando cambia el balance.
   - La Guía ahora está **en toda partida** (antes solo en campañas). Tiene la pestaña «Lecciones» y, en campañas, «Lo que dijo la Guía».
   - **«¿Cómo se usa?»**: es un botón arriba a la derecha del panel de la selección. Abre la lección de lo elegido y marca en el índice las otras que tocan. Algunos ejemplos:
     - centro: cola, repetición y escuela;
     - cuartel: además, herrería y niveles;
     - aldeano: mercado, muralla y maravilla, solo si su pueblo puede levantarlas (los guaraníes no tienen muralla de piedra).
   - Nota: la Guía se abre con **G**, no con F7, que es el marcador de cámara 1. La introducción del tutorial decía F7 y se corrigió.
2. **Tutorial** (`data/campanas/tutorial.json`). Se gana siguiéndolo, en 11:34 (antes, ~10:45). Cambios:
   - o2: la Guía presenta la cola de arriba y qué significa que esté roja.
   - o7: el truco de la repetición (Ctrl + clic en el guerrero).
   - El sitio sagrado «da riqueza mientras tenga guardia».
   - **o13, objetivo nuevo:** «Poné guardia en el sitio sagrado: mandá 2 guerreros…». Aparece con el hito, y se cumple mientras la obra sube.
   - **o14, objetivo nuevo:** al llegar a la II, «comprá Armas templadas (herrería)».
   - Un último mensaje remite a las lecciones para lo demás.
   - Motor de escenarios: tipos `guardia` (sitios propios con guarnición) e `investigar` (`tecnologia` o `herreria: true`). Solo agregan casos, así que el hash no cambia.
3. **Consejos de aprendizaje** (`src/game/ui/consejos.gd → _mecanicas`; textos y tiempos en `data/lecciones.json → consejos`).
   - Salen solo en el tutorial y en la fácil, y cada uno una vez por partida. Cada uno termina con «G: lección «…»».
   - Los consejos:
     - sitio propio sin guardia (si tenés tropa para cuidarlo);
     - casilla de la cola trabada;
     - repetición nunca usada a los 5 min;
     - herrería sin comprar en la II (fuera de campañas: en el tutorial la pide el objetivo);
     - niveles en la III;
     - escuela en la IV;
     - maravilla rival (cómo frenarla);
     - comercio con mercado y sin comerciante en la III;
     - muralla, si hay mucha empalizada y el pueblo la tiene;
     - asedio de área (R al suelo).
   - El de recurso sin gastar suma, desde la edad del mercado: «En el mercado lo cambiás por lo que te falte».

## Pruebas
- `tests/tutorial_letra.gd` (letra): **victoria a las 11:34**, OK. Sigue también o13 (si quedó con menos de 2 guerreros, entrena) y o14. Además revisa que el texto de o13 pida tantos guerreros como `reglas.sitios.guarnicion_pob`.
- `tests/tutorial_letra.gd -- --modo=indefenso`: derrota con motivo, OK, como antes.
- `tests/campaign_smoke.gd`: sin errores: todas las misiones cargan, incluido el tutorial con o13 y o14 ocultos al empezar.
- `tests/test_determinism.gd`: DETERMINISMO OK, **hash 3059812827**, el mismo de la etapa 34.
- `tests/lecciones.gd` (nuevo): revisa que las 11 lecciones estén completas, que no quede ningún marcador sin resolver y que cada consejo nombre una lección que existe. También revisa «¿Cómo se usa?» en 12 casos, entre ellos que el centro no ofrezca herrería y que el aldeano guaraní no ofrezca muralla. OK.
- Autotest guaraníes (`--autotest --civ=guaranies --terreno=llano`): **AUTOTEST: OK**, sin errores de script. La Guía ahora se crea también en escaramuza.
- Capturas:
  - [lección de sitios](capturas/leccion-sitios.jpg) (`--leccion=sitios`);
  - [botón con aldeanos](capturas/como-se-usa-aldeanos.jpg);
  - [botón con el centro](capturas/como-se-usa-centro.jpg).

## Tropiezos
- Al principio el centro ofrecía herrería y niveles, porque entrena al explorador. Ahora solo cuentan las funciones militares.
- Los guaraníes y Palmares no tienen muralla de piedra. La lección y el consejo se ofrecían igual, y ahora no.
- En el tutorial, tras el ataque, el jugador «al pie de la letra» quedaba con 1 guerrero. Por eso o13 dice «si no te quedan, entrená más».
- Dentro del panel, abajo a la derecha, el botón tapaba las ayudas de la selección múltiple. Se lo pasó arriba del panel, en la fila de los grupos.

## Commits
- `13c7f8f` lecciones, tutorial y consejos.
- `ca29c21` «¿Cómo se usa?» según el pueblo y `tests/lecciones.gd`.
- El siguiente: el botón arriba del panel, las capturas y este documento.
