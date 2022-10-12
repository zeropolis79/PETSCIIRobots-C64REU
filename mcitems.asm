!TO         "mcitems-64x", CBM
!SYMBOLLIST "mcitems.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_MCITEMS = ADDR_MAIN
SIZE_MCITEMS = SIZE_MAIN

* = ADDR_MCITEMS

stash_mcitems:

            +STASHI mcitems_data, REU_ADDR_MCITEMS, mcitems_end-mcitems_data
            RTS

mcitems_data:
!SOURCE     "mcitems_64x.inc"

mcitems_end = *

!warn "MCITEMS USED: ", mcitems_end-mcitems_data
!warn "MCITEMS AVAILABLE: ", SIZE_MCITEMS-(*-ADDR_MCITEMS)

!if * > ADDR_MCITEMS+SIZE_MCITEMS {
  !serious "MCITEMS TOO BIG"
}

!if mcitems_end-mcitems_data > REU_SIZE_MCITEMS {
  !serious "MCITEMS TOO BIG"
}

