!TO         "mctiles-64x", CBM
!SYMBOLLIST "mctiles.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_MCTILES = ADDR_MAIN
SIZE_MCTILES = SIZE_MAIN

* = ADDR_MCTILES

stash_mctiles:

            +STASHI mctiles_data, REU_ADDR_MCTILES, mctiles_end-mctiles_data
            RTS

mctiles_data:
!SOURCE     "mctiles_64x.inc"

mctiles_end = *

!warn "MCTILES USED: ", mctiles_end-mctiles_data
!warn "MCTILES AVAILABLE: ", SIZE_MCTILES-(*-ADDR_MCTILES)

!if * > ADDR_MCTILES+SIZE_MCTILES {
  !serious "MCTILES TOO BIG"
}

!if mctiles_end-mctiles_data > REU_SIZE_MCTILES {
  !serious "MCTILES TOO BIG"
}

