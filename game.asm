;PETSCII ROBOTS (C64 REU version)
;by David Murray 2020
;dfwgreencars@gmail.com
;by Scott Robison 2022
;scott@casaderobison.com

!TO         "game-64x", CBM
!SYMBOLLIST "game.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_GAME = ADDR_MAIN
SIZE_GAME = SIZE_MAIN

* = ADDR_GAME

!IF VIC_CHARMAP {
  POS_WEAPON_QTY = $0ED
  POS_ITEM_QTY   = $205
  POS_CUSTOM_KEY = $151

  SP_WEAPON_X    = 256+40
  SP_WEAPON_Y    =     64

  SP_ITEM_X      = 256+40
  SP_ITEM_Y      =    120

  SP_PLAYER_X    =    144
  SP_PLAYER_Y    =    122
}

!IF VIC_BITMAP {
  POS_WEAPON_QTY = $00ED-40
  POS_ITEM_QTY   = $0205-80
  POS_CUSTOM_KEY = $0151

  SP_WEAPON_X    = 256+40
  SP_WEAPON_Y    =     64-6

  SP_ITEM_X      = 256+40
  SP_ITEM_Y      =    120-16

  SP_PLAYER_X    =    144
  SP_PLAYER_Y    =    122
}

!MACRO DECWRITE .pos {
  +STIW $FB, .pos
  JSR DECWRITE
}

!MACRO DECWRITE .pos, .num {
  LDA .num
  STA DECNUM
  +STIW $FB, .pos
  JSR DECWRITE
}

!SOURCE "vic.asm"
;!SOURCE "vdc.asm"

START_GAME  ;JSR INIT_VDC
            JSR SET_CONTROLS  ;copy initial key controls
            JMP INTRO_SCREEN

INIT_GAME
!IF VIC_BITMAP {
            +STI SCROLX, %00011000 ; enable multicolor mode
}
            +STI SCREEN_SHAKE, 0
            JSR INIT_LAST_TILE
            JSR SETUP_SPRITE
            JSR RESET_KEYS_AMMO
            JSR DISPLAY_GAME_SCREEN

-           JSR DISPLAY_LOAD_MESSAGE2
            +STI CIA1_0D, %00000010
            JSR MAP_LOAD_ROUTINE
            BCC +

            JSR DISPLAY_MAP_DISK_MESSAGE
            JMP -

+           +STI CIA1_0D, %10000010
            ;JSR VDC_MAP_RENDER
            JSR SET_DIFF_LEVEL
            JSR ANIMATE_PLAYER
            JSR CALCULATE_AND_REDRAW
            JSR DRAW_MAP_WINDOW
            +STI PLAYER_DIRECTION, 6
            JSR DISPLAY_PLAYER_SPRITE
            JSR DISPLAY_PLAYER_HEALTH
            JSR DISPLAY_KEYS
            JSR DISPLAY_WEAPON
            +STI USER_MUSIC_ON, 1
            +STI SIGVOL, 15 ; volume
            JSR START_LEVEL_MUSIC
            +STI UNIT_TYPE, 1
            JSR SET_INITIAL_TIMERS
            JSR PRINT_INTRO_MESSAGE
            +STI KEYTIMER, 30
            JMP MAIN_GAME_LOOP

KEYS            !BYTE 00  ;bit0=spade bit2=heart bit3=star
AMMO_PISTOL     !BYTE 00  ;how much ammo for the pistol
AMMO_PLASMA     !BYTE 00  ;how many shots of the plasmagun
INV_BOMBS       !BYTE 00  ;How many bombs do we have
INV_EMP         !BYTE 00  ;How many EMPs do we have
INV_MEDKIT      !BYTE 00  ;How many medkits do we have?
INV_MAGNET      !BYTE 00  ;How many magnets do we have?
SELECTED_WEAPON !BYTE 00  ;0=none 1=pistol 2=plasmagun
SELECTED_ITEM   !BYTE 00  ;0=none 1=bomb 2=emp 3=medkit
ANIMATE         !BYTE 01  ;0=DISABLED 1=ENABLED
BIG_EXP_ACT     !BYTE 00  ;0=No explosion active 1=big explosion active
MAGNET_ACT      !BYTE 00  ;0=no magnet active 1=magnet active
PLASMA_ACT      !BYTE 00  ;0=No plasma fire active 1=plasma fire active
RANDOM          !BYTE 00  ;used for random number generation
INTRO_MESSAGE   !SCR"welcome to c64x-robots!",255
                !SCR"by david murray"
                !SCR 255, "and scott robison"
                !SCR" 2022",0
MSG_CANTMOVE    !SCR"can't move that!",0
MSG_BLOCKED     !SCR"blocked!",0
MSG_SEARCHING   !SCR"searching",0
MSG_NOTFOUND    !SCR"nothing found here.",0
MSG_FOUNDKEY    !SCR"you found a key card!",0
MSG_FOUNDGUN    !SCR"you found a pistol!",0
MSG_FOUNDEMP    !SCR"you found an emp device!",0
MSG_FOUNDBOMB   !SCR"you found a timebomb!",0
MSG_FOUNDPLAS   !SCR"you found a plasma gun!",0
MSG_FOUNDMED    !SCR"you found a medkit!",0
MSG_FOUNDMAG    !SCR"you found a magnet!",0
MSG_MUCHBET     !SCR"ahhh, much better!",0
MSG_EMPUSED     !SCR"emp activated!",255
                !SCR"nearby robots are rebooting.",0
MSG_TERMINATED  !SCR"you're terminated!",0
MSG_TRANS1      !SCR"transporter will not activate",255
                !SCR"until all robots destroyed.",0
MSG_ELEVATOR    !SCR"[ elevator panel ]  down",255
                !SCR"[  select level  ]  opens",0
MSG_LEVELS      !SCR"[                ]  door",0
MSG_PAUSED      !SCR"game paused.",255
                !SCR"exit game (y/n)",0
MSG_MUSICON     !SCR"music on.",0
MSG_MUSICOFF    !SCR"music off.",0
MSG_MAPCOLORON  !SCR"map color on.",0
MSG_MAPCOLOROFF !SCR"map color off.",0
MSG_MAPBOTSON   !SCR"map robots enabled.",0
MSG_MAPBOTSOFF  !SCR"map robots disabled.",0


;This is the routine that runs every 60 seconds from the IRQ.
;BGTIMER1 is always set to 1 every cycle, after which the main
;program will reset it to 0 when it is done with it's work for
;that cycle.  BGTIMER2 is a count-down to zero and then stays
;there.
RUNIRQ      LDA MUSIC_STATE       ; is MUSIC_STATE 0?
            BEQ IRQ0              ; if yes, skip next instruction
            JSR MUSIC_PLAY        ; otherwise run music play routine
IRQ0        JSR UPDATE_GAME_CLOCK
            JSR ANIMATE_WATER
            +STI BGTIMER1, 1
            LDA BGTIMER2          ; is BGTIMER2 0?
            BEQ IRQ1              ; if yes, skip next instruction
            DEC BGTIMER2          ; otherwise decrement BGTIMER2
IRQ1        LDA KEYTIMER          ; is KEYTIMER 0?
            BEQ IRQ2              ; if yes, skip next instruction
            DEC KEYTIMER          ; otherwise decrement KEYTIMER
IRQ2        ;BORDER FLASHER
            LDX BORDER            ; if BORDER 0?
            BEQ IRQ3              ; if yes, skip next block
            LDA BORDER,X
            STA EXTCOL
            DEC BORDER
IRQ3        ;BACKGROUND FLASHER
            LDX BGFLASH           ; is BGFLASH 0?
            BEQ IRQ10             ; if yes, skip next block
            LDA BGFLASH,X
            STA BGCOL0
            DEC BGFLASH
IRQ10       ;SCREEN_SHAKER
            LDA SCREEN_SHAKE      ; is SCREEN_SHAKE 0?
            BEQ SHAKE4            ; if yes, skip shaking
SHAKE2      INC SSCOUNT
            LDA SSCOUNT
            CMP #5
            BNE SHAKE3
            LDA #0
            STA SSCOUNT
SHAKE3      LDY SSCOUNT
            LDA SCROLX
            AND #%11111000
            ORA SSHAKE,Y
            STA SCROLX
            JMP IRQ20
SHAKE4      LDA SCROLX
            AND #%11111000
            STA SCROLX
IRQ20       ;CHECK TO SEE IF KEYBOARD WAS DISABLED
            ;This routine causes the kernal to skip keyboard
            ;input for one cycle to help "debounce" the
            ;keyboard.
            LDA XMAX  ;1=normal 0=disabled
            BNE IRQ30
            LDA KEYSOFF
            BEQ IRQ21
            +STI KEYSOFF, 0
            +STI XMAX, 1 ;turn keyboard back on
            JMP IRQ30
IRQ21       INC KEYSOFF
IRQ30       ;Animate Sprite Color
            DEC SPRITECOLTIMER
            LDA SPRITECOLTIMER
            BNE IRQ32
            +STI SPRITECOLTIMER, 7
            LDY SPRITECOLSTATE
            LDA SPRITECOLCHART,Y
            STA SP0COL  ;SPRITE 0 COLOR REGISTER
            ;STA  SP1COL  ;SPRITE 1 COLOR REGISTER
            INY
            CPY #8
            BNE IRQ31
            LDY #0
IRQ31       STY SPRITECOLSTATE
IRQ32       JMP SYSIRQ

BGTIMER2       !BYTE 00
KEYTIMER       !BYTE 00
KEYSOFF        !BYTE 00
BORDER         !BYTE 00,06,02,08,08,07,07,07,08,08,02
BGFLASH        !BYTE 00,00,06,14,14,01,01,01,14,14,06
SPRITECOLTIMER !BYTE 8
SSHAKE         !BYTE 00,02,04,02,00
SSCOUNT        !BYTE 00

!MACRO INC_TIMEPART .part, .max {
            INC .part
            LDA .part
            CMP #.max
            BNE UGC_DONE
            +STI .part, 0
}

;Since the PET OR VIC-20 has no real-time clock, and the Jiffy clock
;is a pain to read from assembly language, I have created my own.
;This could be updated in future to use the 6510's real-time clock
;for C64.
UPDATE_GAME_CLOCK
            LDA CLOCK_ACTIVE
            BEQ UGC_SKIP
            +INC_TIMEPART CYCLES, 60 ; 60 for ntsc or 50 for pal
            +INC_TIMEPART SECONDS, 60
            +INC_TIMEPART MINUTES, 60
            INC HOURS
UGC_DONE    ;JSR VDC_MAP_ANIMATE_PLAYER ; only animate the player if game clock is active
UGC_SKIP    RTS

HOURS        !BYTE 00
MINUTES      !BYTE 00
SECONDS      !BYTE 00
CYCLES       !BYTE 00
CLOCK_ACTIVE !BYTE 00

!IF SHAREWARE = 1 {

SNES_CONTROLER_READ:
  RTS

}

!IF SHAREWARE = 0 {

SNES_CONTROLER_READ:
  ;First copy last time's results to the LAST variables.
  LDY #0
SNCL: LDA SNES_B,Y
  STA LAST_B,Y
  ;STA  $x8398,Y   ;TESTCODE
  INY
  CPY #12
  BNE SNCL
  ;now latch data
  LDA #%00100000  ;latch on pin 5
  STA CI2PRB
  LDA #%00000000
  STA CI2PRB
  LDX #0
  ;Now read in bits
SRLOOP: LDA CI2PRB
  AND #%01000000  ;READ pin 6
  CMP #%01000000
  BEQ SRL1
  LDA #1
  JMP SRL5
SRL1: LDA #0
SRL5: STA SNES_B,X
  ;pulse the clock line
  LDA #%00001000  ;CLOCK on pin 3
  STA CI2PRB
  LDA #%00000000
  STA CI2PRB
  INX
  CPX #12
  BNE SRLOOP
  ;now process any new presses
  LDY #0
SRL09:  LDA NEW_B,Y
  CMP #1
  BEQ SRL10
  LDA SNES_B,Y
  CMP #1
  BNE SRL10
  LDA LAST_B,Y
  CMP #0
  BNE SRL10
  LDA #1
  STA NEW_B,Y
SRL10:  INY
  CPY #12
  BNE SRL09
  RTS
}

;This routine spaces out the timers so that not everything
;is running out once. It also starts the game_clock.
SET_INITIAL_TIMERS:
  +STI CLOCK_ACTIVE, 1
  LDX #01
SIT1
  TXA
  STA UNIT_TIMER_A,X
  LDA #0
  STA UNIT_TIMER_B,X
  INX
  CPX #48
  BNE SIT1
  RTS

DISPLAY_PLAYER_SPRITE:
  LDA UNIT_TILE
  CMP #111  ;Dead player
  BEQ DSPR2
  CMP #97
  BNE DSPR0
  LDA #3
  JMP DSPR1
DSPR0:  LDA #0
DSPR1:  STA TEMP_A
  LDA SPENA
  ORA #%11100000  ;turn on sprites 5,6,7
  STA SPENA
  
  LDA   #SP_PLAYER_UP_1_1
  CLC
  ADC PLAYER_DIRECTION
  ADC TEMP_A
  STA SPRITE_POINTER_5  ;SPRITE POINTER sprite #5

  LDA   #SP_PLAYER_UP_1_2
  CLC
  ADC PLAYER_DIRECTION
  ADC TEMP_A
  STA SPRITE_POINTER_6  ;SPRITE POINTER sprite #6
  
  LDA   #SP_PLAYER_UP_1_3
  CLC
  ADC PLAYER_DIRECTION
  ADC TEMP_A
  STA SPRITE_POINTER_7  ;SPRITE POINTER sprite #7

  RTS
DSPR2:  ;display dead player
  LDA SPENA
  ORA #%11100000  ;turn on sprites 5,6,7
  STA SPENA

  LDA #SP_PLAYER_DEAD_1
  STA SPRITE_POINTER_5  ;SPRITE POINTER sprite #5
  
  LDA #SP_PLAYER_DEAD_2
  STA SPRITE_POINTER_6  ;SPRITE POINTER sprite #6
  
  LDA #SP_PLAYER_DEAD_3
  STA SPRITE_POINTER_7  ;SPRITE POINTER sprite #7
  
  +STI SP5COL,  2 ;red        ;SPRITE COLOR 5
  +STI SP6COL, 10 ;orange     ;SPRITE COLOR 6
  +STI SP7COL, 15 ;light gray ;SPRITE COLOR 7
  RTS

MAIN_GAME_LOOP:
  JSR BACKGROUND_TASKS
  LDA UNIT_TYPE
  CMP #1  ;Is player unit alive
  BEQ MG00
  JMP GAME_OVER
MG00: LDA CONTROL
  CMP #2
  BNE KY01
!IF SHAREWARE = 0 {
  JMP SC01
}
KY01: ;Keyboard controls here.
  JSR KEY_REPEAT
  JSR GET_KEY
  CMP #$00
  BEQ MAIN_GAME_LOOP

  +CMPI_BEQ $1D,               MG_CURSOR_RIGHT
  +CMPI_BEQ $9D,               MG_CURSOR_LEFT
  +CMPI_BEQ $11,               MG_CURSOR_DOWN
  +CMPI_BEQ $91,               MG_CURSOR_UP
  +CMPM_BEQ KEY_CYCLE_WEAPONS, MG_CYCLE_WEAPONS
  +CMPM_BEQ KEY_CYCLE_ITEMS,   MG_CYCLE_ITEMS
  +CMPM_BEQ KEY_MOVE,          MG_MOVE
  +CMPM_BEQ KEY_SEARCH,        MG_SEARCH
  +CMPM_BEQ KEY_USE,           MG_USE
  +CMPM_BEQ KEY_MOVE_LEFT,     MG_CURSOR_LEFT
  +CMPM_BEQ KEY_MOVE_DOWN,     MG_CURSOR_DOWN
  +CMPM_BEQ KEY_MOVE_RIGHT,    MG_CURSOR_RIGHT
  +CMPM_BEQ KEY_MOVE_UP,       MG_CURSOR_UP
  +CMPM_BEQ KEY_FIRE_UP,       MG_FIRE_UP
  +CMPM_BEQ KEY_FIRE_LEFT,     MG_FIRE_LEFT
  +CMPM_BEQ KEY_FIRE_DOWN,     MG_FIRE_DOWN
  +CMPM_BEQ KEY_FIRE_RIGHT,    MG_FIRE_RIGHT
  +CMPI_BEQ 3,                 MG_RUN_STOP
  +CMPI_BEQ $88,               MG_DISP_MAP
!IF SHAREWARE = 0 {
  +CMPI_BEQ 223,               MG_CHEAT_MODE ; C= + *
}
  +CMPI_BEQ 205,               MG_TOGGLE_MUSIC ; SHIFT-M
  ;+CMPI_BEQ 9,                 MG_TOGGLE_COLOR ; TAB
!IF SHAREWARE = 0 {
  ;+CMPI_BEQ 24,                MG_TOGGLE_BOTS ; shift-tab
}
  +CMPI_BEQ 140,               MG_CYCLE_COLOR ; shift-F7 aka F8
  JMP MAIN_GAME_LOOP                         ; not valid key, loop

MG_CURSOR_RIGHT:
  LDA #18
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_RIGHT
  JMP AFTER_MOVE

MG_CURSOR_LEFT:
  LDA #12
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_LEFT
  JMP AFTER_MOVE

MG_CURSOR_DOWN:
  LDA #6
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_DOWN
  JMP AFTER_MOVE

MG_CURSOR_UP:
  LDA #0
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_UP
  JMP AFTER_MOVE

MG_CYCLE_WEAPONS:
  JSR CYCLE_WEAPON
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP

MG_CYCLE_ITEMS:
  JSR CYCLE_ITEM
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP

MG_MOVE:
  JSR MOVE_OBJECT
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP

MG_SEARCH:
  JSR SEARCH_OBJECT
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP

MG_USE:
  JSR USE_ITEM
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP

MG_FIRE_RIGHT:
  LDA #18
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  JSR FIRE_RIGHT
  LDA #20
  STA KEYTIMER
  JMP MAIN_GAME_LOOP

MG_FIRE_LEFT:
  LDA #12
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  JSR FIRE_LEFT
  LDA #20
  STA KEYTIMER
  JMP MAIN_GAME_LOOP

MG_FIRE_DOWN:
  LDA #6
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  JSR FIRE_DOWN
  LDA #20
  STA KEYTIMER
  JMP MAIN_GAME_LOOP

MG_FIRE_UP:
  LDA #0
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  JSR FIRE_UP
  LDA #20
  STA KEYTIMER
  JMP MAIN_GAME_LOOP

MG_RUN_STOP:
  JMP PAUSE_GAME

MG_DISP_MAP:
  JMP DISP_MCBM_MAP

!IF SHAREWARE = 0 {
MG_CHEAT_MODE:
  JSR CHEATER
  JMP MAIN_GAME_LOOP
}

MG_TOGGLE_MUSIC:
  JSR TOGGLE_MUSIC
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP

;MG_TOGGLE_COLOR:
;            LDA #15   ;menu beep
;            JSR PLAY_SOUND  ;SOUND PLAY
;            +MEORI VDC_MAP_USE_COLOR, $01
;            LDA VDC_MAP_USE_COLOR
;            BNE +
;            +STIW $FB, MSG_MAPCOLOROFF
;            JMP ++
;+           +STIW $FB, MSG_MAPCOLORON
;++          JSR PRINT_INFO
;            JSR CLEAR_KEY_BUFFER
;            JSR VDC_MAP_RENDER
;            JMP MAIN_GAME_LOOP

;!IF SHAREWARE = 0 {
;MG_TOGGLE_BOTS:
;            LDA #15   ;menu beep
;            JSR PLAY_SOUND  ;SOUND PLAY
;            +MEORI VDC_MAP_SHOW_BOTS, $01
;            LDA VDC_MAP_SHOW_BOTS
;            BNE +
;            +STIW $FB, MSG_MAPBOTSOFF
;            JMP ++
;+           +STIW $FB, MSG_MAPBOTSON
;++          JSR PRINT_INFO
;            JSR CLEAR_KEY_BUFFER
;            JSR VDC_MAP_RENDER
;            JMP MAIN_GAME_LOOP
;}

MG_CYCLE_COLOR:
            INC PLAYER_COLOR_INDEX
            LDA PLAYER_COLOR_INDEX
            AND #3
            STA PLAYER_COLOR_INDEX
            TAX
            LDA PLAYER_COLOR_SP_5,X
            STA SP5COL
            LDA PLAYER_COLOR_SP_6,X
            STA SP6COL
            LDA PLAYER_COLOR_SP_7,X
            STA SP7COL
            JSR CLEAR_KEY_BUFFER
            JMP MAIN_GAME_LOOP

PLAYER_COLOR_INDEX: !BYTE 2
PLAYER_COLOR_SP_5: !BYTE 12,  0,  2, 11
PLAYER_COLOR_SP_6: !BYTE 15, 14, 13, 15
PLAYER_COLOR_SP_7: !BYTE  1,  8, 10, 10

!IF SHAREWARE = 0 {

SC01: ;SNES CONTROLLER starts here
  JSR SNES_CONTROLER_READ
  ;check keytimer for repeat time.
  LDA KEYTIMER
  CMP #0
  BEQ SC02
  JMP SC40
SC02: LDA #0
  STA NEW_UP
  STA NEW_DOWN
  STA NEW_LEFT
  STA NEW_RIGHT
  STA SNES_UP
  STA SNES_DOWN
  STA SNES_LEFT
  STA SNES_RIGHT
  JSR SNES_CONTROLER_READ
SC05: ;first we start with the 4 directional buttons.
  LDA NEW_LEFT
  CMP #01
  BNE SC10
	LDA	SNES_SELECT	;find out if select is being held down
	CMP	#0
	BEQ	SC06
	LDA	#0
	STA	NEW_LEFT
	JMP DISP_MCBM_MAP
SC06: LDA #12
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_LEFT
  JMP AFTER_MOVE_SNES
SC10: LDA NEW_RIGHT
  CMP #01
  BNE SC20
  LDA #18
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_RIGHT
  JMP AFTER_MOVE_SNES
SC20: LDA NEW_UP
  CMP #01
  BNE SC30
  LDA #0
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_UP
  JMP AFTER_MOVE_SNES
SC30: LDA NEW_DOWN
  CMP #01
  BNE SC35
  LDA #6
  STA PLAYER_DIRECTION
  LDA #0
  STA UNIT
  LDA #%00000001
  STA MOVE_TYPE
  JSR REQUEST_WALK_DOWN
  JMP AFTER_MOVE_SNES
SC35: LDA #0
  STA KEY_FAST
SC40: ;Now check for non-repeating buttons
  LDA NEW_Y
  CMP #1
  BNE SC45
  JSR FIRE_LEFT
  LDA #0
  STA NEW_Y
SC45: LDA NEW_A
  CMP #1
  BNE SC50
  JSR FIRE_RIGHT
  LDA #0
  STA NEW_A
SC50: LDA NEW_X
  CMP #1
  BNE SC55
  JSR FIRE_UP
  LDA #0
  STA NEW_X
SC55: LDA NEW_B
  CMP #1
  BNE SC60
  JSR FIRE_DOWN
  LDA #0
  STA NEW_B
SC60: LDA NEW_BACK_L
  CMP #1
  BNE SC65
  LDA SNES_SELECT
  CMP #1
  BNE SC62
  JSR CYCLE_ITEM
  JMP SC63
SC62: JSR SEARCH_OBJECT
SC63: LDA #0
  STA NEW_BACK_L
  LDA #15
  STA KEYTIMER
SC65: LDA NEW_BACK_R
  CMP #1
  BNE SC70
  LDA SNES_SELECT
  CMP #1
  BNE SC67
  JSR CYCLE_WEAPON
  JMP SC68
SC67: JSR MOVE_OBJECT
SC68: LDA #0
  STA NEW_BACK_R
  LDA #15
  STA KEYTIMER
SC70: LDA NEW_START
  CMP #1
  BNE SC75
  JSR USE_ITEM
  LDA #0
  STA NEW_START
  LDA #15
  STA KEYTIMER
SC75: ;STILL USE KEYBOARD TO CHECK FOR RUN/STOP AND PET MODE
  JSR GET_KEY
  CMP #03 ;RUN/STOP
  BNE SC82
  JMP PAUSE_GAME
  JMP MAIN_GAME_LOOP
SC82: CMP #205  ;SHIFT-M
  BNE SC83
  JSR TOGGLE_MUSIC
  JSR CLEAR_KEY_BUFFER
  JMP MAIN_GAME_LOOP
SC83: ;CMP #9 ; TAB
  ;BNE SC84
  ;JMP MG_TOGGLE_COLOR
SC84: ;CMP #24 ; SHIFT-TAB
  ;BNE SC85
  ;JMP MG_TOGGLE_BOTS
SC85: CMP #140 ; SHIFT-F7 (aka F8)
  BNE SC86
  JMP MG_CYCLE_COLOR
SC86: JMP MAIN_GAME_LOOP

}

;This routine handles things that are in common to
;all 4 directions of movement.
AFTER_MOVE_SNES:
  LDA MOVE_RESULT
  CMP #1
  BNE AMS01
  JSR ANIMATE_PLAYER
  JSR CALCULATE_AND_REDRAW
  JSR DISPLAY_PLAYER_SPRITE
AMS01:  LDA KEY_FAST
  CMP #0
  BNE AMS02
  LDA #15
  STA KEYTIMER
  LDA #1
  STA KEY_FAST
  JMP AMS03
AMS02:  LDA #6
  STA KEYTIMER
  LDA #0
  STA NEW_UP
  STA NEW_DOWN
  STA NEW_LEFT
  STA NEW_RIGHT
AMS03:  JMP MAIN_GAME_LOOP

!IF SHAREWARE = 0 {
;TEMP ROUTINE TO GIVE ME ALL ITEMS AND WEAPONS
CHEATER:
  LDA #7
  STA KEYS
  LDA #100
  STA AMMO_PISTOL
  STA AMMO_PLASMA
  STA INV_BOMBS
  STA INV_EMP
  STA INV_MEDKIT
  STA INV_MAGNET
  LDA #1
  STA SELECTED_WEAPON
  STA SELECTED_ITEM
  JSR DISPLAY_KEYS
  JSR DISPLAY_WEAPON
  JSR DISPLAY_ITEM
  RTS
}

PAUSE_GAME:
  LDA #15   ;menu beep
  JSR PLAY_SOUND  ;SOUND PLAY
  ;pause clock
  LDA #0
  STA CLOCK_ACTIVE
  ;display message to user
  JSR SCROLL_INFO
  LDA #<MSG_PAUSED
  STA $FB
  LDA #>MSG_PAUSED
  STA $FC
  JSR PRINT_INFO
  JSR CLEAR_KEY_BUFFER
PG1:  JSR GET_KEY
  CMP #$00
  BEQ PG1
  CMP #03 ;RUN/STOP
  BEQ PG5
  CMP #78 ;N-KEY
  BEQ PG5
  CMP #89 ;Y-KEY
  BEQ PG6
  JMP PG1
PG5:  LDA #15   ;menu beep
  JSR PLAY_SOUND  ;SOUND PLAY
  JSR SCROLL_INFO
  JSR SCROLL_INFO
  JSR SCROLL_INFO
  JSR CLEAR_KEY_BUFFER
  LDA #1
  STA CLOCK_ACTIVE
  JMP MAIN_GAME_LOOP
PG6:  LDA #0
  STA UNIT_TYPE ;make player dead
  JMP GOM4

DISP_MCBM_MAP:
  LDA #15   ;menu beep
  JSR PLAY_SOUND  ;SOUND PLAY
  ;pause clock
  LDA #0
  STA CLOCK_ACTIVE
  STA MCBM_MAP_SHOW_ROBOTS
  JSR CLEAR_KEY_BUFFER
	JSR	CLEAR_SNES_PAD
  JSR INIT_MCBM_MAP
DMM1:
  JSR RENDER_MCBM_MAP_UPDATE
  JSR	SNES_CONTROLER_READ
	LDA	NEW_B
	CMP	#0
	BEQ	+
	JMP	RETURN_TO_GAME
+:
	LDA	NEW_A
	CMP	#0
	BEQ	+
	LDA	#0
	STA	NEW_A
	JMP	DMM2
+:
  JSR GET_KEY
  CMP #$00
  BEQ DMM1
  CMP #$88
  BEQ DMM2
RETURN_TO_GAME:
  ; other key hit, resume game
  LDA #15   ;menu beep
  JSR PLAY_SOUND  ;SOUND PLAY
  JSR CLEAR_SNES_PAD
  JSR CLEAR_KEY_BUFFER
  LDA #1
  STA CLOCK_ACTIVE
  JSR FETCH_GAME_SCREEN
  JMP MAIN_GAME_LOOP
DMM2:
  LDA #15   ;menu beep
  JSR PLAY_SOUND  ;SOUND PLAY
  JSR CLEAR_KEY_BUFFER
  JSR CLEAR_SNES_PAD
!IF SHAREWARE = 0 {
  LDA MCBM_MAP_SHOW_ROBOTS
  EOR #1
  STA MCBM_MAP_SHOW_ROBOTS
}
  JMP DMM1

RENDER_MCBM_MAP_UPDATE:
  LDA MCBM_MAP_COUNTER+0
  CMP #0
  BNE ++
  LDA MCBM_MAP_COUNTER+1
  CMP #0
  BNE ++

  +STIW MCBM_MAP_COUNTER, $200
  LDA MCBM_MAP_UNIT_COLOR
  EOR #$FF
  STA MCBM_MAP_UNIT_COLOR

  LDA MCBM_MAP_SHOW_ROBOTS
  BNE +
  JSR RENDER_MCBM_MAP_PLAYER
  RTS
+ JSR RENDER_MCBM_MAP_ROBOTS
  RTS

++ +SUBWI MCBM_MAP_COUNTER, 1
   RTS

RENDER_MCBM_MAP_PLAYER:
  LDA UNIT_LOC_X
  STA $FD
  LDA UNIT_LOC_Y
  STA $FE
  JSR RENDER_MCBM_MAP_UNIT
  RTS

RENDER_MCBM_MAP_ROBOTS:
  LDX #1
- LDA UNIT_TYPE,X
  BEQ +
  LDA UNIT_LOC_X,X
  STA $FD
  LDA UNIT_LOC_Y,X
  STA $FE
  +PHX
  JSR RENDER_MCBM_MAP_UNIT
  +PLX
+ INX
  CPX #28
  BNE -
  RTS

RENDER_MCBM_MAP_UNIT:
  LDX $FE
  LDA MCBM_MAP_ROWL,X
  STA $FB
  LDA MCBM_MAP_ROWH,X
  STA $FC
  LDX $FD
  LDA MCBM_MAP_COL_OFF,X
  CLC
  ADC $FB
  STA $FB
  LDA $FC
  ADC #$00
  STA $FC
  ; ($FB) now points to first byte of map unit tile
  LDA MCBM_MAP_UNIT_COLOR
  AND MCBM_MAP_COL_MASK,X
  STA MCBM_MAP_UNIT_VALUE
  LDA MCBM_MAP_COL_MASK,X
  EOR #$FF
  STA MCBM_MAP_UNIT_MASK
  PHP
  SEI
  +PH $01
  LDA $01
  AND #$F8
  STA $01
  LDY #0
  LDA ($FB),Y
  AND MCBM_MAP_UNIT_MASK
  ORA MCBM_MAP_UNIT_VALUE
  STA ($FB),Y
  INY
  STA ($FB),Y
  +PL $01
  PLP
  RTS

