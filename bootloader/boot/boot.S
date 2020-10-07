.code16

.equ BOOTSEG,  0x0
.equ MAGICMBR, 0xAA55

.equ RELOCATED, 0x0600

.equ PARTSTART, 0x430
.equ PARTNBR,   0x4
.equ PARTSIZE,  0x10

.section .bootloader, "ax"

.global _bootloader

_bootloader:
    ljmp $BOOTSEG, $._bootloader

._bootloader:
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw %ax, %fs
    movw %ax, %gs
    xorw %sp, %sp
    cld
    cli

    mov $__BOOT_SECTOR_START, %sp

    mov $0x7C00, %si
    mov $RELOCATED, %di
    mov $0x0200, %cx
    rep movsb

    jmp over + RELOCATED

.equ over, . - 0x7C00

    pushw %dx # bios value

    sti

    mov $0x3, %ax
    int $0x10

    call biosCleanScreen

    mov $0x103, %ax
    mov $0x105, %cx
    int $0x10

    xorw %cx, %cx
    movw $(0x430 + RELOCATED), %bp # yes its the lastest register we got X)
    xorw %bx, %bx

dump_partition:
    pushw %bp

    movb $0x2, %ah
    movw $(0x100 * 9 + 32), %dx
    addb %cl, %dh
    int $0x10

    cmpb $0x80, (%bp)
    jne printBasePart
    movb $0x1, bpartactive

    printBasePart:
        movw $_partbase, %si
        call bprintstr
        movb $0xE, %ah
        movb %cl, %al
        addb $0x31, %al
        int $0x10
        mov $0xA, %al
        int $0x10

        cmpb $0x1, bpartactive 
        jne endOfPartX

    printActive:
        mov $_active, %si
        call bprintstr

    endOfPartX:
        movb $0x0, bpartactive
        popw %bp
        addw PARTSIZE, %bp
        incw %cx
        cmpw $PARTNBR, %cx
        jne dump_partition

    xorw %si, %si
user_boot:
    movb $0x2, %ah
    mov %si, %dx
    shl $0x8, %dx 
    addw $(0x100 * 9 + 30), %dx
    int $0x10

    mov $0x0, %ah
    int $0x16

    cmp $0x011B, %ax # escape
    je biosKill

    cmp $0x1C0D, %ax # enter
    je booting

    cmp $0x4800, %ax # up arrow
    je moveup

    cmp $0x5000, %ax # down arrow
    je movedown

    jmp user_boot

    movedown:
        cmpw $0x3, %si
        je user_boot
        inc %si
        jmp user_boot

    moveup:
        cmpw $0x0, %si
        je user_boot
        dec %si
        jmp user_boot


booting:
    pushw %si
    mov $0x2, %ah
    mov $0x0, %dx
    int $0x10

    call biosCleanScreen

    mov (430 + RELOCATED), %bp
    popw %si
    shlw $4, %si
    addw %si, %bp

    popw %dx
    movb %dl, (%bp)

    push %bp

    movb $0x0, 0x10(%bp)
    movb $0x5, 0x11(%bp)

    /* Check for extension present*/
    mov $0x41, %ah
    mov $0x55AA, %bx
    int $0x13

    pop %bp

    jc ExtensionChecked
    andw $0b1, %cx
    jz ExtensionChecked
    cmpw $0xAA55, %bx
    jz ExtensionChecked

    incb 10(%bp)


ExtensionChecked:
    pusha
    cmpb $0x0, 10(%bp)
    jz readVBR

/* else got extension */
    pushl $0x0
    pushl 8(%bp)
    pushw $0x0
    pushw $0x7C00
    pushw $0x1
    pushw $0x10

    movb $0x42, %ah
    movb (%bp), %dl
    movw %sp, %si
    int $0x13

    lahf
    addw $0x10, %sp
    sahf

    jmp sector


/* VBR Extended */

readVBR:
    mov $0x201, %ax
    mov $0x7C00, %bx
    mov 3(%bp), %ch
    mov 2(%bp), %cl
    mov 1(%bp), %dh
    mov 0(%bp), %dl
    int $0x13

sector:
    popa
    jnb load_dos
    decb 0x11(%bp)
    jz perror

# lets retry
    pushw %bp
    xor %ah, %ah
    movb (%bp), %dl
    int $0x13
    pop %bp
    jmp ExtensionChecked

load_dos:
    /* if not DOS loader then fault */
    cmpw $0x0, 0x7C00
    jne perror
    cmpw $0xAA55, 0x7DFE
    jne perror

    mov (%bp), %dx
    xorb %dh, %dh
    ljmp $0x0, $0x7C00 # jump on the DOS loader


/* Tools */

bprintstr:
    lodsb
    andb %al, %al
    jz   .bendprint
    movb $0xe, %ah
    movw $7, %bx
    int  $0x10
    jmp  bprintstr
.bendprint:
    ret

perror:
    mov $_error, %si
    call bprintstr
reDie:
    xorb %ah, %ah
    int $0x16
    cmp $0x011B, %ax
    jne reDie

biosKill:
    int $0x19 # BIOS poweroff
    ljmp $0xf000,$0xfff0 # case error reset code

biosCleanScreen:
    movw $0x600, %ax
    movb $0x7, %bh
    xorw %cx, %cx
    movw $0x184F, %dx
    int $0x10
    ret

_partbase: .asciz "Partition "
_active:   .asciz " (BOOTABLE)"
_error:    .asciz "Error occcured"
bpartactive: .byte 0x0

.fill 0x1B8 - (. - _bootloader), 1, 0

 diskid:   .fill 0x4, 1, 0

           .fill 0x2, 1, 0

 part1: .fill 16, 1, 0
 part2: .fill 16, 1, 0
 part3: .fill 16, 1, 0
 part4: .fill 16, 1, 0

.section .bootmagic, "ax"
.word MAGICMBR
