.linecont       +               ; Permitir continuar lineas
.feature        c_comments      /* Soportar comentarios tipo C */

;;Este programa utiliza mario.chr como rom de caracteres y sprites
;; Dibuja un mapa (NewWorld) basico con un tubo, algunas nubes solidas
;; y ladrillos como plataforma. Dibuja un solo BOX (?) el cual cuando
;; es golpeado por debajo muesta un hongo (fijo). Al comerlo mario 
;; escucha Lucy in the Sky with diamonds mientras el cielo cambia de 
;; color.

;; El Sprite de mario se dibuja de acuerdo a su estado. Cuando corre
;; para un costado se muestra el movimiento. Cuando se queda quieto
;; mira para el ultimo lado. Cuando salta levanta la mano y cuando cae
;; junta los brazos. Tiene soporte de gravedad.

;; Autor Edgardo Gho
;; Junio 2020

;;El archivo mario.chr es propiedad de Nintendo.

;;Declaramos constantes
JOYPAD1 = $4016
JOYPAD2 = $4017
BUTTON_A      = 1 << 7
BUTTON_B      = 1 << 6
BUTTON_SELECT = 1 << 5
BUTTON_START  = 1 << 4
BUTTON_UP     = 1 << 3
BUTTON_DOWN   = 1 << 2
BUTTON_LEFT   = 1 << 1
BUTTON_RIGHT  = 1 << 0

;Hacemos definiciones MACROS para que los colores 
;sean mas faciles de utilizar
;Tomado de:
;https://github.com/battlelinegames/nes-starter-kit
DARK_GRAY = $00
MEDIUM_GRAY = $10
LIGHT_GRAY = $20
LIGHTEST_GRAY = $30

DARK_BLUE = $01
MEDIUM_BLUE = $11
LIGHT_BLUE = $21
LIGHTEST_BLUE = $31

DARK_INDIGO = $02
MEDIUM_INDIGO = $12
LIGHT_INDIGO = $22
LIGHTEST_INDIGO = $32

DARK_VIOLET = $03
MEDIUM_VIOLET = $13
LIGHT_VIOLET = $23
LIGHTEST_VIOLET = $33

DARK_PURPLE = $04
MEDIUM_PURPLE = $14
LIGHT_PURPLE = $24
LIGHTEST_PURPLE = $34

DARK_REDVIOLET = $05
MEDIUM_REDVIOLET = $15
LIGHT_REDVIOLET = $25
LIGHTEST_REDVIOLET = $35

DARK_RED = $06
MEDIUM_RED = $16
LIGHT_RED = $26
LIGHTEST_RED = $36

DARK_ORANGE = $07
MEDIUM_ORANGE = $17
LIGHT_ORANGE = $27
LIGHTEST_ORANGE = $37

DARK_YELLOW = $08
MEDIUM_YELLOW = $18
LIGHT_YELLOW = $28
LIGHTEST_YELLOW = $38

DARK_CHARTREUSE = $09
MEDIUM_CHARTREUSE = $19
LIGHT_CHARTREUSE = $29
LIGHTEST_CHARTREUSE = $39

DARK_GREEN = $0a
MEDIUM_GREEN = $1a
LIGHT_GREEN = $2a
LIGHTEST_GREEN = $3a

DARK_CYAN = $0b
MEDIUM_CYAN = $1b
LIGHT_CYAN = $2b
LIGHTEST_CYAN = $3b

DARK_TURQUOISE = $0c
MEDIUM_TURQUOISE = $1c
LIGHT_TURQUOISE = $2c
LIGHTEST_TURQUOISE = $3c

BLACK = $0f
DARKEST_GRAY = $2d
MEDIUM_GRAY2 = $3d


;Posicion fija del hongo
HONGOX = 64
HONGOY = 76

;Indices de las notas musicales 
NC4 = 0
NC4b= 1
ND4 = 2
ND4b= 3
NE4 = 4
NF4 = 5
NF4b= 6
NG4 = 7
NG4b= 8
NA4 = 9
NA4b= 10
NB4 = 11

NC5 = 12
NC5b= 13
ND5 = 14
ND5b= 15
NE5 = 16
NF5 = 17
NF5b= 18
NG5 = 19
NG5b= 20
NA5 = 21
NA5b= 22
NB5 = 23

SIL = 24

;Definir el segmento HEADER para que FCEUX reconozca el archivo .nes 
;como una imagen valida de un cartucho de NES

.segment "HEADER"

; Configurar con Mapper NROM 0 con bancos fijos
  .byte 'N', 'E', 'S', $1A    ; Firma de NES para el emulador
  .byte $02                   ; PRG tiene 16k 
  .byte $01                   ; CHR tiene 8k (usar mario.chr)
  .byte %00000000             ;NROM Mapper 0
  .byte $0, $0, $0, $0, $0, $0
; Fin del header 
;; Este Header se encuentra definido en el archivo link.x el cual
;; define donde va a quedar en el archivo .NES final


;Incluir el binario con las imagenes de la rom de caracteres
.segment "IMG"
.incbin "mario.chr"

