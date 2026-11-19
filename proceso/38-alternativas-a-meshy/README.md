# 38 · Alternativas a Meshy (2026-11-19)

> **Pedido del autor (textual):** «Poné a otro agente a buscar alternativas a Meshy gratuitas que podamos ir probando, para no estar esperando por los créditos y aprovechar la mayor cantidad de créditos gratuitos de todos lados.»

Es una investigación: no se crearon cuentas, no se usaron claves y no se corrió Godot. Los datos se buscaron en la web el **2026-11-19**. Lo marcado **[verificar]** no se pudo confirmar en una fuente oficial y hay que mirarlo al crear la cuenta. Los planes cambian seguido: conviene revisar la página de precios de cada servicio antes de gastar.

Qué hace falta (de `27-animaciones`, C-98, C-99 y la decisión del 2026-11-17):

- aldeanos y soldados de seis pueblos, con una versión de cada unidad por pueblo;
- caballos, llamas y elefantes;
- edificios por pueblo y por edad;
- riggear los humanoides para usar las animaciones de KayKit (`Rig_Medium`). Hoy los modelos de Meshy son una sola malla sin esqueleto y con los brazos pegados al cuerpo (`27-animaciones/README.md`, "Cómo retargetear los modelos de Meshy").

**Arte 2D e interfaz** (íconos, retratos, HUD, pantallas, banderas, terreno y cursores): ver [`2D.md`](2D.md).

## 1. Servicios en línea

| Servicio | Gratis | Modelos aprox. | API gratis | Uso comercial en el nivel gratis | Low poly / RTS | Exporta | Riggea |
|---|---|---|---|---|---|---|---|
| **Meshy** (hoy) | 100 créditos por mes | Pocos (de 5 a 20 créditos cada uno, según la versión) [verificar] | Sí, la que usamos (`tools/meshy_api.py`) | CC BY 4.0: hay que atribuir | Buena; tiene remesh a pocos polígonos | glTF, FBX, OBJ | Sí, humanoides, con créditos |
| **Tripo** (web) | 300 créditos por mes | ~10 a 30 [verificar] | No | **No**: los modelos son públicos, con CC BY 4.0 y sin uso comercial (las fuentes se contradicen) [verificar] | Muy buena; tiene "Smart Mesh" (retopología) y modo low poly | glTF, FBX, OBJ, USDZ | **Sí**: autorrig y animaciones, también de cuadrúpedos [verificar] |
| **Tripo** (API, platform.tripo3d.ai) | **2000 créditos al generar la primera clave** (una sola vez) | ~50 a 100 modelos texturados [verificar] | **Sí** | Lo dicen los términos de la API [verificar] | Igual que la web | glTF, FBX | **Sí**: tareas de rig y retarget por API |
| **Hunyuan3D Global** (web, 3d.hunyuanglobal.com) | **20 generaciones por día** | ~600 por mes | — | En los términos del servicio [verificar] | Buena forma; textura algo realista | glTF, OBJ, FBX [verificar] | No consta |
| **Hunyuan3D** (API de Tencent Cloud Internacional) | 200 créditos al activar (una vez); 20 créditos por modelo | 10 | Sí | En el contrato de Tencent Cloud [verificar] | Igual que la web | glTF | No |
| **Rodin / Hyper3D** | Solo vistas previas; se exporta gratis solo de modelos viejos | 0 útiles | No (API desde el plan Business, 120 USD por mes) | No | Muy buena calidad, cara | glTF, FBX | No |
| **3D AI Studio** | Créditos mensuales en el plan gratis [verificar cuántos] | Pocos | Sí | Sí, según su propia comparativa [verificar] | Junta varios modelos (Meshy, Tripo, Rodin, Hunyuan, TRELLIS 2) | glTF, FBX, OBJ | Sí, un autorrig |
| **Sloyd** | 1 generación por día, plantillas paramétricas sin límite | ~30 por mes | No | [verificar] | **Muy buena para utilería y edificios low poly** (plantillas) | glTF, OBJ | No |
| **CSM (Cube)** | Créditos de prueba [verificar cuántos] | Pocos | Sí | [verificar] | Media | glTF, FBX | No consta |
| **Luma Genie** | Créditos limitados gratis; dicen que es comercial | Pocos | No consta | Sí [verificar] | Media, más estilo juguete | glTF, FBX | No |
| **Kaedim** | Sin nivel gratis (desde 50 USD por mes), solo prueba | — | — | — | Buena, con retoque humano | — | — |
| **Spline AI** | Plan gratis; la generación 3D con IA está limitada [verificar] | Pocos | No | [verificar] | Baja para juego | glTF | No |
| **Hitem3D** | 100 créditos, una sola vez | Pocos | No | [verificar] | Buena | glTF, FBX | No |
| **Hugging Face Spaces** (TRELLIS 2, Hunyuan3D 2.1) | Cuota diaria gratis de GPU (ZeroGPU) [verificar minutos] | Varios por día | Con `gradio_client` | La del modelo: TRELLIS es MIT; Hunyuan, ver más abajo | Igual que local | glTF | No |

