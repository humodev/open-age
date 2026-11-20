# 44 · Pipeline de versiones para amigos (2026-11-20)

## Pedido

Primero, una versión para mandar a amigos y que jueguen entre ellos por internet. Después el autor cambió el pedido: el juego está a mitad de camino (falta más de la mitad del arte) y no quiere publicar todavía. Pide una **tubería** que arme una versión para compartir cada vez que la pida, y que las actualizaciones les lleguen solas a los amigos.

- Presets de exportación para Linux y Windows, sin lo que es solo de desarrollo.
- La dirección del relevo, configurable: en `data/`, y que el menú la recuerde por jugador.
- El relevo, listo para desplegar en cualquier Linux (systemd y Docker), con una guía.
- Un comando (`tools/publicar.sh [--subir]`) que exporta, sella la versión, prueba, arma los zip y, si se pide, sube a itch.io con butler.
- Que una versión distinta se rechace con un mensaje claro.
- No desplegar ni subir nada: eso lo hace el autor.

Guía para el autor: **[guia-relevo-y-versiones.md](guia-relevo-y-versiones.md)**.

## Paso a paso

1. **Plantillas 4.7.2.** Godot está en 4.7.2 y las plantillas instaladas eran de 4.7.1. Se bajó `Godot_v4.7.2-stable_export_templates.tpz` (1,2 GB) de GitHub y coincidió con su SHA-512. Se instalaron solo las de Linux y Windows x86_64 (350 MB) en `~/.local/share/godot/export_templates/4.7.2.stable/`.
2. **`export_presets.cfg`**: Linux y Windows x86_64, con el `.pck` adentro del ejecutable (un solo archivo) y texturas S3TC/BPTC. Quedan afuera `tests/`, `tools/`, `proceso/`, `docs/`, `screenshots/`, `server/`, `assets/generados/conceptos/` (21 MB, que nada usa), `assets/ui/iconos/fuentes/`, los `candidatos/` y `referencia_3d/` del arte, y los `*.md`, `*.py`, `*.sh` y `*.txt`. Las licencias (créditos, OFL, KayKit, Godot) van aparte, en `licencias/` dentro del zip.
3. **Dirección del relevo** (`src/net/sala.gd`):
   - `relevo.servidor` en `data/red.json` queda vacío en el repositorio;
   - la fila «Relevo» toma, en orden, lo último que escribió el jugador (`user://red.cfg`), `relevo.txt` junto al ejecutable (lo escribe `publicar.sh` desde `RELEVO=`) y `data/red.json`;
   - si queda vacía, muestra `dirección:47900` de ejemplo, y al tocar un botón pide escribirla;
   - se guarda al crear o al unirse, salvo en las pruebas automáticas (`--red-*`).

   `relevo.txt` existe para que cambiar de relevo no cambie la versión: `data/` entra en el hash.
4. **Versión.** `publicar.sh` escribe `application/config/version` = `AAAA.MM.DD-commit` en `project.godot` mientras corre y lo restaura al salir. Esa versión entra en `RedRelevo.version()`, junto con la de Godot y el hash de `data/`. `--imprimir-version` (en `main.gd`) la imprime y sale; el script la usa para comparar la exportación con el proyecto.
5. **Mensaje de versión distinta** (`src/net/sesion_red.gd`): en lugar de «El relevo no dejó entrar: versión distinta de la del anfitrión: actualicen los dos al mismo commit», la sala dice «Tu amigo tiene otra versión del juego: actualicen los dos a la última. La tuya es …». El relevo también habla de «la última versión» y no de «commit». `tests/red_relevo.gd` ahora también prueba el aviso que ve el jugador.
6. **Relevo desplegable**: `server/raices-relevo.service` (systemd, usuario sin privilegios, 200 MB como tope) y `server/Dockerfile` (python:3.12-alpine). La guía cubre las dos opciones: en la PC del autor con el puerto 47900 reenviado (y cómo darse cuenta de si hay CGNAT), o en un VPS (Oracle Always Free, con su trampa de iptables, o uno de 4 €).
7. **`tools/publicar.sh`**:
   - se niega a correr si hay cambios sin commitear;
   - con `--subir`, revisa antes de exportar que estén `ITCH_TARGET`, butler y su sesión;
   - sella la versión, importa, exporta las dos plataformas y prueba (versión, arranque, determinismo, relevo);
   - arma los zip con `LEEME.txt` (`tools/publicar_leeme.txt`), `relevo.txt` y `licencias/`;
   - con `--subir`, hace `butler push` a los canales `linux` y `windows` con `--userversion`.

   Cada Godot corre de a uno, dentro de `systemd-run --user --scope -p MemoryMax=6G -p MemorySwapMax=1G`, y espera a que haya 8 GB disponibles.
8. **Corrida de prueba** de punta a punta, sin subir: ver «Pruebas».

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/red_relevo.gd` (antes de la tubería) | OK: el aviso «Tu amigo tiene otra versión del juego…» llega a la sala; código falso y mensaje gigante rechazados; 1200 ticks por el relevo con el mismo hash en los dos (2516299682). [pruebas/red_relevo.txt](pruebas/red_relevo.txt) |
| `--autotest --civ=guaranies --terreno=llano` (en ventana, por el cambio en el menú) | AUTOTEST: OK, sin SCRIPT ERROR. [pruebas/autotest.txt](pruebas/autotest.txt) |
| Captura de la sala | [sala-relevo.png](sala-relevo.png): la fila «Relevo» vacía, con `dirección:47900` de ejemplo |
| `tools/publicar.sh` de punta a punta, sin subir | (abajo) |

## Tropiezos

- La consigna pedía `data/red.json` para la dirección. Pero `data/` entra en el hash de versión, así que cambiar de relevo obligaría a todos a bajar otra versión. Por eso la dirección para los amigos va en `relevo.txt`, que no entra en el hash, y `data/` queda como respaldo.
- Si el autor juega desde el editor contra un amigo que tiene la versión publicada, el relevo no los junta, porque el editor no lleva el sello de versión. Está en la guía: para jugar con amigos, usar la versión publicada.
- La conexión directa por IP (ENet, sin relevo) no compara versiones. Se usa en la red local; para internet está el relevo.

## Commits

- (este) Pipeline de versiones: presets, relevo configurable, publicar.sh, systemd y Docker, guía
