org 0x7c00
label:
db 0,0,0
;es:bx指向显存
mov ax,label
mov ax,0xb800
mov es,ax
mov bx,0x00

;ds:0x0000
;si:0x7c00+data
;ds:si指向字符串位置
mov ax,0x00
mov ds,ax
mov ax,[0x7c00+data]
mov si,ax

print:

mov byte al,[ds:si]
;往显存写入字符
mov byte [es:bx],al
add bx,0x01
;往显存写入显示格式
mov byte [es:bx],0x07
add bx,0x01

;递增si
mov cx,si
inc cx
mov si,cx

;如果到字符末尾，退出
or al,al
jz exit

;循环打印
jmp near print
exit:
jmp $

data:
db 'Hello,World'

times 510 - ($ - $$) db 0

db 0x55
db 0xaa

;心得：
;1）寄存器太少不够用；
;2）[0x7c00 + data + bx]中的只能用bx\bp\si\di四个寄存器
;3）0x7c00是段内偏移地址，不是段地址！