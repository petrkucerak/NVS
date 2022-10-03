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
				LDR		R5, =GPIOA_IDR 	; Kopie adresy brany A IDR do R5, GPIOA_IDR je v souboru INI.S			
										; IDR - Input Data Register
				MOV		R3, #0x0		; counter
				MOV		R4, #0x0		; button counter
				MOV		R6, #0x0		; FSM
										; 0 - cekani na stisk
										; 1 - kratka sekvence
										; 2 - dlouha sekvence
				MOV		R7, #0x0		; deadline
	
LOOP
				ADD		R3, R3, #0x1	; inkrementuj counter
				
FSM_CHECK
				CMP		R6, #0x0		; je-li status rovny nule, vykonej stejnou vec jako by counter presahl deadline
				BEQ		DEADLINE_PROCESS
				
				
LIGHT_CHECK
				MOV		R1, #konst_blue
				CMP		R3, R7
				BNE		LIGHT_SET		; dokud se nerovnaji, svit
DEADLINE_PROCESS						; je-li mensi
				MOV		R1, #konst_no	; prestan svitit
				MOV		R3, #0x0		; vubuluj counter
				MOV		R6, #0x0		; nastav FSM na cekani na stisk
				
LIGHT_SET
				STR		R1, [R2]		; propis hodnotu a rozvit nebo zhasni
				

BUTTON_CHECK
				MOV		R4, #0x0		; vynuluj button counter
				LDR		R1, [R5]		; nacti data z gate tlacitka
				TST		R1, #0x1		; je-li rovno 1, neni stiskle
				BEQ		LOOP			; pokud neni stiskle, skoc zpet na LOOP
				
BUTTON_DELAY
				; rozsviceni zeleneho svetla
				MOV		R1, #konst_green
				CMP		R6, #0x0		; neni-li stav v cekani, blikni obema svetly
				BEQ		LIGHT_BOTH1
				MOV		R1, #konst_all
LIGHT_BOTH1
				STR		R1, [R2]		; rozvist svetla
				
				; tlacitko
				ADD		R4, R4, #0x1	; inkrementuj button counter
				
				MOV		R0, #50
				BL		DELAY			; pocekej, abys odchytil chveni
				
				LDR		R1, [R5]		; nacti data z gate tlacitka
				TST		R1, #0x1		; je-li rovno 1, neni tlacitko stiskle
				BNE		BUTTON_DELAY	; je-li tlacitko stikle, vrat se na BUTTON_DELAY
				
				; zhasinani zeleneho svetla
				MOV		R1, #konst_all
				CMP		R6, #0x0
				BEQ		LIGHT_BOTH2
				MOV		R1, #konst_blue
LIGHT_BOTH2				
				STR		R1, [R2]
				
				
				; zkontroluj delku stisku
				CMP		R4, #0x002		; je-li hodnota vetsi nez TODO: nastav limit na delsi hodnotu
				BHI		SET_LONG_TIME

SET_SHORT_TIME
				MOV		R6, #0x1		; FSM - 1
				MOV		R3, #0x0		; counter = 0
				MOV		R7, #0x400000		; waiting value
				B		LOOP
				
SET_LONG_TIME
				MOV		R6, #0x2		; FSM - 2
				MOV		R3, #0x0		; counter = 0
				MOV		R7, #0xF00000		; waiting value
				B		LOOP
				
				
				
				
				
			


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
