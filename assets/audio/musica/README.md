# Música por civilización

Todas las pistas son CC0 o dominio público, salvo tres con atribución: dos de sikuri (CC BY-SA 4.0) y una de masenqo (CC BY 3.0), aceptadas en C-07 a y C-24 c (fuentes exactas en `assets/CREDITOS.md`; también en la pantalla de créditos del juego). Están en Ogg Vorbis estéreo a 44,1 kHz, normalizadas a −16 LUFS, así que se pueden alternar sin reajustar volumen. Las cuatro pistas genéricas de la raíz (`musica_tribal`, `musica_krakatoa_loop`, `musica_flauta_de_pan`, `musica_marcha_batalla`) son de otra tanda y suenan más fuerte (entre −7 y −16 LUFS).

**Momentos:** *paz* = economía y exploración; *combate* = cuando hay lucha cerca; *ceremonia* = cambio de edad, victoria o menú de la civilización. "Loop corto" quiere decir que la pista dura menos de 40 s y conviene marcarla con `loop=true` en el importador de Godot.

**Genérica** significa que tiene la intención estética pero **no** usa instrumentos de esa cultura. Es un relleno hasta tener algo propio.

## Tawantinsuyu (`tawantinsuyu/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_andes_flauta_de_pan_1.ogg | 3:07 | paz | Composición para videojuego al estilo andino: flautas de pan, arpa y bajo sintetizados. La fuente original estaba a 16 kHz, así que no tiene agudos brillantes. |
| musica_andes_charango_1.ogg | 0:36 | paz (loop corto) | Charango rasgueado, interpretación libre del autor |
| musica_tawantinsuyu_sikuri_29_de_setiembre.ogg | 2:00 | paz | **CC BY-SA 4.0.** «29 de setiembre», tema popular, por una pareja de sikus malta (ira y arka) con bombo; Abel Christian Apaza Amanqui, proyecto Sikuri Sumaq Taqi (Azángaro, Puno). Se engancha desde `data/audio.json` |
| musica_tawantinsuyu_sikuri_mula_lunthata.ogg | 1:28 | paz | **CC BY-SA 4.0.** «Mula Lunthata», tema popular, mismo conjunto y proyecto |

El sikuri es música de fiesta y de comunidad, no un objeto sagrado (criterio de `proceso/24-tras-la-segunda-ronda/4h-sonido-con-respeto.md`). Los dos temas son populares del altiplano de Puno y de hoy, no de la época del juego: suenan como ambiente, no como reconstrucción. Sin pista de combate propia.

## Mapuche (`mapuche/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_mapuche_pifilka_1.ogg | 0:33 | paz (C-08 a) | Pifilkas en grupo |
| musica_mapuche_pifilka_2.ogg | 0:38 | paz (C-08 a) | Pifilkas en grupo |

Son demostraciones de instrumentos que publicó el propio intérprete (Juan Huichal) como "instrumentos de la música tradicional mapuche". No son registros etnográficos. Igual, la pifilka tiene uso ceremonial (ngillatun): **desde C-08 a suenan solo en la paz, nunca en el combate** (`data/audio.json → civs.mapuches.musica.paz`), y antes de publicar el juego hay que consultarla con una organización mapuche, junto con el kultrun (C-53 a). Más que pistas completas, son capas cortas.

## Guaraní (`guarani/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_guarani_selva_generica_1.ogg | 2:11 | paz | **Genérica**: música de selva para videojuegos, sin mbaraka, takuapu ni flautas guaraníes |

No encontré nada guaraní con licencia libre clara.

## Etiopía (`etiopia/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_etiopia_krar_kebero_1.ogg | 0:35 | paz (loop corto) | **Sintetizada, obra propia** (`tools/audio/generar_sonidos.py`, C-24): krar, masenqo y kebero en el modo ambassel, 16 compases de 6/8. Empalma sin corte. Diseño en `proceso/24-tras-la-segunda-ronda/4g-sonido.md`; la begena se reemplazó por el krar, que es profano (C-54 b, `4h-sonido-con-respeto.md`) |

