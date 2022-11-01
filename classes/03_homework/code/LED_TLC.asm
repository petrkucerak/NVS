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
	
magicDelay	EQU	0x70
	
NUM_0		EQU	2_11111100
NUM_1		EQU	2_01100000
NUM_2		EQU	2_11011010
NUM_3		EQU	2_11110010
NUM_4		EQU	2_01100110
NUM_5		EQU	2_10110110
NUM_6		EQU	2_10111110
NUM_7		EQU	2_11100000
NUM_8		EQU	2_11111110
NUM_9		EQU	2_11110110
; výstup Qx hgfedcba



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
										
				MOV		R7, #4			; vychozi hodnota
				MOV		R8, #2			; mode: 2 - setting, 3 -executed
TERMINATE_MODE	
				CMP		R8, #3
				BEQ		RUN_MODE
;; SETTING MODE
;; ==============================================
CATCH_NUM
				MOV		R3, #0x0		; delka zmacknuti counter
				MOV		R10, R7			; prirazeni nastavene hodnoty do zasobniku pro mod c. 2

PLUS_BUTTON_CHECK
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
				
				CMP		R3, #0x2
				BHI		PLUS_10
				
				ADD		R7, R7, #0x1
				B		MINUS_BUTTON_CHECK
PLUS_10			ADD		R7, R7, #0xA
				
MINUS_BUTTON_CHECK
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
				B		OK_BUTTON_CHECK
MINUS_10		SUB		R7, R7, #0xA
				
OK_BUTTON_CHECK
				LDR		R0, =GPIOA_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_11111111
				BIC		R1, R1, #2_1111011100000000
				CMP		R1, #2_100000000000
				BNE		DISPLAYING
				MOV		R0, #50
				BL		DELAY
				
				MOV		R8, #3
				MOV		R9, #2
				MOV		R11, #magicDelay
				B		DISPLAYING
;; ==============================================
RUN_MODE

				;MOV		R9, #0x2			; status of light: 2 - turn off, 3 - turn on

OK_BUTTON_CHECK_RUN
				LDR		R0, =GPIOA_IDR
				LDR		R1, [R0]
				BIC		R1, R1, #2_11111111
				BIC		R1, R1, #2_1111011100000000
				CMP		R1, #2_100000000000
				BNE		CHECK_BUTTON
				MOV		R0, #50
				BL		DELAY
				
				MOV		R8, #2
				B		CHECK_BUTTON
				
CHECK_BUTTON
				LDR		R0, =GPIOA_IDR
				LDR		R1, [R0]
				TST		R1, #0x1			; je-li rovno 1, neni aktivni
				BEQ		PROCESS
				MOV		R0, #30
				BL		DELAY
				
				MOV		R7, R10
				MOV		R9, #0x3
				

				
PROCESS
				CMP		R9, #0x2			; neni-li svetlo aktivovano
				BEQ		DISPLAYING
				
				
				CMP		R7, #0x0			; je-li donulovano, skorc rovnou na zobrazeni
				BEQ		NULL
				; magicka podminka pro zpomaleni
				CMP		R11, 0x0
				BNE		MAGIC_SKIP
				SUB		R7, R7, #0x1		; jinac odecti a zobraz a rozsvit
				MOV		R11, #magicDelay
MAGIC_SKIP
				SUB		R11, R11, 0x1
											; zapni svetlo
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_blue
				STR		R1, [R2]
				
				CMP		R7, #0x6
				BEQ		TURN_OFF_WARNING
				CMP		R7, #0x4
				BEQ		TURN_OFF_WARNING
				CMP		R7, #0x2
				BEQ		TURN_OFF_WARNING
				B		DISPLAYING		
				
TURN_OFF_WARNING
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_no
				STR		R1, [R2]	
				B		DISPLAYING
				
NULL			; dostal jsem se na nulu
				MOV		R9, #0x2			; zmen mod
				MOV		R7, R10				; nahraj puvodni hodnotu
											; vypnu svetlo
				LDR		R2, =GPIOC_ODR
				MOV		R1, #konst_no
				STR		R1, [R2]
				
				MOV		R11, #magicDelay	; magic delay
				
				B		DISPLAYING
				
				
;; ==============================================
DISPLAYING
				
				MOV		R6, R7
				
NUMEBR_SET_SECTION_T

				CMP		R6, #9
				BLS		SET_T_0
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_1
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_2
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_3
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_4
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_5
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_6
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_7
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_8
				SUB		R6, R6, #10
				CMP		R6, #9
				BLS		SET_T_9
				
SET_T_0			
				MOV		R4, #:NOT:NUM_0	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_1			
				MOV		R4, #:NOT:NUM_1	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_2			
				MOV		R4, #:NOT:NUM_2	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_3			
				MOV		R4, #:NOT:NUM_3	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_4			
				MOV		R4, #:NOT:NUM_4	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_5			
				MOV		R4, #:NOT:NUM_5	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_6			
				MOV		R4, #:NOT:NUM_6	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_7			
				MOV		R4, #:NOT:NUM_7	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_8			
				MOV		R4, #:NOT:NUM_8	; hodnota majici se nahrat
				B		PREPROCESS_T
SET_T_9			
				MOV		R4, #:NOT:NUM_9	; hodnota majici se nahrat
				B		PREPROCESS_T



PREPROCESS_T									
				LDR		R0, =GPIOB_ODR	; nacteni adres bran
				MOV		R3, #0x0		; definice counteru
				MOV		R1, #2_0111100000	; nastaveni pocatecni hodnoty
				STR		R1, [R0]		; nahrani pocatecni hodnoty
				
				
