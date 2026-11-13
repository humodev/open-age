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

## Etiopía

Sin pistas. No encontré krar, masenqo, washint ni kebero con licencia CC0 o PD. Por ahora, usar las genéricas de la raíz.

## Quilombo dos Palmares (`quilombo/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_quilombo_berimbau_iuna_1.ogg | 2:28 | paz | Toque de iúna con tres berimbaus; los primeros 14 s son un solo berimbau |
| musica_quilombo_berimbau_angola_1.ogg | 0:18 | paz / menú (loop corto) | Toque de Angola, un berimbau solo |
| musica_quilombo_ijexa_1.ogg | 0:24 | paz (loop corto) | Ritmo ijexá de afoxé, programado en MIDI |
| musica_quilombo_tambores_combate_1.ogg | 0:18 | combate (loop corto) | **Genérica**: loop de tambores africanos, no atabaque/agogô específicamente |

## Ayutthaya (`ayutthaya/`)

| archivo | duración | momento | notas |
|---|---|---|---|
| musica_ayutthaya_maha_nimit_1.ogg | 1:20 | ceremonia | *Phleng Maha Nimit*, pieza tailandesa de corte, grabada en 1934 por la Banda de la Armada Real (banda de vientos, no piphat; sonido de época) |
| musica_ayutthaya_xilofono_1.ogg | 1:33 | paz | **Genérica** de aire sudasiático; el xilofón evoca el ranat |
| musica_ayutthaya_combate_xilofono_1.ogg | 1:17 | combate | **Genérica**: tambores tribales con xilofón |
