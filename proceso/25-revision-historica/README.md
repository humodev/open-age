# 25 · Revisión histórica (desde 2026-11-16)

## Pedido del autor
> "Run an analysis with a latin american, an african and asian historians that help us maintain the game truthful to history."

## Cómo se hace
Tres revisores, uno por región, leen todo lo que el juego dice de sus pueblos: civs (nombres, mecánicas, hitos, edades), campañas, arte (`arte_edades`, `arte_hitos`, `arte_animales` y capturas), sonido y lo marcado `[verificar]`.

Cada uno entrega:
- los problemas, con archivo y clave, gravedad (error de hecho, anacronismo, estereotipo o falta de respeto, simplificación aceptable), propuesta y fuente;
- lo que está bien;
- las consultas a comunidades que harían falta;
- bibliografía.

Ninguno cambia el juego: los cambios se hacen después, con las consultas que hagan falta en `CONSULTAS.md`.

| Revisor | Pueblos | Informe |
|---|---|---|
| América Latina | Tawantinsuyu, chankas, cañaris, caranquis, mapuches, guaraníes, tupíes, y el lado brasileño de Palmares | [01-america-latina.md](01-america-latina.md) |
| África | Etiopía, Adal, y el lado africano (Kongo, Ndongo) de Palmares | [02-africa.md](02-africa.md) |
| Asia | Ayutthaya y Birmania | [03-asia.md](03-asia.md) |

## Paso a paso
1. **Tres revisiones** (01–03), con unos 105 problemas en total.
   - El nivel general es alto: narradores de adentro, fuentes reales, nada de "Grañ", ni de Adal como horda, ni de Aqualtune.
   - Lo más serio:
     - la yerba guaraní;
     - los anacronismos de la edad IV inca;
     - lo sagrado usado como bono (Lalibela, la iglesia);
     - los silencios de la campaña etíope (oromo, beta israel, estefanitas);
     - la música de Palmares (capoeira, candomblé) y de Ayutthaya (*Tra Nimit*, Lan Xang);
     - los anacronismos birmanos.
2. **Correcciones que no cambian mecánicas** ([04-correcciones-aplicadas.md](04-correcciones-aplicadas.md), commit `0af58e0`):
   - 82 cambios en 21 archivos: fechas, fuentes, frases, el gult, una línea para los oromo, los beta israel y los estefanitas;
   - arte: sin oro inca en la edad IV y teca birmana;
   - sonido: sin las pistas de capoeira, ijexá, Lan Xang y "Bamboo Blitz";
   - mismo hash; las 25 misiones, las civs, el sonido y el autotest dan OK.
   - [Capturas](capturas/).
3. **Decisiones para el autor:** C-67 a C-74 en `CONSULTAS.md` (yerba, Pacto de Cucaú y liberación, Lalibela e iglesia, nombres de edad, Birmania y barrio chino, otros nombres, sonido, representación y consultas a comunidades).
