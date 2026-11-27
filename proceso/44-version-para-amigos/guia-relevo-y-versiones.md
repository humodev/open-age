# Guía: versiones para amigos y relevo

Una página para el autor: cómo armar una versión, cómo hacérsela llegar a los amigos y dónde poner el relevo para que jueguen por internet.

## 1. Armar una versión (un comando)

```
tools/publicar.sh            # arma y prueba; no sube nada
tools/publicar.sh --subir    # lo mismo y, si todo pasó, sube a itch.io
```

- Se niega a correr con cambios sin commitear: cada versión es un commit.
- La versión es `AAAA.MM.DD-commit` (por ejemplo `2026.11.20-1a2b3c4`). Se escribe en `application/config/version` solo durante la exportación y entra en la versión que el relevo compara.
- Exporta Linux y Windows (x86_64) con `export_presets.cfg`. Al paquete no entran `tests/`, `tools/`, `proceso/`, `docs/`, `server/`, los conceptos ni los candidatos.
- Prueba: que la exportación tenga la misma versión que el proyecto (los mismos `data/`), que arranque y juegue 30 s sin ventana, el determinismo y dos clientes por un relevo local (con el rechazo de una versión distinta).
- Deja `raices-<versión>-linux-x86_64.zip` y `raices-<versión>-windows-x86_64.zip`, con `LEEME.txt` y `licencias/`, en `/home/humodev/_01_Projects/raices-builds/<versión>/`, junto con `publicar.log`.
- Cada Godot corre de a uno, con tope de 6 GB y esperando a que haya 8 GB libres.

Configuración, fuera de git, en `~/.config/raices/publicar.env`:

```
ITCH_TARGET=tu-usuario/raices
RELEVO=203.0.113.5:47900
```

`RELEVO` va a un `relevo.txt` al lado del ejecutable. Así cambiar el relevo no cambia la versión, y el amigo solo tiene que escribir el código de la sala.

## 2. Que les llegue a los amigos (itch.io)

Con la app de itch, cada versión que subís les llega sola.

1. **Crear la página** en itch.io (Dashboard → Create new project). Tipo: *Downloadable*. En *Visibility & access*, elegí **Restricted** (solo entran quienes tengan una clave o la contraseña) o dejala en **Draft**. Para pasar el acceso hay dos caminos: *Distribute → Download keys*, que da un enlace por amigo, o una contraseña de página. El nombre corto de la página (`tu-usuario.itch.io/raices`) es el `ITCH_TARGET`: `tu-usuario/raices`.
2. **Iniciar sesión en butler** una sola vez: `butler login` (abre el navegador). Butler ya está instalado en `~/.local/bin/butler`.
3. **Escribir la configuración**: `~/.config/raices/publicar.env` con `ITCH_TARGET=` (y `RELEVO=` si ya hay relevo).
4. **Subir**: `tools/publicar.sh --subir`. Sube los canales `linux` y `windows` con `--userversion <versión>`. Butler manda solo lo que cambió, así que las versiones siguientes suben rápido.
5. **Los amigos** instalan la app de itch (itch.io/app), entran con su clave o su contraseña e instalan Raíces. Cada versión nueva se baja sola. También pueden bajar el zip a mano desde la página.

### Claves de descarga, una por amigo (C-103 a)

Lo que elegiste. Cada amigo tiene su enlace; si uno lo pasa, se le saca a ese solo.

1. En la página: *Edit game → Visibility & access → **Restricted*** y guardar.
2. *Distribute* (arriba, en la página del proyecto) → **Download keys** → *Generate download keys*. Cantidad: los amigos que quieras (se pueden generar más después). En *Note* poné el nombre del amigo: así sabés de quién es cada una.
3. Cada clave da un enlace `https://tu-usuario.itch.io/raices/download/<clave>`. Mandáselo a cada uno por privado.
4. El amigo abre el enlace con su cuenta de itch iniciada y toca *Link to my account*: el juego le queda en la biblioteca de la app y se actualiza solo con cada `tools/publicar.sh --subir`.
5. Para sacarle el acceso a alguien: *Download keys* → la clave → *Revoke*. Para sumar a otro: otra clave.

Alternativa, sin implementar: una GitHub Action que exporte y suba a GitHub Releases o a itch al crear una etiqueta (`v*`). Sirve cuando haya más de una persona publicando. Mientras sea uno solo, el script local alcanza y no gasta minutos de CI con las plantillas de 1 GB.

## 3. Dónde poner el relevo

El relevo (`server/relevo.py`) es Python 3 sin dependencias. Usa unos 15 MB de memoria y un 1v1 mueve unos pocos KB/s. Escucha en el puerto **47900/TCP**. Los jugadores solo salen hacia él, así que en sus casas no hay que abrir nada.

### Opción A: en tu PC, con el puerto abierto

Sirve para probar ya, gratis. El relevo solo anda mientras tu PC esté prendida.

1. Fijate si tenés CGNAT: compará la IP «WAN» que muestra el router con la de https://ifconfig.me. Si son distintas (o la del router empieza con 100.64 a 100.127), el puerto no se puede abrir y hay que ir a la opción B.
2. En el router: *Port forwarding* (o *Virtual server*) del **TCP 47900** a la IP local de tu PC (`ip -4 addr`). Conviene fijar esa IP con una reserva DHCP.
3. Si usás firewall en la PC: `sudo ufw allow 47900/tcp` (o el equivalente de firewalld).
4. Arrancar el relevo: `python3 server/relevo.py` o, para que quede siempre andando, la unidad de systemd (ver abajo).
5. La dirección es tu IP pública: `RELEVO=<ip-pública>:47900`. Las IP de casa suelen cambiar. Un nombre gratis de DuckDNS (`raices.duckdns.org`) lo resuelve, con su script de actualización cada 5 minutos.
6. Para probarlo desde afuera: con el celular sin wifi, `nc -vz <ip-pública> 47900` desde una app de terminal, o pedile a un amigo que cree una sala.

