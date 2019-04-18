jmp start
msg:
	db 'The x86 instruction set refers to the set of instructions that \
	x86-compatible microprocessors support. The instructions are usually \
	part of an executable program, often stored as a computer file and \
	executed on the processor.The x86 instruction set has been extended \
	several times, introducing wider registers and datatypes as well as \
	new functionality'

number:
	db 0,0,0,0

;00000
; 7c00
;-------
;07c00  <------物理地址
start:
	mov ax,0x7c0
	mov ds,ax
	
	mov si,msg

;        movsb/movsw
;ds:si  -------------> es:di
;df：0：正向复制，1：反向复制

	mov ax,0xb800
	mov es,ax
	mov di,0

	mov cx,(number - msg);设置复制次数
copy:
	mov al,[ds:si]
	mov byte [es:di],al
	inc di
	
	mov byte [es:di],0x07
	inc di
	
	inc si
loop copy


jmp $


times 510 - ($ - $$) db 0
db 0x55,0xaa