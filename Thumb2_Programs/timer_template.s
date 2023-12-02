		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init

	;; the hex value to set the Interupt Enabled bit off and the Clock Enable off
	LDR r0, =STCTRL_STOP
	;; load Status Register Address
	LDR r1, =STCTRL
	;; Store in the Control and Status Register
	STR r0, [r1]

	;; value we count down from. This makes it so an Interupt is generated every 1 second
	LDR r0, =STRELOAD_MX
	;; load Reload Value Regsiter address
	LDR r1, =STRELOAD
	;; store it in the SYST_RVR register
	STR r0, [r1]

	;; we must always clear the Current Value Register on reset
	;; load its address
	LDR r0, =STCURR_CLR
	MOV r1, #0x0
	;; this also clears the counter and COUNTFLAG
	STR r1, [r0]

	MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start

	;; Set value of SYST_CSR (SysTick Control&Status Register)
	LDR r0, =STCTRL
	;; bit 1 (Enable Interupt) = 1, bit 0 (Enable Counter) = 1
	LDR r1, = STCTRL_GO
	;; store altered value
	STR r1, [r0]

	;; return the current counter value???
	LDR r0, =STCURRENT

	MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Grab the current value in the Current Value Register
	;; It returns how much time remains on the timer
	LDR r0, =STCURRENT
	;; address of system variable seconds left
	LDR r1, =SECOND_LEFT
	;; update the system variable SECOND_LEFT
	STR r0, [r1]

	MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	
		MOV		pc, lr		; return to Reset_Handler
		
		END		
