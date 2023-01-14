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
static void TIM2_configuration_PWM(void);
static void AD1_configuration(void);
uint16_t USART_WaitToReceivedData(USART_TypeDef *USARTx);
/**
 * @brief Function turns on blue led light
 *
 */
static void blue_led_on(void);

/**
 * @brief Function turns off blue led light
 *
 */
static void blue_led_off(void);
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
   TIM2_configuration_PWM();
   AD1_configuration();

   /* Clear TC flag */
   USART2->SR &= 0xFFBF;

   printU(welcome, 25, USART2);

   /*Nekonecna smycka*/
   while (1) {
      tmp = USART_WaitToReceivedData(USART2);

      USART_SendData(USART2, tmp);
      if (GPIOA->IDR & 0x1) { // je PA0 stisknuto??
         blue_led_on();

         USART_SendData(USART2, tmp);

      } else {
         blue_led_off();
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
   RCC->APB2ENR |= RCC_APB2ENR_IOPBEN; // enable PB gated
   RCC->APB2ENR |= RCC_APB2ENR_IOPCEN; // enable PC

   RCC->APB1ENR |= RCC_APB1ENR_TIM2EN; // enable TIM2 for PWA

   RCC->APB1ENR |= RCC_APB1ENR_USART2EN; // enable USART2 clock

   RCC->APB1ENR |= RCC_APB1ENR_TIM2EN; // enable TIM2 clock

   RCC->APB1ENR |= RCC_APB1ENR_I2C2EN; // enable I2C_2 clock

   RCC->APB2ENR |= RCC_APB2ENR_ADC1EN; // enable DAC1 clock
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

   /*Details on how to connect the peripheral are specified in doc on the
      page 110 (Asstes\RM0041_reference_manual_ARMSTM32F100xx.pdf). */

   // Configure PA1 (TIM2_CH2): alternate func. output push-pull, 50MHz
   GPIOA->CRL &= 0xFFFFFF0F;
   GPIOA->CRL |= 0x000000B0;

   // Configure PA2 (USART2 TX): alternate func. output Push-pull, 50MHz
   GPIOA->CRL &= 0xFFFFF0FF;
   GPIOA->CRL |= 0x00000B00;

   // Configure PA3 (USART2 RX): floating input
   GPIOA->CRL &= 0xFFFF0FFF;
   GPIOA->CRL |= 0x00004000;

   // PC11 I2Cx_SDA I2C Data I/O Alternate function open drain (11), 10MHz (01)
   GPIOC->CRH &= 0xFFFF0FFF;
   GPIOC->CRH |= 0x0000D000;

   // PC10 I2Cx_SCL I2C clock Alternate function open drain (11), 10MHz (01)
   GPIOC->CRH &= 0xFFFFF0FF;
   GPIOC->CRH |= 0x00000D00;

   // Configure PC0 (ADC1_IN10): Analog input
   GPIOC->CRL &= 0xFFFFFFF0;
   GPIOC->CRL |= 0x00000000;
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

static void TIM2_configuration_PWM(void)
{
   TIM2->CR1 = 0x0080;   // turn of ARPE bit
   TIM2->CCMR1 = 0x6800; // config channel 2
   TIM2->CCER = 0x1;
   TIM2->PSC = 0;
   TIM2->ARR = 23999 / 5;  // set frequency
   TIM2->CCR2 = 12000 / 5; // set dutycycle
   TIM2->CR1 |= 0x1;
   TIM2->CCER |= TIM_CCER_CC2E;
}

static void AD1_configuration(void)
{
   ADC1->CR2 |= 0xE0000;
   ADC1->SMPR2 |= 0x200;
   ADC1->SQR3 |= 0xA;
   ADC1->CR2 |= 0x9;
   ADC1->CR2 |= 0x4;
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

static void blue_led_on(void) { GPIOC->BSRR |= 0x100; }

static void blue_led_off(void) { GPIOC->BSRR |= 0x1000000; }