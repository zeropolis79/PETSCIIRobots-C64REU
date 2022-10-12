!MACRO STI .m, .i {
            LDA #.i
            STA .m
}

!MACRO STI .m0, .m1, .i {
            LDA #.i
            STA .m1
            STA .m0
}

!MACRO STI .m0, .m1, .m2, .i {
            LDA #.i
            STA .m0
            STA .m1
            STA .m2
}

!MACRO STM .d, .s {
            LDA .s
            STA .d
}

!MACRO STIW .m, .i {
            LDA #<.i ; set low byte
            STA .m+0
            LDA #>.i ; set high byte
            STA .m+1
}

!MACRO MANDI .m, .i {
            LDA .m
            AND #.i
            STA .m
}

!MACRO MORAI .m, .i {
            LDA .m
            ORA #.i
            STA .m
}

!MACRO LDMSG .msg {
            LDY #0

-           LDA .data,Y
            JSR CHROUT
            INY
            CPY #(.end-.data)
            BNE -

            JMP .end

.data       !PET 5, .msg, 13
.end
}

!MACRO LDVFILE .file, .len, .addr, .maxsz {
            LDA #.len ;LENGTH OF FILENAME
            LDX #<.file
            LDY #>.file
            JSR SETNAM ;SETNAM A=FILE NAME LENGTH X/Y=POINTER TO FILENAME

            LDA #$02
            ;LDX #$08
            LDX $BA
            LDY #$00
            JSR SETLFS ;SETFLS A=LOGICAL NUMBER X=DEVICE NUMBER Y=SECONDARY

            LDX #<.addr  ;LOW BYTE FOR LOAD ADDRESS
            LDY #>.addr  ;HIGH BYTE FOR LOAD ADDRESS
            LDA #$00
            JSR LOAD ;LOAD FILE A=0 FOR LOAD X/Y=LOAD ADDRESS

            PHP

            JSR CLOSE ;CLOSE FILE

            PLP

            ; TODO (maybe) add error checking to ensure successful load and not too big
}

!MACRO LDCFILE .file, .addr, .maxsz {
            +LDVFILE .data, (.end-.data), .addr, .maxsz
            JMP .end
.data       !PET .file
.end
}

!MACRO LDCFILE .msg, .file, .addr, .maxsz {
            +LDMSG .msg
            +LDCFILE .file, .addr, .maxsz
}

!MACRO CP .d, .s {
            LDA .s
            STA .d
}

!MACRO PHI .v {
            LDA #.v
            PHA
}

!MACRO PH .m {
            LDA .m
            PHA
}

!MACRO PL .m {
            PLA
            STA .m
}

!MACRO PHW .m {
            LDA .m+1
            PHA
            LDA .m+0
            PHA
}

!MACRO PLW .m {
            PLA
            STA .m+0
            PLA
            STA .m+1
}

!MACRO WAIT_VDC {
-           BIT VDCASR
            BPL -
}

!MACRO STIVDC .v {
            +WAIT_VDC
            +STI VDCDAT, .v
}

!MACRO STIVDC .r, .v {
            LDX #.r
            STX VDCASR
            +STIVDC .v
}

!MACRO STIWVDC .r, .v {
            +STIVDC .r+0, >.v
            +STIVDC .r+1, <.v
}

!MACRO STWVDC .r, .a {
            LDA .a+1
            +STVDC .r+0
            LDA .a+0
            +STVDC .r+1
}

!MACRO STVDC {
            +WAIT_VDC
            STA VDCDAT
}

!MACRO STVDC .r {
            LDX #.r
            STX VDCASR
            +STVDC
}

!MACRO STVDC .r, .a {
            LDA .a
            +STVDC .r
}

!MACRO LDVDC {
            +WAIT_VDC
            LDA VDCDAT
}

!MACRO LDVDC .r {
            LDX #.r
            STX VDCASR
            +LDVDC
}

!MACRO CMPI_BEQ .k, .l {
            CMP #.k
            BNE +
            JMP .l
+
}

!MACRO CMPM_BEQ .k, .l {
            CMP .k
            BNE +
            JMP .l
+
}

!MACRO CMPMI_BEQ .a, .k, .l {
            LDA .a
            CMP #.k
            BNE +
            JMP .l
+
}

