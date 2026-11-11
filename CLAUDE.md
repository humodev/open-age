# Instrucciones para agentes

1. Leer primero `docs/00-indice.md` y `docs/04-decisiones.md`. Las reglas del índice valen para todo el repositorio.
2. Estado actual y próximos pasos: `docs/09-estado.md`. Actualizarlo al terminar una tarea.
3. `src/sim/` es determinista: solo enteros, sin nodos, sin `Time`, sin `randf`, sin trigonometría. Detalle en `docs/06-arquitectura.md`.
4. Ningún número de balance en el código: va en `data/`.
5. Antes de entregar cambios en la simulación, correr:
   - `godot --headless --path . -s tests/test_determinism.gd`
   - `godot --headless --path . -s tests/bench.gd`
6. Antes de entregar cambios en la interfaz o los controles, correr `godot --path . -- --autotest` y revisar una captura (`-- --shot=screenshots/x.png --shot-at=3`).
