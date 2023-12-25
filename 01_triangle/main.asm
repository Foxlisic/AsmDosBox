macro   brk     { int3 }

; ------------------------------------------------------------------------------
; Основная программа
; ------------------------------------------------------------------------------

        org     100h
        call    scr13
        call    clear
cycle:  mov     [box.cl], byte 10
        call    drawcube                ; Рисование
        call    copyscr                 ; Вывод на экран
        mov     [box.cl], byte 0
        call    drawcube                ; Удаление куба
        add     word [box.rx], 1
        add     word [box.ry], 2
        add     word [box.rz], 1
        jmp     cycle

; ------------------------------------------------------------------------------
; Нарисовать куб
; ------------------------------------------------------------------------------

drawcube:

        ; Указатель на индексы граней
        mov     si, a_face

        ; Проекция 4 точек
.next:  mov     cx, 4
        mov     di, point
@@:     lodsb
        call    proj
        mov     [di+0], ax      ; px
        mov     [di+2], bx      ; py
        add     di, 4
        loop    @b

        ; Проверка фронтальной стороны
        mov     di, point.a
        mov     ax, [di+4+2]
        sub     ax, [di+0+2]    ; ABy = p(1).y - p(0).y
        mov     bx, [di+8+0]
        sub     bx, [di+0+0]    ; ACx = p(2).x - p(0).x
        imul    bx, ax
        mov     ax, [di+4+0]
        sub     ax, [di+0+0]    ; ABx = p(1).x - p(0).x
        mov     cx, [di+8+2]
        sub     cx, [di+0+2]    ; ACy = p(2).y - p(0).y
        imul    ax, cx
        cmp     bx, ax          ; ABx * ACy - ABy * ACx
        jle     .skip

        ; Нарисовать грань куба
        push    si
        mov     si, point.a
        mov     di, point.b
.rpt:   mov     ax, [si+0]
        mov     bx, [si+2]
        mov     cx, [di+0]
        mov     dx, [di+2]
        mov     bp, [box.cl]
        call    line
        add     si, 4
        add     di, 4
        cmp     si, point.d + 4 ; Выход за пределы
        je      .end
        cmp     si, point.d     ; Если D-то следующая точка A
        jne     .rpt
        mov     di, point.a
        jmp     .rpt
.end:   pop     si

        ; Количество граней, 6
.skip:  cmp     si, a_face + (4*6)
        jne     .next
        ret

; ------------------------------------------------------------------------------
; Рассчитать проекцию PX, PY => AX, BX
; ------------------------------------------------------------------------------

proj:   push    cx
        movzx   ebx, al
        movsx   ecx, byte [a_vtx + 3*ebx + 2]    ; Z
        movsx   eax, byte [a_vtx + 3*ebx + 1]    ; Y
        movsx   ebx, byte [a_vtx + 3*ebx + 0]    ; X

        ; Умножить на 256 всё
        shl     ax, 8 ; y
        shl     bx, 8 ; x
        shl     cx, 8 ; z

        ; Повернуть куб по тем осям
        xchg    eax, ecx            ; Вокруг оси Y (Z,X)
        mov     dx, [box.ry]
        call    rotate
        xchg    eax, ecx            ; Вокруг оси Z (Y,X)
        mov     dx, [box.rz]
        call    rotate
        xchg    ebx, ecx            ; Вокруг оси X (Y,Z)
        mov     dx, [box.rx]
        call    rotate
        xchg    ebx, ecx

        ; Добавить итоговое смещение камеры
        add     ebx, [cam.x]
        add     eax, [cam.y]
        add     ecx, [cam.z]
        imul    eax, 200
        imul    ebx, 200

        ; {ax,bx} = {160 + 200*x/z, 100 - 200*y/z}
        cdq
        idiv    ecx
        xchg    eax, ebx
        cdq
        idiv    ecx
        add     ax, 160
        sub     bx, 100
        neg     bx
        pop     cx
        ret

; ------------------------------------------------------------------------------
; Вращение AX, BX при помощи FPU на угол DX
; ------------------------------------------------------------------------------

rotate: mov     [.x], ax
        mov     [.y], bx
        mov     [.r], dx

        ; Вычислить sina, cosa
        fild    word [.r]
        fld     dword [.f360]
        fdivp   st1,st0         ; r/360
        fsincos

        ; eax = x*cosa - y*sina
        fild    word [.y]
        fild    word [.x]
        fmul    st0,st2         ; x*cosa
        fxch    st1
        fmul    st0,st3         ; y*sina
        fsubp   st1,st0         ; R=x*cosa - y*sina
        fistp   dword [.t]
        mov     eax, [.t]

        ; ebx = y*cosa + x*sina
        fild    word [.x]
        fild    word [.y]
        fmulp   st2,st0         ; y*cosa
        fmulp   st2,st0         ; x*sina
        faddp   st1,st0         ; R=y*cosa + x*sina
        fistp   dword [.t]
        mov     ebx, [.t]

        ret

; Локальные переменные
.f360:  dd      100.0           ; 180/pi(57.295) * speed
.x:     dw      0
.y:     dw      0
.t:     dd      0
.r:     dw      0

; ------------------------------------------------------------------------------
; Фреймбуфер
; ------------------------------------------------------------------------------
; Видеорежим 320x200
scr13:  mov     ax, 0013h
        int     10h
        ret

; ES=CS+1000h
loadvb: mov     ax, cs
        add     ax, 1000h
        mov     es, ax
        ret

; Очистить буфер
clear:  call    loadvb
        xor     di, di
        xor     eax, eax
        mov     cx, 16000
        rep     stosd
        ret

; Копировать из буфера на экран
copyscr:

        push    ds es
        xor     si, si
        xor     di, di
        call    loadvb
        push    es
        mov     ax, $A000
        mov     es, ax
        pop     ds
        mov     cx, 16000
        rep     movsd
        pop     es ds
        ret

; ------------------------------------------------------------------------------
include "../line.asm"
; ------------------------------------------------------------------------------

;   4---5
;  /|  /|
; 0---1 |
; | 7_|_6
; |/  |/
; 3---2

; Цвет и вращение куба
box:
.cl:    db      14
.rx:    dw      0
.ry:    dw      0
.rz:    dw      0

; Вершины (8)
a_vtx:  db      -1, 1, 1    ; 0
        db       1, 1, 1    ; 1
        db       1,-1, 1    ; 2
        db      -1,-1, 1    ; 3
        db      -1, 1,-1    ; 4
        db       1, 1,-1    ; 5
        db       1,-1,-1    ; 6
        db      -1,-1,-1    ; 7

; Грани (6)
a_face: db      0,1,2,3     ; 0
        db      1,5,6,2     ; 1
        db      5,4,7,6     ; 2
        db      4,0,3,7     ; 3
        db      6,7,3,2     ; 4
        db      4,5,1,0     ; 5
; ------------------------------------------------------------------------------
cam:
.x:     dd      0
.y:     dd      0
.z:     dd      1200
; ------------------------------------------------------------------------------
point:
.a:     dw      ?, ?
.b:     dw      ?, ?
.c:     dw      ?, ?
.d:     dw      ?, ?
