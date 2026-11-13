# Proyecto Sur

*Nombre provisional (A-005).*

RTS histórico con asimetría radical, protagonizado por civilizaciones del sur global, c. 1400–1800: **Tawantinsuyu, mapuches, guaraníes, Etiopía, Quilombo dos Palmares y Ayutthaya**. Cada una con su economía, su arquitectura, sus hitos y una campaña de cuatro misiones narrada desde adentro. Hecho en Godot por una persona con agentes de IA.

**Estado:** seis civilizaciones jugables en escaramuza contra la IA y seis campañas (24 misiones). Ver [`docs/09-estado.md`](docs/09-estado.md) y el registro paso a paso en [`proceso/`](proceso/README.md).

![Base en estética de maqueta](docs/img/h1-base.jpg)
![Batalla de 30 contra 30](docs/img/h1-batalla.jpg)

## Jugar

Requiere Godot 4.7.

```
godot --path .
```

| Acción | Entrada |
|---|---|
| Seleccionar | Clic izquierdo o arrastrar; doble clic para todas las del mismo tipo |
| Orden contextual | Clic derecho (mover, atacar, recolectar, construir) |
| Construir | Seleccionar aldeanos y usar la grilla (`Q W E R` / `A S D F`) |
| Ataque en movimiento | `A` y clic |
| Grupos | `Ctrl + 1…9` y `1…9` |
| Aldeano inactivo / centro | `.` / `H` |
| Cámara | Flechas, bordes de pantalla, botón del medio, rueda |
| Velocidad / pausa | `F3` / `Esc` |

## Documentación

Todo el diseño vive en [`docs/`](docs/00-indice.md). Empezar por el índice y el registro de decisiones. Los números de balance están en [`data/`](data/).

## Pruebas

```
godot --headless --path . -s tests/test_determinism.gd
godot --headless --path . -s tests/bench.gd
godot --headless --path . -s tests/ai_match.gd -- --seed=7 --minutes=30
godot --headless --path . -s tests/civ_smoke.gd
godot --headless --path . -s tests/campaign_smoke.gd
godot --headless --path . -s tests/torneo.gd -- --minutes=30 --seeds=2
godot --path . -- --autotest --civ=guaranies --terreno=llano
```

## Licencias

La fuente Fira Sans se distribuye bajo la SIL Open Font License (`assets/fonts/OFL.txt`). El audio y las texturas son CC0; detalle por archivo en [`assets/CREDITOS.md`](assets/CREDITOS.md).
