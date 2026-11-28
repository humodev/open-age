# 62 · Soldados de Meshy

## Pedido

El autor aprobó los soldados con la misma receta que los aldeanos (`proceso/56` y `proceso/57`): malla de Meshy, **nuestro** rig con las animaciones de KayKit, la ropa del equipo en rojo plano (máscara y `equipo_3d.gdshader`) y las armas como piezas en `handslot.r` y `handslot.l`. Cada unidad tiene su aspecto propio por pueblo (decisión del 2026-11-17).

- Presupuesto: ~700 créditos, a 30 por modelo: **23 modelos como máximo**.
- Primero las 3 tropas de a pie más usadas de cada pueblo (18), después las propias o montadas más usadas hasta 23.
- Hojas de referencia con FLUX (ComfyUI local), del mismo formato que `hoja_aldeano_e1_31.png`.
- **Acá no se llama a Meshy:** los modelos los genera la sesión principal.

## 1. Inventario y prioridad

### Cuánto se entrena cada unidad

No había registros por tipo de unidad (el torneo y `salud_ia` cuentan el ejército entero). Se jugaron seis partidas de IA contra IA de 22 minutos, en ronda (cada pueblo, dos partidas), contando el evento `trained` (script de una vez, fuera del repo):

| Pueblo | Infantería común | Propias y otras (de a pie) | Montados y elefantes |
|---|---|---|---|
| Tawantinsuyu | hondero 110, guerrero 47, lancero 28 | **boleador 42**, galgueros 6 | — |
| Mapuches | hondero (arquero) 86, guerrero (weichafe) 74, lancero (lanza larga) 18 | **incendiarios 6** | infantería montada 18, jinete 9 |
| Guaraníes | hondero (arquero) 121, guerrero 34, lancero 33 | arcabucero 0 | — |
| Etiopía | hondero (jabalinero) 58, lancero (chewa) 0, arcabucero 0 | **guerrero de gaša 26** | **guerrero (jinete noble) 78**, färäsäñña 8 |
| Palmares | hondero (flecheiro) 183, guerrero 9, lancero 5 | **zagaieiro 19**, **arcabucero (espingardeiro) 11**, guarnição 2 | — |
| Ayutthaya | guerrero (dap) 112, hondero (arquero) 67, lancero 9 | **ngao 10** | chang suek 7, elefante del rey 6 |

### Los 23 elegidos

- **Comunes (18):** guerrero, lancero y hondero de cada pueblo. En **Etiopía** el guerrero común es el jinete noble (montado): sus tres de a pie son lancero, hondero y **guerrero de gaša**, la propia más entrenada.
- **Propias (5):** boleador (Tawantinsuyu), zagaieiro y espingardeiro (Palmares), ngao (Ayutthaya) e incendiarios (Mapuches), por orden de uso entre las de a pie que quedan.

| Pueblo | Modelos |
|---|---|
| Tawantinsuyu | guerrero, lancero, hondero, boleador |
| Mapuches | guerrero, lancero, hondero, incendiarios |
| Guaraníes | guerrero, lancero, hondero |
| Etiopía | lancero, hondero, guerrero_gasa |
| Palmares | guerrero, lancero, hondero, zagaieiro, arcabucero |
| Ayutthaya | guerrero, lancero, hondero, ngao |

### Afuera: montados y elefantes

El jinete noble etíope (la unidad militar más entrenada de Etiopía), la infantería montada y el kona mapuches, el färäsäñña y los elefantes de Ayutthaya **no entran**:

- Meshy daría jinete y animal en una sola malla; nuestro rig (`gen3d_rig.py`) es de persona. Existe `tools/gen3d_rig_cuadrupedo.py` (proceso/47), pero solo trae caminar y quieto, sin ataque ni muerte.
- El juego no anima montados (`AldeanoAnimado.usa` los excluye): falta el jinete sentado con el golpe encima, el paso del caballo y colgar un esqueleto del otro (ver `proceso/27-animaciones/02-soldados.md`, sección 4).

## 2. Hojas de referencia

![Las 23 hojas](img/hojas_soldados.jpg)

