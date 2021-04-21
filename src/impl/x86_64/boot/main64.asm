global long_mode_start      ;globalize to access for all
extern kernel_main          ;reference to external

section .text
bits 64                     ;in previous one it was set to 32 and now 64
long_mode_start:            ;label
                            ; load null into all data segment registers
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

	call kernel_main
    hlt                     ;halt to avoid any garbage instructions