LOADING_CIRCLE_T
				
				LDR		R2, =2_0011000000	; nastaveni masky pro nulovani
				LDR		R1, [R0]
				BIC		R1, R1, R2			; vynuluj dane bity dle masky
				
				MOV		R5, #0x0
				AND		R5, R4, #0x1 		; vyanduj s maskou
				MOV		R2, #2_0010000000	; nahod jednicku
				CMP		R5, 0x1				; je li po vmaskovani jednicka, preskoc nasledujici instrukci
				BEQ		HOP1_T		
				MOV		R2, #2_0000000000	; nahod nulu
HOP1_T		
				ROR		R4, R4, #0x1		; rotuj hodnotu
				ORR		R1, R1, R2
				STR		R1, [R0]
				
				; aktivuj nabeznou hranu
				LDR		R1, [R0]
				BIC		R1, R1, #2_0001000000
				ORR		R1, R1, #2_0001000000
				STR		R1, [R0]


				; compoare
				CMP		R3, #0x7
				BEQ		CONTINUE_T
				ADD		R3, R3, #0x1	; incease a value of loading pointer
				B		LOADING_CIRCLE_T
				
CONTINUE_T			
				MOV		R0, #1
				BL		DELAY			; pocekej, abys odchytil chveni
				

				
				
NUMEBR_SET_SECTION_D

				CMP		R6, #0
				BEQ		SET_D_0
				CMP		R6, #1
				BEQ		SET_D_1
				CMP		R6, #2
				BEQ		SET_D_2
				CMP		R6, #3
				BEQ		SET_D_3
				CMP		R6, #4
				BEQ		SET_D_4
				CMP		R6, #5
				BEQ		SET_D_5
				CMP		R6, #6
				BEQ		SET_D_6
				CMP		R6, #7
				BEQ		SET_D_7
				CMP		R6, #8
				BEQ		SET_D_8
				CMP		R6, #9
				BEQ		SET_D_9
				
SET_D_0			
				MOV		R4, #:NOT:NUM_0	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_1			
				MOV		R4, #:NOT:NUM_1	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_2			
				MOV		R4, #:NOT:NUM_2	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_3			
				MOV		R4, #:NOT:NUM_3	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_4			
				MOV		R4, #:NOT:NUM_4	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_5			
				MOV		R4, #:NOT:NUM_5	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_6			
				MOV		R4, #:NOT:NUM_6	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_7			
				MOV		R4, #:NOT:NUM_7	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_8			
				MOV		R4, #:NOT:NUM_8	; hodnota majici se nahrat
				B		PREPROCESS_D
SET_D_9			
				MOV		R4, #:NOT:NUM_9	; hodnota majici se nahrat
				B		PREPROCESS_D



PREPROCESS_D										
				LDR		R0, =GPIOB_ODR	; nacteni adres bran
				MOV		R3, #0x0		; definice counteru
				MOV		R1, #2_1011100000	; nastaveni pocatecni hodnoty
				STR		R1, [R0]		; nahrani pocatecni hodnoty
				
				
LOADING_CIRCLE_D
				
				LDR		R2, =2_0011000000	; nastaveni masky pro nulovani
				LDR		R1, [R0]
				BIC		R1, R1, R2			; vynuluj dane bity dle masky
				
				MOV		R5, #0x0
				AND		R5, R4, #0x1 		; vyanduj s maskou
				MOV		R2, #2_0010000000	; nahod jednicku
				CMP		R5, 0x1				; je li po vmaskovani jednicka, preskoc nasledujici instrukci
				BEQ		HOP1_D			
				MOV		R2, #2_0000000000	; nahod nulu
HOP1_D			
				ROR		R4, R4, #0x1		; rotuj hodnotu
				ORR		R1, R1, R2
				STR		R1, [R0]
				
				; aktivuj nabeznou hranu
				LDR		R1, [R0]
				BIC		R1, R1, #2_0001000000
				ORR		R1, R1, #2_0001000000
				STR		R1, [R0]


				; compoare
				CMP		R3, #0x7
				BEQ		CONTINUE_D
				ADD		R3, R3, #0x1	; incease a value of loading pointer
				B		LOADING_CIRCLE_D
				
CONTINUE_D		
				MOV		R0, #1
				BL		DELAY			; pocekej, abys odchytil chveni

				B		TERMINATE_MODE
			


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
;* Komentar			: Nastaveni PC08 a PC09 jako vystup (10MHz), PA0 jako vstup push-pull
;					: A GATE - (GPIOA_CRL)
;					: - PA0: blue button
;					: A GATE - (GPIOA_CRH)
;					: - PA11: in|OK

;					: B GATE - (GPIOB_CRL)
;					: - PB05: out|RESET
;					: - PB06: out|CLK
;					: - PB07: out|DATA
;					: B GATE - (GPIOB_CRH)
;					: - PB08: out|LEFT LIGHT
;					: - PB09: out|RIGHT LIGHT

;					: C GATE (GPIOC_CRL)
;					: - PC06: in|UP
;					: - PC07: in|DOWN
;					: C GATE (GPIOC_CRH)
;					: - PC08: blue
;					: - PC09: green
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
				
Gate_A_HIGH		LDR		R2, =0xF000
				LDR		R0, =GPIOA_CRH
				LDR		R1, [R0]
				BIC		R1, R1, R2
				MOV		R2, #0x8000
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
