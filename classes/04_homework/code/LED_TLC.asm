;***************************************************************************************************
;*
;* Misto			: CVUT FEL, Katedra Mereni
;* Prednasejici		: Doc. Ing. Jan Fischer,CSc.
;* Predmet			: A4M38AVS
;* Vyvojovy Kit		: STM32 VL DISCOVERY (STM32F100RB)
;*
;**************************************************************************************************
;*
;* JMÉNO SOUBORU	: LED_TLC.ASM
;* AUTOR			: Michal TOMÁŠ
;* DATUM			: 12/2010
;* POPIS			: Program pro stridave blikani LED na vyvodech PC8 a PC9 se dvema mody ovladanymi tlacitkem.
;*					  - konfigurace hodin na frekvenci 24MHz (HSE + PLL) 
;*					  - konfigurace pouzitych vyvodu procesotu (PC8 a PC9 jako vystup, PA0 jako vstup)
;*					  - rozblikani LED na PC8 a PC9, cteni stavu tlacitka a prepinani modu blikani
;* Poznamka			: Tento soubor obsahuje podrobny popis kodu vcetne vyznamu pouzitych instrukci
;*
;***************************************************************************************************
				
		AREA    STM32F1xx, CODE, READONLY  	; hlavicka souboru
	
		GET		INI.s					; vlozeni souboru s pojmenovanymi adresami
										; jsou zde definovany adresy pristupu do pameti (k registrum)

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++										
konst_all 	EQU	0x0300
konst_blue	EQU	0x0100
konst_green	EQU	0x0200
konst_no	EQU	0x0
	

; custom ascii table

asci_a 		EQU	0x61
asci_c 		EQU	0x63
asci_e 		EQU	0x65
asci_k 		EQU	0x6B
asci_p 		EQU	0x70
asci_r 		EQU	0x72
asci_t 		EQU	0x74
asci_u 		EQU	0x75
asci_z		EQU	0x7A
	
asci_A		EQU	0x41
asci_D		EQU	0x44
asci_E		EQU	0x45
asci_I		EQU	0x49
asci_M		EQU	0x4D
asci_N		EQU	0x4E
asci_R		EQU	0x52
asci_S		EQU	0x53
asci_T		EQU	0x54
asci_U		EQU	0x55
asci_Y		EQU	0x59

asci_space	EQU	0x20
asci_equals	EQU	0x3D

asci_dot	EQU	0x2E



;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

											
		EXPORT	__main					; export navesti pouzivaneho v jinem souboru, zde konkretne
		EXPORT	__use_two_region_memory	; jde o navesti, ktere pouziva startup code STM32F10x.s
		
__use_two_region_memory	
__main								  						
		
		ENTRY							; vstupni bod do kodu, odtud se zacina vykonavat program

;***************************************************************************************************
;* Jmeno funkce		: MAIN
;* Popis			: Hlavni program + volani podprogramu nastaveni hodinoveho systemu a konfigurace
;*					  pouzitych vyvodu procesoru	
;* Vstup			: Zadny
;* Vystup			: Zadny
;***************************************************************************************************

MAIN									; MAIN navesti hlavni smycky programu											
				BL		RCC_CNF			; Volani podprogramu nastaveni hodinoveho systemu procesoru
										; tj. skok na adresu s navestim RCC_CNF a ulozeni navratove 
										; adresy do LR (Link Register)
				BL		GPIO_CNF		; Volani podprogramu konfigurace vyvodu procesoru
										; tj. skok na adresu s navestim GPIO_CNF 
										;*!* Poznamka pri pouziti volani podprogramu instrukci BL nesmi
										; byt v obsluze podprogramu tato instrukce jiz pouzita, nebot
										; by doslo k prepsani LR a ztrate navratove adresy ->
										; lze ale pouzit i jine instrukce (PUSH, POP) *!*
										
										
				MOV		R0, #100
				BL		DELAY
				MOV		R7, #4			; time variable
				MOV		R9, #2			; mode: 2 - settings, 3 - executing, 4 - wating
										
										
