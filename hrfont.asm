!TO         "hrfont-64x", CBM
!SYMBOLLIST "hrfont.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_HRFONT = ADDR_MAIN
SIZE_HRFONT = SIZE_MAIN

* = ADDR_HRFONT

stash_hrfont:

            +STASHI hrfont_data, REU_ADDR_HRFONT, REU_SIZE_HRFONT
            RTS

hrfont_data:
!SOURCE     "hrfont_64x-1.inc"

!warn "HRFONT AVAILABLE: ", SIZE_HRFONT-(*-ADDR_HRFONT)

!if * > ADDR_HRFONT+SIZE_HRFONT {
  !serious "HRFONT TOO BIG"
}

