!IF VIC_CHARMAP {

!MACRO PLOT_CHAR .o {
  STA SCREEN_MEMORY+.o
}

!MACRO PLOT_CHAR_X .o {
  STA SCREEN_MEMORY+.o,X
}

!MACRO PLOT_CHAR_Y .o {
  STA SCREEN_MEMORY+$0190,Y
}

!MACRO COPY_CHAR .d, .s {
  LDA SCREEN_MEMORY+.s
  STA SCREEN_MEMORY+.d
}

!MACRO COPY_CHAR_X .d, .s {
  LDA SCREEN_MEMORY+.s,X
  STA SCREEN_MEMORY+.d,X
}

!MACRO COPY_CHAR_Y .d, .s {
  LDA SCREEN_MEMORY+.s,Y
  STA SCREEN_MEMORY+.d,Y
}

}

!IF VIC_BITMAP {

COPY_6:
  LDY #0

  +PHW $FD
  ASL $FD
  ROL $FE
  ASL $FD
  ROL $FE
  ASL $FD
  ROL $FE
  +ADDW $FD, ADDR_BITMAP
- LDA ($FB),Y
  STA ($FD),Y
  INY
  CPY #48
  BNE -
  +PLW $FD

  +PHW $FD
  +ADDW $FD, ADDR_COLOR12-48
- LDA ($FB),Y
  STA ($FD),Y
  INY
  CPY #48+6
  BNE -
  +PLW $FD

  +PHW $FD
  +ADDW $FD, ADDR_COLOR3-48-6
- LDA ($FB),Y
  STA ($FD),Y
  INY
  CPY #48+6+6
  BNE -
  +PLW $FD

  RTS

!MACRO COPY_6 .src, .off {
  +STIW $FB, .src
  +STIW $FD, .off
  JSR COPY_6
}

!MACRO BEGIN_IMAGE .src, .dst, .sz {
  LDA #<(.dst*8+ADDR_BITMAP)
  STA REC_02
  LDA #>(.dst*8+ADDR_BITMAP)
  STA REC_03
  LDA #<.src
  STA REC_04
  LDA #>.src
  STA REC_05
  LDA #^.src
  STA REC_06
  LDA #<(.sz*8)
  STA REC_07
  LDA #>(.sz*8)
  STA REC_08
  LDA #%10010001 ; fetch bytes
  STA REC_01
}

!MACRO NEXT_IMAGE .dst, .sz {
  LDA #<(.dst*8+ADDR_BITMAP)
  STA REC_02
  LDA #>(.dst*8+ADDR_BITMAP)
  STA REC_03
  LDA #<(.sz*8)
  STA REC_07
  LDA #>(.sz*8)
  STA REC_08
  LDA #%10010001 ; fetch bytes
  STA REC_01
}

!MACRO NEXT_COLOR .base, .dst, .sz {
  LDA #<(.dst+.base)
  STA REC_02
  LDA #>(.dst+.base)
  STA REC_03
  LDA #<.sz
  STA REC_07
  LDA #>.sz
  STA REC_08
  LDA #%10010001 ; fetch bytes
  STA REC_01
}

ERASE_6:
  LDA #0
  LDY #0
- STA ($FD),Y
  INY
  CPY #48
  BNE -
  RTS

!MACRO ERASE_6 .off {
  +STIW $FD, ADDR_BITMAP+.off*8
  JSR ERASE_6
}

; CHAR
; INDEX
; ORIGINAL_FC
; ORIGINAL_FB
; RETURN_ADDR_HI
; RETURN_ADDR_LO
; ORIGINAL_X
; ORIGINAL_Y
; ORIGINAL_FE
; ORIGINAL_FD
; SP (aka X)

MC_PLOT_CHAR_HELPER:
  +PHX
  +PHY
  +PHW $FD

  TSX         ; get stack pointer for args

  PHP
  SEI

  CLC         ; add index to offset
  LDA $FB
  ADC $0109,X
  STA $FB
  LDA $FC
  ADC #$00
  STA $FC

  ASL $FB     ; multiply offset by 8
  ROL $FC
  ASL $FB
  ROL $FC
  ASL $FB
  ROL $FC

  +ADDW $FB, ADDR_BITMAP

  LDA $010A,X
  STA $FD
  LDA #0
  STA $FE

  ASL $FD     ; multiply offset by 8
  ROL $FE
  ASL $FD
  ROL $FE
  ASL $FD
  ROL $FE

  +ADDW $FD, ($0100*>REU_ADDR_MCFONT)+(<REU_ADDR_MCFONT)

  ; use REU to copy the 8 bytes of the character to the bitmap
  LDA $FB        ; main memory address low byte
  STA REC_02
  LDA $FC        ; main memory address high byte
  STA REC_03
  LDA $FD        ; reu address low byte
  STA REC_04
  LDA $FE        ; reu address high byte
  STA REC_05
  LDA #1         ; reu address bank byte
  STA REC_06
  LDA #8         ; count of bytes to fetch
  STA REC_07
  LDA #0
  STA REC_08
  LDA #%10010001 ; fetch bytes
  STA REC_01

  PLP

  +PLW $FD
  +PLY
  +PLX

  RTS

!MACRO MC_PLOT_CHAR_HELPER {
  +PHW $FB
  JSR MC_PLOT_CHAR_HELPER
  +PLW $FB
}

!MACRO MC_PLOT_CHAR {
  PHA
  +PHI 0
  +MC_PLOT_CHAR_HELPER
  PLA
  PLA
}

!MACRO MC_PLOT_CHAR_X {
  PHA
  +PHX
  +MC_PLOT_CHAR_HELPER
  +PLX
  PLA
}

!MACRO MC_PLOT_CHAR_Y {
  PHA
  +PHY
  +MC_PLOT_CHAR_HELPER
  +PLY
  PLA
}

!MACRO MC_PLOT_CHAR_HELPER .o {
  +PHW $FB
  +STIW $FB, .o
  JSR MC_PLOT_CHAR_HELPER
  +PLW $FB
}

!MACRO MC_PLOT_CHAR .o {
  PHA
  +PHI 0
  +MC_PLOT_CHAR_HELPER .o
  PLA
  PLA
}

!MACRO MC_PLOT_CHAR_X .o {
  PHA
  +PHX
  +MC_PLOT_CHAR_HELPER .o
  +PLX
  PLA
}

!MACRO MC_PLOT_CHAR_Y .o {
  PHA
  +PHY
  +MC_PLOT_CHAR_HELPER .o
  +PLY
  PLA
}

; INDEX
; ORIGINAL_FC
; ORIGINAL_FB
; ORIGINAL_FE
; ORIGINAL_FD
; RETURN_ADDR_HI
; RETURN_ADDR_LO
; ORIGINAL_X
; ORIGINAL_Y
; SP (aka X)

COPY_CHAR_HELPER:
  +PHX
  +PHY

  TSX         ; get stack pointer for args

  CLC         ; add index to dest offset
  LDA $FB
  ADC $0109,X
  STA $FB
  LDA $FC
  ADC #$00
  STA $FC

  ASL $FB     ; multiply dest by 8
  ROL $FC
  ASL $FB
  ROL $FC
  ASL $FB
  ROL $FC

  CLC         ; add index to src offset
  LDA $FD
  ADC $0109,X
  STA $FD
  LDA $FE
  ADC #$00
  STA $FE

  ASL $FD     ; multiply src by 8
  ROL $FE
  ASL $FD
  ROL $FE
  ASL $FD
  ROL $FE

  +ADDW $FB, ADDR_BITMAP
  +ADDW $FD, ADDR_BITMAP

  SEI
  +STI R6510, 4

  LDY #0
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y
  INY
  LDA ($FD),Y
  STA ($FB),Y

  +STI R6510, 6
  CLI

  +PLY
  +PLX

  RTS

!MACRO COPY_CHAR_HELPER .d, .s {
  +PHW $FB
  +PHW $FD
  +STIW $FB, .d
  +STIW $FD, .s
  JSR COPY_CHAR_HELPER
  +PLW $FD
  +PLW $FB
}

!MACRO COPY_CHAR .d, .s {
  +PHI 0
  +COPY_CHAR_HELPER .d, .s
  PLA
}

!MACRO COPY_CHAR_X .d, .s {
  +PHX
  +COPY_CHAR_HELPER .d, .s
  +PLX
}

!MACRO COPY_CHAR_Y .d, .s {
  +PHY
  +COPY_CHAR_HELPER .d, .s
  +PLY
}

}

