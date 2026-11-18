# Generador · contrato v0.2

Entrada: semilla entera de 64 bits. Salida: diccionario `{seed, cells, route}`. Rejilla 29 × 21, `cells[y][x]`; 0 muro, 1 suelo decorativo, 2 camino reservado, 3 plataforma construible. `route` es una lista ordenada de Vector2i ortogonalmente adyacentes.

## Fases

1. RNG local de Godot inicializado con la semilla. No modifica el RNG global.
2. Generar por filas la mitad izquierda y reflejarla. Contexto: dos valores de la fila actual a la izquierda y tres de la fila anterior (izquierda, centro, derecha). `abcde` indexa la tabla de 32 entradas; −1 solicita un bit aleatorio. La tabla usa la convención propia del terreno (0 muro / 1 suelo), no los bytes del cartucho.
3. Crear un laberinto perfecto en una rejilla gruesa 14 × 10 mediante DFS aleatorio con retroceso. La selección de vecinos no visitados se pondera con el terreno contextual (peso 1 o 1,75). La entrada se elige en una fila aleatoria del borde izquierdo. Se guardan padres y profundidades durante el recorrido.
4. Elegir la celda de la fila inferior más profunda en el árbol y reconstruir su ruta mediante padres. Expandir cada paso grueso a dos pasos ortogonales, añadir portales de borde y reservar el camino. Las ramas restantes son suelo decorativo; solo el camino reservado admite enemigos. No se conserva la simetría del terreno inicial.
5. Convertir todo vecino ortogonal interior del camino que no sea camino en plataforma. El suelo decorativo no admite torres ni enemigos.

## Invariantes

- Mismas semilla, versión del generador y versión del motor: mismo resultado.
- Ruta contigua, sin celdas duplicadas, dentro de límites y marcada como camino.
- Entrada y salida distintas; al menos 30 plataformas, todas junto a la ruta.
- Construir no modifica `cells` ni `route`; la ocupación vive en el estado de torres.
- Complejidad O(ancho × alto + longitud de ruta). No hay reintentos ni búsquedas sin límite.

## Referencia y diferencias

La generación contextual de cinco bits, por filas y con simetría está documentada por Newell, Aycock y Biittner (2022), *Still Entombed After All These Years*, sección 3: https://doi.org/10.11141/ia.59.3. Esta implementación es una adaptación propia para tower defense; no copia código, ROM ni assets. La reserva del recorrido y la clasificación de plataformas son añadidos del proyecto.

## Semillas y compatibilidad

La aplicación usa un RNG local aleatorizado al abrirse para elegir semillas. Nuevo mapa consume otra semilla y evita repetir la actual. Repetir semilla usa la entrada escrita. La semilla y la longitud se muestran bajo el tablero. v0.2 sustituye las seis franjas fijas de v0.1: una semilla antigua produce un mapa nuevo con este generador.

Una integración futura con un mapeador externo concreto puede reemplazar `EntombedMapper.generate` conservando este contrato. No se ha recibido ningún código externo de mapeador.
