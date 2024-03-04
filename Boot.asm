bits 16

org		0x7c00	

start:
    ; sets variables to their error state
    mov bl, 0
    mov [0x0000], bl

    ; print startup message
    mov ah, 0x0e 
    mov bx, startmsg
    call printString
    call printNewline

    ; checks if there is enough memory for the kernel
    xor ax, ax
    mov ss, sp
    int 0x12
    cmp ax, [kernalsize]
    jl lowmemory

    ; checks the APM is supported
    mov ah, 0x53
    mov al, 0x00
    xor bx, bx
    int 0x15
    jc apmerror

    ; connect to APM interface
    mov ah, 0x53
    mov al, 0x01
    xor bx, bx
    int 0x15
    jc apmerror
    mov bl, 0
    mov [0x1000], bl

    ; load in kernel and hand over control
    mov ah, 0
    mov dl, 0
    int 0x13
    xor ax, ax                          
    mov es, ax
    mov ds, ax
    mov bp, 0x8000
    mov sp, 0x0000
    call readsect
    
    jmp 0x7e00


printmdigit:
    mov cx, 0
    mov ax, [tempnum]
    mov [quot], ax
repeat:
    xor ax, ax
    xor bx, bx
    xor dx, dx
    mov ax, [quot]
    mov bx, 10
    div bx
    mov [quot], ax
    cmp ax, 0
    je divend
    mov ax, dx
    push ax
    inc cx
    jmp repeat
divend:
    mov ax, dx
    push ax
    inc cx
repeatprint:
    dec cx
    pop ax
    mov [tempnum], ax
    push cx
    call printdigit
    pop cx
    cmp cx, 0
    jne repeatprint
    ret

printdigit:
    mov ax, 0x30
    add [tempnum], ax
    mov ax, [tempnum]
    call printChar
    ret

lowmemory:
    mov ah, 0x0e
    mov bx, lowmemfail
    call printString
    jmp $

apmerror:
    mov ah, 0x0e
    mov bx, apmerr
    call printString
    jmp $


    kernalsize dw 1
    apmerr db "An error occured with your APM", 0
    lowmemfail db "Low memory", 0
    startmsg db "Loading kernel...", 0

printString:
    mov al, [bx]
    cmp al, 0
    je end
    int 0x10
    inc bx
    jmp printString
end:
    ret

printNewline:
    mov ah, 0x0e
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    ret


printChar:
    mov ah, 0x0e 
    int 0x10
    ret


LBACHS:
    xor dx, dx
    div WORD [sectorspertrack]
    inc dl
    mov BYTE [sectortoread], dl
    xor dx, dx
    div WORD [headspercylinder]
    mov BYTE [headtoread], dl
    mov BYTE [tracktoread],al
    ret

readsect:
    mov ax, [sectorread]
    call LBACHS
    mov ah, 0
    mov dl, 0
    int 0x13
    xor ax, ax                          
    mov es, ax
    mov ds, ax
    mov bx, 0x7e00
    mov ah, 0x02
    mov al, [numbertoread]
    mov ch, [tracktoread]
    mov cl, [sectortoread]
    mov dh, [headtoread]
    mov dl, 0
    int 0x13
    ret

sectorread dw 34
sectortoread db 0
tracktoread db 0
headtoread db 0
numbertoread db 2
totalsectors dw 2880
sectorspertrack dw 18
tracksperside dw 80
headspercylinder dw 2
memorystart dw 0x7e00
quot dw 0
tempnum dw 0
 

times 510-($-$$) db 0x00            
dw 0xaa55