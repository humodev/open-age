# 37 · 04 · Relevo y salas: jugar por internet sin abrir puertos

## Pedido

Jugar por internet sin abrir puertos. Hace falta un servidor liviano de relevo y salas para un VPS barato: salas con código corto, reenvío de los paquetes del lockstep sin simular nada, rechazo de las versiones distintas y topes de tamaño y de salas. Del lado del cliente, un transporte «relevo» en `src/net`, que se elige en la sala del menú. Además, una prueba de 2 minutos por el relevo y este documento.

## Qué entró

| Archivo | Qué hace |
|---|---|
| `server/relevo.py` | El relevo: Python 3 con asyncio, sin dependencias, unas 220 líneas. Salas con código de 6 letras (sin I ni O), reenvío ciego, versión, topes, latido y barrido de salas vacías |
| `src/net/relevo.gd` | `RedRelevo extends RedTransporte`: la misma interfaz (`crear`, `unirse`, `enviar`, `poll`, señales), por TCP al relevo. `RedRelevo.version()` es la versión del proyecto, más la de Godot, más los primeros 16 caracteres del sha256 de `data/**/*.json` |
| `src/net/sesion_red.gd` | `usar_relevo(servidor, puerto, codigo)` cambia el transporte. `codigo_relevo()` y los avisos están marcados `# --- relevo ---`. La sesión, el lockstep, la foto y la reconexión no cambian |
| `src/net/sala.gd` | Fila «Relevo» (servidor:puerto, **Crear sala**, código, **Unirse**) y el código grande con la sala abierta. Todo marcado `# --- relevo ---` |
| `data/red.json` | `relevo`: servidor y puerto por defecto, latido y reintento |
| `tests/red_relevo.gd` | Levanta el relevo en 127.0.0.1 y lanza dos clientes |

### Por qué Python y no un Godot sin ventana

- Un VPS de 1 GB ya trae `python3`, así que no hay que subir el binario de Godot (unos 100 MB) ni el proyecto. Alcanza con copiar un archivo.
- El relevo no simula ni decodifica nada. Solo lee marcos con un largo adelante y los reenvía. Para eso asyncio sobra, y el proceso usa unos 15 MB de memoria en vez de los 80 a 150 de Godot.
- Es independiente del juego: no se rompe cuando cambian `src/` o Godot. Lo único compartido es el marco (cinco tipos, documentado arriba del archivo).

### Cómo funciona

- **Marco:** `[u32 big endian: largo][u8 tipo][carga]`. Los tipos son HOLA (JSON con juego, versión, `crear` o `unirse`, código y llave), RESP (JSON con `ok` y el código, el rol y la llave, o con el error), DATOS (se reenvía tal cual), DENTRO y FUERA (el otro entró o se fue) y VIVO (el latido, cada 5 s).
- Es TCP y no UDP: llega confiable y en orden, como el canal de ENet que usaba el lockstep. Con un turno de 100 ms y un retardo de entrada adaptable, el bloqueo de cabeza de línea de TCP no se nota en 1v1.
- **Versión:** la sala toma la versión de quien la crea. Si el invitado trae otra, el relevo lo rechaza con «versión distinta de la del anfitrión: actualicen los dos al mismo commit». Con `--version X`, el relevo acepta solo esa versión.
- **Topes:** `--max-bytes` por mensaje (8 MB por defecto; la foto de un 4v4 ronda los 400 KB). Un largo mayor corta la conexión sin leer el cuerpo. También hay `--max-salas` (200), conexiones como mucho 2 × salas + 8, `--silencio-s` (corta tras 60 s sin nada), `--espera-s` (una sala vacía dura 180 s, para volver con el código) y `--vida-h` (12 h por sala).
- **Reconexión:** el relevo guarda la sala aunque se vaya alguien. El invitado que vuelve de cero entra con el código y recibe la foto del anfitrión, como con ENet. El anfitrión que pierde la conexión con el relevo reintenta solo cada 2 s con su código y su **llave**. La llave le devuelve el lugar aunque el relevo todavía no haya notado el corte (una conexión medio abierta).
- El cliente no cambia en nada más: `SimRed`, `Lockstep` y la validación de lo que llega son los mismos. El relevo ve bytes y no puede leer ni cambiar los comandos más de lo que ya podía un rival con ENet.

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/red_relevo.gd`: 1200 ticks (2 min de juego), la IA de los dos lados por el relevo. El cliente se cae en el tick 400 y vuelve de cero con el código | OK dos veces. En la primera, hash 2743185193 en los dos; en la segunda, 2383403676. Partida recuperada por la foto en el tick 402 a 404, en unos 0,5 s. Hubo 25 y 27 comandos por el relevo. La corrida tarda de 19 a 27 s |
| Mismo archivo: otra versión, código falso y mensaje de 64 MB | Rechazados («versión distinta…», «no hay ninguna sala ZZZZZZ») y la conexión cortada |
| `tests/red.gd`, casos `directo` y `reconexion` (ENet, sin cambios) | OK |
| `tests/test_determinism.gd` | OK, hash 3059812827 (el de siempre) |
| Sala en ventana con el relevo local | `relevo-conexion.png` (fila nueva) y `relevo-sala.png` (sala VGSBRE abierta con el código) |

El hash de la partida cambia entre corridas porque el retardo de entrada se adapta al ping medido, y eso mueve el turno en que entra cada comando. Lo que se exige es que los dos lados den el mismo hash. Salida completa: [pruebas/04-relevo.txt](pruebas/04-relevo.txt).

```
godot --headless --path . -s tests/red_relevo.gd [-- --ticks=1200 --python=python3]
```

A mano, en la misma PC:

```
python3 server/relevo.py --ip 127.0.0.1
godot --path . -- --menu --abrir=red --red-relevo=127.0.0.1:47900 --red-relevo-crear=1 --red-civ=guaranies --red-terreno=llano --red-listo=1
godot --path . -- --menu --abrir=red --red-relevo=127.0.0.1:47900 --red-relevo-unirse=CODIGO --red-civ=mapuches --red-color=1 --red-listo=1
```

## Cómo desplegarlo en un VPS

**Requisitos:** cualquier Linux con Python 3.8 o más nuevo (Debian 12 y Ubuntu 22.04 o 24.04 lo traen). Con 1 vCPU y 512 MB a 1 GB alcanza de sobra. Una partida 1v1 mueve unos pocos KB/s por jugador (más una foto de 100 a 400 KB al reconectar), así que 100 partidas a la vez no llegan a 1 Mbit/s.

**Puerto:** 47900/TCP entrante (`--puerto`). Los jugadores solo salen hacia el VPS, y en sus casas no se abre nada.

```
sudo useradd --system --no-create-home raices
sudo install -D -m 644 server/relevo.py /opt/raices/relevo.py
sudo ufw allow 47900/tcp
```

`/etc/systemd/system/raices-relevo.service`:

```ini
[Unit]
Description=Relevo y salas de Raíces
After=network-online.target
Wants=network-online.target