**Salida:** `comfyui/output/<civ>_gouache/hoja_<unidad>_soldado_31.png` (`incas_gouache` para el Tawantinsuyu), con su `_mascara.png` y su `_meta.json`. Las descartadas quedan como `_v1` y `_v2`. Generador: [`hojas_soldados.py`](hojas_soldados.py).

**Receta:** FLUX schnell, semilla 31, 1152×768, frente a la izquierda y espalda a la derecha, pose A con las manos vacías, **sin arma, sin escudo y nada en la espalda** (el arma, el escudo y el carcaj van después como piezas). La cara es la del aldeano de cada pueblo (de su `hoja_aldeano_e1_meta.json`), compacta, con «a grown man about thirty-five years old, not a boy». Unas 170–185 palabras (FLUX corta el prompt cerca de 256 tokens).

**Ropa de guerra por pueblo** (las piezas de `proceso/42` y `proceso/49`; nada sagrado, sin estereotipos):

- **Tawantinsuyu:** unku rojo sin mangas; casco de caña tejida (guerrero y lancero), flecos bajo la rodilla (guerrero), la honda trenzada atada a la cabeza (hondero), vincha y faja crema (boleador); ojotas.
- **Mapuches:** makuñ rojo corto hasta el muslo, faja oscura; trarilonko (guerrero, hondero), gorro de cuero crudo (lancero), vincha oscura (incendiarios). Sin machi, rewe ni kultrun.
- **Guaraníes:** tipoy rojo corto y vincha de plumas de loro; el guerrero con pintura en los antebrazos, el lancero con bandas bajo las rodillas. Sin yvyra'i ni mbaraka.
- **Etiopía:** túnica roja larga; pantalón blanco ajustado y faja blanca (lancero); piel de colobo en los hombros (gaša). Sin cruces.
- **Palmares:** túnica roja corta; vincha crema (guerrero, flecheiro), cinto de fibra de palma, gorro oscuro y bandolera (espingardeiro). Gente que pelea, sin cadenas.
- **Ayutthaya:** chong kraben rojo; pecho desnudo y paño en la cabeza (dap), chaqueta roja (lancero, ngao), banda cruzada (arquero), casco redondo (ngao). Sin sak yant ni nada del templo.

**Intentos:**

1. Primer lote: los mapuches salieron de frente con túnica roja y de espalda con el chiripá oscuro (o al revés, con el pecho desnudo), y el boleador con la manta solo de espalda. Se cambió la ropa mapuche a un makuñ corto, igual en las dos vistas, y la manta del boleador por una faja.
2. Segundo intento con la semilla 32 para cuatro hojas con el tocado solo de espalda (Palmares guerrero y flecheiro, ngao y lancero de Ayutthaya): la 32 rompe la pose A (de perfil o con los brazos abajo). Quedaron las de la semilla 31; las de la 32 están como `_v2`.

**Vistas que no coinciden** (para Meshy, solo la de frente):

| Hoja | Qué cambia |
|---|---|
| mapuches guerrero, lancero, hondero, incendiarios | el tocado (trarilonko o gorro) solo de espalda |
| etiopia guerrero_gasa | de frente, pantalón corto crudo y sin la piel; de espalda, con la piel de colobo |
| palmares guerrero, hondero | la vincha solo de espalda |
| ayutthaya guerrero | el paño de la cabeza solo de espalda |
| ayutthaya lancero | de frente, faldón; de espalda, pantalón |
| ayutthaya ngao | el casco solo de espalda |
| guaranies lancero, hondero | de frente, faldón; de espalda, pantalón corto |
| tawantinsuyu boleador | una correa cruzada solo de espalda |

**Tropiezos:**
- ComfyUI se traba en el VAE a la tercera hoja: el `scope` aislado llega al tope (12 GB de `MemoryHigh` y 2 GB de swap) y el proceso queda frenado. `POST /free` no alcanza. Se lo reinició cada dos hojas.
- Al reiniciarlo desde un script en segundo plano, la primera hoja fallaba con un `KeyError` con el nombre del `scope`. Con `setsid` dejó de pasar.
- Varias caras salen sonrientes o con barba (inca, mapuche), por las «smile lines» del prompt. Todas son de 30 a 40 años.

