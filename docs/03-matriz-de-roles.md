# 03 — Matriz de roles: las seis civilizaciones

Cómo se juega cada civilización, función por función. Los números están en `data/civs/`. La historia y sus fuentes están en `investigacion/`. Esta versión (2026-11-13) incorpora las correcciones de D-025 y las dos civilizaciones nuevas de D-026.

## Los seis arquetipos

| Civilización | Arquetipo | Frase |
|---|---|---|
| Tawantinsuyu | La red | "El imperio que se construye como una red." |
| Mapuches | El enjambre | "No hay capital que tomar." |
| Guaraníes | El monte | "El pueblo que se mueve con el río y el monte." |
| Etiopía | La corte que camina | "La corte que camina." |
| Palmares | El refugio | "La libertad que llega sola y se esconde en la sierra." |
| Ayutthaya | El puerto | "La ciudad isla que comercia con el mundo y pelea sobre elefantes." |

## Matriz

| Función | Tawantinsuyu | Mapuches | Guaraníes | Etiopía | Palmares | Ayutthaya |
|---|---|---|---|---|---|---|
| **Alimento** | Andenes: rinden más en lomas y laderas | Chacras y ganado | Roza que rinde mucho, se agota y deja un yerbal | Granjas y el tributo del gult | Roças de mandioca | Arrozales que rinden junto al agua |
| **Riqueza** | Tejido de cumbi (aqllawasi) | Malón: el daño a edificios trae ganado | Yerbales (la capuera) | Gult: tierras que rinden sin trabajo | Correrías y resgate | Barrios extranjeros y puerto real |
| **Recurso propio** | Mit'a (turnos de trabajo) | Kulliñ (ganado) | — | — | Fama | — |
| **Expansión** | Qhapaq Ñan: los conectados producen más | Lof dispersos, sin capital | Oga guasu; obra colectiva (potirõ) | La corte (kätäma) se desarma y se muda | Mocambos ocultos que acogen gente | Barrios extranjeros |
| **Población** | Normal | Normal | Normal | Normal | No entrena aldeanos: llegan por la fama y por las liberaciones | Normal |
| **Avance de edad** | Obra estatal con turnos de mit'a | Rewe del toqui elegido (cuesta ganado) | Karai o asamblea; en la edad III, misión o monte | Iglesia o monasterio; amba o remonta; Gondar o alianza | Cercas en anillos; en la edad IV, el pacto de Cucaú o la guerra de Zumbi | Wat o kraal; puerto o fortaleza; junco de tributo o guardia extranjera |
| **Movilidad** | Caminos (aceleran a todos); chaski | Weichafe rápido; kona montado desde la edad III | Sigilo y emboscada en el monte | Jinetes nobles desde la edad I | Sigilo en el monte | Jinete explorador |
| **Choque** | Guerrero de porra | Weichafe | Guerrero de macana | Jinete noble | Gente de guerra | Infantería de dap; compañía japonesa |
| **Distancia** | Hondero; boleador que frena | Arquero | Arquero (su núcleo) | Jabalinero | Flecheiro; espingardeiro | Arquero; compañía portuguesa |
| **Línea** | Lancero con escudo; leva (awqa) | Lanza larga | Lancero (débil al inicio) | Chewa | Lanceiro | Lancero |
| **Asedio** | Hondero de piedra caliente (incendiario) | Débil: sin asedio propio | Cañón de tacuara (se rompe) | Ariete | Débil: sin asedio | Ariete y elefantes |
| **Defensa** | Pukara de piedra (galgas como defensa) | Empalizada con foso; sigilo | Empalizadas; emboscada | Defensa en altura; amba | Cerca con estrepes que hiere | Fortín de río; fortaleza de la isla |
| **Adopción** | Vilcabamba: caballos y arcabuces capturados | Caballo por el ganado | Misión: milicias arcabuceras | Alianza: mosqueteros | Resgate: armas compradas | Compañías extranjeras |
| **Debilidad** | Arranque lento; cortar la red | Batalla frontal y asedio | Campo abierto | Unidades caras; fuera de la altura | Sin caballo ni asedio; el hambre ante un cerco | Elefantes caros; sin agua |

## Arco tardío (edades III y IV)

- **Tawantinsuyu**: el Qorikancha o el reducto de Vilcabamba.
- **Mapuches**: el parlamento (frontera con renta) o el gran weichan.
- **Guaraníes**: el pueblo de misión o el monte libre (D-019).
- **Etiopía**: la corte se asienta en Gondar o se alía para conseguir pólvora.
- **Palmares**: el pacto de Cucaú, que da tierras y paz a cambio de cerrar la puerta a quienes llegan, o la guerra de Zumbi. Las dos opciones son viables.
- **Ayutthaya**: el junco de tributo a China o la guardia extranjera.

## Módulos y propiedades que usan

| Módulo o propiedad (`06`) | Lo usa |
|---|---|
| `recurso_propio` | Tawantinsuyu, mapuches, Palmares |
| `caminos` | Tawantinsuyu |
| `saqueo` | Mapuches, Palmares |
| `liberacion`, `acogida` | Palmares |
| `sigilo` | Mapuches, guaraníes, Palmares |
| `relevo` | Mapuches |
| `obra_colectiva` | Guaraníes |
| `defensa_altura` | Etiopía |
| `renta` | Etiopía (gult), Ayutthaya, varios hitos |
| Base móvil (`empaca_en`) | Etiopía |
| Roza (`cantidad` y `deja`) | Guaraníes |
| Andenes (`permite_ladera`) | Tawantinsuyu |
| Arrozales (`bono_agua_pct`) | Ayutthaya |
| Daño en área (`area`) | Ayutthaya (elefantes) |
| Espinas | Palmares |

## Candidatas para después

Kongo, Malí y Songhai, mexicas, Ashanti, maratas, Majapahit, jemeres y Haití como facción de la era de la rebelión.