[Service]
User=raices
ExecStart=/usr/bin/python3 /opt/raices/relevo.py --puerto 47900 --max-salas 200
Restart=always
RestartSec=2
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
MemoryMax=200M

[Install]
WantedBy=multi-user.target
```

```
sudo systemctl daemon-reload
sudo systemctl enable --now raices-relevo
journalctl -u raices-relevo -f      # salas que se abren y se cierran, rechazos
```

En el juego se cambia `relevo.servidor` en `data/red.json` por la IP o el dominio del VPS. También se puede escribir a mano en la sala. Ojo: `data/` entra en el hash de versión, así que el cambio vale para todos los clientes de esa versión. Para fijar una versión en el relevo, `--version` lleva el texto de `RedRelevo.version()`.

**Costo aproximado (precios de 2026):** un VPS chico cuesta de 4 a 6 USD por mes (Hetzner CX22 unos 4 €, DigitalOcean o Vultr de 4 a 6 USD, Oracle Cloud *free tier* gratis). El tráfico incluido (de 1 a 20 TB) queda muy lejos de lo que se usa. Un dominio es opcional, unos 10 USD al año.

## Lo que falta

- **NAT directo con perforación:** hoy todo pasa por el relevo, y eso suma la ida al VPS a la latencia. El paso siguiente: que el relevo, que ya conoce la IP y el puerto públicos de los dos, les pase la dirección del otro, y que los dos manden UDP a la vez (perforación). Si la perforación funciona, se pasa a ENet directo; si no (NAT simétrico, CGNAT), se queda en el relevo. ENet no trae perforación, así que hay que abrir el socket UDP antes y reusarlo (`ENetConnection` con un puerto local fijo).
- **Cuentas:** hoy cualquiera con el código entra. Faltan una identidad (aunque sea un nombre y una clave guardada en `user://`), bloqueo de quien molesta y salas con contraseña.
- **Emparejamiento:** una lista de salas públicas o una cola por nivel. El relevo ya tiene las salas en memoria: alcanza con un tipo de mensaje «listar» y una pantalla. El nivel (Elo) necesita cuentas y que el resultado lo informen los dos y coincida.
- **El anfitrión que vuelve de cero** abre una sala nueva con otro código. Para eso el juego tendría que guardar el código y la llave en `user://red/retomable.json` y usarlos al crear. ENet lo resolvía con el mismo puerto; por el relevo todavía no.
- **TLS:** el tráfico va sin cifrar, como con ENet. Se puede poner el relevo detrás de `stunnel` o usar `StreamPeerTLS` con un certificado de Let's Encrypt.
- **Más de dos jugadores:** el relevo tiene dos lugares por sala, como la sesión. Pasar a N lugares es poco trabajo cuando la sala del juego lo pida.
- **Límite por IP y por ritmo:** hay topes por mensaje y totales, pero no por IP ni de mensajes por segundo. En un VPS público conviene sumar `fail2ban` o un tope por IP.

## Tropiezos

- La sesión cerrada a propósito avisaba «Se cortó la conexión» a sí misma: `cerrar()` del relevo emitía `desconectado`. Ahora no avisa, igual que ENet.
- `put_data` de `StreamPeerTCP` bloquea hasta mandar todo. Para mensajes de pocos KB no se nota. Con la foto (cientos de KB) puede trabar un cuadro en una red lenta; habría que pasar a `put_partial_data` con una cola.

## Commits

- `51c7ad8` Relevo: servidor de salas y reenvío en Python (server/relevo.py)
- `ce5fc20` Relevo: transporte RedRelevo, sala con código en el menú y tests/red_relevo.gd
- (este) Avisos, capturas, salida de la prueba y este documento