MCBM_MAP_SHOW_ROBOTS !BYTE 0
MCBM_MAP_COUNTER !WORD 0
MCBM_MAP_UNIT_COLOR !BYTE 0 ; $00 for black, $FF for white, toggled
MCBM_MAP_UNIT_MASK !BYTE 0
MCBM_MAP_UNIT_VALUE !BYTE 0

MCBM_MAP_ROWL !BYTE <(ADDR_BITMAP+640+32+ 0*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 0*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 0*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 0*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 1*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 1*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 1*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 1*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 2*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 2*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 2*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 2*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 3*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 3*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 3*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 3*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 4*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 4*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 4*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 4*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 5*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 5*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 5*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 5*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 6*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 6*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 6*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 6*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 7*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 7*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 7*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 7*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 8*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 8*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 8*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 8*320+6)
              !BYTE <(ADDR_BITMAP+640+32+ 9*320+0)
              !BYTE <(ADDR_BITMAP+640+32+ 9*320+2)
              !BYTE <(ADDR_BITMAP+640+32+ 9*320+4)
              !BYTE <(ADDR_BITMAP+640+32+ 9*320+6)
              !BYTE <(ADDR_BITMAP+640+32+10*320+0)
              !BYTE <(ADDR_BITMAP+640+32+10*320+2)
              !BYTE <(ADDR_BITMAP+640+32+10*320+4)
              !BYTE <(ADDR_BITMAP+640+32+10*320+6)
              !BYTE <(ADDR_BITMAP+640+32+11*320+0)
              !BYTE <(ADDR_BITMAP+640+32+11*320+2)
              !BYTE <(ADDR_BITMAP+640+32+11*320+4)
              !BYTE <(ADDR_BITMAP+640+32+11*320+6)
              !BYTE <(ADDR_BITMAP+640+32+12*320+0)
              !BYTE <(ADDR_BITMAP+640+32+12*320+2)
              !BYTE <(ADDR_BITMAP+640+32+12*320+4)
              !BYTE <(ADDR_BITMAP+640+32+12*320+6)
              !BYTE <(ADDR_BITMAP+640+32+13*320+0)
              !BYTE <(ADDR_BITMAP+640+32+13*320+2)
              !BYTE <(ADDR_BITMAP+640+32+13*320+4)
              !BYTE <(ADDR_BITMAP+640+32+13*320+6)
              !BYTE <(ADDR_BITMAP+640+32+14*320+0)
              !BYTE <(ADDR_BITMAP+640+32+14*320+2)
              !BYTE <(ADDR_BITMAP+640+32+14*320+4)
              !BYTE <(ADDR_BITMAP+640+32+14*320+6)
              !BYTE <(ADDR_BITMAP+640+32+15*320+0)
              !BYTE <(ADDR_BITMAP+640+32+15*320+2)
              !BYTE <(ADDR_BITMAP+640+32+15*320+4)
              !BYTE <(ADDR_BITMAP+640+32+15*320+6)

MCBM_MAP_ROWH !BYTE >(ADDR_BITMAP+640+32+ 0*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 0*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 0*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 0*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 1*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 1*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 1*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 1*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 2*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 2*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 2*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 2*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 3*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 3*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 3*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 3*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 4*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 4*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 4*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 4*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 5*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 5*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 5*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 5*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 6*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 6*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 6*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 6*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 7*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 7*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 7*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 7*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 8*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 8*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 8*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 8*320+6)
              !BYTE >(ADDR_BITMAP+640+32+ 9*320+0)
              !BYTE >(ADDR_BITMAP+640+32+ 9*320+2)
              !BYTE >(ADDR_BITMAP+640+32+ 9*320+4)
              !BYTE >(ADDR_BITMAP+640+32+ 9*320+6)
              !BYTE >(ADDR_BITMAP+640+32+10*320+0)
              !BYTE >(ADDR_BITMAP+640+32+10*320+2)
              !BYTE >(ADDR_BITMAP+640+32+10*320+4)
              !BYTE >(ADDR_BITMAP+640+32+10*320+6)
              !BYTE >(ADDR_BITMAP+640+32+11*320+0)
              !BYTE >(ADDR_BITMAP+640+32+11*320+2)
              !BYTE >(ADDR_BITMAP+640+32+11*320+4)
              !BYTE >(ADDR_BITMAP+640+32+11*320+6)
              !BYTE >(ADDR_BITMAP+640+32+12*320+0)
              !BYTE >(ADDR_BITMAP+640+32+12*320+2)
              !BYTE >(ADDR_BITMAP+640+32+12*320+4)
              !BYTE >(ADDR_BITMAP+640+32+12*320+6)
              !BYTE >(ADDR_BITMAP+640+32+13*320+0)
              !BYTE >(ADDR_BITMAP+640+32+13*320+2)
              !BYTE >(ADDR_BITMAP+640+32+13*320+4)
              !BYTE >(ADDR_BITMAP+640+32+13*320+6)
              !BYTE >(ADDR_BITMAP+640+32+14*320+0)
              !BYTE >(ADDR_BITMAP+640+32+14*320+2)
              !BYTE >(ADDR_BITMAP+640+32+14*320+4)
              !BYTE >(ADDR_BITMAP+640+32+14*320+6)
              !BYTE >(ADDR_BITMAP+640+32+15*320+0)
              !BYTE >(ADDR_BITMAP+640+32+15*320+2)
              !BYTE >(ADDR_BITMAP+640+32+15*320+4)
              !BYTE >(ADDR_BITMAP+640+32+15*320+6)

MCBM_MAP_COL_OFF !FILL 4, 0*8
                 !FILL 4, 1*8
                 !FILL 4, 2*8
                 !FILL 4, 3*8
                 !FILL 4, 4*8
                 !FILL 4, 5*8
                 !FILL 4, 6*8
                 !FILL 4, 7*8
                 !FILL 4, 8*8
                 !FILL 4, 9*8
                 !FILL 4,10*8
                 !FILL 4,11*8
                 !FILL 4,12*8
                 !FILL 4,13*8
                 !FILL 4,14*8
                 !FILL 4,15*8
                 !FILL 4,16*8
                 !FILL 4,17*8
                 !FILL 4,18*8
                 !FILL 4,19*8
                 !FILL 4,20*8
                 !FILL 4,21*8
                 !FILL 4,22*8
                 !FILL 4,23*8
                 !FILL 4,24*8
                 !FILL 4,25*8
                 !FILL 4,26*8
                 !FILL 4,27*8
                 !FILL 4,28*8
                 !FILL 4,29*8
                 !FILL 4,30*8
                 !FILL 4,31*8

MCBM_MAP_COL_MASK !FOR I, 32 {
  !BYTE %11000000, %00110000, %00001100, %00000011
}

INIT_MCBM_MAP:
  JSR STASH_GAME_SCREEN

  JSR INIT_LAST_TILE
  LDA #0
  LDX #249
- STA ADDR_COLOR12+   0,X ; fill COLOR12 memory
  STA ADDR_COLOR12+ 250,X
  STA ADDR_COLOR12+ 500,X
  STA ADDR_COLOR12+ 750,X
  STA ADDR_COLOR3 +   0,X ; fill COLOR3 memory
  STA ADDR_COLOR3 + 250,X
  STA ADDR_COLOR3 + 500,X
  STA ADDR_COLOR3 + 750,X
  STA ADDR_BITMAP +   0,X ; fill BITMAP memory
  STA ADDR_BITMAP + 250,X
  STA ADDR_BITMAP + 500,X
  STA ADDR_BITMAP + 750,X
  STA ADDR_BITMAP +1000,X
  STA ADDR_BITMAP +1250,X
  STA ADDR_BITMAP +1500,X
  STA ADDR_BITMAP +1750,X
  STA ADDR_BITMAP +2000,X
  STA ADDR_BITMAP +2250,X
  STA ADDR_BITMAP +2500,X
  STA ADDR_BITMAP +2750,X
  STA ADDR_BITMAP +3000,X
  STA ADDR_BITMAP +3250,X
  STA ADDR_BITMAP +3500,X
  STA ADDR_BITMAP +3750,X
  STA ADDR_BITMAP +4000,X
  STA ADDR_BITMAP +4250,X
  STA ADDR_BITMAP +4500,X
  STA ADDR_BITMAP +4750,X
  STA ADDR_BITMAP +5000,X
  STA ADDR_BITMAP +5250,X
  STA ADDR_BITMAP +5500,X
  STA ADDR_BITMAP +5750,X
  STA ADDR_BITMAP +6000,X
  STA ADDR_BITMAP +6250,X
  STA ADDR_BITMAP +6500,X
  STA ADDR_BITMAP +6750,X
  STA ADDR_BITMAP +7000,X
  STA ADDR_BITMAP +7250,X
  STA ADDR_BITMAP +7500,X
  STA ADDR_BITMAP +7750,X
  CPX #0
  BEQ +
  DEX
  JMP -

+ LDA #$BF                ; dark gray & light gray
  LDX #249
- STA ADDR_COLOR12+   0,X ; fill COLOR12 memory
  STA ADDR_COLOR12+ 250,X
  STA ADDR_COLOR12+ 500,X
  STA ADDR_COLOR12+ 750,X
  CPX #0
  BEQ +
  DEX
  JMP -

+ LDA #$01                ; white
  LDX #249
- STA ADDR_COLOR3 +   0,X ; fill COLOR3 memory
  STA ADDR_COLOR3 + 250,X
  STA ADDR_COLOR3 + 500,X
  STA ADDR_COLOR3 + 750,X
  CPX #0
  BEQ FAST_RENDER_MCBM_MAP
  DEX
  JMP -

FAST_RENDER_MCBM_MAP:
  PHA
  +PHX
  +PHY
  +PHW $FB
  +PHW $FD

  LDX #0
  +STIW $FB, ADDR_MAPDATA
  +STIW $FD, ADDR_BITMAP+32+2*320
- JSR FAST_RENDER_MCBM_MAP_ROW
  +ADDW $FB, 512
  +ADDW $FD, 320
  INX
  CPX #16
  BNE -

  +STIW $FB, MAP_SCENARIO
  +STIW $FD, 680
  
  LDY #0
- LDA MAP_TITLE, Y
  BEQ +
  +MC_PLOT_CHAR_Y 0*40+6
  INY
  JMP -

+ LDY #0
- LDA MAP_SCENARIO, Y
  BEQ +
  +MC_PLOT_CHAR_Y 19*40+2
  INY
  JMP -

+ LDY #0
- LDA MAP_TIME, Y
  BEQ +
  +MC_PLOT_CHAR_Y 20*40+2
  INY
  JMP -

+ LDY #0
- LDA MAP_ROBOTS, Y
  BEQ +
  +MC_PLOT_CHAR_Y 21*40+2
  INY
  JMP -

+ LDY #0
- LDA MAP_SECRETS, Y
  BEQ +
  +MC_PLOT_CHAR_Y 22*40+2
  INY
  JMP -

+ LDY #0
- LDA MAP_DIFFICULTY, Y
  BEQ +
  +MC_PLOT_CHAR_Y 23*40+2
  INY
  JMP -

  ; display map name
+ JSR CALC_MAP_NAME
- LDA ($FB),Y
  +MC_PLOT_CHAR_Y 19*40+2+19
  INY
  CPY #16
  BNE -

  ;display elapsed time
  +DECWRITE 20*40+2+18, HOURS
  +DECWRITE 20*40+2+21, MINUTES
  +DECWRITE 20*40+2+24, SECONDS
  LDA #32 ;SPACE
  +MC_PLOT_CHAR 20*40+2+18
  LDA #58 ;COLON
  +MC_PLOT_CHAR 20*40+2+21
  +MC_PLOT_CHAR 20*40+2+24

  ;count robots remaining
  LDX #1
  LDA #0
  STA DECNUM
- LDA UNIT_TYPE,X
  CMP #0
  BEQ +
  INC DECNUM
+ INX
  CPX #28
  BNE -
  +DECWRITE  21*40+2+19

  ;Count secrets remaining
  LDA #0
  STA DECNUM
  LDX #48
- LDA UNIT_TYPE,X
  CMP #0
  BEQ +
  INC DECNUM
+ INX
  CPX #64
  BNE -
  +DECWRITE  22*40+2+19

  ;display difficulty level
  LDY DIFF_LEVEL
  LDA DIFF_LEVEL_LEN,Y
  TAY
  LDX #0
- LDA DIFF_LEVEL_WORDS,Y
  CMP #0
  BEQ +
  +MC_PLOT_CHAR_X  23*40+2+19
  INY
  INX
  JMP -

+ +PLW $FD
  +PLW $FB
  +PLY
  +PLX
  PLA
  RTS

MAP_TITLE      !SCR "attack of the petscii robots",0
MAP_SCENARIO   !SCR "         scenario:",0
MAP_TIME       !SCR "     elapsed time:",0
MAP_ROBOTS     !SCR " robots remaining:",0
MAP_SECRETS    !SCR "secrets remaining:",0
MAP_DIFFICULTY !SCR "       difficulty:",0

FAST_RENDER_MCBM_MAP_ROW:
  +PHX
  +PHW $FB
  +PHW $FD
  
  LDX #0
- JSR FAST_RENDER_MCBM_MAP_CELL
  INX
  CPX #32
  BNE - 
  
  +PLW $FD
  +PLW $FB
  +PLX
  RTS

FAST_RENDER_MCBM_MAP_CELL:
  JSR FAST_RENDER_MCBM_MAP_QUAD
  JSR FAST_RENDER_MCBM_MAP_QUAD
  JSR FAST_RENDER_MCBM_MAP_QUAD
  JSR FAST_RENDER_MCBM_MAP_QUAD
  +SUBW $FB, 512-4
  RTS

FAST_RENDER_MCBM_MAP_QUAD:
  LDY #0
  LDA ($FB),Y
  TAY
  LDA RENDER_MCBM_MAP_TILE_COLORS,Y
  PHA

  LDY #1
  LDA ($FB),Y
  TAY
  PLA
  ASL
  ASL
  ORA RENDER_MCBM_MAP_TILE_COLORS,Y
  PHA
  
  LDY #2
  LDA ($FB),Y
  TAY
  PLA
  ASL
  ASL
  ORA RENDER_MCBM_MAP_TILE_COLORS,Y
  PHA
  
  LDY #3
  LDA ($FB),Y
  TAY
  PLA
  ASL
  ASL
  ORA RENDER_MCBM_MAP_TILE_COLORS,Y

  LDY #0
  STA ($FD),Y
  INY
  STA ($FD),Y
  
  +ADDW $FB, 128
  +ADDW $FD, 2
  RTS

RENDER_MCBM_MAP_TILE_COLORS:
            !BYTE	0,0,3,3,3,3,3,3	;tiles 0-7
            !BYTE	3,0,3,3,3,3,0,3	;tiles 8-15
            !BYTE	3,3,3,3,3,3,3,0	;tiles 16-23
            !BYTE	2,3,3,3,3,2,0,0	;tiles 24-31
            !BYTE	2,2,2,2,2,2,2,2	;tiles 32-39
            !BYTE	2,2,2,2,2,2,2,2	;tiles 40-47
            !BYTE	3,3,3,2,3,2,2,2	;tiles 48-55
            !BYTE	3,2,2,2,2,2,2,3	;tiles 56-63
            !BYTE	0,0,3,3,3,0,0,3	;tiles 64-71
            !BYTE	2,0,0,3,3,0,0,3	;tiles 72-79
            !BYTE	3,2,3,2,2,2,2,2	;tiles 80-87
            !BYTE	2,2,3,3,3,3,3,2	;tiles 88-95
            !BYTE	0,0,0,0,0,0,0,0	;tiles 96-103
            !BYTE	3,3,3,2,2,2,2,0	;tiles 104-111
            !BYTE	3,3,3,2,0,0,3,3	;tiles 112-119
            !BYTE	3,3,1,1,1,1,1,1	;tiles 120-127
            !BYTE	3,3,2,2,2,2,2,2	;tiles 128-135
            !BYTE	2,2,2,2,2,2,2,2	;tiles 136-143
            !BYTE	3,3,2,2,2,2,2,2	;tiles 144-151
            !BYTE	2,2,2,2,2,2,2,0	;tiles 152-159
            !BYTE	2,2,2,0,2,2,3,2	;tiles 160-167
            !BYTE	0,2,3,2,2,2,3,2	;tiles 168-175
            !BYTE	3,3,3,3,3,2,2,0	;tiles 176-183
            !BYTE	3,3,3,3,3,0,3,3	;tiles 184-191
            !BYTE	3,3,3,3,2,2,2,2	;tiles 192-199
            !BYTE	2,2,2,2,2,1,2,2	;tiles 200-207
            !BYTE	1,1,1,3,3,3,2,2	;tiles 208-215
            !BYTE	3,3,3,2,3,3,3,3	;tiles 216-223
            !BYTE	3,3,3,2,2,2,2,2	;tiles 224-231
            !BYTE	2,2,2,2,3,3,0,0	;tiles 232-239
            !BYTE	0,0,3,0,0,0,0,0	;tiles 240-247
            !BYTE	0,0,0,0,0,0,0,0	;tiles 248-255

RENDER_MCBM_MAP_TILE_MASK  !BYTE 0
RENDER_MCBM_MAP_TILE_VALUE !BYTE 0

CLEAR_KEY_BUFFER:
  LDA #0
  STA XMAX  ;disable keyboard input
  LDA #0
  STA NDX ;CLEAR KEYBOARD BUFFER
  LDA #20
  STA KEYTIMER
  RTS

USE_ITEM:
  ;First figure out which item to use.
  LDA SELECTED_ITEM
  CMP #1  ;BOMB
  BNE UI02
  JMP USE_BOMB
UI02: CMP #2  ;EMP
  BNE UI03
  JMP USE_EMP
UI03: CMP #3  ;MEDKIT
  BNE UI04
  JMP USE_MEDKIT
UI04: CMP #4  ;MAGNET
  BNE UI05
  JMP USE_MAGNET
UI05: RTS

USE_BOMB:
  LDA #SP_ARROWS
  STA CURSOR_SPRITE_NUMBER
  JSR USER_SELECT_OBJECT
  ;NOW TEST TO SEE IF THAT SPOT IS OPEN
  JSR BOMB_MAGNET_COMMON1
  BEQ BM30
  JMP BM3A        ;If not, then exit routine.
BM30: ;Now scan for any units at that location:
  JSR CHECK_FOR_UNIT
  LDA UNIT_FIND
  CMP #255      ;255 means no unit found.
  BEQ BM31
BM3A: JMP BOMB_MAGNET_COMMON2
BM31: LDX #28 ;Start of weapons units
BOMB1:  LDA UNIT_TYPE,X
  CMP #0
  BEQ BOMB2
  INX
  CPX #32
  BNE BOMB1
  RTS ;no slots available right now, abort.
BOMB2:  LDA #6  ;bomb AI
  STA UNIT_TYPE,X
  LDA #SP_BOMB  ;bomb sprite
  STA UNIT_TILE,X
  LDA MAP_X
  STA UNIT_LOC_X,X
  LDA MAP_Y
  STA UNIT_LOC_Y,X
  LDA #100    ;How long until exposion?
  STA UNIT_TIMER_A,X
  LDA #0
  STA UNIT_A,X
  DEC INV_BOMBS
  JSR DISPLAY_ITEM
  LDA #01
  STA REDRAW_WINDOW
  LDA #6    ;move sound
  JSR PLAY_SOUND  ;SOUND PLAY
  RTS

USE_MAGNET:
  LDA MAGNET_ACT  ;only one magnet active at a time.
  CMP #0
  BEQ MG32
  RTS
MG32:
  LDA #SP_ARROWS
  STA CURSOR_SPRITE_NUMBER
  JSR USER_SELECT_OBJECT
  ;NOW TEST TO SEE IF THAT SPOT IS OPEN
  JSR BOMB_MAGNET_COMMON1
  BEQ MG31
  JMP BOMB_MAGNET_COMMON2
MG31: LDX #28 ;Start of weapons units
MAG1: LDA UNIT_TYPE,X
  CMP #0
  BEQ MAG2
  INX
  CPX #32
  BNE MAG1
  RTS ;no slots available right now, abort.
MAG2: LDA #20 ;MAGNET AI
  STA UNIT_TYPE,X
  LDA #SP_MAGNET  ;MAGNET sprite
  STA UNIT_TILE,X
  LDA MAP_X
  STA UNIT_LOC_X,X
  LDA MAP_Y
  STA UNIT_LOC_Y,X
  LDA #1    ;How long until ACTIVATION
  STA UNIT_TIMER_A,X
  LDA #255    ;how long does it live -A
  STA UNIT_TIMER_B,X
  LDA #5    ;how long does it live -B
  STA UNIT_A,X
  LDA #1
  STA MAGNET_ACT  ;only one magnet allowed at a time.
  DEC INV_MAGNET
  JSR DISPLAY_ITEM
  LDA #01
  STA REDRAW_WINDOW
  LDA #6    ;move sound
  JSR PLAY_SOUND  ;SOUND PLAY
  RTS

BOMB_MAGNET_COMMON1:
  LDA #0
  STA CURSOR_ON
  JSR DRAW_MAP_WINDOW   ;ERASE THE CURSOR
  LDA CURSOR_X
  CLC
  ADC MAP_WINDOW_X
  STA MAP_X
  STA MOVTEMP_UX
  LDA CURSOR_Y
  CLC
  ADC MAP_WINDOW_Y
  STA MAP_Y
  STA MOVTEMP_UY
  JSR GET_TILE_FROM_MAP
  LDA TILE
  TAY
  LDA TILE_ATTRIB,Y
  AND #%00000001    ;is that spot available
  CMP #%00000001    ;for something to move onto it?
  RTS

BOMB_MAGNET_COMMON2:
  LDA #<MSG_BLOCKED
  STA $FB
  LDA #>MSG_BLOCKED
  STA $FC
  JSR PRINT_INFO
  LDA #11   ;ERROR SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  RTS

USE_EMP:
  LDA #10
  STA BGFLASH
  LDA #3    ;EMP sound
  JSR PLAY_SOUND  ;SOUND PLAY
  DEC INV_EMP
  JSR DISPLAY_ITEM
  LDX #1  ;start with unit#1 (skip player)
EMP1: ;CHECK THAT UNIT EXISTS
  LDA UNIT_TYPE,X
  CMP #0
  BEQ EMP5
  ;CHECK HORIZONTAL POSITION
  LDA UNIT_LOC_X,X
  CMP MAP_WINDOW_X
  BCC EMP5
  LDA MAP_WINDOW_X
  CLC
  ADC #10
  CMP UNIT_LOC_X,X
  BCC EMP5
  ;NOW CHECK VERTICAL
  LDA UNIT_LOC_Y,X
  CMP MAP_WINDOW_Y
  BCC EMP5
  LDA MAP_WINDOW_Y
  CLC
  ADC #6
  CMP UNIT_LOC_Y,X
  BCC EMP5
  LDA #255
  STA UNIT_TIMER_A,X
  ;test to see if unit is above water
  LDA UNIT_LOC_X,X
  STA MAP_X
  LDA UNIT_LOC_Y,X
  STA MAP_Y
  JSR GET_TILE_FROM_MAP
  LDA TILE
  CMP #204  ;WATER
  BNE EMP5
  LDA #5
  STA UNIT_TYPE,X
  STA UNIT_TIMER_A,X
  LDA #60
  STA UNIT_A,X
  LDA #140  ;Electrocuting tile
  STA UNIT_TILE,X
EMP5: INX
  CPX #28
  BNE EMP1
  LDA #<MSG_EMPUSED
  STA $FB
  LDA #>MSG_EMPUSED
  STA $FC
  JSR PRINT_INFO
  RTS

USE_MEDKIT:
  LDA UNIT_HEALTH
  CMP #12 ;Do we even need the medkit?
  BNE UMK1
  RTS
UMK1: ;Now figure out how many HP we need to be healthy.
  LDA #12
  SEC
  SBC UNIT_HEALTH
  STA TEMP_A    ;how many we need.
  LDA INV_MEDKIT  ;how many do we have?
  SEC
  SBC TEMP_A
  BCC UMK2
  ;we had more than we need, so go to full health.
  LDA #12
  STA UNIT_HEALTH
  LDA INV_MEDKIT
  SEC
  SBC TEMP_A
  STA INV_MEDKIT
  JMP UMK3
UMK2: ;we had less than we need, so we'll use what is available.
  LDA INV_MEDKIT
  CLC
  ADC UNIT_HEALTH
  STA UNIT_HEALTH
  LDA #0
  STA INV_MEDKIT
UMK3: JSR DISPLAY_PLAYER_HEALTH
  JSR DISPLAY_ITEM
  LDA #2    ;MEDKIT SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  LDA #<MSG_MUCHBET
  STA $FB
  LDA #>MSG_MUCHBET
  STA $FC
  JSR PRINT_INFO
  RTS

FIRE_UP:
  LDA SELECTED_WEAPON
  CMP #0
  BNE FRU0
  RTS
FRU0: CMP #1
  BNE FRU1
  JMP FIRE_UP_PISTOL
FRU1: JMP FIRE_UP_PLASMA

FIRE_UP_PISTOL:
  LDA AMMO_PISTOL
  CMP #0
  BNE FU00
  RTS
FU00: LDX #28
FU01: LDA UNIT_TYPE,X
  CMP #0
  BEQ FU02
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FU01
  RTS
FU02:
  LDA #12 ;Fire pistol up AI routine
  STA UNIT_TYPE,X
  LDA #SP_PISTOL_VERT  ;sprite for vertical weapons fire
  STA UNIT_TILE,X
  LDA #3    ;travel distance.
  STA UNIT_A,X
  LDA #0    ;weapon-type = pistol
  STA UNIT_B,X
  JMP AFTER_FIRE

FIRE_UP_PLASMA:
  LDA BIG_EXP_ACT
  CMP #1
  BEQ FUP3
  LDA PLASMA_ACT
  CMP #1
  BEQ FUP3
  LDA AMMO_PLASMA
  CMP #0
  BNE FUP0
FUP3: RTS
FUP0: LDX #28
FUP1: LDA UNIT_TYPE,X
  CMP #0
  BEQ FUP2
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FUP1
  RTS
FUP2: LDA #12 ;Fire pistol up AI routine
  STA UNIT_TYPE,X
  LDA #SP_PLASMA_UP  ;sprite for plasma bolt up
  STA UNIT_TILE,X
  LDA #3    ;travel distance.
  STA UNIT_A,X
  LDA #1    ;weapon-type = plasma
  STA UNIT_B,X
  STA PLASMA_ACT
  JMP AFTER_FIRE

FIRE_DOWN:
  LDA SELECTED_WEAPON
  CMP #0
  BNE FRD0
  RTS
FRD0: CMP #1
  BNE FRD1
  JMP FIRE_DOWN_PISTOL
FRD1: JMP FIRE_DOWN_PLASMA

FIRE_DOWN_PISTOL:
  LDA AMMO_PISTOL
  CMP #0
  BNE FD00
  RTS
FD00: LDX #28
FD01: LDA UNIT_TYPE,X
  CMP #0
  BEQ FD02
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FD01
  RTS
FD02: LDA #13 ;Fire pistol DOWN AI routine
  STA UNIT_TYPE,X
  LDA #SP_PISTOL_VERT  ;sprite for vertical weapons fire
  STA UNIT_TILE,X
  LDA #3    ;travel distance.
  STA UNIT_A,X
  LDA #0    ;weapon-type = pistol
  STA UNIT_B,X
  JMP AFTER_FIRE

FIRE_DOWN_PLASMA:
  LDA BIG_EXP_ACT
  CMP #1
  BEQ FDP3
  LDA PLASMA_ACT
  CMP #1
  BEQ FDP3
  LDA AMMO_PLASMA
  CMP #0
  BNE FDP0
FDP3: RTS
FDP0: LDX #28
FDP1: LDA UNIT_TYPE,X
  CMP #0
  BEQ FDP2
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FDP1
  RTS
FDP2: LDA #13 ;Fire pistol DOWN AI routine
  STA UNIT_TYPE,X
  LDA #SP_PLASMA_DOWN  ;sprite for plasma bolt down
  STA UNIT_TILE,X
  LDA #3    ;travel distance.
  STA UNIT_A,X
  LDA #1    ;weapon-type = plasma
  STA UNIT_B,X
  STA PLASMA_ACT
  JMP AFTER_FIRE

FIRE_LEFT:
  LDA SELECTED_WEAPON
  CMP #0
  BNE FRL0
  RTS
FRL0: CMP #1
  BNE FRL1
  JMP FIRE_LEFT_PISTOL
FRL1: JMP FIRE_LEFT_PLASMA

FIRE_LEFT_PISTOL:
  LDA AMMO_PISTOL
  CMP #0
  BNE FL00
  RTS
FL00: LDX #28
FL01: LDA UNIT_TYPE,X
  CMP #0
  BEQ FL02
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FL01
  RTS
FL02: LDA #14 ;Fire pistol LEFT AI routine
  STA UNIT_TYPE,X
  LDA #SP_PISTOL_HORZ  ;sprite for horizontal weapons fire
  STA UNIT_TILE,X
  LDA #5    ;travel distance.
  STA UNIT_A,X
  LDA #0    ;weapon-type = pistol
  STA UNIT_B,X
  JMP AFTER_FIRE

FIRE_LEFT_PLASMA:
  LDA BIG_EXP_ACT
  CMP #1
  BEQ FLP3
  LDA PLASMA_ACT
  CMP #1
  BEQ FLP3
  LDA AMMO_PLASMA
  CMP #0
  BNE FLP0
FLP3: RTS
FLP0: LDX #28
FLP1: LDA UNIT_TYPE,X
  CMP #0
  BEQ FLP2
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FLP1
  RTS
FLP2: LDA #14 ;Fire pistol LEFT AI routine
  STA UNIT_TYPE,X
  LDA #SP_PLASMA_LEFT  ;sprite for plasma bolt left
  STA UNIT_TILE,X
  LDA #5    ;travel distance.
  STA UNIT_A,X
  LDA #1    ;weapon-type = plasma
  STA UNIT_B,X
  STA PLASMA_ACT
  JMP AFTER_FIRE

FIRE_RIGHT:
  LDA SELECTED_WEAPON
  CMP #0
  BNE FRR0
  RTS
FRR0: CMP #1
  BNE FRR1
  JMP FIRE_RIGHT_PISTOL
FRR1: JMP FIRE_RIGHT_PLASMA

FIRE_RIGHT_PISTOL:
  LDA AMMO_PISTOL
  CMP #0
  BNE FR00
  RTS
FR00: LDX #28
FR01: LDA UNIT_TYPE,X
  CMP #0
  BEQ FR02
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FR01
  RTS
FR02: LDA #15 ;Fire pistol RIGHT AI routine
  STA UNIT_TYPE,X
  LDA #SP_PISTOL_HORZ  ;sprite for horizontal weapons fire
  STA UNIT_TILE,X
  LDA #5    ;travel distance.
  STA UNIT_A,X
  LDA #0    ;weapon-type = pistol
  STA UNIT_B,X
  JMP AFTER_FIRE

