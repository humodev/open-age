# 10 — Terreno y mapas (plan)

Pedido del autor (2026-11-13): mejorar mucho el terreno y los tipos de mapa; que los mapas se parezcan a sitios geográficos reales (sin nombre en escaramuza, con nombre en las campañas); y que los modelos 3D se vean como una continuación del suelo, como en AoE, y no como un bloque apoyado encima.

## 1. Relieve real para las campañas
- **Datos de elevación abiertos**: Copernicus DEM GLO-30 (30 m, licencia abierta con atribución) o SRTM (dominio público). Para cada misión se recorta el área real (Ollantaytambo, Curalaba, Serra da Barriga, la isla de Ayutthaya, Gondar, Mbororé…) y se reduce a la grilla del mapa.
- **Agua real**: los ríos se toman de la hidrografía (OpenStreetMap, ODbL, con atribución) o se tallan desde el modelo de elevación.
- **Dos niveles de detalle**: la imagen usa el relieve continuo de alta resolución; la simulación sigue usando niveles enteros derivados de él, para el bono de altura, la pendiente de los andenes y el determinismo.
- El escalado vertical se ajusta para que se lea como juego y no como maqueta plana.

## 2. Tipos de mapa para escaramuza inspirados en geografías reales
Generados por ruido, pero calibrados para parecerse a paisajes reales sin nombrarlos:
- Valle andino con terrazas, quebradas y un río encajonado.
- Altiplano: llano alto, lagunas y cerros aislados.
- Bosque templado: araucarias, claros y lluvia de volcanes.
- Selva y río: monte denso, ríos anchos con islas y bañados.
- Meseta con ambas: mesetas de laderas abruptas y valles.
- Delta: llanura aluvial con canales, arrozales y crecidas.
- Sierra con mata atlántica: lomas suaves y bosque húmedo.

Cada uno tiene su paleta, su vegetación y su distribución de recursos.

## 3. Materiales del suelo
- **Mezcla por textura** (splat map): pasto, tierra, roca, arena, barro, nieve y pasto seco, elegida por pendiente, altura, humedad y bioma, con texturas CC0 (ambientCG, Poly Haven).
- **Proyección triplanar** en barrancos, para que la roca no se estire.
- **Detalle en el suelo**: pasto, flores, piedras y ramas instanciados, que se desvanecen con la distancia.

## 4. Modelos integrados al suelo
- **Huella aplanada con transición**: el terreno se aplana bajo el edificio y se funde suavemente con el entorno (hoy exige terreno parejo y queda un escalón).
- **Suelo pisado pintado en la mezcla** alrededor de cada edificio: tierra, piedra, caminos de entrada. El edificio "asienta" en lugar de flotar.
- **Hundir unos centímetros** cada modelo y sumar oclusión de contacto (calcomanía de sombra).
- **Modelos generados sin base propia**: el prompt pide "sin plataforma ni suelo", porque varios conceptos salieron con base de diorama. Los que la traen se recortan en Blender.
- **Caminos, campos y huellas** como pintura del suelo, no como objetos.
- **Escala coherente**, observación del autor del 2026-11-13 en una partida de Palmares. Las casas y edificios chicos se ven diminutos al lado de los aldeanos, mientras el centro, que es un modelo generado, se ve grande. Se resuelve así:
  - Una tabla de alturas de referencia en `data/`: aldeano, casa, edificio de producción, capital y torre, en metros y en casillas.
  - Cada modelo, procedural o generado, se escala por esa altura y no solo por su huella.
  - La regla de un aldeano adulto mide alrededor de un tercio de la altura de una casa.
  - Se valida con una captura de lado a lado de cada civilización.
- **Velocidad de las unidades**, la misma observación: los aldeanos parecen moverse demasiado rápido. Esa prueba corría a ×4, pero igual hay que medirla a ×1 contra el tamaño visual. Hoy el aldeano anda 1,25 casillas por segundo. Si la escala cambia, se revisan las velocidades en `data/unidades.json` y la cadencia de los pasos de la animación.

## 5. Orden propuesto
1. Mezcla de materiales y edificios integrados al suelo (es lo que más cambia la imagen).
2. Relieve continuo en la imagen y tipos de mapa nuevos.
3. Recortes reales para las 24 misiones con su atribución.
4. Detalle en el suelo y vegetación por bioma.
5. Escala y velocidad (sección 4), junto con la regeneración de modelos sin base, para medir todos los modelos una sola vez.

## Riesgos
- **Rendimiento**: la malla de 256×256, la mezcla de texturas y el detalle instanciado entran en el presupuesto actual (140 fps a ×6), pero hay que medirlos.
- **Determinismo**: los recortes de elevación son archivos de datos; la simulación usa solo sus niveles enteros.
- **Licencias**: Copernicus y OpenStreetMap exigen atribución en `assets/CREDITOS.md`.
