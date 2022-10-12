!TO         "loader-64x", CBM
!SYMBOLLIST "loader.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"
!SOURCE     "hrintro.sym"
!SOURCE     "mcbackground.sym"
!SOURCE     "mcendgame.sym"

!SOURCE     "hrfont.sym"
!SOURCE     "mcfont.sym"
!SOURCE     "hrsprites.sym"
!SOURCE     "mcweapons.sym"
!SOURCE     "mcitems.sym"
!SOURCE     "mcfaces.sym"
!SOURCE     "mctiles.sym"
!SOURCE     "game.sym"

; disk order
; ----------
; boot-64x
; loader-64x
; intro-64x    (BITMAP  ONLY)
; common-64x
; faces-64x    (BITMAP  ONLY)
; game0-64x
; graphics-64x (BITMAP  ONLY)
; music.c64    (CHARMAP ONLY)
; music-64x (BITMAP  ONLY)
; game1-64x
; tileset.gfx  (CHARMAP ONLY)
; tileset-64x  (BITMAP  ONLY)
; gfxfont.prg  (CHARMAP ONLY)
; sprites-64x
; level-a-64x
; level-b-64x
; level-c-64x
; level-d-64x
; level-e-64x
; level-f-64x
; level-g-64x
; level-h-64x
; level-i-64x
; level-j-64x
; level-k-64x
; level-l-64x
; level-m-64x

* = ADDR_LOADER

LOADER

            HRINTRO_FILE = "hrintro-64x"
            +LDCFILE HRINTRO_FILE, ADDR_HRINTRO, SIZE_HRINTRO
            JSR stash_hrintro

            +STI CI2PRA, %10010100 ; MOVE VIC-II TO $C000-$FFFF REGION via CIA2 PORT A

            +STI VMCSB, %00111000 ; MOVE SCREEN RAM to $CC00 & CHARSET/BITMAP AT $E000
!IF VIC_BITMAP {
            +STI SCROLY, %00111011 ; enable bitmap mode
            +STI SCROLX, %00011000 ; enable multicolor mode
            +MORAI $01, 4          ; disable charset rom
}

            +STI SCROLX, %00001000 ; enable high resolution mode

            +STIW $FB, $E000+(7*320)+(1*8)

            JSR PROGRESS

            MCBACKGROUND_FILE = "mcbackground-64x"
            +LDCFILE MCBACKGROUND_FILE, ADDR_MCBACKGROUND, SIZE_MCBACKGROUND
            JSR stash_mcbackground
            JSR PROGRESS
            JSR PROGRESS

            MCENDGAME_FILE = "mcendgame-64x"
            +LDCFILE MCENDGAME_FILE, ADDR_MCENDGAME, SIZE_MCENDGAME
            JSR stash_mcendgame
            JSR PROGRESS

            HRFONT_FILE = "hrfont-64x"
            +LDCFILE HRFONT_FILE, ADDR_HRFONT, SIZE_HRFONT
            JSR stash_hrfont
            JSR PROGRESS

            MCFONT_FILE = "mcfont-64x"
            +LDCFILE MCFONT_FILE, ADDR_MCFONT, SIZE_MCFONT
            JSR stash_mcfont
            JSR PROGRESS

            HRSPRITES_FILE = "hrsprites-64x"
            +LDCFILE HRSPRITES_FILE, ADDR_HRSPRITES, SIZE_HRSPRITES
            JSR stash_hrsprites
            JSR PROGRESS

            MCWEAPONS_FILE = "mcweapons-64x"
            +LDCFILE MCWEAPONS_FILE, ADDR_MCWEAPONS, SIZE_MCWEAPONS
            JSR stash_mcweapons
            JSR PROGRESS

            MCITEMS_FILE = "mcitems-64x"
            +LDCFILE MCITEMS_FILE, ADDR_MCITEMS, SIZE_MCITEMS
            JSR stash_mcitems
            JSR PROGRESS

            MCFACES_FILE = "mcfaces-64x"
            +LDCFILE MCFACES_FILE, ADDR_MCFACES, SIZE_MCFACES
            JSR stash_mcfaces
            JSR PROGRESS

            MCTILES_FILE = "mctiles-64x"
            +LDCFILE MCTILES_FILE, ADDR_MCTILES, SIZE_MCTILES
            JSR stash_mctiles
            JSR PROGRESS

            GAME_FILE = "game-64x"
            +LDCFILE GAME_FILE, ADDR_GAME, SIZE_GAME
            JSR PROGRESS
            JSR PROGRESS
            JSR PROGRESS

!IF VIC_CHARMAP {
            MUSIC_MSG  = "loading music"
            MUSIC_FILE = "music.c64"
            +LDCFILE MUSIC_MSG, MUSIC_FILE, ADDR_MUSIC, SIZE_MUSIC
}

!IF VIC_BITMAP {
            MUSIC_FILE = "music-64x"
            +LDCFILE MUSIC_FILE, ADDR_MUSIC, SIZE_MUSIC
}

            JSR PROGRESS ; show progress after loading music

            TILE_FILE = "tileset-64x"
            +LDCFILE TILE_FILE, ADDR_TILE, SIZE_TILE

            JSR PROGRESS

            +STI SCREEN_SHAKE, MUSIC_STATE, 0

!IF VIC_CHARMAP {
            CHARSET_MSG  = "loading charset"
            CHARSET_FILE = "gfxfont.prg"
            +LDCFILE CHARSET_MSG, CHARSET_FILE, ADDR_CHARSET, SIZE_CHARSET
}

            SEI     ; Disable interrupt routine
            +STIW CINV, RUNIRQ ; Setup IRQ to visit my routine RUNIRQ before system IRQ routine
           ;+STIW $DC06, 17041 ; 1/60 of a second (cycles NTSC: 17041.58, PAL: 16501.65)
           ;LDA   $0A03
           ;BEQ   +
           ;+STIW $DC06, 16501
+          ;+STI  $DC0D, %10000010
           ;+STI  $DC0F, %00000001
           ;+STIW NMINV, C_RUNNMI ; Setup NMI to visit my routine RUNIRQ as NMI vs IRQ
            CLI     ; Reenable routine.

            JMP START_GAME

PROGRESS    SEI
            LDA $01
            PHA
            AND #$F8
            STA $01

            LDY #0
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            INY
            LDA ($FB),Y
            EOR #$FF
            STA ($FB),Y
            CLC
            LDA $FB
            ADC #8
            STA $FB
            LDA $FC
            ADC #0
            STA $FC

            +PL $01
            CLI

            RTS

;PROGRESS    LDY #5
;            LDA #%00011000
;            STA ($FB),Y
;            INY
;            STA ($FB),Y
;            CLC
;            LDA $FB
;            ADC #8
;            STA $FB
;            LDA $FC
;            ADC #0
;            STA $FC
;            RTS

!if * > ADDR_LOADER+SIZE_LOADER {
  !serious "LOADER TOO BIG"
}

