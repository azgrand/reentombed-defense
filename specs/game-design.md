# Diseño funcional · v0.1

Objetivo: defender la salida de una cripta durante diez oleadas. Estado inicial: 180 oro, 20 vidas. Estados: preparación → combate → preparación; victoria tras la última oleada vacía; derrota inmediata a cero vidas. Pausa congela movimiento, disparos, efectos y generación de enemigos.

## Torres

Los números autoritativos están en `data/balance.json`. Aguja: ataque rápido a un objetivo. Mortero: ataque lento con radio de explosión. Escarcha: daño bajo y ralentización al 45 % durante 1,6 segundos. La ralentización se renueva, no se acumula. Todas priorizan el enemigo vivo más avanzado dentro del alcance y pueden disparar sobre muros.

Construir requiere plataforma libre y oro suficiente. No se construye en el camino. Vender devuelve floor(precio × 0,65). No hay mejoras en v0.1. Los disparos aplican daño instantáneo; los rayos son su representación visual.

## Enemigos y oleadas

Oleada n: 6 + 2n enemigos; vida 32 + 13n; velocidad 2 + 0,09n celdas/s. Cada quinto enemigo global tiene ×2,2 vida y ×0,7 velocidad. Intervalo max(0,3; 0,95 − 0,04n) segundos. Primera aparición inmediata al siguiente tick. Recompensa por baja: 7 oro, 12 para el enemigo grande. Cada llegada a salida resta una vida. Bonificación de oleada: 25 oro. No se permiten oleadas simultáneas.

Reiniciar o regenerar descarta la partida en curso y restaura economía, efectos y oleadas. La semilla controla el mapa; no es un sistema de guardado.