;Declaracion de variables en la pagina 0
;; Esto es RWM (RAM), por ende se "reservan" bytes
;; para luego ser usados como variables.
.segment "ZEROPAGE"
    ;;MarioOffsetX,Y guardan la posicion de mario UL.
    MarioOffsetX: 		.res 1
    MarioOffsetY: 		.res 1
    ;Mario ocupa 4 sprites (UL,UR,LL,LR) solo guardamos
    ;el punto UL (arriba izquierda) ya que el resto se
    ;calcula en base a este unico punto
    
    ;;MarioEstadoSalto guarda el estado del salto.
    ;;  %00000000=No esta saltando
    ;;  %10000000=Comenzo a saltar
    ;;  %10xxxxxx=Estado salto ascendente
    ;;  %01xxxxxx=Cayendo por gravedad
    MarioEstadoSalto:  	.res 1
    
    ;;MarioEstadoSprite indica que dibujo le corresponde
    ;; 00 -> Moviendose derecha etapa 0 (manos separadas)
	;; 01 -> Moviendose derecha etapa 1 (manos juntas)
	;; 02 -> Moviendose derecha etapa 2 (mano adelante)
	;; 03 -> Moviendose derecha etapa 3 (manos juntas)
	;; 04 -> Quieto mirando derecha
	;; 05 -> Salto 
	;; 06 -> Caida 
  
	;; 80 -> Moviendose izquierda etapa 1 (manos separadas)
	;; 81 -> Moviendose izquierda etapa 2 (manos juntas)
	;; 82 -> Moviendose izquierda etapa 3 (mano adelante)
	;; 83 -> Moviendose izquierda etapa 2 (manos juntas)
	;; 84 -> Quieto mirando izquierda
	;; 85 -> Salto izquierda
	;; 86 -> Caida izquierda
    MarioEstadoSprite: 		.res 1
    ;;MarioEstadoSpritedb es un puntero de 16 bits a memoria ROM
    ;;para recorrer la tabla con los sprites correspondientes
    ;;a los estados de mario. Se necesitan 16 bits para apuntar
    ;;en modo indirecto indexado (MarioEstadoSpritedb),y.
    MarioEstadoSpritedb:	.res 2
    
    ;;MarioUltimoLado indica para que lado quedo mirando mario
    ;; 0 --> derecha , 1 --> izquierda
    MarioUltimoLado:	.res 1
    ;Esto se actualiza cada vez que se aprieta un boton LEFT o RIGHT
    ;del Joystick. Right resetea el bit y Left setea el bit menos sig.
    
    ;;JoystickPress ; Indica que boton se apreto en el joystick
    ;; %UP DOWN LEFT RIGHT START SELECT A B: 1=apretado, 0=no apretado
    JoystickPress:		.res 1
    
    ;;Variables usadas para encontrar posiciones
    NameTablePointer:  	.res 2 ;Puntero a nametable
    ;Se usa para el modo de direccionamiento indexado indirecto
    ;de forma de recorrer un Nametable de 960 bytes apuntando
    ;con (NameTablePointer),Y.
    
    ;;Variables de Tile. Se usan para ubicar un Tile en pantalla usando
    ;;las coordenadas de pantalla (x,y) reales.
    FindTileX:    .res 1
    FindTileY:    .res 1
    ;Tanto FindTileX e Y se cargan con coordenadas X,Y reales de
    ;pantalla (ej: posicion de un sprite) y se usan para encontrar
    ;en un Nametable cual es el valor para el tile correspondiente
    ;a la posicion X,Y.
    TileCount:    .res 1
    ;TileCount se usa para contar tiles que generalmente respetan un 
    ;cierto patron, ej: menor a $3F quiere decir que es transparente,
    ;por ejemplo nubes o arbustos o elementos que mario pasa por 
    ;adelante sin chocar. A diferencia de bloques, nubes solidas,etc.
    
    ;;Variable para contar los puntos.
    Puntos1:	  .res 1
    Puntos0:      .res 1
    
    ;;Variable FLAG usado para indicar que hubo una NMI y por ende
    ;;podemos actualizar la pantalla ya que el NES no la esta dibujando.
    FlagNMI:      .res 1
    
    ;;Contador de Frames (NMIs) que sirve para contar tiempo real
    FrameCounter: .res 1
    
    ;;Flag para indica que debe dibujarse el hongo
    HongoVisible: .res 1
    
    ;;Flag usado para indicar que mario choco con el hongo
    SpriteChoca:  .res 1
    
    ;;Variables usadas para la musica
    LSDPlaying:   .res 1
    ;LSDPlaying=1 --> Esta tocando la musica
    LSDNote:	  .res 1
    ;Puntero a la nota que se esta reproduciendo
    LSDNoteTime:  .res 1
    ;Contador de tiempo para la nota.
    LSDSky:       .res 1
    ;Color del cielo usado en el primer byte de la paleta de colores
    ;para cambiar el color del cielo cuando mario escucha LSD.
    
    PaletteBlink: .res 1


;;Segmento de codigo guardado en la ROM
.segment "CODE"

;Rutina de interrupcion (IRQ)
;No es utilizada por ahora
irq:
	rti
	
;;Rutina de interrupcion (Reset)
;;; Esta rutina se dispara cuando el nintendo se enciende 
;;; o se aprieta el boton de reset. Se encarga de inicializar
;;; el hardware
reset:
  SEI          ; desactivar IRQs
  CLD          ; desactivar modo decimal
  
  ;;Durante el encendido del Nintendo hay que respetar unos tiempos 
  ;;hasta que el PPU se encuentra listo para ser utilizado.
  ;;A continuacion se siguen los pasos sugeridos en:
  ;; https://wiki.nesdev.com/w/index.php/Init_code
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs
  
vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

;; Cargamos las paletas de color del fondo y de los sprites.
;; Codigo adaptado para CC65 tomado de: 
;; https://gist.github.com/camsaul/0bd13b94574d936ce9a7
 
LoadPalettes:
  LDA $2002     ; read PPU status to reset the high/low latch to high
  LDA #$3F
  STA $2006     ; write the high byte of $3F10 address
  LDA #$00
  STA $2006     ; write the low byte of $3F10 address

  ;; Load the palette data
  LDX #$00
LoadPalettesLoop:
  LDA NewWorldPalette, x;load data from address (PaletteData + x)
  STA $2007             ; write to PPU
  INX                   ; (inc X)
  CPX #$20              ; Compare X to $20 (decimal 32)
  BNE LoadPalettesLoop  ; (when (not= x 32) (recur))
  
  ;;Inicializamos las variables Puntos ya que se van a dibujar
  ;;ahora que cargamos el fondo.
  LDA #$00
  STA Puntos1
  LDA #$00
  STA Puntos0
  LDA #$00
  STA PaletteBlink

  ;; Ahora que las paletas estan cargadas, podemos dibujar el fondo
  JSR SUBDibujaFondo

  ;; Encendemos el PPU 
  ;; y el barrido vertical 
  ;; y apuntamos el PPU a 
  ;; la tabla 0 de sprites 
  ;; y 1 para fondos
  
  LDA #%10010000 
  STA $2000
  
  ;; Encendemos Sprites, Background y sin clipping en lado izquierdo
  LDA #%00011110   
  STA $2001
  
  ;;Apagamos el scroll del background (fondo)
  LDA #$00       
  STA $2005
  STA $2005
  
  ;;Habilitamos las interrupciones
  CLI
 
  ;;Prendemos audio
  ;;  Solo canal Pulse 1 (primer canal onda cuadrada)
   lda #%00000001
   sta $4015
  
  ;;Inicializamos las variables
  ;;Le damos un offset inicial a mario en X e Y
  LDA  #$C0
  STA  MarioOffsetY
  LDA #$20
  STA MarioOffsetX
  ;;Cielo color azul al principio
  LDA #$21
  STA LSDSky
  ;;Arranca mirando a la izquierda
  LDA #$01
  STA MarioUltimoLado
  LDA #$80
  STA MarioEstadoSprite
  ;;No arranca saltando
  LDA #$00
  STA MarioEstadoSalto
  
  ;;Ponemos en cero otras variables
  STA FrameCounter
  STA HongoVisible
  STA LSDPlaying
  STA LSDNote
  STA LSDNoteTime
  

  ;;Aqui termina la runtina de reset.. el codigo va a quedar ciclando
  ;;en la siguiente posicion. Dado que solo se puede refrezcar la
  ;;pantalla cuando no se esta dibujando.. usamos el FlagNMI para 
  ;;indicar cuando es seguro refrezcar la pantalla. 
