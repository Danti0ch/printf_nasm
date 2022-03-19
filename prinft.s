
section .data

test_string: db "check0: %1, check1: %b, check2: %c, check3: %d, check4: %o, check5: %s, check6: %x, and I %s %x %d%%%c%b\n", 0xa, 0xa, 0xa, 0x00
msg_test:    db "stavim na zero", 0X00
string1:     db "LOVE", 0x00
;__________________________________
section .rodata

PROCENT_SYMB     equ '%'
END_STRING_VALUE equ 0X00
STDOUT_DESCR	 equ 1
alphabet: db "0123456789abcdefghi"
ASCII_a equ 0x61
ASCII_z equ 'z'
ASCII_max equ 256

SYSCALL_EXIT equ 0x3c
SYSCALL_OUTPUT equ 0x01
;__________________________________
section .bss
temp_string: resw 0x100
;__________________________________
section .text

global prinft
;global _start
;_start:
;	push 15
;	push 33
;	push 100
;	push 3802
;	push string1 	
;	push 16 * 4
;	push msg_test
;	push 8*4
;	push 777
;	push 't'
;	push 16
;	push 777
;	push test_string
;
;	call prinft
;
;	add rsp, 8*7 + 5*8
;
;	mov rax, SYSCALL_EXIT
;	xor rdi, rdi
;	syscall

;===============================================================
; model: cdecl
; args:
;	1) string pointer
;       2-inf) parms for string
; ret: 
;	rax - number of characters output
;==============================================================
prinft:
	push rbp
	mov rbp, rsp

	mov rsi, rdi
	mov qword [rbp - 0x8], rsi
	mov rdi, temp_string					; указатель на строку, в которую мы будем ложить все данные
	
	xor rcx, rcx							; args_readen = 0
string_converting:

	cmp byte [rsi], PROCENT_SYMB
	je spec_handler
	movsb

	cmp byte [rsi], END_STRING_VALUE
	jne string_converting

	jmp after_converting
spec_handler:
	inc rsi
	cmp byte [rsi], PROCENT_SYMB
	jne not_percent_spec
	mov byte [rdi], PROCENT_SYMB
	inc rsi
	inc rdi
	jmp string_converting
not_percent_spec:
		
	xor rdx, rdx
	mov dl, byte [rsi]						; dl = ascii of symb after %
	push rdi					    		; saving rdi

	mov rdi, spec_conver_alphabet			; нужно преобразовать букву в отступ для свича
	add rdi, rdx
	
	mov dl, byte [rdi]						; dl = offset для свича
	
	;mov rdi, rcx					
	;shl rdi, 3
	;add rdi, 32
	;add rdi, rbp
	mov rax, 1				; rax = arg_value
	pop rdi
	
	call [specif_cases + 8 * rdx]			; вызываем обработку спецификатора по свичу
	
	inc rsi
	inc rcx									; args_readen++
	
	cmp byte [rsi], END_STRING_VALUE
	jne string_converting

after_converting:
	push temp_string
	call strlen

	mov rdx, rax
	mov rax, SYSCALL_OUTPUT
	mov rdi, STDOUT_DESCR
	mov rsi, temp_string
	syscall									; print(temp_string)
	mov rax, 0x01
	pop rbp	
	ret
;===============================================================
; ФУНКЦИИ - ОБРАБОТЧКИ СПЕЦИФИКАТОРОВ (CASES)
;================================================================
default_spec:
	mov byte [rdi], PROCENT_SYMB
	inc rdi

	movsb
	dec rsi
	ret

int2_spec:
	push 0x02
	push rdi
	push rax
	call itoa
	
	ret

char_spec:
	mov byte [rdi], al
	inc rdi

	ret

int10_spec:
	push 0x0a
	push rdi
	push rax
	call itoa
	
	ret

int8_spec:
	push 0x08
	push rdi
	push rax
	call itoa
	
	ret

string_spec:
	push rsi
	mov rsi, rax

