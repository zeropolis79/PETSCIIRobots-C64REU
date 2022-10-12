!TO         "boot-64x", CBM
!SYMBOLLIST "boot.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"
!SOURCE     "loader.sym"

ADDR_BOOT = ADDR_MAIN
SIZE_BOOT = SIZE_MAIN

* = ADDR_BOOT

;******************************************************************************

.LINE_64    !WORD .BASIC_END       ; link to next line
            !WORD 64               ; line number 64
            !BYTE $9E              ; SYS token
            !BYTE $30+BOOT/1000%10 ; thousands digit of sys address
            !BYTE $30+BOOT/ 100%10 ; hundreds digit of sys address
            !BYTE $30+BOOT/  10%10 ; tens digit of sys address
            !BYTE $30+BOOT/   1%10 ; ones digit of sys address
            !PET  ":"              ; separate SYS from REM
            !BYTE $8F              ; REM token
            !BYTE $22              ; quotation mark
            !FILL 12, $14          ; delete characters to erase line to this point
            !PET  "is being attacked by petscii robots!"
            !BYTE 0                ; end of line 64
.BASIC_END  !WORD 0                ; end of BASIC program

;******************************************************************************

BOOT

!IF SHAREWARE = 1 {

!MACRO CHARAT .at, .var {
  LDA .var
  CLC
  ADC #$30

  EOR #$80
  STA $0400+.at
}

LOADNAG     LDA NAG
            BEQ COUNTDOWN

            EOR #$80
STORENAG    STA $0400

            LDA LOADNAG+1
            CLC
            ADC #1
            STA LOADNAG+1
            LDA LOADNAG+2
            ADC #0
            STA LOADNAG+2

            LDA STORENAG+1
            CLC
            ADC #1
            STA STORENAG+1
            LDA STORENAG+2
            ADC #0
            STA STORENAG+2

            JMP LOADNAG

NAGCOUNT    !BYTE 9, 9, 9

COUNTDOWN   +CHARAT 947, NAGCOUNT+0
            +CHARAT 948, NAGCOUNT+1
            +CHARAT 949, NAGCOUNT+2

            LDY #4
--          LDX #0
-           DEX
            BNE -
            DEY
            BNE --

            DEC NAGCOUNT+2
            BPL COUNTDOWN
            LDA #9
            STA NAGCOUNT+2
            DEC NAGCOUNT+1
            BPL COUNTDOWN
            LDA #9
            STA NAGCOUNT+1
            DEC NAGCOUNT+0
            BPL COUNTDOWN

-           JSR $FFE4
            BEQ -

RELOADNAG   LDA NAG
            BEQ ENDNAG

            LDA #32

CLEARNAG    STA $0400

            LDA RELOADNAG+1
            CLC
            ADC #1
            STA RELOADNAG+1
            LDA RELOADNAG+2
            ADC #0
            STA RELOADNAG+2

            LDA CLEARNAG+1
            CLC
            ADC #1
            STA CLEARNAG+1
            LDA CLEARNAG+2
            ADC #0
            STA CLEARNAG+2

            JMP RELOADNAG

ENDNAG
}

            LDX #0
-           STX .CHKBYTE+1

            ; stash byte to REU
            +STIW REC_02, .CHKBYTE+1
            +STIW REC_04, 0
            +STI  REC_06, 0
            +STIW REC_07, 1
            +STI  REC_01, %10010000

            INC .CHKBYTE+1

            ; fetch byte from REU
            +STIW REC_02, .CHKBYTE+1
            +STIW REC_04, 0
            +STI  REC_06, 0
            +STIW REC_07, 1
            +STI  REC_01, %10010001

.CHKBYTE:   CPX #0 ; imm byte will change through loop
            BNE .NEEDREU

            INX
            BEQ .CONTINUE
            JMP -
            
.NEEDREU:   LDY #0

-           LDA .missreu,Y
            JSR CHROUT
            INY
            CPY #(.missreu_end-.missreu)
            BNE -

            JMP .missreu_end

.missreu    !BYTE 147
            !PET "reu is required for this game"
.missreu_end
            RTS

.CONTINUE:
!IF SHAREWARE = 0 {
            +STI   C2DDRB, %00101000  ; Set userport data direction to output for pins 3 & 5
}

            +STI   BGCOL0, 0          ; Set background to black
            +STI   EXTCOL, 6          ; Set border to blue
            +STI   R6510, $06         ; BASIC OFF, Kernal ON, IO ON
            +STI   RPTFLG, 64         ; Set all keys to NON-repeat mode
            +STI   MODE, $80          ; Disable character set switching
            +STI   VMCSB, $15         ; Enable upper-case character set

            LDY #0

-           LDA .wakeup,Y
            JSR CHROUT
            INY
            CPY #(.wakeup_end-.wakeup)
            BNE -

            JMP .wakeup_end