FIN:
	LDA FlagNMI
	BEQ FIN ;;Queda loopeando mientras FlagNMI=0
	LDA #$0
	STA FlagNMI 
	;;Ahora es seguro escribir cosas en la memoria de la pantalla
	
	;;Empezamos controlando la musica
	JSR SUBPlayLSD
	;;Llevamos la cuenta de los frame en FrameCounter
	;;Se resetea cada 50 frames (1 segundo)
	inc FrameCounter
	LDA FrameCounter
	AND #%00000111
	CMP #%00000111
	BNE incSeg
	JSR SUBBlinkPalette

incSeg:	
	LDA FrameCounter
	CMP #50
	BNE sigueMain
	LDA #0
	STA FrameCounter
sigueMain:
    ;;Dibujamos los tiles de SCORE en caso que hayan cambiado
	JSR SUBActualizaScore
  
  ;Dado que en $0200~$02ff tenemos cargados los sprites
  ;Utilizamos el DMA para transferir estos 256 bytes a memoria
  ;de video en la ubicacion de los sprites.
  LDA #$00
  STA $2003  ; cargamos en el DMA la parte baja de 0200
  LDA #$02
  STA $4014  ; cargamos en el DMA la parte alta de 0200 y comienza.
  ;Esto deberia bloquear el procesador hasta que termina.
  
  ;;Leemos el joystick. Esto actualiza la variable JoystickPress
  JSR SUBReadJoy
  
  ;;Actualizamos la posicion de mario
  LDA JoystickPress
  AND #BUTTON_RIGHT
  BEQ noRight
  ;; Se apreto el boton derecho
  LDA #$00
  STA MarioUltimoLado ;;Actualizamos el lado que mira mario
  ;;Verificamos si a la derecha hay algo 
  JSR SUBVerificarCostado
  ;;Si el resultado da 0, entonces es seguro mover, sino no
  BNE noRight
  INC MarioOffsetX
     
noRight:
  ;; Verificamos si apreto  a la izquierda
  LDA JoystickPress
  AND #BUTTON_LEFT
  BEQ noLeft
  LDA #$01
  STA MarioUltimoLado ;;Actualizamos el lado que mira mario
  ;;Verificamos si a la izquierda hay algo 
  JSR SUBVerificarCostado
  ;;Si el resultado da 0, entonces es seguro mover, sino no
  BNE noLeft
  DEC MarioOffsetX
  
noLeft:
  ;;Vemos si apreto el boton A
  LDA JoystickPress
  AND #BUTTON_A
  BEQ noButtonA
  ;;Si se apreto A, hay que verificar si no esta saltando
  LDA MarioEstadoSalto
  AND #%10000000
  BNE finBotonesCheck ;; si Acc=0 no estaba saltando
  ;;Hay que ver que no este cayendo por gravedad
  LDA MarioEstadoSalto
  AND #%01000000
  BNE finBotonesCheck
  ;;Como no estaba saltando ni cayendo por gravedad entonces
  ;;Ponemos 1 en el bit mas significativo de MarioEstadoSalto
  ;;Para indicar que tiene que saltar
  LDA #%10000000
  STA MarioEstadoSalto
noButtonA:
  ;;Aqui deberiamos verificar el boton B si se usara para algo 
finBotonesCheck:

;;;;
;; Ahora que se actualizaron los offset de X,Y de mario
;; podemos llamar a la funcion que actualiza el sprite 
  JSR SUBDibujaMario
  
  ;;Ahora que se actualizo la posicion de mario en pantalla
  ;;Podemos terminar y volver al loop principal a esperar
  ;;otro refrezco de pantalla.
  JMP FIN
 
;Rutina de interrupcion (NMI)
;Esta rutina se dispara cuando la pantalla
;se dibujo por completo, y el barrido vertical 
;esta volviendo al inicio. Deberia poder utilizarse
;solo por 2250 ciclos aprox. Deberia dispararse 25 veces
;por segundo o 50 con interlaceado
nmi:
  ;;Guardamos en el stack el estado del CPU (flags y acumulador)
  PHA
  PHP
  ;;Incrementamos el flag NMI que deberia pasar de 0 a 1
  INC FlagNMI
  ;;Ahora recuperamos el estado del CPU (flags y acumulador) y listo
  PLP
  PLA
  RTI 
  

;;Aqui comienzan las subrutinas auxiliares
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUBBlinkPalette:

    LDA $2002     ; read PPU status to reset the high/low latch to high
	LDA #$3F
	STA $2006     ; write the high byte of $3F10 address
	LDA #$00
	STA $2006     ; write the low byte of $3F10 address
	LDA #$21
	STA $2007
	
  ;;Si la paleta es $16 pasar a $25, si es $25 pasar
	LDA PaletteBlink
	CMP #$01
	BMI Paleta1
	CMP #$02
	BMI Paleta2
	CMP #$04
	BMI Paleta3
	CMP #$07
	BMI Paleta4
	LDA #00
	STA PaletteBlink

Paleta1:
	LDA #$05
	STA $2007
	JMP finBlinkPalette
	
Paleta2:
	LDA #$16
	STA $2007
	JMP finBlinkPalette

Paleta3:
	LDA #$27
	STA $2007
	JMP finBlinkPalette

Paleta4:
	LDA #$37
	STA $2007
  
finBlinkPalette:
   INC PaletteBlink
   RTS
  

