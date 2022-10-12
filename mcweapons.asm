!TO         "mcweapons-64x", CBM
!SYMBOLLIST "mcweapons.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_MCWEAPONS = ADDR_MAIN
SIZE_MCWEAPONS = SIZE_MAIN

* = ADDR_MCWEAPONS

stash_mcweapons:

            +STASHI mcweapons_data, REU_ADDR_MCWEAPONS, mcweapons_end-mcweapons_data
            RTS

mcweapons_data:
!SOURCE     "mcweapons_64x.inc"

mcweapons_end = *

!warn "MCWEAPONS USED: ", mcweapons_end-mcweapons_data
!warn "MCWEAPONS AVAILABLE: ", SIZE_MCWEAPONS-(*-ADDR_MCWEAPONS)

!if * > ADDR_MCWEAPONS+SIZE_MCWEAPONS {
  !serious "MCWEAPONS TOO BIG"
}

!if mcweapons_end-mcweapons_data > REU_SIZE_MCWEAPONS {
  !serious "MCWEAPONS TOO BIG"
}

