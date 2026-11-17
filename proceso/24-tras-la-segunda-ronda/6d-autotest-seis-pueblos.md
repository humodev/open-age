# 24 · Paso 6d: el autotest con los seis pueblos

## Pedido
`godot --path . -- --autotest --civ=mapuches --terreno=llano` daba 4 fallas que ya existían (también con `--animaciones=0`). Correr el autotest con los seis pueblos (tawantinsuyu, mapuches, guaraníes, etiopía, palmares, ayutthaya) y, para cada falla, decidir si el error es del juego (y arreglar el juego) o de la comprobación, que asume un centro común (y adaptarla para que pruebe lo equivalente de cada pueblo). Ver también si la falla intermitente «cursor de juntar alimento sobre un animal propio» se puede volver estable.

## Lo que salió antes
- **Mapuches** ([salida](pruebas/6d-autotest-mapuches-antes.txt)): 4 fallas.
- **Palmares** ([salida](pruebas/6d-autotest-palmares-antes.txt)): 12 fallas y un error de script; no estaban en el pedido, salieron al correr los seis.
- **Tawantinsuyu** ([salida](pruebas/6d-autotest-tawantinsuyu-antes.txt), con la comprobación de íconos de antes y lo demás nuevo): la misma falla de «la edad 0». Etiopía y Ayutthaya no se corrieron con el código de antes; su centro tiene la misma forma (ver abajo).
- Guaraníes: OK.

## Cada falla

### Mapuches

| Falla | De quién | Causa | Arreglo |
|---|---|---|---|
| «otra H lleva al centro siguiente» y «H dos veces seguidas centra la cámara en ese centro» | **del juego** y de la comprobación | H recorría solo la capital y los edificios de tipo `centro` (`Atajos.centros`). Los mapuches no tienen centro: su centro es el lof (`inicio_edificio`), y los lof que no son la capital no entraban. Además la comprobación ponía un segundo `centro` solo si el pueblo lo tenía, así que con mapuches no ponía nada y las dos fallaban. | `src/game/ui/atajos.gd`: H recorre también el edificio de inicio del pueblo (`civ.inicio_edificio`, el lof). `main.gd → _autotest_veterano4`: el segundo centro es el edificio de inicio del pueblo. |
| «una investigación de la edad 0 queda «bloqueado» (?)» | de la comprobación | No hay ninguna investigación con edad 0 en `data/`: el «0» era el valor por defecto de un resultado vacío. El lof entrena aldeano, explorador y guerrero, y con eso las investigaciones no entran en la raíz de la grilla: van al submenú «Investigar». La comprobación solo miraba la raíz. El centro de Tawantinsuyu, Etiopía y Ayutthaya también lleva ese submenú (cumbi, desarmar la corte, elefante del rey): Tawantinsuyu fallaba igual. Con la comprobación nueva pasan los cuatro. | `autotest_iconos.gd`: busca en la raíz y en el submenú de investigaciones (`_con_investigar`), y para la edad II y «en curso» abre ese submenú como lo haría el jugador (la ficha relee el comando de la grilla abierta). [Captura](capturas/6d-investigaciones-del-lof.png): el submenú del lof con «Marcha forzada» disponible. |
| «en la grilla, lof dice que recibe alimento (común «Centro chico», ícono ruka)» | de la comprobación | Los mapuches no tienen almacenes: el depósito más barato que construye el aldeano es el lof. La comprobación pedía el ícono de un almacén de alimento. La ayuda del lof ya dice «Recibe alimento, madera, piedra y riqueza.». | `main.gd`: vale el ícono de almacén **o** el renglón «Recibe … alimento» de la ayuda (`Ficha._cmd_content`). El mensaje muestra el renglón. |

La «cuarta» es la segunda de H: las dos fallan por la misma causa. La intermitente del animal propio pasó en la [corrida de antes](pruebas/6d-autotest-mapuches-antes.txt); se trata aparte, más abajo.

### Palmares
Palmares no entrena aldeanos (llegan por la fama, `acogida`) y no tiene asedio («Sin caballo ni asedio»).

