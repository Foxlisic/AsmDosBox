macro       brk     { int3 }

_AX          equ    si+0
_AY          equ    si+2
_BX          equ    si+4
_BY          equ    si+6
_CX          equ    si+8
_CY          equ    si+10

; a = b - c
macro       sub3a   a, b, c {
            mov     ax, b
            sub     ax, c
            mov     a, ax
}

; a += b; d += (int)(a / c); a %= c
macro       incr3   a, b, c, d {
            mov     ax, [a]
            add     ax, [b]         ; a += b
            cwd
            idiv    word [c]        ; a /= c; a %= c
            mov     [a], dx
            add     [d], ax
}
