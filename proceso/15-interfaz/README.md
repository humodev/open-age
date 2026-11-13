# 15 · Interfaz: mucha más información en la partida (2026-11-13)

## Pedido del autor
> "En paralelo, armá un equipo de agentes que mejore la interfaz todo lo posible: fichas al pasar el mouse que muestren una imagen del lugar sobre el que estás, con más detalle, y que expliquen qué hace, la civilización, etc. No solo mover o mejorar lo que ya hay, sino darle al jugador mucha más información de lo que está pasando en el juego."

## Equipo (primera tanda)
Cuatro agentes. Tres implementaron en paralelo, cada uno en su copia del repositorio, y el líder integró sus ramas resolviendo dos conflictos en `hud.gd` (se conservaron los dos lados). El cuarto auditó sin implementar.

| Agente | Qué hizo | Detalle |
|---|---|---|
| Fichas | Ficha con retrato al pasar el mouse sobre entidades, botones, selección y cola. Lleva nombre indígena y castellano, pueblo, función, estadísticas, costo, estado "Ahora" y fortalezas y debilidades. 192 retratos renderizados con los modelos del juego (`tools/render_retratos.gd`) | [01-fichas.md](01-fichas.md) |
| Paneles | F1 Mi pueblo, F2 Economía (ingreso por minuto y por origen, aldeanos por tarea, barra de lo disputado), F4 Edad (qué falta, hitos con eje y efecto), F5 Sucesos (con clic para ir), F6 Puntaje y pantalla de fin con gráficos | [02-paneles.md](02-paneles.md) |
| Mundo | Barras de vida (Alt para ver todas), texto flotante "+N", vista previa al colocar (alcance, ladera, agua, "0/2", separación, caminos y el motivo si no se puede), Zz en ociosos, ícono de lo que recolecta cada aldeano, punto de reunión, cola de órdenes con mayúsculas, anillo de captura de los sitios y minimapa con destellos, sitios, arcilla y ociosos | [03-mundo.md](03-mundo.md) |
| Auditoría | 24 problemas y 22 mejoras priorizadas frente a AoE4: escala de la interfaz, paleta para daltónicos, cursores, grilla estable, avisos con jerarquía y errores puntuales | [docs/diseno/interfaz/00-auditoria.md](../../docs/diseno/interfaz/00-auditoria.md) |

## Integración
- **Fichas:** la clase nueva `Ficha` necesitó reimportar el proyecto para registrarse.
- **Paneles:** encontraron que leer el contador de lo disputado creaba estado nuevo y cambiaba el hash. Se arregló en la simulación: los baldes existen desde el inicio.
- **Mundo:** la cola de órdenes con mayúsculas vive del lado del cliente; cada orden sale como comando común cuando la unidad queda ociosa, así que no toca el determinismo. Límite conocido: lo que se encola después de "recolectar" no se cumple.
- **Pruebas tras cada fusión:** autotest OK y determinismo OK.

## Pendiente
- **Segunda tanda**, según la auditoría: escala de interfaz, paleta, cursores contextuales, grilla estable con submenús y avisos con jerarquía.
- **Errores puntuales:**
  - texto pisado en el panel de la capital de Palmares;
  - "Tutorial 0/4";
  - población 33/8 en una misión mapuche.
- **Pedidos a la simulación** de los paneles:
  - gasto por destino;
  - pérdida por llegar al tope;
  - atacante en los avisos;
  - la liberación de Palmares no respeta el techo de población.
