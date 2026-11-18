# Validación v0.3 · 18 de noviembre de 2026

Motor real: Godot 4.6.stable.official.89cea1439, Linux x86_64. `python3 tools/verify_project.py --godot /tmp/reentombed-godot/run`: **All project checks passed**, salida 0. El binario temporal no forma parte del proyecto.

Resultados:

- Balance, recursos y WAV: OK. Gettext: 65 claves ES/EN, paridad de nombres y placeholders y referencias desde datos/código.
- Importación completa: sin errores de script. El sandbox emite avisos de sockets TCP del editor; no afectan al juego.
- 1000 semillas: determinismo de mapa/tema/decoración, rutas únicas/contiguas, portales, 30–44 pads válidos y exclusión de decoraciones. 1000 rutas distintas, 10 entradas y 45 longitudes.
- Suite heredada conservada y ampliada a siete torres: compras, ocupación, oleadas, bajas, victoria/derrota y ataques.
- Efectos: DOT/refresh/no-stack/expiración/pausa/recompensa única; cadena y caída 70%; perforación única; aura strongest-only, mejora y venta dinámicas/exclusión propia.
- Mejoras: siete torres hasta nivel 4, fórmulas de daño/alcance/aura, inversión/reembolso, insuficiencia de oro, máximo, estado obsoleto, operaciones pausadas y ausencia de arbitraje.
- Navegación: pausa sin avance, ajustes, idioma de HUD en vivo, cancelar confirmación preserva run y cambio al menú libera escena anterior.
- Preferencias: persistencia y defaults con archivo corrupto/locale no soportado. No se escribe una run.
- Pronóstico exacto de grandes para 100 combinaciones de oleada/contador. Colocación inválida no cobra. Siete tarjetas dentro de GridContainer de dos columnas.
- Arranque del menú con `--quit-after 120`: OK.

## QA visual

Se revisaron 20 semillas (0–17,42,2026), contacto en `previews/milestone-3/contact-sheet.png`, y capturas de menú, ajustes ES, tienda EN, torre nivel 4, combate y ventana 1024×640. Render real OpenGL/Mesa en Xvfb; advertencias de VSync y método de entrada no disponibles. El fixture de combate ajusta HP y max_hp juntos; las barras se limitan a [0,1]. No hay errores de scripts en capturas finales.

## Balance observado

`tools/balance_review.gd` compra tipos en orden, eligiendo plataformas por cobertura, sin mejoras, con economía inicial y precios reales. Semillas 0/42/2026, rutas 97/75/71: las tres completan oleada 10 con 20 vidas, 19 torres y 140 oro. Resultado de una política concreta; no representa dificultad para una persona. No se retocaron precios sin evidencia adicional.

## Límites pendientes de aceptación interactiva

No se afirma haber escuchado audio, probado gamepad físico, jugado manualmente una campaña completa ni generado exports con plantillas. La comodidad de controles y dificultad humana siguen pendientes. Los PNG aportados no contienen licencia; se conserva el uso local existente sin redistribución adicional. No se publica ni se hace push.
