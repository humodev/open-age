# Frente 4 · Avisos y equipo

Pedido: la fila del frente 4 en [README.md](README.md) (V4, V25, C3, C5, C9, C13, C16, C18 y C22 de la ronda 7 de testers).

## Qué entró

- **Alertas de ataque por zona y por tipo** (`src/game/ui/alertas.gd`). Cada golpe a algo propio o de un aliado se clasifica en *aldeanos*, *tropa*, *edificio* o *aliado* y se ubica en una zona de 12 × 12 casillas. Cada combinación de zona y tipo (contando las zonas vecinas) avisa una vez cada 20 s. **Otra zona avisa enseguida.** El texto dice dónde fue («junto a la casa», «lejos de la base»), y cada aviso tiene su lugar para Espacio y su ping en el minimapa. Cada tipo tiene su sonido.
  - El freno de 15 s **sigue en la simulación**: es el suceso `alert`, y no lo toqué. Lo resolví en la interfaz: las alertas salen de los sucesos `hit`. El suceso `alert` solo avisa si ninguna alerta salió en los últimos 3 s, porque los escenarios avisan sin que haya un golpe.
  - En `avisos.gd`, dos avisos iguales se suman (×2) solo si sus lugares están a 12 casillas o menos.
- **Recurso que se agota.** Se siguen los recursos que trabajan tus aldeanos. Hay un aviso cuando lo que queda a 6 casillas baja del umbral (alimento 150, madera 250, piedra y riqueza 300) y otro cuando se acaba sin otro igual cerca. Los dos avisos llevan lugar y sonido.
- **Granjas vacías.** Una granja que pasa 4 s sin granjero se marca en el mundo con un aro que late y la palabra «vacía», y aparece un aviso. Arriba del minimapa aparece el botón **«Llenar granjas (n)»**, que manda primero a los aldeanos ociosos. Si no hay ociosos, manda a los más cercanos, empezando por los que juntan alimento fuera de una granja.
- **Tributo** (panel F6). Un clic manda un lote, Mayús + clic manda ×5 y Ctrl + clic manda ×10. El clic derecho prende o apaga el **tributo periódico** de ese recurso a ese aliado (cada 60 s de partida, si te alcanza), y el botón lo muestra con borde verde.
- **Bengalas con intención.** Alt + clic tira la bengala automática de siempre. **Alt + arrastrar** abre una rueda con cuatro opciones: arriba, atacar; derecha, defender; abajo, juntarse; izquierda, mirar. El comando `bengala` lleva un `tipo` opcional que se valida contra `reglas.equipos.bengala.tipos`. La IA aliada trata *juntarse* como *defender* y no responde a *mirar*.
- **Ver al aliado.** Debajo de la fila «pedirle», cada aliado tiene otra fila con sus aldeanos, su tropa y su intención: su bengala viva, «ataca a X» (cuando el centro de su tropa está a 18 casillas de un edificio rival), «en su base», «en marcha» o «sin tropa».
- **Minimapa.** Tiene botones **R**, **M** y **E** para mostrar u ocultar los recursos, la tropa y los edificios, y un botón **±** que pasa por tres tamaños (200, 250 y 320 px).
- **Sonidos.** Salen de `tools/audio/generar_avisos.py` y son 6 archivos, unos 73 KB en total: `ui_alerta_{aldeanos,tropa,edificio,aliado}`, `ui_aviso_recurso` y `ui_aviso_granja`. Son golpes de madera y notas puras sintetizadas, sin instrumentos sagrados ni de ningún repertorio. Cada uno se apaga en `data/respuesta.json`.

Los números están en `data/interfaz.json`, en los bloques `alertas`, `minimapa`, `tributo` y `equipo` y en `avisos.fusion_casillas`, y en `data/reglas.json`, en `equipos.bengala.tipos`.

## Archivos

- **Nuevos:** `ui/alertas.gd`, `autotest_avisos.gd` y `tools/audio/generar_avisos.py`.
- **Tocados, con la marca `# --- fluidez 4 ---`:** `avisos.gd`, `mundo_minimapa.gd`, `minimap.gd`, `ordenes_capa.gd`, `panel_puntaje.gd`, `hud.gd` (crear, sucesos y `alert`), `audio.gd` (calla la alarma genérica), `controller.gd` (rueda y `flare(g, tipo)`), `main.gd` (llamada al autotest), `sim.gd` (`_cmd_flare` con tipo) y `sim_ai.gd` (*mirar*).
- **Sin tocar:** la colocación, `mundo_cola`, `mundo_colocacion` y `_cmd_build_line`.

## Pruebas

Ver [04-avisos-y-equipo/pruebas.txt](04-avisos-y-equipo/pruebas.txt).

## Tropiezos

- Una zona fija partía en dos una pelea que caía sobre el borde. Por eso cuentan también las zonas vecinas.
- Calcular lo que queda de un recurso recorriendo todos los recursos por cada uno seguido trababa la partida. Ahora se suma por celdas de 3 casillas, una vez por revisión.
