
VIC_CHARMAP         =  0
VIC_BITMAP          =  1

SHAREWARE           =  0

!IF SHAREWARE = 0 {
MAP_COUNT           = 15
CONTROL_TYPES_COUNT =  3
}

!IF SHAREWARE = 1 {
MAP_COUNT           =  2
CONTROL_TYPES_COUNT =  2
}

ADDR_ZP                = $0000
ADDR_STACK             = $0100
ADDR_SYSVARS           = $0200
ADDR_UNUSED            = $0400
ADDR_MISC              = $0600
ADDR_AVAILABLE         = $0800
ADDR_MAPVARS           = $7D00
ADDR_MAPDATA           = $8000
ADDR_MUSIC             = $A000
ADDR_DESTRUCTPATH      = $CA00
ADDR_TILEATTRIB        = $CB00
ADDR_COLOR12           = $CC00
ADDR_IO                = $D000
ADDR_VIC               = $D000
ADDR_SID               = $D400
ADDR_COLOR3            = $D800
ADDR_CIA1              = $DC00
ADDR_CIA2              = $DD00
ADDR_IORESERVED        = $DE00
ADDR_REC               = $DF00
ADDR_BITMAP            = $E000

SIZE_ZP                = ADDR_STACK-ADDR_ZP
SIZE_STACK             = ADDR_SYSVARS-ADDR_STACK
SIZE_SYSVARS           = ADDR_UNUSED-ADDR_SYSVARS
SIZE_UNUSED            = ADDR_MISC-ADDR_UNUSED
SIZE_MISC              = ADDR_AVAILABLE-ADDR_MISC
SIZE_AVAILABLE         = ADDR_MAPVARS-ADDR_AVAILABLE
SIZE_MAPVARS           = ADDR_MAPDATA-ADDR_MAPVARS
SIZE_MAPDATA           = ADDR_MUSIC-ADDR_MAPDATA
SIZE_MUSIC             = ADDR_DESTRUCTPATH-ADDR_MUSIC
SIZE_DESTRUCTPATH      = ADDR_TILEATTRIB-ADDR_DESTRUCTPATH
SIZE_TILEATTRIB        = ADDR_COLOR12-ADDR_TILEATTRIB
SIZE_COLOR12           = ADDR_IO-ADDR_COLOR12
SIZE_IO                = ADDR_VIC-ADDR_IO
SIZE_VIC               = ADDR_SID-ADDR_VIC
SIZE_SID               = ADDR_COLOR3-ADDR_SID
SIZE_COLOR3            = ADDR_CIA1-ADDR_COLOR3
SIZE_CIA1              = ADDR_CIA2-ADDR_CIA1
SIZE_CIA2              = ADDR_IORESERVED-ADDR_CIA2
SIZE_IORESERVED        = ADDR_REC-ADDR_IORESERVED
SIZE_REC               = ADDR_BITMAP-ADDR_REC
SIZE_BITMAP            = $10000-ADDR_BITMAP

ADDR_MAIN              = ADDR_AVAILABLE+1
SIZE_MAIN              = SIZE_AVAILABLE-1

ADDR_LOADER            = ADDR_MAPVARS
SIZE_LOADER            = SIZE_MAPVARS+SIZE_MAPDATA

ADDR_TILE              = ADDR_DESTRUCTPATH
SIZE_TILE              = SIZE_DESTRUCTPATH+SIZE_TILEATTRIB

REU_ADDR_HRINTRO       = $000000
REU_ADDR_MCBACKGROUND  = $004000
REU_ADDR_MCENDGAME     = $008000
REU_ADDR_MCSAVE        = $00C000

REU_ADDR_HRFONT        = $010000
REU_ADDR_MCFONT        = $010800
REU_ADDR_HRSPRITES     = $011000
REU_ADDR_MCWEAPONS     = $012000
REU_ADDR_MCITEMS       = $012200
REU_ADDR_MCFACES       = $012600
REU_ADDR_MCTILES       = $018000

REU_SIZE_HRINTRO       = 1024*(8+1) ; 1K*(bitmapK+colorK)
REU_SIZE_MCBACKGROUND  = 1024*(8+2) ; 1K*(bitmapK+colorK)
REU_SIZE_MCENDGAME     = 1024*(8+2) ; 1K*(bitmapK+colorK)

REU_SIZE_HRFONT        =      8*256    ;              bytes*count
REU_SIZE_MCFONT        =      8*256    ;              bytes*count
REU_SIZE_HRSPRITES     =     64* 46    ;              bytes*count
REU_SIZE_MCWEAPONS     = 6*3*(8+2)*  2 ; w*h*(bitmap+color)*count
REU_SIZE_MCITEMS       = 6*4*(8+2)*  4 ; w*h*(bitmap+color)*count
REU_SIZE_MCFACES       = 6*7*(8+2)*  6 ; w*h*(bitmap+color)*count
REU_SIZE_MCTILES       = 3*3*(8+2)*256 ; w*h*(bitmap+color)*count

