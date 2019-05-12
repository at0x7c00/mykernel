;位于磁盘第一个扇区，会被BIOS自动加载到0x07c0处执行
app_lba_start equ 1;扇区号从0开始，引导程序位于0号扇区
segment mbr align=16 vstart=0x7c00

;在哪儿会用到栈？很多call调用中都会用到push和pop
mov ax,0
mov ss,ax
mov sp,ax

;ax：实际加载的物理地址的高16位
mov ax,[cs:phy_base]
;bx：实际加载的物理地址的低16位
mov dx,[cs:phy_base+2]

;除以16实际就是右移4位,右移后的结果存放在ax中
mov bx,16
div bx ;dx:ax / bx = ax 余 dx
mov ds,ax  ;将实际物理段地址存放在ds和es中备用
mov es,ax

;加载程序到ds位置(只加载一次，默认用户程序不大于512字节)
call load_hard_disk

;调整入口点
mov ax,[0x02]
mov dx,[0x04]
call relocate
mov [0x02],ax

;重定位栈段
mov ax,[0x06]
mov dx,[0x08]
call relocate
mov [0x06],ax

;重定位数据段
mov ax,[0x0a]
mov dx,[0x0c]
call relocate
mov [0x0a],ax

jmp far [0x00]


;load_hard_disk(bx)------------------------------
load_hard_disk:
	push ax
	push bx
	push cx
	push dx

	mov dx,0x1f2
	mov al,0x01 ;写入读取的扇区数1
	out dx,al

	mov dx,0x1f3
	mov al,1 ;写入起始扇区地址1
	out	dx,al

	inc dx
	mov al,0
	out dx,al

	inc dx
	out dx,al

	inc dx
	mov al,0xe0 ;高4位：1110，主硬盘/LBA方式
	out dx,al  


	inc dx
	mov al,0x20 ;写入020，以开始读取数据
	out dx,al

	;监控状态字节
	.wait:
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz .wait

	mov cx,256  ;读取256*2=512字节
	mov dx,0x1f0

	mov bx,0
	
	.read_data:
	in ax,dx
	mov [bx],ax  ;往ds:bx中存入数据
	add bx,2
	loop .read_data;

	pop dx
	pop cx
	pop bx
	pop ax

	ret


;---------------------------------------------------------
relocate:
	;  dx             :  ax
	;+ phy_base+0x02     phy_base     
	;-----------------------------
	add ax,[cs:phy_base]
	adc dx,[cs:phy_base+0x02]
	;ax右移4位，空出的高4位
	shr ax,4
	ror dx,4
	and dx,0xf000
	or  ax,dx
	ret

phy_base dd 0x10000  ;用户程序实际加载的物理地址

times 510-($-$$)  db 0
                  db 0x55,0xaa