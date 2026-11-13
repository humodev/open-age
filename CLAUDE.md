# Instrucciones para agentes

1. Leer primero `docs/00-indice.md` y `docs/04-decisiones.md`. Las reglas del índice valen para todo el repositorio.
2. Estado actual y próximos pasos: `docs/09-estado.md`. Actualizarlo al terminar una tarea.
3. `src/sim/` es determinista: solo enteros, sin nodos, sin `Time`, sin `randf`, sin trigonometría. Detalle en `docs/06-arquitectura.md`.
4. Ningún número de balance en el código: va en `data/`.
5. Antes de entregar cambios en la simulación, correr:
   - `godot --headless --path . -s tests/test_determinism.gd`
   - `godot --headless --path . -s tests/bench.gd`
6. Antes de entregar cambios en la interfaz o los controles, correr `godot --path . -- --autotest --civ=guaranies --terreno=llano` y revisar una captura (`-- --shot=screenshots/x.png --shot-at=3`).
7. Cambios en civilizaciones o en la IA: `tests/civ_smoke.gd`. Cambios en campañas o en el motor de escenarios: `tests/campaign_smoke.gd`. Balance: `tests/torneo.gd -- --minutes=30 --seeds=2`.
8. **Proceso, en cada push**: cada etapa de trabajo tiene su carpeta numerada en `proceso/`, con su `README.md` (pedido, paso a paso, tropiezos, commits), sus capturas, sus videos y los resultados de las pruebas. El índice `proceso/README.md` se actualiza en el mismo commit; nunca se acumula todo en una sola etapa. Las preguntas para el autor van a `proceso/CONSULTAS.md`, y se revisa si las contestó antes de cada push.
