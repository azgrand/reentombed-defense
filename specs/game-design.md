# Diseño funcional · v0.3

Objetivo: defender la salida de una cripta durante diez oleadas. Estado inicial: 180 oro, 20 vidas. Estados: preparación → combate → preparación; victoria tras la última oleada vacía; derrota inmediata a cero vidas. Pausa congela movimiento, disparos, efectos y generación de enemigos.

## Torres

Los números autoritativos están en `data/balance.json`. Aguja: ataque rápido a un objetivo. Mortero: ataque lento con radio de explosión. Escarcha: daño bajo y ralentización al 45 % durante 1,6 segundos. La ralentización se renueva, no se acumula. Todas priorizan el enemigo vivo más avanzado dentro del alcance y pueden disparar sobre muros.

Construir requiere plataforma libre y oro suficiente. No se construye en el camino. Vender devuelve floor(precio × 0,65). Todas las torres admiten niveles 1–4. Los disparos aplican daño instantáneo; los rayos son su representación visual.

## Enemigos y oleadas

Oleada n: 6 + 2n enemigos; vida 32 + 13n; velocidad 2 + 0,09n celdas/s. Cada quinto enemigo global tiene ×2,2 vida y ×0,7 velocidad. Intervalo max(0,3; 0,95 − 0,04n) segundos. Primera aparición inmediata al siguiente tick. Recompensa por baja: 7 oro, 12 para el enemigo grande. Cada llegada a salida resta una vida. Bonificación de oleada: 25 oro. No se permiten oleadas simultáneas.

Reiniciar o regenerar descarta la partida en curso y restaura economía, efectos y oleadas. La semilla controla el mapa; no es un sistema de guardado.

## Arsenal y mejoras v0.3

Balance autoritativo en JSON: se conservan las tres torres previas y se añaden Veneno (6 directo + 9/s durante 3s, refresco sin stacking), Tormenta (18 inicial, hasta tres saltos de 1,8 celdas, ×0,7 por salto, sin repetir), Balista (30, tres impactos alineados con tolerancia 0,45) y Estandarte (sin ataques; aura strongest-only, excluye propia instancia).

La progresión JSON define multiplicadores de daño [1;1,35;1,75;2,25], adición de alcance [0;0,1;0,2;0,3] y aura [15;20;25;30]%. DOT permanece fijo. Costes de mejora ceil(base × [0,75;1,15;1,60]); venta floor(inversión total × 0,65). Estadísticas efectivas alimentan disparo y detalles; el aura divide cooldown por 1 + bonus al disparar, sin modificar definiciones. La inversión solo cambia en compras/mejoras correctas.

Pausa congela todos los ticks/animaciones y bloquea transacciones. Menú, ajustes y resultado están en una capa independiente. Volver al menú durante run requiere confirmación. Cambiar idioma no reinicia ni avanza run. El pronóstico de grandes usa `(next_enemy_id + offset) % 5 == 4`.
