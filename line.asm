; ------------------------------------------------------------------------------
; Рисование линии
; x1=ax, y1=bx -> x2=cx, y2=dx; bp-цвет
; ------------------------------------------------------------------------------

line:   push    si di
        mov     si, 1       ; int (si) signx  = x1 < x2 ? 1 : -1;
        mov     di, 1       ; int (di) signy  = y1 < y2 ? 1 : -1;
        mov     [.x2], cx
        mov     [.y2], dx
        sub     cx, ax      ; int (cx) deltax = |x2 - x1|
        jge     @f
        neg     cx
        neg     si
@@:     sub     dx, bx      ; int (dx) deltay = |y2 - y1|
        jge     @f
        neg     dx
        neg     di
@@:     mov     [.sx], si   ; signx
        mov     [.sy], di   ; signy
        mov     [.dx], cx   ; deltax = |x2 - x1|
        mov     [.dy], dx   ; deltay = |y2 - y1|
        mov     si, cx      ; error = deltax - deltay
        sub     si, dx
        mov     dx, bp
.ps:    cmp     ax, 320     ; ax=[0..319], bx=[0..119]
        jnb     @f
        cmp     bx, 200
        jnb     @f
        imul    di, bx, 320 ; PSET (ax, bx)
        add     di, ax
        mov     [es: di], dl
@@:     cmp     ax, [.x2]   ; while ((x1 != x2) || (y1 != y2))
        jne     @f
        cmp     bx, [.y2]
        jne     @f
        pop     di si
        ret
@@:     mov     cx, si      ; error2 = 2*error
        add     cx, cx
        cmp     cx, [.dx]   ; if (error2 - deltax < 0):
        jg      @f
        add     si, [.dx]   ; error += deltax; y1 += signy
        add     bx, [.sy]
@@:     add     cx, [.dy]   ; if (error2 + deltay > 0):
        jle     .ps
        sub     si, [.dy]   ; error -= deltay; x1 += signx
        add     ax, [.sx]
        jmp     .ps
.sx:    dw      0
.sy:    dw      0
.dx:    dw      0
.dy:    dw      0
.x2:    dw      0
.y2:    dw      0