| Falla | De quién | Causa | Arreglo |
|---|---|---|---|
| «Q en el centro encola un aldeano» | de la comprobación | En Palmares Q está vacía; el centro entrena el batedor (W). | `main.gd`: si el centro no entrena aldeanos, se aprieta la tecla de lo primero que entrena («W en el centro encola Batedor»). |
| «la cola global muestra lo que se produce (0)» y «clic en la cola global selecciona el edificio» | de la comprobación | La prueba encolaba un aldeano en la capital, y la de Palmares no lo acepta. | Encola lo primero que entrena el centro (el batedor). |
| Error de script en `ficha.gd:293` y las 6 del aldeano en `autotest_iconos.gd` («falta», «Falta: …», «aldeano en Q», «Podés entrenarlo», población llena ×2) | de la comprobación | Buscaba el comando `aldeano` en la grilla del centro; sin él, pasaba un diccionario vacío a la ficha. | Usa el aldeano o, si no está, lo primero que entrena el centro, con su casilla. |
| «el aviso dice que los edificios caen con asedio» | de la comprobación | Sin asedio en el pueblo, el aviso del empujón ya no lo nombra (correcto). | Si el pueblo tiene asedio lo tiene que nombrar; si no, no. |
| «el aviso de la pelea dice qué llevar: asedio y la tropa que les gana» | **del juego** | El aviso decía «Llevá: asedio y Gente de guerra»: pedía algo que Palmares no puede hacer. | `src/game/ui/consejos.gd → fight_text`: sin asedio en el pueblo no se pide asedio en «Llevá:» ni en «Contra lo que tira flechas…, el asedio con clic derecho». Queda «Llevá: Gente de guerra (Casa de guerra)». La comprobación pide eso para Palmares. |

## El cursor sobre el animal propio
La comprobación ponía la llama junto a la base (4 casillas al oeste y 6 al sur), donde los aldeanos van y vienen de los arbustos, con el juego andando. Tres cosas podían hacer que diga «mover»:
1. otro aldeano pasaba por delante y `pick` lo elegía a él (o a nadie);
2. la llama pasta: entre tomar la posición y mirar el cursor se movía;
3. el punto en pantalla se tomaba a 0,3 de altura y `pick` mira a 0,45.

Ahora: la llama se pone en la casilla libre más cercana a ese lugar **sin unidades a 3,5 casillas** y dentro de la pantalla (fuera del panel), se espera a que nazca su figura, **se pausa** el juego 20 cuadros para que quede quieta, y el mouse va a su figura a 0,45 (lo mismo que mira `pick`). El mensaje dice qué hay bajo el cursor. En las 8 corridas de este paso pasó siempre («bajo el cursor: rebano»). No hay forma de probar que una intermitente desapareció, pero las tres causas ya no están.

Tropiezo: la primera versión pausaba antes de poner la llama, y con el juego en pausa no corre el tick que crea su figura: «bajo el cursor: nada». Se pausa después.

## Pruebas
- Autotest, `--terreno=llano`: **OK** en los seis — [tawantinsuyu](pruebas/6d-autotest-tawantinsuyu.txt), [mapuches](pruebas/6d-autotest-mapuches.txt), [mapuches con `--animaciones=0`](pruebas/6d-autotest-mapuches-animaciones0.txt), [guaraníes](pruebas/6d-autotest-guaranies.txt), [etiopía](pruebas/6d-autotest-etiopia.txt), [palmares](pruebas/6d-autotest-palmares.txt), [ayutthaya](pruebas/6d-autotest-ayutthaya.txt).
- Determinismo ([resultado](pruebas/6d-test_determinism.txt)): OK, hash **2203695307**, el mismo: no se tocó la simulación.
- [`tests/casillas.gd`](pruebas/6d-casillas.txt): 532 grillas, OK. [`tests/grilla.gd`](pruebas/6d-grilla.txt): OK.

## Lo que queda
- Godot 4.7.2 se cae **al salir** de cada autotest (`corrupted size vs. prev_size` / `double free or corruption`, código 134), antes y después de este paso, con cualquier pueblo. El «AUTOTEST: OK/FALLO» ya se imprimió: no cambia el resultado, pero quien mire el código de salida ve un error.
- La ficha de «Marcha forzada» en el lof dice «Investigación · Ruka de guerra» (el edificio de `data/`), aunque se investiga ahí mismo: es la misma ficha para todos los edificios que la ofrecen.
- La campana (alarma) sale solo en la capital y en los `centro`; en los lof que no son capital no. No se tocó.

## Commits
- `Etapa 24, paso 6d: el autotest pasa con los seis pueblos (H recorre los lof, sin asedio no se pide asedio)`.
