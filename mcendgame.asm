!TO         "mcendgame-64x", CBM
!SYMBOLLIST "mcendgame.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_MCENDGAME = ADDR_MAIN
SIZE_MCENDGAME = SIZE_MAIN

* = ADDR_MCENDGAME

stash_mcendgame:

            +STASHI mcendgame_data, REU_ADDR_MCENDGAME, REU_SIZE_MCENDGAME
            RTS

mcendgame_data:
!SOURCE     "mcendgame_64x.inc"

!warn "MCENDGAME AVAILABLE: ", SIZE_MCENDGAME-(*-ADDR_MCENDGAME)

!if * > ADDR_MCENDGAME+SIZE_MCENDGAME {
  !serious "MCENDGAME TOO BIG"
}