FIRE_RIGHT_PLASMA:
  LDA BIG_EXP_ACT
  CMP #1
  BEQ FRP3
  LDA PLASMA_ACT
  CMP #1
  BEQ FRP3
  LDA AMMO_PLASMA
  CMP #0
  BNE FRP0
FRP3: RTS
FRP0: LDX #28
FRP1: LDA UNIT_TYPE,X
  CMP #0
  BEQ FRP2
  INX
  CPX #32 ;max unit for weaponsfire
  BNE FRP1
  RTS
FRP2: LDA #15 ;Fire pistol RIGHT AI routine
  STA UNIT_TYPE,X
  LDA #SP_PLASMA_RIGHT  ;sprite for plasma bolt right
  STA UNIT_TILE,X
  LDA #5    ;travel distance.
  STA UNIT_A,X
  LDA #1    ;weapon-type = plasma
  STA UNIT_B,X
  STA PLASMA_ACT
  JMP AFTER_FIRE

AFTER_FIRE:
  LDA #0
  STA UNIT_TIMER_A,X
  LDA UNIT_LOC_X
  STA UNIT_LOC_X,X
  LDA UNIT_LOC_Y
  STA UNIT_LOC_Y,X
  STX UNIT
  LDA SELECTED_WEAPON
  CMP #2
  BEQ AF01
  LDA #09   ;PISTOL-SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  DEC AMMO_PISTOL
  JSR DISPLAY_WEAPON
  RTS
AF01: LDA #08   ;PLASMA-GUN-SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  DEC AMMO_PLASMA
  JSR DISPLAY_WEAPON
  RTS

KEY_REPEAT:
  LDA #16
  STA DELAY ;reset kernal repeat timer (to prevent repeats)
  LDA KEYTIMER
  CMP #0
  BNE KEYR2
  LDA LSTX
  CMP #NO_KEY_PRESSED ;no key pressed
  BEQ KEYR1
  LDA #NO_KEY_PRESSED ;clear LSTX register
  STA LSTX  ;clear LSTX register
  LDA #7
  STA KEYTIMER
  RTS
KEYR1:  ;No key pressed, reset all to defaults
  LDA #0
  STA KEY_FAST
  LDA #7
  STA KEYTIMER
KEYR2:  RTS

;This routine handles things that are in common to
;all 4 directions of movement.
AFTER_MOVE:
  LDA MOVE_RESULT
  CMP #1
  BNE AM01
  JSR ANIMATE_PLAYER
  JSR CALCULATE_AND_REDRAW
  JSR DISPLAY_PLAYER_SPRITE
AM01: ;now reset key-repeat rate
  LDA KEY_FAST
  CMP #0
  BNE KEYR3
  ;FIRST REPEAT
  LDA #15
  STA KEYTIMER
  INC KEY_FAST
KEYR4:  JMP MAIN_GAME_LOOP
KEYR3:  ;SUBSEQUENT REPEATS
  LDA #6
  STA KEYTIMER
  JMP MAIN_GAME_LOOP
KEY_FAST  !BYTE 0 ;0=DEFAULT STATE

;This routine is invoked when the user presses S to search
;an object such as a crate, chair, or plant.
SEARCH_OBJECT:
  LDA #SP_MAG_CURSOR
  STA CURSOR_SPRITE_NUMBER
  JSR USER_SELECT_OBJECT
  JSR DISPLAY_PLAYER_SPRITE
  LDA #1
  STA REDRAW_WINDOW
CHS1: ;first check of object is searchable
  JSR CALC_COORDINATES
  JSR GET_TILE_FROM_MAP
  LDX TILE
  LDA TILE_ATTRIB,X
  AND #%01000000  ;can search attribute
  CMP #%01000000
  BEQ CHS2
  LDA #0
  STA CURSOR_ON
  JMP CHS3
CHS2: ;is the tile a crate?
  LDX TILE
  CPX #041  ;BIG CRATE
  BEQ CHS2B
  CPX #045  ;small CRATE
  BEQ CHS2B
  CPX #199  ;"Pi" CRATE
  BEQ CHS2B
  JMP CHS2C
CHS2B:  LDA DESTRUCT_PATH,X
  STA TILE
  JSR PLOT_TILE_TO_MAP
CHS2C:  ;Now check if there is an object there.
  LDA #0
  STA SEARCHBAR
  LDA #<MSG_SEARCHING
  STA $FB
  LDA #>MSG_SEARCHING
  STA $FC
  JSR PRINT_INFO
SOBJ1:
  TYA
  PHA
  LDY SEARCHBAR
  LDA SEARCHDELTAX,Y
  STA CURSOR_JITTER_X
  LDA SEARCHDELTAY,Y
  STA CURSOR_JITTER_Y
  PLA
  TAY
  LDA #18 ;delay time between search periods
  STA BGTIMER2
SOBJ2:  JSR BACKGROUND_TASKS
  LDA BGTIMER2
  CMP #0
  BNE SOBJ2
  LDX SEARCHBAR
  +MC_PLOT_CHAR_X $03C9, 46 ; PERIOD
  INC SEARCHBAR
  LDA SEARCHBAR
  CMP #8
  BNE SOBJ1
  LDA #0
  STA CURSOR_ON
  JSR DRAW_MAP_WINDOW   ;ERASE THE CURSOR
  JSR CALC_COORDINATES
  JSR CHECK_FOR_HIDDEN_UNIT
  LDA UNIT_FIND
  CMP #255
  BNE SOBJ5
CHS3: LDA #<MSG_NOTFOUND
  STA $FB
  LDA #>MSG_NOTFOUND
  STA $FC
  JSR PRINT_INFO
  RTS
SOBJ5:  LDX UNIT_FIND
  LDA UNIT_TYPE,X
  STA TEMP_A    ;store object type
  LDA UNIT_A,X
  STA TEMP_B    ;store secondary info
  LDA #0  ;DELETE ITEM ONCE FOUND
  STA UNIT_TYPE,X
  ;***NOW PROCESS THE ITEM FOUND***
  LDA #10   ;ITEM-FOUND-SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  LDA TEMP_A
  CMP #128  ;key
  BEQ SOBJ10
  JMP SOBJ15
SOBJ10: LDA TEMP_B    ;WHICH SORT OF KEY?
  CMP #00
  BNE SOBJK1
  LDA KEYS
  ORA #%00000001  ;Add spade key
  STA KEYS
  JMP SOBJ12
SOBJK1: CMP #01
  BNE SOBJK2
  LDA KEYS
  ORA #%00000010  ;Add heart key
  STA KEYS
  JMP SOBJ12
SOBJK2: LDA KEYS
  ORA #%00000100  ;Add star key
  STA KEYS
SOBJ12: LDA #<MSG_FOUNDKEY
  STA $FB
  LDA #>MSG_FOUNDKEY
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_KEYS
  RTS
SOBJ15: CMP #129  ;TIME BOMB
  BNE SOBJ17
  LDA TEMP_B
  CLC
  ADC INV_BOMBS
  STA INV_BOMBS
  LDA #<MSG_FOUNDBOMB
  STA $FB
  LDA #>MSG_FOUNDBOMB
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_ITEM
  RTS
SOBJ17: CMP #130  ;EMP
  BNE SOBJ20
  LDA TEMP_B
  CLC
  ADC INV_EMP
  STA INV_EMP
  LDA #<MSG_FOUNDEMP
  STA $FB
  LDA #>MSG_FOUNDEMP
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_ITEM
  RTS
SOBJ20: CMP #131  ;PISTOL
  BNE SOBJ21
  LDA TEMP_B
  CLC
  ADC AMMO_PISTOL
  STA AMMO_PISTOL
  BCC SOBJ2A  ;If we rolled over past 255
  LDA #255  ;set it to 255.
  STA AMMO_PISTOL
SOBJ2A: LDA #<MSG_FOUNDGUN
  STA $FB
  LDA #>MSG_FOUNDGUN
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_WEAPON
SOBJ21: CMP #132  ;PLASMA GUN
  BNE SOBJ22
  LDA TEMP_B
  CLC
  ADC AMMO_PLASMA
  STA AMMO_PLASMA
  LDA #<MSG_FOUNDPLAS
  STA $FB
  LDA #>MSG_FOUNDPLAS
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_WEAPON
SOBJ22: CMP #133  ;MEDKIT
  BNE SOBJ23
  LDA TEMP_B
  CLC
  ADC INV_MEDKIT
  STA INV_MEDKIT
  LDA #<MSG_FOUNDMED
  STA $FB
  LDA #>MSG_FOUNDMED
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_ITEM
SOBJ23: CMP #134  ;MAGNET
  BNE SOBJ99
  LDA TEMP_B
  CLC
  ADC INV_MAGNET
  STA INV_MAGNET
  LDA #<MSG_FOUNDMAG
  STA $FB
  LDA #>MSG_FOUNDMAG
  STA $FC
  JSR PRINT_INFO
  JSR DISPLAY_ITEM
SOBJ99: ;ADD CODE HERE FOR OTHER OBJECT TYPES
  RTS
SEARCHBAR !BYTE 00  ;to count how many periods to display.
SEARCHDELTAX !BYTE $FC,$00,$04,$00,$FC,$00,$04,$00
SEARCHDELTAY !BYTE $00,$FC,$00,$04,$00,$FC,$00,$04

;combines cursor location with window location
;to determine coordinates for MAP_X and MAP_Y
CALC_COORDINATES:
  LDA CURSOR_X
  CLC
  ADC MAP_WINDOW_X
  STA MAP_X
  LDA CURSOR_Y
  CLC
  ADC MAP_WINDOW_Y
  STA MAP_Y
  RTS

;This routine is called by routines such as the move, search,
;or use commands.  It displays a cursor and allows the user
;to pick a direction of an object.
USER_SELECT_OBJECT:
  LDA #17   ;short beep sound
  JSR PLAY_SOUND  ;SOUND PLAY
  LDA #5
  STA CURSOR_X
  LDA #3
  STA CURSOR_Y
; LDA #SP_MAG_CURSOR
; STA CURSOR_SPRITE_NUMBER
  LDA #1
  STA CURSOR_ON
  JSR DISPLAY_CURSOR
  ;First ask user which object to move
MV01: JSR BACKGROUND_TASKS
  LDA UNIT_TYPE
  CMP #0  ;Did player die wile moving something?
  BNE MVCONT
  LDA #0
  STA CURSOR_ON
  RTS
MVCONT: LDA CONTROL
  CMP #2
  BNE MV01A
!IF SHAREWARE = 0 {
  JMP MVSNES
}
MV01A: 
  JSR GET_KEY
MV02:
  CMP #$1D  ;CURSOR RIGHT
  BNE MV03
MV00R:
  INC CURSOR_X
  LDA #18
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  RTS
MV03:
  CMP #$9D  ;CURSOR LEFT
  BNE MV04
MV00L:
  DEC CURSOR_X
  LDA #12
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  RTS
MV04:
  CMP #$11  ;CURSOR DOWN
  BNE MV05
MV00D:
  INC CURSOR_Y
  LDA #6
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  RTS
MV05:
  CMP #$91  ;CURSOR UP
  BNE MV06
MV00U:
  DEC CURSOR_Y
  LDA #0
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  RTS
MV06:
  CMP KEY_MOVE_LEFT
  BNE MV07
  JMP MV00L
MV07:
  CMP KEY_MOVE_DOWN
  BNE MV08
  JMP MV00D
MV08:
  CMP KEY_MOVE_RIGHT
  BNE MV09
  JMP MV00R
MV09:
  CMP KEY_MOVE_UP
  BNE MV0A
  JMP MV00U
MV0A: JMP MV01

!IF SHAREWARE = 0 {

MVSNES: ;SNES controls for this routine
  JSR SNES_CONTROLER_READ
  LDA NEW_RIGHT
  CMP #1
  BNE MVS03
  INC CURSOR_X
  LDA #0
  STA NEW_RIGHT
  LDA #18
  STA PLAYER_DIRECTION
  RTS
MVS03:  LDA NEW_LEFT
  CMP #1
  BNE MVS04
  DEC CURSOR_X
  LDA #0
  STA NEW_LEFT
  LDA #12
  STA PLAYER_DIRECTION
  RTS
MVS04:  LDA NEW_DOWN
  CMP #1
  BNE MVS05
  INC CURSOR_Y
  LDA #0
  STA NEW_DOWN
  LDA #6
  STA PLAYER_DIRECTION
  RTS
MVS05:  LDA NEW_UP
  CMP #1
  BNE MVS06
  DEC CURSOR_Y
  LDA #0
  STA NEW_UP
  LDA #0
  STA PLAYER_DIRECTION
  RTS
MVS06:  JMP MV01

}

MOVE_OBJECT:
  LDA #SP_SOLID_HAND
  STA CURSOR_SPRITE_NUMBER
  JSR USER_SELECT_OBJECT
  JSR DISPLAY_PLAYER_SPRITE
  LDA UNIT
  ;now test that object to see if it
  ;is allowed to be moved.
MV10: 
  LDA #0
  STA CURSOR_ON
  JSR DISPLAY_CURSOR
  JSR CALC_COORDINATES
  JSR CHECK_FOR_HIDDEN_UNIT
  LDA UNIT_FIND
  STA MOVTEMP_U
  JSR GET_TILE_FROM_MAP
  LDA TILE
  TAY
  LDA TILE_ATTRIB,Y
  AND #%00000100    ;can it be moved?
  CMP #%00000100
  BEQ MV11
  LDA #<MSG_CANTMOVE
  STA $FB
  LDA #>MSG_CANTMOVE
  STA $FC
  JSR PRINT_INFO
  LDA #11   ;ERROR SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  RTS
MV11: LDA TILE
  STA MOVTEMP_O ;Store which tile it is we are moving
  LDA MAP_X
  STA MOVTEMP_X ;Store original location of object
  LDA MAP_Y
  STA MOVTEMP_Y
  LDA #SP_SOLID_HAND
  STA CURSOR_SPRITE_NUMBER
  LDA #1
  STA CURSOR_ON
  JSR DISPLAY_CURSOR
  LDA #17   ;beep sound
  JSR PLAY_SOUND  ;SOUND PLAY
  ;NOW ASK THE USER WHICH DIRECTION TO MOVE IT TO
MV15: JSR BACKGROUND_TASKS
  LDA UNIT_TYPE
  CMP #0  ;Did player die wile moving something?
  BNE MVCONT2
  LDA #0
  STA CURSOR_ON
  RTS
MVCONT2:  ;which controller are we using?
  LDA CONTROL
  CMP #2
  BNE MV15B
!IF SHAREWARE = 0 {
  JMP SMV30
}

MV15B:  ;keyboard control
  JSR GET_KEY
  CMP #$00
  BEQ MV15
MV16: CMP #$1D  ;CURSOR RIGHT
  BNE MV17
  INC CURSOR_X
  JMP MV25
MV17: CMP #$9D  ;CURSOR LEFT
  BNE MV18
  DEC CURSOR_X
  JMP MV25
MV18: CMP #$11  ;CURSOR DOWN
  BNE MV19
  INC CURSOR_Y
  JMP MV25
MV19: CMP #$91  ;CURSOR UP
  BNE MV20
  DEC CURSOR_Y
  JMP MV25
MV20: CMP KEY_MOVE_LEFT
  BNE MV2A
  DEC CURSOR_X
  JMP MV25
MV2A: CMP KEY_MOVE_DOWN
  BNE MV2B
  INC CURSOR_Y
  JMP MV25
MV2B: CMP KEY_MOVE_RIGHT
  BNE MV2C
  INC CURSOR_X
  JMP MV25
MV2C: CMP KEY_MOVE_UP
  BNE MV2D
  DEC CURSOR_Y
  JMP MV25
MV2D: JMP MV15

!IF SHAREWARE = 0 {

SMV30:  ;SNES controls
  JSR SNES_CONTROLER_READ
  LDA NEW_RIGHT
  CMP #1
  BNE SMV31
  INC CURSOR_X
  LDA #0
  STA NEW_RIGHT
  JMP MV25
SMV31:  LDA NEW_LEFT
  CMP #1
  BNE SMV32
  DEC CURSOR_X
  LDA #0
  STA NEW_LEFT
  JMP MV25
SMV32:  LDA NEW_DOWN
  CMP #1
  BNE SMV33
  INC CURSOR_Y
  LDA #0
  STA NEW_DOWN
  JMP MV25
SMV33:  LDA NEW_UP
  CMP #1
  BNE SMV34
  DEC CURSOR_Y
  LDA #0
  STA NEW_UP
  JMP MV25
SMV34:  JMP MV15

}

  ;NOW TEST TO SEE IF THAT SPOT IS OPEN
MV25: LDA #0
  STA CURSOR_ON
  JSR DRAW_MAP_WINDOW   ;ERASE THE CURSOR
  LDA CURSOR_X
  CLC
  ADC MAP_WINDOW_X
  STA MAP_X
  STA MOVTEMP_UX
  LDA CURSOR_Y
  CLC
  ADC MAP_WINDOW_Y
  STA MAP_Y
  STA MOVTEMP_UY
  JSR GET_TILE_FROM_MAP
  LDA TILE
  TAY
  LDA TILE_ATTRIB,Y
  AND #%00100000    ;is that spot available
  CMP #%00100000    ;for something to move onto it?
  BEQ MV30
  JMP MV3A        ;If not, then exit routine.
MV30: ;Now scan for any units at that location:
  JSR CHECK_FOR_UNIT
  LDA UNIT_FIND
  CMP #255      ;255 means no unit found.
  BEQ MV31
MV3A: LDA #<MSG_BLOCKED
  STA $FB
  LDA #>MSG_BLOCKED
  STA $FC
  JSR PRINT_INFO
  LDA #11   ;ERROR SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  RTS
MV31: LDA #6    ;move sound
  JSR PLAY_SOUND  ;SOUND PLAY
  LDY #0
  LDA ($FD),Y     ;Grab current object
  STA MOVTEMP_D
  LDA MOVTEMP_O
  STA ($FD),Y     ;replace with obect we are moving
  LDA MOVTEMP_X   ;RETRIEVE original location of object
  STA MAP_X
  LDA MOVTEMP_Y
  STA MAP_Y
  JSR GET_TILE_FROM_MAP
  LDA MOVTEMP_D
  CMP #148    ;trash compactor tile
  BNE MV31A
  LDA #09   ;Floor tile
MV31A:  STA ($FD),Y     ;Replace former location
  ;+VDC_MAP_CHANGED MOVTEMP_X, MOVTEMP_Y
  ;+VDC_MAP_CHANGED MOVTEMP_UX, MOVTEMP_UY
  LDA #1
  STA REDRAW_WINDOW   ;See the result
  LDA MOVTEMP_U
  CMP #255
  BNE MV32
  RTS
MV32: LDX MOVTEMP_U
  LDA MOVTEMP_UX
  STA UNIT_LOC_X,X
  LDA MOVTEMP_UY
  STA UNIT_LOC_Y,X
  RTS
MOVTEMP_O:  !BYTE 00  ;origin tile
MOVTEMP_D:  !BYTE 00  ;destination tile
MOVTEMP_X:  !BYTE 00  ;x-coordinate
MOVTEMP_Y:  !BYTE 00  ;y-coordinate
MOVTEMP_U:  !BYTE 00  ;unit number (255=none)
MOVTEMP_UX  !BYTE 00
MOVTEMP_UY  !BYTE 00
CALCULATE_AND_REDRAW:
  LDA UNIT_LOC_X  ;no index needed since it's player unit
  SEC
  SBC #5
  STA MAP_WINDOW_X
  LDA UNIT_LOC_Y  ;no index needed since it's player unit
  SEC
  SBC #3
  STA MAP_WINDOW_Y
  LDA #1
  STA REDRAW_WINDOW
  RTS

;This routine checks all units from 0 to 31 and figures out if it should be dislpayed
;on screen, and then grabs that unit's tile and stores it in the MAP_PRECALC array
;so that when the window is drawn, it does not have to search for units during the
;draw, speeding up the display routine.
MAP_PRE_CALCULATE:
  ;CLEAR OLD BUFFER
  LDA #0
  LDY #0
PREC0:  STA MAP_PRECALC,Y
  INY
  CPY #77
  BNE PREC0
  LDX #1  ;In this version, we don't draw the player here.
PREC1:  ;CHECK THAT UNIT EXISTS
  LDA UNIT_TYPE,X
  CMP #0
  BEQ PREC5
  ;CHECK HORIZONTAL POSITION
  LDA UNIT_LOC_X,X
  CMP MAP_WINDOW_X
  BCC PREC5
  LDA MAP_WINDOW_X
  CLC
  ADC #10
  CMP UNIT_LOC_X,X
  BCC PREC5
  ;NOW CHECK VERTICAL
  LDA UNIT_LOC_Y,X
  CMP MAP_WINDOW_Y
  BCC PREC5
  LDA MAP_WINDOW_Y
  CLC
  ADC #6
  CMP UNIT_LOC_Y,X
  BCC PREC5
  ;Unit found in map window, now add that unit's
  ;tile to the precalc map.
PREC2:  LDA UNIT_LOC_Y,X
  SEC
  SBC MAP_WINDOW_Y
  TAY
  LDA UNIT_LOC_X,X
  SEC
  SBC MAP_WINDOW_X
  CLC
  ADC PRECALC_ROWS,Y
  TAY
  LDA UNIT_TILE,X
  ;;; CMP #130  ;is it a bomb
  ;;; BEQ PREC6
  ;;; CMP #134  ;is it a magnet?
  ;;; BEQ PREC6
PREC4:  STA MAP_PRECALC,Y
PREC5:  ;continue search
  INX
  CPX #28 ; 128 uses sprites not tiles, so only check up to 28 here ; CPX #32
  BNE PREC1
  RTS
PREC6:  ;What to do in case of bomb or magnet that should
  ;go underneath the unit or robot.
  LDA MAP_PRECALC,Y
  CMP #0
  BNE PREC5
  LDA UNIT_TILE,X
  JMP PREC4

PRECALC_ROWS: !BYTE 0,11,22,33,44,55,66

;This routine is where the MAP is displayed on the screen
;This is a temporary routine, taken from the map editor.
DRAW_MAP_WINDOW:
  JSR DISPLAY_WEAPON_FIRE_SPRITES ; TODO: move this earlier?
  JSR MAP_PRE_CALCULATE
  LDA #0
  STA REDRAW_WINDOW
  STA TEMP_X
  STA TEMP_Y
  STA PRECALC_COUNT
DM01: ;FIRST CALCULATE WHERE THE BYTE IS STORED IN THE MAP
  LDY #0
  LDA TEMP_Y
  CLC
  ADC MAP_WINDOW_Y
  ROR
  PHP
  CLC
  ADC #>MAP
  STA $FE ;HIGH BYTE OF MAP SOURCE
  LDA #$0
  PLP
  ROR
  CLC
  ADC TEMP_X
  ADC MAP_WINDOW_X
  STA $FD ;LOW BYTE OF MAP SOURCE
  LDA ($FD),Y
  STA TILE
!IF VIC_CHARMAP {
  ;NOW FIGURE OUT WHERE TO PLACE IT ON SCREEN.
  LDX TEMP_Y
  LDA MAP_CHART_L,X
  STA $FB ;LOW BYTE OF SCREEN AREA
  LDA MAP_CHART_H,X
  STA $FC ;HIGH BYTE OF SCREEN AREA
  LDA TEMP_X
  ASL ;MULTIPLY BY 2
  CLC
  ADC TEMP_X  ;ADD ANOTHER TO MAKE X3
  ADC $FB
  STA $FB
  LDA $FC
  ADC #00 ;CARRY FLAG
  STA $FC
}
  ;now check for sprites in this location
  LDY PRECALC_COUNT
  LDA MAP_PRECALC,Y
  CMP #00
  BEQ DM02
  STA TILE
  LDX TEMP_Y
  LDA MAP_CHART_L,X
  STA $FB ;LOW BYTE OF SCREEN AREA
  LDA MAP_CHART_H,X
  STA $FC ;HIGH BYTE OF SCREEN AREA
  LDA TEMP_X
  ASL ;MULTIPLY BY 2
  CLC
  ADC TEMP_X  ;ADD ANOTHER TO MAKE X3
  ADC $FB
  STA $FB
  LDA $FC
  ADC #00 ;CARRY FLAG
  STA $FC
  ;;; JSR PLOT_TRANSPARENT_TILE
DM02:
  JSR PLOT_TILE
  INC TEMP_X
  INC PRECALC_COUNT
  LDA TEMP_X
  CMP #11
  BNE DM01
DM04: LDA #0
  STA TEMP_X
  INC TEMP_Y
  LDA TEMP_Y
  CMP #7
  BEQ DM10
  JMP DM01
DM10:
  JSR DISPLAY_CURSOR
  RTS

DISPLAY_WEAPON_FIRE_SPRITES
  LDA SPENA ; get all sprites enabled
  AND #$E1  ; disable sprites 1-4
  STA SPENA ; set all sprites enabled

  +STI MSIGX, 0 ; clear all most significant bits of sprite x
  +STI SPMC0, 0 ; sprite multicolor 0
  +STI SPMC1, 1 ; sprite multicolor 1

  +STI $FF, $01

  LDY #28 ; start of weapon fire related units

- ASL $FF
  STY TEMP_B ; yreg
  LDA UNIT_TYPE,Y
  BEQ +   ; not defined, skip it

  LDA UNIT_LOC_X,Y
  SEC
  SBC MAP_WINDOW_X
  BCC + ; if UNIT_X-WINDOW_X < 0, skip
  CMP #11
  BCS + ; if REL_X-11 >= 0, skip
  STA TEMP_X

  LDA UNIT_LOC_Y,Y
  SEC
  SBC MAP_WINDOW_Y
  BCC + ; if UNIT_Y-WINDOW_Y < 0, skip
  CMP #7
  BCS + ; if REL_Y-7 >= 0, skip
  STA TEMP_Y

  TYA
  SEC
  SBC #28 ; unit # - 28 is logical sprite number (phys sprite 1-4)
  STA TEMP_A ; xreg
  STY TEMP_B ; yreg
  LDA UNIT_TILE,Y
  STA TEMP_C ; pattern
  SEC
  SBC #(SPRITE_BEGIN_X+2)
  STA TEMP_D ; color index

  JSR DISPLAY_WEAPON_FIRE_SPRITES_HELPER

+ LDY TEMP_B
  INY
  CPY #32
  BNE -
  RTS

DISPLAY_WEAPON_FIRE_SPRITES_HELPER

  +STIW $FB, V_SP_X ; ($FB) -> V_SP_X

  LDX TEMP_A
  LDA R_SP_X_L,X
  STA $FD
  +STI $FE, $D0 ; ($FD) -> $D0xx

  LDY TEMP_X
  LDA ($FB),Y
  LDY #0
  STA ($FD),Y

  LDA TEMP_X
  CMP #10
  BNE +
  LDA MSIGX
  ORA $FF
  STA MSIGX

+ +STIW $FB, V_SP_Y ; ($FB) -> V_SP_Y

  LDX TEMP_A
  LDA R_SP_Y_L,X
  STA $FD

  LDY TEMP_Y
  LDA ($FB),Y
  LDY #0
  STA ($FD),Y

  +STIW $FB, V_SP_C ; ($FB) -> V_SP_C

  LDX TEMP_A
  LDA R_SP_C_L,X
  STA $FD

  LDY TEMP_D
  LDA ($FB),Y
  LDY #0
  STA ($FD),Y

  LDX TEMP_A
  LDA R_SP_N_L,X
  STA $FD
  +STI $FE, 3+>(ADDR_COLOR12) ; ($FD) -> $E3xx

  LDA TEMP_C
  LDY #0
  STA ($FD),Y

  LDX TEMP_A
  LDA SPENA
  ORA V_SP_EN_1,X
  STA SPENA

  RTS

R_SP_X_L: !BYTE $02, $04, $06, $08 ; SP_X_H is always $D0
R_SP_Y_L: !BYTE $03, $05, $07, $09 ; SP_Y_H is always $D0
R_SP_C_L: !BYTE $28, $29, $2A, $2B ; SP_C_H is always $D0
R_SP_N_L: !BYTE $F9, $FA, $FB, $FC ; SP_N_H is always >(ADDR_COLOR12)

V_SP_X: !BYTE 24, 48, 72,  96, 120, 144, 168, 192, 216, 240, 264-256
V_SP_Y: !BYTE 50, 74, 98, 122, 146, 170, 194
V_SP_C: !BYTE 0,  0,  8,  8,  8,   8,  11,   2
V_SP_EN_1: !BYTE $02, $04, $08, $10
;;; V_SP_EN_0: !BYTE $FD, $FB, $F7, $EF

;$92 = $E480  PISTOL_HORZ   AI UNIT_TYPE 14/15
;$93 = $E4C0  PISTOL_VERT   AI UNIT_TYPE 12/13
;$94 = $E500  PLASMA_LEFT   AI UNIT_TYPE 14
;$95 = $E540  PLASMA_RIGHT  AI UNIT_TYPE 15
;$96 = $E580  PLASMA_DOWN   AI UNIT_TYPE 13
;$97 = $E5C0  PLASMA_UP     AI UNIT_TYPE 12
;$98 = $E600  BOMB          AI UNIT_TYPE  6
;$99 = $E640  MAGNET        AI UNIT_TYPE 20

DISPLAY_CURSOR:
  LDA CURSOR_ON
  CMP #1
  BEQ CRSR1
  LDA #0
  STA CURSOR_JITTER_X
  STA CURSOR_JITTER_Y
  LDA #SP_MAG_CURSOR
  STA CURSOR_SPRITE_NUMBER
  LDA SPENA
  AND #%11111110
  STA SPENA ;DISABLE SPRITE 0
  RTS
CRSR1:  ;CURSOR IS ON
  LDA YXPAND
; ORA #%00000001
  AND #%11111110
  STA YXPAND  ;SPRITE Y-EXPANSION OFF
; LDA   #SP_MAG_CURSOR  ;USE SPRITE DEF #1

  LDA CURSOR_SPRITE_NUMBER
  STA SPRITE_POINTER_0

  LDA SPENA
  ORA #%00000001
  STA SPENA ;ENABLE SPRITE
  LDY CURSOR_Y
  LDA SPRITE_CHART_Y,Y
  CLC
  ADC CURSOR_JITTER_Y
  STA SP0Y  ;SPRITE 0 Y-POSTITION
  LDY CURSOR_X
  LDA SPRITE_CHART_XL,Y
  CLC
  ADC CURSOR_JITTER_X
  STA SP0X  ;SPRITE 0 X-POSTITION
  RTS
CURSOR_JITTER_X !BYTE 0
CURSOR_JITTER_Y !BYTE 0
CURSOR_SPRITE_NUMBER !BYTE SP_MAG_CURSOR

;The following tables have pre-calculated positions
;for the sprite that is used to plot things on the map.

SPRITE_CHART_XL:
  !BYTE 24,48,72,96,120,144,168,192,216,240,10
SPRITE_CHART_XH:
  !BYTE 0,0,0,0,0,0,0,0,0,0,1

SPRITE_CHART_Y:
  !BYTE 50,74,98,122,146,170,194