## 3. En el juego

### Cómo se conectan

- **Interruptor** (`data/arte_animaciones.json → modelos`): `soldados[pueblo][tipo]` apunta a una entrada de `lista` (`sol_<pueblo>_<tipo>`); **una línea por unidad**, y sin la línea vuelve la figura de KayKit con su equipo. `soldados_activo: false` los apaga a todos (los aldeanos siguen).
- **`AldeanoAnimado.modelo_tropa(civ, tipo)`** arma el modelo una vez (el mismo `_armar_modelo` de los aldeanos: copia del esqueleto, biblioteca retargeteada compartida, material `equipo_3d.gdshader` por color de equipo). `crear()` se lo pone al soldado en lugar de la malla de KayKit.
- **El arma, el escudo y el carcaj** son las piezas de siempre (`TropaAnimada._arma`, `_escudo`, `_carcaj`, con lo de `tropas.tipos`, `por_forma` y `por_civ`): se arman en la plantilla y `AldeanoAnimado.llevar()` (lo que antes hacía `malla_modelo` para las herramientas) las pasa al hueso del modelo, `handslot.r` y `handslot.l`. El centro del escudo toma el color del equipo.
- La ropa, el tocado y el casco ya vienen en la malla: con modelo, el cambio de edad no cambia el soldado (sí en la figura de KayKit).
- Armas nuevas en los datos: el zagaieiro tira **jabalina** (antes, la honda de su función) y el guerrero de gaša lleva **lanza y escudo redondo** (antes, maza), como en sus piezas de `proceso/49`. Vale también para la figura de KayKit.

### Receta por modelo

[`procesar.sh`](procesar.sh) `<pueblo>_<unidad>`: espera 7 GB libres; `optimizar_glb` a 15.000 triángulos y 2048 px; `gen3d_rig --normalizar --cabeza-rigida --calor-escala=10`; `mascara_equipo_3d --metodo=rojo`; la textura a JPEG 80 con [`glb_jpeg.py`](glb_jpeg.py) (sin Blender). Blender con tope de 4 GB, de a un proceso. [`conectar.py`](conectar.py) agrega la entrada y la línea en los datos.

| Modelo | Triángulos | Vértices sin peso | Máscara | `luz_ref` | GLB |
|---|---|---|---|---|---|
| `tawantinsuyu_guerrero` | 15.000 | 0 | 51 % | 0,065 | 1,4 MB |
| `tawantinsuyu_lancero` | 14.999 | 0 | 35 % | 0,071 | 1,4 MB |
| `tawantinsuyu_hondero` | 14.999 | 0 | 36 % | 0,062 | 1,2 MB |
| `tawantinsuyu_boleador` | 14.999 | 0 | 30 % | 0,056 | 1,4 MB |
| `mapuches_guerrero` | 14.999 | 0 | 34 % | 0,075 | 1,4 MB |
| `mapuches_lancero` | 14.999 | 0 | 32 % | 0,064 | 1,3 MB |
| `mapuches_hondero` | 14.999 | 0 | 46 % | 0,053 | 1,3 MB |
| `mapuches_incendiarios` | 15.000 | 0 | 41 % | 0,050 | 1,4 MB |
| `guaranies_guerrero` | 15.000 | 0 | 41 % | 0,094 | 1,3 MB |
| `guaranies_lancero` | 15.000 | 0 | 58 % | 0,066 | 1,3 MB |
| `guaranies_hondero` | 15.000 | 0 | 41 % | 0,080 | 1,4 MB |
| `etiopia_lancero` | 15.000 | 0 | 58 % | 0,069 | 1,3 MB |
| `etiopia_hondero` | 14.999 | 0 | 49 % | 0,087 | 1,2 MB |
| `etiopia_guerrero_gasa` | 15.000 | 0 | 33 % | 0,052 | 1,1 MB |
| `palmares_guerrero` | 14.999 | 0 | 42 % | 0,099 | 1,1 MB |
| `palmares_lancero` | 15.000 | 0 | 42 % | 0,091 | 1,1 MB |
| `palmares_hondero` | 15.000 | 0 | 44 % | 0,081 | 1,2 MB |
| `palmares_zagaieiro` | 14.999 | 0 | 52 % | 0,095 | 1,3 MB |
| `palmares_arcabucero` | 14.999 | 0 | 51 % | 0,099 | 1,2 MB |
| `ayutthaya_guerrero` | 15.000 | 0 | 58 % | 0,067 | 1,2 MB |
| `ayutthaya_lancero` | 15.000 | 0 | 64 % | 0,063 | 1,2 MB |
| `ayutthaya_hondero` | 15.000 | 0 | 64 % | 0,060 | 1,2 MB |
| `ayutthaya_ngao` | 15.000 | 0 | 60 % | 0,070 | 1,2 MB |