!MACRO MC_PLOT_CHAR .o, .c {
  LDA #.c
  +MC_PLOT_CHAR .o
}

!MACRO MC_PLOT_CHAR_X .o, .c {
  LDA #.c
  +MC_PLOT_CHAR_X .o
}

!MACRO MC_PLOT_CHAR_Y .o, .c {
  LDA #.c
  +MC_PLOT_CHAR_Y .o
}

;DECOMPRESS_MCBM_REP:
;            EOR #$FF ; A = 1+-A
;            CLC
;            ADC #$02
;
;            STA $FF
;
;            INY
;-           LDA ($FB),Y
;
;            LDY #0
;-           STA ($FD),Y
;            INY
;            CPY $FF
;            BNE -
;
;            +ADDW $FB, 2
;
;            LDA $FF
;            +ADDW $FD
;
;            JMP DECOMPRESS_MCBM_PART
;
;DECOMPRESS_MCBM_LIT:
;            STA $FF
;
;            +ADDW $FB, 1
;
;            LDY #0
;-           LDA ($FB),Y
;            STA ($FD),Y
;            INY
;            CPY $FF
;            BNE -
;
;            LDA $FF
;            +ADDW $FB
;
;            LDA $FF
;            +ADDW $FD
;
;            JMP DECOMPRESS_MCBM_PART
;
;DECOMPRESS_MCBM_PART:
;            LDY #0
;            LDA ($FB),Y
;            BEQ +
;            BMI DECOMPRESS_MCBM_REP
;            JMP DECOMPRESS_MCBM_LIT
;
;+           +ADDW $FB, 1
;            RTS
;
;DECOMPRESS_MCBM:
;            +STIW $FD, ADDR_BITMAP
;            JSR DECOMPRESS_MCBM_PART
;            +STIW $FD, ADDR_COLOR12
;            JSR DECOMPRESS_MCBM_PART
;            +STIW $FD, ADDR_COLOR3
;            JSR DECOMPRESS_MCBM_PART
;            RTS

DISPLAY_GAME_SCREEN:
!IF VIC_BITMAP {
            +STI SCROLX, %00011000 ; enable multicolor mode
            +FETCHI ADDR_BITMAP,  REU_ADDR_MCBACKGROUND+$0000, 8192
            +FETCHI ADDR_COLOR12, REU_ADDR_MCBACKGROUND+$2000, 1024
            +FETCHI ADDR_COLOR3,  REU_ADDR_MCBACKGROUND+$2400, 1024
}
!IF VIC_CHARMAP {
            +DECOMPRESS_SCREEN SCR_TEXT, SCREEN_MEMORY
            +DECOMPRESS_SCREEN SCR_COLOR, COLOR_MEMORY
}
            RTS