;This routine checks to see if UNIT is occupying any space
;that is currently visible in the window.  If so, the
;flag for redrawing the window will be set.
CHECK_FOR_WINDOW_REDRAW:
  LDX UNIT
  ;FIRST CHECK HORIZONTAL
  LDA UNIT_LOC_X,X
  CMP MAP_WINDOW_X
  BCC CFR1
  LDA MAP_WINDOW_X
  CLC
  ADC #10
  CMP UNIT_LOC_X,X
  BCC CFR1
  ;NOW CHECK VERTICAL
  LDA UNIT_LOC_Y,X
  CMP MAP_WINDOW_Y
  BCC CFR1
  LDA MAP_WINDOW_Y
  CLC
  ADC #6
  CMP UNIT_LOC_Y,X
  BCC CFR1
  LDA #1
  STA REDRAW_WINDOW
CFR1: RTS

DECWRITE:
  LDA #$00
  STA SCREENPOS
  LDA DECNUM
  LDX   #2
  LDY   #$4C
DEC1
  STY   DECB
  LSR
DEC2
  ROL
  BCS   DEC3
  CMP DECA,X
  BCC   DEC4
DEC3
  SBC   DECA,X
  SEC
DEC4
  ROL   DECB
  BCC   DEC2
  STA DECTEMP
  LDA   DECB
  LDY SCREENPOS
  +MC_PLOT_CHAR_Y
  INC SCREENPOS
  LDA DECTEMP
  LDY   #$13
  DEX
  BPL   DEC1
  RTS
DECA    !BYTE   128,160,200
DECB    !BYTE   1
SCREENPOS !BYTE $00
DECTEMP   !BYTE $00

; The following routine loads the map from disk
MAP_LOAD_ROUTINE:
  +LDVFILE MAPNAME, 11, ADDR_MAPVARS, SIZE_MAPVARS
  RTS

;Displays loading message for map.
DISPLAY_LOAD_MESSAGE2:
  LDY #0
DLM2: LDA LOAD_MSG2,Y
  +MC_PLOT_CHAR_Y $0190
  INY
  CPY #12
  BNE DLM2
  JSR CALC_MAP_NAME
DLM3: LDA ($FB),Y
  +MC_PLOT_CHAR_Y $019C
  INY
  CPY #16
  BNE DLM3
  RTS
LOAD_MSG2:  !SCR"loading map:"

DISPLAY_MAP_DISK_MESSAGE:
  LDY #0
- LDA LOAD_MDM,Y
  +MC_PLOT_CHAR_Y $0190
  INY
  CPY #29
  BNE -

- JSR GET_KEY
  BEQ -

  LDY #0
  LDA #$20
- +MC_PLOT_CHAR_Y $0190
  INY
  CPY #29
  BNE -

  RTS
LOAD_MDM:  !SCR"insert map disk and hit a key"

GREEN_SCREEN:
CS02:
  LDX #$00
CS03:
  LDA #5 ; GREEN
  STA COLOR_MEMORY+$0000,X
  STA COLOR_MEMORY+$0100,X
  STA COLOR_MEMORY+$0200,X
  LDA #$DE
  STA SCREEN_MEMORY+$0000,X
  STA SCREEN_MEMORY+$0100,X
  STA SCREEN_MEMORY+$0200,X
  INX
  CPX #$00
  BNE CS03
CS04:
  LDA #5 ; GREEN
  STA COLOR_MEMORY+$0300,X
  LDA #$DE
  STA SCREEN_MEMORY+$0300,X
  INX
  CPX #$E8
  BNE CS04
  RTS

FILL_MEMORY:


RESET_KEYS_AMMO:
  LDA #$00
  STA KEYS
  STA AMMO_PISTOL
  STA AMMO_PLASMA
  STA INV_BOMBS
  STA INV_EMP
  STA INV_MEDKIT
  STA INV_MAGNET
  STA SELECTED_WEAPON
  STA SELECTED_ITEM
  STA MAGNET_ACT
  STA PLASMA_ACT
  STA BIG_EXP_ACT
  STA CYCLES
  STA SECONDS
  STA MINUTES
  STA HOURS
  RTS

!IF VIC_CHARMAP {
DISPLAY_PLAYER_HEALTH:
  LDA UNIT_HEALTH ;No index needed because it is the player
  LSR     ;divide by two
  STA TEMP_A
  LDY #00
DPH01:  CPY TEMP_A
  BEQ DPH02
  +PLOT_CHAR_Y $03BA, $66    ;GRAY BLOCK
  INY
  JMP DPH01
DPH02:  LDA UNIT_HEALTH
  AND #%00000001
  CMP #%00000001
  BNE DPH03
  +PLOT_CHAR_Y $03BA, $5C    ;HALF GRAY BLOCK
  INY
DPH03:  CPY #6
  BEQ DPH04
  +PLOT_CHAR_Y $03BA, $20    ;SPACE
  INY
  JMP DPH03
DPH04:  RTS
}

!IF VIC_BITMAP {

DISPLAY_PLAYER_HEALTH:
  LDY UNIT_HEALTH ;No index needed because it is the player
  LDX FACES_SEL,Y

  PHP
  SEI
  ;+BEGIN_IMAGE REU_ADDR_MCITEMS+420*0, 16*40+34, 6
  LDA #<((16*40+34)*8+ADDR_BITMAP)
  STA REC_02
  LDA #>((16*40+34)*8+ADDR_BITMAP)
  STA REC_03
  LDA FACES_OFF_LO,X
  STA REC_04
  LDA FACES_OFF_HI,X
  STA REC_05
  LDA #1
  STA REC_06
  LDA #<(6*8)
  STA REC_07
  LDA #>(6*8)
  STA REC_08
  LDA #%10010001 ; fetch bytes
  STA REC_01
  +NEXT_IMAGE 17*40+34, 6
  +NEXT_IMAGE 18*40+34, 6
  +NEXT_IMAGE 19*40+34, 6
  +NEXT_IMAGE 20*40+34, 6
  +NEXT_IMAGE 21*40+34, 6
  +NEXT_IMAGE 22*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 16*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 17*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 18*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 19*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 20*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 21*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 22*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 16*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 17*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 18*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 19*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 20*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 21*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 22*40+34, 6
  PLP

  LDA UNIT_HEALTH ;No index needed because it is the player
  LSR     ;divide by two
  STA TEMP_A
  LDY #00
DPH01:
  CPY TEMP_A
  BEQ DPH02
  +MC_PLOT_CHAR_Y $03BA, $FE    ;GRAY BLOCK
  LDA #$98
  STA ADDR_COLOR12+$03BA,Y
  LDA #$01
  STA ADDR_COLOR3+$03BA,Y
  +MC_PLOT_CHAR_Y $03E2, $FF
  LDA #$98
  STA ADDR_COLOR12+$03E2,Y
  LDA #$01
  STA ADDR_COLOR3+$03E2,Y
  INY
  JMP DPH01
DPH02:
  LDA UNIT_HEALTH
  AND #%00000001
  CMP #%00000001
  BNE DPH03
  +MC_PLOT_CHAR_Y $03BA, $FD    ;HALF GRAY BLOCK
  LDA #$98
  STA ADDR_COLOR12+$03BA,Y
  LDA #$01
  STA ADDR_COLOR3+$03BA,Y
  +MC_PLOT_CHAR_Y $03E2, $FF
  LDA #$98
  STA ADDR_COLOR12+$03E2,Y
  LDA #$01
  STA ADDR_COLOR3+$03E2,Y
  INY
DPH03:
  CPY #6
  BEQ DPH04
  +MC_PLOT_CHAR_Y $03BA, $20    ;SPACE
  LDA #$98
  STA ADDR_COLOR12+$03BA,Y
  LDA #$01
  STA ADDR_COLOR3+$03BA,Y
  +MC_PLOT_CHAR_Y $03E2, $FF
  LDA #$98
  STA ADDR_COLOR12+$03E2,Y
  LDA #$01
  STA ADDR_COLOR3+$03E2,Y
  INY
  JMP DPH03
DPH04:
  RTS

FACES_BASE = $2600
FACES_SEL:      !BYTE 5,5,5,4,4,3,3,2,2,1,1,0,0

FACES_OFF_LO:   !BYTE <(420*0+FACES_BASE),<(420*1+FACES_BASE),<(420*2+FACES_BASE),<(420*3+FACES_BASE),<(420*4+FACES_BASE),<(420*5+FACES_BASE)
FACES_OFF_HI:   !BYTE >(420*0+FACES_BASE),>(420*1+FACES_BASE),>(420*2+FACES_BASE),>(420*3+FACES_BASE),>(420*4+FACES_BASE),>(420*5+FACES_BASE)
}

CYCLE_ITEM:
  LDA #13   ;CHANGE-ITEM-SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  LDA #20
  STA KEYTIMER
  INC SELECTED_ITEM
  LDA SELECTED_ITEM
  CMP #5
  BEQ CYIT1
  JMP DISPLAY_ITEM
CYIT1:  LDA #0
  STA SELECTED_ITEM
  JMP DISPLAY_ITEM

DISPLAY_ITEM:
  JSR PRESELECT_ITEM
DSIT00: LDA SELECTED_ITEM
  CMP #0  ;no items to show
  BNE DSIT01
  ;add routine to draw blank space
  RTS
DSIT01: CMP #5  ;number too high!
  BNE DSIT0A
  LDA #0
  STA SELECTED_ITEM
  RTS
DSIT0A: CMP #1  ;bomb
  BNE DSIT03
  LDA INV_BOMBS
  CMP #0  ;did we run out?
  BNE DSIT02
  INC SELECTED_ITEM
  JMP DSIT00
DSIT02: JSR DISPLAY_TIMEBOMB
  RTS
DSIT03: CMP #2  ;emp
  BNE DSIT05
  LDA INV_EMP
  CMP #0  ;did we run out?
  BNE DSIT04
  INC SELECTED_ITEM
  JMP DSIT00
DSIT04: JSR DISPLAY_EMP
  RTS
DSIT05: CMP #3  ;medkit
  BNE DSIT07
  LDA INV_MEDKIT
  CMP #0  ;did we run out?
  BNE DSIT06
  INC SELECTED_ITEM
  JMP DSIT00
DSIT06: JSR DISPLAY_MEDKIT
  RTS
DSIT07: CMP #4  ;magnet
  BNE DSIT09
  LDA INV_MAGNET
  CMP #0  ;did we run out?
  BNE DSIT08
  INC SELECTED_ITEM
  JMP DSIT09
DSIT08: JSR DISPLAY_MAGNET
  RTS
DSIT09: LDA #0
  STA SELECTED_ITEM
  JSR PRESELECT_ITEM
  JMP DISPLAY_ITEM

;This routine checks to see if currently selected
;item is zero.  And if it is, then it checks inventories
;of other items to decide which item to automatically
;select for the user.
PRESELECT_ITEM:
  LDA SELECTED_ITEM
  CMP #0    ;If item already selected, return
  BEQ PRSI01
  RTS
PRSI01: LDA INV_BOMBS
  CMP #0
  BEQ PRSI02
  LDA #1  ;BOMB
  STA SELECTED_ITEM
  RTS
PRSI02: LDA INV_EMP
  CMP #0
  BEQ PRSI03
  LDA #2  ;EMP
  STA SELECTED_ITEM
  RTS
PRSI03: LDA INV_MEDKIT
  CMP #0
  BEQ PRSI04
  LDA #3  ;MEDKIT
  STA SELECTED_ITEM
  RTS
PRSI04: LDA INV_MAGNET
  CMP #0
  BEQ PRSI05
  LDA #4  ;MAGNET
  STA SELECTED_ITEM
  RTS
PRSI05: ;Nothing found in inventory at this point, so set
  ;selected-item to zero.
  LDA #0  ;nothing in inventory
  STA SELECTED_ITEM
  JSR DISPLAY_BLANK_ITEM
  RTS

DISPLAY_TIMEBOMB:
!IF VIC_CHARMAP {
  LDA SPENA
  ORA #%00011000  ;enable sprites 3 & 4
  STA SPENA
  LDA SPMC
  AND #%11100111  ;sprite 3 and 4 are hi-res
  STA SPMC
  LDA #06 ;blue is primary color
  STA SP3COL  ;SPRITE COLOR 3
  LDA #07 ;yellow is primary color
  STA SP4COL  ;SPRITE COLOR 4
  LDA   #(SPRITE_BEGIN+$04)
  STA SPRITE_POINTER_3  ;SPRITE POINTER sprite #3
  LDA   #(SPRITE_BEGIN+$05)
  STA SPRITE_POINTER_4  ;SPRITE POINTER sprite #4
}
!IF VIC_BITMAP {
  PHP
  SEI
  +BEGIN_IMAGE REU_ADDR_MCITEMS+240*3, 6*40+34, 6
  +NEXT_IMAGE 7*40+34, 6
  +NEXT_IMAGE 8*40+34, 6
  +NEXT_IMAGE 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 9*40+34, 6
  PLP
}
  +DECWRITE POS_ITEM_QTY, INV_BOMBS
  RTS

DISPLAY_EMP:
!IF VIC_CHARMAP {
  LDA SPENA
  ORA #%00011000  ;enable sprites 3 & 4
  STA SPENA
  LDA SPMC
  AND #%11100111
  ORA #%00011000  ;sprite 3 & 4 are multicolor
  STA SPMC
  LDA #02 ;red is primary color
  STA SP3COL  ;SPRITE COLOR 3
  STA SP4COL  ;SPRITE COLOR 4
  LDA   #(SPRITE_BEGIN+$06)
  STA SPRITE_POINTER_3  ;SPRITE POINTER sprite #3
  LDA   #(SPRITE_BEGIN+$07)
  STA SPRITE_POINTER_4  ;SPRITE POINTER sprite #4
}
!IF VIC_BITMAP {
  PHP
  SEI
  +BEGIN_IMAGE REU_ADDR_MCITEMS+240*1, 6*40+34, 6
  +NEXT_IMAGE 7*40+34, 6
  +NEXT_IMAGE 8*40+34, 6
  +NEXT_IMAGE 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 9*40+34, 6
  PLP
}
  +DECWRITE POS_ITEM_QTY, INV_EMP
  RTS

DISPLAY_MEDKIT:
!IF VIC_CHARMAP {
  LDA SPENA
  ORA #%00011000  ;enable sprites 3 & 4
  STA SPENA
  LDA SPMC
  AND #%11100111
  ORA #%00011000  ;sprite 3 & 4 are multicolor
  STA SPMC
  LDA #02 ;red is primary color
  STA SP3COL  ;SPRITE COLOR 3
  STA SP4COL  ;SPRITE COLOR 4
  LDA   #(SPRITE_BEGIN+$02)
  STA SPRITE_POINTER_3  ;SPRITE POINTER sprite #3
  LDA   #(SPRITE_BEGIN+$03)
  STA SPRITE_POINTER_4  ;SPRITE POINTER sprite #4
}
!IF VIC_BITMAP {
  PHP
  SEI
  +BEGIN_IMAGE REU_ADDR_MCITEMS+240*0, 6*40+34, 6
  +NEXT_IMAGE 7*40+34, 6
  +NEXT_IMAGE 8*40+34, 6
  +NEXT_IMAGE 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 9*40+34, 6
  PLP
}
  +DECWRITE POS_ITEM_QTY, INV_MEDKIT
  RTS

DISPLAY_MAGNET:
!IF VIC_CHARMAP {
  LDA SPENA
  ORA #%00011000  ;enable sprites 3 & 4
  STA SPENA
  LDA SPMC
  AND #%11100111
  ORA #%00011000  ;sprite 3 & 4 are multicolor
  STA SPMC
  LDA #02 ;red is primary color
  STA SP3COL  ;SPRITE COLOR 3
  STA SP4COL  ;SPRITE COLOR 4
  LDA   #(SPRITE_BEGIN+$08)
  STA SPRITE_POINTER_3  ;SPRITE POINTER sprite #3
  LDA   #(SPRITE_BEGIN+$09)
  STA SPRITE_POINTER_4  ;SPRITE POINTER sprite #4
}
!IF VIC_BITMAP {
  PHP
  SEI
  +BEGIN_IMAGE REU_ADDR_MCITEMS+240*2, 6*40+34, 6
  +NEXT_IMAGE 7*40+34, 6
  +NEXT_IMAGE 8*40+34, 6
  +NEXT_IMAGE 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 9*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 6*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 7*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 8*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 9*40+34, 6
  PLP
}
  +DECWRITE POS_ITEM_QTY, INV_MAGNET
  RTS

DISPLAY_BLANK_ITEM:
!IF VIC_CHARMAP {
  LDA SPENA
  AND #%11100111  ;disable sprites 3 & 4
  STA SPENA
  ;Clear numbers
  LDA #32
  +PLOT_CHAR $0205
  +PLOT_CHAR $0206
  +PLOT_CHAR $0207
}
!IF VIC_BITMAP {
  +ERASE_6  6*40+34
  +ERASE_6  7*40+34
  +ERASE_6  8*40+34
  +ERASE_6  9*40+34
  +ERASE_6 10*40+34
}
  RTS

CYCLE_WEAPON:
  LDA #12   ;CHANGE WEAPON-SOUND
  JSR PLAY_SOUND  ;SOUND PLAY
  LDA #20
  STA KEYTIMER
  INC SELECTED_WEAPON
  LDA SELECTED_WEAPON
  CMP #2
  BNE CYWE1
  JMP DISPLAY_WEAPON
CYWE1:  LDA #0
  STA SELECTED_WEAPON
  JMP DISPLAY_WEAPON

DISPLAY_WEAPON:
  JSR PRESELECT_WEAPON
  LDA SELECTED_WEAPON
  CMP #0  ;no weapon to show
  BNE DSWP01
  ;add routine to draw blank space
  JSR DISPLAY_BLANK_WEAPON
  RTS
DSWP01: CMP #1  ;PISTOL
  BNE DSWP03
  LDA AMMO_PISTOL
  CMP #0  ;did we run out?
  BNE DSWP02
  LDA #0
  STA SELECTED_WEAPON
  JMP DISPLAY_WEAPON
DSWP02: JSR DISPLAY_PISTOL
  RTS
DSWP03: CMP #2  ;PLASMA GUN
  BNE DSWP05
  LDA AMMO_PLASMA
  CMP #0  ;did we run out?
  BNE DSWP04
  LDA #0
  STA SELECTED_WEAPON
  JMP DISPLAY_WEAPON
DSWP04: JSR DISPLAY_PLASMA_GUN
  RTS
DSWP05: LDA #0
  STA SELECTED_WEAPON ;should never happen
  JMP DISPLAY_WEAPON

;This routine checks to see if currently selected
;weapon is zero.  And if it is, then it checks inventories
;of other weapons to decide which item to automatically
;select for the user.
PRESELECT_WEAPON:
  LDA SELECTED_WEAPON
  CMP #0    ;If item already selected, return
  BEQ PRSW01
  RTS
PRSW01: LDA AMMO_PISTOL
  CMP #0
  BEQ PRSW02
  LDA #1  ;PISTOL
  STA SELECTED_WEAPON
  RTS
PRSW02: LDA AMMO_PLASMA
  CMP #0
  BEQ PRSW04
  LDA #2  ;PLASMAGUN
  STA SELECTED_WEAPON
  RTS
PRSW04: ;Nothing found in inventory at this point, so set
  ;selected-item to zero.
  LDA #0  ;nothing in inventory
  STA SELECTED_WEAPON
  JSR DISPLAY_BLANK_WEAPON
  RTS

DISPLAY_PLASMA_GUN:
!IF VIC_CHARMAP {
  LDA SPENA
  ORA #%00000110  ;enable sprites 1 & 2
  STA SPENA
  LDA SPMC
  AND #%11111001
  ORA #%00000110  ;sprite 1 & 2 are multicolor
  STA SPMC
  LDA #06 ;BLUE is primary color
  STA SP1COL  ;SPRITE COLOR 1
  STA SP2COL  ;SPRITE COLOR 2
  LDA   #(SPRITE_BEGIN+$0C)
  STA SPRITE_POINTER_1  ;SPRITE POINTER sprite #1
  LDA   #(SPRITE_BEGIN+$0D)
  STA SPRITE_POINTER_2  ;SPRITE POINTER sprite #2
}
!IF VIC_BITMAP {
  PHP
  SEI
  +BEGIN_IMAGE REU_ADDR_MCWEAPONS+180*1, 1*40+34, 6
  +NEXT_IMAGE 2*40+34, 6
  +NEXT_IMAGE 3*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 1*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 2*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 3*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 1*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 2*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 3*40+34, 6
  PLP
}
  +DECWRITE POS_WEAPON_QTY, AMMO_PLASMA
  RTS

DISPLAY_PISTOL:
!IF VIC_CHARMAP {
  LDA SPENA
  ORA #%00000110  ;enable sprites 1 & 2
  STA SPENA
  LDA SPMC
  AND #%11111001
  ORA #%00000100  ;sprite 1=hires, 2=multicolor
  STA SPMC
  LDA #14 ;light blue is primary color
  STA SP1COL  ;SPRITE COLOR 1
  STA SP2COL  ;SPRITE COLOR 2
  LDA   #(SPRITE_BEGIN+$0A)
  STA SPRITE_POINTER_1  ;SPRITE POINTER sprite #1
  LDA   #(SPRITE_BEGIN+$0B)
  STA SPRITE_POINTER_2  ;SPRITE POINTER sprite #2
}
!IF VIC_BITMAP {
  PHP
  SEI
  +BEGIN_IMAGE REU_ADDR_MCWEAPONS+180*0, 1*40+34, 6
  +NEXT_IMAGE 2*40+34, 6
  +NEXT_IMAGE 3*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 1*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 2*40+34, 6
  +NEXT_COLOR ADDR_COLOR12, 3*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 1*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 2*40+34, 6
  +NEXT_COLOR ADDR_COLOR3, 3*40+34, 6
  PLP
}
  +DECWRITE POS_WEAPON_QTY, AMMO_PISTOL
  RTS

DISPLAY_BLANK_WEAPON:
!IF VIC_CHARMAP {
  LDA SPENA
  AND #%11111001  ;disable sprites 1 & 2
  STA SPENA

  ;now clear numbers.
  LDA #32
  +PLOT_CHAR POS_WEAPON_QTY+0
  +PLOT_CHAR POS_WEAPON_QTY+1
  +PLOT_CHAR POS_WEAPON_QTY+2
}
!IF VIC_BITMAP {
  +ERASE_6 1*40+34
  +ERASE_6 2*40+34
  +ERASE_6 3*40+34
  +ERASE_6 4*40+34
}
  RTS

DISPLAY_KEYS:
!IF VIC_CHARMAP {
  LDA #32
  +PLOT_CHAR $027A ; ERASE ALL 3 SPOTS
  +PLOT_CHAR $027B
  +PLOT_CHAR $027C
  +PLOT_CHAR $027D
  +PLOT_CHAR $027E
  +PLOT_CHAR $027F
  +PLOT_CHAR $02A2
  +PLOT_CHAR $02A3
  +PLOT_CHAR $02A4
  +PLOT_CHAR $02A5
  +PLOT_CHAR $02A6
  +PLOT_CHAR $02A7
  LDA KEYS
  AND #%00000001
  CMP #%00000001  ;Spade key
  BNE DKS1
  +PLOT_CHAR $027A, $63
  +PLOT_CHAR $027B, $4D
  +PLOT_CHAR $02A2, $41
  +PLOT_CHAR $02A3, $67
DKS1: LDA KEYS
  AND #%00000010
  CMP #%00000010  ;heart key
  BNE DKS2
  +PLOT_CHAR $027C, $63
  +PLOT_CHAR $027D, $4D
  +PLOT_CHAR $02A4, $53
  +PLOT_CHAR $02A5, $67
DKS2: LDA KEYS
  AND #%00000100
  CMP #%00000100  ;star key
  BNE DKS3
  +PLOT_CHAR $027E, $63
  +PLOT_CHAR $027F, $4D
  +PLOT_CHAR $02A6, $2A
  +PLOT_CHAR $02A7, $67
}
!IF VIC_BITMAP {
  LDA #32
  LDY #0
- +MC_PLOT_CHAR_Y $0202 ; ERASE ALL 3 SPOTS
  +MC_PLOT_CHAR_Y $022A
  +MC_PLOT_CHAR_Y $0252
  INY
  CPY #6
  BNE -
  LDA KEYS
  AND #%00000001
  CMP #%00000001  ;Spade key
  BEQ +
  JMP DKS1
+ +MC_PLOT_CHAR $0202, $EB
  +MC_PLOT_CHAR $0203, $EC
  +MC_PLOT_CHAR $022A, $ED
  +MC_PLOT_CHAR $022B, $EE
  +MC_PLOT_CHAR $0252, $EF
  +MC_PLOT_CHAR $0253, $F0
  LDA #$A2
  STA ADDR_COLOR12+$0202
  STA ADDR_COLOR12+$0203
  STA ADDR_COLOR12+$022A
  STA ADDR_COLOR12+$022B
  STA ADDR_COLOR12+$0252
  STA ADDR_COLOR12+$0253
DKS1: LDA KEYS
  AND #%00000010
  CMP #%00000010  ;heart key
  BEQ +
  JMP DKS2
+ +MC_PLOT_CHAR $0204, $F1
  +MC_PLOT_CHAR $0205, $F2
  +MC_PLOT_CHAR $022C, $F3
  +MC_PLOT_CHAR $022D, $F4
  +MC_PLOT_CHAR $0254, $F5
  +MC_PLOT_CHAR $0255, $F6
  LDA #$D5
  STA ADDR_COLOR12+$0204
  STA ADDR_COLOR12+$0205
  STA ADDR_COLOR12+$022C
  STA ADDR_COLOR12+$022D
  STA ADDR_COLOR12+$0254
  STA ADDR_COLOR12+$0255
DKS2: LDA KEYS
  AND #%00000100
  CMP #%00000100  ;star key
  BEQ +
  JMP DKS3
+ +MC_PLOT_CHAR $0206, $F7
  +MC_PLOT_CHAR $0207, $F8
  +MC_PLOT_CHAR $022E, $F9
  +MC_PLOT_CHAR $022F, $FA
  +MC_PLOT_CHAR $0256, $FB
  +MC_PLOT_CHAR $0257, $FC
  LDA #$E6
  STA ADDR_COLOR12+$0206
  STA ADDR_COLOR12+$0207
  STA ADDR_COLOR12+$022E
  STA ADDR_COLOR12+$022F
  STA ADDR_COLOR12+$0256
  STA ADDR_COLOR12+$0257
}
DKS3: RTS

GAME_OVER:
  ;stop game clock
  LDA #0
  STA CLOCK_ACTIVE
  ;Did player die or win?
  LDA UNIT_TYPE
  CMP #0
  BNE GOM0
  LDA #111  ;dead player tile
  STA UNIT_TILE
  JSR DISPLAY_PLAYER_SPRITE
  LDA #100
  STA KEYTIMER
GOM0: JSR BACKGROUND_TASKS
  LDA KEYTIMER
  CMP #0
  BNE GOM0
  ;stop screen shake
  LDA #0
  STA SCREEN_SHAKE
  ;turn off character sprite
  LDA SPENA
  AND #%00011111
  STA SPENA
  ;display game over message
  LDX #0
GOM1: LDA GAMEOVER1,X
  +MC_PLOT_CHAR_X $0173
  LDA GAMEOVER2,X
  +MC_PLOT_CHAR_X $019B
  LDA GAMEOVER3,X
  +MC_PLOT_CHAR_X $01C3
GOM1A:  INX
  CPX #11
  BNE GOM1
  LDA #100
  STA KEYTIMER
GOM2: JSR ANIMATE_GAMEOVER
  LDA KEYTIMER
  CMP #0
  BNE GOM2
  LDA #0
  STA NDX ;CLEAR KEYBOARD BUFFER
  JSR CLEAR_SNES_PAD
GOM3: JSR ANIMATE_GAMEOVER
	JSR	SNES_CONTROLER_READ
	LDA	NEW_B
	CMP	#1
	BEQ	GOM4
  JSR GETIN
  CMP #$00
  BEQ GOM3
GOM4: LDA #0
  STA NDX ;CLEAR KEYBOARD BUFFER
  JSR CLEAR_SNES_PAD
  ;LDA  #15   ;menu beep
  ;JSR  PLAY_SOUND  ;SOUND PLAY
  JSR DISPLAY_ENDGAME_SCREEN
  JSR PLAY_GAME_OVER_MUSIC
  JSR DISPLAY_WIN_LOSE
  ;turn off all sprites
  LDA #%00000000
  STA SPENA
  ;Wait for keypress
GOM5: JSR	SNES_CONTROLER_READ
	LDA	NEW_B
	CMP	#1
	BEQ	GOM6
  JSR GETIN
  CMP #$00
  BEQ GOM5
  LDA #0
  STA NDX ; WAS $009E BUT PERHAPS TYPO  ;CLEAR KEYBOARD BUFFER
GOM6: JMP INTRO_SCREEN

ANIMATE_GAMEOVER:
  LDX #0
  LDA SP0COL  ;CURSOR SPRITE COLOR
ANGO:
  STA COLOR_MEMORY+$0173,X
  STA COLOR_MEMORY+$019B,X
  STA COLOR_MEMORY+$01C3,X
  STA SCREEN_MEMORY+$0173,X
  STA SCREEN_MEMORY+$019B,X
  STA SCREEN_MEMORY+$01C3,X
  INX
  CPX #11
  BNE ANGO
  RTS

GAMEOVER1:  !BYTE $70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$6e
GAMEOVER2:  !BYTE $5d,$07,$01,$0d,$05,$20,$0f,$16,$05,$12,$5d
GAMEOVER3:  !BYTE $6d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$7d

PLAY_GAME_OVER_MUSIC:
  LDA #1
  STA MUSIC_STATE
  LDA UNIT_TYPE
  CMP #0
  BEQ PGOM
  LDA #6    ;pick song
  JSR MUSIC_START   ;START MUSIC
  RTS
PGOM: LDA #7    ;pick song
  JSR MUSIC_START   ;START MUSIC
  RTS

DISPLAY_WIN_LOSE:
  LDX #0
  LDA UNIT_TYPE
  CMP #0
  BEQ DWL5
DWL1: LDA WIN_MSG,X
  +MC_PLOT_CHAR_X $0088
  INX
  CPX #8
  BNE DWL1
  RTS
DWL5: LDA LOS_MSG,X
  +MC_PLOT_CHAR_X $0088
  INX
  CPX #9
  BNE DWL5
  RTS

WIN_MSG:  !SCR"you win!"
LOS_MSG:  !SCR"you lose!"

PRINT_INTRO_MESSAGE:
  LDA #<INTRO_MESSAGE
  STA $FB
  LDA #>INTRO_MESSAGE
  STA $FC
  JSR PRINT_INFO
  RTS

;This routine will print something to the "information" window
;at the bottom left of the screen.  You must first define the
;source of the text in $FB. The text should terminate with
;a null character.
PRINT_INFO:
  JSR SCROLL_INFO ;New text always causes a scroll
  LDY #0
  STY PRINTX
PI01: LDA ($FB),Y
  CMP #0  ;null terminates string
  BNE PI02
  RTS
PI02: CMP #255  ;return
  BNE PI03
  LDX #0
  STX PRINTX
  JSR SCROLL_INFO
  JMP PI04
PI03: LDX PRINTX
  +MC_PLOT_CHAR_X $03C0
  INC PRINTX
PI04: INY
  JMP PI01
