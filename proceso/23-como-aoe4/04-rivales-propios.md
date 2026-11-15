# 23 · D — Rivales con civilización propia

## Pedido
Del informe de historia y estética (`proceso/22-testers/03-historia-y-estetica.md`, sección 4, puntos 1 a 7, y deseo 1): Adal y Birmania jugaban como "Invasores" (edades *Hueste… Virreinato*, rodeleros y fuerte europeo) y el marcador decía "Rojo · Invasores". Chankas, cayambes, cañaris y tupíes jugaban con la cultura del jugador, justo lo contrario de lo que cuentan los textos. AoE4 resuelve esto con una civ propia para cada rival de campaña.

## Qué quedó

### Seis civilizaciones solo de IA (`data/civs/*.json`, `"solo_ia": true`)
Las fuentes y lo que falta verificar van en cada JSON, en los campos `_fuentes` y `_verificar` (el cargador ignora las claves que empiezan con `_`).

| Clave | Nombre en pantalla | Reemplaza a | Unidades con nombre propio | Edificios | Forma y colores | Fuentes principales |
|---|---|---|---|---|---|---|
| `adal` | Adal | `invasores` en Etiopía 1–3 | *Malassay* (élite hararí, choque), *Fāris* (jinete, árabe), *Tüfekçi* (mosquetero, turco otomano), arquero | Campamento del imán, Casa de patio, Torre del *Jugol* | `azotea` (nueva): piedra revocada y techo plano, ocre y verde | *Futūḥ al-Ḥabaša* de Arab Faqih (trad. Stenhouse 2003); Wikipedia "Adal Sultanate"; `investigacion/etiopia.md` H22–H28 |
| `birmanos` | Birmania | `invasores` en Ayutthaya 1, 3 y 4 | *Athi* (aldeano), espadero de *dha*, jinete *kathe* (manipurí), *Bayingyi* (tiradores de origen portugués) | *Myo* (centro), *Ein* (casa), fuerte de troncos | `ayutthaya` con teca oscura y oro | Lieberman 2003; Charney 2004; Wikipedia "Bayingyi people" y "Royal Burmese Armed Forces"; `investigacion/ayutthaya.md` H6–H10 |
| `chankas` | Chankas | `tawantinsuyu` en Tawantinsuyu 1 | Guerrero de porra estrellada, hondero de Andahuaylas, lancero chanka | Aldea de la cumbre, casa redonda, *Imagen de Uscovilca* (hito de guerra) | `redonda` (nueva): muro circular y techo cónico | Betanzos 1551; Bauer, Kellett y Aráoz Silva 2010; Wikipedia "Chanka" |
| `caranquis` | Caranquis y cayambes | `tawantinsuyu` en Tawantinsuyu 2 | Tirador de estólica (lanzadardos), guerrero de porra | *Tola* (montículo, centro), casa redonda, fuerte de cresta | `redonda`, azul pizarra | Salomon 1986; Connell y Gifford (Pambamarca); Wikipedia (es) "Caranquis" |
| `canaris` | Cañaris | `tawantinsuyu` en Tawantinsuyu 3 | Guerrero de hacha, hondero cañari, lancero de chonta | *Guapondélig* (centro), casa redonda | `redonda`, rojo | Hemming 1970; Wikipedia "Cañari" (Francisco Chilche, planta circular) |
| `tupies` | Tupíes | `guaranies` en Guaraníes 2 y 3 | Guerrero de *tacape*, arquero de *uirapara* | *Taba* (aldea), *Oca* (casa larga) | `guarani` con rojo de urucum | Monteiro, *Negros da terra* (1994); Avellaneda y Quarleri 2007; Wikipedia (pt) "Tacape" |

