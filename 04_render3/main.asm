include     "macro.asm"
; ------------------------------------------------------------------------------

            org     100h
            mov     ax, $0013
            int     10h
            mov     ax, $A000
            mov     es, ax
            call    draw2

            ret

; Нарисовать треугольник 2D
; ------------------------------------------------------------------------------
draw2:
            ; Сначала отсортировать по возрастанию
            mov     si, tri2
.R2:        lea     di, [si+4]
.R1:        mov     ax, [si+2]      ; if tri2[si] > tri2[di]:
            cmp     ax, [di+2]
            jle     @f
            mov     eax, [si]
            xchg    eax, [di]       ; swap tri2[si], tri2[di]
            xchg    eax, [si]
@@:         add     di, 4
            cmp     di, tri2+3*4
            jne     .R1
            add     si, 4
            cmp     si, tri2+2*4
            jne     .R2

            ; Вычисление грани (ABx, ABy) (ACx, ACy)
            mov     si, tri2
            sub3a   [AB.x], [si+4+0], [si+0] ; ABx = B.x-A.x
            sub3a   [AB.y], [si+4+2], [si+2] ; ABy = B.y-A.y
            sub3a   [AC.x], [si+8+0], [si+0] ; ACx = C.x-A.x
            sub3a   [AC.y], [si+8+2], [si+2] ; ACy = C.y-A.y

            ; Проверить лицевую сторону грани
            ; if (AB.y*AC.x > AB.x*AC.y): return
            mov     ax,  [AB.y]
            mul     word [AC.x]
            xchg    ax, bx
            mov     ax,  [AB.x]
            mul     word [AC.y]
            cmp     bx, ax
            jg      .END

            ; Загрузка граней
            mov     ax, [si]
            mov     [si+4], ax      ; B.x = A.x
            mov     ax, [si+2+0]
            sub     [si+2+4], ax    ; B.y -= A.y
            mov     [AC.dx], word 0
            mov     [AB.dx], word 0
brk
.R0:
            ; Нормализация x1, x2
            mov     di, [si+2]
            cmp     di, 320
            jg      .END            ; A.y >= 320
            jnb     .K1             ; A.y < 0 (т.к. отрицательные > 320)
            mov     ax, [si+0]      ; A.x
            mov     cx, [si+4]      ; B.x
            cmp     ax, cx
            jbe     .L1              ; A.x <= B.x
            xchg    ax, cx

            ; Пропуск при превышении границ
.L1:        cmp     ax, 320
            jge     .K1             ; x1 >= 320: skip
            cmp     cx, 0
            jl      .K1             ; x2 < 0: skip

            ; Ограничение по ширине
            cmp     ax, 0
            jge     .L2
            xor     ax, ax          ; if x1 < 0: x1 = 0
.L2:        cmp     cx, 320
            jl      .L3
            mov     cx, 319         ; if x2 >= 320: x2 = 319

            ; Вычисление количества точек
.L3:        imul    di, [si+2], 320 ; di=A.y*320
            add     di, ax
            sub     cx, ax
            inc     cx
brk
            ; Растеризация
            mov     al, 15
            rep     stosb

            ; Сдвиг точек вниз
.K1:        incr3   AC.dx, AC.x, AC.y, 0    ; Сдвиг AC
            incr3   AB.dx, AB.x, AB.y, 4    ; Сдвиг AB
            inc     word [si+2]             ; A.y++
            dec     word [si+2+4]           ; B.y--
            js      .K2
            jz      .K2
            jmp     .R0

            ; Загрузка грани BC
.K2:        ;

.END:       ret

; Секция с данными
; ------------------------------------------------------------------------------

; Грани треугольника
AB:
.x:         dw      0
.y:         dw      0
.dx:        dw      0

AC:         dw      0
.x:         dw      0
.y:         dw      0
.dx:        dw      0

; Рисование 2D-треугольника по 3-м точкам
tri2:       dw     60, 50           ; (x1 y1)
            dw     80, 110          ; (x2 y2)
            dw     20, 130          ; (x3 y3)