PRINTX: !BYTE 00  ;used to store X-cursor location

;This routine scrolls the info screen by one row, clearing
;a new row at the bottom.
SCROLL_INFO:
  SEI
  ;--------------
  LDX #0
SCI1:
  +COPY_CHAR_X $0370, $0398 ; MID to TOP
  +COPY_CHAR_X $0398, $03C0 ; BOT to MID
  INX
  CPX #33
  BNE SCI1
  ;NOW CLEAR BOTTOM ROW
  LDX #0
  LDA #32
SCI2:
  +MC_PLOT_CHAR_X $03C0 ; BOTTOM ROW
  INX
  CPX #33
  BNE SCI2
  ;--------------
  CLI
  RTS

;This routine is run after the map is loaded, but before the
;game starts.  If the diffulcty is set to normal, nothing
;actually happens.  But if it is set to easy or hard, then
;some changes occur accordingly.
SET_DIFF_LEVEL:
  LDA DIFF_LEVEL
  CMP #0  ;easy
  BNE +
  JMP SET_DIFF_EASY
+ CMP #2  ;hard
  BNE +
  JMP SET_DIFF_HARD
+ RTS

SET_DIFF_EASY:
  ;Find all hidden items and double the quantity.
  LDX #48
- LDA UNIT_TYPE,X
  CMP #0
  BEQ +
  CMP #128  ;KEY
  BEQ +
  ASL UNIT_A,X  ;item qty
+ INX
  CPX #64
  BNE -
  RTS

SET_DIFF_HARD:
  ;Find all hoverbots and change AI
  LDX #0
.SDH1: LDA UNIT_TYPE,X
  CMP #2  ;hoverbot left/right
  BEQ .SDH4
  CMP #3  ;hoverbot up/down
  BEQ .SDH4
.SDH2: INX
  CPX #28
  BNE .SDH1
  RTS
.SDH4: LDA #4  ;hoverbot attack mode
  STA UNIT_TYPE,X
  JMP .SDH2


;This chart contains the left-most staring position for each
;row of tiles on the map-editor. 7 Rows.
MAP_CHART_L:
  !BYTE $00,$78,$F0,$68,$E0,$58,$D0

MAP_CHART_H:
  !BYTE $E0,$E0,$E0,$E1,$E1,$E2,$E2

;This routine animates the tile #204 (water)
;and also tile 148 (trash compactor)
;And also the HVAC fan
ANIMATE_WATER:
  LDA ANIMATE
  CMP #1
  BEQ .AW00
  RTS
.AW00: INC WATER_TIMER
  LDA WATER_TIMER
  CMP #20
  BEQ .AW01
  RTS
.AW01: LDA #0
  STA WATER_TIMER

!IF VIC_CHARMAP {
  LDA TILE_DATA_BR+204
  STA WATER_TEMP1
  LDA TILE_DATA_MM+204
  STA TILE_DATA_BR+204
  STA TILE_DATA_BR+221
  LDA TILE_DATA_TL+204
  STA TILE_DATA_MM+204
  LDA WATER_TEMP1
  STA TILE_DATA_TL+204

  LDA TILE_DATA_BL+204
  STA WATER_TEMP1
  LDA TILE_DATA_MR+204
  STA TILE_DATA_BL+204
  STA TILE_DATA_BL+221
  LDA TILE_DATA_TM+204
  STA TILE_DATA_MR+204
  LDA WATER_TEMP1
  STA TILE_DATA_TM+204
  STA TILE_DATA_TM+221

  LDA TILE_DATA_BM+204
  STA WATER_TEMP1
  LDA TILE_DATA_ML+204
  STA TILE_DATA_BM+204
  STA TILE_DATA_BM+221
  LDA TILE_DATA_TR+204
  STA TILE_DATA_ML+204
  LDA WATER_TEMP1
  STA TILE_DATA_TR+204
  STA TILE_DATA_TR+221
}

!IF VIC_BITMAP {
ANIM_WATER:
  INC ANIM_WATER_FRAME
  LDA ANIM_WATER_FRAME
  CMP #ANIM_WATER_FRAMES
  BNE +
  +STI ANIM_WATER_FRAME, 0
+ LDY ANIM_WATER_FRAME
  LDA ANIM_WATER_TILES,Y
  LDY ANIM_WATER_TILES
  STA REMAP_TILE,Y
}

  ;now do trash compactor
; .TRSAN1: ; not used label
!IF VIC_CHARMAP {
  LDA TILE_COLOR_TR+148 ; TR->TEMP
  STA WATER_TEMP1
  LDA TILE_COLOR_TM+148 ; TM->TR
  STA TILE_COLOR_TR+148
  LDA TILE_COLOR_TL+148 ; TL->TM
  STA TILE_COLOR_TM+148
  LDA WATER_TEMP1       ; TEMP->TL
  STA TILE_COLOR_TL+148

  LDA TILE_COLOR_MR+148 ; MR->TEMP
  STA WATER_TEMP1
  LDA TILE_COLOR_MM+148 ; MM->MR
  STA TILE_COLOR_MR+148
  LDA TILE_COLOR_ML+148 ; ML->MM
  STA TILE_COLOR_MM+148
  LDA WATER_TEMP1       ; TEMP->ML
  STA TILE_COLOR_ML+148

  LDA TILE_COLOR_BR+148 ; BR->TEMP
  STA WATER_TEMP1
  LDA TILE_COLOR_BM+148 ; BM->BR
  STA TILE_COLOR_BR+148
  LDA TILE_COLOR_BL+148 ; BL->BM
  STA TILE_COLOR_BM+148
  LDA WATER_TEMP1       ; TEMP->BL
  STA TILE_COLOR_BL+148
}
!IF VIC_BITMAP {
ANIM_TC:
  PHP
  SEI
  
  ; fetch tile $94 from REU
  +STIW REC_02, TMP_COLORS
  CLC
  LDA mcbm_tile_lo+$94
  ADC #72
  STA REC_04
  LDA mcbm_tile_hi+$94
  ADC #0
  STA REC_05
  +STI  REC_06, 1
  +STIW REC_07, 18
  +STI  REC_01, %10010001

!MACRO ROT3 .addr {
  +PH .addr+2
  +CP .addr+2, .addr+1
  +CP .addr+1, .addr+0
  +PL .addr+0
}

  +ROT3 TMP_COLORS+ 0
  +ROT3 TMP_COLORS+ 3
  +ROT3 TMP_COLORS+ 6
  +ROT3 TMP_COLORS+ 9
  +ROT3 TMP_COLORS+12
  +ROT3 TMP_COLORS+15

  ; stash tile $94 to REU
  +STIW REC_02, TMP_COLORS
  CLC
  LDA mcbm_tile_lo+$94
  ADC #72
  STA REC_04
  LDA mcbm_tile_hi+$94
  ADC #0
  STA REC_05
  +STI  REC_06, 1
  +STIW REC_07, 18
  +STI  REC_01, %10010000

  PLP
}
  ;Now do HVAC fan
; .HVAC0:  ; not used label
  LDA HVAC_STATE
  CMP #0
  BEQ .HVAC1
!IF VIC_CHARMAP {
  LDA #$CD
  STA TILE_DATA_MM+196
  STA TILE_DATA_TL+201
  LDA #$CE
  STA TILE_DATA_ML+197
  STA TILE_DATA_TM+200
  LDA #$A0
  STA TILE_DATA_MR+196
  STA TILE_DATA_BM+196
  STA TILE_DATA_BL+197
  STA TILE_DATA_TR+200
}
  LDA #0
  STA HVAC_STATE
  JMP .HVAC2
.HVAC1:
!IF VIC_CHARMAP {
  LDA #$A0
  STA TILE_DATA_MM+196
  STA TILE_DATA_TL+201
  STA TILE_DATA_ML+197
  STA TILE_DATA_TM+200
  LDA #$C2
  STA TILE_DATA_MR+196
  STA TILE_DATA_TR+200
  LDA #$C0
  STA TILE_DATA_BM+196
  STA TILE_DATA_BL+197
}
  LDA #1
  STA HVAC_STATE
.HVAC2:
!IF VIC_BITMAP {
  LDY ANIM_HVAC_FRAME
  LDA ANIM_HVAC_TILES_UL,Y
  LDY ANIM_HVAC_TILES_UL
  STA REMAP_TILE,Y
  LDY ANIM_HVAC_FRAME
  LDA ANIM_HVAC_TILES_UR,Y
  LDY ANIM_HVAC_TILES_UR
  STA REMAP_TILE,Y
  LDY ANIM_HVAC_FRAME
  LDA ANIM_HVAC_TILES_LL,Y
  LDY ANIM_HVAC_TILES_LL
  STA REMAP_TILE,Y
  LDY ANIM_HVAC_FRAME
  LDA ANIM_HVAC_TILES_LR,Y
  LDY ANIM_HVAC_TILES_LR
  STA REMAP_TILE,Y
}

;******************************************************************
  ;now do cinema screen tiles
ANIMATE_CINEMA:
  ;FIRST COPY OLD LETTERS TO THE LEFT.
  ; copy from 20 CR to 20 CM
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+24+2*8, 8
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+24+1*8, 8
  ; copy from 21 CL to 20 CR
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+24+0*8, 8
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+24+2*8, 8
  ; copy from 21 CM+CR to 21 CL+CM
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+24+1*8, 16
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+24+0*8, 16
  ; copy from 22 CL to 21 CR
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+24+0*8, 8
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+24+2*8, 8
  ; copy from 22 CM to 20 CL
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+24+1*8, 8
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+24+0*8, 8

  ;NEXT COPY OLD COLORS TO THE LEFT.
  ; copy from 20 CR to 20 CM
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+75+2, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+75+1, 1
  ; copy from 21 CL to 20 CR
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+75+0, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+75+2, 1
  ; copy from 21 CM+CR to 21 CL+CM
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+75+1, 2
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+75+0, 2
  ; copy from 22 CL to 21 CR
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+75+0, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+75+2, 1
  ; copy from 22 CM to 20 CL
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+75+1, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+75+0, 1

  ;NEXT COPY OLD COLORS TO THE LEFT.
  ; copy from 20 CR to 20 CM
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+84+2, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+84+1, 1
  ; copy from 21 CL to 20 CR
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+84+0, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+20*90+84+2, 1
  ; copy from 21 CM+CR to 21 CL+CM
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+84+1, 2
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+84+0, 2
  ; copy from 22 CL to 21 CR
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+84+0, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+21*90+84+2, 1
  ; copy from 22 CM to 20 CL
  +FETCHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+84+1, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+84+0, 1

  ;now insert new character.
  LDY CINEMA_STATE
  LDA CINEMA_MESSAGE,Y

  STA CINE_SCRATCH+0
  LDA #0
  STA CINE_SCRATCH+1

  ASL CINE_SCRATCH+0
  ROL CINE_SCRATCH+1
  ASL CINE_SCRATCH+0
  ROL CINE_SCRATCH+1
  ASL CINE_SCRATCH+0
  ROL CINE_SCRATCH+1

  +ADDWI CINE_SCRATCH, REU_ADDR_MCFONT

  LDA #<CINE_SCRATCH
  STA REC_02
  LDA #>CINE_SCRATCH
  STA REC_03
  LDA CINE_SCRATCH+0
  STA REC_04
  LDA CINE_SCRATCH+1
  STA REC_05
  LDA #^REU_ADDR_MCFONT
  STA REC_06
  LDA #8
  STA REC_07
  LDA #0
  STA REC_08
  LDA #%10010001
  STA REC_01

  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+24+1*8, 8

  LDA #$77
  STA CINE_SCRATCH

  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+75+1, 1
  +STASHI CINE_SCRATCH, REU_ADDR_MCTILES+22*90+84+1, 1

  INC CINEMA_STATE
  LDA CINEMA_STATE
  CMP #CINEMA_MESSAGE_SIZE
  BNE .CINE2
  LDA #0
  STA CINEMA_STATE
;******************************************************************
.CINE2:
  ;Now animate light on server computers
!IF VIC_CHARMAP {
  LDA TILE_DATA_MR+143
  CMP #$D7
  BNE .CINE3
  LDA #$D1
  JMP .CINE4
.CINE3:  LDA #$D7
.CINE4:  STA TILE_DATA_MR+143
}
!IF VIC_BITMAP {
  INC ANIM_SERVER_FRAME
  LDA ANIM_SERVER_FRAME
  CMP #ANIM_SERVER_FRAMES
  BNE +
  +STI ANIM_SERVER_FRAME, 0
+ LDY ANIM_SERVER_FRAME
  LDA ANIM_SERVER_TILES,Y
  LDY ANIM_SERVER_TILES
  STA REMAP_TILE,Y
}
  LDA #1
  STA REDRAW_WINDOW
  RTS

WATER_TIMER !BYTE 00
WATER_TEMP1 !BYTE 00
HVAC_STATE  !BYTE 00
CINEMA_STATE  !BYTE 00

TMP_COLORS !FILL 18, 0

;Water  $CC $EC $FC
;Server $8F $EF
;AC     $C4/$C5/$C8/C9 $ED/$EE/$FD/$FE

ANIM_WATER_FRAMES = 3
ANIM_WATER_FRAME !BYTE 0
ANIM_WATER_TILES !BYTE $CC, $FC, $FD

ANIM_HVAC_FRAMES = 2
ANIM_HVAC_FRAME = HVAC_STATE
ANIM_HVAC_TILES_UL !BYTE $C4, $EE
ANIM_HVAC_TILES_UR !BYTE $C5, $EF
ANIM_HVAC_TILES_LL !BYTE $C8, $FE
ANIM_HVAC_TILES_LR !BYTE $C9, $FF

ANIM_SERVER_FRAMES = 2
ANIM_SERVER_FRAME !BYTE 0
ANIM_SERVER_TILES !BYTE $8F, $AF

CINE_SCRATCH !FILL 24, 0

;This is the routine that allows a person to select
;a level and highlights the selection in the information
;display. It is unique to each computer since it writes
;to the screen directly.
ELEVATOR_SELECT:
  LDA #06
  STA PLAYER_DIRECTION
  JSR DISPLAY_PLAYER_SPRITE
  JSR DRAW_MAP_WINDOW
  LDX UNIT
  LDA UNIT_D,X  ;get max levels
  STA ELEVATOR_MAX_FLOOR
  ;Now draw available levels on screen
  LDY #0
  LDA #$31
ELS1:
  +MC_PLOT_CHAR_Y $03C6
  CLC
  ADC #01
  INY
  CPY ELEVATOR_MAX_FLOOR
  BNE ELS1
  LDA UNIT_C,X    ;what level are we on now?
  STA ELEVATOR_CURRENT_FLOOR
  ;Now highlight current level
  JSR ELEVATOR_INVERT
  ;Now get user input
  LDA CONTROL
  CMP #2
  BNE ELS5
!IF SHAREWARE = 0 {
  JMP SELS5
}
ELS5: ;KEYBOARD INPUT
  JSR GET_KEY
  CMP #$00
  BEQ ELS5
  CMP KEY_MOVE_LEFT
  BNE ELS6
  JSR ELEVATOR_DEC
  JMP ELS5
ELS6: CMP KEY_MOVE_RIGHT
  BNE ELS7
  JSR ELEVATOR_INC
  JMP ELS5
ELS7: CMP #$9D  ;CURSOR LEFT
  BNE ELS8
  JSR ELEVATOR_DEC
  JMP ELS5
ELS8: CMP #$1D  ;CURSOR RIGHT
  BNE ELS9
  JSR ELEVATOR_INC
  JMP ELS5
ELS9: CMP #$11  ;CURSOR DOWN
  BNE ELS10
ELS9B:  JSR SCROLL_INFO
  JSR SCROLL_INFO
  JSR SCROLL_INFO
  JSR CLEAR_KEY_BUFFER
  LDA SPENA
  AND #%11111110
  STA SPENA
  RTS
ELS10:  CMP KEY_MOVE_DOWN
  BEQ ELS9B
ELS11:  JMP ELS5

!IF SHAREWARE = 0 {

SELS5:  ;SNES INPUT
  JSR SNES_CONTROLER_READ
  LDA NEW_LEFT
  CMP #1
  BNE SELS8
  JSR ELEVATOR_DEC
  LDA #0
  STA NEW_LEFT
  JMP SELS5
SELS8:  LDA NEW_RIGHT
  CMP #1
  BNE SELS9
  JSR ELEVATOR_INC
  LDA #0
  STA NEW_RIGHT
  JMP SELS5
SELS9:  LDA NEW_DOWN
  CMP #1
  BNE SELS10
  JSR SCROLL_INFO
  JSR SCROLL_INFO
  JSR SCROLL_INFO
  LDA #15
  STA KEYTIMER
  LDA #0
  STA NEW_DOWN
  RTS
SELS10: JMP SELS5

}

ELEVATOR_MAX_FLOOR  !BYTE 00
ELEVATOR_CURRENT_FLOOR  !BYTE 00

ELEVATOR_INVERT:
  LDA   #SP_ELEVATOR_CURSOR  ;USE SPRITE DEF #1
  STA SPRITE_POINTER_0

  LDA YXPAND
  AND #%11111110
  STA YXPAND  ;SPRITE Y-EXPANSION OFF
  LDA SPENA
  ORA #%00000001
  STA SPENA
  LDY ELEVATOR_CURRENT_FLOOR
  LDA EL_PANEL_SPRITE,Y
  STA SP0X
  LDA #241  ;y coordinate
  STA SP0Y
  RTS

EL_PANEL_SPRITE:
  !BYTE 63,71,79,87,95,103,111

ELEVATOR_INC:
  LDA ELEVATOR_CURRENT_FLOOR
  CMP ELEVATOR_MAX_FLOOR
  BNE ELVIN1
  RTS
ELVIN1: INC ELEVATOR_CURRENT_FLOOR
  JSR ELEVATOR_INVERT
  JSR ELEVATOR_FIND_XY
  RTS
ELEVATOR_DEC:
  LDA ELEVATOR_CURRENT_FLOOR
  CMP #1
  BNE ELVDE1
  RTS
ELVDE1: DEC ELEVATOR_CURRENT_FLOOR
  JSR ELEVATOR_INVERT
  JSR ELEVATOR_FIND_XY
  RTS

ELEVATOR_FIND_XY:
  LDX #32 ;start of doors
ELXY1:  LDA UNIT_TYPE,X
  CMP #19 ;elevator
  BNE ELXY5
  LDA UNIT_C,X
  CMP ELEVATOR_CURRENT_FLOOR
  BNE ELXY5
  JMP ELXY10
ELXY5:  INX
  CPX #48
  BNE ELXY1
  RTS
ELXY10:
  LDA UNIT_LOC_X,X  ;new elevator location
  STA UNIT_LOC_X  ;player location
  SEC
  SBC #5
  STA MAP_WINDOW_X
  LDA UNIT_LOC_Y,X  ;new elevator location
  STA UNIT_LOC_Y  ;player location
  DEC UNIT_LOC_Y
  SEC
  SBC #4
  STA MAP_WINDOW_Y
  JSR DRAW_MAP_WINDOW
  JSR ELEVATOR_INVERT
  LDA #15   ;elevator sound (menu beep)
  JSR PLAY_SOUND  ;SOUND PLAY
  RTS

SET_CUSTOM_KEYS:
!IF VIC_BITMAP {
            +STI SCROLX, %00011000 ; enable multicolor mode
}
  LDA KEYS_DEFINED
  CMP #0
  BEQ SCK00
  RTS
SCK00:  JSR CS02  ;set entire screen to monochrome
  +DECOMPRESS_SCREEN SCR_CUSTOM_KEYS, SCREEN_MEMORY
  ;GET KEYS FROM USER
  LDA #0
  STA TEMP_A
  +STIW $FB, $0151
SCK01:  JSR GETIN
  CMP #00
  BEQ SCK01
  LDY TEMP_A
  STA KEY_MOVE_UP,Y
  STA DECNUM
  JSR DECWRITE
  +ADDW $FB, 40
  INC TEMP_A
  LDA TEMP_A
  CMP #13
  BNE SCK01
  LDA #01
  STA KEYS_DEFINED
  RTS

SETUP_SPRITE:
  +STI SPENA, %00000000 ; disable all sprites
  +STI SPMC, %00011110  ; Sprites 1-4 are multicolor; sprites 0, 5-7 are monochrome

  LDX PLAYER_COLOR_INDEX
  LDA PLAYER_COLOR_SP_5,X
  STA SP5COL
  LDA PLAYER_COLOR_SP_6,X
  STA SP6COL
  LDA PLAYER_COLOR_SP_7,X
  STA SP7COL

  +STI SPMC0, 1   ; WHITE for SPRITE MULTICOLOR #0
  +STI SPMC1, 12  ; GRAY for SPRITE MULTICOLOR #1

  +STI YXPAND, %00000001 ;SPRITE Y-EXPANSION

  +STI SP5X, SP_PLAYER_X%256 ;SPRITE 5 X (Player char layer 1)
  +STI SP5Y, SP_PLAYER_Y     ;SPRITE 5 Y
  +STI SP6X, SP_PLAYER_X%256 ;SPRITE 6 X (Player char layer 2)
  +STI SP6Y, SP_PLAYER_Y     ;SPRITE 6 Y
  +STI SP7X, SP_PLAYER_X%256 ;SPRITE 7 X (Player char layer 3)
  +STI SP7Y, SP_PLAYER_Y     ;SPRITE 7 Y

  MSIGX_SP_PLAYER   = (SP_PLAYER_X+ 0)/256*%11100000
  MSIGX_SP_ITEM_R   = (SP_ITEM_X  +24)/256*%00010000
  MSIGX_SP_ITEM_L   = (SP_ITEM_X  + 0)/256*%00001000
  MSIGX_SP_WEAPON_R = (SP_WEAPON_X+24)/256*%00000100
  MSIGX_SP_WEAPON_L = (SP_WEAPON_X+ 0)/256*%00000010

  MSIGX_VALUE = MSIGX_SP_PLAYER+MSIGX_SP_ITEM_R+MSIGX_SP_ITEM_L+MSIGX_SP_WEAPON_R+MSIGX_SP_WEAPON_L

  +STI MSIGX, MSIGX_VALUE ; MSB of all sprite X

  RTS

;This is technically part of a background routine, but it has to
;be here in the main code because the screen effects are unique
;to each system.
DEMATERIALIZE:
  INC SP5COL  ;SPRITE COLOR 5
  INC SP6COL  ;SPRITE COLOR 6
  INC SP7COL  ;SPRITE COLOR 7
  LDX UNIT
  INC UNIT_TIMER_B,X
  LDA UNIT_TIMER_B,X
  CMP #64
  BEQ DEMA1
  JMP AILP
DEMA1:  ;TRANSPORT COMPLETE
  ;Return player sprite color to normal

  TXA
  PHA
  LDX PLAYER_COLOR_INDEX
  LDA PLAYER_COLOR_SP_5,X
  STA SP5COL
  LDA PLAYER_COLOR_SP_6,X
  STA SP6COL
  LDA PLAYER_COLOR_SP_7,X
  STA SP7COL
  PLA
  TAX

  LDA UNIT_B,X
  CMP #1    ;transport somewhere
  BEQ DEMA2
  LDA #2    ;this means game over condition
  STA UNIT_TYPE ;player type
  LDA #7    ;Normal transporter pad
  STA UNIT_TYPE,X
  JMP AILP
DEMA2:  LDA #97
  STA UNIT_TILE
  LDA UNIT_C,X  ;target X coordinates
  STA UNIT_LOC_X
  LDA UNIT_D,X  ;target Y coordinates
  STA UNIT_LOC_Y
  LDA #7    ;Normal transporter pad
  STA UNIT_TYPE,X
  JSR CALCULATE_AND_REDRAW
  JMP AILP

ANIMATE_PLAYER:
ANP1: LDA UNIT_TILE
  CMP #97
  BNE ANP2
  LDA #96
  STA UNIT_TILE
  RTS
ANP2: LDA #97
  STA UNIT_TILE
  RTS
  RTS

START_LEVEL_MUSIC:
  LDY SELECTED_MAP
  LDA LEVEL_MUSIC,Y ;pick song
  JSR MUSIC_START   ;START MUSIC
  LDA #1
  STA MUSIC_STATE
  RTS

TOGGLE_MUSIC:
  LDA USER_MUSIC_ON
  CMP #1
  BNE TGMUS1
  LDA #5  ;pick song
  JSR MUSIC_START   ;START MUSIC
  LDA #<MSG_MUSICOFF
  STA $FB
  LDA #>MSG_MUSICOFF
  STA $FC
  JSR PRINT_INFO
  LDA #0
  STA USER_MUSIC_ON
  RTS
TGMUS1: LDA #<MSG_MUSICON
  STA $FB
  LDA #>MSG_MUSICON
  STA $FC
  JSR PRINT_INFO
  LDA #1
  STA USER_MUSIC_ON
  JMP START_LEVEL_MUSIC


LEVEL_MUSIC:  !BYTE 1,0,2,3,0,1,2,3,0,1,2,3,0,1,2   ; ADDED NEW MUSIC FOR REU LEVELS

DIFF_LEVEL        !BYTE 1 ; default medium
USER_MUSIC_ON     !BYTE 1
BGTIMER1          !BYTE 0
SPRITECOLSTATE    !BYTE 0
SPRITECOLCHART    !BYTE 0,11,12,15,1,15,12,11
CONTROL           !BYTE 0 ; 0=keyboard 1=custom keys 2=snes
MAPNAME           !PET"level-a-64x"
KEYS_DEFINED      !BYTE 0 ; DEFAULT =0
SELECTED_MAP      !BYTE 0
MAP_NAMES         !SCR"01-research lab "
!IF SHAREWARE = 1 {
                  !SCR"02-the islands  " ; normally #4
}
!IF SHAREWARE = 0 {
                  !SCR"02-headquarters "
                  !SCR"03-the village  "
                  !SCR"04-the islands  "
                  !SCR"05-downtown     "
                  !SCR"06-pi university"
                  !SCR"07-more islands "
                  !SCR"08-robot hotel  "
                  !SCR"09-forest moon  "
                  !SCR"10-death tower  "
                  !SCR"11-river death  "  ;NEW MAP FOR REU
                  !SCR"12-bunker       "  ;NEW MAP FOR REU
                  !SCR"13-castle robot "  ;NEW MAP FOR REU
                  !SCR"14-rocket center"  ;NEW MAP FOR REU
                  !SCR"15-pilands      "  ;NEW MAP FOR REU
}

PLAY_SOUND  TAX
            LDY .SOUND_FX_H,X
            LDA .SOUND_FX_L,X
            LDX #14 ;channel 3
            JSR SOUND_PLAY    ;play sound effect
            RTS

.SOUND_FX_L !BYTE <.SOUND_EXPLOSION    ; sound 00 explosion
            !BYTE <.SOUND_EXPLOSION    ; sound 01 explosion
            !BYTE <.SOUND_MEDKIT       ; sound 02 medkit
            !BYTE <.SOUND_EMP          ; sound 03 emp
            !BYTE <.SOUND_MAGNET       ; sound 04 magnet
            !BYTE <.SOUND_SHOCK        ; sound 05 electric shock
            !BYTE <.SOUND_MOVEOBJ      ; sound 06 move object
            !BYTE <.SOUND_SHOCK        ; sound 07 electric shock
            !BYTE <.SOUND_PLASMA       ; sound 08 plasma gun
            !BYTE <.SOUND_PISTOL       ; sound 09 fire pistol
            !BYTE <.SOUND_ITEM_FOUND   ; sound 10 item found
            !BYTE <.SOUND_ERROR        ; sound 11 error
            !BYTE <.SOUND_CYCLE_WEAPON ; sound 12 change weapons
            !BYTE <.SOUND_CYCLE_ITEM   ; sound 13 change items
            !BYTE <.SOUND_DOOR         ; sound 14 door
            !BYTE <.SOUND_MENU_BEEP    ; sound 15 menu beep
            !BYTE <.SOUND_MENU_BEEP    ; sound 16 walk
            !BYTE <.SOUND_BEEP         ; sound 17 short beep
            !BYTE <.SOUND_BEEP         ; sound 18 short beep

.SOUND_FX_H !BYTE >.SOUND_EXPLOSION    ; sound 00 explosion
            !BYTE >.SOUND_EXPLOSION    ; sound 01 explosion
            !BYTE >.SOUND_MEDKIT       ; sound 02 medkit
            !BYTE >.SOUND_EMP          ; sound 03 emp
            !BYTE >.SOUND_MAGNET       ; sound 04 magnet
            !BYTE >.SOUND_SHOCK        ; sound 05 electric shock
            !BYTE >.SOUND_MOVEOBJ      ; sound 06 move object
            !BYTE >.SOUND_SHOCK        ; sound 07 electric shock
            !BYTE >.SOUND_PLASMA       ; sound 08 plasma gun
            !BYTE >.SOUND_PISTOL       ; sound 09 fire pistol
            !BYTE >.SOUND_ITEM_FOUND   ; sound 10 item found
            !BYTE >.SOUND_ERROR        ; sound 11 error
            !BYTE >.SOUND_CYCLE_WEAPON ; sound 12 change weapons
            !BYTE >.SOUND_CYCLE_ITEM   ; sound 13 change items
            !BYTE >.SOUND_DOOR         ; sound 14 door
            !BYTE >.SOUND_MENU_BEEP    ; sound 15 menu beep
            !BYTE >.SOUND_MENU_BEEP    ; sound 16 walk
            !BYTE >.SOUND_BEEP         ; sound 17 short beep
            !BYTE >.SOUND_BEEP         ; sound 18 short beep

.SOUND_MENU_BEEP
            !BYTE $05,$58,$08,$B5,$41,$BA,$40,$00

.SOUND_DOOR !BYTE $05,$59,$00,$B4,$81,$B5,$80,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE
            !BYTE $C2,$C4,$C6,$C8,$CA,$CC,$CD,$00

.SOUND_CYCLE_ITEM
            !BYTE $05,$58,$08,$B0,$41,$B7,$40,$BC,$00

.SOUND_ERROR
            !BYTE $05,$58,$09,$90,$41,$B0,$40,$B2,$90,$B0,$B2,$90,$B0,$B2,$90,$B0
            !BYTE $B2,$90,$B0,$B2,$00

.SOUND_CYCLE_WEAPON
            !BYTE $05,$58,$00,$B0,$21,$B7,$20,$BC,$00

.SOUND_ITEM_FOUND
            !BYTE $0A,$00,$02,$A0,$41,$A0,$A0,$A4,$A4,$A4,$A7,$A7,$A7,$A0,$A0,$A0
            !BYTE $A4,$A4,$A4,$A7,$A7,$A7,$A0,$A0,$A0,$A4,$A4,$A4,$A7,$A7,$A7,$A0
            !BYTE $A0,$A0,$A4,$A4,$A4,$A7,$A7,$A7,$00

.SOUND_BEEP !BYTE $05,$55,$08,$C0,$41,$C0,$40,$00

.SOUND_PISTOL
            !BYTE $00,$F9,$08,$C4,$81,$A8,$41,$C0,$81,$BE,$BC,$80,$BA,$B8,$B6,$B4
            !BYTE $B2,$B0,$AE,$AC,$AA,$A8,$A6,$A4,$A2,$A0,$9E,$9C,$9A,$98,$96,$94
            !BYTE $92,$90,$00

