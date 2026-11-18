# 28 · 02 · Usabilidad de la ronda 7 (2026-11-17)

Plan 3 de `proceso/22-testers/ronda-7/00-sintesis.md` (filas «Media» y «Baja» del jugador nuevo y del veterano). Solo interfaz y textos: `src/sim` no cambia (mismo hash, 2203695307).

## Qué cambió

1. **Las notas «[verificar…]» no llegan al jugador.**
   - Las 112 notas siguen en `data/` para los historiadores.
   - `src/game/ui/textos.gd` limpia la copia que muestra la interfaz al cargar: la tabla de la partida (`main.gd`, `_build_scene`), la del menú y las campañas.
   - Saca «[verificar…]» con su coma, las frases «…, a verificar.» y las cláusulas «; a verificar…».
   - Solo toca texto que nombra «verificar», ninguna clave ni número.
2. **«Recomendado».**
   - Una estrellita dorada marca la mejora que conviene comprar primero en cada edificio, entre las que ya se pueden pedir.
   - Sigue el orden de compra de la IA: `ia_prioridad`, los niveles de las líneas con más tropa (`ia_niveles`), `ia_compras_tardias.orden` y el `ia_propias.orden` del pueblo.
   - Si la recomendada está en un submenú, el botón del submenú lleva la estrella. La ayuda empieza con «★ Recomendada».
3. **Los niveles dicen la tropa:** «Lanceros veteranos», «Guerreros de élite», «Lanzas largas veteranas».
   - La tabla está en `data/interfaz.json` → `grilla.niveles`, por pueblo y línea.
   - Tiene una forma corta («Lanceros vet.») para la casilla con la franja de lo que falta.
4. **El cuartel ya no queda lleno en la III.**
   - Si las investigaciones de un edificio con tropa dejan menos de `libres_min` casillas libres (1), la herrería (las 4 cadenas de ataque y armadura) pasa a un submenú «Herrería» en A, con un ícono de yunque nuevo.
   - El cuartel inca de la III queda con 9 de 12, y el de Ayutthaya también.
   - Si ni así queda lugar, todo sigue como antes.
5. **Nombres sin cortar y ámbar legible.**
   - Si un nombre no entra a 8 px o más, se usa la forma corta, después se saca lo que va entre paréntesis y, como último recurso, se abrevia con «…».
   - Un común largo con la edad abajo pasa a dos renglones («Taller de asedio» se veía «aller de asedio»).
   - En ámbar, el nombre va en el color normal y el glifo en un ámbar más claro.

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | OK, hash 2203695307 (el mismo) |
| `tests/casillas.gd` | 540 grillas, OK. Revisa también el submenú de la herrería y que haya una sola recomendada |
| `tests/grilla.gd` | OK |
| `tests/iconos.gd` | 680 grillas, 136 íconos distintos, OK. Recorre también la herrería |
| `tests/verificar.gd` (nueva) | 112 notas en los datos; 2849 ayudas y 56 niveles revisados, OK |
| Autotest guaraníes, llano | OK |

La captura `capturas/ronda7-cuartel-iii.png` sale de `tests/galeria_grilla.gd -- --civs=tawantinsuyu --edad=3`. Muestra la kallanka en la III con 3 casillas libres, la estrella en «Herrería (4)» y en «Armas templadas», y «Lanceros vet.» y «Guerreros vet.».

## Tropiezos

- «Taller de asedio» y otros comunes largos con la edad abajo iban en un solo renglón. A 7 px seguían sin entrar, y el centrado los cortaba por la izquierda.
- En la casilla con franja, «Lanceros veteranos» se abreviaba a «Lanceros…» y se perdía justo lo que distingue un nivel del otro. Por eso existe la forma corta.
- El corral mapuche quedaba con 12 de 12 aun con la herrería aparte. Por eso el submenú solo se usa si deja casillas libres.
