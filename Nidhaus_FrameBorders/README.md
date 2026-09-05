# Nidhaus Frame Borders

Borde fino de esquina redonda y sombra exterior alrededor de las barras de acción,
el micromenú, las bolsas, la barra de casteo y las auras. Para WoW 3.3.5a (WotLK).

**Addon aparte, no un módulo.** No depende de Nidhaus UnitFrames ni de ningún otro:
si NUF no está instalado, esto anda igual.

## Uso

`/nfb` abre la ventana. También `/nfb on`, `/nfb off`.

En la ventana se elige dónde va el filo (barras de acción, micromenú, bolsas,
barra de casteo, auras), si lleva sombra exterior, y la letra de los botones
entre **Sin cambiar**, **Prototype** y **Prototype Outline**.

## Diagnóstico

| Comando | Qué hace |
|---|---|
| `/nfb list` | Lista lo que este addon está dibujando ahora mismo, con nombre y tamaño. |
| `/nfb what` | Da tres segundos para llevar el mouse a un punto y después nombra todos los marcos que hay debajo. |

El segundo existe porque en muchos clientes 3.3.5a `Blizzard_DebugTools` viene
vaciado y `/framestack` no funciona.

## Convivencia

- **Lorti UI** no dibuja bordes: tinta las texturas de Blizzard para oscurecerlas.
  Son dos capas distintas y se llevan bien. Donde sí se tocaban era en la letra de
  los botones; ahora Lorti pone tamaño y posición y le pregunta la familia a este
  addon.
- **La barra de casteo**: este addon esconde el marco y el destello de Blizzard
  mientras el grupo esté prendido. Si tenés el módulo pw Cast Bar de NUF, consulta
  antes de retexturarlos. Un solo dueño por textura.

## Arte

Las texturas de `Media/Border` las genera `Tools/mkborders.py`: geometría pura, un
perfil de alfa según la distancia al filo de cada casilla, con esquinas redondeadas
por arco. El script está en el repo, así que se pueden regenerar o retocar.

La fuente **Prototype** es freeware de Neale Davidson (Pixel Sagas). Su licencia pide
que viaje con su nota, que está en `Media/Fonts/Prototype.txt`.

## Autor

Nidhaus