;;Esta subrutina actualiza el byte de la paleta que define el fondo
;;para poder cambiar el color del cielo cuando mario se come el hongo.  
SUBChangeSky:
  LDA $2002       ;Se resetea el puerto del PPU para poder escribirlo
  LDA #$3F
  STA $2006       ;Cargamos la parte alta de la direccion $3F00
  LDA #$00
  STA $2006       ;Cargamos la parte baja de la direccion $3F00

  LDA LSDSky      ;Cargamos en el acumulador el valor para el cielo
  STA $2007       ;Forzamos el valor en el PPU apuntando a $3F00
				  ;; Este valor comienza la paleta, y la primer posicion
				  ;; indica el color del background.
  RTS
  
;;Esta rutina actualiza los tiles hasta el tile de score que cambia
;;constantemente, por ende lo tenemos que actualizar.  
SUBActualizaScore:
  LDA $2002             ; Hay que leer el PPU para resetear la direccion
  LDA #$20
  STA $2006             ; Se carga la parte alta de $2000
  LDA #$00
  STA $2006             ; Se carga la parte baja de $2000
  LDX #$00              ; 
  
  
  ;;El SCORE se muestra en las posiciones $65 y $66 asi que cargamos
  ;;el mapa hasta esas posiciones y luego cargamos a mano el score
LoadBackgroundLoopScore:
  LDA NewWorld, x     
  STA $2007      
  INX 
  CPX #$65  ;;Mientras no cargue $65 que siga
  BNE LoadBackgroundLoopScore 
   ;;Ahora que cargo los primeros $65 tiles, viene el score
  LDA Puntos1
  STA $2007
  LDA Puntos0
  STA $2007
  ;;Listo
  RTS

;;Grabamos la cancion LSD (Lucy in the Sky with Diamonds) 
LSD:
    .byte NE4, 12, NA4, 12, NE5, 12, NG4, 12, NE5, 12, NA4, 12, NF4b, 12,NA4, 12, NE5, 12, NF4, 10, ND5, 8, NC5b,8, NA4, 8  ,$FF

;;Esta subrutina reproduce nota a nota la cancion LSD
SUBPlayLSD:
    PHA
    ;;Primero vemos si la cancion esta activa
    LDA LSDPlaying
    BEQ finPlayLSD ;;No esta sonando
    ;;Si esta sonando, tenemos que verificar que el tiempo de nota
    ;;no haya llegando a cero
    LDA LSDNoteTime
    ;;Si no es cero, entonces lo dejamos
    BNE decNota
    ;;Si el tiempo de nota es cero, avanzamos a la siguiente nota
    LDA #%10111111 ;;Configuramos el Pulse1 para que toque constante
	STA $4000	   ;;a maximo volumen
	
    ;;Buscamos la nota que hay que tocar
    LDX LSDNote ;; Esta variable apunta a LSD
    LDA LSD,x ;; Carga el elemento X del vector LSD
    CMP #$FF ;;Si es el ultimo apago la musica
    BEQ apagaLSD
    ;;Si no es la ultima nota, la buscamos en NOTAS
    TAX ;;El indice para buscar en el vector notas esta en A, lo 
		;;pasamos a X para usarlo en modo indexado
    LDA NOTAS,x ;Ahora buscamos NOTAS[x] siendo X el LSDNote
    STA $4002
    ;;Las primeras 8 notas requieren un 1 en $4003, pero el resto no
    LDA #0 ;;Cargamos un 0 originalmente y le sumamos 1 si hace falta
    CPX #8
    BPL altaCero ;;Si  la nota es mayor a 8, dejamos el 0
    LDA #1 ;;Sino ponemos un 1
altaCero:
	STA $4003 ;;Guardamos la parte alta que puede ser 0 o 1.
    ;;Cargamos ahora el tiempo que debe durar la nota
    INC LSDNote
    LDX LSDNote
    LDA LSD,x
    STA LSDNoteTime
    ;;Apuntamos a la siguiente nota
    INC LSDNote
    ;;Cambiamos el color del cielo
    INC LSDSky
    JSR SUBChangeSky
    ;;Restauramos A y volvemos
    PLA
    RTS
;; Si el tiempo nota no llego a 0, decrementamos el tiempo y salimos    
decNota:
	DEC LSDNoteTime
	PLA
	RTS
;; Si tenemos que apagar la musica, ponemos 0 en PULSE1 en PPU
apagaLSD:
	LDA #0
	STA $4000
	STA $4002
	STA $4003
	;;Reseteamos el tiempo de nota a 0 y apuntamos el vector de nota
	;;a la primer nota y apagamos la musica.
	STA LSDNoteTime
	STA LSDNote
	STA LSDPlaying
	;;Restauramos el cielo al color normal.
	LDA #$21
	STA LSDSky
	JSR SUBChangeSky
    ;;Se termino
finPlayLSD:
    PLA
	RTS
	
  
;;Esta subrutina incrementa el score en 1. Pero como se muestra en dos
;;digitos entonces hay que incrementar el primero y luego el segundo
;;dependiendo del valor del primer digito
SUBIncrementarScore:
    INC Puntos0
    LDA Puntos0
    CMP #10
    BEQ overPuntos0
    RTS
overPuntos0:
	LDA #0
	STA Puntos0
	INC Puntos1
	LDA Puntos1
	CMP #10
	BEQ overPuntos1
	RTS
overPuntos1:
	LDA #0
	STA Puntos1
    STA Puntos0
    RTS
  
  
SUBVerificarCostado:
	;;Esta subrutina verifica si mario se puede mover hacia un costado
	;;Dependiendo si se apreto derecha o izquierda
	;;Si el acumulador tiene 0, verifica derecha
	;;Si el acumulador tiene 1 , verifica izquierda
	BEQ verificaDerecha
	;;Limpiamos TileCount para contar colisiones
	LDA #$00
	STA TileCount
	;;Para verificar a la izquierda, tenemos que ver si hay un tile
	;;en MarioOffsetX-1 con ambos MarioOffsetY y MarioOffsetY
	LDA MarioOffsetX
	CLC
	SBC #1
	STA FindTileX
	LDA MarioOffsetY
	STA FindTileY
	JMP detectarColision
	
verificaDerecha:
    LDA #$00
    STA TileCount
    LDA MarioOffsetX
    CLC
    ADC #17
    STA FindTileX
    LDA MarioOffsetY
    STA FindTileY
    
detectarColision:
    ;;Ahora FindTileX y FindTileY tienen el primer punto a comparar
    JSR SUBFindTile
    ;;Si dio mayor a $3F entonces hay colision
    CMP #$3F
    BMI noHayColisionUno
    INC TileCount
