# Consultas

Preguntas concretas para el autor. Contestá debajo de cada una, en la línea **Respuesta:**, con una letra o una palabra. Se revisan en cada push.

Mientras no haya respuesta, sigo con la opción marcada como *(por defecto)*.

---

### C-01 · Nombre del juego (A-005)
a) Proyecto Sur *(por defecto)* · b) Tierra Adentro · c) Raíces · d) Otro: escribilo

**Respuesta:** c) **Raíces** (2026-11-13). Aplicado: el juego se llama Raíces en el menú, el proyecto, el README y los documentos (D-029).

### C-02 · Civilizaciones nuevas
Elegí Quilombo dos Palmares (Brasil) y Ayutthaya (Siam). ¿Te van?
a) Sí *(por defecto)* · b) Cambiar Palmares por tupinambá · c) Cambiar Ayutthaya por maratas (India)

**Respuesta:** a) Están bien (2026-11-13).

### C-03 · Imágenes generadas por IA
Para retratos y láminas de campaña puedo usar generación de imágenes, o quedarme con arte procedural y libre (CC0).
a) Solo procedural y CC0 *(por defecto)* · b) Generadas por IA, marcadas como tales

**Respuesta:** b, con Meshy (respondido en el chat el 2026-11-13). Se usa con un tope de unos 400 créditos; ver C-05.

### C-04 · Música
Si no aparece música libre que suene a estas regiones:
a) Solo ambiente y efectos, sin música *(por defecto)* · b) Música procedural simple generada por el juego

**Respuesta:** "Consigamos lo que podamos". Se busca más música libre que suene a cada región; el autor va a opinar cuando escuche lo que hay.

### C-05 · Presupuesto de Meshy
El saldo (1.442 créditos) se comparte con apex-open. Usé hasta unos 400: láminas de civilización y de campaña, más los modelos 3D clave. ¿Gasto más para modelar todas las unidades y edificios?
a) No, con eso alcanza *(por defecto)* · b) Sí, hasta ___ créditos más

**Respuesta:** "Gastá lo necesario, de la forma más eficiente posible; los créditos se renuevan una vez al mes" (2026-11-13).

### C-06 · ¿Terreno ahora o cerrar pendientes?
a) Arrancar ya con el plan de terreno y mapas (`docs/10`) · b) Cerrar antes balance e IA

**Respuesta:** a) "Continuá acorde al plan con todo el trabajo" (2026-11-13). Etapa 10 en `proceso/`.

### C-07 · ¿Aceptamos música con licencia CC BY-SA?
Hay buenas grabaciones de siku y sikuri para Tawantinsuyu en Wikimedia, pero son CC BY-SA. Esa licencia obliga a dar crédito y a compartir con la misma licencia cualquier cambio que se haga a la pista, no al juego. Hoy solo se usa CC0 y dominio público.
a) Sí, con crédito *(por defecto)* · b) No, solo CC0

**Respuesta:**

### C-08 · La pifilka mapuche tiene uso ceremonial (ngillatun)
Las grabaciones las publicó el propio intérprete en dominio público, pero suenan en el combate.
a) Dejarla solo en el menú o en la paz, no en el combate *(por defecto)* · b) Dejarla como está · c) Sacarla

**Respuesta:**

### C-09 · ¿Quedaron bien la escala y la velocidad?
Ahora una casa mide unas tres veces un aldeano y todos andan un 10 % más lento. Para probarlo, jugá a velocidad ×1, no con el autotest, que corre a ×4.
a) Están bien · b) Aldeanos todavía grandes · c) Todavía rápidos · d) Ahora demasiado lentos

**Respuesta:**

### C-10 · Modelo de la riqueza (resumen en `docs/diseno/revision-economia/00-sintesis.md`)
a) "Una riqueza, seis motores": un solo recurso, con nombre e ícono por civ, y que cada civ produce con su propio motor pacífico desde la edad I *(recomendado)* · b) Solo cambiar la imagen y los nombres, sin tocar las reglas · c) Un cuarto recurso distinto para cada civ

**Respuesta:**

### C-11 · ¿Qué hay junto a cada base?
a) Una salina chica que se agota, más el paisaje propio de la civ; nada dorado *(recomendado)* · b) Dejar los dos yacimientos, pero con otro aspecto · c) Nada común: solo el motor propio

