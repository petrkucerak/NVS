//;***************************************************************************************************
//;*
//;* Misto			: CVUT FEL, Katedra Mereni
//;* Prednasejici		: Doc. Ing. Jan Fischer,CSc.
//;* Predmet			: A4B38NVS
//;* Vyvojovy Kit		: STM32 VL DISCOVERY (STM32F100RB)
//;*
//;**************************************************************************************************

#include "stm32f10x.h"

/*Definitions*/

/*Global variables*/
uint16_t tmp;
char *welcome = "The start of measuring!\n";
uint8_t i;

/*Function definitions*/
static void RCC_Configuration(void);
static void GPIO_Configuration(void);
static void Delay(vu32 nCount);
static void USART2_Configuration(void);
static void USART_SendData(USART_TypeDef *USARTx, uint16_t Data);
uint16_t USART_WaitToReceivedData(USART_TypeDef *USARTx);
/**
 * @brief Function turns on blue led light
 *
 */
static void blueLedOn();

/**
 * @brief Function turns off blue led light
 *
 */
static void blueLedOff();
static void printU(char *string, uint8_t tx_ptr, USART_TypeDef *USARTx);

void SystemInit(void)
{
   // Prazdna inicializacni metoda
}

/*Main function*/
int main(void)
{
   RCC_Configuration();  // inicializace hodin
   GPIO_Configuration(); // inicializace GPIO
   USART2_Configuration();

   /* Clear TC flag */
   USART2->SR &= 0xFFBF;

   printU(welcome, 25, USART2);

   /*Nekonecna smycka*/
   while (1) {
      if (GPIOA->IDR & 0x1) { // je PA0 stisknuto??
         blueLedOn();

         USART_SendData(USART2, 0x61);

      } else {
         blueLedOff();
      }
   }
}
/*Inicializace RCC*/
static void RCC_Configuration(void)
{
   RCC->CR |= 0x10000; // HSE on
   while (!(RCC->CR & 0x20000)) {
   }
   // flash access setup
   FLASH->ACR &= 0x00000038; // mask register
   FLASH->ACR |= 0x00000002; // flash 2 wait state

   FLASH->ACR &= 0xFFFFFFEF; // mask register
   FLASH->ACR |= 0x00000010; // enable Prefetch Buffer

   RCC->CFGR &= 0xFFC3FFFF; // maskovani PLLMUL
   RCC->CFGR |= 0x1 << 18;  // Nastveni PLLMUL 3x
   RCC->CFGR |= 0x0 << 17;  // nastaveni PREDIV1 1x

   RCC->CFGR |= 0x10000;    // PLL bude clocovan z PREDIV1
   RCC->CFGR &= 0xFFFFFF0F; // HPRE=1x
   RCC->CFGR &= 0xFFFFF8FF; // PPRE2=1x
   RCC->CFGR &= 0xFFFFC7FF; // PPRE2=1x

   RCC->CR |= 0x01000000; // PLL on
   while (!(RCC->CR & 0x02000000)) {
   } // PLL stable??

   RCC->CFGR &= 0xFFFFFFFC;
   RCC->CFGR |= 0x2; // nastaveni PLL jako zdroj hodin pro SYSCLK

   while (!(RCC->CFGR & 0x00000008)) // je SYSCLK nastaveno?
   {
   }
   /* Peripheral clock enable */
   RCC->APB2ENR |= RCC_APB2ENR_IOPAEN; // enable PA
   RCC->APB2ENR |= RCC_APB2ENR_IOPCEN; // enable PC

   RCC->APB1ENR |= RCC_APB1ENR_TIM2EN; // enable TIM2 for PWA

   RCC->APB1ENR |= RCC_APB1ENR_USART2EN; // enable USART2 clock
}
/*Inicializace GPIO*/
static void GPIO_Configuration(void)
{
   /* Blue light */
   GPIOC->CRH &= 0xFFFFFFF0; // PC8
   GPIOC->CRH |= 0x3;        // PC8 jako PP output

   /* Blue button */
   GPIOA->CRL &= 0xFFFFFFF0;
   GPIOA->CRL |= 0x4; // PA0 jako Floating input

   /* Configure PA2 (USART2 TX): alternate func. output Push-pull, 10MHz */
   GPIOA->CRL &= 0xFFFFFF0F;
   GPIOA->CRL |= 0x000000C0;

   /* Configure PA3 (USART2 RX): floating input */
   GPIOA->CRL &= 0xFFFFF0FF;
   GPIOA->CRL |= 0x00000B00;
}

/* Wait loop delays program flow for about nCount ticks */
static void Delay(vu32 nCount)
{
   for (; nCount != 0; nCount--)
      ;
}
static void USART2_Configuration(void)
{
   /* Baud Rate setup 9600 Bd (see Reference manual for details) */
   USART2->BRR = 0x09C4;
   /* 8 data bits */
   USART2->CR1 &= 0xEFFF;
   /* 1 stopbit */
   USART2->CR2 &= 0xCFFF;

   /* Parity disabled */
   USART2->CR1 &= 0xFBFF;

   /* Hardware flow control disable */
   USART2->CR3 &= 0xFCFF;

   /* Rx, TX enable */
   USART2->CR1 |= 0x000C;

   /* USART2 enable */
   USART2->CR1 |= USART_CR1_UE;
}

static void USART_SendData(USART_TypeDef *USARTx, uint16_t Data)
{
   /* Is Transmit Data Register Empty */
   while ((USARTx->SR & USART_SR_TXE) != USART_SR_TXE) {
   }
   /* Transmit a data */
   // USARTx->DR = (Data & (uint16_t)0x01FF);
   USARTx->DR = (Data);
   /* Is Transmission Complete */
   while ((USARTx->SR & USART_SR_TC) != USART_SR_TC) {
   }
}

uint16_t USART_WaitToReceivedData(USART_TypeDef *USARTx)
{
   /* Is Read Data Register Not Empty */
   while ((USARTx->SR & USART_SR_RXNE) != USART_SR_RXNE) {
   }
   return USARTx->DR;
}

static void printU(char *string, uint8_t tx_ptr, USART_TypeDef *USARTx)
{
   for (i = 0; i < tx_ptr; ++i) {
      USART_SendData(USARTx, string[i]);
   }
}

static void blueLedOn() { GPIOC->BSRR |= 0x100; }

static void blueLedOff() { GPIOC->BSRR |= 0x1000000; }