#!/usr/bin/env bash
# Arma una versión para compartir de Raíces (proceso/44-version-para-amigos).
#
#   tools/publicar.sh            exporta Linux y Windows, prueba y deja los zip (no sube nada)
#   tools/publicar.sh --subir    lo mismo y, si todo pasó, sube los dos zip a itch.io con butler
#
# Configuración (fuera de git): ~/.config/raices/publicar.env, o la ruta en RAICES_PUBLICAR_ENV.
#   ITCH_TARGET=usuario/raices     página de itch.io (solo para --subir)
#   RELEVO=host:47900              dirección del relevo; va en relevo.txt junto al ejecutable
#   SALIDA=/ruta/a/raices-builds   dónde quedan las versiones (por defecto la de abajo)
#
# Versión: AAAA.MM.DD-commit. Se escribe en application/config/version de project.godot
# solo mientras dura el script (se restaura al salir) y entra en RedRelevo.version(), así
# que el relevo no junta en una sala a dos versiones distintas.
#
# Cuidado de memoria (la PC se colgó por RAM): cada Godot corre de a uno, con
# systemd-run --user --scope -p MemoryMax=6G -p MemorySwapMax=1G, y espera a que haya
# MEM_MIN_GB (8) de memoria disponible.
set -euo pipefail

RAIZ=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)
cd "$RAIZ"

SUBIR=0
for a in "$@"; do
	case "$a" in
		--subir) SUBIR=1 ;;
		-h|--help) sed -n '2,19p' "$0"; exit 0 ;;
		*) echo "Opción desconocida: $a (ver --help)"; exit 2 ;;
	esac
done

CONF=${RAICES_PUBLICAR_ENV:-$HOME/.config/raices/publicar.env}
if [ -f "$CONF" ]; then
	# shellcheck disable=SC1090
	. "$CONF"
fi
SALIDA=${SALIDA:-/home/humodev/_01_Projects/raices-builds}
GODOT=${GODOT:-godot}
MEM_MIN_GB=${MEM_MIN_GB:-8}
RELEVO=${RELEVO:-}
ITCH_TARGET=${ITCH_TARGET:-}

falla() { echo; echo "PUBLICAR: FALLA · $*"; exit 1; }
paso() { echo; echo "== $*"; }

# --- 0. Antes de empezar -------------------------------------------------------------
if [ -n "$(git status --porcelain)" ]; then
	git status --short | head -20
	falla "hay cambios sin commitear. Commiteá (o descartá) y volvé a correr: la versión tiene que ser un commit."
fi
if [ "$SUBIR" = 1 ]; then
	# Lo de itch se revisa antes de exportar, para no esperar diez minutos y fallar al final.
	if [ -z "$ITCH_TARGET" ]; then
		falla "falta ITCH_TARGET. Creá $CONF con una línea como
    ITCH_TARGET=tu-usuario/raices
(los pasos están en proceso/44-version-para-amigos/guia-relevo-y-versiones.md)."
	fi
	command -v butler >/dev/null || falla "no está butler (https://itch.io/docs/butler/). Instalalo y corré: butler login"
	if [ ! -s "$HOME/.config/itch/butler_creds" ] && [ -z "${BUTLER_API_KEY:-}" ]; then
		falla "butler no tiene sesión. Corré una vez: butler login"
	fi
	butler status "$ITCH_TARGET" >/dev/null 2>&1 || falla "butler no puede ver $ITCH_TARGET. ¿Existe la página en itch.io con ese nombre? ¿La sesión de butler es de esa cuenta? Probá: butler status $ITCH_TARGET"
fi

GV=$("$GODOT" --version | sed -E 's/^([0-9]+(\.[0-9]+)+\.[a-z]+[0-9]*)\..*/\1/')
PLANTILLAS="$HOME/.local/share/godot/export_templates/$GV"
for f in linux_release.x86_64 windows_release_x86_64.exe; do
	[ -f "$PLANTILLAS/$f" ] || falla "faltan las plantillas de exportación de Godot $GV ($PLANTILLAS/$f). Bajá el .tpz de esa versión de https://github.com/godotengine/godot/releases e instalalo desde el editor (Editor → Administrar plantillas → Instalar desde archivo)."
done

