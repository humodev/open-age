# 40 · Generación de imágenes local (2026-11-20)

> **Pedido:** instalar generación de imágenes local y gratuita (ComfyUI, SDXL con IP-Adapter y, si entra, FLUX schnell), un script del repo para manejarla, una comparación con Recraft y una prueba de 4 o 5 estilos con 4 piezas cada uno: retrato del guerrero inca, ícono del ariete, casa inca y pantalla de carga de los Andes.

Página con los resultados: [`estilos.html`](estilos.html) (miniaturas en `estilos/`, JPG de 512 px como mucho).

## Qué se instaló y dónde

Todo fuera del repo, en `/mnt/games/01_Projects/comfyui/` (**29 GB** en disco, contando el caché de uv, que comparte enlaces con el entorno).

| Pieza | Dónde | Tamaño | Licencia |
|---|---|---|---|
| ComfyUI (git, 2026-11-19) | `ComfyUI/` | — | GPL-3.0 (es una herramienta; las imágenes no heredan la licencia) |
| Entorno Python 3.12 (uv), torch 2.11 + CUDA 12.8 | `venv/` | 8,6 GB | — |
| **DreamShaper XL Turbo v2.1** (SDXL afinado, pintado) | `models/checkpoints/DreamShaperXL_Turbo_v2_1.safetensors` | 6,9 GB | **CreativeML OpenRAIL++-M**, según [huggingface.co/Lykon/dreamshaper-xl-v2-turbo](https://huggingface.co/Lykon/dreamshaper-xl-v2-turbo): permite el uso comercial con las restricciones de uso de OpenRAIL |
| IP-Adapter Plus SDXL (ViT-H) | `models/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors` | 0,8 GB | Apache 2.0 ([h94/IP-Adapter](https://huggingface.co/h94/IP-Adapter)) |
| Codificador de imagen CLIP ViT-H | `models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` | 2,4 GB | MIT (OpenCLIP), de h94/IP-Adapter |
| Nodos ComfyUI_IPAdapter_plus (cubiq) | `custom_nodes/` | — | GPL-3.0 |
| FLUX.1 schnell GGUF Q4_K_S | `models/unet/flux1-schnell-Q4_K_S.gguf` | 6,8 GB | **Apache 2.0** ([city96/FLUX.1-schnell-gguf](https://huggingface.co/city96/FLUX.1-schnell-gguf)) |
| T5-XXL GGUF Q4_K_M y CLIP-L | `models/text_encoders/` | 2,9 + 0,25 GB | Apache 2.0 |
| VAE de FLUX (`ae.safetensors`) | `models/vae/` | 0,3 GB | Apache 2.0; bajado de Comfy-Org/Lumina_Image_2.0_Repackaged porque el repo de black-forest-labs pide cuenta |
| Nodos ComfyUI-GGUF (city96) | `custom_nodes/` | — | Apache 2.0 |
| Quitado de fondo: rembg con `isnet-general-use` | `venv/`, `modelos_rembg/` | 0,17 GB | MIT (rembg) y Apache 2.0 (IS-Net) |

No se usó FLUX dev (licencia no comercial), ni BRIA RMBG (no comercial), ni Juggernaut XL (licencia propia de RunDiffusion).

Otros archivos: `arrancar.sh` (arranque), `descargar.sh` (bajada de modelos, reanudable), `tandas.py` (las tandas de esta etapa) y `output/` (originales en PNG).

## Cómo se usa

```sh
/mnt/games/01_Projects/comfyui/arrancar.sh          # ComfyUI en http://127.0.0.1:8188
PY=/mnt/games/01_Projects/comfyui/venv/bin/python
$PY tools/generar_local.py "Unit portrait of an Inka slinger, painterly" \
    --ref assets/ui/arte/tawantinsuyu/retratos/*.png --peso-ref 0.8 \
    --ancho 896 --alto 1152 --semilla 7 --cantidad 2 --jpg 512 --salida salida/hondero
$PY tools/generar_local.py "icon of a battering ram ..." --modelo flux --sin-fondo --salida salida/ariete
```

- `--ref` sube las imágenes a ComfyUI y las promedia en IP-Adapter. `--tipo-ref "style transfer"` (por defecto) copia solo el estilo; `linear` copia también la cara, la ropa y la composición.
- Por defecto usa SDXL Turbo con 8 pasos, CFG 2 y dpmpp_sde karras; con FLUX, 4 pasos y CFG 1. IP-Adapter solo funciona con SDXL.
- `--sin-fondo` guarda además `*_sinfondo.png` (rembg); `--jpg N` guarda una miniatura.
- Por cada tanda deja `<salida>_meta.json`, con el prompt, la semilla y los segundos.
- Para apagar: `pkill -f "^../venv/bin/python main.py --listen 127.0.0.1 --port 8188"`.

`arrancar.sh` usa `--lowvram --disable-smart-memory --disable-pinned-memory`. Por defecto, ComfyUI fija 15 GB de RAM y guarda los modelos entre corridas. La primera sesión se cayó al llenarse la RAM, con SDXL cargando a la vez que 4 Godot de un torneo.

## Tiempos (RTX 2060 Super; el escritorio ocupa unos 2 a 3 GB de VRAM)

| Caso | Por imagen |
|---|---|
| SDXL Turbo, 1024 px, 8 pasos, con o sin IP-Adapter | **13–14 s** (unos 10 s de muestreo y el resto en recargar) |
| Primera imagen de SDXL en la tanda | 25 s (75 s en frío) |
| FLUX schnell Q4, 1024 px, 4 pasos | **18–25 s** (2,8 s por paso) |
| Primera imagen de FLUX | 89 s |

Fueron 57 imágenes contando los descartes (32 en la página), en unos 15 minutos de generación. La RAM disponible nunca bajó de 9 GB.

## Resultados

1. **Comparación con Recraft:** la pintura, la luz y el fondo se parecen mucho. La fidelidad no: la mapuche y la guaraní salen vestidas de inca, por el peso de la referencia; el lancero, con hombreras de fantasía. Con IP-Adapter en `linear` las cuatro salían casi iguales. Esos originales quedaron en `output/proceso40/comparacion_linear/`.
2. **Estilos:** el texto de estilo casi no cambiaba nada hasta que se puso adelante y con peso (`(low poly 3d model:1.5)`). Esa es la segunda pasada, la de la página; la primera está en `output/proceso40/estilos_v1/`.
   - **A** (pintado semirrealista con referencias): el más coherente con lo aprobado.
   - **B** (Warcraft o Northgard): se va a la fantasía.
   - **C** (grabado): lindo en los paisajes, pero cae en estereotipos con las personas.
   - **D** (low poly): sirve para piezas de juego, aunque la arquitectura sale europea.
   - **E** (textil): propio, pero solo sirve para la interfaz.
3. **FLUX schnell** sigue el texto mucho mejor que SDXL: dibujó la porra estrellada, el ariete y la kancha con techo de ichu. SDXL no supo dibujar el ariete en tres pasadas: hizo cañones, un toro y un árbol.

## Límites

- **VRAM:** con 8 GB y el escritorio encima, SDXL entra entero, pero FLUX Q4 se descarga en parte a la RAM. No conviene usar más de 1024 px, ni más de una imagen a la vez, ni SDXL y FLUX juntos. Con el juego abierto, la RAM también aprieta.
- **Consistencia:** IP-Adapter copia la paleta y la pincelada, pero no la identidad de cada pueblo. A más peso, más copia la ropa inca en otros pueblos; a menos peso, se va el estilo. La misma semilla no da la misma cara entre piezas.
- **Conocimiento:** SDXL no conoce objetos andinos (ariete, kancha, tocapu) y tira hacia los estereotipos (plumas, torso desnudo, cascos romanos). Hacen falta prompts negativos por pueblo, y para los objetos, FLUX o una guía de forma (ControlNet desde un boceto o desde el modelo 3D).
- Las imágenes salen a 1024 px; para las pantallas de carga a 1920 px hay que escalar.
- `prompts.html` (etapa 39) nombra «Hondero de piedra caliente (ariete)» en el ícono y en el retrato del ariete inca: es la unidad que ocupa ese lugar en el Tawantinsuyu. Para esta prueba se pidió un ariete literal.

## Próximo paso

Entrenar un **LoRA de SDXL** con 20 a 30 imágenes aprobadas por el autor: los 8 retratos de Recraft, más los mejores locales del estilo A y de FLUX, de varios pueblos, con leyendas que nombren el pueblo y la prenda. Con 8 GB se puede usar kohya_ss o OneTrainer en fp16, con gradient checkpointing, a 768 a 1024 px, en 1 a 2 horas. Con el LoRA, el estilo queda fijo sin IP-Adapter, y el texto vuelve a mandar en la ropa de cada pueblo. Hasta entonces: estilo A con SDXL y referencias para los retratos, y FLUX para los objetos y los edificios.

## Commits

- Script `tools/generar_local.py`, esta carpeta y la línea del índice. Sin modelos en el repo.