FETCH_GAME_SCREEN:
            JSR DISPLAY_GAME_SCREEN
            JSR DISPLAY_PLAYER_SPRITE
            JSR DISPLAY_PLAYER_HEALTH
            JSR DISPLAY_KEYS
            JSR DISPLAY_WEAPON
            JSR DISPLAY_ITEM
            RTS

STASH_GAME_SCREEN:
            LDA #0
            STA SPENA
            RTS

DISPLAY_ENDGAME_SCREEN:
            LDA #%00000000  ;disable ALL sprites
            STA SPENA
!IF VIC_BITMAP {
            +STI SCROLX, %00011000 ; enable multicolor mode
            +FETCHI ADDR_BITMAP,  REU_ADDR_MCENDGAME+$0000, 8192
            +FETCHI ADDR_COLOR12, REU_ADDR_MCENDGAME+$2000, 1024
            +FETCHI ADDR_COLOR3,  REU_ADDR_MCENDGAME+$2400, 1024
}
!IF VIC_CHARMAP {
            JSR CS02  ;set monochrome screen for now.
            +DECOMPRESS_SCREEN SCR_ENDGAME, SCREEN_MEMORY
}
            ;display map name
            JSR CALC_MAP_NAME
DEG3:       LDA ($FB),Y
            +MC_PLOT_CHAR_Y $12F
            INY
            CPY #16
            BNE DEG3
            ;display elapsed time
            +DECWRITE $17E, HOURS
            +DECWRITE $181, MINUTES
            +DECWRITE $184, SECONDS
            LDA #32 ;SPACE
            +MC_PLOT_CHAR $17E
            LDA #58 ;COLON
            +MC_PLOT_CHAR $181
            +MC_PLOT_CHAR $184
            ;count robots remaining
            LDX #1
            LDA #0
            STA DECNUM
DEG7:       LDA UNIT_TYPE,X
            CMP #0
            BEQ DEG8
            INC DECNUM
DEG8:       INX
            CPX #28
            BNE DEG7
            +DECWRITE $1CF
            ;Count secrets remaining
            LDA #0
            STA DECNUM
            LDX #48
DEG9:       LDA UNIT_TYPE,X
            CMP #0
            BEQ DEG10
            INC DECNUM
DEG10:      INX
            CPX #64
            BNE DEG9
            +DECWRITE $21F
            ;display difficulty level
            LDY DIFF_LEVEL
            LDA DIFF_LEVEL_LEN,Y
            TAY
            LDX #0
DEG11:      LDA DIFF_LEVEL_WORDS,Y
            CMP #0
            BEQ DEG12
            +MC_PLOT_CHAR_X $26F
            INY
            INX
            JMP DEG11
DEG12:      RTS

DIFF_LEVEL_WORDS:
            !SCR "easy",0,"normal",0,"hard",0
DIFF_LEVEL_LEN:
            !BYTE 0,5,12

!IF VIC_CHARMAP+1 {
DECOMPRESS_BYTE:
            JMP $FFFF

DECOMPRESS_SCREEN_BYTE:
            PHA
            +PHI 0
            +PHW $FB
            LDA $FD
            STA $FB
            LDA $FE
            SEC
            SBC #>SCREEN_MEMORY
            STA $FC
            JSR MC_PLOT_CHAR_HELPER
            +PLW $FB
            PLA
            PLA
            RTS

DECOMPRESS_COLOR_BYTE:
            STA ($FD),Y
            PHA
            +ADDW $FD, $0800
            PLA
            STA ($FD),Y
            PHA
            +SUBW $FD, $0800
            PLA
            RTS

DECOMPRESS_SCREEN:
            LDY #00
DGS1:       LDA ($FB),Y
            CMP #96 ;REPEAT FLAG
            BEQ DGS10
DGS2:       JSR DECOMPRESS_BYTE
            ;CHECK TO SEE IF WE REACHED $83E7 YET.
DGS4:       LDA $FE
DGS5:       CMP #$83  ;SELF MODIFYING CODE
            BNE DGS3
            LDA $FD
DGS6:       CMP #$E7  ;SELF MODIFYING CODE
            BNE DGS3
            RTS
DGS3:       JSR INC_SOURCE
            JSR INC_DEST
            JMP DGS1
DGS10:      ;REPEAT CODE
            JSR INC_SOURCE
            LDA ($FB),Y
            STA RPT
            JSR INC_SOURCE
            LDA ($FB),Y
            TAX
DGS11:      LDA RPT
            JSR DECOMPRESS_BYTE
            JSR INC_DEST
            DEX
            CPX #$FF
            BNE DGS11
            LDA $FD
            SEC
            SBC #01
            STA $FD
            LDA $FE
            SBC #00
            STA $FE
            JMP DGS4
INC_SOURCE:
            LDA $FB
            CLC
            ADC #01
            STA $FB
            LDA $FC
            ADC #00
            STA $FC
            RTS
INC_DEST:
            LDA $FD
            CLC
            ADC #01
            STA $FD
            LDA $FE
            ADC #00
            STA $FE
            RTS
RPT !BYTE 00  ;repeat value
}