**Respuesta:**

### C-12 · Kulliñ mapuche
a) El kulliñ pasa a ser la riqueza mapuche: el ganado crece en el corral y el botín que supera el tope se vuelve riqueza *(recomendado)* · b) Mantenerlos separados, como hoy

**Respuesta:**

### C-13 · ¿Arranco ya con los arreglos "sin arrepentimiento"?
Son la IA mapuche, la campana, la vida de los edificios mapuches, el costo del gult, los colores y el tooltip de riqueza. Valen para cualquier modelo.
a) Sí, mientras decidís el resto *(recomendado)* · b) No, esperá

**Respuesta:**

> **C-10 a C-12 quedan reemplazadas** por las preguntas del diseño final de la ronda 3 (C-14 a C-20). Resumen en palabras llanas al principio de [`docs/diseno/revision-economia/v3/04-diseno-final.md`](../docs/diseno/revision-economia/v3/04-diseno-final.md).

### C-14 · ¿Cómo medimos que el esfuerzo sea parejo?
a) Umbrales absolutos: como máximo 0,6 órdenes por minuto y 2 pendientes cada 10 minutos por civ, y ninguna por encima de 1,5 veces la mediana *(recomendado)* · b) ×1,5 entre la que más y la que menos pide (falla porque guaraníes y Palmares piden muy poco)

**Respuesta:**

### C-15 · Costo del avance a la edad II
a) 500 de alimento + 300 de riqueza, y se mide con la IA real; si pasa de los 9:00, vuelve a 400 + 250 *(recomendado)* · b) Dejarlo en 400 + 200 (algunas civs llegan antes de los 6:30)

**Respuesta:**

### C-16 · Cuando se acaba la arcilla de casa (minutos 13 a 24), el ingreso de riqueza cae a la mitad
a) Aceptarlo: el final se pelea en el centro, con tope *(recomendado)* · b) Agregar una veta lenta en el flanco

**Respuesta:**

### C-17 · Etiopía en escaramuza: ¿la corte "se funda" en otro lugar en vez de viajar como carpa?
a) Sí: sin carpa vulnerable ni derrota por empacar; la carpa queda para la campaña *(recomendado)* · b) Volver a la carpa que viaja

**Respuesta:**

### C-18 · ¿Ayutthaya sin depósitos comunes, con el elefante del rey como depósito?
a) Sí *(recomendado)* · b) Que pueda construir depósitos comunes

**Respuesta:**

### C-19 · Mapuches: si pierden la arcilla de casa en el minuto 10, conservan el 29 % del ingreso de riqueza (no atrasan la edad)
a) Aceptarlo como el precio de "no hay capital" y mirarlo en el torneo *(recomendado)* · b) Abaratar el lof de flanco de 110 a 80 de madera

**Respuesta:**

### C-20 · Cambiar las frases de Palmares ("se esconde") y Ayutthaya ("comercia con el mundo"), que contradicen el diseño
a) Sí, con las propuestas de la sección 11 del diseño final *(recomendado)* · b) Dejarlas

**Respuesta:**

### C-21 · ¿La IA "Pacífica" puede ganar por sitios sagrados?
Hoy controla el mapa y toma sitios, así que puede ganar por ellos sin atacarte.
a) Sí, es parte de su juego: los sitios hay que disputarlos *(recomendado)* · b) No: toma sitios pero no cuenta para su victoria · c) No toma sitios

**Respuesta:**

### C-22 · Música para Etiopía: no hay grabaciones CC0 ni de dominio público (etapa 19)
Se revisaron Wikimedia Commons, Internet Archive (también la colección de discos de 78 rpm) y OpenGameArt; Freesound no permite descargar sin cuenta. Lo único etíope que apareció es CC-BY-SA (escala de begena, entrevistas de qene), está mal licenciado (discos comerciales subidos como CC0) o es un registro etnográfico o litúrgico (zema de estudiantes de Debre Libanos; Courlander, 1951; Leslau). Detalle en `proceso/19-arte-y-sonido/01-modelos-y-musica.md`.
a) Seguir con las pistas genéricas hasta conseguir algo propio *(recomendado)* · b) Encargar o grabar krar y masenqo con licencia propia · c) Aceptar CC-BY-SA para la música (obliga a compartir esas pistas con la misma licencia)

**Respuesta:**