### Por pueblo

Batalla de cerca de cada pueblo contra sí mismo, azul contra rojo (`tools/aldeanos_animados.gd --modo=batalla --civ=X --rival=X --terreno=llano --seed=7 --sin_hud --pitch=42 --zoom=8`). Las unidades que no son de Meshy (leva, arcabuceros, galgueros…) siguen con la figura de KayKit.

**Tawantinsuyu:** guerrero con porra, lancero con lanza y escudo cuadrado, hondero con honda y boleador con las boleadoras, todos de Meshy.

![Tawantinsuyu, azul contra rojo](img/batalla_tawantinsuyu.jpg)

**Mapuches:** weichafe con macana a dos manos, lanza larga de colihue sin escudo y arquero con arco y carcaj. Los incendiarios (asedio) no entran en la batalla de la herramienta; están conectados igual. El weichafe montado (que pelea a pie) sigue con la figura de KayKit.

![Mapuches, azul contra rojo](img/batalla_mapuches.jpg)

**Guaraníes:** guerrero con macana a dos manos, lancero con lanza y escudo redondo, arquero con arco y carcaj. El ka'aguygua y la milicia arcabucera siguen con KayKit. (El palo grande abajo a la derecha es una flecha en vuelo, cerca de la cámara.)

![Guaraníes, azul contra rojo](img/batalla_guaranies.jpg)

**Etiopía:** chewa con lanza y escudo redondo, jabalinero y guerrero de gaša, ahora con lanza y escudo redondo. Los jabalineros todavía tiran una piedra (el proyectil a distancia es el mismo para todos los que no son arqueros; ya era así). El jinete noble y los mosqueteros siguen como antes.

![Etiopía, azul contra rojo](img/batalla_etiopia.jpg)

**Palmares:** gente de guerra (con la maza común: su pieza de `proceso/49` lleva facão y escudo de palma, queda para `tropas.por_civ`), lanceiro, flecheiro con arco, zagaieiro con jabalina y espingardeiro con la espingarda. La guarnição y el capitão (con casco, atrás) siguen con KayKit.

![Palmares, azul contra rojo](img/batalla_palmares.jpg)

**Ayutthaya:** infantería de dap (una espada en cada mano), lancero con lanza y escudo redondo, arquero y ngao con la hoja curva sobre el asta. Los defensores de Suan Phlu, la compañía japonesa y la portuguesa siguen con KayKit (las figuras con casco).

![Ayutthaya, azul contra rojo](img/batalla_ayutthaya.jpg)

## 4. Rendimiento

200 soldados en pantalla (`tools/aldeanos_animados.gd --modo=fps --soldados=200 --aldeanos=0 --civ=tawantinsuyu --rival=tawantinsuyu --terreno=llano`): la mitad marcha y la mitad pelea; guerrero, lancero y hondero, que en el Tawantinsuyu ahora son todos de Meshy. Dos corridas de cinco rondas cada una ([antes](pruebas/fps_antes.txt), [después](pruebas/fps_despues.txt)):

| | FPS (mediana) | Vista (ms/cuadro) | GPU (ms) |
|---|---|---|---|
| Antes (figura de KayKit) | 56,0 y 56,8 | 5,05 y 4,99 | 11–17 |
| Con los soldados de Meshy | 48,2 y 49,8 | 5,51 y 5,33 | 9–20 |