!IF VIC_CHARMAP {

;This routine plots a 3x3 tile from the tile database anywhere
;on screen.  But first you must define the tile number in the
;TILE variable, as well as the starting screen address must
;be defined in $FB.
PLOT_TILE:
            LDA $FB ;Grab the starting address, and adjust it for
            STA $FD ;the color RAM before we get started.
            LDA $FC
            STA $FE
            LDX TILE
            ;DRAW THE TOP 3 CHARACTERS
            LDA TILE_DATA_TL,X
            LDY #0
            STA ($FB),Y
            LDA TILE_DATA_TM,X
            INY
            STA ($FB),Y
            LDA TILE_DATA_TR,X
            INY
            STA ($FB),Y
            ;MOVE DOWN TO NEXT LINE
            LDY #40
            ;DRAW THE MIDDLE 3 CHARACTERS
            LDA TILE_DATA_ML,X
            STA ($FB),Y
            LDA TILE_DATA_MM,X
            INY
            STA ($FB),Y
            LDA TILE_DATA_MR,X
            INY
            STA ($FB),Y
            ;MOVE DOWN TO NEXT LINE
            LDY #80
            ;DRAW THE BOTTOM 3 CHARACTERS
            LDA TILE_DATA_BL,X
            STA ($FB),Y
            LDA TILE_DATA_BM,X
            INY
            STA ($FB),Y
            LDA TILE_DATA_BR,X
            INY
            STA ($FB),Y
            ;NOW DO THE COLOR
PT01:       LDA $FE
            SEC
            SBC #$08  ;adjust to color RAM area by SUBTRACTING $0800
            STA $FE
            ;DRAW THE TOP 3 COLORS
            LDA TILE_COLOR_TL,X
            LDY #0
            STA ($FD),Y
            LDA TILE_COLOR_TM,X
            INY
            STA ($FD),Y
            LDA TILE_COLOR_TR,X
            INY
            STA ($FD),Y
            ;MOVE DOWN TO NEXT LINE
            LDY #40
            ;DRAW THE MIDDLE 3 COLORS
            LDA TILE_COLOR_ML,X
            STA ($FD),Y
            LDA TILE_COLOR_MM,X
            INY
            STA ($FD),Y
            LDA TILE_COLOR_MR,X
            INY
            STA ($FD),Y
            ;MOVE DOWN TO NEXT LINE
            LDY #80
            ;DRAW THE BOTTOM 3 COLORS
            LDA TILE_COLOR_BL,X
            STA ($FD),Y
            LDA TILE_COLOR_BM,X
            INY
            STA ($FD),Y
            LDA TILE_COLOR_BR,X
            INY
            STA ($FD),Y
            RTS

;This routine plots a transparent tile from the tile database
;anywhere on screen.  But first you must define the tile number
;in the TILE variable, as well as the starting screen address must
;be defined in $FB.  Also, this routine is slower than the usual
;tile routine, so is only used for sprites.  The ":" character ($3A)
;is not drawn.
PLOT_TRANSPARENT_TILE:
            LDA $FB ;Grab the starting address, and adjust it for
            STA $FD ;the color RAM before we get started.
            LDA $FC
            STA $FE
            LDX TILE
            ;DRAW THE TOP 3 CHARACTERS
            LDA TILE_DATA_TL,X
            LDY #0
            CMP #$3A
            BEQ PTT01
            STA ($FB),Y
PTT01:      LDA TILE_DATA_TM,X
            INY
            CMP #$3A
            BEQ PTT02
            STA ($FB),Y
PTT02:      LDA TILE_DATA_TR,X
            INY
            CMP #$3A
            BEQ PTT03
            STA ($FB),Y
            ;MOVE DOWN TO NEXT LINE
PTT03:      LDY #40
            ;DRAW THE MIDDLE 3 CHARACTERS
            LDA TILE_DATA_ML,X
            CMP #$3A
            BEQ PTT04
            STA ($FB),Y
PTT04:      LDA TILE_DATA_MM,X
            INY
            CMP #$3A
            BEQ PTT05
            STA ($FB),Y
PTT05:      LDA TILE_DATA_MR,X
            INY
            CMP #$3A
            BEQ PTT06
            STA ($FB),Y
            ;MOVE DOWN TO NEXT LINE
PTT06:      LDY #80
            ;DRAW THE BOTTOM 3 CHARACTERS
            LDA TILE_DATA_BL,X
            CMP #$3A
            BEQ PTT07
            STA ($FB),Y
PTT07:      LDA TILE_DATA_BM,X
            INY
            CMP #$3A
            BEQ PTT08
            STA ($FB),Y
PTT08:      LDA TILE_DATA_BR,X
            INY
            CMP #$3A
            BEQ PTT09
            STA ($FB),Y
PTT09:      ;NOW DO THE COLOR
            LDA $FE
            SEC
            SBC #$08  ;adjust to color RAM area by SUBTRACTING $0800
            STA $FE
            ;DRAW THE TOP 3 COLORS
            LDA TILE_COLOR_TL,X
            LDY #0
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT10
            STA ($FD),Y
PTT10:      LDA TILE_COLOR_TM,X
            INY
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT11
            STA ($FD),Y
PTT11:      LDA TILE_COLOR_TR,X
            INY
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT12
            STA ($FD),Y
            ;MOVE DOWN TO NEXT LINE
PTT12:      LDY #40
            ;DRAW THE MIDDLE 3 COLORS
            LDA TILE_COLOR_ML,X
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT13
            STA ($FD),Y
PTT13:      LDA TILE_COLOR_MM,X
            INY
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT14
            STA ($FD),Y
PTT14:      LDA TILE_COLOR_MR,X
            INY
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT15
            STA ($FD),Y
            ;MOVE DOWN TO NEXT LINE
PTT15:      LDY #80
            ;DRAW THE BOTTOM 3 COLORS
            LDA TILE_COLOR_BL,X
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT16
            STA ($FD),Y
PTT16:      LDA TILE_COLOR_BM,X
            INY
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT17
            STA ($FD),Y
PTT17:      LDA TILE_COLOR_BR,X
            INY
            CMP #$00  ;If it is black, don't draw it.
            BEQ PTT18
            STA ($FD),Y
PTT18:      RTS

}