SPRITE_BEGIN_X         = ($D000-$C000)/64

SP_MAG_CURSOR          = (SPRITE_BEGIN_X+ 0)
SP_ELEVATOR_CURSOR     = (SPRITE_BEGIN_X+ 1)
SP_PISTOL_HORZ         = (SPRITE_BEGIN_X+ 2)
SP_PISTOL_VERT         = (SPRITE_BEGIN_X+ 3)
SP_PLASMA_LEFT         = (SPRITE_BEGIN_X+ 4)
SP_PLASMA_RIGHT        = (SPRITE_BEGIN_X+ 5)
SP_PLASMA_DOWN         = (SPRITE_BEGIN_X+ 6)
SP_PLASMA_UP           = (SPRITE_BEGIN_X+ 7)
SP_BOMB                = (SPRITE_BEGIN_X+ 8)
SP_MAGNET              = (SPRITE_BEGIN_X+ 9)
SP_EXP_0               = (SPRITE_BEGIN_X+10)
SP_EXP_1               = (SPRITE_BEGIN_X+11)
SP_EXP_2               = (SPRITE_BEGIN_X+12)
SP_EXP_3               = (SPRITE_BEGIN_X+13)
SP_EXP_4               = (SPRITE_BEGIN_X+14)
SP_PLAYER_UP_1_1       = (SPRITE_BEGIN_X+15)
SP_PLAYER_UP_1_2       = (SPRITE_BEGIN_X+16)
SP_PLAYER_UP_1_3       = (SPRITE_BEGIN_X+17)
SP_PLAYER_UP_2_1       = (SPRITE_BEGIN_X+18)
SP_PLAYER_UP_2_2       = (SPRITE_BEGIN_X+19)
SP_PLAYER_UP_2_3       = (SPRITE_BEGIN_X+20)
SP_PLAYER_DN_1_1       = (SPRITE_BEGIN_X+21)
SP_PLAYER_DN_1_2       = (SPRITE_BEGIN_X+22)
SP_PLAYER_DN_1_3       = (SPRITE_BEGIN_X+23)
SP_PLAYER_DN_2_1       = (SPRITE_BEGIN_X+24)
SP_PLAYER_DN_2_2       = (SPRITE_BEGIN_X+25)
SP_PLAYER_DN_2_3       = (SPRITE_BEGIN_X+26)
SP_PLAYER_LT_1_1       = (SPRITE_BEGIN_X+27)
SP_PLAYER_LT_1_2       = (SPRITE_BEGIN_X+28)
SP_PLAYER_LT_1_3       = (SPRITE_BEGIN_X+29)
SP_PLAYER_LT_2_1       = (SPRITE_BEGIN_X+30)
SP_PLAYER_LT_2_2       = (SPRITE_BEGIN_X+31)
SP_PLAYER_LT_2_3       = (SPRITE_BEGIN_X+32)
SP_PLAYER_RT_1_1       = (SPRITE_BEGIN_X+33)
SP_PLAYER_RT_1_2       = (SPRITE_BEGIN_X+34)
SP_PLAYER_RT_1_3       = (SPRITE_BEGIN_X+35)
SP_PLAYER_RT_2_1       = (SPRITE_BEGIN_X+36)
SP_PLAYER_RT_2_2       = (SPRITE_BEGIN_X+37)
SP_PLAYER_RT_2_3       = (SPRITE_BEGIN_X+38)
SP_PLAYER_DEAD_1       = (SPRITE_BEGIN_X+39)
SP_PLAYER_DEAD_2       = (SPRITE_BEGIN_X+40)
SP_PLAYER_DEAD_3       = (SPRITE_BEGIN_X+41)
SP_EMPTY               = (SPRITE_BEGIN_X+42)
SP_SOLID_HAND          = (SPRITE_BEGIN_X+43)
SP_EMPTY_HAND          = (SPRITE_BEGIN_X+44)
SP_ARROWS              = (SPRITE_BEGIN_X+45)

NO_KEY_PRESSED         = 64

R6510                  =   $01
LSTX                   =   $C5
NDX                    =   $C6
XMAX                   = $0289
RPTFLG                 = $028A
DELAY                  = $028C
MODE                   = $0291
CINV                   = $0314
MUSIC_START            = $A000
MUSIC_PLAY             = $A003
SOUND_PLAY             = $A006
SP0X                   = $D000
SP0Y                   = $D001
SP5X                   = $D00A
SP5Y                   = $D00B
SP6X                   = $D00C
SP6Y                   = $D00D
SP7X                   = $D00E
SP7Y                   = $D00F
MSIGX                  = $D010
SCROLY                 = $D011
SPENA                  = $D015
SCROLX                 = $D016
YXPAND                 = $D017
VMCSB                  = $D018
SPMC                   = $D01C
EXTCOL                 = $D020
BGCOL0                 = $D021
SPMC0                  = $D025
SPMC1                  = $D026
SP0COL                 = $D027
SP5COL                 = $D02C
SP6COL                 = $D02D
SP7COL                 = $D02E
SIGVOL                 = $D418
CIA1_0D                = $DC0D
CI2PRA                 = $DD00
CI2PRB                 = $DD01
C2DDRB                 = $DD03
REC_01                 = $DF01
REC_02                 = $DF02
REC_03                 = $DF03
REC_04                 = $DF04
REC_05                 = $DF05
REC_06                 = $DF06
REC_07                 = $DF07
REC_08                 = $DF08
SYSIRQ                 = $EA31
GET_KEY                = $F142
SETLFS                 = $FFBA
SETNAM                 = $FFBD
CLOSE                  = $FFC3
CHROUT                 = $FFD2
LOAD                   = $FFD5
GETIN                  = $FFE4