!MACRO DECOMPRESS_SCREEN .src, .dst {
            !IF .dst = SCREEN_MEMORY {
              +STIW DECOMPRESS_BYTE+1, DECOMPRESS_SCREEN_BYTE
            }
            !IF .dst = COLOR_MEMORY {
              +STIW DECOMPRESS_BYTE+1, DECOMPRESS_COLOR_BYTE
            }
            ;SET SOURCE
            +STIW $FB, .src
            ;SET DESTINATION
            +STIW $FD, .dst
            ;SET END
            LDA #>(.dst+1000-1)
            STA DGS5+1
            LDA #<(.dst+1000-1)
            STA DGS6+1
            JSR DECOMPRESS_SCREEN
}

!MACRO ADDW .a {
            CLC
            ADC .a+0
            STA .a+0
            BCC +
            INC .a+1
+
}

!MACRO ADDW .a, .v {
            CLC
            !IF <.v != 0 {
              LDA .a+0
              ADC #<.v
              STA .a+0
            }
            !IF >.v != 0 {
              LDA .a+1
              ADC #>.v
              STA .a+1
            } ELSE {
              BCC +
              INC .a+1
+
            }
}

!MACRO SUBW .a, .v {
            SEC
            !IF <.v != 0 {
              LDA .a+0
              SBC #<.v
              STA .a+0
            }
            !IF >.v != 0 {
              LDA .a+1
              SBC #>.v
              STA .a+1
            } ELSE {
              BCS +
              DEC .a+1
+
            }
}

!MACRO ADD .a, .v {
            CLC
            LDA .a
            ADC #.v
            STA .a
}

!MACRO SUB .a, .v {
            SEC
            LDA .a
            SBC #.v
            STA .a
}

!MACRO LSRW .a {
            LSR .a+1
            ROR .a+0
}

!MACRO PHX {
            TXA
            PHA
}

!MACRO PLX {
            PLA
            TAX
}

!MACRO PHY {
            TYA
            PHA
}

!MACRO PLY {
            PLA
            TAY
}

!MACRO TXY {
            TXA
            TAY
}

!MACRO MEORI .a, .v {
            LDA .a
            EOR #.v
            STA .a
}

!MACRO PHALL {
            PHP
            PHA
            +PHX
            +PHY
}

!MACRO PLALL {
            +PLY
            +PLX
            PLA
            PLP
}

; macro to call when the map changes
!MACRO VDC_MAP_CHANGED {
            +PHALL

            LDY VDC_MAP_DRAW_COUNT
            TXA
            STA VDC_MAP_DRAW_UNIT,Y
            INC VDC_MAP_DRAW_COUNT

            LDY VDC_MAP_ERASE_COUNT
            LDA UNIT_LOC_X,X
            STA VDC_MAP_ERASE_LOC_X,Y
            LDA UNIT_LOC_Y,X
            STA VDC_MAP_ERASE_LOC_Y,Y
            INC VDC_MAP_ERASE_COUNT

            LDX VDC_MAP_DRAW_COUNT
            CPX #64
            BEQ +

            LDX VDC_MAP_ERASE_COUNT
            CPX #64
            BEQ +
            JMP ++

+           JSR VDC_MAP_DRAW_UNITS

++          +PLALL
}

; macro to call when the map changes
!MACRO VDC_MAP_CHANGED .x, .y {
            +PHALL

            LDX VDC_MAP_ERASE_COUNT
            LDA .x
            STA VDC_MAP_ERASE_LOC_X,X
            LDA .y
            STA VDC_MAP_ERASE_LOC_Y,X
            INC VDC_MAP_ERASE_COUNT

            LDX VDC_MAP_ERASE_COUNT
            CPX #64
            BEQ +
            JMP ++

+           JSR VDC_MAP_DRAW_UNITS

++          +PLALL
}

!MACRO REUI .sys, .reu, .sz, .mode {
            +STIW $DF02, .sys
            +STIW $DF04, .reu
            +STI  $DF06, ^.reu
            +STIW $DF07, .sz
            +STI  $DF01, %10010000+.mode
}

!MACRO STASHI .sys, .reu, .sz {
            +REUI .sys, .reu, .sz, 0
}

!MACRO FETCHI .sys, .reu, .sz {
            +REUI .sys, .reu, .sz, 1
}

!MACRO ASLWM .addr {
            ASL .addr+0
            ROL .addr+1
}

!MACRO ADDWM .dst, .src {
            CLC
            LDA .dst+0
            ADC .src+0
            STA .dst+0
            LDA .dst+1
            ADC .src+1
            STA .dst+1
}