!IF VIC_BITMAP {

;!SOURCE "mctiles.sym"

; This routine plots a 72-byte tile to the VIC-II screen. To use it,
; you must first define TEMP_X and TEMP_Y with the location onscreen
; where the tile will be drawn.  Then you must define TILE as to which
; of the 256 tiles will be plotted.

PLOT_TILE_DEST !WORD 0

!MACRO ADDWI .addr, .value {
            LDA .addr+0
            CLC
            ADC #<.value
            STA .addr+0
            LDA .addr+1
            ADC #>.value
            STA .addr+1
}

!MACRO SUBWI .addr, .value {
            LDA .addr+0
            SEC
            SBC #<.value
            STA .addr+0
            LDA .addr+1
            SBC #>.value
            STA .addr+1
}

LAST_TILE:  !FILL 256, 1
REMAP_TILE: !FILL 256, 0

INIT_LAST_TILE:
            LDA #1
            LDY #0

-           STA LAST_TILE,Y  ; init the last tile to be 1
            INY              ; all tiles should be some other number
            BNE -            ; so this will ensure tiles drawn first time

-           TYA              ; init the remap tiles to identity
            STA REMAP_TILE,Y ; when animations need to be updated
            INY              ; they'll be updated here
            BNE -

            RTS

PLOT_TILE:
            +PH TILE

            PHA
            +PHY
            LDY TILE
            LDA REMAP_TILE,Y
            STA TILE
            +PLY
            PLA

            LDA TEMP_Y
            ASL
            ASL
            ASL
            ASL
            ORA TEMP_X
            TAY
            LDA LAST_TILE,Y
            CMP #$94 ; need to animate trash compactor
            BEQ +
            CMP #20 ; need to animate cinema
            BEQ +
            CMP #21 ; need to animate cinema
            BEQ +
            CMP #22 ; need to animate cinema
            BEQ +
            CMP TILE
            BNE +
            +PL TILE
            RTS

+           PHP
            SEI

            LDA TILE
            STA LAST_TILE,Y

            LDY TEMP_Y
            LDA BITMAP_ADDRESS_L,Y
            STA PLOT_TILE_DEST+0
            LDA BITMAP_ADDRESS_H,Y
            STA PLOT_TILE_DEST+1

            LDY TEMP_X
-           BEQ +
            +ADDWI PLOT_TILE_DEST, 24
            DEY
            JMP -

            ; use REU to copy the 72 bytes of the tile to the bitmap

+           LDA PLOT_TILE_DEST+0 ; main memory address low byte
            STA REC_02
            LDA PLOT_TILE_DEST+1 ; main memory address high byte
            STA REC_03
            LDY TILE
            LDA mcbm_tile_lo,Y   ; reu address low byte
            STA REC_04
            LDA mcbm_tile_hi,Y   ; reu address high byte
            STA REC_05
            LDA #1               ; reu address bank byte
            STA REC_06
            LDA #24              ; count of bytes to fetch
            STA REC_07
            LDA #0
            STA REC_08
            LDA #%10010001       ; fetch bytes
            STA REC_01

            +ADDWI PLOT_TILE_DEST, 320 ; next row of tile
            LDA PLOT_TILE_DEST+0 ; main memory address low byte
            STA REC_02
            LDA PLOT_TILE_DEST+1 ; main memory address high byte
            STA REC_03
                                 ; already at next src row
            LDA #24              ; count of bytes to fetch
            STA REC_07
            LDA #0
            STA REC_08
            LDA #%10010001       ; fetch bytes
            STA REC_01

            +ADDWI PLOT_TILE_DEST, 320 ; next row of tile
            LDA PLOT_TILE_DEST+0 ; main memory address low byte
            STA REC_02
            LDA PLOT_TILE_DEST+1 ; main memory address high byte
            STA REC_03
                                 ; already at next src row
            LDA #24              ; count of bytes to fetch
            STA REC_07
            LDA #0
            STA REC_08
            LDA #%10010001       ; fetch bytes
            STA REC_01

            +SUBWI PLOT_TILE_DEST, 320*2   ; just to be nice to caller, restore original address

            +PHW $FB

            LDX TILE

            LDY TEMP_X
            LDA SCREEN_COL,Y
            STA $FB
            +STI $FC, 0

            LDY TEMP_Y
            CLC
            LDA $FB
            ADC SCREEN_ROW_L,Y
            STA $FB
            LDA $FC
            ADC SCREEN_ROW_H,Y
            STA $FC

!MACRO TILE_COLORS .delta {
            +ADDWI $FB, .delta

            LDA $FB              ; main memory address low byte
            STA REC_02
            LDA $FC              ; main memory address high byte
            STA REC_03
                                 ; reu location already initialized from earlier
            LDA #3               ; count of bytes to fetch
            STA REC_07
            LDA #0
            STA REC_08
            LDA #%10010001       ; fetch bytes
            STA REC_01

            +ADDWI $FB, 40 ; next row of tile
            LDA $FB              ; main memory address low byte
            STA REC_02
            LDA $FC              ; main memory address high byte
            STA REC_03
                                 ; reu location already initialized from earlier
            LDA #3               ; count of bytes to fetch
            STA REC_07
            LDA #0
            STA REC_08
            LDA #%10010001       ; fetch bytes
            STA REC_01

            +ADDWI $FB, 40 ; next row of tile
            LDA $FB              ; main memory address low byte
            STA REC_02
            LDA $FC              ; main memory address high byte
            STA REC_03
                                 ; reu location already initialized from earlier
            LDA #3               ; count of bytes to fetch
            STA REC_07
            LDA #0
            STA REC_08
            LDA #%10010001       ; fetch bytes
            STA REC_01

            +SUBWI $FB, 40*2 ; restore original destination
}

            ; ($FB) has the offset of the top left corner of a tile's color
            ; memory location, so add $CC00 to get into screen memory and then
            ; add $0800 more to get to $0C00 for color memory
            +TILE_COLORS ADDR_COLOR12
            +TILE_COLORS ADDR_COLOR3-ADDR_COLOR12

            +PLW $FB

            PLP

            +PL TILE

            RTS                               ; done, return!

;This routine plots a transparent tile from the tile database
;anywhere on screen.  But first you must define the tile number
;in the TILE variable, as well as the starting screen address must
;be defined in $FB.  Also, this routine is slower than the usual
;tile routine, so is only used for sprites.  The ":" character ($3A)
;is not drawn.
PLOT_TRANSPARENT_TILE:
            JSR PLOT_TILE
            RTS

SCREEN_ROW_L:
  !BYTE <(40*3*0) ;ROW 0
  !BYTE <(40*3*1) ;ROW 1
  !BYTE <(40*3*2) ;ROW 2
  !BYTE <(40*3*3) ;ROW 3
  !BYTE <(40*3*4) ;ROW 4
  !BYTE <(40*3*5) ;ROW 5
  !BYTE <(40*3*6) ;ROW 6
  !BYTE <(40*3*7) ;ROW 7

SCREEN_ROW_H:
  !BYTE >(40*3*0) ;ROW 0
  !BYTE >(40*3*1) ;ROW 1
  !BYTE >(40*3*2) ;ROW 2
  !BYTE >(40*3*3) ;ROW 3
  !BYTE >(40*3*4) ;ROW 4
  !BYTE >(40*3*5) ;ROW 5
  !BYTE >(40*3*6) ;ROW 6
  !BYTE >(40*3*7) ;ROW 7

SCREEN_COL:
  !BYTE <(3* 0) ;COL  0
  !BYTE <(3* 1) ;COL  1
  !BYTE <(3* 2) ;COL  2
  !BYTE <(3* 3) ;COL  3
  !BYTE <(3* 4) ;COL  4
  !BYTE <(3* 5) ;COL  5
  !BYTE <(3* 6) ;COL  6
  !BYTE <(3* 7) ;COL  7
  !BYTE <(3* 8) ;COL  8
  !BYTE <(3* 9) ;COL  9
  !BYTE <(3*10) ;COL 10
  !BYTE <(3*11) ;COL 11

BITMAP_ADDRESS_L:
  !BYTE $00 ;ROW 0
  !BYTE $C0 ;ROW 1
  !BYTE $80 ;ROW 2
  !BYTE $40 ;ROW 3
  !BYTE $00 ;ROW 4
  !BYTE $C0 ;ROW 5
  !BYTE $80 ;ROW 6
  !BYTE $40 ;ROW 7

BITMAP_ADDRESS_H:
  !BYTE $E0 ;ROW 0
  !BYTE $E3 ;ROW 1
  !BYTE $E7 ;ROW 2
  !BYTE $EB ;ROW 3
  !BYTE $EF ;ROW 4
  !BYTE $F2 ;ROW 5
  !BYTE $F6 ;ROW 6
  !BYTE $FA ;ROW 7

B = REU_ADDR_MCTILES

mcbm_tile_lo
            !BYTE <($00*90+B),<($01*90+B),<($02*90+B),<($03*90+B)
            !BYTE <($04*90+B),<($05*90+B),<($06*90+B),<($07*90+B)
            !BYTE <($08*90+B),<($09*90+B),<($0A*90+B),<($0B*90+B)
            !BYTE <($0C*90+B),<($0D*90+B),<($0E*90+B),<($0F*90+B)
            !BYTE <($10*90+B),<($11*90+B),<($12*90+B),<($13*90+B)
            !BYTE <($14*90+B),<($15*90+B),<($16*90+B),<($17*90+B)
            !BYTE <($18*90+B),<($19*90+B),<($1A*90+B),<($1B*90+B)
            !BYTE <($1C*90+B),<($1D*90+B),<($1E*90+B),<($1F*90+B)
            !BYTE <($20*90+B),<($21*90+B),<($22*90+B),<($23*90+B)
            !BYTE <($24*90+B),<($25*90+B),<($26*90+B),<($27*90+B)
            !BYTE <($28*90+B),<($29*90+B),<($2A*90+B),<($2B*90+B)
            !BYTE <($2C*90+B),<($2D*90+B),<($2E*90+B),<($2F*90+B)
            !BYTE <($30*90+B),<($31*90+B),<($32*90+B),<($33*90+B)
            !BYTE <($34*90+B),<($35*90+B),<($36*90+B),<($37*90+B)
            !BYTE <($38*90+B),<($39*90+B),<($3A*90+B),<($3B*90+B)
            !BYTE <($3C*90+B),<($3D*90+B),<($3E*90+B),<($3F*90+B)
            !BYTE <($40*90+B),<($41*90+B),<($42*90+B),<($43*90+B)
            !BYTE <($44*90+B),<($45*90+B),<($46*90+B),<($47*90+B)
            !BYTE <($48*90+B),<($49*90+B),<($4A*90+B),<($4B*90+B)
            !BYTE <($4C*90+B),<($4D*90+B),<($4E*90+B),<($4F*90+B)
            !BYTE <($50*90+B),<($51*90+B),<($52*90+B),<($53*90+B)
            !BYTE <($54*90+B),<($55*90+B),<($56*90+B),<($57*90+B)
            !BYTE <($58*90+B),<($59*90+B),<($5A*90+B),<($5B*90+B)
            !BYTE <($5C*90+B),<($5D*90+B),<($5E*90+B),<($5F*90+B)
            !BYTE <($60*90+B),<($61*90+B),<($62*90+B),<($63*90+B)
            !BYTE <($64*90+B),<($65*90+B),<($66*90+B),<($67*90+B)
            !BYTE <($68*90+B),<($69*90+B),<($6A*90+B),<($6B*90+B)
            !BYTE <($6C*90+B),<($6D*90+B),<($6E*90+B),<($6F*90+B)
            !BYTE <($70*90+B),<($71*90+B),<($72*90+B),<($73*90+B)
            !BYTE <($74*90+B),<($75*90+B),<($76*90+B),<($77*90+B)
            !BYTE <($78*90+B),<($79*90+B),<($7A*90+B),<($7B*90+B)
            !BYTE <($7C*90+B),<($7D*90+B),<($7E*90+B),<($7F*90+B)
            !BYTE <($80*90+B),<($81*90+B),<($82*90+B),<($83*90+B)
            !BYTE <($84*90+B),<($85*90+B),<($86*90+B),<($87*90+B)
            !BYTE <($88*90+B),<($89*90+B),<($8A*90+B),<($8B*90+B)
            !BYTE <($8C*90+B),<($8D*90+B),<($8E*90+B),<($8F*90+B)
            !BYTE <($90*90+B),<($91*90+B),<($92*90+B),<($93*90+B)
            !BYTE <($94*90+B),<($95*90+B),<($96*90+B),<($97*90+B)
            !BYTE <($98*90+B),<($99*90+B),<($9A*90+B),<($9B*90+B)
            !BYTE <($9C*90+B),<($9D*90+B),<($9E*90+B),<($9F*90+B)
            !BYTE <($A0*90+B),<($A1*90+B),<($A2*90+B),<($A3*90+B)
            !BYTE <($A4*90+B),<($A5*90+B),<($A6*90+B),<($A7*90+B)
            !BYTE <($A8*90+B),<($A9*90+B),<($AA*90+B),<($AB*90+B)
            !BYTE <($AC*90+B),<($AD*90+B),<($AE*90+B),<($AF*90+B)
            !BYTE <($B0*90+B),<($B1*90+B),<($B2*90+B),<($B3*90+B)
            !BYTE <($B4*90+B),<($B5*90+B),<($B6*90+B),<($B7*90+B)
            !BYTE <($B8*90+B),<($B9*90+B),<($BA*90+B),<($BB*90+B)
            !BYTE <($BC*90+B),<($BD*90+B),<($BE*90+B),<($BF*90+B)
            !BYTE <($C0*90+B),<($C1*90+B),<($C2*90+B),<($C3*90+B)
            !BYTE <($C4*90+B),<($C5*90+B),<($C6*90+B),<($C7*90+B)
            !BYTE <($C8*90+B),<($C9*90+B),<($CA*90+B),<($CB*90+B)
            !BYTE <($CC*90+B),<($CD*90+B),<($CE*90+B),<($CF*90+B)
            !BYTE <($D0*90+B),<($D1*90+B),<($D2*90+B),<($D3*90+B)
            !BYTE <($D4*90+B),<($D5*90+B),<($D6*90+B),<($D7*90+B)
            !BYTE <($D8*90+B),<($D9*90+B),<($DA*90+B),<($DB*90+B)
            !BYTE <($DC*90+B),<($DD*90+B),<($DE*90+B),<($DF*90+B)
            !BYTE <($E0*90+B),<($E1*90+B),<($E2*90+B),<($E3*90+B)
            !BYTE <($E4*90+B),<($E5*90+B),<($E6*90+B),<($E7*90+B)
            !BYTE <($E8*90+B),<($E9*90+B),<($EA*90+B),<($EB*90+B)
            !BYTE <($EC*90+B),<($ED*90+B),<($EE*90+B),<($EF*90+B)
            !BYTE <($F0*90+B),<($F1*90+B),<($F2*90+B),<($F3*90+B)
            !BYTE <($F4*90+B),<($F5*90+B),<($F6*90+B),<($F7*90+B)
            !BYTE <($F8*90+B),<($F9*90+B),<($FA*90+B),<($FB*90+B)
            !BYTE <($FC*90+B),<($FD*90+B),<($FE*90+B),<($FF*90+B)
mcbm_tile_hi
            !BYTE >($00*90+B),>($01*90+B),>($02*90+B),>($03*90+B)
            !BYTE >($04*90+B),>($05*90+B),>($06*90+B),>($07*90+B)
            !BYTE >($08*90+B),>($09*90+B),>($0A*90+B),>($0B*90+B)
            !BYTE >($0C*90+B),>($0D*90+B),>($0E*90+B),>($0F*90+B)
            !BYTE >($10*90+B),>($11*90+B),>($12*90+B),>($13*90+B)
            !BYTE >($14*90+B),>($15*90+B),>($16*90+B),>($17*90+B)
            !BYTE >($18*90+B),>($19*90+B),>($1A*90+B),>($1B*90+B)
            !BYTE >($1C*90+B),>($1D*90+B),>($1E*90+B),>($1F*90+B)
            !BYTE >($20*90+B),>($21*90+B),>($22*90+B),>($23*90+B)
            !BYTE >($24*90+B),>($25*90+B),>($26*90+B),>($27*90+B)
            !BYTE >($28*90+B),>($29*90+B),>($2A*90+B),>($2B*90+B)
            !BYTE >($2C*90+B),>($2D*90+B),>($2E*90+B),>($2F*90+B)
            !BYTE >($30*90+B),>($31*90+B),>($32*90+B),>($33*90+B)
            !BYTE >($34*90+B),>($35*90+B),>($36*90+B),>($37*90+B)
            !BYTE >($38*90+B),>($39*90+B),>($3A*90+B),>($3B*90+B)
            !BYTE >($3C*90+B),>($3D*90+B),>($3E*90+B),>($3F*90+B)
            !BYTE >($40*90+B),>($41*90+B),>($42*90+B),>($43*90+B)
            !BYTE >($44*90+B),>($45*90+B),>($46*90+B),>($47*90+B)
            !BYTE >($48*90+B),>($49*90+B),>($4A*90+B),>($4B*90+B)
            !BYTE >($4C*90+B),>($4D*90+B),>($4E*90+B),>($4F*90+B)
            !BYTE >($50*90+B),>($51*90+B),>($52*90+B),>($53*90+B)
            !BYTE >($54*90+B),>($55*90+B),>($56*90+B),>($57*90+B)
            !BYTE >($58*90+B),>($59*90+B),>($5A*90+B),>($5B*90+B)
            !BYTE >($5C*90+B),>($5D*90+B),>($5E*90+B),>($5F*90+B)
            !BYTE >($60*90+B),>($61*90+B),>($62*90+B),>($63*90+B)
            !BYTE >($64*90+B),>($65*90+B),>($66*90+B),>($67*90+B)
            !BYTE >($68*90+B),>($69*90+B),>($6A*90+B),>($6B*90+B)
            !BYTE >($6C*90+B),>($6D*90+B),>($6E*90+B),>($6F*90+B)
            !BYTE >($70*90+B),>($71*90+B),>($72*90+B),>($73*90+B)
            !BYTE >($74*90+B),>($75*90+B),>($76*90+B),>($77*90+B)
            !BYTE >($78*90+B),>($79*90+B),>($7A*90+B),>($7B*90+B)
            !BYTE >($7C*90+B),>($7D*90+B),>($7E*90+B),>($7F*90+B)
            !BYTE >($80*90+B),>($81*90+B),>($82*90+B),>($83*90+B)
            !BYTE >($84*90+B),>($85*90+B),>($86*90+B),>($87*90+B)
            !BYTE >($88*90+B),>($89*90+B),>($8A*90+B),>($8B*90+B)
            !BYTE >($8C*90+B),>($8D*90+B),>($8E*90+B),>($8F*90+B)
            !BYTE >($90*90+B),>($91*90+B),>($92*90+B),>($93*90+B)
            !BYTE >($94*90+B),>($95*90+B),>($96*90+B),>($97*90+B)
            !BYTE >($98*90+B),>($99*90+B),>($9A*90+B),>($9B*90+B)
            !BYTE >($9C*90+B),>($9D*90+B),>($9E*90+B),>($9F*90+B)
            !BYTE >($A0*90+B),>($A1*90+B),>($A2*90+B),>($A3*90+B)
            !BYTE >($A4*90+B),>($A5*90+B),>($A6*90+B),>($A7*90+B)
            !BYTE >($A8*90+B),>($A9*90+B),>($AA*90+B),>($AB*90+B)
            !BYTE >($AC*90+B),>($AD*90+B),>($AE*90+B),>($AF*90+B)
            !BYTE >($B0*90+B),>($B1*90+B),>($B2*90+B),>($B3*90+B)
            !BYTE >($B4*90+B),>($B5*90+B),>($B6*90+B),>($B7*90+B)
            !BYTE >($B8*90+B),>($B9*90+B),>($BA*90+B),>($BB*90+B)
            !BYTE >($BC*90+B),>($BD*90+B),>($BE*90+B),>($BF*90+B)
            !BYTE >($C0*90+B),>($C1*90+B),>($C2*90+B),>($C3*90+B)
            !BYTE >($C4*90+B),>($C5*90+B),>($C6*90+B),>($C7*90+B)
            !BYTE >($C8*90+B),>($C9*90+B),>($CA*90+B),>($CB*90+B)
            !BYTE >($CC*90+B),>($CD*90+B),>($CE*90+B),>($CF*90+B)
            !BYTE >($D0*90+B),>($D1*90+B),>($D2*90+B),>($D3*90+B)
            !BYTE >($D4*90+B),>($D5*90+B),>($D6*90+B),>($D7*90+B)
            !BYTE >($D8*90+B),>($D9*90+B),>($DA*90+B),>($DB*90+B)
            !BYTE >($DC*90+B),>($DD*90+B),>($DE*90+B),>($DF*90+B)
            !BYTE >($E0*90+B),>($E1*90+B),>($E2*90+B),>($E3*90+B)
            !BYTE >($E4*90+B),>($E5*90+B),>($E6*90+B),>($E7*90+B)
            !BYTE >($E8*90+B),>($E9*90+B),>($EA*90+B),>($EB*90+B)
            !BYTE >($EC*90+B),>($ED*90+B),>($EE*90+B),>($EF*90+B)
            !BYTE >($F0*90+B),>($F1*90+B),>($F2*90+B),>($F3*90+B)
            !BYTE >($F4*90+B),>($F5*90+B),>($F6*90+B),>($F7*90+B)
            !BYTE >($F8*90+B),>($F9*90+B),>($FA*90+B),>($FB*90+B)
            !BYTE >($FC*90+B),>($FD*90+B),>($FE*90+B),>($FF*90+B)
}