SET_DISPLAY	
				BL		CONFIG_DISPLAY
				BL		SET_URL_ADDRESS
				BL		WRITE_SET_TIME
				BL		WRITE_NUMS
				
				
RECOGNIZE_MODE
				CMP		R9, #2
				BNE		RUN_MODE
				
				
; SETTING_MODE
; =============================================================
				; zobraz display
				
TURN_GREEN_LIGHT_ON
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_green
				STR		R1, [R2]
				

PLUS_BUTTON_CHECK
				MOV		R3, #0x0	; null delay counter
				
				LDR		R0, =GPIOC_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_10111111
				BIC		R1, R1, #2_1111111100000000
				CMP		R1, #2_01000000
				BNE		MINUS_BUTTON_CHECK
PLUS_BUTTON_CHECK_DELAY
				
				MOV		R0, #30
				BL		DELAY
				ADD		R3, R3, #0x1
				
				LDR		R0, =GPIOC_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_10111111
				BIC		R1, R1, #2_1111111100000000
				CMP		R1, #2_01000000
				BEQ		PLUS_BUTTON_CHECK_DELAY
				
				CMP		R3, #0x3
				BHI		PLUS_10
				
				ADD		R7, R7, #0x1
				B		WRITE_PLUS
PLUS_10			ADD		R7, R7, #0xA

WRITE_PLUS
				
				BL		WRITE_SET_TIME
				BL		WRITE_NUMS
				
				
MINUS_BUTTON_CHECK
				MOV		R3, #0x0	; null delay counter

				LDR		R0, =GPIOC_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_01111111
				BIC		R1, R1, #2_1111111100000000
				CMP		R1, #2_10000000
				BNE		OK_BUTTON_CHECK
MINUS_BUTTON_CHECK_DELAY				
				MOV		R0, #30
				BL		DELAY
				ADD		R3, R3, #0x1
				
				LDR		R0, =GPIOC_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_01111111
				BIC		R1, R1, #2_1111111100000000
				CMP		R1, #2_10000000
				BEQ		MINUS_BUTTON_CHECK_DELAY
				
				CMP		R3, #0x2
				BHI		MINUS_10
				
				SUB		R7, R7, #0x1
				B		WRITE_MINUS
MINUS_10		SUB		R7, R7, #0xA

WRITE_MINUS
				BL		WRITE_SET_TIME
				BL		WRITE_NUMS


OK_BUTTON_CHECK
				LDR		R0, =GPIOA_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_11111111
				BIC		R1, R1, #2_1111011100000000
				CMP		R1, #2_100000000000
				BNE		RECOGNIZE_MODE
				MOV		R0, #50
				BL		DELAY
				
				; if it is pushed
				MOV		R9, #0x4		; set mode: waiting
				
				; write new display text
				BL		WRITE_READY_TIME
				BL		WRITE_NUMS
				
				MOV		R10, R7
				
				; turn of a green light
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_no
				STR		R1, [R2]
				
				
				B		RECOGNIZE_MODE
				LTORG

; RUN MODE
; =============================================================			
RUN_MODE

CHECK_BUTTON	
				LDR		R0, =GPIOA_IDR
				LDR		R1, [R0]
				TST		R1, #0x1			; je-li rovno 1, neni aktivni
				BEQ		CHECK_EXEC
				MOV		R0, #30
				BL		DELAY
				
				MOV		R7, R10				; copy time of a light shine
				MOV		R9, #0x3			; set mode: executing
				
				; display RUN TIME
				BL		CONFIG_DISPLAY
				BL		SET_URL_ADDRESS
				BL		WRITE_RUN_TIME
				BL		WRITE_NUMS
				
				; turn on blue light
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_blue
				STR		R1, [R2]
				
				MOV		R11, #0x0			; magic delay variable
				
				
CHECK_EXEC		
				CMP		R9, #0x3
				BNE		CHECK_OK_BUTTTON
				
				CMP		R11, #0x90000	; set magic delay
				BNE		MAGIC_SUB			; pokud dojede magicky delay na nulu, zreseti a odecti
				MOV		R11, #0x0
				SUB		R7, #0x1
				
				BL		WRITE_RUN_TIME
				BL		WRITE_NUMS
				
