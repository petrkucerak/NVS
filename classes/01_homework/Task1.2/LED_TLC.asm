;***************************************************************************************************
;*
;* Misto			: CVUT FEL, Katedra Mereni
;* Prednasejici		: Doc. Ing. Jan Fischer,CSc.
;* Predmet			: A4M38AVS
;* Vyvojovy Kit		: STM32 VL DISCOVERY (STM32F100RB)
;*
;**************************************************************************************************
;*
;* JM�NO SOUBORU	: LED_TLC.ASM
;* AUTOR			: Michal TOM��
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
konst_green	EQU	0x0100
konst_blue	EQU	0x0200
konst_no	EQU	0x0
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

				LDR		R2, =GPIOC_ODR	; Kopie adresy brany C ODR do R2, GPIOC_ODR je v souboru INI.S			
										; ODR - Output Data Register
				MOV		R7, #konst_all	; vychozi hodnota pro blik 1
				MOV		R6,	#konst_no	; vychozi hodnota pro blik 2
				MOV		R8, #0			; vychozi hodnota pro vystup SOS
				MOV		R4,	#0			; Vlozeni 0 do R4, nulovani citace (softwarov� citac registr R4)
				MOV		R3, #0			; Vytvor stavovy automat (citac z registru R3)
				LDR		R5, =GPIOA_IDR 	; Kopie adresy brany A IDR do R5, GPIOA_IDR je v souboru INI.S			
										; IDR - Input Data Register
										
LOOP			; hlavni smycka programu
				ADD		R4, R4, #0x1	; inkrementace citace
				
				CMP		R4, #0x0
				BEQ		SET_OFF
				
				CMP		R4, #0x8000
				BEQ		SET_ON
				
				CMP		R4, #0x10000
				BEQ		SET_OFF
				CMP		R4, #0x18000
				BEQ		SET_OFF
				
				CMP		R4, #0x20000
				BEQ		SET_ON
				
				CMP		R4, #0x28000
				BEQ		SET_OFF
				CMP		R4, #0x30000
				BEQ		SET_OFF
				
				CMP		R4, #0x38000
				BEQ		SET_ON
				
				CMP		R4, #0x40000
				BEQ		SET_OFF
				CMP		R4, #0x48000
				BEQ		SET_OFF
				
				CMP		R4, #0x50000
				BEQ		SET_ON
				CMP		R4, #0x58000
				BEQ		SET_ON
				CMP		R4, #0x60000
				BEQ		SET_ON
				
				CMP		R4, #0x68000
				BEQ		SET_OFF
				CMP		R4, #0x70000
				BEQ		SET_OFF
				CMP		R4, #0x78000
				
				BEQ		SET_ON
				CMP		R4, #0x80000
				BEQ		SET_ON
				CMP		R4, #0x88000
				BEQ		SET_ON
				
				CMP		R4, #0x90000
				BEQ		SET_OFF
				CMP		R4, #0x98000
				BEQ		SET_OFF
				
				CMP		R4, #0xA0000
				BEQ		SET_ON
				CMP		R4, #0xA8000
				BEQ		SET_ON
				CMP		R4, #0xB0000
				BEQ		SET_ON
				
				CMP		R4, #0xB8000
				BEQ		SET_OFF
				CMP		R4, #0xC0000
				BEQ		SET_OFF
				
				CMP		R4, #0xC8000
				BEQ		SET_ON
				
				CMP		R4, #0xD0000
				BEQ		SET_OFF
				CMP		R4, #0xD8000
				BEQ		SET_OFF
				
				CMP		R4, #0xE0000
				BEQ		SET_ON
				
				CMP		R4, #0xE8000
				BEQ		SET_OFF
				CMP		R4, #0xF0000
				BEQ		SET_OFF
				
				CMP		R4, #0xF8000
				BEQ		SET_ON
				
				CMP		R4, #0x100000
				BEQ		SET_ALL_OFF
				
				CMP		R4, #0x120000
				BEQ		NORMALIZE_R4

FSM				; FSM
				CMP		R3, #0
				BEQ		STAGE_A
				CMP		R3, #1
				BEQ		STAGE_B
				CMP		R3, #2
				BEQ		STAGE_C
				CMP		R3, #3
				BEQ		STAGE_D

SET_ON
				MOV		R8, #0x1
				B		FSM	
SET_OFF			
				MOV		R8, #0x0
				B		FSM
SET_ALL_OFF
				MOV		R8, #0x2
				B		FSM
NORMALIZE_R4
				MOV		R4, #0
				B		FSM


				
