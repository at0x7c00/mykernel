;存储在磁盘中第2个扇区,由mbr负责加载并执行
section header align=16 vstart=0

	entrance dw start                 ;[0x00]
	data dd section.code_sg.start     ;[0x02]
									  ;jmp far [0x00]，实际是取[0x00]为偏移地址，[0x01]为段地址

	data_segment dd section.data_sg.start    ;[0x06]  0x50
	stack_segment dd section.stack_sg.start  ;[0x0a]  0x70
									  
section code_sg align=16 vstart=0
start:
	;设置ss:sp
	mov ax,[stack_segment]
	mov ss,ax
	mov ax,stack_end
	mov sp,ax

	;设置ds
	mov ax,[data_segment]
	mov ds,ax

	mov bx,0
	call print
	jmp $


print:
	mov ax,0xb800
	mov es,ax
	mov si,0

_print:
	mov al,[bx]
	cmp al,0
	jz  _print_exit
	mov [es:si],al
	inc si
	mov byte [es:si],0x07
	inc si
	inc bx

	cmp al,0
	jnz _print
_print_exit:
	ret


section data_sg align=16
msg 
	db 'Say hello from user programming.'
	db 0 ;字符结尾，以免溢出到后面的栈
section stack_sg align=16
	resb 256
stack_end: 