VERSION="$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)"
DEST="$SALIDA/$VERSION"
[ -n "$VERSION" ] && [ -n "$SALIDA" ] || falla "versión o salida vacías"
if [ -e "$DEST" ]; then
	echo "Ya existe $DEST: se rehace."
	rm -rf -- "$DEST"
fi
mkdir -p "$DEST"
LOG="$DEST/publicar.log"
echo "Raíces $VERSION · Godot $GV · salida $DEST" | tee "$LOG"

# --- Godot de a uno y con tope de memoria ---------------------------------------------
esperar_memoria() {
	local disp
	while :; do
		disp=$(free -g | awk '/^Mem:/{print $7}')
		[ "$disp" -ge "$MEM_MIN_GB" ] && return 0
		echo "   (esperando memoria: $disp GB disponibles, hacen falta $MEM_MIN_GB)"
		sleep 30
	done
}
limitado() {
	esperar_memoria
	if command -v systemd-run >/dev/null; then
		systemd-run --user --scope -q -p MemoryMax=6G -p MemorySwapMax=1G "$@"
	else
		"$@"
	fi
}

# --- 1. Sello de versión (se restaura al salir) ---------------------------------------
cp project.godot "$DEST/.project.godot.orig"
restaurar() { [ -f "$DEST/.project.godot.orig" ] && mv -f "$DEST/.project.godot.orig" "$RAIZ/project.godot"; }
trap restaurar EXIT
sed -i '/^config\/version=/d' project.godot
sed -i "/^\[application\]/a config/version=\"$VERSION\"" project.godot

# --- 2. Exportar ------------------------------------------------------------------------
paso "Importar recursos"
limitado "$GODOT" --headless --path . --import >>"$LOG" 2>&1 || falla "la importación falló (ver $LOG)"

exportar() { # preset carpeta ejecutable
	paso "Exportar $1"
	mkdir -p "$DEST/$2"
	limitado "$GODOT" --headless --path . --export-release "$1" "$DEST/$2/$3" >>"$LOG" 2>&1 || falla "la exportación $1 falló (ver $LOG)"
	local tam
	tam=$(stat -c %s "$DEST/$2/$3" 2>/dev/null || echo 0)
	[ "$tam" -gt 20000000 ] || falla "la exportación $1 quedó vacía o muy chica ($tam bytes; ver $LOG)"
	echo "   $3: $((tam / 1048576)) MB"
}
LIN="raices-$VERSION-linux-x86_64"
WIN="raices-$VERSION-windows-x86_64"
exportar Linux "$LIN" raices.x86_64
exportar Windows "$WIN" raices.exe

# --- 3. Pruebas rápidas ----------------------------------------------------------------
paso "Versión de la exportación = versión del proyecto"
VFUENTE=$(limitado "$GODOT" --headless --path . -- --imprimir-version 2>/dev/null | sed -n 's/^VERSION: //p')
VEXPORT=$(limitado "$DEST/$LIN/raices.x86_64" --headless -- --imprimir-version 2>/dev/null | sed -n 's/^VERSION: //p')
echo "   proyecto:    $VFUENTE"
echo "   exportación: $VEXPORT"
[ -n "$VEXPORT" ] && [ "$VFUENTE" = "$VEXPORT" ] || falla "las versiones no coinciden: la exportación no tiene los mismos data/ que el proyecto"

paso "La exportación de Linux arranca y juega 30 s sin ventana"
SALIDA_JUEGO=$(limitado timeout 300 "$DEST/$LIN/raices.x86_64" --headless -- --preset=1v1 --salir-a=0.5 --speed=8 --mute 2>&1 || true)
echo "$SALIDA_JUEGO" >>"$LOG"
echo "$SALIDA_JUEGO" | grep -q "^PARTIDA A MEDIDA: 0:30" || falla "la partida de prueba no llegó a los 30 s (ver $LOG)"
if echo "$SALIDA_JUEGO" | grep -q "SCRIPT ERROR"; then
	echo "$SALIDA_JUEGO" | grep -A2 "SCRIPT ERROR" | head -12
	falla "la exportación tiene errores de script (ver $LOG)"
fi
echo "$SALIDA_JUEGO" | grep "^PARTIDA A MEDIDA: 0:30"