SCREEN_MEMORY          = ADDR_COLOR12
COLOR_MEMORY           = ADDR_COLOR3

SPRITE_POINTER_0       = ADDR_COLOR12+$400-8
SPRITE_POINTER_1       = ADDR_COLOR12+$400-7
SPRITE_POINTER_2       = ADDR_COLOR12+$400-6
SPRITE_POINTER_3       = ADDR_COLOR12+$400-5
SPRITE_POINTER_4       = ADDR_COLOR12+$400-4
SPRITE_POINTER_5       = ADDR_COLOR12+$400-3
SPRITE_POINTER_6       = ADDR_COLOR12+$400-2
SPRITE_POINTER_7       = ADDR_COLOR12+$400-1

;*** Zero Page locations used ***
TILE              = $23    ;The tile number to be plotted
TEMP_X            = $24    ;Temporarily used for loops
TEMP_Y            = $25    ;Temporarily used for loops
MAP_X             = $26    ;Current X location on map
MAP_Y             = $27    ;Current Y location on map
MAP_WINDOW_X      = $28    ;Top left location of what is displayed in map window
MAP_WINDOW_Y      = $29    ;Top left location of what is displayed in map window
DECNUM            = $2A    ;a decimal number to be displayed onscreen as 3 digits.
ATTRIB            = $2B    ;Tile attribute value
UNIT              = $2C    ;Current unit being processed
TEMP_A            = $2D    ;used within some routines
TEMP_B            = $2E    ;used within some routines
TEMP_C            = $2F    ;used within some routines
TEMP_D            = $30    ;used within some routines
CURSOR_X          = $31    ;For on-screen cursor
CURSOR_Y          = $32    ;For on-screen cursor
CURSOR_ON         = $33    ;Is cursor active or not? 1=yes 0=no
REDRAW_WINDOW     = $34    ;1=yes 0=no
MOVE_RESULT       = $35    ;1=Move request success, 0=fail.
UNIT_FIND         = $36    ;255=no unit present.
MOVE_TYPE         = $37    ;%00000001=WALK %00000010=HOVER
SCREEN_SHAKE      = $38    ;0=NO 1=YES
PRECALC_COUNT     = $39    ;part of screen draw routine
GOAT_ZERO1        = $3E    ;used by goat-tracker
GOAT_ZERO2        = $3F    ;used by goat-tracker

DESTRUCT_PATH     = ADDR_DESTRUCTPATH    ;Destruct path array (256 bytes)
TILE_ATTRIB       = ADDR_TILEATTRIB      ;Tile attrib array (256 bytes)

;***These arrays can go anywhere in RAM***
UNIT_TIMER_A      = ADDR_MISC+$0000  ;Primary timer for units (64 bytes)
UNIT_TIMER_B      = ADDR_MISC+$0040  ;Secondary timer for units (64 bytes)
UNIT_TILE         = ADDR_MISC+$0080  ;Current tile assigned to unit (32 bytes)
;UNIT_ALT_MOVE    = ADDR_MISC+$00A0  ;For moving around objects (32 bytes)
;UNIT_DEST_X      = ADDR_MISC+$00C0  ;Destination X coordinate (32 bytes)
;UNIT_DEST_Y      = ADDR_MISC+$00E0  ;Destination Y coordinate (32 bytes)
EXP_BUFFER_CENTER = ADDR_MISC+$00FF  ;Extra byte for explosion buffer
EXP_BUFFER        = ADDR_MISC+$0100  ;Explosion Buffer (16 bytes)
MAP_PRECALC       = ADDR_MISC+$0110  ;Stores pre-calculated objects for map window (77 bytes)