MAGIC_SUB
				ADD		R11, #0x1
				
NULL
				CMP		R7, #0x0
				BNE		CHECK_OK_BUTTTON
				
				
				MOV		R9, #0x4		; set mode: waiting
				MOV		R7, R10			; recovery time of a light shine
				
				; turn off blue light
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_no
				STR		R1, [R2]
				
				; display ready mode
				BL		WRITE_READY_TIME
				BL		WRITE_NUMS
				

CHECK_OK_BUTTTON
				LDR		R0, =GPIOA_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_11111111
				BIC		R1, R1, #2_1111011100000000
				CMP		R1, #2_100000000000
				BNE		RECOGNIZE_MODE
				MOV		R0, #50
				BL		DELAY
				
				MOV		R9, #0x2 		; set mode: setting
				
				BL		CONFIG_DISPLAY
				BL		SET_URL_ADDRESS
				BL		WRITE_SET_TIME
				BL		WRITE_NUMS
				
				
				
				
				B		RECOGNIZE_MODE
				LTORG
				
				
;***************************************************************
;*********        ~        PODRPOGRAMY       ~         *********
;***************************************************************

WRITE_NUMS
				PUSH	{LR}
				MOV		R8, R7
				
				CMP		R8, #9			
				BLS		SET_T_0
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_1
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_2
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_3
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_4
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_5
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_6
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_7
				SUB		R8, R8, #10
				CMP		R8, #9			
				BLS		SET_T_8
				SUB		R8, R8, #10
				CMP		R8, #9		
				BLS		SET_T_9

SET_T_0			MOV		R6, #0x30
				B		SET_B_NUM
SET_T_1			MOV		R6, #0x31
				B		SET_B_NUM
SET_T_2			MOV		R6, #0x32
				B		SET_B_NUM
SET_T_3			MOV		R6, #0x33
				B		SET_B_NUM
SET_T_4			MOV		R6, #0x34
				B		SET_B_NUM
SET_T_5			MOV		R6, #0x35
				B		SET_B_NUM
SET_T_6			MOV		R6, #0x36
				B		SET_B_NUM
SET_T_7			MOV		R6, #0x37
				B		SET_B_NUM
SET_T_8			MOV		R6, #0x38
				B		SET_B_NUM
SET_T_9			MOV		R6, #0x39
				B		SET_B_NUM
				
SET_B_NUM
				BL		SET_LETTER
				
				MOV		R6, #0x30
				ADD		R6, R6, R8
				BL		SET_LETTER
				
				POP		{PC}

WRITE_SET_TIME
				PUSH		{LR}
				BL		SET_TOP_ROW
				MOV		R6, #asci_S
				BL		SET_LETTER
				MOV		R6, #asci_E
				BL		SET_LETTER
				MOV		R6, #asci_T
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				MOV		R6, #asci_T
				BL		SET_LETTER
				MOV		R6, #asci_I
				BL		SET_LETTER
				MOV		R6, #asci_M
				BL		SET_LETTER
				MOV		R6, #asci_E
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				MOV		R6, #asci_equals
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				POP 	{PC}

WRITE_RUN_TIME
				PUSH		{LR}
				BL		SET_TOP_ROW
				MOV		R6, #asci_R
				BL		SET_LETTER
				MOV		R6, #asci_U
				BL		SET_LETTER
				MOV		R6, #asci_N
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				MOV		R6, #asci_T
				BL		SET_LETTER
				MOV		R6, #asci_I
				BL		SET_LETTER
				MOV		R6, #asci_M
				BL		SET_LETTER
				MOV		R6, #asci_E
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				MOV		R6, #asci_equals
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				POP 	{PC}

