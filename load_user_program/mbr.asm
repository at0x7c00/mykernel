;位于磁盘第一个扇区，会被BIOS自动加载到0x07c0处执行
segment mbr align=16 vstart=0x7c00

;写入读取的扇区数
mov dx,0x1f2
mov al,0x01
out dx,al

;写入起始扇区地址
mov dx,0x1f3
mov al,1
out	dx,al

inc dx
mov al,0
out dx,al

inc dx
out dx,al

inc dx
mov al,0xe0;高4位：1110，主硬盘/LBA方式
out dx,al  

;写入020，以开始读取数据
inc dx
mov al,0x20
out dx,al

;读入状态字节
.wait:
in al,dx
and al,0x88
cmp al,0x08
jnz .wait

mov cx,512
mov dx,0x1f0

mov ax,0
mov ds,ax
mov bx,.heap

.read_data:
in ax,dx
mov [bx],ax
add bx,2
loop .read_data;

mov bx,.heap
call print

jmp $

;es:si --> display mem
;ds:bx --> heap
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

.heap:
db 0

times 510-($-$$)  db 0
                  db 0x55,0xaa