.SOUND_PLASMA
            !BYTE $05,$5A,$08,$AA,$41,$AA,$80,$AD,$40,$AF,$B1,$B3,$B6,$B7,$B9,$AA
            !BYTE $41,$AA,$80,$AD,$40,$AF,$B1,$B3,$B6,$B7,$B9,$AA,$41,$AA,$80,$AD
            !BYTE $40,$AF,$B1,$B3,$B6,$B7,$B9,$AA,$41,$AA,$80,$AD,$40,$AF,$B1,$B3
            !BYTE $B6,$B7,$B9,$AA,$41,$AA,$80,$AD,$40,$AF,$B1,$B3,$B6,$B7,$B9,$AA
            !BYTE $41,$AA,$80,$AD,$40,$AF,$B1,$B3,$B6,$B7,$B9,$AA,$41,$AA,$80,$AD
            !BYTE $40,$AF,$B1,$B3,$B6,$B7,$B9,$AA,$41,$AA,$80,$AD,$40,$AF,$B1,$B3
            !BYTE $B6,$B7,$B9,$AA,$41,$AA,$80,$AD,$40,$AF,$B1,$B3,$B6,$B7,$B9,$AA
            !BYTE $41,$AA,$80,$AD,$40,$AF,$B1,$B3,$B6,$B7,$B9,$AA,$41,$AA,$80,$AD
            !BYTE $40,$AF,$B1,$B3,$B6,$B7,$B9,$AA,$41,$AA,$80,$AD,$40,$AF,$B1,$B3
            !BYTE $B6,$B7,$B9,$00

.SOUND_SHOCK
            !BYTE $05,$59,$08,$A5,$40,$C5,$80,$A5,$90,$40,$90,$80,$A4,$A0,$40,$B0
            !BYTE $A0,$80,$B5,$40,$BA,$99,$80,$90,$C0,$98,$9B,$40,$8B,$9B,$00

.SOUND_MOVEOBJ
            !BYTE $05,$58,$00,$D0,$81,$C0,$80,$B8,$00

.SOUND_MAGNET
            !BYTE $05,$5B,$08,$B1,$41,$B4,$40,$A3,$BA,$C7,$A6,$B4,$93,$92,$B1,$A8
            !BYTE $C6,$A4,$9C,$BA,$BB,$BC,$C3,$A2,$B9,$B7,$95,$94,$B1,$B4,$A3,$BA
            !BYTE $C7,$A6,$B4,$93,$92,$B1,$A8,$C6,$A4,$95,$94,$B1,$B4,$A3,$BA,$C7
            !BYTE $94,$B4,$A3,$BA,$C7,$A6,$B4,$93,$92,$B1,$A8,$C6,$A4,$9C,$BA,$BB
            !BYTE $94,$B4,$A3,$CA,$C7,$A6,$B4,$93,$92,$00

.SOUND_EMP  !BYTE $05,$5B,$08,$95,$41,$97,$80,$99,$9B,$9D,$40,$9F,$91,$93,$80,$95
            !BYTE $97,$99,$40,$9B,$9D,$9F,$80,$A1,$A2,$A3,$40,$A4,$A5,$A6,$80,$A7
            !BYTE $A8,$A9,$40,$AA,$AB,$AC,$80,$AD,$AE,$AF,$40,$B0,$B1,$B2,$80,$B3
            !BYTE $B4,$B5,$40,$B6,$B7,$B8,$80,$B9,$BA,$BB,$40,$BC,$BE,$BF,$80,$C0
            !BYTE $C1,$C2,$40,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$80,$CC,$CD,$CE
            !BYTE $40,$CF,$D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$80,$D8,$D9,$DA,$40,$DB
            !BYTE $DC,$DD,$80,$DE,$DF,$00

.SOUND_MEDKIT
            !BYTE $05,$59,$08,$C0,$41,$C4,$40,$C7,$CC,$C4,$C7,$CC,$C4,$C7,$CC,$C4
            !BYTE $C7,$CC,$C4,$C7,$CC,$C4,$C7,$CC,$C4,$C7,$CC,$C4,$C7,$CC,$C4,$C7
            !BYTE $CC,$C4,$C7,$CC,$C4,$C7,$CC,$00

.SOUND_EXPLOSION
            !BYTE $05,$5C,$00,$94,$81,$95,$80,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E
            !BYTE $92,$80,$94,$8F,$8E,$8D,$8C,$8B,$8A,$89,$88,$87,$86,$84,$00

;This routine clears any new-button-presses
;that are pending.
CLEAR_SNES_PAD:
	LDA	#0
	STA	NEW_UP
	STA	NEW_DOWN
	STA	NEW_LEFT
	STA	NEW_RIGHT
	STA	NEW_A
	STA	NEW_B
	STA	NEW_X
	STA	NEW_Y
	STA	NEW_BACK_L
	STA	NEW_BACK_R
	RTS

INTRO_SCREEN:
  LDA #15
  STA SIGVOL  ; volume
  LDA #4    ;pick song
  JSR MUSIC_START   ;START MUSIC
  LDA #1
  STA MUSIC_STATE
  JSR DISPLAY_INTRO_SCREEN
  JSR DISPLAY_MAP_NAME
  JSR CHANGE_DIFFICULTY_LEVEL
  +STI MENUY, 3
  JSR UNHIGHLIGHT_MENU_OPTION
  +STI MENUY, 2
  JSR UNHIGHLIGHT_MENU_OPTION
  +STI MENUY, 1
  JSR UNHIGHLIGHT_MENU_OPTION
  +STI MENUY, 0
  JSR HIGHLIGHT_MENU_OPTION
  JSR CLEAR_SNES_PAD
  JSR CLEAR_KEY_BUFFER
.ISLOOP: LDA BGTIMER1
  CMP #1
  BNE .ISCHKKEY
  LDA #0
  STA BGTIMER1
  JSR HIGHLIGHT_MENU_OPTION
.ISCHKKEY: JSR GET_KEY
  +CMPI_BEQ $00,           .IS_CHK_SNES ; no key
  +CMPI_BEQ $11,           ISDOWN ; cursor down
  ;+CMPM_BEQ KEY_MOVE_DOWN, ISDOWN
  +CMPI_BEQ $91,           ISUP   ; cursor up
  ;+CMPM_BEQ KEY_MOVE_UP,   ISUP
  +CMPI_BEQ 32,            .ISEXEC ; exec command
  +CMPI_BEQ 13,            .ISEXEC
  +CMPI_BEQ '1',           .ISPLAY1
  +CMPI_BEQ '2',           .ISPLAY2
  +CMPI_BEQ '3',           .ISPLAY3
  +CMPI_BEQ '4',           .ISPLAY4
  +CMPI_BEQ '5',           .ISPLAY5
  +CMPI_BEQ '+',           .ISTESTFX
.IS_CHK_SNES:
  JSR SNES_CONTROLER_READ
  +CMPMI_BEQ NEW_UP,   1,  .IS_SNES_UP
  +CMPMI_BEQ NEW_DOWN, 1,  .IS_SNES_DOWN
  +CMPMI_BEQ NEW_B,    1,  .IS_SNES_B
  JMP .ISLOOP
.IS_SNES_UP:
	JSR	MENU_UP
	LDA	#0
	STA	NEW_UP
	JMP	.ISLOOP
.IS_SNES_DOWN:
	JSR	MENU_DOWN
	LDA	#0
	STA	NEW_DOWN
	JMP	.ISLOOP
.IS_SNES_B:
	LDA	#0
	STA	NEW_B
  JMP EXEC_COMMAND
.ISEXEC:
  JMP EXEC_COMMAND
.ISPLAY1:
  LDA #0    ;pick song (title music)
  JSR MUSIC_START   ;START MUSIC
  JMP .ISLOOP
.ISPLAY2:
  LDA #1    ;pick song
  JSR MUSIC_START   ;START MUSIC
  JMP .ISLOOP
.ISPLAY3:
  LDA #2    ;pick song
  JSR MUSIC_START   ;START MUSIC
  JMP .ISLOOP
.ISPLAY4:
  LDA #3    ;pick song
  JSR MUSIC_START   ;START MUSIC
  JMP .ISLOOP
.ISPLAY5:
  LDA #4    ;pick song
  JSR MUSIC_START   ;START MUSIC
  JMP .ISLOOP
ISDOWN:
  JSR MENU_DOWN
  JMP .ISLOOP
ISUP:
  JSR MENU_UP
  JMP .ISLOOP
.ISTESTFX:
  LDA #5  ;pick song
  JSR MUSIC_START   ;START MUSIC
  LDA #0
  STA USER_MUSIC_ON
- JSR GET_KEY
  CMP #0
  BEQ -
  CMP #$41 ; compare with 'A'
  BMI +    ; less than 'A', nothing to play
  SEC
  SBC #$41 ; adjust from 'A'+ down to 0+
  CMP #$13 ; compare with 13 (1 more than max FX)
  BCS +    ; greater than 13, nothing to play
  JSR PLAY_SOUND
+ JMP .ISLOOP

MENU_UP:
	LDA	MENUY
	CMP	#0
	BNE	MENUP1
	RTS
MENUP1:	JSR	UNHIGHLIGHT_MENU_OPTION
	DEC	MENUY
	LDA	#3
	STA	SPRITECOLSTATE
	JSR	HIGHLIGHT_MENU_OPTION
	LDA	#15		;MENU BEEP
	JSR	PLAY_SOUND	;SOUND PLAY
	RTS

MENU_DOWN:
	LDA	MENUY
	CMP	#3
	BNE	MENDN1
	RTS
MENDN1:	JSR	UNHIGHLIGHT_MENU_OPTION
	INC	MENUY
	LDA	#3
	STA	SPRITECOLSTATE
	JSR	HIGHLIGHT_MENU_OPTION
	LDA	#15		;menu beep
	JSR	PLAY_SOUND	;SOUND PLAY
	RTS

DISPLAY_INTRO_SCREEN:
!IF VIC_CHARMAP {
            +DECOMPRESS_SCREEN INTRO_TEXT, SCREEN_MEMORY
            +DECOMPRESS_SCREEN INTRO_COLOR, COLOR_MEMORY
}
!IF VIC_BITMAP {
            +STI SCROLX, %00001000 ; enable high resolution mode
            ;JSR VDC_INTRO_RENDER
            +FETCHI ADDR_BITMAP,  REU_ADDR_HRINTRO+   0, 8192
            +FETCHI ADDR_COLOR12, REU_ADDR_HRINTRO+8192, 1024
}
            RTS

HR_PLOT_CHAR_HELPER:
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

  +ADDW $FD, $0000

  LDA $FB         ; copy to screen address
  STA REC_02
  LDA $FC
  STA REC_03
  LDA $FD         ; copy from reu offset
  STA REC_04
  LDA $FE
  STA REC_05
  LDA #$01        ; copy from reu bank
  STA REC_06
  LDA #8          ; copy 8 bytes
  STA REC_07
  LDA #0
  STA REC_08
  LDA #%10010001  ; fetch
  STA REC_01

  PLP

  +PLW $FD
  +PLY
  +PLX

  RTS

!MACRO PLOT_CHAR_HELPER .o {
  +PHW $FB
  +STIW $FB, .o
  JSR HR_PLOT_CHAR_HELPER
  +PLW $FB
}

!MACRO PLOT_CHAR .o {
  PHA
  +PHI 0
  +PLOT_CHAR_HELPER .o
  PLA
  PLA
}

!MACRO PLOT_CHAR_X .o {
  PHA
  +PHX
  +PLOT_CHAR_HELPER .o
  +PLX
  PLA
}

!MACRO PLOT_CHAR_Y .o {
  PHA
  +PHY
  +PLOT_CHAR_HELPER .o
  +PLY
  PLA
}

DISPLAY_MAP_NAME:
  JSR CALC_MAP_NAME
- LDA ($FB),Y
  +PLOT_CHAR_Y $0119
  INY
  CPY #16
  BNE -
  ;now set the mapname for the filesystem load
  LDA SELECTED_MAP
  CLC
  ADC #65
  STA MAPNAME+6
  RTS

CHANGE_DIFFICULTY_LEVEL:
  LDY DIFF_LEVEL
  LDA FACE_LEVEL,Y
  TAY
  LDX #$00
- LDA ROBOT_FACE_BITMAP,Y
  STA ADDR_BITMAP+$0C28,X
  INY
  INX
  CPX #24
  BNE -
  RTS

HIGHLIGHT_MENU_OPTION:
  LDY MENUY
  LDA MENU_CHART_L,Y
  STA $FB
  LDA #$CC
  STA $FC
  LDY #0
- LDX SPRITECOLSTATE
  LDA SPRITECOLCHART,X
  ASL
  ASL
  ASL
  ASL
  STA ($FB),Y
  INY
  CPY #10
  BNE -
  RTS
MENUY !BYTE $00 ;CURRENT MENU SELECTION
MENU_CHART_L:
  !BYTE $2C,$54,$7C,$A4

UNHIGHLIGHT_MENU_OPTION:
  LDY MENUY
  LDA MENU_CHART_L,Y
  STA $FB
  LDA #$CC
  STA $FC
  LDY #0
  LDA #$D0 ; LT GREEN
- STA ($FB),Y
  INY
  CPY #10
  BNE -
  RTS

EXEC_COMMAND:
  LDA #17   ;SHORT BEEP
  JSR PLAY_SOUND  ;SOUND PLAY
  LDA MENUY
  CMP #00 ;START GAME
  BNE .EXEC1
  JSR SET_CONTROLS
  LDA #5    ;pick song (blank song)
  JSR MUSIC_START   ;START MUSIC
  LDA #0
  STA MUSIC_STATE
  LDA #0
  STA SIGVOL  ; volume
  JSR PAUSE_UNTIL_NEXT_CYCLE
  JMP INIT_GAME
.EXEC1:  CMP #2  ;DIFF LEVEL
  BNE .EXEC05
  INC DIFF_LEVEL
  LDA DIFF_LEVEL
  CMP #3
  BNE .EXEC02
  LDA #0
  STA DIFF_LEVEL
.EXEC02: JSR CHANGE_DIFFICULTY_LEVEL
  JMP .ISLOOP
.EXEC05: CMP #1  ;cycle map
  BNE .EXEC06
  JSR CYCLE_MAP
.EXEC06: CMP #3
  BNE .EXEC07
  JSR CYCLE_CONTROLS
.EXEC07: JMP .ISLOOP

CALC_MAP_NAME:
  ;FIND MAP NAME
  LDA SELECTED_MAP
  STA $FB
  LDA #0
  STA $FC
  ;multiply by 16 by shifting 4 times to left.
  ASL $FB
  ROL $FC
  ASL $FB
  ROL $FC
  ASL $FB
  ROL $FC
  ASL $FB
  ROL $FC
  ;now add offset for mapnames
  LDA $FB
  CLC
  ADC #<MAP_NAMES
  STA $FB
  LDA $FC
  ADC #>MAP_NAMES
  STA $FC
  LDY #0
  RTS

SET_CONTROLS:
  LDA CONTROL
  CMP #1  ;CUSTOM KEYS
  BNE SETC1
  JSR SET_CUSTOM_KEYS
  RTS
SETC1:  ;load standard values for key controls
  LDY #0
SETC2:  LDA STANDARD_CONTROLS,Y
  STA KEY_MOVE_UP,Y
  INY
  CPY #13
  BNE SETC2
  RTS

;This routine simply pauses until the next interrupt cycle
;completes.  This will hopefully keep the sound from hanging
;when the disk drive starts up.
PAUSE_UNTIL_NEXT_CYCLE:
  LDX #0
.PUNC1:  LDA #0
  STA BGTIMER1
.PUNC2:  LDA BGTIMER1
  CMP #0
  BEQ .PUNC2
  INX
  CPX #2
  BNE .PUNC1
  RTS

CYCLE_CONTROLS:
  LDA #0
  STA KEYS_DEFINED
  INC CONTROL
  LDA CONTROL
  CMP #CONTROL_TYPES_COUNT
  BNE .CCON2
  LDA #0
  STA CONTROL
.CCON2:  ;display control method on screen
  LDY CONTROL
  LDA CONTROLSTART,Y
  TAY
  LDX #0
.CCON3:
  LDA CONTROLTEXT,Y
  +PLOT_CHAR_X $00A4
  INX
  INY
  CPX #10
  BNE .CCON3
  RTS

CONTROLTEXT:  !SCR"keyboard  "
              !SCR"custom key"
              !SCR"snes pad  "
CONTROLSTART: !BYTE 00,10,20

CYCLE_MAP:
  INC SELECTED_MAP
  LDA SELECTED_MAP
  CMP #MAP_COUNT ;max number of maps INCREASED FOR C128
  BNE +
  LDA #0
  STA SELECTED_MAP
+ JSR DISPLAY_MAP_NAME
  RTS

ROBOT_FACE_BITMAP: ;Starts at BITMAP_RAM + $0C28
;Easy
!BYTE %11000000
!BYTE %10111111
!BYTE %11100001
!BYTE %10000000
!BYTE %00011100
!BYTE %00111110
!BYTE %00110110
!BYTE %00111110

!BYTE %00000111 XOR $FF
!BYTE %10001000 XOR $FF
!BYTE %00000000 XOR $FF
!BYTE %00000111 XOR $FF
!BYTE %10001111 XOR $FF
!BYTE %11011100 XOR $FF
!BYTE %11011000 XOR $FF
!BYTE %11011001 XOR $FF

!BYTE %11000000 XOR $FF
!BYTE %00100000 XOR $FF
!BYTE %00000000 XOR $FF
!BYTE %11100000 XOR $FF
!BYTE %11110000 XOR $FF
!BYTE %01111000 XOR $FF
!BYTE %00111000 XOR $FF
!BYTE %00111000 XOR $FF

;Normal
!BYTE %11111000
!BYTE %11111111
!BYTE %11100001
!BYTE %10000000
!BYTE %00011100
!BYTE %00110110
!BYTE %00110110
!BYTE %00111110

!BYTE %00000011 XOR $FF
!BYTE %10000100 XOR $FF
!BYTE %01001000 XOR $FF
!BYTE %00000111 XOR $FF
!BYTE %10001111 XOR $FF
!BYTE %11011100 XOR $FF
!BYTE %11011001 XOR $FF
!BYTE %11011001 XOR $FF

!BYTE %10000000 XOR $FF
!BYTE %00000000 XOR $FF
!BYTE %00000000 XOR $FF
!BYTE %11100000 XOR $FF
!BYTE %11110000 XOR $FF
!BYTE %01111000 XOR $FF
!BYTE %00111000 XOR $FF
!BYTE %00111000 XOR $FF

;Hard
!BYTE %11110111
!BYTE %11111011
!BYTE %11100001
!BYTE %10000000
!BYTE %00011100
!BYTE %00100110
!BYTE %00100110
!BYTE %00111110

!BYTE %00000000 XOR $FF
!BYTE %00000000 XOR $FF
!BYTE %00000001 XOR $FF
!BYTE %00000011 XOR $FF
!BYTE %10000111 XOR $FF
!BYTE %11001100 XOR $FF
!BYTE %11011011 XOR $FF
!BYTE %10011011 XOR $FF

!BYTE %01000000 XOR $FF
!BYTE %10000000 XOR $FF
!BYTE %00000000 XOR $FF
!BYTE %11100000 XOR $FF
!BYTE %11110000 XOR $FF
!BYTE %01111000 XOR $FF
!BYTE %00111000 XOR $FF
!BYTE %00111000 XOR $FF

FACE_LEVEL:
  !BYTE 0,24,48

STANDARD_CONTROLS:
	!BYTE	73	;MOVE UP
	!BYTE	75	;MOVE DOWN
	!BYTE	74	;MOVE LEFT
	!BYTE	76	;MOVE RIGHT
	!BYTE	87	;FIRE UP
	!BYTE	83	;FIRE DOWN
	!BYTE	65	;FIRE LEFT
	!BYTE	68	;FIRE RIGHT
	!BYTE	133	;CYCLE WEAPONS
	!BYTE	134	;CYCLE ITEMS
	!BYTE	32	;USE ITEM
	!BYTE	90	;SEARCH OBEJCT
	!BYTE	77	;MOVE OBJECT

;$D800 - $DBE7  COLOR RAM
;$E000 - $E3E7  SCREEN RAM
;$E3F8    SPRITE POINTER  sprite #0 (tile/elevator cursor)
;$E3F9    SPRITE POINTER  sprite #1 (weapon left)
;$E3FA    SPRITE POINTER  sprite #2 (weapon right)
;$E3FB    SPRITE POINTER  sprite #3 (item left)
;$E3FC    SPRITE POINTER  sprite #4 (item right)
;$E3FD    SPRITE POINTER  sprite #5 (player layer 1)
;$E3FE    SPRITE POINTER  sprite #6 (player layer 2)
;$E3FF    SPRITE POINTER  sprite #7 (player layer 3)

;SPRITE POINTER LOCATIONS:
;$90 = $E400  TILE CURSOR
;$91 = $E440  ELEVATOR CURSOR

;$92 = $E480  PISTOL_HORZ
;$93 = $E4C0  PISTOL_VERT
;$94 = $E500  PLASMA_LEFT
;$95 = $E540  PLASMA_RIGHT
;$96 = $E580  PLASMA_DOWN
;$97 = $E5C0  PLASMA_UP
;$98 = $E600  BOMB
;$99 = $E640  MAGNET
;;; ;$9A = $E680  PISTOL LEFT
;;; ;$9B = $E6C0  PISTOL RIGHT
;;; ;$9C = $E700  PLASMA GUN LEFT
;;; ;$9D = $E740  PLASMA GUN RIGHT

;$9E = $E780  PLAYER UP ANIM1 LAYER 1
;$9F = $E7C0  PLAYER UP ANIM1 LAYER 2
;$A0 = $E800  PLAYER UP ANIM1 LAYER 3
;$A1 = $E840  PLAYER UP ANIM2 LAYER 1
;$A2 = $E880  PLAYER UP ANIM2 LAYER 2
;$A3 = $E8C0  PLAYER UP ANIM2 LAYER 3
;$A4 = $E900  PLAYER DOWN ANIM1 LAYER 1
;$A5 = $E940  PLAYER DOWN ANIM1 LAYER 2
;$A6 = $E980  PLAYER DOWN ANIM1 LAYER 3
;$A7 = $E9C0  PLAYER DOWN ANIM2 LAYER 1
;$A8 = $EA00  PLAYER DOWN ANIM2 LAYER 2
;$A9 = $EA40  PLAYER DOWN ANIM2 LAYER 3
;$AA = $EA80  PLAYER LEFT ANIM1 LAYER 1
;$AB = $EAC0  PLAYER LEFT ANIM1 LAYER 2
;$AC = $EB00  PLAYER LEFT ANIM1 LAYER 3
;$AD = $EB40  PLAYER LEFT ANIM2 LAYER 1
;$AE = $EB80  PLAYER LEFT ANIM2 LAYER 2
;$AF = $EBC0  PLAYER LEFT ANIM2 LAYER 3
;$B0 = $EC00  PLAYER RIGHT ANIM1 LAYER 1
;$B1 = $EC40  PLAYER RIGHT ANIM1 LAYER 2
;$B2 = $EC80  PLAYER RIGHT ANIM1 LAYER 3
;$B3 = $ECC0  PLAYER RIGHT ANIM2 LAYER 1
;$B4 = $ED00  PLAYER RIGHT ANIM2 LAYER 2
;$B5 = $ED40  PLAYER RIGHT ANIM2 LAYER 3
;$B6 = $ED80  PLAYER DEAD LAYER 1
;$B7 = $EDC0  PLAYER DEAD LAYER 2
;$B8 = $EE00  PLAYER DEAD LAYER 3

;$C000 - $C800  Character set

;SPRITES ARE FULLY VISIBLE STARTING AT X=24 Y=50

!SOURCE "background_tasks.asm"

!IF VIC_CHARMAP {

;These are the included binary files that contain the screen
;image for the main editor.
INTRO_TEXT:
  !BYTE $60,$20,$02,$4e,$60,$63,$0a,$4e,$65,$60,$20,$05,$e9,$ce,$20,$20,$e9,$ce,$60,$20
  !BYTE $0d,$cd,$60,$a0,$09,$ce,$20,$65,$60,$20,$05,$66,$a0,$20,$20,$66,$a0,$60,$20,$0d
  !BYTE $a0,$13,$14,$01,$12,$14,$20,$07,$01,$0d,$05,$a0,$20,$65,$60,$20,$04,$e9,$66,$ce
  !BYTE $a0,$a0,$66,$ce,$ce,$60,$20,$0c,$a0,$13,$05,$0c,$05,$03,$14,$20,$0d,$01,$10,$a0
  !BYTE $20,$65,$60,$20,$03,$e9,$a0,$e3,$60,$a0,$02,$e3,$60,$ce,$02,$60,$20,$0b,$a0,$04
  !BYTE $09,$06,$06,$09,$03,$15,$0c,$14,$19,$a0,$20,$65,$60,$20,$02,$e9,$60,$66,$06,$ce
  !BYTE $ce,$a0,$60,$20,$0b,$a0,$03,$0f,$0e,$14,$12,$0f,$0c,$13,$20,$20,$a0,$20,$65,$60
  !BYTE $20,$02,$66,$3a,$4d,$60,$3a,$02,$4e,$3a,$66,$a0,$a0,$60,$20,$02,$e9,$ce,$20,$20
  !BYTE $e9,$ce,$60,$20,$02,$ce,$60,$a0,$09,$cd,$4e,$60,$20,$03,$66,$55,$43,$4d,$3a,$4e
  !BYTE $43,$49,$66,$a0,$a0,$60,$20,$02,$66,$a0,$20,$20,$66,$a0,$60,$20,$13,$66,$42,$51
  !BYTE $48,$3a,$42,$51,$48,$66,$a0,$69,$60,$20,$02,$66,$a0,$20,$20,$66,$a0,$60,$20,$02
  !BYTE $70,$60,$40,$02,$73,$0d,$01,$10,$6b,$60,$40,$02,$6e,$60,$20,$03,$66,$4a,$46,$4b
  !BYTE $3a,$4a,$46,$4b,$66,$ce,$60,$20,$03,$66,$ce,$a0,$a0,$66,$a0,$20,$20,$0b,$09,$0c
  !BYTE $0c,$20,$01,$0c,$0c,$20,$08,$15,$0d,$01,$0e,$13,$60,$20,$03,$60,$66,$06,$a0,$a0
  !BYTE $60,$20,$03,$60,$66,$04,$69,$60,$20,$14,$66,$60,$d0,$04,$66,$a0,$a0,$60,$20,$05
  !BYTE $66,$a0,$20,$20,$60,$43,$14,$66,$60,$d0,$04,$66,$a0,$69,$60,$43,$05,$66,$a0,$43
  !BYTE $43,$60,$3a,$14,$60,$66,$06,$ce,$a0,$a0,$ce,$60,$3a,$03,$66,$a0,$60,$3a,$16,$e9
  !BYTE $a0,$a0,$e7,$d0,$ce,$60,$a0,$02,$ce,$a0,$60,$3a,$03,$66,$a0,$60,$3a,$15,$e9,$60
  !BYTE $a0,$03,$e3,$60,$a0,$02,$ce,$a0,$a0,$60,$3a,$03,$66,$a0,$60,$3a,$0b,$e9,$ce,$df
  !BYTE $60,$3a,$06,$60,$66,$08,$d5,$c0,$c9,$60,$3a,$03,$66,$ce,$df,$60,$3a,$09,$e9,$e3
  !BYTE $cd,$ce,$60,$a0,$06,$66,$51,$60,$66,$04,$51,$66,$dd,$ce,$e3,$60,$a0,$02,$ce,$a0
  !BYTE $cd,$ce,$60,$3a,$09,$a0,$d1,$e7,$60,$66,$10,$dd,$60,$66,$04,$a0,$d1,$e7,$69,$60
  !BYTE $3a,$09,$5f,$a0,$ce,$60,$3a,$07,$60,$66,$08,$ca,$c0,$cb,$60,$3a,$02,$5f,$e4,$69
  !BYTE $60,$3a,$0b,$66,$a0,$3a,$e9,$a0,$a0,$ce,$3a,$e9,$a0,$a0,$ce,$e9,$a0,$a0,$ce,$66
  !BYTE $e9,$a0,$a0,$ce,$e9,$a0,$a0,$ce,$e9,$a0,$a0,$ce,$60,$3a,$0a,$66,$a0,$3a,$60,$66
  !BYTE $02,$ce,$ce,$60,$66,$02,$a0,$60,$66,$02,$ce,$ce,$60,$66,$02,$a0,$60,$66,$02,$69
  !BYTE $60,$66,$02,$69,$60,$3a,$0a,$66,$a0,$3a,$66,$ce,$a0,$66,$ce,$66,$a0,$66,$a0,$66
  !BYTE $ce,$a0,$66,$ce,$66,$a0,$66,$a0,$3a,$66,$a0,$3a,$66,$ce,$a0,$ce,$60,$3a,$0a,$66
  !BYTE $a0,$3a,$60,$66,$02,$ce,$ce,$66,$a0,$66,$a0,$60,$66,$02,$ce,$ce,$66,$a0,$66,$a0
  !BYTE $3a,$66,$a0,$3a,$60,$66,$02,$a0,$60,$3a,$0a,$66,$a0,$3a,$66,$a0,$3a,$66,$a0,$66
  !BYTE $ce,$66,$a0,$66,$ce,$a0,$66,$69,$66,$ce,$66,$a0,$3a,$66,$a0,$3a,$e9,$a0,$66,$a0
  !BYTE $60,$3a,$0a,$66,$a0,$3a,$66,$69,$3a,$66,$69,$60,$66,$02,$69,$60,$66,$02,$69,$3a
  !BYTE $60,$66,$02,$69,$3a,$66,$69,$3a,$60,$66,$02,$69,$3a

INTRO_COLOR:
  !BYTE $60, $01, $02, $60, $0B, $0D, $60, $01, $05, $0C, $0C, $01, $01, $0C, $0C
  !BYTE $60, $01, $0D, $60, $0B, $0D, $60, $01, $04, $0C, $02, $0C, $01, $01, $02
  !BYTE $0C, $60, $01, $0D, $0B, $60, $05, $09, $0B, $01, $0B, $60, $01, $04, $0C
  !BYTE $02, $60, $0C, $02, $02, $0C, $0C, $60, $01, $0C, $0B, $60, $05, $09, $0B
  !BYTE $01, $0B, $60, $01, $03, $60, $0C, $09, $60, $01, $0B, $0B, $60, $05, $09
  !BYTE $0B, $01, $0B, $60, $01, $02, $0C, $60, $02, $06, $60, $0C, $02, $60, $01
  !BYTE $0B, $0B, $60, $05, $09, $60, $0B, $02, $60, $01, $02, $02, $02, $01, $60
  !BYTE $02, $02, $01, $02, $02, $0C, $0C, $60, $01, $02, $0C, $0C, $01, $01, $0C
  !BYTE $0C, $60, $01, $02, $60, $0B, $0C, $60, $01, $03, $02, $60, $01, $02, $02
  !BYTE $60, $01, $02, $02, $0C, $0C, $60, $01, $02, $02, $0C, $01, $01, $02, $0C
  !BYTE $60, $01, $13, $02, $01, $02, $01, $02, $01, $02, $01, $02, $0C, $0C, $60
  !BYTE $01, $02, $02, $0C, $01, $0C, $02, $0C, $60, $01, $13, $02, $60, $01, $02
  !BYTE $02, $60, $01, $02, $02, $0C, $0C, $60, $01, $02, $02, $60, $0C, $02, $02
  !BYTE $0C, $60, $05, $13, $01, $60, $02, $06, $0C, $0C, $60, $01, $03, $60, $02
  !BYTE $04, $0C, $60, $01, $14, $02, $60, $01, $04, $02, $0C, $0C, $60, $01, $05
  !BYTE $02, $0C, $01, $01, $60, $06, $14, $02, $60, $01, $04, $02, $0C, $0C, $60
  !BYTE $06, $05, $02, $0C, $60, $06, $16, $60, $02, $06, $60, $0C, $03, $60, $06
  !BYTE $03, $02, $0C, $60, $06, $16, $60, $0C, $03, $08, $60, $0C, $05, $60, $06
  !BYTE $03, $02, $0C, $60, $06, $15, $60, $0C, $0B, $60, $06, $03, $02, $0C, $60
  !BYTE $06, $0B, $60, $0C, $02, $60, $06, $06, $60, $02, $08, $60, $0C, $02, $60
  !BYTE $06, $03, $02, $0C, $0C, $60, $06, $09, $60, $0C, $0A, $02, $01, $60, $02
  !BYTE $04, $01, $02, $60, $0C, $09, $60, $06, $09, $60, $0C, $02, $60, $02, $10
  !BYTE $0C, $60, $02, $04, $60, $0C, $03, $60, $06, $09, $60, $0C, $02, $60, $06
  !BYTE $07, $60, $02, $08, $60, $0C, $02, $60, $06, $02, $60, $0C, $02, $60, $06
  !BYTE $0B, $02, $0C, $60, $06, $0D, $02, $60, $06, $16, $02, $0C, $06, $60, $01
  !BYTE $02, $06, $06, $60, $01, $02, $06, $60, $01, $02, $06, $06, $60, $01, $02
  !BYTE $06, $60, $01, $02, $06, $60, $01, $02, $60, $06, $0B, $02, $0C, $06, $01
  !BYTE $06, $06, $01, $06, $01, $06, $01, $06, $01, $06, $06, $01, $06, $01, $06
  !BYTE $01, $06, $06, $01, $06, $06, $01, $60, $06, $0D, $02, $0C, $06, $60, $01
  !BYTE $02, $06, $06, $01, $06, $01, $06, $60, $01, $02, $06, $06, $01, $06, $01
  !BYTE $06, $06, $01, $06, $06, $60, $01, $02, $60, $06, $0B, $02, $0C, $06, $01, $06
  !BYTE $06, $01, $06, $01, $06, $01, $06, $01, $06, $06, $01, $06, $01, $06, $01
  !BYTE $06, $06, $01, $06, $06, $06, $06, $01, $60, $06, $0B, $02, $0C, $06, $01
  !BYTE $06, $06, $01, $06, $60, $01, $02, $06, $60, $01, $02, $06, $06, $60, $01
  !BYTE $02, $06, $06, $01, $06 ,$06, $60, $01, $02, $06, $06

SCR_TEXT:
  !BYTE $60,$20,$20,$5d,$17,$05,$01,$10,$0f,$0e,$60,$20,$20,$5d,$60,$20,$26,$5d,$60,$20
  !BYTE $26,$5d,$60,$20,$26,$5d,$60,$20,$26,$5d,$60,$20,$26,$6b,$60,$40,$05,$60,$20,$20
  !BYTE $5d,$20,$09,$14,$05,$0d,$60,$20,$21,$5d,$60,$20,$26,$5d,$60,$20,$26,$5d,$60,$20
  !BYTE $26,$5d,$60,$20,$26,$5d,$60,$20,$26,$6b,$60,$40,$05,$60,$20,$20,$5d,$20,$0b,$05
  !BYTE $19,$13,$60,$20,$21,$5d,$60,$20,$26,$5d,$60,$20,$26,$6b,$60,$40,$05,$60,$20,$20
  !BYTE $5d,$60,$20,$26,$5d,$60,$20,$26,$5d,$60,$20,$05,$73,$09,$0e,$06,$0f,$12,$0d,$01
  !BYTE $14,$09,$0f,$0e,$6b,$60,$40,$13,$5b,$60,$40,$05,$60,$20,$20,$5d,$08,$05,$01,$0c
  !BYTE $14,$08,$60,$20,$20,$5d,$60,$20,$26,$5d,$60,$71,$05
SCR_COLOR:
  !BYTE $60, $F1, $20, $FE, $60, $F1, $26, $FE, $60, $F1, $26, $FE, $60, $F1, $26
  !BYTE $FE, $60, $F1, $26, $FE, $60, $F1, $26, $FE, $60, $F1, $26, $60, $FE, $06
  !BYTE $60, $F1, $20, $FE, $60, $F1, $26, $FE, $60, $F1, $26, $FE, $60, $F1, $26
  !BYTE $FE, $60, $F1, $26, $FE, $60, $F1, $26, $FE, $60, $F1, $26, $60, $FE, $06
  !BYTE $60, $F1, $20, $FE, $60, $F1, $26, $FE, $FA, $FA, $FD, $FD, $FE, $FE, $60
  !BYTE $F1, $20, $FE, $FA, $FA, $FD, $FD, $FE, $FE, $60, $F1, $20, $60, $FE, $06
  !BYTE $60, $F1, $20, $FE, $60, $F1, $26, $FE, $60, $F1, $26, $FE, $60, $F1, $05
  !BYTE $FE, $60, $F1, $0A, $60, $FE, $1B, $60, $F5, $20, $FE, $60, $F1, $05, $60
  !BYTE $F5, $20, $FE, $60, $F1, $05, $60, $F5, $20, $FE, $F2, $F2, $F8, $F8, $F5
  !BYTE $F5

SCR_ENDGAME:
  !BYTE $55, $60, $40, $03, $73, $01, $14, $14, $01, $03, $0B, $20, $0F, $06, $20
  !BYTE $14, $08, $05, $20, $10, $05, $14, $13, $03, $09, $09, $20, $12, $0F, $02
  !BYTE $0F, $14, $13, $6B, $60, $40, $03, $49, $5D, $60, $20, $25, $5D, $5D, $60
  !BYTE $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60
  !BYTE $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $0A, $13, $03, $05
  !BYTE $0E, $01, $12, $09, $0F, $3A, $60, $20, $11, $5D, $5D, $60, $20, $25, $5D
  !BYTE $5D, $60, $20, $06, $05, $0C, $01, $10, $13, $05, $04, $20, $14, $09, $0D
  !BYTE $05, $3A, $60, $20, $11, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $02
  !BYTE $12, $0F, $02, $0F, $14, $13, $20, $12, $05, $0D, $01, $09, $0E, $09, $0E
  !BYTE $07, $3A, $60, $20, $11, $5D, $5D, $60, $20, $25, $5D, $5D, $20, $20, $13
  !BYTE $05, $03, $12, $05, $14, $13, $20, $12, $05, $0D, $01, $09, $0E, $09, $0E
  !BYTE $07, $3A, $60, $20, $11, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $08
  !BYTE $04, $09, $06, $06, $09, $03, $15, $0C, $14, $19, $3A, $60, $20, $11, $5D
  !BYTE $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D
  !BYTE $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D
  !BYTE $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D, $4A, $60, $40, $25, $4B

}