Lectura rápida:

- **Hunyuan3D Global es lo más generoso** (20 por día), y su modelo es de los mejores en forma.
- **La API de Tripo es la mejor bolsa de una sola vez** (2000 créditos). Además **riggea por API**, que es lo que más nos falta.
- **Sloyd** sirve para edificios y utilería low poly sin gastar créditos.
- **Rodin y Kaedim no sirven** sin pagar.

## 2. Modelos para correr local (RTX 2060 Super, 8 GB, 31 GB de RAM, Linux)

| Modelo | VRAM | Licencia | Calidad | ¿Anda en esta PC? |
|---|---|---|---|---|
| **Hunyuan3D-2mini-Turbo** (forma 0,6B) + textura | ~6 GB solo la forma con `low_vram_mode` y FlashVDM; la textura pide más (~10 GB) [verificar] | Tencent Hunyuan Community: **excluye la UE, el Reino Unido y Corea del Sur**; tiene tope de usuarios mensuales para uso comercial [verificar el número] | La mejor forma de las que entran en 8 GB | **Sí la forma.** La textura, con descarga a la CPU o pintada aparte |
| **Hunyuan3D-2.1** | Forma ~10 GB, textura ~21 GB | La misma, versión 2.1 | Muy buena; textura PBR | Forma, quizás con descarga a la CPU [verificar]; textura no |
| **TRELLIS 2** (Microsoft, 2025-12) | 16 GB mínimo a 512³; hay forks recortados de ~8 GB [verificar] | **MIT** | Muy buena; textura PBR | Solo con un fork de poca VRAM; probar |
| **TRELLIS 1** (image-large) | ~16 GB [verificar] | MIT | Buena | No, salvo un fork |
| **Stable Fast 3D** | ~7 GB | Stability Community: libre hasta 1 M USD de facturación anual | Media; rápida (0,5 s); UV y textura | **Sí** |
| **SPAR3D** | 10,5 GB, o ~7 GB en modo de poca VRAM | Stability Community | Algo mejor que SF3D; se edita la nube de puntos | **Sí**, en modo de poca VRAM |
| **TripoSR** | ~6 GB | **MIT** | Básica; textura por vértice | **Sí** |
| **InstantMesh** | ~4 GB en PyTorch (1 GB con GGML) | Apache 2.0 [verificar] | Media | **Sí** |

Instalación, en general: `git clone` del repositorio, un entorno de Python (conda o venv) con PyTorch para CUDA 12, `pip install -r requirements.txt` y la compilación de las extensiones (rasterizador, `custom_rasterizer` o `nvdiffrast`). La 2060 Super es Turing (sm_75): **no tiene FlashAttention 2**, así que hay que usar xformers o SDPA. Lo más cómodo es **ComfyUI** con nodos de Hunyuan3D y TRELLIS, porque bajan los pesos solos y descargan a la CPU. Ninguno de estos riggea.

**Qué correr local:** primero **Hunyuan3D-2mini-Turbo** (forma) y **Stable Fast 3D** o **SPAR3D** (rápidos, con textura) para iterar sin límite. Las texturas finales salen mejor en la web de Hunyuan o en Tripo. Para nosotros el low poly es una ventaja: después de generar hay que decimar en Blender igual (tenemos `--poli` en Meshy).

## 3. Rigging