| musica_etiopia_masenqo_azmari_1.ogg | 1:58 | paz | **CC BY 3.0.** Un azmari que canta y se acompaña con masenqo, grabado en la calle en Etiopía (Miez Production, 2016; C-24 c). Es música profana de los azmari, no zema ni begena (C-54 b). [escuchar: que no haya voces habladas del camarógrafo; verificar de qué habla la letra] |

Se engancha desde `data/audio.json` (`civs.etiopia.musica`), no desde `CIV_MUSIC`.

Tercera búsqueda (2026-11-24, C-24 c: se acepta CC BY-SA), en Commons e Internet Archive: de krar grabado no hay nada con licencia libre (en Commons solo hay fotos; en Internet Archive, discos comerciales subidos como CC0, que no sirven). Los videos «Ethiopian Ambassel scale» y «Tizita minor scale» (CC BY) son una clase de escalas con guitarra eléctrica. El de Mestawet Shumye (VOA, dominio público) es con violín. Queda el masenqo de Miez Production.

Segunda búsqueda (2026-11-14), en Commons, Internet Archive (con los discos de 78 rpm) y OpenGameArt: solo hay material CC-BY-SA, discos comerciales mal licenciados o registros etnográficos y litúrgicos (zema). El detalle está en `proceso/19-arte-y-sonido/01-modelos-y-musica.md` y la decisión, en la consulta C-24.

## Quilombo dos Palmares (`quilombo/`)

**Fuera de uso desde la revisión histórica (etapa 25):** ninguna de estas pistas está en `CIV_MUSIC`. Los toques de iúna y de angola son de capoeira (siglos XIX y XX), el ijexá es yorubá-bahiano y del candomblé, y el loop de combate es exotismo genérico; Palmares era sobre todo centroafricano (kimbundu y kikongo). Los archivos quedan por si se contesta C-57 a) y hasta tener música propia de ngoma, marimba y kisanji (`proceso/25-revision-historica/04-correcciones-aplicadas.md`).

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_quilombo_berimbau_iuna_1.ogg | 2:28 | paz | Toque de iúna con tres berimbaus; los primeros 14 s son un solo berimbau |
| musica_quilombo_berimbau_angola_1.ogg | 0:18 | paz / menú (loop corto) | Toque de Angola, un berimbau solo |
| musica_quilombo_ijexa_1.ogg | 0:24 | paz (loop corto) | Ritmo ijexá de afoxé, programado en MIDI |
| musica_quilombo_tambores_combate_1.ogg | 0:18 | combate (loop corto) | **Genérica**: loop de tambores africanos, no atabaque/agogô específicamente |

## Palmares (`palmares/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_palmares_ngoma_marimba_1.ogg | 0:27 | paz | **Obra propia**, sintetizada: ngongi (campana doble), ngoma y marimba en 12/8, sin berimbau ni toques de capoeira (C-73 a) |

## Ayutthaya (`ayutthaya/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_ayutthaya_khong_ranat_1.ogg | 0:32 | paz | **Obra propia**, sintetizada (`tools/audio/generar_sonidos.py`): khong wong, ranat ek y ching. Reemplaza a *Phleng Maha Nimit* (Tra Nimit), que salió por ser del repertorio ceremonial *naphat* (C-73 a) |
| musica_ayutthaya_xilofono_1.ogg | 1:33 | fuera de uso | **Genérica**. Su título original («Kingdom of a million elephants under a white parasol») es el nombre de Lan Xang, el reino lao vecino: salió de `CIV_MUSIC` en la etapa 25 |
| musica_ayutthaya_combate_xilofono_1.ogg | 1:17 | fuera de uso | **Genérica** («Bamboo Blitz»): tambores genéricos con xilofón; salió de `CIV_MUSIC` en la etapa 25 |
