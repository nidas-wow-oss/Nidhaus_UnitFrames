*[Read in English](README.md)*

# Nidhaus UnitFrames (NUF)

Addon de interfaz orientado a PvP para World of Warcraft WotLK 3.3.5a (Warmane Blackrock y otros servidores privados).

NUF combina y reescribe varios addons existentes — entre ellos Eazy Frames y sArena — con funciones propias, en un solo paquete enfocado en interfaz y PvP y configurable desde un único panel dentro del juego.

> ## Descarga
>
> **Última versión: 4.3** — es la build actual, la recomendada y la que está en uso.
>
> **[Descargar v4.3 (última release)](../../releases/latest)**
>
> Una sola descarga, todo incluido: el addon y su panel de opciones.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Cliente](https://img.shields.io/badge/Client-WotLK-orange)
![Licencia](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

## Funciones

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/panel.png" width="559" alt="Panel de opciones de NUF" />

- **Marcos de unidad** — jugador, objetivo, foco, grupo y boss, con skins propias, colores de clase y escala por marco.
- **Arena** — marcos de arena en dos estilos (Default y Flat) con trinkets, iconos de especialización, DR, DoTs y cuenta regresiva, y un modo de prueba para ubicarlos fuera de una partida.
- **Grupo** — disposición 3v3 para arena con escala por miembro, y un modo de prueba para acomodar el grupo estando solo.
- **Move Everything** — arrastrá cualquier marco y cambiale el tamaño con Ctrl + rueda.
- **Módulos opcionales** — barras de acción, trackers de clase, tooltip, chat y extras de comodidad, cada uno se prende o apaga desde el panel.
- **Character Setup** — copiá barras de acción, macros y bindeos entre personajes (nExtraBars incluido).
- **Perfiles** — exportá e importá toda tu configuración.

<img width="215" alt="Arena" src="https://github.com/user-attachments/assets/ace03d46-ccb9-4952-b3c1-bdbd25d2b891" /> <img width="220" alt="Arena" src="https://github.com/user-attachments/assets/ba6e5101-b017-4d48-a4bc-9b57ba7d2023" /> <img width="212" alt="Arena" src="https://github.com/user-attachments/assets/431c3a78-f485-40e2-b942-b1a4e6202e0c" /> <img width="137" alt="DoT warning" src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dot-warning.png" />

| Marcos de grupo | Objetivos del grupo | NiceDamage |
|:-:|:-:|:-:|
| <img width="75" alt="NewPartyFrame" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> | <img width="100" alt="PartyTargets" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> | <img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |

## Arena: DR y DoTs

Dos trackers que viven al lado de los marcos de arena. Los dos vienen prendidos de fábrica y se
configuran en el panel, en **Arena > DR** y **Arena > DoT** (Vista previa los muestra sin estar en
una partida; Shift + Alt + arrastrar mueve los cinco marcos juntos).

### Diminishing Returns

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dr-panel.png" width="555" alt="Opciones de DR" /> <img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dr-ingame.png" width="316" alt="Iconos de DR al lado de los marcos de arena" />

Un icono por categoría de DR en cada enemigo de arena, con un reloj que cuenta hasta que se
reinicia: **1/2** significa que el próximo CC de ese tipo dura la mitad, **1/4** un cuarto, **X**
que es inmune. El DR es compartido por categoría, así que la trampa del cazador lo comparte con
Polimorfia, Sap, Reprensión y las demás.

De fábrica: iconos de 25 creciendo hacia la izquierda, el reloj prendido, sin borde de color y sin
el texto "1/2 - 1/4 - X" — en plena pelea el reloj ya te dice lo que necesitás.

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dr-categories.png" width="298" alt="Categorías de DR" />

Solo se muestran **Aturdimientos** e **Incapacitaciones**. Las demás categorías siguen contando por
detrás, así que si tildás una más tarde aparece ya al día. *Todas*, *Mi clase* y *Ninguna* cambian
la lista entera de una.

### DoTs

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dot-panel.png" width="389" alt="Opciones de DoT" />

El daño periódico que tenés puesto en cada enemigo de arena, en iconos chicos al lado de su marco,
para ver de un vistazo a quién le falta el tuyo y cuándo está por caerse.

De fábrica: hasta 3 iconos de 14 pegados entre sí, creciendo hacia afuera del marco, sin el texto
"DoT" ni el borde rojo.

## Instalación

1. Descargá **`Nidhaus_UnitFrames-v4.4.zip`** desde la [página de releases](../../releases/latest).
   Ese archivo, **no** el "Source code (zip)": GitHub mete la descarga del código dentro de una
   carpeta extra `Nidhaus_UnitFrames-main`, y copiar *esa* a `Interface/AddOns/` no hace nada.
2. Extraé el archivo. Vas a obtener tres carpetas: `Nidhaus_UnitFrames`, `Nidhaus_UnitFrames_Config` y `Nidhaus_UnitFrames_Arena`.
3. Copiá **las tres** carpetas a tu directorio `Interface/AddOns/` de WoW.
4. Reiniciá el cliente, o escribí `/reload` si ya estás en el juego.
5. Activá **los tres** addons en la pantalla de selección de personaje. `Nidhaus_UnitFrames_Arena` es nuevo en la v4.4 y trae los marcos de arena: si no lo tildás, la arena no anda.

> **¿Venís de una versión anterior?** Borrá la carpeta vieja `Nidhaus_UnitFrames` antes de copiar la nueva, en vez de superponerla: entre releases se reorganizan archivos y los restos de una build anterior pueden dar errores. Tu configuración vive en la carpeta `WTF` y se conserva.

> **El botón verde *Code* no es la descarga que querés.** Te da una carpeta `Nidhaus_UnitFrames-main`
> con las tres carpetas del addon *adentro*. WoW no las ve: en `Interface/AddOns/` tienen que estar las
> tres carpetas `Nidhaus_UnitFrames*` en sí, no el envoltorio. Si ya lo bajaste así, abrí
> `Nidhaus_UnitFrames-main` y sacá las tres carpetas de adentro.

## Comandos

| Comando | Acción |
|---------|--------|
| `/nuf` | Abre el panel de opciones |
| `/nuf config` | Muestra las variables guardadas en el chat |
| `/nuf arena` | Activa el modo de prueba de arena |
| `/nuf boss` | Activa el modo de prueba de marcos de boss |
| `/nuf reset` | Restablece toda la configuración |
| `/nuf modules` | Lista los módulos y su estado |
| `/move` o `/nufmove` | Modo desbloquear todo: mové cualquier marco arrastrándolo |

El botón del minimapa también sirve de atajo: click izquierdo abre las opciones, click derecho activa el mover de arena.

## Compatibilidad

- **Cliente:** WoW 3.3.5a (WotLK)
- **Probado en:** Warmane Blackrock
- **API:** compatible con el sandbox Lua de 3.3.5a (sin HTTP, sin llamadas de hardware)

## Créditos

NUF está construido sobre el trabajo de mucha gente. El motor y varios módulos son ports o adaptaciones, y el crédito de esos es de sus autores originales:

| Proyecto original | Autor | Usado para |
|---|---|---|
| Eazy Frames, Sarena | — | Base del trabajo de marcos de unidad |
| pw_unitframes | — | Bordes de auras, barras de casteo, PartyFramePW, estilo Square de PartyTargets |
| RE/TabBinder | Veev, AcidWeb | TabBinder |
| TipTacTalents | Aezay | Talentos en el tooltip |
| PvPRating | Fernir | Experiencia de arena en el tooltip |
| AuraSource | Renstrom | Quien lanzo el buff, en el tooltip |
| FriskesUI | Friskes | MiniBar (FriskesBar) |
| RougeUI | — | ClassOutline |
| MageNuggets | — | ClassTimers |
| MySlot | tg123 | SlotProfiles |
| MobileEnergy | B-Buck | PowerBar |
| ZAutoShot | — | AutoShotTimer |
| ShieldWatch | — | ShieldWatch |
| !ComboWatch | — | ComboWatch |
| DisplayDungeon | Smokey | DungeonRoles |
| PartyFramesImproved | SoupsBelly, que viene de UnitFramesImproved (kiforsbe) y PartyTarget (Valconeye) | PartyFramesImproved |
| Abbreviated Status Text | RomanSpector | AbbreviatedStatus (reimplementado) |
| Arena Points Calculator | — | ArenaPointsCalc |
| AutoSell, ErrorHide | FatalEntity | Ambos módulos |
| Varias WeakAuras | — | PaladinAuras, SacredShield, SacredShieldTracker, SeductionAlert, EnemySpellAlert, temporizador de Dalaran |

Integración, port a 3.3.5a, corrección de bugs y todo lo demás: **Nidhaus**.

## Licencia

Todos los derechos reservados. Este addon se provee tal cual, para uso personal.