**Por qué se agrupa y por qué no:**
- **Toungoo y Konbaung van juntos.** Son dos dinastías sucesivas del mismo Estado del Irrawaddy, con la misma leva (*ahmudan*), los mismos elefantes y los mismos tiradores hereditarios. Las edades marcan el paso: *Ywa* (aldea), *Myo* (ciudad amurallada), *Hanthawaddy* (Pegu, la capital de Bayinnaung) y *Konbaung*.
- **Cayambes y caranquis van juntos** porque las fuentes los tratan como señoríos de una misma cultura (con Otavalo) y la misión ya los nombra así.
- **Cañaris y caranquis van separados**, aunque los dos son del actual Ecuador: tenían otra lengua, otro territorio (400 km de distancia) y otra historia. Los caranquis resistieron al Inka hasta Yahuarcocha; los cañaris, castigados por Atahualpa, pelearon junto a los españoles. Juntarlos repetía el error que marcó el informe.
- **No se separan** las milicias de Pumakawa (un kuraka inca de Chinchero), los señores de Lasta (etíopes) ni los señores siameses rivales de Taksin: son del mismo pueblo que el jugador. Los europeos siguen como `invasores`; queda a consulta separarlos (C-40).

**Lenguas:** solo se usan palabras en lengua propia cuando hay fuente para la palabra. Para los chankas no: las fuentes discrepan sobre su lengua (puquina, aimara o quechua), así que sus nombres van en castellano. Los caranquis hablaban cara, que no es quechua, y los nombres van en castellano salvo *tola*, que es el término de la arqueología ecuatoriana.

**Números:** Adal y Birmania copian los de `invasores.json` (centro de 3000 de vida, armadura 3 y 3 flechas; jinete y lancero desde la edad I; arcabucero desde la II; todo sale del cuartel), así la dificultad de las misiones no cambia. Los rivales andinos y los tupíes usan la capa común con los retoques que tenían como incas o guaraníes (hondero con alcance 6000; el arquero tupí con los números del guaraní) y quitan caballo, pólvora y ariete (`sin_unidades`), porque no los tenían. Cuando una misión pide un ataque con una unidad que el rival no tiene, el motor ya elige la más parecida por función. No se tocaron las seis civs jugables.

### Campañas y marcador
- Cada rival de `data/campanas/*.json` tiene ahora un nombre `corto` para el marcador (por ejemplo, "Imán Ahmad", "Maha Nawrahta", "Tupíes"). El nombre largo sigue en el relato.
- `panel_comun.gd`: `mission_name()` y `people_name()`. En campaña, el marcador, la pantalla de fin, el aviso "llegó a la edad", la ficha y el panel de selección muestran el rival de la misión ("Rojo · Imán Ahmad") en vez de la civ ("Rojo · Invasores"). Fuera de campaña no cambia nada.
- `civ_meshes.gd`: formas `redonda` y `azotea`, y la paleta entra en la clave del caché (antes, dos civs con la misma forma y el mismo color de equipo compartían malla).
- `docs/campanas/README.md` actualizado (facciones y equivalencias).

| Misión | Rival | Antes | Ahora |
|---|---|---|---|
| Etiopía 1 | Ejército de Badlay | invasores | `adal` |
| Etiopía 2 y 3 | Ejército del imán Ahmad | invasores | `adal` |
| Ayutthaya 1 | Ejército de Mingyi Swa | invasores | `birmanos` |
| Ayutthaya 3 | Maha Nawrahta y Ne Myo Thihapate | invasores | `birmanos` |
| Ayutthaya 4 | Guarniciones de Thonburi y Pho Sam Ton | invasores | `birmanos` |
| Tawantinsuyu 1 | Confederación chanka | tawantinsuyu | `chankas` |
| Tawantinsuyu 2 | Cayambes y caranquis | tawantinsuyu | `caranquis` |
| Tawantinsuyu 3 | Auxiliares cañaris | tawantinsuyu | `canaris` |
| Guaraníes 2 y 3 | Auxiliares tupí de la bandeira | guaranies | `tupies` |

