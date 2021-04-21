global start
extern long_mode_start

section .text
bits 32
start:
	mov esp, stack_top                ;esp register points on the current stack , stack_top is moved to esp

	call check_multiboot              ;checks that the multiboot boot loader has been loaded
	call check_cpuid                  ; provides cpu information
	call check_long_mode              ;checks if cpu supports long mode

	call setup_page_tables
	call enable_paging

	lgdt [gdt64.pointer]              ; loads global descriptor table
	jmp gdt64.code_segment:long_mode_start

	hlt

check_multiboot:
	cmp eax, 0x36d76289
	jne .no_multiboot            ; if the comaprison fails it jumps to no multiboot 
	ret                          ; otherwise return from the sub routine
.no_multiboot:                   ;label
	mov al, "M"                  ; eroor message is stored in al register
	jmp error                    ;displays the error message

check_cpuid:
	pushfd                      ;flag register is pushed onto the stack
	pop eax                     ;stack is poped into the eax register
	mov ecx, eax                ;copy is made in ecx register
	xor eax, 1 << 21
	push eax
	popfd
	pushfd
	pop eax
	push ecx
	popfd
	cmp eax, ecx                ;if id bit(i.e. 21) remains fliped and the cpu didnot reversed then cpu supports cpu id
	je .no_cpuid                ;if not supported then jump to no cpu id supported label
	ret
.no_cpuid:
	mov al, "C"                 ;error message
	jmp error

check_long_mode:
	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001         ; if this number is greater than the above nuber then cpu supports long mode
	jb .no_long_mode            ;if less than , then jump to no_long_mode label

	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29           ; if ln bit is set long mode is supported
	jz .no_long_mode            ; else jumps to no long mode label
	
	ret
.no_long_mode:
	mov al, "L"                  ;error message
	jmp error

setup_page_tables:                       ;pagging is requirement to set long mode
	mov eax, page_table_l3               ;address of level 3 table is moved to eax
	or eax, 0b11                         ; present, writable flags
	mov [page_table_l4], eax             ;one entry of level 3 table is moved to level 4 table
	
	mov eax, page_table_l2
	or eax, 0b11 ; present, writable
	mov [page_table_l3], eax

	mov ecx, 0 ; counter
.loop:

	mov eax, 0x200000                                           ; 2MiB
	mul ecx
	or eax, 0b10000011                                          ; present, writable, huge page
	mov [page_table_l2 + ecx * 8], eax

	inc ecx                                                    ; increment counter
	cmp ecx, 512                                               ; checks if the whole table is mapped
	jne .loop ; if not, continue

	ret

enable_paging:                             ;implementing paging
	                                       ; pass page table location to cpu
	mov eax, page_table_l4                 ; address of table 4 is moved in eax register
	mov cr3, eax                           ; the content of eax if copied in cr3

	                                       ; enable physical address extension
	mov eax, cr4
	or eax, 1 << 5                         ;enables 5 page
	mov cr4, eax                           copies the contents back into cr4

	                                        ; enable long mode
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8                         ;enables long mode flag
	wrmsr

	                                       ; enable paging
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

error:
	; print "ERR: X" where X is the error code
	mov dword [0xb8000], 0x4f524f45
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov byte  [0xb800a], al                           ;asci letter is stored in al register
	hlt                                               ;halts the cpu after error code is displayed

section .bss
align 4096                                            ;each table is 4K bytes
page_table_l4:
	resb 4096 
page_table_l3:
	resb 4096
page_table_l2:
	resb 4096
stack_bottom:
	resb 4096 * 4
stack_top:

section .rodata
gdt64:
	dq 0                                                          ; zero entry
.code_segment: equ $ - gdt64
	dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)              ; code segment
.pointer:
	dw $ - gdt64 - 1 ; length
	dq gdt64                                                       ; address