WRITE_READY_TIME
				PUSH		{LR}
				BL		SET_TOP_ROW
				MOV		R6, #asci_R
				BL		SET_LETTER
				MOV		R6, #asci_E
				BL		SET_LETTER
				MOV		R6, #asci_A
				BL		SET_LETTER
				MOV		R6, #asci_D
				BL		SET_LETTER
				MOV		R6, #asci_Y
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				MOV		R6, #asci_T
				BL		SET_LETTER
				MOV		R6, #asci_I
				BL		SET_LETTER
				MOV		R6, #asci_M
				BL		SET_LETTER
				MOV		R6, #asci_E
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				MOV		R6, #asci_equals
				BL		SET_LETTER
				MOV		R6, #asci_space
				BL		SET_LETTER
				POP 	{PC}

SET_URL_ADDRESS
				PUSH	{LR}
				BL		SET_BOTTOM_ROW
				MOV		R6, #asci_p
				BL		SET_LETTER
				MOV		R6, #asci_e
				BL		SET_LETTER
				MOV		R6, #asci_t
				BL		SET_LETTER
				MOV		R6, #asci_r
				BL		SET_LETTER
				MOV		R6, #asci_k
				BL		SET_LETTER
				MOV		R6, #asci_u
				BL		SET_LETTER
				MOV		R6, #asci_c
				BL		SET_LETTER
				MOV		R6, #asci_e
				BL		SET_LETTER
				MOV		R6, #asci_r
				BL		SET_LETTER
				MOV		R6, #asci_a
				BL		SET_LETTER
				MOV		R6, #asci_k
				BL		SET_LETTER
				MOV		R6, #asci_dot
				BL		SET_LETTER
				MOV		R6, #asci_c
				BL		SET_LETTER
				MOV		R6, #asci_z
				BL		SET_LETTER
				POP		{PC}
				
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_LETTER		; use R6 to define current letter value
				
				PUSH	{LR}
				
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_1
				MOV		R3, R6
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				
				POP		{PC}


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_BOTTOM_ROW
				PUSH	{LR}
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_0
				MOV		R3, #2_11000000
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				POP		{PC}
				
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_TOP_ROW
				PUSH	{LR}
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_0
				MOV		R3, #2_10000000
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				POP		{PC}
				
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CONFIG_DISPLAY
				PUSH	{LR}
				; 02 Nastavení funkce
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_0
				MOV		R3, #2_00111000
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				; Nastavení módu displeje
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_0
				MOV		R3, #2_00001110
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				; Nastavení módu vstupu dat
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_0
				MOV		R3, #2_00000110
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				; Smaz display
				BL		SET_ENABLE_1
				BL		SET_RW_0
				BL		SET_RS_0
				MOV		R3, #2_00000001
				BL		SET_DB_DATA
				MOV		R0, #1
				BL		DELAY
				BL		SET_ENABLE_0
				MOV		R0, #1
				BL		DELAY
				
				POP		{PC}

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_ENABLE_0
				LDR		R0, =GPIOB_ODR
				LDR		R1, [R0]
				BIC		R1, R1, #2_100000000
				ORR		R1, R1, #2_000000000
				STR		R1, [R0]	
				
				BX		LR				; navrat na misto spusteni podprogramu

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_ENABLE_1
				LDR		R0, =GPIOB_ODR
				LDR		R1, [R0]
				BIC		R1, R1, #2_100000000
				ORR		R1, R1, #2_100000000
				STR		R1, [R0]		
				
				BX		LR				; navrat na misto spusteni podprogramu
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_RW_0
				LDR		R0, =GPIOB_ODR
				LDR		R1, [R0]
				BIC		R1, R1, #2_1000000000
				ORR		R1, R1, #2_0000000000
				STR		R1, [R0]
				
				BX		LR				; navrat na misto spusteni podprogramu

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_RS_1	; instruction / data
				LDR		R0, =GPIOA_ODR
				MOV		R2,	#2_1000000000000	; nastaeni masky pro nulovani
				LDR		R1, [R0]		; nacti hodnotu
				BIC		R1, R1, R2		; vymazani dle masky
				MOV		R2, #2_1000000000000		; nastaveni hodnoty
				ORR		R1, R1, R2		; vyorovani hodnoty
				STR		R1, [R0]		; ulozeni hodnoty
				

				
				BX		LR				; navrat na misto spusteni podprogramu

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_RS_0	; instruction / data
				LDR		R0, =GPIOA_ODR
				MOV		R2,	#2_1000000000000	; nastaeni masky pro nulovani
				LDR		R1, [R0]		; nacti hodnotu
				BIC		R1, R1, R2		; vymazani dle masky
				MOV		R2, #0x0		; nastaveni hodnoty
				ORR		R1, R1, R2		; vyorovani hodnoty
				STR		R1, [R0]		; ulozeni hodnoty
				
				
				BX		LR				; navrat na misto spusteni podprogramu

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET_DB_DATA		; nastaveni dat pomoci shift registeru, hodnota ulozena do R3,

				LDR		R0, =GPIOB_ODR
				MOV		R5, #0x8		; nastaveni poctu cyklu
				
				LDR		R1, [R0]
				BIC		R1, R1, #2_0011100000
				ORR		R1, R1, #2_0011100000
				STR		R1, [R0]
				
				
