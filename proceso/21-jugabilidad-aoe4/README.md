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
