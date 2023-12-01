		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
	;; Implement by yourself
		; Import routines
		IMPORT 	_kfree
		IMPORT 	_kalloc
		IMPORT 	_signal_handler
		IMPORT 	_timer_start
		
		; Store entries
		LDR		r0, =_kfree
		LDR 	r1, =0x20007B14
		STR 	r0, [r1]
		
		LDR 	r0, =_kalloc
		LDR 	r1, =0x20007B10
		STR 	r0, [r1]
		
		LDR 	r0, =_signal_handler
		LDR 	r1, =0x20007B08
		STR 	r0, [r1]
		
		LDR		r0, =_timer_start
		LDR 	r1, =0x20007B04
		STR 	r0, [r1]
	
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	;; Implement by yourself
		STMDB sp!, {lr}		; Save lr before jumping
	; Matches
		CMP		r7, SYS_FREE
		BEQ		kfree
		CMP		r7, SYS_MALLOC
		BEQ		malloc
		CMP		r7, SYS_SIGNAL
		BEQ		signal
		CMP		r7, SYS_ALARM
		BEQ		alarm
	
	; Actions
kfree
		LDR		r8, =0x20007B14
		LDR		r9, [r8]
		BLX		r9
		B 		stop
malloc
		LDR		r8, =0x20007B10
		LDR		r9, [r8]
		BLX		r9
		B 		stop
signal
		LDR		r8, =0x20007B08
		LDR		r9, [r8]
		BLX		r9
		B 		stop
alarm
		LDR		r8, =0x20007B04
		LDR		r9, [r8]
		BLX		r9
		B 		stop
stop
		LDMIA sp!, {lr}		; resume registers
		MOV		pc, lr			
		
		END


		