CYCLE_1
				LDR		R2, =2_0011000000	; nastaveni masky pro nulovani
				LDR		R1, [R0]
				BIC		R1, R1, R2
				
				MOV		R4, #0x0
				AND		R4, R3, #2_10000000
				MOV		R2, #2_0010000000	; nahod jednicku
				CMP		R4, #2_10000000		; je-li po proandovani jednicka, preskoc instrukci
				BEQ		HOP_1
				MOV		R2, #0x0			; nahod nulu
HOP_1
				LSL		R3, R3, #0x1
				ORR		R1, R1, R2
				STR		R1, [R0]
				
				; aktivuj nabeznou hranu
				LDR		R1, [R0]
				BIC		R1, R1, #2_0001000000
				ORR		R1, R1, #2_0001000000
				STR		R1, [R0]
				
				; compare
				SUB		R5, R5, #0x1
				CMP		R5, #0x0
				BNE		CYCLE_1
				
				BX		LR				; navrat na misto spusteni podprogramu
				
				
				
				
										


;***************************************************************************************************
;* Jmeno funkce		: RCC_CNF
;* Popis			: Konfigurace systemovych hodin a hodin periferii
;* Vstup			: Zadny
;* Vystup			: Zadny
;* Komentar			: Nastaveni PLL jako zdroj hodin systemu (24MHz),
;*  				  a privedeni hodin na branu A, B a C 	
;**************************************************************************************************
RCC_CNF	
				LDR		R0, =RCC_CR		; Kopie adresy RCC_CR (Clock Control Register) do R0,
										; RCC_CRje v souboru INI.S			
				LDR		R1, [R0]		; Nacteni obsahu registru na adrese v R0 do R1
				BIC		R1, R1, #0x50000; Editace hodnoty v R1, tj. nulovani hodnoty, kde je '1'
										; HSE oscilator OFF (HSEON), ext.oscilator NOT BZPASSED(HSEBYP) 
				STR		R1, [R0]		; Ulozeni editovane hodnoty v R1 na adresu v R0 
 
				LDR		R1, [R0]		; Opet nacteni do R1 stav registru RCC_CR
				ORR		R1, R1, #0x10000; Maska pro zapnuti HSE	(krystalovy oscilator)	
				STR		R1, [R0]		; HSE zapnut
