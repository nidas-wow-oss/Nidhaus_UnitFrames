*[Read in English](README.md)*

# Nidhaus UnitFrames (NUF)

Addon de interfaz orientado a PvP para World of Warcraft WotLK 3.3.5a (Warmane Blackrock y otros servidores privados).

NUF nació de combinar y reescribir varios addons existentes — entre ellos Eazy Frames y Sarena — sumándole funciones propias, sobre todo alrededor de los marcos de grupo. Todo quedó unificado en un solo paquete enfocado en interfaz y PvP: marcos de unidad configurables, herramientas específicas de arena (tracker de trinkets, detección de especialización, temporizadores, posiciones por estilo) y un sistema modular de más de cincuenta funciones opcionales, todo desde un único panel de opciones dentro del juego.

> ## Descarga
>
> **Última versión: 3.6** — es la build actual, la recomendada y la que está en uso.
>
> **[Descargar v3.6 (última release)](../../releases/latest)**
>
> Una sola descarga, todo incluido: el addon y su panel de opciones.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Cliente](https://img.shields.io/badge/Client-WotLK-orange)
![Licencia](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

---

## Qué trae este repositorio

Este repositorio contiene **los dos addons**. Necesitás ambos:

| Carpeta | Qué es |
|---|---|
| `Nidhaus_UnitFrames/` | El addon en sí. Obligatorio. |
| `Nidhaus_UnitFrames_Config/` | El panel de opciones dentro del juego (`/nufconfig`). Muy recomendado: sin él no hay interfaz de configuración. |

## Instalación

1. Descargá la **v3.6** desde la [página de releases](../../releases/latest).
2. Extraé el archivo. Vas a obtener dos carpetas: `Nidhaus_UnitFrames` y `Nidhaus_UnitFrames_Config`.
3. Copiá **las dos** carpetas a tu directorio `Interface/AddOns/` de WoW.
4. Reiniciá el cliente, o escribí `/reload` si ya estás en el juego.
5. Activá los dos addons en la pantalla de selección de personaje.

> **¿Venís de una versión anterior?** Borrá la carpeta vieja `Nidhaus_UnitFrames` antes de copiar la nueva, en vez de superponerla: la 3.6 reorganizó archivos y los restos de una build anterior pueden dar errores. Tu configuración vive en la carpeta `WTF` y se conserva.

> Si bajás el repositorio con el botón verde *Code* en vez de la release, la carpeta extraída se va a llamar `Nidhaus_UnitFrames-main` y va a tener las dos carpetas adentro. Copiá esas dos carpetas a `Interface/AddOns/` — no copies `Nidhaus_UnitFrames-main` en sí.

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

---

## Funciones principales

### Marcos de unidad

- **Marco del jugador** — reescalable, con variantes de textura clara y oscura, soporte de vehículos y estilo integrado para la mascota.
- **Marco del objetivo** — objetivo, foco, objetivo-del-objetivo y objetivo-del-foco, cada uno con su escala.
- **Marcos de grupo** — contenedor con espaciado y escala ajustables, más un modo 3v3 dedicado para arena.
- **Marcos de boss** — arrastrables, con ancla visual y espaciado/escala ajustables.
- **Barras de vida por color de clase** — con soporte de colores de reacción para NPCs.
- **Porcentaje de vida** — sobre el marco del objetivo, con indicador de fase de ejecución configurable.

### Sistemas de arena

- **Marcos de arena** — dos estilos completos: **Default** (Blizzard mejorado) y **Flat** (minimalista, competitivo).

<img width="215" alt="Marcos de arena" src="https://github.com/user-attachments/assets/ace03d46-ccb9-4952-b3c1-bdbd25d2b891" />

<img width="220" alt="Marcos de arena" src="https://github.com/user-attachments/assets/ba6e5101-b017-4d48-a4bc-9b57ba7d2023" />

<img width="212" alt="Marcos de arena" src="https://github.com/user-attachments/assets/431c3a78-f485-40e2-b942-b1a4e6202e0c" />

- **Arena Mover** — modo de prueba con vista previa de clases, para acomodar los marcos fuera de una partida.
- **Tracker de trinkets** — sigue el uso del trinket de PvP enemigo con indicador de cooldown.
- **Detección de especialización** — por combat log, con una base de más de 600 hechizos.
- **Cuenta regresiva de arena** — con temporizador de Shadow Sight.
- **Guardado de posiciones** — por estilo y por modo espejo, con claves compuestas.

### Modo espejo

Da vuelta la interfaz en horizontal (jugador a la derecha, objetivo a la izquierda). Los marcos de arena, las barras de casteo y los marcos de grupo respetan el estado del espejo de forma independiente.

### Posicionamiento

- **Frame Dragger** — mové cualquier marco soportado con `Shift + Alt + Click`.
- **Desbloquear todo** (`/move`) — overlay arrastrable sobre todos los marcos movibles a la vez, con imantado a una cuadrícula y escalado con `Ctrl + rueda`.

---

## Sistema modular

Cada función se prende o apaga por separado desde el panel, y al apagarla restaura el estado original.

### Mover cosas

| Módulo | Descripción |
|--------|-------------|
| **GlobalUnlock** | Modo *desbloquear todo*: overlay arrastrable sobre cada marco movible — jugador, objetivo, foco, grupo, barras de acción, buffs, debuffs, barra de casteo, Auto Shot y swing timer — y guarda cada posición. Los marcos se imantan a una cuadrícula para alinearlos fácil, y `Ctrl + rueda` agranda los que lo soportan. Comandos: `/move`, `/nufmove`, `/nufunlock` (`/move lock`, `/move reset`, `/move frames`). |
| **Frame Dragger** | Mové cualquier marco con `Shift + Alt + Click`. Las posiciones se guardan por marco. |
| **AuraAnchor** | Mueve tus buffs y debuffs. Resuelve que Blizzard vuelva a anclar `BuffButton1` en cada actualización, que es la razón por la que mover `BuffFrame` solo nunca funciona en 3.3.5a. |
| **PartyTestMode** | Muestra los cuatro marcos de grupo con datos falsos aunque estés solo, para acomodarlos junto con Party Buffs, Party Targets y Party Casting Bars sin necesitar un grupo real. `/nufparty` |
| **ArenaMover** | Modo de prueba de arena con vista previa de clases. `/nuf arena` o click derecho en el botón del minimapa. |

### Arena y PvP

| Módulo | Descripción |
|--------|-------------|
| **SpecIcons** | Detecta la especialización enemiga por combat log con una base de más de 600 hechizos. Muestra el icono en objetivo, foco y arena. |
| **Tracker de trinkets** | Sigue el trinket de PvP y los raciales que rompen control, por spell ID (no por nombre, así funciona en cualquier idioma del cliente). |
| **ArenaToT** | Muestra a quién está apuntando cada enemigo de arena, con marcos estilo ToT de Blizzard. Arrastrable, escalable, icono de clase o retrato. |
| **ArenaCountDown** | Cuenta regresiva en las rejas, disparada por los mensajes del sistema. Incluye temporizador de Shadow Sight. |
| **ArenaEndTimer** | Tiempo restante hasta que la arena termine en empate. `Alt + arrastrar` para mover. `/nuftimers` |
| **ArenaDalaranPipeTimer** | Temporizador de la cascada de la Arena de Dalaran, con el ciclo verificado contra la WeakAura de Warmane. |
| **ArenaRoVPillarTimer** | Temporizador de los pilares del Círculo de Valor: 45s el primer ciclo, después cada 25s. |
| **ArenaPointsCalc** | Calculadora de puntos de arena, integrada de Arena Points Calculator v2.1. `/apc`, `/arenapts` |
| **ArenaTimes** | Temporizador en el popup de invitación y tiempo en cola junto al minimapa. También funciona en campos de batalla. |
| **EnemySpellAlert** | Cuando un enemigo castea uno de los hechizos vigilados, su icono aparece en pantalla unos segundos. Basado en la WeakAura *Announce Spells*. |
| **SeductionAlert** | Avisa cuando la súcubo de un rival empieza a castear Seducción sobre vos. |
| **TabBinder** | En arena, campo de batalla y zonas en disputa, limita el `Tab` a jugadores enemigos. |
| **TooltipExtras** | Suma al tooltip la experiencia de arena (mejor rating personal de 2v2, 3v3 y 5v5) y otros datos. |

### Marcos de grupo

| Módulo | Descripción |
|--------|-------------|
| **NewPartyFrame** | Marcos de grupo con texturas propias, integrados con Party Buffs y Party Targets. <br><img width="75" alt="NewPartyFrame" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> |
| **PartyFramePW** | Un cuarto estilo de marco de grupo, tomado de pw_unitframes. |
| **PartyFrameStyle** | Coordina el aspecto de los marcos de grupo: los estilos son excluyentes, así que se asegura de que solo uno retexturice a la vez. `/nufpartystyle` |
| **PartyFramesImproved** | Mejoras sobre los marcos de grupo. `/nufpfi` |
| **PartyBuffs** | Buffs y debuffs extendidos (1 a 20 iconos) sobre los marcos de grupo, con posiciones independientes por modo. `/pbuffs` |
| **PartyTargets** | Muestra a quién apunta cada compañero, con espejo opcional y un estilo Square inspirado en pw_unitframes. `/ptarget`, `/ptstyle` <br><img width="100" alt="PartyTargets" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> |
| **PartyCastingBars** | Barras de casteo de los compañeros, con ventana de opciones propia. `/pcb` |
| **PartyPetFrame** | Marco dedicado a la mascota del compañero 1: retrato, vida/maná, casteo, buffs/debuffs y aviso de CC. `/ppf` |
| **Partymode3v3** | Disposición 3v3 para arena, con escala por integrante desde el panel. |

### Barras de acción

| Módulo | Descripción |
|--------|-------------|
| **ActionBars** | Unifica y retextura las barras de acción. Guarda todo el estado original antes de tocar nada y lo restaura exacto al desactivarse, con protecciones de combate y manejo de vehículos. |
| **MiniBar** | Disposición compacta: barra principal a media anchura, barras apiladas y marco de bolsas. Basado en FriskesBar. |
| **SideBarHover** | Muestra las barras laterales solo cuando el mouse está encima. |
| **ButtonRange** | Tiñe de rojo los botones fuera de alcance. |
| **HideActionBarTextures** | Quita los adornos de las barras de acción. `/hidebar` |
| **HideBindsAndMacros** | Oculta el texto de los bindeos y/o el nombre de las macros en los botones. |
| **SlotProfiles** | Copia barras, macros y bindeos de un personaje a otro. Portado de MySlot, con la interfaz sacada del chino y cuatro bugs reales corregidos. `/nufslot` |

### Trackers de clase y combate

| Módulo | Descripción |
|--------|-------------|
| **ClassTimers** | Barras de duración específicas por clase, portadas de MageNuggets. `/nufclass` |
| **ComboWatch** | Número grande de puntos de combo, coloreado según la cantidad. `/nufcombo` |
| **GargoyleTracker** | Tracker de gárgola para caballeros de la muerte. `/gt` |
| **HunterPetBuffs** | Fila de iconos bajo el marco de la mascota con los buffs que más importa vigilar como cazador. `/nufpetbuffs` |
| **AutoShotTimer** | Barra del disparo automático. Contempla Hacerse el muerto usando la velocidad sin modificar. `/nufshot` |
| **MeleeSwingTimer** | Barra hasta tu próximo golpe blanco, leída de tu propio combat log. `/nufswing` |
| **PaladinAuras** | Port nativo del grupo de WeakAuras *paladin wa*: proc de Cruzado, debuffs de sanación (Golpe Mortal / Disparo Certero / Veneno de Herida VII) y más. `/nufpal` |
| **PaladinICD** | Cooldowns internos visuales de las defensivas de paladín: Protección Divina, Escudo Divino, Mano de Protección, Ira Vengadora, Imposición de Manos. `/paladinicd` |
| **SacredShield** | Icono cuando tu objetivo tiene Escudo Sagrado. `/ss` |
| **SacredShieldTracker** | Recordatorio de renovación y seguimiento de Escudo Sagrado, portado de un grupo de WeakAuras. `/sst` |
| **ShieldWatch** | Barra con la absorción restante de los escudos. `/swh` |
| **DTSU** | Tracker de daño saliente — swing, directo y periódico — con iconos flotantes de total, último golpe y cantidad de impactos. `/dtsu` |
| **PowerBar** | Barra movible de recurso (maná, energía, rabia, poder rúnico, concentración) para tenerla cerca del personaje. Portada de MobileEnergy. `/nufpower` |
| **ArrowCount** | Cantidad de flechas o balas en las bolsas. `Alt + arrastrar` para mover. `/arrowcount` |
| **CastingBarTimer** | Tiempo de casteo en segundos sobre tu barra y la del objetivo. |
| **HealthPercentage** | Porcentaje de vida en el marco del objetivo, con umbral de ejecución configurable. |

### Aspecto

| Módulo | Descripción |
|--------|-------------|
| **Lorti UI** | Oscurece las texturas de los marcos y estiliza las barras de acción. Requiere `/reload` para aplicarse. |
| **ClassIcons** | Reemplaza los retratos por iconos de clase. Cuatro estilos: default, modern, hs, ex. Refresco limitado en arena por rendimiento. |
| **ClassOutline** | Anillo del color de la clase alrededor del retrato. Adaptado de RougeUI para 3.3.5a. |
| **AuraBorders** | Bordes de los iconos de buffs y debuffs, estilo pw_unitframes. |
| **CastBarPW** | Barras de casteo estilo pw_unitframes para jugador, objetivo y foco. |
| **AbbreviatedStatus** | Acorta los números de vida y maná en los marcos. Reimplementación propia de la idea de Abbreviated Status Text. |
| **HealthTextFormat** | Muestra solo el valor actual en vez de `actual / máximo`. |
| **UnitNameColor** | Color de los nombres: Default, Blanco o por Clase. |
| **MinimapStyle** | Minimapa redondo o cuadrado, y limpieza de los adornos que casi nadie usa: nombre de zona, reloj, botones de zoom. `/nufmap` |
| **MinimapIconToggle** | Botón en la esquina del minimapa que oculta o muestra todos los iconos de una. `/nufminimap` |
| **NiceDamage** | Reemplazo del texto de combate flotante con selector de fuente doble: una para daño y otra para sanación y auras, con vista previa. `/nd` <br><img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |

### Chat y comodidades

| Módulo | Descripción |
|--------|-------------|
| **ChatCopy** | Doble click en la pestaña del chat abre una caja con el historial para copiar. `/nufcopy` |
| **ChatURLs** | Convierte las URLs del chat en links clicables, abriendo una cajita para copiar. |
| **SystemSpamFilter** | Saca del chat los mensajes de sistema que son solo ruido: duelos ajenos, borracheras y "has aprendido X". `/nufspam` |
| **HideChatButton** | Botón para ocultar o mostrar todo el marco del chat. `/hcb` |
| **DuelBlocker** | Rechaza los duelos automáticamente. `/nufduel` |
| **AutoSell** | Vende los grises automáticamente al abrir un vendedor e informa el oro obtenido. |
| **AutoRepair** | Repara automáticamente, probando primero con el banco de hermandad, e informa el costo. |
| **ErrorHide** | Oculta los errores rojos durante el combate, con una red de seguridad que los restaura si algo sale mal. |
| **DungeonRoles** | Mientras estás en la cola del buscador de mazmorras, muestra cinco iconos — tanque, sanador y tres dps — que se encienden a medida que se llenan los roles. Portado de DisplayDungeon. |

---

## Panel de opciones

Interfaz de configuración completa dentro del juego, organizada en pestañas:

- **General** — ajustes globales: colores de clase, porcentaje de vida, modo espejo, frame dragger.
- **Marcos** — escala y posición de jugador, objetivo, grupo y boss, con vista previa en vivo.
- **Arena** — estilo de marcos (Default/Flat), trinkets, iconos de especialización y escalas de arena.
- **Módulos** — prendé y apagá cada módulo. Los que tienen sub-opciones despliegan su propio panel.
- **Extra** — utilidades sueltas (AutoSell, AutoRepair, ErrorHide).
- **Acerca de** — información del addon, versión y referencia de comandos.

### Perfiles

- **Exportar / importar** — serializá toda tu configuración a un texto para compartir o respaldar. La importación usa deserialización aislada por seguridad.
- **Slots con nombre** — guardá y cargá perfiles con nombre desde un desplegable.

---

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

---

## Compatibilidad

- **Cliente:** WoW 3.3.5a (WotLK)
- **Probado en:** Warmane Blackrock
- **API:** compatible con el sandbox Lua de 3.3.5a (sin HTTP, sin llamadas de hardware)

---

## Changelog

### v3.6
- Arregladas las opciones del menú de estilos
- Arreglados problemas de visualización de texto
- Arreglados varios bugs de marcos
- El panel de opciones ahora viene junto al addon, en la misma descarga

---

## Autor

**Nidhaus**

---

## Licencia

Todos los derechos reservados. Este addon se provee tal cual, para uso personal.
