
section .data
test_string: db "ahahah, %d %d %d %d %d %d %s %b", 0x00
msg_test:    db "stavim na zero", 0X00
string1:     db "LOVE", 0x00
;__________________________________
section .rodata

PROCENT_SYMB     equ '%'
END_STRING_VALUE equ 0X00
STDOUT_DESCR	 equ 1
alphabet: db "0123456789abcdefghi"

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
;	mov rdi, test_string
;	mov rsi, 0x01
;	mov rdx, 0x02
;	mov rcx, 0x03
;	mov r8,  0x04
;	mov r9,  0x05
;	push 0x10
;	push msg_test
;;	push 0x10
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
	
	sub rsp, 0x30
	mov r10, rdi
	mov qword [rbp - 0x10], rsi
	mov qword [rbp - 0x18], rdx
	mov qword [rbp - 0x20], rcx
	mov qword [rbp - 0x28], r8
	mov qword [rbp - 0x30], r9

	mov rsi, r10
	mov rdi, temp_string					; указатель на строку, в которую мы будем ложить все данные
	
	xor rcx, rcx							; args_readen = 0
string_conv_ph1:
	cmp rcx, 0x05
	je string_conv_ph2

	cmp byte [rsi], END_STRING_VALUE
	je after_converting

	cmp byte [rsi], PROCENT_SYMB
	je spec_handler1
	movsb
	
	jmp string_conv_ph1

spec_handler1:
	inc rsi
	cmp byte [rsi], PROCENT_SYMB
	jne not_percent_spec1
	mov byte [rdi], PROCENT_SYMB
	inc rsi
	inc rdi
	jmp string_conv_ph1
not_percent_spec1:
	
	mov rax, rcx
	shl rax, 3
	add rax, 0x10
	mov rdx, rbp
	sub rdx, rax

	mov rax, [rdx]

	xor rdx, rdx
	mov dl, byte [rsi]						; dl = ascii of symb after %
	shl rdx, 3

	call [rdx+jump_table]			; вызываем обработку спецификатора по свичу
	
	inc rsi
	inc rcx									; args_readen++
	
	jmp string_conv_ph1
string_conv_ph2:

	cmp byte [rsi], END_STRING_VALUE
	je after_converting

	cmp byte [rsi], PROCENT_SYMB
	je spec_handler2
	movsb
	
	jmp string_conv_ph2

spec_handler2:
	inc rsi
	cmp byte [rsi], PROCENT_SYMB
	jne not_percent_spec2
	mov byte [rdi], PROCENT_SYMB
	inc rsi
	inc rdi
	jmp string_conv_ph2
not_percent_spec2:
		
	xor rdx, rdx
	mov dl, byte [rsi]						; dl = ascii of symb after %
	shl rdx, 3
	
	mov rax, [rbp + rcx * 0x08 - 0x28 + 0x10]				; rax = arg_value
	
	call [rdx + jump_table]			; вызываем обработку спецификатора по свичу
	
	inc rsi
	inc rcx									; args_readen++
	
	cmp byte [rsi], END_STRING_VALUE
	jne string_conv_ph2

after_converting:
	push temp_string
	call strlen

	mov rdx, rax
	mov rax, SYSCALL_OUTPUT
	mov rdi, STDOUT_DESCR
	mov rsi, temp_string
	syscall									; print(temp_string)
	mov rax, 0x01

	add rsp, 0x30
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

;specif_cases:
;	dq default_spec
;	dq int2_spec
;	dq int16_spec
;	dq char_spec
;	dq int10_spec
;	dq int8_spec
;	dq string_spec

jump_table: 
		times 'b' 		dq 0x00
						dq int2_spec
						dq char_spec
						dq int10_spec
		times 'o' - 'd' - 1 	dq 0x00
						dq int8_spec
		times 's' - 'o' - 1	dq 0x00
						dq string_spec
		times 'x' - 's' - 1	dq 0x00
						dq int16_spec
		times 0x100 - 'x' dq 0x00
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
	
	mov rsi, rdi	
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

	pop rdi
after_reverse:
	
	pop rcx	
	pop rsi
	pop rbp
    	ret 24