NO_HSE_RDY		LDR		R1, [R0]		; Nacteni do R1 stav registru RCC_CR
				TST	 	R1, #0x20000	; Test stability HSE, (R0 & 0x20000)
				BEQ 	NO_HSE_RDY		; Skok pri nestabilite, pri stabilite se pokracuje v kodu
	
				LDR		R0, =RCC_CFGR	; Nacteni adresy RCC_CFGR (Clock Configuration Register) do R0
				LDR		R1, [R0]		; Nacteni do R1 stav registru RCC_CFGR
				BIC		R1, R1, #0xF0	; Editace, SCLK nedeleno
				STR		R1, [R0]		; Ulozeni noveho stavu do RCC_CFGR 

				LDR		R1, [R0]		; Opet nacteni RCC_CFGR
				BIC		R1, R1, #0x3800	; Editace, HCLK nedeleno (PPRE2)
				STR		R1, [R0]		; Ulozeni nove hodnoty

				LDR		R1, [R0]		; Opet nacteni RCC_CFGR
				BIC		R1, R1, #0x700	; HCLK nedeleno	(PPRE1)
				ORR		R1, R1, #0x400	; Maskovani, konstanta pro HCLK/2
				STR		R1, [R0]		; Ulozeni nove hodnoty
			
				LDR		R1, [R0]		 ; Opet nacteni RCC_CFGR
				BIC		R1, R1, #0x3F0000; Nuluje PLLMUL, PLLXTPRE, PLLSRC
				LDR		R2, =0x50000	 ; Maska, PLL x3, HSE jako PLL vstup =24MHz Clk
				ORR		R1, R1, R2		 ; Maskovani, logicky soucet R1 a R2	
				STR		R1, [R0]		 ; Ulozeni nove hodnoty		 

				LDR		R0, =PLLON		; Nacteni adresy bitu PLLON do R0(ADRESA BIT BANDING)
				MOV		R1, #0x01		; Konstanta pro povoleni PLL (fazovy zaves) 
				STR		R1, [R0]		; Ulozeni nove hodnoty

				LDR		R0, =RCC_CR		; Kopie adresy  RCC_CR do R0
NO_PLL_RDY		LDR		R1, [R0]		; Nacteni stavu registru RCC_CR do R1
				TST		R1, #0x2000000	; Test spusteni PLL (test stability)
				BEQ		NO_PLL_RDY		; Skok na navesti NO_PLL_RDY pri nespustene PLL

				LDR		R0, =RCC_CFGR	; Kopie adresy RCC_CFGR do R0
				LDR		R1, [R0]		; Nacteni stavu registru RCC_CFGR do R1
				BIC		R1, R1, #0x3	; HSI jako hodiny
			;	ORR		R1, R1, #0x1	; Maskovani, HSE jako hodiny
				ORR		R1, R1, #0x2	; Maskovani, PLL jako hodiny
				STR		R1, [R0]		; PLL je zdroj hodin

				LDR		R0, =RCC_APB2ENR; Kopie adresy RCC_APB2ENR (APB2 peripheral clock enable register) do R0  
				LDR		R1, [R0]		; Nacteni stavu registru RCC_APB2ENR do R1
				LDR		R2, =0x1C		; Konstanta pro zapnuti hodin pro branu A, B a C
				ORR		R1, R1, R2		; Maskovani		
				STR		R1, [R0]		; Ulozeni nove hodnoty

				BX		LR				; Navrat z podprogramu, skok na adresu v LR
 
;**************************************************************************************************
;* Jmeno funkce		: GPIO_CNF
;* Popis			: Konfigurace brany A, B a C
;* Vstup			: Zadny
;* Vystup			: Zadny
;* Komentar			: 
;					: A GATE - (GPIOA_CRL)
;					: - PA0: blue button
;					: A GATE - (GPIOA_CRH)				0001 1000 0000 0000 0000 | 1111 1111 0000 0000 0000
;					: - PA11: in|confirm				1000
;					: - PA12: out|DATA/INSTRUCTION		0001

;					: B GATE - (GPIOB_CRL)				0001 0001 0001 0000 0000 0000 0000 0000 | 1111 1111 1111 0000 0000 0000 0000 0000
;					: - PB05: out|RESET					0001
;					: - PB06: out|CLK					0001
;					: - PB07: out|DATA					0001
;					: B GATE - (GPIOB_CRH)				0001 0001 | 1111 1111
;					: - PB08: out|ENABLE				0001
;					: - PB09: out|R/W					0001