### Opción B: un VPS chico

Queda prendido siempre y no expone tu IP.

- **Oracle Cloud Always Free** (gratis): una VM *VM.Standard.E2.1.Micro* (1 GB) o *Ampere A1*, con Ubuntu. Hay que abrir el puerto en **dos** lugares:
  - en la consola: *VCN → Security List → Add Ingress Rule*, TCP, origen `0.0.0.0/0`, puerto 47900;
  - en la VM, porque la imagen de Oracle trae iptables cerrado: `sudo iptables -I INPUT 6 -p tcp --dport 47900 -m state --state NEW -j ACCEPT && sudo netfilter-persistent save`.

  Oracle a veces recupera las VM gratis que no se usan y a veces no hay capacidad en la región. Si molesta, la opción de pago más simple es la de abajo.
- **De pago**: Hetzner CX22 (unos 4 € por mes), DigitalOcean o Vultr (de 4 a 6 USD por mes). Con 512 MB alcanza.

**Lista corta para el VPS de pago (C-102 c, lo que elegiste).** Con Hetzner; en DigitalOcean o Vultr los pasos son los mismos con otros nombres.

1. **Crear la cuenta** en https://console.hetzner.cloud y un proyecto («raices»).
2. **Subir tu clave SSH**: *Security → SSH keys → Add SSH key*, pegando `~/.ssh/id_ed25519.pub` (si no tenés una: `ssh-keygen -t ed25519`).
3. **Crear el servidor**: *Add Server* → ubicación cercana a tus amigos (con Sudamérica, la de Estados Unidos, Ashburn o Hillsboro, da menos ping que las de Europa) → imagen **Ubuntu 24.04** → tipo **CX22** (o el más barato que haya: con 512 MB alcanza) → tu clave SSH → *Create & Buy*. Anotá la IPv4.
4. **Entrar**: `ssh root@<ip>`. Actualizar: `apt update && apt -y upgrade` (Ubuntu ya trae Python 3).
5. **Copiar el relevo** desde tu PC, en la raíz del repositorio: `scp server/relevo.py server/raices-relevo.service root@<ip>:/root/`.
6. **Instalarlo con la unidad que ya está** (en el VPS):
   ```
   useradd --system --no-create-home raices
   install -D -m 644 /root/relevo.py /opt/raices/relevo.py
   install -m 644 /root/raices-relevo.service /etc/systemd/system/
   systemctl daemon-reload && systemctl enable --now raices-relevo
   systemctl status raices-relevo      # tiene que decir active (running)
   ```
7. **Abrir el puerto 47900/TCP**. En Hetzner, si le pusiste un *Firewall* al servidor, sumale la regla de entrada TCP 47900 (y la 22 para SSH). En la VM, si usás ufw: `ufw allow 22/tcp && ufw allow 47900/tcp && ufw enable`.
8. **Probar desde tu PC**: `nc -vz <ip> 47900` tiene que decir *succeeded*; después crear una sala en el juego con `Relevo = <ip>:47900`.
9. **Dejarlo fijo para los amigos**: `RELEVO=<ip>:47900` en `~/.config/raices/publicar.env` y una versión nueva con `tools/publicar.sh --subir`. El relevo queda dentro del zip (`relevo.txt`) y los amigos solo escriben el código de la sala.
10. **Mantenimiento**: para actualizar el relevo, repetir 5 y `systemctl restart raices-relevo`; para ver qué pasa, `journalctl -u raices-relevo -f`. Hetzner cobra por hora hasta que borrás el servidor.

**Con systemd** (en la PC o en el VPS):

```
sudo useradd --system --no-create-home raices
sudo install -D -m 644 server/relevo.py /opt/raices/relevo.py
sudo install -m 644 server/raices-relevo.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now raices-relevo
journalctl -u raices-relevo -f      # salas que se abren y rechazos
```

**Con Docker**: copiar la carpeta `server/` y correr

```
docker build -t raices-relevo server/
docker run -d --name raices-relevo --restart unless-stopped -p 47900:47900 raices-relevo
```

Para actualizar el relevo alcanza con copiar `relevo.py` de nuevo y reiniciar. No depende de la versión del juego.

## 4. En el juego

- Menú → **Red** → fila **Relevo**. La dirección sale, en este orden, de lo último que escribió ese jugador (`user://red.cfg`), de `relevo.txt` al lado del ejecutable y de `relevo.servidor` en `data/red.json` (vacío en el repositorio). Si no hay ninguna, el jugador la escribe; el campo muestra `dirección:47900` de ejemplo.
- Uno toca **Crear sala** y pasa el código de 6 letras. El otro lo escribe y toca **Unirse**.
- Versiones distintas: el relevo no las junta. El que llega ve «Tu amigo tiene otra versión del juego: actualicen los dos a la última. La tuya es …». Con la app de itch alcanza con abrirla para actualizar.
- Si jugás desde el editor contra un amigo que tiene la versión publicada, no van a coincidir, porque el editor no lleva el sello de versión. Para jugar con amigos, usá la versión publicada.