noHayColisionUno:
    CLC
    LDA FindTileY
    ADC #16
    STA FindTileY
    JSR SUBFindTile
    CMP #$3F
    BMI noHayColisionDos
    INC TileCount
noHayColisionDos:
	LDA TileCount
	;; si TileCount es 0 entonces no hay colision
	;; Si es mayor a 0 entonces hay colision
	;; Devolvemos esto
	RTS

;;Rutina para leer el registro del Joystick tomada de
;; https://wiki.nesdev.com/w/index.php/Controller_reading_code
SUBReadJoy:
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta JOYPAD1
    sta JoystickPress
    lsr a        ; now A is 0
    ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
    sta JOYPAD1
loop:
    lda JOYPAD1
    lsr a	       ; bit 0 -> Carry
    rol JoystickPress  ; Carry -> bit 0; bit 7 -> Carry
    bcc loop
    rts	


 ;;Esta subrutina busca un TILE en un mapa (NewWorld) usando 
 ;;coordenadas X e Y apuntadas por FindTileX, FindTileY y usa un indice 
 ;;de 2 bytes para recorrer el mapa (NameTablePointer)
 ;;Codigo tomado de:
 ;; http://forums.nesdev.com/viewtopic.php?t=19551
SUBFindTile:
  clc
  ;;Dado que buscamos en una matriz de 32x30 donde cada elemento tiene
  ;; 8x8 pixeles, tenemos que dividir por 8 y multiplicar por 32
  ;; pero esto es lo mismo que multiplicar por 4, asi que tomamos
  ;; los 5 bits mas significativos de la posicion Y
  lda FindTileY
  and #%11111000
  
  ;;Y shifteamos a la izquierda dos veces para multiplicar por 4
  asl
  rol NameTablePointer+1
  asl
  rol NameTablePointer+1
  ;;Y esos valores los guardamos en la parte alta de NameTablePointer
  clc
  adc #<NewWorld ;;Cargamos la parte baja del mapa
  sta NameTablePointer+0
  lda NameTablePointer+1 
  and #%00000011
  adc #>NewWorld
  sta NameTablePointer+1 ;;Ahora la parte alta del mapa
  
  ;;Ahora ya avanzamos en el vector de 32x30 tantas filas como tiles
  ;;en Y hacian falta, asi que tenemos que dividir la posicion X
  ;;en 8 y usar eso como indice
  clc
  lda FindTileX
  SBC #1
  lsr
  lsr
  lsr
  tay

  ;Ahora NameTablePointer tiene NewWorld avanzando en Y, necesitamos
  ;resolver X que ya esta dividido por 8 en el registro Y. Asi que lo 
  ;usamos como indice apuntando indirecto indexado con NameTablePointer
  lda (NameTablePointer), y 
  ;;Listo, en el acumulador quedo el TILE apuntado por FindTileX e Y.
  RTS
  
  
;;Esta subrutina se fija si mario tiene algun lugar donde estar apoyado
;;caso contrario lo hace caer por gravedad  
SUBAplicarGravedad:
	;;Verifica si mario no tiene nada debajo de sus pies y debe caer
	;; SALVO que este subiendo
	LDA #$00
	STA TileCount
	LDA MarioEstadoSalto
	AND #%10000000
	BNE chauGravedad ;; Esta saltando
	;; Verificamos que no haya nada debajo en los dos extremos

	CLC
	LDA MarioOffsetY
	ADC #18
	STA FindTileY
	LDA MarioOffsetX
	STA FindTileX
	JSR SUBFindTile
	;;Ahora A tiene el tile a abajo
	CMP #$3F
	BPL nadaX
	INC TileCount
nadaX:
	CLC
	LDA MarioOffsetX
	ADC #16
	STA FindTileX
	JSR SUBFindTile
	CMP #$3F
	BPL finGravedad
	INC TileCount
	
finGravedad:
   LDA TileCount
   CMP #$02
   BNE chauGravedad
   INC MarioOffsetY
   INC MarioOffsetY
   LDA #%01000000
   STA MarioEstadoSalto ;;Mario esta cayendo
chauGravedad:   
   RTS
  
SUBActualizaEstadoMario:
	;; Esta subrutina actualiza el estado de mario segun su posicion
	;; o si esta saltando o cayendo.
	LDA #$00
	STA MarioEstadoSprite ;;Primero borramos el estado del sprite
	
	;;Verificamos a que lado apuntaba mario por ultima vez
	LDA MarioUltimoLado
	BNE miraIzquierda
miraDerecha:
	;;Vemos si esta saltando
	LDA MarioEstadoSalto
	BEQ estadoSegunPosicion
	;;Esta saltando a la derecha
	;; Puede que este cayendo
	AND #%01000000
	BNE cayendoGravedadDerecha
	LDA #$05 ;;Si no cae ni salta y esta quieto, entoces mira derecha
	STA MarioEstadoSprite
	RTS
cayendoGravedadDerecha:
    LDA #$03 ;;Si esta cayendo por gravedad, manitos juntas
    STA MarioEstadoSprite
    RTS 
miraIzquierda:
    LDA MarioEstadoSalto
    BEQ preEstadoSegunPosicion
    ;;Puede que este cayendo
    AND #%01000000
    BNE cayendoGravedadIzquierda
    LDA #$85 ;;Si no cae ni salta y esta quiero, entonces mira izquierda
    STA MarioEstadoSprite
    RTS
cayendoGravedadIzquierda:
	LDA #$83 ;; Si esta cayendo por gravedad, manitos juntas
	STA MarioEstadoSprite
	RTS

;;El estado de mario depende entonces de la posicion en donde esta
;;en pantalla  
preEstadoSegunPosicion:    
    LDA #$80
    STA MarioEstadoSprite ;; Sumo $80 de base ya que es izquierda

estadoSegunPosicion:
	;; Esta quieto mario?
	LDA JoystickPress
	;;enmascaro con LeftRight a ver si se mueve
	AND #%00000011
	BNE realPosicion ;;Efectivamente se esta apretando algun boton
				     ;;del joystick asi que vamos al estado basado
				     ;;en la posicion de la pantalla
	CLC
	LDA MarioEstadoSprite
	ADC #$04
	STA MarioEstadoSprite
	RTS