;The following addresses are used to store the current
;state of the SNES buttons.
SNES_B            = ADDR_MISC+$015D
SNES_Y            = ADDR_MISC+$015E
SNES_SELECT       = ADDR_MISC+$015F
SNES_START        = ADDR_MISC+$0160
SNES_UP           = ADDR_MISC+$0161
SNES_DOWN         = ADDR_MISC+$0162
SNES_LEFT         = ADDR_MISC+$0163
SNES_RIGHT        = ADDR_MISC+$0164
SNES_A            = ADDR_MISC+$0165
SNES_X            = ADDR_MISC+$0166
SNES_BACK_L       = ADDR_MISC+$0167
SNES_BACK_R       = ADDR_MISC+$0168
;The following addresses are used to store the last
;state of the SNES buttons so that we can determine
;if a button was released.
LAST_B            = ADDR_MISC+$0169
LAST_Y            = ADDR_MISC+$016A
LAST_SELECT       = ADDR_MISC+$016B
LAST_START        = ADDR_MISC+$016C
LAST_UP           = ADDR_MISC+$016D
LAST_DOWN         = ADDR_MISC+$016E
LAST_LEFT         = ADDR_MISC+$016F
LAST_RIGHT        = ADDR_MISC+$0170
LAST_A            = ADDR_MISC+$0171
LAST_X            = ADDR_MISC+$0172
LAST_BACK_L       = ADDR_MISC+$0173
LAST_BACK_R       = ADDR_MISC+$0174

;The following addresses are used to store new
;presses of the SNES buttons.  Once they are set
;as a 1, it requires the game to reset them to
;0 when it is ready to be read again.
NEW_B             = ADDR_MISC+$0175
NEW_Y             = ADDR_MISC+$0176
NEW_SELECT        = ADDR_MISC+$0177
NEW_START         = ADDR_MISC+$0178
NEW_UP            = ADDR_MISC+$0179
NEW_DOWN          = ADDR_MISC+$017A
NEW_LEFT          = ADDR_MISC+$017B
NEW_RIGHT         = ADDR_MISC+$017C
NEW_A             = ADDR_MISC+$017D
NEW_X             = ADDR_MISC+$017E
NEW_BACK_L        = ADDR_MISC+$017F
NEW_BACK_R        = ADDR_MISC+$0180

;The following are the locations where the current
;key controls are stored.  These must be set before
;the game can start.
KEY_MOVE_UP       = ADDR_MISC+$0181
KEY_MOVE_DOWN     = ADDR_MISC+$0182
KEY_MOVE_LEFT     = ADDR_MISC+$0183
KEY_MOVE_RIGHT    = ADDR_MISC+$0184
KEY_FIRE_UP       = ADDR_MISC+$0185
KEY_FIRE_DOWN     = ADDR_MISC+$0186
KEY_FIRE_LEFT     = ADDR_MISC+$0187
KEY_FIRE_RIGHT    = ADDR_MISC+$0188
KEY_CYCLE_WEAPONS = ADDR_MISC+$0189
KEY_CYCLE_ITEMS   = ADDR_MISC+$018A
KEY_USE           = ADDR_MISC+$018B
KEY_SEARCH        = ADDR_MISC+$018C
KEY_MOVE          = ADDR_MISC+$018D

PLAYER_DIRECTION  = ADDR_MISC+$018E  ;0=up 6=down 12=left 18=right
MUSIC_STATE       = ADDR_MISC+$018F  ;0=music off.

;***MAP FILES CONSIST OF EVERYTHING FROM THIS POINT ON***
UNIT_TYPE         = ADDR_MAPVARS+$0000  ;Unit type 0=none (64 bytes)
UNIT_LOC_X        = ADDR_MAPVARS+$0040  ;Unit X location (64 bytes)
UNIT_LOC_Y        = ADDR_MAPVARS+$0080  ;Unit Y location (64 bytes)
UNIT_A            = ADDR_MAPVARS+$00C0
UNIT_B            = ADDR_MAPVARS+$0100
UNIT_C            = ADDR_MAPVARS+$0140
UNIT_D            = ADDR_MAPVARS+$0180
UNIT_HEALTH       = ADDR_MAPVARS+$01C0  ;Unit health (0 to 11) (64 bytes)
MAP               = ADDR_MAPDATA        ;Location of MAP (8K)
;***END OF MAP FILE***

;DIFF_LEVEL        = V_SPACE+ 0 ;   1
;USER_MUSIC_ON     = V_SPACE+ 1 ;   1
;BGTIMER1          = V_SPACE+ 2 ;   1
;SPRITECOLSTATE    = V_SPACE+ 3 ;   1
;SPRITECOLCHART    = V_SPACE+ 4 ;   8
;CONTROL           = V_SPACE+12 ;   1
;MAPNAME           = V_SPACE+13 ;  11
;KEYS_DEFINED      = V_SPACE+24 ;   1
;SELECTED_MAP      = V_SPACE+25 ;   1
;MAP_NAMES         = V_SPACE+26 ; 192