;					: C GATE (GPIOC_CRL)				1000 1000 0000 0000 0000 0000 0000 0000 | 1111 1111 0000 0000 0000 0000 0000 0000
;					: - PC06: in|UP						1000
;					: - PC07: in|DOWN					1000
;					: C GATE (GPIOC_CRH)				0001 0001 | 1111 1111
;					: - PC08: blue						0001
;					: - PC09: green						0001
;**************************************************************************************************
GPIO_CNF								; Navesti zacatku podprogramu
Gate_A_LOW		LDR		R2, =0xF		; Konstanta pro nulovani nastaveni bitu 0	
				LDR		R0, =GPIOA_CRL	; Kopie adresy GPIOA_CRL (Port Configuration Register Low)
										; do R0, GPIOA_CRL je v souboru INI.S	
				LDR		R1, [R0]		; Nacteni hodnoty z adresy v R0 do R1 
				BIC		R1, R1, R2 		; Nulovani bitu v R2 
				MOV		R2, #0x8		; Vlozeni 1 do R2
				ORR		R1, R1, R2		; maskovani, bit 0 nastven jako push-pull vstup
				STR		R1, [R0]		; Ulozeni konfigurace PAO0
				
Gate_A_HIGH		LDR		R2, =0xFF000	; mask
				LDR		R0, =GPIOA_CRH
				LDR		R1, [R0]
				BIC		R1, R1, R2
				MOV		R2, #0x18000	; value
				ORR		R1, R1, R2
				STR		R1, [R0]
				
Gate_B_LOW		LDR		R2, =0xFFF00000
				LDR		R0, =GPIOB_CRL
				LDR		R1, [R0]
				BIC		R1, R1, R2
				MOV		R2, #0x1100000
				ORR		R1, R1, R2
				MOV		R2, #0x10000000
				ORR		R1, R1, R2
				STR		R1, [R0]
				
Gate_B_HIGH		LDR		R2, =0xFF
				LDR		R0, =GPIOB_CRH
				LDR		R1, [R0]
				BIC		R1, R1, R2
				MOV		R2, #0x11
				ORR		R1, R1, R2
				STR		R1, [R0]
				
Gate_C_LOW		LDR		R2, =0xFF000000
				LDR		R0, =GPIOC_CRL
				LDR		R1, [R0]
				BIC		R1, R1, R2
				MOV		R2, #0x88000000
				ORR		R1, R1, R2
				STR		R1, [R0]
				
				
Gate_C_HIGH		LDR		R2, =0xFF		; Konstanta pro nulovani nastaveni bitu 8, 9	
				LDR		R0, =GPIOC_CRH	; Kopie adresy GPIOC_CRH (Port Configuration Register High)
										; do R0, GPIOC_CRH je v souboru INI.S	
				LDR		R1, [R0]		; Nacteni hodnoty z adresy v R0 do R1 
				BIC		R1, R1, R2 		; Nulovani bitu v R2 
				MOV		R2, #0x11		; Vlozeni 1 do R2
				ORR		R1, R1, R2		; maskovani, bit 8, 9 nastven jako vystup push-pull v modu 1 (10MHz)
				STR		R1, [R0]		; Ulozeni konfigurace PCO9 a PC09

				BX		LR				; Navrat z podprogramu, skok na adresu v LR

;**************************************************************************************************
;* Jmeno funkce		: DELAY
;* Popis			: Softwarove zpozdeni procesoru
;* Vstup			: R0 = pocet opakovani cyklu spozdeni
;* Vystup			: Zadny
;* Komentar			: Podprodram zpozdi prubech vykonavani programu	
;**************************************************************************************************
DELAY 									; Navesti zacatku podprogramu
				PUSH	{R2, LR}		; Ulozeni hodnoty R2 do zasobniku (R2 muze byt editovan)
										; a ulozeni navratove adresy do zasobniku
WAIT1			
				LDR		R2, =40000		; Vlozeni konstanty pro prodlevu do R2
WAIT			SUBS	R2, R2, #1		; Odecteni 1 od R2,tj. R2 = R2 - 1 a nastaveni priznakoveho registru   	
				BNE		WAIT			; Skok na navesti pri nenulovosti R2 (skok dle priznaku)
				SUBS	R0, R0, #1
				BNE		WAIT1
			
				POP		{R2, PC}		; Navrat z podprogramu, obnoveni hodnoty R2 ze zasobniku
										; a navratove adresy do PC

;**************************************************************************************************
				NOP
				END	
