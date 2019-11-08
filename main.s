.linecont       +               ; Permitir continuar lineas
.feature        c_comments      /* Soportar comentarios tipo C */


;Definir el segmento HEADER para que FCEUX reconozca el archivo .nes como
;una imagen valida de un cartucho de NES

.segment "HEADER"

; Configurar con Mapper NROM 0 con bancos fijos
  .byte 'N', 'E', 'S', $1A    ; Firma de NES para el emulador
  .byte $02                   ; PRG tiene 16k 
  .byte $01                   ; CHR tiene 8k (usar mario.chr)
  .byte %00000000             ;NROM Mapper 0
  .byte $0, $0, $0, $0, $0, $0
; Fin del header 



;Incluir el binario con las imagenes de la rom de caracteres
.segment "IMG"
.incbin "mario.chr"

;Declaracion de variables en la pagina 0
.segment "ZEROPAGE"
    OffsetMarioX: .res 1
    OffsetMarioY: .res 1


;Comienza el codigo
.segment "CODE"

;Rutina de interrupcion (IRQ)
;No es utilizada por ahora
irq:
	rti
	

;Rutina de interrupcion (NMI)
;Esta rutina se dispara cuando el la pantalla
;se dibujo por completo, y el barrido vertical 
;esta volviendo al inicio. Deberia poder utilizarse
;solo por 2250 ciclos aprox. Deberia dispararse 25 veces
;por segundo o 50 con interlaceado
nmi:
  
  ;Dado que en $0200~$02ff tenemos cargados los sprites
  ;Utilizamos el DMA para transferir estos 256 bytes a memoria
  ;de video en la ubicacion de los sprites.
  LDA #$00
  STA $2003                     ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014                     ; set the high byte (02) of the RAM address, start the transfer
  ;Esto deberia bloquear el procesador hasta que termina.
  
  
;Aprovechamos este tiempo para leer el joystick.
;El codigo esta tomado de http://www.vbforums.com/showthread.php?858965-NES-6502-Programming-Tutorial-Part-5-Controller-Commands
;Se deja con comentario originales en ingles
LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons

ReadA: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadADone   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)

ReadADone:        ; handling this button is done
  
ReadB: 
  LDA $4016       ; player 1 - B
  AND #%00000001  ; only look at bit 0
  BEQ ReadBDone   ; branch to ReadBDone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)

ReadBDone:        ; handling this button is done

ReadSelect: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadSelectDone   ; branch to ReadADone if button is NOT pressed (0)

ReadSelectDone:

ReadStart: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadStartDone   ; branch to ReadADone if button is NOT pressed (0)

ReadStartDone:

ReadUp: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadUpDone   ; branch to ReadADone if button is NOT pressed (0)

  LDA OffsetMarioY
  SBC #01
  STA OffsetMarioY
ReadUpDone:

ReadDown: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadDownDone   ; branch to ReadADone if button is NOT pressed (0)
  
  ;;Dado que hay que bajar, movemos a Mario para abajo hasta que llegamos 
  ;;Al limite de ladrillos inferior
  LDA OffsetMarioY
  CMP #$CF
  BPL ReadDownDone
  ADC #01
  STA OffsetMarioY

ReadDownDone:

ReadLeft: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BNE DoLeft
  JMP ReadLeftDone   ; branch to ReadADone if button is NOT pressed (0)

;Move Mario to the left 
DoLeft:
  LDA OffsetMarioX
  SBC #01
  STA OffsetMarioX  
  
ReadLeftDone:

ReadRight: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BNE DoRight
  JMP ReadRightDone ; branch to ReadADone if button is NOT pressed (0)

;Move Mario to the right  
DoRight:
  LDA OffsetMarioX
  ADC #01
  STA OffsetMarioX
  
ReadRightDone:
  

;;;;
;; Ahora que se actualizaron los offset de X,Y de mario
;; podemos llamar a la funcion que actualiza el sprite 
  JSR MoverAMario

;;Finalizamos la atencion a NMI
  RTI
;; Tenemos que estar seguros que todo el tiempo de proceso es menor a 2250 ciclos.

 
;;Rutina de interrupcion (Reset)
;;; Esta rutina se dispara cuando el nintendo se enciende o se aprieta el boton de reset
;;; 
reset:
  SEI          ; desactivar IRQs
  CLD          ; desactivar modo decimal
  
  ;;Durante el encendido del Nintendo hay que respetar unos tiempos hasta que el PPU
  ;;se encuentra listo para ser utilizado.
  ;;A continuacion se siguen los pasos sugeridos en: https://wiki.nesdev.com/w/index.php/Init_code
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


 ;; Cargamos las paletas de color tanto como para el fondo como para los sprites
 ;; Codigo tomado de https://gist.github.com/camsaul/0bd13b94574d936ce9a7
 ;; y adaptado para usar con CC65 
 
LoadPalettes:
  LDA $2002                     ; read PPU status to reset the high/low latch to high
  LDA #$3F
  STA $2006                     ; write the high byte of $3F10 address
  LDA #$00
  STA $2006                     ; write the low byte of $3F10 address

  ;; Load the palette data
  LDX #$00