.wakeup     !BYTE 147, 5
            !FILL 8, 17
            !FILL 10, 29
            !PET "waking up the robots"

            !BYTE 13, 13
            !FILL 15, 29
            !BYTE 158,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,144,$20

            !BYTE 13
            !FILL 15, 29
            !BYTE 151,18,$69,$20,$20,$20,$20,$20,$20,$20,$20,$A7,146,152,$B5

            !BYTE 13
            !FILL 15, 29
            !BYTE 151,18,$6B,$20,$20,$20,$20,$20,$20,$20,$20,$A7,146,152,$B5

            !BYTE 13
            !FILL 15, 29
            !BYTE 158,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC,144,$20

            !BYTE 13, 13, 5
            !FILL 14, 29
            !PET "ram expander"

            !BYTE 13
            !FILL 16, 29
            !PET "detected"

.wakeup_end

            LOADER_FILE = "loader-64x"
            +LDCFILE LOADER_FILE, ADDR_LOADER, SIZE_LOADER
            JMP LOADER

!IF SHAREWARE = 1 {
NAG
!BYTE $20,$20,$20,$20,$20,$20,$6c,$62,$7b,$7b,$20,$7b,$6c,$62,$20,$62,$62,$20,$62,$62,$7b,$7b,$20,$7b,$6c,$62,$20,$62,$62,$20,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62
!BYTE $20,$20,$20,$20,$20,$20,$7f,$62,$20,$fc,$62,$61,$fc,$62,$61,$fc,$62,$7e,$fc,$62,$20,$61,$61,$61,$fc,$62,$61,$fc,$62,$7e,$fc,$62,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $62,$62,$62,$62,$62,$62,$62,$62,$7e,$61,$20,$61,$61,$20,$61,$61,$20,$61,$fc,$62,$7b,$7f,$7f,$7e,$61,$20,$61,$61,$20,$61,$fc,$62,$7b,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$01,$14,$14,$01,$03,$0b,$20,$0f,$06,$20,$14,$08,$05,$20,$10,$05,$14,$13,$03,$09,$09,$20,$12,$0f,$02,$0f,$14,$13,$20,$03,$36,$34,$20,$20,$20,$20,$20
!BYTE $13,$08,$01,$12,$05,$17,$01,$12,$05,$20,$16,$05,$12,$13,$09,$0f,$0e,$20,$09,$13,$20,$06,$12,$05,$05,$20,$14,$0f,$20,$04,$09,$13,$14,$12,$09,$02,$15,$14,$05,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$19,$0f,$15,$20,$03,$01,$0e,$20,$04,$0f,$17,$0e,$0c,$0f,$01,$04,$20,$01,$20,$06,$12,$05,$05,$20,$03,$0f,$10,$19,$20,$0f,$06,$20,$14,$08,$05,$20,$20,$20
!BYTE $20,$15,$13,$05,$12,$27,$13,$20,$0d,$01,$0e,$15,$01,$0c,$20,$0f,$12,$20,$02,$15,$19,$20,$14,$08,$05,$20,$06,$15,$0c,$0c,$20,$16,$05,$12,$13,$09,$0f,$0e,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$01,$14,$20,$17,$17,$17,$2e,$14,$08,$05,$38,$02,$09,$14,$07,$15,$19,$2e,$03,$0f,$0d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$2a,$2a,$2a,$20,$06,$15,$0c,$0c,$20,$16,$05,$12,$13,$09,$0f,$0e,$20,$09,$0e,$03,$0c,$15,$04,$05,$13,$20,$2a,$2a,$2a,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$2d,$20,$01,$0c,$0c,$20,$31,$35,$20,$0c,$05,$16,$05,$0c,$13,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$2d,$20,$13,$0e,$05,$13,$20,$03,$0f,$0e,$14,$12,$0f,$0c,$0c,$05,$12,$20,$13,$15,$10,$10,$0f,$12,$14,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

!SCR  "       - hotkey for robot locations     "
; !BYTE $20,$20,$20,$20,$20,$20,$20,$2d,$20,$03,$36,$34,$2c,$20,$16,$09,$03,$2d,$32,$30,$2c,$20,$26,$20,$10,$05,$14,$20,$16,$05,$12,$13,$09,$0f,$0e,$13,$20,$20,$20,$20

!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$2d,$20,$07,$05,$14,$20,$12,$09,$04,$20,$0f,$06,$20,$14,$08,$09,$13,$20,$0e,$01,$07,$07,$09,$0e,$07,$20,$13,$03,$12,$05,$05,$0e,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$10,$12,$05,$13,$13,$20,$01,$0e,$19,$20,$0b,$05,$19,$20,$14,$0f,$20,$03,$0f,$0e,$14,$09,$0e,$15,$05,$20,$0f,$0e,$03,$05,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$14,$09,$0d,$05,$12,$20,$12,$05,$01,$03,$08,$20,$1a,$05,$12,$0f,$3a,$20,$30,$30,$30,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
!BYTE $00
}

;******************************************************************************

!if * > ADDR_BOOT+SIZE_BOOT {
  !serious "BOOT TOO BIG"
}