- Se pierde un 13 % de los cuadros, como con los aldeanos (`proceso/57`: 46 contra 52). El costo es de GPU: 15.000 triángulos con piel por figura, contra unos 1.500 de la de KayKit. Los esqueletos compartidos siguen igual (la vista sube medio milisegundo).
- Si molesta en batallas grandes: una versión de 6.000–8.000 triángulos para lejos, o sin sombra lejos.

## 5. Pruebas

- `test_determinism`: **OK**, hash 3617052205, el mismo de antes ([pruebas/determinismo.txt](pruebas/determinismo.txt)): es solo imagen.
- `civ_smoke`: sin errores ([pruebas/civ_smoke.txt](pruebas/civ_smoke.txt)). `iconos`: OK (780 grillas). `grilla`: OK.
- Autotest con ventana, `--civ=etiopia --terreno=llano`: **AUTOTEST: OK** a la primera ([pruebas/autotest_etiopia.txt](pruebas/autotest_etiopia.txt)). Captura del inicio revisada.

## Tropiezos

- **No había cuentas por tipo de unidad**: el torneo y `salud_ia` cuentan el ejército entero. Un script de una vez contó el evento `trained` en seis partidas. La primera versión (12 partidas de 25 minutos) era demasiado lenta y se cortó.
- **ComfyUI trabado en el VAE** y el `KeyError` al reiniciarlo en segundo plano (ver la sección 2).
- **Datos rotos por una regex**: la primera versión de `conectar.py` buscaba el bloque `soldados` vacío con una expresión que se pasaba de largo y rompió el JSON. Se volvió a la versión de git y se cortó el bloque por posición.
- **Editar un script de bash mientras corre** lo rompe (bash lo lee de a pedazos): un lote se cortó con un error de sintaxis a la mitad.
- Las mallas llegaron de la sesión principal ya livianas (3,6–3,8 MB, con el remesh de Meshy): ninguna necesitó arreglos, y las 23 quedaron con 0 vértices sin peso.

## Lo que queda

- Montados y elefantes (sección 1).
- Unidades de a pie que siguen con KayKit: leva (awqa), galgueros, arcabuceros (salvo Palmares), ka'aguygua, guarnição, capitão, Suan Phlu, compañías japonesa y portuguesa, weichafe montado, exploradores y guardias.
- La gente de guerra de Palmares usa la maza común; su pieza lleva facão y escudo de palma.
- Los jabalineros tiran una piedra como proyectil.

## Cómo repetirlo

```sh
PY=/mnt/games/01_Projects/comfyui/venv/bin/python
$PY proceso/62-soldados-meshy/hojas_soldados.py <pueblo> <unidad> [semilla]   # ComfyUI arriba; reiniciarlo cada dos hojas
# Meshy (sesión principal) → .cache/meshy_soldados/<pueblo>_<unidad>.glb
bash proceso/62-soldados-meshy/procesar.sh <pueblo>_<unidad>
python3 proceso/62-soldados-meshy/conectar.py <pueblo>_<unidad>
godot --headless --path . --import   # dos veces
godot --path . -s tools/aldeanos_animados.gd -- --modo=batalla --civ=<pueblo> --rival=<pueblo> --terreno=llano --nofog --mute --seed=7 --sin_hud --pitch=42 --zoom=8
```

Para volver atrás una unidad, borrar su línea en `modelos.soldados`; todas, `soldados_activo: false`.

## Commits

- Proceso 62: inventario de soldados por uso, 23 hojas de FLUX para Meshy e interruptor por unidad (modelos.soldados)
- Proceso 62: soldados de Meshy del Tawantinsuyu (guerrero, lancero, hondero, boleador) conectados
- Proceso 62: soldados de Meshy mapuches (weichafe, lanza larga, arquero, incendiarios) conectados
- Proceso 62: soldados de Meshy guaraníes (guerrero de macana, lancero, arquero) conectados
- Proceso 62: soldados de Meshy de Etiopía (chewa, jabalinero, guerrero de gaša) conectados
- Proceso 62: soldados de Meshy de Palmares (gente de guerra, lanceiro, flecheiro, zagaieiro, espingardeiro) conectados
- Proceso 62: soldados de Meshy de Ayutthaya (dap, lancero, arquero, ngao) conectados; los 23
- Proceso 62: rendimiento, pruebas, índice y estado