paso "Determinismo (tests/test_determinism.gd)"
DET=$(limitado "$GODOT" --headless --path . -s tests/test_determinism.gd 2>&1 || true)
echo "$DET" >>"$LOG"
echo "$DET" | grep -E "^ticks=|^DETERMINISMO" || true
echo "$DET" | grep -q "^DETERMINISMO: OK" || falla "determinismo"

paso "Dos clientes por el relevo (tests/red_relevo.gd, con la versión distinta rechazada)"
REL=$(limitado "$GODOT" --headless --path . -s tests/red_relevo.gd 2>&1 || true)
echo "$REL" >>"$LOG"
echo "$REL" | grep -E "^relevo: aviso|^anfitrión: tick|^RED RELEVO" || true
echo "$REL" | grep -q "^RED RELEVO: OK" || falla "relevo"

# --- 4. Zip con LEEME, relevo.txt y licencias ------------------------------------------
paso "Armar los zip"
for d in "$LIN" "$WIN"; do
	python3 - "$RAIZ/tools/publicar_leeme.txt" "$DEST/$d/LEEME.txt" "$VERSION" "$RELEVO" <<'EOF'
import sys
src, dst, version, relevo = sys.argv[1:5]
if relevo:
    linea = "2. Fila «Relevo»: la dirección (%s) ya viene escrita. No la cambies salvo que te pasen otra." % relevo
else:
    linea = ("2. Fila «Relevo»: escribí la dirección del relevo que te pasó quien te mandó el juego\n"
             "   (por ejemplo 203.0.113.5:47900). El juego la recuerda para la próxima vez.")
t = open(src, encoding="utf-8").read().replace("{VERSION}", version).replace("{RELEVO_LINEA}", linea)
open(dst, "w", encoding="utf-8", newline="\r\n" if "windows" in dst else "\n").write(t)
EOF
	if [ -n "$RELEVO" ]; then
		printf '# Dirección del relevo de Raíces (host:puerto). Lo que escribas en el menú tiene prioridad.\n%s\n' "$RELEVO" >"$DEST/$d/relevo.txt"
	fi
	mkdir -p "$DEST/$d/licencias"
	cp assets/CREDITOS.md "$DEST/$d/licencias/CREDITOS.md"
	cp assets/fonts/OFL.txt "$DEST/$d/licencias/fuentes-OFL.txt"
	cp assets/animaciones/kaykit/License.txt "$DEST/$d/licencias/kaykit-License.txt"
	if [ -f /usr/share/licenses/godot/LICENSE ]; then
		cp /usr/share/licenses/godot/LICENSE "$DEST/$d/licencias/godot-LICENSE.txt"
	fi
	(cd "$DEST" && zip -qr9 "$d.zip" "$d")
	rm -rf -- "${DEST:?}/$d"
done
python3 - "$RAIZ/tools/publicar_leeme.txt" "$DEST/LEEME.txt" "$VERSION" "$RELEVO" <<'EOF'
import sys
src, dst, version, relevo = sys.argv[1:5]
linea = ("2. Fila «Relevo»: la dirección (%s) ya viene escrita." % relevo) if relevo else "2. Fila «Relevo»: escribí la dirección del relevo."
open(dst, "w", encoding="utf-8").write(open(src, encoding="utf-8").read().replace("{VERSION}", version).replace("{RELEVO_LINEA}", linea))
EOF
echo "$VERSION" >"$DEST/version.txt"
ls -la "$DEST"/*.zip | awk '{printf "   %s  %d MB\n", $NF, $5/1048576}'

# --- 5. Subir (opcional) ---------------------------------------------------------------
if [ "$SUBIR" = 1 ]; then
	paso "Subir a itch.io ($ITCH_TARGET)"
	butler push "$DEST/$LIN.zip" "$ITCH_TARGET:linux" --userversion "$VERSION" || falla "butler push linux"
	butler push "$DEST/$WIN.zip" "$ITCH_TARGET:windows" --userversion "$VERSION" || falla "butler push windows"
	butler status "$ITCH_TARGET" || true
	echo "Subido. La app de itch actualiza sola a quien la tenga instalada."
else
	echo
	echo "(No se subió nada: para subir, tools/publicar.sh --subir)"
fi

echo
echo "PUBLICAR: OK · $VERSION · $DEST"
