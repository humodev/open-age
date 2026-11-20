# Procesar una tanda de arte: `tools/procesar_arte.py`

Lleva lo que se baja de Recraft (`~/Descargas`, nombres genéricos, a veces en .zip) a la ruta de destino que figura en `prompts.html`. Hace lo mismo que se hizo a mano con los 8 retratos incas.

## Uso

Hace falta un Python con Pillow y rembg (el modelo `isnet-general-use` está en `~/.rembg/models/`). La hoja de contacto anda con el Python del sistema.

```
python tools/procesar_arte.py ~/Descargas/images.zip --hoja=hoja.png      # hoja numerada + hoja_mapa.txt
python tools/procesar_arte.py ~/Descargas/images.zip --mapa=mapa.txt --seco   # solo revisa el mapeo
python tools/procesar_arte.py ~/Descargas/images.zip --mapa=mapa.txt [--raiz=DIR] [--pisar]
```

**Mapeo**: un archivo de texto con una línea por imagen, `imagen = destino`. Del lado izquierdo va el nombre del archivo o su número en la hoja de contacto. El destino es la ruta «Guardar como» de `prompts.html`. En los íconos se puede agregar `| nombre`, que es el nombre del ícono en `data/iconos.json → imagenes`. Hay un ejemplo en `mapa_ejemplo.txt`.

## Qué hace según la ruta

| Ruta | Salida |
|---|---|
| `retratos/` | 384×510 con fondo, y recortado en `retratos_recorte/`. El original va a `referencia_3d/retratos/` |
| `iconos/`, `edificios/`, `mejoras/`, `comun/edadN` | Recorte con rembg, figura en la caja de 52/64, contorno oscuro de 2/64 y el marco de `iconos_render.py`. Salen `_32`, `_64` y `_256.png` |
| `hojas3d/` | Sin recortar. El original va a `referencia_3d/hojas3d/` (fuera de git) y en la ruta queda una miniatura de 512 |
| `pantallas/`, `campana/`, `comun/{menu_fondo,titulo,derrota,victoria}` | 1920×1080, recortado al centro, en JPG de calidad 85 (la extensión cambia a `.jpg`) |
| `accesorios/` | Recortado en alta resolución, ajustado al contenido. El original va a `referencia_3d/accesorios/` |

**Registro.** Los íconos se agregan a `data/iconos.json → imagenes` con la versión `_64`. La clave es el nombre que se dé con `|`; si no hay, se usa `comun` → nombre del archivo, y para los de un pueblo, `pueblo/archivo`. Esas claves de pueblo el juego todavía no las lee. Los retratos van a `data/retratos.json` si ese archivo existe. Como hoy no existe, el script imprime la lista `pueblo/archivo → {fondo, recorte}`.

**Revisión.** El script avisa en estos casos:
- la imagen es chica o parece vacía (de un solo color);
- la proporción no sirve para el tipo;
- el recorte quedó casi vacío, no sacó el fondo o dejó el alfa difuso;
- hay destinos repetidos (gana el primero) o una imagen va a dos destinos;
- un destino no figura en `prompts.html`;
- quedaron imágenes sin asignar.

Lo que ya existe no se pisa salvo con `--pisar`.

## Prueba (2026-11-19)

- **Retratos**: se corrió `images.zip` con `mapa_ejemplo.txt` y `--raiz` apuntando a una carpeta del scratchpad. Salieron 24 archivos (8 retratos, 8 recortes y 8 originales) sin avisos. Comparados con los que se habían procesado a mano en `assets/ui/arte/tawantinsuyu/`, la diferencia media por canal da menos de 1/255, tanto con fondo como recortados. Para armar el mapeo se emparejó cada imagen con el retrato elegido más parecido; las 8 coincidieron sin ambigüedad.
- **Otros tipos**: se corrió otro mapeo de prueba con las mismas imágenes. Salieron un ícono (`procesar_icono_prueba.png`), una hoja 3D, una pantalla y un accesorio, y el registro en una copia de `iconos.json`. También avisó del destino repetido, de la imagen con dos destinos, de las 3 imágenes sin asignar y de la pantalla que no es 16:9.
- **Hoja de contacto**: `procesar_hoja.jpg`.
