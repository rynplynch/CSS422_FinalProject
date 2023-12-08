		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself
		LDR		r0, =MCB_TOP		; Beginning of MCB
		
		MOV		r1, #0x4000			; Initial config
		STR		r1, [r0], #0x2
		
		MOV		r1, #0x0			; Zero
		LDR		r3, =0x20006C00		; Out of bounds memory addr
init_lbegin
		CMP		r0, r3				; Break once out of memory region
		BEQ		init_lend
		STR		r1, [r0], #0x2		; Zero init
		B		init_lbegin
init_lend
		
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	; r0 = size
		STMDB sp!, {lr}		; save all registers
		LDR		r1, =MCB_TOP
		LDR		r2, =MCB_BOT
		BL		_ralloc				; Call helper function
		
		LDMIA sp!, {lr}		; resume registers
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Helper function for _ralloc
; finds the appropriate tree to iterate over
; Returns address of appropriate tree spot
; Handles special case of combining buddies if needed
; int* _rfind( int size, int* left, int* right)
_rfind
	; r0 = size
	; r1 = left
	; r2 = right
	; r3 = current block content
	; r4 = current block size
		LDR		r3, [r1]
		LDR		r5, =0xFFF0
		AND		r4, r3, r5			; Check size
		CMP		r4, r0
		BHS		rsize_found
		B		rnot_found
rsize_found
		LDR		r5, =0x0001
		AND		r6, r3, r5			; Check availability
		CMP		r6, r5
		ADDNE	r2, r1, r4, ASR #4	; Update right
		SUBNE	r2, r2, #0x2
		BNE		r_done
rnot_found
		ASR		r4, r4, #4			; Get next buddy or upper layer, this is the formula
		ADD		r10, r1, r4
		; Check if this block + buddy can combine to fit
		LDR		r5, =0x0001			; Check availability
		AND		r6, r3, r5			
		CMP		r6, r5
		BEQ		iterate
		
		; Check if this block + buddy can combine to fit
		LDR		r7, [r10]			; Contents of buddy
		LDR		r5, =0x0001			; Check availability
		AND		r6, r7, r5			
		CMP		r6, r5
		BEQ		iterate
		
		ADD		r8, r3, r7			; Sum of contents
		CMP		r8, r0
		BNE		iterate
		
		; Found
		LDR		r9, =0x0			; Zero-init buddy
		STR		r9, [r10]
		STR		r8,	[r1]			; Update left with combination of contents
		
		ASR		r12, r0, #4			; Update right
		ADD		r2, r1, r12			
		SUB		r2, r2, #0x2
		
		B		r_done
iterate
		ADD		r1, r1, r4			; Update left
		LDR		r5, =0x20006C00		; Check if out of bounds
		CMP		r1, r5					
		BLO		_rfind
		; Out of bounds
		LDR		r1, =0x0000
r_done
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Helper function for kalloc
; Places appropriate address in MCB
; void _ralloc( int size, int* left, int* right)
_ralloc
	; r0 = size
	; r1 = left
	; r2 = right
	
	; r3 = current block content
	; r4 = address of buddy once block halved
	; r5 = right + 2 bytes
	; r6 = current block size
		MOV r11, lr					; Save lr before jumping
		BL		_rfind
		MOV lr, r11					; resume registers
		
_ralloc_routine		
		LDR		r3, [r1]			; Get info for current block
		
		ADD		r5, r2, #0x2		; Get right + 2 bytes
		SUB		r6, r5, r1			; Get size of block
		LSL		r6, #4			
		
		CMP		r6, r0	
		BLT		base_case			; Base case, block size is smaller than data	
		BNE		not_found			; Placement not found
		
		; Size found, check availability		
		AND		r7, r3, #0x0001
		CMP		r7, #0x0001
		BNE		found
		
not_found
		ADD		r8, r1, r5			; Get info for middle
		ASR		r4, r8, #1
		
		; Check availabilities
		AND		r7, r3, #0x0001		; left
		CMP		r7, #0x0001
		BNE		left
		
		AND		r7, r4, #0x0001		; right
		CMP		r7, #0x0001
		BNE		right
		
		B		base_case			; no availability

left
		SUB		r2, r4, #0x2		; new right
		ASR		r8, r6, #1			; update buddy, split in half
		STR		r8, [r4]
		B		_ralloc_routine
right
		MOV		r1, r4				; new left
		B		_ralloc
base_case		
		LDR		r0, =0x0000			; Return value is 0x0000 if none found
		B 		ralloc_done
found
		STR		r0, [r4]			; update buddy
		ADD		r0, r0, #0x1
		STR		r0, [r1]			; Store content in current block address
		MOV		r4, r1				; Return address in r4 - r4 doesn't get resumed from SVC call
ralloc_done
		MOV		pc, lr


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; Recursively updates MCB
; void _rfree( int* target, int* ogAddr )
_rfree
		; r0 = current MCB address
		; r1 = current MCB content
		; r2 = original MCB address
		LDR		r1, [r0]			
		
		AND		r3, r1, #0x0001		; Base case: Block is in use or empty	
		CMP		r3, #0x0001
		BEQ		rfree_done
		CMP		r1, #0x0
		BEQ		rfree_done
		
		; Empty block - remove block and loop
		LDR		r3,	[r2]			; Update orginal MCB entry
		ADD		r3,	r3, r1
		STR		r3, [r2]
		
		LDR		r3, =0x0			; Zero-init
		STR		r3,	[r0]
		
		ASR		r4, r1, #4			; Get next buddy or upper layer, this is the formula 
		ADD		r0, r0, r4

		B		_rfree
rfree_done
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
		; r0 = address of target
		; r1 = content of target addr
		LDR		r1, [r0]			; Initially free target
		LDR		r3, =0xFFF0
		AND		r1,	r1, r3
		STR		r1, [r0]	
		
		ASR		r3, r1, #4			; Get next buddy or upper layer, this is the formula
		MOV		r2, r0				; Save og address
		ADD		r0, r0, r3			; Get prior to entering recursion
		
		MOV		r10, lr
		BL		_rfree				; Recursively traverse buddies
		MOV		lr, r10
		
		MOV		pc, lr				; return from rfree( )
		
		END