realPosicion:
	;;Tomo la posicion X
	CLC
	LDA MarioOffsetX
	AND #%00011000
	;;Dividimos por 8 y tomamos solo dos bits (4 estados posibles)
	LSR
	LSR
	LSR
	ADC MarioEstadoSprite
	STA MarioEstadoSprite
	;;Entonces guardamos el estado en funcion de la coordenada X.
   RTS
   
   
;;Esta rutina detecta si dos Sprites estan colisionando.
;;Codigo tomado de:
;;https://refreshgames.co.uk/2018/01/27/nes-asm-tips-box-collision/
;;Y adaptado a sprite fijo (hongo) y sprite movil (mario)
SUBDetectCollisions:
	PHA ; Guarda el acumulador en el stack
	LDA #$00
	STA SpriteChoca ;Inicializa SpriteChoca en 0 asumiendo que no choca
; Verifica primer caso
	CLC 
	LDA MarioOffsetX ;Toma coordenada de MarioX
	ADC #16 ; Dado que tiene 16 de ancho se lo suma
	CMP #HONGOX ; Compara con el comienzo del hongo
	BMI FinishCollisionCheckBetter ;Si es menor, no puede estar chocando
 
; Verifica segundo caso
	CLC 
	LDA #HONGOX ;Carga coordenada del hongo X
	ADC #16 ; Dado que el hongo es de 16 de ancho, los suma
	CMP MarioOffsetX ; Comparo contra el comienzo de mario en X
	BMI FinishCollisionCheckBetter ;Si es menor, no puede estar chocando
 
; Verifica tercer caso
	CLC 
	LDA MarioOffsetY ; Carga la posicion de MArioY
	ADC #16 ; dado que es de 16 de alto, se los suma
	CMP #HONGOY ; compara con la posicion Y del hongo
	BMI FinishCollisionCheckBetter ;Si es menor, no puede estar chocando
 
; Ultimo caso
	CLC 
	LDA #HONGOY ; Carga la posicion Y del hongo
	ADC #16 ; Dado que tiene 16 de alto se los suma
	CMP MarioOffsetY ; Compara con la posicion Y de mario
	BMI FinishCollisionCheckBetter ;Si es menor, no puede estar chocando
 
;SI llego hasta aca sin saltar, quiere decir que hay colision
	LDA #$01
	STA SpriteChoca 
 
FinishCollisionCheckBetter:
	PLA ; Restaura el valor de A del stack
 
	RTS


;;Esta rutina verifica que pasa con el hongo y si hay choque
;;usando la rutina de arriba como auxiliar   
SUBCheckColisionHongo:
	LDA HongoVisible
	BEQ finCheckColisionHongo
	;;Hay que comparar donde esta mario con los limites del hongo
	JSR SUBDetectCollisions
	LDA SpriteChoca
	BEQ finCheckColisionHongo ;;No esta chocando con el hongo
	;;Aca si esta chocando, asi que si el hongo esta visible
	;;lo ocultamos
	LDA #0
	STA HongoVisible
	;;Sumamos un puntito
	JSR SUBIncrementarScore
	;;Refrezcamos el hongo en pantalla (no se muestra mas)
	JSR SUBDisplayHongo
	;;Tocamos LSD
	LDA #1
	STA LSDPlaying
finCheckColisionHongo:
    RTS   

;;Esta rutina muestra el hongo en pantalla dependiendo de si 
;;la variable HongoVisible esta en 1 o 0.   
SUBDisplayHongo:
	LDA HongoVisible
	BNE dibujalo
	;;Si no esta visible, lo dibujamos fuera de pantalla
	LDA #$FF
	STA $0220
	STA $0224
    STA $0228
    STA $022C
	RTS
;;Si esta visible, entonces los dibujamos en coordenadas fijas
dibujalo:
  CLC
  LDA #76
  STA $0220
  clc
  LDA #64
  STA $0223
  LDA #$76
  STA $0221
  LDA #$01
  STA $0222
  
  ;Seguimos con UpperRight UR
  clc
  LDA #76
  STA $0224                     
  clc
  LDA #72
  STA $0227                     
  LDA #$77
  STA $0225                     
  LDA #$01
  STA $0226 
  
  ;Seguimos con LowerLeft LL
  clc
  LDA #84
  STA $0228                     
  clc
  LDA #64
  STA $022B                     
  LDA #$78
  STA $0229                     
  LDA #$01
  STA $022A  
  
  ;Ultimo con lowerRight LR
  clc
  LDA #84
  STA $022C                    
  clc
  LDA #72
  STA $022F                     
  LDA #$79
  STA $022D                    
  LDA #$01
  STA $022E   

  RTS
   

;;Esta rutina se fija si mario choca algo con la cabeza
;;En caso de ser un BOX ? , entonces muestra el hongo   
SUBCheckCabeza:
	;; Esta rutina se fija que no haya nada arriba de la cabeza a mario
	CLC
	LDA MarioOffsetY
	SBC #1
	STA FindTileY
	LDA #0
	STA TileCount
	LDA MarioOffsetX
	STA FindTileX
	JSR SUBFindTile
	;; Si hay un $55 o $56 hay un BOX
	;; Si arriba hay algo mayor a $3F sumo
	CMP #$3F
	BMI checkCabeza2
	INC TileCount
	CMP #$55
	BNE checkOtroQuestion
	INC HongoVisible
checkOtroQuestion:
    CMP #$56
    BNE checkCabeza2
    INC HongoVisible
checkCabeza2:
	CLC
	LDA FindTileX
	ADC #16
	STA FindTileX
	JSR SUBFindTile
	CMP #$3F
	BMI finCheckCabeza
    INC TileCount
	CMP #$55
	BNE checkOtroQuestion1
	INC HongoVisible
checkOtroQuestion1:
    CMP #$56
    BNE finCheckCabeza
    INC HongoVisible
finCheckCabeza:
    LDA TileCount
    RTS
 
;;Esta rutina se fija si mario esta saltando y procesa el salto.   
SUBCheckSalto:
    ;;No puede haber gravedad aun, ya que se resetea cada vez que se
    ;; dibuja  a mario
    ;; El BMS de MArioEstadoSalto indica si esta saltando o no
    LDA MarioEstadoSalto
    AND #%10000000
    BEQ finCheckSalto
    ;;Dado que MarioEstadoSalto tiene 10xxxxxx
    ;;podemos vemos si subimos o bajamos
    LDA MarioEstadoSalto
    CMP #%10010111
    BPL Bajando
    ;;Si estoy aca es porque esta subiendo con el salto
    INC MarioEstadoSalto
    ;;HAy que verificar que no haya nada en la cabeza de mario
    JSR SUBCheckCabeza
    ;;Si devolvio 0 es que se puede saltar
    BNE ChocoCabeza
    CLC
    LDA MarioOffsetY
    SBC #2
    STA MarioOffsetY
    JMP finCheckSalto
    