### Revisión de nombres
| Caso | Qué se hizo | Por qué |
|---|---|---|
| "Espingardeiro de resgate" (Palmares) | **Aplicado:** pasa a *Espingardeiro*, con una descripción que explica de dónde salían las armas (correrías y trato con los moradores) | En el portugués colonial, *resgate* era ante todo la compra de personas esclavizadas (y, en la Amazonia, la "guerra de resgate"). Ficha y README de campañas corregidos |
| "roças", "milho", "farinha" | **Aplicado:** *rozas*, *maíz*, *fariña* en Palmares y guaraníes; quedan *mocambo*, *quilombo*, *terço*, *morador* y *bandeira*, que no tienen equivalente | Tienen palabra en castellano. El criterio, a C-39 |
| "Inkarri" (edad IV inca) | A consulta (C-35) | Mito documentado en el siglo XX; cambiarlo es decisión de diseño |
| Qorikancha en la edad IV | A consulta (C-36) | Moverlo cambia hitos y balance |
| Orden de las edades guaraníes y "Amundá" | A consulta (C-37) | La investigación propone otro orden, pero la dejaba "a confirmar"; "Amundá" no tiene fuente |
| "Cucaú o Quilombo" | A consulta (C-38) | Es una decisión de nombre |

## Capturas (`capturas/rivales/`)
Base del rival de cada misión, sin niebla, con el marcador arriba a la derecha.

1. [Adal en Etiopía 1](capturas/rivales/01-adal-etiopia-1.jpg): casas de techo plano; el marcador dice "Rojo · Adal · Badlay"
2. [Birmania en Ayutthaya 3](capturas/rivales/02-birmanos-ayutthaya-3.jpg): pabellones de teca oscura; "Rojo · Maha Nawrahta", "Violeta · Ne Myo Thihapate"
3. [Chankas en Tawantinsuyu 1](capturas/rivales/03-chankas-tawantinsuyu-1.jpg): casas redondas
4. [Caranquis en Tawantinsuyu 2](capturas/rivales/04-caranquis-tawantinsuyu-2.jpg)
5. [Cañaris en Tawantinsuyu 3](capturas/rivales/05-canaris-tawantinsuyu-3.jpg): "Rojo · Hueste de H. Pizarro", "Violeta · Cañaris"
6. [Tupíes en Guaraníes 2](capturas/rivales/06-tupies-guaranies-2.jpg)
7. [Adal en Etiopía 2](capturas/rivales/07-adal-etiopia-2.jpg)

## Pruebas
- `tests/campaign_smoke.gd`: las 25 misiones cargan y avanzan 3 minutos sin errores de script.
- `tests/campaign_smoke.gd -- --ia-jugador --minutes=20`, antes y después: RESULTADO_IA
- `tests/civ_smoke.gd`: las seis civs jugables, sin errores (no cambian).
- Humo propio de las seis civs nuevas, IA contra IA 8 minutos (Adal contra Birmania, chankas contra tupíes, caranquis contra cañaris, Etiopía contra Adal): todas llegan a la edad II con 30 aldeanos, cuartel, granjas y ejército, sin errores.
- Autotest (`--autotest --civ=guaranies --terreno=llano`): OK.

## Tropiezos
- `--panel=puntaje` **cierra** el marcador en vez de abrirlo, porque ya está abierto de entrada (es un conmutador). Las capturas van sin esa opción.
- Los primeros nombres cortos ("Konbaung · Maha Nawrahta") se cortaban con "…" en el marcador; quedaron en el nombre del jefe, que es lo que cuenta la misión.
- Las casas de Adal con revoque casi blanco se confundían con la maqueta sin pintar; se pasaron a un ocre.
- El caché de mallas usaba solo la forma y el color de equipo: un birmano y un siamés del mismo color se habrían visto iguales. Ahora la paleta entra en la clave.
- No hubo búsquedas web disponibles en esta sesión (se agotó el cupo): los datos salen de las páginas leídas directamente y de la bibliografía de `docs/investigacion/`. Lo que no se pudo confirmar va en `_verificar` de cada JSON.