!IF 0 {

!ADDRESS {

FAR_ADDR_COMMON0_LO    = $000000
FAR_ADDR_MISC          = $000800
FAR_ADDR_COMMON        = $000B00
FAR_ADDR_REFINED0      = $001000
FAR_ADDR_GAME0         = $001300
FAR_ADDR_BOOT          = $000801
FAR_ADDR_GRAPHICS      = $003700
!IF VIC_CHARMAP {
FAR_ADDR_SOUND         = $00A000
}
!IF VIC_BITMAP {
FAR_ADDR_SOUND         = $009000
FAR_ADDR_VIC0          = $00C000
}
FAR_ADDR_IO0           = $00D000
FAR_ADDR_COMMON0_HI    = $00FF00

FAR_ADDR_COMMON1_LO    = $010000
FAR_ADDR_REFINED1      = $011000
FAR_ADDR_GAME1         = $011000
FAR_ADDR_DESTRUCTPATH  = $019B00
FAR_ADDR_TILEATTRIB    = $019C00
;;; FAR_ADDR_TILECHAR      = $018B00
;;; FAR_ADDR_TILECOLOR     = $019400
FAR_ADDR_MAPVARS       = $007D00
FAR_ADDR_MAPDATA       = $008000
FAR_ADDR_VIC1          = $01C000
FAR_ADDR_CHARSET       = $01C000
FAR_ADDR_BITMAP        = $01C000
FAR_ADDR_IO1           = $00D000
FAR_ADDR_COLOR         = $01D800
FAR_ADDR_SCREEN        = $01E000
FAR_ADDR_COMMON1_HI    = $01FF00

FAR_ADDR_TILE          = FAR_ADDR_DESTRUCTPATH
FAR_ADDR_MAP           = FAR_ADDR_MAPVARS

FAR_ADDR_HRFONT        = FAR_ADDR_BOOT
FAR_ADDR_MCBACKGROUND  = FAR_ADDR_BOOT
FAR_ADDR_MCFONT        = FAR_ADDR_BOOT
FAR_ADDR_MCFACES       = FAR_ADDR_BOOT
FAR_ADDR_HRSPRITE      = FAR_ADDR_BOOT

ADDR_MISC              = ($100*>FAR_ADDR_MISC)+(<FAR_ADDR_MISC)
ADDR_COMMON            = ($100*>FAR_ADDR_COMMON)+(<FAR_ADDR_COMMON)
ADDR_BOOT              = ($100*>FAR_ADDR_BOOT)+(<FAR_ADDR_BOOT)
ADDR_GRAPHICS          = ($100*>FAR_ADDR_GRAPHICS)+(<FAR_ADDR_GRAPHICS)
ADDR_GAME0             = ($100*>FAR_ADDR_GAME0)+(<FAR_ADDR_GAME0)
ADDR_GAME1             = ($100*>FAR_ADDR_GAME1)+(<FAR_ADDR_GAME1)
ADDR_TILE              = ($100*>FAR_ADDR_TILE)+(<FAR_ADDR_TILE)
ADDR_DESTRUCTPATH      = ($100*>FAR_ADDR_DESTRUCTPATH)+(<FAR_ADDR_DESTRUCTPATH)
ADDR_TILEATTRIB        = ($100*>FAR_ADDR_TILEATTRIB)+(<FAR_ADDR_TILEATTRIB)
;;; ADDR_TILECHAR          = ($100*>FAR_ADDR_TILECHAR)+(<FAR_ADDR_TILECHAR)
;;; ADDR_TILECOLOR         = ($100*>FAR_ADDR_TILECOLOR)+(<FAR_ADDR_TILECOLOR)
ADDR_MAPVARS           = ($100*>FAR_ADDR_MAPVARS)+(<FAR_ADDR_MAPVARS)
ADDR_MAPDATA           = ($100*>FAR_ADDR_MAPDATA)+(<FAR_ADDR_MAPDATA)
ADDR_CHARSET           = ($100*>FAR_ADDR_CHARSET)+(<FAR_ADDR_CHARSET)
ADDR_SPRITE            = ($100*>FAR_ADDR_SPRITE)+(<FAR_ADDR_SPRITE)

ADDR_BOOTSECT          = ADDR_COMMON
SIZE_BOOTSECT          = $0100

ADDR_HRFONT            = ($100*>FAR_ADDR_HRFONT)+(<FAR_ADDR_HRFONT)
SIZE_HRFONT            = FAR_ADDR_LOADER-FAR_ADDR_HRFONT

ADDR_MCBACKGROUND      = ($100*>FAR_ADDR_MCBACKGROUND)+(<FAR_ADDR_MCBACKGROUND)
SIZE_MCBACKGROUND      = FAR_ADDR_LOADER-FAR_ADDR_MCBACKGROUND

ADDR_MCFONT            = ($100*>FAR_ADDR_MCFONT)+(<FAR_ADDR_MCFONT)
SIZE_MCFONT            = FAR_ADDR_LOADER-FAR_ADDR_MCFONT

ADDR_MCFACES           = ($100*>FAR_ADDR_MCFACES)+(<FAR_ADDR_MCFACES)
SIZE_MCFACES           = FAR_ADDR_LOADER-FAR_ADDR_MCFACES

SCREEN_MEMORY          = ($100*>FAR_ADDR_SCREEN)+(<FAR_ADDR_SCREEN)
COLOR_MEMORY           = ($100*>FAR_ADDR_COLOR)+(<FAR_ADDR_COLOR)

SPRITE_BEGIN_X         = (FAR_ADDR_SPRITE-FAR_ADDR_VIC1)/64

SP_MAG_CURSOR          = (SPRITE_BEGIN_X+ 0)
SP_ELEVATOR_CURSOR     = (SPRITE_BEGIN_X+ 1)
SP_PISTOL_HORZ         = (SPRITE_BEGIN_X+ 2)
SP_PISTOL_VERT         = (SPRITE_BEGIN_X+ 3)
SP_PLASMA_LEFT         = (SPRITE_BEGIN_X+ 4)
SP_PLASMA_RIGHT        = (SPRITE_BEGIN_X+ 5)
SP_PLASMA_DOWN         = (SPRITE_BEGIN_X+ 6)
SP_PLASMA_UP           = (SPRITE_BEGIN_X+ 7)
SP_BOMB                = (SPRITE_BEGIN_X+ 8)
SP_MAGNET              = (SPRITE_BEGIN_X+ 9)
SP_EXP_0               = (SPRITE_BEGIN_X+10)
SP_EXP_1               = (SPRITE_BEGIN_X+11)
SP_EXP_2               = (SPRITE_BEGIN_X+12)
SP_EXP_3               = (SPRITE_BEGIN_X+13)
SP_EXP_4               = (SPRITE_BEGIN_X+14)
SP_PLAYER_UP_1_1       = (SPRITE_BEGIN_X+15)
SP_PLAYER_UP_1_2       = (SPRITE_BEGIN_X+16)
SP_PLAYER_UP_1_3       = (SPRITE_BEGIN_X+17)
SP_PLAYER_UP_2_1       = (SPRITE_BEGIN_X+18)
SP_PLAYER_UP_2_2       = (SPRITE_BEGIN_X+19)
SP_PLAYER_UP_2_3       = (SPRITE_BEGIN_X+20)
SP_PLAYER_DN_1_1       = (SPRITE_BEGIN_X+21)
SP_PLAYER_DN_1_2       = (SPRITE_BEGIN_X+22)
SP_PLAYER_DN_1_3       = (SPRITE_BEGIN_X+23)
SP_PLAYER_DN_2_1       = (SPRITE_BEGIN_X+24)
SP_PLAYER_DN_2_2       = (SPRITE_BEGIN_X+25)
SP_PLAYER_DN_2_3       = (SPRITE_BEGIN_X+26)
SP_PLAYER_LT_1_1       = (SPRITE_BEGIN_X+27)
SP_PLAYER_LT_1_2       = (SPRITE_BEGIN_X+28)
SP_PLAYER_LT_1_3       = (SPRITE_BEGIN_X+29)
SP_PLAYER_LT_2_1       = (SPRITE_BEGIN_X+30)
SP_PLAYER_LT_2_2       = (SPRITE_BEGIN_X+31)
SP_PLAYER_LT_2_3       = (SPRITE_BEGIN_X+32)
SP_PLAYER_RT_1_1       = (SPRITE_BEGIN_X+33)
SP_PLAYER_RT_1_2       = (SPRITE_BEGIN_X+34)
SP_PLAYER_RT_1_3       = (SPRITE_BEGIN_X+35)
SP_PLAYER_RT_2_1       = (SPRITE_BEGIN_X+36)
SP_PLAYER_RT_2_2       = (SPRITE_BEGIN_X+37)
SP_PLAYER_RT_2_3       = (SPRITE_BEGIN_X+38)
SP_PLAYER_DEAD_1       = (SPRITE_BEGIN_X+39)
SP_PLAYER_DEAD_2       = (SPRITE_BEGIN_X+40)
SP_PLAYER_DEAD_3       = (SPRITE_BEGIN_X+41)
SP_EMPTY               = (SPRITE_BEGIN_X+42)
SP_SOLID_HAND          = (SPRITE_BEGIN_X+43)
SP_EMPTY_HAND          = (SPRITE_BEGIN_X+44)
SP_ARROWS              = (SPRITE_BEGIN_X+45)

;***These arrays can go anywhere in RAM***
UNIT_TIMER_A      = ADDR_MISC+$0000  ;Primary timer for units (64 bytes)
UNIT_TIMER_B      = ADDR_MISC+$0040  ;Secondary timer for units (64 bytes)
UNIT_TILE         = ADDR_MISC+$0080  ;Current tile assigned to unit (32 bytes)
;UNIT_ALT_MOVE    = ADDR_MISC+$00A0  ;For moving around objects (32 bytes)
;UNIT_DEST_X      = ADDR_MISC+$00C0  ;Destination X coordinate (32 bytes)
;UNIT_DEST_Y      = ADDR_MISC+$00E0  ;Destination Y coordinate (32 bytes)
EXP_BUFFER_CENTER = ADDR_MISC+$00FF  ;Extra byte for explosion buffer
EXP_BUFFER        = ADDR_MISC+$0100  ;Explosion Buffer (16 bytes)
MAP_PRECALC       = ADDR_MISC+$0110  ;Stores pre-calculated objects for map window (77 bytes)

;The following addresses are used to store the current
;state of the SNES buttons.
SNES_B            = ADDR_MISC+$015D
SNES_Y            = ADDR_MISC+$015E
SNES_SELECT       = ADDR_MISC+$015F
SNES_START        = ADDR_MISC+$0160
SNES_UP           = ADDR_MISC+$0161
SNES_DOWN         = ADDR_MISC+$0162
SNES_LEFT         = ADDR_MISC+$0163
SNES_RIGHT        = ADDR_MISC+$0164
SNES_A            = ADDR_MISC+$0165
SNES_X            = ADDR_MISC+$0166
SNES_BACK_L       = ADDR_MISC+$0167
SNES_BACK_R       = ADDR_MISC+$0168
;The following addresses are used to store the last
;state of the SNES buttons so that we can determine
;if a button was released.
LAST_B            = ADDR_MISC+$0169
LAST_Y            = ADDR_MISC+$016A
LAST_SELECT       = ADDR_MISC+$016B
LAST_START        = ADDR_MISC+$016C
LAST_UP           = ADDR_MISC+$016D
LAST_DOWN         = ADDR_MISC+$016E
LAST_LEFT         = ADDR_MISC+$016F
LAST_RIGHT        = ADDR_MISC+$0170
LAST_A            = ADDR_MISC+$0171
LAST_X            = ADDR_MISC+$0172
LAST_BACK_L       = ADDR_MISC+$0173
LAST_BACK_R       = ADDR_MISC+$0174

;The following addresses are used to store new
;presses of the SNES buttons.  Once they are set
;as a 1, it requires the game to reset them to
;0 when it is ready to be read again.
NEW_B             = ADDR_MISC+$0175
NEW_Y             = ADDR_MISC+$0176
NEW_SELECT        = ADDR_MISC+$0177
NEW_START         = ADDR_MISC+$0178
NEW_UP            = ADDR_MISC+$0179
NEW_DOWN          = ADDR_MISC+$017A
NEW_LEFT          = ADDR_MISC+$017B
NEW_RIGHT         = ADDR_MISC+$017C
NEW_A             = ADDR_MISC+$017D
NEW_X             = ADDR_MISC+$017E
NEW_BACK_L        = ADDR_MISC+$017F
NEW_BACK_R        = ADDR_MISC+$0180

;The following are the locations where the current
;key controls are stored.  These must be set before
;the game can start.
KEY_MOVE_UP       = ADDR_MISC+$0181
KEY_MOVE_DOWN     = ADDR_MISC+$0182
KEY_MOVE_LEFT     = ADDR_MISC+$0183
KEY_MOVE_RIGHT    = ADDR_MISC+$0184
KEY_FIRE_UP       = ADDR_MISC+$0185
KEY_FIRE_DOWN     = ADDR_MISC+$0186
KEY_FIRE_LEFT     = ADDR_MISC+$0187
KEY_FIRE_RIGHT    = ADDR_MISC+$0188
KEY_CYCLE_WEAPONS = ADDR_MISC+$0189
KEY_CYCLE_ITEMS   = ADDR_MISC+$018A
KEY_USE           = ADDR_MISC+$018B
KEY_SEARCH        = ADDR_MISC+$018C
KEY_MOVE          = ADDR_MISC+$018D

PLAYER_DIRECTION  = ADDR_MISC+$018E  ;0=up 6=down 12=left 18=right
MUSIC_STATE       = ADDR_MISC+$018F  ;0=music off.

DESTRUCT_PATH     = ADDR_DESTRUCTPATH    ;Destruct path array (256 bytes)
TILE_ATTRIB       = ADDR_TILEATTRIB      ;Tile attrib array (256 bytes)
;;; TILE_DATA_TL      = ADDR_TILECHAR +$0000 ;Tile character top-left (256 bytes)
;;; TILE_DATA_TM      = ADDR_TILECHAR +$0100 ;Tile character top-middle (256 bytes)
;;; TILE_DATA_TR      = ADDR_TILECHAR +$0200 ;Tile character top-right (256 bytes)
;;; TILE_DATA_ML      = ADDR_TILECHAR +$0300 ;Tile character middle-left (256 bytes)
;;; TILE_DATA_MM      = ADDR_TILECHAR +$0400 ;Tile character middle-middle (256 bytes)
;;; TILE_DATA_MR      = ADDR_TILECHAR +$0500 ;Tile character middle-right (256 bytes)
;;; TILE_DATA_BL      = ADDR_TILECHAR +$0600 ;Tile character bottom-left (256 bytes)
;;; TILE_DATA_BM      = ADDR_TILECHAR +$0700 ;Tile character bottom-middle (256 bytes)
;;; TILE_DATA_BR      = ADDR_TILECHAR +$0800 ;Tile character bottom-right (256 bytes)
;;; TILE_COLOR_TL     = ADDR_TILECOLOR+$0000 ;Tile character top-left (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_TM     = ADDR_TILECOLOR+$0100 ;Tile character top-middle (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_TR     = ADDR_TILECOLOR+$0200 ;Tile character top-right (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_ML     = ADDR_TILECOLOR+$0300 ;Tile character middle-left (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_MM     = ADDR_TILECOLOR+$0400 ;Tile character middle-middle (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_MR     = ADDR_TILECOLOR+$0500 ;Tile character middle-right (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_BL     = ADDR_TILECOLOR+$0600 ;Tile character bottom-left (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_BM     = ADDR_TILECOLOR+$0700 ;Tile character bottom-middle (256 bytes) (C64/VIC/TED VERSION ONLY)
;;; TILE_COLOR_BR     = ADDR_TILECOLOR+$0800 ;Tile character bottom-right (256 bytes) (C64/VIC/TED VERSION ONLY)

SPRITE_POINTER_0  = SCREEN_MEMORY+$400-8
SPRITE_POINTER_1  = SCREEN_MEMORY+$400-7
SPRITE_POINTER_2  = SCREEN_MEMORY+$400-6
SPRITE_POINTER_3  = SCREEN_MEMORY+$400-5
SPRITE_POINTER_4  = SCREEN_MEMORY+$400-4
SPRITE_POINTER_5  = SCREEN_MEMORY+$400-3
SPRITE_POINTER_6  = SCREEN_MEMORY+$400-2
SPRITE_POINTER_7  = SCREEN_MEMORY+$400-1

NDX                =   $D0
LSTX               =   $D5
GRAPHM             =   $D8
CINV               = $0314
NMINV              = $0318
KEYCHK             = $033C
INIT_STATUS        = $0A04
XMAX               = $0A20
DELAY              = $0A24
IRQ_WRAP_FLAG      = $12FD
BASIC_PROGRAM_TEXT = $0801
J_EXECUTE_A_LINE   = $AFA5
SP0X               = $D000
SP0Y               = $D001
SP1X               = $D002
SP1Y               = $D003
SP2X               = $D004
SP2Y               = $D005
SP3X               = $D006
SP3Y               = $D007
SP4X               = $D008
SP4Y               = $D009
SP5X               = $D00A
SP5Y               = $D00B
SP6X               = $D00C
SP6Y               = $D00D
SP7X               = $D00E
SP7Y               = $D00F
MSIGX              = $D010
RASTER             = $D012
YXPAND             = $D017
VICIRQ             = $D019
SPMC               = $D01C
SPMC0              = $D025
SPMC1              = $D026
SP0COL             = $D027
SP1COL             = $D028
SP2COL             = $D029
SP3COL             = $D02A
SP4COL             = $D02B
SP5COL             = $D02C
SP6COL             = $D02D
SP7COL             = $D02E
CLKRATE            = $D030
SIGVOL             = $D418
MMURCR             = $D506
MMUP0L             = $D507
MMUP0H             = $D508
MMUP1L             = $D509
MMUP1H             = $D50A
VDCASR             = $D600
VDCDAT             = $D601
CI2PRB             = $DD01
GET_KEY            = $EEEF
IRQ                = $FA65
MMU                = $FF00
RETIRQ             = $FF33
JSETBNK            = $FF68
SETLFS             = $FFBA
SETNAM             = $FFBD
CLOSE              = $FFC3
LOAD               = $FFD5
GETIN              = $FFE4

}

NO_KEY_PRESSED = 88

SIZE_MISC      = $0200
SIZE_COMMON    = FAR_ADDR_REFINED0-FAR_ADDR_COMMON
SIZE_GAME0     = FAR_ADDR_GRAPHICS-FAR_ADDR_GAME0
SIZE_BOOT      = FAR_ADDR_LOADER-FAR_ADDR_BOOT
SIZE_GRAPHICS  = FAR_ADDR_LOADER-FAR_ADDR_GRAPHICS

SIZE_GAME1     = FAR_ADDR_DESTRUCTPATH-FAR_ADDR_GAME1
SIZE_CHARSET   = 256*2*8 ; 256 CHARACTERS PER SET, 2 SETS, 8 BYTES PER CHARACTER
SIZE_BITMAP    = (8192+1024+1024) ; enough room for the full bitmap and 2K of color data
SIZE_SPRITE    = 46*64 ; 46 SPRITES, 64 BYTES PER SPRITE

SIZE_TILE      = FAR_ADDR_MAP-FAR_ADDR_TILE
SIZE_MAP       = FAR_ADDR_VIC1-FAR_ADDR_MAP

REU_HRINTRO      = $000000
REU_HRFONT       = REU_HRINTRO+8192+1024+1024
REU_MCBACKGROUND = REU_HRFONT+2048
REU_MCFONT       = REU_MCBACKGROUND+8192+1024+1024

}
