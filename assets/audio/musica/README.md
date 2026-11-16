# Música por civilización

Todas las pistas son CC0 o dominio público (fuentes exactas en `assets/CREDITOS.md`). Están en Ogg Vorbis estéreo a 44,1 kHz, normalizadas a −16 LUFS, así que se pueden alternar sin reajustar volumen. Las cuatro pistas genéricas de la raíz (`musica_tribal`, `musica_krakatoa_loop`, `musica_flauta_de_pan`, `musica_marcha_batalla`) son de otra tanda y suenan más fuerte (entre −7 y −16 LUFS).

**Momentos:** *paz* = economía y exploración; *combate* = cuando hay lucha cerca; *ceremonia* = cambio de edad, victoria o menú de la civilización. "Loop corto" quiere decir que la pista dura menos de 40 s y conviene marcarla con `loop=true` en el importador de Godot.

**Genérica** significa que tiene la intención estética pero **no** usa instrumentos de esa cultura. Es un relleno hasta tener algo propio.

## Tawantinsuyu (`tawantinsuyu/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_andes_flauta_de_pan_1.ogg | 3:07 | paz | Composición para videojuego al estilo andino: flautas de pan, arpa y bajo sintetizados. La fuente original estaba a 16 kHz, así que no tiene agudos brillantes. |
| musica_andes_charango_1.ogg | 0:36 | paz (loop corto) | Charango rasgueado, interpretación libre del autor |

Sin pista de combate propia: no encontré quena, siku ni bombo con licencia CC0 o PD. Mientras tanto se puede usar `../musica_tribal.ogg`.

## Mapuche (`mapuche/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_mapuche_pifilka_1.ogg | 0:33 | combate (capa rítmica / alerta) | Pifilkas en grupo |
| musica_mapuche_pifilka_2.ogg | 0:38 | combate (capa rítmica / alerta) | Pifilkas en grupo |

Son demostraciones de instrumentos que publicó el propio intérprete (Juan Huichal) como "instrumentos de la música tradicional mapuche". No son registros etnográficos. Igual, la pifilka tiene uso ceremonial (ngillatun): antes de publicar el juego conviene confirmar el contexto con el autor o con una organización mapuche. Más que pistas completas, son capas cortas. No hay música de paz, ni kultrun ni trutruka.

## Guaraní (`guarani/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_guarani_selva_generica_1.ogg | 2:11 | paz | **Genérica**: música de selva para videojuegos, sin mbaraka, takuapu ni flautas guaraníes |

No encontré nada guaraní con licencia libre clara.

## Etiopía (`etiopia/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_etiopia_krar_kebero_1.ogg | 0:35 | paz (loop corto) | **Sintetizada, obra propia** (`tools/audio/generar_sonidos.py`, C-24): krar, masenqo y kebero en el modo ambassel, 16 compases de 6/8. Empalma sin corte. Diseño en `proceso/24-tras-la-segunda-ronda/4g-sonido.md`; la begena se reemplazó por el krar, que es profano (C-54 b, `4h-sonido-con-respeto.md`) |

Se engancha desde `data/audio.json` (`civs.etiopia.musica`), no desde `CIV_MUSIC`.

Antes no había pistas. No encontré krar, masenqo, washint ni kebero con licencia CC0 o PD. Por ahora, usar las genéricas de la raíz.

Segunda búsqueda (2026-11-14), en Commons, Internet Archive (con los discos de 78 rpm) y OpenGameArt: solo hay material CC-BY-SA, discos comerciales mal licenciados o registros etnográficos y litúrgicos (zema). El detalle está en `proceso/19-arte-y-sonido/01-modelos-y-musica.md` y la decisión, en la consulta C-24.

## Quilombo dos Palmares (`quilombo/`)

**Fuera de uso desde la revisión histórica (etapa 25):** ninguna de estas pistas está en `CIV_MUSIC`. Los toques de iúna y de angola son de capoeira (siglos XIX y XX), el ijexá es yorubá-bahiano y del candomblé, y el loop de combate es exotismo genérico; Palmares era sobre todo centroafricano (kimbundu y kikongo). Los archivos quedan por si se contesta C-57 a) y hasta tener música propia de ngoma, marimba y kisanji (`proceso/25-revision-historica/04-correcciones-aplicadas.md`).

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_quilombo_berimbau_iuna_1.ogg | 2:28 | paz | Toque de iúna con tres berimbaus; los primeros 14 s son un solo berimbau |
| musica_quilombo_berimbau_angola_1.ogg | 0:18 | paz / menú (loop corto) | Toque de Angola, un berimbau solo |
| musica_quilombo_ijexa_1.ogg | 0:24 | paz (loop corto) | Ritmo ijexá de afoxé, programado en MIDI |
| musica_quilombo_tambores_combate_1.ogg | 0:18 | combate (loop corto) | **Genérica**: loop de tambores africanos, no atabaque/agogô específicamente |

## Ayutthaya (`ayutthaya/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_ayutthaya_maha_nimit_1.ogg | 1:20 | paz (única pista propia, en consulta C-59) | *Phleng Maha Nimit*, pieza tailandesa de corte, grabada en 1934 por la Banda de la Armada Real (banda de vientos, no piphat; sonido de época) |
| musica_ayutthaya_xilofono_1.ogg | 1:33 | fuera de uso | **Genérica**. Su título original («Kingdom of a million elephants under a white parasol») es el nombre de Lan Xang, el reino lao vecino: salió de `CIV_MUSIC` en la etapa 25 |
| musica_ayutthaya_combate_xilofono_1.ogg | 1:17 | fuera de uso | **Genérica** («Bamboo Blitz»): tambores genéricos con xilofón; salió de `CIV_MUSIC` en la etapa 25 |