SCR_CUSTOM_KEYS:
  !BYTE $55, $60, $40, $03, $73, $01, $14, $14, $01, $03, $0B, $20, $0F, $06, $20
  !BYTE $14, $08, $05, $20, $10, $05, $14, $13, $03, $09, $09, $20, $12, $0F, $02
  !BYTE $0F, $14, $13, $6B, $60, $40, $03, $49, $5D, $60, $20, $25, $5D, $5D, $60
  !BYTE $20, $25, $5D, $5D, $60, $20, $03, $10, $12, $05, $13, $13, $20, $14, $08
  !BYTE $05, $20, $0B, $05, $19, $13, $20, $19, $0F, $15, $20, $17, $09, $13, $08
  !BYTE $20, $14, $0F, $20, $15, $13, $05, $60, $20, $03, $5D, $5D, $60, $20, $04
  !BYTE $06, $0F, $12, $20, $14, $08, $05, $20, $06, $0F, $0C, $0C, $0F, $17, $09
  !BYTE $0E, $07, $20, $06, $15, $0E, $03, $14, $09, $0F, $0E, $13, $60, $20, $05
  !BYTE $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $25
  !BYTE $5D, $5D, $60, $20, $06, $0D, $0F, $16, $05, $20, $15, $10, $3A, $60, $20
  !BYTE $16, $5D, $5D, $60, $20, $04, $0D, $0F, $16, $05, $20, $04, $0F, $17, $0E
  !BYTE $3A, $60, $20, $16, $5D, $5D, $60, $20, $04, $0D, $0F, $16, $05, $20, $0C
  !BYTE $05, $06, $14, $3A, $60, $20, $16, $5D, $5D, $60, $20, $03, $0D, $0F, $16
  !BYTE $05, $20, $12, $09, $07, $08, $14, $3A, $60, $20, $16, $5D, $5D, $60, $20
  !BYTE $06, $06, $09, $12, $05, $20, $15, $10, $3A, $60, $20, $16, $5D, $5D, $60
  !BYTE $20, $04, $06, $09, $12, $05, $20, $04, $0F, $17, $0E, $3A, $60, $20, $16
  !BYTE $5D, $5D, $60, $20, $04, $06, $09, $12, $05, $20, $0C, $05, $06, $14, $3A
  !BYTE $60, $20, $16, $5D, $5D, $60, $20, $03, $06, $09, $12, $05, $20, $12, $09
  !BYTE $07, $08, $14, $3A, $60, $20, $16, $5D, $5D, $20, $03, $19, $03, $0C, $05
  !BYTE $20, $17, $05, $01, $10, $0F, $0E, $13, $3A, $60, $20, $16, $5D, $5D, $60
  !BYTE $20, $02, $03, $19, $03, $0C, $05, $20, $09, $14, $05, $0D, $13, $3A, $60
  !BYTE $20, $16, $5D, $5D, $60, $20, $05, $15, $13, $05, $20, $09, $14, $05, $0D
  !BYTE $3A, $60, $20, $16, $5D, $5D, $20, $13, $05, $01, $12, $03, $08, $20, $0F
  !BYTE $02, $0A, $05, $03, $14, $3A, $60, $20, $16, $5D, $5D, $60, $20, $02, $0D
  !BYTE $0F, $16, $05, $20, $0F, $02, $0A, $05, $03, $14, $3A, $60, $20, $16, $5D
  !BYTE $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D, $5D, $60, $20, $25, $5D
  !BYTE $4A, $60, $40, $25, $4B

CINEMA_MESSAGE:
  !SCR"coming soon: space balls 2 - the search for more money, "
  !SCR"attack of the paperclips: clippy's revenge, "
  !SCR"it came from planet earth, "
  !SCR"rocky 5000, all my circuits the movie, "
  !SCR"conan the librarian, "
  !SCR"scott robison as james bland in no time to diet, "
  !SCR"and more! "
END_CINEMA_MESSAGE = *
CINEMA_MESSAGE_SIZE = END_CINEMA_MESSAGE-CINEMA_MESSAGE

;WEAPON_PISTOL:
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$04
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$24,$14
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $DE,$6E,$DE,$DE,$36,$DE,$0F,$0F
;            !BYTE $0F,$0F,$0F,$0F,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$3C,$37,$28,$00
;            !BYTE $00,$00,$00,$00,$F3,$FF,$51,$02
;            !BYTE $02,$00,$00,$00,$AA,$95,$AA,$3F
;            !BYTE $39,$6E,$09,$0E,$AA,$96,$68,$F0
;            !BYTE $C0,$00,$80,$80,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$DE,$36,$6C,$13
;            !BYTE $36,$DE,$0F,$0E,$0E,$0B,$0B,$0F
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $0B,$01,$00,$00,$00,$00,$00,$00
;            !BYTE $40,$80,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $DE,$DE,$DE,$BC,$1C,$DE,$0F,$0F
;            !BYTE $0F,$0F,$0F,$0F
;
;WEAPON_PLASMA:
;            !BYTE $00,$00,$00,$00
;            !BYTE $02,$03,$05,$3F,$00,$00,$00,$00
;            !BYTE $00,$E0,$AA,$59,$00,$00,$00,$00
;            !BYTE $0F,$00,$AA,$55,$00,$00,$00,$00
;            !BYTE $FC,$3F,$AA,$D6,$00,$00,$00,$00
;            !BYTE $F0,$FC,$57,$7E,$00,$00,$00,$00
;            !BYTE $00,$00,$80,$50,$6C,$16,$16,$16
;            !BYTE $6B,$BC,$0F,$0F,$0B,$0B,$0C,$0F
;            !BYTE $15,$3F,$02,$0A,$00,$00,$00,$00
;            !BYTE $55,$BE,$0A,$AA,$00,$00,$00,$00
;            !BYTE $55,$AA,$FC,$AA,$0C,$FA,$00,$00
;            !BYTE $55,$55,$02,$55,$A0,$DA,$B3,$12
;            !BYTE $55,$5E,$55,$5E,$AB,$D0,$58,$D4
;            !BYTE $FC,$AD,$F5,$A4,$C0,$00,$00,$00
;            !BYTE $3B,$36,$36,$6B,$6B,$6B,$0C,$0C
;            !BYTE $0B,$0C,$0C,$0F,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$0F,$01,$00,$00
;            !BYTE $00,$00,$00,$00,$94,$EE,$A6,$2A
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$DE,$DE,$DE,$BE
;            !BYTE $6B,$DE,$0F,$0F,$0F,$0F,$0F,$0F
;
;ITEM_MEDKIT:
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$05,$1A,$15
;            !BYTE $00,$00,$00,$00,$00,$AA,$5D,$AA
;            !BYTE $00,$00,$00,$00,$00,$FF,$A6,$FF
;            !BYTE $00,$00,$00,$00,$00,$80,$80,$60
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $DE,$6E,$36,$13,$36,$DE,$0F,$0F
;            !BYTE $0E,$06,$0F,$0F,$00,$00,$2F,$35
;            !BYTE $37,$35,$35,$35,$35,$30,$AA,$55
;            !BYTE $55,$55,$55,$55,$55,$00,$FF,$55
;            !BYTE $55,$A5,$A5,$A5,$55,$00,$FF,$55
;            !BYTE $55,$A5,$A5,$A5,$A0,$A0,$FF,$55
;            !BYTE $5D,$55,$55,$55,$00,$00,$40,$80
;            !BYTE $90,$A0,$B0,$A0,$1B,$1C,$1A,$1A
;            !BYTE $16,$BC,$0C,$0E,$0C,$0C,$0C,$0F
;            !BYTE $2D,$25,$2D,$2F,$2E,$2F,$2A,$00
;            !BYTE $55,$55,$55,$55,$F5,$FD,$AA,$00
;            !BYTE $AA,$A5,$A5,$A5,$55,$55,$FF,$55
;            !BYTE $A5,$A5,$A5,$A5,$55,$55,$FF,$55
;            !BYTE $55,$55,$55,$55,$5D,$55,$FF,$AA
;            !BYTE $B0,$B0,$B0,$A0,$B0,$A0,$E0,$50
;            !BYTE $1C,$1C,$1A,$1A,$1B,$BC,$0F,$0F
;            !BYTE $0C,$0C,$0C,$0F,$05,$01,$00,$00
;            !BYTE $00,$00,$00,$00,$59,$55,$00,$00
;            !BYTE $00,$00,$00,$00,$AA,$55,$00,$00
;            !BYTE $00,$00,$00,$00,$AA,$55,$00,$00
;            !BYTE $00,$00,$00,$00,$A5,$55,$00,$00
;            !BYTE $00,$00,$00,$00,$60,$50,$00,$00
;            !BYTE $00,$00,$00,$00,$BE,$BC,$BC,$BC
;            !BYTE $BC,$BC,$0F,$0F,$0F,$0F,$0F,$0F
;
;ITEM_EMP:
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$01
;            !BYTE $00,$00,$00,$00,$00,$15,$50,$40
;            !BYTE $00,$00,$00,$00,$00,$54,$05,$01
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$40
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $DE,$AE,$AE,$AE,$AE,$DE,$0F,$0F
;            !BYTE $0F,$0F,$0F,$0F,$00,$00,$00,$D5
;            !BYTE $EF,$B7,$D5,$BF,$02,$0A,$08,$08
;            !BYTE $48,$D8,$F4,$FE,$00,$05,$15,$15
;            !BYTE $55,$55,$55,$75,$00,$A0,$A8,$A8
;            !BYTE $9A,$AE,$A6,$AE,$80,$A0,$20,$22
;            !BYTE $29,$27,$1D,$BF,$00,$00,$00,$7E
;            !BYTE $FB,$DB,$5E,$FF,$1C,$1A,$2E,$12
;            !BYTE $1A,$1C,$0F,$0F,$0F,$0F,$0F,$0F
;            !BYTE $EF,$EA,$D5,$FF,$00,$FF,$00,$00
;            !BYTE $D4,$58,$88,$08,$88,$0A,$02,$02
;            !BYTE $9A,$BA,$A6,$2A,$2A,$0A,$00,$80
;            !BYTE $55,$55,$55,$54,$54,$50,$00,$02
;            !BYTE $15,$2F,$2B,$22,$28,$A2,$80,$80
;            !BYTE $56,$DA,$EE,$AA,$00,$A0,$00,$00
;            !BYTE $13,$3A,$12,$2A,$3A,$36,$06,$0F
;            !BYTE $0F,$0F,$0F,$0F,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$50,$15,$00,$00
;            !BYTE $00,$00,$00,$00,$05,$54,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$DE,$DE,$AE,$AE
;            !BYTE $DE,$DE,$0F,$0F,$0F,$0F,$0F,$0F
;
;ITEM_MAGNET:
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$10,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$10
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $DE,$6E,$DE,$DE,$6E,$DE,$0F,$0F
;            !BYTE $0F,$0F,$0F,$0F,$04,$02,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$C0,$20
;            !BYTE $00,$01,$01,$01,$B8,$AC,$BC,$AC
;            !BYTE $B8,$70,$60,$60,$D4,$D4,$B4,$F4
;            !BYTE $AC,$2B,$3F,$3F,$00,$00,$02,$04
;            !BYTE $00,$00,$00,$00,$10,$40,$00,$00
;            !BYTE $00,$00,$00,$00,$6E,$26,$8C,$1C
;            !BYTE $6E,$6E,$0F,$0E,$0F,$0F,$0F,$0F
;            !BYTE $16,$00,$00,$00,$00,$00,$00,$02
;            !BYTE $A1,$01,$01,$01,$03,$20,$80,$00
;            !BYTE $90,$90,$60,$95,$5A,$55,$D5,$35
;            !BYTE $1A,$15,$1A,$55,$5B,$54,$5C,$70
;            !BYTE $05,$00,$00,$00,$00,$04,$02,$00
;            !BYTE $A4,$00,$00,$00,$00,$00,$00,$40
;            !BYTE $6E,$26,$28,$28,$6E,$6E,$0F,$09
;            !BYTE $09,$09,$0F,$0F,$04,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$04,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$40,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$10,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$6E,$6E,$DE,$DE
;            !BYTE $6E,$6E,$0F,$0F,$0F,$0F,$0F,$0F
;
;ITEM_BOMB:
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$01
;            !BYTE $00,$00,$00,$00,$00,$15,$45,$95
;            !BYTE $00,$00,$00,$00,$00,$00,$C9,$C4
;            !BYTE $00,$00,$00,$00,$00,$00,$60,$10
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $DE,$BE,$BC,$89,$89,$DE,$0F,$0F
;            !BYTE $0F,$0B,$0F,$0F,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$06,$06,$09,$1A
;            !BYTE $15,$1A,$1F,$1B,$D5,$92,$53,$A2
;            !BYTE $A3,$F5,$E8,$B9,$10,$10,$00,$44
;            !BYTE $90,$F4,$90,$05,$0C,$08,$32,$03
;            !BYTE $09,$0D,$3D,$0D,$00,$00,$00,$00
;            !BYTE $80,$C0,$70,$C0,$DE,$BC,$BC,$9C
;            !BYTE $18,$78,$0F,$0F,$0F,$0F,$09,$09
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $1D,$1D,$1B,$1B,$0A,$06,$05,$01
;            !BYTE $B9,$BA,$B9,$EA,$F5,$A9,$55,$A4
;            !BYTE $DE,$F6,$DC,$F4,$D4,$F8,$D0,$F0
;            !BYTE $0B,$01,$33,$03,$00,$00,$00,$00
;            !BYTE $40,$00,$20,$00,$00,$00,$00,$00
;            !BYTE $DE,$BC,$BC,$89,$78,$89,$0F,$0F
;            !BYTE $0F,$0B,$09,$0F,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$55,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$40,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$00,$00,$00,$00
;            !BYTE $00,$00,$00,$00,$DE,$DE,$BE,$BE
;            !BYTE $DE,$DE,$0F,$0F,$0F,$0F,$0F,$0F
!IF 0 {
GAME_MCBM:
            !BYTE $80,$00,$80,$00,$FB,$00,$0A,$22
            !BYTE $04,$1B,$3A,$32,$1D,$08,$22,$AA
            !BYTE $80,$FE,$11,$0A,$15,$91,$AA,$FF
            !BYTE $C3,$16,$10,$14,$10,$16,$FF,$FF
            !BYTE $04,$03,$98,$44,$54,$FF,$44,$FF
            !BYTE $FF,$0A,$03,$58,$44,$58,$40,$4C
            !BYTE $FF,$AA,$02,$98,$FE,$44,$01,$98
            !BYTE $FF,$AA,$07,$08,$41,$51,$65,$49
            !BYTE $41,$AA,$80,$00,$80,$00,$FB,$00
            !BYTE $03,$2A,$26,$2A,$FF,$26,$01,$2A
            !BYTE $FF,$26,$80,$00,$80,$00,$CB,$00
            !BYTE $02,$2E,$26,$FF,$2E,$01,$26,$FE
            !BYTE $2E,$80,$00,$80,$00,$CB,$00,$FE
            !BYTE $2E,$01,$26,$FF,$2E,$02,$26,$2E
            !BYTE $80,$00,$80,$00,$CB,$00,$FF,$26
            !BYTE $01,$2A,$FF,$26,$03,$2A,$26,$2A
            !BYTE $80,$00,$80,$00,$CB,$00,$0F,$22
            !BYTE $04,$1B,$3A,$32,$1D,$08,$22,$AA
            !BYTE $82,$14,$3A,$3E,$14,$80,$FF,$AA
            !BYTE $02,$02,$54,$FE,$12,$01,$54,$FF
            !BYTE $AA,$02,$00,$54,$FD,$10,$FF,$AA
            !BYTE $06,$02,$54,$40,$50,$40,$54,$FF
            !BYTE $AA,$0F,$08,$40,$51,$66,$48,$40
            !BYTE $AA,$FF,$00,$4A,$47,$4F,$4A,$40
            !BYTE $FF,$80,$00,$80,$00,$FB,$00,$03
            !BYTE $2A,$26,$2A,$FF,$26,$01,$2A,$FF
            !BYTE $26,$80,$00,$80,$00,$CB,$00,$02
            !BYTE $2E,$26,$FF,$2E,$01,$26,$FE,$2E
            !BYTE $80,$00,$80,$00,$CB,$00,$02,$26
            !BYTE $2E,$FD,$26,$02,$2E,$26,$80,$00
            !BYTE $80,$00,$CB,$00,$FE,$2E,$01,$26
            !BYTE $FF,$2E,$02,$26,$2E,$80,$00,$80
            !BYTE $00,$CB,$00,$FF,$26,$01,$2A,$FF
            !BYTE $26,$03,$2A,$26,$2A,$80,$00,$80
            !BYTE $00,$CB,$00,$0F,$22,$04,$1B,$3A
            !BYTE $32,$1D,$08,$22,$AA,$80,$15,$3B
            !BYTE $3F,$15,$80,$FF,$AA,$01,$88,$FF
            !BYTE $11,$01,$16,$FF,$11,$FF,$AA,$06
            !BYTE $80,$15,$10,$14,$10,$15,$FF,$AA
            !BYTE $01,$88,$FF,$11,$FF,$84,$12,$04
            !BYTE $AA,$FF,$C0,$25,$10,$C4,$C1,$16
            !BYTE $FF,$AA,$80,$15,$BB,$BF,$15,$00
            !BYTE $AA,$80,$00,$80,$00,$FB,$00,$03
            !BYTE $2A,$26,$2A,$FF,$26,$01,$2A,$FF
            !BYTE $26,$80,$00,$80,$00,$CB,$00,$02
            !BYTE $2E,$26,$FD,$2E,$02,$26,$2E,$80
            !BYTE $00,$80,$00,$CB,$00,$FF,$26,$01
            !BYTE $2A,$FF,$26,$03,$2A,$26,$2A,$80
            !BYTE $00,$80,$00,$CB,$00,$0A,$22,$04
            !BYTE $1B,$3A,$32,$1D,$08,$22,$AA,$80
            !BYTE $FF,$11,$01,$15,$FF,$11,$FF,$AA
            !BYTE $0C,$80,$15,$10,$14,$10,$15,$AA
            !BYTE $FF,$C0,$26,$11,$15,$FF,$11,$04
            !BYTE $FF,$AA,$8A,$10,$FF,$12,$02,$10
            !BYTE $15,$FF,$AA,$02,$02,$54,$FD,$10
            !BYTE $FF,$AA,$01,$22,$FF,$44,$01,$54
            !BYTE $FF,$44,$01,$AA,$80,$00,$80,$00
            !BYTE $FB,$00,$03,$2A,$26,$2A,$FF,$26
            !BYTE $01,$2A,$FF,$26,$80,$00,$80,$00
            !BYTE $CB,$00,$02,$2E,$26,$FF,$2E,$01
            !BYTE $26,$FE,$2E,$80,$00,$80,$00,$CB
            !BYTE $00,$02,$26,$2E,$FD,$26,$02,$2E
            !BYTE $26,$80,$00,$80,$00,$CB,$00,$FE
            !BYTE $2E,$01,$26,$FF,$2E,$02,$26,$2E
            !BYTE $80,$00,$80,$00,$CB,$00,$FF,$26
            !BYTE $01,$2A,$FF,$26,$03,$2A,$26,$2A
            !BYTE $D1,$00,$07,$AA,$02,$54,$EE,$FE
            !BYTE $54,$00,$FF,$AA,$02,$02,$54,$FE
            !BYTE $10,$01,$54,$FF,$AA,$06,$08,$41
            !BYTE $51,$65,$49,$41,$FF,$AA,$04,$80
            !BYTE $15,$10,$14,$FF,$12,$04,$AA,$FF
            !BYTE $C0,$26,$FE,$11,$01,$26,$FF,$FF
            !BYTE $04,$C0,$16,$11,$16,$FF,$11,$0E
            !BYTE $FF,$AA,$8A,$10,$14,$19,$12,$10
            !BYTE $AA,$FF,$CC,$12,$51,$D1,$FF,$11
            !BYTE $FF,$FF,$04,$0C,$61,$10,$50,$FF
            !BYTE $10,$04,$FF,$AA,$08,$51,$FE,$48
            !BYTE $05,$41,$AA,$FF,$0C,$52,$FE,$41
            !BYTE $01,$52,$FF,$FF,$02,$0C,$61,$FE
            !BYTE $11,$09,$61,$FF,$AA,$22,$04,$44
            !BYTE $94,$24,$04,$FF,$AA,$06,$00,$55
            !BYTE $EE,$FF,$55,$00,$FF,$AA,$06,$00
            !BYTE $55,$BA,$FF,$55,$00,$FF,$AA,$06
            !BYTE $00,$55,$AA,$FF,$55,$00,$FF,$AA
            !BYTE $06,$00,$55,$AA,$FF,$55,$00,$FF
            !BYTE $AA,$06,$00,$55,$AA,$FF,$55,$00
            !BYTE $FF,$AA,$06,$00,$55,$AA,$FF,$55
            !BYTE $00,$FF,$AA,$06,$00,$55,$AA,$FF
            !BYTE $55,$00,$FF,$AA,$06,$00,$55,$AA
            !BYTE $FF,$55,$00,$FF,$AA,$06,$00,$55
            !BYTE $AA,$FF,$55,$00,$FF,$AA,$06,$00
            !BYTE $55,$AA,$FF,$55,$00,$FF,$AA,$06
            !BYTE $00,$55,$AA,$FF,$55,$00,$FF,$AA
            !BYTE $06,$00,$55,$AA,$FF,$55,$00,$FF
            !BYTE $AA,$06,$00,$55,$AA,$FF,$55,$00
            !BYTE $FF,$AA,$06,$00,$55,$AA,$FF,$55
            !BYTE $00,$FF,$AA,$06,$00,$55,$AA,$FF
            !BYTE $55,$00,$FF,$AA,$06,$00,$55,$AA
            !BYTE $FF,$55,$00,$FF,$AA,$06,$00,$55
            !BYTE $AA,$FF,$55,$00,$FF,$AA,$06,$00
            !BYTE $55,$AA,$FF,$55,$00,$FF,$AA,$06
            !BYTE $00,$55,$AE,$FF,$55,$00,$FF,$AA
            !BYTE $0F,$00,$55,$BB,$FF,$55,$00,$AA
            !BYTE $A2,$84,$1B,$3A,$32,$1D,$88,$A2
            !BYTE $80,$00,$80,$00,$CB,$00,$03,$2A
            !BYTE $26,$2A,$FF,$26,$01,$2A,$FF,$26
            !BYTE $80,$00,$80,$00,$CB,$00,$02,$2E
            !BYTE $26,$FD,$2E,$02,$26,$2E,$80,$00
            !BYTE $80,$00,$CB,$00,$FF,$26,$01,$2A
            !BYTE $FF,$26,$03,$2A,$26,$2A,$D1,$00
            !BYTE $00,$E0,$DE,$02,$46,$16,$FE,$14
            !BYTE $FF,$16,$E0,$DE,$01,$46,$DA,$DE
            !BYTE $01,$46,$DA,$DE,$01,$46,$DA,$DE
            !BYTE $01,$46,$DA,$DE,$FF,$46,$FD,$16
            !BYTE $01,$14,$E0,$DE,$01,$46,$DA,$DE
            !BYTE $01,$46,$DA,$DE,$01,$36,$DA,$DE
            !BYTE $01,$46,$DA,$DE,$01,$46,$DA,$DE
            !BYTE $FF,$46,$FE,$16,$02,$14,$46,$E0
            !BYTE $DE,$01,$46,$DA,$DE,$01,$46,$DA
            !BYTE $DE,$01,$46,$DA,$DE,$01,$46,$FF
            !BYTE $16,$01,$14,$FE,$16,$E0,$DE,$01
            !BYTE $46,$DA,$DE,$01,$46,$DA,$DE,$01
            !BYTE $36,$DA,$DE,$01,$46,$DA,$DE,$01
            !BYTE $46,$FB,$DE,$01,$46,$FE,$16,$FF
            !BYTE $14,$01,$16,$FF,$14,$01,$16,$FF
            !BYTE $14,$01,$16,$EC,$46,$DA,$DE,$01
            !BYTE $46,$DA,$DE,$01,$46,$DA,$DE,$01
            !BYTE $46,$FB,$DE,$00,$E0,$0F,$02,$0E
            !BYTE $0F,$FE,$06,$B6,$0F,$01,$0E,$DA
            !BYTE $0F,$01,$0E,$B2,$0F,$FF,$0E,$FD
            !BYTE $0F,$01,$06,$B8,$0F,$01,$0E,$DA
            !BYTE $0F,$01,$0E,$DA,$0F,$01,$0E,$B2
            !BYTE $0F,$FF,$0E,$FE,$0F,$02,$06,$0E
            !BYTE $B8,$0F,$01,$0E,$B2,$0F,$01,$0E
            !BYTE $FF,$0F,$01,$06,$B5,$0F,$01,$0E
            !BYTE $DA,$0F,$01,$0E,$DA,$0F,$01,$0E
            !BYTE $D3,$0F,$01,$0E,$FE,$0F,$FF,$06
            !BYTE $01,$0F,$FF,$06,$01,$0F,$FF,$06
            !BYTE $01,$0F,$EC,$0E,$B2,$0F,$01,$0E
            !BYTE $D3,$0F,$00,$00,$00,$00,$00,$00
}

