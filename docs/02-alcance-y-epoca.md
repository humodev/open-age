# 02 — Alcance y época

## Época

El juego cubre aproximadamente de 1400 a 1800. Llegar hasta 1800 permite incluir la adopción del caballo y la pólvora, las guerras de resistencia y las rebeliones, lo que da un final de partida más rico y es coherente con el tono del proyecto.

## Edades

Todas las civilizaciones tienen cuatro edades, pero cada una les pone su propio nombre y su propia periodización (se define en cada ficha). El marco genérico:

| Edad | Marco genérico | Qué habilita |
|---|---|---|
| I | Asentamiento | Economía básica, exploración, unidades iniciales |
| II | Consolidación | Segunda base, unidades por función, primeras defensas |
| III | Apogeo o resistencia | Mecánicas únicas completas, asedio, primeras adopciones |
| IV | Pólvora y rebelión | Adopciones plenas, unidades de élite, condiciones de victoria tardías |

## Adopción

Caballo, hierro y pólvora no están en el árbol de todas las civilizaciones desde el principio. Se incorporan por una de tres vías, según la historia de cada una:
- **Captura**: se obtienen al vencer o saquear a quien los tiene.
- **Comercio**: se compran con riqueza a través de rutas o puestos.
- **Alianza**: llegan con un acuerdo que también trae un costo.

Cada civilización adopta cosas distintas, en momentos distintos y con resultados distintos. Los detalles están en `03-matriz-de-roles.md`.

## Recursos

Cuatro recursos comunes:
- **Alimento**
- **Madera**
- **Piedra**
- **Riqueza**: equivalente funcional del oro. Según la civilización son tejidos, ganado, tributo o yerba. Cómo se obtiene es uno de los ejes principales de asimetría.

## Triángulo de contadores

Se define por función y no por tipo de unidad:
- **Choque** (cuerpo a cuerpo rápido: caballería o infantería de asalto) vence a **distancia**.
- **Distancia** (arcos, hondas, boleadoras, armas de fuego) vence a **línea**.
- **Línea** (infantería lenta con lanza larga o escudo) vence a **choque**.

El asedio y las defensas quedan fuera del triángulo y se detallan en `05-mecanicas-nucleo.md`.

## Alcance por hito

Cada hito tiene un criterio de "terminado" verificable.

| Hito | Contenido | Terminado cuando |
|---|---|---|
| H0 | Documentos de diseño completos | Todos los archivos del índice existen y no se contradicen |
| H1 | Prototipo gris del núcleo | Con cubos: recolectar, construir, producir, pelear y avanzar de edad, a 200 unidades sin caídas de rendimiento |
| H2 | Dos civilizaciones asimétricas en gris | Tawantinsuyu contra mapuches pasa el test de los cinco minutos y una partida completa contra IA básica |
| H3 | Slice con calidad final | Las mismas dos civilizaciones, un mapa, arte, sonido e interfaz finales |
| H4 | Cuatro civilizaciones e IA sólida | Las cuatro pasan los tests de asimetría; IA en tres dificultades |
| H5 | Multijugador | Partidas 1v1 en línea estables y sin desincronización |
| H6 | Acceso anticipado | Cuatro civilizaciones, varios mapas, escaramuza y multijugador |

Fuera de alcance hasta después de H6: campañas, documentales, combate naval completo, editor de mapas, más civilizaciones.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| El alcance supera a una persona | Hitos chicos, cubos grises primero, nada de arte antes de H3 |
| El multijugador exige simulación determinista | Diseñar la simulación determinista desde H1, aunque el multijugador llegue en H5 |
| Búsqueda de caminos con cientos de unidades | Resolverlo y medirlo en H1, antes que cualquier contenido |
| Arte 3D con calidad AoE4 hecho por una persona | Estilo estilizado, pocas piezas muy reutilizadas; presupuestar ayuda externa para H3 |
| La asimetría multiplica el trabajo | Presupuesto fijo por civilización y mecánicas como módulos (ver `01-vision-y-pilares.md`) |
| Errores o estereotipos históricos | Marca `[verificar]`, fuentes por ficha, y consulta con historiadores y comunidades antes de H6 |
| IA rival floja | Documento propio (`08-ia-rival.md`) y pruebas automáticas de IA contra IA |
