; Boot sector brainfuck

cpu 386
section boot
org 0x7c00

tape:	equ 0x8200	; Tape location
stack:	equ 0xff00	; Stack
input:	equ 0x7e00	; Input buffer

start:
	mov sp, stack
	push cs
	push cs
	push cs
	pop ds
	pop es
	pop ss

	cld
	mov bx, tape
.1:	mov byte [bx], 0
	inc bx
	jne .1
	
	mov bp, tape
	jmp main

clrf:
	push ax
	mov ah, 0xe
	mov al, 0xa
	int 10h
	mov al, 0xd
	int 10h
	pop ax
	ret
putc:
	push ax
	mov ah, 0xe
	int 10h
	pop ax
	ret
puts:
	push ax
	push si
	mov ah, 0xe
.1:	lodsb
	or al, al
	je .2
	int 10h
	jmp .1
.2:	pop si
	pop ax
	ret
getc:
	mov ah, 0x0
	int 16h
	ret

; Main loop
main:
	call getline	; get line
	cmp di, input	; Hasn't changed?
	je main
	mov al, ' '
	call putc
	call runcode	; run buffered code
	jmp main

getline:
	call clrf
	push ax
	mov di, input

.1:	call getc		; Get char
	cmp	al, 8		; Backspace?
	jne .2			; no?
	
	mov ah, 0x3
	int 10h
	or dl, dl
	je .1
	dec dl
	mov ah, 0x2
	int 10h

	mov ah, 0x0
	dec di
	jmp .1

.2:	cmp al, 0xd		; Is it return key then?
	je  .4
.3:	stosb
	call putc
	jmp .1
.4:	mov al, 0
	stosb
	dec di
	pop ax
	ret

runcode:
	push ax
	push si
	mov si, input
						; switch (*ptr) {
e1:	lodsb
	cmp al, '+'	;	case '+'
	je instr_inc
	cmp al, '-'	;	case '-'
	je instr_dec
	cmp al, '>'	;	...
	je instr_mr
	cmp al, '<'
	je instr_ml
	cmp al, ','
	je instr_getc
	cmp al, '.'
	je instr_putc
	cmp al, '['
	je instr_ob
	cmp al, ']'
	je instr_cb
	cmp al, '#'
	je instr_debug
	cmp al, 0
	jne e1				; }
.2: pop si
	pop ax
	ret

instr_inc:
	inc byte [bp]
	jmp e1
instr_dec:
	dec byte [bp]
	jmp e1
instr_mr:
	inc bp
	jmp e1
instr_ml:
	dec bp
	jmp e1
instr_getc:
	push ax
	mov ah, 0x0
	int 16h
	mov [bp], al
	pop ax
	jmp e1
instr_putc:
	push ax
	mov ah, 0xe
	mov al, [bp]
	int 10h
	pop ax
	jmp e1
instr_ob:
	cmp byte [bp], 0
	jne e1
	mov cx, 1
.1:	lodsb
	cmp al, '['
	jne .2
	inc cx
.2:	cmp al, ']'
	jne .3
	dec cx
	je e1
.3:	jmp .1
instr_cb:
	cmp byte [bp], 0
	je e1
	mov cx, 1
	std
	sub si, 2
.1:	lodsb
	cmp al, ']'
	jne .2
	inc cx
.2:	cmp al, '['
	jne .1
	dec cx
	jne .1
.3:	cld
	inc si
	jmp e1
instr_debug:
	push ax
	mov al, byte [bp]
	mov ah, al
	shr al, 4
	and al, 0x0f
	call .1
	mov al, ah
	and al, 0x0f
	call .1

	mov al, ' '
	call putc
	pop ax
	jmp e1
.1:	cmp al, 0x0a
	jl .2
	add al, 'a'
	sub al, 0x0a
	call putc
	ret
.2:	add al, '0'
	call putc
	ret

times 510-($-$$) db 0x4f
db 0x55,0xaa