ChocoCabeza:
    ;;Como choco la cabeza paramos de subir
    LDA #%10011111
    STA MarioEstadoSalto
    
Bajando:
	;; SI esta bajando, tenemos que bajar hasta que choca con algo
	;; entonces copiamos la rutina que verifica por gravedad
	LDA #0
	STA TileCount
	CLC
	LDA MarioOffsetY
	ADC #18
	STA FindTileY
	LDA MarioOffsetX
	STA FindTileX
	JSR SUBFindTile
	;;Ahora A tiene el tile a abajo
	CMP #$3F
	BPL nadaXcayendo
	INC TileCount
nadaXcayendo:
	CLC
	LDA MarioOffsetX
	ADC #16
	STA FindTileX
	JSR SUBFindTile
	CMP #$3F
	BPL finCayendo
	INC TileCount
	
finCayendo:
   LDA TileCount
   CMP #$02
   BNE impactoSuelo
   INC MarioOffsetY
   INC MarioOffsetY
   RTS
    
impactoSuelo:
   ;;No cae mas
   LDA #$00
   STA MarioEstadoSalto

finCheckSalto:
    RTS   
  
  
;;Esta es la rutina principal que actualiza todos los Sprites.  
SUBDibujaMario:
	;; Primero reseteo el flag de cayendo por gravedad
	;; ya que  lo vamos a chequear siempre despues de ver si esta 
	;; saltando o no.
	LDA MarioEstadoSalto
	AND #%10111111
	STA MarioEstadoSalto
	;; Primero vemos si esta saltando
	JSR SUBCheckSalto
	;; Ahora que ya sabemos si salta o no, vemos si se cae por gravedad
	JSR SUBAplicarGravedad
	
	;;Dado que la posicion X, Y ya esta actualizada podemos actualizar
	;;como se dibuja mario en pantalla
	JSR SUBActualizaEstadoMario
	;;Vemos si choco con el hongo y lo mostramos
	JSR SUBCheckColisionHongo
	JSR SUBDisplayHongo
	
	;; Ahora que su estado esta actualizado podemos dibujarlo.
	;; Apuntamos a donde estan los sprites relativos al estado
	;; y buscamos los mismos con la variable de estado.
	LDA MarioEstadoSprite
	CMP #$70
	BPL parteIzquierda
    LDA #<dbEstadoMario00
    STA MarioEstadoSpritedb
    LDA #>dbEstadoMario00
    STA MarioEstadoSpritedb+1
    JMP sumarBajo
parteIzquierda:
    LDA #<dbEstadoMario80
    STA MarioEstadoSpritedb
    LDA #>dbEstadoMario80
    STA MarioEstadoSpritedb+1

sumarBajo:    
    LDA MarioEstadoSprite
    AND #$0F
    asl
    asl
    asl
    ADC MarioEstadoSpritedb
    STA MarioEstadoSpritedb
    BCC actualizaSprite
    INC MarioEstadoSpritedb+1
    
;; Ahora MarioEstadoSpritedb apunta a un vector que tiene
;; todos los valores para los sprites
;; Cada parte de mario (UL, UR, LL, LR) necesita un valor de sprite
;; y un atributo asi que cargamos los 8 valores    
actualizaSprite:
    LDY #0
    lda (MarioEstadoSpritedb), y
    STA $0211
    INY
    LDA (MarioEstadoSpritedb), y
    STA $0219
    INY
    LDA (MarioEstadoSpritedb), y
    STA $0215
    INY
    LDA (MarioEstadoSpritedb), y
    STA $021D
    INY
    LDA (MarioEstadoSpritedb), y
    STA $0212
    INY
    LDA (MarioEstadoSpritedb), y
    STA $021A
    INY
    LDA (MarioEstadoSpritedb), y
    STA $0216
    INY
    LDA (MarioEstadoSpritedb), y
    STA $021E
    ;;Ahora que ya se cargo como se dibuja mario le decimos en donde
    ;;Lo tiene que dibujar (cada parte)
    CLC
    LDA MarioOffsetY
    STA $0210
    STA $0218
    ADC #$08
    STA $0214
    STA $021C
    
    CLC
    LDA MarioOffsetX
    STA $0213
    STA $0217
    ADC #$08
    STA $021B
    STA $021F

	RTS

;;Tabla de estados de mario. Guarda primero el numero de sprite
;; y luego guarda el atributo correspondiente	
	
dbEstadoMario00: ;Moviendose Derecha etapa 0 (manos separadas)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $36,$37,$38,$39,$0,$0,$0,$0
dbEstadoMario01: ;Moviendose Derecha etapa 1 (manos juntas)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $3A,$37,$3B,$3C,$0,$0,$0,$0
dbEstadoMario02: ;Moviendose Derecha etapa 2 (mano adelante)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $32,$33,$34,$35,$0,$0,$0,$0
dbEstadoMario03: ;Moviendose Derecha etapa 3 (manos juntas)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $3A,$37,$3B,$3C,$0,$0,$0,$0
dbEstadoMario04: ;Mario quieto mirando a la derecha
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $32,$33,$4F,$4F,$0,$0,$0,$40
dbEstadoMario05: ;Salto positivo a la derecha
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $32,$41,$42,$43,$0,$0,$0,$0

dbEstadoMario80: ;Moviendose Derecha etapa 0 (manos separadas)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $37,$36,$39,$38,$40,$40,$40,$40
dbEstadoMario81: ;Moviendose Derecha etapa 1 (manos juntas)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $37,$3A,$3C,$3B,$40,$40,$40,$40
dbEstadoMario82: ;Moviendose Derecha etapa 2 (mano adelante)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $33,$32,$35,$34,$40,$40,$40,$40
dbEstadoMario83: ;Moviendose Derecha etapa 3 (manos juntas)
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $37,$3A,$3C,$3B,$40,$40,$40,$40
dbEstadoMario84: ;Mario quieto mirando a la derecha
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $33,$32,$4F,$4F,$40,$40,$0,$40
dbEstadoMario85: ;Salto positivo a la derecha
          ;UL, UR, LL, LR,UL,UR,LL, LR
	.byte $41,$32,$43,$42,$40,$40,$40,$40
	

  
