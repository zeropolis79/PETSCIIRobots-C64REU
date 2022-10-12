!TO         "mcfaces-64x", CBM
!SYMBOLLIST "mcfaces.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_MCFACES = ADDR_MAIN
SIZE_MCFACES = SIZE_MAIN

* = ADDR_MCFACES

stash_mcfaces:

            +STASHI mcfaces_data, REU_ADDR_MCFACES, mcfaces_end-mcfaces_data
            RTS

mcfaces_data:
!SOURCE     "mcfaces_64x.inc"

mcfaces_end = *

!warn "MCFACES USED: ", mcfaces_end-mcfaces_data
!warn "MCFACES AVAILABLE: ", SIZE_MCFACES-(*-ADDR_MCFACES)

!if * > ADDR_MCFACES+SIZE_MCFACES {
  !serious "MCFACES TOO BIG"
}

!if mcfaces_end-mcfaces_data > REU_SIZE_MCFACES {
  !serious "MCFACES TOO BIG"
}