| Herramienta | Precio | Licencia | Con modelos generados | Para KayKit |
|---|---|---|---|---|
| **Mixamo** | Gratis con cuenta de Adobe; anda en noviembre de 2026, pero está en mantenimiento, sin desarrollo | Personajes y animaciones sin regalías, uso comercial; no se redistribuyen sueltos | Anda bien si el modelo está en **pose T o A**, con los brazos separados; una sola malla | Esqueleto `mixamorig:*`, que se mapea a `SkeletonProfileHumanoid` en Godot. Muy probado |
| **AccuRIG 2** (Reallusion) | Gratis; pide cuenta de ActorCore para exportar | Uso personal y comercial | **Mejor que Mixamo con poses raras y mallas sucias**; ajusta los dedos | **Solo Windows** (hay que probarlo con Wine o CrossOver [verificar]). Exporta FBX con su esqueleto, que se mapea al humanoide de Godot |
| **Tripo, rig por API o web** | Créditos (de los 2000 de la API) | La de Tripo | Riggea su propia malla y también mallas subidas [verificar]; **también cuadrúpedos** | Exporta glTF con esqueleto; después se retargetea en Godot |
| **Meshy, autorrig** | Créditos | La de Meshy | Solo humanoides | Ya documentado en `27-animaciones` |
| **UniRig** (VAST, local) | Gratis | Permisiva (MIT [verificar]) | Rig automático de **cualquier malla**, humanoides y animales; pide ≥ 8 GB de VRAM (justo) | El esqueleto que sale es propio: hay que mapear huesos a mano |
| **Rigify** (Blender) | Gratis | GPL la herramienta; el resultado es nuestro | Bueno, pero lleva trabajo: ubicar el metarig y retocar los pesos | Se puede armar con los nombres de KayKit |
| **Auto-Rig Pro** | Pago (~40 USD) | Comercial | Muy bueno, retargeting incluido | Ideal, pero no es gratis |
| **Animate Anything** (Anything World) | Hay nivel gratis con un tope mensual [verificar]; los planes son desde 50 USD por mes | Comercial | **Pensado para low poly**, incluye cuadrúpedos | Trae sus animaciones; no es el camino para KayKit |

**Camino recomendado para los humanoides:**

1. Generar el modelo en **pose T o A**, con los brazos separados, y sin la herramienta fundida a la mano (hacer la herramienta aparte). Meshy ya tiene `--pose=t-pose`; Tripo y Hunyuan aceptan una imagen de entrada en pose T.
2. Decimar y limpiar en Blender (con un script, como `tools/kaykit_extraer.py`).
3. Riggear en **Mixamo** (gratis, sin límite). Si falla (axilas, faldas, ponchos), probar **AccuRIG** y, si no, el rig de Tripo.
4. En Godot: `BoneMap` con `SkeletonProfileHumanoid`, "Overwrite Axis" y "Fix Silhouette" (pasos de `27-animaciones`). Así la `AnimationLibrary` de KayKit se aplica tal cual. Mixamo y KayKit se mapean al mismo perfil.
5. Tomar un aldeano (guaraní) como prueba antes de hacer los 6 × N.

**Animales:** no hace falta riggear. Usar los de Quaternius (CC0, ya animados) y, para las siluetas propias (llama, elefante), **el rig de cuadrúpedos de Tripo** o UniRig local. Si no, mapear a mano sobre el esqueleto de un animal de Quaternius parecido.

## 4. Bibliotecas CC0 y CC-BY (además de las de `24/4s`)

