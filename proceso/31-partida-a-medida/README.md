# 31 · Partida a medida

## Pedido (textual)

> Quisiera cambiar la creación de partidas a algo más como Age of Empires, donde se pueda elegir a medida el mapa, cada jugador, los equipos, los colores, etc. Eso nos ayudaría a poner a los expertos contra más IA, como 1v3 o 1v6, para probarlos, ayudarlos a llegar al final del juego y que encuentren mejoras al diseño.

## Qué entró

- **Pantalla «Partida personalizada»** (`src/game/ui/partida_a_medida.gd`), desde el botón «A medida» del menú (comparte renglón con «Campañas» para que el menú siga entrando a 1366×768):
  - **Mapa:** terreno (o al azar), tamaño (chico, normal, grande; con 3 o más jugadores), recursos y semilla (con «Al azar»).
  - **Ocho renglones**, uno por jugador: tipo (Vos, IA, Cerrado), pueblo (o al azar), dificultad y estilo de la IA, equipo (1 a 4 o sin equipo) y color. Los colores no se repiten: al elegir uno ocupado, se intercambian. Un solo «Vos»; sin «Vos» se mira IA contra IA.
  - **Opciones de partida:** sitios, hitos, maravilla, tiempo límite y aliados juntos o mezclados.
  - **Presets:** 1v1, 1v3 y 1v6 (vos contra las IA en equipo), 2v2, 4v4 y todos contra todos. Cambian tipo y equipo; pueblo, dificultad y color de cada renglón se conservan.
  - Una línea dice la partida («4 jugadores · 2 equipos») o por qué no se puede jugar, y «Empezar» se apaga.
  - **Recuerda la última configuración** en `user://partida_a_medida.json` (se lee con chequeos de tipo; si falta o está roto, vuelve lo de siempre). Las capturas y el autotest no lo leen ni lo escriben.
- **Colores por jugador** (`Palette.colores`, `Palette.color_idx`): `Palette.team()` y `team_name()` los usan, así llegan a banderas, aros, minimapa, panel de puntaje, ficha y registro de sucesos. No es estado de la simulación; la repetición los guarda.
- **Tamaño del mapa** en la simulación: `opts.tamano` → `reglas.opciones_partida.tamano_mapa_pct` (80/100/125 %), solo con 3 o más jugadores. Sin la opción, nada cambia (el hash sigue en 2903543624).
- La **dificultad por jugador** ya la soportaban los lugares de la etapa 18; no hizo falta tocar la IA.
- Lógica sin nodos en `src/game/partida_config.gd` (parseo, presets, colores, validación, guardado).

## Línea de comandos

```
# Un renglón por jugador; cada parte se reconoce sola y el orden no importa:
# tipo (vos|ia|cerrado), pueblo (o azar), dificultad, estilo, equipo (1-4; 0 o «sin» = sin equipo),
# color (nombre: azul, rojo, violeta… o c1…c8).
godot --path . -- --jugadores="vos:guaranies:1:azul,ia:mapuches:dificil:2:rojo,ia:azar:2,ia:azar:experta:2"

# Archivo JSON (ejemplo: proceso/31-partida-a-medida/1v6.json); lo que se pase aparte gana.
godot --path . -- --partida=proceso/31-partida-a-medida/1v6.json

# Preset con la dificultad de todas las IA:
godot --path . -- --preset=1v3 --dificultad=experta --civ=guaranies

# Opciones sueltas: --tamano=chico|normal|grande, --terreno, --seed, --recursos, --tiempo,
# --sitios=no, --hitos=no, --maravilla=no, --ubicacion=mezclados.
# --salir-a=MIN imprime un resumen a los MIN minutos de juego y sale; anda con --headless:
godot --headless --path . -- --preset=1v3 --salir-a=2 --speed=8 --mute
# La pantalla abierta (capturas): --menu --abrir=partida [--preset=1v3]
```

`--partida=N` (un número) sigue preeligiendo el tipo de partida del menú viejo.

## Pruebas

- `tests/test_determinism.gd`: OK, hash 2903543624 (el de main con fluidez 1 y 2).
- `tests/opciones_partida.gd`: OK. `tests/equipos.gd -- --minutes=8`: OK (con 30 minutos no terminó en 10 min de reloj con la máquina cargada).
- 1v3 headless desde la línea de comandos, 2 minutos, mapa grande (216): sin errores. 1v6 desde el JSON, 1 minuto: sin errores.
- Autotest guaraníes en llano: OK.
- Capturas: `pantalla.png` (la pantalla con el preset 1v3, a 1366×768) y `colores.png` (vos en rosa, la IA en oliva: aros, bandera y puntaje).

## Tropiezos

- `--partida=N` ya existía para el menú viejo: un número sigue siendo eso, otra cosa es un archivo.
- Con un botón más, el menú se pasaba de 768 de alto: «A medida» va al lado de «Campañas».
