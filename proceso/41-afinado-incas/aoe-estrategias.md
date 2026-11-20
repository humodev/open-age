# Cómo resuelve el arte la serie Age of Empires, y qué nos conviene (voz 4: experto en arte de AoE)

> Escrito de memoria, sin las guías internas de los estudios. Lo marcado **(aprox.)** es lo que no sé con seguridad: hay que verificarlo con capturas antes de usarlo como regla.

## 1. Dónde se ve cada pieza y a qué tamaño

| Pieza | AoE (aprox.) | Raíces hoy (medido en `src/game/hud.gd`) | Qué detalle sobrevive |
|---|---|---|---|
| Ícono de la grilla de producción | AoE2 DE ~36–48 px; AoE4 ~56–64 px **(aprox.)** | `SLOT` = **62 px** | Silueta, una o dos masas de color, el arma o la herramienta. La cara ocupa ~15–20 px: solo el tono de la piel, el pelo y lo que tiene en la cabeza. |
| Retrato de la selección (una unidad) | AoE4 usa el mismo ícono, más grande, ~100–120 px **(aprox.)**; AoE2 igual. Ninguno tiene retrato animado | **112 px** (`_single`) | La cara ocupa ~35–45 px: se leen la forma de la cara, la nariz, el ceño y el tono de la piel. Los tocapu y bordados ya no. |
| Selección múltiple | Íconos chicos, ~40 px | 56 px (pocas) o **40 px** (muchas) | Solo la silueta y el color de fondo. |
| Ficha / tooltip / guía | Texto + ícono | Ícono | Igual que el ícono. |
| Pantallas de carga, civ y victoria | Ilustración grande, 1920 px o más | Pantallas y misiones | Todo: es donde vale el detalle histórico fino. |
| Modelo 3D en el mapa | Una unidad mide ~30–60 px de alto con la cámara de juego **(aprox.)** | Igual o menos | Silueta, la proporción del arma, el casco o tocado y el color de jugador. Lo que cambia entre edades tiene que verse en la silueta. |

**Conclusión de tamaño:** el retrato de la unidad se ve a lo sumo a **112 px**. Nada de lo que solo se lee a 512 px (tocapu, bordados, caras sutiles) vale el esfuerzo en unidades. Las caras tienen que leerse como andinas **a 112 px**: con rasgos grandes y claros (forma de la cara, nariz, color de la piel y mejillas), no con detalles.

## 2. Estrategias de legibilidad

- **Silueta antes que detalle.** AoE2 y AoE4 separan las líneas de unidades por la forma del arma y del casco: la lanza larga, el arco, el escudo grande, el jinete. El color y la textura vienen después.
- **Fondos y marcos.** Los íconos de AoE4 son pinturas de busto o de medio cuerpo sobre un fondo liso o un degradé. El marco o el fondo cambian según el tipo de ícono (unidad, edificio, mejora) **(aprox.: no recuerdo si el color va por clase de unidad)**. En AoE2 DE los íconos son pinturas cuadradas con fondo propio y sin marco por clase.
- **Edades y niveles.**
  - En **AoE4** el veterano y el élite comparten el arte. El nivel se marca con un indicador chico en el ícono (galones o números) **(aprox.)**. El que cambia por edad es el **modelo 3D**: más armadura, otro casco.
  - En **AoE2** cada mejora de línea (milicia → hombre de armas → espadachín…) tiene su propio ícono y su propio sprite: el equipo cambia de verdad. Las unidades «élite» únicas cambian de ícono **(aprox.)**.
  - En ninguno de los dos hay un retrato distinto de la misma unidad por cada edad.
- **Color de jugador.**
  - **En el mapa:** AoE2 lo pinta en ciertos píxeles del sprite (túnicas, estandartes, partes del escudo) con una paleta que se reemplaza. AoE4 usa una máscara en la textura del modelo (tela del torso, faldón, estandartes y escudos). En los dos el color cubre una zona grande y plana del cuerpo, y la piel, el metal y la madera quedan naturales.
  - **En la interfaz:** los íconos y retratos de AoE **no se recolorean** **(aprox., casi seguro)**. Son iguales para todos los jugadores y el color del jugador aparece en el marco, la barra de vida o el minimapa.
