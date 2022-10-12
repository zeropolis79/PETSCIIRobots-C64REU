!TO         "mcbackground-64x", CBM
!SYMBOLLIST "mcbackground.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_MCBACKGROUND = ADDR_MAIN
SIZE_MCBACKGROUND = SIZE_MAIN

* = ADDR_MCBACKGROUND

stash_mcbackground:

            +STASHI mcbackground_data, REU_ADDR_MCBACKGROUND, REU_SIZE_MCBACKGROUND
            RTS

mcbackground_data:
!SOURCE     "mcbackground_64x.inc"

!warn "MCBACKGROUND AVAILABLE: ", SIZE_MCBACKGROUND-(*-ADDR_MCBACKGROUND)

!if * > ADDR_MCBACKGROUND+SIZE_MCBACKGROUND {
  !serious "MCBACKGROUND TOO BIG"
}

