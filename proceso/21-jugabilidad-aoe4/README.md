# 21 · Jugabilidad al estilo AoE4: estudio e implementación (desde 2026-11-14 22:00)

## Pedido del autor
> "Por ahora me está costando, pero puede ser un tema de skill. Necesitamos varias cosas para acercarnos a un gameplay como el de Age of Empires 4. Ahora parece más al 1 por algunas cosas puntuales."
>
> "Necesitamos mejorar mucho y crear features que hacen de la jugabilidad una experiencia agradable, como pueden ser la agrupación de diferentes tropas. Que las unidades que son enviadas a algo en grupo, si son aldeanos y se los manda a caminar, lo hagan ordenados en bloque y se esperen para llegar juntos; si se los manda a un trabajo puntual cerca, está bien que vayan todos corriendo para llegar antes; si se los manda muy lejos, que se agrupen. Los oficiales militares siempre agrupados, formaciones militares, etc."
>
> "Por ejemplo, mandar a construir un almacén de arcilla al lado de la arcilla y que los aldeanos rápidamente comiencen a recolectar eso cuando terminan de hacerlo; que haya diferentes almacenes para diferentes cosas, ajustar precios obvio. Si alguna civ no tiene todos y tiene unificado está bien, pero si no nos quedamos cortos. Lo mismo para los militares: si arqueros, caballos, infantería, asedio, todo sale del mismo lugar, no tiene mucho sentido, la madera pasa a ser un poco innecesaria de colectar, etc."
>
> "Creo que necesitamos hacer ahora un estudio más serio de Age of Empires en todos estos sentidos, revisar en qué nos quedamos cortos, qué podemos adoptar y llevarlo adelante."

## Punto de partida (verificado en `data/edificios.json`)
- **Un solo almacén para todo:** `deposito` recibe alimento, madera, piedra y riqueza, igual que el centro.
- **Un solo cuartel para todo el ejército:** `cuartel` produce guerrero, hondero, lancero y ariete.
- **Movimiento:** los grupos se mueven cada unidad por su cuenta, sin formación ni velocidad común.

## Plan
1. **Estudio, con un equipo de agentes de perfiles distintos:**
   - (a) investigación de AoE4 (y AoE2 donde sirva) sobre movimiento de grupos y formaciones, almacenes, edificios de producción, y comodidades de economía y de órdenes;
   - (b) auditoría de nuestro juego contra esa lista;
   - (c) crítica de diseño: qué conviene adoptar, adaptado a nuestros pueblos y no como copia.
2. Plan priorizado en `docs/diseno/jugabilidad/`, con lo que cambia en datos y en la simulación.
3. Implementación por pasos, cada uno con su prueba, determinismo, banco y captura.

## Paso a paso
1. **(22:10) Estudio, primera vuelta: dos agentes en paralelo.**
   - **Referencia de AoE4** ([01-referencia-aoe4.md](../../docs/diseno/jugabilidad/01-referencia-aoe4.md), 70 fuentes: archivos del juego publicados por aoe4world, wiki, notas de parche, respuestas de desarrolladores en el foro):
     - **formación militar:** se arma sola, en un rectángulo de doble ancho que fondo, con choque adelante, distancia atrás y asedio al final, y todo el grupo a la velocidad del más lento; los rezagados corren +40 %;
     - **los aldeanos no forman en AoE4,** a propósito según un desarrollador: que esperen al grupo en viajes largos, como pide el autor, sería algo propio de Raíces;
     - **almacenes:** molino, maderero y minero a 50 de madera; quien construye uno empieza solo a recolectar lo más cercano;
     - **producción:** cuartel en la edad I; arquería y establo en la II (150 de madera cada uno); taller de asedio en la III (250). Ninguna civ unifica estos edificios;
     - **comodidades** que llegaron después del lanzamiento: patrullar, cola global de producción, seleccionar todos los edificios de un tipo, volver al trabajo;
     - **puntos débiles del estudio:** el ritmo de partida es la sección con menos datos.
   - **Auditoría de nuestro juego** ([02-auditoria.md](../../docs/diseno/jugabilidad/02-auditoria.md)), con mediciones propias:
     - **sin noción de grupo:** 24 unidades mandadas a 40 casillas llegan con 21 s de diferencia y se estiran hasta 14 casillas; los jinetes llegan 20 s antes que los lanceros, y las unidades se cruzan porque los lugares se reparten por número;
     - **al terminar un almacén,** el aldeano vuelve a lo que juntaba antes, no a lo que tiene al lado;
     - **la simulación ya admite almacenes de un solo recurso** (la qollqa inca funciona así): separarlos es sobre todo datos, interfaz e IA;
     - **un cuartel de 150 de madera** produce todo en cinco de seis civs;
     - **la madera** pesa 26–33 % de lo recolectado y no sobra, pero no decide nada porque un edificio alcanza para todo el ejército;
     - **fallas encontradas de paso:**
       - lo encolado con Mayús detrás de recolectar nunca sale;
       - Ayutthaya no puede investigar `hachas`, `canteria` ni `orfebreria` (no tiene depósito);
       - los mapuches no pueden investigar `cestas`, `riego` ni `mamposteria` (no tienen centro);
       - las proporciones de aldeanos de la IA están escritas en el código.
   - **Sigue:** un tercer agente, crítico de diseño, propone qué adoptar y cómo adaptarlo a cada pueblo, con historia y números (`03-propuesta.md`). Después, el plan por pasos.