| Biblioteca | Qué trae | Licencia | Para qué |
|---|---|---|---|
| [Quaternius · Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html) | Más de 300 piezas modulares de edificios en grilla | CC0 | Base para edificios de la edad II y III (la teja y el muro); hay que retexturarlos por pueblo |
| [KayKit · Medieval Hexagon](https://kaylousberg.itch.io/kaykit-medieval-hexagon) | Más de 200 edificios, losetas y utilería low poly, con un atlas de 1024 | CC0 | Edificios genéricos (molino, cuartel, mercado) con el mismo estilo que las animaciones de KayKit |
| [Kenney · Castle Kit](https://www.kenney.nl/assets/castle-kit) | Más de 70 piezas de castillo y **armas de asedio**, en glTF | CC0 | Murallas de piedra (C-101), torres y asedio |
| [Quaternius · Ultimate Animated Animal Pack](https://quaternius.com/packs/ultimateanimatedanimals.html) | 12 animales animados (**caballo** incluido [verificar la lista]) | CC0 | Caballos y la base de la llama (ya está en 4s) |
| [OpenGameArt · elefante low poly riggeado](https://opengameart.org/node/92420) | Elefante con esqueleto, en Blender | CC0 [verificar en la ficha] | **Elefante** de Ayutthaya, para retexturar |
| [OpenGameArt · Quaternius, "5 Low poly animals"](https://opengameart.org/node/66795) | Animales animados | CC0 | Más animales |
| [Poly Pizza](https://poly.pizza) | Buscador low poly: hay llamas, alpacas, elefantes y caballos | Mezcla de CC0 y CC-BY: **ver cada ficha** | Llama y alpaca |
| [Sketchfab, filtro "Downloadable" + CC0](https://sketchfab.com/search?features=downloadable&licenses=7c23a1ba438d4306920229c12afcb5f9&type=models) | Escaneos y modelos; hay patrimonio andino, etíope y siamés | CC0 o CC-BY según la ficha | Referencia y piezas de hitos |

## 5. Plan para aprovechar varios créditos gratis a la vez

| Fuente | Puntos fuertes | Qué generar ahí |
|---|---|---|
| **Hunyuan3D Global** (20 por día) | Volumen y buena forma | **Las variantes por pueblo**: aldeano y soldados de los 6 pueblos en pose T (6 × ~6 unidades ≈ 36 modelos, en 2 días) y edificios por edad (decimados después) |
| **API de Tripo** (2000 créditos, una vez) | Rig humanoide y de cuadrúpedos, low poly | **Lo que hay que riggear y no sale en Mixamo**: llama y elefante (generar y riggear), y los humanoides que Mixamo no pueda riggear. Se puede sumar a `tools/` un `tripo_api.py` hermano de `meshy_api.py` |
| **Meshy** (100 por mes) | Ya integrado; remesh | Seguir con lo que ya tiene estilo propio (repetir un pueblo para que no cambie el aspecto); atribuir (CC BY) |
| **Sloyd** (1 por día y plantillas) | Utilería y edificios paramétricos | Cercos, carros, pozos, empalizadas y graneros |
| **Local: Hunyuan3D-2mini, SF3D o SPAR3D** | Sin límite | Bocetos y pruebas de prompt antes de gastar créditos; utilería simple |
| **Mixamo** (sin límite) | Rig humanoide | Riggear todos los humanoides |
| **CC0** (Quaternius, KayKit, Kenney) | Ya animado o modular | Caballos, murallas, asedio y piezas de edificios genéricos |

**Orden:** (1) probar un aldeano guaraní de Hunyuan en pose T, riggearlo en Mixamo y retargetearlo a KayKit en Godot; (2) si anda, sacar las 36 variantes en Hunyuan; (3) con la API de Tripo, llama y elefante riggeados; (4) edificios en Hunyuan y Sloyd, completados con kits CC0.

Para no mezclar estilos, conviene **una imagen de referencia por pueblo** (paleta y tocado), generada una vez y usada como entrada de imagen a 3D en todos los servicios. Así cambia el motor, pero no el aspecto.

## 6. Riesgos de licencia

- **Tripo, nivel gratis:** los modelos son públicos y **no comerciales**. Si Raíces se vende o recibe dinero, no sirven. Usar la **API** (otros términos, [verificar]) o pagar un mes para los finales. Las fuentes dicen a la vez "CC BY 4.0" y "sin uso comercial": leer los términos al crear la cuenta.
- **Meshy gratis:** CC BY 4.0. Se puede usar, pero hay que atribuir en `assets/CREDITOS.md` (ya lo hacemos).
- **Hunyuan3D, pesos abiertos:** la licencia **no vale en la UE, el Reino Unido ni Corea del Sur**. Generar desde Uruguay o Argentina está dentro, pero distribuir el juego en la UE con modelos hechos con esos pesos es una zona gris [verificar con la licencia]. Tiene un tope de usuarios mensuales para uso comercial [verificar].
- **Hunyuan3D Global (web y API):** la propiedad de lo generado está en los términos del servicio. Leerlos antes de usar los modelos en la versión final [verificar].
- **Stable Fast 3D y SPAR3D:** libres por debajo de 1 M USD de facturación anual. Sin problema para nosotros.
- **TRELLIS y TripoSR:** MIT. Sin restricciones.
- **Mixamo:** se pueden usar en el juego, pero no redistribuir los personajes ni las animaciones sueltos. En un repo público, **versionar el `.glb` final ya integrado, no los FBX de Mixamo**.
- **AccuRIG:** comercial sí; el EULA tiene preguntas abiertas en el foro sobre la redistribución [verificar].
- **CC-BY de Poly Pizza y Sketchfab:** atribución obligatoria y ficha por ficha.
- **Imágenes de entrada:** nada de personajes ni obras ajenas en los prompts ni en las imágenes, como dice ya `meshy_api.py`. Se registra todo en `assets/generados/registro.jsonl`.

## 7. Cuentas que tiene que crear el autor

1. **Hunyuan3D Global** (web, 20 por día): https://3d.hunyuanglobal.com
2. **API de Tripo** (2000 créditos al generar la clave): https://platform.tripo3d.ai. Ya hay un `tripo.env` en `../apex-open/.secrets/`; si es de esta cuenta, solo falta ver el saldo.
3. **Mixamo** (cuenta de Adobe gratis): https://www.mixamo.com
4. **Hugging Face** (Spaces de TRELLIS 2 y Hunyuan, más la descarga de pesos locales): https://huggingface.co/join
5. Opcionales: **Sloyd** (https://www.sloyd.ai), **ActorCore** para AccuRIG (https://actorcore.reallusion.com/auto-rig) y **Tencent Cloud Internacional** para la API de Hunyuan (https://www.tencentcloud.com; pide tarjeta [verificar]).

## 8. Cómo guardar las claves

Igual que Meshy: un archivo por servicio en `../apex-open/.secrets/` (fuera del repo, nunca se versiona), con una línea `NOMBRE=valor`:

```
../apex-open/.secrets/tripo.env      TRIPO_API_KEY=...
../apex-open/.secrets/hunyuan.env    TENCENTCLOUD_SECRET_ID=...   TENCENTCLOUD_SECRET_KEY=...
../apex-open/.secrets/hf.env         HF_TOKEN=...
```

- Crearlos con el editor, o con `read -s` en la terminal, para que la clave no quede en el historial. Después, `chmod 600`.
- Los scripts leen el archivo como `key()` en `tools/meshy_api.py` (con variable de entorno para cambiar la ruta: `TRIPO_ENV`, `HUNYUAN_ENV`, `HF_ENV`). **Nunca imprimen la clave**, ni en errores ni en `registro.jsonl`.
- Para chequear que existe, sin mostrarla: `grep -c '^TRIPO_API_KEY=' ../apex-open/.secrets/tripo.env`.

## Fuentes (consultadas el 2026-11-19)

- Comparativa de precios de 3D AI Studio, revisada el 1 de noviembre de 2026: https://www.3daistudio.com/3d-generator-ai-comparison-alternatives-guide/ai-3d-generator-pricing-compared
- Plan gratis de Tripo: https://costbench.com/software/ai-3d-generation/tripo-ai/free-plan/ · Créditos de la API: https://yangmao.ai/en/providers/tripo/free-tier/ · Facturación de la API: https://developers.tripo3d.com/en/docs/billing
- Precios de Hyper3D: https://hyper3d.ai/pricing
- Hunyuan 3D Global (20 por día y 200 créditos por API): https://www.tencent.com/en-us/articles/2202235.html · https://www.tencentcloud.com/document/product/1281/74121
- Hunyuan3D-2 (Turbo y mini, poca VRAM): https://github.com/Tencent/Hunyuan3D-2 · Territorio de la licencia: https://open.windriver.com/info/uni-license-list/licenses/tencent-hunyuan-3d-2.0-cla.html
- TRELLIS 2 (VRAM, MIT): https://www.codesota.com/news/trellis-2-3d-generation · https://app.cinevva.com/news/2026-03-20-trellis-2-microsoft-open-source-3d
- Stable Fast 3D: https://stability.ai/news/introducing-stable-fast-3d · SPAR3D: https://stability.ai/news/stable-point-aware-3d · TripoSR: https://raw.githubusercontent.com/VAST-AI-Research/TripoSR/main/README.md
- Sloyd, CSM, Luma, Kaedim y Spline: https://costbench.com/software/ai-3d-generation/sloyd/free-plan/ · https://costbench.com/software/ai-3d-generation/compare-all/
- Mixamo: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html · https://app.cinevva.com/guides/free-character-animations-rigging · AccuRIG 2: https://www.cgchannel.com/2025/07/rig-and-animate-3d-characters-for-free-with-accurig-2-0/
- UniRig: https://github.com/VAST-AI-Research/UniRig · Puppeteer: https://raw.githubusercontent.com/Seed3D/Puppeteer/main/README.md · Animate Anything: https://www.cgchannel.com/2023/10/animate-anything-uses-ai-to-rig-your-3d-characters
