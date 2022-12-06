/**
 * University:  		CVUT FEL, Department of Measurement
 * Lecturer:			Doc. Ing. Jan Fischer, CSc.
 * Course:	 			A4B38NVS
 * Evaluation board: 	STM32 VL DISCOVERY (STM32F100RB)
 *
 * @brief This is a simple USART demo application tailored for processor
 * STM32F100RB used in
 * VL Discovery Kit evaluation board by ST Microelectronics.
 *
 * NOTE:
 * Standard Peripheral Library package is not supported in the project.
 *
 * Find detailed functional description in README.txt in the project directory.
 *
 * Podrobny popis funkce naleznete v souboru README_cz.txt v projektovem
 * adresari.
 *
 * @author Vojtech Elias
 *
 */

#include "stm32f10x.h"

/* Definitions */
#define USART_ENGAGED USART1
#define CHAR_OFFSET (('a') - ('A'))

#define TEXT_LENGTH 20
#define NEW_LINE_LENGTH 2

#define CR_CHAR (0x0D)
#define LF_CHAR (0x0A)

/* Function prototypes */
static void RCC_Configuration(void);
static void GPIO_Configuration(void);
static void USART_Configuration(void);

static void USART_SendData(USART_TypeDef *USARTx, uint16_t Data);
static void Delay(vu32 nCount);

char *message = "Welcome to A4B38NVS!";
char new_line[NEW_LINE_LENGTH] = {CR_CHAR, LF_CHAR};
uint8_t tx_ptr = 0;

/** System init
 *
 * Called by the startup file.
 * This function initializes the Embedded Flash Interface, the PLL and update
 * the SystemCoreClock variable.
 *
 * The function is defined in file system_stm32f10x.c which is part of
 * the Standard Peripheral Library package
 *
 * The implementation is let emty in this case (Standard Peripheral Library not
 * supported)
 */
void SystemInit(void) { /* Let empty in this case */ }

/* Program entry point */
int main(void) {

  /* Configure RCC (Reset and Clock Control) */
  RCC_Configuration();

  /* Configure GPIOs */
  GPIO_Configuration();

  /* Configure USART peripheral */
  USART_Configuration();

  /* Clear TC flag */
  USART_ENGAGED->SR &= 0xFFBF;
  /* Start message transmission */
  USART_SendData(USART_ENGAGED, message[tx_ptr]);

  /* Program Loop */
  while (1) {

    /* Check TC flag */
    if (USART_ENGAGED->SR & 0x0040) {
      if (tx_ptr == TEXT_LENGTH - 1) {
        /* Send CR (Carriage Return) character */
        tx_ptr++;
        USART_SendData(USART_ENGAGED, new_line[0]);
      } else if (tx_ptr == TEXT_LENGTH) {
        /* Send LF (Line Feed) character */
        tx_ptr++;
        USART_SendData(USART_ENGAGED, new_line[1]);
      } else if (tx_ptr == TEXT_LENGTH + 1) {
        /* Message transmission complete */
        tx_ptr = 0;

        /* Short delay */
        Delay(0x3FFFFF);

        /* Start new data transmission */
        USART_SendData(USART_ENGAGED, message[tx_ptr]);
      } else {
        /* Continue message transmission */
        tx_ptr++;
        USART_SendData(USART_ENGAGED, message[tx_ptr]);
      }
    }

    /* Other flags could be polled here */
    else if (0) {
      /* Add your further application code here */
    } else if (0) {
      /* Add your further application code here */
    } else {
      /* Add your further application code here */
    }
  }
}

/* RCC initialization */
static void RCC_Configuration(void) {
  /* Turn on HSE */
  RCC->CR |= 0x10000;
  while (!(RCC->CR & 0x20000)) {
  }

  /* Flash access setup */
  FLASH->ACR &= 0x00000038;
  FLASH->ACR |= 0x00000002; // flash 2 wait state

  FLASH->ACR &= 0xFFFFFFEF;
  FLASH->ACR |= 0x00000010; // enable Prefetch Buffer

  /* PLL setup (SYSCLK = 3*PLLCLK) */
  RCC->CFGR &= 0xFFC3FFFF;
  RCC->CFGR |= 0x1 << 18;

  RCC->CFGR &= 0xFFFEFFFF;
  RCC->CFGR |= 0x00 << 17; // set PREDIV1 1x

  RCC->CFGR |= 0x10000;    // HSE as PLL clk input
  RCC->CFGR &= 0xFFFFFF0F; // HPRE=1x
  RCC->CFGR &= 0xFFFFF8FF; // PPRE2=1x
  RCC->CFGR &= 0xFFFFC7FF; // PPRE2=1x

  /* Turn on PLL */
  RCC->CR |= 0x01000000;
  while (!(RCC->CR & 0x02000000)) {
  }

  /* Set PLL as SYSCLK source */
  RCC->CFGR &= 0xFFFFFFFC;
  RCC->CFGR |= 0x2;

  /* Wait for PLL startup */
  while (!(RCC->CFGR & 0x00000008)) {
  }

  /* Peripheral clock enable */
  /* GPIOA */
  RCC->APB2ENR |= 0x04;

  /* USART1 */
  RCC->APB2ENR |= 0x4000;
}

/* GPIO initialization */
static void GPIO_Configuration(void) {
  /* Configure PA9 (USART1 TX): alternate func. output Push-pull, 10MHz */
  GPIOA->CRH &= 0xFFFFFF0F;
  GPIOA->CRH |= 0x000000B0;

  /* Configure PA10 (USART RX): floating input */
  GPIOA->CRH &= 0xFFFFF0FF;
  GPIOA->CRH |= 0x00000400;
}

/* USART initialization */
static void USART_Configuration(void) {
  /* Baud Rate setup 9600 Bd (see Reference manual for details) */
  USART_ENGAGED->BRR = 0x09C4;

  /* 8 data bits */
  USART_ENGAGED->CR1 &= 0xEFFF;

  /* 1 stopbit */
  USART_ENGAGED->CR2 &= 0xCFFF;

  /* Parity disabled */
  USART_ENGAGED->CR1 &= 0xFBFF;

  /* Hardware flow control disable */
  USART_ENGAGED->CR3 &= 0xFCFF;

  /* Rx, TX enable */
  USART_ENGAGED->CR1 |= 0x000C;

  /* USART1 enable */
  USART_ENGAGED->CR1 |= 0x2000;
}

static void USART_SendData(USART_TypeDef *USARTx, uint16_t Data) {
  /* Transmit Data */
  USARTx->DR = (Data & (uint16_t)0x01FF);
}

/* Wait loop delays program flow for about nCount ticks */
void Delay(vu32 nCount) {
  for (; nCount != 0; nCount--)
    ;
}