;; Esta rutina dibuja el fondo (Background Tiles).
SUBDibujaFondo:
  LDA $2002             ; Hay que leer el PPU para resetear la posicion
  LDA #$20
  STA $2006             ; Se carga la parte alta de $2000
  LDA #$00
  STA $2006             ; Se carga la parte baja de $2000
  LDX #$00              
  ;;Una pantalla entera tiene 32x30 tiles, o sea 960 bytes.
  ;;Pero el registro X es de 8 bits, por ende tenemos que cargar 
  ;;de 256 bytes a la vez o usar modo indirecto indexado pero hay que
  ;;contar con 16 bits, asi que es mas facil cargarlo por partes.
   
  ;;Cargamos los primeros 256 bytes
LoadBackgroundLoop:
  LDA NewWorld, x     
  STA $2007              ;Grabamos el valor a PPU, que se autoincrementa
  INX                    ; incrementamos X para el loop.
  CPX #$65               ; en $65 corta para cargar el SCORE, sino sigue
  BNE LoadBackgroundLoop ; Mientras no haya recorrido los $65, que siga.
  
  ;;Cargamos los puntos en el medio de los primeros 256
  LDA Puntos1
  STA $2007
  LDA Puntos0
  STA $2007
  LDX #$67

LoadBackgroundLoopPos:
  LDA NewWorld, x     
  STA $2007             
  INX                   
  CPX #$00            
  BNE LoadBackgroundLoopPos ;Si no llego a 00, no termino aun.
                       
  ;;Todos los loops son mas o menos iguales 
  ;; pero con el offset avanzado en 256
                        
LoadBackgroundLoop256:
  LDA NewWorld+256, x     
  STA $2007             
  INX                   
  CPX #$00             
  BNE LoadBackgroundLoop256  
                        
LoadBackgroundLoop512:
  LDA NewWorld+512, x     
  STA $2007             
  INX                  
  CPX #$00             
  BNE LoadBackgroundLoop512 
  
  ;;Este ultimo loop tiene que ir desde 768 hasta 960 solamente

LoadBackgroundLoop192:
  LDA NewWorld+512+256, x    
  STA $2007            
  INX                   
  CPX #192             
  BNE LoadBackgroundLoop192 
                       
 ;;Este loop carga los registros de atributos que estan a continuacion de los tiles.
 ;;Comienza apuntando el PPU a la memoria de atributos correspondiente

LoadAttribute:
  LDA $2002             
  LDA #$23
  STA $2006             
  LDA #$C0
  STA $2006             
  LDX #$00           
  
  ;;Ahora barremos los atributos y los vamos pasando al PPU   
LoadAttributeLoop:
  LDA NewWorldAttribute, x      
  STA $2007            
  INX                  
  CPX #64            
  BNE LoadAttributeLoop
  
  ;;Todo listo, podemos volver
  RTS
  
;;Cargamos los tiempos para el timer que genera las notas musicales
;;con el Pulse1 del PPU  
NOTAS: 
	.byte %10101011 ;, %1
	.byte %10010011 ;, %1
	.byte %01111100 ;, %1
	.byte %01100111 ;, %1
	.byte %01010010 ;, %1
	.byte %00111111 ;, %1
	.byte %00101101 ;, %1
	.byte %00011100 ;, %1
	.byte %00001100 ;, %1
	.byte %11111101 ;, %0
	.byte %11101111 ;, %0
	.byte %11100001 ;, %0
	.byte %11010101 ;, %0
	.byte %11001001 ;, %0
	.byte %10111101 ;, %0
	.byte %10110011 ;, %0
	.byte %10101001 ;, %0
	.byte %10011111 ;, %0
	.byte %10010110 ;, %0
	.byte %10001110 ;, %0
	.byte %10000110 ;, %0
	.byte %01111110 ;, %0
	.byte %01110111 ;, %0
	.byte %01110000 ;, %0
	.byte $00  

;;Cargamos el mapa estatico original (NameTable) con atributos 
NewWorld:
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$36,$37,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$19,$1e,$17,$1d,$18,$1c,$24,$24,$24,$24,$24,$24,$24
	.byte $35,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$00,$00,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $39,$3a,$3b,$3c,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$b0,$b2,$b0,$b2,$b0,$b2,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$b1,$b3,$b1,$b3,$b1,$b3,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$45,$45,$45,$45,$45,$45,$45,$45,$24,$24,$24,$24
	.byte $24,$45,$45,$45,$45,$45,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$47,$47,$47,$47,$47,$47,$47,$47,$24,$24,$24,$24
	.byte $24,$47,$47,$47,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$31
	.byte $32,$24,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24,$24,$24
	.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$30,$34
	.byte $26,$33,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24,$24,$24
	.byte $24,$24,$36,$37,$24,$24,$24,$24,$24,$24,$24,$24,$24,$30,$26,$26
	.byte $26,$34,$33,$24,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24,$24,$24
	.byte $24,$35,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$30,$26,$34,$26
	.byte $26,$26,$26,$33,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24,$24,$24
	.byte $b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5
	.byte $b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5
	.byte $b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7
	.byte $b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7
NewWorldAttribute:
	.byte $54,$50,$50,$00,$55,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$05,$00
	.byte $00,$a0,$a0,$00,$a0,$20,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$00
	.byte $f0,$b0,$a0,$fc,$f3,$a0,$ff,$00,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a
;;Paleta de colores original
NewWorldPalette:
;	.byte $21,$27,$16,$0f,$21,$20,$21,$0f,$21,$20,$16,$0f,$21,$2a,$1a,$0f
    .byte $21,$27,$16,$0f,$21,$20,$21,$0f,$21,$37,$16,$0f,$21,$2a,$1a,$0f
    .byte $21,MEDIUM_RED,LIGHT_ORANGE,MEDIUM_YELLOW
    .byte  LIGHT_ORANGE,MEDIUM_RED,$20,LIGHT_ORANGE
    .byte  BLACK,MEDIUM_RED,MEDIUM_RED,LIGHT_CHARTREUSE
    .byte  BLACK,MEDIUM_RED,MEDIUM_RED,LIGHT_CHARTREUSE 




	


.segment "VECTORS" ; Direcciones para las ISR (rutinas de interrupcion)
.word nmi
.word reset
.word irq