LoadPalettesLoop:
  LDA PaletteData, x            ; load data from address (PaletteData + value in x)
  STA $2007                     ; write to PPU
  INX                           ; (inc X)
  CPX #$20                      ; Compare X to $20 (decimal 32)
  BNE LoadPalettesLoop          ; (when (not= x 32) (recur))

 
  ;; Ahora que las paletas estan cargadas, podemos dibujar el fondo
  JSR DIBUJAFONDO

  ;; Encendemos el PPU y el barrido vertical y apuntamos el PPU a la tabla 0 de sprites y 1 para fondos
  
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
  
  ;;Habilitamos las interrupciones
  CLI
  
  ;;Le damos un offset inicial a mario en Y
  LDA  #$D0
  STA  OffsetMarioY

  ;;Aqui termina la runtina de reset.. el codigo va a quedar ciclando
  ;;en la siguiente posicion. En este tiempo no se puede refrezcar datos en pantalla
  ;;ya que solo se puede hacer cuando se realiza el barrido vertical, PERO...
  ;;es un buen momento para hacer todo el resto de las cosas que hay que hacer en un juego
FIN:
  JMP FIN
  
  
  ;;Rutina que dibuja a Mario en la pantalla. Mario esta compuesto de 4 sprites
  ;;Que tienen que dibujarse pegados uno al otro en una matriz de 2x2. El siguiente
  ;;Codigo dibuja los 4 sprites y les suma el offset de la posicion grabado en la variables
  ;;offsetMarioX y OffsetMarioY.  
MoverAMario:

  ;Dibuja el primer Sprite
  LDA #$00
  ADC OffsetMarioY
  STA $0210                     ; Graba posicion Y
  LDA #$00
  ADC OffsetMarioX
  STA $0213                     ; Graba Posicion X
  LDA #$32
  STA $0211                     ; Puntero a dibujo en la ROM de caracteres
  LDA #0
  STA $0212                     ; Datos de paleta y rotacion
  
  ;;El resto de los sprites tienen la misma estructura
  LDA #$00
  ADC OffsetMarioY
  STA $0214                     
  LDA #$08
  ADC OffsetMarioX
  STA $0217                     
  LDA #$33
  STA $0215                    
  LDA #0
  STA $0216                    
  
  LDA #$08
  ADC OffsetMarioY
  STA $0218                     
  LDA #$00
  ADC OffsetMarioX
  STA $021B                     
  LDA #$42
  STA $0219                     
  LDA #0
  STA $021A                     
  
  LDA #$08
  ADC OffsetMarioY
  STA $021C                    
  LDA #$08
  ADC OffsetMarioX
  STA $021F                     
  LDA #$43
  STA $021D                    
  LDA #0
  STA $021E                     
  
  RTS
  
  
  ;; Esta rutina dibuja el fondo.
DIBUJAFONDO:

LoadBackground:
  LDA $2002             ; Hay que leer el PPU para resetear el latch de nibble
  LDA #$20
  STA $2006             ; Se carga la parte alta de $2000
  LDA #$00
  STA $2006             ; Se carga la parte baja de $2000
  LDX #$00              ; start out at 0
  
  ;;Una pantalla entera tiene 32x30 tiles, o sea 960 bytes.
  ;;Pero el registro X es de 8 bits, por ende tenemos que cargar de 256 bytes a la vez
  
  ;;Cargamos los primeros 256 bytes
LoadBackgroundLoop:
  LDA nametable, x     
  STA $2007             ; Grabamos el valor a PPU, que se autoincrementa
  INX                   ; incrementamos X para el loop.
  CPX #$00             ;  Nos fijamos si X volvio a 0, siendo que recorrio 256 valores
  BNE LoadBackgroundLoop  ; Mientras no haya recorrido los 256, que siga.
                       
  ;;Todos los loops son mas o menos iguales pero con el offset avanzado en 256
                        
LoadBackgroundLoop256:
  LDA nametable+256, x     
  STA $2007             
  INX                   
  CPX #$00             
  BNE LoadBackgroundLoop256  
                        
LoadBackgroundLoop512:
  LDA nametable+512, x     
  STA $2007             
  INX                  
  CPX #$00             
  BNE LoadBackgroundLoop512 
  
  ;;Este ultimo loop tiene que ir desde 768 hasta 960 solamente

LoadBackgroundLoop192:
  LDA nametable+512+256, x    
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
  LDA attribute, x      
  STA $2007            
  INX                  
  CPX #64            
  BNE LoadAttributeLoop
  
  ;;Todo listo, podemos volver
  RTS
  
  
;; Hacemos definiciones MACROS para que los colores sean mas faciles de utilizar
 ; these are the palette hex values and the colors they represent
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
  
  
 PaletteData:
  .byte LIGHT_INDIGO,LIGHT_CHARTREUSE,MEDIUM_GREEN,BLACK
  .byte LIGHT_INDIGO,LIGHTEST_RED,MEDIUM_ORANGE,BLACK
  .byte LIGHT_INDIGO,LIGHTEST_GRAY,LIGHT_BLUE,BLACK
  .byte LIGHT_INDIGO,LIGHT_ORANGE,MEDIUM_ORANGE,BLACK
  
  .byte LIGHT_INDIGO,MEDIUM_RED,LIGHT_ORANGE,MEDIUM_YELLOW
  .byte  BLACK,MEDIUM_RED,LIGHTEST_CHARTREUSE,$00
  .byte  BLACK,MEDIUM_RED,MEDIUM_RED,LIGHT_CHARTREUSE
  .byte  BLACK,MEDIUM_RED,MEDIUM_RED,LIGHT_CHARTREUSE  
  
nametable:
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
 
 attribute:
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111

	


.segment "VECTORS" ; Direcciones para las rutinas de atencion a interrupcion
.word nmi
.word reset
.word irq