s_spec_loop:
	movsb
	cmp byte [rsi], 0x00
	jne s_spec_loop
	
	pop rsi
	
	ret

int16_spec:
	push 0x10
	push rdi
	push rax
	call itoa
	
	ret
;__________________________________
section .rodata

specif_cases:
	dq default_spec
	dq int2_spec
	dq int16_spec
	dq char_spec
	dq int10_spec
	dq int8_spec
	dq string_spec

; таблица преобразования ascii ---> офсет для свича
spec_conver_alphabet: 
		times ASCII_a db 0x00
		      db 0x00 ;a
		      db 0x01 ;b
	              db 0x02 ;c
	              db 0x03 ;d
                      db 0x00 ;e
	              db 0x00 ;f
	              db 0x00 ;g
	              db 0x00 ;h
	              db 0x00 ;i
	              db 0x00 ;j
	              db 0x00 ;k
	              db 0x00 ;l
	              db 0x00 ;m
	              db 0x00 ;n
	              db 0x04 ;o
	              db 0x00 ;p
	              db 0x00 ;q
	              db 0x00 ;r
	              db 0x05 ;s
	              db 0x00 ;t
	              db 0x00 ;u
	              db 0x00 ;v
	              db 0x00 ;w
	              db 0x06 ;x
	              db 0x00 ;y
	              db 0x00 ;z
		times ASCII_max - ASCII_z db 0x00
section .text
;===============================================================
; model: stdcall
; args:
;	1) string pointer
; ret: 
;	rax - string length
;==============================================================
strlen:

    	push rbp
    	mov rbp, rsp
	
    	mov rdi, qword [rbp + 16]
	
	xor al, al				; end of the string value
	mov rdx, rdi				; saving base offset

loop_until_end_symb:	
	inc rdi
	cmp al, byte [rdi]
	jne loop_until_end_symb

    	sub rdi, rdx
    	mov rax, rdi

	pop rbp
	ret 8

;===================================================
; model: stdcall
; args:
;	1) value
;	2) pointer of the string to write
;	3) the basis of the calculus system
;
; ret:
;	di - pointer of the string to write
;===================================================
itoa:
	push rbp
	mov rbp, rsp
	
	push rsi
	push rcx

	mov rax, qword [rbp + 16]
	mov rdi, qword [rbp + 24]
	mov rcx, qword [rbp + 32]
	mov rbx, alphabet
	
	mov rsi, rdi 				; save rdi start value
	mov rdx, rcx				; checking rcx = 2^n
	dec rdx
	and rdx, rcx
	jz base_is_pow2
	
default_converting_to_string:
	
	xor rdx, rdx	
	div rcx
	
	push rax
	mov rax, rbx
	add rax, rdx
	
	mov al, byte [rax]
	stosb
	
	pop rax
	cmp rax, 0x00
	jne default_converting_to_string
	
	jmp init_reverse

base_is_pow2:
	mov rdx, rcx
	xor rcx, rcx

getting_pow:
	
	inc rcx
	shr rdx, 1
	cmp rdx, 0x01
	jne getting_pow

converting_pow2_to_string:
	mov rdx, rax
	shr rax, cl
	shl rax, cl


	sub rdx, rax
	shr rax, cl

	push rax
	mov rax, rbx
	add rax, rdx

	mov al, byte [rax]
	stosb
	pop rax

	cmp rax, 0x00

	jne converting_pow2_to_string

init_reverse:
	
	mov al, 0x00
	mov byte [rdi], al

	mov rdx, rsi				; save pointer to the string
	
	mov rcx, rdi
	sub rcx, rsi				; rcx = strlen = rdi - rsi
	shr rcx, 1				; rcx = strlen/2
	
	jz after_reverse
	push rdi
	dec rdi
reversing:

	mov al, byte [rdi]
	xchg al, byte [rsi]
	mov byte [rdi], al
	
	inc rsi
	dec rdi
	loop reversing

after_reverse:
	pop rdi
	
	pop rcx	
	pop rsi
	pop rbp
    	ret 24