END_MCBM:
            !BYTE $F2,$00,$01,$15,$FA,$00,$01,$55
            !BYTE $FA,$00,$01,$55,$FA,$00,$05,$55
            !BYTE $00,$05,$15,$16,$FD,$5A,$FF,$AA
            !BYTE $FF,$FF,$01,$DF,$FF,$77,$01,$57
            !BYTE $FF,$AA,$FF,$FF,$01,$57,$FE,$DF
            !BYTE $FF,$AA,$FF,$FF,$01,$57,$FE,$DF
            !BYTE $FF,$AA,$FF,$FF,$01,$DF,$FF,$77
            !BYTE $01,$57,$FF,$AA,$FF,$FF,$02,$DF
            !BYTE $77,$FF,$7F,$FF,$AA,$FF,$FF,$FF
            !BYTE $77,$FF,$5F,$FF,$55,$F9,$AA,$FF
            !BYTE $FF,$01,$DF,$FE,$77,$FF,$AA,$FF
            !BYTE $FF,$01,$57,$FF,$7F,$01,$5F,$FF
            !BYTE $55,$F9,$AA,$FF,$FF,$01,$57,$FE
            !BYTE $DF,$FF,$AA,$FF,$FF,$FE,$77,$01
            !BYTE $57,$FF,$AA,$FF,$FF,$01,$57,$FF
            !BYTE $7F,$01,$5F,$FF,$55,$F9,$AA,$FF
            !BYTE $FF,$01,$5F,$FF,$77,$01,$5F,$FF
            !BYTE $AA,$FF,$FF,$01,$57,$FF,$7F,$01
            !BYTE $5F,$FF,$AA,$FF,$FF,$01,$57,$FE
            !BYTE $DF,$FF,$AA,$FF,$FF,$04,$DF,$77
            !BYTE $7F,$DF,$FF,$AA,$FF,$FF,$02,$DF
            !BYTE $77,$FF,$7F,$FF,$AA,$FF,$FF,$01
            !BYTE $57,$FE,$DF,$FF,$AA,$FF,$FF,$01
            !BYTE $57,$FE,$DF,$FF,$55,$F9,$AA,$FF
            !BYTE $FF,$01,$5F,$FF,$77,$01,$5F,$FF
            !BYTE $AA,$FF,$FF,$01,$DF,$FE,$77,$FF
            !BYTE $AA,$FF,$FF,$01,$5F,$FF,$77,$01
            !BYTE $5F,$FF,$AA,$FF,$FF,$01,$DF,$FE
            !BYTE $77,$FF,$AA,$FF,$FF,$01,$57,$FE
            !BYTE $DF,$0A,$A8,$AA,$FE,$FF,$DF,$77
            !BYTE $7F,$DF,$00,$40,$FF,$50,$FE,$94
            !BYTE $01,$95,$FA,$00,$01,$55,$FA,$00
            !BYTE $01,$55,$FA,$00,$01,$55,$FA,$00
            !BYTE $01,$54,$F9,$00,$01,$01,$FF,$05
            !BYTE $FC,$14,$02,$55,$40,$FB,$00,$01
            !BYTE $55,$FA,$00,$01,$55,$FA,$00,$01
            !BYTE $55,$FA,$00,$FD,$5A,$04,$16,$15
            !BYTE $05,$00,$FE,$77,$FE,$FF,$FF,$AA
            !BYTE $FE,$DF,$FE,$FF,$FF,$AA,$FE,$DF
            !BYTE $FE,$FF,$FF,$AA,$FE,$77,$FE,$FF
            !BYTE $FF,$AA,$03,$7F,$77,$DF,$FE,$FF
            !BYTE $FF,$AA,$FE,$77,$FE,$FF,$F9,$AA
            !BYTE $FF,$55,$FF,$77,$01,$DF,$FE,$FF
            !BYTE $FF,$AA,$FE,$7F,$FE,$FF,$F9,$AA
            !BYTE $FF,$55,$FE,$DF,$FE,$FF,$FF,$AA
            !BYTE $FE,$77,$FE,$FF,$FF,$AA,$FF,$7F
            !BYTE $01,$57,$FE,$FF,$F9,$AA,$FF,$55
            !BYTE $FE,$7F,$FE,$FF,$FF,$AA,$FF,$7F
            !BYTE $01,$57,$FE,$FF,$FF,$AA,$FE,$DF
            !BYTE $FE,$FF,$FF,$AA,$03,$F7,$77,$DF
            !BYTE $FE,$FF,$FF,$AA,$03,$7F,$77,$DF
            !BYTE $FE,$FF,$FF,$AA,$FF,$DF,$01,$57
            !BYTE $FE,$FF,$FF,$AA,$FF,$9A,$01,$56
            !BYTE $FF,$AA,$03,$A8,$A3,$8F,$FE,$55
            !BYTE $02,$41,$28,$FE,$A8,$FE,$66,$03
            !BYTE $AA,$A8,$A3,$FF,$8F,$FF,$66,$02
            !BYTE $9A,$00,$FF,$FF,$02,$C3,$00,$FF
            !BYTE $66,$04,$5A,$AA,$2A,$C8,$FF,$F3
            !BYTE $FF,$66,$04,$9A,$80,$3F,$FF,$FF
            !BYTE $C0,$FE,$9A,$03,$2A,$CA,$F2,$FF
            !BYTE $3C,$03,$F7,$77,$DF,$FF,$FF,$04
            !BYTE $FE,$AA,$A8,$95,$FE,$94,$FF,$50
            !BYTE $03,$40,$00,$55,$FA,$00,$01,$55
            !BYTE $FA,$00,$01,$55,$FA,$00,$02,$55
            !BYTE $01,$FB,$00,$01,$40,$FF,$50,$F4
            !BYTE $14,$80,$00,$BA,$00,$01,$05,$FA
            !BYTE $00,$F9,$14,$01,$05,$FD,$00,$01
            !BYTE $01,$FF,$05,$06,$00,$01,$05,$15
            !BYTE $54,$50,$FF,$55,$03,$51,$50,$40
            !BYTE $FE,$01,$FF,$50,$01,$40,$FF,$55
            !BYTE $FE,$40,$03,$55,$15,$14,$FF,$50
            !BYTE $FE,$14,$02,$50,$40,$D1,$00,$F1
            !BYTE $14,$89,$00,$FE,$CC,$FD,$30,$02
            !BYTE $00,$30,$FC,$CC,$02,$30,$00,$FB
            !BYTE $CC,$01,$30,$F8,$00,$FB,$C0,$03
            !BYTE $FC,$00,$30,$FC,$CC,$0B,$30,$00
            !BYTE $30,$CC,$C0,$30,$0C,$CC,$30,$00
            !BYTE $FC,$FF,$C0,$01,$F0,$FF,$C0,$02
            !BYTE $FC,$00,$FC,$30,$02,$00,$30,$90
            !BYTE $00,$F1,$14,$80,$00,$80,$00,$D3
            !BYTE $00,$F1,$14,$80,$00,$80,$00,$D3
            !BYTE $00,$F1,$14,$80,$00,$80,$00,$D3
            !BYTE $00,$F1,$14,$B1,$00,$01,$01,$FF
            !BYTE $04,$09,$01,$00,$04,$01,$00,$40
            !BYTE $11,$01,$41,$FF,$11,$04,$40,$00
            !BYTE $50,$04,$FE,$00,$04,$04,$50,$00
            !BYTE $54,$FF,$40,$01,$50,$FF,$40,$03
            !BYTE $54,$00,$41,$FF,$51,$FF,$45,$FF
            !BYTE $41,$02,$00,$05,$FF,$10,$01,$15
            !BYTE $FE,$10,$02,$00,$05,$FF,$44,$01
            !BYTE $45,$FE,$44,$02,$00,$41,$FF,$10
            !BYTE $01,$40,$FF,$10,$03,$11,$00,$50
            !BYTE $FC,$41,$03,$50,$00,$50,$FC,$04
            !BYTE $01,$50,$FE,$00,$FF,$10,$01,$00
            !BYTE $FF,$10,$80,$00,$F9,$00,$F1,$14
            !BYTE $80,$00,$80,$00,$D3,$00,$F1,$14
            !BYTE $D1,$00,$01,$05,$FF,$04,$01,$05
            !BYTE $FF,$04,$03,$05,$00,$44,$FC,$04
            !BYTE $03,$45,$00,$01,$FF,$04,$01,$05
            !BYTE $FF,$04,$03,$44,$00,$41,$FF,$11
            !BYTE $01,$51,$FE,$11,$02,$00,$50,$FF
            !BYTE $04,$01,$50,$FD,$00,$09,$14,$41
            !BYTE $40,$14,$01,$41,$14,$00,$15,$FF
            !BYTE $10,$01,$14,$FF,$10,$03,$15,$00
            !BYTE $15,$FC,$10,$01,$15,$FF,$00,$FC
            !BYTE $40,$FF,$00,$01,$05,$FB,$01,$02
            !BYTE $00,$45,$FC,$01,$04,$05,$00,$44
            !BYTE $05,$FD,$04,$05,$44,$00,$04,$14
            !BYTE $44,$FD,$04,$02,$00,$54,$FF,$40
            !BYTE $01,$50,$FF,$40,$01,$54,$FF,$00
            !BYTE $FF,$10,$01,$00,$FF,$10,$80,$00
            !BYTE $F8,$00,$F1,$14,$80,$00,$80,$00
            !BYTE $D3,$00,$F1,$14,$F9,$00,$01,$54
            !BYTE $FF,$41,$01,$54,$FE,$41,$02,$00
            !BYTE $05,$FC,$10,$03,$05,$00,$05,$FF
            !BYTE $44,$01,$45,$FF,$44,$03,$05,$00
            !BYTE $40,$FF,$11,$01,$41,$FF,$11,$03
            !BYTE $40,$00,$50,$FC,$04,$03,$50,$00
            !BYTE $54,$FB,$10,$08,$00,$14,$41,$40
            !BYTE $14,$01,$41,$14,$F8,$00,$01,$15
            !BYTE $FF,$10,$01,$15,$FE,$10,$02,$00
            !BYTE $05,$FF,$44,$01,$05,$FF,$44,$04
            !BYTE $45,$00,$44,$05,$FD,$04,$05,$44
            !BYTE $00,$04,$14,$44,$FD,$04,$02,$00
            !BYTE $14,$FF,$41,$01,$55,$FE,$41,$02
            !BYTE $00,$15,$FC,$04,$03,$15,$00,$10
            !BYTE $FF,$14,$FF,$11,$FF,$10,$02,$00
            !BYTE $45,$FC,$41,$03,$45,$00,$44,$FF
            !BYTE $05,$FE,$04,$03,$44,$00,$10,$FF
            !BYTE $11,$FF,$51,$07,$11,$10,$00,$50
            !BYTE $04,$00,$14,$FF,$04,$01,$50,$FE
            !BYTE $00,$FF,$10,$01,$00,$FF,$10,$80
            !BYTE $00,$F9,$00,$F1,$14,$80,$00,$80
            !BYTE $00,$D3,$00,$F1,$14,$01,$05,$FF
            !BYTE $10,$09,$05,$00,$10,$05,$00,$05
            !BYTE $44,$04,$05,$FF,$44,$03,$05,$00
            !BYTE $41,$FC,$04,$04,$41,$00,$41,$11
            !BYTE $FE,$01,$04,$11,$41,$00,$50,$FF
            !BYTE $04,$01,$50,$FE,$04,$02,$00,$54
            !BYTE $FF,$40,$01,$50,$FF,$40,$03,$54
            !BYTE $00,$54,$FB,$10,$08,$00,$14,$41
            !BYTE $40,$14,$01,$41,$14,$F8,$00,$01
            !BYTE $15,$FF,$10,$01,$15,$FE,$10,$02
            !BYTE $00,$05,$FF,$44,$01,$05,$FF,$44
            !BYTE $04,$45,$00,$44,$05,$FD,$04,$05
            !BYTE $44,$00,$04,$14,$44,$FD,$04,$02
            !BYTE $00,$14,$FF,$41,$01,$55,$FE,$41
            !BYTE $02,$00,$15,$FC,$04,$03,$15,$00
            !BYTE $10,$FF,$14,$FF,$11,$FF,$10,$02
            !BYTE $00,$45,$FC,$41,$03,$45,$00,$44
            !BYTE $FF,$05,$FE,$04,$03,$44,$00,$10
            !BYTE $FF,$11,$FF,$51,$07,$11,$10,$00
            !BYTE $50,$04,$00,$14,$FF,$04,$01,$50
            !BYTE $FE,$00,$FF,$10,$01,$00,$FF,$10
            !BYTE $80,$00,$F9,$00,$F1,$14,$80,$00
            !BYTE $80,$00,$D3,$00,$F1,$14,$C1,$00
            !BYTE $FA,$01,$02,$00,$50,$FC,$04,$03
            !BYTE $50,$00,$54,$FC,$10,$03,$54,$00
            !BYTE $54,$FF,$40,$01,$50,$FE,$40,$02
            !BYTE $00,$54,$FF,$40,$01,$50,$FE,$40
            !BYTE $02,$00,$54,$FC,$10,$04,$54,$00
            !BYTE $14,$41,$FE,$40,$03,$41,$14,$00
            !BYTE $FB,$10,$02,$05,$00,$FB,$44,$03
            !BYTE $05,$00,$05,$FC,$01,$03,$41,$00
            !BYTE $44,$FF,$04,$01,$01,$FD,$00,$FE
            !BYTE $04,$01,$10,$FE,$40,$FE,$00,$FF
            !BYTE $10,$01,$00,$FF,$10,$80,$00,$F9
            !BYTE $00,$F1,$14,$80,$00,$80,$00,$D3
            !BYTE $00,$F1,$14,$8A,$00,$01,$01,$FA
            !BYTE $00,$01,$94,$FA,$00,$01,$05,$FA
            !BYTE $00,$01,$40,$F2,$00,$01,$18,$E3
            !BYTE $00,$01,$04,$FB,$00,$03,$2F,$3F
            !BYTE $B5,$FC,$00,$03,$40,$80,$90,$A1
            !BYTE $00,$F1,$14,$EC,$00,$01,$01,$FF
            !BYTE $05,$FC,$00,$FF,$54,$01,$58,$B6
            !BYTE $00,$01,$11,$FD,$00,$FE,$02,$01
            !BYTE $91,$FE,$01,$04,$00,$54,$59,$57
            !BYTE $FE,$5B,$03,$BB,$03,$0B,$FD,$22
            !BYTE $FE,$12,$08,$E0,$F2,$A0,$62,$92
            !BYTE $68,$98,$68,$FF,$00,$0C,$80,$40
            !BYTE $44,$89,$01,$08,$1E,$63,$60,$92
            !BYTE $DB,$3C,$EE,$00,$01,$11,$FA,$00
            !BYTE $03,$68,$00,$04,$FF,$00,$10,$45
            !BYTE $00,$97,$D8,$F3,$8D,$87,$27,$2D
            !BYTE $0D,$E0,$00,$60,$E0,$F0,$70,$FF
            !BYTE $30,$03,$00,$02,$03,$FF,$01,$FF
            !BYTE $03,$01,$02,$FF,$00,$FF,$41,$FC
            !BYTE $00,$01,$C0,$FF,$40,$02,$C8,$C0
            !BYTE $FF,$80,$02,$00,$2F,$FF,$00,$0F
            !BYTE $B7,$00,$0A,$00,$03,$89,$0D,$25
            !BYTE $35,$3D,$37,$3E,$F0,$5C,$56,$FF
            !BYTE $57,$03,$43,$2A,$BE,$D1,$00,$F1
            !BYTE $14,$F1,$00,$01,$0A,$FE,$2E,$FF
            !BYTE $2F,$02,$2D,$0B,$FF,$AC,$02,$A4
            !BYTE $BC,$FF,$F4,$03,$D4,$53,$00,$FF
            !BYTE $40,$03,$D2,$D8,$F2,$FF,$F8,$FD
            !BYTE $00,$04,$03,$30,$3F,$E7,$FB,$00
            !BYTE $02,$55,$4F,$FC,$00,$03,$02,$C9
            !BYTE $E5,$FD,$00,$04,$C0,$7C,$6F,$5A
            !BYTE $FB,$00,$02,$40,$BD,$E9,$00,$01
            !BYTE $45,$FA,$00,$03,$A8,$00,$45,$FC
            !BYTE $00,$02,$FC,$01,$FE,$25,$06,$00
            !BYTE $02,$0A,$92,$4A,$49,$FF,$29,$0B
            !BYTE $25,$27,$1D,$78,$54,$74,$D4,$74
            !BYTE $F4,$74,$F4,$FE,$00,$05,$40,$00
            !BYTE $40,$41,$4B,$FA,$00,$01,$10,$E1
            !BYTE $00,$03,$06,$02,$01,$FC,$00,$03
            !BYTE $A0,$90,$80,$FF,$00,$03,$05,$07
            !BYTE $1F,$FC,$00,$08,$90,$E0,$F4,$82
            !BYTE $EB,$3C,$00,$20,$FF,$10,$01,$8C
            !BYTE $F1,$00,$03,$2C,$0C,$0A,$FF,$02
            !BYTE $01,$01,$FF,$00,$FF,$D7,$06,$57
            !BYTE $5E,$E9,$B7,$BE,$28,$FE,$C0,$01
            !BYTE $00,$FF,$C0,$02,$0E,$39,$FB,$00
            !BYTE $02,$B0,$60,$FB,$00,$02,$01,$02
            !BYTE $FC,$00,$03,$A0,$B4,$E8,$F1,$00
            !BYTE $F1,$14,$F1,$00,$02,$06,$05,$FF
            !BYTE $01,$FD,$00,$03,$F3,$C7,$85,$FF
            !BYTE $A1,$FE,$00,$15,$A4,$8C,$87,$1D
            !BYTE $37,$7D,$FF,$FD,$E7,$FC,$30,$0A
            !BYTE $2A,$26,$28,$08,$23,$A8,$A4,$50
            !BYTE $10,$FE,$00,$02,$09,$02,$FB,$00
            !BYTE $03,$6F,$7C,$C0,$CC,$00,$04,$0A
            !BYTE $06,$0E,$06,$FF,$0D,$06,$05,$09
            !BYTE $17,$1F,$9F,$1F,$FD,$9F,$03,$D8
            !BYTE $78,$D8,$FF,$58,$0B,$78,$F8,$E8
            !BYTE $4F,$C3,$44,$45,$49,$86,$89,$8A
            !BYTE $FE,$3C,$02,$00,$80,$FE,$60,$E1
            !BYTE $00,$0B,$80,$E0,$B0,$14,$04,$80
            !BYTE $84,$40,$2E,$BF,$BD,$FF,$B4,$06
            !BYTE $F4,$E4,$FD,$78,$CD,$DD,$FF,$32
            !BYTE $08,$36,$39,$E9,$4C,$11,$33,$13
            !BYTE $01,$E7,$00,$02,$11,$02,$FB,$00
            !BYTE $03,$98,$3A,$AA,$FE,$E5,$09,$EA
            !BYTE $FA,$EE,$98,$67,$5B,$66,$5A,$66
            !BYTE $FF,$5A,$01,$03,$FE,$01,$07,$23
            !BYTE $21,$33,$23,$98,$68,$28,$FD,$2C
            !BYTE $01,$68,$F1,$00,$F1,$14,$E9,$00
            !BYTE $FD,$02,$01,$01,$FE,$00,$17,$7A
            !BYTE $5F,$5D,$75,$DD,$B7,$0F,$00,$C2
            !BYTE $72,$70,$72,$C0,$00,$20,$A8,$42
            !BYTE $53,$4B,$0B,$4E,$2E,$28,$C0,$00
            !BYTE $01,$01,$FF,$02,$06,$00,$02,$09
            !BYTE $05,$0A,$9F,$FF,$25,$FF,$00,$08
            !BYTE $60,$80,$00,$50,$40,$0A,$28,$02
            !BYTE $FE,$00,$08,$CF,$47,$45,$29,$22
            !BYTE $88,$20,$80,$FD,$60,$04,$A0,$00
            !BYTE $C0,$30,$F2,$00,$01,$01,$FD,$00
            !BYTE $01,$05,$FF,$00,$07,$1D,$00,$01
            !BYTE $03,$04,$0C,$10,$FF,$30,$0D,$00
            !BYTE $80,$C0,$20,$30,$08,$0C,$04,$BB
            !BYTE $7E,$2F,$1B,$05,$FE,$00,$08,$FE
            !BYTE $F8,$E8,$AC,$F0,$01,$0C,$70,$FC
            !BYTE $00,$03,$10,$00,$10,$E7,$00,$01
            !BYTE $14,$FC,$00,$10,$A6,$B9,$EE,$1B
            !BYTE $36,$09,$00,$03,$AA,$AB,$AF,$F8
            !BYTE $AC,$73,$02,$FB,$FF,$03,$04,$02
            !BYTE $80,$40,$80,$FF,$00,$04,$2C,$48
            !BYTE $94,$A0,$ED,$00,$F1,$14,$DF,$00
            !BYTE $01,$01,$FF,$05,$08,$21,$30,$2C
            !BYTE $64,$A4,$64,$90,$40,$FF,$00,$01
            !BYTE $F0,$C7,$00,$01,$45,$FA,$00,$03
            !BYTE $1A,$00,$05,$FD,$00,$02,$0A,$25
            !BYTE $FF,$2D,$01,$08,$FB,$00,$04,$10
            !BYTE $34,$3C,$18,$FE,$00,$09,$18,$1E
            !BYTE $63,$60,$92,$01,$00,$44,$10,$FD
            !BYTE $00,$02,$64,$78,$FF,$BC,$02,$64
            !BYTE $10,$FD,$00,$06,$80,$E0,$DC,$36
            !BYTE $0F,$02,$FB,$00,$02,$40,$80,$F9
            !BYTE $00,$FF,$18,$01,$10,$FC,$00,$FF
            !BYTE $24,$01,$04,$FA,$00,$03,$01,$00
            !BYTE $01,$FF,$02,$FF,$01,$01,$18,$FF
            !BYTE $00,$0C,$05,$40,$55,$D7,$14,$18
            !BYTE $54,$18,$58,$68,$A8,$64,$F2,$00
            !BYTE $01,$01,$FA,$00,$01,$15,$FE,$00
            !BYTE $03,$01,$06,$1B,$FF,$2F,$09,$08
            !BYTE $0C,$08,$20,$32,$23,$89,$D7,$98
            !BYTE $FD,$00,$01,$80,$FF,$E0,$E1,$00
            !BYTE $F1,$14,$F0,$00,$01,$01,$FB,$00
            !BYTE $02,$15,$55,$FB,$00,$02,$1A,$05
            !BYTE $FB,$00,$02,$90,$40,$A3,$00,$02
            !BYTE $DB,$3C,$FB,$00,$01,$11,$FA,$00
            !BYTE $01,$59,$FA,$00,$01,$A9,$FA,$00
            !BYTE $01,$40,$F2,$00,$01,$04,$FA,$00
            !BYTE $03,$55,$00,$01,$FC,$00,$01,$51
            !BYTE $FF,$54,$FC,$00,$03,$FE,$B5,$2F
            !BYTE $FC,$00,$03,$D0,$60,$80,$FB,$00
            !BYTE $01,$04,$FA,$00,$01,$51,$FB,$00
            !BYTE $03,$01,$55,$05,$FC,$00,$03,$37
            !BYTE $2D,$8B,$FC,$00,$03,$FD,$57,$5E
            !BYTE $FC,$00,$02,$D0,$40,$DB,$00,$F7
            !BYTE $14,$FF,$05,$01,$01,$FB,$00,$03
            !BYTE $40,$55,$15,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FB,$00,$FF,$55,$FB
            !BYTE $00,$FF,$55,$FC,$00,$03,$01,$55
            !BYTE $54,$FF,$00,$FF,$14,$FF,$50,$01
            !BYTE $40,$FE,$00,$00,$01,$DE,$FD,$5E
            !BYTE $01,$56,$FB,$15,$01,$56,$FF,$15
            !BYTE $01,$56,$FE,$15,$01,$56,$FA,$15
            !BYTE $01,$56,$FB,$15,$01,$56,$FD,$5E
            !BYTE $01,$DE,$FC,$5E,$01,$56,$FB,$15
            !BYTE $01,$56,$FF,$15,$01,$56,$FE,$15
            !BYTE $01,$56,$FB,$15,$02,$16,$67,$FC
            !BYTE $16,$02,$15,$56,$FB,$5E,$E8,$DE
            !BYTE $FA,$7E,$FB,$DE,$FF,$5E,$DB,$DE
            !BYTE $FF,$5E,$DB,$DE,$FF,$5E,$DB,$DE
            !BYTE $FF,$5E,$DB,$DE,$FF,$5E,$F7,$DE
            !BYTE $F6,$5E,$F0,$DE,$FF,$5E,$DB,$DE
            !BYTE $FF,$5E,$FB,$DE,$F2,$5E,$F0,$DE
            !BYTE $FF,$5E,$DB,$DE,$FF,$5E,$01,$DE
            !BYTE $FA,$5E,$01,$DE,$F5,$5E,$F0,$DE
            !BYTE $FF,$5E,$DB,$DE,$F7,$5E,$01,$DE
            !BYTE $F5,$5E,$F0,$DE,$FF,$5E,$DB,$DE
            !BYTE $FF,$5E,$F9,$DE,$F4,$5E,$F0,$DE
            !BYTE $FF,$5E,$DB,$DE,$FF,$5E,$F3,$DE
            !BYTE $02,$9E,$29,$FF,$9E,$02,$DE,$BC
            !BYTE $FE,$DE,$03,$5E,$15,$5D,$F5,$DE
            !BYTE $FF,$5E,$FF,$DE,$02,$9E,$9A,$F8
            !BYTE $DE,$03,$9E,$29,$2A,$FE,$29,$01
            !BYTE $BC,$FF,$DE,$02,$5E,$5D,$FF,$15
            !BYTE $03,$1C,$CE,$1C,$FE,$7C,$FB,$DE
            !BYTE $FF,$5E,$FF,$DE,$FF,$79,$03,$26
            !BYTE $2A,$CE,$FF,$17,$01,$27,$FE,$DE
            !BYTE $02,$5E,$9D,$FE,$29,$02,$BC,$CE
            !BYTE $FD,$DE,$02,$5D,$BD,$FF,$BC,$FF
            !BYTE $DE,$02,$BC,$7C,$FF,$34,$FF,$BC
            !BYTE $FF,$DE,$FF,$5E,$FF,$DE,$05,$9A
            !BYTE $29,$6A,$7A,$2A,$FF,$17,$FB,$DE
            !BYTE $FF,$29,$03,$12,$2A,$29,$FD,$DE
            !BYTE $04,$BC,$1C,$BC,$CE,$FF,$DE,$06
            !BYTE $BE,$4B,$13,$34,$1C,$BC,$FF,$DE
            !BYTE $FF,$5E,$FE,$DE,$04,$6E,$36,$39
            !BYTE $9B,$F9,$DE,$FF,$29,$01,$2B,$FF
            !BYTE $29,$01,$DE,$FE,$CE,$04,$1C,$BC
            !BYTE $6B,$6E,$FE,$DE,$01,$BE,$FF,$34
            !BYTE $02,$4B,$BC,$FF,$DE,$FF,$5E,$FD
            !BYTE $DE,$02,$9B,$9A,$FA,$DE,$02,$9E
            !BYTE $9A,$FF,$29,$06,$BC,$BE,$BC,$1B
            !BYTE $BC,$DE,$FF,$1C,$04,$6E,$6C,$6E
            !BYTE $DE,$FF,$BE,$03,$BC,$1C,$3B,$FD
            !BYTE $DE,$FF,$5E,$FF,$DE,$FF,$BE,$FF
            !BYTE $BC,$F6,$DE,$02,$BC,$BE,$FF,$BC
            !BYTE $02,$BE,$DE,$FE,$6E,$FF,$36,$FE
            !BYTE $BE,$03,$1B,$1C,$BE,$FD,$DE,$D8
            !BYTE $5E,$00,$FB,$0F,$FB,$06,$01,$0F
            !BYTE $FF,$06,$01,$0F,$FE,$06,$01,$0F
            !BYTE $FA,$06,$01,$0F,$FB,$06,$F5,$0F
            !BYTE $FB,$06,$01,$0F,$FF,$06,$01,$0F
            !BYTE $FE,$06,$01,$0F,$FB,$06,$02,$07
            !BYTE $0F,$FC,$07,$01,$06,$80,$0F,$80
            !BYTE $0F,$80,$0F,$80,$0F,$8E,$0F,$01
            !BYTE $0D,$E3,$0F,$01,$0D,$FF,$0A,$FB
            !BYTE $0F,$FF,$0D,$F1,$0F,$FE,$0A,$03
            !BYTE $0C,$0F,$0C,$FF,$0A,$FC,$0F,$01
            !BYTE $0D,$FF,$0A,$F3,$0F,$FF,$0B,$F8
            !BYTE $0F,$02,$0A,$0E,$FF,$0C,$02,$0F
            !BYTE $0A,$FB,$0F,$FE,$0A,$FF,$0B,$F5
            !BYTE $0F,$02,$04,$0B,$F7,$0F,$FF,$0E
            !BYTE $01,$0C,$F8,$0F,$04,$0A,$0F,$0A
            !BYTE $0B,$FB,$0F,$01,$0C,$FC,$0F,$FF
            !BYTE $0B,$01,$0C,$F8,$0F,$02,$0C,$0B
            !BYTE $F8,$0F,$FF,$0A,$FE,$0F,$01,$0C
            !BYTE $FC,$0F,$01,$0E,$DA,$0F,$FF,$0E
            !BYTE $FE,$0F,$01,$0C,$D2,$0F,$00,$00

!warn "GAME USED: ", (*-ADDR_GAME)
!warn "GAME AVAILABLE: ", SIZE_GAME-(*-ADDR_GAME)

!if * > ADDR_GAME+SIZE_GAME {
  !serious "GAME TOO BIG"
}