- **Ícono de AoE4:** pintura semirrealista de busto o tres cuartos, mirando de lado, luz lateral, una sola figura y el arma visible si cabe.

## 3. Qué se reusa

- **Unidades comunes.**
  - AoE2: base compartida por todas las civs (el mismo arquero), con variaciones por región en algunas unidades (monje, aldeano y jinetes en DE **(aprox.)**). Las unidades únicas tienen arte propio.
  - AoE4: cada civ tiene sus modelos, pero los íconos de las unidades equivalentes se parecen mucho entre civs **(aprox.)**.
- **Retratos por edad:** no existen, en ninguno de los dos.
  - En AoE2 lo que cambia por edad es el sprite de los edificios (estilos de arquitectura por edad) y la línea de la unidad.
  - En AoE4 cambian por edad el modelo de la unidad (en algunas civs) y los edificios.
- **Una sola vez:** un ícono por unidad o mejora, y uno por edificio (AoE4 no cambia el ícono del edificio por edad **(aprox.)**).
- **Lo que se multiplica:** los modelos 3D por edad, la arquitectura por edad y la textura con el color del jugador.

## 4. Recomendación para «Raíces»

Hoy `tools/prompts_arte.py` pide **1433** imágenes, entre ellas 315 retratos de unidad por edad, 111 íconos de unidad, 385 de edificios (uno por edad) y 315 hojas 3D.

1. **Un solo arte por unidad que sirva de ícono y de retrato:** busto o medio cuerpo, legible a 62 y a 112 px. No hagan falta un retrato y un ícono distintos.
2. **Sin retrato por edad.** La edad se muestra en el **modelo 3D** (equipo y silueta, la regla nueva del autor) y, en el ícono, con un **distintivo de edad** chico (I–IV o galones) dibujado por el juego, no pintado.
   - Excepción: el **aldeano**, hombre y mujer por edad (es la unidad que más se ve, y los retratos ya existen).
   - Excepción opcional: las unidades propias de cada pueblo, si el autor lo pide.
3. **Edificios:** un ícono por edificio y por pueblo, sin variante por edad. La edad se ve en el modelo del mapa.
4. **Hojas 3D:** una por unidad. Los cambios de edad se resuelven como piezas que se agregan (casco, escudo, capa o acolchado), que ya están en «Accesorios 3D». Una hoja por edad solo cuando cambia todo el cuerpo.
5. **Detalle:** pintar para 128 px y revisar todo a 62 y a 112 px (`tools/recolorear.py` ya arma hojas; sumar la miniatura). Cara grande en el cuadro: la cabeza ocupa ~35–40 % del alto en el retrato.
6. **Zona recoloreable.**
   - **En el 3D:** sí, con máscara (túnica y manto en un color plano). Así lo hace AoE y es lo que pidió el autor.
   - **En los íconos y retratos:** propongo **no recolorearlos** y mostrar el color del jugador en el marco y el fondo (el HUD ya pinta el fondo del retrato por función, `_fondo_retrato`).
   - Si el autor igual quiere íconos recoloreables, la técnica de `tools/recolorear.py` (rojo plano, máscara HSV y `_mascara.png`) funciona. Lo decide el autor.

**Cuentas aproximadas con esta recomendación:**

| Pieza | Imágenes |
|---|---|
| Íconos de unidad | 111 |
| Aldeano por edad (6 pueblos × 2 sexos × 4 edades) | 48 |
| Íconos de edificio (385 / 4) | ~96 |
| Hojas 3D (una por unidad) | ~111 |
| Accesorios 3D | 99 |
| Mejoras | 56 + 49 |
| Hitos | 42 |
| Pantallas | 30 |
| Campaña | 24 |
| Interfaz | 7 |
| **Total** | **~670** |

Son **~670 imágenes en lugar de 1433**, menos de la mitad. Y el esfuerzo fino se concentra donde se ve: caras a 112 px, siluetas a 62 px y las pantallas grandes.
