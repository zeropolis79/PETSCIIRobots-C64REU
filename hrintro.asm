!TO         "hrintro-64x", CBM
!SYMBOLLIST "hrintro.sym"

!SOURCE     "const.inc"
!SOURCE     "macro.inc"

ADDR_HRINTRO = ADDR_MAIN
SIZE_HRINTRO = SIZE_MAIN

* = ADDR_HRINTRO

stash_hrintro:

            +STASHI hrintro_data, REU_ADDR_HRINTRO, REU_SIZE_HRINTRO
            +FETCHI ADDR_BITMAP,  REU_ADDR_HRINTRO+   0, 8192
            +FETCHI ADDR_COLOR12, REU_ADDR_HRINTRO+8192, 1024
            RTS

hrintro_data:
!SOURCE     "hrintro_64x.inc"

!warn "HRINTRO AVAILABLE: ", SIZE_HRINTRO-(*-ADDR_HRINTRO)

!if * > ADDR_HRINTRO+SIZE_HRINTRO {
  !serious "HRINTRO TOO BIG"
}