BUTTON_CHECK	; OSETRENI TLACITKA
				LDR		R1, [R5]
				TST		R1, #0x1
				BEQ		LOOP
				
				; osetreni zpetne vazby
				MOV		R0, #50
				BL		DELAY
				
				; inkrementace FSM
				ADD		R3, R3, #0x1
				CMP		R3, #4
				BEQ		NORMALIZE
				
				B		LOOP
				
				
NORMALIZE		; pokud je stav vetsi nez 3, nastav zpatky nulu
				MOV		R3, #0
				B		LOOP
				
				
				
				
STAGE_A			; SOS x N SOS
				CMP		R8,	#0x1
				BEQ		LED_GREEN_ON
				
				CMP		R8, #0x0
				BEQ		LED_BLUE_ON
				
				CMP		R8, #0x2
				BEQ		LED_ALL_OFF
				
				B		BUTTON_CHECK
				
				
				
STAGE_B			; 0 x SOS
				CMP		R8, #0x1
				BEQ		LED_BLUE_ON
				
				CMP		R8, #0x0
				BEQ		LED_ALL_OFF
				
				CMP		R8, #0x2
				BEQ		LED_ALL_OFF
				
				B		BUTTON_CHECK
				
				
STAGE_C			; SOS x 0
				CMP		R8, #0x1
				BEQ		LED_GREEN_ON
				
				CMP		R8, #0x0
				BEQ		LED_ALL_OFF
				
				CMP		R8, #0x2
				BEQ		LED_ALL_OFF
				
				B		BUTTON_CHECK
				
				
STAGE_D			; 1 x 1
				MOV		R1, #konst_all
				STR		R1, [R2]
				
				B		BUTTON_CHECK

				
				
				
LED_GREEN_ON
				MOV		R1, #konst_green
				STR		R1, [R2]
				
				B		BUTTON_CHECK
				
LED_BLUE_ON
				MOV		R1, #konst_blue
				STR		R1, [R2]
				
				B		BUTTON_CHECK

LED_ALL_ON
				MOV		R1, #konst_all
				STR		R1, [R2]
				
				B		BUTTON_CHECK
				
LED_ALL_OFF
				MOV		R1, #konst_no
				STR		R1, [R2]
				
				B		BUTTON_CHECK
				
				
			


;***************************************************************************************************
;* Jmeno funkce		: RCC_CNF
;* Popis			: Konfigurace systemovych hodin a hodin periferii
;* Vstup			: Zadny
;* Vystup			: Zadny
;* Komentar			: Nastaveni PLL jako zdroj hodin systemu (24MHz),
;*  				  a privedeni hodin na branu A a C 	
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
				LDR		R2, =0x14		; Konstanta pro zapnuti hodin pro branu A a C
				ORR		R1, R1, R2		; Maskovani		
				STR		R1, [R0]		; Ulozeni nove hodnoty

				BX		LR				; Navrat z podprogramu, skok na adresu v LR
 
;**************************************************************************************************
;* Jmeno funkce		: GPIO_CNF
;* Popis			: Konfigurace brany A a C
;* Vstup			: Zadny
;* Vystup			: Zadny
;* Komentar			: Nastaveni PC08 a PC09 jako vystup (10MHz), PA0 jako vstup push-pull	
;**************************************************************************************************
GPIO_CNF								; Navesti zacatku podprogramu
				LDR		R2, =0xFF		; Konstanta pro nulovani nastaveni bitu 8, 9	
				LDR		R0, =GPIOC_CRH	; Kopie adresy GPIOC_CRH (Port Configuration Register High)
										; do R0, GPIOC_CRH je v souboru INI.S	
				LDR		R1, [R0]		; Nacteni hodnoty z adresy v R0 do R1 
				BIC		R1, R1, R2 		; Nulovani bitu v R2 
				MOV		R2, #0x11		; Vlozeni 1 do R2
				ORR		R1, R1, R2		; maskovani, bit 8, 9 nastven jako vystup push-pull v modu 1 (10MHz)
				STR		R1, [R0]		; Ulozeni konfigurace PCO9 a PC09

				LDR		R2, =0xF		; Konstanta pro nulovani nastaveni bitu 0	
				LDR		R0, =GPIOA_CRL	; Kopie adresy GPIOA_CRL (Port Configuration Register Low)
										; do R0, GPIOA_CRL je v souboru INI.S	
				LDR		R1, [R0]		; Nacteni hodnoty z adresy v R0 do R1 
				BIC		R1, R1, R2 		; Nulovani bitu v R2 
				MOV		R2, #0x8		; Vlozeni 1 do R2
				ORR		R1, R1, R2		; maskovani, bit 0 nastven jako push-pull vstup
				STR		R1, [R0]		; Ulozeni konfigurace PAO0

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
