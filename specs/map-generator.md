# Generador · contrato v0.3

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

## Selección y presentación v0.3

Se generan exactamente 16 candidatos con semillas `seed * 104729 + index * 8191`. Se conserva el mayor score y el orden resuelve empates. Score: 200 − 0,7 × distancia de longitud a 85; penalización 40 fuera de 45–120; 3 por tramo de una celda antes de giro, 0,5 por otro giro, 0,4 por giro total y 0,4 por pares de segmentos cercanos separados en el recorrido. No se descartan mapas válidos por preferencias estéticas.

Las plataformas candidatas se ordenan al recorrer la ruta y se muestrean de forma uniforme: entre 30 y 44, según longitud y disponibilidad. La prueba de 1000 semillas verifica el mínimo y la adyacencia. No se cambian los IDs de celda. Se añaden `generator_version`, `quality_score`, `theme` y `decorations`. Semillas v0.2 no son compatibles visualmente.

Cinco centros de agrupación generan bosques; rocas y setas aparecen de forma más aislada. Un margen de una celda alrededor de camino, plataformas y portales excluye decoraciones. Tres tintes de terreno dependen de semilla. Se inspeccionaron semillas 0–17, 42 y 2026: menos piedra, grupos distinguibles, algunos claros amplios deliberados. La capa estática registra comandos Canvas una vez al generar, no en cada frame. El atlas 48×48 es un anillo de nueve regiones: se usan cuadrantes exteriores de 8px y base sólida para mantener continuidad, evitando huecos del centro transparente.
