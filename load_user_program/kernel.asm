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

	mov bx,0    ;bx cursor index
	mov bp,0    ;bp char index
	call print
	
	;监听键盘输入，显示到屏幕
.reps:
      mov ah,0x00
      int 0x16
      
      mov ah,0x0e
      mov bl,0x07
      int 0x10

      jmp .reps
	
	jmp $

;bx cursor index
print:
	mov ax,0xb800
	mov es,ax
	mov si,0

_print:
	mov cl,[ds:bp]
	inc bp
	
	cmp cl,0  
	jz  _print_exit  ;遇到字符结尾，退出
	
	;call get_cursor  ;bx = get_cursor()
	
	;cmp + jnz ====> if(...){
	cmp cl,0x0d
	jnz .put_0a
	mov ax,bx
	mov bl,80
	div bl 
	mul bl ;div + mul ：去除余数，得到80的倍数的一个值
	mov bx,ax
	
	jmp .set_cursor
	
.put_0a:
	cmp cl,0x0a
	jnz .put_other
	add bx,80
	jmp .roll_screen ;只有换行才会可能导致滚动屏幕
	
.put_other:
    
	shl bx,1    ;光标位置 * 2 = 字符位置   (转换成字符位置值)
	mov [es:bx],cl ;注意：属性字节默认为白底黑字，
				   ;      因此不用写了
											
	shr bx,1    ;字符位置 / 2 = 光标位置  (转换回光标值)
	add bx,1	;推进光标位置

.roll_screen:
	cmp bx,2000
	jl .set_cursor  ;jmp less
	call roll_screen

.set_cursor:

	mov ax,bx
	call set_cursor  ;set_cursor(ax)

	cmp cl,0
	jnz _print
_print_exit:
	ret
	
;获取光标位置，从bx中返回
get_cursor:
	push dx
	
	mov dx,0x3d4
	mov al,0x0e
	out dx,al
	mov dx,0x3d5
	in al,dx
	mov ah,al  ;读入光标位置高8位
	
	mov dx,0x3d4
	mov al,0x0f
	out dx,al
	mov dx,0x3d5
	in al,dx  ;读入光标位置低8位
	mov bx,ax ;光标位置存入到bx中
	
	pop dx
	ret
	
;设置光标位置，参数从bx中传递
set_cursor:
	push dx
	
	mov dx,0x3d4
	mov al,0x0e
	out dx,al
	mov dx,0x3d5
	mov al,bh
	out dx,al     ;写入光标位置高8位  
	
	mov dx,0x3d4
	mov al,0x0f
	out dx,al
	mov dx,0x3d5
	mov al,bl
	out dx,al      ;写入光标位置低8位
	
	pop dx
	ret

roll_screen:
	push ds
	push es
	push cx
	
	mov ax,0xb800
	mov ds,ax
	mov es,ax
	;        movsw
	;ds:si  -------> es:di
	cld
	mov si,0xa0 ;第2行第0列  80*2 = 160 = a0
	mov di,0x00 ;第1行第0列
	mov cx,1920 ;80*24=1920
	rep movsw
	
	mov bx,3840 ;第25行第0列 (25-1) * 160 = 3840
	mov cx,80
.cls:
	mov word[es:bx],0x0720
	add bx,2
	loop .cls
	
	mov bx,1920

	pop cx
	pop es
	pop ds
	ret

section data_sg align=16
msg	db 'Hello',0x0d,0x0a,0x0d,0x0a
	db '     inc cx',0x0d,0x0a
	db '     add ax,cx',0x0d,0x0a
	db '     adc dx,0',0x0d,0x0a
	db '     inc cx',0x0d,0x0a
	db '     cmp cx,1000',0x0d,0x0a
	db '     jle @@',0x0d,0x0a
	db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
	db 0 ;字符结尾，以免溢出到后面的栈
section stack_sg align=16
	resb 100
stack_end: 
