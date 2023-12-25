macro   brk     { int3 }
        org     100h
        mov     ax, 0013h
        int     10h
        mov     ax, $A000
        mov     es, ax
        ret
